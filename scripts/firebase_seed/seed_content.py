"""
seed_content.py — Story 2.1 (Valide School, Epic 2).

Seed idempotent du contenu pédagogique dans Firestore (3 collections :
chapters, lessons, notions) à partir de content_demo.json.

Usage :
    # Auth via Application Default Credentials (recommandé)
    python seed_content.py --project valide-edu

    # Auth via service-account JSON
    python seed_content.py --project valide-edu --credentials ./service-account.json

    # Dry-run : valide le JSON + log ce qui serait écrit, sans toucher Firestore
    python seed_content.py --project valide-edu --dry-run

    # Fichier de données alternatif
    python seed_content.py --project valide-edu --data ./data/my_content.json

Schéma Firestore : doc/partage/BASE-DE-DONNEES.md § chapters/lessons/notions.
Données source   : scripts/firebase_seed/data/content_demo.json.

Idempotence : utilise set(merge=True) partout (jamais add()). Un re-run avec
le même JSON produit le même état Firestore. Modifier content_demo.json + re-run
pour propager des évolutions.

Sécurité : le service-account.json est gitignored. Ne jamais commit ce fichier
ni logger son contenu.
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

# ---------------------------------------------------------------------
# Constantes
# ---------------------------------------------------------------------

DEFAULT_DATA_PATH = Path(__file__).resolve().parent / "data" / "content_demo.json"

# Champs requis minimum par type de document.
REQUIRED_CHAPTER_FIELDS = {"chapterId", "order", "title"}
REQUIRED_LESSON_FIELDS = {"lessonId", "order", "title", "content"}
REQUIRED_NOTION_FIELDS = {"notionId", "order", "title"}


# ---------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------

def _validate_data(data: dict) -> None:
    """Valide le fichier JSON avant écriture. Lève ValueError si invalide."""
    if "subjects" not in data:
        raise ValueError("Clé manquante dans le JSON : 'subjects'")
    if not isinstance(data["subjects"], list):
        raise ValueError("data['subjects'] doit être une liste")
    if len(data["subjects"]) == 0:
        raise ValueError("data['subjects'] est vide — au moins 1 matière requise")

    for s_idx, subject_entry in enumerate(data["subjects"]):
        if "subjectId" not in subject_entry:
            raise ValueError(f"subjects[{s_idx}] : champ 'subjectId' manquant")
        if "chapters" not in subject_entry:
            raise ValueError(f"subjects[{s_idx}] : champ 'chapters' manquant")

        subject_id = subject_entry["subjectId"]
        chapter_ids: set[str] = set()
        lesson_ids: set[str] = set()
        notion_ids: set[str] = set()

        for ch_idx, chapter in enumerate(subject_entry["chapters"]):
            _validate_doc("chapter", ch_idx, chapter, REQUIRED_CHAPTER_FIELDS)
            chapter_id = chapter["chapterId"]
            if chapter_id in chapter_ids:
                raise ValueError(f"{subject_id} : chapterId '{chapter_id}' dupliqué")
            chapter_ids.add(chapter_id)

            if not isinstance(chapter.get("order"), int) or chapter["order"] < 1:
                raise ValueError(f"chapter '{chapter_id}' : order doit être un entier >= 1")

            _validate_bilingual_field(f"chapter '{chapter_id}'", chapter["title"])
            if "description" in chapter and chapter["description"] is not None:
                _validate_bilingual_field(f"chapter '{chapter_id}'.description", chapter["description"])

            for le_idx, lesson in enumerate(chapter.get("lessons", [])):
                _validate_doc("lesson", le_idx, lesson, REQUIRED_LESSON_FIELDS)
                lesson_id = lesson["lessonId"]
                if lesson_id in lesson_ids:
                    raise ValueError(f"{subject_id} : lessonId '{lesson_id}' dupliqué")
                lesson_ids.add(lesson_id)

                if not isinstance(lesson.get("order"), int) or lesson["order"] < 1:
                    raise ValueError(f"lesson '{lesson_id}' : order doit être un entier >= 1")

                _validate_bilingual_field(f"lesson '{lesson_id}'.title", lesson["title"])
                _validate_bilingual_field(f"lesson '{lesson_id}'.content", lesson["content"])

                for no_idx, notion in enumerate(lesson.get("notions", [])):
                    _validate_doc("notion", no_idx, notion, REQUIRED_NOTION_FIELDS)
                    notion_id = notion["notionId"]
                    if notion_id in notion_ids:
                        raise ValueError(f"{subject_id} : notionId '{notion_id}' dupliqué")
                    notion_ids.add(notion_id)

                    if not isinstance(notion.get("order"), int) or notion["order"] < 1:
                        raise ValueError(f"notion '{notion_id}' : order doit être un entier >= 1")

                    _validate_bilingual_field(f"notion '{notion_id}'.title", notion["title"])


def _validate_doc(kind: str, idx: int, doc: dict, required: set) -> None:
    if not isinstance(doc, dict):
        raise ValueError(f"{kind}[{idx}] doit être un dict (reçu : {type(doc).__name__})")
    missing = required - set(doc.keys())
    if missing:
        raise ValueError(f"{kind}[{idx}] champs manquants : {sorted(missing)}")


def _validate_bilingual_field(context: str, field) -> None:
    if not isinstance(field, dict) or "fr" not in field or "en" not in field:
        raise ValueError(f"{context} doit être un dict {{fr, en}} (reçu : {field!r})")
    if not field["fr"] or not field["en"]:
        raise ValueError(f"{context} : les valeurs 'fr' et 'en' ne peuvent pas être vides")


def _validate_subject_refs(data: dict, db) -> None:
    """Vérifie que tous les subjectId référencés existent dans la collection subjects Firestore."""
    subject_ids_in_data = {s["subjectId"] for s in data["subjects"]}

    existing_ids = set()
    for doc in db.collection("subjects").stream():
        existing_ids.add(doc.id)

    missing = subject_ids_in_data - existing_ids
    if missing:
        raise ValueError(
            f"subjectId(s) absents de la collection Firestore 'subjects' : {sorted(missing)}\n"
            "  → vérifier que le seed catalogue (seed_catalogue.py) a bien été exécuté."
        )

    print(f"[OK] Référence cross-collection : {len(subject_ids_in_data)} subjectId(s) validés dans Firestore.")


# ---------------------------------------------------------------------
# Firebase init
# ---------------------------------------------------------------------

def _init_firebase(project_id: str, credentials_path: Optional[Path]):
    if credentials_path is not None:
        if not credentials_path.exists():
            raise FileNotFoundError(f"Fichier credentials introuvable : {credentials_path}")
        cred = credentials.Certificate(str(credentials_path))
        auth_mode = f"service-account ({credentials_path.name})"
    else:
        cred = credentials.ApplicationDefault()
        auth_mode = "Application Default Credentials"

    firebase_admin.initialize_app(cred, {"projectId": project_id})
    print(f"[OK] Auth: {auth_mode}, projectId={project_id}")
    return firestore.client()


# ---------------------------------------------------------------------
# Seed
# ---------------------------------------------------------------------

def _seed_content(db, data: dict, dry_run: bool) -> dict[str, int]:
    """Écrit (ou simule l'écriture) chapters, lessons, notions dans l'ordre.

    Retourne un dict {chapters: N, lessons: N, notions: N}.
    """
    counts = {"chapters": 0, "lessons": 0, "notions": 0}

    for subject_entry in data["subjects"]:
        subject_id = subject_entry["subjectId"]

        for chapter in subject_entry.get("chapters", []):
            chapter_id = chapter["chapterId"]
            chapter_payload = {
                "subjectId": subject_id,
                "order": chapter["order"],
                "title": chapter["title"],
                "description": chapter.get("description"),
                "createdAt": SERVER_TIMESTAMP,
            }
            if not dry_run:
                db.collection("chapters").document(chapter_id).set(chapter_payload, merge=True)
            counts["chapters"] += 1

            for lesson in chapter.get("lessons", []):
                lesson_id = lesson["lessonId"]
                lesson_payload = {
                    "chapterId": chapter_id,
                    "order": lesson["order"],
                    "title": lesson["title"],
                    "subtitle": lesson.get("subtitle"),
                    "content": lesson["content"],
                    "durationMinutes": lesson.get("durationMinutes", 0),
                    "createdAt": SERVER_TIMESTAMP,
                }
                if not dry_run:
                    db.collection("lessons").document(lesson_id).set(lesson_payload, merge=True)
                counts["lessons"] += 1

                for notion in lesson.get("notions", []):
                    notion_id = notion["notionId"]
                    notion_payload = {
                        "lessonId": lesson_id,
                        "order": notion["order"],
                        "title": notion["title"],
                        "createdAt": SERVER_TIMESTAMP,
                    }
                    if not dry_run:
                        db.collection("notions").document(notion_id).set(notion_payload, merge=True)
                    counts["notions"] += 1

    prefix = "[DRY-RUN]" if dry_run else "[OK]"
    print(f"{prefix} chapters          : {counts['chapters']:3d} docs")
    print(f"{prefix} lessons           : {counts['lessons']:3d} docs")
    print(f"{prefix} notions           : {counts['notions']:3d} docs")
    return counts


# ---------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Seed idempotent du contenu pédagogique Firestore (Story 2.1).",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Exemples :\n"
            "  python seed_content.py --project valide-edu --dry-run\n"
            "  python seed_content.py --project valide-edu\n"
            "  python seed_content.py --project valide-edu --credentials ./service-account.json\n"
        ),
    )
    parser.add_argument("--project", required=True, help="ID du projet Firebase (ex. valide-edu)")
    parser.add_argument(
        "--credentials",
        type=Path,
        default=None,
        help="Chemin vers service-account.json. Si absent, utilise Application Default Credentials.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Valide le JSON + log ce qui serait écrit, sans toucher Firestore.",
    )
    parser.add_argument(
        "--data",
        type=Path,
        default=DEFAULT_DATA_PATH,
        help=f"Chemin vers le fichier JSON (défaut : {DEFAULT_DATA_PATH.name} dans data/)",
    )
    args = parser.parse_args()

    # 1. Charger et valider le JSON.
    if not args.data.exists():
        print(f"[ERROR] Fichier de données introuvable : {args.data}", file=sys.stderr)
        return 1

    try:
        with args.data.open("r", encoding="utf-8") as f:
            data = json.load(f)
    except json.JSONDecodeError as exc:
        print(f"[ERROR] JSON invalide : {exc}", file=sys.stderr)
        return 1

    try:
        _validate_data(data)
    except ValueError as exc:
        print(f"[ERROR] Validation JSON échouée :\n{exc}", file=sys.stderr)
        return 1

    subject_count = len(data["subjects"])
    print(f"[OK] JSON chargé : version={data.get('version', '?')}, {subject_count} matière(s)")

    # 2. Init Firebase.
    if args.dry_run:
        print("[DRY-RUN] Init Firebase sautée — pas d'écriture.")
        db = None
    else:
        try:
            db = _init_firebase(args.project, args.credentials)
        except Exception as exc:  # noqa: BLE001
            print(f"[ERROR] Init Firebase échouée : {exc}", file=sys.stderr)
            print(
                "  → vérifier auth (gcloud auth application-default login OU --credentials service-account.json)",
                file=sys.stderr,
            )
            return 1

        # 3. Validation référentielle cross-collection.
        try:
            _validate_subject_refs(data, db)
        except ValueError as exc:
            print(f"[ERROR] Validation référentielle échouée :\n{exc}", file=sys.stderr)
            return 1

    # 4. Seed.
    start = time.perf_counter()
    try:
        counts = _seed_content(db, data, args.dry_run)
    except Exception as exc:  # noqa: BLE001
        print(f"[ERROR] Échec seed : {exc}", file=sys.stderr)
        return 1

    elapsed = time.perf_counter() - start
    prefix = "[DRY-RUN]" if args.dry_run else "[OK]"
    grand_total = sum(counts.values())
    print(f"\n{prefix} Total: {grand_total} documents en {elapsed:.2f} s.")

    if args.dry_run:
        print("[DRY-RUN] Aucune écriture effectuée. Relance sans --dry-run pour seed réel.")

    return 0


if __name__ == "__main__":
    sys.exit(main())
