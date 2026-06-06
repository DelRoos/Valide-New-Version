"""
seed_catalogue.py — Story 1.1b (Valide School).

Seed idempotent du catalogue scolaire dans Firestore (6 collections) à partir
d'une matrice JSON versionnée.

Usage :
    # Auth via Application Default Credentials (recommandé : gcloud auth application-default login)
    python seed_catalogue.py --project valide-edu

    # Auth via service-account JSON (CI/CD ou serveur partagé)
    python seed_catalogue.py --project valide-edu --credentials ./service-account.json

    # Dry-run : valide la matrice + log ce qui serait écrit, sans toucher Firestore
    python seed_catalogue.py --project valide-edu --dry-run

Schéma Firestore : doc/partage/BASE-DE-DONNEES.md § Catalogue scolaire.
Matrice source   : doc/partage/DONNEES-REFERENCE.md § Tableau de dérivation.
ADR              : project_manage/planning-artifacts/architecture/adrs/ADR-015.

Idempotence : utilise set(merge=True) partout (jamais add()). Un re-run avec
la même matrice produit le même état Firestore. Modifier matrice.json + re-run
pour propager des évolutions.

Sécurité : le service-account.json est gitignored au niveau racine du dépôt
ET au niveau dossier (.gitignore local). Ne jamais commit ce fichier ni
logger son contenu.
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

# ---------------------------------------------------------------------
# Constantes
# ---------------------------------------------------------------------

DEFAULT_MATRICE_PATH = Path(__file__).resolve().parent / "data" / "matrice.json"

# Ordre d'écriture des collections (dépendances logiques montantes).
COLLECTION_ORDER = (
    "filieres",
    "niveaux",
    "series",
    "subjects",
    "exam_targets",
    "derivation_rules",
)

# Mapping collection → champ ID extrait du doc avant écriture.
ID_FIELD = {
    "filieres": "filiereId",
    "niveaux": "niveauId",
    "series": "serieId",
    "subjects": "subjectId",
    "exam_targets": "examTargetId",
    "derivation_rules": "ruleId",
}

# Champs requis minimum par collection (pour validation pré-écriture).
REQUIRED_FIELDS = {
    "filieres":         {"filiereId", "name", "isActive", "sortOrder"},
    "niveaux":          {"niveauId", "subSystem", "name", "filiereIds", "isActive", "sortOrder"},
    "series":           {"serieId", "subSystem", "niveauId", "filiereId", "name", "canOptOut", "isActive", "sortOrder"},
    "subjects":         {"subjectId", "subSystem", "name", "icon", "isActive", "sortOrder"},
    "exam_targets":     {"examTargetId", "subSystem", "name", "isActive", "sortOrder"},
    "derivation_rules": {"ruleId", "matchSubSystem", "matchFiliere", "matchNiveau", "subjectIds", "examTargetIds", "canOptOut", "isActive"},
    # matchSerie est requis (nullable) — vérifié séparément dans _validate_doc().
}


# ---------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------

def _validate_matrice(matrice: dict) -> None:
    """Valide la matrice JSON avant écriture. Lève ValueError si invalide."""
    # Présence des 6 clés racines.
    for coll in COLLECTION_ORDER:
        if coll not in matrice:
            raise ValueError(f"Clé manquante dans matrice.json : '{coll}'")
        if not isinstance(matrice[coll], list):
            raise ValueError(f"matrice['{coll}'] doit être une liste (reçu : {type(matrice[coll]).__name__})")

    # Validation par doc.
    for coll in COLLECTION_ORDER:
        for idx, doc in enumerate(matrice[coll]):
            _validate_doc(coll, idx, doc)

    # Validation référentielle : les derivation_rules pointent vers des IDs existants.
    _validate_references(matrice)


def _validate_doc(coll: str, idx: int, doc: dict) -> None:
    """Valide un document individuel — champs requis + types basiques."""
    if not isinstance(doc, dict):
        raise ValueError(f"{coll}[{idx}] doit être un dict (reçu : {type(doc).__name__})")

    required = REQUIRED_FIELDS[coll]
    missing = required - set(doc.keys())
    if missing:
        raise ValueError(f"{coll}[{idx}] champs manquants : {sorted(missing)}")

    # derivation_rules.matchSerie est requis mais nullable.
    if coll == "derivation_rules" and "matchSerie" not in doc:
        raise ValueError(f"derivation_rules[{idx}] champ manquant : 'matchSerie' (peut être null)")

    # name doit être un dict {fr, en} pour les 5 collections qui ont un name.
    if "name" in doc:
        name = doc["name"]
        if not isinstance(name, dict) or "fr" not in name or "en" not in name:
            raise ValueError(f"{coll}[{idx}].name doit être un dict {{fr, en}} (reçu : {name!r})")


def _validate_references(matrice: dict) -> None:
    """Vérifie que toutes les références dans derivation_rules pointent vers des IDs existants."""
    filiere_ids = {d["filiereId"] for d in matrice["filieres"]}
    niveau_ids = {d["niveauId"] for d in matrice["niveaux"]}
    serie_ids = {d["serieId"] for d in matrice["series"]}
    subject_ids = {d["subjectId"] for d in matrice["subjects"]}
    exam_target_ids = {d["examTargetId"] for d in matrice["exam_targets"]}

    errors = []
    for rule in matrice["derivation_rules"]:
        rid = rule["ruleId"]
        # matchFiliere : "*" wildcard accepté, sinon doit exister.
        if rule["matchFiliere"] != "*" and rule["matchFiliere"] not in filiere_ids:
            errors.append(f"{rid}.matchFiliere = '{rule['matchFiliere']}' (inexistant)")
        # matchNiveau : doit exister.
        if rule["matchNiveau"] not in niveau_ids:
            errors.append(f"{rid}.matchNiveau = '{rule['matchNiveau']}' (inexistant)")
        # matchSerie : null OK, sinon doit exister.
        if rule["matchSerie"] is not None and rule["matchSerie"] not in serie_ids:
            errors.append(f"{rid}.matchSerie = '{rule['matchSerie']}' (inexistant)")
        # subjectIds : tous doivent exister.
        for sid in rule["subjectIds"]:
            if sid not in subject_ids:
                errors.append(f"{rid}.subjectIds référence '{sid}' (inexistant)")
        # examTargetIds : tous doivent exister.
        for eid in rule["examTargetIds"]:
            if eid not in exam_target_ids:
                errors.append(f"{rid}.examTargetIds référence '{eid}' (inexistant)")

    if errors:
        raise ValueError("Références invalides dans derivation_rules :\n  - " + "\n  - ".join(errors))


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

def _seed_collection(db, coll_name: str, docs: list, dry_run: bool) -> tuple[int, int, int]:
    """Écrit (ou simule l'écriture) tous les docs d'une collection.

    Retourne (total, active, inactive).
    """
    id_field = ID_FIELD[coll_name]
    active = 0
    inactive = 0

    for doc in docs:
        doc_id = doc[id_field]
        payload = {k: v for k, v in doc.items() if k != id_field}

        if dry_run:
            # Pas d'écriture, juste comptage.
            pass
        else:
            db.collection(coll_name).document(doc_id).set(payload, merge=True)

        if doc.get("isActive", False):
            active += 1
        else:
            inactive += 1

    total = len(docs)
    prefix = "[DRY-RUN]" if dry_run else "[OK]"
    # Padding pour alignement visuel (16 cars max pour les noms de collection).
    print(f"{prefix} {coll_name:<17}: {total:3d} docs   ({active} active, {inactive} inactive)")
    return total, active, inactive


# ---------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Seed idempotent du catalogue scolaire Firestore (Story 1.1b).",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Exemples :\n"
            "  python seed_catalogue.py --project valide-edu --dry-run\n"
            "  python seed_catalogue.py --project valide-edu\n"
            "  python seed_catalogue.py --project valide-edu --credentials ./service-account.json\n"
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
        "--matrice",
        type=Path,
        default=DEFAULT_MATRICE_PATH,
        help=f"Chemin vers le fichier matrice JSON (défaut : {DEFAULT_MATRICE_PATH.name} dans data/)",
    )
    args = parser.parse_args()

    # 1. Charger et valider la matrice.
    if not args.matrice.exists():
        print(f"[ERROR] Matrice introuvable : {args.matrice}", file=sys.stderr)
        return 1

    try:
        with args.matrice.open("r", encoding="utf-8") as f:
            matrice = json.load(f)
    except json.JSONDecodeError as exc:
        print(f"[ERROR] Matrice JSON invalide : {exc}", file=sys.stderr)
        return 1

    try:
        _validate_matrice(matrice)
    except ValueError as exc:
        print(f"[ERROR] Validation matrice échouée :\n{exc}", file=sys.stderr)
        return 1

    print(f"[OK] Matrice chargée : version={matrice.get('version', '?')}, generatedAt={matrice.get('generatedAt', '?')}")

    # 2. Init Firebase (sauf si dry-run et matrice OK — on garde l'init pour valider l'auth aussi).
    if args.dry_run:
        print("[DRY-RUN] Init Firebase sautée — pas d'écriture.")
        db = None
    else:
        try:
            db = _init_firebase(args.project, args.credentials)
        except Exception as exc:  # noqa: BLE001 — capture large volontaire pour message clair
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

    # 3. Seed collections dans l'ordre.
    start = time.perf_counter()
    grand_total = 0
    for coll_name in COLLECTION_ORDER:
        try:
            total, _, _ = _seed_collection(db, coll_name, matrice[coll_name], args.dry_run)
            grand_total += total
        except Exception as exc:  # noqa: BLE001
            print(f"[ERROR] Échec seed collection '{coll_name}' : {exc}", file=sys.stderr)
            return 1

    elapsed = time.perf_counter() - start
    prefix = "[DRY-RUN]" if args.dry_run else "[OK]"
    print(f"\n{prefix} Total: {grand_total} documents en {elapsed:.2f} s.")

    if args.dry_run:
        print("[DRY-RUN] Aucune écriture effectuée. Relance sans --dry-run pour seed réel.")

    return 0


if __name__ == "__main__":
    sys.exit(main())
