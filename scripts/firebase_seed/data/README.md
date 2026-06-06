# data/matrice.json — Source de vérité catalogue scolaire

Fichier JSON versionné qui contient la matrice exhaustive du catalogue scolaire Valide School (6 collections Firestore). Lu par `seed_catalogue.py` (Story 1.1b) au seed et après chaque évolution.

## Source autoritaire

- **Tableau de dérivation** (les 69 entrées de `derivation_rules`) : [`doc/partage/DONNEES-REFERENCE.md § Tableau de dérivation`](../../../doc/partage/DONNEES-REFERENCE.md#tableau-de-dérivation-subsystem-filiere-niveau-serie--examtargetids)
- **Schéma TypeScript** des 6 collections : [`doc/partage/BASE-DE-DONNEES.md § Catalogue scolaire`](../../../doc/partage/BASE-DE-DONNEES.md#catalogue-scolaire-6-collections--story-11a)
- **Conventions IDs** : [`doc/partage/DONNEES-REFERENCE.md § Convention de nommage des IDs`](../../../doc/partage/DONNEES-REFERENCE.md)

## Structure racine

```jsonc
{
  "version": "1.0.0",
  "generatedAt": "YYYY-MM-DD",
  "comment": "Note humaine sur le contenu",
  "filieres":         [ /* 2 docs */ ],
  "niveaux":          [ /* 14 docs */ ],
  "series":           [ /* 60 docs */ ],
  "subjects":         [ /* 38 docs */ ],
  "exam_targets":     [ /* 47 docs */ ],
  "derivation_rules": [ /* 69 docs */ ]
}
```

## Conventions IDs (résumé)

| Collection | Convention | Exemple |
|---|---|---|
| `filieres` | snake_case sans préfixe | `generale`, `technique` |
| `niveaux` | `{subSystem}_{slug}` | `francophone_6e`, `anglophone_lower_sixth` |
| `series` | `{subSystem}_{niveau_slug}_{serie_slug}` | `francophone_terminale_d`, `anglophone_upper_sixth_s2` |
| `subjects` | `{subSystem}_{shortCode}` | `francophone_math`, `anglophone_chemistry` |
| `exam_targets` | `exam_{slug}_{subSystem}[_{serie}]` | `exam_bac_francophone_d`, `exam_gce_a_level_anglophone_s2` |
| `derivation_rules` | `rule_{subSystem}_{filiere}_{niveau_slug}_{serie_slug|none}` | `rule_francophone_generale_terminale_d`, `rule_anglophone_generale_form_1_none` |

Détails complets dans [BASE-DE-DONNEES.md § Catalogue scolaire](../../../doc/partage/BASE-DE-DONNEES.md#catalogue-scolaire-6-collections--story-11a).

## Champ par champ

### `filieres[i]`

```jsonc
{
  "filiereId": "generale",                       // = doc ID Firestore
  "name": { "fr": "Générale", "en": "General" },
  "isActive": true,
  "sortOrder": 10
}
```

### `niveaux[i]`

```jsonc
{
  "niveauId": "francophone_terminale",
  "subSystem": "francophone",                    // "francophone" | "anglophone"
  "name": { "fr": "Terminale", "en": "Terminale" },
  "filiereIds": ["generale", "technique"],       // liste de filieres applicables
  "isActive": true,
  "sortOrder": 170
}
```

### `series[i]`

```jsonc
{
  "serieId": "francophone_terminale_d",
  "subSystem": "francophone",
  "niveauId": "francophone_terminale",           // ref → niveaux/{id}
  "filiereId": "generale",                       // ref → filieres/{id}
  "name": { "fr": "D", "en": "D" },
  "canOptOut": false,                            // Story 1.4 — true si l'élève peut retirer des matières
  "isActive": true,
  "sortOrder": 90
}
```

### `subjects[i]`

```jsonc
{
  "subjectId": "francophone_math",
  "subSystem": "francophone",
  "name": { "fr": "Mathématiques", "en": "Mathematics" },
  "icon": "function-square",                     // nom Lucide (cf. https://lucide.dev/icons/)
  "isActive": true,
  "sortOrder": 10
}
```

### `exam_targets[i]`

```jsonc
{
  "examTargetId": "exam_bac_francophone_d",
  "subSystem": "francophone",
  "name": { "fr": "BAC D", "en": "BAC D" },
  "isActive": true,
  "sortOrder": 80
}
```

### `derivation_rules[i]`

```jsonc
{
  "ruleId": "rule_francophone_generale_terminale_d",
  "matchSubSystem": "francophone",
  "matchFiliere": "generale",                    // ref → filieres/{id} OU "*" wildcard
  "matchNiveau": "francophone_terminale",        // ref → niveaux/{id}
  "matchSerie": "francophone_terminale_d",       // ref → series/{id} OU null (si niveau sans série)
  "subjectIds": [                                // liste de refs → subjects/{id}
    "francophone_math", "francophone_pct", "francophone_svt",
    "francophone_fr", "francophone_en", "francophone_lv2",
    "francophone_philo", "francophone_hg", "francophone_eps"
  ],
  "examTargetIds": ["exam_bac_francophone_d"],   // liste de refs → exam_targets/{id}
  "canOptOut": false,                            // doublon avec series.canOptOut, pour requête directe
  "isActive": true
}
```

Note : `derivation_rules` n'a **pas** de `sortOrder` (contrairement aux 5 autres collections).

## Périmètre d'activation (`isActive`)

Le périmètre activé au seed initial reflète [DONNEES-REFERENCE.md § Périmètre MVP suggéré](../../../doc/partage/DONNEES-REFERENCE.md#périmètre-mvp-suggéré) :

- **Périmètre prioritaire** (`isActive: true`, ~57/69 rules actives) :
  - Francophone général : 6ᵉ→3ᵉ + BEPC, Seconde/Première/Terminale séries **A, C, D** + Probatoire/BAC
  - Francophone technique : Première/Terminale **F1-F4** + **G1-G3**
  - Anglophone : Form 1→Form 5 + O Level, Lower/Upper Sixth **S1-S8 et A1-A5** + A Level

- **Périmètre étendu** (`isActive: false`, ~12/69 rules inactives) :
  - Francophone général : série **E** (Première + Terminale)
  - Francophone technique : série **F5** (Première + Terminale) + 8 séries étendues Terminale (ESF, IH, MVT, ACA, MAVA, MEAC AUTO, MEM, MECA)
  - L'admin pédagogique active runtime via Console toggle `isActive` quand le contenu pédagogique est prêt — pas besoin de re-run script ni de release mobile

## Volumétrie finale

| Collection | Total | Active | Inactive |
|---|---|---|---|
| `filieres` | 2 | 2 | 0 |
| `niveaux` | 14 | 14 | 0 |
| `series` | 60 | 48 | 12 |
| `subjects` | 38 | 37 | 1 (placeholder technique étendu) |
| `exam_targets` | 47 | 35 | 12 |
| `derivation_rules` | 69 | 57 | 12 |
| **Total** | **230** | **193** | **37** |

## Notes d'écart vs DONNEES-REFERENCE.md

- **69 derivation_rules** (vs **79** indiqués dans DONNEES-REFERENCE.md § volumétrie ligne 417) : le tableau réel des sections § Tableau de dérivation ne contient que 69 entrées. Le 79 de la ligne 417 inclut probablement des doubles-comptages (2nd cycle général : 10 réelles vs 14 estimées ; technique industriel : 10 réelles vs 16 estimées). La matrice livrée est cohérente avec **les tableaux DONNEES-REFERENCE.md** (source vérité).
- **Séries techniques étendues** (8 séries Terminale) : les listes de matières exactes ne sont pas encore validées par enseignant camerounais (cf. DONNEES-REFERENCE.md ligne 141 🟡). Modélisées avec un subject placeholder `francophone_tech_general_etendu` + matières communes (fr, en, eps) — à enrichir post-MVP quand l'équipe pédagogique aura validé les listes exactes.
- **Form 1-2 anglophone** : `integrated_science` agrégé en un seul subject, à éclater en physics/chemistry/biology dès Form 3 (élargissement scientifique documenté DONNEES-REFERENCE.md ligne 198).

## Workflow d'évolution

1. Repérer le changement à apporter (nouvelle série activable, correction matière, nouveau niveau...)
2. Éditer ce JSON (respecter la structure documentée ci-dessus)
3. `python ../seed_catalogue.py --project valide-edu --dry-run` pour validation + comptage
4. Si OK : `python ../seed_catalogue.py --project valide-edu`
5. Commit `data/matrice.json` (et éventuellement DONNEES-REFERENCE.md si la matrice doc a évolué — accord backend requis pour `doc/partage/`)

Pour les **micro-corrections** (typo dans un nom, toggle `isActive`), passer directement par Firebase Console est plus rapide et acceptable — pas besoin de re-run le script.
