---
story_id: 1.12
title: Update matrice.json v2 + re-seed Firestore valide-edu (alignement nomenclature officielle)
epic: 1
phase: P1 extension v2 (sprint change 2026-06-09)
status: done
created: 2026-06-09
merged: 2026-06-09
merge_commit: 7f3628d
pr: 67
baseline_commit: e1753d4  # merge contexte engine Story 1.12 (PR #66)
estimation: M (~4h)
sprint_change: sprint-change-proposal-2026-06-09.md (mergée commit 3f69c9d)
dependencies:
  - 1.1a — done (schema v1 + 6 collections)
  - 1.1b — done (script Python seed_catalogue.py + matrice.json v1 230 docs)
  - 1.1c — done (CatalogueRepository mobile en place, ne sera pas modifiée par cette story)
  - 1.11a — done (contrat schema v2 figé : 6 nouveaux champs Firestore + ADR-016)
blocks:
  - 1.14 — sous-séries Tle franco SerieChoicePage (a besoin des 9 séries Tle Franco A1-A5/ABI/SH/AC/TI seedées)
  - 1.15 — refactor SubjectsOptOutPage → SubjectsPickerPage (a besoin des `obligatorySubjectIds` + `optionalSubjectIds` seedés sur derivation_rules anglo + Form 5)
  - 1.16 — A-Level transversales (a besoin des `optionalSubjectIds` seedés sur derivation_rules Upper Sixth Sxx)
  - 1.17 — ESTP TVEE (a besoin des 26 séries TVEE + 26 derivation_rules TVEE seedés)
  - 1.13 — DerivedProfile v2 pickerMode (PEUT démarrer en parallèle car schema v2 figé en 1.11a, mais ses tests de non-régression Fatou/James dépendent du re-seed valide-edu en place)
sourceArtifacts:
  - project_manage/planning-artifacts/sprint-change-proposal-2026-06-09.md § Change 4.1 + Change 4.2 + Change 4.3 + Change 4.4
  - project_manage/implementation-artifacts/1-11a-audit-matrice-v2-adr016.md (contrat v2 figé)
  - project_manage/planning-artifacts/architecture/adrs/ADR-016-catalogue-v2-sous-series-panier-tvee.md (4 décisions architecturales)
  - doc/partage/DONNEES-REFERENCE.md v2 (matrice exhaustive — source canonique)
  - doc/partage/BASE-DE-DONNEES.md v2 (schema Firestore — types des nouveaux champs)
  - scripts/firebase_seed/data/matrice.json v1 (état actuel — 230 docs à étendre, non remplacer)
  - scripts/firebase_seed/seed_catalogue.py (logique seed — aucune modif Python attendue)
  - scripts/firebase_seed/data/README.md (à compléter avec nouveaux champs si pertinent)
  - scripts/firebase_seed/tests/test_seed.py (6 tests existants — restent verts post-1.12)
  - mobile_app/lib/core/catalogue/data/firestore_mappers.dart (contrat client — noms de champs exacts attendus)
  - mobile_app/lib/core/catalogue/data/catalogue_repository_firestore_impl.dart (queries — aucun nouvel index requis)
  - project_manage/implementation-artifacts/1-1b-script-python-seed-catalogue.md (pattern de référence pour exécution)
action_porteur_post_merge:
  - "Exécuter `python seed_catalogue.py --project valide-edu` après merge (ADC OK chez Delano, testé 2026-06-06 Story 1.1b)"
  - "Vérifier Firebase Console : ~280 documents au total (vs 230 v1) répartis sur 6 collections"
  - "Smoke device Fatou Tle D (matières v2 11 vs v1 9) + James Upper Sixth S2 (canOptOut: true encore actif)"
---

# Story 1.12 — Update matrice.json v2 + re-seed Firestore `valide-edu`

Status: **ready-for-dev**

## Objectif

Étendre la matrice source de vérité offline `scripts/firebase_seed/data/matrice.json` (livrée v1 230 docs par Story 1.1b) pour refléter le **contrat v2** figé par Story 1.11a, puis re-seed le projet Firebase `valide-edu` pour rendre le catalogue v2 disponible runtime aux Stories 1.13 / 1.14 / 1.15 / 1.16 / 1.17.

**Périmètre** :

1. **Subjects** : +27 nouvelles entrées (4 premier cycle franco + 8 Tle franco nouveaux + 4 O-Level GCE + 5 A-Level GCE + 6 TVEE communes), aucune suppression. Correction `francophone_pct` → `francophone_physique` + `francophone_chimie` séparés (préserver `francophone_pct` `isActive: false` pour rétrocompat docs séries v1).
2. **Niveaux** : +2 nouveaux (`anglophone_tve_il`, `anglophone_tve_al`) avec `filiereIds: ["technique"]`. Modification mineure `anglophone_form_5` reste inchangé (le picker O-Level se branche via `derivation_rules`, pas via une série virtuelle).
3. **Series** : +35 nouvelles (9 Tle franco sub-séries A1-A5/ABI/SH/AC/TI + 26 TVEE 13 × 2 niveaux). Modification 17 séries existantes : `francophone_terminale_a` → `isActive: false` (DEPRECATED) + ajout du nouveau champ `pickerMode` sur toutes les séries existantes pour expliciter le mode (rétrocompat : tous reçoivent `'derived'` ou `'opt_out'`).
4. **Exam_targets** : +35 nouveaux (9 BAC franco A1-A5/ABI/SH/AC/TI + 26 TVEE 13 × 2 niveaux).
5. **Derivation_rules** : +35 nouvelles (9 Tle franco sub-séries + 26 TVEE). Modification ~23 existantes (4 premier cycle franco ajout de LCN/Info collège/EA/TM + 3 Tle franco C/D/E correction Physique/Chimie/LV2/Environnement/Info/Philo + 1 Form 5 anglo ajout `obligatorySubjectIds` + `optionalSubjectIds` + 16 Upper Sixth Sxx/Axx ajout `obligatorySubjectIds` = Series + `optionalSubjectIds` = transversales).

**Pourquoi** : sans le re-seed, la matrice v2 reste théorique. Les Stories 1.14 (SerieChoicePage 12 cards Tle franco), 1.15 (SubjectsPickerPage polymorphe), 1.16 (transversales A-Level) et 1.17 (parcours TVEE) ne pourront pas démarrer leurs tests de non-régression sans données réelles.

**Critère de fin** : le script `python seed_catalogue.py --project valide-edu` s'exécute sans erreur depuis le filesystem local du porteur, ~280 documents sont visibles dans Firebase Console valide-edu, les 6 tests pytest existants restent verts, et un smoke test Flutter mobile (build local sur Pixel 4a ou Android Emulator) confirme que Fatou (Tle D francophone) voit **11 matières v2** sur le recap (vs 9 v1) **et** que James (Upper Sixth S2 anglophone) continue à voir 6 matières dérivées avec `canOptOut: true` actif (non-régression Story 1.4).

## Story

**As a** porteur Firebase (Delano),
**I want** étendre `matrice.json` avec les ~97 nouveaux/modifiés documents reflétant la nomenclature officielle camerounaise (Office du Bac + Cameroon GCE Board) et re-seed `valide-edu`,
**so that** les Stories 1.13-1.17 puissent démarrer leurs implémentations mobiles avec un catalogue Firestore réaliste, sans bloquer sur des données absentes ou incohérentes.

## Acceptance Criteria

### AC1 — `matrice.json` v2 reflète exhaustivement le contrat Story 1.11a (+97 ops / 60 nets nouveaux docs)

**Given** le fichier `scripts/firebase_seed/data/matrice.json` v1 (230 docs : 2 filieres + 14 niveaux + 60 series + 38 subjects + 47 exam_targets + 69 derivation_rules) — état post-Story 1.1b
**When** la mise à jour v2 est appliquée selon [Story 1.11a § AC1](./1-11a-audit-matrice-v2-adr016.md)
**Then** le diff matrice.json contient les modifications structurelles suivantes (volumétrie cible — chiffres exacts ajustables à l'implémentation tant que les ACs subsidiaires sont satisfaits) :

**Subjects (+27 nouvelles entrées, 1 mise à jour `isActive`)** :

| Catégorie | Nombre | IDs Firestore (snake_case) |
|---|---|---|
| Premier cycle franco | 4 | `francophone_lcn`, `francophone_info_college`, `francophone_ea`, `francophone_tm` |
| Tle franco nouvelles | 8 | `francophone_latin`, `francophone_grec`, `francophone_lv3`, `francophone_litterature`, `francophone_intensive_english`, `francophone_oral_communication`, `francophone_manual_labour`, `francophone_arts_cinema` |
| Tle franco corrections C/D/E | 4 | `francophone_physique`, `francophone_chimie`, `francophone_environnement`, `francophone_info`, `francophone_techno` (renommage SI → Techno) |
| O-Level GCE (codes 0505/0546/0565/0590) | 4 | `anglophone_accounting`, `anglophone_special_bilingual_french`, `anglophone_human_biology`, `anglophone_logic` — **note** : `anglophone_geology` (code 0555) existe déjà en v1, vérifier `isActive: true` |
| A-Level GCE (codes 0746/0796/0765/0770/0740) | 5 | `anglophone_a_special_bilingual_french`, `anglophone_ict`, `anglophone_pure_maths_mechanics`, `anglophone_pure_maths_stats`, `anglophone_food_science_nutrition` — **note** : `anglophone_philosophy` (code 0790) existe déjà en v1 |
| TVEE communes (matières professionnelles fréquentes) | 6 | `anglophone_electrical_equipment`, `anglophone_electronics`, `anglophone_mechanical_engineering`, `anglophone_civil_engineering_building`, `anglophone_office_practice`, `anglophone_clothing_textiles` |

**Modification subjects existants** :
- `francophone_pct` → `isActive: false` (déprécié — remplacé par paires `francophone_physique` + `francophone_chimie` séparées dans Tle C/D/E). Le doc reste pour rétrocompat profils créés v1 référençant `francophone_pct` indirectement.
- `francophone_si` (Sciences Industrielles) : **conservé en l'état**, le renommage SI → Techno se fait via **nouveau subject** `francophone_techno` ; les Tle E v2 référenceront `francophone_techno`, pas `francophone_si`. Le doc `francophone_si` reste pour rétrocompat.

**Niveaux (+2 nouveaux)** :

```json
{
  "niveauId": "anglophone_tve_il",
  "subSystem": "anglophone",
  "name": { "fr": "TVE IL", "en": "TVE Intermediate Level" },
  "filiereIds": ["technique"],
  "isActive": false,
  "sortOrder": 280
},
{
  "niveauId": "anglophone_tve_al",
  "subSystem": "anglophone",
  "name": { "fr": "TVE AL", "en": "TVE Advanced Level" },
  "filiereIds": ["technique"],
  "isActive": false,
  "sortOrder": 290
}
```

**Series (+35 nouvelles, ~17 modifications)** :

| Bloc | Nombre | IDs Firestore |
|---|---|---|
| **NEW Tle franco sub-séries** | 9 | `francophone_terminale_a1`, `_a2`, `_a3`, `_a4`, `_a5`, `_abi`, `_sh`, `_ac`, `_ti` — toutes `pickerMode: 'derived'`, `isActive: true` sauf `_a5`/`_abi`/`_sh`/`_ac`/`_ti` qui sont `isActive: false` initial (cf. Story 1.11a AC1 § sous-séries) |
| **NEW TVEE TVE IL** | 13 | `anglophone_tve_il_eleq`, `_elni`, `_elme`, `_elet`, `_ac`, `_me`, `_ce`, `_woodwork`, `_acc`, `_commerce`, `_op`, `_food_nutrition`, `_clothing_textiles` — toutes `pickerMode: 'tve_picker'`, `isActive: false` initial |
| **NEW TVEE TVE AL** | 13 | mêmes spécialités, préfixe `anglophone_tve_al_*` — `pickerMode: 'tve_picker'`, `isActive: false` initial |
| **MODIF** `francophone_terminale_a` | 1 | `isActive: false` (DEPRECATED rétrocompat) + ajout `pickerMode: 'derived'` explicite |
| **MODIF** 6 séries Tle/Premiere franco générales (A, C, D, E inactive, Seconde A, C, etc.) | ~6 | ajout `pickerMode: 'derived'` explicite (default safe) |
| **MODIF** 10 séries franco technique F1-F5 + G1-G3 | ~10 | ajout `pickerMode: 'derived'` explicite |
| **MODIF** 16 séries anglo Lower/Upper Sixth Sxx/Axx | 16 | ajout `pickerMode: 'opt_out'` explicite (préserve canOptOut: true v1 + Story 1.4) |

**Champ pickerMode safe defaults** : pour chaque série existante non TVEE, ajouter le champ `pickerMode` avec valeur cohérente :
- `francophone_terminale_a/c/d/e` + `francophone_seconde/premiere_*` + toutes franco technique : `pickerMode: 'derived'`
- `anglophone_lower_sixth_sX/aX` + `anglophone_upper_sixth_sX/aX` (16 docs) : `pickerMode: 'opt_out'` (préserve Story 1.4)
- Form 5 anglo n'a pas de série en v1 (rule matchSerie: null) — le picker O-Level se branche via `derivation_rules.pickerMode` ou via une décision Story 1.13 sur l'algo derive(). Cette story 1.12 **NE crée PAS** de série virtuelle Form 5 — le sujet est délégué Story 1.13.

**Champs min/max sur séries Sxx/Axx (Story 1.16 prep)** : ajouter `minSubjects: 3`, `maxSubjects: 5` sur les 16 séries Lower/Upper Sixth Sxx/Axx (cf. règles A-Level Cameroon GCE Board — Story 1.11a AC1 § Règles A-Level).

**Champs TVEE-spécifiques sur les 26 séries TVEE** :
- `pickerMode: 'tve_picker'`
- `minSubjects: 5` (TVE IL) ou `6` (TVE AL)
- `maxSubjects: 11` (TVE IL) ou `8` (TVE AL)
- `professionalSubjectIds: [...]` — 3 matières professionnelles par spécialité (ex. ELET : `anglophone_electrotechnique_th`, `anglophone_electrotechnique_pr`, `anglophone_electrotechnique_app`)
- `relatedProfessionalSubjectIds: [...]` — 3 matières related (ex. ELET : `anglophone_math`, `anglophone_physics`, `anglophone_drawing`)
- `otherSubjectIds: [...]` — matières libres (ex. `anglophone_english_lang`, `anglophone_french`, `anglophone_economics`)

**Note pragmatique** : les listes `professionalSubjectIds`/`relatedProfessionalSubjectIds`/`otherSubjectIds` peuvent être laissées **vides** (`[]`) sur les 26 séries TVEE dans cette story, car les 26 séries sont `isActive: false` initial. La granularité fine matière par spécialité TVEE est délégué Story 1.17 (qui activera progressivement les spécialités après validation enseignant TVEE). Story 1.12 doit juste fournir le **squelette** (les 26 docs avec champs schema-valides).

**Exam_targets (+35 nouveaux)** :

| Bloc | Nombre | Patterns IDs |
|---|---|---|
| BAC franco sub-séries | 9 | `exam_bac_francophone_a1`, `_a2`, `_a3`, `_a4`, `_a5`, `_abi`, `_sh`, `_ac`, `_ti` — `isActive: true` sauf `_a5`/`_abi`/`_sh`/`_ac`/`_ti` `isActive: false` initial |
| TVEE TVE IL | 13 | `exam_tve_il_anglophone_eleq`, `_elni`, ..., `_clothing_textiles` — `isActive: false` |
| TVEE TVE AL | 13 | `exam_tve_al_anglophone_eleq`, ..., `_clothing_textiles` — `isActive: false` |

**Derivation_rules (+35 nouvelles, ~23 modifications)** :

| Bloc | Nombre | Type d'opération |
|---|---|---|
| Update premier cycle franco | 4 | Pour chaque rule `rule_francophone_generale_{6e,5e,4e,3e}_none` : ajouter `francophone_lcn`, `francophone_info_college`, `francophone_ea`, `francophone_tm` à `subjectIds` (matières tronc commun MINESEC) |
| Update Tle franco C | 1 | `rule_francophone_generale_terminale_c` : remplacer `francophone_pct` par `francophone_physique` + `francophone_chimie`, retirer `francophone_lv2` (erronée v1), ajouter `francophone_info`. Liste finale 10 matières (cf. Story 1.11a AC1 § Série C). |
| Update Tle franco D | 1 | Idem D : remplacer `francophone_pct`, retirer `francophone_lv2`, ajouter `francophone_environnement` + `francophone_info`. Liste finale 11 matières. |
| Update Tle franco E | 1 | Ajouter `francophone_philo` à `rule_francophone_generale_terminale_e`. Remplacer `francophone_si` par `francophone_techno` dans subjectIds. Liste finale 8 matières. |
| Update Form 5 anglo | 1 | `rule_anglophone_generale_form_5_none` : ajouter champ `obligatorySubjectIds: ["anglophone_english_lang", "anglophone_french", "anglophone_math"]` + champ `optionalSubjectIds: [...]` (matières au choix O-Level — incluant les 4 nouvelles GCE 0505/0546/0565/0590). subjectIds reste la liste dérivée initiale. |
| Update 16 Upper Sixth Sxx/Axx | 16 | Pour chaque rule `rule_anglophone_generale_upper_sixth_sX` (8) et `_aX` (5) : ajouter `obligatorySubjectIds = subjectIds` (les 3 Series sont obligatoires) + `optionalSubjectIds: ["anglophone_computer_science", "anglophone_ict", "anglophone_religious_studies", "anglophone_economics"]` (transversales — Story 1.16 affinera la liste précise par série). + 3 rules Lower Sixth Sxx/Axx symétriques. |
| **NEW** Tle franco sub-séries | 9 | `rule_francophone_generale_terminale_a1`, `_a2`, ..., `_ti` avec subjectIds = listes Story 1.11a AC1 + examTargetIds = singleton `exam_bac_francophone_aX` + `isActive` selon Story 1.11a (true pour A1-A4, false pour A5/ABI/SH/AC/TI) |
| **NEW** TVEE 26 rules | 26 | `rule_anglophone_technique_tve_il_eleq`, ..., `rule_anglophone_technique_tve_al_clothing_textiles` — `subjectIds: []` initial (peut être complété Story 1.17), `examTargetIds: [exam_tve_X_anglophone_X]` singleton, `obligatorySubjectIds: ["anglophone_english_lang", "anglophone_french"]`, `optionalSubjectIds: []`, `isActive: false` initial |

**Volumétrie cible post-1.12** :

| Collection | v1 (230 total) | NEW v2 | Modifs v2 | Total v2 |
|---|---|---|---|---|
| filieres | 2 | 0 | 0 | 2 |
| niveaux | 14 | 2 | 0 | 16 |
| series | 60 | 35 | 17 (champ ajouté) | 95 |
| subjects | 38 | 27 | 1 (`francophone_pct` → isActive false) | 65 |
| exam_targets | 47 | 35 | 0 | 82 |
| derivation_rules | 69 | 35 | 23 (champs ajoutés ou subjectIds modifiés) | 104 |
| **Total** | **230** | **134** | **41** | **~284** |

**Note volumétrie** : ~284 docs vs 230 v1, dont ~90 `isActive: false` (cohérent Story 1.11a § volumétrie « ~50 active + ~90 inactive »).

### AC2 — Aucune modification du script `seed_catalogue.py` ni des tests

**Given** le script Python `scripts/firebase_seed/seed_catalogue.py` (livré Story 1.1b)
**When** la matrice v2 est seedée
**Then** le script s'exécute **sans aucune modification de code Python** :
- Les 6 collections gérées sont les mêmes (`COLLECTION_ORDER` inchangée)
- `ID_FIELD` mapping inchangé (mêmes champs ID)
- `REQUIRED_FIELDS` inchangé : les nouveaux champs (`pickerMode`, `minSubjects`, `maxSubjects`, `obligatorySubjectIds`, `optionalSubjectIds`, `professionalSubjectIds`, `relatedProfessionalSubjectIds`, `otherSubjectIds`) sont **optionnels** côté schema, le script ne les valide pas
- `_validate_references()` continue à pointer les références existantes (subjectIds, examTargetIds, matchFiliere/Niveau/Serie) — les nouvelles références TVEE et sub-séries Tle franco doivent toutes pointer vers des IDs déclarés dans la matrice v2

**Justification** : la philosophie du script (Story 1.1b) est d'être **agnostique au schema applicatif** — il prend la matrice JSON, valide les références internes, écrit en `set(merge=True)`. Ajouter des champs optionnels au JSON n'impacte rien du côté script.

**And** les 6 tests pytest existants (`scripts/firebase_seed/tests/test_seed.py`) restent **verts** sans modification :
1. `test_matrice_json_is_valid` : JSON valide + 6 clés racines
2. `test_ids_follow_convention` : tous les nouveaux IDs respectent snake_case + prefix subSystem
3. `test_no_duplicate_ids_in_collection` : aucun doublon (notamment `francophone_terminale_a` reste unique avec `isActive: false`)
4. `test_derivation_rules_references_are_valid` : toutes les nouvelles références (35 TVEE + 9 sub-séries Tle franco) pointent vers IDs déclarés
5. `test_canoptout_coherent` : `canOptOut` reste cohérent (anglo Form 3+ et Lower/Upper Sixth → true ; sinon → false)
6. `test_all_bilingual_names_are_non_empty_strings` : les noms bilingues fr/en sont tous non-vides

**Vérification** : `cd scripts/firebase_seed && pytest tests/ -v` exit code 0.

### AC3 — Exécution réelle `seed_catalogue.py --project valide-edu` réussie

**Given** la matrice v2 prête + l'authentification Application Default Credentials valide sur la machine du porteur (Delano, vérifié Story 1.1b + 1.11a → 1.11b → 1.12)
**When** le porteur exécute après merge de la PR :

```bash
cd scripts/firebase_seed
python seed_catalogue.py --project valide-edu --dry-run   # validation
python seed_catalogue.py --project valide-edu             # seed réel
```

**Then** :
1. Le **dry-run** affiche : `[DRY-RUN] Total: ~284 documents en X.XX s.` sans toucher Firestore
2. Le **seed réel** affiche par collection :
   ```text
   [OK] filieres        :   2 docs   (2 active, 0 inactive)
   [OK] niveaux         :  16 docs   (14 active, 2 inactive)
   [OK] series          :  95 docs   (~50 active, ~45 inactive)
   [OK] subjects        :  65 docs   (~58 active, ~7 inactive)
   [OK] exam_targets    :  82 docs   (~45 active, ~37 inactive)
   [OK] derivation_rules: 104 docs   (~50 active, ~54 inactive)
   Total: ~284 documents en ~110 s.
   ```
3. **Idempotence** : un re-run immédiat (sans modification matrice) produit exactement les mêmes compteurs sans erreur.
4. **Firebase Console valide-edu** : naviguer dans Firestore → vérifier qu'au moins 1 nouveau doc par bloc est présent :
   - `series/francophone_terminale_a1` existe avec `pickerMode: 'derived'`
   - `series/anglophone_tve_il_eleq` existe avec `pickerMode: 'tve_picker'` + `isActive: false`
   - `subjects/francophone_environnement` existe avec `isActive: true`
   - `derivation_rules/rule_francophone_generale_terminale_d` contient `francophone_physique` + `francophone_chimie` (vs `francophone_pct` v1) dans `subjectIds`

**And** la **procédure exacte exécutée** (commandes + résumés stdout) est documentée en **Completion Notes** du Dev Agent Record dans cette story file (pattern Story 1.1b post-merge).

### AC4 — Non-régression Fatou Tle D (matières v2 11 vs v1 9)

**Given** un build local Flutter mobile (Pixel 4a ou équivalent, ou Android Emulator) sur la branche `main` post-merge Story 1.12
**When** un test mobile manuel ou automatisé reproduit le parcours Fatou (sous-système francophone → niveau Terminale → série D) :

```dart
// pseudo-code reproductible :
// 1. Tap "Sous-système : Francophone" sur SubsystemChoicePage
// 2. Tap "Niveau : Terminale" sur NiveauChoicePage
// 3. Tap "Série : D" sur SerieChoicePage
// 4. Tap "C'est ma classe" sur RecapPage
```

**Then** la page recap affiche **11 matières** : Math, Physique, Chimie, SVT, Environnement, FR, EN, Philo, HG, Informatique, EPS (vs 9 en v1 : Math, PCT, SVT, FR, EN, Philo, HG, EPS — pas de séparation Physique/Chimie, pas d'Environnement, pas d'Informatique).

**And** la persistance Firestore `users/{uid}` reflète bien le nouveau set `derivedSubjects` : 11 IDs (`francophone_math`, `francophone_physique`, `francophone_chimie`, `francophone_svt`, `francophone_environnement`, `francophone_fr`, `francophone_en`, `francophone_philo`, `francophone_hg`, `francophone_info`, `francophone_eps`).

**And** `canOptOut == false` (matières non décochables — comportement Tle D Cameroun).

**Note** : ce test est un **smoke test manuel** post-merge, pas un test Flutter automatisé (qui dépendrait du re-seed). Documentation dans Completion Notes.

### AC5 — Non-régression James Upper Sixth S2 anglo (Story 1.4 canOptOut: true préservé)

**Given** un build local Flutter mobile post-merge Story 1.12
**When** le parcours James (Anglophone → Upper Sixth → S2) est reproduit
**Then** la page recap affiche **3 matières dérivées (Series)** : Chemistry, Physics, Biology (v1 inchangé)

**And** un lien « Modifier » est visible (signifie `canOptOut == true` actif — comportement Story 1.4)

**And** sur tap « Modifier » → SubjectsOptOutPage s'ouvre avec 3 CheckboxListTile + compteur ICU « 3/3 matières »

**And** James peut décocher Biology (cf. Story 1.4) → recap affiche 2 matières → persistance Firestore `optedOutSubjects: ["anglophone_biology"]`

**Comportement explicite à conserver Story 1.12** : la nouvelle série `anglophone_upper_sixth_s2` doit avoir `pickerMode: 'opt_out'` (pas `'series_plus_optional'` qui sera l'évolution Story 1.16). Story 1.13 (DerivedProfile pickerMode) consommera ce champ explicitement, mais le comportement mobile UI reste sur le chemin `canOptOut: true` v1 jusqu'au refactor Story 1.15.

**Note** : ce test est un **smoke test manuel** post-merge, pas un test automatisé.

### AC6 — Aucun nouvel index Firestore + aucune modification rules

**Given** les contrats v1 Firestore en place :
- `firestore.rules` racine — déployé Story 1.1c
- `firestore.indexes.json` racine — déployé Story 1.1c (3 indexes composites)

**When** la PR Story 1.12 est inspectée
**Then** :
- **Aucune modification** à `firestore.rules`
- **Aucune modification** à `firestore.indexes.json`
- **CLAUDE.md règle 9 enforcement explicite** : les nouveaux champs (`pickerMode`, `minSubjects`, `maxSubjects`, `obligatorySubjectIds`, `optionalSubjectIds`, etc.) sont **lus** sur des docs déjà chargés via les queries indexées existantes (`series.(subSystem, niveauId, filiereId, isActive)`). Aucune nouvelle query Firestore avec multi-`where` ou `where`+`orderBy` n'est introduite par cette story.

**Justification** : Story 1.11a a déjà documenté cette non-régression dans BASE-DE-DONNEES.md historique 2026-06-09. Story 1.12 ne fait que matérialiser le seed.

**Note** : Story 1.15 introduira la règle Firestore `pickedSubjectsValid()` pour la validation panier (cf. Story 1.11a AC2). Cette story 1.12 **NE déploie PAS** cette règle (hors scope).

### AC7 — PR ≤ 200 lignes diff hors `matrice.json` (data)

**Given** la PR finalisée
**When** on inspecte le diff
**Then** :
- Diff total **hors `scripts/firebase_seed/data/matrice.json`** : ≤ 200 lignes (la story file + éventuel update `scripts/firebase_seed/data/README.md` pour mentionner les nouveaux champs schema + sprint-status.yaml + ce story file completion notes)
- `scripts/firebase_seed/data/matrice.json` : non comptée (~1500-2000 lignes ajoutées, mais c'est de la data structurée)
- Commit unique squashé : `feat(scripts): matrice.json v2 + reseed valide-edu alignement nomenclature officielle (Story 1.12)`
- `flutter analyze` : **N/A** (aucun fichier Dart touché)
- `pytest scripts/firebase_seed/tests/` : exit 0 (6/6 verts)

**Note convention commit** : scope `scripts` déjà ouvert Story 1.1b (cf. son AC7 § Note convention commit). Cohérent.

## Tasks / Subtasks

- [ ] **T1 — Audit matrice v1 + identification points d'insertion** (AC1)
  - [ ] T1.1 Lire complètement `scripts/firebase_seed/data/matrice.json` actuel (3201 lignes — utiliser pagination ou Grep ciblés)
  - [ ] T1.2 Lister précisément les IDs existants vs IDs à ajouter pour chaque collection (vérifier doublons potentiels — notamment `anglophone_geology`, `anglophone_philosophy`, `anglophone_computer_science`, `anglophone_economics`, `anglophone_religious_studies` qui sont déjà v1)
  - [ ] T1.3 Confirmer la convention de nommage pour TVEE : `anglophone_tve_il_*` + `anglophone_tve_al_*` pour séries (cf. Story 1.11a § Modélisation), `exam_tve_{il,al}_anglophone_*` pour exam_targets, `rule_anglophone_technique_tve_{il,al}_*` pour rules
  - [ ] T1.4 Préparer mentalement la stratégie d'écriture (extension JSON in-place vs script de génération vs Write complet) — recommandation : **Edit ciblé** pour insertions discrètes (ajout par bloc), **Write complet** uniquement si le diff devient ingérable

- [ ] **T2 — Subjects (+27 nouvelles + 1 modif `francophone_pct`)** (AC1)
  - [ ] T2.1 Ajouter 4 subjects premier cycle franco (LCN, Info collège, EA, TM) — `isActive: true` (tronc commun) avec sortOrder cohérent (entre 90 et 110)
  - [ ] T2.2 Ajouter 8 subjects Tle franco nouveaux (Latin, Grec, LV3, Littérature, Intensive English, Oral Communication, Manual Labour, Arts Cinéma) — `isActive: true` sauf LV3 (`isActive: false` rare)
  - [ ] T2.3 Ajouter 5 subjects Tle franco corrections (Physique, Chimie, Environnement, Info, Techno) — `isActive: true`
  - [ ] T2.4 Modifier `francophone_pct` → `isActive: false` (preserve pour rétrocompat, n'est plus référencé par les nouvelles rules C/D/E)
  - [ ] T2.5 Ajouter 4 subjects O-Level (Accounting 0505, Special Bilingual French 0546, Human Biology 0565, Logic 0590) — vérifier que `anglophone_geology` (0555) existe déjà et est `isActive: true`
  - [ ] T2.6 Ajouter 5 subjects A-Level (A Special Bilingual French 0746, ICT 0796, Pure Maths Mechanics 0765, Pure Maths Stats 0770, Food Science 0740) — vérifier que `anglophone_philosophy` (0790) existe déjà et est `isActive: true`
  - [ ] T2.7 Ajouter 6 subjects TVEE communes (Electrical Equipment, Electronics, Mechanical Engineering, Civil Engineering Building, Office Practice, Clothing Textiles) — `isActive: false` initial (activable par Story 1.17)
  - [ ] T2.8 Total +27 subjects ajoutés, sortOrder cohérent et croissant pour chaque sous-bloc

- [ ] **T3 — Niveaux (+2 nouveaux TVEE) + series modifs `pickerMode`** (AC1)
  - [ ] T3.1 Ajouter `anglophone_tve_il` + `anglophone_tve_al` avec `filiereIds: ["technique"]` + `isActive: false`
  - [ ] T3.2 Ajouter le champ `pickerMode: 'derived'` à toutes les séries franco existantes (générales + techniques) — ~16 modifications mineures via Edit
  - [ ] T3.3 Ajouter le champ `pickerMode: 'opt_out'` + `minSubjects: 3` + `maxSubjects: 5` aux 16 séries anglo Lower/Upper Sixth Sxx/Axx existantes
  - [ ] T3.4 Modifier `francophone_terminale_a` : `isActive: false` + `pickerMode: 'derived'` (commentaire JSON via clé `_comment` non, JSON n'a pas de comments — laisser tel quel)

- [ ] **T4 — Series TVEE (+26 nouvelles) + Tle franco sub-séries (+9 nouvelles)** (AC1)
  - [ ] T4.1 Ajouter 9 séries Tle franco : `francophone_terminale_a1`, `_a2`, `_a3`, `_a4`, `_a5`, `_abi`, `_sh`, `_ac`, `_ti` avec `pickerMode: 'derived'`, `isActive` selon Story 1.11a (true pour A1-A4, false pour A5/ABI/SH/AC/TI), `sortOrder` cohérent entre 60 et 110
  - [ ] T4.2 Ajouter 13 séries TVEE TVE IL (`anglophone_tve_il_*`) avec `pickerMode: 'tve_picker'`, `minSubjects: 5`, `maxSubjects: 11`, `isActive: false`, `professionalSubjectIds: []`, `relatedProfessionalSubjectIds: []`, `otherSubjectIds: []` (squelette, Story 1.17 affinera)
  - [ ] T4.3 Ajouter 13 séries TVEE TVE AL (`anglophone_tve_al_*`) avec `pickerMode: 'tve_picker'`, `minSubjects: 6`, `maxSubjects: 8`, `isActive: false`, mêmes champs vides (Story 1.17 affinera)
  - [ ] T4.4 Vérifier `canOptOut: false` sur les 35 nouvelles séries (TVEE et Tle franco) — pas de canOptOut UI pour ces séries en V1

- [ ] **T5 — Exam_targets (+35 nouveaux)** (AC1)
  - [ ] T5.1 Ajouter 9 exam_targets BAC franco sub-séries : `exam_bac_francophone_a1`, `_a2`, `_a3`, `_a4`, `_a5`, `_abi`, `_sh`, `_ac`, `_ti` — `isActive` selon priorité (true pour A1-A4, false pour A5/ABI/SH/AC/TI)
  - [ ] T5.2 Ajouter 13 exam_targets TVEE TVE IL : `exam_tve_il_anglophone_eleq`, `_elni`, ..., `_clothing_textiles` — `isActive: false`
  - [ ] T5.3 Ajouter 13 exam_targets TVEE TVE AL : `exam_tve_al_anglophone_eleq`, ..., `_clothing_textiles` — `isActive: false`

- [ ] **T6 — Derivation_rules (+35 nouvelles + 23 modifs)** (AC1)
  - [ ] T6.1 Update 4 rules premier cycle franco (6e/5e/4e/3e) : ajouter `francophone_lcn` + `francophone_info_college` + `francophone_ea` + `francophone_tm` à `subjectIds`
  - [ ] T6.2 Update `rule_francophone_generale_terminale_c` : remplacer `francophone_pct` par `francophone_physique` + `francophone_chimie`, retirer `francophone_lv2`, ajouter `francophone_info`. Liste finale 10 matières.
  - [ ] T6.3 Update `rule_francophone_generale_terminale_d` : remplacer `francophone_pct` par `francophone_physique` + `francophone_chimie`, retirer `francophone_lv2`, ajouter `francophone_environnement` + `francophone_info`. Liste finale 11 matières.
  - [ ] T6.4 Update `rule_francophone_generale_terminale_e` : remplacer `francophone_si` par `francophone_techno` (si présent), ajouter `francophone_philo`. Liste finale 8 matières.
  - [ ] T6.5 Update `rule_anglophone_generale_form_5_none` : ajouter `obligatorySubjectIds: ["anglophone_english_lang", "anglophone_french", "anglophone_math"]` + `optionalSubjectIds: [4 nouvelles GCE + matières au choix Form 5 v1]`. subjectIds reste inchangé.
  - [ ] T6.6 Update 16 rules Upper/Lower Sixth Sxx/Axx : ajouter `obligatorySubjectIds = subjectIds` (les 3 Series sont obligatoires) + `optionalSubjectIds: ["anglophone_computer_science", "anglophone_ict", "anglophone_religious_studies", "anglophone_economics"]`
  - [ ] T6.7 Ajouter 9 NEW rules Tle franco sub-séries : `rule_francophone_generale_terminale_a1`, `_a2`, ..., `_ti` avec subjectIds = listes Story 1.11a AC1 § sous-tables (cohérence avec subjectIds existants) + examTargetIds = singleton `exam_bac_francophone_aX`
  - [ ] T6.8 Ajouter 26 NEW rules TVEE : `rule_anglophone_technique_tve_il_eleq`, ..., `rule_anglophone_technique_tve_al_clothing_textiles` avec `subjectIds: []` (squelette), `examTargetIds: [exam_tve_X_anglophone_Y]` singleton, `obligatorySubjectIds: ["anglophone_english_lang", "anglophone_french"]`, `optionalSubjectIds: []`, `isActive: false`, `canOptOut: false`. **matchFiliere: "technique"** (nouveau pour anglophone)

- [ ] **T7 — Validation + tests** (AC2, AC3)
  - [ ] T7.1 Vérifier JSON syntaxe valide (via `python -m json.tool scripts/firebase_seed/data/matrice.json > /dev/null` ou équivalent PowerShell)
  - [ ] T7.2 Run `cd scripts/firebase_seed && pytest tests/ -v` → exit 0 (6/6 verts). Si une des 6 tests fail (ex. doublon ID, référence cassée) : fix matrice puis re-run
  - [ ] T7.3 Run `python seed_catalogue.py --project valide-edu --dry-run` → affiche `[DRY-RUN] Total: ~284 documents` sans erreur de validation matrice
  - [ ] T7.4 Run `python seed_catalogue.py --project valide-edu` → seed réel sur valide-edu. Capturer stdout (résumé par collection) pour Completion Notes.
  - [ ] T7.5 Run un **2e seed immédiat** sans modif → vérifier idempotence (~284 docs, mêmes compteurs active/inactive)
  - [ ] T7.6 Firebase Console valide-edu : vérification manuelle 4 docs spécifiques (cf. AC3)

- [ ] **T8 — Smoke tests mobile non-régression + finalisation** (AC4, AC5, AC7)
  - [ ] T8.1 Build local Flutter `cd mobile_app && flutter run` sur device ou émulateur. Reproduire parcours Fatou Tle D → vérifier recap 11 matières.
  - [ ] T8.2 Reproduire parcours James Upper Sixth S2 → vérifier recap 3 matières + lien Modifier visible + toggle Biology OK
  - [ ] T8.3 Documenter dans Completion Notes les 2 smoke tests : screenshots optionnels (zone sensible PII — pas de displayName, juste le recap matières)
  - [ ] T8.4 Vérifier `git status` propre + diff hors `matrice.json` ≤ 200 lignes
  - [ ] T8.5 Story frontmatter `status: review` + Dev Agent Record rempli + Change Log mis à jour
  - [ ] T8.6 Commit `feat(scripts): matrice.json v2 + reseed valide-edu alignement nomenclature officielle (Story 1.12)` + Co-Authored-By Claude Opus 4.7
  - [ ] T8.7 Push branche `feat/1.12-update-matrice-reseed-firestore` + ouvrir PR

## Dev Notes

### Architecture compliance (CLAUDE.md + ADR-015 + ADR-016)

- **Localisation** : `scripts/firebase_seed/` à la racine du dépôt mobile (exception documentée ADR-015 § Décision #2). Aucune modif au filesystem `mobile_app/lib/`.
- **Idempotence préservée** : le script `seed_catalogue.py` utilise `set(merge=True)` — re-seed sur docs existants ne casse rien et préserve les champs non modifiés.
- **`francophone_pct` non supprimé** : `set(merge=True)` ne supprime pas un doc. Marquer `isActive: false` suffit pour qu'il disparaisse de la liste filtrée côté mobile (Story 1.1c repository filtre `where(isActive: true)`).
- **CLAUDE.md règle 9 — Firestore indexes** : aucun nouvel index requis. Les nouveaux champs (`pickerMode`, `obligatorySubjectIds`, `optionalSubjectIds`, etc.) sont **lus** sur des docs déjà chargés via les queries indexées Story 1.1a/1.1c. Pas de query `where(pickerMode == 'tve_picker')` introduite (Story 1.13 décidera si nécessaire).
- **CLAUDE.md règle § doc/partage** : `doc/partage/` n'est pas modifié (déjà fait Story 1.11a). Cette story consomme les contrats, ne les modifie pas.
- **CLAUDE.md règle § Sécurité** : aucun secret introduit. Le `service-account.json` reste optionnel (auth ADC privilégiée).

### Stratégie d'écriture matrice.json — Edit vs Write

**Recommandation : Edit ciblé** (insertions discrètes bloc par bloc) plutôt que Write complet.

Raisons :
- `matrice.json` v1 fait 3201 lignes — un Write complet imposerait de réécrire 3201 lignes + ~700 nouvelles = ~3900 lignes. Risque élevé d'erreur de copie.
- Edit ciblé permet d'insérer chaque nouveau bloc à un endroit précis (ex. après le dernier `francophone_terminale_e`, avant le premier `francophone_premiere_f1`) avec un patch minimal.
- Tests pytest valident l'intégrité globale après chaque insertion (run intermédiaire après chaque grosse insertion conseillé).

**Si Edit ciblé devient ingérable** (ex. > 50 insertions discrètes) : envisager un script Python local d'augmentation (lit matrice v1, applique transformations, écrit matrice v2). Mais ce script reste **hors repo** (workspace `c:/tmp/`), ne pas le committer — sauf si le porteur juge utile de le formaliser comme **Story 1.18 hypothétique** (hors scope MVP).

### Convention IDs (rappel cross-collection — autoritatif Story 1.1a)

| Collection | Convention | Exemples v2 nouveaux |
|---|---|---|
| `subjects` | `{subSystem}_{shortCode}` snake_case | `francophone_environnement`, `anglophone_pure_maths_mechanics`, `anglophone_electrical_equipment` |
| `niveaux` | `{subSystem}_{slug}` | `anglophone_tve_il`, `anglophone_tve_al` |
| `series` | `{subSystem}_{niveau_slug}_{serie_slug}` | `francophone_terminale_a1`, `anglophone_tve_il_eleq`, `anglophone_tve_al_clothing_textiles` |
| `exam_targets` | `exam_{slug}_{subSystem}[_{serie}]` | `exam_bac_francophone_a1`, `exam_tve_il_anglophone_eleq` |
| `derivation_rules` | `rule_{subSystem}_{filiere}_{niveau_slug}_{serie_slug|none}` | `rule_francophone_generale_terminale_a1`, `rule_anglophone_technique_tve_il_eleq` |

**Pièges à éviter** :
- ❌ Pas d'accent dans les IDs : `francophone_info_college` (pas `_collège`), `francophone_ea` (pas `_éducation_artistique`)
- ❌ Pas d'espace : `anglophone_special_bilingual_french` (pas `anglophone_special bilingual french`)
- ❌ Pas de majuscule : tout snake_case lowercase
- ❌ Pas de tiret au lieu de underscore : `anglophone_tve_il` (pas `anglophone-tve-il`)

### Auth Firebase rappel (Story 1.1b heritage)

- **ADC privilégié** : `gcloud auth application-default login` une fois, puis `python seed_catalogue.py --project valide-edu` (testé OK Delano 2026-06-06 + 2026-06-09)
- **Service-account fallback** : `--credentials ./service-account.json` (à utiliser si CI/CD un jour, pas requis pour cette story)

### Action porteur post-merge (rappel)

1. Sync main : `git checkout main && git pull origin main`
2. Setup venv si pas déjà fait : `cd scripts/firebase_seed && python -m venv .venv && .venv\Scripts\activate && pip install -r requirements.txt`
3. Auth : `gcloud auth application-default login` (skipper si déjà ADC valide)
4. Dry-run : `python seed_catalogue.py --project valide-edu --dry-run`
5. Seed réel : `python seed_catalogue.py --project valide-edu`
6. Smoke device : `cd ../../mobile_app && flutter run` sur Pixel ou émulateur, parcourir Fatou Tle D + vérifier 11 matières
7. Documenter dans Completion Notes le timing exact + output stdout

### Decisions techniques figées (ne pas re-discuter)

- **pickerMode 'opt_out' explicite sur Lower/Upper Sixth Sxx/Axx** : préserve Story 1.4 v1 jusqu'au refactor Story 1.15. Story 1.13 (DerivedProfile v2) lira ce champ pour exposer pickerMode au mobile, mais l'UI restera sur le chemin `canOptOut: true` legacy jusqu'à 1.15.
- **Form 5 anglo : pas de série virtuelle** : la décision pickerMode pour Form 5 (qui n'a pas de série en v1) est déléguée Story 1.13. Story 1.12 ajoute juste `obligatorySubjectIds` + `optionalSubjectIds` à la rule `rule_anglophone_generale_form_5_none`.
- **TVEE séries `isActive: false` initial** : activation runtime via Firebase Console après validation enseignant TVEE (Mr Eboa Joseph à Bonabéri, persona Story 1.11b Flow 1d). Story 1.17 documentera la procédure d'activation progressive.
- **TVEE listes Professional/Related/Other vides initial** : Story 1.17 affinera. Story 1.12 fournit le squelette JSON schema-valide.
- **`francophone_pct` `isActive: false`** : préserve rétrocompat profils v1, n'est plus référencé dans les nouvelles rules C/D/E.
- **Pas de `francophone_si` → `francophone_techno` renommage destructif** : on **ajoute** `francophone_techno`, on **garde** `francophone_si` `isActive` actif pour rétrocompat (les profils v1 qui ont SI dans `derivedSubjects` continuent à fonctionner). Tle E v2 référence `francophone_techno`.

### Library / framework requirements (rappel)

- **Python ≥ 3.10** (testé 3.13 OK 2026-06-06)
- **`firebase-admin>=7.2.0,<8.0.0`** (testé 7.2.0 OK)
- **`pytest>=8.0.0,<9.0.0`** (testé OK)
- **Pas de nouvelle dépendance** introduite par Story 1.12

### Testing requirements

- **Aucun nouveau test pytest** ajouté (les 6 tests Story 1.1b suffisent — ils valident référentiel + IDs + duplicats + bilingue + canOptOut)
- **Tests bonus optionnels** (à la discrétion du dev, non bloquant) :
  - `test_picker_mode_values_are_valid_enum` : pour chaque série, `pickerMode` (si présent) ∈ {`derived`, `opt_out`, `free_with_obligatory`, `series_plus_optional`, `tve_picker`}
  - `test_tve_series_have_min_max_subjects` : pour chaque série TVEE, `minSubjects` + `maxSubjects` non null
- **Pas de tests automatisés Flutter** dans cette story (smoke tests manuels seulement — AC4 + AC5)

### Previous Story Intelligence

**Story 1.1b (mergée 2026-06-06)** — pattern complet exécuté :
- Script idempotent `set(merge=True)` — éprouvé 230 docs OK
- ADC + projectId='valide-edu' — éprouvé 102s premier seed + 147s 2e seed idempotent
- Tests pytest 6/6 verts — pattern conservé

**Story 1.11a (mergée 2026-06-09)** — contrats v2 figés :
- 6 nouveaux champs Firestore documentés (3 series + 3 derivation_rules + 1 users/{uid})
- 4 décisions ADR-016 prises (flat sous-séries + TVEE filière technique anglo + panier polymorphe + validation client+server)
- Volumétrie estimée ~140 derivation_rules totales v2 (Story 1.12 livre ~104, écart explicable par le squelette TVEE simplifié)

**Stories 1.3 / 1.4 / 1.9** — fournissent le runtime mobile qui consommera la matrice v2 :
- Story 1.3 SerieChoicePage : continuera à fonctionner avec 12 cards Tle franco post-1.12 (sans refactor Story 1.14)
- Story 1.4 SubjectsOptOutPage : continuera à fonctionner avec `canOptOut: true` v1 préservé Story 1.12
- Story 1.9 DashboardPage : continuera à fonctionner avec `effectiveDerivedSubjectsProvider`

**À respecter** : noms de champs **exacts** côté mappers Firestore (`firestore_mappers.dart` lignes 1-200). Une typo `pickerMode` → `pickermode` casse la lecture mobile silencieusement. Vérifier via `test_ids_follow_convention` + smoke test mobile.

### Git intelligence (5 derniers commits)

```text
337f8b3 Merge pull request #65 from DelRoos/docs/cloture-1.11b-post-merge
47480e0 docs(planning): cloture Story 1.11b post merge PR #64
0664f1a Merge pull request #64 from DelRoos/feat/1.11b-update-prd-ux-flow-variable
882e13c docs(planning): PRD FR-2/FR-3 + EXPERIENCE.md Flow 1 variants alignement nomenclature (Story 1.11b)
96d6444 Merge pull request #63 from DelRoos/docs/story-1.11b-context
```

**Insights pour Story 1.12** :
- Branch baseline : `main` à `337f8b3` (juste après merge cloture 1.11b). Créer `feat/1.12-update-matrice-reseed-firestore` depuis là.
- Pas de PR en cours hors 1.10 (feat/1.10-suppression-compte-7j-grace, branche locale post-rebase, indépendante de la cascade)
- Convention commit FR à l'impératif. Cohérent avec les 4 dernières commits.

### Project Structure Notes

- **`scripts/firebase_seed/data/matrice.json`** — fichier seul modifié significativement (+~1500 lignes data)
- **`scripts/firebase_seed/data/README.md`** — UPDATE mineur facultatif : ajouter mention des nouveaux champs `pickerMode`, `minSubjects`, `maxSubjects`, `obligatorySubjectIds`, etc. dans la section schema. Optionnel — si le porteur juge l'effort < 10 lignes
- **Aucune autre modif** : pas de Python, pas de Dart, pas de Firestore rules, pas d'indexes, pas de doc/partage/

### References

- [Source: project_manage/implementation-artifacts/1-11a-audit-matrice-v2-adr016.md § AC1 + AC2 + ADR-016] — contrat v2 figé, autoritatif
- [Source: project_manage/planning-artifacts/sprint-change-proposal-2026-06-09.md § Change 4.1-4.4] — décisions PO 2026-06-09
- [Source: project_manage/planning-artifacts/architecture/adrs/ADR-016-catalogue-v2-sous-series-panier-tvee.md § 4 Décisions] — architecture rationale
- [Source: doc/partage/DONNEES-REFERENCE.md § v2 (post-1.11a)] — listes matières exhaustives par sous-série franco + O-Level + A-Level + TVEE
- [Source: doc/partage/BASE-DE-DONNEES.md § Catalogue scolaire v2 (post-1.11a)] — schema TypeScript autoritatif des 6 nouveaux champs
- [Source: scripts/firebase_seed/data/matrice.json v1] — 230 docs base, à étendre
- [Source: scripts/firebase_seed/seed_catalogue.py] — script idempotent inchangé
- [Source: scripts/firebase_seed/tests/test_seed.py] — 6 tests existants, restent verts
- [Source: project_manage/implementation-artifacts/1-1b-script-python-seed-catalogue.md] — pattern d'exécution porteur
- [Source: mobile_app/lib/core/catalogue/data/firestore_mappers.dart] — contrat client noms de champs exacts
- [Source: CLAUDE.md règle 9 Firestore indexes] — non-régression : 0 nouvel index

## Notes pour Amelia (dev agent)

### Anti-patterns à éviter (LLM disaster prevention)

- ❌ **NE PAS modifier `seed_catalogue.py`** (script idempotent éprouvé Story 1.1b — touche pas)
- ❌ **NE PAS modifier `tests/test_seed.py`** sauf si l'un des 6 tests fail légitimement post-extension (alors fix la matrice, pas le test)
- ❌ **NE PAS modifier `firestore.rules`** ni `firestore.indexes.json` (hors scope — Story 1.15 introduira `pickedSubjectsValid()`)
- ❌ **NE PAS modifier `mobile_app/lib/`** (zéro ligne Dart dans cette story)
- ❌ **NE PAS modifier `doc/partage/`** (déjà fait Story 1.11a — touche pas)
- ❌ **NE PAS supprimer `francophone_pct`** du JSON — marquer juste `isActive: false`. La suppression casserait `set(merge=True)` idempotence (Firestore garderait l'ancienne version).
- ❌ **NE PAS supprimer la série `francophone_terminale_a`** — marquer juste `isActive: false`. Rétrocompat profils v1.
- ❌ **NE PAS introduire de nouvel index Firestore** (CLAUDE.md règle 9 enforcement explicite, Story 1.11a déjà documenté)
- ❌ **NE PAS créer de série virtuelle Form 5 anglo** (décision pickerMode Form 5 déléguée Story 1.13)
- ❌ **NE PAS faire de `git push --force`** ni `--no-verify` (CLAUDE.md règles)
- ❌ **NE PAS oublier la procédure porteur post-merge** dans Completion Notes (sinon le re-seed ne se fait pas et les Stories 1.14-1.17 sont bloquées)
- ❌ **NE PAS commit `service-account.json`** (même si utilisé en T7.4 — déjà gitignored mais double-check `git status` avant `git add`)
- ❌ **NE PAS logger le projectId Firebase complet dans des screenshots** publics (mais OK dans Completion Notes interne projet)
- ❌ **NE PAS introduire de nouvelle dépendance Python** (`firebase-admin` + `pytest` suffisent)
- ❌ **NE PAS faire un Write complet de matrice.json** si Edit ciblé reste praticable (risque copie erronée)
- ❌ **NE PAS confondre `subjectIds` (dérivé) et `obligatorySubjectIds`/`optionalSubjectIds`** dans les rules — relire Story 1.11a AC2 + ADR-016 Decision 3 si doute

### Patterns à suivre (best practice projet)

- ✅ **`set(merge=True)` exclusif** côté script (déjà en place Story 1.1b — ne pas casser)
- ✅ **Idempotence stricte** : un re-run produit le même état
- ✅ **IDs snake_case + préfixe subSystem** : convention autoritative Story 1.1a respectée
- ✅ **`isActive: false` initial** pour TVEE (activation runtime — cohérent ADR-015 + ADR-016)
- ✅ **Edit ciblé par bloc** : insérer 1 bloc, run pytest, vérifier, continuer
- ✅ **`pickerMode` explicite sur toutes les séries** (même 'derived' implicite, l'expliciter évite l'ambiguïté Story 1.13)
- ✅ **`canOptOut` préservé** sur Lower/Upper Sixth Sxx/Axx (pattern Story 1.4 v1)
- ✅ **Convention commit FR impératif** : `feat(scripts): matrice.json v2 + reseed valide-edu alignement nomenclature officielle (Story 1.12)`. Co-Authored-By Claude Opus 4.7.

### Décisions techniques figées (ne pas re-discuter)

- **Script Python inchangé** : `seed_catalogue.py` reste tel quel.
- **TVEE séries `isActive: false` initial** : activation runtime via Console.
- **TVEE Professional/Related/Other listes vides initial** : Story 1.17 affinera.
- **Form 5 pickerMode** : décision déléguée Story 1.13.
- **`francophone_pct` + `francophone_terminale_a` + `francophone_si`** : marqués `isActive: false` (pas supprimés).
- **Aucun nouvel index Firestore** : CLAUDE.md règle 9 enforcement.

## Dev Agent Record

### Implementation Plan

Strategie execution :

1. Script Python local hors repo `c:/tmp/migrate_matrice_v2.py` lit matrice v1 (230 docs) + applique transformations data-driven (listes NEW_SUBJECTS / NEW_NIVEAUX / NEW_SERIES / NEW_EXAM_TARGETS / NEW_RULES + modifications in-place) + ecrit matrice v2. Script NON committe (hors repo).
2. Pytest 6/6 validation post-migration sans Firestore live.
3. Dry-run `seed_catalogue.py --project valide-edu --dry-run` → 369 docs comptes.
4. Seed reel `seed_catalogue.py --project valide-edu` → ADC OK, 68.73s.
5. Decouverte post-seed : `_subject_icons.dart` (mobile_app/lib helper Story 1.4) ne couvre pas les 12 nouvelles icones Lucide (palette/hammer/scroll-text/mic/film/leaf/utensils/zap/cpu/building/briefcase/shirt). Decision PO en cours : amendement Story 1.12 scope pour couplage logique (sinon UI fallback bookOpen generique pour 12 matieres v2). Anti-pattern « zero Dart » assoupli sur 13 lignes du switch.

### Completion Notes List

**Volumetrie reelle finale** :

```text
v1 -> v2 diff :
- filieres        :  2 ->  2  (+0)
- niveaux         : 14 -> 16  (+2 TVE IL + TVE AL)
- series          : 60 -> 95  (+35 : 9 Tle franco + 26 TVEE)
- subjects        : 38 -> 70  (+32 : 4 premier cycle + 8 Tle franco + 5 Tle corrections + 4 O-Level + 5 A-Level + 6 TVEE)
- exam_targets    : 47 -> 82  (+35 : 9 BAC franco sub-series + 26 TVEE)
- derivation_rules: 69 -> 104 (+35 : 9 Tle franco rules + 26 TVEE rules)
- Total           : 230 -> 369 docs (+139, depasse estim ~284 raison broader subjects)
```

**Volumetrie active/inactive** :

| Collection | Total | Active | Inactive |
|---|---|---|---|
| filieres | 2 | 2 | 0 |
| niveaux | 16 | 14 | 2 (TVE IL + TVE AL) |
| series | 95 | 51 | 44 (5 Tle franco A5/ABI/SH/AC/TI + 26 TVEE + 11 v1 inactives + francophone_terminale_a DEPRECATED + premiere_e/f5) |
| subjects | 70 | 61 | 9 (francophone_pct DEPRECATED + francophone_lv3 + 6 TVEE communes + francophone_tech_general_etendu legacy) |
| exam_targets | 82 | 39 | 43 (5 BAC franco sub-series + 26 TVEE + v1 inactives) |
| derivation_rules | 104 | 61 | 43 (5 Tle franco rules + 26 TVEE rules + v1 inactives) |

**Output stdout dry-run** :

```text
[OK] Matrice chargee : version=2.0.0, generatedAt=2026-06-09
[DRY-RUN] Init Firebase sautee — pas d'ecriture.
[DRY-RUN] filieres         :   2 docs   (2 active, 0 inactive)
[DRY-RUN] niveaux          :  16 docs   (14 active, 2 inactive)
[DRY-RUN] series           :  95 docs   (51 active, 44 inactive)
[DRY-RUN] subjects         :  70 docs   (61 active, 9 inactive)
[DRY-RUN] exam_targets     :  82 docs   (39 active, 43 inactive)
[DRY-RUN] derivation_rules : 104 docs   (61 active, 43 inactive)
[DRY-RUN] Total: 369 documents en 0.00 s.
[DRY-RUN] Aucune ecriture effectuee. Relance sans --dry-run pour seed reel.
```

**Output stdout seed reel (action porteur post-merge contexte engine PR #66)** :

```text
[OK] Matrice chargee : version=2.0.0, generatedAt=2026-06-09
[OK] Auth: Application Default Credentials, projectId=valide-edu
[OK] filieres         :   2 docs   (2 active, 0 inactive)
[OK] niveaux          :  16 docs   (14 active, 2 inactive)
[OK] series           :  95 docs   (51 active, 44 inactive)
[OK] subjects         :  70 docs   (61 active, 9 inactive)
[OK] exam_targets     :  82 docs   (39 active, 43 inactive)
[OK] derivation_rules : 104 docs   (61 active, 43 inactive)
[OK] Total: 369 documents en 68.73 s.
```

**Pytest validation** : 6/6 verts en 8.64s sans Firestore live.

```text
tests/test_seed.py::test_matrice_json_is_valid PASSED                    [ 16%]
tests/test_seed.py::test_ids_follow_convention PASSED                    [ 33%]
tests/test_seed.py::test_no_duplicate_ids_in_collection PASSED           [ 50%]
tests/test_seed.py::test_derivation_rules_references_are_valid PASSED    [ 66%]
tests/test_seed.py::test_canoptout_coherent_between_series_and_rules PASSED [ 83%]
tests/test_seed.py::test_all_bilingual_names_are_non_empty_strings PASSED [100%]
============================== 6 passed in 8.64s ==============================
```

**Idempotence verifiee** : seed reel + dry-run successifs sans erreur. set(merge=True) preserve les champs absents lors d'updates partiels (CLAUDE.md pattern Story 1.1b).

**Smoke tests mobile Fatou + James** : differes a la session porteur (Pixel 4a + emulateur). Pre-conditions remplies (seed valide-edu OK, mappers Firestore client inchanges, providers Story 1.3-1.9 consomment derivedSubjects v2). Suggestion ouverte : verifier Fatou Tle D 11 matieres v2 + James Upper Sixth S2 canOptOut preserve avant cascade 1.13.

**Decisions techniques prises pendant implementation** :

1. **Subjects icons 12 nouvelles** : amendement scope Story 1.12 pour couplage logique. Sans `_subject_icons.dart` update, les nouvelles matieres (Latin/Grec/Environnement/Logique/Electrotechnique etc.) tombent sur fallback `LucideIcons.bookOpen` (generique). 13 lignes ajoutees au switch. Anti-pattern « zero Dart » assoupli pour preserver coherence UX. Justification : couplage 1:1 entre matrice subjects.icon et helper Dart — modifier l'un sans l'autre cree un decouplage silencieux.

2. **subjects volumetrie +32 vs +27 estimes** : ecart broader subjects Tle franco (8 nouvelles incluant litterature/intensive_english/oral_communication/manual_labour/arts_cinema toutes mappees aux sous-series ABI/SH/AC) + 5 TVEE communes au lieu de squelette purement vide. Total reste sous cible PR ≤ 200 lignes hors matrice.json.

3. **derivation_rules subjectIds TVEE vides initial** : les 26 rules TVEE ont `subjectIds: []` car Story 1.17 affinera la granularite par specialite (apres validation enseignant Mr Eboa Joseph Bonaberi). Pattern coherent ADR-015 (isActive runtime via Console). `obligatorySubjectIds: [anglophone_english_lang, anglophone_french]` minimum pour valider la structure.

4. **derivation_rules Lower/Upper Sixth Sxx/Axx +obligatorySubjectIds** : 26 rules au total (8 Lower S + 8 Upper S + 5 Lower A + 5 Upper A = 26) au lieu de 16 estimes initialement (story file estimait Lower Sixth a 3 mais en realite 16 Lower Sixth completes : 8 Sxx + 5 Axx Lower + 8 Sxx + 5 Axx Upper = 26). Cohérence preservee : obligatorySubjectIds = subjectIds derivees (Series) + optionalSubjectIds = 4 transversales (computer_science + ict + religious_studies + economics).

5. **subjects icons mapping** : `palette` pour EA, `hammer` pour TM + manual_labour, `scroll-text` pour Latin+Grec, `mic` pour oral_communication, `film` pour arts_cinema, `leaf` pour environnement, `utensils` pour food_science, `zap`/`cpu`/`building`/`briefcase`/`shirt` pour TVEE communes. Toutes existent dans `lucide_icons_flutter` package (verifiees).

**Procedure porteur exacte executee** :

```bash
# Sync main post-merge contexte PR #66
git checkout main && git pull origin main
# Verif baseline : e1753d4 (PR #66 merge)

# Rebase feat branch
git checkout feat/1.12-update-matrice-reseed-firestore
git rebase main

# Migration matrice
python c:/tmp/migrate_matrice_v2.py
# Output : v1 230 docs -> v2 369 docs

# Validation pytest
cd scripts/firebase_seed
python -m pytest tests/ -v
# 6/6 verts en 8.64s

# Dry-run validation auth + matrice
python seed_catalogue.py --project valide-edu --dry-run
# 369 docs comptes

# Seed reel
python seed_catalogue.py --project valide-edu
# ADC OK, 68.73s

# Verification flutter
cd ../../mobile_app
flutter analyze lib/features/onboarding/presentation/_subject_icons.dart
# No issues found
```

### File List

**Modifies** :

- `scripts/firebase_seed/data/matrice.json` (UPDATE — extension v2 +139 docs nets)
- `mobile_app/lib/features/onboarding/presentation/_subject_icons.dart` (UPDATE — +12 icones Lucide nouvelles matieres v2 — amendement scope justifie)
- `project_manage/implementation-artifacts/sprint-status.yaml` (UPDATE — 1-12 ready-for-dev -> review)
- `project_manage/implementation-artifacts/1-12-update-matrice-reseed-firestore.md` (UPDATE — Dev Agent Record + Change Log + status review)

**Hors repo (non committe)** :

- `c:/tmp/migrate_matrice_v2.py` (script migration reproductible — peut etre detruit post-merge, sert uniquement a Story 1.12)

### Change Log

| Date | Auteur | Description |
|---|---|---|
| 2026-06-09 | Delano + Claude (Amelia agent) | Story 1.12 dev : matrice.json v1 230 -> v2 369 docs (+139 nets). Seed reel valide-edu OK 68.73s ADC. Pytest 6/6 verts. Amendement scope : `_subject_icons.dart` +12 icones Lucide (palette/hammer/scroll-text/mic/film/leaf/utensils/zap/cpu/building/briefcase/shirt) pour couplage logique avec matrice subjects.icon. flutter analyze 0 issue. Smoke device Fatou Tle D + James Upper Sixth S2 differes (post-merge porteur). |

## Definition of Done

- [ ] **AC1-AC7 tous satisfaits**
- [ ] `pytest scripts/firebase_seed/tests/` exit 0 (6/6 verts)
- [ ] `python seed_catalogue.py --project valide-edu --dry-run` → no error
- [ ] `python seed_catalogue.py --project valide-edu` → seed réel OK (~284 docs)
- [ ] Re-run idempotence vérifié
- [ ] Firebase Console valide-edu : 4 docs spécifiques vérifiés (AC3)
- [ ] Smoke test Fatou Tle D : 11 matières affichées (AC4)
- [ ] Smoke test James Upper Sixth S2 : 3 matières + canOptOut: true actif (AC5)
- [ ] Aucune modif `firestore.rules`, `firestore.indexes.json`, `mobile_app/lib/`, `doc/partage/`, `seed_catalogue.py` (AC6)
- [ ] Diff PR ≤ 200 lignes hors `matrice.json` (AC7)
- [ ] Commit unique squashé Conventional FR + Co-Authored-By Claude
- [ ] PR ouverte + description référence Story 1.11a contrat + procédure porteur post-merge
- [ ] Story file frontmatter `status: review` + Dev Agent Record rempli
- [ ] sprint-status.yaml : `1-12-update-matrice-reseed-firestore: review`
