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
import '../../../../core/logging/app_logger.dart';
import 'onboarding_notifier.dart';
import 'onboarding_state.dart';

/// Provider racine de la state machine onboarding refonte (Epic E1bis).
final onboardingNotifierProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
  OnboardingNotifier.new,
);

/// Story E1bis-3 — Profil derive depuis le state E1bis.
///
/// Matche la règle en mémoire depuis le snapshot [catalogueProvider] (données
/// fraîches chargées au démarrage) plutôt que de refaire une query Firestore
/// dédiée. Seuls les fetches subjects/examTargets/série sont effectués via
/// [CatalogueRepository.deriveFromRule]. Avantage : -1 RTT + pas de cache
/// stale sur la query derivation_rules (bug LV2 post-seed 2026-06-15).
///
/// Consommé par [StreamSubjectsPickerStepBody] (step 4) pour dispatcher sur
/// [DerivedProfile.pickerMode] (5 modes).
final derivedProfileV2Provider =
    FutureProvider<Either<CatalogueFailure, DerivedProfile>>((ref) async {
  final state = ref.watch(onboardingNotifierProvider);
  final repo = ref.watch(catalogueRepositoryProvider);
  // Le snapshot est déjà chargé par catalogueProvider au splash — l'await
  // retourne quasi-instantanément (pas de RTT supplémentaire).
  final snapshot = await ref.watch(catalogueProvider.future);

  final subSystemId = state.subSystem?.id;
  final trackId = state.trackId;
  final levelId = state.levelId;
  final streamId = state.streamId;

  if (subSystemId == null || trackId == null || levelId == null) {
    return Left(
      CatalogueFailure.noMatchingRule(
        subSystem: subSystemId ?? 'unknown',
        filiere: trackId ?? 'unknown',
        niveau: levelId ?? 'unknown',
        serie: streamId,
      ),
    );
  }

  // Matching en mémoire — même logique que derive() (filiere wildcard + serie nullable).
  final rule = snapshot.derivationRules
      .where((r) =>
          r.isActive &&
          r.matchSubSystem == subSystemId &&
          (r.matchFiliere == '*' || r.matchFiliere == trackId) &&
          r.matchNiveau == levelId &&
          (r.matchSerie == null || r.matchSerie == streamId))
      .firstOrNull;

  if (rule == null) {
    AppLogger.w(
      'derive() noMatchingRule: subSystem=$subSystemId filiere=$trackId '
      'niveau=$levelId serie=${streamId ?? "(none)"}',
    );
    return Left(
      CatalogueFailure.noMatchingRule(
        subSystem: subSystemId,
        filiere: trackId,
        niveau: levelId,
        serie: streamId,
      ),
    );
  }

  return repo.deriveFromRule(rule: rule, serie: streamId);
});
