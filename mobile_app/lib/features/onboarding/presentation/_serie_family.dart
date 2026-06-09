// Story 1.14 — Helper de regroupement visuel des sous-séries Tle francophone
// générale par famille pédagogique (Lettres / Sciences humaines / Sciences /
// Sciences techniques).
//
// Le mapping `serieId → SerieFamily` est **hardcodé Dart** (pas de champ
// Firestore), cohérent avec ADR-016 Décision 1 (sous-séries flat, groupement
// UX-only).
//
// Utilisé par `serie_choice_page.dart` pour le rendu groupé du cas Tle franco
// générale (12 sous-séries A1-A5/ABI/SH/AC/C/D/E/TI). Pour tous les autres
// cas (Upper Sixth anglo, Premiere franco, TVEE), `serieFamilyFor(...)`
// retourne `null` → le widget consommateur tombe sur le layout v1.

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Familles de regroupement visuel pour les sous-séries Tle francophone
/// générale (Story 1.14). Purement UX — pas de donnée métier persistée.
///
/// Icônes Lucide validées par EXPERIENCE.md Flow 1a (Aïssatou Tle A1).
enum SerieFamily {
  lettres,
  sciencesHumaines,
  sciences,
  sciencesTechniques;

  /// Libellé FR pour le header de famille.
  String get labelFr {
    return switch (this) {
      SerieFamily.lettres => 'Lettres',
      SerieFamily.sciencesHumaines => 'Sciences humaines',
      SerieFamily.sciences => 'Sciences',
      SerieFamily.sciencesTechniques => 'Sciences techniques',
    };
  }

  /// Libellé EN pour le header de famille.
  String get labelEn {
    return switch (this) {
      SerieFamily.lettres => 'Letters',
      SerieFamily.sciencesHumaines => 'Humanities',
      SerieFamily.sciences => 'Sciences',
      SerieFamily.sciencesTechniques => 'Technical Sciences',
    };
  }

  /// Icône Lucide pour le header de famille (cf. EXPERIENCE.md Flow 1a).
  IconData get icon {
    return switch (this) {
      SerieFamily.lettres => LucideIcons.bookOpen,
      SerieFamily.sciencesHumaines => LucideIcons.users,
      SerieFamily.sciences => LucideIcons.atom,
      SerieFamily.sciencesTechniques => LucideIcons.wrench,
    };
  }
}

/// Libellé de la famille catch-all `Autres séries` (graceful pour séries
/// hors mapping — ex. `francophone_terminale_a` v1 DEPRECATED si encore
/// `isActive: true`).
const String kSerieFamilyOtherLabelFr = 'Autres séries';
const String kSerieFamilyOtherLabelEn = 'Other series';

/// Retourne la famille d'une série Tle francophone générale par convention
/// d'ID, ou `null` si la série n'est pas Tle franco générale (cas Upper Sixth
/// anglo, Premiere franco, TVEE, etc.).
///
/// Mapping :
/// - `francophone_terminale_a1` à `_a5` → [SerieFamily.lettres]
/// - `francophone_terminale_abi` → [SerieFamily.lettres]
/// - `francophone_terminale_sh` → [SerieFamily.sciencesHumaines]
/// - `francophone_terminale_c`, `_d`, `_e` → [SerieFamily.sciences]
/// - `francophone_terminale_ac`, `_ti` → [SerieFamily.sciencesTechniques]
/// - tout autre serieId (vide, malformé, v1 legacy `_a`, autre niveau /
///   subsystem) → `null`
SerieFamily? serieFamilyFor(String serieId) {
  // Lettres : A1-A5 + ABI
  if (RegExp(r'^francophone_terminale_a[1-5]$').hasMatch(serieId) ||
      serieId == 'francophone_terminale_abi') {
    return SerieFamily.lettres;
  }
  // Sciences humaines : SH
  if (serieId == 'francophone_terminale_sh') {
    return SerieFamily.sciencesHumaines;
  }
  // Sciences : C, D, E
  if (serieId == 'francophone_terminale_c' ||
      serieId == 'francophone_terminale_d' ||
      serieId == 'francophone_terminale_e') {
    return SerieFamily.sciences;
  }
  // Sciences techniques : AC, TI
  if (serieId == 'francophone_terminale_ac' ||
      serieId == 'francophone_terminale_ti') {
    return SerieFamily.sciencesTechniques;
  }
  return null;
}
