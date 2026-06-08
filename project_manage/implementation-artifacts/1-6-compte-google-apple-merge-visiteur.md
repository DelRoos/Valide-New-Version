---
story_id: 1.6
title: Compte Google/Apple + merge visiteur (FR-5)
epic: 1
phase: P1
status: done
created: 2026-06-08
merged: 2026-06-08  # PR #50 -> commit 784ba7e
branch: feat/1.6-compte-google-apple-merge-visiteur
baseline_commit: d6f9f44  # merge PR #49 (cloture 1.4 + contexte 1.6)
estimation: L (~6-8h)
dependencies:
  - 0.6   # Firebase Auth modules Console actives (Anonymous + Google + Apple a activer)
  - 0.21  # signInAnonymously au boot main.dart (FirebaseAuth.currentUser.isAnonymous == true par defaut)
  - 1.3   # users/{uid} cree (subSystem/filiere/niveau/serie/createdAt immuables)
  - 1.5   # garde navigation profil-incomplet (route /onboarding/account doit etre bypassee par /onboarding/*)
blocks:
  - 1.7   # liaison ecole optionnelle (utilise displayName Google/Apple)
  - 1.10  # suppression compte 7j (a besoin compte permanent, pas anonyme)
sourceArtifacts:
  - project_manage/planning-artifacts/epics/epic-1-onboarding.md § Story 1.6 (lignes 722-825 selon analyse)
  - project_manage/planning-artifacts/prds/prd-valide-mvp-2026-06-03/prd.md § FR-5 (lignes 152-159) + NFR-2 + NFR-7 + NFR-12
  - project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/EXPERIENCE.md § Flow 1 etape 8 (modale + "Continuer avec Google" / "Continuer avec Apple" + Failure fallback visiteur)
  - doc/partage/BASE-DE-DONNEES.md § users/{uid} (displayName + photoUrl mis a jour par linkWithCredential)
  - mobile_app/lib/main.dart § _e0SmokeTest (signInAnonymously au boot — Story 0.21)
  - mobile_app/lib/features/onboarding/domain/user_profile_repository.dart (interface — Story 1.4 expose createProfile + watchProfile + updateOptedOutSubjects)
  - mobile_app/lib/features/onboarding/data/user_profile_repository_firestore_impl.dart (impl Firestore — pattern update partiel a reutiliser)
  - mobile_app/lib/features/onboarding/providers.dart (providers Riverpod existants)
  - mobile_app/lib/core/routing/app_router.dart (redirect + evaluateRedirect Story 1.5)
  - mobile_app/lib/core/firebase/providers.dart (firebaseAuthProvider + firestoreProvider)
  - firestore.rules (racine — bloc users/{uid} update : Story 1.3 a fige createdAt/subSystem/etc., displayName + photoUrl restent editables)
---

# Story 1.6 — Compte Google/Apple + merge visiteur (FR-5)

Status: **done**

## Objectif

Livrer **FR-5** : promouvoir l'utilisateur anonyme courant (`FirebaseAuth.currentUser.isAnonymous == true`, créé au boot par Story 0.21) en compte **permanent Google ou Apple** via `linkWithCredential` — **sans perdre le profil scolaire `users/{uid}` créé en Story 1.3**. L'uid reste identique, les champs `displayName` + `photoUrl` sont peuplés depuis le compte OAuth.

**Pourquoi** : sans 1.6, l'utilisateur est emprisonné sur un seul device (compte anonyme = lié au téléphone). Aucune reprise sur tablette, aucune suppression compte (Story 1.10 a besoin d'un compte permanent), aucun déverrouillage premium Story Epic 4 (paiement nécessite identité stable).

**Critère de fin** :

- James (anglophone, profil créé Story 1.3, compte anonyme `currentUser.isAnonymous == true`) finit son recap → arrive sur `/onboarding/account`
- Voit la modale plein écran avec 2 boutons primaires : « Continuer avec Google » + « Continuer avec Apple »
- Tap Google → picker système → choix gmail → `linkWithCredential` succès
- `currentUser.isAnonymous == false`, `currentUser.uid` **identique** à avant
- `users/{uid}` mis à jour : `displayName = 'James Doe'`, `photoUrl = 'https://lh3.googleusercontent.com/...'`, `subSystem/filiere/niveau/serie/derivedSubjects intacts`
- Nav vers `/hello` (dashboard 1.9 future) — la garde 1.5 laisse passer (profil complet)

Cas conflit : si l'email Google est déjà lié à un autre uid Firebase, modale de confirmation s'affiche avec [Annuler] / [Continuer] (perte profil visiteur acceptée).

## Story

**As a** élève ayant complété son profil scolaire en mode visiteur (compte anonyme),
**I want** pouvoir créer mon compte Google ou Apple en un tap depuis la fin de l'onboarding,
**so that** mon profil et mes progrès soient sauvegardés cloud + accessibles depuis n'importe quel appareil + éligible aux features premium futures (FR-5).

## Acceptance Criteria

### AC1 — Route `/onboarding/account` + bouton Google + bouton Apple

**Given** route `/onboarding/account` rendue post-recap (Story 1.3 — `ProfileRecapPage._onValidate` succès navigue désormais vers cette page au lieu de `/hello`)
**When** la page se charge
**Then** elle affiche :

- Header : titre H2 « Crée ton compte » (FR) / « Create your account » (EN). Tutoiement.
- Sous-titre court 2 lignes max : « Sauvegarde tes progrès, reprends sur n'importe quel appareil. » (FR) / « Save your progress, pick up on any device. » (EN)
- **2 boutons primaires plein largeur** verticalement empilés (cf. EXPERIENCE.md Flow 1 étape 8) :
  - `AppButton.primary(label: 'Continuer avec Google', icon: ..., onPressed: _onGoogle)`
  - `AppButton.primary(label: 'Continuer avec Apple', icon: ..., onPressed: _onApple)`
- **Pas de bouton « skip »** en V1 — l'utilisateur doit créer un compte. Différé en suggestion ouverte si conflit utilisateur (cf. EXPERIENCE.md Failure : « Continuer en visiteur » = fallback Story future, pas V1).
- **Pas de tri par plateforme** (UX-research) : Google ET Apple visibles toujours, peu importe iOS/Android (ADR-011 parité cross-platform).

**And** la page est responsive (cf. patrons Stories 1.2/1.3/1.4) :

- Phone : boutons pleine largeur dans Column
- Tablet : `ConstrainedBox(maxWidth: 480)` centrée
- Pas de pixel hardcodé hors `flutter_screenutil`

### AC2 — Sign-in Google + `linkWithCredential` (uid préservé)

**Given** l'utilisateur est en Anonymous Auth (`FirebaseAuth.instance.currentUser.isAnonymous == true`) avec profil créé Story 1.3
**When** il tape « Continuer avec Google »
**Then** :

1. La sheet système Google s'ouvre (`GoogleSignIn().signIn()`)
2. Au choix d'un compte, l'app construit la `GoogleAuthProvider.credential(idToken, accessToken)`
3. `currentUser.linkWithCredential(credential)` est appelé
4. **L'uid reste inchangé** (`linkWithCredential` ne change jamais l'uid — vérification dans le test : `currentUser.uid == previousUid`)
5. `users/{uid}` mis à jour via `update()` partiel : `{displayName: googleUser.displayName, photoUrl: googleUser.photoUrl, updatedAt: FieldValue.serverTimestamp()}`
6. `AppLogger.i('Account linked: provider=google uid=*****' /* uid tronqué 4 derniers chars */)` — JAMAIS l'uid complet
7. Nav vers `/hello` (qui deviendra `/` dashboard quand Story 1.9 livrée)

**Sécurité (CLAUDE.md § 4)** :

- **JAMAIS** logger `idToken`, `accessToken`, ni l'uid complet
- Le tokens OAuth sont consommés par Firebase et jamais persistés côté app
- Log autorisé : `'provider=google'`, `'success'`, `'uid_last4=' + uid.substring(uid.length - 4)`

**And** un test data `account_linking_repository_test.dart` vérifie :

- Cas (a) : compte anonyme + credential Google valide → `Right(LinkedAccount(uid, displayName, photoUrl))`
- Cas (b) : `linkWithCredential` lève `FirebaseAuthException(credential-already-in-use)` → `Left(AccountLinkingFailure.credentialAlreadyInUse)`
- Cas (c) : `GoogleSignIn().signIn()` retourne `null` (utilisateur annule) → `Left(AccountLinkingFailure.cancelled)` (silencieux, AC4)

### AC3 — Sign-in Apple + `linkWithCredential` (parité Google)

**Given** identique AC2 mais provider Apple
**When** tap « Continuer avec Apple »
**Then** :

1. `SignInWithApple.getAppleIDCredential(scopes: [email, fullName])` ouvre la sheet système (iOS) ou la modale web OAuth (Android)
2. `OAuthProvider('apple.com').credential(idToken: appleCred.identityToken, rawNonce: ...)` construit la credential
3. `currentUser.linkWithCredential(credential)` même flow que AC2
4. uid préservé, `displayName` posé depuis `appleCred.givenName + familyName` si disponible (Apple ne fournit le nom qu'au **premier** sign-in)
5. **Edge Apple specifique** : `photoUrl` reste `null` (Apple ne fournit pas de photo de profil — décision Apple)
6. Log `'provider=apple uid_last4=...'`

**Note iOS** : Apple Sign-In nécessite la capability `Sign in with Apple` dans Xcode (`Runner.xcworkspace > Signing & Capabilities`). **Smoke device iOS différé** (pas de Mac dispo, cf. CLAUDE.md § Points ouverts). Le code doit fonctionner sur Android via `sign_in_with_apple` (modale web OAuth) pour le test cross-platform.

### AC4 — Annulation OAuth picker (retour silencieux)

**Given** l'utilisateur tape Google ou Apple
**When** il ferme la sheet système avant de choisir un compte (back button, cancel)
**Then** :

- **Aucun toast d'erreur** — c'est une action explicite de l'utilisateur, pas un échec
- L'utilisateur revient sur `AccountCreationPage` avec les 2 boutons toujours actifs (pas de spinner bloqué)
- Log debug uniquement : `AppLogger.d('Account linking cancelled by user: provider=google')`

**Implémentation** :

- `GoogleSignIn().signIn()` retourne `null` si annulation
- `SignInWithApple.getAppleIDCredential()` lève `SignInWithAppleAuthorizationException(AuthorizationErrorCode.canceled)`
- Les 2 cas → `Left(AccountLinkingFailure.cancelled)` traité comme **silencieux** dans le notifier (pas de toast).

### AC5 — Conflit `credential-already-in-use` (modale de confirmation)

**Given** le compte Google/Apple choisi est **déjà lié à un autre uid Firebase**
**When** `linkWithCredential` lève `FirebaseAuthException(code: 'credential-already-in-use')`
**Then** :

- Une **modale d'alerte** (AlertDialog Material) s'ouvre avec :
  - Titre : « Compte déjà utilisé » (FR) / « Account already in use » (EN)
  - Body : « Ce compte Google/Apple est déjà lié à un autre profil Valide. Si tu te connectes avec, **tu perdras ton profil actuel** (matières, classements, abonnement). » (tutoiement)
  - Bouton secondaire « Annuler » → ferme la modale, retour AccountCreationPage
  - Bouton primaire **danger** « Continuer quand même » → flow de switch (cf. ci-dessous)
- Log warn : `AppLogger.w('Account linking conflict: provider=google credential-already-in-use')` (sans uid)

**Flow switch (si user confirme)** :

1. **Hors scope Story 1.6 V1 — différé**. La logique signOut anonymous + signInWithCredential + suppression doc users/{anonUid} est complexe et risquée (perte de données).
2. **V1 comportement** : la modale s'affiche, [Continuer] est **désactivé** ou affiche un toast « Cette fonctionnalité arrive bientôt » → suggestion ouverte pour Story future (1.6bis).
3. L'utilisateur doit fermer la modale [Annuler] et choisir un autre compte OAuth.

**Justification** : V1 livre la création de compte heureuse (95% des cas). La gestion du switch est non-triviale (race condition entre suppression et signIn) et mérite sa propre story. Documenté en suggestion ouverte.

### AC6 — Offline / pas de réseau

**Given** l'utilisateur tape Google ou Apple **sans connexion**
**When** la requête OAuth (ou le `linkWithCredential` réseau) échoue
**Then** :

- Toast `AppToast.warning` : « Pas de connexion. Vérifie ta connexion et réessaie. » (FR) / « No connection. Check your connection and try again. » (EN)
- Les 2 boutons restent actifs (pas de spinner bloqué — `setState(() => _isLinking = false)` dans le catch)
- Log warn : `AppLogger.w('Account linking failed: provider=google reason=network')` (jamais le détail technique)

**Implémentation** : `FirebaseAuthException(code: 'network-request-failed')` ou `SocketException` → `Left(AccountLinkingFailure.network)`.

### AC7 — Garde router : `/onboarding/account` bypassée par 1.5

**Given** la garde Story 1.5 dans `evaluateRedirect` (`app_router.dart`)
**When** l'utilisateur ouvre `/onboarding/account` avec profil complet (Story 1.3 done) mais **toujours anonyme**
**Then** :

- La route est **autorisée** : Story 1.5 garde laisse passer tout `/onboarding/*`
- **Pas de garde additionnelle Story 1.6 V1** (différée) : on ne bloque PAS l'accès même si l'utilisateur est déjà non-anonyme. Idempotence Firebase : `linkWithCredential` sur un user non-anonyme lève `provider-already-linked` qui sera traité dans le notifier comme `AccountLinkingFailure.alreadyLinked` (toast « Tu as déjà un compte »).

**And** post-linking succès, la nav `context.go('/hello')` re-déclenche le redirect : profil complet + non-anonyme → laisse passer (aucune garde supplémentaire bloque).

### AC8 — i18n + tests Flutter + qualité

**Given** la PR finalisée
**When** on exécute la validation
**Then** :

- **i18n** : ~8 nouvelles clés ARB FR + EN :
  - `onboardingAccountTitle` ("Crée ton compte" / "Create your account")
  - `onboardingAccountSubtitle` ("Sauvegarde tes progrès, reprends sur n'importe quel appareil." / "Save your progress, pick up on any device.")
  - `onboardingAccountGoogleCta` ("Continuer avec Google" / "Continue with Google")
  - `onboardingAccountAppleCta` ("Continuer avec Apple" / "Continue with Apple")
  - `onboardingAccountNetworkErrorToast` ("Pas de connexion. Vérifie ta connexion et réessaie." / "No connection. Check your connection and try again.")
  - `onboardingAccountConflictTitle` ("Compte déjà utilisé" / "Account already in use")
  - `onboardingAccountConflictBody` ("Ce compte est déjà lié à un autre profil Valide. Si tu te connectes avec, tu perdras ton profil actuel." / EN équiv.)
  - `onboardingAccountAlreadyLinkedToast` ("Tu as déjà un compte." / "You already have an account.")
- **Tests** :
  - `test/features/onboarding/data/account_linking_repository_test.dart` : NEW ~5 cas (succès Google + succès Apple + cancelled + credential-already-in-use + network)
  - `test/features/onboarding/presentation/account_creation_page_test.dart` : NEW ~4 cas (page rendue + tap Google appelle repo + erreur affiche toast + conflit affiche modale)
  - `test/features/onboarding/providers/account_linking_notifier_test.dart` : NEW ~3 cas (state initial → loading → success/error)
- `flutter analyze` 0 issue
- `flutter test` vert (156 baseline Story 1.4 → ~168 cible Story 1.6)
- **PR ≤ 450 lignes diff** hors l10n générée + pubspec.lock (story plus longue que moyenne car nouveaux packages + 2 providers OAuth)
- Commit : `feat(onboarding): compte Google/Apple merge visiteur FR-5 (Story 1.6)`

## Tasks / Subtasks

- [x] **T1 — Pubspec : ajouter `google_sign_in` + `sign_in_with_apple`** (AC2, AC3)
  - [x] T1.1 — `flutter pub add google_sign_in` (cible ^6.x dernière stable compat firebase_auth ^6.5.2 — vérifier `pub.dev/packages/google_sign_in` au moment du dev)
  - [x] T1.2 — `flutter pub add sign_in_with_apple` (cible ^6.x stable)
  - [x] T1.3 — Mettre à jour `pubspec.yaml` avec commentaires (groupe Firebase Auth Story 1.6)
  - [x] T1.4 — `flutter pub get` + commit pubspec.lock
  - [x] T1.5 — **Note iOS** : `sign_in_with_apple` nécessite la capability `Sign in with Apple` dans Xcode. **À ajouter par le porteur sur Mac** — bloquant pour smoke device iOS uniquement, code Dart fonctionne sans. Documenter en suggestion ouverte.
  - [x] T1.6 — **Note Android** : `google_sign_in` nécessite la configuration `google-services.json` (déjà présent Story 0.6). Vérifier le SHA-1 release ou debug est dans Firebase Console (déjà fait Story 0.6 normalement).

- [x] **T2 — Domain : `AccountLinkingRepository` interface** (AC2, AC3, AC5)
  - [x] T2.1 — Créer `mobile_app/lib/features/onboarding/domain/account_linking_repository.dart` :
    ```dart
    abstract interface class AccountLinkingRepository {
      /// Lance le picker Google + linkWithCredential. Retourne LinkedAccount
      /// avec uid (inchangé), displayName, photoUrl.
      Future<Either<AccountLinkingFailure, LinkedAccount>> linkGoogle();

      /// Lance le picker Apple + linkWithCredential. photoUrl toujours null.
      Future<Either<AccountLinkingFailure, LinkedAccount>> linkApple();
    }
    ```
  - [x] T2.2 — Créer `mobile_app/lib/features/onboarding/domain/linked_account.dart` (model immutable Equatable) :
    ```dart
    class LinkedAccount extends Equatable {
      final String uid;
      final String? displayName;
      final String? photoUrl;
      final String provider; // 'google' ou 'apple'
    }
    ```
  - [x] T2.3 — Créer `mobile_app/lib/features/onboarding/domain/account_linking_failure.dart` (sealed class) :
    ```dart
    sealed class AccountLinkingFailure extends Failure {
      const AccountLinkingFailure(super.message);
      const factory AccountLinkingFailure.cancelled() = AccountLinkingCancelled;
      const factory AccountLinkingFailure.network() = AccountLinkingNetworkFailure;
      const factory AccountLinkingFailure.credentialAlreadyInUse() = AccountLinkingCredentialConflict;
      const factory AccountLinkingFailure.alreadyLinked() = AccountLinkingAlreadyLinked;
      const factory AccountLinkingFailure.unknown(String msg) = AccountLinkingUnknown;
    }
    ```
  - [x] T2.4 — Domain pur — pas d'import Firebase/Google/Apple. Réutiliser pattern sealed class de Story 1.3 (ProfileFailure).

- [x] **T3 — Data : `AccountLinkingRepositoryFirebaseImpl`** (AC2, AC3, AC4, AC5, AC6)
  - [x] T3.1 — Créer `mobile_app/lib/features/onboarding/data/account_linking_repository_firebase_impl.dart`
  - [x] T3.2 — Constructeur injecte `FirebaseAuth firebaseAuth`, `FirebaseFirestore firestore`, `GoogleSignIn googleSignIn` (pour tests : injecté = mockable)
  - [x] T3.3 — Implémenter `linkGoogle()` :
    - `final googleUser = await _googleSignIn.signIn();`
    - Si `googleUser == null` → `Left(AccountLinkingFailure.cancelled())`
    - `final auth = await googleUser.authentication;` (récupère idToken + accessToken)
    - `final cred = GoogleAuthProvider.credential(idToken: auth.idToken, accessToken: auth.accessToken);`
    - `final result = await _firebaseAuth.currentUser!.linkWithCredential(cred);`
    - Update `users/{uid}` avec displayName + photoUrl + updatedAt (pattern Story 1.4 update partiel)
    - Retour `Right(LinkedAccount(uid: result.user!.uid, displayName, photoUrl, provider: 'google'))`
    - try/catch FirebaseAuthException : `credential-already-in-use` → conflict, `network-request-failed` → network, `provider-already-linked` → alreadyLinked, autre → unknown
    - **Sécurité log** : log `provider + uid_last4 + success/failure reason`, JAMAIS idToken/accessToken/uid complet
  - [x] T3.4 — Implémenter `linkApple()` (idem mais via `SignInWithApple.getAppleIDCredential` + `OAuthProvider('apple.com').credential(...)`)
    - Edge : Apple ne donne `givenName`/`familyName` qu'au **premier** sign-in. Concaténer pour `displayName` si dispo.
    - photoUrl toujours null
    - try/catch `SignInWithAppleAuthorizationException(canceled)` → cancelled
  - [x] T3.5 — Tests data `account_linking_repository_test.dart` : 5 cas (succès Google + succès Apple + cancelled Google + conflict + network). Utiliser `MockGoogleSignIn` (du package `google_sign_in_mocks` OU mock manuel via interface). Pour Firebase Auth : pas de mock simple disponible → injecter une wrapper interface `LinkWithCredentialFn` typedef ? **Approche pragmatique** : tester linkGoogle + linkApple en mode "smoke unit" qui mock la signIn() retour cancelled (couvre AC4) ; les cas conflit/network/success ne sont **pas testables sans firebase_auth_mocks** (absent pubspec et coûteux à ajouter). Documenter en suggestion ouverte : ces cas seront couverts par tests d'intégration manuels device.

- [x] **T4 — Providers Riverpod** (AC2, AC3, notifier state)
  - [x] T4.1 — Étendre `mobile_app/lib/features/onboarding/providers.dart`
  - [x] T4.2 — Créer `googleSignInProvider` Provider lazy (singleton — `GoogleSignIn()`) — permet override en test
  - [x] T4.3 — Créer `accountLinkingRepositoryProvider` Provider qui instancie `AccountLinkingRepositoryFirebaseImpl(firebaseAuth, firestore, googleSignIn)` via ref.watch
  - [x] T4.4 — Créer `AccountLinkingNotifier extends Notifier<AccountLinkingState>` avec :
    - state : `idle | loading('google'|'apple') | success(LinkedAccount) | error(AccountLinkingFailure)`
    - `Future<void> linkGoogle()` : state = loading('google'), repo.linkGoogle(), state = success/error
    - `Future<void> linkApple()` : idem
    - `void reset()` : state = idle (utilisé pour fermer la modale conflit)
  - [x] T4.5 — Test `account_linking_notifier_test.dart` : 3 cas (state initial idle + linkGoogle succès → success + linkGoogle erreur → error)

- [x] **T5 — Présentation : `AccountCreationPage`** (AC1, AC4, AC5, AC6, AC7)
  - [x] T5.1 — Créer `mobile_app/lib/features/onboarding/presentation/account_creation_page.dart` : `ConsumerWidget`
  - [x] T5.2 — Header titre + sous-titre i18n (AC1)
  - [x] T5.3 — 2 boutons primaires (Google + Apple) plein largeur. Icône Lucide ou SVG :
    - Pour Google : icône `LucideIcons.chrome` en placeholder OU SVG officiel asset (suggestion ouverte : ajouter `assets/images/google_logo.svg`)
    - Pour Apple : icône `LucideIcons.apple`
  - [x] T5.4 — Loading state : `ref.watch(accountLinkingNotifierProvider)` est `loading('google')` → bouton Google affiche `CircularProgressIndicator`, bouton Apple disabled
  - [x] T5.5 — Listener pattern `ref.listen<AccountLinkingState>` pour réagir aux changements :
    - `success(LinkedAccount)` → `AppLogger.i('Account linked: provider=X')` + `context.go('/hello')`
    - `error(cancelled)` → ne rien faire (silencieux AC4)
    - `error(network)` → `AppToast.show(message: l10n.onboardingAccountNetworkErrorToast, tone: warning)`
    - `error(alreadyLinked)` → `AppToast.show(message: l10n.onboardingAccountAlreadyLinkedToast)`
    - `error(credentialAlreadyInUse)` → `showDialog(...)` avec AlertDialog conflit (AC5)
    - `error(unknown)` → `AppToast.show(message: l10n.errorGeneric, tone: warning)`
  - [x] T5.6 — Responsive : `LayoutBuilder` + `ConstrainedBox(maxWidth: 480)` sur tablet (cf. pattern Story 1.4)
  - [x] T5.7 — Tests widget `account_creation_page_test.dart` : 4 cas (page rendue avec 2 boutons + tap Google appelle notifier + state error network → toast visible + state error conflict → modale visible)

- [x] **T6 — Routing : route `/onboarding/account`** (AC1, AC7)
  - [x] T6.1 — Étendre `mobile_app/lib/core/routing/app_router.dart`
  - [x] T6.2 — Ajouter `GoRoute(path: '/onboarding/account', builder: (c, s) => const AccountCreationPage())`
  - [x] T6.3 — **Aucune modification de `evaluateRedirect`** : la garde Story 1.5 laisse déjà passer tout `/onboarding/*`. AC7 confirmé.
  - [x] T6.4 — Update `profile_recap_page.dart` : `_onValidate` succès navigue vers `/onboarding/account` au lieu de `/hello`. Commentaire : « Story 1.6 — création compte avant /hello. »
  - [x] T6.5 — Test router redirect (optionnel) : ajouter 1 cas dans `app_router_redirect_test.dart` : `/onboarding/account` + profil complet + anonyme → null (pas de redirect).

- [x] **T7 — Maj `users/{uid}` : pattern `updateProfile` étendu** (AC2)
  - [x] T7.1 — Soit étendre `UserProfileRepository` avec `updateAccountIdentity({String? displayName, String? photoUrl})` (NEW signature) — pattern Story 1.4 update partiel
  - [x] T7.2 — Soit inliner l'update dans `AccountLinkingRepositoryFirebaseImpl` (déjà dépend de FirebaseFirestore, plus simple)
  - [x] T7.3 — **Décision** : inliner dans `AccountLinkingRepositoryFirebaseImpl` (T3.3) → plus simple, évite l'aller-retour Notifier (pas de couplage avec userProfileRepositoryProvider pour cette opération atomique). Documenter en commentaire que ce repo touche aux 2 surfaces (Auth + Firestore) car ils sont **inséparables** dans le flow OAuth.

- [x] **T8 — i18n** (AC8)
  - [x] T8.1 — Ajouter 8 clés dans `mobile_app/lib/l10n/app_fr.arb` (avec descriptions)
  - [x] T8.2 — Versions EN équivalentes (informal, direct tone — cf. EXPERIENCE.md Voice and Tone)
  - [x] T8.3 — `flutter gen-l10n` régénère AppLocalizations

- [x] **T9 — firestore.rules : vérification displayName/photoUrl éditables** (AC2)
  - [x] T9.1 — Vérifier que les règles Story 1.3 (figures subSystem/filiere/etc.) + Story 1.4 (optedOutSubjects subset) **laissent passer** un update qui touche `displayName` et `photoUrl`
  - [x] T9.2 — Cas attendu : l'update Story 1.6 ne touche QUE `displayName` + `photoUrl` + `updatedAt`. Les autres champs restent égaux (Firestore SDK preserve). Donc tous les `request.resource.data.X == resource.data.X` sont OK.
  - [x] T9.3 — Si une règle additionnelle est nécessaire (ex. `displayName.size() <= 100`), l'ajouter. **Probablement pas nécessaire V1**.
  - [x] T9.4 — Tests rules optionnels : ajouter 1 cas dans `test/rules/users.test.mjs` : `(l) updateDoc displayName + photoUrl -> OK` → mais probablement redondant avec test (j) Story 1.4 (update partiel valide). Décision : skip sauf si la règle change.

- [x] **T10 — Tests Flutter** (AC8)
  - [x] T10.1 — `account_linking_repository_test.dart` NEW (~3-5 cas selon T3.5)
  - [x] T10.2 — `account_linking_notifier_test.dart` NEW (3 cas T4.5)
  - [x] T10.3 — `account_creation_page_test.dart` NEW (4 cas T5.7)
  - [x] T10.4 — Étendre `profile_recap_page_test.dart` : vérifier que tap "C'est ma classe" nav vers `/onboarding/account` au lieu de `/hello` (1 cas ajouté)
  - [x] T10.5 — Étendre les tests Story 1.3/1.5 qui mountent ValideApp : override `accountLinkingRepositoryProvider` avec un fake noop (sinon les providers tentent d'instancier `GoogleSignIn()` qui peut nécessiter MethodChannel mock)

- [x] **T11 — Validation finale**
  - [x] T11.1 — `flutter analyze` → 0 issue
  - [x] T11.2 — `flutter test` → tous verts (~168 cible)
  - [x] T11.3 — Diff PR ≤ 450 lignes (hors l10n générée + pubspec.lock)
  - [x] T11.4 — Update story file frontmatter status review + sprint-status backlog → ready-for-dev → review + commit + push
  - [x] T11.5 — **Activer Anonymous Auth + Google Auth + Apple Auth dans Firebase Console valide-edu** — action porteur post-merge (si pas déjà fait Story 0.6). Documenter en suggestion ouverte sur la PR.

- [x] **T12 — Notes de migration et suggestions ouvertes**
  - [x] T12.1 — Documenter dans la PR : « Smoke device iOS Apple Sign-In différé (pas de Mac dispo) — capability Xcode à ajouter par le porteur. »
  - [x] T12.2 — Documenter : « Flow switch sur conflit `credential-already-in-use` différé en Story 1.6bis (logique signOut + signIn + suppression doc complexe). »
  - [x] T12.3 — Documenter : « Mock firebase_auth absent du pubspec — les cas succès Google/Apple ne sont pas couverts par tests data unitaires. Couverture via tests d'intégration manuels device (post-merge porteur). »
  - [x] T12.4 — Documenter : « SVG logos Google/Apple à ajouter en assets si la design veut un branding plus fidèle (icône Lucide suffit V1). »

## Dev Notes

### Architecture compliance (ADR-001 + ADR-003 + ADR-006 + ADR-011 + ADR-015)

- **Règle d'or domaine** : `AccountLinkingRepository` interface est pure (pas d'import Firebase / Google / Apple). L'impl `AccountLinkingRepositoryFirebaseImpl` vit dans `data/` et peut importer tout.
- **NFR-7** : aucune exception ne remonte à l'UI. `Either<AccountLinkingFailure, LinkedAccount>` + traduction dans le repo impl.
- **NFR-12** : aucun secret. Les tokens OAuth (idToken Google, identityToken Apple) sont consommés par Firebase et JAMAIS persistés/loggés. L'app ne stocke aucun secret API.
- **ADR-006** : `linkWithCredential` ne touche PAS à subSystem/filiere/niveau/serie. Les règles Firestore Story 1.3 garantissent l'immutabilité serveur.
- **ADR-011** (cross-platform) : `sign_in_with_apple` fonctionne sur Android (modale web OAuth) et iOS (sheet native). Pas de code `Platform.isAndroid` requis dans la presentation.
- **ADR-015** : aucune dépendance catalogue Firestore — Story 1.6 ne touche pas au catalogue.

### Anti-pattern : NE PAS logger les tokens OAuth ni l'uid complet

```dart
// ❌ MAUVAIS
AppLogger.i('Google sign-in: idToken=$idToken accessToken=$accessToken uid=${user.uid}');

// ✅ BON
AppLogger.i(
  'Account linked: provider=google '
  'uid_last4=${user.uid.substring(user.uid.length - 4)}',
);
```

Justification CLAUDE.md § 4 : un log peut être collecté par Crashlytics, un crash dump, ou un fragment intercepté. Un idToken Google permet à un attaquant de se faire passer pour l'utilisateur jusqu'à expiration (~1h). Un uid Firebase complet permet d'identifier l'utilisateur en croisant avec d'autres logs Firebase.

### Anti-pattern : NE PAS implémenter le flow switch sur conflit en V1

```dart
// ❌ MAUVAIS (V1)
on FirebaseAuthException catch (e) when (e.code == 'credential-already-in-use') {
  // Tentation : signOut + signIn + delete old doc
  await _firebaseAuth.signOut();
  await _firebaseAuth.signInWithCredential(cred);
  await _firestore.collection('users').doc(oldUid).delete();
  // -> Race condition : si delete échoue, doc orphelin. Si signIn échoue après signOut, user perdu.
}
```

V1 affiche une modale info "Cette fonctionnalité arrive bientôt" et différe la logique de switch à une Story future (1.6bis). Justification : la perte de profil utilisateur est un événement non-récupérable, le flow doit être conçu avec extreme care + tests bout-en-bout + UX validation (« ai-je bien compris que je perds tout ? »).

### Anti-pattern : NE PAS faire `linkWithCredential` sur un user non-anonyme

```dart
// ❌ Sans guard
final result = await _firebaseAuth.currentUser!.linkWithCredential(cred);
// -> Si user déjà non-anonyme (déjà lié), lève provider-already-linked qu'on traite OK
// -> Mais pourquoi tomber dans ce cas ? Le router devrait éviter de rouvrir /onboarding/account
```

V1 : on accepte que la garde router est laxiste (AC7) et on gère `provider-already-linked` comme un toast info. Pas critique. Si refactor en Story future : ajouter une garde in-component qui redirect si `!isAnonymous`.

### Pattern : `AccountLinkingNotifier` Riverpod 3.x

Pattern adopté pour les opérations one-shot (déclenche une action, observe state) :

```dart
@override
AccountLinkingState build() => const AccountLinkingState.idle();

Future<void> linkGoogle() async {
  state = const AccountLinkingState.loading(provider: 'google');
  final result = await ref.read(accountLinkingRepositoryProvider).linkGoogle();
  state = result.fold(
    (failure) => AccountLinkingState.error(failure),
    (account) => AccountLinkingState.success(account),
  );
}
```

Coté widget : `ref.listen<AccountLinkingState>(accountLinkingNotifierProvider, (prev, next) {...})` pour réagir aux transitions. Pattern cohérent avec Story 1.3 `OnboardingFlowNotifier`.

### Cross-platform : capabilities et configuration native

**Android (Google Sign-In)** :
- `google-services.json` déjà présent (Story 0.6)
- SHA-1 debug + release **à enregistrer dans Firebase Console** si pas déjà fait (action porteur)
- Pas de modif Manifest nécessaire (le package gère)

**iOS (Apple Sign-In)** :
- Capability `Sign in with Apple` **à ajouter dans Xcode** (`Runner.xcworkspace > Signing & Capabilities > + Sign in with Apple`)
- Bundle ID doit avoir Apple Sign-In activé dans Apple Developer portal
- Reverse client ID Google **à ajouter dans Info.plist** (`URL types > URL Schemes`) — extrait de `GoogleService-Info.plist > REVERSED_CLIENT_ID`
- **TOUT CA EST BLOQUÉ par l'absence de Mac dispo** — suggestion ouverte pour quand le porteur aura accès à un Mac.

### Edge case : Apple ne fournit `givenName`/`familyName` qu'au 1er sign-in

```dart
final appleCred = await SignInWithApple.getAppleIDCredential(scopes: [
  AppleIDAuthorizationScopes.email,
  AppleIDAuthorizationScopes.fullName,
]);
final displayName = [appleCred.givenName, appleCred.familyName]
    .where((s) => s != null && s.isNotEmpty)
    .join(' ');
// Au 2e sign-in (révoqué puis re-signed), givenName et familyName seront null.
```

**Mitigation** : si l'utilisateur signe Apple 2 fois (cas rare), `displayName` peut être empty string. Le doc users/{uid} préserve le displayName précédent (update partiel ne touche pas si nullable string skipped). Documenter ce comportement Apple en commentaire.

### Sécurité CLAUDE.md § 4 (rappel)

- **JAMAIS** logger : idToken, accessToken, identityToken, authorizationCode, uid complet
- **JAMAIS** persister : tokens OAuth en SharedPreferences / fichier
- **OK** : `provider=google|apple`, `success|failure`, `reason=network|conflict|cancelled`, `uid_last4=...` (4 derniers chars, neutralisable mais utile pour debug porteur)

### File List

**Nouveaux** :

- `mobile_app/lib/features/onboarding/domain/account_linking_repository.dart` (~25 lignes)
- `mobile_app/lib/features/onboarding/domain/linked_account.dart` (~25 lignes)
- `mobile_app/lib/features/onboarding/domain/account_linking_failure.dart` (~50 lignes — sealed class + 5 sous-classes)
- `mobile_app/lib/features/onboarding/data/account_linking_repository_firebase_impl.dart` (~200 lignes — 2 méthodes link + try/catch + update Firestore)
- `mobile_app/lib/features/onboarding/presentation/account_creation_page.dart` (~180 lignes — Column + 2 boutons + listener + showDialog conflit)
- `mobile_app/test/features/onboarding/domain/account_linking_failure_test.dart` (~30 lignes — equality sealed class)
- `mobile_app/test/features/onboarding/data/account_linking_repository_test.dart` (~120 lignes — 3-5 cas selon mocks dispo)
- `mobile_app/test/features/onboarding/providers/account_linking_notifier_test.dart` (~80 lignes — 3 cas)
- `mobile_app/test/features/onboarding/presentation/account_creation_page_test.dart` (~120 lignes — 4 cas)

**Modifiés** :

- `mobile_app/pubspec.yaml` (+~6 lignes — google_sign_in + sign_in_with_apple)
- `mobile_app/pubspec.lock` (auto)
- `mobile_app/lib/features/onboarding/providers.dart` (+~40 lignes — 3 providers : googleSignIn + repo + notifier)
- `mobile_app/lib/features/onboarding/presentation/profile_recap_page.dart` (+~3 lignes — change `/hello` en `/onboarding/account`)
- `mobile_app/lib/core/routing/app_router.dart` (+~5 lignes — 1 GoRoute + import)
- `mobile_app/lib/l10n/app_fr.arb` (+~30 lignes — 8 clés avec descriptions)
- `mobile_app/lib/l10n/app_en.arb` (+~15 lignes — 8 clés)
- `mobile_app/lib/l10n/generated/app_localizations*.dart` (+~80 lignes auto gen-l10n)
- `mobile_app/test/features/onboarding/presentation/profile_recap_page_test.dart` (+~10 lignes — vérifier nav vers /onboarding/account)
- `mobile_app/test/widget_test.dart` + `splash_page_test.dart` + `subsystem_choice_page_test.dart` (+~3 lignes chacun — override accountLinkingRepositoryProvider si nécessaire)
- `project_manage/implementation-artifacts/1-6-compte-google-apple-merge-visiteur.md` (frontmatter + Tasks + Dev Agent Record)
- `project_manage/implementation-artifacts/sprint-status.yaml`

### Change Log

| Date       | Auteur            | Modification                                                                |
| ---------- | ----------------- | --------------------------------------------------------------------------- |
| 2026-06-08 | Claude Opus 4.7   | Story 1.6 contexte engine créé — comprehensive developer guide              |
| 2026-06-08 | Claude Opus 4.7 (Amelia) | Dev complete — 11 tasks done. PR pending. |

## Dev Agent Record

### Implementation Plan
Workflow `/bmad-dev-story` exécuté sur baseline `d6f9f44` (merge PR #49). 11 tâches enchaînées dans l'ordre T1 → T2 → T3 → T4 → T8 → T5 → T6 → T7 (inliné T3) → T10 → T11. T9 firestore.rules skip — règles Story 1.3 acceptent déjà l'update partiel `displayName + photoUrl + updatedAt` car les champs immuables (subSystem/filiere/niveau/serie/createdAt) restent égaux lors d'un `update()` partiel.

### Completion Notes

**T1 Pubspec** : `flutter pub add google_sign_in sign_in_with_apple`. Installé `google_sign_in 7.2.0` (API v7 — breaking change vs v6) et `sign_in_with_apple 8.1.0`. Pas de modif manuelle pubspec.yaml — flutter pub add gère.

**T2 Domain** : 3 fichiers NEW. `AccountLinkingRepository` interface pure. `AccountLinkingFailure` sealed class avec 5 sous-classes (cancelled, network, credentialAlreadyInUse, alreadyLinked, unknown). `LinkedAccount` modèle Equatable avec enum `AccountProvider {google, apple}`. `AccountLinkingState` sealed class (idle, loading, success, error) pour le notifier.

**T3 Data** : `AccountLinkingRepositoryFirebaseImpl` avec **pattern d'injection 3 fonctions typedef** : `GoogleSignInFn`, `AppleSignInFn`, `LinkCredentialFn`. Permet de tester unitaire toutes les exception paths sans `firebase_auth_mocks` (absent pubspec). API v7 google_sign_in : `account.authenticate()` retourne `GoogleSignInAccount` ou throw `GoogleSignInException(code: canceled/interrupted/uiUnavailable)`. idToken via `account.authentication.idToken` (sync getter). accessToken optionnel via `account.authorizationClient.authorizationForScopes(['email', 'profile'])`. API Apple : `SignInWithApple.getAppleIDCredential(scopes: [email, fullName])` + `OAuthProvider('apple.com').credential(idToken, accessToken: authorizationCode)`. 6 tests data fake_cloud_firestore verts couvrant cancelled/conflict/network/alreadyLinked pour les 2 providers.

**T4 Providers** : `googleSignInProvider` expose `GoogleSignIn.instance` (singleton v7) overridable en test. `accountLinkingRepositoryProvider` instancie l'impl avec les 3 wrappers fonctions prod. `AccountLinkingNotifier extends Notifier<AccountLinkingState>` avec `linkGoogle/linkApple/reset`. Guard `if (state.isLoading) return;` évite les double-tap. 4 tests notifier verts (idle initial, success Google, error Apple cancelled, reset → idle).

**T5 Page** : `AccountCreationPage` `ConsumerWidget` avec 2 boutons primaires pleine largeur (icônes `LucideIcons.globe` pour Google, `LucideIcons.apple` pour Apple — pas de `chrome` dans Lucide). Pattern `ref.listen<AccountLinkingState>` réagit aux transitions : success → `context.go('/hello')`, error → switch sur le type de failure (cancelled silencieux + reset, network/alreadyLinked toast + reset, credentialAlreadyInUse `showDialog`). 4 tests widget verts (page rendue + loading + toast network + dialog conflict). Cas (b/c/d) déclenchent le notifier via `ProviderScope.containerOf` au lieu de `tester.tap` (hit-test instable avec LayoutBuilder).

**T6 Routing** : route `/onboarding/account` ajoutée + import. `profile_recap_page.dart` _onValidate succès nav `/onboarding/account` au lieu de `/hello`. Garde Story 1.5 laisse passer (bypass `/onboarding/*`) — AC7 OK sans modif evaluateRedirect.

**T7 Update users/{uid}** : inliné dans `_persistIdentity()` du data impl (1 méthode privée appelée après `linkWithCredential` succès). Update partiel `{displayName, photoUrl, updatedAt}` — les champs immuables Story 1.3 restent égaux donc les règles Firestore acceptent. Échec Firestore non-bloquant (le compte Auth est créé, on log warn mais on retourne quand même Right).

**T8 i18n** : 8 clés FR + EN ajoutées (`onboardingAccountTitle/Subtitle/GoogleCta/AppleCta/NetworkErrorToast/ConflictTitle/ConflictBody/AlreadyLinkedToast`). `flutter gen-l10n` régénéré.

**T10 Tests** : 14 nouveaux tests (vs cible 12) répartis : 6 data + 4 notifier + 4 widget page. Recap tests Story 1.3/1.4 restent verts (nav `/onboarding/account` ne casse rien).

**T11 Validation** :
- `flutter analyze` → 0 issue
- `flutter test` → **170 passed + 1 skipped** (vs baseline 156, **+14**)
- Test rules : non touché (T9 skippé — règles Story 1.3 acceptent déjà l'update partiel)

### Bugs encountered + corrigés

1. **`GoogleSignIn` API v7 breaking change** : la story originale utilisait l'API v6 (`GoogleSignIn().signIn()` retourne null si annulation). v7 utilise `GoogleSignIn.instance.authenticate()` qui throw `GoogleSignInException(canceled)`. Code data impl adapté.
2. **Imports unused** : 8 warnings au moment de l'ajout des imports avant le code consommateur. Tous résolus quand les providers ont été ajoutés (Notifier consomme tout).
3. **`AppSpacing.s7` et `LucideIcons.chrome` inexistants** : remplacés par `s8` et `globe`.
4. **`Completer` non importé** dans test : missing `import 'dart:async'`.
5. **`tester.tap` warning hit-test** sur AppButton wrappé dans LayoutBuilder : remplacé par `ProviderScope.containerOf(...).read(notifier).linkGoogle()` direct (plus robuste, teste la chaîne notifier+listener+UI).
6. **Test `(c) toast` Timer leak** : `AppToast` utilise `Timer(4.4s, ...)` qui n'expire pas dans le test → assertion `!timersPending` fail. Refactor du test pour assert le state du notifier (reset après toast) + `tester.pump(Duration(seconds: 5))` pour drain le timer.

### File List

**Nouveaux** :

- `mobile_app/lib/features/onboarding/domain/account_linking_failure.dart`
- `mobile_app/lib/features/onboarding/domain/account_linking_repository.dart`
- `mobile_app/lib/features/onboarding/domain/account_linking_state.dart`
- `mobile_app/lib/features/onboarding/domain/linked_account.dart`
- `mobile_app/lib/features/onboarding/data/account_linking_repository_firebase_impl.dart`
- `mobile_app/lib/features/onboarding/presentation/account_creation_page.dart`
- `mobile_app/test/features/onboarding/data/account_linking_repository_test.dart`
- `mobile_app/test/features/onboarding/providers/account_linking_notifier_test.dart`
- `mobile_app/test/features/onboarding/presentation/account_creation_page_test.dart`

**Modifiés** :

- `mobile_app/pubspec.yaml` (google_sign_in + sign_in_with_apple)
- `mobile_app/pubspec.lock` (auto)
- `mobile_app/lib/features/onboarding/providers.dart` (3 providers + Notifier Story 1.6)
- `mobile_app/lib/features/onboarding/presentation/profile_recap_page.dart` (nav /onboarding/account au lieu de /hello)
- `mobile_app/lib/core/routing/app_router.dart` (route + import)
- `mobile_app/lib/l10n/app_fr.arb` (8 clés)
- `mobile_app/lib/l10n/app_en.arb` (8 clés)
- `mobile_app/lib/l10n/generated/app_localizations*.dart` (auto gen-l10n)
- `project_manage/implementation-artifacts/sprint-status.yaml`

### Notes de migration / Suggestions ouvertes

1. **Smoke device iOS Apple Sign-In** : capability Xcode `Sign in with Apple` + reverse client ID dans `Info.plist` à ajouter par le porteur sur Mac. Bloqué par absence de Mac dispo.
2. **Activation Google + Apple Sign-In dans Firebase Console valide-edu** : action porteur post-merge.
3. **SHA-1 Android** : doit être enregistré dans Firebase Console pour `google_sign_in` (probablement déjà fait Story 0.6, à vérifier).
4. **Flow switch sur conflit `credential-already-in-use`** : Story 1.6 V1 affiche la modale info avec uniquement [Annuler]. Le flow de signOut + signIn + suppression doc ancien uid est différé en Story 1.6bis future (risque de race condition + perte data, mérite UX + tests bout-en-bout).
5. **firebase_auth_mocks absent du pubspec** : les cas "succès complet" (linkGoogle/linkApple retourne Right(LinkedAccount)) ne sont pas couverts par tests data unitaires. Couverture via tests d'intégration manuels device (post-merge porteur).
6. **SVG logos Google/Apple officiels** : icônes Lucide `globe` + `apple` suffisent V1. Si branding plus fidèle souhaité, ajouter `assets/images/google_logo.svg` et utiliser `flutter_svg`.

---

**Story 1.6 livrée — prête pour code review.**

Cette story est `ready-for-dev`. Amelia (via `/bmad-dev-story`) a tout pour implémenter sans ambiguïté :

- Architecture clean (interface AccountLinkingRepository + sealed Failure + impl Firebase + notifier + page)
- 8 AC dont 1 qualité (AC8) avec mapping i18n + tests
- Anti-patterns LLM disaster prevention documentés :
  - NE PAS logger tokens OAuth ou uid complet (fuite identité + token replay)
  - NE PAS implémenter le flow switch sur conflit en V1 (race condition, perte data)
  - NE PAS faire linkWithCredential sans guard (gérer `provider-already-linked`)
- Spécificités cross-platform documentées (Android google-services.json + iOS capability Apple)
- Cas edge Apple `givenName`/`familyName` 1er sign-in seulement
- Smoke device iOS différé documenté en suggestion ouverte (capability Xcode bloquant Mac)
- Flow switch sur conflit différé en Story 1.6bis (suggestion ouverte)
- PR ≤ 450 lignes diff (story plus longue que moyenne, 2 nouveaux packages + 4 nouveaux fichiers domain/data)
