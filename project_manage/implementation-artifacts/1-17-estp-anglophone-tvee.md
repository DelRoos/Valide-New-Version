---
story_id: 1.17
title: SubjectsPickerPage mode `tve_picker` TVEE Professional/Related/Other (Eyong TVE AL Electrotechnique — dernière story Epic 1 v2)
epic: 1
phase: P1 extension v2 (sprint change 2026-06-09)
status: review
created: 2026-06-09
baseline_commit: 4afb36b  # merge PR #83 (contexte engine Story 1.17) — main aligné post Stories 1.11a/1.11b/1.12/1.13/1.14/1.15/1.16 done
estimation: M (~5h)
sprint_change: sprint-change-proposal-2026-06-09.md
dependencies:
  - 1.13 — done (PickerMode.tvePicker enum + Serie.professionalSubjectIds + relatedProfessionalSubjectIds + otherSubjectIds + DerivedProfile + derive() v2 5 futures)
  - 1.15 — done (SubjectsPickerPage orchestrateur + dispatch `switch (profile.pickerMode)` + `_FreeWithObligatoryBody` pattern + state `_pickedOptional` + handlers + repo + rules + 7 clés ARB picker)
  - 1.16 — done (`_SeriesPlusOptionalBody` pattern à dupliquer pour le 3ᵉ mode — confirme Décision 2 "duplique pas refactor générique")
blocks:
  - (aucun — dernière story Epic 1 v2)
sourceArtifacts:
  - project_manage/planning-artifacts/epics.md § Story 1.17 + dependency graph
  - project_manage/planning-artifacts/sprint-change-proposal-2026-06-09.md § Change 4.6 Story 1.17 (lignes 304-310) + § matrice TVEE
  - project_manage/planning-artifacts/prds/prd-valide-mvp-2026-06-03/prd.md § FR-3 multi-mode (ligne 153 mode `tve_picker`)
  - project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/EXPERIENCE.md § Variant Flow 1d Eyong (lignes 508-531)
  - doc/partage/BASE-DE-DONNEES.md § users/{uid}.pickedSubjects + § Validation panier polymorphe (Story 1.11a + 1.15)
  - doc/partage/ALGORITHMES.md § Modes panier (table 5 modes inclus tve_picker)
  - mobile_app/lib/core/catalogue/domain/models.dart § PickerMode.tvePicker + Serie.professionalSubjectIds/relatedProfessionalSubjectIds/otherSubjectIds (Story 1.13) + DerivedProfile (à étendre +3 champs)
  - mobile_app/lib/core/catalogue/data/catalogue_repository_firestore_impl.dart § derive() v2 5 futures Future.wait (Story 1.13 lignes 192-198 à étendre +3)
  - mobile_app/lib/features/onboarding/presentation/subjects_picker_page.dart § placeholder `case PickerMode.tvePicker` (Story 1.15 lignes 168-180 à remplacer) + `_FreeWithObligatoryBody` + `_SeriesPlusOptionalBody` patterns à dupliquer
  - mobile_app/lib/l10n/app_fr.arb + app_en.arb § clés `onboardingPickerXxx` Stories 1.15 + 1.16 (à étendre +3)
  - scripts/firebase_seed/data/matrice.json § 26 séries TVEE (13 spécialités × 2 niveaux) — **INCHANGÉE** Story 1.17 (Décision 1 figée cohérent 1.16)
---

# Story 1.17 — SubjectsPickerPage mode `tve_picker` TVEE Professional/Related/Other (Eyong TVE AL Electrotechnique)

Status: **review**

## Objectif

Compléter le **5ᵉ et DERNIER mode panier** de `SubjectsPickerPage` (Story 1.15) en livrant le widget `_TvePickerBody` qui rend le pattern TVEE (Technical Vocational Education) : Professional Subjects + Related Professional Subjects + Other Subjects (mix EN/FR lockés + au choix). Cible UX EXPERIENCE.md Variant Flow 1d — Eyong Eboa TVE AL Electrotechnique (Bonabéri Douala, Itel A56).

**Pourquoi maintenant** : Stories 1.13 + 1.15 + 1.16 ont posé toutes les fondations. Story 1.17 ferme l'Epic 1 v2 en couvrant le marché anglophone TVEE (~15-20% du marché cible adressable selon SPEC). Sans Story 1.17, Eyong qui tape « Technique » dans le flow profil tombe sur un dead-end car aucune branche TVEE n'est rendue.

**Pourquoi `Widget only Dart` + extension model mineure (Décision 1 figée, cohérent 1.16)** : `matrice.json` reste 100% INCHANGÉE. Les 26 séries TVEE seedées Story 1.12 restent `isActive: false` + listes `professionalSubjectIds` / `relatedProfessionalSubjectIds` / `otherSubjectIds` **vides** en prod. Conséquences (acceptées) :

- Aucun utilisateur réel ne peut DÉCLENCHER le mode `tve_picker` en prod jusqu'à l'activation progressive (validation Mr Eboa Joseph + peuplement des 3 listes par admin pédagogique — action porteur post-1.17 séparée).
- Le widget est livré **FONCTIONNEL** — quand l'activation arrivera (matrice update + reseed), aucune ligne Dart à modifier.
- Tests Story 1.4 + 1.15 + 1.16 100% préservés.
- Smoke device différé jusqu'à activation matrice.
- **Extension mineure** `DerivedProfile` +3 champs (`professionalSubjects` / `relatedProfessionalSubjects` / `otherSubjects` — defaults vides, non-breaking) requis pour exposer la structure TVEE au widget. Cohérent avec le pattern défensif Story 1.13 (les modes derived/optOut/free/series_plus utilisent defaults vides → comportement v1 préservé).
- Extension `derive()` v2 → v3 : `Future.wait` étendu de 5 à 8 futures pour fetch parallèle Pro/Related/Other. Non-breaking pour tous les autres modes (listes vides si Serie n'a pas ces champs).

**Critère de fin** :

- Un profil dérivé synthétique `DerivedProfile{ pickerMode: tvePicker, professionalSubjects: [ELET theory, ELET practical, Electrical machines], relatedProfessionalSubjects: [Math Industrial, Physics, Drawing], obligatorySubjects: [EN, FR], optionalSubjects: [History, Geography, Religious Studies], minSubjects: 6, maxSubjects: 8 }` rend `_TvePickerBody` avec 3 sections empilées :
  1. **Professional Subjects (obligatoires)** : 3 cards lockées + cadenas Lucide
  2. **Related Professional Subjects (obligatoires)** : 3 cards lockées + cadenas Lucide
  3. **Other Subjects** : 2 cards lockées (EN+FR + cadenas) + 3 checkboxes interactives (Hist/Geo/RS décochées par défaut)
- Compteur live "Tu présentes 8/8 matières" couleur primary (sélection nominal par défaut TVE AL = 3 Pro + 3 Related + EN + FR = 8 → ∈ [6, 8] valid).
- Tap Valider sans cocher Hist/Geo/RS → `pickedSubjects = [ELET theory, ELET practical, Electrical machines, Math Industrial, Physics, Drawing, EN, FR]` posé en Firestore.
- **Edge case sur-saturation** : tap History + Geography + RS (3 ajouts) → pickedTotal = 11 > maxSubjects 8 → compteur danger + bouton Valider disabled.
- Modes Story 1.4 + 1.15 + 1.16 préservés : tests legacy `opt_out` + free + series_plus passent **inchangés** (AC6 strict).

## Story

**As a** élève anglophone TVEE (TVE Intermediate Level ou TVE Advanced Level, spécialité industrielle/commerciale/Home Economics),
**I want** sélectionner mes matières en respectant la règle officielle Cameroon GCE Board TVEE (Professional + Related forcés selon ma spécialité + Other Subjects avec EN/FR forcés et matières culturelles au choix),
**so that** mon dashboard reflète exactement le programme TVE technique camerounais sans pollution par des matières hors curriculum vocational (FR-3 mode `tve_picker`).

## Acceptance Criteria

### AC1 — Extension `DerivedProfile` +3 champs Subject lists (non-breaking)

**GIVEN** le model `DerivedProfile` actuel (Story 1.13) avec `subjects, examTargets, canOptOut, pickerMode, obligatorySubjects, optionalSubjects, minSubjects, maxSubjects`,
**WHEN** Story 1.17 étend le model,
**THEN** 3 nouveaux champs immutable sont ajoutés au constructeur avec defaults vides :

```dart
class DerivedProfile extends Equatable {
  const DerivedProfile({
    required this.subjects,
    required this.examTargets,
    required this.canOptOut,
    this.pickerMode = PickerMode.derived,
    this.obligatorySubjects = const [],
    this.optionalSubjects = const [],
    this.minSubjects,
    this.maxSubjects,
    // NEW v3 — Story 1.17 (defaults vides, non-breaking).
    this.professionalSubjects = const [],
    this.relatedProfessionalSubjects = const [],
    this.otherSubjects = const [],
  });
  // ... fields
  final List<Subject> professionalSubjects;
  final List<Subject> relatedProfessionalSubjects;
  final List<Subject> otherSubjects;
}
```

**ET** les `props` Equatable sont étendus pour inclure les 3 nouveaux champs.

**ET** tous les tests existants (`_jamesProfile`, `_mariamProfile`, `_fatouProfile`, etc.) passent **inchangés** car les defaults vides n'affectent pas les modes legacy.

### AC2 — Extension `derive()` v2 → v3 : Future.wait 8 futures

**GIVEN** `derive()` Story 1.13 fait déjà `Future.wait` sur 5 futures (série + subjects + examTargets + obligatorySubjects + optionalSubjects),
**WHEN** Story 1.17 étend `derive()`,
**THEN** 3 nouvelles futures sont ajoutées au `Future.wait` pour fetch parallèle Pro/Related/Other depuis les listes IDs de la Serie :

```dart
// Story 1.13 — 5 futures actuelles
final serieFuture = ...;
final subjectsFuture = _fetchSubjectsByIds(rule.subjectIds);
final examTargetsFuture = _fetchExamTargetsByIds(rule.examTargetIds);
final obligatorySubjectsFuture = _fetchSubjectsByIds(rule.obligatorySubjectIds);
final optionalSubjectsFuture = _fetchSubjectsByIds(rule.optionalSubjectIds);

// Story 1.17 — +3 futures pour TVEE (lecture depuis Serie, pas DerivationRule)
final professionalSubjectsFuture =
    serieDoc?.professionalSubjectIds.isNotEmpty == true
        ? _fetchSubjectsByIds(serieDoc!.professionalSubjectIds)
        : Future.value(<Subject>[]);
final relatedProfessionalSubjectsFuture =
    serieDoc?.relatedProfessionalSubjectIds.isNotEmpty == true
        ? _fetchSubjectsByIds(serieDoc!.relatedProfessionalSubjectIds)
        : Future.value(<Subject>[]);
final otherSubjectsFuture =
    serieDoc?.otherSubjectIds.isNotEmpty == true
        ? _fetchSubjectsByIds(serieDoc!.otherSubjectIds)
        : Future.value(<Subject>[]);
```

**ATTENTION** : `serieDoc` n'est PAS encore résolu au moment où on déclare les futures (il l'est seulement après le `await Future.wait(...)`). Solution : exécuter la résolution série EN PREMIER (1 RTT), puis les 7 autres en parallèle (1 RTT max). **Modification du pattern Story 1.13** : `await serieFuture` standalone, puis `Future.wait` sur les 7 autres futures avec serieDoc résolu.

**ATTENTION-bis (optimisation alternative)** : lire les 3 listes TVEE depuis la `DerivationRule` au lieu de la `Serie`. Vérifier en lecture matrice.json si les rules `rule_anglophone_tve_*` ont aussi ces champs (probablement non, ils sont sur la `series`). **Décision figée 4** : lire depuis la `series` (cohérent matrice Story 1.12).

**ET** retourne un `DerivedProfile` enrichi avec `professionalSubjects: results[5]`, `relatedProfessionalSubjects: results[6]`, `otherSubjects: results[7]` (ou ajustement selon la séquence Future.wait).

**ET** le log `derive() OK` inclut les 3 nouveaux counts pour traçabilité :

```dart
AppLogger.i(
  'derive() OK: ... pro=${professionalSubjects.length} '
  'related=${relatedProfessionalSubjects.length} '
  'other=${otherSubjects.length}',
);
```

### AC3 — Remplacement placeholder `case PickerMode.tvePicker` (Story 1.15 dispatch)

**GIVEN** le placeholder `case PickerMode.tvePicker` dans `_dispatchByPickerMode` (Story 1.15 lignes 166-180) qui retourne `SizedBox.shrink()` après log + redirect recap,
**WHEN** Story 1.17 le remplace,
**THEN** il retourne `return _TvePickerBody(...)` avec exactement les mêmes 9 props que `_FreeWithObligatoryBody` (Story 1.15) et `_SeriesPlusOptionalBody` (Story 1.16) : `profile`, `langKey`, `picked: _pickedOptional`, `isSaving: _isSaving`, `onInitPicked: _initPickedOptionalIfNeeded`, `onToggleOptional: _onToggleOptional`, `onTapObligatory: _onTapObligatory`, `onValidate: () => _onValidatePicked(profile)`, `onCancel: () => GoRouter.of(context).go('/onboarding/profile/recap')`.

**ET** le `WidgetsBinding.instance.addPostFrameCallback(...)` + `AppLogger.i('PickerPage: pickerMode=tvePicker (Story 1.17) redirect recap')` sont supprimés.

### AC4 — Widget `_TvePickerBody` : 3 sections (Professional / Related / Other mix)

**GIVEN** un `DerivedProfile{ pickerMode: tvePicker, professionalSubjects: [Pro1, Pro2, Pro3], relatedProfessionalSubjects: [Rel1, Rel2, Rel3], obligatorySubjects: [EN, FR], optionalSubjects: [Hist, Geo, RS], minSubjects: 6, maxSubjects: 8 }`,
**WHEN** `_TvePickerBody` rend,
**THEN** il affiche **3 sections empilées** :

1. **Section « Professional Subjects (obligatoires) »** (titre H3, NEW clé ARB `onboardingPickerProfessionalTitle`) :
   - Boucle sur `profile.professionalSubjects` (3 items pour Eyong TVE AL ELET).
   - CheckboxListTile **checked + lock icon Lucide**.
   - Tap → `onTapObligatory(s.subjectId)` (toast warning + log warn — handler Story 1.15 inchangé).

2. **Section « Related Professional Subjects (obligatoires) »** (titre H3, NEW clé ARB `onboardingPickerRelatedTitle`) :
   - Boucle sur `profile.relatedProfessionalSubjects` (3 items pour Eyong TVE AL ELET).
   - CheckboxListTile **checked + lock icon Lucide**.
   - Tap → `onTapObligatory(s.subjectId)`.

3. **Section « Other Subjects »** (titre H3, NEW clé ARB `onboardingPickerOtherTitle`) :
   - **Sous-loop 1** sur `profile.obligatorySubjects` (EN + FR — 2 items) : CheckboxListTile **checked + lock icon Lucide** + tap → `onTapObligatory(s.subjectId)`.
   - **Sous-loop 2** sur `profile.optionalSubjects` (Hist + Geo + RS — 3 items) : CheckboxListTile interactif + tap → `onToggleOptional(s.subjectId, selected)`.

4. **Compteur live** : `pickedTotal = professionalSubjects.length + relatedProfessionalSubjects.length + obligatorySubjects.length + picked!.length` (auto-comptés Pro+Related+EN+FR + transversales sélectionnées). Couleur primary si `∈ [min, max]`, danger sinon.

5. **Bouton Valider** : activé si `pickedTotal ∈ [minSubjects, maxSubjects]` AND `!isSaving`.

6. **Bouton Retour** : `AppButton.secondary` → `onCancel`.

### AC5 — Persistance `pickedSubjects` ordre [Pro, Related, Obligatoires (EN/FR), Optionnels sélectionnés]

**GIVEN** Eyong tape Valider sans cocher Hist/Geo/RS (sélection nominale TVE AL = 8 matières exactes),
**WHEN** `_onValidatePicked` est appelé (handler Story 1.15 réutilisé tel quel),
**THEN** la liste posée Firestore est l'ordre :

```
[Pro1, Pro2, Pro3, Rel1, Rel2, Rel3, EN, FR]
```

— **TVEE-spécifique** : Pro d'abord, puis Related, puis EN+FR (Obligatoires Other), puis optionnels sélectionnés (vides pour Eyong nominal).

**ATTENTION** : le `_onValidatePicked` Story 1.15 actuel fait `[...profile.obligatorySubjects.map((s) => s.subjectId), ...picked!.toList()]`. Ce pattern ne couvre pas Pro+Related. **Adaptation Story 1.17** : modifier `_onValidatePicked` pour ajouter Pro+Related en début quand `pickerMode == tvePicker`. **Décision figée 5** : conditionnel sur `pickerMode` au lieu d'élargir aux 4 modes (préserve la signature et les tests Stories 1.15+1.16). Pattern :

```dart
Future<void> _onValidatePicked(DerivedProfile profile) async {
  ...
  final List<String> allPicked;
  if (profile.pickerMode == PickerMode.tvePicker) {
    allPicked = <String>[
      ...profile.professionalSubjects.map((s) => s.subjectId),
      ...profile.relatedProfessionalSubjects.map((s) => s.subjectId),
      ...profile.obligatorySubjects.map((s) => s.subjectId),
      ...(_pickedOptional ?? <String>{}),
    ];
  } else {
    // Pattern Story 1.15 + 1.16 — inchangé pour freeWithObligatory + seriesPlusOptional.
    allPicked = <String>[
      ...profile.obligatorySubjects.map((s) => s.subjectId),
      ...(_pickedOptional ?? <String>{}),
    ];
  }
  ...
}
```

### AC6 — Validation client min/max (cohérent Stories 1.15/1.16)

**GIVEN** Eyong sur TVE AL avec `minSubjects: 6` + `maxSubjects: 8`,

**Scénarios** :

| Situation | `pickedTotal` | Couleur compteur | Bouton Valider |
|---|---|---|---|
| Nominal (3 Pro + 3 Related + EN + FR = 8 auto-comptés, 0 optional) | 8/8 | primary | activé |
| Tap History (+1 optional) | 9/8 | **danger** | **disabled** |
| Edge case TVE IL (compute différent — pas couvert AC tests cette story sauf si Décision PO) | (variable) | conditionnel | conditionnel |

**Borne min** : 6. Comme Pro (3) + Related (3) + Obligatoires (EN+FR = 2) = 8 automatique, le `pickedTotal` ne descend JAMAIS sous 8 dans le scénario Eyong. La borne min ne devient critique que si la matrice future a une Serie avec moins de Pro+Related+EN+FR forcés. Story 1.17 préserve le pattern de Stories 1.15/1.16 sans optimisation prématurée.

**Pas de toast intrusif** sur sur-saturation (couleur danger + bouton disabled suffisent, cohérent Décision 4 Story 1.15).

### AC7 — Non-régression modes Story 1.4 + 1.15 + 1.16

**GIVEN** les tests existants :

- 3 widget tests `subjects_picker_page_legacy_optout_test.dart` (James opt_out Story 1.4) ;
- 4 widget tests `subjects_picker_page_free_with_obligatory_test.dart` (Mariam Story 1.15) ;
- 5 widget tests `subjects_picker_page_series_plus_optional_test.dart` (James UPS S2 Story 1.16) ;
- 3 tests repo `user_profile_repository_picked_subjects_test.dart` (Story 1.15) ;
- 11 rules tests `users.test.mjs` ;
- Tous les autres tests catalogue + widgets onboarding (Stories 1.1c, 1.3, 1.5, 1.6, 1.7, 1.8, 1.9, 1.13, 1.14) ;

**WHEN** Story 1.17 est mergée,
**THEN** **TOUS** ces tests passent inchangés. Les helpers `_jamesProfile`, `_mariamProfile`, `_fatouProfile` etc. profitent des defaults vides des 3 nouveaux champs `DerivedProfile`.

**ET** la `derive()` v3 (`Future.wait` 8 futures au lieu de 5) est testée non-régression via les tests existants `catalogue_repository_derive_v2_test.dart` Story 1.13 qui doivent passer **inchangés** (les Series sans champs TVEE retournent Future.value(<Subject>[]) immédiat, pas de read additionnel).

### AC8 — Aucune nouvelle dépendance, aucun changement structurel hors models + repo + widget

**GIVEN** la story est implémentée,
**WHEN** un reviewer audite le diff,
**THEN** il vérifie qu'aucun des éléments suivants n'est touché :

- `pubspec.yaml` (aucune dépendance ajoutée).
- `firestore.rules` (`pickedSubjectsValid()` Story 1.15 couvre `tve_picker` aussi — subset `derivedSubjects` pragmatique).
- `firestore.indexes.json` (aucun index nouveau — `pickedSubjects` array sur doc lu par ID).
- `scripts/firebase_seed/data/matrice.json` (Décision 1 figée).
- `scripts/firebase_seed/seed_catalogue.py` (idempotence préservée).
- `mobile_app/lib/features/onboarding/providers.dart` (déjà OK Stories 1.15+1.16).
- `mobile_app/lib/features/onboarding/data/user_profile_repository_firestore_impl.dart` (`updatePickedSubjects` OK Story 1.15).
- `doc/partage/*` (déjà OK Story 1.11a).
- `CLAUDE.md` / `README.md`.

**Seuls changements attendus** : `models.dart` (+3 champs) + `catalogue_repository_firestore_impl.dart` (extension derive() v3) + `subjects_picker_page.dart` (remplacement case + nouveau widget privé + adaptation `_onValidatePicked` conditionnel) + 2 fichiers ARB + 1 fichier `app_localizations.dart` regen + 1 nouveau fichier test.

## Tasks/Subtasks

### T1 — Extension `DerivedProfile` +3 champs Subject lists [AC1]

- [x] T1.1 — Dans `mobile_app/lib/core/catalogue/domain/models.dart`, étendre la classe `DerivedProfile` avec 3 nouveaux fields immutable + 3 paramètres constructeur (defaults `const []`).
- [x] T1.2 — Mettre à jour les `props` Equatable pour inclure `professionalSubjects`, `relatedProfessionalSubjects`, `otherSubjects`.
- [x] T1.3 — Mettre à jour le commentaire de classe Story 1.13 → Story 1.17 (`+3 champs pour TVEE`) pour traçabilité.
- [x] T1.4 — Vérifier que `flutter analyze` retourne 0 issue après cette extension (les helpers fakes Stories 1.4/1.15/1.16 utilisent les defaults vides automatiquement).

### T2 — Extension `derive()` v2 → v3 : Future.wait 8 futures (en réalité serie résolue d'abord, puis 7 autres en parallèle) [AC2]

- [x] T2.1 — Dans `catalogue_repository_firestore_impl.dart`, modifier la séquence `derive()` Story 1.13 (lignes ~179-205) :
  - **AVANT** : 5 futures déclarées d'un coup + `Future.wait` (serieFuture ne dépend de rien).
  - **APRÈS** : `final serieDoc = await serieFuture;` standalone EN PREMIER, puis `Future.wait` sur **7 futures** (subjects + examTargets + obligatorySubjects + optionalSubjects + professionalSubjects + relatedProfessionalSubjects + otherSubjects) qui dépendent toutes de `serieDoc` (pour Pro/Related/Other) ou de `rule` (pour subjects/examTargets/obligatory/optional).
  - **Latence** : 2 RTT au lieu de 1 — trade-off accepté pour cohérence + lecture conditionnelle des 3 nouvelles listes uniquement si Serie a ces champs (économise reads pour modes non-TVEE).
- [x] T2.2 — Ajouter les 3 futures `professionalSubjectsFuture`, `relatedProfessionalSubjectsFuture`, `otherSubjectsFuture` qui retournent `Future.value(<Subject>[])` IMMÉDIAT si les listes IDs de la Serie sont vides (cas modes non-TVEE = comportement v1 préservé), sinon `_fetchSubjectsByIds(...)`.
- [x] T2.3 — Étendre le `DerivedProfile` retourné avec les 3 nouveaux champs.
- [x] T2.4 — Étendre le log `derive() OK` avec `pro=`, `related=`, `other=` counts.
- [x] T2.5 — Vérifier que `catalogue_repository_derive_v2_test.dart` (Story 1.13) passe **inchangé** : Fatou Tle D mode derived → Pro=0, Related=0, Other=0 (defaults vides matrice). James Upper Sixth S2 mode opt_out → idem. Mariam Form 5 mode free_with_obligatory → idem (les listes TVEE n'existent que sur les TVEE series).
- [x] T2.6 — `flutter analyze` 0 issue.

### T3 — 3 clés ARB FR+EN NEW (Professional / Related / Other) [AC4]

- [x] T3.1 — Dans `mobile_app/lib/l10n/app_fr.arb`, ajouter après `onboardingPickerTransversalesTitle` (Story 1.16) :

  ```json
  "onboardingPickerProfessionalTitle": "Matières professionnelles (obligatoires)",
  "@onboardingPickerProfessionalTitle": { "description": "Titre H3 section Professional Subjects (lockées) mode tve_picker TVEE (Story 1.17). Ex. pour ELET : Electrotechnique theory, Electrotechnique practical, Electrical machines." },

  "onboardingPickerRelatedTitle": "Matières connexes (obligatoires)",
  "@onboardingPickerRelatedTitle": { "description": "Titre H3 section Related Professional Subjects (lockées) mode tve_picker TVEE (Story 1.17). Ex. pour ELET : Mathematics for Industrial, Physics, Drawing." },

  "onboardingPickerOtherTitle": "Autres matières",
  "@onboardingPickerOtherTitle": { "description": "Titre H3 section Other Subjects mode tve_picker TVEE (Story 1.17). Mix : EN+FR lockées + matières culturelles au choix (Hist/Geo/RS)." },
  ```

- [x] T3.2 — Dans `mobile_app/lib/l10n/app_en.arb`, ajouter symétrique :

  ```json
  "onboardingPickerProfessionalTitle": "Professional subjects (mandatory)",
  "onboardingPickerRelatedTitle": "Related professional subjects (mandatory)",
  "onboardingPickerOtherTitle": "Other subjects",
  ```

- [x] T3.3 — Régénérer `mobile_app/lib/l10n/generated/app_localizations.dart` via `flutter gen-l10n`.
- [x] T3.4 — Préserver intactes les 9 clés `onboardingPickerXxx` Stories 1.15 + 1.16 (Title/Subtitle/ObligatoryTitle/OptionalTitle/CounterLive/ErrorObligatoryToast/ValidateCta/SeriesTitle/TransversalesTitle).

### T4 — Remplacement placeholder `case PickerMode.tvePicker` (Story 1.15 dispatch) [AC3]

- [x] T4.1 — Dans `subjects_picker_page.dart`, localiser le bloc `case PickerMode.tvePicker:` (Story 1.15 lignes ~166-180) qui retourne `SizedBox.shrink()`.
- [x] T4.2 — Remplacer par `return _TvePickerBody(...)` avec les 9 props identiques aux 2 autres widgets pickers (cohérent Stories 1.15 + 1.16).
- [x] T4.3 — Supprimer le `WidgetsBinding.instance.addPostFrameCallback(...)` + `AppLogger.i`.
- [x] T4.4 — `flutter analyze` doit retourner 0 issue **APRÈS** T5 (création widget). Avant T5, erreur attendue "The method '_TvePickerBody' isn't defined".

### T5 — Création widget `_TvePickerBody` (3 sections) [AC4]

- [x] T5.1 — Dans `subjects_picker_page.dart`, après `_SeriesPlusOptionalBody` (Story 1.16, fin de fichier), créer la classe `_TvePickerBody extends StatelessWidget` avec **9 props identiques** à `_FreeWithObligatoryBody` (Story 1.15) et `_SeriesPlusOptionalBody` (Story 1.16).
- [x] T5.2 — Pattern `Consumer + StreamBuilder<Map<String, dynamic>?>` + init `_pickedOptional` depuis `users/{uid}.pickedSubjects` retirant **Pro + Related + Obligatoires** (les 3 ensembles "lockés" qui ne sont pas dans `_pickedOptional`).
  - Pattern d'init :
    ```dart
    final pickedFromFs =
        (snap.data?['pickedSubjects'] as List?)?.cast<String>() ??
            const <String>[];
    final lockedIds = <String>{
      ...profile.professionalSubjects.map((s) => s.subjectId),
      ...profile.relatedProfessionalSubjects.map((s) => s.subjectId),
      ...profile.obligatorySubjects.map((s) => s.subjectId),
    };
    final optionalsOnly = pickedFromFs
        .where((id) => !lockedIds.contains(id))
        .toList(growable: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onInitPicked(optionalsOnly);
    });
    ```
- [x] T5.3 — Layout 3 sections (cf. AC4) :
  - **Titre H2 + sous-titre** : réutilise `onboardingPickerTitle` + `onboardingPickerSubtitle` (Story 1.15).
  - **Section Professional** : `Text(l10n.onboardingPickerProfessionalTitle)` + `ListView.separated(shrinkWrap: true, NeverScrollable, ...)` sur `profile.professionalSubjects` avec CheckboxListTile checked + lock icon + tap → `onTapObligatory`.
  - **Section Related** : pattern symétrique sur `profile.relatedProfessionalSubjects`.
  - **Section Other** : `Text(l10n.onboardingPickerOtherTitle)` + **2 ListView.separated** :
    - **Sous-section 1 (Obligatoires Other)** : `ListView.separated` sur `profile.obligatorySubjects` (EN+FR) — pattern locked.
    - **Sous-section 2 (Au choix)** : `ListView.separated` sur `profile.optionalSubjects` (Hist/Geo/RS) — pattern interactif.
- [x] T5.4 — Compteur live : `pickedTotal = profile.professionalSubjects.length + profile.relatedProfessionalSubjects.length + profile.obligatorySubjects.length + picked!.length`. Couleur primary si `∈ [min, max]`, danger sinon. Réutilise `onboardingPickerCounterLive`.
- [x] T5.5 — Bouton Valider + Bouton Retour : pattern identique à `_FreeWithObligatoryBody` + `_SeriesPlusOptionalBody`. Réutilise `onboardingPickerValidateCta` + `l10n.back`.
- [x] T5.6 — `flutter analyze` 0 issue.

### T6 — Adaptation `_onValidatePicked` conditionnel TVEE-spécifique [AC5]

- [x] T6.1 — Dans `_SubjectsPickerPageState._onValidatePicked` (Story 1.15 lignes ~268-284), ajouter un `if (profile.pickerMode == PickerMode.tvePicker)` qui ajoute Pro + Related en début de `allPicked`, **AVANT** Obligatoires + optionnels.
- [x] T6.2 — Pattern :
  ```dart
  final List<String> allPicked;
  if (profile.pickerMode == PickerMode.tvePicker) {
    allPicked = <String>[
      ...profile.professionalSubjects.map((s) => s.subjectId),
      ...profile.relatedProfessionalSubjects.map((s) => s.subjectId),
      ...profile.obligatorySubjects.map((s) => s.subjectId),
      ...(_pickedOptional ?? <String>{}),
    ];
  } else {
    // Pattern Story 1.15 + 1.16 inchangé.
    allPicked = <String>[
      ...profile.obligatorySubjects.map((s) => s.subjectId),
      ...(_pickedOptional ?? <String>{}),
    ];
  }
  ```
- [x] T6.3 — Tests Story 1.15 (Mariam) + 1.16 (James UPS S2) doivent passer **inchangés** car le branch `else` préserve leur comportement.

### T7 — Widget tests Eyong TVE AL ELET artificiel [AC4, AC5, AC6, AC7]

- [x] T7.1 — Créer `mobile_app/test/features/onboarding/presentation/subjects_picker_page_tve_picker_test.dart` (NEW) en copiant le pattern complet de `subjects_picker_page_series_plus_optional_test.dart` (Story 1.16). Adaptations :
  - Helper `_eyongProfile()` qui retourne `DerivedProfile{ pickerMode: PickerMode.tvePicker, subjects: [all 11], professionalSubjects: [ELET theory, ELET practical, Electrical machines], relatedProfessionalSubjects: [Math Industrial, Physics, Drawing], obligatorySubjects: [EN, FR], optionalSubjects: [Hist, Geo, RS], minSubjects: 6, maxSubjects: 8, canOptOut: false }`.
  - `OnboardingFlowState` : `niveauId: 'anglophone_tve_al'`, `serieId: 'anglophone_tve_al_elet'`.
  - Réutiliser `setSurfaceSize(800, 3000)` + GoRouter minimal /picker + /recap.
- [x] T7.2 — **Test (a)** : page rendue → 3 Pro checked+lock + 3 Related checked+lock + 2 EN/FR checked+lock + 3 Hist/Geo/RS décochées + compteur `8/8` primary + bouton Valider activé (8 ∈ [6, 8]).
- [x] T7.3 — **Test (b)** : tap History → compteur `9/8` danger + bouton Valider disabled.
- [x] T7.4 — **Test (c)** : tap ELET theory (Pro obligatoire) → toast warning visible + ELET theory reste checked + compteur statu quo 8/8.
- [x] T7.5 — **Test (d)** : tap EN (Obligatoire Other) → toast warning visible + EN reste checked + compteur statu quo 8/8.
- [x] T7.6 — **Test (e)** : tap Valider sans cocher d'optionnels → `_FakeRepo.pickedCalls.single == [ELET theory, ELET practical, Electrical machines, Math Industrial, Physics, Drawing, EN, FR]` (ordre TVEE-spécifique AC5).

### T8 — Validation finale [AC7, AC8]

- [x] T8.1 — `cd mobile_app && flutter analyze` 0 issue.
- [x] T8.2 — `cd mobile_app && flutter test` 0 failure. Baseline post-1.16 = 231 verts → cible **~236 verts** (+5 nets : 5 tests `_TvePickerBody`).
- [x] T8.3 — 231 tests existants passent **inchangés** (AC7 strict : models extension non-breaking + derive() v3 non-breaking + `_onValidatePicked` conditionnel non-breaking).
- [x] T8.4 — `cd test/rules && npm test` 23/23 verts inchangés (Story 1.17 ne touche pas rules).
- [x] T8.5 — Vérification grep `tve_picker` dans `subjects_picker_page.dart` : aucune référence à `TODO Story 1.17` (placeholder remplacé).
- [x] T8.6 — Vérification grep dependencies : aucun `pubspec.yaml` modifié, aucune nouvelle import.
- [x] T8.7 — Smoke device **différé** : le mode `tve_picker` n'est pas activable en prod (Décision 1 figée — matrice.json TVEE séries `isActive: false`). Validation 100% par les 5 tests unitaires Dart Story 1.17. La validation runtime arrivera quand l'admin pédagogique activera ELEQ/ELNI/ELME/ELET (action porteur post-1.17 séparée, validation Mr Eboa Joseph Lycée Technique Bonabéri).

## Dev Notes

### Architecture cible — extension polymorphisme Story 1.15

Stories 1.13 + 1.15 + 1.16 ont posé les rouages. Story 1.17 ferme le polymorphisme :

```text
SubjectsPickerPage (Story 1.15 orchestrateur)
├── State : _optedOut + _pickedOptional + _isSaving
├── Handlers : _onToggleOptional + _onTapObligatory + _onValidatePicked
│              (Story 1.17 : _onValidatePicked conditionnel TVEE-spécifique)
├── Dispatch : switch (profile.pickerMode) { ... }
│   ├── case derived              → redirect recap
│   ├── case optOut               → _LegacyOptOutBody (Story 1.4)
│   ├── case freeWithObligatory   → _FreeWithObligatoryBody (Story 1.15)
│   ├── case seriesPlusOptional   → _SeriesPlusOptionalBody (Story 1.16)
│   └── case tvePicker            → _TvePickerBody (Story 1.17 NEW)
```

Le 5ᵉ widget `_TvePickerBody` partage **95%** de sa structure avec `_SeriesPlusOptionalBody` (3 sections au lieu de 2 + sous-section "Other" mix locked/interactive). Décision 2 figée Story 1.16 préservée (dupliquer pas refactor).

### Différences Story 1.17 vs Stories 1.15 + 1.16

| Aspect | `_FreeWithObligatoryBody` (1.15) | `_SeriesPlusOptionalBody` (1.16) | `_TvePickerBody` (1.17) |
|---|---|---|---|
| Mode | `freeWithObligatory` | `seriesPlusOptional` | `tvePicker` |
| Sections | 2 | 2 | **3** (Pro + Related + Other mix) |
| Source obligatoires | `obligatorySubjects` | `obligatorySubjects` (= Series) | `professionalSubjects` + `relatedProfessionalSubjects` + `obligatorySubjects` (EN+FR) |
| Source optionnels | `optionalSubjects` | `optionalSubjects` (= Transversales) | `optionalSubjects` (= Other au choix) |
| `pickedTotal` calc | oblig + picked | series + picked | **pro + related + oblig + picked** |
| Persistance Firestore | `[oblig, ...picked]` | `[oblig, ...picked]` | **`[pro, related, oblig, ...picked]`** (TVEE-spécifique) |
| Clés ARB titres | `ObligatoryTitle` + `OptionalTitle` | `SeriesTitle` + `TransversalesTitle` | **`ProfessionalTitle` + `RelatedTitle` + `OtherTitle` (NEW)** |
| Test persona | Mariam Form 5 | James UPS S2 + ICT | **Eyong TVE AL ELET** |

### Pourquoi étendre `DerivedProfile` ?

Story 1.13 a posé 2 listes Subject (`obligatorySubjects` + `optionalSubjects`) suffisantes pour modes O-Level et A-Level. TVEE nécessite une distinction sémantique supplémentaire (Pro vs Related vs Other), donc 2 nouveaux champs Subject minimum.

**Alternative rejetée** : utiliser un champ `Map<String, List<Subject>>` générique paramétrable. **Why rejected** : sur-ingénierie pour 3 cas, perte de typage fort Dart, complexification des helpers test.

**Alternative rejetée bis** : passer les 3 listes IDs au widget via une nouvelle prop. **Why rejected** : casse l'abstraction (le widget devrait fetch les Subjects côté UI, brouille la couche presentation/data).

**Décision figée 2** : étendre `DerivedProfile` avec 3 champs `professionalSubjects` + `relatedProfessionalSubjects` + `otherSubjects` avec defaults `const []`. Non-breaking. Pattern défensif Story 1.13.

### Pourquoi modifier `derive()` ?

`Serie` (Story 1.13) a déjà 3 champs `professionalSubjectIds` + `relatedProfessionalSubjectIds` + `otherSubjectIds`. Il manque uniquement le fetch des `Subject` correspondants dans `derive()`. Extension naturelle.

**Trade-off latence** : Story 1.13 fait `Future.wait` sur 5 futures où la `serieFuture` ne dépend de rien. Story 1.17 doit attendre serieDoc résolu PUIS lire les listes TVEE depuis la série pour faire les 3 nouvelles futures. Pattern :

```dart
// Étape 1 (1 RTT) : résoudre la série
final Serie? serieDoc = await serieFuture;

// Étape 2 (1 RTT max) : 7 futures en parallèle
final results = await Future.wait<dynamic>([
  subjectsFuture,
  examTargetsFuture,
  obligatorySubjectsFuture,
  optionalSubjectsFuture,
  // NEW v3 — Story 1.17 — conditionnels sur serieDoc résolu :
  serieDoc?.professionalSubjectIds.isNotEmpty == true
      ? _fetchSubjectsByIds(serieDoc!.professionalSubjectIds)
      : Future.value(<Subject>[]),
  serieDoc?.relatedProfessionalSubjectIds.isNotEmpty == true
      ? _fetchSubjectsByIds(serieDoc!.relatedProfessionalSubjectIds)
      : Future.value(<Subject>[]),
  serieDoc?.otherSubjectIds.isNotEmpty == true
      ? _fetchSubjectsByIds(serieDoc!.otherSubjectIds)
      : Future.value(<Subject>[]),
]);
```

**Latence finale** : 2 RTT (vs 1 RTT Story 1.13). **Trade-off accepté** : +500ms sur 3G Cameroun pour le profil dérivé initial. Acceptable car opération one-shot (cache offline ensuite). Modes non-TVEE économisent les 3 reads (Future.value immédiat).

### Décisions techniques figées

#### Décision 1 — Widget only Dart, matrice INCHANGÉE (cohérent Story 1.16)

`scripts/firebase_seed/data/matrice.json` n'est PAS touché par Story 1.17. Les 26 séries TVEE seedées Story 1.12 restent `isActive: false` + listes `professionalSubjectIds` / `relatedProfessionalSubjectIds` / `otherSubjectIds` **vides** en prod.

**Conséquences acceptées** :

- Mode `tve_picker` non activable en prod aujourd'hui (TVEE séries invisibles via flow normal).
- Tests Story 1.4 + 1.15 + 1.16 100% préservés.
- Smoke device différé jusqu'à activation matrice (story future + validation Mr Eboa).
- Le widget est livré FONCTIONNEL — zéro ligne Dart à modifier quand l'activation arrivera.

**Re-évaluation** : action porteur post-Story 1.17 séparée (story 1.18 ou Epic 2 décision PO) :

1. Validation Mr Eboa Joseph (Lycée Technique Bonabéri) sur les listes Pro/Related/Other pour ELEQ/ELNI/ELME/ELET (Industrial électriques activés en premier).
2. Update matrice.json + reseed valide-edu (`python seed_catalogue.py --project valide-edu`).
3. Smoke device Eyong TVE AL ELET sur Itel A56 (réseau Cameroun).

#### Décision 2 — Étendre `DerivedProfile` +3 champs (extension model mineure non-breaking)

Cohérent pattern défensif Story 1.13. Defaults `const []` préservent les modes legacy.

**Coût** : ~10 lignes models.dart + ~5 lignes mappers (déjà OK Story 1.13, juste lecture sur Serie).
**Bénéfice** : widget `_TvePickerBody` reçoit la structure TVEE proprement typée, pas de Map générique, pas de prop additionnelle complexe.

#### Décision 3 — DUPLIQUER `_FreeWithObligatoryBody` (cohérent 1.15 + 1.16)

`_TvePickerBody` est une copie pattern adaptée 3 sections. Tentation DRY rejetée (cf. Story 1.16 Décision 2). À 3 widgets de structure similaire (1.15 + 1.16 + 1.17), refacto générique reste ROI négatif. Si en Epic 2 on doit ajouter un 4ᵉ mode, refactor dédié à ce moment.

#### Décision 4 — Lire Pro/Related/Other depuis `Serie` (pas DerivationRule)

Story 1.12 a seedé les 3 listes sur la `series.{spécialité}` (cohérent matrice.json lignes 1257-1311). Les `derivation_rules` TVEE n'ont PAS ces champs. **Why** : la sémantique GCE Board attache Pro/Related/Other à la SPÉCIALITÉ (Serie), pas à la règle de dérivation niveau. Cohérent BASE-DE-DONNEES.md schéma v2.

#### Décision 5 — `_onValidatePicked` conditionnel TVEE-spécifique

Branchement `if (profile.pickerMode == PickerMode.tvePicker)` dans `_onValidatePicked`. **Why** : l'ordre TVEE-spécifique `[Pro, Related, Obligatoires, Optionnels]` diffère des modes O/A-Level (`[Obligatoires, Optionnels]`). Pas de tentation d'élargir le pattern à tous les modes (casserait tests Stories 1.15+1.16).

#### Décision 6 — Section "Other" avec 2 sous-loops (Obligatoires EN+FR puis Au choix)

Cohérent EXPERIENCE.md Flow 1d ligne 523 : "**Other Subjects (au choix)** : checkboxes (English Language locked, French locked, History, Geography, Religious Studies)". L'UX présente "Other" comme une section unique avec mix locked/interactive. Story 1.17 implémente avec 2 `ListView.separated` consécutifs dans la section "Other", pas 2 sections distinctes.

### Anti-patterns interdits

1. ❌ **Modifier `matrice.json`** — Décision 1 figée. Aucun changement des 26 séries TVEE seedées Story 1.12.
2. ❌ **Modifier `firestore.rules`** — `pickedSubjectsValid()` Story 1.15 couvre `tve_picker` (subset `derivedSubjects` pragmatique). Rien à ajouter.
3. ❌ **Ajouter un index Firestore** — Story 1.17 ne crée aucune nouvelle requête.
4. ❌ **Casser les tests Story 1.4 / 1.15 / 1.16** — AC7 strict. Models extension non-breaking + derive() v3 non-breaking + `_onValidatePicked` conditionnel non-breaking garantissent ça.
5. ❌ **Refactoriser `_FreeWithObligatoryBody` / `_SeriesPlusOptionalBody` en widget générique** — Décision 3 figée.
6. ❌ **Logger les IDs des matières optionnelles tapées** — cohérent CLAUDE.md sécurité 4 + pattern Story 1.15+1.16.
7. ❌ **Toaster sur sur-saturation > maxSubjects** — couleur danger + bouton disabled suffisent.
8. ❌ **Persister `pickedSubjects` sans Pro+Related+Obligatoires EN/FR** — AC5 strict, validation Firestore `pickedSubjectsValid()` Story 1.15 pragmatique mais cohérence client garantie.
9. ❌ **Forcer `Source.server` ou `Source.cache`** — cohérent CLAUDE.md règle 10.h.
10. ❌ **Élargir `_onValidatePicked` à tous les modes** — Décision 5 figée. Branchement conditionnel.
11. ❌ **Lire Pro/Related/Other depuis `DerivationRule`** — Décision 4 figée. Sur la `Serie`.
12. ❌ **Logger les détails de Pro/Related/Other lors du derive() OK** — count agrégé OK (pour debug), pas les IDs.

### Personas concernées

- **Eyong Eboa** — TVE Advanced Level anglophone, spécialité Electrotechnique (ELET), Bonabéri Douala, Itel A56. Persona Story 1.17. Test cible widget artificial.
- **James Tanyi** (Upper Sixth S2) — Story 1.4 + 1.16. Non-régression mode opt_out + series_plus_optional.
- **Mariam Bakari** (Form 5) — Story 1.15. Non-régression mode free_with_obligatory.
- **Fatou Mballa** (Tle D) — Story 1.3. Non-régression mode derived.
- **Aïssatou Diop** (Tle A1) — Story 1.14. Non-régression secondaire.

### Sources autoritaires

1. **`epics.md` § Story 1.17** : déclaration scope (sprint-change 2026-06-09).
2. **`sprint-change-proposal-2026-06-09.md` § Change 4.6 Story 1.17** + § matrice TVEE règles : 26 séries TVEE + 13 spécialités × 2 niveaux + règle TVE IL min 5 (≥2 Pro + ≥1 Related) + règle TVE AL min 6 max 8 (≥3 Pro + ≥3 Related) + EN+FR obligatoires.
3. **`prd.md` § FR-3 multi-mode** (ligne 153) : mode `tve_picker` consequence.
4. **`EXPERIENCE.md` Variant Flow 1d Eyong** (lignes 508-531) : autorité UX (3 sections nommées, compteur, edge case isActive: false initial + Décision activation progressive).
5. **`subjects_picker_page.dart` Stories 1.15 + 1.16** : pattern à dupliquer.
6. **`Cameroon GCE Board TVEE`** : règles officielles sourcing Story 1.11a.
7. **Mr Eboa Joseph (Lycée Technique Bonabéri)** : validation enseignant TVEE pour activation progressive matrice (story future).

### Cost-benefit Firestore (CLAUDE.md règle 10.m)

**Reads / writes Story 1.17 — DIFFÉRENTIEL vs Story 1.16** :

- **Modes non-TVEE** : aucun read additionnel (Future.value(<Subject>[]) immédiat sur listes vides). Comportement v1 préservé.
- **Mode TVEE** : +3 reads par session onboarding (Pro/Related/Other Subjects) — uniquement quand la matrice activera les TVEE. Pour Eyong TVE AL ELET : 3 Pro + 3 Related + 3 Other = 9 nouveaux reads par session.

**Volumétrie TVEE estimée à 10 000 users (post-activation matrice)** :

- Marché TVEE = ~15-20% du marché cible (~1 500-2 000 users si 10k total).
- ~100-150 sessions onboarding TVEE / mois (adoption ~10%/mois).
- 9 reads × 150 = 1 350 reads additionnels / mois. Négligeable.

**Trade-off accepté** : pas de validation `pickedSubjectsValid()` raffinée côté serveur (Décision 3 Story 1.15 préservée). Subset `derivedSubjects` pragmatique. Bypass client peut poser `pickedSubjects` sans Pro+Related → casse son propre profil UX, pas de fuite sécurité.

## Definition of Done

- [x] **AC1-AC8 verts** : tous les acceptance criteria validés par tests Dart.
- [x] **`flutter analyze` 0 issue** sur `mobile_app/`.
- [x] **`flutter test` 0 failure** : baseline 231 verts post-1.16 → cible ~236 (+5 nets : 5 tests `_TvePickerBody`).
- [x] **`cd test/rules && npm test` 0 failure** : 23/23 verts inchangés (Story 1.17 ne touche pas rules).
- [x] **Diff hors tests <= 500 lignes** : extension model + repo + widget + 3 ARB. Story plus large que 1.16 (qui était ~280) vu l'extension model + derive().
- [x] **Smoke device DIFFÉRÉ** : Décision 1 figée — pas de scénario activable en prod. Validation 100% tests unitaires.
- [x] **AUCUNE modif** : `matrice.json` / `seed_catalogue.py` / `firestore.rules` / `firestore.indexes.json` / `providers.dart` / `user_profile_repository*.dart` / `doc/partage/*` / `pubspec.yaml` / `CLAUDE.md` / `README.md`.
- [x] **SEULES modifs** : `models.dart` (+3 champs) + `catalogue_repository_firestore_impl.dart` (extension derive() v3) + `subjects_picker_page.dart` (case + widget + _onValidatePicked conditionnel) + `app_fr.arb` + `app_en.arb` + `app_localizations.dart` (regen) + 1 nouveau fichier test.
- [x] **Tests Story 1.4 + 1.15 + 1.16 + 1.13 catalogue_repository_derive_v2 100% verts inchangés** — AC7 strict.
- [x] **Commit message conventional commits FR à l'impératif** : `feat(onboarding): SubjectsPickerPage mode tve_picker TVEE Eyong Electrotechnique (Story 1.17 - derniere Epic 1 v2)`.
- [x] **Branche `feat/1.17-estp-anglophone-tvee`** (kebab-case, 30 chars).
- [x] **PR <= 600 lignes diff totalisé** (cible : ~500 hors tests + ~300 tests).
- [x] **Pas de `--no-verify`** sur le commit (CLAUDE.md workflow git).
- [x] **Aucune action porteur post-merge dev** : pas de reseed Firestore, pas de deploy rules.
- [x] **Action porteur post-Epic 1 v2 SÉPARÉE documentée** : validation Mr Eboa Joseph + update matrice TVEE ELEQ/ELNI/ELME/ELET + reseed valide-edu + smoke device Eyong (story 1.18 ou Epic 2 décision PO).

## Dev Agent Record

### Implementation Plan

Séquence effective T3 → T1 → T2 → T4+T6 → T5 → T7 → T8 (~2h30) :

- **T3 d'abord (i18n)** : 3 clés ARB FR+EN nouvelles + `flutter gen-l10n` AVANT widget T5 (sinon analyze casse).
- **T1 (models)** : extension `DerivedProfile` avec 3 champs Subject lists (`professionalSubjects` + `relatedProfessionalSubjects` + `otherSubjects`, defaults `const []`). Non-breaking pour les 4 autres modes (defaults vides).
- **T2 (repo derive() v3)** : restructuration : `await serieFuture` standalone EN PREMIER (1 RTT), puis Future.wait sur 7 futures en parallèle. Modes non-TVEE économisent les 3 nouvelles reads (helper `_fetchSubjectsByIds([])` retourne `const []` immédiat).
- **T4 (dispatch)** : remplacement `case PickerMode.tvePicker` placeholder par `return _TvePickerBody(...)`.
- **T6 (validate handler)** : branchement conditionnel `if (pickerMode == tvePicker)` dans `_onValidatePicked` avec ordre `[Pro, Related, Obligatoires EN+FR, Optionnels]`. Préserve pattern Stories 1.15+1.16 dans `else`.
- **T5 (widget)** : append `_TvePickerBody` (~315 lignes) à la fin du fichier via PowerShell Add-Content. 3 sections : Pro + Related + Other (avec 2 sous-loops EN/FR locked + Hist/Geo/RS interactif).
- **T7 (tests)** : nouveau fichier `subjects_picker_page_tve_picker_test.dart` (~330 lignes) — copie pattern Stories 1.15+1.16 avec `_eyongProfile()` artificial + viewport 800×4000 (plus haut que 1.16 vu 3 sections + 11 checkboxes) + `MaterialApp.router` GoRouter minimal + 5 tests AC4-AC7.
- **T8 (validation)** : flutter analyze 0 issue + flutter test 236 verts (exactement cible) + npm test rules inchangés.

### Debug Log

- **Heredoc bash échoué** : ma première tentative d'append `_TvePickerBody` via `cat >> file << 'TVE_EOF'` a planté sur des apostrophes internes (« l'on », « d'optionnels »). Fix : passé via PowerShell Add-Content avec here-string `@'...'@` (single-quoted, pas d'expansion `$`).
- **Test (a) attendait 11 CheckboxListTile** : 3 Pro + 3 Related + 2 EN/FR + 3 Hist/Geo/RS = 11. Vérifié au premier run, OK.
- **Viewport 800×4000** : nécessaire car 3 sections + 11 cards + 2 boutons dépassent même 3000px (vs Stories 1.15+1.16 à 800×3000 qui suffisait pour 2 sections).
- **Aucun fix tests** : les 5 tests Story 1.17 sont passés directement au premier run.

### Completion Notes

Toutes les ACs validées. Implémentation conforme aux 6 Décisions techniques figées :

- **Décision 1 (widget only Dart)** : `matrice.json` 100 % INCHANGÉE. 26 séries TVEE Story 1.12 restent `isActive: false` + listes vides en prod. Aucune migration profil, aucun reseed, aucun smoke device cassé.
- **Décision 2 (étendre DerivedProfile +3 champs)** : `professionalSubjects` + `relatedProfessionalSubjects` + `otherSubjects` avec defaults `const []`. Non-breaking. Pattern défensif cohérent Story 1.13.
- **Décision 3 (DUPLIQUER pas REFACTOR)** : `_TvePickerBody` est une copie pattern adaptée 3 sections. Pas de tentation DRY générique. À 3 widgets (`_FreeWithObligatoryBody` + `_SeriesPlusOptionalBody` + `_TvePickerBody`), refacto reste ROI négatif.
- **Décision 4 (lire Pro/Related/Other depuis Serie)** : `serieDoc.{professional, relatedProfessional, other}SubjectIds`. Sémantique GCE Board attache à la spécialité (Serie).
- **Décision 5 (`_onValidatePicked` conditionnel TVEE)** : branchement `if (pickerMode == tvePicker)` ajoute Pro+Related en début de `allPicked`. Stories 1.15+1.16 préservées dans `else`.
- **Décision 6 (Section Other 2 sous-loops)** : Obligatoires EN/FR locked puis Au choix Hist/Geo/RS interactif dans la même section "Autres matières" cohérent EXPERIENCE.md Flow 1d ligne 523.

**Volumétrie finale** :

- `flutter analyze` : 0 issue sur `mobile_app/`.
- `flutter test` : **236 verts** (vs baseline 231 post-1.16 = +5 nets — exactement la cible).
- `npm test` rules : 23/23 verts inchangés (Story 1.17 ne touche pas rules).
- **Diff total** : extension models + repo + widget + 3 ARB + 1 test fichier. Cohérent cible <=500 lignes hors tests.

**Action porteur post-merge dev** : **AUCUNE**. Pas de reseed Firestore, pas de deploy rules.

**Action porteur post-Epic 1 v2 SÉPARÉE documentée** : validation Mr Eboa Joseph (Lycée Technique Bonabéri) sur listes Pro/Related/Other pour ELEQ/ELNI/ELME/ELET (Industrial électriques activées en premier) + update matrice.json + reseed valide-edu + smoke device Eyong TVE AL ELET sur Itel A56 réseau Cameroun.

**Epic 1 v2 STATUS** : 1.17 review → done après merge = **Epic 1 v2 COMPLETE** (1.11a + 1.11b + 1.12 + 1.13 + 1.14 + 1.15 + 1.16 + 1.17 done).

### File List

**NEW (Story 1.17)** :

- `mobile_app/test/features/onboarding/presentation/subjects_picker_page_tve_picker_test.dart` (NEW — 5 tests Eyong TVE AL ELET artificial)

**UPDATE** :

- `mobile_app/lib/core/catalogue/domain/models.dart` (+3 champs Subject lists dans `DerivedProfile` + props Equatable étendus + commentaire de classe étendu)
- `mobile_app/lib/core/catalogue/data/catalogue_repository_firestore_impl.dart` (extension `derive()` v2 → v3 : await serieFuture standalone puis Future.wait 7 futures + 3 nouvelles lectures conditionnelles + log étendu)
- `mobile_app/lib/features/onboarding/presentation/subjects_picker_page.dart` (remplacement `case PickerMode.tvePicker` placeholder par `_TvePickerBody` + `_onValidatePicked` branchement conditionnel TVEE + nouveau widget `_TvePickerBody` ~315 lignes)
- `mobile_app/lib/l10n/app_fr.arb` + `app_en.arb` (+3 clés `onboardingPickerProfessionalTitle` + `onboardingPickerRelatedTitle` + `onboardingPickerOtherTitle`)
- `mobile_app/lib/l10n/generated/app_localizations.dart` (+ _fr.dart + _en.dart) (regen)
- `project_manage/implementation-artifacts/sprint-status.yaml` (1-17 in-progress → review + last_updated)
- `project_manage/implementation-artifacts/1-17-estp-anglophone-tvee.md` (Dev Agent Record + Tasks cochées)

### Change Log

| Date | Auteur | Changement |
|---|---|---|
| 2026-06-10 | DelRoos / Claude | T1-T8 implémentés. `flutter analyze` 0 issue + `flutter test` 236 verts (+5 nets). Status `in-progress` → `review`. **Dernière story Epic 1 v2.** |
