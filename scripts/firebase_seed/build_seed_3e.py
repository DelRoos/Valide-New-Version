#!/usr/bin/env python3
"""
build_seed_3e.py — Génère data/seed_3e.json depuis scripts/content_demo/3e/.

Normalise les formats JSON hétérogènes du répertoire content_demo/3e/ vers
le schéma v2 (sous-collections Firestore) attendu par seed_3e_content.py.

Formats source supportés (3 variantes observées) :
  A. math_3e.json   — lessons plate, content FR inline, notionIds → notions plates
  B. chinois_3e.json — lessons plate, content par chemin .md, notions plates term+definition
  C. info_3e.json   — chapters avec lessonIds explicites, content par chemin .md, notionIds

Transformations appliquées :
  - content .md → Markdown inline ; FR-only → copié en EN
  - term+definition → title+content (modèle notion v2)
  - type notion inféré par analyse lexicale du contenu
  - sortOrder/order/duration → order/durationMinutes normalisés
  - IDs stables conservés tels quels

Usage :
    python build_seed_3e.py
    python build_seed_3e.py --output ./data/seed_3e.json
"""

from __future__ import annotations

import argparse
import json
import re
from datetime import datetime, timezone
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
CONTENT_DEMO_3E = SCRIPT_DIR.parent / "content_demo" / "3e"
DEFAULT_OUTPUT = SCRIPT_DIR / "data" / "seed_3e.json"


# ─────────────────────────────────────────────────────────────────────────────
# Inférence du type de notion
# ─────────────────────────────────────────────────────────────────────────────

_RULE_TOKENS = [
    "règle", "toujours", "jamais", "obligatoire", "interdit",
    "ne pas confondre", "ne jamais", "doit être", "ne peut pas",
    "attention", "sandhi", "exception",
]
_METHOD_TOKENS = [
    "méthode", "étapes", "procédure", "marche à suivre",
    "pour calculer", "pour résoudre", "pour simplifier", "démarche",
]
_FORMULA_TOKENS = [
    r"\$\$", r"\$[a-zA-Z(\\]",
    "formule", "identité remarquable", "théorème",
]
_PROPERTY_TOKENS = ["propriété", "proprietes", "caractéristique", "attribut"]
_FACT_TOKENS = [
    "créé en", "fondé en", r"depuis \d{4}", "inscrit au",
    "patrimoine", "en chine", "en afrique", "en france", "km", "milliard",
    "historique", "culturel", "géographique",
]


def infer_notion_type(title_fr: str, content_fr: str) -> str:
    """Infère le type de notion depuis son titre et son contenu (FR)."""
    text = (title_fr + " " + content_fr).lower()

    if any(tok in text for tok in _RULE_TOKENS):
        return "rule"
    if any(tok in text for tok in _METHOD_TOKENS):
        return "method"
    if any(re.search(pattern, text) for pattern in _FORMULA_TOKENS):
        return "formula"
    if any(tok in text for tok in _PROPERTY_TOKENS):
        return "property"
    if any(re.search(pattern, text) for pattern in _FACT_TOKENS):
        return "fact"
    return "definition"


# ─────────────────────────────────────────────────────────────────────────────
# Normalisation des champs bilingues
# ─────────────────────────────────────────────────────────────────────────────

def ensure_bilingual(value, fallback_fr: str = "", fallback_en: str = "") -> dict:
    """Garantit la forme {fr, en}. Fallback : duplique FR→EN si EN absent."""
    if isinstance(value, dict):
        fr = value.get("fr") or fallback_fr
        en = value.get("en") or fr or fallback_en
        return {"fr": fr, "en": en}
    if isinstance(value, str) and value:
        return {"fr": value, "en": value}
    return {"fr": fallback_fr, "en": fallback_en}


# ─────────────────────────────────────────────────────────────────────────────
# Résolution du contenu Markdown
# ─────────────────────────────────────────────────────────────────────────────

def resolve_content(raw: dict | str, base_dir: Path) -> dict:
    """
    Résout le contenu d'une leçon :
      - chemin .md → lit le fichier
      - string non-.md → contenu inline (interprété comme FR)
      - dict {fr, en} → résout chaque langue
    Si EN absent, copie FR.
    """
    if isinstance(raw, str):
        # Format math_3e : content inline dans un simple string FR
        return {"fr": raw, "en": raw}

    if not isinstance(raw, dict):
        return {"fr": "", "en": ""}

    result: dict[str, str] = {}
    for lang in ("fr", "en"):
        val = raw.get(lang, "")
        if isinstance(val, str) and val.endswith(".md"):
            md_file = base_dir / val
            result[lang] = md_file.read_text(encoding="utf-8") if md_file.exists() else ""
        else:
            result[lang] = val or ""

    # Fallback croisé
    if not result.get("en") and result.get("fr"):
        result["en"] = result["fr"]
    if not result.get("fr") and result.get("en"):
        result["fr"] = result["en"]

    return result


# ─────────────────────────────────────────────────────────────────────────────
# Transformation d'un fichier JSON source
# ─────────────────────────────────────────────────────────────────────────────

def _get_id(obj: dict, *keys: str) -> str:
    """Retourne la première clé présente dans obj parmi les candidates."""
    for k in keys:
        if k in obj and obj[k]:
            return str(obj[k])
    return ""


def _get_order(obj: dict) -> int:
    """Extrait l'ordre depuis sortOrder ou order."""
    return int(obj.get("sortOrder") or obj.get("order") or 1)


def _build_notions(raw_notions: list, lesson_id: str) -> list[dict]:
    """Transforme une liste de notions brutes vers le schéma v2."""
    notions_out = []
    for idx, n in enumerate(raw_notions, start=1):
        n_id = _get_id(n, "notionId", "id")
        if not n_id:
            continue

        # Support format A (title only) et format B (term + definition)
        if "term" in n:
            title = ensure_bilingual(n["term"])
            content = ensure_bilingual(n.get("definition", {}))
        elif "title" in n:
            title = ensure_bilingual(n["title"])
            content = ensure_bilingual(n.get("content", {}))
        else:
            title = {"fr": n_id, "en": n_id}
            content = {"fr": "", "en": ""}

        notion_type = infer_notion_type(title["fr"], content["fr"])

        notions_out.append({
            "notionId": n_id,
            "order": int(n.get("order", idx)),
            "type": notion_type,
            "title": title,
            "content": content,
        })
    return notions_out


def _build_quizzes(raw_quizzes: list, lesson_id: str) -> list[dict]:
    """Transforme une liste de quizzes bruts vers le schéma v2."""
    quizzes_out = []
    for q_raw in raw_quizzes:
        q_id = _get_id(q_raw, "quizId", "id")
        if not q_id:
            continue

        questions_out = []
        for q in q_raw.get("questions", []):
            # Normalise l'énoncé (peut être "question" ou "text")
            text_raw = q.get("question") or q.get("text", {})
            text = ensure_bilingual(text_raw)

            # Normalise les options (list ou dict {fr, en})
            opts_raw = q.get("options", {})
            if isinstance(opts_raw, list):
                options = {"fr": opts_raw, "en": opts_raw}
            elif isinstance(opts_raw, dict):
                fr_opts = opts_raw.get("fr", [])
                en_opts = opts_raw.get("en", fr_opts)
                options = {"fr": fr_opts, "en": en_opts}
            else:
                options = {"fr": [], "en": []}

            explanation = ensure_bilingual(q.get("explanation", {}))

            questions_out.append({
                "id": q.get("id", ""),
                "notionId": q.get("notionId", None),  # null → à renseigner manuellement
                "text": text,
                "type": "mcq",
                "options": options,
                "correctIndex": int(q.get("correctIndex", 0)),
                "explanation": explanation,
            })

        quizzes_out.append({
            "quizId": q_id,
            "version": int(q_raw.get("version", 1)),
            "questions": questions_out,
        })
    return quizzes_out


def transform_subject(json_path: Path) -> dict:
    """
    Lit un fichier JSON de content_demo/3e/ et retourne un dict sujet v2.
    Gère les 3 formats source (A, B, C).
    """
    with open(json_path, encoding="utf-8") as f:
        raw = json.load(f)

    base_dir = json_path.parent
    meta = raw.get("meta", {})
    subject_id = (
        meta.get("subjectId")
        or raw.get("subjectId")
        or json_path.stem  # fallback sur le nom de fichier
    )

    # ── Index rapide : notions plates par lessonId (formats B et C)
    flat_notions_by_lesson: dict[str, list] = {}
    for n in raw.get("notions", []):
        lid = n.get("lessonId", "")
        flat_notions_by_lesson.setdefault(lid, []).append(n)

    # ── Index rapide : quizzes plates par lessonId
    flat_quizzes_by_lesson: dict[str, list] = {}
    for q in raw.get("quizzes", []):
        lid = q.get("lessonId", "")
        flat_quizzes_by_lesson.setdefault(lid, []).append(q)

    # ── Index leçons par ID (pour lookup depuis chapitres)
    lessons_by_id: dict[str, dict] = {}
    for l in raw.get("lessons", []):
        l_id = _get_id(l, "id", "lessonId")
        if l_id:
            lessons_by_id[l_id] = l

    # ── Construire les chapitres
    chapters_out = []
    for ch_raw in raw.get("chapters", []):
        ch_id = _get_id(ch_raw, "id", "chapterId")
        if not ch_id:
            continue

        ch_title = ensure_bilingual(ch_raw.get("title", {}))
        ch_desc_raw = ch_raw.get("description")
        ch_desc = ensure_bilingual(ch_desc_raw) if ch_desc_raw else None

        # Détermine la liste des leçons du chapitre :
        # Format C : lessonIds explicite dans le chapitre
        # Format A/B : les leçons ont un champ chapterId
        if "lessonIds" in ch_raw:
            lesson_ids = ch_raw["lessonIds"]
        else:
            lesson_ids = [
                lid for lid, l in lessons_by_id.items()
                if l.get("chapterId") == ch_id
            ]
            # Trier par order
            lesson_ids.sort(key=lambda lid: _get_order(lessons_by_id[lid]))

        lessons_out = []
        for l_id in lesson_ids:
            l_raw = lessons_by_id.get(l_id)
            if not l_raw:
                continue

            l_title = ensure_bilingual(l_raw.get("title", {}))
            l_duration = int(
                l_raw.get("duration")
                or l_raw.get("durationMinutes")
                or 45
            )
            l_content = resolve_content(l_raw.get("content", {}), base_dir)

            # Notions : cherche d'abord dans les notions imbriquées,
            # sinon dans l'index plat, sinon dans notionIds (format A avec notions plates)
            if l_raw.get("notions"):
                raw_notions = l_raw["notions"]
            elif flat_notions_by_lesson.get(l_id):
                raw_notions = flat_notions_by_lesson[l_id]
            else:
                # Format A : notionIds → cherche dans les notions plates par ID
                all_notions_flat = raw.get("notions", [])
                notion_ids_set = set(l_raw.get("notionIds", []))
                raw_notions = [
                    n for n in all_notions_flat
                    if _get_id(n, "id", "notionId") in notion_ids_set
                ]

            notions_out = _build_notions(raw_notions, l_id)

            # Quizzes
            raw_quizzes = flat_quizzes_by_lesson.get(l_id, [])
            quizzes_out = _build_quizzes(raw_quizzes, l_id)

            lessons_out.append({
                "lessonId": l_id,
                "order": _get_order(l_raw),
                "title": l_title,
                "durationMinutes": l_duration,
                "content": l_content,
                "notions": notions_out,
                "quizzes": quizzes_out,
            })

        # Trier les leçons par order pour garantir l'ordre croissant
        lessons_out.sort(key=lambda l: l["order"])

        chapters_out.append({
            "chapterId": ch_id,
            "order": _get_order(ch_raw),
            "title": ch_title,
            "description": ch_desc,
            "lessons": lessons_out,
        })

    chapters_out.sort(key=lambda ch: ch["order"])

    return {"subjectId": subject_id, "chapters": chapters_out}


# ─────────────────────────────────────────────────────────────────────────────
# Point d'entrée
# ─────────────────────────────────────────────────────────────────────────────

def build(content_demo_dir: Path, output_path: Path) -> dict:
    """Génère le seed JSON et le retourne (pour les tests)."""
    json_files = sorted(content_demo_dir.glob("*.json"))
    if not json_files:
        raise FileNotFoundError(f"Aucun JSON dans : {content_demo_dir}")

    subjects = []
    for jf in json_files:
        print(f"  >> {jf.name} ...", end=" ", flush=True)
        subject = transform_subject(jf)
        subjects.append(subject)

        ch_count = len(subject["chapters"])
        l_count = sum(len(ch["lessons"]) for ch in subject["chapters"])
        n_count = sum(
            len(l["notions"])
            for ch in subject["chapters"]
            for l in ch["lessons"]
        )
        q_count = sum(
            len(l["quizzes"])
            for ch in subject["chapters"]
            for l in ch["lessons"]
        )
        print(f"{ch_count}ch / {l_count}leç / {n_count}not / {q_count}quiz")

    seed = {
        "version": "2.0.0",
        "schema": "v2-subcollections",
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "level": "3e",
        "subSystem": "francophone",
        "subjects": subjects,
    }

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(seed, f, ensure_ascii=False, indent=2)

    total_ch = sum(len(s["chapters"]) for s in subjects)
    total_l = sum(
        len(ch["lessons"]) for s in subjects for ch in s["chapters"]
    )
    total_n = sum(
        len(l["notions"])
        for s in subjects
        for ch in s["chapters"]
        for l in ch["lessons"]
    )
    total_q = sum(
        len(l["quizzes"])
        for s in subjects
        for ch in s["chapters"]
        for l in ch["lessons"]
    )

    print(f"\n[OK] {output_path.name}")
    print(f"    Matières  : {len(subjects)}")
    print(f"    Chapitres : {total_ch}")
    print(f"    Leçons    : {total_l}")
    print(f"    Notions   : {total_n}")
    print(f"    Quiz      : {total_q}")

    return seed


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Génère seed_3e.json depuis content_demo/3e/",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Exemples :\n"
            "  python build_seed_3e.py\n"
            "  python build_seed_3e.py --output ./data/seed_3e.json\n"
            "  python build_seed_3e.py --source ../../content_demo/3e\n"
        ),
    )
    parser.add_argument(
        "--source",
        type=Path,
        default=CONTENT_DEMO_3E,
        help=f"Répertoire source content_demo/3e/ (défaut : {CONTENT_DEMO_3E})",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT,
        help=f"Fichier JSON de sortie (défaut : {DEFAULT_OUTPUT})",
    )
    args = parser.parse_args()

    print(f"Source : {args.source}")
    print(f"Sortie : {args.output}\n")
    build(args.source, args.output)


if __name__ == "__main__":
    main()
