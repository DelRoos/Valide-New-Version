---
story_id: 1bis.3
title: Pages 2+3+4 (track choice + level choice + stream/subjects picker 5 modes) + extension OnboardingShell
epic: 1bis
phase: P1bis — Refonte intégrale du flow pré-dashboard
status: in-progress
created: 2026-06-12
baseline_commit: d869d47  # merge PR #106 (feat/1bis-2bis-refactor-shell-slides) - main aligné post-livraison shell + slides
estimation: L (~3-4 jours)
sprint_change: Décisions porteur produit 2026-06-12 — (a) Step 2 lit `filieres` depuis catalogueProvider existant (pas de nouvelle collection `tracks` créée), (b) Step 3 lit `niveaux` depuis catalogueProvider existant, (c) 5 modes picker step 4 en 1 PR.
dependencies:
  - E1bis-0 mergée — composants catalogue picker (`PickerSectionScaffold`, `ObligatorySubjectCheckboxList`, `OptionalSubjectCheckboxList`, `PickerValidateBar`, `PickerCounterBadge`, `SelectionCard`)
  - E1bis-1 mergée — `OnboardingNotifier` setTrackId/setLevelId/setStreamId/setPickedSubjects + next() conditionnel skip step 4 si derived
  - E1bis-2bis mergée — `OnboardingShell` shell partagé + slides + header partagé prêt à activer pour steps 2-4
  - Story 1.5/1.13/1.15 livrées — `catalogueProvider` charge 6 collections (filieres, niveaux, series, subjects, examTargets, derivationRules) + `DerivedProfile` + `PickerMode` enum
  - Story 1.18 livrée — composants catalogue picker extraits
blocks:
  - E1bis-4 (page 5 auth choice) — étendra `OnboardingShell` pour case 5
  - E1bis-5 → E1bis-9 (pages suivantes)
sourceArtifacts:
  - doc/templates/src/components/OnboardingFlow.tsx l.298-540 (steps 2 + 3 + 4 du template comme référence comportement)
  - mobile_app/lib/core/catalogue/providers.dart (`catalogueProvider` FutureProvider snapshot 6 collections)
  - mobile_app/lib/core/catalogue/domain/models.dart (`Filiere` + `Niveau` + `Serie` + `Subject` + `PickerMode`)
  - mobile_app/lib/features/onboarding/presentation/subjects_picker_page.dart (legacy Epic 1 — réf. comportement 5 modes picker à PRESERVER intact)
  - mobile_app/lib/core/widgets/picker/* (composants catalogue Story 1.18 réutilisés)
  - mobile_app/lib/features/onboarding/presentation/state/onboarding_notifier.dart (setTrackId/setLevelId/setStreamId)
---

# Story 1bis.3 — Pages 2+3+4 (track + level + stream/subjects picker 5 modes) + extension shell

Status: **in-progress**

## Objectif

Livrer les 3 étapes suivantes du flow refonte E1bis : **track choice (Général/Technique)**, **level choice (selon sub-system + track)**, **stream/subjects picker 5 modes** (derived / optOut / freeWithObligatory / seriesPlusOptional / tvePicker). Étendre `OnboardingShell` pour activer le **header progress** sur steps 2-4 (`configStepsActive` template ligne 206). Toute la donnée vient du **`catalogueProvider`** existant (Story 1.5).

## Décisions porteur produit (2026-06-12)

- ✅ **Pas de nouvelle collection Firestore `tracks`** : on lit `filieres` du `catalogueProvider` existant. Mapping local `Filiere` → variables `track*` côté E1bis (la dette globale rename Filiere→Track est Story 1.19).
- ✅ **Step 3 lit `niveauxCatalogProvider` existant** : pas de descriptions FR/EN sur les `Niveau` actuels — affichage du `name.fr` / `name.en` selon `subSystem`.
- ✅ **5 modes picker step 4 en 1 PR** : derived auto-skip via `OnboardingNotifier.next()`, optOut/freeWithObligatory/seriesPlusOptional/tvePicker rendus dans le `StreamSubjectsPickerStepBody`. Dispatch via `Serie.pickerMode`.
- ✅ **ARB hard-codé temporairement** pour labels picker (titre obligatoires/optionnels, sélecteur série, badges, etc.). Refactor Firestore enrichi reporté E1bis-9b post-accord backend.
- ✅ **Réutilisation maximale** des composants Story 1.18 (PickerSectionScaffold + Checkbox lists + PickerValidateBar + PickerCounterBadge).
- ❌ **PAS de modification de `subjects_picker_page.dart` legacy** (Epic 1 reste intact).
- ❌ **PAS d'écriture Firestore** (`OnboardingNotifier.toFirestorePayload` reste en attente — flush prévu E1bis-4 post-auth).

## Acceptance Criteria

- **AC1 — `TrackChoiceStepBody`** : lit `catalogueProvider` → filtre `filieres` actives (`isActive == true`) triées par `sortOrder`. Affiche N `SelectionCard(variant: standard, title: filiere.name[locale])` (2 attendues : `generale` + `technique`). Tap card → `notifier.setTrackId(filiere.filiereId)` (qui auto-avance step 3 via E1bis-1). CTA "Continuer" footer (composé par shell). Gestion error : si `catalogueProvider.error` → message localisé `errorCatalogueLoading`.

- **AC2 — `LevelChoiceStepBody`** : lit `catalogueProvider` + `state.subSystem` + `state.trackId` → filtre `niveaux` actives matchant `subSystem == state.subSystem.id` ET `filiereIds.contains(state.trackId)`. Affiche N `SelectionCard` (variants compact ou standard selon nombre). Tap → `notifier.setLevelId(niveau.niveauId)`. Auto-determine si le level requiert un picker via `levelRequiresPicker` (lookup dans `series` : existe-t-il au moins une série pour ce niveau ?).

- **AC3 — `StreamSubjectsPickerStepBody` 5 modes** :
  - **derived** : pas atteint (skip via notifier.next).
  - **optOut** : reprise comportement legacy `subjects_picker_page.dart` `_LegacyOptOutBody` : sélection série + matières du domaine retiré.
  - **freeWithObligatory** : `ObligatorySubjectCheckboxList` (matières lockees du series.professionalSubjectIds) + `OptionalSubjectCheckboxList` (autres subjects de cette série) + `PickerCounterBadge(minSubjects, maxSubjects)` + `PickerValidateBar`.
  - **seriesPlusOptional** : `SelectionCard` série + `OptionalSubjectCheckboxList` matières transversales.
  - **tvePicker** : `ObligatorySubjectCheckboxList(series.professionalSubjectIds)` + `ObligatorySubjectCheckboxList(series.relatedProfessionalSubjectIds)` + `OptionalSubjectCheckboxList(series.otherSubjectIds)` + counter min/max.
  - Tap CTA → `notifier.setPickedSubjects(...)` puis `notifier.setStreamId(...)` puis `notifier.next()`.

- **AC4 — Extension `OnboardingShell`** : `_bodyForStep(2)` → `TrackChoiceStepBody`, `_bodyForStep(3)` → `LevelChoiceStepBody`, `_bodyForStep(4)` → `StreamSubjectsPickerStepBody`. `_footerForStep` dispatch pour ces 3 cases. `_OnboardingHeader.configStepsActive` désormais ACTIF (header back + progress + counter visible).

- **AC5 — Tests interactions** : par step body, ≥ 2 cas (tap card normal + tap card edge case). Pour step 4 : 1 test par mode = 4 tests (derived skip testé via shell, pas par body).

- **AC6 — Goldens** : 6 phone + 6 tablet (2 par step body au minimum, 4-5 pour step 4 modes).

- **AC7 — ARB** : ajout clés FR/EN `onboardingTrackTitle`, `onboardingLevelTitle`, `onboardingStreamSubjectsTitle`, `pickerObligatoryTitle`, `pickerOptionalTitle`, `pickerCounterFormat` ({count}/{max}), `errorCatalogueLoading`. Estimation +10 clés.

- **AC8 — Sprint-status + catalogue historique** : mises à jour à la cloture.

## Architecture providers Riverpod (E1bis-3)

Pas de nouveau provider en racine. Filtrage local dans chaque step body :

```dart
final tracks = catalogueSnapshot.filieres
    .where((f) => f.isActive)
    .toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
```

Pour `levelRequiresPicker` (E1bis-1 state), calcul dans LevelChoiceStepBody au tap : si la liste `series` pour ce `niveauId` est vide ou tous `pickerMode == derived` → `levelRequiresPicker = false` (skip step 4).

## Composants réutilisés

| Composant | Path | Usage |
|---|---|---|
| `SelectionCard` (compact + standard) | `lib/core/widgets/cards/selection_card.dart` | Steps 2, 3 + step 4 sélecteurs série |
| `PickerSectionScaffold` | `lib/core/widgets/picker/picker_section_scaffold.dart` | Step 4 modes wrapper |
| `ObligatorySubjectCheckboxList` | `lib/core/widgets/picker/obligatory_subject_checkbox_list.dart` | Step 4 freeWithObligatory + tvePicker |
| `OptionalSubjectCheckboxList` | `lib/core/widgets/picker/optional_subject_checkbox_list.dart` | Step 4 freeWithObligatory + seriesPlusOptional + tvePicker |
| `PickerCounterBadge` | `lib/core/widgets/picker/picker_counter_badge.dart` | Step 4 min/max counter |
| `PickerValidateBar` | `lib/core/widgets/picker/picker_validate_bar.dart` | Step 4 validation |
| `OnboardingCtaFooter` | `lib/core/widgets/onboarding/onboarding_cta_footer.dart` | Footer steps 2, 3 (et step 4 selon mode) |
| `OnboardingShell` | E1bis-2bis | Extension cases 2, 3, 4 |

## Stratégie responsive

- Phone < 600 dp : layout par défaut, scrollable.
- Tablet ≥ 840 dp : `LayoutBuilder` + `ConstrainedBox(maxWidth: 600.w)` centré pour les step bodies (cohérent avec hero step body E1bis-2bis).

Goldens obligatoires (CLAUDE.md règle 5) : phone 360×780 + tablet 800×1280.

## Cost-benefit Firestore

- **N/A** : aucun nouveau `snapshots()`, aucune nouvelle écriture. Réutilisation de `catalogueProvider` FutureProvider existant (Story 1.5 — 1 read par doc initial, cache offline ensuite).
- Pas de nouvel index Firestore.

## Risques

- ⚠️ **Step 4 mode tvePicker complexe** : 3 listes obligatoires + 1 optionnelle + counter min/max. Le legacy `subjects_picker_page.dart` `_TvePickerBody` est la référence — porter le comportement à l'identique.
- ⚠️ **Détermination `levelRequiresPicker`** : implique de fetch les series pour ce niveau. Si async + transition setLevelId trop rapide, risque de race. Solution : calcul synchrone depuis le snapshot déjà chargé.
- ⚠️ **PR ≥ 400 lignes** : CLAUDE.md règle 6 plafond. Justifié par le scope `tous modes en 1 PR` choisi porteur produit. Commits logiques permettent revue incrémentale.

## Dev Agent Record

À remplir progressivement par phases :

- [ ] Phase 1 : providers Riverpod E1bis-3 (filtrage local depuis catalogueProvider)
- [ ] Phase 2 : TrackChoiceStepBody (step 2) + extension shell case 2 + tests + goldens
- [ ] Phase 3 : LevelChoiceStepBody (step 3) + shell case 3 + tests + goldens
- [ ] Phase 4 : StreamSubjectsPickerStepBody (step 4 - 5 modes) + shell case 4 + tests + goldens
- [ ] Phase 5 : ARB FR/EN + clôture docs

Commits incrémentaux push sur la branche pour revue incrémentale.
