"""
dump_content.py — Exporte le contenu pédagogique Firestore vers un fichier JSON de backup.

Collections exportées :
  chapters/{chapterId}                    (doc principal)
  chapters/{chapterId}/fiche/main         (sous-doc optionnel)
  lessons/{lessonId}                      (doc principal)
  lessons/{lessonId}/content/main         (sous-doc Markdown)
  lessons/{lessonId}/quizzes/*            (sous-collection QCM)
  notions/{notionId}                      (collection racine)

Usage :
    python dump_content.py --project valide-edu
    python dump_content.py --project valide-edu --credentials ./service-account.json
    python dump_content.py --project valide-edu --output ./data/backup_2026-07-07.json

Sécurité : service-account.json est gitignored. Ne jamais committer ce fichier.
"""

from __future__ import annotations

import argparse
import json
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

import firebase_admin
from firebase_admin import credentials, firestore

DEFAULT_OUTPUT_DIR = Path(__file__).resolve().parent / "data"


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
# Sérialisation
# ─────────────────────────────────────────────────────────────────────────────

def _serialize(value):
    """Convertit les types Firestore non-sérialisables (timestamps, etc.) en JSON."""
    if value is None:
        return None
    if hasattr(value, "isoformat"):  # DatetimeWithNanoseconds, datetime
        return value.isoformat()
    if isinstance(value, dict):
        return {k: _serialize(v) for k, v in value.items()}
    if isinstance(value, list):
        return [_serialize(v) for v in value]
    return value


# ─────────────────────────────────────────────────────────────────────────────
# Export
# ─────────────────────────────────────────────────────────────────────────────

def dump_content(db) -> dict:
    data: dict = {
        "exportedAt": datetime.now(timezone.utc).isoformat(),
        "chapters": [],
        "lessons": [],
        "notions": [],
    }

    # ── Chapters + sous-collection fiche ─────────────────────────────────────
    print("[...] Export chapters...")
    ch_docs = list(db.collection("chapters").stream())
    for doc in ch_docs:
        entry: dict = {"id": doc.id, "data": _serialize(doc.to_dict())}
        fiche_doc = doc.reference.collection("fiche").document("main").get()
        if fiche_doc.exists:
            entry["fiche_main"] = _serialize(fiche_doc.to_dict())
        data["chapters"].append(entry)
    print(f"[OK] {len(data['chapters'])} chapters")

    # ── Lessons + content/main + quizzes/* ───────────────────────────────────
    print("[...] Export lessons...")
    lesson_docs = list(db.collection("lessons").stream())
    for doc in lesson_docs:
        entry = {"id": doc.id, "data": _serialize(doc.to_dict())}
        content_doc = doc.reference.collection("content").document("main").get()
        if content_doc.exists:
            entry["content_main"] = _serialize(content_doc.to_dict())
        entry["quizzes"] = [
            {"id": q.id, "data": _serialize(q.to_dict())}
            for q in doc.reference.collection("quizzes").stream()
        ]
        data["lessons"].append(entry)
    print(f"[OK] {len(data['lessons'])} lessons ({sum(len(l['quizzes']) for l in data['lessons'])} quiz docs)")

    # ── Notions ──────────────────────────────────────────────────────────────
    print("[...] Export notions...")
    notion_docs = list(db.collection("notions").stream())
    for doc in notion_docs:
        data["notions"].append({"id": doc.id, "data": _serialize(doc.to_dict())})
    print(f"[OK] {len(data['notions'])} notions")

    return data


# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Export contenu pédagogique Firestore → JSON backup",
        epilog=(
            "Exemples :\n"
            "  python dump_content.py --project valide-edu\n"
            "  python dump_content.py --project valide-edu --credentials ./service-account.json\n"
        ),
    )
    parser.add_argument("--project", required=True, help="ID projet Firebase (ex. valide-edu)")
    parser.add_argument("--credentials", type=Path, default=None)
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Chemin du fichier JSON de sortie (défaut : data/backup_content_YYYY-MM-DD_HH-MM.json)",
    )
    args = parser.parse_args()

    if args.output is None:
        ts = datetime.now(timezone.utc).strftime("%Y-%m-%d_%H-%M")
        args.output = DEFAULT_OUTPUT_DIR / f"backup_content_{ts}.json"

    try:
        db = init_firebase(args.project, args.credentials)
    except Exception as exc:
        print(f"[ERROR] Init Firebase : {exc}", file=sys.stderr)
        return 1

    start = time.perf_counter()
    data = dump_content(db)
    elapsed = time.perf_counter() - start

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    total = len(data["chapters"]) + len(data["lessons"]) + len(data["notions"])
    print(f"\n[OK] {total} docs exportés en {elapsed:.2f}s")
    print(f"[OK] Backup : {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
