// Story E1bis-2 — Feature flags pour la refonte onboarding.
//
// **Refactor 2026-06-12 (fix routing)** : `useNewOnboardingFlow` est
// desormais un PROVIDER Riverpod overridable au lieu d'une constante
// compile-time. Permet aux tests (Story 1.2 subsystem_choice_page_test
// notamment, qui utilisent ValideApp) d'override le flag a false pendant
// que le toggle local dev reste a true pour test runtime sur appareil.
//
// La valeur par defaut du provider est lue depuis la constante
// `FeatureFlags.useNewOnboardingFlow` (toggle build time). Pour QA runtime,
// modifier la constante puis hot-restart.
//
// Pour tests : `featureFlagsProvider.overrideWithValue(const FeatureFlags(useNewOnboardingFlow: false))`.

import 'package:flutter_riverpod/flutter_riverpod.dart';

class FeatureFlags {
  const FeatureFlags({this.useNewOnboardingFlow = false});

  /// Si vrai, le router redirige les routes onboarding Epic 1 legacy
  /// (`/onboarding/subsystem`, `/onboarding/profile/*`, `/onboarding/account`,
  /// `/onboarding/school`) vers la route unique `/onboarding/v2` (nouveau
  /// shell E1bis). Si faux, le flow Epic 1 reste actif.
  ///
  /// Toggle au build pour QA via [defaultFeatureFlags]. Override possible
  /// en tests via [featureFlagsProvider] (cf. doc en tete de fichier).
  final bool useNewOnboardingFlow;
}

/// Valeur par defaut du provider — toggle au build time pour QA runtime.
///
/// Modifier `useNewOnboardingFlow: true` puis hot-restart pour tester le
/// nouveau flow E1bis sur appareil. Remettre `false` avant push si tu veux
/// que les tests Epic 1 (Story 1.2) continuent de passer SANS modification
/// des tests eux-memes.
const FeatureFlags defaultFeatureFlags = FeatureFlags(
  useNewOnboardingFlow: true,
);

/// Provider lecture-seule des feature flags. Override en tests via
/// `featureFlagsProvider.overrideWithValue(const FeatureFlags(useNewOnboardingFlow: false))`.
final featureFlagsProvider = Provider<FeatureFlags>((ref) {
  return defaultFeatureFlags;
});
