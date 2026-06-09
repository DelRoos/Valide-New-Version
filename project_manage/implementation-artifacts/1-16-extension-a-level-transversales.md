---
story_id: 1.16
title: SubjectsPickerPage mode `series_plus_optional` A-Level transversales (Computer Science / ICT / Religious Studies / Commerce — James Upper Sixth S2 + ICT)
epic: 1
phase: P1 extension v2 (sprint change 2026-06-09)
status: ready-for-dev
created: 2026-06-09
baseline_commit: dc27c21  # merge PR #79 (cloture 1.15) — main aligné post Stories 1.11a/1.11b/1.12/1.13/1.14/1.15 done
estimation: S (~3h)
sprint_change: sprint-change-proposal-2026-06-09.md
dependencies:
  - 1.13 — done (PickerMode.seriesPlusOptional enum + DerivedProfile.optionalSubjects + obligatorySubjects + min/max + Serie/DerivationRule enrichis)
  - 1.15 — done (SubjectsPickerPage orchestrateur + dispatch `switch (profile.pickerMode)` + `_FreeWithObligatoryBody` pattern réutilisable + `_pickedOptional` state + `_onToggleOptional` + `_onTapObligatory` handlers + `_onValidatePicked` + `UserProfileRepository.updatePickedSubjects` + `firestore.rules pickedSubjectsValid()` + 7 clés ARB picker)
blocks:
  - (aucun — 1.17 TVEE n'a pas de dépendance widget directe sur 1.16, parallèle possible)
sourceArtifacts:
  - project_manage/planning-artifacts/epics.md § Story 1.16 + table dependency graph
  - project_manage/planning-artifacts/sprint-change-proposal-2026-06-09.md § Change 4.6 (Story 1.16 lignes 297-303) + table § 14 (lignes 405-409 A-Level règle panier)
  - project_manage/planning-artifacts/prds/prd-valide-mvp-2026-06-03/prd.md § FR-3 multi-mode (ligne 152 mode `series_plus_optional`)
  - project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/EXPERIENCE.md § Variant Flow 1c James Upper Sixth S2 + ICT (lignes 490-506)
  - doc/partage/BASE-DE-DONNEES.md § users/{uid}.pickedSubjects + § Validation panier polymorphe (déjà fait Story 1.11a + 1.15)
  - doc/partage/ALGORITHMES.md § Modes panier
  - mobile_app/lib/core/catalogue/domain/models.dart § PickerMode.seriesPlusOptional + DerivedProfile.optionalSubjects (Story 1.13)
  - mobile_app/lib/features/onboarding/presentation/subjects_picker_page.dart § placeholder `case PickerMode.seriesPlusOptional` (Story 1.15 lignes 152-164 à remplacer) + `_FreeWithObligatoryBody` pattern à dupliquer (Story 1.15 lignes 410-580)
  - mobile_app/lib/features/onboarding/providers.dart § `_pickedOptional` state already in place (Story 1.15)
  - mobile_app/lib/l10n/app_fr.arb + app_en.arb § clés `onboardingPickerXxx` Story 1.15 (à étendre +2)
  - scripts/firebase_seed/data/matrice.json § rules `rule_anglophone_generale_upper_sixth_s2` ligne 4363-4385 + symétriques S1/S3-S8 (référence — **PAS modifié Story 1.16**, cf. Décision 1)
---

# Story 1.16 — SubjectsPickerPage mode `series_plus_optional` A-Level transversales (James Upper Sixth S2 + ICT)

Status: **ready-for-dev**

## Objectif

Compléter le **5ᵉ et avant-dernier mode panier** de `SubjectsPickerPage` (Story 1.15) en livrant le widget `_SeriesPlusOptionalBody` qui rend le pattern A-Level : Series obligatoires lockées + transversales optionnelles avec validation max 5. Cible UX EXPERIENCE.md Variant Flow 1c — James Tanyi Upper Sixth S2 (Chemistry/Physics/Biology) qui veut ajouter ICT pour son orientation IT.

**Pourquoi maintenant** : Story 1.15 a posé toutes les fondations widget (dispatch + handlers + state + repo + rules + ARB picker). Story 1.16 réutilise tout ça et ajoute uniquement le rendu du mode `series_plus_optional` (placeholder redirect recap actuel). Scope minimal — c'est la story la plus rapide de la cascade Epic 1 v2.

**Pourquoi `Widget only Dart` (Décision 1 figée)** : matrice.json `pickerMode: 'opt_out'` sur Upper/Lower Sixth S1-S8 reste inchangé Story 1.16. Conséquences (acceptées) :

- Aucun utilisateur réel ne peut DÉCLENCHER le mode `series_plus_optional` en prod jusqu'à une story future de bascule matrice (Story 1.18 ou Epic 2).
- Tests Story 1.4 (`_jamesProfile()` en mode `opt_out` explicite) **100% préservés** — pas de migration des profils Firestore, pas de smoke device cassé.
- Tests Story 1.16 fabriquent un `_jamesProfile()` artificiel avec `pickerMode: PickerMode.seriesPlusOptional` explicite + `obligatorySubjects: [Chemistry, Physics, Biology]` + `optionalSubjects: [Computer Science, ICT, Religious Studies, Commerce]`. Cohérent pattern Story 1.15 (`_mariamProfile()` artificiel).
- Le widget est livré FONCTIONNEL — quand la story de bascule matrice arrivera plus tard, aucune ligne Dart à modifier.

**Critère de fin** :

- Un profil dérivé synthétique `DerivedProfile{ pickerMode: seriesPlusOptional, obligatorySubjects: [Chemistry, Physics, Biology], optionalSubjects: [Computer Science, ICT, Religious Studies, Commerce], minSubjects: 3, maxSubjects: 5 }` rend `_SeriesPlusOptionalBody` avec :
  - 3 cards "Series (obligatoires)" cochées + cadenas Lucide, tap → toast warning (réutilise `onboardingPickerErrorObligatoryToast`).
  - 4 checkboxes "Transversales optionnelles" décochées par défaut.
  - Compteur live "Tu présentes 3/5 matières" couleur primary (valide).
- Tap ICT → compteur passe à "4/5 matières", bouton Valider activé.
- Tap Valider → `pickedSubjects = [Chemistry, Physics, Biology, ICT]` posé en Firestore via `updatePickedSubjects` Story 1.15.
- **Edge case max 5** : tap 3 transversales (Computer Science + ICT + Religious Studies) → compteur "6/5" couleur danger, bouton Valider **disabled**. Tap 4 transversales jamais possible (la 4ᵉ checkbox reste interactive mais le bouton reste disabled — pas de toast intrusif, juste la couleur).
- Modes Story 1.4 + 1.15 préservés : tests legacy `opt_out` (James actuel matrice.json) et `freeWithObligatory` (Mariam) passent **inchangés** (AC6 strict 1.15).

## Story

**As a** élève anglophone A-Level (Lower ou Upper Sixth, série S1-S8 ou A1-A5),
**I want** sélectionner les matières transversales optionnelles (Computer Science / ICT / Religious Studies / Commerce) en complément de ma Series figée,
**so that** mon dashboard reflète exactement mes choix d'orientation (ex. IT vs business pur), dans la limite officielle GCE Board de 5 matières maximum au A-Level (FR-3 mode `series_plus_optional`).

## Acceptance Criteria

### AC1 — Rendu `_SeriesPlusOptionalBody` (remplace placeholder Story 1.15)

**GIVEN** un `DerivedProfile{ pickerMode: PickerMode.seriesPlusOptional, ... }`,
**WHEN** la page `SubjectsPickerPage` dispatche dans `_dispatchByPickerMode` (Story 1.15 ligne 152),
**THEN** elle rend `_SeriesPlusOptionalBody(...)` au lieu du placeholder `redirect recap` actuel.

**ET** le widget `_SeriesPlusOptionalBody` (NEW) accepte exactement les mêmes props que `_FreeWithObligatoryBody` (Story 1.15) : `profile`, `langKey`, `picked`, `isSaving`, `onInitPicked`, `onToggleOptional`, `onTapObligatory`, `onValidate`, `onCancel`. Aucune nouvelle prop, aucun nouveau handler côté state Story 1.15.

### AC2 — Layout 2 sections (Series + Transversales)

**GIVEN** `_SeriesPlusOptionalBody` est en train de rendre,
**WHEN** il construit son layout,
**THEN** il affiche **2 sections** structurellement identiques à `_FreeWithObligatoryBody` mais sémantiquement adaptées :

1. **Section « Series (obligatoires) »** (titre H3, NEW clé ARB `onboardingPickerSeriesTitle`) :
   - `profile.obligatorySubjects.length` CheckboxListTile **checked + lock icon Lucide**.
   - Tap → `onTapObligatory(s.subjectId)` (handler Story 1.15 inchangé : toast warning `onboardingPickerErrorObligatoryToast` + log warn).

2. **Section « Transversales optionnelles »** (titre H3, NEW clé ARB `onboardingPickerTransversalesTitle`) :
   - `profile.optionalSubjects.length` CheckboxListTile interactifs.
   - État initial : décochées par défaut. Si `users/{uid}.pickedSubjects` non vide (cas back/édit), cocher celles présentes dans `pickedSubjects` ∩ `optionalSubjects`.
   - Tap → `onToggleOptional(s.subjectId, selected)` (handler Story 1.15 inchangé).

3. **Compteur live** + **bouton Valider** + **bouton Retour** : 100% identique à `_FreeWithObligatoryBody` (Story 1.15). Réutilise `onboardingPickerCounterLive` (NEW Story 1.15) + `onboardingPickerValidateCta` + `l10n.back`.

### AC3 — Validation client `series_plus_optional`

**GIVEN** profil avec `obligatorySubjects: [Chem, Phy, Bio]` + `optionalSubjects: [CS, ICT, RS, Com]` + `minSubjects: 3` + `maxSubjects: 5`,

**Scénarios** :

| Situation | `pickedTotal` | Couleur compteur | Bouton Valider |
|---|---|---|---|
| État initial (3 oblig + 0 opt) | 3/5 | primary | activé (3 ∈ [3, 5]) |
| Tap ICT (+1) | 4/5 | primary | activé |
| Tap ICT + CS (+2) | 5/5 | primary | activé |
| Tap ICT + CS + RS (+3) | 6/5 | **danger** | **disabled** |
| Tap CS + RS + Com (+3) avec ICT non sélectionné | 6/5 | danger | disabled |

**Cohérent** avec la borne `pickedTotal ∈ [minSubjects, maxSubjects]` posée Story 1.15 dans `_FreeWithObligatoryBody`. **Pas de toast intrusif** sur sur-saturation (la couleur danger + bouton disabled suffisent — cohérent Décision 4 Story 1.15).

### AC4 — Persistance `pickedSubjects` avec Series d'abord

**GIVEN** James tape Valider avec ICT sélectionné,
**WHEN** `_onValidatePicked` est appelé (handler Story 1.15 inchangé),
**THEN** la liste posée Firestore est `[Chemistry, Physics, Biology, ICT]` — **Series obligatoires d'abord, transversales sélectionnées ensuite**, dans l'ordre des listes du profil (cohérent ordre tap Story 1.15 Mariam AC3).

**ET** la persistance utilise `repo.updatePickedSubjects(...)` (Story 1.15 T4) + `.update({pickedSubjects: [...], updatedAt: FieldValue.serverTimestamp()})` partiel (CLAUDE.md règle 10.l).

**ET** sur succès → `GoRouter.of(context).go('/onboarding/profile/recap')`.

### AC5 — Non-régression modes Story 1.4 + 1.15

**GIVEN** les tests existants :

- 3 widget tests `subjects_picker_page_legacy_optout_test.dart` (James Upper Sixth opt_out mode) ;
- 4 widget tests `subjects_picker_page_free_with_obligatory_test.dart` (Mariam Form 5) ;
- 3 tests repo `user_profile_repository_picked_subjects_test.dart` (Story 1.15) ;
- 11 rules tests `users.test.mjs` ;

**WHEN** Story 1.16 est mergée,
**THEN** **TOUS** ces tests passent inchangés. AUCUN test Story 1.4 ou 1.15 ne doit être modifié.

**ET** la matrice.json **n'est pas touchée** (Décision 1 figée — widget only Dart).

### AC6 — Aucune nouvelle dépendance, aucun changement structurel

**GIVEN** la story est implémentée,
**WHEN** un reviewer audite le diff,
**THEN** il vérifie qu'aucun des éléments suivants n'est touché :

- `pubspec.yaml` (aucune dépendance ajoutée).
- `firestore.rules` (déjà fait Story 1.15, `pickedSubjectsValid()` couvre `series_plus_optional`).
- `firestore.indexes.json` (aucun index nouveau — `pickedSubjects` array sur doc lu par ID).
- `scripts/firebase_seed/data/matrice.json` (Décision 1 figée).
- `scripts/firebase_seed/seed_catalogue.py` (idempotence préservée).
- `mobile_app/lib/core/catalogue/domain/models.dart` (PickerMode + DerivedProfile inchangés — Story 1.13).
- `mobile_app/lib/features/onboarding/providers.dart` (déjà OK Story 1.15).
- `mobile_app/lib/features/onboarding/data/user_profile_repository_firestore_impl.dart` (`updatePickedSubjects` OK Story 1.15).
- `doc/partage/*` (déjà OK Story 1.11a).
- `CLAUDE.md` / `README.md`.

**Seuls changements attendus** : `subjects_picker_page.dart` (remplacement case + nouveau widget privé) + 2 fichiers ARB + 1 fichier `app_localizations.dart` regen + 1 nouveau fichier test.

### AC7 — Compteur live ICU pluralized + EN/FR

**GIVEN** la clé ARB `onboardingPickerCounterLive` (Story 1.15) est ICU pluralized,
**WHEN** Story 1.16 réutilise cette clé pour le compteur,
**THEN** elle ne nécessite **aucun ajustement** côté Story 1.16 :

- FR : "Tu présentes 4/5 matières" (vs 1 = "Tu présentes 1/5 matière").
- EN : "You take 4/5 subjects" (vs 1 = "You take 1/5 subject").

Aucune duplication clé. Aucune modif `app_localizations.dart` autre que les 2 NEW Story 1.16 (`onboardingPickerSeriesTitle` + `onboardingPickerTransversalesTitle`).

## Tasks/Subtasks

### T1 — Remplacer placeholder `case PickerMode.seriesPlusOptional` (Story 1.15 lignes 152-164) [AC1]

- [ ] T1.1 — Dans `mobile_app/lib/features/onboarding/presentation/subjects_picker_page.dart`, localiser le bloc `case PickerMode.seriesPlusOptional:` (Story 1.15 ligne 152) qui retourne actuellement `SizedBox.shrink()` après log + redirect recap.
- [ ] T1.2 — Remplacer par un `return _SeriesPlusOptionalBody(...)` avec exactement les mêmes 9 props que `_FreeWithObligatoryBody` (Story 1.15 lignes 137-150) : `profile`, `langKey`, `picked: _pickedOptional`, `isSaving: _isSaving`, `onInitPicked: _initPickedOptionalIfNeeded`, `onToggleOptional: _onToggleOptional`, `onTapObligatory: _onTapObligatory`, `onValidate: () => _onValidatePicked(profile)`, `onCancel: () => GoRouter.of(context).go('/onboarding/profile/recap')`.
- [ ] T1.3 — Supprimer le `WidgetsBinding.instance.addPostFrameCallback(...)` + `AppLogger.i('PickerPage: pickerMode=seriesPlusOptional (Story 1.16) redirect recap')` qui n'a plus lieu d'être.
- [ ] T1.4 — Vérifier que `flutter analyze` retourne 0 issue après ce changement (la classe `_SeriesPlusOptionalBody` n'existe pas encore → erreur attendue à corriger par T2).

### T2 — Créer widget `_SeriesPlusOptionalBody` (calque sur `_FreeWithObligatoryBody`) [AC2, AC3]

- [ ] T2.1 — Dans le même fichier `subjects_picker_page.dart`, après le widget `_FreeWithObligatoryBody` (en fin de fichier), créer la classe `_SeriesPlusOptionalBody extends StatelessWidget` avec :
  - **Props identiques** à `_FreeWithObligatoryBody` (constructeur, fields, types).
  - **Build()** : duplication quasi-littérale de `_FreeWithObligatoryBody.build` (Story 1.15 lignes 410-580) avec **3 différences sémantiques uniquement** :
    1. **Titre H3 section 1** : `l10n.onboardingPickerSeriesTitle` (NEW T3) au lieu de `l10n.onboardingPickerObligatoryTitle` (Story 1.15).
    2. **Titre H3 section 2** : `l10n.onboardingPickerTransversalesTitle` (NEW T3) au lieu de `l10n.onboardingPickerOptionalTitle` (Story 1.15).
    3. **Icône section 1** : reste `LucideIcons.lock` (cadenas — sémantique identique : matière non décochable).
- [ ] T2.2 — Tout le reste — pattern `Consumer + StreamBuilder<Map<String, dynamic>?>` + init `_pickedOptional` depuis `users/{uid}.pickedSubjects` retirant les obligatoires, layout `ListView` parent + 2 `ListView.separated(shrinkWrap: true, NeverScrollable, ...)` inner, compteur couleur conditionnelle, AppButton.primary, AppButton.secondary — **EST IDENTIQUE** à `_FreeWithObligatoryBody`. Pas de copier-coller créatif : utiliser exactement la structure Story 1.15.
- [ ] T2.3 — Vérifier que le widget compile : `flutter analyze` retourne 0 issue.

### T3 — Ajouter 2 clés ARB FR+EN (sémantique A-Level Series + Transversales) [AC2, AC7]

- [ ] T3.1 — Dans `mobile_app/lib/l10n/app_fr.arb`, ajouter après `onboardingPickerOptionalTitle` (Story 1.15) :
  ```json
  "onboardingPickerSeriesTitle": "Series (obligatoires)",
  "@onboardingPickerSeriesTitle": { "description": "Titre H3 section Series (obligatoires) mode series_plus_optional A-Level (Story 1.16). Series = combinaison fixe 3-4 matières GCE A-Level (ex. Chemistry/Physics/Biology pour S2)." },

  "onboardingPickerTransversalesTitle": "Transversales optionnelles",
  "@onboardingPickerTransversalesTitle": { "description": "Titre H3 section matières transversales optionnelles mode series_plus_optional A-Level (Story 1.16). Computer Science, ICT, Religious Studies, Commerce ajoutables jusqu'à max 5 total." },
  ```
- [ ] T3.2 — Dans `mobile_app/lib/l10n/app_en.arb`, ajouter symétrique :
  ```json
  "onboardingPickerSeriesTitle": "Series (mandatory)",
  "onboardingPickerTransversalesTitle": "Optional transversal subjects",
  ```
- [ ] T3.3 — Régénérer `mobile_app/lib/l10n/generated/app_localizations.dart` via `flutter gen-l10n` (depuis `mobile_app/`).
- [ ] T3.4 — Préserver **intactes** les 7 clés `onboardingPickerXxx` Story 1.15 (Title/Subtitle/ObligatoryTitle/OptionalTitle/CounterLive/ErrorObligatoryToast/ValidateCta).

### T4 — Widget tests James Upper Sixth S2 + ICT [AC3, AC4, AC5]

- [ ] T4.1 — Créer `mobile_app/test/features/onboarding/presentation/subjects_picker_page_series_plus_optional_test.dart` (NEW) en copiant le pattern complet de `subjects_picker_page_free_with_obligatory_test.dart` (Story 1.15). Adaptations :
  - Helper `_jamesProfile()` qui retourne `DerivedProfile{ pickerMode: PickerMode.seriesPlusOptional, subjects: [Chem, Phy, Bio, CS, ICT, RS, Com], obligatorySubjects: [Chem, Phy, Bio], optionalSubjects: [CS, ICT, RS, Com], minSubjects: 3, maxSubjects: 5, canOptOut: false }`.
  - `OnboardingFlowState` : `niveauId: 'anglophone_upper_sixth'`, `serieId: 'anglophone_upper_sixth_s2'`.
  - Réutiliser `setSurfaceSize(800, 3000)` + GoRouter minimal (Story 1.15 patterns).
- [ ] T4.2 — **Test (a)** : page rendue → 3 Series checked+lock + 4 transversales décochées + compteur `3/5` couleur primary + bouton Valider activé (3 ∈ [3, 5]).
- [ ] T4.3 — **Test (b)** : tap ICT → compteur `4/5` primary + Valider activé. Cohérent EXPERIENCE.md Flow 1c ligne 501.
- [ ] T4.4 — **Test (c)** : tap CS + ICT + RS (3 transversales) → compteur `6/5` couleur danger + bouton Valider **disabled**. Cohérent edge case EXPERIENCE.md Flow 1c ligne 506 "Maximum 5 matières au A-Level".
- [ ] T4.5 — **Test (d)** : tap Chemistry (obligatoire) → toast warning `'This subject is mandatory and cannot be removed.'` visible + Chemistry reste checked + compteur statu quo 3/5.
- [ ] T4.6 — **Test (e)** : tap ICT puis Valider → `_FakeRepo.updatePickedSubjects` appelé avec `['anglophone_chemistry', 'anglophone_physics', 'anglophone_biology', 'anglophone_ict']` (Series d'abord, transversales sélectionnées ensuite). Cohérent AC4 + ordre EXPERIENCE.md Flow 1c ligne 502.

### T5 — Validation finale [AC5, AC6]

- [ ] T5.1 — `cd mobile_app && flutter analyze` retourne **0 issue**.
- [ ] T5.2 — `cd mobile_app && flutter test` retourne **0 failure**. Baseline post-1.15 = 226 verts → cible **~231 verts** (+5 nets : 5 tests `_SeriesPlusOptionalBody`). 226 tests existants passent **inchangés** (AC5 strict).
- [ ] T5.3 — Vérification grep `flutter analyze` : aucune référence à `// TODO Story 1.16` dans `subjects_picker_page.dart` (le placeholder est remplacé).
- [ ] T5.4 — Vérification grep `dart` : aucune nouvelle dépendance dans `pubspec.yaml`. Aucune modif `firestore.rules` / `firestore.indexes.json` / `matrice.json` / `seed_catalogue.py` / `doc/partage/*` / models.dart.
- [ ] T5.5 — Smoke device **différé session porteur** : créer manuellement un profil James Upper Sixth S2 (matrice actuelle = mode `opt_out`) → AUCUNE régression UX (le mode `series_plus_optional` n'est pas activable en prod aujourd'hui). Validation `_SeriesPlusOptionalBody` purement via tests unitaires Dart Story 1.16. La vraie bascule UX viendra avec la story future de migration matrice.

## Dev Notes

### Architecture cible — extension minimale du dispatch Story 1.15

Story 1.15 a posé tous les rouages :

```text
SubjectsPickerPage (Story 1.15 orchestrateur)
├── State : _optedOut + _pickedOptional + _isSaving
├── Handlers : _onToggleOptional + _onTapObligatory + _onValidatePicked
├── Dispatch : switch (profile.pickerMode) { ... }
│   ├── case derived              → redirect recap
│   ├── case optOut               → _LegacyOptOutBody (Story 1.4 preserved)
│   ├── case freeWithObligatory   → _FreeWithObligatoryBody (Mariam Form 5)
│   ├── case seriesPlusOptional   → ⚠️ PLACEHOLDER redirect recap (Story 1.16 cible)
│   └── case tvePicker            → ⚠️ PLACEHOLDER redirect recap (Story 1.17 cible)
```

Story 1.16 remplace **uniquement** le `case seriesPlusOptional` par un appel à un nouveau widget `_SeriesPlusOptionalBody` qui **partage 99% de sa structure** avec `_FreeWithObligatoryBody`. Les seules différences :

| Aspect | `_FreeWithObligatoryBody` (1.15) | `_SeriesPlusOptionalBody` (1.16) |
|---|---|---|
| Mode | `freeWithObligatory` (Mariam Form 5) | `seriesPlusOptional` (James Upper Sixth S2) |
| Sémantique section 1 | "Matières obligatoires" (EN+FR+Math) | "Series (obligatoires)" (Chem+Phy+Bio) |
| Sémantique section 2 | "Matières au choix" (8 optionnels) | "Transversales optionnelles" (CS+ICT+RS+Com) |
| Clé ARB titre 1 | `onboardingPickerObligatoryTitle` | `onboardingPickerSeriesTitle` (NEW) |
| Clé ARB titre 2 | `onboardingPickerOptionalTitle` | `onboardingPickerTransversalesTitle` (NEW) |
| Compteur ARB | `onboardingPickerCounterLive` (1.15) | `onboardingPickerCounterLive` (réutilisé) |
| `minSubjects` matrice | 6 | 3 (Series base) |
| `maxSubjects` matrice | 11 | 5 |
| `obligatorySubjects.length` | 3 | 3 (S2) ou 4 (autres) |
| `optionalSubjects.length` | 8 (Mariam) | 4 (CS/ICT/RS/Com) |
| Cadenas icon | `LucideIcons.lock` | `LucideIcons.lock` (identique) |

**TOUT LE RESTE EST IDENTIQUE** : `Consumer + StreamBuilder`, init `_pickedOptional` depuis `pickedSubjects` Firestore en retirant les obligatoires, `ListView` parent + 2 `ListView.separated(shrinkWrap, NeverScrollable)` inner, compteur live couleur primary/danger conditionnelle, AppButton.primary disabled hors bornes, AppButton.secondary back.

### Files to UPDATE (existants) vs NEW (Story 1.16)

| Fichier | Action | Lignes estimées | Référence |
|---|---|---|---|
| `mobile_app/lib/features/onboarding/presentation/subjects_picker_page.dart` | UPDATE — remplacer placeholder + ajouter `_SeriesPlusOptionalBody` widget (~180 lignes) | +180 / -10 | T1, T2 |
| `mobile_app/lib/l10n/app_fr.arb` | UPDATE — +2 clés panier A-Level | +12 | T3.1 |
| `mobile_app/lib/l10n/app_en.arb` | UPDATE — +2 clés EN | +4 | T3.2 |
| `mobile_app/lib/l10n/generated/app_localizations.dart` (+ _fr.dart + _en.dart) | REGEN auto | (auto) | T3.3 |
| `mobile_app/test/features/onboarding/presentation/subjects_picker_page_series_plus_optional_test.dart` | **NEW** — 5 tests James Upper Sixth S2 | ~250 | T4 |

**Diff cible** : ~280 lignes hors tests (largement sous cible 300 — story focused).

### Pattern testing — copie de `_free_with_obligatory_test.dart` Story 1.15

Le helper test Story 1.15 (`_pumpPicker`, `_FakeRepo`, `_PreloadedFlow`, `setSurfaceSize(800, 3000)`, `MaterialApp.router(routerConfig: GoRouter(...))`) **est dupliqué tel quel** dans Story 1.16 — seul le helper `_jamesProfile()` change. Cohérent avec le pattern Story 1.4 → 1.15 (`_jamesProfile()` legacy + `_mariamProfile()` free) → Story 1.16 (`_jamesProfile()` series_plus_optional artificial).

```dart
DerivedProfile _jamesProfile() {
  final series = [
    _subj('anglophone_chemistry', 'Chimie', 'Chemistry', icon: 'flask-conical'),
    _subj('anglophone_physics', 'Physique', 'Physics', icon: 'atom'),
    _subj('anglophone_biology', 'Biologie', 'Biology', icon: 'dna'),
  ];
  final transversales = [
    _subj('anglophone_computer_science', 'Informatique', 'Computer Science', icon: 'cpu'),
    _subj('anglophone_ict', 'TIC', 'ICT', icon: 'laptop'),
    _subj('anglophone_religious_studies', 'Religion', 'Religious Studies', icon: 'scroll-text'),
    _subj('anglophone_commerce', 'Commerce', 'Commerce', icon: 'briefcase'),
  ];
  return DerivedProfile(
    subjects: [...series, ...transversales],
    examTargets: const [],
    canOptOut: false,
    pickerMode: PickerMode.seriesPlusOptional,
    obligatorySubjects: series,
    optionalSubjects: transversales,
    minSubjects: 3,
    maxSubjects: 5,
  );
}
```

### Anti-patterns interdits

1. ❌ **Modifier `matrice.json`** — Décision 1 figée. Aucun changement de `pickerMode` sur Upper/Lower Sixth A-Level. Si tu veux activer le mode en prod, fais-le dans une story dédiée future (1.18 ou Epic 2).
2. ❌ **Modifier `firestore.rules`** — `pickedSubjectsValid()` Story 1.15 couvre déjà `series_plus_optional` (subset `derivedSubjects` — pragmatique). Rien à ajouter.
3. ❌ **Ajouter un index Firestore** — Story 1.16 ne crée aucune nouvelle requête. `pickedSubjects` array sur doc lu par ID.
4. ❌ **Casser les tests Story 1.4 ou 1.15** — AC5 strict. Les 13 tests widget existants + 11 rules tests doivent passer inchangés.
5. ❌ **Refactoriser `_FreeWithObligatoryBody`** pour le rendre générique paramétrable. Tentation naturelle "DRY" mais ÉCHEC garanti :
   - Coût refacto : ~3h additionnel (props, génériques, nommage)
   - Bénéfice : duplication évitée ~140 lignes
   - Risque : casser tests 1.15 + 1.4 + introduction bug par effet de bord
   - **Décision** : DUPLIQUER avec 3 différences sémantiques. Story 1.17 fera pareil pour `_TvePickerBody` (5 sections). Si vraie redondance émerge sur Stories 1.18+ ou Epic 2, faire un refactor dédié à ce moment-là.
6. ❌ **Logger les IDs des matières optionnelles tapées** — cohérent CLAUDE.md sécurité 4 + pattern Story 1.15. Pas de bruit console.
7. ❌ **Toaster sur sur-saturation > maxSubjects** — la couleur danger + bouton disabled suffisent (Décision 4 Story 1.15). Pas d'intrusion UX.
8. ❌ **Persister `pickedSubjects` sans les Series** — la liste DOIT contenir Series obligatoires + transversales sélectionnées (AC4). Cohérent BASE-DE-DONNEES.md ligne 75 (`obligatorySubjectIds ⊂ pickedSubjects`).
9. ❌ **Forcer `Source.server` ou `Source.cache`** — cohérent CLAUDE.md règle 10.h, accepter `Source.serverAndCache` par défaut.
10. ❌ **Modifier `models.dart` ou `providers.dart` ou repo** — Story 1.13 + 1.15 ont tout fourni. Story 1.16 = présentation uniquement.
11. ❌ **Ajouter `_SeriesPlusOptional` props supplémentaires côté state Story 1.15** — les 9 props existantes suffisent. Si tentation d'ajouter des props : tu casses la symétrie avec `_FreeWithObligatoryBody`.

### Décisions techniques figées

#### Décision 1 — Widget only Dart, matrice.json INCHANGÉE

`scripts/firebase_seed/data/matrice.json` n'est PAS touché par Story 1.16. Upper/Lower Sixth S1-S8 + A1-A5 restent `pickerMode: 'opt_out'` en prod. **Why** :

- Préserver 100% les tests Story 1.4 (James opt_out) et 1.15 (Mariam free) sans migration.
- Pas de scope creep sur seed + reseed valide-edu + smoke device complexe.
- Le widget est livré FONCTIONNEL — quand la story de migration arrivera (1.18 ou Epic 2), zéro ligne Dart à modifier.

**Trade-off accepté** : le mode `series_plus_optional` n'est pas testable en flow réel app (matrice prod = `opt_out`). Validation 100% par tests unitaires Dart Story 1.16. Smoke device différé.

**Re-évaluable** : si après Story 1.17, le PO décide d'activer A-Level en prod, une story dédiée fera la bascule matrice + reseed + adaptation tests Story 1.4 (déplacer James vers une serie qui reste `opt_out` — ex. série Form 4 si on en garde une, sinon supprimer le test 1.4 et le remplacer par un equivalent series_plus_optional avec James devenu Sixth S2).

#### Décision 2 — Dupliquer `_FreeWithObligatoryBody` (pas de refactor générique)

`_SeriesPlusOptionalBody` est une **copie quasi-littérale** de `_FreeWithObligatoryBody` avec 3 différences sémantiques (titres + 2 clés ARB). Tentation DRY rejetée : cf. anti-pattern 5. **Why** :

- Coût refacto > bénéfice à 2 widgets seulement.
- Story 1.17 va dupliquer aussi (`_TvePickerBody` 5 sections).
- Si vraie redondance émerge Story 1.17+, faire un refactor dédié post-Epic 1.

#### Décision 3 — Cadenas Lucide identique sur les 2 widgets

Les Series A-Level (Chemistry/Physics/Biology) sont sémantiquement "obligatoires" pour le profil (figées par le choix de Series). Cadenas `LucideIcons.lock` reste cohérent avec mode `freeWithObligatory` (Mariam EN+FR+Math). **Why** : pas de jargon "Series" sur une icône, on transmet la sémantique "non décochable" — le mot "Series" est dans le titre H3 de la section.

#### Décision 4 — Réutiliser `onboardingPickerCounterLive` Story 1.15 (pas de nouvelle clé)

Le compteur "Tu présentes X/Y matières" est suffisamment générique pour les 2 modes. Pas de "X/Y matières A-Level" qui serait redondant avec le titre H2 page + bandeau récap futur. Économie 1 clé ARB inutile.

#### Décision 5 — Ordre `[Series..., Optionals sélectionnés]` dans `pickedSubjects`

L'ordre Firestore est `[obligatoires d'abord, optionnels ensuite dans l'ordre de tap]` — cohérent avec `_onValidatePicked` Story 1.15 ligne 271-274 (déjà implémenté). Story 1.16 hérite de ce comportement sans rien changer.

### Personas concernées

- **James Tanyi** — Upper Sixth S2 anglophone, Buea, Tecno Spark 8. Persona Story 1.4 (mode opt_out) ET Story 1.16 (mode series_plus_optional + ICT). En attendant la bascule matrice, le profil prod reste opt_out — Story 1.16 valide la mécanique side-by-side via tests Dart.
- **Mariam Bakari** — Form 5 anglophone (Story 1.15) — non-régression secondaire.
- **Fatou Mballa** — Tle D francophone (Story 1.3) — non-régression secondaire.

### Sources autoritaires

1. **`epics.md` § Story 1.16** : déclaration scope (sprint-change 2026-06-09).
2. **`sprint-change-proposal-2026-06-09.md` § Change 4.6 Story 1.16** (lignes 297-303) + § 14 table A-Level règle panier (lignes 405-409) : authorité sur min 3 / max 5 / 4 transversales.
3. **`prd.md` § FR-3 multi-mode** (ligne 152) : mode `series_plus_optional` consequence — "max 5 transversales (Computer Science, ICT, Religious Studies, Commerce) ajoutables jusqu'à max 5 total".
4. **`EXPERIENCE.md` Variant Flow 1c James** (lignes 490-506) : autorité UX (sections nommées, compteur, edge case max 5).
5. **`subjects_picker_page.dart` Story 1.15** (lignes 152-164 placeholder + lignes 410-580 `_FreeWithObligatoryBody`) : pattern à dupliquer.
6. **`Office du Bac` + `Cameroon GCE Board`** : règles officielles sourcing Story 1.11a.

### Cost-benefit Firestore (CLAUDE.md règle 10.m — obligatoire)

**Reads / writes Story 1.16 — DIFFERENTIEL** vs Story 1.15 :

- **Aucun read additionnel** : `derivedProfileProvider` + `userProfileRepositoryProvider.watchProfile()` déjà comptés Story 1.13 + 1.15.
- **Aucun write additionnel** : `updatePickedSubjects` déjà compté Story 1.15.
- **Aucune nouvelle requête** = aucun nouvel index.

**Volumétrie A-Level estimée 10 000 users** :

- Marché Upper Sixth + Lower Sixth anglo = ~15% marché global (~1 500 users cibles à 10k total).
- ~150 sessions onboarding A-Level / mois (adoption ~10%/mois).
- 6 reads (déjà comptés) + 1 write × 150 = 150 reads + 150 writes additionnels / mois.
- Négligeable.

**Trade-off accepté** : pas de validation cardinalité côté serveur (Décision 3 Story 1.15 préservée). Bypass client peut poser `pickedSubjects: [chemistry]` seulement (1 Series sans transversales et sans EN/FR sur A-Level) → casse son propre profil UX. Pas de fuite sécurité.

## Definition of Done

- [ ] **AC1-AC7 verts** : tous les acceptance criteria validés par tests Dart.
- [ ] **`flutter analyze` 0 issue** sur `mobile_app/`.
- [ ] **`flutter test` 0 failure** : baseline 226 verts post-1.15 → cible ~231 (+5 nets : 5 tests `_SeriesPlusOptionalBody`).
- [ ] **`cd test/rules && npm test` 0 failure** : 23/23 verts inchangés (Story 1.16 ne touche pas rules).
- [ ] **Diff hors tests <= 300 lignes** : story focused, beaucoup plus petite que 1.15.
- [ ] **Smoke device DIFFÉRÉ** : pas de scénario réel app activable (matrice = opt_out). Validation 100% tests unitaires.
- [ ] **AUCUNE modif** : `matrice.json` / `seed_catalogue.py` / `firestore.rules` / `firestore.indexes.json` / `models.dart` / `providers.dart` / `user_profile_repository*.dart` / `doc/partage/*` / `pubspec.yaml` / `CLAUDE.md` / `README.md`.
- [ ] **Tests Story 1.4 (3 widget tests) + Story 1.15 (4 widget tests free + 3 repo Picked) + Story 0.9 (11 rules tests) 100% verts inchangés** — AC5 strict.
- [ ] **Commit message conventional commits FR à l'impératif** : `feat(onboarding): SubjectsPickerPage mode series_plus_optional A-Level transversales (Story 1.16)`.
- [ ] **Branche `feat/1.16-extension-a-level-transversales`** (kebab-case, 39 chars).
- [ ] **PR <= 400 lignes diff totalisé** (cible largement atteignable vu scope focused ~280 lignes hors tests).
- [ ] **Pas de `--no-verify`** sur le commit (CLAUDE.md workflow git).
- [ ] **Aucune action porteur post-merge** : pas de reseed Firestore, pas de deploy rules (déjà OK Story 1.15).

## Dev Agent Record

(à remplir par /bmad-dev-story)

### Implementation Plan

(à remplir)

### Debug Log

(à remplir)

### Completion Notes

(à remplir)

### File List

(à remplir)

### Change Log

(à remplir)

## Senior Developer Review (AI)

(à remplir post-implémentation)
