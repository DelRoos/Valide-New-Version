// Story 1.4 — Helper partage entre ProfileRecapPage (Story 1.3) et
// SubjectsOptOutPage (Story 1.4). Extrait depuis profile_recap_page.dart pour
// eviter la duplication du switch icon name -> IconData.

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
    _ => LucideIcons.bookOpen,
  };
}
