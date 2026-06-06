"""Tests pytest pour Story 1.1b — validation de data/matrice.json sans Firestore live.

Exécution :
    cd scripts/firebase_seed
    pytest tests/ -v

Tous les tests valident la matrice JSON statique. Aucune connexion Firestore.
"""

import json
import re
import sys
from pathlib import Path

import pytest

# Charger le module seed_catalogue pour réutiliser son validator.
SCRIPT_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(SCRIPT_DIR))
from seed_catalogue import (  # noqa: E402
    COLLECTION_ORDER,
    ID_FIELD,
    _validate_matrice,
)

MATRICE_PATH = SCRIPT_DIR / "data" / "matrice.json"


@pytest.fixture(scope="session")
def matrice():
    """Charge la matrice une fois par session de tests."""
    with MATRICE_PATH.open("r", encoding="utf-8") as f:
        return json.load(f)


# =====================================================================
# Test 1 — JSON valide + 6 clés racines + validator script OK
# =====================================================================

def test_matrice_json_is_valid(matrice):
    """matrice.json se parse et contient les 6 clés racines attendues."""
    # Clés metadata.
    assert "version" in matrice
    assert "generatedAt" in matrice

    # Les 6 collections.
    for coll in COLLECTION_ORDER:
        assert coll in matrice, f"clé '{coll}' manquante"
        assert isinstance(matrice[coll], list), f"matrice['{coll}'] doit être une liste"
        assert len(matrice[coll]) > 0, f"matrice['{coll}'] est vide"

    # Le validator du script doit accepter la matrice.
    # _validate_matrice lève ValueError si invalide.
    _validate_matrice(matrice)


# =====================================================================
# Test 2 — IDs respectent la convention de nommage
# =====================================================================

ID_PATTERNS = {
    "filieres":         re.compile(r"^[a-z][a-z_0-9]*$"),
    "niveaux":          re.compile(r"^(francophone|anglophone)_[a-z0-9][a-z_0-9]*$"),
    "series":           re.compile(r"^(francophone|anglophone)_[a-z0-9][a-z_0-9]*_[a-z0-9][a-z_0-9]*$"),
    "subjects":         re.compile(r"^(francophone|anglophone)_[a-z][a-z_0-9]*$"),
    "exam_targets":     re.compile(r"^exam_[a-z][a-z_0-9]*$"),
    "derivation_rules": re.compile(r"^rule_(francophone|anglophone)_[a-z0-9][a-z_0-9]*$"),
}


def test_ids_follow_convention(matrice):
    """Chaque doc respecte la convention de nommage IDs (snake_case + préfixes)."""
    for coll, pattern in ID_PATTERNS.items():
        id_field = ID_FIELD[coll]
        for doc in matrice[coll]:
            doc_id = doc[id_field]
            assert pattern.match(doc_id), (
                f"{coll}/{doc_id} ne respecte pas la convention {pattern.pattern}"
            )


# =====================================================================
# Test 3 — Pas de doublon d'ID par collection
# =====================================================================

def test_no_duplicate_ids_in_collection(matrice):
    """Pour chaque collection, tous les IDs sont uniques."""
    for coll in COLLECTION_ORDER:
        id_field = ID_FIELD[coll]
        ids = [doc[id_field] for doc in matrice[coll]]
        duplicates = {x for x in ids if ids.count(x) > 1}
        assert not duplicates, f"{coll} contient des IDs dupliqués : {sorted(duplicates)}"


# =====================================================================
# Test 4 — Toutes les références des derivation_rules sont valides
# =====================================================================

def test_derivation_rules_references_are_valid(matrice):
    """Chaque rule pointe vers des IDs réellement présents dans les autres collections."""
    filiere_ids = {d["filiereId"] for d in matrice["filieres"]}
    niveau_ids = {d["niveauId"] for d in matrice["niveaux"]}
    serie_ids = {d["serieId"] for d in matrice["series"]}
    subject_ids = {d["subjectId"] for d in matrice["subjects"]}
    exam_target_ids = {d["examTargetId"] for d in matrice["exam_targets"]}

    for rule in matrice["derivation_rules"]:
        rid = rule["ruleId"]

        # matchFiliere : "*" wildcard OU id existant.
        assert rule["matchFiliere"] == "*" or rule["matchFiliere"] in filiere_ids, (
            f"{rid}.matchFiliere = '{rule['matchFiliere']}' (inexistant)"
        )
        # matchNiveau : doit exister.
        assert rule["matchNiveau"] in niveau_ids, (
            f"{rid}.matchNiveau = '{rule['matchNiveau']}' (inexistant)"
        )
        # matchSerie : null OU id existant.
        if rule["matchSerie"] is not None:
            assert rule["matchSerie"] in serie_ids, (
                f"{rid}.matchSerie = '{rule['matchSerie']}' (inexistant)"
            )
        # subjectIds : tous doivent exister.
        for sid in rule["subjectIds"]:
            assert sid in subject_ids, f"{rid}.subjectIds référence '{sid}' (inexistant)"
        # examTargetIds : tous doivent exister.
        for eid in rule["examTargetIds"]:
            assert eid in exam_target_ids, f"{rid}.examTargetIds référence '{eid}' (inexistant)"


# =====================================================================
# Test 5 (bonus) — Cohérence canOptOut entre series et derivation_rules
# =====================================================================

def test_canoptout_coherent_between_series_and_rules(matrice):
    """Quand une rule cite une serie, son canOptOut doit matcher la serie.canOptOut."""
    serie_optout = {d["serieId"]: d["canOptOut"] for d in matrice["series"]}

    for rule in matrice["derivation_rules"]:
        if rule["matchSerie"] is None:
            continue
        rid = rule["ruleId"]
        serie_id = rule["matchSerie"]
        assert rule["canOptOut"] == serie_optout[serie_id], (
            f"{rid}.canOptOut={rule['canOptOut']} != "
            f"series/{serie_id}.canOptOut={serie_optout[serie_id]}"
        )


# =====================================================================
# Test 6 (bonus) — Tous les name.fr / name.en sont des strings non vides
# =====================================================================

def test_all_bilingual_names_are_non_empty_strings(matrice):
    """name.fr et name.en sont présents et non vides pour les 5 collections concernées."""
    for coll in ("filieres", "niveaux", "series", "subjects", "exam_targets"):
        for doc in matrice[coll]:
            doc_id = doc[ID_FIELD[coll]]
            assert isinstance(doc["name"], dict), f"{coll}/{doc_id}.name doit être un dict"
            assert isinstance(doc["name"].get("fr"), str) and doc["name"]["fr"].strip(), (
                f"{coll}/{doc_id}.name.fr vide ou absent"
            )
            assert isinstance(doc["name"].get("en"), str) and doc["name"]["en"].strip(), (
                f"{coll}/{doc_id}.name.en vide ou absent"
            )
