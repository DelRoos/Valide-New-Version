"""
seed_3e_content.py — Seed Firestore depuis data/seed_3e.json (schéma v2).

Écrit les collections et sous-collections suivantes :
  chapters/{chapterId}
  lessons/{lessonId}
  lessons/{lessonId}/content/main
  notions/{notionId}              ← collection racine (schema v2 — lisible sans lessonId côté mobile)
  lessons/{lessonId}/quizzes/{quizId}

Usage :
    # Valider sans écrire
    python seed_3e_content.py --project valide-edu --dry-run

    # Seed réel
    python seed_3e_content.py --project valide-edu

    # Générer seed_3e.json avant de seeder
    python build_seed_3e.py && python seed_3e_content.py --project valide-edu

Prérequis :
    - python build_seed_3e.py exécuté au moins une fois (crée data/seed_3e.json)
    - gcloud auth application-default login   OU   --credentials service-account.json
    - La collection subjects doit exister (seed_catalogue.py exécuté)

Idempotence : set(merge=True) partout — un re-run produit le même état Firestore.

Sécurité : service-account.json est gitignored. Ne jamais committer ce fichier.
"""

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path
from typing import Optional

import firebase_admin
from firebase_admin import credentials, firestore
from google.cloud.firestore_v1 import SERVER_TIMESTAMP

DEFAULT_DATA_PATH = Path(__file__).resolve().parent / "data" / "seed_3e.json"

EXPECTED_SCHEMA = "v2-subcollections"

# Types callout reconnus par _Callout._styleFor() dans l'app Flutter.
# Ces valeurs sont les noms des blocs :::type::: du contenu Markdown.
VALID_NOTION_TYPES = {
    "definition",
    "theoreme", "theorem",
    "demonstration", "demo", "preuve",
    "propriete", "prop", "property",
    "methode", "method",
    "attention", "warning", "danger",
    "retenir", "recap",
    "exemple", "example",
    "figure",
}


# ─────────────────────────────────────────────────────────────────────────────
# Validation
# ─────────────────────────────────────────────────────────────────────────────

def _require_bilingual(ctx: str, field) -> None:
    if not isinstance(field, dict) or not field.get("fr") or not field.get("en"):
        raise ValueError(f"{ctx} : champ bilingue {{fr, en}} requis — reçu {field!r}")


def validate_seed(data: dict) -> None:
    """Valide la structure complète du JSON seed v2. Lève ValueError si invalide."""
    if data.get("schema") != EXPECTED_SCHEMA:
        raise ValueError(
            f"schema attendu '{EXPECTED_SCHEMA}', reçu '{data.get('schema')}'. "
            "Relance build_seed_3e.py pour regénérer."
        )

    subjects = data.get("subjects", [])
    if not subjects:
        raise ValueError("data.subjects est vide — au moins 1 matière requise")

    seen_chapters: set[str] = set()
    seen_lessons: set[str] = set()

    for s in subjects:
        s_id = s.get("subjectId", "?")
        if not s.get("chapters"):
            raise ValueError(f"subjectId '{s_id}' : chapters vide")

        for ch in s["chapters"]:
            ch_id = ch.get("chapterId", "")
            if not ch_id:
                raise ValueError(f"subjectId '{s_id}' : chapterId manquant")
            if ch_id in seen_chapters:
                raise ValueError(f"chapterId dupliqué : '{ch_id}'")
            seen_chapters.add(ch_id)

            if not isinstance(ch.get("order"), int) or ch["order"] < 1:
                raise ValueError(f"chapter '{ch_id}' : order doit être entier >= 1")
            _require_bilingual(f"chapter '{ch_id}'.title", ch.get("title"))
            fiche = ch.get("fiche")
            if fiche is not None:
                _require_bilingual(f"chapter '{ch_id}'.fiche", fiche)

            for l in ch.get("lessons", []):
                l_id = l.get("lessonId", "")
                if not l_id:
                    raise ValueError(f"chapter '{ch_id}' : lessonId manquant")
                if l_id in seen_lessons:
                    raise ValueError(f"lessonId dupliqué : '{l_id}'")
                seen_lessons.add(l_id)

                if not isinstance(l.get("order"), int) or l["order"] < 1:
                    raise ValueError(f"lesson '{l_id}' : order doit être entier >= 1")
                _require_bilingual(f"lesson '{l_id}'.title", l.get("title"))
                _require_bilingual(f"lesson '{l_id}'.content", l.get("content"))

                # Les notionId sont uniques par leçon (sous-collection lessons/{id}/notions/).
                # Un même ID dans deux leçons différentes est valid en Firestore v2.
                seen_notions_in_lesson: set[str] = set()
                for n in l.get("notions", []):
                    n_id = n.get("notionId", "")
                    if not n_id:
                        raise ValueError(f"lesson '{l_id}' : notionId manquant")
                    if n_id in seen_notions_in_lesson:
                        raise ValueError(f"lesson '{l_id}' : notionId dupliqué dans la même leçon : '{n_id}'")
                    seen_notions_in_lesson.add(n_id)

                    if n.get("type") not in VALID_NOTION_TYPES:
                        raise ValueError(
                            f"notion '{n_id}' : type '{n.get('type')}' invalide "
                            f"— attendu parmi {sorted(VALID_NOTION_TYPES)}"
                        )
                    _require_bilingual(f"notion '{n_id}'.title", n.get("title"))

                for q in l.get("quizzes", []):
                    q_id = q.get("quizId", "")
                    if not q_id:
                        raise ValueError(f"lesson '{l_id}' : quizId manquant")
                    if not q.get("questions"):
                        raise ValueError(f"quiz '{q_id}' : questions vide")


def validate_subject_refs(data: dict, db) -> None:
    """Vérifie que tous les subjectId existent dans Firestore (collection subjects)."""
    subject_ids = {s["subjectId"] for s in data["subjects"]}
    existing = {doc.id for doc in db.collection("subjects").stream()}
    missing = subject_ids - existing
    if missing:
        raise ValueError(
            f"subjectId(s) absents de Firestore : {sorted(missing)}\n"
            "  → Relance seed_catalogue.py d'abord."
        )
    print(f"[OK] Cross-ref subjects : {len(subject_ids)} validé(s) dans Firestore")


# ─────────────────────────────────────────────────────────────────────────────
# Firebase init
# ─────────────────────────────────────────────────────────────────────────────

def init_firebase(project_id: str, credentials_path: Optional[Path]):
    if credentials_path:
        if not credentials_path.exists():
            raise FileNotFoundError(f"Credentials introuvable : {credentials_path}")
        cred = credentials.Certificate(str(credentials_path))
        mode = f"service-account ({credentials_path.name})"
    else:
        cred = credentials.ApplicationDefault()
        mode = "Application Default Credentials"

    firebase_admin.initialize_app(cred, {"projectId": project_id})
    print(f"[OK] Auth : {mode} | project={project_id}")
    return firestore.client()


# ─────────────────────────────────────────────────────────────────────────────
# Seed
# ─────────────────────────────────────────────────────────────────────────────

def seed_content(db, data: dict, dry_run: bool) -> dict[str, int]:
    """
    Écrit (ou simule) les collections/sous-collections du schéma v2.
    Retourne les compteurs par type de document.
    """
    counts = {
        "chapters": 0,
        "lessons": 0,
        "lessonContents": 0,
        "notions": 0,
        "quizzes": 0,
        "chapterFiches": 0,
    }

    # levelId au format "<subSystem>_<level>" (ex. "francophone_3e")
    level_id = f"{data['subSystem']}_{data['level']}"
    sub_system = data["subSystem"]

    for subject in data["subjects"]:
        subject_id = subject["subjectId"]

        for ch in subject.get("chapters", []):
            ch_id = ch["chapterId"]
            lesson_count = len(ch.get("lessons", []))

            quiz_count = sum(
                1 for l in ch.get("lessons", []) if l.get("quizzes")
            )

            ch_payload = {
                "subjectId": subject_id,
                "levelId": level_id,
                "subSystem": sub_system,
                "order": ch["order"],
                "title": ch["title"],
                "description": ch.get("description"),
                "lessonCount": lesson_count,
                "quizCount": quiz_count,
                "exerciseCount": 0,    # Pas d'exercices en V1
                "progressPercent": 0,  # Toujours 0 en V1 — placeholder Epic 3
                "studentCount": 0,     # Initialisé à 0 — Cloud Function met à jour
                "updatedAt": SERVER_TIMESTAMP,
                "createdAt": SERVER_TIMESTAMP,
            }
            if not dry_run:
                db.collection("chapters").document(ch_id).set(ch_payload, merge=True)
            counts["chapters"] += 1

            # ── Fiche de révision (optionnelle) — chapters/{id}/fiche/main
            fiche = ch.get("fiche")
            if fiche and (fiche.get("fr") or fiche.get("en")):
                fiche_payload = {
                    "fr": fiche.get("fr", ""),
                    "en": fiche.get("en") or fiche.get("fr", ""),
                    "updatedAt": SERVER_TIMESTAMP,
                }
                if not dry_run:
                    (db.collection("chapters").document(ch_id)
                       .collection("fiche").document("main")
                       .set(fiche_payload, merge=True))
                counts["chapterFiches"] += 1

            for lesson in ch.get("lessons", []):
                l_id = lesson["lessonId"]

                # ── Métadonnées leçon (sans Markdown)
                # Champs lus par LessonModel.fromFirestore :
                #   lessonId (doc ID), chapterId, order, title, subtitle?, durationMinutes
                l_payload = {
                    "chapterId": ch_id,
                    "order": lesson["order"],
                    "title": lesson["title"],
                    "durationMinutes": lesson["durationMinutes"],
                    "updatedAt": SERVER_TIMESTAMP,
                    "createdAt": SERVER_TIMESTAMP,
                }
                if lesson.get("subtitle"):
                    l_payload["subtitle"] = lesson["subtitle"]
                if not dry_run:
                    db.collection("lessons").document(l_id).set(l_payload, merge=True)
                counts["lessons"] += 1

                # ── Contenu Markdown — sous-document lessons/{id}/content/main
                content_payload = {
                    "fr": lesson["content"].get("fr", ""),
                    "en": lesson["content"].get("en", ""),
                }
                if not dry_run:
                    (
                        db.collection("lessons").document(l_id)
                        .collection("content").document("main")
                        .set(content_payload, merge=True)
                    )
                counts["lessonContents"] += 1

                # ── Notions — collection racine notions/{notionId}
                # (lisible côté mobile via notions/{notionId} sans connaître lessonId)
                for notion in lesson.get("notions", []):
                    n_id = notion["notionId"]
                    n_payload = {
                        "notionId": n_id,
                        "lessonId": l_id,
                        "order": notion["order"],
                        "type": notion["type"],
                        "title": notion["title"],
                        "content": notion["content"],
                    }
                    if not dry_run:
                        db.collection("notions").document(n_id).set(
                            n_payload, merge=True
                        )
                    counts["notions"] += 1

                # ── Quizzes — sous-collection lessons/{id}/quizzes/{quizId}
                for quiz in lesson.get("quizzes", []):
                    q_id = quiz["quizId"]
                    q_payload = {
                        "lessonId": l_id,
                        "version": quiz.get("version", 1),
                        "questions": quiz.get("questions", []),
                    }
                    if not dry_run:
                        (
                            db.collection("lessons").document(l_id)
                            .collection("quizzes").document(q_id)
                            .set(q_payload, merge=True)
                        )
                    counts["quizzes"] += 1

    prefix = "[DRY-RUN]" if dry_run else "[OK]"
    for key, count in counts.items():
        print(f"{prefix} {key:<20}: {count:3d} docs")

    return counts


# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Seed Firestore — contenu pédagogique 3e (schéma v2 sous-collections)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Exemples :\n"
            "  python seed_3e_content.py --project valide-edu --dry-run\n"
            "  python seed_3e_content.py --project valide-edu\n"
            "  python seed_3e_content.py --project valide-edu --credentials ./service-account.json\n"
        ),
    )
    parser.add_argument("--project", required=True, help="ID projet Firebase (ex. valide-edu)")
    parser.add_argument("--credentials", type=Path, default=None)
    parser.add_argument("--dry-run", action="store_true", help="Simule sans écrire dans Firestore")
    parser.add_argument(
        "--data",
        type=Path,
        default=DEFAULT_DATA_PATH,
        help=f"Fichier seed JSON v2 (défaut : {DEFAULT_DATA_PATH.name})",
    )
    args = parser.parse_args()

    # 1. Charger
    if not args.data.exists():
        print(
            f"[ERROR] {args.data} introuvable.\n"
            "  → Lance d'abord : python build_seed_3e.py",
            file=sys.stderr,
        )
        return 1

    with args.data.open(encoding="utf-8") as f:
        data = json.load(f)

    # 2. Valider
    try:
        validate_seed(data)
    except ValueError as exc:
        print(f"[ERROR] Validation échouée :\n  {exc}", file=sys.stderr)
        return 1

    n_subjects = len(data["subjects"])
    print(
        f"[OK] {args.data.name} — "
        f"schema={data['schema']} v={data['version']} "
        f"({n_subjects} matière(s))"
    )

    # 3. Firebase
    if args.dry_run:
        db = None
        print("[DRY-RUN] Init Firebase sautée.")
    else:
        try:
            db = init_firebase(args.project, args.credentials)
        except Exception as exc:
            print(f"[ERROR] Init Firebase : {exc}", file=sys.stderr)
            return 1

        try:
            validate_subject_refs(data, db)
        except ValueError as exc:
            print(f"[ERROR] {exc}", file=sys.stderr)
            return 1

    # 4. Seed
    start = time.perf_counter()
    try:
        counts = seed_content(db, data, args.dry_run)
    except Exception as exc:
        print(f"[ERROR] Seed échoué : {exc}", file=sys.stderr)
        return 1

    elapsed = time.perf_counter() - start
    total = sum(counts.values())
    prefix = "[DRY-RUN]" if args.dry_run else "[OK]"
    print(f"\n{prefix} Total : {total} docs en {elapsed:.2f}s")

    if args.dry_run:
        print("[DRY-RUN] Aucune écriture. Relance sans --dry-run pour le seed réel.")

    return 0


if __name__ == "__main__":
    sys.exit(main())
