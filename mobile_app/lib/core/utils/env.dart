// Lecture centralisée des variables d'environnement injectées au build via
// `--dart-define`. Les valeurs par défaut sont des sentinelles non-prod.
// Ne JAMAIS y mettre un secret (cf. CLAUDE.md § Sécurité 1).

class Env {
  const Env._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.valide.school',
  );
}
