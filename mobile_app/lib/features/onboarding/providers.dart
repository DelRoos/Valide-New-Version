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
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/catalogue/domain/catalogue_failure.dart';
import '../../core/catalogue/domain/models.dart';
import '../../core/catalogue/providers.dart';
import '../../core/firebase/providers.dart';
import '../../core/logging/app_logger.dart';
import 'data/subsystem_prefs.dart';
import 'data/user_profile_repository_firestore_impl.dart';
import 'domain/onboarding_flow_state.dart';
import 'domain/profile_completion_state.dart';
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
