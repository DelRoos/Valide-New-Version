// Story E1bis-1 — Provider Riverpod de la state machine onboarding refonte.
//
// Expose une seule provider racine consommee par les step bodies et le
// wrapper `OnboardingShell`. Les pages calculent leurs derivees localement
// via `ref.watch(onboardingNotifierProvider)`.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/catalogue/domain/catalogue_failure.dart';
import '../../../../core/catalogue/domain/models.dart';
import '../../../../core/catalogue/providers.dart';
import 'onboarding_notifier.dart';
import 'onboarding_state.dart';

/// Provider racine de la state machine onboarding refonte (Epic E1bis).
final onboardingNotifierProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
  OnboardingNotifier.new,
);

/// Story E1bis-3 — Profil derive depuis le state E1bis.
///
/// Appelle `CatalogueRepository.derive(...)` avec les valeurs du
/// `OnboardingNotifier` (subSystem + trackId + levelId + streamId). Retourne
/// `Left(CatalogueFailure.noMatchingRule)` si les champs requis sont nuls
/// (cas marginal : le router redirige normalement vers la step manquante).
///
/// Consomme par `StreamSubjectsPickerStepBody` (step 4) pour dispatcher sur
/// `DerivedProfile.pickerMode` (5 modes).
final derivedProfileV2Provider =
    FutureProvider<Either<CatalogueFailure, DerivedProfile>>((ref) async {
  final state = ref.watch(onboardingNotifierProvider);
  final repo = ref.watch(catalogueRepositoryProvider);

  final subSystemId = state.subSystem?.id;
  final trackId = state.trackId;
  final levelId = state.levelId;

  if (subSystemId == null || trackId == null || levelId == null) {
    return Left(
      CatalogueFailure.noMatchingRule(
        subSystem: subSystemId ?? 'unknown',
        filiere: trackId ?? 'unknown',
        niveau: levelId ?? 'unknown',
        serie: state.streamId,
      ),
    );
  }

  return repo.derive(
    subSystem: subSystemId,
    filiere: trackId,
    niveau: levelId,
    serie: state.streamId,
  );
});
