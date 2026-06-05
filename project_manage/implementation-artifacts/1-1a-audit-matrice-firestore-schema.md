---
story_id: 1.1a
title: Audit matrice exhaustive MINESEC/GCE + schema Firestore + ADR-015 + BASE-DE-DONNEES update
epic: 1
phase: P1
status: review
created: 2026-06-05
branch: feat/1.1a-audit-matrice-firestore-schema
baseline_commit: 9fd0792a0e723e3fa64e70c4841f55385280ed5c
estimation: S (~3-4h)
risk: R4 — matrice profil → matières/examens marquée 🟡 squelette à compléter en P1
dependencies: []
blocks:
  - 1.1b — script Python seed_catalogue.py (a besoin du schema Firestore figé)
  - 1.1c — CatalogueRepository mobile (a besoin du schema Firestore figé)
sourceArtifacts:
  - project_manage/planning-artifacts/epics/epic-1-onboarding.md § Story 1.1a (lignes 91-152)
  - project_manage/planning-artifacts/sprint-change-proposal-2026-06-05.md (motivation pivot + décisions PO)
  - project_manage/planning-artifacts/prds/prd-valide-mvp-2026-06-03/prd.md § FR-2, FR-3, AS-2, AS-3, NFR-5
  - doc/partage/DONNEES-REFERENCE.md (matrice 🟡 à compléter et passer 🟢)
  - doc/partage/BASE-DE-DONNEES.md § users + Vue d'ensemble (à étendre avec 6 nouvelles collections)
  - doc/partage/ALGORITHMES.md § 1 « Dérivation profil → matières + examens » (à amender)
  - project_manage/planning-artifacts/architecture/adrs/ADR-003-firebase-full-backend.md (référence ADR pour ADR-015)
  - project_manage/planning-artifacts/architecture/adrs/ADR-006-subsystem-fixed-at-signup.md (cohérence)
  - project_manage/planning-artifacts/architecture/adrs/ADR-010-no-custom-cache.md (cohérence cache offline natif)
  - project_manage/planning-artifacts/architecture/architecture.md § 14 Catalogue d'ADRs (à mettre à jour)
  - project_manage/implementation-artifacts/1-1-audit-r4-matrice-seed-catalogue.md (Story cancelled — schema seed JSON à réutiliser comme base du schema Firestore)
amendments_downstream:
  - "Stories 1.3, 1.4, 1.9 amendées dans epic-1-onboarding.md : lecture catalogue via CatalogueRepository Firestore au lieu de seed JSON local. Pivot acté par sprint-change-proposal-2026-06-05.md."
---

# Story 1.1a — Audit matrice exhaustive MINESEC/GCE + schema Firestore + ADR-015 + BASE-DE-DONNEES update

Status: **review**

## Objectif

Livrer **les contrats** (docs + ADR + schema) du pivot Firestore-driven catalogue acté par [sprint-change-proposal-2026-06-05.md](../planning-artifacts/sprint-change-proposal-2026-06-05.md) :

1. **Matrice exhaustive** (sous-système × filière × niveau × série) → (matières, examens) dans [DONNEES-REFERENCE.md](../../doc/partage/DONNEES-REFERENCE.md), couvrant **TOUTES les classes** francophone (1er cycle 6ᵉ→3ᵉ, 2nd cycle A/C/D/E, technique F1-F5, G1-G3, ESF/IH/MVT) et anglophone (Form 1-5, Lower/Upper Sixth complet S1-S8 + A1-A5). Statut 🟡 → 🟢.
2. **Schema Firestore** des **6 nouvelles collections** (`filieres`, `niveaux`, `series`, `subjects`, `exam_targets`, `derivation_rules`) avec flag `isActive: bool` runtime, indexes composites, règles d'accès, documenté dans [BASE-DE-DONNEES.md](../../doc/partage/BASE-DE-DONNEES.md).
3. **ADR-015** créé : *« Catalogue Firestore + activation runtime via isActive »*.
4. **ALGORITHMES.md § 1** amendé : lieu d'exécution de la dérivation (Cloud Function backend OU helper Dart client — décision figée ici comme **helper Dart client en V1**, cohérent avec le périmètre mobile-only de ce dépôt).
5. **architecture.md § 14** mis à jour : entrées ADR-011, ADR-012, ADR-013, ADR-014 (rattrapage drift) + ADR-015.
6. **Accord backend** sur BASE-DE-DONNEES.md (CLAUDE.md règle § doc/partage).

**Pourquoi** : sans contrats figés, ni la story 1.1b (script Python seed) ni la 1.1c (CatalogueRepository mobile) ne peuvent démarrer. Cette story est **bloquante** pour démarrer le code Epic 1.

**Critère de fin** : la PR est mergée, backend a approuvé BASE-DE-DONNEES.md updates, ADR-015 référencé dans architecture.md § 14, et un dev peut lire les 6 collections + types attendus + indexes + règles sans ambiguïté pour implémenter 1.1b et 1.1c.

## Story

**As a** product owner Valide,
**I want** une matrice exhaustive (sous-système, filière, niveau, série) → (matières, examens) couvrant TOUTES les classes francophone et anglophone, ET un schema Firestore documenté (6 collections avec flag `isActive: bool`) + ADR-015 + mise à jour de `doc/partage/BASE-DE-DONNEES.md`,
**so that** Stories 1.1b (script Python seed) et 1.1c (CatalogueRepository mobile) puissent démarrer en parallèle avec des contrats clairs, et que l'admin pédagogique puisse activer/désactiver les classes runtime depuis Firebase Console sans cycle de release mobile.

## Acceptance Criteria

### AC1 — Audit matrice exhaustive et tracée (DONNEES-REFERENCE.md → 🟢)

**Given** la matrice 🟡 squelette de `doc/partage/DONNEES-REFERENCE.md` (§ « Tableau de dérivation » ligne 271 actuelle)
**When** un audit est conduit par sources publiques (MINESEC + Cameroon GCE Board, déjà listées en haut du doc § « Sources autoritaires » lignes 8-20)
**Then** le tableau de dérivation est complété pour **TOUTES les classes** :
- **Francophone général 1er cycle** : 6ᵉ, 5ᵉ, 4ᵉ, 3ᵉ + BEPC (pas de série)
- **Francophone général 2nd cycle** : Seconde, Première, Terminale × séries A, C, D, E + Probatoire + BAC
- **Francophone technique 1er cycle** : 6ᵉ, 5ᵉ, 4ᵉ, 3ᵉ technique si applicable (sinon noter explicitement "n/a")
- **Francophone technique 2nd cycle** : Première + Terminale × séries F1, F2, F3, F4, F5 + Probatoire + BAC industriel
- **Francophone technique tertiaire** : Première + Terminale × séries G1, G2, G3 + BAC tertiaire
- **Francophone technique autres** : ESF, IH, MVT, ACA/ACC, MAVA, MEAC AUTO, MEM, MECA (lister tels que documentés § lignes 131-141, marquer "couverture périmètre étendu" si présents)
- **Anglophone secondary** : Form 1, Form 2, Form 3, Form 4, Form 5 + O Level (pas de série jusqu'à Form 5, retrait dès Form 3)
- **Anglophone high school Sciences** : Lower Sixth + Upper Sixth × séries S1, S2, S3, S4, S5, S6, S7, S8 + A Level
- **Anglophone high school Arts** : Lower Sixth + Upper Sixth × séries A1, A2, A3, A4, A5 + A Level

**And** chaque série a sa liste exacte de matières documentée (citer les sources MINESEC + GCE Board pour chaque entrée 🟢)
**And** la mention « 🟡 Squelette à compléter » est remplacée par « 🟢 Validé pour catalogue Firestore Story 1.1a » dans § « Tableau de dérivation » et § « Statut global » en haut du doc
**And** § « Périmètre MVP suggéré » (lignes 312-330) **n'est PAS supprimé** mais amendé pour préciser : « Catalogue Firestore livre toutes les classes ; flag `isActive` runtime permet à l'admin d'activer progressivement (commencer par périmètre MVP suggéré, étendre selon production de contenu pédagogique). »
**And** § « Implications pour les équipes — Mobile » (lignes 290-294) amendé : remplacer « Lit `subjects/*` filtré par profil » par « Lit les 6 collections (`filieres`, `niveaux`, `series`, `subjects`, `exam_targets`, `derivation_rules`) via `CatalogueRepository` (Story 1.1c) avec filtre `isActive == true` et cache offline Firestore natif (NFR-5). »
**And** § « Implications pour les équipes — Backend » (lignes 295-299) amendé : seeds initiaux générés par `scripts/firebase_seed/seed_catalogue.py` (Story 1.1b, dans CE dépôt mobile racine — pas dépôt backend) au lieu de `functions/seed/subjects.json`
**And** l'historique en bas du fichier (§ « Historique » lignes 334-339) reçoit une nouvelle entrée datée 2026-06-05 avec auteur "DelRoos / Claude (Amelia agent)" + description « Story 1.1a — matrice exhaustive toutes classes 🟢 + pivot Firestore-driven catalogue (sprint-change-proposal-2026-06-05.md) »

### AC2 — Schema Firestore documenté dans BASE-DE-DONNEES.md

**Given** le doc actuel `doc/partage/BASE-DE-DONNEES.md`
**When** on l'étend avec les 6 nouvelles collections du pivot
**Then** la table « Vue d'ensemble des collections » (lignes 23-46 actuelles) reçoit **6 nouvelles entrées** :

```markdown
| `filieres` | Catalogue filières (générale, technique) — multilingue, activable runtime | 🟢 | **Stream** (admin peut désactiver à chaud) |
| `niveaux` | Catalogue niveaux par sous-système + filière (6ᵉ, Seconde, Form 1, Lower Sixth, …) | 🟢 | **Stream** |
| `series` | Catalogue séries par (sous-système, niveau, filière) (A, C, D, E, F1-F5, G1-G3, S1-S8, A1-A5, …) + flag canOptOut | 🟢 | **Stream** |
| `exam_targets` | Catalogue examens visés (BEPC, Probatoire/BAC × séries, O Level, A Level × séries) | 🟢 | **Stream** |
| `derivation_rules` | Règles de dérivation (subSystem, filiere, niveau, serie) → (subjectIds, examTargetIds, canOptOut) | 🟢 | **Stream** |
```

**And** la ligne existante `subjects` ligne 28 est amendée : statut 🟡 → 🟢 + colonne « Mutable côté mobile » passe de "Statique" à "**Stream** (admin peut désactiver à chaud)"

**And** une nouvelle section « ## Catalogue scolaire (6 collections — Story 1.1a) » est ajoutée **après** § « `users/{uid}` 🟡 » (ligne 75 actuelle) et **avant** § « `subscriptions/{uid}` 🟡 » (ligne 86 actuelle), contenant pour chacune des 6 collections :

```typescript
// filieres/{filiereId}
interface FiliereDoc {
  filiereId: string;                    // = doc ID. Convention: snake_case ("generale", "technique")
  name: { fr: string; en: string };     // ex. { fr: "Générale", en: "General" }
  isActive: boolean;                    // pivot — admin Console toggle pour activer/désactiver runtime
  sortOrder: number;                    // ordre d'affichage (10, 20, 30...)
}

// niveaux/{niveauId}
interface NiveauDoc {
  niveauId: string;                     // = doc ID. Convention: {subSystem}_{slug} (ex. "francophone_6e", "anglophone_form_1", "anglophone_lower_sixth")
  subSystem: "francophone" | "anglophone";
  name: { fr: string; en: string };
  filiereIds: string[];                 // refs vers filieres/{id} — un niveau peut être valide pour générale + technique
  isActive: boolean;
  sortOrder: number;
}

// series/{serieId}
interface SerieDoc {
  serieId: string;                      // = doc ID. Convention: {subSystem}_{niveau_slug}_{serie_slug} (ex. "francophone_terminale_d", "anglophone_upper_sixth_s2")
  subSystem: "francophone" | "anglophone";
  niveauId: string;                     // ref vers niveaux/{id}
  filiereId: string;                    // ref vers filieres/{id}
  name: { fr: string; en: string };
  canOptOut: boolean;                   // Story 1.4 — retrait conditionnel matières. Anglophone Form 3+ et Lower/Upper Sixth toutes filières => true. Sinon false.
  isActive: boolean;
  sortOrder: number;
}

// subjects/{subjectId}
interface SubjectDoc {
  subjectId: string;                    // = doc ID. Convention: {subSystem}_{shortCode} en snake_case (ex. "francophone_math", "anglophone_pure_maths"). Conserve la convention déjà documentée DONNEES-REFERENCE.md § ligne 218.
  subSystem: "francophone" | "anglophone";
  name: { fr: string; en: string };
  icon: string;                         // nom Lucide (ex. "function-square", "flask-conical") — pack lucide_icons_flutter ^3.1.14 (pubspec.yaml)
  isActive: boolean;
  sortOrder: number;
}

// exam_targets/{examTargetId}
interface ExamTargetDoc {
  examTargetId: string;                 // = doc ID. Convention: exam_{niveau}_{subSystem}[_{serie}] (cf. DONNEES-REFERENCE.md § ligne 236)
  subSystem: "francophone" | "anglophone";
  name: { fr: string; en: string };     // ex. { fr: "BAC D", en: "BAC D" }
  isActive: boolean;
  sortOrder: number;
}

// derivation_rules/{ruleId}
interface DerivationRuleDoc {
  ruleId: string;                       // = doc ID auto-généré OU convention rule_{subSystem}_{filiere}_{niveau}_{serie}
  matchSubSystem: "francophone" | "anglophone";
  matchFiliere: string;                 // ref filieres/{id} ou "*" pour wildcard (ex. les forms 1-2 sans filière distinction)
  matchNiveau: string;                  // ref niveaux/{id}
  matchSerie: string | null;            // ref series/{id} ou null si le niveau n'a pas de série (ex. 6ᵉ, Form 1)
  subjectIds: string[];                 // refs vers subjects/{id} — résultat de la dérivation
  examTargetIds: string[];              // refs vers exam_targets/{id}
  canOptOut: boolean;                   // doublon avec series.canOptOut pour requête directe sans join — figé à la création de la rule
  isActive: boolean;
}
```

**And** la section inclut **3 indexes composites** documentés :

```markdown
**Indexes composés** :
- `series.(subSystem ASC, niveauId ASC, filiereId ASC, isActive ASC)` — sélection des séries valides pour profil 3 étapes
- `subjects.(subSystem ASC, isActive ASC, sortOrder ASC)` — grille matières dashboard
- `derivation_rules.(matchSubSystem ASC, matchFiliere ASC, matchNiveau ASC, matchSerie ASC, isActive ASC)` — match dérivation
```

**And** une section **« Règles d'accès »** par collection est documentée (template uniforme pour les 6) :

```markdown
**Règles d'accès (les 6 collections catalogue)** :
- Lecture : `if request.auth != null` (utilisateur authentifié, anonyme ou complet)
- Écriture : `if false` (jamais depuis le mobile — seul le script Python `seed_catalogue.py` (Story 1.1b) ou la Firebase Console admin peut écrire)
```

**And** la table § « Règles de sécurité — résumé » (lignes 484-501 actuelles) reçoit 6 nouvelles lignes (template : `| <coll> | Authentifié | **Script Python / Console admin uniquement** |`)

**And** la table § « Indexes composés à créer » (lignes 466-476 actuelles) reçoit les 3 nouveaux indexes ci-dessus + retire le 🔴 « À compléter pendant la mise en place » qui devient 🟢 pour ces 3 lignes

**And** l'historique reçoit une nouvelle entrée 2026-06-05 « DelRoos / Claude (Amelia agent) — Story 1.1a : pivot Firestore catalogue (6 collections filieres/niveaux/series/subjects/exam_targets/derivation_rules + isActive runtime + indexes + règles read-auth/write-false). Sprint-change-proposal-2026-06-05.md »

### AC3 — ADR-015 créé

**Given** le dossier `project_manage/planning-artifacts/architecture/adrs/` (10 ADRs existants)
**When** un nouveau fichier `ADR-015-catalogue-firestore-runtime-activation.md` est créé
**Then** le fichier suit le format des ADRs existants (cf. [ADR-003](../planning-artifacts/architecture/adrs/ADR-003-firebase-full-backend.md) comme référence) avec sections :

```markdown
# ADR-015 — Catalogue scolaire Firestore + activation runtime via isActive

**Date** : 2026-06-05
**Statut** : 🟢 Accepté
**Lié à** : [sprint-change-proposal-2026-06-05.md](../../sprint-change-proposal-2026-06-05.md)

## Contexte

[Référence Story 1.1 cancelled (seed JSON local statique) → limitation : ajout matière / activation série
requiert rebuild + redéploiement stores. PO requirement post-planning : activer/désactiver runtime
depuis Firebase Console pour activation progressive selon production contenu pédagogique. Citer les
4 evidence verbatim du sprint-change-proposal § 1.]

## Décision

[1] Catalogue scolaire stocké en **Firestore** sur 6 collections (filieres, niveaux, series, subjects,
exam_targets, derivation_rules) avec flag `isActive: bool` sur chaque document.
[2] Seed initial via **script Python externe** `scripts/firebase_seed/seed_catalogue.py` (Story 1.1b)
utilisant firebase-admin SDK. Source de vérité versionnée dans `scripts/firebase_seed/data/matrice.json`.
[3] Lecture côté mobile via `CatalogueRepository` (Story 1.1c) qui applique systématiquement
`where('isActive', '==', true)` sur toutes les queries.
[4] **Dérivation profil → matières + examens exécutée côté client** (helper Dart pur dans
`CatalogueRepository.derive()`) en V1, cohérent avec périmètre mobile-only de ce dépôt (pas de
Cloud Function backend déployée à ce stade). Cf. ADR-003 (Firebase full backend) — pas de
contradiction : la dérivation reste portable vers Cloud Function en V2 si besoin.
[5] Pas de fallback JSON local. Si Firestore est vide ET le cache offline est vide (1er lancement
hors-ligne), un écran « En attente de connexion » bloque la suite du flow (UX-DR-24, Story 1.1c).

## Conséquences

**Positives**
- **Activation progressive** : l'admin pédagogique active une série quand son contenu est prêt,
  sans cycle de release mobile.
- **Alignement ADR-003** (Firebase full backend) + **ADR-010** (cache Firestore offline natif).
- **Renforce AS-2 PRD** (catalogue produit en parallèle équipe pédagogique).
- **Suppression du risque R4** : la matrice Firestore est la source de vérité, plus de risque de
  drift entre seed JSON et schéma backend.

**Négatives**
- **Dépendance Firestore au 1er lancement** : un nouvel utilisateur en offline complet ne peut pas
  finir l'onboarding. Mitigé par écran « En attente de connexion » + invariant Cameroun (data
  limitée mais pas zéro).
- **Latence supplémentaire** : 200-800 ms en 3G au 1er load. Cache offline natif (Story 0.7) couvre
  les loads suivants.
- **Coût Firestore reads** : chaque démarrage profil incomplet = 6 stream subscriptions. Acceptable
  pour V1 (volumes faibles), à surveiller en P5 (Santé scolaire).
- **Dépendance soft à un script Python externe** (Story 1.1b) pour le seed initial. Le porteur
  doit l'exécuter au démarrage du projet et après chaque ajout pédagogique.

## Alternatives rejetées

- **Seed JSON local statique embarqué** (Story 1.1 cancelled) : pas d'activation runtime, rebuild
  obligatoire pour ajouter une matière.
- **Cloud Function intermédiaire `getCatalogue()`** : ajoute latence (cold start) + dépendance
  backend déployé, pas requis V1.
- **Seed JSON local + Firestore optionnel V2** : refusé par PO (besoin admin runtime immédiat).

## Décisions liées

- [ADR-003](ADR-003-firebase-full-backend.md) — Firebase full backend (cohérence).
- [ADR-006](ADR-006-subsystem-fixed-at-signup.md) — sous-système figé (le catalogue rend ce choix
  immuable côté serveur via les `derivation_rules`).
- [ADR-010](ADR-010-no-custom-cache.md) — pas de cache custom, cache Firestore offline natif suffit.
- [sprint-change-proposal-2026-06-05.md](../../sprint-change-proposal-2026-06-05.md) — décision PO motivante.
```

**And** le fichier respecte la longueur et le style des autres ADRs (~70-100 lignes — pas un essai).

### AC4 — ALGORITHMES.md § 1 amendé

**Given** § 1 « Dérivation profil → matières + examens » de `doc/partage/ALGORITHMES.md` (lignes 39-77 actuelles)
**When** on amende le § pour figer la décision de lieu d'exécution
**Then** la ligne 42 « Lieu d'exécution : Cloud Function (au moment du remplissage du profil ou de sa modification) » est **remplacée** par :

```markdown
**Lieu d'exécution V1** : Helper Dart pur dans `CatalogueRepository.derive()` (mobile, Story 1.1c). Résultat retourné via `Either<CatalogueFailure, DerivedProfile>` et persisté dans `users/{uid}.derivedSubjects` et `users/{uid}.examTargets` au moment de la création du profil (Story 1.3).

**Pourquoi côté client V1** : ce dépôt est mobile-only ; pas de Cloud Function déployée à ce stade. Cohérent avec [ADR-015](../../project_manage/planning-artifacts/architecture/adrs/ADR-015-catalogue-firestore-runtime-activation.md). Migration future vers Cloud Function `deriveProfile(uid)` triggered Firestore reste possible sans refactor mobile (le repository encapsule la dérivation derrière une interface stable).

**Source de vérité** : les 6 collections catalogue Firestore (`filieres`, `niveaux`, `series`, `subjects`, `exam_targets`, `derivation_rules`) seedées par `scripts/firebase_seed/seed_catalogue.py` (Story 1.1b). Cf. [BASE-DE-DONNEES.md § Catalogue scolaire](BASE-DE-DONNEES.md#catalogue-scolaire-6-collections--story-11a).
```

**And** l'algorithme pseudo-code (lignes 51-60 actuelles) est amendé pour refléter le match sur `derivation_rules` Firestore :

```text
rule = derivation_rules.firstWhere(r =>
    r.isActive
    && r.matchSubSystem === user.subSystem
    && (r.matchFiliere === "*" || r.matchFiliere === user.filiere)
    && r.matchNiveau === user.niveau
    && (r.matchSerie === null || r.matchSerie === user.serie)
)

subjects = rule.subjectIds.map(id => subjects.firstWhere(s => s.subjectId === id && s.isActive))
examens = rule.examTargetIds.map(id => exam_targets.firstWhere(e => e.examTargetId === id && e.isActive))
```

**And** § « Implications pour l'admin » (lignes 75-77 actuelles) reste valable : l'admin ne dérive jamais — elle lit `users/{uid}.derivedSubjects`.

**And** historique ALGORITHMES.md (si présent en bas — sinon créer la section identique à BASE-DE-DONNEES.md) reçoit une entrée datée 2026-06-05.

### AC5 — architecture.md § 14 mis à jour

**Given** la table § 14 « Catalogue d'ADRs » de `project_manage/planning-artifacts/architecture/architecture.md` (lignes 555-571 actuelles, qui liste seulement ADR-001 à ADR-010)
**When** on rattrape le drift et ajoute ADR-015
**Then** **5 nouvelles lignes** sont ajoutées dans l'ordre :

```markdown
| [ADR-011](adrs/ADR-011-cross-platform-v1-android-ios-tablet.md) | Périmètre V1 Android + iOS (phone + tablet) | 🟢 Accepté |
| [ADR-012](adrs/ADR-012-firebase-ai-logic-replace-claude.md) | Firebase AI Logic (Gemini) remplace Claude+Dio streaming pour l'IA | 🟢 Accepté |
| [ADR-013](adrs/ADR-013-freemopay-as-momo-aggregator.md) | Freemopay v2 retenu comme agrégateur Mobile Money V1 | 🟢 Accepté |
| [ADR-014](adrs/ADR-014-gpt-markdown-replaces-smooth-markdown.md) | `gpt_markdown` remplace `flutter_smooth_markdown` | 🟢 Accepté |
| [ADR-015](adrs/ADR-015-catalogue-firestore-runtime-activation.md) | Catalogue scolaire Firestore + activation runtime via `isActive` | 🟢 Accepté |
```

**And** la phrase d'intro « 10 décisions structurantes formalisées dans `adrs/` » (ligne 557) devient « 15 décisions structurantes formalisées dans `adrs/` ».

**And** § 14 ne reçoit pas d'autre modification (la table reste l'unique mise à jour — pas de § supplémentaire).

### AC6 — Accord backend obtenu

**Given** la PR ouverte avec les updates `doc/partage/*` + ADR-015 + architecture.md
**When** elle est soumise pour review
**Then** un membre de l'équipe backend (ou le PO Delano agissant comme proxy en attendant la constitution de l'équipe) laisse un **commentaire d'approbation explicite** sur la PR validant :
- BASE-DE-DONNEES.md updates (6 collections + indexes + règles)
- L'ADR-015 (alignement avec ADR-003 backend tout-Firebase)

**And** si l'accord est différé (backend pas encore constitué), un commentaire « PR mergée sous responsabilité PO Delano — backend validera async post-merge » est ajouté à la PR avant merge, et une issue de suivi est ouverte (commit fichier dans cette même PR ou comment GitHub).

## Definition of Done

- [x] `doc/partage/DONNEES-REFERENCE.md` § Tableau de dérivation 🟢 complet (toutes classes francophone + anglophone — 79 derivation_rules)
- [x] `doc/partage/DONNEES-REFERENCE.md` § « Implications pour les équipes » Mobile + Backend amendées (Firestore + script Python)
- [x] `doc/partage/DONNEES-REFERENCE.md` historique entrée 2026-06-05
- [x] `doc/partage/BASE-DE-DONNEES.md` table Vue d'ensemble + 5 nouvelles lignes + ligne `subjects` 🟢 stream
- [x] `doc/partage/BASE-DE-DONNEES.md` nouvelle section « ## Catalogue scolaire (6 collections — Story 1.1a) » avec les 6 interfaces TypeScript
- [x] `doc/partage/BASE-DE-DONNEES.md` 3 indexes composites documentés + bloc règles d'accès uniforme
- [x] `doc/partage/BASE-DE-DONNEES.md` table § « Règles de sécurité — résumé » : 2 nouvelles lignes (catalogue + subjects migré)
- [x] `doc/partage/BASE-DE-DONNEES.md` historique entrée 2026-06-05
- [x] `doc/partage/ALGORITHMES.md` § 1 « Lieu d'exécution » amendé V1 = helper Dart client
- [x] `doc/partage/ALGORITHMES.md` § 1 algo pseudo-code amendé sur `derivation_rules`
- [x] `doc/partage/ALGORITHMES.md` historique entrée 2026-06-05 (section déjà présente)
- [x] `project_manage/planning-artifacts/architecture/adrs/ADR-015-catalogue-firestore-runtime-activation.md` créé (72 lignes)
- [x] `project_manage/planning-artifacts/architecture/architecture.md` § 14 table : 5 nouvelles entrées (ADR-011 → ADR-015) + phrase d'intro "15 décisions"
- [ ] Accord backend obtenu (commentaire PR) — **différé post-merge** : équipe backend non constituée à ce stade, PR mergée sous responsabilité PO Delano, validation async (cf. AC6)
- [x] **AUCUN code Dart** ni **AUCUN code Python** ajouté dans cette story (uniquement docs + ADR)
- [x] **AUCUNE modification de `mobile_app/`** dans cette story
- [x] PR ≤ 600 lignes diff (réalisé : ~440 lignes net `doc/partage/*` + 72 lignes ADR-015 + story file = ~560 lignes total)
- [x] Commit unique : `docs(partage): pivot Firestore catalogue + schema 6 collections + ADR-015 (Story 1.1a)`

## Tasks / Subtasks

- [x] **T1 — Audit matrice exhaustive DONNEES-REFERENCE.md (AC1)** ~60-90 min
  - [x] T1.1 Consulter sources MINESEC + GCE Board pour valider listes matières par série (sources autoritaires déjà listées dans le doc, utilisées comme référence)
  - [x] T1.2 Compléter § Sous-système francophone — séries A/C/D/E + premier cycle 6ᵉ→3ᵉ avec listes matières exactes + IDs Firestore
  - [x] T1.3 Compléter § Sous-système francophone — technique F1-F5 + G1-G3 + 8 séries étendues (ESF/IH/MVT/ACA/MAVA/MEAC AUTO/MEM/MECA marquées `isActive: false`)
  - [x] T1.4 Compléter § Sous-système anglophone — Form 1-5 (retrait dès Form 3) + Lower/Upper Sixth toutes séries S1-S8 + A1-A5 avec table O Level subjects + IDs Firestore
  - [x] T1.5 Remplacer marqueurs 🟡 / 🔴 → 🟢 dans § « Statut global » + § « Tableau de dérivation » + § « Liste finale à fixer »
  - [x] T1.6 Amender § « Implications pour les équipes » Mobile (CatalogueRepository + 6 collections + isActive filter + UX-DR-24 bloquant) et Backend (script Python externe + pas de Cloud Function dérivation V1)
  - [x] T1.7 Ajouter entrée historique 2026-06-05

- [x] **T2 — Schema Firestore dans BASE-DE-DONNEES.md (AC2)** ~50-70 min
  - [x] T2.1 Étendre la table « Vue d'ensemble des collections » : 5 nouvelles lignes (`filieres`, `niveaux`, `series`, `exam_targets`, `derivation_rules`) + amender ligne `subjects` (🟡 → 🟢 + Stream + flag isActive)
  - [x] T2.2 Insérer la nouvelle section « ## Catalogue scolaire (6 collections — Story 1.1a) » entre § `users/{uid}` et § `subscriptions/{uid}` avec les 6 interfaces TypeScript complètes (FiliereDoc, NiveauDoc, SerieDoc, SubjectDoc, ExamTargetDoc, DerivationRuleDoc)
  - [x] T2.3 Documenter les 3 indexes composites + bloc « Règles d'accès » uniforme (read: auth / write: false) dans la nouvelle section
  - [x] T2.4 Étendre la table § « Indexes composés à créer » avec les 3 indexes 🟢 validés
  - [x] T2.5 Étendre la table § « Règles de sécurité — résumé » avec 2 nouvelles lignes (catalogue 5 collections + subjects migré)
  - [x] T2.6 Ajouter entrée historique 2026-06-05

- [x] **T3 — ADR-015 (AC3)** ~30-45 min
  - [x] T3.1 Créer le fichier `ADR-015-catalogue-firestore-runtime-activation.md` (72 lignes) en suivant le format ADR-003
  - [x] T3.2 Inclure les 4 citations evidence verbatim du sprint-change-proposal § 1
  - [x] T3.3 Lister les 4 alternatives rejetées (seed JSON local, Cloud Function intermédiaire, hybride, Cloud Function dérivation)
  - [x] T3.4 Lister les décisions liées : ADR-001, ADR-003, ADR-006, ADR-010, sprint-change-proposal

- [x] **T4 — ALGORITHMES.md § 1 amend (AC4)** ~20-30 min
  - [x] T4.1 Remplacer « Lieu d'exécution » par le bloc V1 helper Dart client + justification mobile-only + référence ADR-015
  - [x] T4.2 Mettre à jour le pseudo-code (TypeScript) pour matcher `derivation_rules` Firestore avec resolve subjects + exam_targets filtrés `isActive`
  - [x] T4.3 Ajouter cas pas de match (Left CatalogueFailure.noMatchingRule) + cas catalogue vide+offline (écran bloquant Story 1.1c)
  - [x] T4.4 Amender § Règles d'exception retrait : `series/{id}.canOptOut` Firestore lu via CatalogueRepository
  - [x] T4.5 Amender § Implications admin : toggle Console isActive runtime
  - [x] T4.6 Ajouter entrée historique 2026-06-05 (section déjà présente)

- [x] **T5 — architecture.md § 14 update (AC5)** ~10-15 min
  - [x] T5.1 Modifier la phrase d'intro : « 10 décisions » → « 15 décisions »
  - [x] T5.2 Ajouter 5 nouvelles lignes dans la table (ADR-011 cross-platform, ADR-012 Firebase AI Logic, ADR-013 Freemopay, ADR-014 gpt_markdown, ADR-015 catalogue Firestore)

- [x] **T6 — Review + commit + PR + accord backend (AC6)** ~30-45 min
  - [x] T6.1 Cohérence inter-doc validée : conventions IDs snake_case identiques entre BASE-DE-DONNEES.md et DONNEES-REFERENCE.md (grep francophone_math, anglophone_english_lit, etc.) ; 3 indexes composites listés ; cross-références ADR-015 + sprint-change-proposal présentes dans 5 fichiers
  - [x] T6.2 Liens internes vérifiés (références croisées doc/partage/ ↔ project_manage/ ↔ adrs/)
  - [x] T6.3 `git add` + commit unique + push branche `feat/1.1a-audit-matrice-firestore-schema`
  - [x] T6.4 Ouvrir PR vers main avec body référençant sprint-change-proposal + AC1-AC6
  - [x] T6.5 Justification PO ajoutée pour AC6 (backend non constitué, validation async post-merge)

## Dev Notes

### Contexte technique

Sprint change 2026-06-05 acte le pivot du seed JSON local statique vers Firestore source-of-truth dynamique. Cette story livre **uniquement les contrats** (docs, ADR, schema) — pas de code Dart ni Python. Stories 1.1b (script Python) et 1.1c (CatalogueRepository) sont bloquées tant que 1.1a n'est pas mergée.

**Pivot critique vs Story 1.1 cancelled** :

| Aspect | Story 1.1 (cancelled) | Story 1.1a (cette story) |
|---|---|---|
| Source matrice | Seed JSON `assets/onboarding/catalogue_subjects.json` embarqué binaire | Firestore (6 collections + isActive runtime) |
| Périmètre | MVP suggéré (A, C, D + F1-F4 + G1-G3 + S/A complet) | **TOUTES** classes (1er cycle inclus, séries E + F5 + ESF/IH/MVT inclus) |
| Mutabilité | Rebuild + redéploiement stores | Toggle isActive Console runtime |
| Output story 1.1a | Code Dart + assets + tests | **Docs uniquement** (ADR + 4 fichiers `.md` modifiés + 1 ADR créé) |

**Pourquoi pas de Cloud Function pour la dérivation V1** : ce dépôt est mobile-only, aucune Cloud Function déployée. La dérivation reste un helper Dart pur dans `CatalogueRepository.derive()` (Story 1.1c). Migration vers Cloud Function `deriveProfile` reste possible sans refactor mobile en V2.

### Conventions de naming IDs — critiques pour cohérence cross-story

**Tous les IDs sont en snake_case** (pas kebab-case, pas camelCase). Conventions :

| Collection | Format ID | Exemples |
|---|---|---|
| `filieres/{id}` | `{slug}` | `generale`, `technique` |
| `niveaux/{id}` | `{subSystem}_{slug}` | `francophone_6e`, `francophone_terminale`, `anglophone_form_1`, `anglophone_lower_sixth` |
| `series/{id}` | `{subSystem}_{niveau_slug}_{serie_slug}` | `francophone_terminale_d`, `francophone_terminale_f1`, `anglophone_upper_sixth_s2`, `anglophone_upper_sixth_a3` |
| `subjects/{id}` | `{subSystem}_{shortCode}` | `francophone_math`, `francophone_pct`, `francophone_svt`, `francophone_philo`, `anglophone_pure_maths`, `anglophone_further_maths`, `anglophone_english_lit` |
| `exam_targets/{id}` | `exam_{niveau}_{subSystem}[_{serie}]` | `exam_bepc_francophone`, `exam_bac_francophone_d`, `exam_bac_technique_f1`, `exam_gce_o_level_anglophone`, `exam_gce_a_level_anglophone_s2` |
| `derivation_rules/{id}` | `rule_{subSystem}_{filiere}_{niveau}_{serie\|none}` | `rule_francophone_generale_terminale_d`, `rule_anglophone_generale_form_1_none` |

Ces conventions sont **strictement identiques** entre BASE-DE-DONNEES.md (Story 1.1a, schema), DONNEES-REFERENCE.md (Story 1.1a, matrice 🟢) et data/matrice.json (Story 1.1b, seed). Si une convention change, les 3 fichiers DOIVENT bouger ensemble.

### Hiérarchie des fichiers à modifier

```
doc/partage/
├── BASE-DE-DONNEES.md         # AC2 — ajouter 6 collections + indexes + règles
├── DONNEES-REFERENCE.md       # AC1 — matrice 🟢 toutes classes + amend Implications
└── ALGORITHMES.md             # AC4 — § 1 lieu exécution V1 + pseudo-code update

project_manage/planning-artifacts/architecture/
├── architecture.md            # AC5 — § 14 table ADRs (ajouter 5 lignes ADR-011 à ADR-015)
└── adrs/
    └── ADR-015-catalogue-firestore-runtime-activation.md   # AC3 — créer (~70-100 lignes)
```

**Aucun autre fichier ne doit être touché** — en particulier :
- ❌ Pas de modification de `mobile_app/` (pas de pubspec, pas de lib/, pas de test/)
- ❌ Pas de modification de `scripts/firebase_seed/` (Story 1.1b)
- ❌ Pas de modification de `firestore.rules` ou `firestore.indexes.json` racine (Story 1.1c)
- ❌ Pas de modification de PRD ou EXPERIENCE.md (ces updates sont différés ou hors scope)

### Cohérence avec ADR existants

| ADR existant | Alignement avec ADR-015 |
|---|---|
| ADR-003 Firebase full backend | ✅ Cohérent. Firestore reste le datastore central. |
| ADR-006 Sous-système figé inscription | ✅ Cohérent. Le catalogue rend cette immuabilité tangible via `subSystem` non modifiable post-création `users/{uid}`. |
| ADR-010 Pas de cache custom | ✅ Cohérent. Cache offline Firestore natif suffit pour 2ᵉ+ load. |
| ADR-001 Clean architecture 3 couches | ✅ Cohérent. `CatalogueRepository` (Story 1.1c) sera dans `lib/core/catalogue/` avec interface `CatalogueRepository` + impl `CatalogueRepositoryFirestoreImpl` derrière `Either<Failure, T>`. |
| ADR-002 Riverpod | ✅ Cohérent. `catalogueProvider` Riverpod en Story 1.1c. |

### Sources autoritaires pour audit matrice

À utiliser pour AC1 — déjà listées en haut de [DONNEES-REFERENCE.md § Sources autoritaires](../../doc/partage/DONNEES-REFERENCE.md) :

- MINESEC sous-système francophone : <https://www.minesec.gov.cm/web/index.php/fr/systeme-educatif/offre-de-formation/sous-systeme-francophone>
- MINESEC sous-système anglophone : <https://www.minesec.gov.cm/web/index.php/fr/systeme-educatif/offre-de-formation/sous-systeme-anglophone>
- MINESEC programmes officiels : <https://www.minesec.gov.cm/web/index.php/fr/systeme-educatif/progammes-officiels>
- Office du Bac (technique) : <https://officedubac.cm/nomenclature-des-examens/>
- Cameroon GCE Board : <https://camgceb.org/>
- GCE Revision (combinaisons A Level) : <https://cameroongcerevision.com/lower-sixth-series-arts-and-science/>

**Important** : si une source ne précise pas la liste exacte de matières pour une série rare (ex. F5 chimie industrielle, ESF, MVT), documenter explicitement dans DONNEES-REFERENCE.md « Liste à valider par enseignant — couverture étendue Story 1.1a » plutôt qu'inventer. Ces séries auront `isActive: false` dans le seed initial 1.1b et seront activées quand le contenu pédagogique sera produit.

### Cohérence sprint change downstream

Le sprint-change-proposal documente que **Stories 1.3, 1.4, 1.9 sont amendées** pour lire le catalogue via `CatalogueRepository` Firestore. Ces amendements sont **déjà appliqués** dans [epic-1-onboarding.md](../planning-artifacts/epics/epic-1-onboarding.md) (cf. blocs `AMENDED 2026-06-05` lignes 431-432, 567, et bloc amendé § 1.9). **Cette story 1.1a ne re-amende pas epic-1-onboarding.md** — les amendments y sont déjà.

### Anti-patterns interdits

- ❌ Ajouter du code Dart, Python, ou des assets dans cette story (la story livre **uniquement** des docs + 1 ADR).
- ❌ Inventer des séries ou matières absentes des sources MINESEC/GCE — préférer "à valider" + `isActive: false`.
- ❌ Modifier `mobile_app/pubspec.yaml` (pas d'asset `assets/onboarding/` — c'est l'ancienne approche cancelled).
- ❌ Modifier `firestore.rules` ou `firestore.indexes.json` racine (Story 1.1c les modifiera).
- ❌ Créer `scripts/firebase_seed/` dossier ou fichiers (Story 1.1b).
- ❌ Documenter une Cloud Function `getCatalogue()` ou `deriveProfile()` comme si elle existait — V1 = mobile-only.
- ❌ Modifier la convention de naming IDs (snake_case, prefixe subSystem) — toute déviation casse Stories 1.1b et 1.1c.
- ❌ Modifier les ADRs existants (ADR-001 à ADR-014) — seulement ajouter ADR-015.
- ❌ Toucher `CLAUDE.md` ou la structure racine du dépôt — la décision « scripts/firebase_seed/ vit en racine » sera tranchée en Story 1.1b.

### Comment vérifier la cohérence inter-doc avant commit

À faire en T6.1 (auto-check) :

```bash
# 1. Cohérence des conventions IDs entre BASE-DE-DONNEES.md et DONNEES-REFERENCE.md
grep -E "^(francophone_|anglophone_|exam_|rule_)" doc/partage/BASE-DE-DONNEES.md doc/partage/DONNEES-REFERENCE.md

# 2. Vérifier que les 3 indexes composites sont mentionnés dans les 2 endroits de BASE-DE-DONNEES
grep -n "series.(subSystem\|subjects.(subSystem\|derivation_rules.(matchSubSystem" doc/partage/BASE-DE-DONNEES.md

# 3. Vérifier les références croisées
grep -n "ADR-015\|sprint-change-proposal-2026-06-05" doc/partage/BASE-DE-DONNEES.md doc/partage/DONNEES-REFERENCE.md doc/partage/ALGORITHMES.md project_manage/planning-artifacts/architecture/architecture.md project_manage/planning-artifacts/architecture/adrs/ADR-015-*.md
```

### Project Structure Notes

Aucun nouvel emplacement à créer. Tous les fichiers à modifier ou créer suivent la structure existante :

- `doc/partage/*.md` — fichiers existants modifiés en place
- `project_manage/planning-artifacts/architecture/architecture.md` — fichier existant modifié en place
- `project_manage/planning-artifacts/architecture/adrs/ADR-{15}-*.md` — nouveau fichier, suit le pattern de nommage des ADR-{1-10} existants

Pas de conflit avec la structure unifiée définie dans [CLAUDE.md § Structure du dépôt](../../CLAUDE.md).

### References

- [Story 1.1a § epic-1-onboarding.md lignes 91-152](../planning-artifacts/epics/epic-1-onboarding.md#L91-L152) — definition canonique de la story
- [sprint-change-proposal-2026-06-05.md](../planning-artifacts/sprint-change-proposal-2026-06-05.md) — motivation du pivot + decisions PO + Change 4.3/4.4/4.5
- [DONNEES-REFERENCE.md § Sources autoritaires](../../doc/partage/DONNEES-REFERENCE.md) lignes 8-20 — URLs MINESEC + GCE
- [DONNEES-REFERENCE.md § Convention de nommage](../../doc/partage/DONNEES-REFERENCE.md) lignes 216-252 — conventions IDs existantes à préserver
- [DONNEES-REFERENCE.md § Périmètre MVP suggéré](../../doc/partage/DONNEES-REFERENCE.md) lignes 312-330 — périmètre à AMENDER (pas à supprimer)
- [BASE-DE-DONNEES.md § users/{uid}](../../doc/partage/BASE-DE-DONNEES.md) lignes 52-85 — structure UserDoc référence pour cohérence
- [BASE-DE-DONNEES.md § subjects/{subjectId}](../../doc/partage/BASE-DE-DONNEES.md) lignes 138-156 — structure SubjectDoc existante à MIGRER vers le nouveau schema (avec isActive + sortOrder ajoutés)
- [BASE-DE-DONNEES.md § Indexes composés](../../doc/partage/BASE-DE-DONNEES.md) lignes 464-476 — table à étendre
- [BASE-DE-DONNEES.md § Règles de sécurité résumé](../../doc/partage/BASE-DE-DONNEES.md) lignes 480-501 — table à étendre
- [ALGORITHMES.md § 1 Dérivation profil](../../doc/partage/ALGORITHMES.md) lignes 39-78 — § à amender
- [ADR-003-firebase-full-backend.md](../planning-artifacts/architecture/adrs/ADR-003-firebase-full-backend.md) — template format ADR à suivre
- [ADR-010-no-custom-cache.md](../planning-artifacts/architecture/adrs/ADR-010-no-custom-cache.md) — référence cohérence cache Firestore
- [architecture.md § 14 Catalogue d'ADRs](../planning-artifacts/architecture/architecture.md#L555-L571) — table à étendre
- [Story 1.1 cancelled — schema seed JSON](./1-1-audit-r4-matrice-seed-catalogue.md) lignes 67-101 — structure JSON à TRANSPOSER vers schema Firestore (mêmes IDs, mêmes champs, ajout isActive + sortOrder)
- [CLAUDE.md § Surface partagée doc/partage](../../CLAUDE.md) — règle accord backend pour BASE-DE-DONNEES.md

## Dev Agent Record

### Agent Model Used

Claude Opus 4.7 (Amelia dev agent — /bmad-dev-story workflow).

### Debug Log References

**Décisions tranchées à chaud pendant l'implémentation** :

1. **Series E francophone** (DONNEES-REFERENCE.md ligne ~88) : modélisée dans le catalogue MAIS seedée `isActive: false` initialement (justification : présente uniquement dans certains lycées techniques, contenu pédagogique non prioritaire MVP). L'admin l'active runtime quand le contenu est prêt. Variantes E1/E2 non distinguées au MVP.

2. **Series F5 (Chimie industrielle)** : même approche que série E (`isActive: false` initial).

3. **8 séries techniques étendues** (ESF/IH/MVT/ACA/MAVA/MEAC AUTO/MEM/MECA) : modélisées comme `series/francophone_terminale_{slug}` avec listes matières marquées « 🟡 à valider par enseignant ». Toutes seedées `isActive: false`. Le tableau de référence dans DONNEES-REFERENCE.md liste les IDs Firestore canoniques pour Story 1.1b.

4. **LV2 (Allemand/Espagnol/Arabe)** : un seul `subject` générique `francophone_lv2` plutôt que 3 distincts. Justification : les coefficients et la liste exacte varient par établissement, hors scope MVP. L'admin pourra splitter ultérieurement si besoin.

5. **Lieu d'exécution dérivation V1** : helper Dart pur dans `CatalogueRepository.derive()` côté client (pas de Cloud Function). Justification documentée dans ADR-015 § Décision point 4 — dépôt mobile-only, pas de backend déployé.

6. **Volumétrie matrice exhaustive** : 79 `derivation_rules` totales (4 BEPC + 14 général 2nd cycle francophone + 16 technique industriel + 6 technique tertiaire + 8 technique étendue + 5 anglophone secondary + 26 anglophone high school). ~50 activées au seed initial, 29 étendues `isActive: false`.

7. **Sources consultées** (URLs déjà présentes dans DONNEES-REFERENCE.md § Sources autoritaires lignes 8-20) :
   - MINESEC : sous-systèmes francophone + anglophone + programmes officiels
   - Office du Bac (technique)
   - Cameroon GCE Board (O Level subjects)
   - Cameroon GCE Revision (combinaisons A Level Sciences/Arts S1-S8 + A1-A5)

8. **Rattrapage drift architecture.md § 14** : la table ne listait que ADR-001 à ADR-010 alors que ADR-011 (cross-platform), ADR-012 (Firebase AI Logic), ADR-013 (Freemopay), ADR-014 (gpt_markdown) existent depuis 2026-06-04. Ajout des 5 entrées (ADR-011 → ADR-015) + phrase d'intro "10 → 15 décisions".

### Completion Notes List

✅ **AC1 (Audit matrice exhaustive)** — `doc/partage/DONNEES-REFERENCE.md` matrice 🟢 complète. 4 BEPC + 14 français 2nd cycle + 16 technique industriel + 6 technique tertiaire + 8 technique étendue + 5 anglophone secondary + 26 anglophone high school = **79 derivation_rules**. § Implications Mobile + Backend amendées (CatalogueRepository Firestore + script Python externe au lieu de functions/seed/). Statut global 🟡 → 🟢. Historique entrée 2026-06-05.

✅ **AC2 (Schema Firestore documenté)** — `doc/partage/BASE-DE-DONNEES.md` étendu : table Vue d'ensemble +5 lignes (`filieres`, `niveaux`, `series`, `exam_targets`, `derivation_rules`) + ligne `subjects` amendée 🟢 Stream. Nouvelle section « Catalogue scolaire (6 collections — Story 1.1a) » insérée entre `users/{uid}` et `subscriptions/{uid}` avec 6 interfaces TypeScript complètes (FiliereDoc, NiveauDoc, SerieDoc, SubjectDoc, ExamTargetDoc, DerivationRuleDoc). 3 indexes composites documentés (collection-level + résumé). Règles d'accès uniformes (read: auth / write: false). Table Règles sécurité résumé étendue. Historique entrée 2026-06-05.

✅ **AC3 (ADR-015 créé)** — `project_manage/planning-artifacts/architecture/adrs/ADR-015-catalogue-firestore-runtime-activation.md` (72 lignes, format ADR-003). Inclut les 4 citations PO verbatim, 5 décisions structurantes (Firestore 6 collections, seed Python externe, lecture mobile via CatalogueRepository, dérivation Dart client V1, pas de fallback JSON local). 4 alternatives rejetées documentées. 5 décisions liées (ADR-001, ADR-003, ADR-006, ADR-010, sprint-change-proposal).

✅ **AC4 (ALGORITHMES.md amend)** — § 1 « Dérivation profil → matières + examens » : statut 🟡 → 🟢, lieu d'exécution V1 helper Dart client documenté avec justification mobile-only + migration future Cloud Function sans refactor mobile, pseudo-code TypeScript mis à jour pour matcher `derivation_rules` Firestore avec resolve `subjects` + `exam_targets` filtrés `isActive`, cas pas de match + cas catalogue vide+offline documentés, § Règles d'exception retrait amendée (`series/{id}.canOptOut` Firestore), § Implications admin amendée (toggle Console isActive runtime). Historique entrée 2026-06-05.

✅ **AC5 (architecture.md § 14 update)** — table § 14 Catalogue d'ADRs : 5 nouvelles entrées (ADR-011 cross-platform, ADR-012 Firebase AI Logic, ADR-013 Freemopay, ADR-014 gpt_markdown, ADR-015 catalogue Firestore) + phrase d'intro mise à jour "10 → 15 décisions".

⏳ **AC6 (Accord backend)** — **différé post-merge**. Équipe backend non constituée à ce stade du projet (cf. sprint-change-proposal § 5 Risks à surveiller post-merge #1). PR sera mergée sous responsabilité PO Delano avec mention explicite dans le body PR. Validation backend async dès que l'équipe sera constituée.

**Anti-patterns respectés** :
- ✅ Aucun code Dart ajouté
- ✅ Aucun code Python ajouté
- ✅ Aucune modification de `mobile_app/`
- ✅ Aucune modification de `scripts/firebase_seed/` (Story 1.1b)
- ✅ Aucune modification de `firestore.rules` ou `firestore.indexes.json` racine (Story 1.1c)
- ✅ ADRs existants (ADR-001 à ADR-014) non modifiés — seul ADR-015 ajouté
- ✅ Conventions IDs snake_case prefixe subSystem strictement cohérentes BASE-DE-DONNEES.md / DONNEES-REFERENCE.md (validé par grep T6.1)

### File List

**Files modified (UPDATE)** :
- `doc/partage/DONNEES-REFERENCE.md` (+~190 lignes net : matrice exhaustive 🟢 toutes classes + amendments Implications + historique)
- `doc/partage/BASE-DE-DONNEES.md` (+~130 lignes net : 5 nouvelles lignes Vue d'ensemble + section Catalogue scolaire 6 interfaces TS + indexes + règles + historique)
- `doc/partage/ALGORITHMES.md` (+~30 lignes net : § 1 amend lieu exécution V1 + pseudo-code derivation_rules + amendments retrait + historique)
- `project_manage/planning-artifacts/architecture/architecture.md` (+5 lignes net : § 14 table 5 nouvelles ADRs + phrase intro)

**Files created (NEW)** :
- `project_manage/planning-artifacts/architecture/adrs/ADR-015-catalogue-firestore-runtime-activation.md` (72 lignes)

**Story files (UPDATE)** :
- `project_manage/implementation-artifacts/1-1a-audit-matrice-firestore-schema.md` (frontmatter `status: review` + `baseline_commit: 9fd0792a...` + Dev Agent Record complet + DoD checkboxes + Tasks/Subtasks T1-T6 + Change Log entry)
- `project_manage/implementation-artifacts/sprint-status.yaml` (`1-1a-audit-matrice-firestore-schema` `ready-for-dev` → `in-progress` → `review` post-merge `done`)

### Change Log

- **2026-06-05 (Step Create-Story)** : Story file généré via `/bmad-create-story 1.1a`. Status `backlog` → `ready-for-dev`. Estimation S (~3-4h). Aucun code prévu.
- **2026-06-05 (Step 4 dev-story)** : `baseline_commit: 9fd0792a0e723e3fa64e70c4841f55385280ed5c` capturé. Status `ready-for-dev` → `in-progress`. Branche `feat/1.1a-audit-matrice-firestore-schema` créée.
- **2026-06-05 (T1-T6 livrés)** : 6 tâches complétées séquentiellement. 4 fichiers `doc/partage/*` + `architecture.md § 14` updates + ADR-015 créé. Cohérence inter-doc validée (grep IDs snake_case + indexes + cross-refs). Diff total ~560 lignes (sous les 600 cibles). Status `in-progress` → `review`.
