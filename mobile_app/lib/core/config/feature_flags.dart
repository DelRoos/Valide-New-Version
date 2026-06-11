// Story E1bis-2 — Feature flags constants pour la refonte onboarding.
//
// Toggle au build time (constante compile-time) pour activer/desactiver le
// nouveau flow onboarding E1bis sans casser le flow Epic 1 live en prod.
// Si besoin d'un toggle runtime (QA via la page audit toolkit), migrer vers
// SharedPreferences dans une story dette ulterieure.
//
// Defaut OFF : tant que les pages E1bis-3 a E1bis-7 ne sont pas livrees, on
// ne veut pas envoyer les utilisateurs dans un flow incomplet.

class FeatureFlags {
  FeatureFlags._();

  /// Si vrai, le router redirige `/onboarding/subsystem` (Epic 1 legacy)
  /// vers `/onboarding/sub-system-v2` (nouveau flow E1bis). Si faux, le
  /// flow Epic 1 reste actif.
  ///
  /// Toggle au build pour QA. Migration runtime via SharedPreferences :
  /// story dette future si besoin.
  static const bool useNewOnboardingFlow = false;
}
