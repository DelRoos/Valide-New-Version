---
story_id: 1.18
title: Refactor extractif `_Body` x4 → composants partagés + audit responsive screens (dette Epic 1 v2 — Action Items A5 + A7) — V2 corrigée 2026-06-10
revision: 2 (corrections post-discovery dev exploration)
epic: 1
phase: P1 cleanup post Epic 1 v2 (action items rétro epic-1v2-retro-2026-06-10.md)
status: ready-for-dev
created: 2026-06-10
revised: 2026-06-10  # corrections noms composants + scope A7 après lecture source code
baseline_commit: 44044df  # merge PR #88 (contexte engine Story 1.18) — main aligné post discipline composants + responsive  # merge PR #87 (discipline composants + responsive) — main aligné post Epic 1 v2 COMPLETE + retro + règles 11/6 + catalogue + templates + customize.toml BMAD enhancements
estimation: M (~5-6h)
sprint_change: epic-1v2-retro-2026-06-10.md (action items A5 + A7)
dependencies:
  - PR #87 (discipline) merged — CLAUDE.md règle 11 + COMPOSANTS-REUTILISABLES.md + STORY-TEMPLATES.md + customize.toml `bmad-create-story` / `bmad-dev-story` (catalogue à alimenter)
  - Stories 1.4 + 1.15 + 1.16 + 1.17 mergées — 4 `_Body` widgets privés à extraire dans `subjects_picker_page.dart` (1297 lignes)
  - Story 1.7 mergée — `school_picker_page.dart` à auditer pour responsive (A7)
  - Story 1.9 mergée — `dashboard_placeholder` à auditer pour responsive (A7)
blocks:
  - Story 1.10 (suppression compte 7j grace) — pas bloquante mais cloture Epic 1 après 1.18
  - Epic 1.5 Schools completion — bénéficiera des composants extraits (chips résultats recherche école pourront réutiliser `OptionalSubjectChipGrid` ou similaire)
  - Epic 2 (Navigation & Lecture contenu) — bénéficiera du catalogue alimenté + golden tests tablet baseline en place
sourceArtifacts:
  - project_manage/implementation-artifacts/epic-1v2-retro-2026-06-10.md § Action Items A5 (Story 1.18 refactor extractif) + A7 (audit responsive screens existants)
  - CLAUDE.md règle 11 (composants réutilisables) + règles 3/5 (responsive durcies) + règle 6 Workflow Git (1 PR à la fois)
  - doc/tech/COMPOSANTS-REUTILISABLES.md § « À extraire — dette Epic 1 v2 » (5 composants candidats + paths cibles + lignes source)
  - doc/tech/STORY-TEMPLATES.md (templates 1 Dev Notes condensé + 3 Stratégie responsive + 4 Composants réutilisables)
  - mobile_app/lib/features/onboarding/presentation/subjects_picker_page.dart (1297 lignes — fichier source du refactor)
  - mobile_app/lib/features/onboarding/presentation/school_picker_page.dart (audit responsive A7)
  - mobile_app/lib/features/dashboard/presentation/dashboard_placeholder.dart (audit responsive A7) — vérifier path exact
  - mobile_app/test/features/onboarding/presentation/subjects_picker_page_*_test.dart (4 fichiers tests — Story 1.4 + 1.15 + 1.16 + 1.17 — à 100% préserver)
  - mobile_app/test/features/onboarding/presentation/school_picker_page_test.dart (Story 1.7 — à 100% préserver)
---

# Story 1.18 — Refactor extractif `_Body` x4 → composants partagés + audit responsive screens

Status: **ready-for-dev** (révision 2 — corrections post-discovery 2026-06-10)

## ⚠️ Discovery & révision 2 (2026-06-10)

Lors d'une première exploration du dev de cette story, lecture des ~480 premières lignes de `mobile_app/lib/features/onboarding/presentation/subjects_picker_page.dart` a révélé **2 écarts importants** avec les hypothèses de la révision 1 :

### Écart 1 : `LayoutBuilder` responsive **déjà en place** dans les 4 `_Body`

Lignes 376-378 (`_LegacyOptOutBody`) et 559-561 (`_FreeWithObligatoryBody`) confirment :

```dart
return LayoutBuilder(
  builder: (context, constraints) {
    final isTablet = constraints.maxWidth >= 840;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isTablet ? 720 : double.infinity),
        ...
```

Les Stories 1.15-1.17 ont **déjà** introduit `LayoutBuilder + ConstrainedBox(maxWidth: 720 si tablet)` sans le tracer en Dev Notes. La rétro Epic 1 v2 Challenge 2 a sur-estimé la dette responsive sur ce fichier — **l'AC8 sur `subjects_picker_page` est partiellement déjà résolu** (manque uniquement les golden tests baseline tablet).

→ Conséquence : **AC8 + T8 sont réduits** sur `subjects_picker_page` (golden tests uniquement) et **conservés intégralement** sur `school_picker_page` + `dashboard_page` + `placeholder_tab_page` (audit à faire).

### Écart 2 : Le code utilise `CheckboxListTile` + `ListView.separated`, **pas** `Chip` ni `Grid`

Les noms d'origine du catalogue + de cette story (révision 1) — `ObligatorySubjectChipList`, `OptionalSubjectChipGrid` — étaient basés sur des hypothèses incorrectes. Le code réel utilise :

- `ListView.separated` + `CheckboxListTile` avec `secondary: Icon(LucideIcons.lock)` pour les obligatoires
- `ListView.separated` + `CheckboxListTile` interactif pour les optionnels

→ Conséquence : **renommer les composants** pour refléter l'implémentation réelle :

| Nom révision 1 (incorrect) | Nom révision 2 (corrigé) | Pourquoi |
|---|---|---|
| `ObligatorySubjectChipList` | `ObligatorySubjectCheckboxList` | Le widget réel est `CheckboxListTile`, pas `Chip` |
| `OptionalSubjectChipGrid` | `OptionalSubjectCheckboxList` | `ListView.separated` (vertical), pas `Grid` |
| `PickerSectionCard` | `PickerSectionScaffold` (proposition) ou `PickerSectionWrapper` | Pattern réel = LayoutBuilder + Center + ConstrainedBox + Padding + Column scaffold, pas un Card visuel |
| `PickerValidateBar` | `PickerValidateBar` (inchangé) | Nom toujours correct |
| `PickerToastFeedback` | **À ne pas créer** — `AppToast.show(context, message, tone: ToastTone.warning)` existant suffit | Découverte ligne 261-265 : pattern déjà unifié via `AppToast` |

→ Conséquence catalogue : `doc/tech/COMPOSANTS-REUTILISABLES.md` § « À extraire — dette Epic 1 v2 » mis à jour avec les noms corrigés (PR de cette révision 2).

→ Conséquence T6 : la sous-tâche « Extraire `PickerToastFeedback` » est **supprimée** (déjà résolue par `AppToast`). T6 devient une simple confirmation dans Completion Notes que les 4 `_Body` consomment bien `AppToast.show(...)` (déjà le cas).

### Décision périmètre révisé

- **5 composants → 4 composants** à créer (skip `PickerToastFeedback`).
- **AC8 audit responsive sur `subjects_picker_page`** : réduit à « ajouter ≥ 1 golden test baseline tablet » (le `LayoutBuilder` existe déjà).
- **AC8 sur `school_picker_page` + `dashboard_page` + `placeholder_tab_page`** : conservé intégralement (à auditer).
- **Estimation** : M (~4-5h) au lieu de ~5-6h (skip T6 PickerToastFeedback + scope T8 réduit).

Les AC + Tasks ci-dessous restent valides avec ces corrections de noms et de scope. Le dev `/bmad-dev-story` (session dédiée fresh-context recommandée) utilisera la révision 2.

---

## Objectif

Résorber la **dette technique majeure** identifiée en rétrospective Epic 1 v2 (Challenge 1 + Challenge 2) :

1. **Action Item A5** : extraire les 4 widgets privés `_LegacyOptOutBody` + `_FreeWithObligatoryBody` + `_SeriesPlusOptionalBody` + `_TvePickerBody` du fichier `mobile_app/lib/features/onboarding/presentation/subjects_picker_page.dart` (1297 lignes) en **5 composants partagés** dans `mobile_app/lib/core/widgets/picker/` + `mobile_app/lib/core/widgets/feedback/`, et les documenter dans `doc/tech/COMPOSANTS-REUTILISABLES.md` (catalogue source de vérité, CLAUDE.md règle 11).

2. **Action Item A7** : auditer les 3 écrans existants non-responsive (`subjects_picker_page`, `school_picker_page`, `dashboard_placeholder`) et y ajouter `LayoutBuilder` adaptatif phone/tablet + golden tests baseline tablet ≥ 840 dp (CLAUDE.md règle 5 durcie).

**Pourquoi maintenant** :
- Epic 1 v2 a accumulé cette dette via le pattern « dupliquer plutôt que généraliser » (Stories 1.15 → 1.16 → 1.17 — décision pragmatique cohérente court-terme).
- L'attendre = la propager à Epic 1.5 Schools (chips résultats recherche école dupliqueraient les chips matières) puis à Epic 2 (cartes leçon / listes chapitres reproduiraient le même anti-pattern).
- Premier test grandeur nature des nouvelles règles CLAUDE.md 11 et 3/5 durcies + customize.toml BMAD enhancements (PR #87 merge `b451b5f`).

**Pourquoi pas plus tard** : la résorption coûte ~5-6h maintenant ; reportée après Epic 2 elle coûtera 3-5× plus (refactor d'un patchwork de duplications cumulées).

---

## User Story

**En tant que** développeur de Valide School (et Project Lead),
**je veux** que les widgets répétés du `SubjectsPickerPage` soient extraits en composants réutilisables documentés dans le catalogue,
**afin que** :
- les futures stories (Epic 1.5 + Epic 2) consomment ces composants au lieu de dupliquer du code,
- le fichier `subjects_picker_page.dart` redevienne lisible (~500 lignes vs 1297) — l'orchestrateur polymorphe pur sans corps de widget,
- les 3 écrans existants reçoivent un comportement tablet-adaptive minimum (audit A7) en preventif d'Epic 2 (qui héritera de la dette responsive sinon),
- la PR serve de preuve par démonstration que les nouvelles règles CLAUDE.md 11 + 3/5 durcies + customize.toml BMAD enhancements produisent le résultat attendu.

---

## Acceptance Criteria

### AC1 — Extraction `PickerSectionCard`

**Étant donné** que les 4 `_Body` recréent un wrapper de section identique (titre + sous-titre optionnel + contenu),
**Quand** la Story 1.18 est terminée,
**Alors** :
- Le composant `PickerSectionCard(title: String, subtitle: String?, child: Widget)` existe dans `mobile_app/lib/core/widgets/picker/picker_section_card.dart`.
- Une entrée catalogue est ajoutée dans `doc/tech/COMPOSANTS-REUTILISABLES.md` § « Catalogue actuel » au format du template d'entrée (path, story origine, catégorie `picker`, responsive `phone + tablet`, props, exemple, tests associés).
- Les 4 `_Body` utilisent ce composant pour toutes leurs sections (au moins 8 usages cumulés à travers les 4 `_Body`).
- Au moins 1 test widget unitaire et **1 golden test ≥ 840 dp** dans `mobile_app/test/core/widgets/picker/picker_section_card_test.dart`.

### AC2 — Extraction `ObligatorySubjectChipList`

**Étant donné** que les 4 `_Body` recréent une liste de chips lockées identiques (matières obligatoires, non-toggleable),
**Quand** la Story 1.18 est terminée,
**Alors** :
- Le composant `ObligatorySubjectChipList(subjects: List<Subject>)` existe dans `mobile_app/lib/core/widgets/picker/obligatory_subject_chip_list.dart`.
- Une entrée catalogue est ajoutée pour ce composant.
- Les 4 `_Body` consomment ce composant.
- Tests : 1 widget test + 1 golden test ≥ 840 dp.

### AC3 — Extraction `OptionalSubjectChipGrid`

**Étant donné** que 3 des 4 `_Body` (Stories 1.4 / 1.15 / 1.16) recréent une grille de chips toggleable + danger banner sur over-pick,
**Quand** la Story 1.18 est terminée,
**Alors** :
- Le composant `OptionalSubjectChipGrid({required subjects, required picked, required onToggle, int? maxPicks, bool dangerBannerOnOverpick = true})` existe dans `mobile_app/lib/core/widgets/picker/optional_subject_chip_grid.dart`.
- Une entrée catalogue est ajoutée.
- Les 3 `_Body` concernés consomment ce composant (le `_TvePickerBody` n'a pas d'over-pick possible, peut quand même consommer pour cohérence sans `maxPicks`).
- Tests : 1 widget test (toggle + over-pick danger banner) + 1 golden test ≥ 840 dp.

### AC4 — Extraction `PickerValidateBar`

**Étant donné** que les 4 `_Body` recréent une bar CTA validation (compteur + bouton primary/secondary désactivé si invalide),
**Quand** la Story 1.18 est terminée,
**Alors** :
- Le composant `PickerValidateBar({required pickedCount, required totalCount, required onValidate, required isValid})` existe dans `mobile_app/lib/core/widgets/picker/picker_validate_bar.dart`.
- Une entrée catalogue est ajoutée.
- Les 4 `_Body` consomment ce composant.
- Tests : 1 widget test (état désactivé si !isValid, tap déclenche callback si isValid) + 1 golden test ≥ 840 dp.

### AC5 — Extraction `PickerToastFeedback`

**Étant donné** que les 4 `_Body` recréent un pattern toast pour signaler une matière obligatoire « locked-out » sur tap,
**Quand** la Story 1.18 est terminée,
**Alors** :
- Le composant ou helper `PickerToastFeedback.show(context, message)` existe dans `mobile_app/lib/core/widgets/feedback/picker_toast_feedback.dart`.
- Une entrée catalogue est ajoutée (catégorie `feedback`).
- Les 4 `_Body` (et helpers internes orchestrateur) consomment ce composant.
- Test : 1 widget test (show + auto-dismiss after timer).

### AC6 — `subjects_picker_page.dart` réduit à ≤ ~500 lignes

**Étant donné** la cible de réduction du fichier d'orchestration,
**Quand** la Story 1.18 est terminée,
**Alors** :
- `mobile_app/lib/features/onboarding/presentation/subjects_picker_page.dart` fait **≤ 550 lignes** (vs 1297 lignes baseline).
- Les 4 widgets `_LegacyOptOutBody` / `_FreeWithObligatoryBody` / `_SeriesPlusOptionalBody` / `_TvePickerBody` **n'existent plus** (entièrement remplacés par composition de composants extraits).
- L'orchestrateur conserve son `switch (profile.pickerMode)` polymorphe + son `_onValidatePicked` conditionnel TVEE ordering (AC7 Story 1.17 préservée).

### AC7 — Tests Stories 1.4 / 1.15 / 1.16 / 1.17 = 100% préservés

**Étant donné** que la baseline post-Story 1.17 est 236 tests Flutter verts,
**Quand** la Story 1.18 est terminée,
**Alors** :
- `flutter test` retourne **≥ 241 tests verts** (236 baseline + 5 nouveaux tests par composant minimum AC1-AC5).
- **Aucun test des 4 stories préservées (1.4 / 1.15 / 1.16 / 1.17) ne régresse** — chaque persona artificiel passe toujours son onboarding (Fatou Mballa / Mariam Bakari / James Tanyi / Eyong Eboa via les fichiers de test existants).
- `flutter analyze` retourne **0 issue**.
- `npm test rules` (Firestore rules) retourne **23/23** verts (aucune modification rules attendue).

### AC8 — Audit responsive A7 sur 3 écrans existants

**Étant donné** que `subjects_picker_page`, `school_picker_page`, `dashboard_placeholder` n'ont aujourd'hui aucun `LayoutBuilder` ni golden test tablet (dette identifiée rétro Epic 1 v2 Challenge 2),
**Quand** la Story 1.18 est terminée,
**Alors** :
- Chacun des 3 écrans contient un `LayoutBuilder` ou `MediaQuery.sizeOf(context).width` qui distingue **au moins** phone < 600 dp et tablet ≥ 840 dp.
- Stratégie minimum acceptée pour V1 : ajouter une `maxWidth: 600` au contenu central + centrage horizontal sur tablet (évite gaspillage espace horizontal sans coûter une refonte 2-colonnes). Refonte 2-colonnes peut attendre Epic 2 si scope trop large ici.
- Chaque écran reçoit **≥ 1 golden test ≥ 840 dp** dans son fichier de test associé (viewport `Size(900, 1200)` par exemple).
- La section « Stratégie responsive » de la story (template 3 de `STORY-TEMPLATES.md`) est remplie dans les Dev Notes ci-dessous.

### AC9 — Documentation catalogue alimentée

**Étant donné** que CLAUDE.md règle 11 exige qu'un nouveau composant réutilisable soit documenté dans le catalogue dans la même PR,
**Quand** la Story 1.18 est terminée,
**Alors** :
- `doc/tech/COMPOSANTS-REUTILISABLES.md` § « Catalogue actuel » contient les **5 entrées** des composants extraits (AC1 à AC5), au format du template d'entrée.
- `doc/tech/COMPOSANTS-REUTILISABLES.md` § « À extraire — dette Epic 1 v2 » est **vidée** (déplacée vers Catalogue actuel ou supprimée avec note historique).
- `doc/tech/COMPOSANTS-REUTILISABLES.md` § « Historique » reçoit une nouvelle entrée datée 2026-06-XX (date du jour de merge) référençant cette PR Story 1.18.

### AC10 — Conformité templates STORY-TEMPLATES.md

**Étant donné** que cette story est le premier test grandeur nature des templates,
**Quand** la Story 1.18 est terminée,
**Alors** la story file `1-18-*.md` contient bien dans ses Dev Notes :
- Template 1 (Dev Notes condensé) : sections Contexte, Décisions techniques, Modèle/API impactés, Cost-benefit Firestore (N/A car refactor), Stratégie responsive (couvre AC8), Composants réutilisables (couvre AC1-AC5 + AC9), Tests, Anti-patterns, Références.
- Template 3 (Stratégie responsive) : forme cibles + breakpoints + layout strategy + golden tests planifiés.
- Template 4 (Composants réutilisables) : composants existants réutilisés (aucun — story de création), composants adaptés (aucun), nouveaux composants créés (5).
- Vérification anti-duplication AC10-bis : les 4 `_XxxBody` supprimés ; chaque composant extrait a entrée catalogue dans la PR.

---

## Tasks / Subtasks

### T1 — Setup branche + tests baseline (~15 min)

- [ ] T1.1 Créer branche `feat/1.18-refactor-extractif-body-composants` depuis main `b451b5f`.
- [ ] T1.2 Lancer `flutter test` baseline → **noter le nombre exact de tests verts** (attendu : 236). En cas d'écart : signaler dans Completion Notes.
- [ ] T1.3 Lancer `flutter analyze` baseline → **doit être 0 issue**. En cas d'écart : ouvrir investigation **avant** de refactorer.
- [ ] T1.4 Créer répertoire cible `mobile_app/lib/core/widgets/picker/` et `mobile_app/lib/core/widgets/feedback/` si absent.

### T2 — Extraction `PickerSectionCard` (AC1) (~30 min)

- [ ] T2.1 Identifier les 8+ usages du wrapper section dans les 4 `_Body` (cf. catalogue § « À extraire » lignes source indiquées).
- [ ] T2.2 Définir la signature minimale : `PickerSectionCard({required String title, String? subtitle, required Widget child})`. Si props supplémentaires nécessaires (ex. `padding`, `backgroundColor`) → ajouter en paramètres optionnels avec defaults sains.
- [ ] T2.3 Implémenter le composant dans `mobile_app/lib/core/widgets/picker/picker_section_card.dart`.
- [ ] T2.4 Écrire test widget unitaire dans `mobile_app/test/core/widgets/picker/picker_section_card_test.dart` (rendu basique + variantes subtitle absent).
- [ ] T2.5 Écrire **golden test ≥ 840 dp** (`tester.binding.setSurfaceSize(Size(900, 600))` puis `expectGoldenMatches`).
- [ ] T2.6 Remplacer les 8+ usages dans `subjects_picker_page.dart` par `PickerSectionCard(...)`.
- [ ] T2.7 Lancer `flutter test` → **0 régression** sur les tests Stories 1.4/1.15/1.16/1.17 préservés.
- [ ] T2.8 Ajouter l'entrée catalogue dans `doc/tech/COMPOSANTS-REUTILISABLES.md` § « Catalogue actuel ».

### T3 — Extraction `ObligatorySubjectChipList` (AC2) (~30 min)

- [ ] T3.1 Définir signature : `ObligatorySubjectChipList({required List<Subject> subjects, EdgeInsets? padding})`.
- [ ] T3.2 Implémenter dans `mobile_app/lib/core/widgets/picker/obligatory_subject_chip_list.dart`.
- [ ] T3.3 Tests widget + golden ≥ 840 dp.
- [ ] T3.4 Remplacer les usages dans les 4 `_Body`.
- [ ] T3.5 `flutter test` → 0 régression.
- [ ] T3.6 Entrée catalogue.

### T4 — Extraction `OptionalSubjectChipGrid` (AC3) (~45 min)

- [ ] T4.1 Définir signature : `OptionalSubjectChipGrid({required List<Subject> subjects, required Set<String> picked, required void Function(String subjectId) onToggle, int? maxPicks, bool dangerBannerOnOverpick = true})`.
- [ ] T4.2 Implémenter le danger banner over-pick comme widget interne du composant (logique conditionnelle `pickedCount > maxPicks!` + animation discrète).
- [ ] T4.3 Tests widget : toggle, over-pick affiche le banner + désactive validate bar (intégration avec `PickerValidateBar` parent), max-pick respecté.
- [ ] T4.4 Golden ≥ 840 dp.
- [ ] T4.5 Remplacer les usages dans les 3 `_Body` concernés (1.4 / 1.15 / 1.16) + `_TvePickerBody` pour cohérence (sans `maxPicks`).
- [ ] T4.6 `flutter test` → 0 régression.
- [ ] T4.7 Entrée catalogue.

### T5 — Extraction `PickerValidateBar` (AC4) (~30 min)

- [ ] T5.1 Définir signature : `PickerValidateBar({required int pickedCount, required int totalCount, required VoidCallback onValidate, required bool isValid, String? customLabel})`.
- [ ] T5.2 Implémenter avec `AppButton.primary` (validé) et `AppButton.secondary` ou disabled state (invalidé). Réutiliser les composants `AppButton` existants (cf. Story 0.13 — **ne pas dupliquer**).
- [ ] T5.3 Tests widget + golden ≥ 840 dp.
- [ ] T5.4 Remplacer les usages dans les 4 `_Body`.
- [ ] T5.5 `flutter test` → 0 régression.
- [ ] T5.6 Entrée catalogue.

### T6 — Extraction `PickerToastFeedback` (AC5) (~20 min)

- [ ] T6.1 Définir : `PickerToastFeedback.show(BuildContext context, String message, {Duration? duration})`.
- [ ] T6.2 Vérifier si un `AppToast` existant (cf. Stories 1.15-1.17 qui mentionnent AppToast) peut être réutilisé tel quel. Si oui → **ne pas créer de doublon**, juste documenter l'usage de `AppToast` dans le catalogue + lien depuis les `_Body`.
- [ ] T6.3 Si vraiment besoin d'un wrapper spécifique picker (logique métier picker-locked-out) : créer le composant dans `mobile_app/lib/core/widgets/feedback/picker_toast_feedback.dart`. Sinon : utiliser `AppToast` direct.
- [ ] T6.4 Tests + entrée catalogue (uniquement si nouveau composant créé).

### T7 — Cleanup `subjects_picker_page.dart` (AC6) (~30 min)

- [ ] T7.1 Supprimer entièrement les classes `_LegacyOptOutBody`, `_FreeWithObligatoryBody`, `_SeriesPlusOptionalBody`, `_TvePickerBody` (toutes lignes ~150-300 + ~520-700 + ~750-930 + ~1000-1297).
- [ ] T7.2 Recomposer chaque `case PickerMode.xxx` du `switch` dans `_buildBody(...)` avec **uniquement** des compositions de composants extraits.
- [ ] T7.3 Préserver le `_onValidatePicked` conditionnel TVEE ordering (AC7 Story 1.17) — pas de modification métier.
- [ ] T7.4 Vérifier que le fichier est ≤ 550 lignes.
- [ ] T7.5 `flutter analyze` → 0 issue.
- [ ] T7.6 `flutter test` → 0 régression (focus sur les tests préservés Stories 1.4/1.15/1.16/1.17).

### T8 — Audit responsive A7 (AC8) (~60 min)

- [ ] T8.1 Auditer `subjects_picker_page.dart` (refactorisé) : ajouter `LayoutBuilder` au root avec branche `if (constraints.maxWidth >= 840) ConstrainedBox(maxWidth: 600, child: ...) else (...)`. Centrage horizontal sur tablet.
- [ ] T8.2 Ajouter golden test `subjects_picker_page_tablet_test.dart` (viewport `Size(900, 1200)`) — au moins pour le mode `derived` (Fatou).
- [ ] T8.3 Auditer `school_picker_page.dart` : appliquer le même pattern `LayoutBuilder` + maxWidth.
- [ ] T8.4 Ajouter golden test `school_picker_page_tablet_test.dart`.
- [ ] T8.5 Auditer `dashboard_placeholder.dart` (vérifier path exact d'abord — `mobile_app/lib/features/dashboard/...`). Pattern identique.
- [ ] T8.6 Ajouter golden test `dashboard_placeholder_tablet_test.dart` (ou test plein-écran équivalent).
- [ ] T8.7 `flutter test` → tous verts.

### T9 — Documentation catalogue (AC9) (~20 min)

- [ ] T9.1 Vérifier que les 5 entrées catalogue sont bien ajoutées dans `doc/tech/COMPOSANTS-REUTILISABLES.md` § « Catalogue actuel » (au fur et à mesure pendant T2-T6).
- [ ] T9.2 Vider la section « À extraire — dette Epic 1 v2 » ou la remplacer par une note : « ✅ Résorbée Story 1.18 — voir Catalogue actuel ».
- [ ] T9.3 Ajouter entrée Historique : `| 2026-06-XX | Story 1.18 — 5 composants extraits (PickerSectionCard, ObligatorySubjectChipList, OptionalSubjectChipGrid, PickerValidateBar, PickerToastFeedback) + audit responsive A7 sur 3 écrans existants | <PR-numero> | Amelia |`.

### T10 — Validation finale + commit + push (AC7 + AC10) (~15 min)

- [ ] T10.1 `flutter analyze` → 0 issue (final).
- [ ] T10.2 `flutter test` → **≥ 241 tests verts** (236 baseline + 5 nouveaux minimum), aucune régression.
- [ ] T10.3 `cd test/rules && npm test` → 23/23 verts (sanity check Firestore rules).
- [ ] T10.4 Vérifier `subjects_picker_page.dart` ≤ 550 lignes (`wc -l mobile_app/lib/features/onboarding/presentation/subjects_picker_page.dart`).
- [ ] T10.5 Commit Conventional : `refactor(onboarding): extract _Body x4 to shared picker components + responsive audit A7 (Story 1.18 retro Epic 1 v2 A5+A7)`.
- [ ] T10.6 Push branche + créer PR (URL fournie par git remote).
- [ ] T10.7 Attendre confirmation merge utilisateur **avant** d'enchaîner avec cloture 1.18 (CLAUDE.md règle 6 Workflow Git).

---

## Dev Notes

### Contexte et motivation

Story 1.18 résorbe la dette technique majeure identifiée en rétrospective Epic 1 v2 (cf. `epic-1v2-retro-2026-06-10.md` Challenges 1 + 2 + Action Items A5 + A7). Sa réussite valide le dispositif discipline introduit par PR #87 (`b451b5f`) : règles CLAUDE.md 11 + 3/5 durcies + catalogue COMPOSANTS-REUTILISABLES.md + templates STORY-TEMPLATES.md + customize.toml BMAD `bmad-create-story` / `bmad-dev-story`.

Refactor **pur** (zéro changement métier) : préserver 100% des comportements Stories 1.4 / 1.15 / 1.16 / 1.17 + Story 1.7 (audit only) + Story 1.9 (audit only). Les tests existants sont la garantie de non-régression.

### Décisions techniques clés

- **Décision 1** : Extraire 5 composants distincts plutôt qu'un seul « SuperPickerBody » paramétrable — **raison** : chaque composant a une responsabilité unique et un sweet spot d'API. **Alternative écartée** : composant générique configurable par énumération `PickerSectionType` — refusée car complexifie l'API publique et masque la sémantique.

- **Décision 2** : Ne PAS créer de nouveau toast si `AppToast` existant (Stories 1.15-1.17) suffit — **raison** : CLAUDE.md règle 11 alinéa « quand un composant existe mais a besoin d'une adaptation mineure : ajouter un paramètre optionnel plutôt que dupliquer ». **Alternative écartée** : créer `PickerToastFeedback` distinct — refusée si redondant.

- **Décision 3** : Audit responsive A7 = minimum viable V1 (maxWidth + centrage) plutôt que refonte 2-colonnes — **raison** : scope Story 1.18 doit rester maîtrisé (~5-6h). **Alternative écartée** : refonte 2-colonnes par écran — différée à Epic 2 si justifié par UX.

- **Décision 4** : Préserver le `_onValidatePicked` conditionnel TVEE ordering dans `subjects_picker_page.dart` (logique Story 1.17) — **raison** : c'est du métier, pas de la duplication visuelle. **Alternative écartée** : déplacer le ordering dans un `usecase` domain — différé (hors scope refactor visuel).

- **Décision 5** : Branche unique `feat/1.18-refactor-extractif-body-composants` + PR unique (pas de séparation context/dev/cloture car la story est un refactor sans contenu métier nouveau) — **raison** : pas de contexte engine à pré-mergée + corps story file = spécification suffisante. **Alternative écartée** : pattern 3-PR Stories 1.12-1.17 — non justifié pour un refactor pur.

### Modèle de données / API impactés

- **Fichiers `domain/*.dart`** : 0 modification (refactor visuel pur).
- **Fichiers `data/*_repository_impl.dart`** : 0 modification.
- **Schéma Firestore** : 0 modification.
- **Contrats Cloud Function** : 0 modification.
- **Fichiers `lib/core/widgets/picker/*.dart`** : **5 nouveaux fichiers** (1 par composant extrait).
- **Fichiers `lib/core/widgets/feedback/*.dart`** : 0 ou 1 nouveau fichier (selon T6.2 décision réutilisation `AppToast`).
- **Fichier `lib/features/onboarding/presentation/subjects_picker_page.dart`** : **réduit de 1297 → ≤ 550 lignes** (suppression de 4 `_XxxBody` privés).
- **Fichier `lib/features/onboarding/presentation/school_picker_page.dart`** : **LayoutBuilder ajouté** (audit responsive A7), reste métier inchangé.
- **Fichier `lib/features/dashboard/.../dashboard_placeholder.dart`** : idem.
- **`doc/tech/COMPOSANTS-REUTILISABLES.md`** : 5 entrées catalogue ajoutées + Historique mis à jour.

### Cost-benefit Firestore

**N/A pour cette story** — refactor visuel pur, zéro interaction Firestore modifiée.

### Stratégie responsive

**Form factors cibles** :
- Phone portrait (< 600 dp) : **OUI** — comportement : layout actuel des Stories 1.4/1.15/1.16/1.17/1.7/1.9 préservé (colonne unique pleine largeur).
- Phone landscape (600-840 dp) : **OPTIONNEL** — comportement : layout phone portrait inchangé (pas de spécialisation V1 — peut rester verrouillé portrait si stories le justifient).
- Tablet portrait & landscape (≥ 840 dp) : **OUI** — comportement V1 minimum : `ConstrainedBox(maxWidth: 600)` + centrage horizontal pour éviter le gaspillage espace horizontal. Refonte 2-colonnes différée à Epic 2 si UX le demande.

**Breakpoints à utiliser** :
- `LayoutBuilder` au root de chaque écran auditer (T8.1, T8.3, T8.5).
- Seuils : `constraints.maxWidth >= 840` (tablet) | `constraints.maxWidth >= 600` (phone landscape — V1 traite comme phone) | `else` phone portrait.
- Constantes à définir éventuellement dans `mobile_app/lib/core/theme/tokens.dart` si pas déjà présentes : `kBreakpointPhone = 600`, `kBreakpointTablet = 840`. Sinon hardcoder dans T8 avec commentaire `// CLAUDE.md règle 3`.

**Layout strategy par form factor** :
- Phone < 600 dp : colonne unique scrollable (= actuel, préservé).
- Tablet ≥ 840 dp : `ConstrainedBox(maxWidth: 600).center` (V1 minimum). Le contenu interne reste vertical scroll.

**Golden tests à inclure** :
- [ ] Golden test phone portrait (375×812) pour chaque composant extrait T2-T5 (4-5 tests).
- [ ] Golden test tablet portrait (900×1200) pour chaque composant extrait T2-T5 (4-5 tests).
- [ ] Golden test tablet portrait (900×1200) pour `subjects_picker_page` mode `derived` (T8.2).
- [ ] Golden test tablet portrait (900×1200) pour `school_picker_page` (T8.4).
- [ ] Golden test tablet portrait (900×1200) pour `dashboard_placeholder` (T8.6).
- **Total nouveaux golden tests** : ~8-12.

**Acceptance Criteria responsive ajoutée à la story** : AC8 (voir ci-dessus).

### Composants réutilisables

**Catalogue consulté** : [doc/tech/COMPOSANTS-REUTILISABLES.md](../../doc/tech/COMPOSANTS-REUTILISABLES.md) — section « À extraire — dette Epic 1 v2 ».

**Composants existants réutilisés** :
- `AppButton.primary` / `AppButton.secondary` (cf. Story 0.13) — usage : composer `PickerValidateBar` (T5.2) **sans dupliquer**.
- `AppToast` (cf. Stories 1.15-1.17 qui le mentionnent) — usage : T6.2 réutilisation conditionnelle au lieu de créer `PickerToastFeedback`.

**Composants existants adaptés (paramètre optionnel ajouté)** :
- Aucun a priori. Si T6 décide d'étendre `AppToast` avec un paramètre `level: ToastLevel.warning` au lieu de créer `PickerToastFeedback`, justifier dans Dev Notes complétion.

**Nouveaux composants créés et ajoutés au catalogue** :
- `PickerSectionCard` (path `lib/core/widgets/picker/picker_section_card.dart`) — AC1
- `ObligatorySubjectChipList` (path `lib/core/widgets/picker/obligatory_subject_chip_list.dart`) — AC2
- `OptionalSubjectChipGrid` (path `lib/core/widgets/picker/optional_subject_chip_grid.dart`) — AC3
- `PickerValidateBar` (path `lib/core/widgets/picker/picker_validate_bar.dart`) — AC4
- Possiblement `PickerToastFeedback` (path `lib/core/widgets/feedback/picker_toast_feedback.dart`) — AC5 si T6 décide création.

**Vérification anti-duplication** :
- [ ] Les 4 anciens `_LegacyOptOutBody` / `_FreeWithObligatoryBody` / `_SeriesPlusOptionalBody` / `_TvePickerBody` **supprimés** de `subjects_picker_page.dart` (T7.1).
- [ ] Aucune classe privée `_XxxBody` reproduisant un composant extrait (vérifier `grep -n "_.*Body" mobile_app/lib/features/onboarding/presentation/subjects_picker_page.dart` → 0 résultat post-T7).
- [ ] Entrée catalogue présente pour chaque composant créé (T9.1).

### Tests à écrire

- **Unit / widget par composant extrait** (T2-T5, T6 conditionnel) :
  - `picker_section_card_test.dart` : rendu + subtitle absent + golden tablet.
  - `obligatory_subject_chip_list_test.dart` : rendu liste + golden tablet.
  - `optional_subject_chip_grid_test.dart` : toggle + over-pick danger banner + max-pick respect + golden tablet.
  - `picker_validate_bar_test.dart` : disabled state si !isValid + tap callback + golden tablet.
  - `picker_toast_feedback_test.dart` (si nouveau) : show + auto-dismiss timer.
- **Golden tests responsive** (T8) :
  - `subjects_picker_page_tablet_test.dart` (mode `derived` au minimum — Fatou).
  - `school_picker_page_tablet_test.dart`.
  - `dashboard_placeholder_tablet_test.dart`.
- **Tests préservés (vérification anti-régression)** :
  - `subjects_picker_page_test.dart` (mode derived legacy, Story 1.4) — **0 régression**.
  - `subjects_picker_page_o_level_picker_test.dart` (Mariam, Story 1.15) — **0 régression**.
  - `subjects_picker_page_series_plus_optional_test.dart` (James, Story 1.16) — **0 régression**.
  - `subjects_picker_page_tve_picker_test.dart` (Eyong, Story 1.17) — **0 régression**.
  - `school_picker_page_test.dart` (Story 1.7) — **0 régression**.

### Anti-patterns à éviter

- ❌ **Dupliquer du code de composant** dans plusieurs `_Body` post-extraction (le but est exactement l'inverse — vérifier `grep` après T7).
- ❌ **Ajouter un golden test phone seulement** (CLAUDE.md règle 5 durcie : ≥ 1 golden test viewport ≥ 840 dp obligatoire par composant + par écran audité).
- ❌ **Modifier les tests Stories 1.4/1.15/1.16/1.17 pour les faire passer** (si un test régresse, c'est le refactor qui doit s'adapter, pas le test).
- ❌ **Étendre le scope vers Epic 2** (cartes leçon, listes chapitres) — pas dans cette story.
- ❌ **Refonte 2-colonnes des écrans en T8** (V1 minimum maxWidth+centrage suffit — différer si UX le demande).
- ❌ **Créer un composant générique paramétrable par énum** au lieu de 5 composants à responsabilité unique (cf. Décision 1).
- ❌ **Mettre à jour `doc/partage/`** sans raison (refactor pur, aucun schéma touché — CLAUDE.md règle Surface partagée non applicable ici).
- ❌ **Push 2 PR enchaînées** (CLAUDE.md règle 6 Workflow Git — attendre merge cette PR avant cloture 1.18).

### Références

- [Rétrospective Epic 1 v2](epic-1v2-retro-2026-06-10.md) § Challenges 1 + 2 + Action Items A5 + A7
- [CLAUDE.md](../../CLAUDE.md) § Architecture mobile règle 11 + Cross-platform & responsive règles 3 et 5 durcies + Workflow Git règle 6
- [Catalogue composants](../../doc/tech/COMPOSANTS-REUTILISABLES.md) § À extraire — dette Epic 1 v2
- [Templates story](../../doc/tech/STORY-TEMPLATES.md) § Templates 1, 3, 4
- [Customize BMAD bmad-create-story](../../_bmad/custom/bmad-create-story.toml) (persistent_facts règles enforcées)
- [Customize BMAD bmad-dev-story](../../_bmad/custom/bmad-dev-story.toml) (checkpoints avant push enforcés)
- Stories d'origine : [1-4](1-4-retrait-conditionnel-matieres.md), [1-15](1-15-refactor-opt-out-en-picker-anglo-olevel.md), [1-16](1-16-extension-a-level-transversales.md), [1-17](1-17-estp-anglophone-tvee.md)
- Story 1.7 (audit responsive) : [1-7](1-7-liaison-ecole-optionnelle.md)
- Story 1.9 (audit responsive) : [1-9](1-9-dashboard-skeleton-filtrage-profil.md)

---

## Change Log

| Date | Auteur | Action |
|---|---|---|
| 2026-06-10 | Amelia (Developer via `/bmad-create-story`) | Création du contexte engine Story 1.18 — premier test grandeur nature des nouvelles règles CLAUDE.md 11 + 3/5 durcies + customize.toml BMAD enhancements (PR #87 merge `b451b5f`) |

---

## Dev Agent Record

*Cette section sera remplie pendant l'exécution `/bmad-dev-story`. Pré-rempli ici à blanc pour suivre la structure.*

### Debug Log

*(rempli pendant dev)*

### Implementation Plan

*(rempli pendant dev)*

### Completion Notes

*(rempli pendant dev)*

### File List

*(rempli pendant dev — paths exacts des nouveaux fichiers + modifiés)*

---

## Notes pour le Project Lead

**Cette story est le test décisif** des nouvelles règles discipline. Si elle se déroule bien :
- ≥ 241 tests verts, 0 régression sur Stories 1.4/1.15/1.16/1.17/1.7/1.9
- Catalogue alimenté avec 5 entrées
- `subjects_picker_page.dart` ≤ 550 lignes
- Audit responsive A7 fait

Alors les Stories Epic 1.5 Schools completion + Epic 2 navigation hériteront d'une base propre.

Si elle révèle des frictions (templates STORY-TEMPLATES.md trop verbeux, customize.toml persistent_facts trop chargés, etc.), c'est un input pour affiner la PR discipline en aval. À documenter dans Completion Notes.

PR unique attendue (refactor pur, pas de séparation context/dev/cloture). Attendre merge avant cloture/Story suivante (CLAUDE.md règle 6).
