#!/usr/bin/env python3
"""
Migration matrice v2.5.0 -> v2.5.1
Ajoute les 4 series + regles de derivation pour francophone_seconde + technique.

AVANT : 0 serie technique a Seconde -> _StreamPickerEmpty affiche
APRES :
  - francophone_seconde_industrielle  (path vers F1/F2/F3/F4)
  - francophone_seconde_commerciale   (path vers G1/G2/G3)
  - francophone_seconde_sciences_biologiques  (path vers F6/F7)
  - francophone_seconde_arts_appliques        (path vers AF1/AF2/AF3)
"""

import json
import os
import datetime

MATRICE_PATH = os.path.join(os.path.dirname(__file__), "data", "matrice.json")

NEW_SERIES = [
    {
        "serieId":    "francophone_seconde_industrielle",
        "subSystem":  "francophone",
        "niveauId":   "francophone_seconde",
        "filiereId":  "technique",
        "name":       {"fr": "Seconde Industrielle", "en": "Seconde - Industrial"},
        "description": {
            "fr": "Filiere industrielle (sciences et technologies) - mene aux series F1/F2/F3/F4",
            "en": "Industrial track (sciences and technology) - leads to F1/F2/F3/F4 series"
        },
        "canOptOut":  False,
        "isActive":   True,
        "sortOrder":  151,
        "pickerMode": "derived",
    },
    {
        "serieId":    "francophone_seconde_commerciale",
        "subSystem":  "francophone",
        "niveauId":   "francophone_seconde",
        "filiereId":  "technique",
        "name":       {"fr": "Seconde Commerciale", "en": "Seconde - Commercial"},
        "description": {
            "fr": "Filiere commerciale et tertiaire - mene aux series G1/G2/G3",
            "en": "Commercial and tertiary track - leads to G1/G2/G3 series"
        },
        "canOptOut":  False,
        "isActive":   True,
        "sortOrder":  152,
        "pickerMode": "derived",
    },
    {
        "serieId":    "francophone_seconde_sciences_biologiques",
        "subSystem":  "francophone",
        "niveauId":   "francophone_seconde",
        "filiereId":  "technique",
        "name":       {"fr": "Seconde Sciences Biologiques et Chimiques", "en": "Seconde - Biological and Chemical Sciences"},
        "description": {
            "fr": "Filiere bio-chimique - mene aux series F6 (BIPE/COPH/MIPE) et F7 (BIOLO/BIOCH)",
            "en": "Biochemical track - leads to F6 (BIPE/COPH/MIPE) and F7 (BIOLO/BIOCH) series"
        },
        "canOptOut":  False,
        "isActive":   True,
        "sortOrder":  153,
        "pickerMode": "derived",
    },
    {
        "serieId":    "francophone_seconde_arts_appliques",
        "subSystem":  "francophone",
        "niveauId":   "francophone_seconde",
        "filiereId":  "technique",
        "name":       {"fr": "Seconde Arts Appliques", "en": "Seconde - Applied Arts"},
        "description": {
            "fr": "Filiere arts appliques - mene aux series AF1 (ceramique), AF2 (peinture), AF3 (sculpture)",
            "en": "Applied arts track - leads to AF1 (ceramics), AF2 (painting), AF3 (sculpture) series"
        },
        "canOptOut":  False,
        "isActive":   True,
        "sortOrder":  154,
        "pickerMode": "derived",
    },
]

NEW_RULES = [
    {
        "ruleId":         "rule_francophone_technique_seconde_industrielle",
        "matchSubSystem": "francophone",
        "matchFiliere":   "technique",
        "matchNiveau":    "francophone_seconde",
        "matchSerie":     "francophone_seconde_industrielle",
        "subjectIds": [
            "francophone_fr", "francophone_en", "francophone_math",
            "francophone_physique_appliquee", "francophone_chimie",
            "francophone_technologie", "francophone_dessin_technique",
            "francophone_histoire", "francophone_geographie",
            "francophone_ecv", "francophone_eps",
        ],
        "examTargetIds":          [],
        "canOptOut":              False,
        "isActive":               True,
        "obligatorySubjectIds":   [],
        "optionalSubjectIds":     [],
    },
    {
        "ruleId":         "rule_francophone_technique_seconde_commerciale",
        "matchSubSystem": "francophone",
        "matchFiliere":   "technique",
        "matchNiveau":    "francophone_seconde",
        "matchSerie":     "francophone_seconde_commerciale",
        "subjectIds": [
            "francophone_fr", "francophone_en", "francophone_math",
            "francophone_economie_generale", "francophone_droit",
            "francophone_hg", "francophone_bureautique",
            "francophone_ecv", "francophone_eps",
        ],
        "examTargetIds":          [],
        "canOptOut":              False,
        "isActive":               True,
        "obligatorySubjectIds":   [],
        "optionalSubjectIds":     [],
    },
    {
        "ruleId":         "rule_francophone_technique_seconde_sciences_biologiques",
        "matchSubSystem": "francophone",
        "matchFiliere":   "technique",
        "matchNiveau":    "francophone_seconde",
        "matchSerie":     "francophone_seconde_sciences_biologiques",
        "subjectIds": [
            "francophone_fr", "francophone_en", "francophone_math",
            "francophone_physique_appliquee", "francophone_chimie",
            "francophone_svt",
            "francophone_histoire", "francophone_geographie",
            "francophone_ecv", "francophone_eps",
        ],
        "examTargetIds":          [],
        "canOptOut":              False,
        "isActive":               True,
        "obligatorySubjectIds":   [],
        "optionalSubjectIds":     [],
    },
    {
        "ruleId":         "rule_francophone_technique_seconde_arts_appliques",
        "matchSubSystem": "francophone",
        "matchFiliere":   "technique",
        "matchNiveau":    "francophone_seconde",
        "matchSerie":     "francophone_seconde_arts_appliques",
        "subjectIds": [
            "francophone_fr", "francophone_en", "francophone_math",
            "francophone_histoire_de_lart", "francophone_dessin_artistique",
            "francophone_histoire", "francophone_geographie",
            "francophone_ecv", "francophone_eps",
        ],
        "examTargetIds":          [],
        "canOptOut":              False,
        "isActive":               True,
        "obligatorySubjectIds":   [],
        "optionalSubjectIds":     [],
    },
]


def migrate():
    with open(MATRICE_PATH, "r", encoding="utf-8") as f:
        m = json.load(f)

    old_version = m.get("version", "?")

    existing_serie_ids = {s["serieId"] for s in m["series"]}
    added_series = 0
    for s in NEW_SERIES:
        if s["serieId"] not in existing_serie_ids:
            m["series"].append(s)
            added_series += 1

    existing_rule_ids = {r["ruleId"] for r in m["derivation_rules"]}
    added_rules = 0
    for r in NEW_RULES:
        if r["ruleId"] not in existing_rule_ids:
            m["derivation_rules"].append(r)
            added_rules += 1

    m["version"] = "2.5.1"
    m["generatedAt"] = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    with open(MATRICE_PATH, "w", encoding="utf-8") as f:
        json.dump(m, f, ensure_ascii=False, indent=2)

    print(f"[OK] Migration {old_version} -> 2.5.1")
    print(f"  Series ajoutees : {added_series}")
    print(f"  Regles ajoutees : {added_rules}")
    print()

    tech_sec = [s for s in m["series"] if s.get("niveauId") == "francophone_seconde" and s.get("filiereId") == "technique"]
    print(f"Series francophone_seconde technique: {len(tech_sec)}")
    for s in tech_sec:
        print(f"  {s['serieId']:55s}  sort={s['sortOrder']}")


if __name__ == "__main__":
    migrate()
