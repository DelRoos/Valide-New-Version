// Providers Riverpod feature onboarding.
//
// Providers exposes :
//   1. `sharedPreferencesProvider` : instance préchargée en `main.dart`.
//   2. `subsystemPrefsProvider` : wrapper lazy autour de SharedPreferences.
//   3. `onboardingDraftPrefsProvider` : persistance du draft flow E1bis
//      (audit 2026-06-13 PR1).
//   4. `subSystemNotifierProvider` : state in-memory du sous-système choisi.
//   5. `userProfileRepositoryProvider` : impl Firestore.
//   6. `onboardingFlushServiceProvider` : ecrit le profil onboarding dans
//      users/{uid} apres completion (E1bis-7).
//   7. `userSubjectsProvider` : Stream des Subject du user derives depuis
//      users/{uid}.pickedSubjects + jointure catalogue.
//   8. `profileCompletionProvider` : Stream `ProfileCompletionState` (garde
//      navigation profil-incomplet).
//   9. `accountLinkingRepositoryProvider` + `accountLinkingNotifierProvider` :
//      OAuth Google/Apple, reutilise par auth_choice_step_body + account
//      upgrade sheet (audit PR5).
//  10. `schoolRepositoryProvider` + `schoolSearchNotifierProvider` :
//      recherche autocomplete ecoles.
//  11. `googleSignInProvider`.
//  12. `profileDataProvider` : StreamProvider.autoDispose partagé sur
//      users/{uid}. Remplace les appels directs à watchProfile() dans build()
//      qui créaient un nouveau stream Firestore à chaque rebuild.
//  13. `deletionScheduledForProvider` : DateTime? dérivée de
//      profileDataProvider.deletionRequestedAt + 7 jours.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/catalogue/domain/models.dart';
import '../../core/catalogue/providers.dart';
import '../../core/firebase/providers.dart';
import '../../core/logging/app_logger.dart';
import '../account/domain/public_profile.dart';
import 'data/account_linking_repository_firebase_impl.dart';
import 'data/onboarding_draft_prefs.dart';
import 'data/onboarding_flush_service.dart';
import 'data/school_repository_firestore_impl.dart';
import 'data/subsystem_prefs.dart';
import 'data/user_profile_repository_firestore_impl.dart';
import 'domain/account_linking_repository.dart';
import 'domain/account_linking_state.dart';
import 'domain/linked_account.dart';
import 'domain/profile_completion_state.dart';
import 'domain/profile_failure.dart';
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

/// Audit 2026-06-13 (PR1) — Wrapper SharedPreferences pour le draft du flow
/// onboarding refonte E1bis. Persiste trackId/levelId/streamId/pickedSubjects/
/// currentStep entre kill app et relaunch (cf. OnboardingDraftPrefs).
final onboardingDraftPrefsProvider = Provider<OnboardingDraftPrefs>((ref) {
  return OnboardingDraftPrefs(ref.watch(sharedPreferencesProvider));
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
    draftPrefs: ref.watch(onboardingDraftPrefsProvider),
    catalogueRepository: ref.watch(catalogueRepositoryProvider),
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
  // Rebuild quand auth change pour eviter le stream stale sur l'ancien uid
  // (typique apres dev-audit-reset ou sign-out -> re-auth anonyme).
  ref.watch(currentUserProvider);

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
///   2. `currentUserProvider` — User? courant (Audit NEW-BUG-17 :
///      `authStateChanges()` propage les transitions signIn/signOut)
///   3. `userProfileRepository.watchProfile()` (Firestore users/{uid} Story 1.5)
///
/// Audit NEW-BUG-17 2026-06-13 — Avant ce fix, on lisait
/// `firebaseAuthProvider.currentUser` directement. Le `firebaseAuthProvider`
/// est un `Provider` STATIQUE, donc Riverpod ne reagissait pas aux
/// `signInAnonymously()` declenches au step 5 -> le router restait bloque
/// sur `/onboarding` avec uid=null. Maintenant on watch `currentUserProvider`
/// (StreamProvider sur `authStateChanges()`) qui propage proprement.
final profileCompletionProvider =
    StreamProvider<ProfileCompletionState>((ref) {
  final subSystem = ref.watch(subSystemNotifierProvider);
  if (subSystem == null) {
    return Stream.value(ProfileCompletionState.subsystemMissing);
  }

  // Watch le StreamProvider auth pour rebuild a chaque transition.
  final userAsync = ref.watch(currentUserProvider);
  String? uid = userAsync.maybeWhen(
    data: (user) => user?.uid,
    orElse: () => null,
  );
  // Fallback synchrone : si AsyncLoading (etat transitoire ex. rebuild apres
  // dismiss CompleteProfileDialog), lire currentUser depuis FirebaseAuth pour
  // eviter un redirect spurieux vers /onboarding (Bug A 2026-06-29).
  // Ne s'applique pas aux erreurs (hasError=true -> fail-safe normal ci-dessous).
  if (uid == null && !userAsync.hasError) {
    uid = ref.read(firebaseAuthProvider).currentUser?.uid;
  }
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
/// Schema E1bis (post 2026-06-13) : `trackId` + `levelId` + `pickedSubjects`.
/// `streamId` peut etre null pour les niveaux sans serie (6e, Form 1...) —
/// pas dans l'invariant de completude. Le visiteur (isAnonymous=true sans
/// displayName/phone/school) est considere complet — pas de bounce vers
/// l'onboarding.
///
/// Audit 2026-06-13 (PR1) — `pickedSubjects` non-vide est maintenant exige.
/// Avant ce PR, un flush partiel (reseau coupe entre l'ecriture des champs)
/// laissait `trackId+levelId` poses mais `pickedSubjects=[]` -> profil
/// considere complet -> redirect dashboard vide. Confusion utilisateur.
///
/// Bug 4 fix (2026-06-17) — Compte permanent (isAnonymous=false) avec
/// displayName vide = upgrade visiteur interrompu avant completion identite
/// (steps 6-8). profileUpgradeInProgressProvider est en memoire -> perdu au
/// kill app. On derive l'etat depuis le doc Firestore pour que le router
/// renvoie vers /onboarding meme apres un relaunch.
///
/// Schema legacy Epic 1 (`filiere` + `niveau` + `serie`) : retrocompat tant
/// que les docs users existants n'ont pas migre (Story 1.19 dette).
ProfileCompletionState _mapDataToCompletion(Map<String, dynamic>? data) {
  if (data == null) return ProfileCompletionState.filiereMissing;

  // Schema E1bis prioritaire (post-2026-06-13).
  final trackId = data['trackId'];
  final levelId = data['levelId'];
  if (trackId is String && trackId.isNotEmpty) {
    if (levelId is! String || levelId.isEmpty) {
      return ProfileCompletionState.niveauMissing;
    }
    // Audit PR1 : exiger des matieres effectivement rattachees au profil
    // pour eviter les dashboards vides post flush partiel.
    final picked = data['pickedSubjects'];
    if (picked is! List || picked.isEmpty) {
      return ProfileCompletionState.serieMissing;
    }
    // Bug 4 fix : compte permanent sans displayName = upgrade interrompu.
    // isAnonymous=false (pose par _persistIdentity au moment du link OAuth)
    // + displayName vide = le user a linke son compte mais n'a pas complete
    // les steps identite (6-8). On le renvoie vers /onboarding.
    final isAnonymous = data['isAnonymous'] as bool? ?? true;
    final displayName = data['displayName'] as String? ?? '';
    if (!isAnonymous && displayName.isEmpty) {
      AppLogger.w(
        'profileCompletion: compte permanent sans displayName -> identite incomplete',
      );
      return ProfileCompletionState.filiereMissing;
    }
    return ProfileCompletionState.complete;
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
    linkCredential: (credential) {
      // Si currentUser est null (premier lancement sans session anonyme
      // préalable), linkWithCredential crasherait avec Null check error.
      // On retombe sur signInWithCredential pour créer un compte Google direct.
      final u = firebaseAuth.currentUser;
      return u != null
          ? u.linkWithCredential(credential)
          : firebaseAuth.signInWithCredential(credential);
    },
    signInWithCredential: (credential) =>
        firebaseAuth.signInWithCredential(credential),
    getCurrentUser: () => firebaseAuth.currentUser,
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

/// Flag posé lors d'un upgrade visiteur -> compte permanent (Google/Apple)
/// déclenché depuis la modale dashboard (AccountUpgradeSheet).
///
/// Tant que true, le router autorise /onboarding même si
/// profileCompletionProvider == complete — le profil scolaire existe déjà
/// (flush guest), mais l'identité (name + phone + school, steps 6-8) reste
/// à compléter. Remis à false par SuccessCelebrationStepBody._onComplete()
/// après le flush final au step 9.
class ProfileUpgradeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setInProgress(bool value) => state = value;
}

final profileUpgradeInProgressProvider =
    NotifierProvider<ProfileUpgradeNotifier, bool>(ProfileUpgradeNotifier.new);

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

/// State machine de la recherche autocomplete — entierement en memoire.
/// Charge toutes les ecoles une seule fois (preload), puis filtre cote client
/// par prefixe sur le champ `keywords[]` pre-calcule par le seed.
/// Avantage : 0 appel Firestore supplementaire apres preload, recherche
/// instantanee meme en offline (cache natif).
class SchoolSearchNotifier extends Notifier<AsyncValue<List<School>>> {
  Timer? _debounceTimer;
  List<School> _allSchools = const [];
  bool _loaded = false;

  // Table de translitteration accents -> ASCII pour la normalisation des tokens.
  static const Map<String, String> _kAccentMap = {
    'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
    'ç': 'c', 'ñ': 'n',
    'À': 'a', 'Â': 'a', 'Ä': 'a', 'Á': 'a', 'Ã': 'a',
    'È': 'e', 'É': 'e', 'Ê': 'e', 'Ë': 'e',
    'Ì': 'i', 'Í': 'i', 'Î': 'i', 'Ï': 'i',
    'Ò': 'o', 'Ó': 'o', 'Ô': 'o', 'Ö': 'o',
    'Ù': 'u', 'Ú': 'u', 'Û': 'u', 'Ü': 'u',
    'Ç': 'c', 'Ñ': 'n',
  };

  /// Decompose la saisie utilisateur en tokens ASCII minuscules (≥2 chars).
  static List<String> _queryTokens(String query) {
    if (query.isEmpty) return const [];
    final lower = query.toLowerCase();
    final buf = StringBuffer();
    for (final char in lower.split('')) {
      buf.write(_kAccentMap[char] ?? char);
    }
    final cleaned = buf.toString().replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
    return cleaned.split(RegExp(r'\s+')).where((t) => t.length >= 2).toList();
  }

  @override
  AsyncValue<List<School>> build() {
    ref.onDispose(() => _debounceTimer?.cancel());
    return const AsyncValue.data([]);
  }

  /// Charge toutes les ecoles depuis Firestore (une seule fois).
  /// Les appels suivants sont des no-op si deja charge.
  void preload({int limit = 300}) {
    if (_loaded) return;
    state = const AsyncValue.loading();
    ref.read(schoolRepositoryProvider).listFirst(limit).then((result) {
      state = result.fold(
        (failure) {
          AppLogger.w('schools.preload failed: ${failure.message}');
          return const AsyncValue.data([]);
        },
        (schools) {
          _allSchools = schools;
          _loaded = true;
          AppLogger.i('schools.preload count=${schools.length}');
          return AsyncValue.data(schools);
        },
      );
    });
  }

  /// Filtre en memoire par prefixe sur keywords[]. Debounce 150 ms.
  void search(String query) {
    _debounceTimer?.cancel();
    final tokens = _queryTokens(query.trim());
    if (tokens.isEmpty) {
      state = AsyncValue.data(_allSchools);
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      final filtered = _allSchools.where((s) {
        return tokens.every((qt) => s.keywords.any((k) => k.startsWith(qt)));
      }).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      state = AsyncValue.data(filtered);
    });
  }

  void clear() {
    _debounceTimer?.cancel();
    state = AsyncValue.data(_allSchools);
  }
}

final schoolSearchNotifierProvider =
    NotifierProvider<SchoolSearchNotifier, AsyncValue<List<School>>>(
  SchoolSearchNotifier.new,
);

// =====================================================================
// Dashboard profil — stream partagé users/{uid}
// =====================================================================

/// Stream partagé du doc users/{uid}, consommé par tous les widgets du profil.
///
/// Évite le bug "watchProfile() dans build()" : chaque appel direct crée un
/// nouveau listener Firestore à chaque rebuild. Ici, Riverpod gère le cycle
/// de vie du listener — un seul abonnement tant que la tab profil est active.
///
/// Rebuidle sur changement d'auth (currentUserProvider) pour éviter le stream
/// stale après sign-out/re-auth anonyme.
final profileDataProvider =
    StreamProvider.autoDispose<Map<String, dynamic>?>((ref) {
  ref.watch(currentUserProvider);
  return ref.watch(userProfileRepositoryProvider).watchProfile();
});

/// DateTime à laquelle la suppression de compte sera effective, dérivée de
/// `deletionRequestedAt` Firestore + 7 jours. Retourne `null` si aucune
/// demande en cours ou si les données du profil ne sont pas encore chargées.
///
/// Provider.autoDispose (pas StreamProvider) car la valeur est entièrement
/// dérivée de `profileDataProvider.valueOrNull` — Riverpod recalcule
/// automatiquement à chaque emission du stream parent.
final deletionScheduledForProvider = Provider.autoDispose<DateTime?>((ref) {
  final data = ref.watch(profileDataProvider).maybeWhen(
    data: (d) => d,
    orElse: () => null,
  );
  if (data == null) return null;
  final ts = data['deletionRequestedAt'];
  if (ts == null) return null;
  try {
    final requestedAt = (ts as dynamic).toDate() as DateTime;
    return requestedAt.add(const Duration(days: 7));
  } catch (_) {
    return null;
  }
});

// =====================================================================
// Story A.2 — Profil public d'un pair (lecture users/{uid} par uid tiers)
// =====================================================================

/// Lit le profil public de l'utilisateur identifié par [uid].
///
/// FutureProvider.autoDispose.family : chaque uid est mis en cache séparément,
/// libéré automatiquement dès que la page PublicProfilePage est dépilée.
/// Cost : 1 read Firestore par visite (règle A.2-DR-01).
final publicProfileProvider = FutureProvider.autoDispose
    .family<Either<ProfileFailure, PublicProfile?>, String>((ref, uid) {
  return ref.watch(userProfileRepositoryProvider).fetchPublicProfile(uid);
});
