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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/catalogue/domain/catalogue_failure.dart';
import '../../core/catalogue/domain/models.dart';
import '../../core/catalogue/providers.dart';
import '../../core/firebase/providers.dart';
import 'data/subsystem_prefs.dart';
import 'data/user_profile_repository_firestore_impl.dart';
import 'domain/onboarding_flow_state.dart';
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
