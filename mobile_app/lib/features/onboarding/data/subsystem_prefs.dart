// Story 1.2 — Data : wrapper SharedPreferences pour le sous-système.
//
// Isole l'accès aux clés `subsystem` et `language` derrière une API
// synchrone. Toutes les opérations sont triviales (string get/set) — pas
// besoin de `Either<Failure, T>` ni de logger ici. Le `SharedPreferences`
// est préchargé dans `main.dart` avant `runApp` (Story 1.2 AC4) pour
// éviter tout flash de locale par défaut au boot.

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/sub_system.dart';

class SubsystemPrefs {
  SubsystemPrefs(this._prefs);

  final SharedPreferences _prefs;

  // Clés SharedPreferences. Préfixées pour éviter les collisions futures
  // (autres features pourraient persister leurs propres états).
  static const String _kSubsystemKey = 'onboarding.subsystem';
  static const String _kLanguageKey = 'onboarding.language';

  /// Lit le sous-système persisté. Retourne `null` au 1er lancement (jamais
  /// écrit) OU si la valeur stockée est corrompue (string inattendue).
  SubSystem? read() => SubSystem.fromString(_prefs.getString(_kSubsystemKey));

  /// Persiste le sous-système + sa langue dérivée. Idempotent : un re-write
  /// avec la même valeur ne change rien.
  Future<void> write(SubSystem subSystem) async {
    await _prefs.setString(_kSubsystemKey, subSystem.id);
    await _prefs.setString(_kLanguageKey, subSystem.languageCode);
  }
}
