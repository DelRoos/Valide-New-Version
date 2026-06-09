---
story_id: 1.11a
title: Audit matrice exhaustive v2 + ADR-016 modélisation + BASE-DE-DONNEES.md update
epic: 1
phase: P1 extension v2 (sprint change 2026-06-09)
status: ready-for-dev
created: 2026-06-09
estimation: S (~3h)
sprint_change: sprint-change-proposal-2026-06-09.md (mergé PR #59 commit 3f69c9d sur main e1eb9fa)
dependencies:
  - 1.1a — done (matrice v1 + 6 collections Firestore + ADR-015 en place, base de référence à étendre)
  - 1.1b — done (matrice.json + seed script Python en place, sera étendue par Story 1.12 après 1.11a)
  - 1.1c — done (CatalogueRepository mobile en place, sera étendu par Story 1.13 après 1.11a)
blocks:
  - 1.11b — update PRD FR-2/FR-3 + EXPERIENCE.md Flow 1 variants (a besoin des contrats v2 figés)
  - 1.12 — update matrice.json + re-seed Firestore (a besoin du schema v2 figé)
  - 1.13 — DerivedProfile v2 pickerMode (a besoin du schema v2 figé)
  - 1.14, 1.15, 1.16, 1.17 — implementation mobile (dépendent de 1.13)
sourceArtifacts:
  - project_manage/planning-artifacts/epics/epic-1-onboarding.md § Story 1.11a (sections nouvelles sprint change 2026-06-09)
  - project_manage/planning-artifacts/sprint-change-proposal-2026-06-09.md (décisions PO + 4 changements proposés)
  - project_manage/planning-artifacts/sprint-change-proposal-2026-06-05.md (référence pattern story 1.1a)
  - project_manage/implementation-artifacts/1-1a-audit-matrice-firestore-schema.md (référence structure + format)
  - doc/partage/DONNEES-REFERENCE.md (matrice v1 🟢 à étendre v2)
  - doc/partage/BASE-DE-DONNEES.md § Catalogue scolaire (6 collections à étendre avec nouveaux champs)
  - doc/partage/ALGORITHMES.md § 1 (algo derive à enrichir)
  - project_manage/planning-artifacts/architecture/adrs/ADR-015-catalogue-firestore-runtime-activation.md (référence pour ADR-016 cohérence)
  - project_manage/planning-artifacts/architecture/architecture.md § 14 Catalogue d'ADRs (à étendre)
  - Office du Baccalauréat camerounais (officedubac.cm) — Nomenclature ESG + ESTP francophone (séries A1-A5/ABI/SH/AC/TI + F6/F7/F8 + AF + BT/BP/BEP)
  - Cameroon GCE Board (camgceb.org) — Syllabus O-Level (21 codes 0505-0595) + A-Level (20 codes 0705-0796) + TVEE règles (TVE IL min 5 + TVE AL min 6 max 8)
  - Doc utilisateur 2026-06-09 "Orientation et matières au secondaire camerounais" (synthèse complète sources)
accord_requis:
  - "Backend team : 6 nouveaux champs Firestore (3 sur series : pickerMode + minSubjects + maxSubjects ; 2 sur derivation_rules : obligatorySubjectIds + optionalSubjectIds ; 1 sur users/{uid} : pickedSubjects). CLAUDE.md règle § doc/partage applicable."
amendments_downstream:
  - "Stories 1.1c (DerivedProfile model) + 1.3 (SerieChoicePage) + 1.4 (SubjectsOptOutPage) seront amendées par Stories 1.13 + 1.14 + 1.15 respectivement. Non-breaking via defaults safe."
---

# Story 1.11a — Audit matrice exhaustive v2 + ADR-016 modélisation + BASE-DE-DONNEES.md update

Status: **ready-for-dev**

## Objectif

Livrer les **contrats v2** (docs + ADR + schema) du sprint change 2026-06-09 acté par [sprint-change-proposal-2026-06-09.md](../planning-artifacts/sprint-change-proposal-2026-06-09.md), qui aligne le catalogue Valide School avec la **nomenclature officielle camerounaise** (Office du Baccalauréat francophone + Cameroon GCE Board anglophone) :

1. **Matrice v2 exhaustive** dans [DONNEES-REFERENCE.md](../../doc/partage/DONNEES-REFERENCE.md) — extension matrice v1 livrée par Story 1.1a (🟢 toutes classes v1) :
   - **Premier cycle francophone** : +4 matières (Langues et Cultures Nationales, Informatique, Éducation Artistique, Travail Manuel)
   - **Tle francophone générale** : +9 sous-séries (A1, A2, A3, A4, A5, ABI, SH, AC, TI) + corrections séries C/D (séparer Physique+Chimie ; retirer LV2 erronée ; ajouter Informatique + Environnement) + correction série E (ajouter Philo)
   - **O-Level anglophone** : +4 matières manquantes (0546 Special Bilingual French, 0555 Geology, 0565 Human Biology, 0590 Logic) + 1 ajout Accounting (0505)
   - **A-Level anglophone** : +3 matières manquantes (0746 Bilingual French, 0790 Philosophy, 0796 ICT) + variantes Maths (0765 Pure Maths Mechanics, 0770 Pure Maths Statistics) + 0740 Food Science Nutrition
   - **Sous-système ESTP anglophone (TVEE)** : nouveau (TVE IL + TVE AL × 13 spécialités industrielles/commerciales/Home Economics, isActive=false initial)

2. **Schema Firestore v2** dans [BASE-DE-DONNEES.md](../../doc/partage/BASE-DE-DONNEES.md) — extension non-breaking schema v1 livré par Story 1.1a :
   - `series` : +3 champs (`pickerMode: enum`, `minSubjects: number?`, `maxSubjects: number?`)
   - `derivation_rules` : +2 champs (`obligatorySubjectIds: string[]`, `optionalSubjectIds: string[]`)
   - `series` TVEE spécifiques : +3 champs (`professionalSubjectIds: string[]`, `relatedProfessionalSubjectIds: string[]`, `otherSubjectIds: string[]`)
   - `users/{uid}` : +1 champ optionnel (`pickedSubjects: string[]`) pour profils créés en mode panier
   - Aucun nouvel index Firestore (les nouveaux champs sont lus sur docs filtrés par indexes existants)

3. **ADR-016** créé : *« Catalogue v2 : sous-séries flat francophone + TVEE filière technique anglophone + panier polymorphe via pickerMode »* avec 4 décisions clés et alternatives rejetées.

4. **ALGORITHMES.md § 1** amendé : algo `derive()` retourne `DerivedProfile` v2 enrichi (champs `pickerMode`, `obligatorySubjects`, `optionalSubjects`, `minSubjects`, `maxSubjects`). Pseudo-code mis à jour.

5. **architecture.md § 14 Catalogue d'ADRs** : ajout référence ADR-016 (suivant ADR-015 existant).

6. **Accord backend** sur BASE-DE-DONNEES.md updates (CLAUDE.md règle § doc/partage).

**Pourquoi** : sans contrats v2 figés, ni la story 1.11b (PRD/UX), ni la 1.12 (re-seed Firestore), ni la 1.13 (DerivedProfile model) ne peuvent démarrer. Cette story est **bloquante** pour l'extension Epic 1 v2.

**Critère de fin** : la PR est mergée, backend a approuvé BASE-DE-DONNEES.md updates, ADR-016 référencé dans architecture.md § 14, et un dev peut lire les 6 nouveaux champs Firestore + types attendus + nouvelles règles de validation sans ambiguïté pour implémenter 1.12, 1.13, 1.14, 1.15, 1.16, 1.17.

## Story

**As a** product owner Valide,
**I want** une matrice v2 exhaustive alignée nomenclature officielle (Office du Bac + Cameroon GCE Board) ET un schema Firestore v2 documenté (5 nouveaux champs catalogue + 1 champ `users/{uid}`) + ADR-016 + amendement ALGORITHMES.md,
**so that** Stories 1.11b (PRD/UX), 1.12 (matrice.json + reseed), 1.13 (DerivedProfile pickerMode) et la cascade 1.14-1.17 puissent démarrer en parallèle avec des contrats clairs, et que l'admin pédagogique puisse activer/désactiver les nouvelles séries/spécialités runtime via Firebase Console.

## Acceptance Criteria

### AC1 — Matrice v2 exhaustive dans DONNEES-REFERENCE.md (🟢 → 🟢 v2)

**Given** le doc actuel `doc/partage/DONNEES-REFERENCE.md` (matrice v1 🟢 toutes classes — Story 1.1a)
**When** l'extension v2 est appliquée selon la nomenclature officielle camerounaise
**Then** les sections suivantes sont amendées :

**§ Sous-système francophone — Premier cycle (collège)** : la table § « Matières du premier cycle (tronc commun) » (existante) reçoit 4 nouvelles entrées documentées comme matières officielles MINESEC manquantes en v1 :

| ID Firestore | Matière | Niveaux |
|---|---|---|
| `francophone_lcn` | Langues et Cultures Nationales | 6ᵉ, 5ᵉ, 4ᵉ, 3ᵉ |
| `francophone_info_collège` | Informatique (collège) | 6ᵉ → 3ᵉ (distincte de l'Informatique Tle scientifique) |
| `francophone_ea` | Éducation Artistique | 6ᵉ, 5ᵉ, 4ᵉ, 3ᵉ |
| `francophone_tm` | Travail Manuel | 6ᵉ, 5ᵉ, 4ᵉ, 3ᵉ |

**And** § « Second cycle ESG — séries et leurs matières » : 9 nouvelles sous-tables ajoutées **après** la table existante § « Série A (littéraire) » (qui reste documentée mais marquée `isActive: false` post-1.12 — fallback rétrocompat) :

| Série | Statut catalogue | Matières (IDs Firestore) |
|---|---|---|
| **A1 Lettres + Latin + Grec** | NEW — `isActive: true` post-1.12 (priorité haute) | `francophone_fr`, `francophone_en`, `francophone_math`, `francophone_philo`, `francophone_hg`, `francophone_eps`, `francophone_latin`, `francophone_grec`, `francophone_lv2` |
| **A2 Lettres + Latin + LV2** | NEW | `francophone_fr`, `francophone_en`, `francophone_math`, `francophone_philo`, `francophone_hg`, `francophone_eps`, `francophone_latin`, `francophone_lv2` |
| **A3 Lettres + Latin** | NEW | `francophone_fr`, `francophone_en`, `francophone_math`, `francophone_philo`, `francophone_hg`, `francophone_eps`, `francophone_latin` |
| **A4 Lettres + LV2 + Philo** | NEW | `francophone_fr`, `francophone_en`, `francophone_math`, `francophone_philo`, `francophone_hg`, `francophone_eps`, `francophone_lv2` |
| **A5 LV2 + LV3 + Philo** | NEW — `isActive: false` initial (LV3 rare) | `francophone_fr`, `francophone_en`, `francophone_math`, `francophone_philo`, `francophone_hg`, `francophone_eps`, `francophone_lv2`, `francophone_lv3` |
| **ABI Lettres bilingues** | NEW — `isActive: false` initial (option locale) | `francophone_fr`, `francophone_en`, `francophone_litterature`, `francophone_philo`, `francophone_hg`, `francophone_math`, `francophone_intensive_english`, `francophone_oral_communication`, `francophone_manual_labour` |
| **SH Sciences Humaines** | NEW — `isActive: false` initial | `francophone_fr`, `francophone_en`, `francophone_math`, `francophone_philo`, `francophone_hg`, `francophone_eps` |
| **AC Art et Cinématographie** | NEW — `isActive: false` initial (option marginale) | `francophone_fr`, `francophone_en`, `francophone_arts_cinema`, `francophone_philo`, `francophone_hg`, `francophone_eps` |
| **TI Technologie de l'Information** | NEW — `isActive: false` initial (lycée technique uniquement) | `francophone_math`, `francophone_physique`, `francophone_info` (algo+prog+BD+réseaux), `francophone_fr`, `francophone_philo`, `francophone_en`, `francophone_eps` |

**And** § « Série C » et § « Série D » existantes sont **corrigées** :

- **Série C** : remplacer `francophone_pct` par 2 entrées séparées `francophone_physique` + `francophone_chimie`. **Retirer** `francophone_lv2` (erronée v1). **Ajouter** `francophone_info`. Liste finale 10 matières : Math, Physique, Chimie, SVT, FR, EN, Philo, HG, Informatique, EPS.
- **Série D** : remplacer `francophone_pct` par 2 entrées séparées `francophone_physique` + `francophone_chimie`. **Retirer** `francophone_lv2`. **Ajouter** `francophone_environnement` (Environnement/Hygiène/Biotechnologie) + `francophone_info`. Liste finale 11 matières : Math, SVT, Physique, Chimie, Environnement, FR, EN, Philo, HG, Informatique, EPS.

**And** § « Série E » existante est **corrigée** : **Ajouter** `francophone_philo`. Conserver `francophone_si` (Sciences Industrielles) → renommer en `francophone_techno` (Techniques/Technologie) pour cohérence terminologique. Liste finale 8 matières : Math, Physique, Chimie, Techniques/Technologie, FR, Philo, EN, EPS.

**And** § « Tableau de dérivation `(subSystem, filiere, niveau, serie) → examTargetIds` — Francophone 2nd cycle général » : table étendue avec 9 nouvelles lignes pour A1-A5/ABI/SH/AC/TI :

```markdown
| francophone | générale | Terminale | A1 | exam_bac_francophone_a1 | non |
| francophone | générale | Terminale | A2 | exam_bac_francophone_a2 | non |
| francophone | générale | Terminale | A3 | exam_bac_francophone_a3 | non |
| francophone | générale | Terminale | A4 | exam_bac_francophone_a4 | non |
| francophone | générale | Terminale | A5 | exam_bac_francophone_a5 | non |
| francophone | générale | Terminale | ABI | exam_bac_francophone_abi | non |
| francophone | générale | Terminale | SH | exam_bac_francophone_sh | non |
| francophone | générale | Terminale | AC | exam_bac_francophone_ac | non |
| francophone | générale | Terminale | TI | exam_bac_francophone_ti | non |
```

**And** la ligne existante `francophone | générale | Terminale | A` est annotée « DEPRECATED — conservée pour rétrocompat données existantes. Les nouveaux élèves Tle A choisissent A1-A5/ABI/SH/AC. `isActive: false` post-1.12. »

**And** § « Anglophone — secondary (O Level) — Matières fréquentes au O Level » : table étendue avec 5 nouvelles matières (codes GCE officiels en annotation) :

| ID Firestore | Code GCE | Matière |
|---|---|---|
| `anglophone_accounting` | 0505 | Accounting |
| `anglophone_special_bilingual_french` | 0546 | Special Bilingual Education French |
| `anglophone_geology` | 0555 | Geology |
| `anglophone_human_biology` | 0565 | Human Biology |
| `anglophone_logic` | 0590 | Logic |

**And** une nouvelle sous-section § « Règles panier O-Level (sources Cameroon GCE Board) » est ajoutée documentant :
- min 6 matières, max 10 (ou 11 avec Religious Studies)
- English Language + French + Mathematics obligatoires non décochables
- Modélisation Firestore : `series.pickerMode: 'free_with_obligatory'` + `series.minSubjects: 6` + `series.maxSubjects: 11` + `derivation_rules.obligatorySubjectIds: [anglophone_english_lang, anglophone_french, anglophone_math]`

**And** § « Anglophone — high school (A Level) » : table étendue avec 6 nouvelles matières :

| ID Firestore | Code GCE | Matière |
|---|---|---|
| `anglophone_a_special_bilingual_french` | 0746 | Special Bilingual Education French |
| `anglophone_philosophy` | 0790 | Philosophy |
| `anglophone_ict` | 0796 | Information and Communication Technology |
| `anglophone_pure_maths_mechanics` | 0765 | Pure Mathematics With Mechanics |
| `anglophone_pure_maths_stats` | 0770 | Pure Mathematics With Statistics |
| `anglophone_food_science_nutrition` | 0740 | Food Science and Nutrition |

**And** une nouvelle sous-section § « Règles A-Level (sources Cameroon GCE Board) » documente :
- max 5 matières, min 3 (Series obligatoires)
- min 2 réussies pour certificat (hors Religious Studies)
- Modélisation Firestore : `series.pickerMode: 'series_plus_optional'` + `series.minSubjects: 3` + `series.maxSubjects: 5` + `derivation_rules.optionalSubjectIds: [anglophone_computer_science, anglophone_ict, anglophone_religious_studies, anglophone_commerce]`

**And** une nouvelle section majeure § « Sous-système ESTP anglophone (TVEE) » est ajoutée **après** la section anglophone existante et **avant** § « Catalogue subjects (Firestore) » documentant :

```markdown
## Sous-système anglophone — ESTP (TVEE)

Le sous-système anglophone technique est administré par le Cameroon GCE Board (TVEE — Technical and Vocational Education Examinations). Deux niveaux d'examen :

- **TVE Intermediate Level (TVE IL)** — équivalent O-Level technique, fin Form 5 technique
- **TVE Advanced Level (TVE AL)** — équivalent A-Level technique, fin Upper Sixth technique

### Modélisation

- subSystem : `anglophone` (même que général)
- filière : `technique` (nouvelle valeur, cohérente avec `francophone/technique`)
- niveau : `anglophone_tve_il` OU `anglophone_tve_al`
- série : spécialité parmi 13 (industrielles + commerciales + Home Economics)

### Spécialités (13)

| Code | ID série TVE IL | ID série TVE AL | Spécialité | Famille |
|---|---|---|---|---|
| ELEQ | `anglophone_tve_il_eleq` | `anglophone_tve_al_eleq` | Electrical Equipment | Industrial |
| ELNI | `anglophone_tve_il_elni` | `anglophone_tve_al_elni` | Electronics | Industrial |
| ELME | `anglophone_tve_il_elme` | `anglophone_tve_al_elme` | Electromechanical | Industrial |
| ELET | `anglophone_tve_il_elet` | `anglophone_tve_al_elet` | Electrotechnique | Industrial |
| AC | `anglophone_tve_il_ac` | `anglophone_tve_al_ac` | Air Conditioning & Refrigeration | Industrial |
| ME | `anglophone_tve_il_me` | `anglophone_tve_al_me` | Mechanical Engineering | Industrial |
| CE | `anglophone_tve_il_ce` | `anglophone_tve_al_ce` | Civil Engineering / Building | Industrial |
| WW | `anglophone_tve_il_woodwork` | `anglophone_tve_al_woodwork` | Woodwork / Carpentry | Industrial |
| ACC | `anglophone_tve_il_acc` | `anglophone_tve_al_acc` | Accounting | Commercial |
| COM | `anglophone_tve_il_commerce` | `anglophone_tve_al_commerce` | Commerce | Commercial |
| OP | `anglophone_tve_il_op` | `anglophone_tve_al_op` | Office Practice | Commercial |
| FN | `anglophone_tve_il_food_nutrition` | `anglophone_tve_al_food_nutrition` | Food and Nutrition | Home Economics |
| CT | `anglophone_tve_il_clothing_textiles` | `anglophone_tve_al_clothing_textiles` | Clothing & Textiles | Home Economics |

### Règles panier TVEE (sources Cameroon GCE Board)

**TVE IL** :
- min 5 matières au total
- ≥2 Professional Subjects + ≥1 Related Professional Subject
- English Language + French obligatoires
- max 11 avec Other Subjects libres

**TVE AL** :
- min 6, max 8 matières
- ≥3 Professional Subjects + ≥3 Related Professional Subjects
- English Language + French obligatoires

### Modélisation Firestore

- `series.pickerMode: 'tve_picker'` sur chaque série TVE IL/AL
- `series.professionalSubjectIds: string[]` (spécifique TVEE — matières professionnelles obligatoires)
- `series.relatedProfessionalSubjectIds: string[]` (matières related obligatoires)
- `series.otherSubjectIds: string[]` (matières au choix)
- `series.minSubjects`, `series.maxSubjects` selon TVE IL/AL
- `derivation_rules.obligatorySubjectIds`: doit inclure English + French + Professional + Related

### Statut activation initial (1.12)

Toutes les séries TVEE seedées `isActive: false` initialement. Activation runtime par l'admin pédagogique via Firebase Console après validation par enseignant TVEE camerophone (action porteur post-merge 1.17).
```

**And** § « Tableau de dérivation `(subSystem, filiere, niveau, serie) → examTargetIds` — Anglophone » : table étendue avec **52 nouvelles lignes** (13 spécialités × 2 niveaux × 2 = TVE IL + TVE AL : 26 + équivalents BAC visés)

**And** § « Volumétrie » mise à jour : ~140 `derivation_rules` totales v2 (vs ~79 v1), ~50 toujours activées au seed v2, ~90 `isActive: false` (incluant TVEE complet + sous-séries ABI/SH/AC/AI/TI + matières A-Level Bilingual French/Philosophy/ICT activables progressivement).

**And** la mention statut global en haut du doc reste 🟢 mais ligne 4 amendée : « **Statut global** : 🟢 **Validé v2 alignement nomenclature officielle Story 1.11a** — matrice exhaustive couvre toutes classes francophone (1er cycle 4 matières ajoutées, 2nd cycle A1-A5/ABI/SH/AC/C/D/E/TI complet, technique F1-F5/G1-G3 + 8 séries étendues) + anglophone (Form 1-5 + Lower/Upper Sixth complet S1-S8 + A1-A5 + matières manquantes ajoutées) + sous-système ESTP TVEE complet (TVE IL + TVE AL × 13 spécialités). Périmètre prioritaire MVP activé au seed initial (1.12) : 4 séries Tle Franco principales (A1-A4/C/D/E), C/D corrigées, F1-F4 + G1-G3, Form 1-5 + Lower/Upper Sixth S1-S8 + A1-A5. Reste activable runtime via Firebase Console quand contenu pédagogique prêt. »

**And** l'historique en bas du fichier reçoit une nouvelle entrée 2026-06-09 :

```markdown
| 2026-06-09 | DelRoos / Claude (Amelia agent) | Story 1.11a — matrice v2 alignement nomenclature officielle (Office du Bac + Cameroon GCE Board). +4 matières premier cycle franco + 9 sous-séries Tle franco (A1-A5/ABI/SH/AC/TI) + corrections séries C/D/E + 5 matières O-Level (codes GCE 0505/0546/0555/0565/0590) + 6 matières A-Level (0746/0790/0796/0765/0770/0740) + sous-système ESTP anglophone TVEE complet (TVE IL + TVE AL × 13 spécialités). 140 `derivation_rules` totales v2, ~50 activées au seed initial (1.12), 90 `isActive: false` étendues. Pivot panier polymorphe : `series.pickerMode` enum (5 modes). Cf. sprint-change-proposal-2026-06-09.md, ADR-016. |
```

### AC2 — Schema Firestore v2 documenté dans BASE-DE-DONNEES.md (5 nouveaux champs catalogue + 1 champ users)

**Given** le doc `doc/partage/BASE-DE-DONNEES.md` (schema v1 livré Story 1.1a)
**When** l'extension v2 est appliquée
**Then** la section § « Catalogue scolaire (6 collections — Story 1.1a) » reçoit l'amendement suivant pour la collection `series` :

```typescript
// series/{serieId} — v2 amended Story 1.11a
interface SerieDoc {
  serieId: string;
  subSystem: "francophone" | "anglophone";
  niveauId: string;
  filiereId: string;
  name: { fr: string; en: string };
  canOptOut: boolean;                       // v1
  isActive: boolean;
  sortOrder: number;
  
  // NEW Story 1.11a — panier polymorphe
  pickerMode?: PickerMode;                  // default 'derived' si absent (rétrocompat v1)
  minSubjects?: number;                     // default null = pas de min
  maxSubjects?: number;                     // default null = pas de max
  
  // NEW Story 1.11a — spécifique TVEE (uniquement si pickerMode == 'tve_picker')
  professionalSubjectIds?: string[];        // matières professionnelles obligatoires TVEE
  relatedProfessionalSubjectIds?: string[]; // matières related obligatoires TVEE
  otherSubjectIds?: string[];               // matières libres TVEE
}

type PickerMode =
  | 'derived'               // default : matières dérivées non modifiables (Tle franco)
  | 'opt_out'               // legacy 1.4 : retrait simple (Lower/Upper Sixth A-Level avant 1.16)
  | 'free_with_obligatory'  // O-Level Form 3-5 : sélection libre 6-11 + obligatoires
  | 'series_plus_optional'  // A-Level Lower/Upper Sixth : Series fixe + transversales optionnelles
  | 'tve_picker';           // TVEE : Professional + Related obligatoires + Other libres
```

**And** la collection `derivation_rules` reçoit l'amendement :

```typescript
// derivation_rules/{ruleId} — v2 amended Story 1.11a
interface DerivationRuleDoc {
  ruleId: string;
  matchSubSystem: "francophone" | "anglophone";
  matchFiliere: string;
  matchNiveau: string;
  matchSerie: string | null;
  subjectIds: string[];                     // v1
  examTargetIds: string[];                  // v1
  canOptOut: boolean;                       // v1
  isActive: boolean;
  
  // NEW Story 1.11a
  obligatorySubjectIds?: string[];          // matières non décochables (pour modes free_with_obligatory + tve_picker)
  optionalSubjectIds?: string[];            // matières ajoutables (pour mode series_plus_optional)
}
```

**And** la collection `users/{uid}` reçoit l'amendement :

```typescript
// users/{uid} — v2 amended Story 1.11a
interface UserDoc {
  // ... champs existants (Stories 1.1c, 1.3, 1.4, 1.6, 1.7) ...
  derivedSubjects: string[];                // existant, calculé par derive()
  optedOutSubjects: string[];               // existant, mode opt_out
  
  // NEW Story 1.11a — utilisé par modes free_with_obligatory + series_plus_optional + tve_picker
  pickedSubjects?: string[];                // matières finalement sélectionnées (subset de derivedSubjects ∪ optionalSubjects, doit contenir obligatorySubjects)
}
```

**And** une nouvelle sous-section § « **Règles de validation panier (1.15 + 1.16 + 1.17)** » documente :

```markdown
**Règles Firestore `users/{uid}` (update) pour modes panier** :

```javascript
// firestore.rules — extrait Story 1.15
function pickedSubjectsValid(data) {
  let picked = data.get('pickedSubjects', []).toSet();
  let derived = data.derivedSubjects.toSet();
  let obligatory = data.get('obligatorySubjectIds', []).toSet();
  let optional = data.get('optionalSubjectIds', []).toSet();
  
  // pickedSubjects ⊂ (derivedSubjects ∪ optionalSubjectIds)
  let inAllowed = picked.difference(derived.union(optional)).size() == 0;
  
  // obligatorySubjectIds ⊂ pickedSubjects
  let obligatoryPresent = obligatory.difference(picked).size() == 0;
  
  return inAllowed && obligatoryPresent;
}
```

Validation côté serveur **en complément** de la validation client UI (Stories 1.15-1.17). Le client peut être bypass — la rule Firestore est la garantie d'intégrité.
```

**And** la table § « Indexes composés à créer » : **aucun nouvel index** ajouté Story 1.11a. Justification documentée : les nouveaux champs (`pickerMode`, `obligatory/optional/professional/relatedProfessional/other SubjectIds`, `pickedSubjects`) sont lus sur des docs déjà filtrés par les indexes Story 1.1a existants (`series.(subSystem, niveauId, filiereId, isActive)` etc.). **CLAUDE.md règle 9 enforcée** : aucune nouvelle query Firestore avec multi-`where` ou `where`+`orderBy` sur champs différents n'est introduite par cette story.

**And** la table § « Règles de sécurité — résumé » : ligne `users/{uid}` actualisée pour inclure mention « **+ pickedSubjects valid (mode panier)** » (sera implémenté en Story 1.15 — référence cross).

**And** l'historique reçoit nouvelle entrée 2026-06-09 :

```markdown
| 2026-06-09 | DelRoos / Claude (Amelia agent) | Story 1.11a — schema v2 alignement nomenclature officielle. +3 champs `series` (`pickerMode` enum 5 valeurs + `minSubjects` + `maxSubjects`) + 3 champs `series` TVEE (`professionalSubjectIds` + `relatedProfessionalSubjectIds` + `otherSubjectIds`) + 2 champs `derivation_rules` (`obligatorySubjectIds` + `optionalSubjectIds`) + 1 champ `users/{uid}` (`pickedSubjects`). Aucun nouvel index (CLAUDE.md règle 9 enforced). Pattern panier polymorphe documenté. Validation Firestore `pickedSubjectsValid()` documentée pour implémentation Story 1.15. |
```

### AC3 — ADR-016 créé

**Given** le dossier `project_manage/planning-artifacts/architecture/adrs/` (15 ADRs existants dont ADR-015 pour catalogue v1)
**When** un nouveau fichier `ADR-016-catalogue-v2-sous-series-panier-tvee.md` est créé
**Then** le fichier suit le format des ADRs existants (cf. ADR-015 comme référence directe) avec sections :

```markdown
# ADR-016 — Catalogue v2 : sous-séries flat francophone + TVEE filière technique anglophone + panier polymorphe

**Date** : 2026-06-09
**Statut** : 🟢 Accepté
**Lié à** : [sprint-change-proposal-2026-06-09.md](../../sprint-change-proposal-2026-06-09.md), [ADR-015](./ADR-015-catalogue-firestore-runtime-activation.md)

## Contexte

Audit comparatif (2026-06-09) entre le catalogue Firestore v1 livré par Stories 1.1a/1.1b/1.1c et la **nomenclature officielle camerounaise** (Office du Baccalauréat francophone + Cameroon GCE Board anglophone) révèle 4 catégories de gaps critiques : matières manquantes, sous-séries Tle francophone absentes, règles de choix anglophone non implémentées, sous-système ESTP anglophone (TVEE) totalement absent.

PO Delano Roosvelt confirme le 2026-06-09 (AskUserQuestion sprint change) : aligner les 4 axes. Décisions architecturales à acter.

## Décisions

### Décision 1 — Sous-séries Tle francophone modélisées **flat** (pas hiérarchique)

Les sous-séries A1, A2, A3, A4, A5, ABI, SH, AC, TI sont modélisées comme **séries de plein droit** dans `series/` Firestore (ex. `francophone_terminale_a1`, `francophone_terminale_abi`). Pas de hiérarchie parent-enfant (série A regroupant A1-A5).

**Conséquence UX** : Tle Franco générale = 12 cards à plat sur SerieChoicePage (A1, A2, A3, A4, A5, ABI, SH, AC, C, D, E, TI) avec groupement visuel par famille (Lettres / Sciences humaines / Sciences / Sciences techniques). Pas d'étape supplémentaire dans le flow profil 3 étapes.

**Alternative rejetée** : hiérarchique (groupe A puis sous-série A1-A5). Refusée par PO (overhead UX, étape conditionnelle supplémentaire, gain pédagogique marginal).

### Décision 2 — TVEE modélisé en filière `technique` dans subSystem `anglophone`

Le sous-système ESTP anglophone (TVEE) est modélisé en ajoutant la filière `technique` à `anglophone` (existante uniquement en `francophone` v1), avec 2 niveaux dédiés `anglophone_tve_il` (TVE Intermediate Level) et `anglophone_tve_al` (TVE Advanced Level), et 13 spécialités comme `series/`.

**Cohérence** : pattern identique au sous-système `francophone/technique` (F1-F5, G1-G3) déjà modélisé v1.

**Alternative rejetée** : nouveau subSystem `anglophone_technique`. Refusée car incohérente avec `francophone/technique` (subSystem reste le découpage linguistique fondamental, pas technique).

### Décision 3 — Panier polymorphe via champ `series.pickerMode` enum

Un nouveau champ `series.pickerMode: PickerMode` (5 valeurs : `derived` | `opt_out` | `free_with_obligatory` | `series_plus_optional` | `tve_picker`) pilote le comportement de la page de sélection matières (`SubjectsPickerPage` après refactor Story 1.15).

**Default safe** : `pickerMode == 'derived'` si champ absent → comportement identique à v1 (rétrocompat). Les profils créés v1 (Fatou Tle D, James Upper Sixth S2 en mode opt-out) continuent à fonctionner.

**Alternative rejetée** : panier mono-mode. Refusée — impossibilité de couvrir O-Level (free + obligatoires), A-Level (Series + optionnelles), opt-out simple, TVEE (Professional + Related + Other) avec un seul mode.

### Décision 4 — Validation panier **côté client (UI)** + **côté Firestore rules**

Pour chaque mode panier, la validation (min/max + obligatoires + appartenance au set autorisé) est dupliquée :
- **Client** : UI live (toast erreur sur tap décocher obligatoire, disable bouton Save sous min, etc.) — UX rapide
- **Serveur** : Firestore rule `pickedSubjectsValid()` qui rejette les updates invalides — garantie d'intégrité même si client bypass

**Alternative rejetée** : validation serveur uniquement. Refusée — UX dégradée (toast erreur après round-trip réseau, latence Cameroun).

## Conséquences

### Positives
- Alignement nomenclature officielle Cameroon → MVP crédible auprès enseignants et établissements
- +20-25% du marché cible adressable (parcours TVEE Nord-Ouest/Sud-Ouest + parcours littéraires francophones complets)
- Scaling progressif via flag `isActive` (cf. ADR-015) — TVEE activable post-validation enseignant
- Pattern Firestore-driven préservé (cohérent ADR-015)
- Non-breaking pour profils existants (defaults safe `pickerMode: 'derived'`)

### Négatives
- SerieChoicePage charge mentale +200% en Tle Franco (12 cards vs 4) — mitigation : groupement visuel famille (Story 1.14)
- matrice.json +60% volumétrie (130 docs vs 79 v1)
- Cumul Epic 1 +31-36h effort (cf. sprint-change-proposal-2026-06-09.md)
- Tests +30-40 nouveaux cas (validation panier, parsing nouvelles règles, widgets pickers)
- Dépendance soft validation enseignant TVEE pour activation runtime (acceptable, isActive false initial)

## Out of scope ADR-016 (post-MVP)

Les nomenclatures officielles documentent aussi :
- **Franco technique étendu** : F6/F7/F8 (Génie Chimique, Sciences Biologiques, Sciences Sanitaires), AF1/AF2/AF3 (Artistiques : Céramique, Peinture, Sculpture)
- **Franco BT/BP/BEP** : Brevet de Technicien, Brevet Professionnel, Brevet d'Études Professionnelles — 30+ spécialités (HO-HE/HO-RB/HO-CU hôtellerie, TO-AAT/TO-AV tourisme, etc.)
- **Franco STT raffiné** : ACA/CG/ACC/FIG/SES (notre G1/G2/G3 actuel est approximatif)

Décision PO 2026-06-09 : **out of scope MVP**, peut être ajouté progressivement post-MVP via re-run script seed avec matrice étendue, sans cycle de release mobile.

## Sources autoritaires

- [Office du Baccalauréat camerounais](https://officedubac.cm/) — Nomenclature des examens ESG + ESTP
- [Cameroon GCE Board](https://camgceb.org/) — Syllabus O-Level + A-Level + TVEE
- [Cameroon GCE Revision](https://cameroongcerevision.com/) — Lower Sixth Series Arts + Science
- Doc utilisateur 2026-06-09 « Orientation et matières au secondaire camerounais » — Synthèse complète

## Acteurs

- **PO** : Delano Roosvelt (décisions sprint change 2026-06-09)
- **Architecte** : Claude Opus 4.7 (PM agent via /bmad-correct-course)
- **Backend** : à approuver async sur PR Story 1.11a (CLAUDE.md règle § doc/partage)
```

**And** le fichier respecte le format standard ADRs (cf. ADR-015 pour structure exacte).

### AC4 — ALGORITHMES.md § 1 mis à jour (algo derive() enrichi)

**Given** le doc `doc/partage/ALGORITHMES.md § 1 Dérivation profil → matières + examens` (livré v1 Story 1.1a)
**When** l'extension v2 est appliquée
**Then** la sous-section § « Algorithme » est étendue avec le retour enrichi `DerivedProfile` v2 :

```typescript
// pseudo-code v2 (Story 1.11a — référence implémentation Story 1.13)

interface DerivedProfile {
  // v1 (existant)
  subjects: Subject[];                  // matières dérivées
  examTargets: ExamTarget[];            // examens visés
  canOptOut: boolean;                   // retrait autorisé (legacy mode opt_out)
  
  // NEW v2 (Story 1.13 implementation)
  pickerMode: PickerMode;               // default 'derived' si pas de pickerMode sur series
  obligatorySubjects: Subject[];        // sous-ensemble de subjects, non décochable
  optionalSubjects: Subject[];          // matières ajoutables (transversales A-Level + autres TVEE)
  minSubjects: number | null;           // null = pas de min (mode 'derived')
  maxSubjects: number | null;
}

function derive(profile: Profile): Either<CatalogueFailure, DerivedProfile> {
  // 1. Match la première derivation_rule active compatible (v1, inchangé)
  const rule = derivation_rules.firstWhere(r =>
    r.matchSubSystem == profile.subSystem &&
    (r.matchFiliere == profile.filiereId || r.matchFiliere == '*') &&
    r.matchNiveau == profile.niveauId &&
    (r.matchSerie == profile.serieId || r.matchSerie == null) &&
    r.isActive == true
  );
  
  if (!rule) return Left(CatalogueFailure.noMatchingRule(profile));
  
  // 2. Map subjects via subjectIds (v1)
  const subjects = mapSubjects(rule.subjectIds);
  const examTargets = mapExamTargets(rule.examTargetIds);
  
  // 3. NEW v2 — récupérer la série pour pickerMode + min/max
  const series = getSeries(profile.serieId);
  
  // 4. NEW v2 — defaults safe pour rétrocompat v1
  const pickerMode = series.pickerMode ?? 'derived';
  const minSubjects = series.minSubjects ?? null;
  const maxSubjects = series.maxSubjects ?? null;
  
  // 5. NEW v2 — obligatoires / optionnelles
  const obligatorySubjects = mapSubjects(rule.obligatorySubjectIds ?? []);
  const optionalSubjects = mapSubjects(rule.optionalSubjectIds ?? []);
  
  return Right({
    subjects, examTargets,
    canOptOut: series.canOptOut ?? false,
    pickerMode,
    obligatorySubjects,
    optionalSubjects,
    minSubjects, maxSubjects,
  });
}
```

**And** la sous-section § « Règles d'exception (retrait de matières) » existante est amendée : ajouter une note « ⚠️ Story 1.4 implémente le mode `opt_out`. Stories 1.15-1.17 étendent à 4 autres modes via `pickerMode`. Cf. ADR-016. »

**And** la sous-section § « Cas pas de match » est inchangée (`derive()` retourne `Left(CatalogueFailure.noMatchingRule(profile))`).

**And** une nouvelle sous-section § « Modes panier (PickerMode) v2 » est ajoutée documentant chaque mode (3 lignes par mode : sémantique, validation client, validation Firestore rule) :

```markdown
### Modes panier (PickerMode) — v2 Story 1.11a

| Mode | Sémantique | Validation client UI | Validation Firestore rule |
|---|---|---|---|
| `derived` | Matières dérivées non modifiables (default Tle franco) | Aucune (pas de page picker) | `pickedSubjects` non utilisé |
| `opt_out` | Retrait simple (legacy Story 1.4 — Anglo Lower/Upper Sixth) | `optedOutSubjects ⊂ derivedSubjects` | `optedOutSubjects ⊂ derivedSubjects` (v1) |
| `free_with_obligatory` | Sélection libre 6-11 avec obligatoires (O-Level) | min/max + obligatoires non décochables | `pickedSubjectsValid()` |
| `series_plus_optional` | Series fige + transversales (A-Level) | max 5 incl. Series | `pickedSubjectsValid()` |
| `tve_picker` | Professional + Related obligatoires + Other libres (TVEE) | min/max + Professional + Related obligatoires | `pickedSubjectsValid()` |
```

**And** l'historique du doc (si table historique existe) reçoit nouvelle entrée 2026-06-09.

### AC5 — architecture.md § 14 Catalogue d'ADRs mis à jour

**Given** le doc `project_manage/planning-artifacts/architecture/architecture.md § 14 Catalogue d'ADRs` (liste 15 ADRs après Story 1.1a)
**When** l'ajout est appliqué
**Then** une nouvelle entrée ADR-016 est ajoutée **après** ADR-015 :

```markdown
| ADR-016 | Catalogue v2 : sous-séries flat francophone + TVEE filière technique anglophone + panier polymorphe | 🟢 Accepté | 2026-06-09 | [ADR-016](./adrs/ADR-016-catalogue-v2-sous-series-panier-tvee.md) |
```

**And** la ligne ADR-015 reste inchangée (aucun amendement).

### AC6 — Accord backend (commentaire PR)

**Given** la PR de cette Story 1.11a sur GitHub
**When** la PR est ouverte
**Then** un commentaire `@backend-team` est ajouté à la PR demandant approbation des 6 nouveaux champs Firestore :
- 3 sur `series` : `pickerMode`, `minSubjects`, `maxSubjects`
- 3 sur `series` TVEE-spécifiques : `professionalSubjectIds`, `relatedProfessionalSubjectIds`, `otherSubjectIds`
- 2 sur `derivation_rules` : `obligatorySubjectIds`, `optionalSubjectIds`
- 1 sur `users/{uid}` : `pickedSubjects`

**And** le porteur (Delano) commit l'accord async (commentaire backend lead OU mention dans la PR description si pas de team backend formelle). Cf. pattern Story 1.1a (backend approval async tolerated CLAUDE.md règle § doc/partage).

## Tasks / Subtasks

- [ ] **T1 — Extension DONNEES-REFERENCE.md** (AC1)
  - [ ] T1.1 Ajouter 4 matières premier cycle francophone (LCN + Informatique collège + Éducation Artistique + Travail Manuel)
  - [ ] T1.2 Ajouter 9 nouvelles sous-séries Tle franco (A1, A2, A3, A4, A5, ABI, SH, AC, TI) avec listes matières exhaustives
  - [ ] T1.3 Corriger série C francophone (séparer Physique/Chimie, retirer LV2, ajouter Informatique)
  - [ ] T1.4 Corriger série D francophone (séparer Physique/Chimie, retirer LV2, ajouter Environnement + Informatique)
  - [ ] T1.5 Corriger série E (ajouter Philosophie)
  - [ ] T1.6 Annoter série A existante DEPRECATED + isActive false post-1.12
  - [ ] T1.7 Ajouter 5 matières O-Level (Accounting 0505 + Special Bilingual French 0546 + Geology 0555 + Human Biology 0565 + Logic 0590) avec codes GCE
  - [ ] T1.8 Ajouter 6 matières A-Level (Bilingual French 0746 + Philosophy 0790 + ICT 0796 + Pure Maths Mechanics 0765 + Pure Maths Stats 0770 + Food Science 0740)
  - [ ] T1.9 Documenter règles panier O-Level (min 6 max 11 + EN+FR+Math obligatoires)
  - [ ] T1.10 Documenter règles panier A-Level (max 5 + Series + transversales)
  - [ ] T1.11 Ajouter section majeure sous-système ESTP anglophone (TVEE) avec niveaux TVE IL/AL + 13 spécialités + règles min/max + Professional/Related
  - [ ] T1.12 Étendre tableau de dérivation francophone avec 9 nouvelles lignes Tle (A1-A5/ABI/SH/AC/TI)
  - [ ] T1.13 Étendre tableau de dérivation anglophone avec 52 nouvelles lignes TVEE (13 × 2 niveaux × 2)
  - [ ] T1.14 Mettre à jour statut global ligne 4 + volumétrie (140 derivation_rules totales v2)
  - [ ] T1.15 Ajouter entrée historique 2026-06-09 en bas du doc

- [ ] **T2 — Extension BASE-DE-DONNEES.md** (AC2)
  - [ ] T2.1 Amender interface SerieDoc avec 3 nouveaux champs v1 (pickerMode + min/max) + 3 champs TVEE-spécifiques
  - [ ] T2.2 Amender interface DerivationRuleDoc avec 2 nouveaux champs (obligatory/optional SubjectIds)
  - [ ] T2.3 Amender interface UserDoc avec champ pickedSubjects optionnel
  - [ ] T2.4 Ajouter type PickerMode (enum 5 valeurs)
  - [ ] T2.5 Documenter règle de validation Firestore `pickedSubjectsValid()` (Story 1.15 implem)
  - [ ] T2.6 Confirmer aucun nouvel index Firestore (CLAUDE.md règle 9 enforcement explicite)
  - [ ] T2.7 Mettre à jour table § Règles de sécurité — résumé pour users/{uid}
  - [ ] T2.8 Ajouter entrée historique 2026-06-09

- [ ] **T3 — Créer ADR-016** (AC3)
  - [ ] T3.1 Créer fichier `project_manage/planning-artifacts/architecture/adrs/ADR-016-catalogue-v2-sous-series-panier-tvee.md`
  - [ ] T3.2 Format standard ADR (cf. ADR-015 référence)
  - [ ] T3.3 4 Décisions documentées (flat sous-séries, filière technique anglo TVEE, panier polymorphe via pickerMode, validation client+server)
  - [ ] T3.4 4 Conséquences positives + 5 conséquences négatives + 3 alternatives rejetées
  - [ ] T3.5 Out of scope MVP documenté (F6/F7/F8, AF, BT/BP/BEP, STT raffiné)
  - [ ] T3.6 Sources autoritaires citées (Office du Bac, GCE Board, Cameroon GCE Revision, doc utilisateur)

- [ ] **T4 — Update ALGORITHMES.md § 1** (AC4)
  - [ ] T4.1 Étendre pseudo-code derive() avec retour DerivedProfile v2
  - [ ] T4.2 Ajouter sous-section Modes panier (PickerMode) v2 avec table 5 modes × 3 colonnes (sémantique, validation client, validation rule)
  - [ ] T4.3 Amender sous-section Règles d'exception avec note Story 1.4 + Stories 1.15-1.17

- [ ] **T5 — Update architecture.md § 14** (AC5)
  - [ ] T5.1 Ajouter entrée ADR-016 dans la table § Catalogue d'ADRs

- [ ] **T6 — PR + accord backend** (AC6)
  - [ ] T6.1 Vérifier `git status` propre + commit `docs(partage): catalogue v2 alignement nomenclature officielle + ADR-016 (Story 1.11a)`
  - [ ] T6.2 Push branche + ouvrir PR avec description claire (référencer sprint-change-proposal-2026-06-09.md + lister les 6 nouveaux champs Firestore)
  - [ ] T6.3 Commenter `@backend-team` dans la PR pour accord
  - [ ] T6.4 PR ≤ 800 lignes diff (cible — peut être dépassé légèrement vu volume matrice mais essayer de rester compact)

- [ ] **T7 — Validation finale**
  - [ ] T7.1 Re-lire les 5 documents modifiés (DONNEES-REFERENCE.md, BASE-DE-DONNEES.md, ALGORITHMES.md, architecture.md, ADR-016)
  - [ ] T7.2 Vérifier cohérence des IDs Firestore (snake_case + prefix subSystem + cohérence ALL DOCs)
  - [ ] T7.3 Vérifier que toutes les références croisées (cf. AC1 ↔ AC2 ↔ AC4) sont cohérentes
  - [ ] T7.4 Vérifier que ADR-016 référence sprint-change-proposal-2026-06-09.md + ADR-015 + sources autoritaires (URLs)
  - [ ] T7.5 Mettre à jour story file (ce fichier) status frontmatter à `review` + completion notes

## Dev Notes

### Architecture compliance (CLAUDE.md règles non négociables)

- **Surface partagée doc/partage/** (CLAUDE.md règle § doc/partage) : 3 docs modifiés (DONNEES-REFERENCE + BASE-DE-DONNEES + ALGORITHMES). Tous les 3 sont autoritaires pour backend + admin + landing. Accord backend requis sur BASE-DE-DONNEES.md (les 6 nouveaux champs catalogue) — async via commentaire PR conformément au pattern Story 1.1a (backend approval async tolerated).
- **Firestore indexes — règle 9 CLAUDE.md** : aucun nouvel index nécessaire pour Story 1.11a. Documenté explicitement en AC2 T2.6. Les nouveaux champs sont lus sur docs déjà filtrés par indexes existants Story 1.1a. **À vérifier explicitement** avant commit : aucune nouvelle query avec multi-`where` ou `where`+`orderBy` sur champs différents n'est introduite.
- **Conventional Commits** : 1 seul commit pour cette story `docs(partage): catalogue v2 alignement nomenclature officielle + ADR-016 (Story 1.11a)` — scope `partage` (CLAUDE.md). Pas de mélange scope.
- **Branche** : `feat/1.11a-audit-matrice-v2-adr016` créée depuis main e1eb9fa post-merge sprint change PR #59. À créer en T6.1.
- **PR ≤ 400 lignes diff** (CLAUDE.md règle Git workflow) : objectif respecté difficile (matrice v2 = ~300 lignes, ADR-016 = ~150 lignes, BASE-DE-DONNEES = ~80 lignes, ALGORITHMES = ~60 lignes, architecture = ~3 lignes = ~593 lignes total). Cible élargie à 800 (cohérent avec Story 1.1a précédente similaire).

### Pattern référence : Story 1.1a (sprint change 2026-06-05)

Cette story 1.11a suit le **même pattern** que la Story 1.1a livrée lors du sprint change précédent (2026-06-05) :
- Docs only (pas de code Dart/Python)
- 3 docs/partage/ modifiés + 1 ADR créé + 1 architecture.md update + accord backend async
- Pattern de validation : matrice v1 🟡 → 🟢 + 6 collections ajoutées BASE-DE-DONNEES
- **Diff** : v1.1a = 1480 lignes (au-delà cible 600), v1.11a cible 800 (plus compact car extension v2 réutilise structure v1)

**Réutiliser** :
- Format AC en BDD (Given/When/Then/And) — cf. AC1 Story 1.1a
- Frontmatter complet avec sourceArtifacts + dependencies + blocks + accord_requis
- Structure ADR identique à ADR-015 (Contexte, Décisions multiples, Conséquences positives/négatives, Alternatives rejetées, Out of scope, Sources)

### Sources autoritaires à consulter (T1 + T3)

**Office du Baccalauréat camerounais** ([officedubac.cm](https://officedubac.cm/)) :
- Nomenclature ESG francophone : séries A1-A5/ABI/SH/AC + C/D/E + TI (et F1-F5 + G1-G3 déjà v1)
- Nomenclature ESTP francophone : F1-F8 + AF + BT/BP/BEP (V2 ne couvre que F1-F5 existant — extensions F6/F7/F8 et BT/BP/BEP = out of scope ADR-016)

**Cameroon GCE Board** ([camgceb.org](https://camgceb.org/)) :
- O-Level : 21 codes matières (0505-0595) + règle panier (min 6 max 11 + EN+FR+Math obligatoires)
- A-Level : 20 codes matières (0705-0796) + règle Series + transversales (max 5)
- TVEE : règles TVE IL (min 5 + ≥2 Professional + ≥1 Related + EN/FR) + TVE AL (min 6 max 8 + ≥3 Professional + ≥3 Related)

**Doc utilisateur 2026-06-09** « Orientation et matières au secondaire camerounais » :
- Section 1-3 : Principe spécialisation progressive + Acteurs orientation + Premier cycle francophone
- Section 4-5 : Entrée 2nde + séries littéraires (A1-A5/ABI/SH/AC) + scientifiques (C/D/E/TI)
- Section 6 : Impact choix série sur matières (coefficient redistribution + matières disparaissent/apparaissent)
- Section 7 : Parcours technique francophone (STI/STT/BT/BP)
- Section 8 : Parcours anglophone GCE O-Level (règles panier officielles) + A-Level Series (S1-S7 + A-Series)
- Section 9 : ESTP anglophone TVEE complet (TVE IL/AL + spécialités + règles min/max)
- Section 10 : Récapitulatif règles de choix par cursus

**Cameroon GCE Revision** ([cameroongcerevision.com/lower-sixth-series-arts-and-science/](https://cameroongcerevision.com/lower-sixth-series-arts-and-science/)) :
- Combinaisons A-Level Series officielles
- Important : doc officiel mentionne **S1-S7** mais matrice v1 a S8 (variante régionale). À conserver S1-S8 v2 pour rétrocompat profils existants. ADR-016 doit noter cette divergence.

### Anti-patterns à éviter (NE PAS faire)

- ❌ **NE PAS** modifier matrice v1 en place de manière destructive (ex. supprimer série A en faveur de A1-A5 directement). Conserver A annoté DEPRECATED + isActive: false post-1.12. Permet rétrocompat profils existants Story 1.1a déjà créés.
- ❌ **NE PAS** réindexer les IDs Firestore existants (ex. ne pas renommer `francophone_pct` directement). Préférer ajout `francophone_physique` + `francophone_chimie` + annotation deprecation sur `francophone_pct` (sera retiré dans matrice.json Story 1.12 mais doc le mentionne).
- ❌ **NE PAS** ajouter de nouveaux indexes Firestore sans nécessité absolue (CLAUDE.md règle 9). Cette story n'introduit aucune nouvelle query, donc 0 nouvel index. Documenter explicitement.
- ❌ **NE PAS** modifier les règles d'accès Firestore (lecture auth + écriture false) — inchangées v2. Story 1.15 ajoutera la règle `pickedSubjectsValid()` pour validation panier côté serveur.
- ❌ **NE PAS** créer plusieurs commits pour cette story. 1 commit unique scope `partage` (CLAUDE.md Conventional Commits).
- ❌ **NE PAS** mélanger les amendments doc/partage avec des changements code (ex. ne pas toucher mobile_app/lib/* dans cette PR). Docs only. Tout code = Stories 1.12-1.17.
- ❌ **NE PAS** dépasser PR 800 lignes (cible élargie vs 400 standard CLAUDE.md vu volume matrice). Si débordement → split en 2 commits (matrice + schema/ADR) sur même branche, ou défer une partie en 1.11a-bis (à discuter avec PO).
- ❌ **NE PAS** supposer que le backend valide immédiatement. Le pattern Story 1.1a a montré que l'accord backend peut être async (commentaire PR post-merge). Acceptable.
- ❌ **NE PAS** modifier ALGORITHMES.md § 2-12 (pas concernés par 1.11a). Uniquement § 1 Dérivation profil → matières.
- ❌ **NE PAS** modifier CLAUDE.md ni README.md — cette story n'introduit pas de règle/structure nouvelle à expliquer au top niveau.

### Décisions structurelles techniques (à acter en T2 + T3)

1. **Type `PickerMode`** documenté comme enum string avec 5 valeurs (TypeScript-like dans BASE-DE-DONNEES). Côté Dart (Story 1.13) ce sera un sealed class ou enum natif.

2. **Champs TVEE-spécifiques** (`professionalSubjectIds`, `relatedProfessionalSubjectIds`, `otherSubjectIds`) : documentés comme optionnels sur SerieDoc. Présents uniquement si `pickerMode == 'tve_picker'`. Validation Firestore rule pourrait les exiger conditionnellement (TODO Story 1.15 ou 1.17).

3. **Champ `users/{uid}.pickedSubjects`** : optionnel, présent uniquement pour profils créés en mode panier. Pas d'amendement règle immutabilité Story 1.3 (createdAt + subSystem restent immuables, pickedSubjects est éditable).

4. **Mode `tve_picker` règle obligatoires** : obligatorySubjectIds doit inclure English Language + French + tous les Professional + tous les Related Professional. Documenté explicitement dans AC2.

### Project structure notes

- **Story file** : `project_manage/implementation-artifacts/1-11a-audit-matrice-v2-adr016.md` (ce fichier)
- **Files to modify** :
  - `doc/partage/DONNEES-REFERENCE.md` (existant — extension v2)
  - `doc/partage/BASE-DE-DONNEES.md` (existant — extension v2)
  - `doc/partage/ALGORITHMES.md` (existant — extension § 1)
  - `project_manage/planning-artifacts/architecture/architecture.md` (existant — § 14 ajout)
- **Files to create** :
  - `project_manage/planning-artifacts/architecture/adrs/ADR-016-catalogue-v2-sous-series-panier-tvee.md` (nouveau)
- **No conflict expected** : tous les fichiers modifiés sont des docs (pas de code Dart), aucun impact build/test.
- **PR ouverte depuis branche** : `feat/1.11a-audit-matrice-v2-adr016` (à créer en T6.1) — NE PAS confondre avec la branche actuelle `docs/story-1.11a-context` qui contient le contexte engine. Le dev (Amelia) doit créer une nouvelle branche pour l'implémentation.

### Testing standards

Pas de tests automatisés requis pour cette story (docs only). Vérifications manuelles à T7 :
- Cohérence IDs Firestore (snake_case + prefix subSystem)
- Cross-références entre AC1 ↔ AC2 ↔ AC4 (matrice cite les champs schema cite l'algo)
- Liens fonctionnels (sprint-change-proposal-2026-06-09.md, ADR-015 référence, sources URLs)
- Markdown valide (préférer linter local si disponible — CLAUDE.md n'impose pas)

### Risques + mitigations

| Risque | Probabilité | Impact | Mitigation |
|---|---|---|---|
| Backend bloque PR sur BASE-DE-DONNEES | Faible | Moyen | Pattern Story 1.1a accepté async. Commentaire PR explicit + commit doc avec note "pending backend approval" |
| Dépassement PR 800 lignes | Moyen | Faible | Split en 2 commits si besoin (matrice + schema/ADR) sur même branche |
| Incohérence IDs entre DONNEES + BASE + ALGORITHMES | Moyen | Moyen | T7.2 vérification systématique avant commit |
| Backend refuse modélisation TVEE (préfère nouveau subSystem) | Faible | Élevé | ADR-016 documente alternative rejetée + justification (cohérence francophone/technique). Si backend insiste, ouvrir discussion async. |
| Sources nomenclature divergentes (officedubac vs camgceb vs doc utilisateur) | Moyen | Moyen | Doc utilisateur 2026-06-09 = synthèse, sources autoritaires en cas de divergence. Citer toutes sources en ADR-016. |

### References

- Sprint change 2026-06-09 : [sprint-change-proposal-2026-06-09.md](../planning-artifacts/sprint-change-proposal-2026-06-09.md)
- Sprint change 2026-06-05 (référence pattern) : [sprint-change-proposal-2026-06-05.md](../planning-artifacts/sprint-change-proposal-2026-06-05.md)
- Epic 1 (sections nouvelles 1.11a) : [epic-1-onboarding.md](../planning-artifacts/epics/epic-1-onboarding.md)
- Story 1.1a (pattern référence) : [1-1a-audit-matrice-firestore-schema.md](./1-1a-audit-matrice-firestore-schema.md)
- ADR-015 (référence pour ADR-016) : [ADR-015-catalogue-firestore-runtime-activation.md](../planning-artifacts/architecture/adrs/ADR-015-catalogue-firestore-runtime-activation.md)
- DONNEES-REFERENCE.md v1 (matrice à étendre) : [DONNEES-REFERENCE.md](../../doc/partage/DONNEES-REFERENCE.md)
- BASE-DE-DONNEES.md v1 (schema à étendre) : [BASE-DE-DONNEES.md](../../doc/partage/BASE-DE-DONNEES.md)
- ALGORITHMES.md § 1 v1 (algo à enrichir) : [ALGORITHMES.md](../../doc/partage/ALGORITHMES.md)
- architecture.md § 14 (catalogue ADRs) : [architecture.md](../planning-artifacts/architecture/architecture.md)
- Office du Baccalauréat : <https://officedubac.cm/>
- Cameroon GCE Board : <https://camgceb.org/>
- Cameroon GCE Revision (A-Level Series) : <https://cameroongcerevision.com/lower-sixth-series-arts-and-science/>

## Dev Agent Record

### Agent Model Used

Claude Opus 4.7 (claude-opus-4-7) via `/bmad-dev-story`

### Debug Log References

(à remplir pendant le dev)

### Completion Notes List

(à remplir pendant le dev)

### File List

À toucher (modifs) :
- `doc/partage/DONNEES-REFERENCE.md`
- `doc/partage/BASE-DE-DONNEES.md`
- `doc/partage/ALGORITHMES.md`
- `project_manage/planning-artifacts/architecture/architecture.md`
- `project_manage/implementation-artifacts/1-11a-audit-matrice-v2-adr016.md` (status review + completion notes)

À créer :
- `project_manage/planning-artifacts/architecture/adrs/ADR-016-catalogue-v2-sous-series-panier-tvee.md`

## Change Log

(à remplir pendant le dev — pattern Story 1.10)

---

**Contexte engine généré par `/bmad-create-story` le 2026-06-09. Source d'audit : sprint-change-proposal-2026-06-09.md (mergé sur main e1eb9fa via PR #59).**
