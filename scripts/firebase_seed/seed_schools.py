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
from unidecode import unidecode

# ---------------------------------------------------------------------
# Constantes
# ---------------------------------------------------------------------

DEFAULT_SCHOOLS_PATH = Path(__file__).resolve().parent / "data" / "schools.json"

COLLECTION_NAME = "schools"

REQUIRED_FIELDS = {"schoolId", "name", "city", "region", "subSystem", "isValidated"}

ALLOWED_SUB_SYSTEMS = {"francophone", "anglophone", "both"}

SCHOOL_ID_PATTERN = re.compile(r"^school_[a-z0-9_]+$")

# Story 1.5.b — Pattern de validation des keywords (lower-case ASCII + digits).
KEYWORD_PATTERN = re.compile(r"^[a-z0-9]+$")

# Story 1.5.b — Token minimum pour eviter les bruits (« a », « le », « de » trop courts).
KEYWORD_MIN_LENGTH = 2

# Story 1.5.b — Abreviations courantes ecoles camerounaises ajoutees
# automatiquement quand le nom complet est detecte. Permet aux eleves
# de taper « ghs » au lieu de « Government High School ». Patterns case-
# insensitive : on cherche apres normalisation lower-case + sans accents.
ABBREVIATIONS = {
    "government bilingual high school": "gbhs",
    "government high school": "ghs",
    "government technical high school": "gths",
    "government technical bilingual high school": "gtbhs",
    "presbyterian secondary school": "pss",
    "lycee bilingue": "lb",       # alias usage commun
    "comprehensive high school": "chs",
}


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

    # Story 1.5.b — keywords est optionnel jusqu'a generation, mais si present
    # il doit etre une liste de strings lower-case ASCII >= 2 chars uniques.
    if "keywords" in school:
        kws = school["keywords"]
        if not isinstance(kws, list):
            raise ValueError(
                f"schools[{idx}].keywords doit être une liste (reçu : {type(kws).__name__})"
            )
        if len(kws) < 3:
            raise ValueError(
                f"schools[{idx}].keywords doit contenir au moins 3 tokens (reçu : {len(kws)})"
            )
        seen: set[str] = set()
        for token in kws:
            if not isinstance(token, str):
                raise ValueError(
                    f"schools[{idx}].keywords contient un non-string : {token!r}"
                )
            if not KEYWORD_PATTERN.match(token):
                raise ValueError(
                    f"schools[{idx}].keywords token invalide : '{token}' "
                    f"(doit matcher ^[a-z0-9]+$)"
                )
            if len(token) < KEYWORD_MIN_LENGTH:
                raise ValueError(
                    f"schools[{idx}].keywords token trop court : '{token}' "
                    f"(min {KEYWORD_MIN_LENGTH} chars)"
                )
            if token in seen:
                raise ValueError(
                    f"schools[{idx}].keywords token dupliqué : '{token}'"
                )
            seen.add(token)


# ---------------------------------------------------------------------
# Story 1.5.b — Génération des keywords[]
# ---------------------------------------------------------------------

def _generate_keywords(school: dict) -> list[str]:
    """Genere la liste keywords[] d'une ecole.

    Pipeline (deterministe, idempotent) :
      1. Concatenation name + city + region
      2. Lower-case + unidecode (ASCII sans accents)
      3. Remplacement ponctuation par espace
      4. Split sur whitespace + filter mots >= 2 chars
      5. Ajout des abreviations communes detectees (ghs, gbhs, pss, ...)
      6. Dedup + sort alphabetique (idempotence)

    Exemples :
      Lycée Bilingue de Bonaberi / Douala / Littoral
        -> ['bilingue', 'bonaberi', 'de', 'douala', 'lb', 'littoral', 'lycee']
      Government High School Buea Town / Buea / Sud-Ouest
        -> ['buea', 'ghs', 'government', 'high', 'ouest', 'school', 'sud', 'town']
    """
    parts = [school["name"], school["city"], school["region"]]
    text = " ".join(p for p in parts if p)

    # Step 2 + 3 : lower-case + ASCII + nettoyage ponctuation.
    normalized = unidecode(text).lower()
    cleaned = re.sub(r"[^a-z0-9]+", " ", normalized)

    # Step 4 : tokenization + filter longueur.
    tokens = {tok for tok in cleaned.split() if len(tok) >= KEYWORD_MIN_LENGTH}

    # Step 5 : detection des abreviations dans le nom normalise.
    name_normalized = unidecode(school["name"]).lower()
    for pattern, abbrev in ABBREVIATIONS.items():
        if pattern in name_normalized:
            tokens.add(abbrev)

    # Step 6 : sort alphabetique (idempotence stable).
    return sorted(tokens)


def _regenerate_keywords_in_matrice(matrice: dict) -> int:
    """Regenere keywords[] pour toutes les ecoles de la matrice. Retourne le nombre touche."""
    count = 0
    for school in matrice["schools"]:
        school["keywords"] = _generate_keywords(school)
        count += 1
    return count


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
    parser.add_argument(
        "--regen-keywords",
        action="store_true",
        help="Story 1.5.b — Regenere le champ keywords[] pour toutes les écoles "
             "(lower-case + sans accents + abreviations communes). En mode --dry-run, "
             "affiche les keywords générés pour 5 ecoles sample sans modifier le JSON. "
             "Sans --dry-run, ré-écrit data/schools.json avec keywords[] mis à jour.",
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

    # Story 1.5.b — regenere keywords[] avant validation (les nouveaux keywords
    # doivent passer la validation s'ils n'etaient pas conformes avant).
    if args.regen_keywords:
        count = _regenerate_keywords_in_matrice(matrice)
        prefix = "[DRY-RUN]" if args.dry_run else "[OK]"
        print(f"{prefix} keywords[] regenere pour {count} ecoles")
        # En mode dry-run, on affiche 5 samples pour inspection.
        if args.dry_run:
            print(f"[DRY-RUN] Sample des keywords generes (5 premieres ecoles) :")
            for school in matrice["schools"][:5]:
                print(f"  {school['schoolId']:<55} keywords={school['keywords']}")

    try:
        _validate_schools(matrice)
    except ValueError as exc:
        print(f"[ERROR] Validation schools échouée :\n{exc}", file=sys.stderr)
        return 1

    # Story 1.5.b — si --regen-keywords sans --dry-run, ecrire le JSON mis a jour.
    if args.regen_keywords and not args.dry_run:
        with args.schools.open("w", encoding="utf-8") as f:
            json.dump(matrice, f, ensure_ascii=False, indent=2)
            f.write("\n")
        print(f"[OK] Matrice schools réécrite avec keywords[] : {args.schools}")

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
