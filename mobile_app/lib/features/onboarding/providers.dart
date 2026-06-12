// Providers Riverpod feature onboarding.
//
// Story E1bis-9 — Cleanup Epic 1 legacy. Suppression de :
//   - `onboardingFlowProvider` + `OnboardingFlowNotifier` (state machine
//     filiere/niveau/serie remplacee par `OnboardingNotifier` E1bis).
//   - `onboardingFlowPrefsProvider` (persistance flow Story 1.8).
//   - `derivedProfileProvider` refactor : lit `userProfileRepository.watchProfile()`
//     au lieu de `onboardingFlowProvider`. Le dashboard consomme toujours ce
//     provider pour afficher les matieres.
//
// Providers exposes :
//   1. `sharedPreferencesProvider` : instance préchargée en `main.dart`.
//   2. `subsystemPrefsProvider` : wrapper lazy autour de SharedPreferences.
//   3. `subSystemNotifierProvider` : state in-memory du sous-système choisi.
//   4. `userProfileRepositoryProvider` : impl Firestore.
//   5. `profileCompletionProvider` (Story 1.5) : Stream `ProfileCompletionState`.
//   6. `derivedProfileProvider` (refactor E1bis-9) : Stream du DerivedProfile
//      derive de users/{uid}.
//   7. `effectiveDerivedSubjectsProvider` (Story 1.4) : matieres filtrees
//      `derivedSubjects \ optedOutSubjects`.
//   8. `accountLinkingRepositoryProvider` + `accountLinkingNotifierProvider`
//      (Story 1.6) — reutilises par E1bis-4 future.
//   9. `schoolRepositoryProvider` + `schoolSearchNotifierProvider` (Story 1.7)
//      — reutilises par E1bis-6 future.
//  10. `googleSignInProvider` (Story 1.6).

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/catalogue/domain/models.dart';
import '../../core/catalogue/providers.dart';
import '../../core/firebase/providers.dart';
import '../../core/logging/app_logger.dart';
import 'data/account_linking_repository_firebase_impl.dart';
import 'data/onboarding_flush_service.dart';
import 'data/school_repository_firestore_impl.dart';
import 'data/subsystem_prefs.dart';
import 'data/user_profile_repository_firestore_impl.dart';
import 'domain/account_linking_repository.dart';
import 'domain/account_linking_state.dart';
import 'domain/linked_account.dart';
import 'domain/profile_completion_state.dart';
import 'domain/school.dart';
import 'domain/school_repository.dart';
import 'domain/sub_system.dart';
import 'domain/user_profile_repository.dart';

/// SharedPreferences préchargée en `main.dart` avant `runApp`.
///
/// MUST be overridden in `ProviderScope.overrides`.
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
/// est préchargé). Notifie les watchers (LocaleNotifier dans `app.dart`).
class SubSystemNotifier extends Notifier<SubSystem?> {
  @override
  SubSystem? build() => ref.read(subsystemPrefsProvider).read();

  /// Persiste le choix + met à jour le state in-memory.
  Future<void> set(SubSystem subSystem) async {
    await ref.read(subsystemPrefsProvider).write(subSystem);
    state = subSystem;
  }
}

final subSystemNotifierProvider =
    NotifierProvider<SubSystemNotifier, SubSystem?>(SubSystemNotifier.new);

/// Repository Firestore du users/{uid}. Lazy.
final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepositoryFirestoreImpl(
    firestore: ref.watch(firestoreProvider),
    getUid: () => ref.read(firebaseAuthProvider).currentUser?.uid,
  );
});

/// Story E1bis-7 — Service de flush du profil onboarding vers users/{uid}.
final onboardingFlushServiceProvider = Provider<OnboardingFlushService>((ref) {
  return OnboardingFlushService(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

/// Story E1bis-7 — Liste des matieres du user, derivee depuis users/{uid}
/// (schema E1bis : pickedSubjects ou subjects[] derivees via trackId/levelId/
/// streamId). Stream Firestore + jointure catalogueProvider in-memory.
///
/// Retourne :
///   - [] si users/{uid} absent ou pickedSubjects vide
///   - liste de Subject matchant pickedSubjects (resolus via catalogue)
final userSubjectsProvider = StreamProvider<List<Subject>>((ref) {
  final userRepo = ref.watch(userProfileRepositoryProvider);
  final catalogueAsync = ref.watch(catalogueProvider);

  return userRepo.watchProfile().map((data) {
    if (data == null) return const <Subject>[];
    final pickedIds = (data['pickedSubjects'] as List?)?.cast<String>() ??
        const <String>[];
    if (pickedIds.isEmpty) return const <Subject>[];
    return catalogueAsync.maybeWhen(
      data: (snapshot) {
        final idSet = pickedIds.toSet();
        return snapshot.subjects
            .where((s) => idSet.contains(s.subjectId))
            .toList(growable: false);
      },
      orElse: () => const <Subject>[],
    );
  });
});

// =====================================================================
// Story 1.5 — Garde navigation profil-incomplet (FR-4)
// =====================================================================

/// Stream du `ProfileCompletionState` derive de :
///   1. `subSystemNotifierProvider` (sync, SharedPreferences Story 1.2)
///   2. `firebaseAuthProvider.currentUser?.uid` (auth Story 0.6)
///   3. `userProfileRepository.watchProfile()` (Firestore users/{uid} Story 1.5)
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
///
/// Schema E1bis (post 2026-06-13) : `trackId` + `levelId` + `streamId`
/// (anglais). `streamId` peut etre null pour les niveaux sans serie (6e,
/// Form 1...) — on considere le profil complet si trackId + levelId sont
/// poses. Le visiteur (isAnonymous=true sans displayName/phone/school) est
/// considere complet — pas de bounce vers l'onboarding.
///
/// Schema legacy Epic 1 (`filiere` + `niveau` + `serie`) : retrocompat tant
/// que les docs users existants n'ont pas migre (Story 1.19 dette).
ProfileCompletionState _mapDataToCompletion(Map<String, dynamic>? data) {
  if (data == null) return ProfileCompletionState.filiereMissing;

  // Schema E1bis prioritaire (post-2026-06-13).
  final trackId = data['trackId'];
  final levelId = data['levelId'];
  if (trackId is String && trackId.isNotEmpty) {
    if (levelId is String && levelId.isNotEmpty) {
      return ProfileCompletionState.complete;
    }
    return ProfileCompletionState.niveauMissing;
  }

  // Schema legacy Epic 1 (filiere / niveau / serie).
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
/// l'override en test.
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn.instance;
});

/// Repository de linking de compte anonyme vers Google/Apple.
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

/// Repository Firestore du catalogue `schools` + collection `school_requests`.
final schoolRepositoryProvider = Provider<SchoolRepository>((ref) {
  return SchoolRepositoryFirestoreImpl(
    firestore: ref.watch(firestoreProvider),
    getUid: () => ref.read(firebaseAuthProvider).currentUser?.uid,
  );
});

/// State machine de la recherche autocomplete avec debounce 300ms interne.
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
      if (_lastQuery != query) return;
      state = const AsyncValue.loading();
      final result =
          await ref.read(schoolRepositoryProvider).searchByPrefix(query);
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

// Story E1bis-9 — Suppression des providers Epic 1 :
//   - `derivedProfileProvider` (FutureProvider derive de onboardingFlowProvider)
//   - `effectiveDerivedSubjectsProvider` (filtre opted-out matieres)
//
// Justification : ces providers consommaient le schema Epic 1 (filiere/
// niveau/serie/optedOutSubjects) sur users/{uid}. Le schema E1bis-4..7
// (trackId/levelId/streamId/pickedSubjects) sera defini quand le flush
// Firestore sera livre. En attendant, le `DashboardPage` affiche un empty
// state pour les comptes sans profil flush. Pas de mid-state hybride
// schema Epic 1 / E1bis maintenu cote code.
