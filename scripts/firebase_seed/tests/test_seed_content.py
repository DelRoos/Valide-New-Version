# Story 2.1 — Tests seed_content.py.
#
# Couverts (sans connexion Firestore live) :
#   (1) structure JSON valide — subjects + chapters + lessons + notions
#   (2) champs requis présents dans chaque type de document
#   (3) cross-ref subjectId : validation détecte un ID absent
#   (4) ordres ascendants : chapters/lessons/notions triés par order >= 1
#   (5) dry-run : aucune écriture Firestore (mock db jamais appelé)
#   (6) idempotence : un double-run avec mock ne crée pas de doublons (set merge=True)
#   (7) JSON invalide : _validate_data lève ValueError sur structure cassée
#   (8) contenu bilingue non vide : fr et en renseignés dans au moins 1 lesson

import json
import sys
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import MagicMock, call

import pytest

# Ajouter le répertoire parent dans sys.path pour importer seed_content.
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from seed_content import (
    _validate_data,
    _validate_bilingual_field,
    _seed_content,
)

# -------------------------------------------------------------------------
# Fixture : données démo réelles
# -------------------------------------------------------------------------

DATA_PATH = Path(__file__).resolve().parent.parent / "data" / "content_demo.json"


@pytest.fixture(scope="session")
def demo_data() -> dict:
    with DATA_PATH.open("r", encoding="utf-8") as f:
        return json.load(f)


# -------------------------------------------------------------------------
# (1) Structure JSON valide
# -------------------------------------------------------------------------

def test_json_loads_and_has_subjects(demo_data):
    """Le fichier content_demo.json se charge et contient des subjects."""
    assert "subjects" in demo_data
    assert isinstance(demo_data["subjects"], list)
    assert len(demo_data["subjects"]) >= 2, "Au moins 2 matières requises (AC5)"


# -------------------------------------------------------------------------
# (2) Champs requis présents
# -------------------------------------------------------------------------

def test_required_fields_present(demo_data):
    """Chaque chapter/lesson/notion possède les champs requis."""
    for subject in demo_data["subjects"]:
        assert "subjectId" in subject
        for ch in subject["chapters"]:
            assert "chapterId" in ch
            assert "order" in ch
            assert "title" in ch
            for le in ch["lessons"]:
                assert "lessonId" in le
                assert "order" in le
                assert "title" in le
                assert "content" in le
                for no in le["notions"]:
                    assert "notionId" in no
                    assert "order" in no
                    assert "title" in no


# -------------------------------------------------------------------------
# (3) Cross-ref subjectId : un ID absent fait lever ValueError
# -------------------------------------------------------------------------

def test_validate_subject_refs_raises_on_missing():
    """_validate_subject_refs doit lever ValueError si un subjectId n'existe pas en Firestore."""
    from seed_content import _validate_subject_refs

    fake_data = {
        "subjects": [
            {
                "subjectId": "nonexistent_subject_xyz",
                "chapters": [],
            }
        ]
    }

    mock_db = MagicMock()
    mock_db.collection("subjects").stream.return_value = []

    with pytest.raises(ValueError, match="nonexistent_subject_xyz"):
        _validate_subject_refs(fake_data, mock_db)


# -------------------------------------------------------------------------
# (4) Ordres ascendants et >= 1
# -------------------------------------------------------------------------

def test_orders_are_positive_and_ascending(demo_data):
    """Les champs order sont >= 1 et strictement croissants au sein de chaque parent."""
    for subject in demo_data["subjects"]:
        prev_ch_order = 0
        for ch in subject["chapters"]:
            assert ch["order"] >= 1, f"chapter {ch['chapterId']} order < 1"
            assert ch["order"] > prev_ch_order, f"chapter {ch['chapterId']} order non croissant"
            prev_ch_order = ch["order"]

            prev_le_order = 0
            for le in ch["lessons"]:
                assert le["order"] >= 1, f"lesson {le['lessonId']} order < 1"
                assert le["order"] > prev_le_order, f"lesson {le['lessonId']} order non croissant"
                prev_le_order = le["order"]

                prev_no_order = 0
                for no in le["notions"]:
                    assert no["order"] >= 1, f"notion {no['notionId']} order < 1"
                    assert no["order"] > prev_no_order, f"notion {no['notionId']} order non croissant"
                    prev_no_order = no["order"]


# -------------------------------------------------------------------------
# (5) Dry-run : aucune écriture sur le mock db
# -------------------------------------------------------------------------

def test_dry_run_no_firestore_write(demo_data):
    """En mode dry_run, _seed_content ne doit jamais appeler db.collection(...)."""
    mock_db = MagicMock()
    counts = _seed_content(mock_db, demo_data, dry_run=True)
    mock_db.collection.assert_not_called()
    assert counts["chapters"] >= 8
    assert counts["lessons"] >= 16
    assert counts["notions"] >= 32


# -------------------------------------------------------------------------
# (6) Idempotence : set(merge=True) appelé sur chaque doc (pas add())
# -------------------------------------------------------------------------

def test_seed_calls_set_merge_true(demo_data):
    """_seed_content doit appeler .set(..., merge=True) et jamais .add()."""
    mock_collection = MagicMock()
    mock_doc_ref = MagicMock()
    mock_collection.return_value.document.return_value = mock_doc_ref

    mock_db = MagicMock()
    mock_db.collection.side_effect = lambda name: mock_collection(name)

    _seed_content(mock_db, demo_data, dry_run=False)

    assert mock_doc_ref.set.called, "set() doit être appelé sur chaque document"
    assert mock_doc_ref.add.call_count == 0, "add() ne doit jamais être appelé (idempotence)"

    for set_call in mock_doc_ref.set.call_args_list:
        args, kwargs = set_call
        assert kwargs.get("merge") is True or (len(args) > 1 and args[1] is True), \
            f"set() doit toujours être appelé avec merge=True, got: {set_call}"


# -------------------------------------------------------------------------
# (7) JSON invalide : _validate_data lève ValueError
# -------------------------------------------------------------------------

def test_validate_data_raises_on_missing_subjects():
    with pytest.raises(ValueError, match="subjects"):
        _validate_data({})


def test_validate_data_raises_on_missing_chapter_fields():
    bad_data = {
        "subjects": [
            {
                "subjectId": "francophone_math",
                "chapters": [
                    {"chapterId": "ch01"}  # manque order, title, lessons
                ],
            }
        ]
    }
    with pytest.raises(ValueError):
        _validate_data(bad_data)


# -------------------------------------------------------------------------
# (8) Contenu bilingue non vide
# -------------------------------------------------------------------------

def test_bilingual_content_non_empty(demo_data):
    """Au moins 1 lesson par matière a du contenu FR et EN non vides."""
    for subject in demo_data["subjects"]:
        has_bilingual_lesson = False
        for ch in subject["chapters"]:
            for le in ch["lessons"]:
                if le["content"].get("fr") and le["content"].get("en"):
                    has_bilingual_lesson = True
                    break
            if has_bilingual_lesson:
                break
        assert has_bilingual_lesson, (
            f"subjectId '{subject['subjectId']}' : aucune lesson avec contenu FR+EN non vide"
        )


def test_bilingual_field_raises_on_missing_key():
    """_validate_bilingual_field lève ValueError si fr ou en manque."""
    with pytest.raises(ValueError):
        _validate_bilingual_field("test", {"fr": "texte"})  # manque 'en'

    with pytest.raises(ValueError):
        _validate_bilingual_field("test", {"en": "text"})  # manque 'fr'
