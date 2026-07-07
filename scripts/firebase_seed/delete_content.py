"""
delete_content.py — Supprime les collections de contenu pédagogique de Firestore.

Collections supprimées (dans cet ordre) :
  1. notions/          (collection racine — pas de sous-collections)
  2. lessons/{id}/quizzes/*   (sous-collection)
  3. lessons/{id}/content/*   (sous-collection)
  4. lessons/          (collection racine)
  5. chapters/{id}/fiche/*    (sous-collection)
  6. chapters/         (collection racine)

NE supprime PAS :
  - subjects, filieres, niveaux, series, exam_targets, derivation_rules  (catalogue)
  - schools, school_requests
  - users et sous-collections

Usage :
    # Simuler sans supprimer
    python delete_content.py --project valide-edu --dry-run

    # Supprimer réellement (demande confirmation interactive)
    python delete_content.py --project valide-edu

    # Avec service account
    python delete_content.py --project valide-edu --credentials ./service-account.json

⚠️  IRRÉVERSIBLE — toujours faire un backup avec dump_content.py avant.

Sécurité : service-account.json est gitignored. Ne jamais committer ce fichier.
"""

from __future__ import annotations

import argparse
import sys
import time
from pathlib import Path
from typing import Optional

import firebase_admin
from firebase_admin import credentials, firestore

_BATCH_SIZE = 400  # < 500 (limite Firestore)


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
# Suppression par batch
# ─────────────────────────────────────────────────────────────────────────────

def _delete_subcollection(db, col_ref, dry_run: bool) -> int:
    """Supprime tous les docs d'une sous-collection via batches."""
    count = 0
    batch = db.batch()
    batch_count = 0

    for doc in col_ref.stream():
        if not dry_run:
            batch.delete(doc.reference)
            batch_count += 1
            if batch_count >= _BATCH_SIZE:
                batch.commit()
                batch = db.batch()
                batch_count = 0
        count += 1

    if not dry_run and batch_count > 0:
        batch.commit()

    return count


# ─────────────────────────────────────────────────────────────────────────────
# Suppression du contenu
# ─────────────────────────────────────────────────────────────────────────────

def delete_content(db, dry_run: bool) -> dict[str, int]:
    prefix = "[DRY-RUN]" if dry_run else "[DELETE]"
    counts = {
        "notions": 0,
        "lesson_sub_docs": 0,
        "lessons": 0,
        "chapter_sub_docs": 0,
        "chapters": 0,
    }

    # ── 1. Notions (pas de sous-collections) ─────────────────────────────────
    print(f"\n{prefix} notions/...")
    notion_docs = list(db.collection("notions").stream())
    if notion_docs:
        batch = db.batch()
        batch_count = 0
        for doc in notion_docs:
            if not dry_run:
                batch.delete(doc.reference)
                batch_count += 1
                if batch_count >= _BATCH_SIZE:
                    batch.commit()
                    batch = db.batch()
                    batch_count = 0
            counts["notions"] += 1
        if not dry_run and batch_count > 0:
            batch.commit()
    print(f"{prefix} {counts['notions']} notions")

    # ── 2. Lessons + sous-collections ────────────────────────────────────────
    print(f"\n{prefix} lessons/ (+ content/main + quizzes/*)...")
    lesson_docs = list(db.collection("lessons").stream())
    lesson_batch = db.batch()
    lesson_batch_count = 0

    for doc in lesson_docs:
        # Sous-collections d'abord
        n = _delete_subcollection(db, doc.reference.collection("content"), dry_run)
        counts["lesson_sub_docs"] += n
        n = _delete_subcollection(db, doc.reference.collection("quizzes"), dry_run)
        counts["lesson_sub_docs"] += n

        # Doc lesson lui-même
        if not dry_run:
            lesson_batch.delete(doc.reference)
            lesson_batch_count += 1
            if lesson_batch_count >= _BATCH_SIZE:
                lesson_batch.commit()
                lesson_batch = db.batch()
                lesson_batch_count = 0
        counts["lessons"] += 1

    if not dry_run and lesson_batch_count > 0:
        lesson_batch.commit()

    print(f"{prefix} {counts['lessons']} lessons + {counts['lesson_sub_docs']} sous-docs")

    # ── 3. Chapters + sous-collections ───────────────────────────────────────
    print(f"\n{prefix} chapters/ (+ fiche/main)...")
    chapter_docs = list(db.collection("chapters").stream())
    ch_batch = db.batch()
    ch_batch_count = 0

    for doc in chapter_docs:
        # Fiche
        n = _delete_subcollection(db, doc.reference.collection("fiche"), dry_run)
        counts["chapter_sub_docs"] += n

        # Doc chapter lui-même
        if not dry_run:
            ch_batch.delete(doc.reference)
            ch_batch_count += 1
            if ch_batch_count >= _BATCH_SIZE:
                ch_batch.commit()
                ch_batch = db.batch()
                ch_batch_count = 0
        counts["chapters"] += 1

    if not dry_run and ch_batch_count > 0:
        ch_batch.commit()

    print(f"{prefix} {counts['chapters']} chapters + {counts['chapter_sub_docs']} fiches")

    return counts


# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Supprime les collections de contenu pédagogique de Firestore",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "⚠️  IRRÉVERSIBLE. Faites toujours un backup avec dump_content.py avant.\n\n"
            "Exemples :\n"
            "  python delete_content.py --project valide-edu --dry-run\n"
            "  python delete_content.py --project valide-edu\n"
            "  python delete_content.py --project valide-edu --credentials ./service-account.json\n"
        ),
    )
    parser.add_argument("--project", required=True, help="ID projet Firebase (ex. valide-edu)")
    parser.add_argument("--credentials", type=Path, default=None)
    parser.add_argument("--dry-run", action="store_true", help="Simule sans supprimer")
    args = parser.parse_args()

    if not args.dry_run:
        print(
            f"\n[!] ATTENTION - Suppression irreversible\n"
            f"   Collections : chapters, lessons, notions (et sous-collections)\n"
            f"   Projet      : {args.project}\n"
        )
        confirm = input("   Tapez 'SUPPRIMER' pour confirmer : ").strip()
        if confirm != "SUPPRIMER":
            print("[ANNULE] Aucune suppression effectuee.")
            return 0
        print()

    try:
        db = init_firebase(args.project, args.credentials)
    except Exception as exc:
        print(f"[ERROR] Init Firebase : {exc}", file=sys.stderr)
        return 1

    start = time.perf_counter()
    try:
        counts = delete_content(db, args.dry_run)
    except Exception as exc:
        print(f"[ERROR] Suppression échouée : {exc}", file=sys.stderr)
        return 1

    elapsed = time.perf_counter() - start
    total = sum(counts.values())
    prefix = "[DRY-RUN]" if args.dry_run else "[OK]"
    print(f"\n{prefix} {total} opérations en {elapsed:.2f}s")
    if args.dry_run:
        print("[DRY-RUN] Relance sans --dry-run pour supprimer réellement.")
    else:
        print("[OK] Contenu supprimé. Lance seed_3e_content.py + seed_fiches.py pour re-seeder.")

    return 0


if __name__ == "__main__":
    sys.exit(main())
