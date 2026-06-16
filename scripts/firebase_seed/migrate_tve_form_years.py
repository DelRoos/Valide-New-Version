#!/usr/bin/env python3
"""
Migration matrice v2.4.0 → v2.5.0
Découpe les niveaux TVE agrégés en années individuelles.

AVANT :
  - anglophone_tve_il  (1 niveau, 13 séries, 13 règles)
  - anglophone_tve_al  (1 niveau, 13 séries, 13 règles)

APRÈS :
  - anglophone_tve_form_1 … form_5   (5 niveaux)
  - anglophone_tve_lower_sixth        (1 niveau)
  - anglophone_tve_upper_sixth        (1 niveau)
  → 13 spécialités × 5 IL + 13 × 2 AL = 91 séries + 91 règles

Raison : le contenu pédagogique (cours, exercices) est différent par
année de classe, même à l'intérieur d'un cycle TVE.
"""

import json
import os
from datetime import datetime, timezone

MATRICE_PATH = os.path.join(os.path.dirname(__file__), "data", "matrice.json")

# ---------------------------------------------------------------------------
# Données de référence
# ---------------------------------------------------------------------------

IL_FORMS = [
    {"key": "form_1", "en": "TVE Form One",   "fr": "TVE Form 1",   "sort": 280},
    {"key": "form_2", "en": "TVE Form Two",   "fr": "TVE Form 2",   "sort": 281},
    {"key": "form_3", "en": "TVE Form Three", "fr": "TVE Form 3",   "sort": 282},
    {"key": "form_4", "en": "TVE Form Four",  "fr": "TVE Form 4",   "sort": 283},
    {"key": "form_5", "en": "TVE Form Five",  "fr": "TVE Form 5",   "sort": 284},
]

AL_FORMS = [
    {"key": "lower_sixth", "en": "TVE Lower Sixth", "fr": "TVE Lower Sixth", "sort": 285},
    {"key": "upper_sixth", "en": "TVE Upper Sixth", "fr": "TVE Upper Sixth", "sort": 286},
]

# 13 spécialités TVE — mêmes pour IL et AL
SPECIALTIES = [
    # code          | label EN                              | label FR
    ("eleq",               "ELEQ — Electrical Equipment",        "ELEQ — Équipement Électrique"),
    ("elni",               "ELNI — Electronics",                 "ELNI — Électronique"),
    ("elme",               "ELME — Electromechanical",           "ELME — Électromécanique"),
    ("elet",               "ELET — Electrotechnique",            "ELET — Électrotechnique"),
    ("ac",                 "AC — Air Conditioning",              "AC — Climatisation / Froid"),
    ("me",                 "ME — Mechanical Engineering",        "ME — Génie Mécanique"),
    ("ce",                 "CE — Civil Engineering / Building",  "CE — Génie Civil / Bâtiment"),
    ("woodwork",           "WW — Woodwork / Carpentry",          "WW — Menuiserie / Charpenterie"),
    ("acc",                "ACC — Accounting",                   "ACC — Comptabilité"),
    ("commerce",           "COM — Commerce",                     "COM — Commerce"),
    ("op",                 "OP — Office Practice",               "OP — Pratique de Bureau"),
    ("food_nutrition",     "FN — Food & Nutrition",              "FN — Alimentation & Nutrition"),
    ("clothing_textiles",  "CT — Clothing & Textiles",           "CT — Habillement & Textiles"),
]

# Matières communes TVE IL (Math inclus)
IL_SUBJECTS = [
    "anglophone_english_lang",
    "anglophone_french",
    "anglophone_math",
    "anglophone_tve_professional",
    "anglophone_tve_related_professional",
    "anglophone_tve_workshop",
]

# Matières communes TVE AL (sans Math — conforme au GCE Board)
AL_SUBJECTS = [
    "anglophone_english_lang",
    "anglophone_french",
    "anglophone_tve_professional",
    "anglophone_tve_related_professional",
    "anglophone_tve_workshop",
]

OBLIGATORY = ["anglophone_english_lang", "anglophone_french"]

OLD_NIVEAU_IDS = {"anglophone_tve_il", "anglophone_tve_al"}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def build_niveau(form: dict, filiere: str = "technique") -> dict:
    return {
        "niveauId":   f"anglophone_tve_{form['key']}",
        "subSystem":  "anglophone",
        "name":       {"fr": form["fr"], "en": form["en"]},
        "filiereIds": [filiere],
        "isActive":   True,
        "sortOrder":  form["sort"],
    }

def build_serie(form_key: str, spec_code: str, spec_en: str, spec_fr: str,
                sort_order: int) -> dict:
    return {
        "serieId":    f"anglophone_tve_{form_key}_{spec_code}",
        "subSystem":  "anglophone",
        "niveauId":   f"anglophone_tve_{form_key}",
        "filiereId":  "technique",
        "name":       {"fr": spec_fr, "en": spec_en},
        "canOptOut":  False,
        "isActive":   True,
        "sortOrder":  sort_order,
        "pickerMode": "derived",
    }

def build_rule(form_key: str, spec_code: str, subjects: list[str],
               exam_cycle: str) -> dict:
    niveau_id = f"anglophone_tve_{form_key}"
    serie_id  = f"anglophone_tve_{form_key}_{spec_code}"
    return {
        "ruleId":             f"rule_anglophone_tve_{form_key}_{spec_code}",
        "matchSubSystem":     "anglophone",
        "matchFiliere":       "technique",
        "matchNiveau":        niveau_id,
        "matchSerie":         serie_id,
        "subjectIds":         subjects,
        "examTargetIds":      [f"exam_tve_{exam_cycle}_anglophone_{spec_code}"],
        "canOptOut":          False,
        "isActive":           True,
        "obligatorySubjectIds": OBLIGATORY,
        "optionalSubjectIds": [],
    }

# ---------------------------------------------------------------------------
# Migration
# ---------------------------------------------------------------------------

def migrate():
    with open(MATRICE_PATH, "r", encoding="utf-8") as f:
        matrice = json.load(f)

    old_version = matrice.get("version", "?")

    # ── NIVEAUX ──────────────────────────────────────────────────────────────
    # Supprimer les 2 anciens niveaux agrégés
    matrice["niveaux"] = [
        n for n in matrice["niveaux"]
        if n["niveauId"] not in OLD_NIVEAU_IDS
    ]

    # Ajouter 7 nouveaux niveaux
    for form in IL_FORMS:
        matrice["niveaux"].append(build_niveau(form))
    for form in AL_FORMS:
        matrice["niveaux"].append(build_niveau(form))

    # ── SÉRIES ───────────────────────────────────────────────────────────────
    # Supprimer les 26 anciennes séries TVE
    old_serie_ids = {
        s["serieId"] for s in matrice["series"]
        if s.get("niveauId") in OLD_NIVEAU_IDS
    }
    matrice["series"] = [
        s for s in matrice["series"]
        if s["serieId"] not in old_serie_ids
    ]

    # Ajouter 65 séries TVE IL (5 formes × 13 spécialités)
    sort = 1000
    for form in IL_FORMS:
        for code, en, fr in SPECIALTIES:
            matrice["series"].append(build_serie(form["key"], code, en, fr, sort))
            sort += 1

    # Ajouter 26 séries TVE AL (2 formes × 13 spécialités)
    sort = 1200
    for form in AL_FORMS:
        for code, en, fr in SPECIALTIES:
            matrice["series"].append(build_serie(form["key"], code, en, fr, sort))
            sort += 1

    # ── RÈGLES DE DÉRIVATION ─────────────────────────────────────────────────
    # Supprimer les 26 anciennes règles TVE
    old_rule_ids = {
        r["ruleId"] for r in matrice["derivation_rules"]
        if r.get("matchNiveau") in OLD_NIVEAU_IDS
    }
    matrice["derivation_rules"] = [
        r for r in matrice["derivation_rules"]
        if r["ruleId"] not in old_rule_ids
    ]

    # Ajouter 65 règles TVE IL
    for form in IL_FORMS:
        for code, _, _ in SPECIALTIES:
            matrice["derivation_rules"].append(
                build_rule(form["key"], code, IL_SUBJECTS, "il")
            )

    # Ajouter 26 règles TVE AL
    for form in AL_FORMS:
        for code, _, _ in SPECIALTIES:
            matrice["derivation_rules"].append(
                build_rule(form["key"], code, AL_SUBJECTS, "al")
            )

    # ── MÉTADONNÉES ──────────────────────────────────────────────────────────
    matrice["version"] = "2.5.0"
    matrice["generatedAt"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    with open(MATRICE_PATH, "w", encoding="utf-8") as f:
        json.dump(matrice, f, ensure_ascii=False, indent=2)

    # ── RAPPORT ──────────────────────────────────────────────────────────────
    n_niveaux = len(matrice["niveaux"])
    n_series  = len(matrice["series"])
    n_rules   = len(matrice["derivation_rules"])
    tve_niveaux = [n for n in matrice["niveaux"] if "tve" in n["niveauId"]]
    tve_series  = [s for s in matrice["series"]  if "tve" in s["serieId"]]
    tve_rules   = [r for r in matrice["derivation_rules"] if "tve" in r["ruleId"]]

    print(f"\n[OK] Migration {old_version} -> 2.5.0")
    print(f"   niveaux  : {n_niveaux}  ({len(tve_niveaux)} TVE)")
    print(f"   séries   : {n_series}  ({len(tve_series)} TVE)")
    print(f"   règles   : {n_rules}  ({len(tve_rules)} TVE)")
    print(f"\nNiveaux TVE créés :")
    for n in tve_niveaux:
        print(f"  {n['niveauId']:45s}  {n['name']['en']}")


if __name__ == "__main__":
    migrate()
