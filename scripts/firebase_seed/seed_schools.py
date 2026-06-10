"""
seed_schools.py — Story 1.5.a (Valide School Epic 1.5 Schools completion).

Seed idempotent de la collection Firestore `schools` à partir d'une matrice
JSON versionnée (data/schools.json).

Usage :
    # Auth via Application Default Credentials (recommandé)
    python seed_schools.py --project valide-edu

    # Auth via service-account JSON (CI/CD)
    python seed_schools.py --project valide-edu --credentials ./service-account.json

    # Dry-run : valide la matrice + log ce qui serait écrit, sans toucher Firestore
    python seed_schools.py --project valide-edu --dry-run

Schéma Firestore : doc/partage/BASE-DE-DONNEES.md § schools/{schoolId}.
Story d'origine : project_manage/implementation-artifacts/1-5-a-seed-minesec-schools.md.

Idempotence : utilise set(merge=True) partout (jamais add()). Un re-run avec
la même matrice produit le même état Firestore. createdAt est posé via
SERVER_TIMESTAMP au first-write uniquement (merge préserve la valeur existante
sur les re-runs).

Sécurité : le service-account.json est gitignored. Ne jamais commit ce fichier.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
from pathlib import Path
from typing import Optional

import firebase_admin
from firebase_admin import credentials, firestore

# ---------------------------------------------------------------------
# Constantes
# ---------------------------------------------------------------------

DEFAULT_SCHOOLS_PATH = Path(__file__).resolve().parent / "data" / "schools.json"

COLLECTION_NAME = "schools"

REQUIRED_FIELDS = {"schoolId", "name", "city", "region", "subSystem", "isValidated"}

ALLOWED_SUB_SYSTEMS = {"francophone", "anglophone", "both"}

SCHOOL_ID_PATTERN = re.compile(r"^school_[a-z0-9_]+$")


# ---------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------

def _validate_schools(matrice: dict) -> None:
    """Valide la matrice JSON avant écriture. Lève ValueError si invalide."""
    if "schools" not in matrice:
        raise ValueError("Clé manquante dans schools.json : 'schools'")
    if not isinstance(matrice["schools"], list):
        raise ValueError(
            f"matrice['schools'] doit être une liste (reçu : {type(matrice['schools']).__name__})"
        )

    seen_ids: set[str] = set()
    for idx, school in enumerate(matrice["schools"]):
        _validate_school(idx, school)
        sid = school["schoolId"]
        if sid in seen_ids:
            raise ValueError(f"schools[{idx}] schoolId dupliqué : '{sid}'")
        seen_ids.add(sid)


def _validate_school(idx: int, school: dict) -> None:
    """Valide un document individuel — champs requis + types + valeurs."""
    if not isinstance(school, dict):
        raise ValueError(
            f"schools[{idx}] doit être un dict (reçu : {type(school).__name__})"
        )

    missing = REQUIRED_FIELDS - set(school.keys())
    if missing:
        raise ValueError(f"schools[{idx}] champs manquants : {sorted(missing)}")

    sid = school["schoolId"]
    if not isinstance(sid, str) or not SCHOOL_ID_PATTERN.match(sid):
        raise ValueError(
            f"schools[{idx}].schoolId invalide : '{sid}' (doit matcher ^school_[a-z0-9_]+$)"
        )

    for field in ("name", "city", "region"):
        value = school[field]
        if not isinstance(value, str) or not value.strip():
            raise ValueError(
                f"schools[{idx}].{field} doit être une string non vide (reçu : {value!r})"
            )

    sub = school["subSystem"]
    if sub not in ALLOWED_SUB_SYSTEMS:
        raise ValueError(
            f"schools[{idx}].subSystem invalide : '{sub}' "
            f"(doit être dans {sorted(ALLOWED_SUB_SYSTEMS)})"
        )

    if not isinstance(school["isValidated"], bool):
        raise ValueError(
            f"schools[{idx}].isValidated doit être un bool (reçu : {type(school['isValidated']).__name__})"
        )


# ---------------------------------------------------------------------
# Firebase init
# ---------------------------------------------------------------------

def _init_firebase(project_id: str, credentials_path: Optional[Path]):
    """Initialise firebase-admin et retourne un client Firestore.

    - Si credentials_path est fourni : auth par service-account JSON.
    - Sinon : Application Default Credentials (gcloud auth application-default login).
    """
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

def _seed_schools(db, schools: list, dry_run: bool) -> tuple[int, int, int]:
    """Écrit (ou simule l'écriture) tous les schools dans Firestore.

    Retourne (total, validated, unvalidated).
    """
    validated = 0
    unvalidated = 0

    for school in schools:
        school_id = school["schoolId"]
        # Payload Firestore : tous les champs sauf schoolId (qui est l'ID du doc).
        payload = {k: v for k, v in school.items() if k != "schoolId"}
        # createdAt posé first-write uniquement. merge=True préserve la valeur
        # existante lors des re-runs (cf. Firestore docs : SERVER_TIMESTAMP
        # n'écrase pas un Timestamp pré-existant via merge).
        if not dry_run:
            payload["createdAt"] = firestore.SERVER_TIMESTAMP

        if dry_run:
            pass
        else:
            db.collection(COLLECTION_NAME).document(school_id).set(payload, merge=True)

        if school["isValidated"]:
            validated += 1
        else:
            unvalidated += 1

    total = len(schools)
    prefix = "[DRY-RUN]" if dry_run else "[OK]"
    print(
        f"{prefix} {COLLECTION_NAME:<17}: {total:3d} docs   "
        f"({validated} validated, {unvalidated} unvalidated)"
    )
    return total, validated, unvalidated


# ---------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Seed idempotent de la collection Firestore schools (Story 1.5.a).",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Exemples :\n"
            "  python seed_schools.py --project valide-edu --dry-run\n"
            "  python seed_schools.py --project valide-edu\n"
            "  python seed_schools.py --project valide-edu --credentials ./service-account.json\n"
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
        help="Valide la matrice + log ce qui serait écrit, sans toucher Firestore.",
    )
    parser.add_argument(
        "--schools",
        type=Path,
        default=DEFAULT_SCHOOLS_PATH,
        help=f"Chemin vers le fichier schools JSON (défaut : {DEFAULT_SCHOOLS_PATH.name} dans data/)",
    )
    args = parser.parse_args()

    # 1. Charger et valider la matrice.
    if not args.schools.exists():
        print(f"[ERROR] Matrice schools introuvable : {args.schools}", file=sys.stderr)
        return 1

    try:
        with args.schools.open("r", encoding="utf-8") as f:
            matrice = json.load(f)
    except json.JSONDecodeError as exc:
        print(f"[ERROR] Matrice JSON invalide : {exc}", file=sys.stderr)
        return 1

    try:
        _validate_schools(matrice)
    except ValueError as exc:
        print(f"[ERROR] Validation schools échouée :\n{exc}", file=sys.stderr)
        return 1

    print(
        f"[OK] Matrice schools chargée : version={matrice.get('version', '?')}, "
        f"generatedAt={matrice.get('generatedAt', '?')}, "
        f"count={len(matrice['schools'])}"
    )

    # 2. Init Firebase (sauf si dry-run).
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
            print(
                f"  → vérifier que le projet '{args.project}' existe et que le compte a le rôle 'Cloud Datastore User'",
                file=sys.stderr,
            )
            return 1

    # 3. Seed schools.
    start = time.perf_counter()
    try:
        total, _, _ = _seed_schools(db, matrice["schools"], args.dry_run)
    except Exception as exc:  # noqa: BLE001
        print(f"[ERROR] Échec seed schools : {exc}", file=sys.stderr)
        return 1

    elapsed = time.perf_counter() - start
    prefix = "[DRY-RUN]" if args.dry_run else "[OK]"
    print(f"\n{prefix} Total: {total} documents en {elapsed:.2f} s.")

    if args.dry_run:
        print("[DRY-RUN] Aucune écriture effectuée. Relance sans --dry-run pour seed réel.")

    return 0


if __name__ == "__main__":
    sys.exit(main())
