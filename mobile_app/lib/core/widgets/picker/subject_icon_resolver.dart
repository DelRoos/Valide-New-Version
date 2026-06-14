// Audit 2026-06-13 — Resolveur d'icone Lucide par nom de matiere Firestore.
//
// Le champ `Subject.icon` (couche domain) stocke un nom kebab-case publie par
// la matrice de seed (`scripts/firebase_seed/data/matrice.json`). Cote UI on a
// besoin d'un `IconData` (paquet `lucide_icons_flutter`). Cette table fait
// la jonction. Default = `LucideIcons.bookOpen` si nom inconnu (defense en
// profondeur : un futur seed pourrait introduire une icone non mappee).
//
// Pourquoi ici ? Le pattern `iconResolver` est deja en place dans
// `OptionalSubjectCheckboxList` (cf. fichier voisin) pour eviter une
// dependance `core/widgets` -> `features/onboarding`. On garde la fonction
// pure et reutilisable dans `core/widgets/picker/`.

import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Resolveur : nom Firestore kebab-case -> `IconData` Lucide. Couvre tous
/// les noms presents dans `scripts/firebase_seed/data/matrice.json` au
/// 2026-06-13. Si un nouveau nom apparait cote seed, ajouter une entree ici.
IconData subjectIconFor(String iconName) {
  return switch (iconName) {
    'function-square' => LucideIcons.functionSquare,
    'sigma' => LucideIcons.sigma,
    'calculator' => LucideIcons.calculator,
    'atom' => LucideIcons.atom,
    'flask-conical' => LucideIcons.flaskConical,
    'dna' => LucideIcons.dna,
    'leaf' => LucideIcons.leaf,
    'microscope' => LucideIcons.microscope,
    'heart-pulse' => LucideIcons.heartPulse,
    'brain' => LucideIcons.brain,
    'languages' => LucideIcons.languages,
    'book' => LucideIcons.book,
    'book-open' => LucideIcons.bookOpen,
    'book-open-text' => LucideIcons.bookOpenText,
    'book-marked' => LucideIcons.bookMarked,
    'scroll-text' => LucideIcons.scrollText,
    'file-text' => LucideIcons.fileText,
    'globe' => LucideIcons.globe,
    'map' => LucideIcons.map,
    'landmark' => LucideIcons.landmark,
    'scale' => LucideIcons.scale,
    'mountain' => LucideIcons.mountain,
    'plane' => LucideIcons.plane,
    'code-2' => LucideIcons.code2,
    'cpu' => LucideIcons.cpu,
    'zap' => LucideIcons.zap,
    'cog' => LucideIcons.cog,
    'wrench' => LucideIcons.wrench,
    'hammer' => LucideIcons.hammer,
    'ruler' => LucideIcons.ruler,
    'building' => LucideIcons.building,
    'briefcase' => LucideIcons.briefcase,
    'palette' => LucideIcons.palette,
    'brush' => LucideIcons.brush,
    'film' => LucideIcons.film,
    'disc' => LucideIcons.disc,
    'mic' => LucideIcons.mic,
    'shirt' => LucideIcons.shirt,
    'shopping-bag' => LucideIcons.shoppingBag,
    'boxes' => LucideIcons.boxes,
    'bed' => LucideIcons.bed,
    'utensils' => LucideIcons.utensils,
    'chef-hat' => LucideIcons.chefHat,
    'dumbbell' => LucideIcons.dumbbell,
    'trending-up' => LucideIcons.trendingUp,
    _ => LucideIcons.bookOpen,
  };
}
