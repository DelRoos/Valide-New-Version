"""Tests pytest pour Story 1.5.a — validation de data/schools.json sans Firestore live.

Exécution :
    cd scripts/firebase_seed
    pytest tests/test_seed_schools.py -v

Tous les tests valident la matrice JSON statique. Aucune connexion Firestore.
"""

import json
import re
import sys
from pathlib import Path

import pytest

# Charger le module seed_schools pour réutiliser son validator.
SCRIPT_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(SCRIPT_DIR))
from seed_schools import (  # noqa: E402
    ALLOWED_SUB_SYSTEMS,
    REQUIRED_FIELDS,
    SCHOOL_ID_PATTERN,
    _validate_schools,
)

SCHOOLS_PATH = SCRIPT_DIR / "data" / "schools.json"


@pytest.fixture(scope="session")
def schools_matrice():
    """Charge la matrice schools une fois par session de tests."""
    with SCHOOLS_PATH.open("r", encoding="utf-8") as f:
        return json.load(f)


@pytest.fixture(scope="session")
def schools(schools_matrice):
    return schools_matrice["schools"]


# =====================================================================
# Test 1 — JSON loads + métadonnées + clé racine schools
# =====================================================================

def test_schools_json_loads(schools_matrice):
    """schools.json se parse et contient les clés racines attendues."""
    assert "version" in schools_matrice
    assert "generatedAt" in schools_matrice
    assert "schools" in schools_matrice
    assert isinstance(schools_matrice["schools"], list)
    assert len(schools_matrice["schools"]) > 0, "Au moins une école attendue"


# =====================================================================
# Test 2 — Tous les schools ont les champs requis
# =====================================================================

def test_schools_has_required_fields(schools):
    """Chaque school a tous les champs requis (REQUIRED_FIELDS)."""
    for idx, school in enumerate(schools):
        missing = REQUIRED_FIELDS - set(school.keys())
        assert not missing, f"schools[{idx}] ({school.get('schoolId', '?')}) champs manquants : {sorted(missing)}"


# =====================================================================
# Test 3 — Unicité des schoolId
# =====================================================================

def test_schools_ids_unique(schools):
    """Aucun schoolId dupliqué dans la matrice."""
    ids = [s["schoolId"] for s in schools]
    duplicates = {sid for sid in ids if ids.count(sid) > 1}
    assert not duplicates, f"schoolId dupliqués : {sorted(duplicates)}"
    assert len(set(ids)) == len(ids)


# =====================================================================
# Test 4 — subSystem dans la liste autorisée
# =====================================================================

def test_schools_subsystem_valid(schools):
    """Chaque school.subSystem est dans {francophone, anglophone, both}."""
    for school in schools:
        sub = school["subSystem"]
        assert sub in ALLOWED_SUB_SYSTEMS, (
            f"schools[{school['schoolId']}].subSystem invalide : '{sub}' "
            f"(attendu : {sorted(ALLOWED_SUB_SYSTEMS)})"
        )


# =====================================================================
# Test 5 — name / city / region non-vides
# =====================================================================

def test_schools_names_non_empty(schools):
    """Chaque school a name, city, region non-vides."""
    for school in schools:
        for field in ("name", "city", "region"):
            value = school[field]
            assert isinstance(value, str), (
                f"schools[{school['schoolId']}].{field} doit être string (reçu {type(value).__name__})"
            )
            assert value.strip(), (
                f"schools[{school['schoolId']}].{field} est vide ou whitespace-only"
            )


# =====================================================================
# Test 6 — schoolId matche le pattern slugifié
# =====================================================================

def test_schools_ids_slugified(schools):
    """Chaque schoolId matche ^school_[a-z0-9_]+$ (slug reproductible)."""
    for school in schools:
        sid = school["schoolId"]
        assert SCHOOL_ID_PATTERN.match(sid), (
            f"schoolId '{sid}' ne matche pas ^school_[a-z0-9_]+$"
        )


# =====================================================================
# Test 7 — Validator du script accepte la matrice complète
# =====================================================================

def test_schools_validator_passes(schools_matrice):
    """_validate_schools() ne lève pas sur la matrice livrée."""
    # Si _validate_schools() lève, le test échoue avec le message d'erreur.
    _validate_schools(schools_matrice)


# =====================================================================
# Test 8 — Couverture des 10 régions camerounaises
# =====================================================================

def test_schools_covers_all_regions(schools):
    """La matrice couvre les 10 régions officielles MINESEC Cameroun."""
    expected_regions = {
        "Adamaoua",
        "Centre",
        "Est",
        "Extreme-Nord",
        "Littoral",
        "Nord",
        "Nord-Ouest",
        "Ouest",
        "Sud",
        "Sud-Ouest",
    }
    found_regions = {s["region"] for s in schools}
    missing = expected_regions - found_regions
    assert not missing, f"Régions absentes du seed V1 : {sorted(missing)}"


# =====================================================================
# Test 9 — Mix subSystem cohérent (francophone majoritaire, anglophone & both présents)
# =====================================================================

def test_schools_subsystem_mix(schools):
    """Le seed contient un mix réaliste : francophone majoritaire + anglophone + both présents."""
    from collections import Counter

    counts = Counter(s["subSystem"] for s in schools)
    assert counts["francophone"] > 0, "Aucune école francophone"
    assert counts["anglophone"] > 0, "Aucune école anglophone"
    assert counts["both"] > 0, "Aucune école bilingue (both)"
    # Le francophone doit être majoritaire (reflète la démographie scolaire Cameroun).
    assert counts["francophone"] > counts["anglophone"], (
        f"francophone ({counts['francophone']}) doit être > anglophone ({counts['anglophone']})"
    )
