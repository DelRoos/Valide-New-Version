// Story 1.5 — Etat de completion du profil utilisateur (FR-4).
//
// Couche domain pure : aucun import Flutter, Firebase, Riverpod (ADR-001 regle d'or).
//
// Les 5 etats encodent les paliers du flow d'onboarding. Story E1bis-9 :
// le router consomme uniquement `isComplete` (toutes les routes incompletes
// menent vers `/onboarding/v2`). Le getter Epic 1 `nextOnboardingRoute`
// (qui mappait chaque etat vers une route /onboarding/profile/*) a ete
// supprime avec le flow Epic 1.

enum ProfileCompletionState {
  subsystemMissing,
  filiereMissing,
  niveauMissing,
  serieMissing,
  complete;

  bool get isComplete => this == ProfileCompletionState.complete;
}
