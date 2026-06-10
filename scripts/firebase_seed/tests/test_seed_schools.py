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
    ABBREVIATIONS,
    ALLOWED_SUB_SYSTEMS,
    KEYWORD_MIN_LENGTH,
    KEYWORD_PATTERN,
    REQUIRED_FIELDS,
    SCHOOL_ID_PATTERN,
    _generate_keywords,
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


# =====================================================================
# Story 1.5.b — Tests keywords[] (T3)
# =====================================================================

def test_keywords_generated_for_all_schools(schools):
    """Chaque école a un champ keywords[] non-vide (>= 3 tokens)."""
    for school in schools:
        assert "keywords" in school, (
            f"schools[{school['schoolId']}] manque le champ keywords[]"
        )
        assert isinstance(school["keywords"], list), (
            f"schools[{school['schoolId']}].keywords doit être une liste"
        )
        assert len(school["keywords"]) >= 3, (
            f"schools[{school['schoolId']}].keywords doit contenir >= 3 tokens "
            f"(reçu {len(school['keywords'])}) — risque cassé recherche arrayContains"
        )


def test_keywords_lowercase_no_accents(schools):
    """Tous les tokens keywords[] matchent ^[a-z0-9]+$ (no uppercase, no accent)."""
    for school in schools:
        for token in school["keywords"]:
            assert KEYWORD_PATTERN.match(token), (
                f"schools[{school['schoolId']}].keywords token invalide : '{token}' "
                f"(doit matcher ^[a-z0-9]+$)"
            )
            assert len(token) >= KEYWORD_MIN_LENGTH, (
                f"schools[{school['schoolId']}].keywords token trop court : '{token}'"
            )


def test_keywords_contain_normalized_name_tokens(schools):
    """Pour 5 écoles sample, les tokens du nom (normalisés) sont présents dans keywords."""
    samples = [
        # (schoolId pattern, expected token attendu dans keywords)
        ("school_lycee_general_leclerc_yaounde", "leclerc"),
        ("school_lycee_bilingue_bonaberi_douala", "bonaberi"),
        ("school_ghs_buea_town_buea", "buea"),
        ("school_pss_mankon_bamenda", "mankon"),
        ("school_college_vogt_yaounde", "vogt"),
    ]
    for school_id, expected_token in samples:
        school = next((s for s in schools if s["schoolId"] == school_id), None)
        assert school is not None, f"École '{school_id}' introuvable dans le seed"
        assert expected_token in school["keywords"], (
            f"schools[{school_id}].keywords ne contient pas '{expected_token}' "
            f"(reçu : {school['keywords']})"
        )


def test_keywords_contain_city_and_region(schools):
    """Pour chaque école, les tokens normalisés de city sont présents dans keywords.

    Note : une city multi-mots (« Penka-Michel », « Sud-Ouest ») est splittée en
    plusieurs tokens (« penka », « michel ») — on vérifie qu'AU MOINS un token
    normalisé issu de city >= KEYWORD_MIN_LENGTH est présent dans keywords.
    """
    import re
    from unidecode import unidecode

    for school in schools:
        # Tokenise city avec la même pipeline que _generate_keywords.
        city_normalized = unidecode(school["city"]).lower()
        city_cleaned = re.sub(r"[^a-z0-9]+", " ", city_normalized)
        city_tokens = [
            t for t in city_cleaned.split() if len(t) >= KEYWORD_MIN_LENGTH
        ]
        # Au moins un token de city doit être dans keywords.
        intersection = set(city_tokens) & set(school["keywords"])
        assert intersection, (
            f"schools[{school['schoolId']}].keywords ne contient aucun token de city. "
            f"city tokens = {city_tokens}, keywords = {school['keywords']}"
        )


def test_keywords_contain_abbreviations_when_applicable(schools):
    """Les écoles dont le nom contient un pattern ABBREVIATIONS ont l'abréviation dans keywords."""
    from unidecode import unidecode

    for school in schools:
        name_normalized = unidecode(school["name"]).lower()
        for pattern, abbrev in ABBREVIATIONS.items():
            if pattern in name_normalized:
                assert abbrev in school["keywords"], (
                    f"schools[{school['schoolId']}] nom contient '{pattern}' "
                    f"mais keywords ne contient pas '{abbrev}' (reçu : {school['keywords']})"
                )


def test_keywords_deduplicated_and_sorted(schools):
    """Aucun doublon dans keywords + ordre alphabétique (idempotence stable)."""
    for school in schools:
        kws = school["keywords"]
        # Pas de doublon.
        assert len(kws) == len(set(kws)), (
            f"schools[{school['schoolId']}].keywords contient des doublons : {kws}"
        )
        # Trié alphabétiquement.
        assert kws == sorted(kws), (
            f"schools[{school['schoolId']}].keywords n'est pas trié : {kws} != {sorted(kws)}"
        )


def test_generate_keywords_idempotent():
    """_generate_keywords(s) appelée 2× sur le même input retourne le même array (idempotence)."""
    school = {
        "schoolId": "school_test_idempotence",
        "name": "Lycée Bilingue de Test",
        "city": "Douala",
        "region": "Littoral",
        "subSystem": "both",
        "isValidated": True,
    }
    first = _generate_keywords(school)
    second = _generate_keywords(school)
    assert first == second, (
        f"_generate_keywords doit être idempotent. Run 1 = {first}, Run 2 = {second}"
    )


def test_generate_keywords_normalisation_accents():
    """Les accents FR sont normalisés (é→e, è→e, à→a, ô→o, ç→c, etc.)."""
    school = {
        "schoolId": "school_test_accents",
        "name": "Lycée Général d'Étoug-Ébé",
        "city": "Yaoundé",
        "region": "Centre",
        "subSystem": "francophone",
        "isValidated": True,
    }
    kws = _generate_keywords(school)
    # Tous les tokens doivent être ASCII lower-case.
    for token in kws:
        assert KEYWORD_PATTERN.match(token), f"Token avec accent ou non-ASCII : '{token}'"
    # Tokens spécifiques attendus après normalisation.
    assert "lycee" in kws  # Lycée → lycee
    assert "general" in kws  # Général → general
    assert "yaounde" in kws  # Yaoundé → yaounde
    assert "etoug" in kws or "ebe" in kws  # Étoug ou Ébé normalisés


def test_generate_keywords_ghs_abbreviation():
    """Le nom contenant 'Government High School' génère l'abréviation 'ghs'."""
    school = {
        "schoolId": "school_test_ghs",
        "name": "Government High School Test City",
        "city": "Test City",
        "region": "Sud-Ouest",
        "subSystem": "anglophone",
        "isValidated": True,
    }
    kws = _generate_keywords(school)
    assert "ghs" in kws, f"keywords doit contenir 'ghs' (reçu : {kws})"
    assert "government" in kws
    assert "high" in kws
    assert "school" in kws
