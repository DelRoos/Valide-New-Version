"""
migrate_user_school_denorm.py — Story 1.5.d (Valide School Epic 1.5).

Migration one-shot admin : denormalise les champs `schoolCity`, `schoolRegion`
et `schoolName` dans `users/{uid}` depuis `schools/{schoolId}` pour tous les
users legacy crees avant Story 1.5.d (ceux avec `schoolId != null` mais sans
les 3 nouveaux champs).

Usage :
    # Auth via Application Default Credentials (recommande)
    python migrate_user_school_denorm.py --project valide-edu

    # Dry-run : liste les users a migrer sans ecrire
    python migrate_user_school_denorm.py --project valide-edu --dry-run

    # Auth via service-account JSON (CI/CD)
    python migrate_user_school_denorm.py --project valide-edu --credentials ./service-account.json

Schema cible : doc/partage/BASE-DE-DONNEES.md § users/{uid} (Story 1.5.d).
Story d'origine : project_manage/implementation-artifacts/1-5-d-denormalisation-school-fields-users.md.

Idempotence : utilise set(merge=True). Re-run sur un user deja migre = 0
changement (skip detecte via schoolCity deja renseigne). Le script peut
etre rejoue en cas d'interruption reseau.

Edge case : si un user reference un schoolId qui n'existe plus dans la
collection `schools` (cas rare : ecole supprimee manuellement par admin),
le script log un warning et skip le user — l'admin peut le traiter
manuellement via Firebase Console.

Securite : le service-account.json est gitignored. Ne jamais commit.
"""

from __future__ import annotations

import argparse
import sys
import time
from pathlib import Path
from typing import Optional

import firebase_admin
from firebase_admin import credentials, firestore

USERS_COLLECTION = "users"
SCHOOLS_COLLECTION = "schools"


# ---------------------------------------------------------------------
# Firebase init (calque seed_schools.py)
# ---------------------------------------------------------------------

def _init_firebase(project_id: str, credentials_path: Optional[Path]):
    """Initialise firebase-admin et retourne un client Firestore."""
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
# Migration core (testable via injection client mock)
# ---------------------------------------------------------------------

def migrate_users_school_denorm(db, dry_run: bool = False) -> dict:
    """Scanne `users` et denormalise les 4 champs school* pour ceux legacy.

    Pour chaque user avec `schoolId != null` ET `schoolCity` absent ou None :
      - Fetch `schools/{schoolId}` (lookup par ID auto-indexe, regle 10.k)
      - Si school existe : set(merge=True) {schoolCity, schoolRegion, schoolName}
      - Si school absente : log warning + skip

    Retourne un dict de stats :
      {scanned, migrated, already_done, skipped_missing_school, no_school_id}
    """
    stats = {
        "scanned": 0,
        "migrated": 0,
        "already_done": 0,
        "skipped_missing_school": 0,
        "no_school_id": 0,
    }

    # Cache local des schools pour eviter de re-fetch le meme school plusieurs
    # fois si plusieurs users pointent dessus (1 read par school touchee).
    schools_cache: dict[str, Optional[dict]] = {}

    users_stream = db.collection(USERS_COLLECTION).stream()
    for doc in users_stream:
        stats["scanned"] += 1
        user_data = doc.to_dict() or {}
        user_uid = doc.id  # public ID, OK a logger via uid prefix court

        school_id = user_data.get("schoolId")
        if school_id is None:
            stats["no_school_id"] += 1
            continue

        # Idempotence : skip si schoolCity deja renseigne (= deja migre).
        if user_data.get("schoolCity") is not None:
            stats["already_done"] += 1
            continue

        # Lookup school avec cache.
        if school_id not in schools_cache:
            school_doc = db.collection(SCHOOLS_COLLECTION).document(school_id).get()
            schools_cache[school_id] = school_doc.to_dict() if school_doc.exists else None

        school = schools_cache[school_id]
        if school is None:
            # Ecole inexistante : log + skip (admin doit traiter manuellement).
            uid_prefix = user_uid[:6] + "..." if len(user_uid) > 6 else user_uid
            print(
                f"[WARN] user {uid_prefix} references schoolId='{school_id}' "
                f"which does not exist in schools/ -> skip"
            )
            stats["skipped_missing_school"] += 1
            continue

        payload = {
            "schoolCity": school.get("city"),
            "schoolRegion": school.get("region"),
            "schoolName": school.get("name"),
            "updatedAt": firestore.SERVER_TIMESTAMP,
        }

        if dry_run:
            uid_prefix = user_uid[:6] + "..." if len(user_uid) > 6 else user_uid
            print(
                f"[DRY-RUN] would migrate user {uid_prefix}: "
                f"schoolId={school_id} -> city={payload['schoolCity']} "
                f"region={payload['schoolRegion']} name={payload['schoolName']}"
            )
        else:
            db.collection(USERS_COLLECTION).document(user_uid).set(
                payload, merge=True
            )

        stats["migrated"] += 1

    return stats


# ---------------------------------------------------------------------
# Main CLI
# ---------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Migration one-shot denormalisation users/{uid}.school* (Story 1.5.d).",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Exemples :\n"
            "  python migrate_user_school_denorm.py --project valide-edu --dry-run\n"
            "  python migrate_user_school_denorm.py --project valide-edu\n"
            "  python migrate_user_school_denorm.py --project valide-edu --credentials ./service-account.json\n"
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
        help="Liste les users a migrer sans ecrire dans Firestore.",
    )
    args = parser.parse_args()

    # Init Firebase.
    try:
        db = _init_firebase(args.project, args.credentials)
    except Exception as exc:  # noqa: BLE001
        print(f"[ERROR] Init Firebase echouee : {exc}", file=sys.stderr)
        print(
            "  -> verifier auth (gcloud auth application-default login OU --credentials service-account.json)",
            file=sys.stderr,
        )
        return 1

    # Migration.
    start = time.perf_counter()
    try:
        stats = migrate_users_school_denorm(db, dry_run=args.dry_run)
    except Exception as exc:  # noqa: BLE001
        print(f"[ERROR] Echec migration : {exc}", file=sys.stderr)
        return 1

    elapsed = time.perf_counter() - start
    prefix = "[DRY-RUN]" if args.dry_run else "[OK]"
    print(
        f"\n{prefix} Migration terminee en {elapsed:.2f} s.\n"
        f"  scanned                 : {stats['scanned']}\n"
        f"  migrated                : {stats['migrated']}\n"
        f"  already_done (idempot.) : {stats['already_done']}\n"
        f"  no_school_id            : {stats['no_school_id']}\n"
        f"  skipped_missing_school  : {stats['skipped_missing_school']}"
    )

    if args.dry_run:
        print("[DRY-RUN] Aucune ecriture effectuee. Relance sans --dry-run pour migration reelle.")

    return 0


if __name__ == "__main__":
    sys.exit(main())
