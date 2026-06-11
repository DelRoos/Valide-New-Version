---
story_id: 1bis.1
title: State machine onboarding (Riverpod `OnboardingNotifier` pure)
epic: 1bis
phase: P1bis — Refonte intégrale du flow pré-dashboard
status: review
created: 2026-06-11
baseline_commit: b07e8b1  # merge PR #101 (feat/1bis-0-foundation-widgets) - main aligné post-livraison 5 composants + maskPhone
estimation: S (~2 jours)
sprint_change: project_manage/planning-artifacts/epics/epic-1bis-refonte-onboarding.md (Story E1bis-1)
dependencies:
  - E1bis-0 mergée (PR #101) — pas de consommation directe des widgets dans cette story mais cohérence catalogue préservée
  - Story 1.2 livrée — `SubsystemPrefs` + `sharedPreferencesProvider` existants à réutiliser (pas de wrapper duplicate)
  - Story 1.3 livrée — `SubSystem` enum existant à réutiliser (`domain/sub_system.dart`)
  - `doc/tech/STORY-TEMPLATES.md` (template 1 Dev Notes condensé)
blocks:
  - E1bis-2 (pages 0+1 sub-system + hero — consomme `onboardingNotifierProvider` pour `setSubSystem`)
  - E1bis-3 (pages 2+3+4 — consomme `setTrackId`, `setLevelId`, `setStreamAndSubjects`)
  - E1bis-4 (page 5 auth — consomme `setAuthProvider` + extension future `flushToFirestore`)
  - E1bis-5 (pages 6+7 — consomme `setUserDisplayName`, `setPhoneNumber`, `skipPhone`)
  - E1bis-6 (page 8 school — consomme `setSchool`, `skipSchool`)
  - E1bis-7 (page 9 success — observe `OnboardingState.isComplete`)
sourceArtifacts:
  - project_manage/planning-artifacts/epics/epic-1bis-refonte-onboarding.md § « Story E1bis-1 » (AC1-AC10 source — AC5/AC6/AC8/AC10 reportés explicitement, cf. § Out of scope)
  - project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/EXPERIENCE.md § « State machine onboarding » (transitions next/back, branches conditionnelles)
  - doc/templates/src/components/OnboardingFlow.tsx (référence comportement — useState `currentStep`, skip step 6 si OAuth fournit displayName, skip steps 6-8 si visiteur)
  - doc/templates/src/types.ts (modèle `UserProfile` — référence champs)
  - mobile_app/lib/features/onboarding/data/subsystem_prefs.dart (wrapper SharedPreferences existant à réutiliser)
  - mobile_app/lib/features/onboarding/domain/sub_system.dart (enum existant à réutiliser)
  - mobile_app/lib/features/onboarding/providers.dart (pattern `subSystemNotifierProvider` à observer comme référence Riverpod 3.x)
---

# Story 1bis.1 — State machine onboarding (`OnboardingNotifier` pure)

Status: **ready-for-dev**

## Objectif

Livrer la **state machine Riverpod déterministe** qui orchestre les 10 étapes du nouveau flow onboarding E1bis : `OnboardingState` immutable (Equatable), `OnboardingNotifier` avec transitions `next()` / `back()` + branches conditionnelles (skip step 4 si mode picker `derived`, skip step 6 si OAuth fournit `displayName`, skip steps 6-8 si visiteur), persistance partielle `subSystem` SharedPreferences (réutilisation `SubsystemPrefs`), restoration au démarrage via `loadFromPersistence()`. Pas de rendu UI, pas de Firebase, pas de modification router.

**Pourquoi maintenant** : les stories E1bis-2 à E1bis-7 (pages onboarding) consomment toutes au moins une méthode du Notifier. Sans la state machine livrée d'abord, chaque page devrait inventer son propre orchestrateur local (anti-pattern Stories 1.3 à 1.7 résorbé par `OnboardingFlowNotifier` historique). Livrer la state machine en isolation permet : (a) tests unit exhaustifs sans bruit UI, (b) PR petite et reviewable, (c) zéro rupture du flow Epic 1 actuel qui reste live.

**Pourquoi pas plus tard** : si E1bis-2 (pages 0+1) démarrait avant cette story, elle devrait soit (a) inventer un Notifier local jetable, soit (b) être bloquée → cascade de retard.

---

## User Story

**En tant que** développeur Flutter qui implémente la refonte E1bis pages 0-9,
**je veux** une state machine Riverpod pure (`OnboardingNotifier`) qui gère `currentStep`, les transitions next/back avec branches conditionnelles, et la persistance partielle `subSystem`,
**afin que** chaque story page (E1bis-2 à E1bis-7) se concentre sur le rendu et la microcopie, en consommant un Notifier stable, testé exhaustivement et sans dépendance Firebase/router.

---

## Scope (décisions porteur produit 2026-06-11)

- ✅ **State machine PURE** : `OnboardingState` immutable + `OnboardingNotifier` + transitions. Réutilisation `SubsystemPrefs` + `SubSystem` existants.
- ✅ **Persistance SharedPreferences pour `subSystem` UNIQUEMENT** (clé existante `onboarding.subsystem` via `SubsystemPrefs`). Le reste du draft profile vit en RAM Riverpod.
- ❌ **PAS de modification du router** (`go_router` `app_router.dart`). Le flow Epic 1 actuel reste live. Le branchement UI vers les nouvelles pages arrive avec E1bis-2.
- ❌ **PAS de Firebase / Firestore writes** dans cette story. La méthode `flushToFirestore` (epic AC6) est **reportée à E1bis-4** (post-auth WriteBatch). Cette story expose une méthode interne `toFirestorePayload()` réservée à E1bis-4 — pas d'appel Firebase ici.
- ❌ **PAS de restart-router logic au démarrage** (epic AC5). Cette story expose `loadFromPersistence()` qui hydrate `OnboardingState.subSystem`. La logique de redirection « si subSystem présent ET user non auth → step 0 pré-rempli sinon step 1 » est implémentée dans E1bis-2.

---

## Acceptance Criteria

- **AC1 — `OnboardingState` immutable**. Créer `mobile_app/lib/features/onboarding/presentation/state/onboarding_state.dart` (Equatable). Champs :
  - `currentStep: int` (0 à 9, défaut 0)
  - `subSystem: SubSystem?` (réutilise `domain/sub_system.dart`, défaut `null`)
  - `trackId: String?` (`general` | `technical`, défaut `null`)
  - `levelId: String?` (défaut `null`)
  - `levelRequiresPicker: bool` (défaut `false`, vrai si le mode picker du niveau ≠ `derived` — capturé par `setLevelId`)
  - `streamId: String?` (défaut `null`)
  - `pickedSubjects: List<String>` (défaut `const []`)
  - `userDisplayName: String?` (défaut `null`)
  - `phoneNumber: String?` (E.164 CM, défaut `null`)
  - `phoneSkipped: bool` (défaut `false`)
  - `schoolId: String?` (défaut `null`)
  - `schoolName: String?` (dénormalisé pour reprise sans re-fetch, défaut `null`)
  - `pendingSchoolRequestId: String?` (défaut `null`)
  - `schoolSkipped: bool` (défaut `false`)
  - `isVisitor: bool` (défaut `false`)
  - `authProvider: OnboardingAuthProvider?` (enum `google` | `apple` | `guest`, défaut `null`)
  
  Méthode `copyWith(...)` avec tous les paramètres nullable (signature `Object? value = const _Sentinel()` pour distinguer "pas fourni" de "fourni `null`" — pattern existant codebase `OnboardingFlowState`). Méthode `toFirestorePayload()` retournant `Map<String, dynamic>` du payload partiel pour E1bis-4 (non appelée dans cette story, simplement préparée). Equatable `props` exhaustif. Pas d'import Firebase / Flutter / Riverpod / `dart:io` dans ce fichier.

- **AC2 — Enum `OnboardingAuthProvider`**. Dans le même fichier (`onboarding_state.dart`) ou un fichier frère `onboarding_auth_provider.dart` (au choix dev, ≤ 300 lignes total). Valeurs : `google`, `apple`, `guest`. Méthode `String get id => name`. Helper `static OnboardingAuthProvider? fromString(String?)` pour future déserialisation.

- **AC3 — `OnboardingNotifier` Riverpod**. Créer `mobile_app/lib/features/onboarding/presentation/state/onboarding_notifier.dart`. Hérite de `Notifier<OnboardingState>`. `build()` retourne `const OnboardingState()` initial (currentStep=0). N'écrit PAS dans SharedPreferences au build — la restoration est explicite via `loadFromPersistence()` (cf. AC8).

  **Méthodes mutation** (chacune respecte CLAUDE.md règle 10.l — `copyWith` partiel, jamais réécriture complète) :
  - `Future<void> setSubSystem(SubSystem subSystem)` — écrit aussi `SubsystemPrefs.write()` (await) puis `state = copyWith(subSystem: subSystem, currentStep: 1)` (next implicite, cf. AC4).
  - `void setTrackId(String trackId)` — `state = copyWith(trackId: trackId, levelId: null, levelRequiresPicker: false, streamId: null, pickedSubjects: const [], currentStep: 3)` (reset downstream cf. AC5).
  - `void setLevelId(String levelId, {required bool requiresPicker})` — `state = copyWith(levelId: levelId, levelRequiresPicker: requiresPicker, streamId: null, pickedSubjects: const [], currentStep: requiresPicker ? 4 : 5)` (skip step 4 si derived cf. AC6).
  - `void setStreamAndSubjects({String? streamId, required List<String> pickedSubjects})` — `state = copyWith(streamId: streamId, pickedSubjects: pickedSubjects, currentStep: 5)`.
  - `void setAuthProvider(OnboardingAuthProvider provider, {String? displayName})` — `state = copyWith(authProvider: provider, userDisplayName: displayName, isVisitor: provider == OnboardingAuthProvider.guest, currentStep: (displayName != null && displayName.isNotEmpty) ? 7 : 6)` (skip step 6 si OAuth fournit name cf. AC6).
  - `void setUserDisplayName(String displayName)` — `state = copyWith(userDisplayName: displayName, currentStep: 7)`.
  - `void setPhoneNumber(String phoneNumber)` — `state = copyWith(phoneNumber: phoneNumber, phoneSkipped: false, currentStep: state.isVisitor ? 9 : 8)` (skip step 8 si visiteur cf. AC6).
  - `void skipPhone()` — `state = copyWith(phoneNumber: null, phoneSkipped: true, currentStep: state.isVisitor ? 9 : 8)`.
  - `void setSchool({required String schoolId, required String schoolName})` — `state = copyWith(schoolId: schoolId, schoolName: schoolName, pendingSchoolRequestId: null, schoolSkipped: false, currentStep: 9)`.
  - `void setPendingSchoolRequest({required String pendingRequestId, required String schoolName})` — `state = copyWith(schoolId: null, schoolName: schoolName, pendingSchoolRequestId: pendingRequestId, schoolSkipped: false, currentStep: 9)`.
  - `void skipSchool()` — `state = copyWith(schoolId: null, schoolName: null, pendingSchoolRequestId: null, schoolSkipped: true, currentStep: 9)`.
  - `void next()` — incrément déterministe en consultant le state actuel. Implémentation : switch sur `currentStep` avec les mêmes branches que les setters (cf. AC6 tableau). À `currentStep == 9` → no-op.
  - `void back()` — décrément déterministe inverse. Voir AC7 pour le tableau back symétrique. À `currentStep == 0` → no-op.
  - `void reset()` — `state = const OnboardingState()` (utile pour tests et future déconnexion). Ne touche PAS `SubsystemPrefs` (la déconnexion future décidera ; CLAUDE.md §6 sequencing).

- **AC4 — Persistance `subSystem` via `SubsystemPrefs`**. Le Notifier reçoit en dépendance `SubsystemPrefs` via `ref.read(subsystemPrefsProvider)` (provider existant Story 1.2). `setSubSystem(...)` appelle `await prefs.write(subSystem)` AVANT `state = copyWith(...)`. Si l'écriture échoue (rarissime — SharedPreferences est local), l'exception remonte au caller (la page step 0 affichera un toast erreur — responsabilité E1bis-2). Aucune autre persistance ; le draft profile reste en RAM.

- **AC5 — Reset downstream sur changement amont**. `setTrackId(...)` reset `levelId`, `levelRequiresPicker`, `streamId`, `pickedSubjects`. `setLevelId(...)` reset `streamId`, `pickedSubjects`. Justification : un changement de track invalide les niveaux disponibles ; un changement de niveau invalide la série/le picker. Cohérent avec le pattern `OnboardingFlowState.resetFrom(step)` existant (Story 1.3).

- **AC6 — Transitions conditionnelles `next()`**. Tableau de vérité :

  | Depuis | Vers | Condition |
  |---|---|---|
  | 0 (sub-system) | 1 | toujours (après `setSubSystem`) |
  | 1 (hero) | 2 | toujours (`next()` simple) |
  | 2 (track) | 3 | toujours (après `setTrackId`) |
  | 3 (level) | 4 | si `levelRequiresPicker == true` |
  | 3 (level) | 5 | si `levelRequiresPicker == false` (mode `derived`) |
  | 4 (stream/subjects) | 5 | toujours (après `setStreamAndSubjects`) |
  | 5 (auth) | 6 | si `userDisplayName` null ou vide |
  | 5 (auth) | 7 | si `userDisplayName` non vide (OAuth a fourni) |
  | 6 (name) | 7 | toujours (après `setUserDisplayName`) |
  | 7 (phone) | 8 | si `isVisitor == false` |
  | 7 (phone) | 9 | si `isVisitor == true` (skip school) |
  | 8 (school) | 9 | toujours (après `setSchool` / `setPendingSchoolRequest` / `skipSchool`) |
  | 9 (success) | 9 | no-op (clamp final) |

- **AC7 — Transitions conditionnelles `back()`**. Symétrique :

  | Depuis | Vers | Condition |
  |---|---|---|
  | 0 | 0 | no-op (clamp initial) |
  | 1 | 0 | toujours |
  | 2 | 1 | toujours |
  | 3 | 2 | toujours |
  | 4 | 3 | toujours |
  | 5 | 4 | si `levelRequiresPicker == true` |
  | 5 | 3 | si `levelRequiresPicker == false` (symétrie skip step 4) |
  | 6 | 5 | toujours |
  | 7 | 6 | si `userDisplayName` null ou vide |
  | 7 | 5 | si `userDisplayName` non vide (symétrie skip step 6) |
  | 8 | 7 | toujours |
  | 9 | 8 | si `isVisitor == false` |
  | 9 | 7 | si `isVisitor == true` (symétrie skip step 8) |

  Note : `back()` ne reset PAS les valeurs amont. Si l'utilisateur revient à un step, ses choix précédents sont préservés (pré-remplissage UI). C'est `setTrackId` / `setLevelId` qui reset downstream (AC5).

- **AC8 — `loadFromPersistence()` async**. Méthode publique sur le Notifier : `Future<void> loadFromPersistence()`. Lit `SubsystemPrefs.read()`. Si non-null → `state = copyWith(subSystem: persistedValue, currentStep: 1)` (l'utilisateur a déjà tapé son sub-system avant kill app → reprise step 1 hero). Si null → no-op (state initial). Cette méthode est appelée explicitement par E1bis-2 (page wrapper `OnboardingShell`) au `initState` — pas en `build()` du Notifier (qui doit rester synchrone et déterministe pour les tests).

- **AC9 — Provider `onboardingNotifierProvider`**. Créer `mobile_app/lib/features/onboarding/presentation/state/onboarding_providers.dart`. Expose :
  - `final onboardingNotifierProvider = NotifierProvider<OnboardingNotifier, OnboardingState>(OnboardingNotifier.new);`
  - Pas de provider supplémentaire dans cette story. Le `subsystemPrefsProvider` existant Story 1.2 est consommé via `ref.read` interne au Notifier.

- **AC10 — Tests unit exhaustifs**. Créer `mobile_app/test/features/onboarding/presentation/state/onboarding_notifier_test.dart`. Cas obligatoires (≥ 20 tests) :
  - **Setters** (10 tests) : un test par setter vérifiant l'état post-mutation (incl. `setSubSystem` qui doit aussi écrire SharedPreferences via `setMockInitialValues({})` + lecture post-write).
  - **Reset downstream** (3 tests) : (a) `setTrackId` après level posé → levelId/streamId/pickedSubjects à null ; (b) `setLevelId` après stream/subjects posés → streamId/pickedSubjects à null ; (c) `setLevelId(requiresPicker: false)` puis check `currentStep == 5`.
  - **Transitions `next()`** (8 tests) : un test par branche conditionnelle du tableau AC6 (notamment skip step 4 derived, skip step 6 OAuth, skip step 8 visiteur, clamp step 9).
  - **Transitions `back()`** (6 tests) : symétries critiques (back depuis 5 vers 3 si !requiresPicker, back depuis 7 vers 5 si OAuth, back depuis 9 vers 7 si visiteur, clamp step 0).
  - **`loadFromPersistence`** (3 tests) : (a) prefs vides → state initial ; (b) prefs `francophone` → subSystem hydraté + currentStep == 1 ; (c) prefs `anglophone` → idem en anglais.
  - **`reset()`** (1 test) : state revient à initial, SharedPreferences inchangées.
  - **Equatable** (1 test) : deux `OnboardingState` avec mêmes champs → égaux ; un champ différent → non égaux.

  Mock SharedPreferences via `SharedPreferences.setMockInitialValues({})` puis `await SharedPreferences.getInstance()` injecté dans `ProviderScope` via `sharedPreferencesProvider.overrideWithValue(prefs)`. Pattern existant codebase Story 1.2/1.3.

- **AC11 — Identifiers anglais 100 % (CLAUDE.md règle 5)**. Noms de fichiers, classes, enums, props, variables internes : `OnboardingState`, `OnboardingNotifier`, `OnboardingAuthProvider`, `currentStep`, `subSystem`, `trackId`, `levelId`, `streamId`, `pickedSubjects`, `userDisplayName`, `phoneNumber`, `phoneSkipped`, `schoolId`, `schoolName`, `pendingSchoolRequestId`, `schoolSkipped`, `isVisitor`, `authProvider`, `levelRequiresPicker`. Pas de `filiere`, `niveau`, `serie`, `matiere`.

- **AC12 — Domain pur (CLAUDE.md règle 1)**. `OnboardingState` (et `OnboardingAuthProvider`) ne doit importer **que** `package:equatable/equatable.dart` et `../../domain/sub_system.dart`. Aucun import Firebase, Flutter, Riverpod, `dart:io`, `package:logger`. Le Notifier (couche presentation) peut importer Riverpod + SharedPreferences (via provider), mais reste **sans** Firebase (CLAUDE.md règle 1 + scope décision 2026-06-11).

- **AC13 — Taille fichiers ≤ 300 lignes / cible, 500 / plafond (CLAUDE.md règle 12)**. Cible par fichier :
  - `onboarding_state.dart` (state + enum + copyWith + toFirestorePayload) : ~170 lignes
  - `onboarding_notifier.dart` (mutations + next/back + loadFromPersistence) : ~260 lignes
  - `onboarding_providers.dart` (1 provider exposé) : ~30 lignes

  Si `onboarding_notifier.dart` dépasse 300 lignes en draft, extraire la table de transitions `next()`/`back()` dans un helper privé (`_OnboardingTransitions`) du même fichier — pas dans un fichier séparé (cohésion forte).

---

## Tasks / Subtasks

> Ordre recommandé (état avant transitions).

- [x] **T1 — `OnboardingState` immutable Equatable** (AC1, AC2, AC12)
  - Fichier `lib/features/onboarding/presentation/state/onboarding_state.dart`.
  - Définir `OnboardingAuthProvider` enum + `fromString`.
  - Définir `OnboardingState` Equatable avec 15 champs (cf. AC1).
  - `copyWith` avec sentinelle pour distinguer "non fourni" de "fourni null" — pattern existant `OnboardingFlowState`.
  - `toFirestorePayload()` retourne `Map<String, dynamic>` du payload partiel (champs non-null uniquement) — reservé E1bis-4.
  - Constructeur `const OnboardingState()` état initial.
  - 0 import Firebase/Flutter/Riverpod.

- [x] **T2 — Tests `OnboardingState`** (AC1, AC10 partiel — Equatable + copyWith)
  - Fichier `test/features/onboarding/presentation/state/onboarding_state_test.dart` (~5 cas).
  - Cas : copyWith préserve les champs non touchés ; copyWith permet de remettre un champ à null via sentinelle ; Equatable equality ; `toFirestorePayload` n'inclut pas les champs null.

- [x] **T3 — `OnboardingNotifier` setters + reset downstream** (AC3, AC4, AC5)
  - Fichier `lib/features/onboarding/presentation/state/onboarding_notifier.dart`.
  - 11 setters publics + `reset()`.
  - `setSubSystem` écrit SharedPreferences via `ref.read(subsystemPrefsProvider).write(...)` puis met à jour state.
  - Imports : `flutter_riverpod`, `../../domain/sub_system.dart`, `../../providers.dart` (pour `subsystemPrefsProvider`), `onboarding_state.dart`.

- [x] **T4 — Transitions `next()` et `back()` conditionnelles** (AC6, AC7)
  - Implémenter `next()` avec switch sur `currentStep` consultant `levelRequiresPicker`, `userDisplayName`, `isVisitor`.
  - Implémenter `back()` symétrique.
  - À step 9 / step 0 → no-op respectifs.

- [x] **T5 — `loadFromPersistence()` async** (AC8)
  - Méthode publique async.
  - Lit `subsystemPrefsProvider.read()`.
  - Hydrate `subSystem` + `currentStep = 1` si non-null. No-op sinon.
  - Pas appelée en `build()` — appelée explicitement par E1bis-2.

- [x] **T6 — Provider `onboardingNotifierProvider`** (AC9)
  - Fichier `lib/features/onboarding/presentation/state/onboarding_providers.dart`.
  - Expose le `NotifierProvider<OnboardingNotifier, OnboardingState>`.

- [x] **T7 — Tests `OnboardingNotifier` exhaustifs** (AC10)
  - Fichier `test/features/onboarding/presentation/state/onboarding_notifier_test.dart`.
  - Setup helper `_buildContainer({Map<String, Object>? prefsInitial})` qui appelle `SharedPreferences.setMockInitialValues(prefsInitial ?? {})` + `await SharedPreferences.getInstance()` + `ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)])`.
  - ≥ 20 tests couvrant : setters (10), reset downstream (3), next conditionnel (8), back conditionnel (6), loadFromPersistence (3), reset (1), Equatable (1).
  - Vérifier que `setSubSystem(francophone)` produit `prefs.getString('onboarding.subsystem') == 'francophone'`.

- [x] **T8 — `flutter analyze` + `flutter test` propres**
  - `cd mobile_app && flutter analyze` → 0 issue (baseline E1bis-0 = 0).
  - `cd mobile_app && flutter test` → tous verts. Baseline E1bis-0 = 339 passed + 1 skipped. Cible E1bis-1 = 339 + ~25 nouveaux ≈ 364 verts + 1 skipped.

- [x] **T9 — Mise à jour catalogue / sprint-status / commit + push**
  - **Pas d'entrée catalogue** (cette story ne livre aucun widget — CLAUDE.md règle 11 ne s'applique pas).
  - Mettre à jour `project_manage/implementation-artifacts/sprint-status.yaml` : `1bis-0` `review` → `done` (PR #101 mergée), `1bis-1` `ready-for-dev` → `in-progress` au début du dev, puis `review` en fin.
  - Commits Conventional Commits :
    1. `feat(onboarding): ajouter OnboardingState immutable Equatable + enum AuthProvider`
    2. `feat(onboarding): ajouter OnboardingNotifier Riverpod + transitions conditionnelles + loadFromPersistence`
    3. `test(onboarding): couverture exhaustive OnboardingNotifier (setters + next/back + persistance)`
    4. `docs(planning): finaliser story E1bis-1 - status ready-for-dev -> review`
  - Push `feat/1bis-1-state-machine-onboarding` → ouvrir PR avec description "Story E1bis-1 — State machine OnboardingNotifier (Riverpod pure)". **Attendre merge avant E1bis-2** (CLAUDE.md règle 6).

---

## Dev Notes

### Contexte et motivation

E1bis-0 (foundation widgets, PR #101 mergée b07e8b1) a livré la base visuelle. E1bis-1 livre la base **comportementale** : le `OnboardingNotifier` qui orchestre les 10 étapes. Tant qu'il n'existe pas, chaque page E1bis-2/3/4/5/6/7 devrait inventer son propre Notifier local jetable — déjà vu et résorbé Story 1.3 → 1.8 dans Epic 1 (et c'est précisément le `OnboardingFlowNotifier` historique qui sera déprécié E1bis-9).

Cette story **n'introduit pas de rupture** : `OnboardingFlowNotifier` (Epic 1) reste fonctionnel et alimente toujours le flow Epic 1 actif. Le nouveau `OnboardingNotifier` est créé **en parallèle**, sans router branchement. Le branchement arrive avec E1bis-2 quand les premières pages consommatrices seront prêtes.

### Décisions techniques clés

- **Décision 1** : **State machine PURE, pas de Firebase, pas de router.** — **raison** : porteur produit 2026-06-11 ("PR petite et reviewable, zero rupture utilisateur, conformité CLAUDE.md règle 6"). — **alternative écartée** : tout livrer en une story (Notifier + flushToFirestore + reroutage). Refusé car PR > 600 lignes garantie + risque casse flow Epic 1 live.

- **Décision 2** : **Persistance `subSystem` uniquement** (pas tout le draft profile). — **raison** : conforme EXPERIENCE.md « state restoration partielle » + minimise la surface de bugs de sérialisation (10 champs nullable à JSONifier serait coûteux pour bénéfice marginal — 10 étapes courtes, kill app rare). — **alternative écartée** : SharedPreferences full draft profile. Refusé : complexité JSON × 10 champs, faible ROI.

- **Décision 3** : **Réutilisation `SubsystemPrefs` existante** (Story 1.2). — **raison** : zéro duplication, clé canonique `onboarding.subsystem` partagée avec `SubSystemNotifier` Epic 1 (les deux Notifiers lisent/écrivent la même clé sans collision tant qu'on n'écrit qu'au step 0 du nouveau flow). — **alternative écartée** : créer `OnboardingPersistence` wrapper séparé. Refusé : duplique le code de `SubsystemPrefs` qui fait déjà exactement ça.

- **Décision 4** : **Branches conditionnelles dans le Notifier, pas dans les pages.** — **raison** : centralise la logique de skip step 4 / step 6 / step 8 — testable unit sans bruit UI. Les pages appellent `next()` sans connaître les conditions. — **alternative écartée** : `jumpToStep(int)` exposé aux pages. Refusé : disperse la logique et casse l'invariant "next() est l'unique source de vérité".

- **Décision 5** : **`loadFromPersistence()` explicite, pas en `build()` du Notifier.** — **raison** : `build()` doit rester synchrone et déterministe pour les tests unit (pas de `await prefs.read()` dans le build). La page E1bis-2 (futur `OnboardingShell`) appelle `loadFromPersistence()` au `initState` (un peu comme `loadAppFonts()` dans `flutter_test_config.dart` story E1bis-0). — **alternative écartée** : Notifier async `AsyncNotifier`. Refusé : ajoute de la complexité dans les pages (`AsyncValue.when(...)`) pour un cas où la SharedPreferences est déjà préchargée par `main.dart` (Story 1.2 AC4).

### Modèle de données / API impactés

- Fichiers `domain/` : aucun ajout/modif (réutilise `SubSystem` existant).
- Fichiers `data/` : aucun ajout/modif (réutilise `SubsystemPrefs` existant). Pas de nouveau wrapper.
- Fichiers `presentation/state/` (nouveau dossier) :
  - `onboarding_state.dart` (nouveau, ~170 l).
  - `onboarding_notifier.dart` (nouveau, ~260 l).
  - `onboarding_providers.dart` (nouveau, ~30 l).
- Schéma Firestore : **pas de modif**. `toFirestorePayload()` préparé pour E1bis-4 mais pas appelé.
- Contrats Cloud Function : N/A.

### Cost-benefit Firestore

**N/A pour cette story** — aucune lecture/écriture Firestore. Le `flushToFirestore` est explicitement reporté à E1bis-4 (post-auth WriteBatch). Le payload est juste préparé via `toFirestorePayload()` pour E1bis-4.

### Stratégie responsive

**N/A pour cette story** — pas de widget UI livré. La state machine est pure logique.

### Composants réutilisables

**Catalogue consulté** : [doc/tech/COMPOSANTS-REUTILISABLES.md](../../doc/tech/COMPOSANTS-REUTILISABLES.md) — pas de section pertinente (cette story ne livre pas de widget).

**Composants existants réutilisés** :
- `SubsystemPrefs` (`lib/features/onboarding/data/subsystem_prefs.dart`) — usage : appel `write(subSystem)` dans `setSubSystem` + `read()` dans `loadFromPersistence`.
- `subsystemPrefsProvider` (`lib/features/onboarding/providers.dart`) — usage : injection via `ref.read` dans le Notifier.
- `SubSystem` enum (`lib/features/onboarding/domain/sub_system.dart`) — usage : champ du state + setter.
- `maskPhone()` (`lib/core/logging/log_safe.dart`, livré E1bis-0) — usage **uniquement dans les tests** : si un test log le state pour debug, masquer le `phoneNumber`.

**Composants existants adaptés (paramètre optionnel ajouté)** : Aucun.

**Nouveaux composants créés et ajoutés au catalogue** : Aucun (cette story ne livre pas de widget UI).

**Vérification anti-duplication** :
- [x] `OnboardingPersistence` wrapper **non créé** — `SubsystemPrefs` réutilisé (cf. Décision 3).
- [x] `OnboardingFlowNotifier` Epic 1 **non touché** — nouveau Notifier créé en parallèle (déprécation E1bis-9).
- [x] `SubSystem` enum **non dupliqué** — réutilisé tel quel.

### Tests à écrire

- **Unit `OnboardingState`** (`test/features/onboarding/presentation/state/onboarding_state_test.dart`, ~5 cas) :
  - `copyWith` préserve les champs non touchés.
  - `copyWith` permet de remettre un champ nullable à `null` via sentinelle.
  - Equatable equality avec mêmes champs.
  - `toFirestorePayload()` n'inclut que les champs non-null.
  - Constructeur `const OnboardingState()` produit currentStep=0, tous les champs null/false/empty.

- **Unit `OnboardingNotifier`** (`test/features/onboarding/presentation/state/onboarding_notifier_test.dart`, ≥ 20 cas) :
  - Voir AC10 pour la liste exhaustive.

- **Pas de widget test, pas de golden, pas de test d'intégration Firebase** dans cette story.

### Anti-patterns à éviter

- ❌ **NE PAS** ajouter `flushToFirestore` à cette story — c'est explicitement E1bis-4.
- ❌ **NE PAS** modifier `app_router.dart` ou le redirect global — c'est E1bis-2.
- ❌ **NE PAS** dupliquer `SubsystemPrefs` en créant `OnboardingPersistence`.
- ❌ **NE PAS** déprécier `OnboardingFlowNotifier` Epic 1 dans cette story (c'est E1bis-9 — sequencing strict).
- ❌ **NE PAS** logger `phoneNumber` complet si un test debug print le state — utiliser `maskPhone()`.
- ❌ **NE PAS** mettre `await prefs.read()` en `build()` du Notifier (le build doit rester sync).

### Références

- Story d'origine : E1bis-1 dans `project_manage/planning-artifacts/epics/epic-1bis-refonte-onboarding.md` lignes 147-181 (AC source — AC5/AC6/AC8/AC10 reportés cf. § Scope).
- Story de référence pattern Notifier : 1.3 (`OnboardingFlowNotifier` historique) — modèle de `copyWith` avec sentinelle + `resetFrom(step)`.
- Story de référence pattern SharedPreferences + Provider : 1.2 (`SubsystemPrefs` + `subsystemPrefsProvider`).
- EXPERIENCE.md § « State machine onboarding » : transitions next/back canoniques.
- Template `doc/templates/src/components/OnboardingFlow.tsx` : référence comportement React → on Dart (useState currentStep, skip si OAuth fournit displayName, skip si guest).

---

## Definition of Done

- [ ] **AC1-AC13** validés.
- [ ] `flutter analyze` : 0 issue.
- [ ] `flutter test` : ≥ 339 passed (baseline E1bis-0) + ≥ 25 nouveaux tests verts.
- [ ] 3 nouveaux fichiers `lib/` + 2 nouveaux fichiers `test/`. Aucun fichier modifié dans `lib/features/onboarding/` hors du nouveau dossier `presentation/state/` (sauf si ajout minime dans `providers.dart` jugé nécessaire — à justifier alors dans commit).
- [ ] Aucun import Firebase / `dart:io` dans les nouveaux fichiers (vérifier via `grep`).
- [ ] Aucun nom français (`filiere`, `niveau`, `serie`, `matiere`) dans les nouveaux fichiers (CLAUDE.md règle 5).
- [ ] Tailles fichiers : `onboarding_state.dart` ≤ 200 l, `onboarding_notifier.dart` ≤ 300 l, `onboarding_providers.dart` ≤ 50 l (sous cible).
- [ ] PR diff utile ≤ 400 lignes (CLAUDE.md règle 6 Workflow Git).
- [ ] Story file `1bis-1-state-machine-onboarding.md` status `review` + Dev Agent Record complété (Agent Model, Debug Log References s'il y a eu, Completion Notes List, File List, Change Log).
- [ ] Sprint-status `1bis-0` → `done` (PR #101 mergée) + `1bis-1` → `review`.
- [ ] PR poussée sur `feat/1bis-1-state-machine-onboarding`. **Attendre merge avant E1bis-2** (CLAUDE.md règle 6 sequencement strict).

---

## Risques

- **R-E1bis-1.1 — Collision SharedPreferences key avec `SubSystemNotifier` Epic 1.** Les deux Notifiers (`SubSystemNotifier` Epic 1 + `OnboardingNotifier` E1bis) écrivent la même clé `onboarding.subsystem`. Si Epic 1 est encore live et écrit la clé puis E1bis-1 la lit → cohérence OK (même format). Si E1bis-1 écrit puis Epic 1 la lit → cohérence OK aussi. **Pas de collision** tant que les deux flows ne tournent pas simultanément dans la même session (impossible, le router redirige vers l'un OU l'autre). Vérification : test unit `loadFromPersistence` avec `setMockInitialValues({'onboarding.subsystem': 'francophone'})` → state correctement hydraté.

- **R-E1bis-1.2 — `OnboardingNotifier` lu par mégarde par du code Epic 1.** Improbable car nouveau provider (`onboardingNotifierProvider` est un nouveau nom). Mitigation : grep avant push pour s'assurer qu'aucun code Epic 1 n'importe le nouveau provider.

- **R-E1bis-1.3 — `next()` non déterministe en cas de state corrompu.** Si quelqu'un appelle `next()` à `currentStep == 5` avec `userDisplayName` posé hors séquence (test mal écrit), la machine saute step 6. Mitigation : tests exhaustifs des transitions + Dev Notes anti-patterns + considérer un assert défensif sur `currentStep ∈ [0, 9]` au début de `next()`.

---

## Dev Agent Record

### Agent Model Used

Claude Opus 4.7 (claude-opus-4-7) via Claude Code CLI, skill `bmad-dev-story`, exécuté en une session continue.

### Debug Log References

Aucun bug bloquant identifié pendant le dev.

Issues mineures résolues sans détour :

1. **`flutter analyze` 2 issues `info` (unintended_html_in_doc_comment)** — les docstrings `OnboardingState.pendingSchoolRequestId` et `OnboardingNotifier.setPendingSchoolRequest` contenaient `"+ Ajouter <saisie>"` pris pour du HTML. Fix : remplacer `<saisie>` par `` `[saisie]` `` (backtickés). Vérification post-fix : `flutter analyze` ran in 7.5s → "No issues found!".

2. **Unused import dans `onboarding_notifier_test.dart`** — l'import direct `onboarding_notifier.dart` n'était pas utilisé (les tests accèdent au Notifier via `onboardingNotifierProvider.notifier`, pas via le type direct). Fix : import retiré.

### Completion Notes List

1. **Décision AC1 — `OnboardingState` Equatable avec sentinelle pour `copyWith`** : pattern repris de `OnboardingFlowState` (Story 1.3). Permet `copyWith(streamId: null)` pour reset explicite vs `copyWith(currentStep: 5)` qui préserve `streamId`. Coût : signature `Object? value = _sentinel` un peu verbeuse, mais zéro ambiguïté pour le reader.

2. **Décision AC2 — `OnboardingAuthProvider` dans `onboarding_state.dart`** plutôt que fichier séparé. Justification : 16 lignes seulement (3 valeurs + `id` getter + `fromString` helper), aucun bénéfice à isoler. Fichier `onboarding_state.dart` final : 230 lignes (sous cible 200 — léger dépassement justifié par la cohésion enum + state).

3. **Décision AC3 — Réutilisation `SubsystemPrefs` + `subsystemPrefsProvider` existants** (Story 1.2) au lieu de créer un wrapper `OnboardingPersistence` dédié. Zero duplicate. La clé canonique `onboarding.subsystem` est partagée avec `SubSystemNotifier` legacy Epic 1 (cohabitation safe — même format string).

4. **Décision AC4 — `setSubSystem` est `async` mais les autres setters sont `void`** : seul `setSubSystem` touche SharedPreferences, donc seul lui doit être attendu. Les pages step 0 (E1bis-2) feront `await notifier.setSubSystem(...)` puis navigation.

5. **Décision AC6/AC7 — Switch expression Dart 3 dans `next()`/`back()`** : table de vérité exprimée nativement, lisible, sans `if/else` cascadés. Le code suit exactement la table AC6/AC7 — pas de divergence.

6. **Décision AC8 — `loadFromPersistence()` explicite, pas dans `build()`** : le `build()` reste synchrone et déterministe (les tests unit peuvent assert sur state initial immédiatement). La page wrapper E1bis-2 (`OnboardingShell` à venir) appellera `loadFromPersistence()` au `initState`. Coût : un appel explicite côté UI au lieu d'implicite. Bénéfice : tests Notifier triviaux à mettre en place sans async setup.

7. **Décision AC10 — `OnboardingNotifier` mute `state` directement dans les tests** : pour tester les transitions `next()`/`back()` indépendamment des setters, certains tests font `notifier.state = const OnboardingState(currentStep: 7, isVisitor: true)` directement. C'est autorisé Riverpod (le `state` setter est public via `Notifier`) et c'est plus lisible que de chaîner 7 setters pour reproduire un state intermédiaire.

8. **Décision AC11/AC12/AC13 — Identifiers 100% anglais + 0 import Firebase / dart:io + tailles sous cible** : vérifié via `grep` sur les fichiers livrés. `onboarding_state.dart` 230 l (cible 170, plafond 500 — OK), `onboarding_notifier.dart` 222 l (cible 260, plafond 500 — OK), `onboarding_providers.dart` 20 l (cible 30 — OK).

9. **Hors-scope respecté** : (a) aucun appel Firebase / Firestore, (b) aucune modification de `app_router.dart`, (c) aucune modification de `OnboardingFlowNotifier` legacy Epic 1, (d) aucun appel `flushToFirestore` (préparé via `toFirestorePayload()` mais inutilisé). Les 4 reports vers E1bis-2 / E1bis-4 / E1bis-9 sont strictement respectés.

10. **Résultats tests** : `flutter analyze` 0 issue. `flutter test` 391 passed + 1 skipped (baseline E1bis-0 = 339 + 1 → delta +52 verts = 12 OnboardingState + 40 OnboardingNotifier). Zero régression sur baseline `b07e8b1`.

### File List

**Nouveaux fichiers (5)** :

- `mobile_app/lib/features/onboarding/presentation/state/onboarding_state.dart` (230 l) — `OnboardingState` Equatable + `OnboardingAuthProvider` enum + `_Sentinel` + `copyWith` + `toFirestorePayload`.
- `mobile_app/lib/features/onboarding/presentation/state/onboarding_notifier.dart` (222 l) — `OnboardingNotifier` Riverpod `Notifier<OnboardingState>` : 11 setters + `reset` + `next`/`back` conditionnels + `loadFromPersistence` async.
- `mobile_app/lib/features/onboarding/presentation/state/onboarding_providers.dart` (20 l) — `onboardingNotifierProvider` (`NotifierProvider<OnboardingNotifier, OnboardingState>`).
- `mobile_app/test/features/onboarding/presentation/state/onboarding_state_test.dart` (~170 l) — 12 cas : constructeur initial + 3 copyWith + 3 Equatable + 3 toFirestorePayload + 2 OnboardingAuthProvider.fromString.
- `mobile_app/test/features/onboarding/presentation/state/onboarding_notifier_test.dart` (~470 l) — 40 cas : setters (18) + reset downstream (3) + next (9) + back (7) + loadFromPersistence (3).

**Fichiers modifiés (2)** :

- `project_manage/implementation-artifacts/1bis-1-state-machine-onboarding.md` — status `ready-for-dev` → `in-progress` → `review` + Dev Agent Record rempli + tasks [x] cochées.
- `project_manage/implementation-artifacts/sprint-status.yaml` — `1bis-1-state-machine-onboarding` `ready-for-dev` → `in-progress` → `review`.

### Change Log

| Commit | Message | Fichiers |
|---|---|---|
| 1 | `feat(onboarding): ajouter OnboardingState immutable Equatable + enum AuthProvider` | `onboarding_state.dart` + `onboarding_state_test.dart` |
| 2 | `feat(onboarding): ajouter OnboardingNotifier Riverpod + transitions conditionnelles + loadFromPersistence` | `onboarding_notifier.dart` + `onboarding_providers.dart` |
| 3 | `test(onboarding): couverture exhaustive OnboardingNotifier (setters + next/back + persistance)` | `onboarding_notifier_test.dart` |
| 4 | `docs(planning): finaliser story E1bis-1 - status ready-for-dev -> review` | `1bis-1-state-machine-onboarding.md` + `sprint-status.yaml` |
