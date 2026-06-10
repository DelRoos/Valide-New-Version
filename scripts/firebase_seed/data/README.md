# data/ — Sources de vérité versionnées

Ce dossier contient les matrices JSON versionnées seedées dans Firestore par les scripts Python du dossier parent.

| Fichier | Collection Firestore | Script | Story |
|---|---|---|---|
| `matrice.json` | `filieres`, `niveaux`, `series`, `subjects`, `exam_targets`, `derivation_rules` | `seed_catalogue.py` | 1.1b |
| `schools.json` | `schools` | `seed_schools.py` | 1.5.a |

---

## matrice.json — Source de vérité catalogue scolaire

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

---

## schools.json — Source de vérité catalogue des écoles MINESEC

Fichier JSON versionné qui contient la matrice des établissements scolaires camerounais (collection Firestore `schools`). Lu par `seed_schools.py` (Story 1.5.a) au seed initial et après chaque évolution.

### Source autoritaire

- **Schéma TypeScript** : [`doc/partage/BASE-DE-DONNEES.md § schools/{schoolId}`](../../../doc/partage/BASE-DE-DONNEES.md#schoolsschoolid-)
- **Story d'origine** : [Story 1.5.a — Seed MINESEC](../../../project_manage/implementation-artifacts/1-5-a-seed-minesec-schools.md)
- **Sources composites** : MINESEC (lycées/collèges publics francophones) + GCE Board (GHS/GBHS/PSS anglophones) + Wikipédia FR + techno-science.net

### Structure racine

```jsonc
{
  "version": "1.0.0",
  "generatedAt": "YYYY-MM-DD",
  "source": "Composite : MINESEC + GCE Board + Wikipedia + techno-science.net",
  "comment": "Dataset Story 1.5.a (Epic 1.5)",
  "schools": [ /* ~200 docs V1 — extensible via PR + flow demande ajout Story 1.5.c */ ]
}
```

### Conventions schoolId

Slug reproductible `school_<slug_nom>_<slug_ville>` :

- Lower-case
- Accents normalisés (é → e)
- Espaces → underscore
- Caractères spéciaux supprimés
- Pattern : `^school_[a-z0-9_]+$`

Exemples :

- `school_lycee_general_leclerc_yaounde`
- `school_lycee_bilingue_bonaberi_douala`
- `school_ghs_buea_town_buea`
- `school_pss_mankon_bamenda`

### Champ par champ — `schools[i]`

```jsonc
{
  "schoolId": "school_lycee_bilingue_bonaberi_douala",  // = doc ID Firestore
  "name": "Lycee Bilingue de Bonaberi",                 // casse officielle préservée
  "city": "Douala",                                     // ville
  "region": "Littoral",                                 // une des 10 régions officielles MINESEC
  "subSystem": "both",                                  // "francophone" | "anglophone" | "both"
  "isValidated": true                                   // true pour toutes les écoles MINESEC officielles
}
```

> **Note** : le champ `createdAt: Timestamp` est posé automatiquement par le script de seed (`firestore.SERVER_TIMESTAMP`), pas dans le JSON.

### Régions MINESEC officielles (10)

`Adamaoua`, `Centre`, `Est`, `Extreme-Nord`, `Littoral`, `Nord`, `Nord-Ouest`, `Ouest`, `Sud`, `Sud-Ouest`.

### Heuristique `subSystem`

| Nom contient... | subSystem | Sémantique |
|---|---|---|
| « Lycée » / « Collège » / « CES » (FR pur) | `francophone` | Section uniquement francophone |
| « Government High School » / « GHS » / « PSS » / « Comprehensive » | `anglophone` | Section uniquement anglophone |
| « Lycée Bilingue » / « Government Bilingual High School » / « GBHS » | `both` | **Sections multiples francophone + anglophone** coexistantes |

**Note importante** : la valeur `both` couvre toutes les écoles avec **plusieurs langues coexistantes** dans le même établissement — pas seulement les écoles « bilingues » dans le nom officiel. Beaucoup de grands lycées francophones (Lycée Joss, Lycée Général Leclerc, etc.) ont en pratique une section bilingue opérationnelle et peuvent être promus `francophone` → `both` ultérieurement.

Si ambigu (école bilingue privée, nom mixte) : choisir `both` par défaut. Corrections possibles via Firebase Console toggle ultérieur OU PR sur `schools.json` + re-seed.

> **Évolution future** : si un nouveau sous-système devait être ajouté (ex. arabophone via madrasas), une migration vers `subSystems: string[]` (array Firestore avec `arrayContains`) serait privilégiée. À tracer en sprint-change si le cas survient. Cf. note dans [BASE-DE-DONNEES.md § schools/{schoolId}](../../../doc/partage/BASE-DE-DONNEES.md#schoolsschoolid-).

### Volumétrie V1 (post-seed Story 1.5.a)

| Région | Écoles |
|---|---|
| Centre | 40 |
| Littoral | 38 |
| Ouest | 34 |
| Sud-Ouest | 20 |
| Nord-Ouest | 16 |
| Nord | 13 |
| Sud | 11 |
| Extreme-Nord | 10 |
| Adamaoua | 8 |
| Est | 8 |
| **Total** | **198** |

| subSystem | Écoles |
|---|---|
| francophone | 136 |
| both | 35 |
| anglophone | 27 |
| **Total** | **198** |

### Workflow d'évolution

1. Identifier l'école à ajouter (nom, ville, région, subSystem)
2. Générer le `schoolId` selon la convention (`school_<slug>`)
3. Ajouter l'entrée dans `schools[]` (respecter l'ordre alphabétique par région si possible)
4. `python ../seed_schools.py --project valide-edu --dry-run` pour validation + comptage
5. Si OK : `python ../seed_schools.py --project valide-edu`
6. Commit `data/schools.json` (Conventional Commits scope `core` ou `partage`)

Pour les **micro-corrections** (typo dans un nom, toggle `isValidated`), passer directement par Firebase Console est plus rapide et acceptable — pas besoin de re-run le script.

### Source complémentaire — flow demande ajout Story 1.5.c (à venir)

Les écoles absentes de `schools.json` peuvent être ajoutées par les utilisateurs via le flow « Mon école n'est pas dans la liste » (Story 1.7 — temporaire jusqu'à Story 1.5.c).

Le flow écrit dans la sous-collection `schools/_pending_<timestamp>/requests/<auto>` (cf. [`BASE-DE-DONNEES.md § schools requests`](../../../doc/partage/BASE-DE-DONNEES.md)). Une école demandée + modérée admin doit ensuite être promue dans `schools.json` (workflow PR séparé) puis re-seedée pour ancrer la source de vérité versionnée.
