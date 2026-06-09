// Story 1.4 — Helper partage entre ProfileRecapPage (Story 1.3) et
// SubjectsOptOutPage (Story 1.4). Extrait depuis profile_recap_page.dart pour
// eviter la duplication du switch icon name -> IconData.
// Story 1.12 — +12 icones nouvelles matieres v2 (Tle franco sub-series +
// O-Level/A-Level GCE + TVEE) coherent avec matrice.json v2.

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Mapping `Subject.icon` (string Lucide) -> `IconData`.
/// Fallback `book-open` si l'icone n'est pas reconnue.
IconData subjectIconFor(String iconName) {
  return switch (iconName) {
    'function-square' => LucideIcons.functionSquare,
    'atom' => LucideIcons.atom,
    'flask-conical' => LucideIcons.flaskConical,
    'dna' => LucideIcons.dna,
    'cog' => LucideIcons.cog,
    'book-open-text' => LucideIcons.bookOpenText,
    'languages' => LucideIcons.languages,
    'globe' => LucideIcons.globe,
    'brain' => LucideIcons.brain,
    'landmark' => LucideIcons.landmark,
    'scale' => LucideIcons.scale,
    'dumbbell' => LucideIcons.dumbbell,
    'wrench' => LucideIcons.wrench,
    'file-text' => LucideIcons.fileText,
    'calculator' => LucideIcons.calculator,
    'shopping-bag' => LucideIcons.shoppingBag,
    'sigma' => LucideIcons.sigma,
    'mountain' => LucideIcons.mountain,
    'trending-up' => LucideIcons.trendingUp,
    'code-2' => LucideIcons.code,
    'book' => LucideIcons.book,
    'book-marked' => LucideIcons.bookMarked,
    // Story 1.12 — nouvelles icones matrice v2
    'palette' => LucideIcons.palette,
    'hammer' => LucideIcons.hammer,
    'scroll-text' => LucideIcons.scrollText,
    'mic' => LucideIcons.mic,
    'film' => LucideIcons.film,
    'leaf' => LucideIcons.leaf,
    'utensils' => LucideIcons.utensils,
    'zap' => LucideIcons.zap,
    'cpu' => LucideIcons.cpu,
    'building' => LucideIcons.building,
    'briefcase' => LucideIcons.briefcase,
    'shirt' => LucideIcons.shirt,
    _ => LucideIcons.bookOpen,
  };
}
