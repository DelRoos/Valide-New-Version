// Story 1.8 — Data : wrapper SharedPreferences pour le flow profil scolaire.
//
// Persiste les 3 champs de `OnboardingFlowState` (filiereId/niveauId/serieId)
// localement pour permettre la reprise au boot apres kill app (FR-8).
//
// Choix : SharedPreferences uniquement (PAS Firestore onboardingStep). Cf.
// Decision technique dans la story 1.8 :
//   1. Anonymous Auth est mono-device par definition (avant Story 1.6 compte
//      permanent) -> pas besoin de cross-device.
//   2. users/{uid} n'existe pas encore pendant les 3 etapes profile (cree
//      par createProfile Story 1.3 a l'etape recap) -> persister un champ
//      partiel la-bas complique les regles Firestore immuabilite Story 1.3.
//   3. SharedPreferences est synchrone + offline-safe. Pattern deja en place
//      pour subSystem (Story 1.2). On etend.
//   4. Apres createProfile, profileCompletionProvider Story 1.5 + /dashboard
//      Story 1.9 prennent le relais via Firestore -> les prefs deviennent
//      inertes mais inoffensives.

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/onboarding_flow_state.dart';

class OnboardingFlowPrefs {
  OnboardingFlowPrefs(this._prefs);

  final SharedPreferences _prefs;

  // Cles SharedPreferences. Prefixees `onboarding.flow.*` pour cohabiter sans
  // collision avec les cles `onboarding.subsystem` + `onboarding.language` de
  // SubsystemPrefs Story 1.2.
  static const String _kFiliereKey = 'onboarding.flow.filiere_id';
  static const String _kNiveauKey = 'onboarding.flow.niveau_id';
  static const String _kSerieKey = 'onboarding.flow.serie_id';

  /// Lit l'etat persiste. Champs absents (1er lancement ou backTo qui a
  /// efface) -> `null` dans l'etat retourne. Coherent avec
  /// `OnboardingFlowState()` par defaut.
  OnboardingFlowState read() {
    return OnboardingFlowState(
      filiereId: _prefs.getString(_kFiliereKey),
      niveauId: _prefs.getString(_kNiveauKey),
      serieId: _prefs.getString(_kSerieKey),
    );
  }

  /// Persiste l'etat. Les champs `null` sont retires des prefs (pas ecrits
  /// avec une valeur sentinelle) — coherent avec la semantique "absent ==
  /// non choisi" du domain Story 1.3.
  Future<void> write(OnboardingFlowState state) async {
    await _writeOrRemove(_kFiliereKey, state.filiereId);
    await _writeOrRemove(_kNiveauKey, state.niveauId);
    await _writeOrRemove(_kSerieKey, state.serieId);
  }

  /// Reset complet (3 cles supprimees). Utilise par `Notifier.reset()` et au
  /// premier choix de filiere (qui doit repartir d'une feuille propre).
  Future<void> clear() async {
    await _prefs.remove(_kFiliereKey);
    await _prefs.remove(_kNiveauKey);
    await _prefs.remove(_kSerieKey);
  }

  Future<void> _writeOrRemove(String key, String? value) async {
    if (value == null) {
      await _prefs.remove(key);
    } else {
      await _prefs.setString(key, value);
    }
  }
}
