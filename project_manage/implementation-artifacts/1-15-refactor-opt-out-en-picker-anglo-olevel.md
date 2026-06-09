---
story_id: 1.15
title: SubjectsOptOutPage → SubjectsPickerPage polymorphe (modes derived / opt_out legacy / free_with_obligatory O-Level — Mariam Form 5)
epic: 1
phase: P1 extension v2 (sprint change 2026-06-09)
status: ready-for-dev
created: 2026-06-09
baseline_commit: f9102f4  # merge PR #76 (cloture 1.14) — main aligné post Stories 1.11a/1.11b/1.12/1.13/1.14 done
estimation: M (~5h)
sprint_change: sprint-change-proposal-2026-06-09.md
dependencies:
  - 1.4 — done (SubjectsOptOutPage v1 + route /onboarding/profile/opt-out + UserProfileRepository.updateOptedOutSubjects + firestore.rules optedOutSubjects ⊂ derivedSubjects + tests legacy à préserver)
  - 1.11a — done (BASE-DE-DONNEES.md `users/{uid}.pickedSubjects` documenté + ALGORITHMES.md modes panier + ADR-016 Décision 4 validation client+serveur)
  - 1.11b — done (UX EXPERIENCE.md Flow 1b Mariam Form 5 panier O-Level documenté + PRD FR-3 multi-mode 5 valeurs)
  - 1.12 — done (matrice.json v2 + reseed valide-edu : Form 5 anglo a `pickerMode: 'free_with_obligatory'` + `obligatorySubjectIds: [anglophone_english_lang, anglophone_french, anglophone_math]` + `optionalSubjectIds: [8 matières au choix]` + `minSubjects: 6` + `maxSubjects: 11`)
  - 1.13 — done (PickerMode enum 5 valeurs + DerivedProfile.pickerMode/obligatorySubjects/optionalSubjects/min/max + Serie/DerivationRule enrichis + derive() v2)
blocks:
  - 1.16 — A-Level transversales (mode `series_plus_optional` réutilisera SubjectsPickerPage avec section "Series lockées" + "Transversales optionnelles" — refactor pose les fondations)
  - 1.17 — TVEE (mode `tve_picker` réutilisera SubjectsPickerPage avec sections "Professional / Related / Other" — refactor pose les fondations)
sourceArtifacts:
  - project_manage/planning-artifacts/epics.md § Story 1.15 + table dependency graph
  - project_manage/planning-artifacts/sprint-change-proposal-2026-06-09.md § Change 4.6 (Story 1.15)
  - project_manage/planning-artifacts/prds/prd-valide-mvp-2026-06-03/prd.md § FR-3 (lignes 143-156, mode `free_with_obligatory` consequence ligne 151)
  - project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/EXPERIENCE.md § Variant Flow 1b Mariam Form 5 (lignes 470-488)
  - doc/partage/BASE-DE-DONNEES.md § users/{uid}.pickedSubjects (lignes 71-76) + § Validation panier polymorphe (lignes 232-250) + § Patterns d'update users (ligne 742)
  - doc/partage/ALGORITHMES.md § 1 Modes panier (table 5 modes x 5 colonnes)
  - mobile_app/lib/core/catalogue/domain/models.dart § PickerMode + DerivedProfile v2 (Story 1.13)
  - mobile_app/lib/features/onboarding/presentation/subjects_opt_out_page.dart (à refactor — Story 1.4)
  - mobile_app/lib/features/onboarding/providers.dart § effectiveDerivedSubjectsProvider (Story 1.4 ligne 466 — à étendre pickedSubjects)
  - mobile_app/lib/features/onboarding/domain/user_profile_repository.dart (interface — Story 1.4 expose updateOptedOutSubjects, Story 1.15 ajoute updatePickedSubjects)
  - mobile_app/lib/features/onboarding/data/user_profile_repository_firestore_impl.dart (impl à étendre)
  - mobile_app/lib/core/routing/app_router.dart § route /onboarding/profile/opt-out (à renommer /picker)
  - mobile_app/lib/features/onboarding/presentation/profile_recap_page.dart § lien "Retirer une matière" (à renommer + nav)
  - firestore.rules (racine — ajouter `pickedSubjectsValid()` + autoriser pickedSubjects en update)
  - test/rules/users.test.mjs (étendre tests update users/{uid})
  - mobile_app/lib/l10n/app_fr.arb + app_en.arb (nouvelles clés panier)
---

# Story 1.15 — SubjectsOptOutPage → SubjectsPickerPage polymorphe (modes derived / opt_out / free_with_obligatory — Mariam Form 5)

Status: **ready-for-dev**

## Objectif

Livrer la **brique pivot du panier polymorphe v2** : refactorer `SubjectsOptOutPage` (Story 1.4) en `SubjectsPickerPage` dispatché par `DerivedProfile.pickerMode` (Story 1.13). Cette story introduit le mode `free_with_obligatory` pour les élèves anglophones O-Level (Form 3-5), conserve à 100 % le mode `opt_out` legacy (Story 1.4 Lower/Upper Sixth) et pose les fondations widget pour les modes `series_plus_optional` (Story 1.16) et `tve_picker` (Story 1.17).

**Pourquoi maintenant** : la matrice v2 est seedée (Story 1.12), les models Dart sont enrichis (Story 1.13), le PRD FR-3 + EXPERIENCE.md Flow 1b sont à jour (Story 1.11b). Sans Story 1.15, Mariam Bakari (Form 5, anglophone, Limbé) qui ouvre l'app post-1.13 voit aujourd'hui sa liste dérivée affichée sans validation panier — alors que la règle officielle GCE Board impose `min 6, max 11, EN+FR+Math obligatoires`. Couvre 100 % du marché anglophone O-Level (Form 3, 4, 5) qui représente environ 35 % du marché cible camerounais.

**Critère de fin** :

- Mariam (anglophone, Form 5, anonyme) → flow profil 2 étapes (filière + niveau, pas de série) → atterrit sur `SubjectsPickerPage` mode `free_with_obligatory` :
  - 3 obligatoires (English Language + French + Mathematics) checkbox checked + cadenas Lucide
  - 8 au choix (Physics, Chemistry, Biology, Geography, History, Citizenship, Computer Science, Religion) checkbox décochées
  - Compteur live « Tu présentes 3/11 matières » → tap 5 matières → 8/11
  - Bouton « Valider mon choix » activé car X ∈ [6, 11]
- Tap obligatoire → toast erreur + log warn, pas de modification
- Tap > 11 (impossible : seul Religion atteint 12, jamais en pratique) → toast erreur + bloque
- Save → `users/{uid}.pickedSubjects = [EN, FR, Math, Phy, Chem, Bio, Geo, Hist]` posé en Firestore
- James (anglophone, Upper Sixth S2, série S2) : **non-régression** — voit le layout legacy mode `opt_out` Story 1.4 inchangé (3 checkboxes, retrait simple, persistence `optedOutSubjects`)
- Fatou (francophone, Tle D, mode `derived`) : **non-régression** — pas de page picker, redirect direct recap (Tle D `canOptOut: false` + `pickerMode: 'derived'`)

## Story

**As a** élève anglophone O-Level (Form 3, Form 4 ou Form 5),
**I want** sélectionner mes matières dans un panier respectant la règle officielle GCE Board (6-11 matières dont EN+FR+Math obligatoires),
**so that** mon dashboard, mes classements et mes recommandations correspondent exactement à ce que je présenterai à l'examen, sans pollution par des matières que je n'ai pas choisies (FR-3 mode `free_with_obligatory`).

Et : **as a** élève anglophone Upper Sixth ou Lower Sixth (mode `opt_out` legacy Story 1.4) ou francophone Tle (mode `derived`), **I want** que le refactor de la page picker ne casse rien à mon flow existant.

## Acceptance Criteria

### AC1 — Dispatch sur `DerivedProfile.pickerMode` (Story 1.13)

**GIVEN** un élève authentifié arrive sur la route `/onboarding/profile/picker` (renommée de `/opt-out`),
**WHEN** la page lit `derivedProfileProvider` et résout en `DerivedProfile`,
**THEN** elle dispatche le rendu selon `profile.pickerMode` :
- `PickerMode.derived` → redirect immédiat `/onboarding/profile/recap` + log info (cohérent avec garde existante Story 1.4 ligne 73 `if (!profile.canOptOut)` → étendre la condition).
- `PickerMode.optOut` → rendu **layout legacy** identique Story 1.4 (CheckboxListTile vertical + compteur `Tu présentes N matières sur total` + bouton Valider activé si N > 0).
- `PickerMode.freeWithObligatory` → rendu **nouveau layout 2 sections** (cf. AC2).
- `PickerMode.seriesPlusOptional` → TODO Story 1.16 : redirect recap + log info (placeholder explicite, pas de crash).
- `PickerMode.tvePicker` → TODO Story 1.17 : redirect recap + log info (placeholder explicite, pas de crash).

**ET** la route v1 `/onboarding/profile/opt-out` est renommée `/onboarding/profile/picker` dans `app_router.dart` + le lien `profile_recap_page.dart` (Story 1.3) pointe vers `/picker` (un grep `opt-out` ne doit rien retourner hors comments historiques).

### AC2 — Layout mode `free_with_obligatory` (Mariam Form 5)

**GIVEN** un profil `DerivedProfile{ pickerMode: freeWithObligatory, obligatorySubjects: [EN, FR, Math], optionalSubjects: [Phy, Chem, Bio, Geo, Hist, Citizenship, ComputerScience, Religion], minSubjects: 6, maxSubjects: 11 }`,
**WHEN** la page rend `SubjectsPickerPage`,
**THEN** elle affiche **2 sections empilées** :

1. **Section « Matières obligatoires »** (titre H3) :
   - `obligatorySubjects.length` CheckboxListTile **checked + disabled** (toggle bloqué).
   - Trailing : icône `LucideIcons.lock` couleur `AppColors.primary` taille 18.sp.
   - Tap sur une checkbox obligatoire → no-op visuel (la valeur ne change pas) **+** appel `AppToast.show(message: l10n.onboardingPickerErrorObligatoryToast, tone: ToastTone.warning)` **+** `AppLogger.w('PickerPage: tap obligatoire bloque subject=${s.subjectId}')` (jamais l'uid — CLAUDE.md sécurité 4).

2. **Section « Matières au choix »** (titre H3) :
   - `optionalSubjects.length` CheckboxListTile interactifs.
   - État initial : décochées par défaut **sauf** si `users/{uid}.pickedSubjects` non vide (cas back/édit) → cocher celles présentes dans `pickedSubjects` (modulo retrait des obligatoires qui y sont aussi).

3. **Compteur live** en bas (au-dessus des boutons) :
   - Texte ICU pluralisé `l10n.onboardingPickerCounterLive(count: pickedTotal, max: maxSubjects)` :
     - FR : `"Tu présentes {count}/{max} matières"`
     - EN : `"You take {count}/{max} subjects"`
   - `pickedTotal = obligatorySubjects.length + (optionalSubjects sélectionnées)`.
   - Couleur `AppColors.primary` si `pickedTotal ∈ [minSubjects, maxSubjects]`, `AppColors.danger` sinon.

4. **Bouton « Valider mon choix »** (`AppButton.primary`) :
   - Activé **uniquement** si `pickedTotal ∈ [minSubjects, maxSubjects]` AND `!isSaving`.
   - Disabled (grisé) si `pickedTotal < minSubjects` ou `pickedTotal > maxSubjects`.

5. **Bouton « Retour »** (`AppButton.secondary`) :
   - Toujours actif sauf pendant `isSaving`.
   - Tap → `GoRouter.of(context).go('/onboarding/profile/recap')`.

### AC3 — Validation client (panier `free_with_obligatory`)

**GIVEN** Mariam est sur `SubjectsPickerPage` mode `free_with_obligatory` avec `pickedTotal = 5` (3 oblig + 2 optionnels),
**WHEN** elle tape « Valider mon choix »,
**THEN** le bouton est disabled, donc rien ne se passe — aucun appel Firestore (cohérent avec pattern Story 1.4 ligne 206 `canSave = takingCount > 0 && !isSaving`).

**ET GIVEN** `pickedTotal = 12` (3 oblig + 9 optionnels — cas impossible avec 8 optionnels mais protection défense en profondeur),
**WHEN** Mariam tape « Valider »,
**THEN** bouton disabled + visuel compteur rouge `AppColors.danger`.

**ET GIVEN** `pickedTotal = 8` (3 oblig + 5 optionnels),
**WHEN** Mariam tape « Valider »,
**THEN** `UserProfileRepository.updatePickedSubjects([EN, FR, Math, Phy, Chem, Bio, Geo, Hist])` est appelé **avec la liste complète obligatoires + optionnels sélectionnés** (pas juste les optionnels), puis succès → `GoRouter.go('/onboarding/profile/recap')`.

### AC4 — Persistance Firestore `pickedSubjects`

**GIVEN** un appel `repo.updatePickedSubjects(['anglophone_english_lang', 'anglophone_french', 'anglophone_math', 'anglophone_physics', 'anglophone_chemistry', 'anglophone_biology', 'anglophone_geography', 'anglophone_history'])`,
**WHEN** l'impl Firestore l'exécute,
**THEN** elle fait `.update({'pickedSubjects': [...], 'updatedAt': FieldValue.serverTimestamp()})` (PATTERN OBLIGATOIRE CLAUDE.md règle 10.l : update partielle, pas `.set()` complet) sur `users/{uid}`.

**ET** retourne `Right(null)` si OK ou `Left(ProfileFailure.firestoreError(reason))` si KO (FirebaseException, network).

**ET** un log `AppLogger.i('updatePickedSubjects success count=${ids.length}')` est émis sur succès (JAMAIS les IDs détaillés — log d'opération, pas dump métier).

### AC5 — firestore.rules : `pickedSubjectsValid()` + autorisation update

**GIVEN** Mariam authentifiée pousse `users/{uid}.update({pickedSubjects: [EN, FR, Math, Phy, Chem, Bio, Geo, Hist]})`,
**WHEN** firestore.rules évalue l'update,
**THEN** la règle accepte si :
1. `request.auth.uid == uid` (existant Story 1.3 + 1.4) ;
2. `subSystem`, `language`, `filiere`, `niveau`, `serie`, `createdAt` sont **immutables** (existant Story 1.3) ;
3. **NEW** si `pickedSubjects` est dans `diff.affectedKeys`, la fonction `pickedSubjectsValid(request.resource.data)` retourne true.

**ET** la fonction `pickedSubjectsValid()` (à AJOUTER en haut du fichier, après `isOwner`) est :

```javascript
function pickedSubjectsValid(data) {
  let picked = data.get('pickedSubjects', []).toSet();
  let derived = data.derivedSubjects.toSet();
  let obligatory = data.get('obligatorySubjectIds', []).toSet();
  let optional = data.get('optionalSubjectIds', []).toSet();
  // pickedSubjects ⊂ (derivedSubjects ∪ optionalSubjectIds)
  // ET obligatorySubjectIds ⊂ pickedSubjects
  return picked.difference(derived.union(optional)).size() == 0
      && obligatory.difference(picked).size() == 0;
}
```

**ATTENTION** : la version BASE-DE-DONNEES.md ligne 238 lit `data.get('obligatorySubjectIds', [])` et `data.get('optionalSubjectIds', [])` directement sur `users/{uid}`. **MAIS** `obligatorySubjectIds` et `optionalSubjectIds` vivent sur la `derivation_rule` côté Firestore, pas sur `users/{uid}`. **Décision Story 1.15** : pour éviter une jointure (impossible en Firestore rules sans `get()` cross-doc coûteux), on **dénormalise** `obligatorySubjectIds` + `optionalSubjectIds` côté `users/{uid}` lors de `createProfile()` (Story 1.3 — à amender léger, pas dans Story 1.15 scope, voir Décision « Dénormalisation v2 » plus bas).

**Si la dénormalisation n'est PAS faite Story 1.15 (option pragmatique MVP)** : la rule `pickedSubjectsValid()` se réduit à `picked.difference(derived).size() == 0` (subset de `derivedSubjects` uniquement, l'obligatoire est garanti côté client). C'est l'option recommandée pour Story 1.15 — voir Décision plus bas.

**ET** la règle existante `optedOutSubjects ⊂ derivedSubjects` (Story 1.4 lignes 81-89) est **préservée intacte** (mode legacy).

**ET** les 3 tests `test/rules/users.test.mjs` sont ajoutés :
1. **(n)** `pickedSubjects` valide subset de `derivedSubjects` → ACCEPTED.
2. **(o)** `pickedSubjects` contient un ID hors `derivedSubjects` → REJECTED.
3. **(p)** `pickedSubjects` ne contient pas Math → REJECTED si option dénormalisée, ACCEPTED si option pragmatique (test commenté avec note explicite).

**ET** déploiement post-merge porteur : `firebase deploy --only firestore:rules --project valide-edu` (CLAUDE.md règle 9 type : règles, pas indexes — `firestore.rules` est source de vérité).

### AC6 — Non-régression mode `opt_out` (James Upper Sixth S2 — Story 1.4)

**GIVEN** James (anglophone, Upper Sixth, série S2, `pickerMode: 'opt_out'`, `canOptOut: true`),
**WHEN** il arrive sur `/onboarding/profile/picker`,
**THEN** il voit **exactement le même layout** qu'aujourd'hui Story 1.4 :
- Titre `l10n.onboardingOptOutTitle` (« Choisis tes matières »).
- Sous-titre `l10n.onboardingOptOutSubtitle` (« Décoche celles que tu ne présentes pas. »).
- 3 CheckboxListTile (Chemistry, Physics, Biology) **toutes cochées par défaut** (= toutes incluses).
- Compteur ICU `l10n.onboardingOptOutTakingCount` (« Tu présentes 3 matières sur 3 »).
- Bouton `l10n.onboardingOptOutValidateCta` (« Valider »), disabled si `takingCount == 0`.
- Persistance `users/{uid}.optedOutSubjects` via `repo.updateOptedOutSubjects(...)`.

**ET** les 3 widget tests existants `subjects_opt_out_page_test.dart` sont **renommés** `subjects_picker_page_test.dart` ou splittés en 2 fichiers (`_legacy_optout_test.dart` + `_free_with_obligatory_test.dart`), **tous verts** après refactor.

### AC7 — Non-régression mode `derived` (Fatou Tle D)

**GIVEN** Fatou (francophone, Tle, série D, `pickerMode: 'derived'`, `canOptOut: false`),
**WHEN** elle tape le lien « Retirer une matière » depuis `profile_recap_page.dart` (Story 1.3) — **SCÉNARIO IMPOSSIBLE NORMALEMENT** car le lien n'est affiché que si `canOptOut: true` (Story 1.4 AC5),
**THEN** `SubjectsPickerPage` détecte `pickerMode == derived` ET `canOptOut == false` → redirect immédiat `/onboarding/profile/recap` + `AppLogger.w('PickerPage: pickerMode=derived canOptOut=false redirect to recap')`.

**ET** dans le flow nominal Fatou, le lien n'est pas affiché du tout (AC5 Story 1.4 préservée).

**ET** les tests d'intégration `profile_recap_page_test.dart` existants (Story 1.3) **continuent de passer** sans modification (Fatou ne voit pas le lien).

## Tasks/Subtasks

### T1 — Renommer fichier + classe + route (squelette préparatoire) [AC1]

- [ ] T1.1 — Renommer `mobile_app/lib/features/onboarding/presentation/subjects_opt_out_page.dart` → `subjects_picker_page.dart` via `git mv` (préserve l'historique).
- [ ] T1.2 — Renommer classe `SubjectsOptOutPage` → `SubjectsPickerPage` + state `_SubjectsOptOutPageState` → `_SubjectsPickerPageState` (toutes occurrences).
- [ ] T1.3 — Renommer la widget privée `_OptOutBody` → `_PickerBody` (sera remaniée en T3).
- [ ] T1.4 — Mettre à jour l'import dans `mobile_app/lib/core/routing/app_router.dart` ligne 21 + le path GoRoute `/onboarding/profile/opt-out` → `/onboarding/profile/picker` ligne 135 + builder `SubjectsPickerPage`.
- [ ] T1.5 — Mettre à jour `mobile_app/lib/features/onboarding/presentation/profile_recap_page.dart` (Story 1.3 ligne ~246-255) : le lien « Retirer une matière » doit naviguer vers `/onboarding/profile/picker` au lieu de `/opt-out`. **VÉRIFIER** d'abord par grep que c'est bien la seule navigation vers cette route (pas de deep link externe).
- [ ] T1.6 — `flutter analyze` doit retourner 0 issue (sinon corriger imports manqués).
- [ ] T1.7 — `flutter test test/features/onboarding/` doit passer (renomme aussi le fichier de test correspondant T6).

### T2 — Dispatch sur `DerivedProfile.pickerMode` (mode dispatch + placeholders 1.16/1.17) [AC1, AC7]

- [ ] T2.1 — Dans `build()` de `_SubjectsPickerPageState`, après la résolution `derivedAsync.when(data: (either) => either.fold(..., (profile) => ...))`, **remplacer la garde existante** `if (!profile.canOptOut)` par un `switch (profile.pickerMode)` (pattern Dart 3 switch expression).
- [ ] T2.2 — Cas `PickerMode.derived` : redirect immédiat recap + log info `'PickerPage: pickerMode=derived redirect recap'`. Pattern : `WidgetsBinding.instance.addPostFrameCallback((_) { if (context.mounted) GoRouter.of(context).go('/onboarding/profile/recap'); }); return const SizedBox.shrink();`.
- [ ] T2.3 — Cas `PickerMode.seriesPlusOptional` : redirect recap + log info `'PickerPage: pickerMode=seriesPlusOptional TODO Story 1.16 redirect recap'` (placeholder explicite, le widget `_SeriesPlusOptionalBody` sera ajouté Story 1.16).
- [ ] T2.4 — Cas `PickerMode.tvePicker` : redirect recap + log info `'PickerPage: pickerMode=tvePicker TODO Story 1.17 redirect recap'`.
- [ ] T2.5 — Cas `PickerMode.optOut` : rendu `_LegacyOptOutBody(profile: profile, langKey: subSystem.languageCode, ...)` (T3.1 ci-dessous).
- [ ] T2.6 — Cas `PickerMode.freeWithObligatory` : rendu `_FreeWithObligatoryBody(profile: profile, langKey: subSystem.languageCode, ...)` (T3.2 ci-dessous).
- [ ] T2.7 — Ajout au passage : garde profil avec `pickerMode == derived` ET `canOptOut == false` (Fatou) → redirect recap (cohérent avec ancienne garde Story 1.4 ligne 73 `if (!profile.canOptOut)`). Cas Fatou normalement absent (lien Story 1.3 masqué) mais defensive — log warn `'PickerPage: pickerMode=derived canOptOut=false redirect (Fatou path)'`.

### T3 — Implémentation des 2 widgets privés (`_LegacyOptOutBody` + `_FreeWithObligatoryBody`) [AC2, AC3, AC6]

- [ ] T3.1 — `_LegacyOptOutBody` (StatelessWidget) : **copie quasi-littérale** de `_OptOutBody` existant (Story 1.4 lignes 156-311) — préserve le pattern `Consumer + StreamBuilder<Map<String, dynamic>?>` + `userProfileRepositoryProvider.watchProfile()` + init `_optedOut` depuis `optedOutSubjects` Firestore.
  - **Aucune modification logique** : le seul changement est le rename de classe.
  - Garder le l10n existant `l10n.onboardingOptOutTitle`/`Subtitle`/`TakingCount`/`ValidateCta` (clés ARB préservées Story 1.4).
- [ ] T3.2 — `_FreeWithObligatoryBody` (StatelessWidget NEW) : nouveau widget avec props :
  - `required DerivedProfile profile` (lit `obligatorySubjects`, `optionalSubjects`, `minSubjects`, `maxSubjects`).
  - `required String langKey`.
  - `required Set<String>? picked` (IDs des matières optionnelles sélectionnées — null avant init depuis Firestore).
  - `required bool isSaving`.
  - `required void Function(List<String>) onInitPicked` (callback init après lecture `users/{uid}.pickedSubjects`).
  - `required void Function(String subjectId, bool selected) onToggleOptional`.
  - `required void Function(String subjectId) onTapObligatory` (déclenche toast erreur).
  - `required VoidCallback onValidate`.
  - `required VoidCallback onCancel`.
- [ ] T3.3 — `_FreeWithObligatoryBody.build()` : reprendre le pattern `Consumer + StreamBuilder<Map<String, dynamic>?>` de `_LegacyOptOutBody` (Story 1.4 lignes 181-202), **mais lire `pickedSubjects` au lieu de `optedOutSubjects`** :
  ```dart
  final pickedFromFirestore = (snap.data?['pickedSubjects'] as List?)?.cast<String>() ?? const <String>[];
  final optionalOnly = pickedFromFirestore.where((id) => !profile.obligatorySubjects.map((s) => s.subjectId).contains(id)).toList();
  WidgetsBinding.instance.addPostFrameCallback((_) => onInitPicked(optionalOnly));
  ```
- [ ] T3.4 — Layout `_FreeWithObligatoryBody` (cf. AC2) :
  - `ListView` parent qui contient :
    1. Titre H2 `l10n.onboardingPickerTitle` + sous-titre `l10n.onboardingPickerSubtitle`.
    2. Section H3 `l10n.onboardingPickerObligatoryTitle` + `ListView.separated(shrinkWrap: true, physics: NeverScrollableScrollPhysics(), ...)` avec N `CheckboxListTile(value: true, onChanged: (_) => onTapObligatory(s.subjectId), secondary: Icon(LucideIcons.lock, ...), title: Text(s.name[langKey]), ...)`.
    3. Section H3 `l10n.onboardingPickerOptionalTitle` + `ListView.separated(shrinkWrap: true, NeverScrollable, ...)` avec N `CheckboxListTile(value: picked!.contains(s.subjectId), onChanged: isSaving ? null : (v) => onToggleOptional(s.subjectId, v ?? false), title: Text(s.name[langKey]), ...)`.
    4. Compteur live (couleur `AppColors.primary` si valide, `AppColors.danger` sinon) + bouton Valider + bouton Retour.
- [ ] T3.5 — `onTapObligatory` (à câbler dans `_SubjectsPickerPageState`) : `AppToast.show(context, message: l10n.onboardingPickerErrorObligatoryToast, tone: ToastTone.warning); AppLogger.w('PickerPage: tap obligatoire bloque subject=$subjectId');`.
- [ ] T3.6 — `onValidate` (à câbler) : construit `final allPicked = [...profile.obligatorySubjects.map((s) => s.subjectId), ...picked!.toList()];` puis appelle `repo.updatePickedSubjects(allPicked)` (cf. T4).

### T4 — `UserProfileRepository.updatePickedSubjects` + impl Firestore [AC4]

- [ ] T4.1 — Ajouter dans `mobile_app/lib/features/onboarding/domain/user_profile_repository.dart` (interface) :
  ```dart
  /// Story 1.15 — Persiste pickedSubjects (panier polymorphe mode
  /// free_with_obligatory / series_plus_optional / tve_picker).
  /// La liste inclut OBLIGATOIRES + OPTIONNELS sélectionnés.
  Future<Either<ProfileFailure, void>> updatePickedSubjects(
    List<String> pickedSubjectIds,
  );
  ```
- [ ] T4.2 — Impl dans `user_profile_repository_firestore_impl.dart` : pattern symétrique à `updateOptedOutSubjects` existant.
  ```dart
  @override
  Future<Either<ProfileFailure, void>> updatePickedSubjects(
    List<String> pickedSubjectIds,
  ) async {
    final uid = getUid();
    if (uid == null) return const Left(ProfileFailure.unauthenticated());
    try {
      await firestore.collection('users').doc(uid).update({
        'pickedSubjects': pickedSubjectIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.i('updatePickedSubjects success count=${pickedSubjectIds.length}');
      return const Right(null);
    } on FirebaseException catch (e) {
      AppLogger.w('updatePickedSubjects failed code=${e.code}');
      return Left(ProfileFailure.firestoreError(e.message ?? e.code));
    }
  }
  ```
  **CLAUDE.md règle 10.l** : `.update()` partiel (pas `.set()`) — préserve les autres champs sans race condition.
- [ ] T4.3 — Update fake repos dans tous les widget tests existants pour implémenter `updatePickedSubjects` (sinon erreur compile). Pattern minimal : `Future<Either<ProfileFailure, void>> updatePickedSubjects(List<String> ids) async => const Right(null);`.

### T5 — i18n FR + EN (nouvelles clés panier) [AC2, AC3]

- [ ] T5.1 — Ajouter dans `mobile_app/lib/l10n/app_fr.arb` (après les clés `onboardingOptOut*` existantes) :
  ```json
  "onboardingPickerTitle": "Choisis tes matières",
  "@onboardingPickerTitle": { "description": "Titre H2 de SubjectsPickerPage (Story 1.15 FR-3 mode free_with_obligatory)." },

  "onboardingPickerSubtitle": "Sélectionne les matières que tu présentes à ton examen.",
  "@onboardingPickerSubtitle": { "description": "Sous-titre de SubjectsPickerPage mode panier." },

  "onboardingPickerObligatoryTitle": "Matières obligatoires",
  "@onboardingPickerObligatoryTitle": { "description": "Titre H3 section matières obligatoires (lockées) mode free_with_obligatory." },

  "onboardingPickerOptionalTitle": "Matières au choix",
  "@onboardingPickerOptionalTitle": { "description": "Titre H3 section matières sélectionnables mode free_with_obligatory." },

  "onboardingPickerCounterLive": "{count, plural, =1{Tu présentes 1/{max} matière} other{Tu présentes {count}/{max} matières}}",
  "@onboardingPickerCounterLive": {
    "description": "Compteur live mode free_with_obligatory. Couleur primaire si valide, danger sinon.",
    "placeholders": {
      "count": { "type": "int" },
      "max": { "type": "int" }
    }
  },

  "onboardingPickerErrorObligatoryToast": "Cette matière est obligatoire et ne peut pas être retirée.",
  "@onboardingPickerErrorObligatoryToast": { "description": "Toast warning sur tap matière obligatoire (Story 1.15 AC2)." },

  "onboardingPickerValidateCta": "Valider mon choix",
  "@onboardingPickerValidateCta": { "description": "Bouton primaire SubjectsPickerPage mode panier. Disabled hors [min, max]." }
  ```
- [ ] T5.2 — Symétrique dans `mobile_app/lib/l10n/app_en.arb` :
  ```json
  "onboardingPickerTitle": "Choose your subjects",
  "onboardingPickerSubtitle": "Select the subjects you will sit for at your exam.",
  "onboardingPickerObligatoryTitle": "Mandatory subjects",
  "onboardingPickerOptionalTitle": "Optional subjects",
  "onboardingPickerCounterLive": "{count, plural, =1{You take 1/{max} subject} other{You take {count}/{max} subjects}}",
  "onboardingPickerErrorObligatoryToast": "This subject is mandatory and cannot be removed.",
  "onboardingPickerValidateCta": "Confirm my choice"
  ```
- [ ] T5.3 — Régénérer `mobile_app/lib/l10n/generated/app_localizations.dart` via `flutter gen-l10n` (depuis `mobile_app/`).
- [ ] T5.4 — Préserver **intactes** les 4 clés `onboardingOptOut*` existantes (mode legacy James).

### T6 — Tests widget (legacy + free_with_obligatory) [AC2, AC3, AC6]

- [ ] T6.1 — Renommer `mobile_app/test/features/onboarding/presentation/subjects_opt_out_page_test.dart` → `subjects_picker_page_legacy_optout_test.dart` (via `git mv`). Mettre à jour l'import (`SubjectsOptOutPage` → `SubjectsPickerPage`) + le `_jamesProfile()` doit explicitement déclarer `pickerMode: PickerMode.optOut` (sinon default `derived` → la garde T2.7 redirect recap → tests cassent).
- [ ] T6.2 — Vérifier que les 3 tests Story 1.4 existants passent **inchangés** (sauf renames). Si non, fixer le test (pas la prod !) car AC6 = non-régression à 100 %.
- [ ] T6.3 — Créer `mobile_app/test/features/onboarding/presentation/subjects_picker_page_free_with_obligatory_test.dart` avec :
  - Helper `_mariamProfile()` qui retourne `DerivedProfile{ pickerMode: PickerMode.freeWithObligatory, subjects: [3 oblig + 8 optionnels], obligatorySubjects: [EN, FR, Math], optionalSubjects: [Phy, Chem, Bio, Geo, Hist, Citizenship, ComputerScience, Religion], minSubjects: 6, maxSubjects: 11, canOptOut: false (le mode panier override l'opt-out v1) }`.
  - **Test (a)** : page rendue avec 3 obligatoires checked+lock + 8 optionnels uncheked, compteur « 3/11 », bouton Valider disabled (3 < min 6).
  - **Test (b)** : tap 3 optionnels (Phy, Chem, Bio) → compteur « 6/11 », bouton Valider activé.
  - **Test (c)** : tap obligatoire (EN) → toast warning visible (`find.text(l10n.onboardingPickerErrorObligatoryToast)`) + checkbox EN reste checked.
  - **Test (d)** : tap Valider avec 5 optionnels (8/11) → `_FakeRepo.updatePickedSubjectsCalls` contient `[EN, FR, Math, Phy, Chem, Bio, Geo, Hist]` (ordre obligatoires d'abord, puis optionnels sélectionnés dans l'ordre de tap).
- [ ] T6.4 — Créer `mobile_app/test/features/onboarding/data/user_profile_repository_picked_subjects_test.dart` avec `fake_cloud_firestore` :
  - 2 tests : (1) `updatePickedSubjects` success → vérifier `users/{uid}.pickedSubjects` posé + `updatedAt` non null + retour `Right(null)`. (2) FirebaseException → retour `Left(ProfileFailure.firestoreError)`.

### T7 — firestore.rules + tests JS [AC5]

- [ ] T7.1 — Ajouter en haut de `firestore.rules` (après `isOwner` ligne 22) la fonction `pickedSubjectsValid()`.
  - **DÉCISION pragmatique MVP (recommandée)** : version réduite — `picked.difference(derived).size() == 0`. Ne valide pas l'obligatoire (le client le garantit). Évite la dénormalisation `obligatorySubjectIds` côté `users/{uid}` (qui demanderait amender Story 1.3 + 1.13 createProfile). Trade-off documenté Decisions.
- [ ] T7.2 — Étendre la règle `allow update` users/{uid} (ligne 74-89) avec une clause symétrique à `optedOutSubjects` :
  ```javascript
  allow update: if isOwner(uid)
    && request.resource.data.subSystem == resource.data.subSystem
    && // ... (existant)
    && (
      !('optedOutSubjects' in request.resource.data.diff(resource.data).affectedKeys())
      || (
        request.resource.data.optedOutSubjects is list
        && request.resource.data.optedOutSubjects.toSet().difference(
             request.resource.data.derivedSubjects.toSet()
           ).size() == 0
      )
    )
    && (
      !('pickedSubjects' in request.resource.data.diff(resource.data).affectedKeys())
      || (
        request.resource.data.pickedSubjects is list
        && pickedSubjectsValid(request.resource.data)
      )
    );
  ```
- [ ] T7.3 — Étendre `test/rules/users.test.mjs` avec 3 nouveaux tests update (cohérents avec scenarios Story 1.4 existants) :
  - **(n)** Mariam update `pickedSubjects: [EN, FR, Math, Phy, Chem, Bio]` (subset valide) → `succeeds()`.
  - **(o)** Mariam update `pickedSubjects: [EN, FR, Math, 'anglophone_unknown']` (extra hors `derivedSubjects`) → `fails()`.
  - **(p)** Mariam update `pickedSubjects: [EN, FR, Math]` (subset valide mais que les 3 oblig, pas d'optionnels) → `succeeds()` côté rule (la validation min 6 est client uniquement option pragmatique MVP).
- [ ] T7.4 — `cd test/rules && npm test` doit passer en local AVANT push.
- [ ] T7.5 — Action porteur post-merge documentée : `firebase deploy --only firestore:rules --project valide-edu` (cohérent CLAUDE.md règle 9 type rules, pas indexes).

### T8 — Validation finale + smoke device [AC2-AC7]

- [ ] T8.1 — `cd mobile_app && flutter analyze` retourne **0 issue**.
- [ ] T8.2 — `cd mobile_app && flutter test` retourne **0 failure** (baseline post-1.14 = 219 verts, cible = ~225 avec +6 nets : 4 free_with_obligatory + 2 repo).
- [ ] T8.3 — `cd test/rules && npm test` retourne **0 failure** (baseline = 9 verts Story 0.9, cible = 12 avec +3 nets).
- [ ] T8.4 — Smoke device (Pixel 4a + iPhone si possible) :
  - **Mariam Form 5** (créer compte anonyme test → flow anglophone Form 5 → arrive sur picker → 3 oblig + 8 optionnels affichés → coche 5 → save → recap montre 8 matières + bandeau O-Level).
  - **James Upper Sixth S2** (compte test anglophone → S2 → picker mode opt_out → layout legacy identique Story 1.4 → décoche Biology → save → recap 2 matières).
  - **Fatou Tle D** (compte test francophone → Tle D → recap : pas de lien picker affiché → vérifier que `/onboarding/profile/picker` direct redirige bien recap).
- [ ] T8.5 — Vérification grep `opt-out` dans `mobile_app/lib` :
  - Doit rester : références dans commentaires historiques (Story 1.4 origin) + clés ARB `onboardingOptOut*` (mode legacy préservé).
  - Doit disparaître : route `/onboarding/profile/opt-out` (renommée `/picker`) + nom de classe + nom de fichier.

## Dev Notes

### Architecture cible — dispatch sur `DerivedProfile.pickerMode`

**Pattern central de la story** : `SubjectsPickerPage` devient un orchestrateur léger qui dispatche sur `profile.pickerMode` (5 valeurs `PickerMode` enum Story 1.13) vers 5 widgets privés. Story 1.15 implémente 2 (`_LegacyOptOutBody` + `_FreeWithObligatoryBody`) et place 3 placeholders (redirect recap) pour Stories 1.16 + 1.17.

```text
DerivedProfile.pickerMode dispatch matrix :
  derived              → redirect recap (Fatou, Tle franco)
  optOut               → _LegacyOptOutBody (James Upper Sixth S2 — Story 1.4 quasi-littéral)
  freeWithObligatory   → _FreeWithObligatoryBody (Mariam Form 5 — NEW Story 1.15)
  seriesPlusOptional   → TODO Story 1.16 placeholder redirect recap
  tvePicker            → TODO Story 1.17 placeholder redirect recap
```

**Pourquoi un seul widget orchestrateur ?** L'alternative naïve consisterait à créer 3 routes Flutter distinctes (`/picker/legacy`, `/picker/free`, `/picker/series-plus`). On rejette pour 3 raisons :

1. Le `pickerMode` est une **propriété dérivée du profil** côté Riverpod — pas une intention utilisateur. C'est au framework de router le rendu, pas à l'utilisateur de naviguer.
2. Le redirect `profile_recap_page.dart` (Story 1.3) doit rester unique (`/onboarding/profile/picker`) — sinon refacto Story 1.3 = scope creep.
3. Pattern Riverpod + Dart 3 switch expression rend le dispatch très lisible (cf. T2.1) — pas besoin de routes.

### Files to UPDATE (existants) vs NEW (Story 1.15)

| Fichier | Action | Lignes estimées | Référence |
|---|---|---|---|
| `mobile_app/lib/features/onboarding/presentation/subjects_opt_out_page.dart` | **RENAME** `subjects_picker_page.dart` + REWRITE dispatch + ajout `_FreeWithObligatoryBody` | ~350 (vs 311 v1) | T1, T2, T3 |
| `mobile_app/lib/features/onboarding/domain/user_profile_repository.dart` | UPDATE +1 méthode | +5 | T4.1 |
| `mobile_app/lib/features/onboarding/data/user_profile_repository_firestore_impl.dart` | UPDATE +1 méthode | +20 | T4.2 |
| `mobile_app/lib/core/routing/app_router.dart` | UPDATE rename route | +2/-2 | T1.4 |
| `mobile_app/lib/features/onboarding/presentation/profile_recap_page.dart` | UPDATE nav target | +1/-1 | T1.5 |
| `mobile_app/lib/l10n/app_fr.arb` + `app_en.arb` | UPDATE +7 clés panier | +50 | T5.1, T5.2 |
| `mobile_app/lib/l10n/generated/app_localizations.dart` | REGEN auto | (auto) | T5.3 |
| `firestore.rules` | UPDATE +1 function + 1 clause | +25 | T7.1, T7.2 |
| `mobile_app/test/features/onboarding/presentation/subjects_opt_out_page_test.dart` | **RENAME** `_legacy_optout_test.dart` + adapter fake | minimal | T6.1 |
| `mobile_app/test/features/onboarding/presentation/subjects_picker_page_free_with_obligatory_test.dart` | **NEW** | ~200 | T6.3 |
| `mobile_app/test/features/onboarding/data/user_profile_repository_picked_subjects_test.dart` | **NEW** | ~100 | T6.4 |
| `test/rules/users.test.mjs` | UPDATE +3 tests | +60 | T7.3 |

**Diff cible** : ~600 lignes hors tests (cohérent avec Story 1.13 audit Rule 10).

### Pattern testing — préserver Story 1.4 + ajouter Mariam

Le pattern Story 1.4 (`_FakeRepo implements UserProfileRepository` + `_PreloadedFlow extends OnboardingFlowNotifier`) est **réutilisé tel quel**. Une seule adaptation : ajouter `updatePickedSubjects` au `_FakeRepo` (returns `Right(null)` par défaut, traçable via getter `pickedCalls`).

```dart
// Pattern fake repo Story 1.15
class _FakeRepo implements UserProfileRepository {
  _FakeRepo({
    List<String> initialOptedOut = const [],
    List<String> initialPicked = const [],
  }) : _data = <String, dynamic>{
          'optedOutSubjects': initialOptedOut,
          'pickedSubjects': initialPicked,
        };
  final Map<String, dynamic> _data;
  final List<List<String>> pickedCalls = [];

  @override
  Stream<Map<String, dynamic>?> watchProfile() => Stream.value(_data);

  @override
  Future<Either<ProfileFailure, void>> updatePickedSubjects(List<String> ids) async {
    pickedCalls.add(ids);
    return const Right(null);
  }
  // ... autres méthodes (createProfile, updateOptedOutSubjects, updateSchoolId) inchangées
}
```

### Anti-patterns interdits

1. ❌ **Casser les tests Story 1.4** — c'est le critère AC6. Si un test 1.4 casse, c'est le test OU le code qui doit s'adapter au refactor, jamais supprimer le test ou faire un xfail.
2. ❌ **Ajouter une route `/onboarding/profile/free-picker`** — un seul orchestrateur `/picker` dispatché par `pickerMode`. Cf. Architecture cible.
3. ❌ **Persister `pickedSubjects` sans les obligatoires** — la liste posée Firestore **DOIT** contenir oblig + optionnels sélectionnés. Cohérent avec la règle BASE-DE-DONNEES.md ligne 75 (`obligatorySubjectIds ⊂ pickedSubjects`).
4. ❌ **Logger les IDs de matières** dans `updatePickedSubjects` — log d'opération uniquement (`count=${ids.length}`). CLAUDE.md sécurité 4 vise les données sensibles mais c'est aussi un anti-pattern de bruit. Idem pour `tap obligatoire bloque subject=$subjectId` — borderline OK car ID n'est pas du PII, mais à garder concis.
5. ❌ **Bloquer le scroll dans la section optionnels** — si la liste optionnels dépasse l'écran, le `ListView` parent doit scroller naturellement. `ListView.separated` inner avec `shrinkWrap: true` + `physics: NeverScrollableScrollPhysics()` (pattern Story 1.14 `_SeriesGroupedByFamily`).
6. ❌ **Faire `.set({...})` complet** dans `updatePickedSubjects` — CLAUDE.md règle 10.l obligatoire : `.update({pickedSubjects: [...], updatedAt: ...})` partiel.
7. ❌ **Modifier la garde Story 1.4 ligne 73 `if (!profile.canOptOut)` en place** — c'est le `switch pickerMode` qui prend le relais. La garde devient cas `derived` ET cas `derived + canOptOut: false` (T2.2 + T2.7).
8. ❌ **Forcer `Source.server` ou `Source.cache`** sur les reads — cohérent CLAUDE.md règle 10.h, accepter `Source.serverAndCache` par défaut.
9. ❌ **Toucher matrice.json ou seed_catalogue.py** — déjà fait Story 1.12, hors scope.
10. ❌ **Toucher Serie / DerivationRule / DerivedProfile models** — déjà fait Story 1.13, hors scope.
11. ❌ **Ajouter un index Firestore** — Story 1.15 ne crée aucune requête nouvelle. La validation `pickedSubjectsValid()` est une RULE, pas un index. CLAUDE.md règle 9 N/A.
12. ❌ **Toucher Story 1.3 ou Story 1.13 (denormaliser `obligatorySubjectIds` sur `users/{uid}` à la création)** — voir Décision « Dénormalisation v2 » : on **NE PAS** dénormaliser dans Story 1.15, on opte pour la validation rule pragmatique. Si plus tard on veut valider l'obligatoire côté serveur, ça devient une story dédiée (1.15bis ou Epic 2).

### Décisions techniques figées

#### Décision 1 — Dispatch côté Dart, pas côté router

`SubjectsPickerPage` orchestrateur unique + `switch (profile.pickerMode)` dans `build()`. Pas de 5 routes. **Why** : `pickerMode` est dérivé du profil Firestore, pas d'une intention utilisateur. **Trade-off** : un seul fichier de ~350 lignes vs 5 fichiers ~100 lignes chacun. Avantage : couplage évident, le dev voit immédiatement les 5 cas dans le même `switch`. Inconvénient mineur : si Story 1.16 + 1.17 ajoutent des layouts complexes (>200 lignes chacun), envisager extraction `lib/features/onboarding/presentation/_picker_modes/*.dart` en Epic 2.

#### Décision 2 — Conservation 100 % du mode `opt_out` legacy

Cas `PickerMode.optOut` rendu via `_LegacyOptOutBody` **copie quasi-littérale** de l'ancien `_OptOutBody` Story 1.4. Tous les tests Story 1.4 doivent passer après renames mécaniques. **Why** : préserver l'investissement Story 1.4 + éviter régression James Upper Sixth (~50 % du marché anglophone côté lycée). **How** : un seul widget privé `_LegacyOptOutBody` avec props identiques à l'ancien `_OptOutBody`. Le seul changement structurel = remontée de la logique état (`_optedOut`, `_isSaving`) vers `_SubjectsPickerPageState` au lieu de Consumer interne, **OU** garde le pattern original 100 %. **Recommandation** : garder le pattern original 100 % (Consumer + StreamBuilder interne) pour minimiser la surface de refactor.

#### Décision 3 — Validation `pickedSubjectsValid()` pragmatique (pas de dénormalisation)

Version Firestore rule **réduite** : `picked.difference(derived).size() == 0` (subset de `derivedSubjects` uniquement). N'inclut PAS la validation `obligatorySubjectIds ⊂ pickedSubjects` ni `picked ⊂ derived ∪ optional`. **Why** : éviter la dénormalisation `obligatorySubjectIds` + `optionalSubjectIds` sur `users/{uid}` (qui demanderait amender Story 1.3 `createProfile` + Story 1.13 `derive()` impl). **Trade-off accepté** :
- Client garantit `EN + FR + Math` toujours dans la liste (T3.6 `allPicked = [...obligatoires, ...optionnels]`).
- Si un bypass client malveillant POST `pickedSubjects: ['anglophone_geography', 'anglophone_history']` (sans EN/FR/Math), Firestore l'accepte. Conséquence : profil cassé côté UX (le user n'a plus les matières obligatoires affichées). Pas critique sécurité (pas de fuite donnée, pas d'escalade privilèges). **Re-évaluable** Epic 2+ via dénormalisation `obligatorySubjectIds` sur `users/{uid}` créée à `createProfile()` Story 1.3 (amend ~5 lignes).
- Validation min/max purement client (UX) — Firestore ne valide pas la cardinalité.

**ALTERNATIVE rejetée (renforcée)** : amender Story 1.3 `createProfile` pour poser `obligatorySubjectIds` + `optionalSubjectIds` sur `users/{uid}` (dénormalisation), puis `pickedSubjectsValid()` valide tout. **Why rejected** : scope creep (touche Story 1.3 déjà mergée + Story 1.13 derive() + tests existants) — pas justifié pour le MVP, à reprendre Epic 2 si abus constatés en prod.

**Cost-benefit documenté (CLAUDE.md règle 10.m)** :
- Reads par session Mariam : 1 read `users/{uid}` (pre-populate) + 1 read snapshot post-save = 2 reads (déjà comptés Story 1.4).
- Écritures par session Mariam : 1 update partiel `pickedSubjects` = 1 write (cohérent règle 10.l).
- Volumétrie 10 000 users : ~10 000 writes/session onboarding + 0 writes additionnels post-onboarding (mode panier persistant). Aucun impact prod.
- Trade-off : -0 (dénormalisation économisée) vs sécurité dégradée légèrement (bypass client malveillant peut casser son propre profil, sans fuite).

#### Décision 4 — Compteur live couleur conditionnelle

Compteur passe en `AppColors.danger` (rouge) si `pickedTotal < minSubjects` OU `> maxSubjects`, `AppColors.primary` (bleu) sinon. **Why** : feedback immédiat de validité sans toast intrusif (le toast erreur est réservé au tap obligatoire). Pattern UX cohérent avec compteur Story 1.4 (bouton Valider grisé suffit, le rouge renforce visuellement).

#### Décision 5 — Rename rétrocompat-friendly via git mv

T1.1 utilise `git mv subjects_opt_out_page.dart subjects_picker_page.dart` au lieu de Delete+Create. **Why** : préserve l'historique git (`git log --follow`) pour comprendre la généalogie Story 1.4 → 1.15. Le diff GitHub affichera "renamed with 87% similarity" et focus sur les changements réels.

### Mapping `PickerMode` → comportement UI (référence rapide)

| Mode | Persona | Route effective | Widget rendu | Persistance | Validation |
|---|---|---|---|---|---|
| `derived` | Fatou Tle D | redirect `/recap` | (aucun) | (rien à persister) | N/A |
| `optOut` | James Upper Sixth S2 | `/picker` mode legacy | `_LegacyOptOutBody` | `optedOutSubjects` | client : `takingCount > 0` + serveur : `subset(derived)` |
| `freeWithObligatory` | Mariam Form 5 | `/picker` mode panier | `_FreeWithObligatoryBody` | `pickedSubjects` | client : `count ∈ [min, max]` + obligatoires forcées + serveur : `subset(derived)` |
| `seriesPlusOptional` | James Upper Sixth + ICT (Story 1.16) | `/picker` placeholder | redirect `/recap` | (Story 1.16) | (Story 1.16) |
| `tvePicker` | Eyong TVE AL ELET (Story 1.17) | `/picker` placeholder | redirect `/recap` | (Story 1.17) | (Story 1.17) |

### Personas concernées

- **Mariam Bakari** — Form 5 anglophone, Limbé, Tecno Pop 7. Persona Story 1.15. Test panier 8 matières (3 oblig + 5 optionnels).
- **James Tanyi** — Upper Sixth S2 anglophone, Buea, Tecno Spark 8. Persona Story 1.4 + 1.16. Test non-régression mode `opt_out`.
- **Fatou Mballa** — Tle D francophone, Yaoundé, Tecno Spark 8. Persona Story 1.3 + 1.4. Test non-régression mode `derived` (pas de page picker).
- **Aïssatou Diop** — Tle A1 francophone, Douala. Persona Story 1.14 (mode `derived` aussi). Non-régression secondaire (pas de page picker, redirect recap).

### Sources autoritaires

1. **`epics.md` § Story 1.15** : déclaration scope (sprint-change 2026-06-09).
2. **`sprint-change-proposal-2026-06-09.md` § Change 4.6** : design Story 1.15 (lignes 287-296).
3. **`prd.md` § FR-3 multi-mode** (lignes 143-156) : mode `free_with_obligatory` consequence ligne 151 — autorité produit sur min 6 / max 11 / EN+FR+Math obligatoires.
4. **`EXPERIENCE.md` Variant Flow 1b Mariam** (lignes 470-488) : autorité UX (sections nommées, compteur, edge cases).
5. **`BASE-DE-DONNEES.md` § users/{uid}.pickedSubjects** (lignes 71-76) + § Validation panier polymorphe (lignes 232-250) : schéma + règle Firestore canonique.
6. **`ALGORITHMES.md` § Modes panier** : table 5 modes (référence cohérence cross-story).
7. **`ADR-016` Décision 3 + 4** : justification panier polymorphe + validation client+serveur.
8. **`Office du Bac` + `Cameroon GCE Board`** : règles officielles sourcing nomenclature Story 1.11a.

### Pourquoi maintenant (timing produit)

- Story 1.12 a seedé Form 5 anglo avec `pickerMode: 'free_with_obligatory'` mais aujourd'hui Mariam voit la liste dérivée sans validation → UX dégradée temporaire (couvert par CLAUDE.md règle 10.m doc cost-benefit acceptée Story 1.13).
- Story 1.16 + 1.17 dépendent de Story 1.15 (refactor pose les fondations widget pour les deux autres modes).
- Sprint Epic 1 v2 : Story 1.15 est la **pénultième** brique (avant Story 1.17 TVEE). Bloque la sortie d'Epic 1.

### Cost-benefit Firestore (CLAUDE.md règle 10.m — obligatoire)

**Reads par session Mariam onboarding** :
- `derivedProfileProvider` (Story 1.13) : 5 reads (serie + subjects + examTargets + obligatorySubjects + optionalSubjects via `Future.wait` parallèle) — déjà comptés Story 1.13.
- `userProfileRepositoryProvider.watchProfile()` snapshot : 1 read pre-populate `pickedSubjects` initial + N reads sur updates internes (Mariam coche/décoche → pas de re-read, snapshot reste live mais ne se re-trigger pas si le doc Firestore ne change pas).
- **Total reads onboarding** : ~6 reads.

**Écritures par session Mariam** :
- 1 `update()` partiel `pickedSubjects` = 1 write.
- **Total writes** : 1.

**Volumétrie 10 000 users Form 5 (~35 % marché anglophone secondaire ~30 % marché global)** :
- ~1 000 utilisateurs cibles Form 5 / mois (hypothèse adoption ~10 %/mois).
- ~1 000 sessions onboarding × 6 reads = 6 000 reads/mois.
- ~1 000 writes/mois.
- À 100 000 users : 100 000 reads + 100 000 writes/mois sur cette feature seule. Aligné avec capacités Firestore (1 M reads/jour gratuit dépassable sur Spark, négligeable sur Blaze).

**Trade-off accepté** : pas de dénormalisation `obligatorySubjectIds` sur `users/{uid}` (Décision 3) — économie 0 writes mais lacune sécurité documentée. Re-évaluable Epic 2+.

## Definition of Done

- [ ] **AC1-AC7 verts** : tous les acceptance criteria validés par tests Dart + tests rules JS + smoke device.
- [ ] **`flutter analyze` 0 issue** sur `mobile_app/`.
- [ ] **`flutter test` 0 failure** : baseline 219 verts post-1.14 → cible ~225 (+6 nets : 4 free_with_obligatory + 2 repo Firestore).
- [ ] **`cd test/rules && npm test` 0 failure** : baseline 9 verts Story 0.9 → cible 12 verts (+3 nets).
- [ ] **Diff PR <= 600 lignes hors tests** (cohérent avec Story 1.13 audit Rule 10).
- [ ] **Smoke device Mariam + James + Fatou OK** (Pixel 4a obligatoire, iPhone si dispo). Capture FR + EN pour Mariam (variant Flow 1b).
- [ ] **`firebase deploy --only firestore:rules --project valide-edu` exécuté** par porteur post-merge (CLAUDE.md règle 9 type rules).
- [ ] **Aucun nouvel index Firestore** (vérifié : la validation est rule, pas requête).
- [ ] **Aucune modif `doc/partage/*`** (déjà fait Story 1.11a).
- [ ] **Aucune modif matrice.json / seed_catalogue.py / Serie / DerivationRule / DerivedProfile model / derive()** (déjà fait Stories 1.12 + 1.13).
- [ ] **Tests Story 1.4 (3 widget tests + 9 rules tests) 100 % verts après renames** — critère AC6 strict.
- [ ] **Commit message conventional commits FR à l'impératif** : `feat(onboarding): SubjectsOptOutPage refactor en SubjectsPickerPage polymorphe + mode free_with_obligatory O-Level (Story 1.15)`.
- [ ] **Branche `feat/1.15-refactor-opt-out-en-picker-anglo-olevel`** (kebab-case, ≤ 50 chars).
- [ ] **PR <= 400 lignes diff totalisé** : si > 400, splitter en 2 PRs (rules + Dart) ou amendement scope documenté.
- [ ] **Pas de `--no-verify`** sur le commit (CLAUDE.md workflow git).

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
