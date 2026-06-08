---
story_id: 1.5
title: Garde navigation profil-incomplet centralisée go_router (FR-4)
epic: 1
phase: P1
status: ready-for-dev
created: 2026-06-08
branch: feat/1.5-garde-navigation-profil-incomplet
baseline_commit: 04181cc  # merge commit Story 1.3 (PR #44)
estimation: S (~3-4h)
dependencies:
  - 1.2   # SubSystem fixé en SharedPreferences (subSystemNotifierProvider sync)
  - 1.3   # Profil créé : users/{uid} Firestore avec filiere/niveau/serie posés
  - 0.6   # Firebase Auth + Firestore providers (firebaseAuthProvider + firestoreProvider)
  - 0.7   # Cache offline Firestore 40MB activé (lecture users/{uid} offline OK)
  - 0.9   # Règles Firestore users/{uid} (lecture self-only — pas de fuite)
blocks:
  - 1.6   # Compte Google/Apple : redirect /onboarding/account valide quand profil complet
  - 1.9   # Dashboard skeleton : prerequis garde profil avant d'exposer dashboard métier
sourceArtifacts:
  - project_manage/planning-artifacts/epics/epic-1-onboarding.md § Story 1.5 (lignes 645-718)
  - project_manage/planning-artifacts/prds/prd-valide-mvp-2026-06-03/prd.md § FR-4 (lignes 143-150)
  - project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/EXPERIENCE.md § Règles de navigation (ligne 70 — "Garde profil-incomplet (FR-4)")
  - project_manage/planning-artifacts/architecture/adrs/ADR-006-subsystem-fixed-at-signup.md (subSystem immutable serveur)
  - mobile_app/lib/core/routing/app_router.dart (router actuel à étendre — Story 1.1c + 1.2 + 1.3 redirect en place)
  - mobile_app/lib/features/onboarding/providers.dart (subSystemNotifierProvider + onboardingFlowProvider + userProfileRepositoryProvider — Story 1.3)
  - mobile_app/lib/features/onboarding/domain/user_profile_repository.dart (interface — Story 1.3 expose seulement createProfile, Story 1.5 ajoute watchProfile)
  - mobile_app/lib/features/onboarding/data/user_profile_repository_firestore_impl.dart (impl Firestore à étendre)
  - mobile_app/lib/core/firebase/providers.dart (firebaseAuthProvider + firestoreProvider)
  - mobile_app/lib/core/logging/app_logger.dart (AppLogger.w pour fail-safe)
  - mobile_app/lib/features/splash/presentation/splash_page.dart (post-splash navigation, à harmoniser : `/hello` ou `/` selon completion)
  - mobile_app/lib/features/onboarding/presentation/profile_recap_page.dart (post-création users/{uid} → navigue vers `/hello` temporairement, à harmoniser)
---

# Story 1.5 — Garde navigation profil-incomplet centralisée go_router (FR-4)

Status: **ready-for-dev**

## Objectif

Livrer **la garde de navigation centralisée** qui, à chaque requête de route métier (cours, exercices, dashboard, classement…), vérifie l'état du profil utilisateur et redirige vers la prochaine étape d'onboarding manquante si le profil n'est pas complet — **logique unique dans `go_router.redirect`, jamais dispersée écran par écran** (FR-4 + EXPERIENCE.md ligne 70).

C'est la story qui scelle l'invariant FR-4 : **un utilisateur dont le profil n'est pas complet ne peut pas accéder à un autre écran que ceux d'inscription/profil**. Sans elle, dès qu'une route métier existera (dashboard 1.9, lessons E2), un deep link malveillant ou accidentel pourra court-circuiter l'onboarding.

**1 provider** + **1 enum** + **1 méthode repository** + **redirect étendu** livrés. Aucune nouvelle page UI.

**Pourquoi maintenant** : Story 1.3 vient de poser `users/{uid}` avec `filiere/niveau/serie`. Le terrain est prêt. Si on attend Epic 2 (lessons), on rétro-ajoute une garde après coup → risque de réintroduire les bugs Story 1.3 (in-component guards dispersés).

**Critère de fin** : un utilisateur sans `users/{uid}` (ou avec un doc partiel) qui tape `/lessons/maths` ou `/dashboard` est redirigé vers la 1ère étape manquante de l'onboarding **sans qu'aucune page métier ne soit jamais rendue, même un frame**.

## Story

**As a** tech lead Flutter,
**I want** une garde centralisée dans `go_router` qui redirige toute navigation vers une route métier (cours, exercice, dashboard, classement) lorsque le profil utilisateur est incomplet, vers l'étape d'onboarding en cours,
**so that** FR-4 soit appliqué de façon homogène et auditable, sans logique dispersée dans chaque feature, et qu'un futur deep link malveillant ne contourne pas l'onboarding.

## Acceptance Criteria

### AC1 — Enum `ProfileCompletionState` + provider `profileCompletionProvider`

**Given** un utilisateur (état Firestore `users/{uid}` + état `subSystemNotifierProvider`)
**When** on lit `ref.read(profileCompletionProvider)` (AsyncValue)
**Then** il retourne un `ProfileCompletionState` parmi 5 états :

```dart
enum ProfileCompletionState {
  subsystemMissing,  // 1. subSystemNotifierProvider == null
  filiereMissing,    // 2. subSystem OK, users/{uid} absent OU sans champ 'filiere'
  niveauMissing,     // 3. filiere OK, sans 'niveau'
  serieMissing,      // 4. niveau OK, sans 'serie' (et le niveau a des séries)
  complete;          // 5. tous champs présents + non vides

  /// Route cible si l'utilisateur tente une nav métier dans cet état.
  String get nextOnboardingRoute => switch (this) {
    ProfileCompletionState.subsystemMissing => '/onboarding/subsystem',
    ProfileCompletionState.filiereMissing  => '/onboarding/profile/filiere',
    ProfileCompletionState.niveauMissing   => '/onboarding/profile/niveau',
    ProfileCompletionState.serieMissing    => '/onboarding/profile/serie',
    ProfileCompletionState.complete        => '/',
  };

  bool get isComplete => this == ProfileCompletionState.complete;
}
```

**And** la dérivation lit dans cet ordre :

1. `subSystemNotifierProvider` (sync, depuis SharedPreferences — préchargé au boot Story 1.2). Si `null` → `subsystemMissing`. Court-circuit.
2. `firebaseAuthProvider.currentUser?.uid`. Si `null` → log warn + `filiereMissing` (fail-safe : l'utilisateur n'est pas auth, l'onboarding va re-déclencher Anonymous Auth via SplashPage Story 0.21).
3. Stream `firestore.collection('users').doc(uid).snapshots()` (cache offline OK — NFR-5 + ADR-010, lecture sans coût réseau si offline). Pour chaque snapshot :
   - `!doc.exists` → `filiereMissing` (sera le cas du visiteur mi-flow qui n'a pas encore tap "C'est ma classe")
   - `data['filiere']` absent/vide/null → `filiereMissing`
   - `data['niveau']` absent/vide/null → `niveauMissing`
   - `data['serie']` absent/null → `serieMissing` (note : la valeur sentinelle `'-'` posée Story 1.3 pour les niveaux sans série compte comme **présent** — ce n'est pas vide)
   - Sinon → `complete`
4. Sur erreur de read Firestore (`FirebaseException permission-denied`, `unavailable` réseau) → log warn + `filiereMissing` (fail-safe : redirige vers onboarding plutôt que d'autoriser une route métier qui crasherait derrière).

**And** un test unitaire vérifie les **5 cas + 2 cas d'erreur** dans `test/features/onboarding/providers/profile_completion_provider_test.dart` via `FakeFirebaseFirestore` :

- (a) `subSystem == null` → `subsystemMissing`
- (b) `subSystem != null` + users/{uid} absent → `filiereMissing`
- (c) doc avec `filiere == ''` → `filiereMissing`
- (d) doc avec filière mais `niveau == null` → `niveauMissing`
- (e) doc avec filière + niveau mais `serie == ''` → `serieMissing`
- (f) doc avec tous champs non vides (`serie == '-'` ok ; `serie == 'francophone_terminale_d'` ok) → `complete`
- (g) `auth.currentUser == null` (post-déconnexion) → `filiereMissing` + AppLogger.w émis

### AC2 — Redirect centralisé dans `GoRouter`

**Given** la configuration `GoRouter` actuelle (Story 1.1c + 1.2 + 1.3 — `app_router.dart`)
**When** une route est requested
**Then** le callback `redirect` applique cette logique dans cet ordre :

1. **Bypass système** : routes `/`, `/splash`, toute route commençant par `/_` (debug) → `return null`.
2. **Catalogue check (Story 1.1c, préservé tel quel)** : si `appStartupCatalogueCheckProvider` indique vide+offline → `/catalogue-waiting`. La route `/catalogue-waiting` elle-même n'est pas redirigée.
3. **Story 1.2 anti-replay (préservé)** : si subSystem présent ET route `==` `/onboarding/subsystem` → `return '/'` (renvoie home pour relancer le flow normal).
4. **Story 1.5 garde profil-incomplet (NEW)** : pour les routes **hors `/onboarding/*` ET hors `/catalogue-waiting`** (donc les routes métier futures + l'actuelle `/hello`) :
   - Lire `ref.read(profileCompletionProvider)` (AsyncValue).
   - Si `data(complete)` → `return null` (laisse passer).
   - Si `data(autre état)` → `return state.nextOnboardingRoute` (redirige vers la 1ère étape manquante).
   - Si `loading` → `return null` (laisse passer, le frame suivant le stream aura délivré une valeur ; cf. raisonnement UX-DR-XX en dev notes).
   - Si `error` → `return '/onboarding/subsystem'` (fail-safe + log warn).
5. **Bypass `/onboarding/*`** : ces routes sont laissées passer (les guards de cohérence mi-flow restent gérés par les pages elles-mêmes — Story 1.3 in-component guards).

**And** un test integration `test/core/routing/app_router_redirect_test.dart` vérifie **5 cas de redirect** via `MockGoRouter` ou `ProviderContainer` + `GoRouter.tester` :

- (a) subSystem null + tentative `/hello` → redirect `/onboarding/subsystem`
- (b) subSystem OK + users/{uid} absent + tentative `/lessons/maths` (route hypothétique) → redirect `/onboarding/profile/filiere`
- (c) users/{uid} complet + tentative `/hello` → passe (null)
- (d) users/{uid} complet + tentative `/onboarding/profile/recap` → passe (null — `/onboarding/*` bypass)
- (e) subSystem null + tentative `/_crash` → passe (null — `/_*` bypass)

### AC3 — Deep link `/lessons/{id}` avec profil incomplet → redirect

**Given** un utilisateur avec `subSystem == 'francophone'` ET sans `users/{uid}` (visiteur après Story 1.2, avant Story 1.3 terminée)
**When** un deep link `/lessons/maths_derivees` est ouvert (route hypothétique Epic 2 — Story 1.5 doit la protéger avant qu'elle existe)
**Then** le router redirige vers `/onboarding/profile/filiere` (1ère étape manquante)
**And** aucun fragment de page métier n'est rendu (pas de skeleton, pas de placeholder)
**And** un `AppToast.show(AppLocalizations.of(context).profileIncompleteToast)` est déclenché par la page de destination si elle veut (optionnel V1 — implémentation différée tant qu'aucune page métier n'existe).

**Note implémentation** : pour valider AC3 sans page métier livrée, le test integration utilise une route `/_test_protected` ajoutée **uniquement en mode debug** (sous `if (kDebugMode)`) — ou plus simplement, le test instancie une route fictive `/protected` et observe le redirect. Aucune route business réelle n'est introduite par Story 1.5.

### AC4 — Pas de redirection une fois profil complet

**Given** un profil complet (`users/{uid}` avec `filiere/niveau/serie` non vides)
**When** l'utilisateur navigue vers `/hello`, `/`, ou un deep link futur `/lessons/X` / `/dashboard`
**Then** la route est servie normalement
**And** aucun redirect parasite ne se déclenche, même au cold start (le 1er frame peut être `loading` → bypass cohérent AC2)

### AC5 — Routes `/onboarding/*` accessibles inconditionnellement

**Given** un utilisateur dans n'importe quel état (subSystem null, profil partiel, ou complet)
**When** il accède manuellement à `/onboarding/profile/filiere`, `/onboarding/profile/niveau`, `/onboarding/profile/serie`, ou `/onboarding/profile/recap`
**Then** la route est servie (router redirect retourne `null` pour `/onboarding/*`)
**And** les guards de cohérence in-component Story 1.3 restent en place (ex. `/onboarding/profile/recap` redirige vers `/onboarding/profile/filiere` si `flow.isComplete == false`) — **non touchés par Story 1.5**

**Justification** : la garde Story 1.5 protège les routes **métier**. Les routes `/onboarding/*` sont elles-mêmes l'antidote au profil incomplet — les bloquer serait contre-productif. La cohérence mi-flow reste gérée par les in-component guards livrés Story 1.3.

### AC6 — Logique de fail-safe + logs

**Given** un état dégradé (erreur Firestore, auth dropped, stream cancel)
**When** `profileCompletionProvider` rencontre l'erreur
**Then** :

- Émet `ProfileCompletionState.filiereMissing` (état le plus restrictif après `subsystemMissing`, redirige vers profil)
- Log `AppLogger.w('profileCompletion: fail-safe (filiereMissing) — reason=...')` avec :
  - `reason` = `'auth missing'`, `'firestore permission-denied'`, `'firestore unavailable'`, ou `'stream error: <code>'`
  - **JAMAIS** l'uid complet (CLAUDE.md § Sécurité 4 — uniquement subSystem)
- Le router consomme cet état comme `data(filiereMissing)` → redirige vers `/onboarding/profile/filiere`. Pas de boucle infinie : `/onboarding/profile/filiere` est bypass donc le redirect retourne `null` une fois sur place.

**Justification fail-safe vers `filiereMissing` plutôt que `subsystemMissing`** : si on est au point où Firestore échoue mais que le subSystem est posé en SharedPreferences, on suppose que le flow a déjà démarré. Renvoyer à `/onboarding/subsystem` ferait perdre le subSystem (Story 1.2 anti-replay redirige immédiatement vers `/`). `/onboarding/profile/filiere` est la 1ère étape utile et permet de relancer le flow sans repartir de zéro.

### AC7 — `UserProfileRepository.watchProfile()` ajoutée à l'interface

**Given** l'interface `UserProfileRepository` actuelle (Story 1.3 expose `createProfile(...)` seulement)
**When** on étend l'interface pour Story 1.5
**Then** ajouter une méthode :

```dart
abstract interface class UserProfileRepository {
  // existant Story 1.3
  Future<Either<ProfileFailure, void>> createProfile({...});

  // Story 1.5 — NEW
  /// Stream du doc users/{uid}. Émet le snapshot (possiblement absent ou
  /// partiel) à chaque update Firestore. Lecture en cache offline (NFR-5).
  ///
  /// Émet `null` si l'utilisateur n'est pas authentifié.
  /// Émet `Map<String, dynamic>?` (data du doc OU null si !doc.exists) sinon.
  ///
  /// Le mapping vers ProfileCompletionState est fait par
  /// `profileCompletionProvider` — le repo retourne la donnée brute.
  Stream<Map<String, dynamic>?> watchProfile();
}
```

**Implémentation Firestore** (`UserProfileRepositoryFirestoreImpl`) :

```dart
@override
Stream<Map<String, dynamic>?> watchProfile() {
  final uid = _getUid();
  if (uid == null) {
    // Stream vide qui émet null immédiatement (pas une erreur — l'auth peut
    // arriver plus tard via _e0SmokeTest Story 0.21).
    return Stream.value(null);
  }
  return _firestore
      .collection(_kCollection)
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? doc.data() : null)
      .handleError((Object e, StackTrace st) {
        AppLogger.w('watchProfile() stream error: $e');
        AppLogger.w('watchProfile() stack: $st');
        // L'erreur est propagée — profileCompletionProvider la traduit en
        // ProfileCompletionState.filiereMissing via .when(error: ...).
      });
}
```

**And** un test `user_profile_repository_test.dart` couvre :

- (h) `watchProfile()` avec doc présent → émet la map
- (i) `watchProfile()` avec doc absent → émet null
- (j) `watchProfile()` avec uid absent → émet null (Stream.value(null))

### AC8 — refreshListenable étendu + i18n optionnelle

**Given** le `refreshListenable` actuel (ValueNotifier<int> écouté par 3 `ref.listen` : catalogue + subSystem + flowProvider, Story 1.1c + 1.2 + 1.3)
**When** on étend pour Story 1.5
**Then** ajouter un 4e `ref.listen(profileCompletionProvider, ...)` qui incrémente le notifier à chaque transition d'état (le changement de complétion doit déclencher une ré-évaluation du redirect — sinon un utilisateur qui finit son profil pendant qu'il est sur `/onboarding/profile/recap` puis qui navigue verra son router évalué avec l'ancien état).

**i18n (optionnelle V1)** : prévoir 1 clé ARB FR + EN pour un toast futur (« Termine ton profil pour continuer. » / « Complete your profile to continue. ») — utilisée par Stories Epic 2 quand les routes métier existeront. Si pas utilisée par Story 1.5, la clé reste en réserve.

**ARB clés ajoutées (réservées)** :

- `profileGuardIncompleteToast` ("Termine ton profil pour continuer.")

EN : "Complete your profile to continue."

### AC9 — Tests Flutter + qualité

**Given** la PR finalisée
**When** on exécute la validation
**Then** :

- **Tests unitaires `ProfileCompletionState`** : 1 cas (vérifie le mapping `nextOnboardingRoute` pour les 5 états)
- **Tests unitaires `profileCompletionProvider`** : 7 cas (AC1 a-g)
- **Test repository `watchProfile()`** : 3 cas (AC7 h-j)
- **Test integration router redirect** : 5 cas (AC2 a-e)
- `flutter analyze` 0 issue préservé (113 tests baseline Story 1.3 → 128+ tests cible Story 1.5)
- `flutter test` complet vert (no régression)
- **PR ≤ 250 lignes diff** hors l10n générée (~250 cible — légèrement étendue par rapport au DoD epic 200 lignes car le refreshListenable + repo extension justifient les ~50 lignes supplémentaires)
- Commit : `feat(onboarding): garde navigation profil-incomplet centralisee (Story 1.5)`

## Tasks / Subtasks

- [ ] **T1 — Domain : `ProfileCompletionState` enum** (AC1)
  - [ ] T1.1 — Créer `mobile_app/lib/features/onboarding/domain/profile_completion_state.dart` avec enum + getter `nextOnboardingRoute` + getter `isComplete`
  - [ ] T1.2 — Pas de dépendance Flutter ni Firebase (domain pur — ADR-001 règle d'or)
  - [ ] T1.3 — Test unitaire `test/features/onboarding/domain/profile_completion_state_test.dart` : mapping `nextOnboardingRoute` pour les 5 états + `isComplete` only pour `complete`

- [ ] **T2 — Domain : étendre `UserProfileRepository`** (AC7)
  - [ ] T2.1 — Ouvrir `mobile_app/lib/features/onboarding/domain/user_profile_repository.dart`
  - [ ] T2.2 — Ajouter signature `Stream<Map<String, dynamic>?> watchProfile()` avec docstring
  - [ ] T2.3 — Domain pur — pas d'import Firebase

- [ ] **T3 — Data : implémenter `watchProfile()` dans `UserProfileRepositoryFirestoreImpl`** (AC7)
  - [ ] T3.1 — Ouvrir `mobile_app/lib/features/onboarding/data/user_profile_repository_firestore_impl.dart`
  - [ ] T3.2 — Ajouter méthode `watchProfile()` :
    - Si `_getUid() == null` → `Stream.value(null)`
    - Sinon → `firestore.collection('users').doc(uid).snapshots().map((doc) => doc.exists ? doc.data() : null)`
  - [ ] T3.3 — `.handleError` qui log `AppLogger.w` mais ne propage pas (l'erreur est traduite en `filiereMissing` par le provider en aval)
  - [ ] T3.4 — Test `test/features/onboarding/data/user_profile_repository_test.dart` étendu avec 3 cas (h/i/j) via `FakeFirebaseFirestore` + `GetUidFn` closure (pattern Story 1.3)

- [ ] **T4 — Providers : `profileCompletionProvider`** (AC1, AC6)
  - [ ] T4.1 — Étendre `mobile_app/lib/features/onboarding/providers.dart` (existant Story 1.2 + 1.3)
  - [ ] T4.2 — Créer `profileCompletionProvider` : `StreamProvider<ProfileCompletionState>` qui :
    - Watch `subSystemNotifierProvider` → si null émet `subsystemMissing` et return
    - Read `firebaseAuthProvider.currentUser?.uid` → si null émet `filiereMissing` + log warn
    - Subscribe à `userProfileRepositoryProvider.watchProfile()`
    - Pour chaque snapshot map → calcule `ProfileCompletionState` selon AC1 (filiere/niveau/serie présence)
    - `.handleError` → émet `filiereMissing` + log warn avec `reason` masquée (jamais l'uid complet)
  - [ ] T4.3 — Test `test/features/onboarding/providers/profile_completion_provider_test.dart` : 7 cas AC1 (a-g) via `ProviderContainer` + override de `userProfileRepositoryProvider` avec un mock qui émet des Maps configurables

- [ ] **T5 — Routing : étendre `GoRouter.redirect`** (AC2, AC4, AC5)
  - [ ] T5.1 — Ouvrir `mobile_app/lib/core/routing/app_router.dart`
  - [ ] T5.2 — Réorganiser le bloc `redirect` selon l'ordre AC2 (bypass système → catalogue → anti-replay subsystem → garde profil-incomplet → bypass /onboarding/*)
  - [ ] T5.3 — Ajouter la lecture `ref.read(profileCompletionProvider)` avec `AsyncValue.maybeWhen` :
    - `data(complete)` → `return null`
    - `data(autre)` → `return state.nextOnboardingRoute`
    - `loading` → `return null` (laisse passer le frame initial pour éviter flash)
    - `error` → `return '/onboarding/subsystem'` + log warn (fail-safe — ne devrait pas arriver car le provider lui-même intercepte ses erreurs)
  - [ ] T5.4 — Étendre `refreshListenable` avec un 4e `ref.listen(profileCompletionProvider, ...)` qui incrémente `notifier.value++` à chaque transition d'état
  - [ ] T5.5 — Vérifier que les commentaires existants Story 1.1c + 1.2 + 1.3 sont préservés (pas de churn cosmétique)
  - [ ] T5.6 — Test integration `test/core/routing/app_router_redirect_test.dart` : 5 cas AC2 (a-e) avec `MaterialApp.router` + `ProviderScope.overrides`

- [ ] **T6 — i18n (réservée)** (AC8)
  - [ ] T6.1 — Ajouter 1 clé FR + EN dans `mobile_app/lib/l10n/app_fr.arb` + `app_en.arb` :
    - `profileGuardIncompleteToast` ("Termine ton profil pour continuer." / "Complete your profile to continue.")
  - [ ] T6.2 — Description ARB explique que la clé est **réservée** pour usage futur (Story 1.9 dashboard ou Epic 2)
  - [ ] T6.3 — `flutter gen-l10n` régénère AppLocalizations sans erreur

- [ ] **T7 — Validation finale** (AC9)
  - [ ] T7.1 — `cd mobile_app && flutter analyze` → 0 issue
  - [ ] T7.2 — `cd mobile_app && flutter test` → tous verts (113 baseline → ~128 cible)
  - [ ] T7.3 — Smoke device : 3 scénarios
    - (a) cold start visiteur (jamais ouvert l'app) → `/splash` → `/onboarding/subsystem` (aucun redirect parasite)
    - (b) cold start avec subSystem + sans users/{uid} → `/splash` → `/hello` → redirect `/onboarding/profile/filiere`
    - (c) cold start avec profil complet → `/splash` → `/hello` (aucun redirect)
  - [ ] T7.4 — Vérifier diff PR ≤ 250 lignes
  - [ ] T7.5 — Update story file frontmatter status: ready-for-dev → review (après dev) + sprint-status.yaml backlog → ready-for-dev (auto par cette skill) → review (post-dev) + commit + push

## Dev Notes

### Architecture compliance (ADR-001 + ADR-006 + NFR-9)

- **Règle d'or des dépendances** (CLAUDE.md § Architecture 1) : `ProfileCompletionState` enum vit dans `domain/` — aucun import Firebase, Riverpod, ni Flutter.
- **NFR-7** : `profileCompletionProvider` retourne un `AsyncValue<ProfileCompletionState>`. Les erreurs Firestore sont attrapées dans le repo (handleError) ou dans le provider (.handleError) et traduites en state restrictif. **Aucune `FirebaseException` ne remonte au router**.
- **NFR-9 (vrai verrou serveur)** : Story 1.5 est une **optimisation UX**, pas un verrou. Le vrai verrou est dans les règles Firestore (Story 0.9 + 1.3 : `users/{uid}` lecture self-only, écriture limitée). Si un utilisateur contourne la garde Flutter, il ne peut rien lire/écrire de plus.
- **ADR-006 (subSystem immutable)** : Story 1.5 ne touche pas le subSystem. Il est juste lu (sync) pour court-circuiter le check Firestore.
- **ADR-010 (pas de cache custom)** : utilisation du cache Firestore natif. `snapshots()` retourne immédiatement le cache offline si disponible (Story 0.7 cache 40MB activé).

### Pattern Riverpod : pourquoi StreamProvider, pas FutureProvider ?

- `StreamProvider` émet à chaque snapshot Firestore → react au moment où l'utilisateur termine son profil (Story 1.3 `createProfile()` → snapshot émis → provider passe à `complete` → router re-évalue).
- `FutureProvider` aurait nécessité une `invalidate()` manuelle après `createProfile()` → couplage spaghetti.

### Pattern Router redirect : pourquoi maybeWhen et pas .when ?

- Le `when()` exige une gestion explicite des 3 états (data/loading/error). `maybeWhen` permet un défaut `orElse: () => null` plus lisible.
- Cf. usage déjà en place dans `app_router.dart` ligne 74 (catalogue check) — pattern cohérent.

### Ordre des checks dans le redirect : pourquoi catalogue avant profil ?

- Le catalogue est une prérequis **système** (pas de catalogue → impossible de dériver le profil même).
- Si on inversait (profil avant catalogue), un utilisateur sans catalogue qui ouvre `/onboarding/profile/filiere` verrait la page se rendre avec un stream vide → expérience cassée.
- Order finalisé : système → catalogue → anti-replay → profil → bypass.

### Anti-pattern : NE PAS centraliser les in-component guards Story 1.3

- La tentation est de supprimer les guards in-component dans `filiere_choice_page.dart`, `niveau_choice_page.dart`, `serie_choice_page.dart`, `profile_recap_page.dart` (Story 1.3 lignes 45-55 etc.).
- **NE PAS LE FAIRE en Story 1.5.** Raisons :
  1. Ces guards protègent la **cohérence in-memory du flow** (`onboardingFlowProvider`), pas la complétion users/{uid}. Concerns orthogonaux.
  2. Story 1.5 redirect bypass `/onboarding/*` → les guards in-component restent l'unique défense pour les transitions interne mi-flow.
  3. Diff économisé. PR ≤ 250 lignes.
- **À reconsidérer** : Story 1.8 (persistance session reprise flow) — si elle réintroduit un état persistant pour `onboardingFlowProvider`, on pourra revoir si certains guards peuvent migrer dans le router.

### Anti-pattern : NE PAS lire users/{uid} dans `derivedProfileProvider`

- `derivedProfileProvider` (Story 1.3) lit `flow.filiereId / niveauId / serieId` (in-memory). C'est correct : la dérivation se fait avant la création Firestore.
- Story 1.5 lit `users/{uid}` (Firestore) → c'est pour la **garde** post-création.
- Confusion à éviter : les deux providers cohabitent, n'écrasent pas l'un l'autre.

### Sécurité — règle CLAUDE.md § 4

- **JAMAIS** logger l'uid complet. Toujours masquer ou ne logger que `subSystem` + raison.
- Exemple correct : `AppLogger.w('profileCompletion: fail-safe reason=firestore-permission-denied subSystem=${subSystem.id}')`
- Exemple **incorrect** : `AppLogger.w('profileCompletion fail-safe uid=$uid')` ← banni.

### Comportement loading initial : pourquoi laisse passer ?

- Au cold start, `profileCompletionProvider` est en `loading` pendant ~50-200ms (le premier snapshot Firestore cache ou réseau).
- Si on redirigeait pendant `loading`, l'utilisateur verrait : `/splash` → flash de `/onboarding/subsystem` → page cible.
- En laissant passer (`return null`) pendant `loading`, on permet à la page cible de se rendre avec son `AsyncValue.when(loading: skeleton, data: …)`. La transition est fluide.
- **Risque sécurité** : pendant le frame `loading`, un utilisateur sans profil pourrait voir une page métier 50ms. **Accepté** car :
  - Les données métier sont protégées par Firestore rules (NFR-9). Aucune fuite réelle.
  - Le frame suivant le `data(filiereMissing)` redirige proprement.
- Pour les routes ultra-sensibles (paiement, suppression compte), on pourra ajouter un guard `loading: redirect to splash` dans des Stories futures.

### Cas edge — `serie == '-'`

- Story 1.3 a posé `serie: '-'` (sentinelle) pour les niveaux sans série (6ᵉ francophone, Form 1-4 anglophone).
- `ProfileCompletionState.serieMissing` doit considérer `'-'` comme **présent** (le sentinel signifie "explicitement pas de série", pas "manquant").
- Implémentation : `if (data['serie'] == null || data['serie'] == '')` → serieMissing. Le `'-'` passe.

### Cas edge — utilisateur déconnecté en cours de session

- Si `firebaseAuthProvider.currentUser` devient null (déconnexion programmée future), le stream émettrait une erreur ou null.
- Le repo `watchProfile()` gère ce cas : retourne `Stream.value(null)` immédiatement.
- Le provider mappe `null` → `filiereMissing` → redirect vers `/onboarding/profile/filiere`.
- Si l'utilisateur n'a pas re-authentifié à ce moment, la page filière fonctionnera quand même (lecture catalogue auth-only OK avec Anonymous Auth).

### Pattern test : `ProviderContainer` + override `userProfileRepositoryProvider`

```dart
final mockRepo = MockUserProfileRepository();
when(mockRepo.watchProfile()).thenAnswer((_) => Stream.value({
  'filiere': 'generale',
  'niveau': 'francophone_terminale',
  'serie': 'francophone_terminale_d',
}));

final container = ProviderContainer(overrides: [
  userProfileRepositoryProvider.overrideWithValue(mockRepo),
  subSystemNotifierProvider.overrideWith(() => _StubSubsystemNotifier(SubSystem.francophone)),
]);

final state = await container.read(profileCompletionProvider.future);
expect(state, ProfileCompletionState.complete);
```

### Smoke device — scénarios à valider après merge

- (a) Cold start sur device vierge → `/splash` → `/onboarding/subsystem` (aucun flash métier)
- (b) Compléter onboarding jusqu'à "C'est ma classe" → vérifier que la nav suivante (vers `/hello` placeholder Story 1.3) passe sans redirect
- (c) Tuer l'app + relancer après création profil → cold start direct sur `/hello` sans flash de `/onboarding/*`

### File List

**Nouveaux** :

- `mobile_app/lib/features/onboarding/domain/profile_completion_state.dart` (~30 lignes)
- `mobile_app/test/features/onboarding/domain/profile_completion_state_test.dart` (~30 lignes)
- `mobile_app/test/features/onboarding/providers/profile_completion_provider_test.dart` (~150 lignes — 7 cas)
- `mobile_app/test/core/routing/app_router_redirect_test.dart` (~150 lignes — 5 cas integration)

**Modifiés** :

- `mobile_app/lib/features/onboarding/domain/user_profile_repository.dart` (+~10 lignes — signature `watchProfile()`)
- `mobile_app/lib/features/onboarding/data/user_profile_repository_firestore_impl.dart` (+~25 lignes — impl `watchProfile()`)
- `mobile_app/lib/features/onboarding/providers.dart` (+~50 lignes — `profileCompletionProvider`)
- `mobile_app/lib/core/routing/app_router.dart` (+~30 lignes — redirect étendu + 4e listen)
- `mobile_app/lib/l10n/app_fr.arb` (+~3 lignes — 1 clé réservée)
- `mobile_app/lib/l10n/app_en.arb` (+~3 lignes — 1 clé réservée)
- `mobile_app/lib/l10n/generated/app_localizations*.dart` (+~10 lignes auto gen-l10n)
- `mobile_app/test/features/onboarding/data/user_profile_repository_test.dart` (+~50 lignes — 3 cas h/i/j)
- `project_manage/implementation-artifacts/1-5-garde-navigation-profil-incomplet.md` (frontmatter + Tasks + Dev Agent Record)
- `project_manage/implementation-artifacts/sprint-status.yaml`

### Change Log

| Date | Auteur | Modification |
|---|---|---|
| 2026-06-08 | Claude Opus 4.7 | Story 1.5 contexte engine créé — comprehensive developer guide |

---

**Ultimate context engine analysis completed — comprehensive developer guide created.**

Cette story est `ready-for-dev`. Amelia (via `/bmad-dev-story`) a tout pour implémenter sans ambiguïté :

- Architecture clean (domain enum + interface étendue + provider StreamProvider + router redirect)
- 5 états ProfileCompletionState + mapping nextOnboardingRoute + isComplete
- Pattern Riverpod 3.x (StreamProvider + ref.listen pour refreshListenable)
- Pattern Firestore snapshots() + handleError + cache offline (Story 0.7)
- 5 cas integration router redirect + 7 cas provider + 3 cas repo + 1 cas enum mapping
- Fail-safe sur tous chemins d'erreur (auth dropped, permission-denied, unavailable)
- Anti-patterns LLM disaster prevention (pas de suppression des in-component guards Story 1.3, pas de centralisation prématurée, pas de log uid)
- Intelligence Stories 1.1c + 1.2 + 1.3 (patterns refreshListenable + redirect + repo + providers + tests réutilisés)
- File List explicite par tâche + estimation diff ≤ 250 lignes
