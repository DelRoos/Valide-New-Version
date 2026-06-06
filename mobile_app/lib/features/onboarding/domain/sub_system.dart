// Story 1.2 — Domain : enum SubSystem + helpers.
//
// Le sous-système est figé définitivement à l'inscription (ADR-006). Il
// dérive la `Locale` de `MaterialApp` et fixe le curriculum (catalogue
// Firestore filtré côté CatalogueRepository Story 1.1c).
//
// Couche `domain` : aucune dépendance Flutter/Firebase. `Locale` vient de
// `dart:ui` (équivalent stdlib, acceptable).

import 'dart:ui' show Locale;

enum SubSystem {
  francophone,
  anglophone;

  /// Identifiant string utilisé comme clé SharedPreferences et comme champ
  /// `users/{uid}.subSystem` Firestore (Story 1.3+). Aligné sur la convention
  /// `doc/partage/BASE-DE-DONNEES.md` (`"francophone" | "anglophone"`).
  String get id => name;

  /// Langue dérivée du sous-système (ADR-006 § Décision).
  ///   - francophone → fr
  ///   - anglophone  → en
  String get languageCode =>
      this == SubSystem.francophone ? 'fr' : 'en';

  /// Locale Flutter pour `MaterialApp.locale`. Pas de région (cf. Story 1.2
  /// Dev Notes : `Locale('fr')` sans `'FR'` — aligné `AppLocalizations`).
  Locale get locale => Locale(languageCode);

  /// Parse une valeur SharedPreferences. Retourne `null` si absent ou invalide
  /// (kill app premier lancement, ou string corrompue par un downgrade futur).
  static SubSystem? fromString(String? raw) {
    if (raw == 'francophone') return francophone;
    if (raw == 'anglophone') return anglophone;
    return null;
  }
}
