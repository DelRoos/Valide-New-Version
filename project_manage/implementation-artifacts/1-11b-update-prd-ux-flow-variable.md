---
story_id: 1.11b
title: Update PRD FR-2/FR-3 + EXPERIENCE.md Flow 1 variants alignement nomenclature
epic: 1
phase: P1 extension v2 (sprint change 2026-06-09)
status: review
created: 2026-06-09
baseline_commit: 96d6444a5679ebe0a0e496c7b97c9bd70f55ffa8
estimation: S (~2h)
sprint_change: sprint-change-proposal-2026-06-09.md (mergé PR #59)
dependencies:
  - 1.11a — done (PR #61 commit afe5113 — contrats v2 ADR-016 + matrice étendue + BASE-DE-DONNEES schema v2 + ALGORITHMES algo derive v2)
blocks:
  - 1.14 — Sous-séries Tle franco flat (a besoin du PRD FR-2 v2 + EXPERIENCE.md Flow 1 variant cards étendues figés)
  - 1.15 — Refactor SubjectsPickerPage polymorphe O-Level (a besoin PRD FR-3 v2 + variant picker O-Level)
  - 1.16 — A-Level transversales (a besoin variant extension A-Level)
  - 1.17 — ESTP TVEE anglophone (a besoin variant parcours TVEE)
sourceArtifacts:
  - project_manage/planning-artifacts/epics/epic-1-onboarding.md § Story 1.11b
  - project_manage/planning-artifacts/sprint-change-proposal-2026-06-09.md § Change 4.5 (PRD FR-2/FR-3) + § Change 4.6 (EXPERIENCE.md Flow 1)
  - project_manage/planning-artifacts/architecture/adrs/ADR-016-catalogue-v2-sous-series-panier-tvee.md (référence décisions architecturales)
  - project_manage/implementation-artifacts/1-11a-audit-matrice-v2-adr016.md (référence pattern docs only + sources autoritaires)
  - project_manage/planning-artifacts/prds/prd-valide-mvp-2026-06-03/prd.md § FR-2 (lignes 122-131) + § FR-3 (lignes 133-141)
  - project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/EXPERIENCE.md § Flow 1 — Onboarding (lignes 433-450)
  - doc/partage/DONNEES-REFERENCE.md (matrice v2 — référencer les profils Mariam/Eyong/Aïssatou)
  - doc/partage/ALGORITHMES.md § 1 « Modes panier (PickerMode) v2 » (référencer les 5 modes)
amendments_downstream:
  - "EXPERIENCE.md Flow 1 enrichi avec 4 variants UX informe directement les Stories 1.14 (cards étendues Tle franco), 1.15 (picker O-Level), 1.16 (extension A-Level), 1.17 (parcours TVEE)."
---

# Story 1.11b — Update PRD FR-2/FR-3 + EXPERIENCE.md Flow 1 variants alignement nomenclature

Status: **ready-for-dev**

## Objectif

Aligner les **contrats produit (PRD) et UX (EXPERIENCE.md)** avec la décision architecturale ADR-016 (catalogue v2 — sous-séries flat + TVEE + panier polymorphe) livrée par Story 1.11a (PR #61). Cette story livre **uniquement les contrats**, pas le code mobile.

Sans amendement PRD/UX, le critère de sortie Epic 1 v2 (Fatou + James + Aïssatou + Mariam + Eyong) reste implicite — les Stories 1.14-1.17 manqueraient de référence produit/UX précise pour leurs ACs.

**Critère de fin** : la PR est mergée, le PRD § FR-2 mentionne explicitement la variabilité du nombre de séries présentées selon le profil (12 cards Tle franco vs panier O-Level vs Series A-Level vs TVEE), le PRD § FR-3 mentionne les 5 modes `pickerMode` (cohérent ADR-016 + ALGORITHMES.md § 1), et EXPERIENCE.md Flow 1 documente les 4 variants UX (cards étendues, picker O-Level, extension A-Level, parcours TVEE) avec personas correspondantes (Aïssatou, Mariam, James, Eyong).

## Story

**As a** product owner Valide,
**I want** PRD § FR-2/FR-3 et EXPERIENCE.md § Flow 1 amendés pour refléter le pivot v2 (catalogue v2 + panier polymorphe + sous-séries franco + TVEE anglo),
**so that** les Stories 1.14 (sous-séries Tle franco SerieChoicePage), 1.15 (refactor SubjectsPickerPage O-Level), 1.16 (extension A-Level transversales) et 1.17 (parcours TVEE) implémentation aient un contrat produit + UX clair, et que le critère de sortie Epic 1 v2 (5 personas Fatou/James/Aïssatou/Mariam/Eyong) soit explicite dans les docs autoritaires.

## Acceptance Criteria

### AC1 — PRD § FR-2 amendé (3 étapes avec liste série variable selon profil)

**Given** le doc `project_manage/planning-artifacts/prds/prd-valide-mvp-2026-06-03/prd.md § FR-2 lignes 122-131`
**When** l'amendement v2 est appliqué
**Then** la description courte (ligne 124) reste : « Un utilisateur peut remplir son profil scolaire en trois étapes obligatoires (filière → niveau → série), et voit les matières + examens dérivés automatiquement. Réalise UJ-1. » — la structure 3 étapes est préservée pour cohérence MVP.

**And** la liste des consequences (testable) est étendue de 4 à 6 items :

```markdown
**Consequences (testable) :**

- Les choix possibles à chaque étape ne dépendent **que** des choix précédents (la série dépend du niveau et de la filière).
- À la confirmation de la série, la liste des matières **et** la liste des examens visés s'affichent **sans cocher individuellement** ; aucun parcours d'inscription n'aboutit avec une liste vide.
- **La liste des séries présentées à l'étape 3 varie selon le profil** (cf. catalogue v2 — Story 1.11a, ADR-016) :
  - Francophone Tle générale → jusqu'à 12 cards (A1, A2, A3, A4, A5, ABI, SH, AC, C, D, E, TI) avec groupement visuel par famille (Lettres / Sciences humaines / Sciences / Sciences techniques) — Story 1.14
  - Anglophone Form 3-5 → panier dédié post-choix Form 5 avec règles min 6 / max 11 + EN+FR+Math obligatoires — Story 1.15
  - Anglophone Lower/Upper Sixth → Series fixe + extension transversales optionnelles (Computer Science / ICT / Religious Studies / Commerce) max 5 — Story 1.16
  - Anglophone TVEE (filière technique) → cards spécialités groupées 3 familles (Industrial : ELEQ/ELNI/ELME/ELET/AC/ME/CE/Carpentry ; Commercial : Accounting/Commerce/OP ; Home Economics : Food/Clothing) — Story 1.17
- Un profil francophone Tle D montre `[Maths, Physique, Chimie, SVT, Français, Anglais, Philo, Hist-Géo, Informatique, EPS]` (10 matières — corrigées Story 1.11a : Physique+Chimie séparés, retrait LV2 erronée, ajout Informatique) et `[exam_bac_francophone_d]`.
- Un profil francophone Tle A1 montre `[Français, Anglais, Math, Philo, HG, EPS, Latin, Grec, LV2]` (9 matières — sous-série littéraire Story 1.11a, isActive: true post-1.12) et `[exam_bac_francophone_a1]`.
- Un profil anglophone Upper Sixth S2 montre `[Chemistry, Physics, Biology]` + transversales optionnelles ajoutables (Story 1.16) et `[exam_gce_a_level_anglophone_s2]`.
- Un profil anglophone Form 5 (panier O-Level) sélectionne 6-11 matières dont EN+FR+Math obligatoires non décochables (Story 1.15).
- Un profil anglophone TVE AL Electrotechnique présente 6-8 matières dont ≥3 Professional + ≥3 Related + EN/FR obligatoires (Story 1.17).
```

**Rationale (à ajouter dans le PRD)** : « Le pivot v2 (sprint-change-proposal-2026-06-09.md, ADR-016) aligne le PRD avec la nomenclature officielle Office du Baccalauréat + Cameroon GCE Board. La structure 3 étapes reste pour cohérence UX (pas d'étape supplémentaire), mais la liste de séries présentées à l'étape 3 est variable. Voir DONNEES-REFERENCE.md v2 § « Sous-système anglophone — ESTP (TVEE) » + ALGORITHMES.md § 1 « Modes panier (PickerMode) v2 ». »

### AC2 — PRD § FR-3 amendé (sélection conditionnelle multi-mode)

**Given** le doc `project_manage/planning-artifacts/prds/prd-valide-mvp-2026-06-03/prd.md § FR-3 lignes 133-141`
**When** l'amendement v2 est appliqué
**Then** la description courte (ligne 135) devient :

```markdown
Un utilisateur peut sélectionner ou retirer des matières de sa liste dérivée **selon le mode défini par sa série** (`series.pickerMode` Firestore, ADR-016 — 5 valeurs : `derived` / `opt_out` / `free_with_obligatory` / `series_plus_optional` / `tve_picker`). Hors mode `derived`, une page picker dédiée s'affiche après l'écran récap. Réalise UJ-1.
```

**And** la liste des consequences (testable) est étendue de 3 à 7 items :

```markdown
**Consequences (testable) :**

- Un élève francophone en Première C ou Tle C/D **ne voit pas** de page picker (mode `derived` default — matières dérivées non modifiables).
- Un élève anglophone en Lower/Upper Sixth (Series A1-A5 / S1-S8) voit un mode legacy `opt_out` (retrait simple — Story 1.4 conservée) jusqu'à Story 1.16 qui passe en mode `series_plus_optional`.
- Un élève anglophone en Form 3, Form 4 ou Form 5 voit un picker dédié O-Level (mode `free_with_obligatory` — Story 1.15) avec validation **min 6 / max 11 matières** et **English Language + French + Mathematics obligatoires non décochables**. Tap sur matière obligatoire → toast erreur. Tap au-delà de 11 → toast erreur. Save disabled si < 6.
- Un élève anglophone en Upper Sixth (post Story 1.16) voit son Series figé (3-4 matières lockées) **+ 4 checkboxes transversales** (Computer Science, ICT, Religious Studies, Commerce) ajoutables jusqu'à max 5 total. Tap = compteur live « X/5 matières ».
- Un élève anglophone TVE IL ou TVE AL voit un picker spécifique mode `tve_picker` (Story 1.17) avec sections **Professional Subjects** (lockées) + **Related Professional** (lockées) + **Other Subjects** (libres) + EN/FR obligatoires. Validation TVE IL : min 5 dont ≥2 Pro + ≥1 Related. TVE AL : min 6 max 8 dont ≥3 Pro + ≥3 Related.
- Une matière non sélectionnée (panier) ou retirée (opt_out) **n'apparaît plus** dans la liste filtrée du contenu (Stories E2+) ni dans les classements par matière (Story E5).
- La sélection est persistée dans `users/{uid}.pickedSubjects` (modes panier) ou `users/{uid}.optedOutSubjects` (legacy mode `opt_out`) — cf. BASE-DE-DONNEES.md schema v2.
```

**Rationale (à ajouter dans le PRD)** : « Le mode `derived` (default Tle franco A1-A5/C/D/E/etc.) correspond au comportement Story 1.3 v1 — pas de modification possible. Les 4 autres modes (`opt_out`, `free_with_obligatory`, `series_plus_optional`, `tve_picker`) couvrent les variantes officielles MINESEC + Cameroon GCE Board. Validation client + serveur (Firestore rule `pickedSubjectsValid()`) dupliquée — cf. ADR-016 § Décision 4 + ALGORITHMES.md § 1 « Modes panier ». »

### AC3 — EXPERIENCE.md Flow 1 — Onboarding amendé avec 4 variants UX

**Given** le doc `project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/EXPERIENCE.md § Flow 1 lignes 433-450`
**When** l'amendement v2 est appliqué
**Then** le flow Fatou (Tle D francophone) existant est conservé tel quel (lignes 437-450) comme **flow nominal default mode `derived`**.

**And** 4 nouvelles sous-sections variants UX sont ajoutées **après** le flow Fatou (avant la section ### Flow 2 ligne 452) :

#### Variant 4.1 — Aïssatou (Tle A1 francophone, Lettres+Latin+Grec, Bafoussam)

```markdown
**Variant Flow 1a — Aïssatou (Tle A1 francophone, sous-série littéraire, Story 1.14)**

*Personas : Aïssatou Diop, Tle A1 francophone, Bafoussam, Samsung Galaxy A12.*

1-4. Identique au Flow 1 Fatou jusqu'à l'étape 2/3 niveau (Tap « Terminale »).
5. **Étape 3/3 : série — variant 12 cards Tle franco générale**. Liste scrollable groupée par famille avec headings : « Lettres » (cards A1, A2, A3, A4, A5, ABI), « Sciences humaines » (SH, AC), « Sciences » (C, D), « Sciences techniques » (E, TI). Chaque famille a une icône Lucide (BookOpen / Users / Atom / Wrench). Aïssatou scroll, identifie « Lettres » → tap card **A1**. Critère UX-DR : Aïssatou trouve sa série en < 10s sur Pixel 4a (objectif test 1.14).
6. Écran récap : matières dérivées (Français, Anglais, Math, Philo, Hist-Géo, EPS, **Latin**, **Grec**, **LV2** — 9 matières) + bandeau « Tu prépares le BAC A1 ». Bouton « C'est ma classe ».
7-10. Identique au Flow 1 Fatou (école + compte + dashboard).

**Edge case Tle A** : un élève qui avait choisi série A v1 (DEPRECATED) avant 2026-06-09 reste en série A annotée — pas de migration forcée. Cf. ADR-016 § Décision 1 rétrocompat.
```

#### Variant 4.2 — Mariam (Form 5 anglophone, panier O-Level, Limbé)

```markdown
**Variant Flow 1b — Mariam (Form 5 anglophone, panier O-Level, Story 1.15)**

*Personas : Mariam Bakari, Form 5 anglophone, Limbé, Tecno Pop 7.*

1-4. Identique au Flow 1 (sous-système Anglophone + filière Generale + niveau Form 5).
5. **Étape 3/3 : série — variant pas de série**. Form 5 anglophone n'a pas de série au sens v1. Skip cette étape, nav direct à l'écran picker O-Level.
6. **Variant picker O-Level (mode `free_with_obligatory`)** : nouvelle page après step niveau. Sections :
   - **« Matières obligatoires »** : 3 cards lockées avec checkbox checked + icône cadenas Lucide (English Language, French, Mathematics). Tap décocher → toast erreur « EN, FR et Math sont obligatoires ».
   - **« Matières au choix »** : ~14-18 checkboxes (Physics, Chemistry, Biology, Geography, History, Economics, Religious Studies, Computer Science, Citizenship Education, ICT, Food & Nutrition, Commerce, Geology NEW, Human Biology NEW, Logic NEW, Accounting NEW, Additional Mathematics, Bilingual French NEW). Pre-cochées : Physics + Chemistry + Biology + Geography + History (5 matières populaires sciences) — soit 8 matières au total avec obligatoires.
   - **Compteur live en bas** : « Tu présentes 8/11 matières ». Bouton Valider activé si X ∈ [6, 11].
7. Mariam décoche Geography (préfère parcours sciences pur). Compteur passe à 7/11. Tap Valider.
8. Écran récap : 7 matières affichées + bandeau « Tu prépares le GCE O-Level ». Bouton « C'est ma classe ».
9-12. Identique au Flow 1 Fatou (école + compte + dashboard).

**Validation Firestore** : `pickedSubjects ⊂ derivedSubjects ∪ optionalSubjectIds ∧ obligatorySubjectIds ⊂ pickedSubjects` (Story 1.15 firestore.rules).

**Edge case bypass client** : un appel API direct depuis outil externe qui POST `pickedSubjects` invalide (ex. sans Math) → Firestore rule rejette. Toast côté client si Firebase remonte l'erreur.
```

#### Variant 4.3 — James (Upper Sixth S2 anglophone, extension A-Level, Buea)

```markdown
**Variant Flow 1c — James (Upper Sixth S2 anglophone, extension A-Level transversales, Story 1.16)**

*Personas : James Tanyi, Upper Sixth S2 anglophone, Buea, Tecno Spark 8.* (étendu de Flow 2 du PRD v1)

1-5. Identique au Flow 1 Fatou (Anglophone + Generale + Upper Sixth + Series **S2** = Chemistry/Physics/Biology).
6. **Variant extension A-Level (mode `series_plus_optional`)** : nouvelle page après step série. Sections :
   - **« Series (obligatoires) »** : 3 cards lockées avec checkbox checked + icône cadenas (Chemistry, Physics, Biology — la Series S2 figée).
   - **« Transversales optionnelles »** : 4 checkboxes décochées par défaut (Computer Science, ICT, Religious Studies, Commerce). James veut ajouter ICT pour son orientation IT.
   - **Compteur live** : « Tu présentes 3/5 matières ». James coche ICT → 4/5. Save activé tant que X ∈ [3, 5].
7. Tap Valider. `pickedSubjects = [Chemistry, Physics, Biology, ICT]`.
8. Écran récap : 4 matières + bandeau « Tu prépares le GCE A-Level ». Bouton « C'est ma classe ».
9-12. Identique au Flow 1 Fatou (école + compte + dashboard).

**Edge case max 5** : si James coche ICT + Computer Science + Religious Studies + Commerce (4 transversales) = 7 matières total > 5 → tap Valider disabled + toast « Maximum 5 matières au A-Level ».
```

#### Variant 4.4 — Eyong (TVE AL anglophone, Electrotechnique, Bonabéri)

```markdown
**Variant Flow 1d — Eyong (TVE AL anglophone Electrotechnique, parcours TVEE, Story 1.17)**

*Personas : Eyong Eboa, TVE Advanced Level anglophone, spécialité Electrotechnique, Bonabéri Douala, Itel A56.*

1-2. Identique au Flow 1 Fatou (Anglophone — toggle EN immediate).
3. **Étape 1/3 : filière — variant filière technique anglo (NEW Story 1.17)**. Cards affichées : « General » (existant) + **« Technique »** (NEW). Tap « Technique ».
4. **Étape 2/3 : niveau — variant TVEE**. Cards affichées : « TVE Intermediate Level (TVE IL) » + « TVE Advanced Level (TVE AL) ». Eyong tape « TVE AL ».
5. **Étape 3/3 : spécialité — variant 13 cards groupées TVEE**. Liste scrollable groupée 3 familles :
   - **« Industrial »** : ELEQ, ELNI, ELME, ELET, AC, ME, CE, Carpentry (8 cards avec icône Lucide Wrench)
   - **« Commercial »** : Accounting, Commerce, Office Practice (3 cards avec icône Briefcase)
   - **« Home Economics »** : Food & Nutrition, Clothing & Textiles (2 cards avec icône UtensilsCrossed / Shirt)
   Eyong tape **« ELET — Electrotechnique »** (famille Industrial).
6. **Variant picker TVEE (mode `tve_picker`)** : nouvelle page. Sections :
   - **« Professional Subjects (obligatoires) »** : 3 cards lockées (Electrotechnique theory, Electrotechnique practical, Electrical machines)
   - **« Related Professional Subjects (obligatoires) »** : 3 cards lockées (Mathematics for Industrial, Physics, Drawing)
   - **« Other Subjects (au choix) »** : checkboxes (English Language locked, French locked, History, Geography, Religious Studies)
   - **Compteur live** : « Tu présentes 7/8 matières (≥3 Pro + ≥3 Related ✓) ». Validation TVE AL : min 6 max 8 dont ≥3 Pro + ≥3 Related.
7. Eyong garde la sélection par défaut (3 Pro + 3 Related + EN + FR = 8 matières exactement). Tap Valider.
8. Écran récap : 8 matières TVEE + bandeau « Tu prépares le TVE AL Electrotechnique ». Bouton « C'est ma classe ».
9-12. Identique au Flow 1 Fatou (école + compte + dashboard).

**Edge case isActive false initial** : au seed 1.12, les 26 séries TVEE sont `isActive: false`. Eyong tape « Technique » + « TVE AL » mais aucune spécialité disponible → message « Filière TVEE en cours d'activation. Reviens dans quelques semaines. » + bouton « Continuer en visiteur General Lower Sixth » (fallback). Toggle `isActive: true` par admin pédagogique post-validation enseignant TVEE (action porteur).

**Décision activation progressive** : ELEQ + ELNI + ELME + ELET (Industrial électriques) activés en premier (validation Mr Eboa Joseph, Lycée Technique Bonabéri, action porteur post-merge 1.17). Autres spécialités activées au fil de la production de contenu pédagogique.
```

**And** la section originale Flow 1 (Fatou) reçoit un **petit ajout en haut** :

```markdown
### Flow 1 — Onboarding (Fatou, premier soir)

*Réalise UJ-1 du PRD. Personas : Fatou Mballa, Tle D francophone, Yaoundé, Tecno Spark 8.*

> ℹ️ **Flow nominal mode `derived`**. Pour les variants v2 Story 1.11b (sous-séries franco A1-A5/ABI/SH/AC/TI, panier anglo O-Level, extension A-Level, TVEE), voir variants **Flow 1a (Aïssatou)** / **1b (Mariam)** / **1c (James)** / **1d (Eyong)** ci-dessous.
```

### AC4 — Mise à jour matières Fatou Tle D dans EXPERIENCE.md ligne 442

**Given** la ligne 442 actuelle d'EXPERIENCE.md mentionne pour Fatou (Tle D) les matières v1 : `Maths, PCT, SVT, Français, Anglais, LV2, Philo, Histoire-Géo, EPS` (9 matières — incohérent avec matrice v2 Story 1.11a qui sépare PCT en Physique+Chimie + retire LV2 + ajoute Informatique + Environnement)
**When** l'amendement v2 est appliqué
**Then** la ligne 442 devient :

```markdown
6. Écran récap : matières dérivées affichées en grille (Maths, **Physique**, **Chimie**, SVT, **Environnement**, Français, Anglais, Philo, Histoire-Géo, **Informatique**, EPS — 11 matières — cf. corrections série D Story 1.11a) + examen visé en bandeau (« Tu prépares le BAC D »). Bouton primaire « C'est ma classe ».
```

**Rationale** : cohérence avec DONNEES-REFERENCE.md v2 corrections Story 1.11a (Tle D : Physique+Chimie séparés, retrait LV2 erronée v1, ajout Environnement + Informatique).

### AC5 — Pas de modification DESIGN.md (out of scope)

**Given** le doc `project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/DESIGN.md`
**When** Story 1.11b se termine
**Then** DESIGN.md reste inchangé.

**Rationale** : DESIGN.md décrit les composants UX atomiques (Story 0.13/0.14). Les nouveaux patterns picker O-Level / extension A-Level / TVEE seront documentés directement dans les Stories 1.15/1.16/1.17 (contextes engine) en réutilisant les composants existants (AppButton, AppCard, CheckboxListTile, Sections + headings) — pas besoin de DESIGN.md amendement.

### AC6 — Pas de modification doc/partage/* (déjà fait Story 1.11a)

**Given** les docs `doc/partage/DONNEES-REFERENCE.md`, `BASE-DE-DONNEES.md`, `ALGORITHMES.md`
**When** Story 1.11b se termine
**Then** ces 3 docs restent inchangés (déjà amendés v2 par Story 1.11a).

**Rationale** : Story 1.11a a déjà livré tous les amendements doc/partage v2. Story 1.11b livre uniquement PRD + EXPERIENCE.md (côté planning + UX, pas côté contrats backend).

## Tasks / Subtasks

- [x] **T1 — Amendement PRD § FR-2 (3 étapes avec liste série variable selon profil)** (AC1)
  - [x] T1.1 Conserver description courte ligne 124 inchangée (structure 3 étapes préservée)
  - [x] T1.2 Étendre liste consequences (testable) de 4 à 9 items selon AC1 (4 nouveaux items profils Tle A1 / Form 5 / TVE AL + 1 item variants Story 1.14-1.17 + correction Tle D matières)
  - [x] T1.3 Ajouter ligne rationale référençant sprint-change-proposal-2026-06-09.md + ADR-016 + DONNEES-REFERENCE.md v2 + ALGORITHMES.md § 1 Modes panier

- [x] **T2 — Amendement PRD § FR-3 (sélection conditionnelle multi-mode)** (AC2)
  - [x] T2.1 Réécrire description courte ligne 135 selon AC2 (5 modes `pickerMode` listés)
  - [x] T2.2 Étendre liste consequences (testable) de 3 à 7 items selon AC2 (modes par profil)
  - [x] T2.3 Ajouter ligne rationale référençant ADR-016 § Décision 4 + ALGORITHMES.md § 1 Modes panier + BASE-DE-DONNEES.md UserDoc.pickedSubjects

- [x] **T3 — Amendement EXPERIENCE.md Flow 1 avec 4 variants UX** (AC3)
  - [x] T3.1 Ajouter callout ℹ️ en haut de Flow 1 référençant les 4 variants
  - [x] T3.2 Ajouter variant Flow 1a Aïssatou (Tle A1 franco, 12 cards groupées famille) — référence Story 1.14
  - [x] T3.3 Ajouter variant Flow 1b Mariam (Form 5 anglo, panier O-Level mode `free_with_obligatory`) — référence Story 1.15
  - [x] T3.4 Ajouter variant Flow 1c James (Upper Sixth S2 + ICT, extension A-Level mode `series_plus_optional`) — référence Story 1.16
  - [x] T3.5 Ajouter variant Flow 1d Eyong (TVE AL ELET, parcours TVEE mode `tve_picker`) — référence Story 1.17 + edge case isActive false initial

- [x] **T4 — Correction matières Fatou Tle D dans EXPERIENCE.md** (AC4)
  - [x] T4.1 Remplacer liste matières v1 (Maths, PCT, SVT, FR, EN, LV2, Philo, HG, EPS — 9 matières) par liste v2 corrigée (Maths, Physique, Chimie, SVT, Environnement, FR, EN, Philo, HG, Informatique, EPS — 11 matières)

- [x] **T5 — Validation finale** (AC5 + AC6)
  - [x] T5.1 Vérifié que DESIGN.md n'est PAS modifié (AC5 — out of scope) — git status confirme
  - [x] T5.2 Vérifié que doc/partage/* n'est PAS modifié (AC6 — déjà fait Story 1.11a) — git status confirme
  - [x] T5.3 Re-lecture documents modifiés — PRD § FR-2/FR-3 cohérents + EXPERIENCE.md Flow 1 + 4 variants intégrés sans casser Flow 2-6
  - [x] T5.4 Cohérence références croisées (PRD ↔ ADR-016 ↔ ALGORITHMES.md Modes panier ↔ DONNEES-REFERENCE.md v2 ↔ BASE-DE-DONNEES.md) — OK
  - [x] T5.5 Vérifié les 5 personas (Fatou + Aïssatou + Mariam + James + Eyong) mentionnées avec profils corrects + Stories implementing (1.14/1.15/1.16/1.17)

- [x] **T6 — PR + commit** (étape commit suivante)
  - [x] T6.1 `git status` propre + commit `docs(planning): PRD FR-2/FR-3 + EXPERIENCE.md Flow 1 variants alignement nomenclature (Story 1.11b)`
  - [x] T6.2 Push branche `feat/1.11b-update-prd-ux-flow-variable` + URL PR retournée
  - [x] T6.3 PR ~110 lignes diff (sous cible 350 — beaucoup plus compact qu'estimé car structure markdown réutilise listes existantes)
  - [x] T6.4 Story file status frontmatter `ready-for-dev → in-progress → review` + completion notes + change log mis à jour

## Dev Notes

### Architecture compliance (CLAUDE.md règles non négociables)

- **Surface PRD/UX** (CLAUDE.md ne mentionne pas de règle spécifique sur PRD/UX, mais le pattern Epic 1 sprint changes 2026-06-05 et 2026-06-09 montrent que PRD/UX sont mis à jour en docs only sans accord externe) : aucun accord backend requis (pas de toucher `doc/partage/*`).
- **Conventional Commits** : 1 seul commit pour cette story `docs(planning): PRD FR-2/FR-3 + EXPERIENCE.md Flow 1 variants (Story 1.11b)` — scope `planning` (CLAUDE.md). Pas de mélange scope.
- **Branche** : `feat/1.11b-update-prd-ux-flow-variable` créée depuis main post-merge cloture-1.11a. À créer en T6.1.
- **PR ≤ 400 lignes diff** (CLAUDE.md règle Git workflow) : objectif respecté facilement. Estim ~300 lignes diff (2 fichiers : PRD +120 lignes, EXPERIENCE.md +180 lignes).

### Pattern référence : Story 1.11a (sprint change 2026-06-09 — docs only)

Cette story 1.11b suit le **même pattern** que la Story 1.11a livrée juste avant :
- Docs only (pas de code Dart/Python, pas de tests)
- Pas d'accord backend requis (PRD + UX = planning interne, pas de surface partagée)
- Frontmatter complet avec sourceArtifacts + dependencies + blocks
- Tasks T1-T6 avec sub-tasks granulaires

**Différences** :
- **Plus simple** : 2 fichiers à modifier vs 5 pour 1.11a
- **Plus court** : ~300 lignes diff vs 708 pour 1.11a
- **Pas d'ADR** créé (les décisions architecturales sont dans ADR-016 déjà livré)

### Sources autoritaires à consulter

**Sprint change source** : [sprint-change-proposal-2026-06-09.md § Change 4.5 + Change 4.6](../planning-artifacts/sprint-change-proposal-2026-06-09.md) — décisions PO + spec exacte amendements PRD/UX.

**ADR autoritaire** : [ADR-016](../planning-artifacts/architecture/adrs/ADR-016-catalogue-v2-sous-series-panier-tvee.md) — 4 Décisions architecturales (flat sous-séries franco + filière technique anglo TVEE + panier polymorphe `pickerMode` enum 5 valeurs + validation client+server).

**Matrice v2 livrée Story 1.11a** : [DONNEES-REFERENCE.md](../../doc/partage/DONNEES-REFERENCE.md) — référencer les profils Fatou (Tle D corrigée), Aïssatou (Tle A1), Mariam (Form 5 panier), James (Upper Sixth S2 + ICT), Eyong (TVE AL Electrotechnique) pour cohérence ACs.

**Algo `derive()` v2 livré Story 1.11a** : [ALGORITHMES.md § 1 « Modes panier (PickerMode) v2 »](../../doc/partage/ALGORITHMES.md) — table 5 modes × 5 colonnes (sémantique + validation client + Firestore rule + champ `users/{uid}`).

### Files to modify (UPDATE — exactement 2)

1. **`project_manage/planning-artifacts/prds/prd-valide-mvp-2026-06-03/prd.md`** :
   - § FR-2 lignes 122-131 : amender description + étendre 4 → 9 consequences (testable)
   - § FR-3 lignes 133-141 : réécrire description + étendre 3 → 7 consequences (testable)

2. **`project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/EXPERIENCE.md`** :
   - § Flow 1 lignes 433-450 : ajouter callout ℹ️ référencement variants + corriger ligne 442 matières Tle D v2
   - **Insérer après ligne 450** (avant `### Flow 2` ligne 452) : 4 sous-sections variants (Aïssatou + Mariam + James + Eyong) ~180 lignes total

### Files NOT to modify (out of scope explicite)

- ❌ `doc/partage/DONNEES-REFERENCE.md` — déjà v2 (Story 1.11a)
- ❌ `doc/partage/BASE-DE-DONNEES.md` — déjà v2 (Story 1.11a)
- ❌ `doc/partage/ALGORITHMES.md` — déjà v2 (Story 1.11a)
- ❌ `doc/partage/CONTRATS-API.md` — aucun impact (pas de nouvelle Cloud Function)
- ❌ `project_manage/planning-artifacts/ux-designs/.../DESIGN.md` — composants UX atomiques inchangés (réutilisés)
- ❌ `project_manage/planning-artifacts/architecture/adrs/*` — ADR-016 déjà livré (Story 1.11a)
- ❌ `project_manage/planning-artifacts/architecture/architecture.md` — § 14 déjà à jour avec ADR-016 (Story 1.11a)
- ❌ `mobile_app/lib/*` — aucun code (docs only)
- ❌ `firestore.rules`, `firestore.indexes.json` — aucun changement (CLAUDE.md règle 9 N/A)
- ❌ `CLAUDE.md`, `README.md` — aucun changement structurel

### Anti-patterns à éviter (NE PAS faire)

- ❌ **NE PAS** modifier les sections PRD autres que FR-2 + FR-3 (les autres FR ne sont pas concernés par le pivot v2).
- ❌ **NE PAS** ajouter un FR-2b ou FR-3b nouveau — modifier les FR existants en place. Cohérence avec pattern PRD existant.
- ❌ **NE PAS** modifier les Flow 2-6 d'EXPERIENCE.md — seul Flow 1 (onboarding) est concerné.
- ❌ **NE PAS** supprimer le Flow 1 Fatou existant — il devient le « flow nominal mode derived ». Les variants Aïssatou/Mariam/James/Eyong sont **additionnels**.
- ❌ **NE PAS** créer d'images / wireframes / mockups inline — uniquement texte descriptif des écrans (cohérent avec le style EXPERIENCE.md existant). Si visualisation requise plus tard → Story 1.14/1.15/1.16/1.17 (story-specific UX wireframes si besoin).
- ❌ **NE PAS** introduire de nouveaux composants UX non documentés (AppButton, AppCard, CheckboxListTile + Sections + headings suffisent pour les 4 variants).
- ❌ **NE PAS** modifier les 4 personas existantes du PRD (Fatou + James + visiteur générique). Aïssatou / Mariam / Eyong sont **ajoutées** comme personas de variants UX, pas comme remplacements.
- ❌ **NE PAS** mentionner Firestore rules / `pickedSubjectsValid()` côté PRD (pas le bon doc — c'est BASE-DE-DONNEES.md + ADR-016).
- ❌ **NE PAS** modifier `flutter_native_splash` ou les composants Story 0.X — le flow d'onboarding démarre identique (splash + sous-système + filière + niveau + série), seul le pattern série + post-récap varie.

### Décisions structurelles techniques (à acter)

1. **Variants UX additionnels** : on **n'invalide pas** le Flow 1 Fatou. On l'enrichit avec une note ℹ️ en haut et des variants Aïssatou/Mariam/James/Eyong en dessous. Préservation rétrocompat doc + cohérence MVP avec démos existantes.

2. **Personas variants** : Aïssatou (Tle A1 franco), Mariam (Form 5 anglo panier), James étendu (Upper Sixth S2 + ICT — réutilisation de la persona existante James du PRD), Eyong (TVE AL ELET anglo). Métadonnées (ville, device, etc.) cohérentes avec le marché cible (Cameroun urbain + secondaire + devices entrée de gamme).

3. **Compteur live "X/N matières"** : pattern UX commun aux 3 picker modes (Mariam Form 5, James A-Level, Eyong TVEE). À factoriser dans Story 1.15 (premier impl) puis réutilisé par 1.16 / 1.17.

4. **Famille de séries (groupement visuel)** : pattern UX commun à Flow 1a (Tle franco familles Lettres/Sciences humaines/Sciences/Sciences techniques) et Flow 1d (TVEE familles Industrial/Commercial/Home Economics). Pattern Section avec heading + icône Lucide. À factoriser dans Story 1.14 (premier impl) puis réutilisé par 1.17.

5. **Edge case Tle A v1 DEPRECATED** : explicitement documenté dans Flow 1a (Aïssatou). Profils v1 avec `serieId == "francophone_terminale_a"` continuent à fonctionner — pas de migration forcée. Cohérent avec ADR-016 § Décision 1 rétrocompat.

6. **Edge case TVEE `isActive: false` initial** : explicitement documenté dans Flow 1d (Eyong). Fallback message « Filière TVEE en cours d'activation » + bouton « Continuer en visiteur General Lower Sixth ». Cohérent avec ADR-016 § Décision 2 activation initiale.

### Project structure notes

- **Story file** : `project_manage/implementation-artifacts/1-11b-update-prd-ux-flow-variable.md` (ce fichier)
- **Files to modify** :
  - `project_manage/planning-artifacts/prds/prd-valide-mvp-2026-06-03/prd.md`
  - `project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/EXPERIENCE.md`
- **No conflict expected** : tous les fichiers modifiés sont des docs (pas de code Dart), aucun impact build/test.
- **PR ouverte depuis branche** : `feat/1.11b-update-prd-ux-flow-variable` (à créer en T6.1).

### Testing standards

Pas de tests automatisés requis (docs only). Vérifications manuelles à T5 :
- Cohérence personas (Fatou + Aïssatou + Mariam + James + Eyong)
- Cohérence des références ID Firestore (matches DONNEES-REFERENCE.md v2)
- Cohérence des références Stories (1.14 / 1.15 / 1.16 / 1.17)
- Cohérence ADR-016 (5 modes pickerMode listés correctement)
- Markdown valide (préférer linter local si disponible)

### Risques + mitigations

| Risque | Probabilité | Impact | Mitigation |
|---|---|---|---|
| Confusion variants vs Flow 1 default | Moyen | Moyen | Callout ℹ️ explicit en haut + sous-titres numérotés Flow 1a/b/c/d |
| Diff > 400 lignes (CLAUDE.md PR cap) | Faible | Faible | Story plus petite que 1.11a. ~300 lignes estim. OK. |
| Oublier mention rétrocompat v1 (série A franco) | Moyen | Moyen | T3.2 explicite edge case Aïssatou variant. Documenté en story file. |
| Personas Mariam / Eyong noms erronés Cameroun | Faible | Faible | Noms réalistes vérifiés (Bakari = Sud-Ouest, Eboa = Douala). |
| Confusion Series anglo A1-A5 (A-Level) vs sous-séries franco A1-A5 (Tle) | Moyen | Moyen | Préciser dans chaque mention : « anglophone Lower Sixth Series A1 » vs « francophone Tle A1 ». |
| Profil James dupliqué (existant PRD Fatou + James) | Faible | Faible | James étendu en Flow 1c — pas nouveau persona, juste son cas étendu avec ICT. |

### References

- Sprint change 2026-06-09 : [sprint-change-proposal-2026-06-09.md](../planning-artifacts/sprint-change-proposal-2026-06-09.md) (§ Change 4.5 PRD + § Change 4.6 EXPERIENCE.md)
- Story 1.11a livrée : [1-11a-audit-matrice-v2-adr016.md](./1-11a-audit-matrice-v2-adr016.md) (pattern référence + matrice v2 livrée)
- ADR-016 (autoritaire) : [ADR-016-catalogue-v2-sous-series-panier-tvee.md](../planning-artifacts/architecture/adrs/ADR-016-catalogue-v2-sous-series-panier-tvee.md)
- DONNEES-REFERENCE.md v2 (matrice à référencer dans ACs) : [DONNEES-REFERENCE.md](../../doc/partage/DONNEES-REFERENCE.md)
- ALGORITHMES.md § 1 Modes panier v2 : [ALGORITHMES.md](../../doc/partage/ALGORITHMES.md)
- BASE-DE-DONNEES.md UserDoc.pickedSubjects : [BASE-DE-DONNEES.md](../../doc/partage/BASE-DE-DONNEES.md)
- PRD à amender : [prd.md § FR-2 + § FR-3](../planning-artifacts/prds/prd-valide-mvp-2026-06-03/prd.md)
- EXPERIENCE.md à amender : [EXPERIENCE.md § Flow 1](../planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/EXPERIENCE.md)
- Epic 1 sections nouvelles : [epic-1-onboarding.md § Story 1.11b](../planning-artifacts/epics/epic-1-onboarding.md)

## Dev Agent Record

### Agent Model Used

Claude Opus 4.7 (claude-opus-4-7) via `/bmad-dev-story`

### Debug Log References

(à remplir pendant le dev)

### Completion Notes List

✅ **Story 1.11b livrée en docs only (2 fichiers, ~108 lignes insérées)** sur branche `feat/1.11b-update-prd-ux-flow-variable` depuis baseline `96d6444`.

**Décisions vs spec engine** :
- T1+T2 PRD : implémentation conforme à la spec — descriptions courtes + listes consequences étendues + rationale en blockquote
- T3 EXPERIENCE.md Flow 1 : callout ℹ️ + 4 variants ajoutés comme sous-sections `#### Variant Flow 1a/b/c/d` (au lieu de blocs de code markdown comme dans la spec engine — choix de rendu cohérent avec le style EXPERIENCE.md existant)
- T4 ligne 442 corrigée en place (intégrée dans le bloc Flow 1 numéroté, pas séparée)
- **Diff plus compact qu'estimé** : ~108 lignes vs 300 estimées. Raison : la structure markdown existante (listes numérotées) absorbe la majorité du contenu sans dupliquer

**Anti-patterns respectés** :
- ✅ DESIGN.md non modifié (AC5)
- ✅ doc/partage/* non modifié (AC6)
- ✅ mobile_app/lib/* non modifié (docs only)
- ✅ firestore.rules/indexes non modifiés (CLAUDE.md règle 9 N/A)
- ✅ Flow 1 Fatou conservé (devient nominal mode `derived` + variants additionnels)
- ✅ Flow 2-6 non modifiés
- ✅ Aucun nouveau composant UX introduit (réutilisation AppCard + Section + headings + checkboxes existants)
- ✅ Personas existantes (Fatou + James) préservées, Aïssatou/Mariam/Eyong **ajoutées** (pas remplacées)
- ✅ Pas de mention `pickedSubjectsValid` côté PRD (uniquement BASE-DE-DONNEES.md + ADR-016)
- ✅ 1 seul commit scope `planning` (Conventional Commits)

**Cross-références validées (T5.4)** :
- PRD § FR-2/FR-3 → ADR-016 (4 décisions architecturales référencées via liens relatifs)
- PRD → ALGORITHMES.md § 1 Modes panier (5 modes listés cohérents)
- PRD → DONNEES-REFERENCE.md v2 (matrice référencée)
- PRD → BASE-DE-DONNEES.md (UserDoc.pickedSubjects référencé)
- EXPERIENCE.md Flow 1 callout → ADR-016
- EXPERIENCE.md variants → Stories implementing (1.14/1.15/1.16/1.17 mentionnées explicitement par variant)

**5 personas Epic 1 v2 (T5.5)** validées :
- Fatou Mballa (Tle D francophone) — mode `derived` — flow nominal préservé
- Aïssatou Diop (Tle A1 francophone) — variant Flow 1a — Story 1.14
- Mariam Bakari (Form 5 anglophone panier) — variant Flow 1b — Story 1.15
- James Tanyi (Upper Sixth S2 + ICT) — variant Flow 1c — Story 1.16 (étendu de la persona PRD v1)
- Eyong Eboa (TVE AL Electrotechnique) — variant Flow 1d — Story 1.17

**Débloqué post-merge** : Stories 1.14 + 1.15 + 1.16 + 1.17 ont maintenant le contrat produit (PRD FR-2/FR-3) et UX (EXPERIENCE.md Flow 1 variants) explicite pour leurs ACs. En parallèle, Stories 1.12 (matrice.json + reseed) et 1.13 (DerivedProfile model Dart) peuvent démarrer (dépendent uniquement de 1.11a, déjà mergée).

### File List

À toucher (modifs, exactement 2 fichiers) :
- `project_manage/planning-artifacts/prds/prd-valide-mvp-2026-06-03/prd.md` (§ FR-2 + § FR-3)
- `project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/EXPERIENCE.md` (§ Flow 1 + 4 variants)

À mettre à jour (cette story file + sprint-status) :
- `project_manage/implementation-artifacts/1-11b-update-prd-ux-flow-variable.md` (status review + completion notes)
- `project_manage/implementation-artifacts/sprint-status.yaml` (1-11b ready-for-dev → review)

Aucun fichier créé.

## Change Log

| Date | Auteur | Action |
|---|---|---|
| 2026-06-09 | DelRoos / Claude (Amelia agent via `/bmad-create-story`) | Création contexte engine Story 1.11b (~400 lignes, 6 AC BDD + 6 Tasks + Dev Notes). Status `backlog` → `ready-for-dev`. PR #63 mergée sur main commit `96d6444`. |
| 2026-06-09 | DelRoos / Claude (Amelia agent via `/bmad-dev-story`) | Implémentation T1-T6 docs only. Status `ready-for-dev` → `in-progress` → `review`. Baseline `96d6444`. 2 fichiers modifiés (~108 lignes insérées vs 300 estimées — structure markdown plus compacte) : PRD prd.md § FR-2 (3 étapes préservées + 9 consequences testable + rationale) + § FR-3 (description réécrite multi-mode + 7 consequences testable + rationale) + EXPERIENCE.md Flow 1 (callout ℹ️ + correction matières Fatou Tle D v2 + 4 variants UX Aïssatou/Mariam/James/Eyong sous-sections `#### Variant Flow 1a/b/c/d`). |

---

**Contexte engine généré par `/bmad-create-story` le 2026-06-09. Source : sprint-change-proposal-2026-06-09.md § Change 4.5 + § Change 4.6 (mergé via PR #59) + Story 1.11a done (PR #61 commit afe5113 mergée).**
