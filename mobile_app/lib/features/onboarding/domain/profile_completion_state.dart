// Story 1.5 — Etat de completion du profil utilisateur (FR-4).
//
// Couche domain pure : aucun import Flutter, Firebase, Riverpod (ADR-001 regle d'or).
//
// Les 5 etats encodent les paliers du flow d'onboarding :
//   1. subsystemMissing  : Story 1.2 pas encore faite
//   2. filiereMissing    : users/{uid} absent OU sans champ 'filiere'
//   3. niveauMissing     : 'filiere' OK, 'niveau' absent/vide
//   4. serieMissing      : 'niveau' OK, 'serie' absent/vide
//                          (la sentinelle '-' Story 1.3 compte comme presente)
//   5. complete          : tous champs presents et non vides
//
// `nextOnboardingRoute` mappe l'etat vers la route de redirect attendue par
// `profileCompletionProvider` (Story 1.5) via `GoRouter.redirect`.

enum ProfileCompletionState {
  subsystemMissing,
  filiereMissing,
  niveauMissing,
  serieMissing,
  complete;

  /// Route cible si l'utilisateur tente une nav metier dans cet etat.
  /// `/` n'est jamais retourne aux consommateurs (le router gere ce cas
  /// en laissant passer la route) — la valeur est presente pour exhaustivite
  /// du switch.
  String get nextOnboardingRoute => switch (this) {
        ProfileCompletionState.subsystemMissing => '/onboarding/subsystem',
        ProfileCompletionState.filiereMissing => '/onboarding/profile/filiere',
        ProfileCompletionState.niveauMissing => '/onboarding/profile/niveau',
        ProfileCompletionState.serieMissing => '/onboarding/profile/serie',
        ProfileCompletionState.complete => '/',
      };

  bool get isComplete => this == ProfileCompletionState.complete;
}
