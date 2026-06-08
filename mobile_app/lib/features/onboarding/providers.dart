// Story 1.2 — Providers Riverpod feature onboarding.
//
// Story 1.3 — etend avec 3 providers supplementaires :
//   4. `onboardingFlowProvider` : state machine OnboardingFlowState (Notifier).
//   5. `userProfileRepositoryProvider` : impl Firestore du UserProfileRepository.
//   6. `derivedProfileProvider` : FutureProvider qui appelle
//      CatalogueRepository.derive(...) avec les valeurs du flow + subSystem.
//
// 6 providers exposés (Story 1.2 + 1.3) :
//   1. `sharedPreferencesProvider` : instance préchargée en `main.dart`.
//      L'override en `ProviderScope` est OBLIGATOIRE — sans lui, toute
//      lecture lève `UnimplementedError` (garde défensive).
//   2. `subsystemPrefsProvider` : wrapper lazy autour de SharedPreferences.
//   3. `subSystemNotifierProvider` : state in-memory du sous-système choisi,
//      initialisé synchroniquement depuis SharedPreferences au build.
//      Notifie ses watchers (LocaleNotifier, GoRouter redirect) au changement.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/catalogue/domain/catalogue_failure.dart';
import '../../core/catalogue/domain/models.dart';
import '../../core/catalogue/providers.dart';
import '../../core/firebase/providers.dart';
import '../../core/logging/app_logger.dart';
import 'data/account_linking_repository_firebase_impl.dart';
import 'data/school_repository_firestore_impl.dart';
import 'data/subsystem_prefs.dart';
import 'data/user_profile_repository_firestore_impl.dart';
import 'domain/account_linking_repository.dart';
import 'domain/account_linking_state.dart';
import 'domain/linked_account.dart';
import 'domain/onboarding_flow_state.dart';
import 'domain/profile_completion_state.dart';
import 'domain/school.dart';
import 'domain/school_repository.dart';
import 'domain/sub_system.dart';
import 'domain/user_profile_repository.dart';

/// SharedPreferences préchargée en `main.dart` avant `runApp`.
///
/// MUST be overridden in `ProviderScope.overrides` :
/// ```dart
/// final prefs = await SharedPreferences.getInstance();
/// runApp(ProviderScope(
///   overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
///   child: const ValideApp(),
/// ));
/// ```
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider doit être overridé dans ProviderScope.overrides '
    'avec l\'instance préchargée par main.dart. Voir Story 1.2 AC4.',
  );
});

/// Wrapper lazy autour de SharedPreferences pour le sous-système.
final subsystemPrefsProvider = Provider<SubsystemPrefs>((ref) {
  return SubsystemPrefs(ref.watch(sharedPreferencesProvider));
});

/// État courant du sous-système. Synchrone (le `sharedPreferencesProvider`
/// est préchargé). Notifie les watchers (LocaleNotifier dans `app.dart`,
/// redirect global de GoRouter dans `app_router.dart`) au changement.
class SubSystemNotifier extends Notifier<SubSystem?> {
  @override
  SubSystem? build() => ref.read(subsystemPrefsProvider).read();

  /// Persiste le choix + met à jour le state in-memory. La bascule de
  /// `MaterialApp.locale` se fait automatiquement (LocaleNotifier `ref.watch`).
  /// Le router re-évalue son redirect (refreshListenable écoute ce notifier).
  Future<void> set(SubSystem subSystem) async {
    await ref.read(subsystemPrefsProvider).write(subSystem);
    state = subSystem;
  }
}

final subSystemNotifierProvider =
    NotifierProvider<SubSystemNotifier, SubSystem?>(SubSystemNotifier.new);

// =====================================================================
// Story 1.3 — providers du flow profil scolaire 3 etapes
// =====================================================================

/// State machine du flow Filiere -> Niveau -> Serie -> Recap.
/// Notifie les watchers (pages onboarding + router redirect) au changement.
class OnboardingFlowNotifier extends Notifier<OnboardingFlowState> {
  @override
  OnboardingFlowState build() => const OnboardingFlowState();

  void selectFiliere(String filiereId) {
    state = const OnboardingFlowState().copyWith(filiereId: filiereId);
  }

  void selectNiveau(String niveauId) {
    // Reset serie au cas ou un niveau precedent avait deja pose un serieId.
    state = OnboardingFlowState(
      filiereId: state.filiereId,
      niveauId: niveauId,
    );
  }

  /// `serieId` peut etre null si le niveau n'a pas de serie (skip explicite).
  void selectSerie(String? serieId) {
    state = state.copyWith(serieId: serieId);
  }

  /// Reset les champs APRES `step` (inclus). Permet a `backTo(filiere)` de
  /// repartir d'une feuille propre.
  void backTo(OnboardingFlowStep step) {
    state = state.resetFrom(step);
  }

  /// Reset complet (utile en tests ou apres deconnexion future).
  void reset() {
    state = const OnboardingFlowState();
  }
}

final onboardingFlowProvider =
    NotifierProvider<OnboardingFlowNotifier, OnboardingFlowState>(
  OnboardingFlowNotifier.new,
);

/// Repository Firestore du users/{uid}. Lazy.
final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepositoryFirestoreImpl(
    firestore: ref.watch(firestoreProvider),
    getUid: () => ref.read(firebaseAuthProvider).currentUser?.uid,
  );
});

// =====================================================================
// Story 1.5 — Garde navigation profil-incomplet (FR-4)
// =====================================================================

/// Stream du `ProfileCompletionState` derive de :
///   1. `subSystemNotifierProvider` (sync, SharedPreferences Story 1.2)
///   2. `firebaseAuthProvider.currentUser?.uid` (auth Story 0.6)
///   3. `userProfileRepository.watchProfile()` (Firestore users/{uid} Story 1.5)
///
/// Mapping :
///   - subSystem == null                    -> subsystemMissing
///   - uid == null (auth dropped)           -> filiereMissing (+ log warn)
///   - users/{uid} absent                   -> filiereMissing
///   - data['filiere'] null/vide            -> filiereMissing
///   - data['niveau'] null/vide             -> niveauMissing
///   - data['serie'] null/vide              -> serieMissing
///     (la sentinelle '-' Story 1.3 = present)
///   - tous champs presents et non vides    -> complete
///
/// Fail-safe : si le stream emet une erreur (FirebaseException
/// permission-denied, unavailable, etc.), retombe sur `filiereMissing`
/// + log warn (reason masquee, JAMAIS l'uid — CLAUDE.md securite 4).
///
/// Consomme par `GoRouter.redirect` (AC2) via `ref.read` + `.maybeWhen`.
final profileCompletionProvider =
    StreamProvider<ProfileCompletionState>((ref) {
  final subSystem = ref.watch(subSystemNotifierProvider);
  if (subSystem == null) {
    return Stream.value(ProfileCompletionState.subsystemMissing);
  }

  final auth = ref.watch(firebaseAuthProvider);
  final uid = auth.currentUser?.uid;
  if (uid == null) {
    AppLogger.w(
      'profileCompletion: fail-safe (filiereMissing) reason=auth-missing '
      'subSystem=${subSystem.id}',
    );
    return Stream.value(ProfileCompletionState.filiereMissing);
  }

  final repo = ref.watch(userProfileRepositoryProvider);
  return repo
      .watchProfile()
      .map(_mapDataToCompletion)
      .transform(_failSafeTransformer(subSystem.id));
});

/// Transformer fail-safe : si le stream emet une erreur, log warn (reason
/// masquee, JAMAIS l'uid — CLAUDE.md securite 4) puis emet `filiereMissing`.
StreamTransformer<ProfileCompletionState, ProfileCompletionState>
    _failSafeTransformer(String subSystemId) {
  return StreamTransformer<ProfileCompletionState, ProfileCompletionState>
      .fromHandlers(
    handleError: (Object e, StackTrace st,
        EventSink<ProfileCompletionState> sink) {
      AppLogger.w(
        'profileCompletion: fail-safe (filiereMissing) '
        'reason=${e.runtimeType} subSystem=$subSystemId',
      );
      sink.add(ProfileCompletionState.filiereMissing);
    },
  );
}

/// Helper pur : traduit la map brute Firestore en ProfileCompletionState.
/// La sentinelle `'-'` (Story 1.3 pour les niveaux sans serie) est consideree
/// comme **presente** — pas comme manquante.
ProfileCompletionState _mapDataToCompletion(Map<String, dynamic>? data) {
  if (data == null) return ProfileCompletionState.filiereMissing;
  final filiere = data['filiere'];
  final niveau = data['niveau'];
  final serie = data['serie'];

  if (filiere is! String || filiere.isEmpty) {
    return ProfileCompletionState.filiereMissing;
  }
  if (niveau is! String || niveau.isEmpty) {
    return ProfileCompletionState.niveauMissing;
  }
  if (serie is! String || serie.isEmpty) {
    return ProfileCompletionState.serieMissing;
  }
  return ProfileCompletionState.complete;
}

// =====================================================================
// Story 1.6 — Compte Google/Apple + merge visiteur (FR-5)
// =====================================================================

/// Singleton `GoogleSignIn.instance` exposed via Provider pour permettre
/// l'override en test. v7+ : `GoogleSignIn.instance` est statique.
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn.instance;
});

/// Repository de linking de compte anonyme vers Google/Apple.
///
/// Pattern : on injecte 3 fonctions (sign-in Google + sign-in Apple +
/// linkWithCredential) plutot que les singletons, pour permettre le test
/// unitaire des cas exception sans firebase_auth_mocks (absent du pubspec).
final accountLinkingRepositoryProvider =
    Provider<AccountLinkingRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final googleSignIn = ref.watch(googleSignInProvider);

  return AccountLinkingRepositoryFirebaseImpl(
    firestore: firestore,
    googleSignIn: () => googleSignIn.authenticate(
      scopeHint: const ['email', 'profile'],
    ),
    appleSignIn: () => SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    ),
    linkCredential: (credential) =>
        firebaseAuth.currentUser!.linkWithCredential(credential),
  );
});

/// State machine du linking (idle -> loading -> success/error).
class AccountLinkingNotifier extends Notifier<AccountLinkingState> {
  @override
  AccountLinkingState build() => const AccountLinkingState.idle();

  Future<void> linkGoogle() async {
    if (state.isLoading) return;
    state = const AccountLinkingState.loading(AccountProvider.google);
    final result = await ref.read(accountLinkingRepositoryProvider).linkGoogle();
    state = result.fold(
      (failure) => AccountLinkingState.error(failure),
      (account) => AccountLinkingState.success(account),
    );
  }

  Future<void> linkApple() async {
    if (state.isLoading) return;
    state = const AccountLinkingState.loading(AccountProvider.apple);
    final result = await ref.read(accountLinkingRepositoryProvider).linkApple();
    state = result.fold(
      (failure) => AccountLinkingState.error(failure),
      (account) => AccountLinkingState.success(account),
    );
  }

  /// Reset vers idle (ferme la modale conflit, permet de retenter).
  void reset() {
    state = const AccountLinkingState.idle();
  }
}

final accountLinkingNotifierProvider =
    NotifierProvider<AccountLinkingNotifier, AccountLinkingState>(
  AccountLinkingNotifier.new,
);

// =====================================================================
// Story 1.7 — Liaison ecole optionnelle (FR-6)
// =====================================================================

/// Repository Firestore du catalogue `schools` + sous-collection requests.
/// Reutilise `firebaseAuthProvider` pour injecter l'uid (pattern Story 1.3).
final schoolRepositoryProvider = Provider<SchoolRepository>((ref) {
  return SchoolRepositoryFirestoreImpl(
    firestore: ref.watch(firestoreProvider),
    getUid: () => ref.read(firebaseAuthProvider).currentUser?.uid,
  );
});

/// State machine de la recherche autocomplete avec debounce 300ms interne.
///
/// `state` :
///   - `AsyncValue.data([])` : invitation vide (rien tape, ou < 2 chars)
///   - `AsyncValue.loading()` : query Firestore en cours
///   - `AsyncValue.data([...])` : resultats
///   - `AsyncValue.error(SchoolFailure)` : erreur Firestore
///
/// Le notifier expose 2 actions :
///   - `search(query)` : declenche la recherche avec debounce 300ms
///   - `clear()` : reset a `data([])` sans attendre le debounce
class SchoolSearchNotifier extends Notifier<AsyncValue<List<School>>> {
  Timer? _debounceTimer;
  String? _lastQuery;

  @override
  AsyncValue<List<School>> build() {
    ref.onDispose(() => _debounceTimer?.cancel());
    return const AsyncValue.data([]);
  }

  void search(String query) {
    _debounceTimer?.cancel();
    _lastQuery = query;
    if (query.length < 2) {
      state = const AsyncValue.data([]);
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      // Si l'utilisateur a deja tape autre chose pendant le debounce, le
      // _lastQuery aura ete update mais ce timer est cancelled. Defensive
      // check : verifier que ce timer n'a pas ete remplace.
      if (_lastQuery != query) return;
      state = const AsyncValue.loading();
      final result =
          await ref.read(schoolRepositoryProvider).searchByPrefix(query);
      // Si une nouvelle recherche a ete demandee entre temps, ignorer.
      if (_lastQuery != query) return;
      state = result.fold(
        (failure) => AsyncValue.error(failure, StackTrace.current),
        (schools) => AsyncValue.data(schools),
      );
    });
  }

  void clear() {
    _debounceTimer?.cancel();
    _lastQuery = null;
    state = const AsyncValue.data([]);
  }
}

final schoolSearchNotifierProvider =
    NotifierProvider<SchoolSearchNotifier, AsyncValue<List<School>>>(
  SchoolSearchNotifier.new,
);

// =====================================================================
// Story 1.3/1.4 — providers derives du profil
// =====================================================================

/// FutureProvider qui derive matieres + examens depuis le profil courant.
/// Invalide automatiquement quand subSystem ou flowState changent (ref.watch).
/// Retourne `Left(CatalogueFailure)` si :
///   - subSystem absent (ne devrait pas arriver : Story 1.2 garde redirect)
///   - flow incomplet (manque filiere ou niveau)
///   - derive() echoue (offline+vide, noMatchingRule, FirebaseException)
final derivedProfileProvider =
    FutureProvider<Either<CatalogueFailure, DerivedProfile>>((ref) async {
  final subSystem = ref.watch(subSystemNotifierProvider);
  final flow = ref.watch(onboardingFlowProvider);

  if (subSystem == null) {
    // Coherent avec CatalogueFailure.noMatchingRule (le profil n'est pas
    // valide). En pratique ne devrait pas arriver — le router redirige
    // vers /onboarding/subsystem si subSystem est null.
    return Left(
      CatalogueFailure.noMatchingRule(
        subSystem: 'unknown',
        filiere: flow.filiereId ?? 'unknown',
        niveau: flow.niveauId ?? 'unknown',
        serie: flow.serieId,
      ),
    );
  }

  if (!flow.isComplete) {
    return Left(
      CatalogueFailure.noMatchingRule(
        subSystem: subSystem.id,
        filiere: flow.filiereId ?? 'unknown',
        niveau: flow.niveauId ?? 'unknown',
        serie: flow.serieId,
      ),
    );
  }

  final repo = ref.watch(catalogueRepositoryProvider);
  return repo.derive(
    subSystem: subSystem.id,
    filiere: flow.filiereId!,
    niveau: flow.niveauId!,
    serie: flow.serieId, // peut etre null (niveau sans serie)
  );
});

// =====================================================================
// Story 1.4 — Retrait conditionnel matieres (FR-3)
// =====================================================================

/// Stream de la liste effective des matieres (derivedSubjects \ optedOutSubjects).
///
/// Combine :
///   1. `derivedProfileProvider` (Story 1.3) -> profil derive du catalogue
///   2. `userProfileRepository.watchProfile()` -> stream users/{uid} avec
///      `optedOutSubjects` a jour
///
/// Retourne la liste filtree : matieres dont l'id n'est PAS dans `optedOutSubjects`.
///
/// Pattern : logique de filtrage dans le provider, pas dans la widget — testable
/// et memoise Riverpod (re-evalue uniquement quand l'un des inputs change).
///
/// Empty stream si :
///   - derivedProfile en loading -> stream vide jusqu'a resolution
///   - derivedProfile en error/Left -> stream vide (la page recap gere son propre
///     error state, on ne double pas le message)
final effectiveDerivedSubjectsProvider =
    StreamProvider<List<Subject>>((ref) {
  final derivedAsync = ref.watch(derivedProfileProvider);
  final repo = ref.watch(userProfileRepositoryProvider);

  return derivedAsync.maybeWhen(
    data: (either) => either.fold(
      (_) => const Stream<List<Subject>>.empty(),
      (profile) => repo.watchProfile().map((data) {
        final optedOut =
            (data?['optedOutSubjects'] as List?)?.cast<String>() ??
                const <String>[];
        return profile.subjects
            .where((s) => !optedOut.contains(s.subjectId))
            .toList(growable: false);
      }),
    ),
    orElse: () => const Stream<List<Subject>>.empty(),
  );
});
