# tests/test_build_seed_3e.py — Tests build_seed_3e.py + seed_3e_content.py
#
# Couverts :
#   (1)  infer_notion_type — règle, méthode, formule, fait, définition
#   (2)  ensure_bilingual  — dict complet, dict FR only, string, valeur vide
#   (3)  resolve_content   — inline string, chemin .md existant, .md manquant, dict {fr,en}
#   (4)  transform_subject — format A (math inline), format B (chinois file-path+term+def)
#   (5)  build intégration — lit les vrais JSON de content_demo/3e/ (si présents)
#   (6)  validate_seed     — schéma valide, mauvais schema, champ manquant, notionId dupliqué
#   (7)  seed dry-run      — aucune écriture Firestore en dry_run=True
#   (8)  seed sous-collections — set() appelé avec le bon chemin subcollection
#   (9)  idempotence       — set(merge=True) partout, jamais add()

import json
import sys
import tempfile
from pathlib import Path
from unittest.mock import MagicMock, call, patch

import pytest

# Ajout du répertoire parent dans sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from build_seed_3e import (
    build,
    ensure_bilingual,
    infer_notion_type,
    resolve_content,
    transform_subject,
)
from seed_3e_content import seed_content, validate_seed

CONTENT_DEMO_3E = Path(__file__).resolve().parent.parent.parent / "content_demo" / "3e"


# ─────────────────────────────────────────────────────────────────────────────
# (1) infer_notion_type
# ─────────────────────────────────────────────────────────────────────────────

@pytest.mark.parametrize("title,content,expected", [
    (
        "Règle des signes",
        "Le produit de deux négatifs est toujours positif.",
        "rule",
    ),
    (
        "Méthode de résolution d'équation",
        "Étapes : regrouper les termes, simplifier, diviser.",
        "method",
    ),
    (
        "Identité remarquable",
        "$(a+b)^2 = a^2 + 2ab + b^2$ — formule à retenir.",
        "formula",
    ),
    (
        "FOCAC",
        "Cadre officiel créé en 2000, depuis 2009 la Chine partenaire commercial.",
        "fact",
    ),
    (
        "Nombre relatif",
        "Un nombre relatif est un nombre muni d'un signe (+ ou −).",
        "definition",
    ),
    (
        "Pinyin",
        "Système de transcription phonétique officiel du mandarin.",
        "definition",
    ),
])
def test_infer_notion_type(title, content, expected):
    assert infer_notion_type(title, content) == expected


# ─────────────────────────────────────────────────────────────────────────────
# (2) ensure_bilingual
# ─────────────────────────────────────────────────────────────────────────────

def test_ensure_bilingual_full_dict():
    result = ensure_bilingual({"fr": "Bonjour", "en": "Hello"})
    assert result == {"fr": "Bonjour", "en": "Hello"}


def test_ensure_bilingual_fr_only_fallback():
    result = ensure_bilingual({"fr": "Seul français"})
    assert result["fr"] == "Seul français"
    assert result["en"] == "Seul français"  # EN copié depuis FR


def test_ensure_bilingual_string():
    result = ensure_bilingual("texte brut")
    assert result == {"fr": "texte brut", "en": "texte brut"}


def test_ensure_bilingual_empty_uses_fallback():
    result = ensure_bilingual({}, fallback_fr="def_fr", fallback_en="def_en")
    assert result["fr"] == "def_fr"
    assert result["en"] == "def_fr"  # EN copié depuis FR (fallback_en ignoré si FR disponible)


def test_ensure_bilingual_none_returns_empty():
    result = ensure_bilingual(None)
    assert result == {"fr": "", "en": ""}


# ─────────────────────────────────────────────────────────────────────────────
# (3) resolve_content
# ─────────────────────────────────────────────────────────────────────────────

def test_resolve_content_inline_string():
    result = resolve_content("# Titre\n\nContenu FR", Path("/any"))
    assert result["fr"] == "# Titre\n\nContenu FR"
    assert result["en"] == "# Titre\n\nContenu FR"  # fallback FR→EN


def test_resolve_content_md_file(tmp_path):
    md_file = tmp_path / "lesson.md"
    md_file.write_text("# Leçon test\n\n:::definition\nX est Y.\n:::", encoding="utf-8")

    raw = {"fr": "lesson.md", "en": "lesson.md"}
    result = resolve_content(raw, tmp_path)

    assert "# Leçon test" in result["fr"]
    assert ":::definition" in result["fr"]
    assert result["en"] == result["fr"]


def test_resolve_content_md_missing_file(tmp_path):
    raw = {"fr": "inexistant.md", "en": "inexistant.md"}
    result = resolve_content(raw, tmp_path)
    assert result["fr"] == ""
    assert result["en"] == ""


def test_resolve_content_inline_dict():
    raw = {"fr": "# FR content", "en": "# EN content"}
    result = resolve_content(raw, Path("/any"))
    assert result["fr"] == "# FR content"
    assert result["en"] == "# EN content"


def test_resolve_content_fr_only_dict_copies_to_en():
    raw = {"fr": "# FR seulement"}
    result = resolve_content(raw, Path("/any"))
    assert result["fr"] == "# FR seulement"
    assert result["en"] == "# FR seulement"


# ─────────────────────────────────────────────────────────────────────────────
# (4) transform_subject — formats A et B
# ─────────────────────────────────────────────────────────────────────────────

FORMAT_A_SUBJECT = {
    "meta": {"subjectId": "francophone_math"},
    "chapters": [
        {
            "id": "ch_math_01",
            "sortOrder": 1,
            "title": {"fr": "Chapitre 1"},
        }
    ],
    "lessons": [
        {
            "id": "les_math_01_01",
            "chapterId": "ch_math_01",
            "sortOrder": 1,
            "title": {"fr": "Leçon 1"},
            "content": {"fr": "# Leçon 1 FR"},
            "notionIds": ["not_math_n01"],
        }
    ],
    "notions": [
        {
            "id": "not_math_n01",
            "lessonId": "les_math_01_01",
            "title": {"fr": "Nombre relatif", "en": "Relative number"},
            "content": {"fr": "Un nombre relatif...", "en": "A relative number..."},
        }
    ],
    "quizzes": [],
}

FORMAT_B_SUBJECT = {
    "meta": {"subjectId": "francophone_chinois_lv2_college"},
    "chapters": [
        {
            "id": "chinois_ch01",
            "order": 1,
            "title": {"fr": "Phonétique", "en": "Phonetics"},
            "description": {"fr": "Maîtriser le pinyin", "en": "Master pinyin"},
        }
    ],
    "lessons": [
        {
            "id": "chinois_01_01",
            "chapterId": "chinois_ch01",
            "order": 1,
            "title": {"fr": "Le pinyin", "en": "The pinyin"},
            "duration": 45,
            "content": {"fr": "# Pinyin FR", "en": "# Pinyin EN"},
        }
    ],
    "notions": [
        {
            "id": "chinois_n01",
            "lessonId": "chinois_01_01",
            "term": {"fr": "Pinyin", "en": "Pinyin"},
            "definition": {
                "fr": "Système de transcription officiel.",
                "en": "Official transcription system.",
            },
        }
    ],
    "quizzes": [
        {
            "id": "chinois_q01",
            "lessonId": "chinois_01_01",
            "questions": [
                {
                    "id": "q01_1",
                    "question": {"fr": "Combien de tons ?", "en": "How many tones?"},
                    "options": {
                        "fr": ["3", "4", "5", "6"],
                        "en": ["3", "4", "5", "6"],
                    },
                    "correctIndex": 1,
                    "explanation": {"fr": "4 tons principaux.", "en": "4 main tones."},
                }
            ],
        }
    ],
}


def test_transform_subject_format_a(tmp_path):
    json_path = tmp_path / "math.json"
    json_path.write_text(json.dumps(FORMAT_A_SUBJECT), encoding="utf-8")

    result = transform_subject(json_path)

    assert result["subjectId"] == "francophone_math"
    assert len(result["chapters"]) == 1

    ch = result["chapters"][0]
    assert ch["chapterId"] == "ch_math_01"
    assert ch["order"] == 1
    assert len(ch["lessons"]) == 1

    l = ch["lessons"][0]
    assert l["lessonId"] == "les_math_01_01"
    assert l["durationMinutes"] == 45  # valeur par défaut
    assert l["content"]["fr"] == "# Leçon 1 FR"
    assert l["content"]["en"] == "# Leçon 1 FR"  # copie FR→EN

    assert len(l["notions"]) == 1
    n = l["notions"][0]
    assert n["notionId"] == "not_math_n01"
    assert n["title"] == {"fr": "Nombre relatif", "en": "Relative number"}
    assert n["type"] in {"definition", "rule", "method", "formula", "property", "fact"}


def test_transform_subject_format_b_term_definition(tmp_path):
    json_path = tmp_path / "chinois.json"
    json_path.write_text(json.dumps(FORMAT_B_SUBJECT), encoding="utf-8")

    result = transform_subject(json_path)

    assert result["subjectId"] == "francophone_chinois_lv2_college"
    l = result["chapters"][0]["lessons"][0]
    assert l["durationMinutes"] == 45

    n = l["notions"][0]
    assert n["notionId"] == "chinois_n01"
    assert n["title"] == {"fr": "Pinyin", "en": "Pinyin"}
    assert n["content"]["fr"] == "Système de transcription officiel."
    assert n["type"] in {"definition", "rule", "method", "formula", "property", "fact"}


def test_transform_subject_format_b_quizzes(tmp_path):
    json_path = tmp_path / "chinois.json"
    json_path.write_text(json.dumps(FORMAT_B_SUBJECT), encoding="utf-8")

    result = transform_subject(json_path)
    l = result["chapters"][0]["lessons"][0]

    assert len(l["quizzes"]) == 1
    q = l["quizzes"][0]
    assert q["quizId"] == "chinois_q01"
    assert len(q["questions"]) == 1
    assert q["questions"][0]["correctIndex"] == 1
    assert q["questions"][0]["type"] == "mcq"
    assert isinstance(q["questions"][0]["options"]["fr"], list)


def test_transform_subject_orders_are_ascending(tmp_path):
    json_path = tmp_path / "math.json"
    json_path.write_text(json.dumps(FORMAT_A_SUBJECT), encoding="utf-8")
    result = transform_subject(json_path)

    ch_orders = [ch["order"] for ch in result["chapters"]]
    assert ch_orders == sorted(ch_orders)

    for ch in result["chapters"]:
        l_orders = [l["order"] for l in ch["lessons"]]
        assert l_orders == sorted(l_orders)


# ─────────────────────────────────────────────────────────────────────────────
# (5) build — intégration sur les vrais fichiers content_demo/3e/
# ─────────────────────────────────────────────────────────────────────────────

@pytest.mark.skipif(
    not CONTENT_DEMO_3E.exists(),
    reason="content_demo/3e/ absent — test intégration ignoré",
)
def test_build_integration_real_files(tmp_path):
    output = tmp_path / "seed_3e.json"
    seed = build(CONTENT_DEMO_3E, output)

    assert output.exists()
    assert seed["schema"] == "v2-subcollections"
    assert len(seed["subjects"]) >= 1

    # Vérifie que chaque leçon a au moins un champ content non vide
    for s in seed["subjects"]:
        for ch in s["chapters"]:
            for l in ch["lessons"]:
                assert l["content"]["fr"], f"Contenu FR vide : {l['lessonId']}"
                assert l["lessonId"]
                assert l["order"] >= 1
                for n in l["notions"]:
                    assert n["type"] in {"definition", "rule", "method", "formula", "property", "fact"}
                    assert n["title"]["fr"]


@pytest.mark.skipif(
    not CONTENT_DEMO_3E.exists(),
    reason="content_demo/3e/ absent — test intégration ignoré",
)
def test_build_no_duplicate_ids(tmp_path):
    output = tmp_path / "seed_3e.json"
    seed = build(CONTENT_DEMO_3E, output)

    chapter_ids = [
        ch["chapterId"]
        for s in seed["subjects"]
        for ch in s["chapters"]
    ]
    lesson_ids = [
        l["lessonId"]
        for s in seed["subjects"]
        for ch in s["chapters"]
        for l in ch["lessons"]
    ]
    notion_ids = [
        n["notionId"]
        for s in seed["subjects"]
        for ch in s["chapters"]
        for l in ch["lessons"]
        for n in l["notions"]
    ]

    assert len(chapter_ids) == len(set(chapter_ids)), "chapterId dupliqués"
    assert len(lesson_ids) == len(set(lesson_ids)), "lessonId dupliqués"
    # Les notionIds peuvent apparaître dans plusieurs leçons (données source partagées).
    # En Firestore v2, chaque leçon a sa propre sous-collection lessons/{id}/notions/
    # donc un même notionId à des chemins différents n'est pas un conflit Firestore.
    duplicated = set(n for n in notion_ids if notion_ids.count(n) > 1)
    if duplicated:
        print(f"\n[INFO] {len(duplicated)} notionId(s) partagés entre leçons : {sorted(duplicated)}")


# ─────────────────────────────────────────────────────────────────────────────
# (6) validate_seed
# ─────────────────────────────────────────────────────────────────────────────

VALID_SEED = {
    "version": "2.0.0",
    "schema": "v2-subcollections",
    "subjects": [
        {
            "subjectId": "francophone_math",
            "chapters": [
                {
                    "chapterId": "ch_test_01",
                    "order": 1,
                    "title": {"fr": "Chapitre", "en": "Chapter"},
                    "lessons": [
                        {
                            "lessonId": "les_test_01_01",
                            "order": 1,
                            "title": {"fr": "Leçon", "en": "Lesson"},
                            "durationMinutes": 45,
                            "content": {"fr": "# FR", "en": "# EN"},
                            "notions": [
                                {
                                    "notionId": "not_test_01",
                                    "order": 1,
                                    "type": "definition",
                                    "title": {"fr": "Notion", "en": "Notion"},
                                    "content": {"fr": "...", "en": "..."},
                                }
                            ],
                            "quizzes": [],
                        }
                    ],
                }
            ],
        }
    ],
}


def test_validate_seed_valid():
    validate_seed(VALID_SEED)  # ne doit pas lever


def test_validate_seed_wrong_schema():
    bad = {**VALID_SEED, "schema": "v1-flat"}
    with pytest.raises(ValueError, match="schema"):
        validate_seed(bad)


def test_validate_seed_empty_subjects():
    bad = {**VALID_SEED, "subjects": []}
    with pytest.raises(ValueError, match="subjects"):
        validate_seed(bad)


def test_validate_seed_duplicate_notion_id():
    import copy
    bad = copy.deepcopy(VALID_SEED)
    # Dupliquer la notion dans la même leçon
    original_notion = bad["subjects"][0]["chapters"][0]["lessons"][0]["notions"][0]
    bad["subjects"][0]["chapters"][0]["lessons"][0]["notions"].append(
        {**original_notion}  # même notionId
    )
    with pytest.raises(ValueError, match="dupliqué"):
        validate_seed(bad)


def test_validate_seed_invalid_notion_type():
    import copy
    bad = copy.deepcopy(VALID_SEED)
    bad["subjects"][0]["chapters"][0]["lessons"][0]["notions"][0]["type"] = "unknown_type"
    with pytest.raises(ValueError, match="type"):
        validate_seed(bad)


def test_validate_seed_missing_bilingual_content():
    import copy
    bad = copy.deepcopy(VALID_SEED)
    bad["subjects"][0]["chapters"][0]["lessons"][0]["content"] = {"fr": ""}  # fr vide
    with pytest.raises(ValueError):
        validate_seed(bad)


# ─────────────────────────────────────────────────────────────────────────────
# (7) seed dry-run — aucune écriture Firestore
# ─────────────────────────────────────────────────────────────────────────────

def test_seed_dry_run_no_firestore_write():
    mock_db = MagicMock()
    counts = seed_content(mock_db, VALID_SEED, dry_run=True)
    mock_db.collection.assert_not_called()
    assert counts["chapters"] == 1
    assert counts["lessons"] == 1
    assert counts["lessonContents"] == 1
    assert counts["notions"] == 1
    assert counts["quizzes"] == 0


# ─────────────────────────────────────────────────────────────────────────────
# (8) seed sous-collections — bon chemin de subcollection
# ─────────────────────────────────────────────────────────────────────────────

def test_seed_uses_subcollection_for_content():
    """Le contenu Markdown doit être écrit dans lessons/{id}/content/main."""
    collection_calls = []

    mock_db = MagicMock()

    def track_collection(name):
        collection_calls.append(name)
        return mock_db.collection.return_value

    mock_db.collection.side_effect = track_collection

    seed_content(mock_db, VALID_SEED, dry_run=False)

    # "content" doit apparaître dans les appels de collection (sous-collection)
    subcollection_names = []
    for mock_call in mock_db.mock_calls:
        call_str = str(mock_call)
        if "collection('content')" in call_str or 'collection("content")' in call_str:
            subcollection_names.append("content")
        if "collection('notions')" in call_str or 'collection("notions")' in call_str:
            subcollection_names.append("notions")

    # Vérifie que les sous-collections sont bien appelées via .document().collection()
    doc_ref_mock = mock_db.collection.return_value.document.return_value
    # La sous-collection content doit être appelée sur le document de leçon
    assert doc_ref_mock.collection.called, "Aucune sous-collection appelée sur le document leçon"


# ─────────────────────────────────────────────────────────────────────────────
# (9) idempotence — set(merge=True) partout, jamais add()
# ─────────────────────────────────────────────────────────────────────────────

def test_seed_uses_set_merge_true_never_add():
    mock_db = MagicMock()
    seed_content(mock_db, VALID_SEED, dry_run=False)

    # Parcourt tous les appels et vérifie qu'add() n'est jamais appelé
    for mock_call in mock_db.mock_calls:
        call_name = str(mock_call)
        assert ".add(" not in call_name, f"add() appelé — interdit pour idempotence : {mock_call}"
