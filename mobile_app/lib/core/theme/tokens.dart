// Design tokens cristallisés depuis DESIGN.md (source canonique).
// Voir project_manage/planning-artifacts/ux-designs/.../DESIGN.md.
// Toute extension passe par mise à jour de DESIGN.md d'abord.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppColors {
  AppColors._();

  // Palette marque
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1E3A8A);
  static const Color primaryLight = Color(0xFFDBEAFE);
  static const Color primarySoft = Color(0xFFEFF6FF);
  static const Color primarySoftBorder = Color(0xFFBFDBFE);

  // Neutres
  static const Color ink = Color(0xFF0F172A);
  static const Color inkSoft = Color(0xFF334155);
  static const Color muted = Color(0xFF64748B);
  static const Color mute2 = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color bg = Color(0xFFF8FAFC);
  static const Color card = Color(0xFFFFFFFF);

  // États — Succès (vert)
  static const Color success = Color(0xFF16A34A);
  static const Color successSoft = Color(0xFFDCFCE7);
  static const Color successInk = Color(0xFF166534);

  // États — Attention (ambre)
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFEF3C7);
  static const Color warningInk = Color(0xFF92400E);

  // États — Erreur (rouge)
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFEE2E2);
  static const Color dangerInk = Color(0xFF991B1B);

  // États — Information (ciel)
  static const Color sky = Color(0xFF0284C7);
  static const Color skySoft = Color(0xFFE0F2FE);
  static const Color skyInk = Color(0xFF075985);
}

class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Nunito Sans';
  static const String monoFontFamily = 'JetBrains Mono';

  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 46,
    fontWeight: FontWeight.w900,
    height: 1.05,
    letterSpacing: -1.84, // -0.04em sur 46px
    color: AppColors.ink,
  );

  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 30,
    fontWeight: FontWeight.w900,
    height: 1.15,
    letterSpacing: -0.9, // -0.03em sur 30px
    color: AppColors.ink,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 1.25,
    letterSpacing: -0.44, // -0.02em sur 22px
    color: AppColors.ink,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w800,
    height: 1.3,
    color: AppColors.ink,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.ink,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.5,
    color: AppColors.ink,
  );

  static const TextStyle meta = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.inkSoft,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.ink,
  );

  static const TextStyle eyebrow = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w800,
    height: 1.3,
    letterSpacing: 0.66, // 0.06em sur 11px
    color: AppColors.muted,
  );
}

class AppSpacing {
  AppSpacing._();

  static const double s075 = 3; // 3 dp — micro-padding (badge interne)
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s9 = 36;
  static const double s10 = 40;
  static const double s12 = 48;
  static const double s16 = 64;
}

class AppRadius {
  AppRadius._();

  static const double hairline = 2;
  static const double xs = 6;
  static const double sm = 9;
  static const double md = 11;
  static const double lg = 14;
  static const double xl = 16;
  static const double xl2 = 18;
  static const double pill = 999;
}

class AppElevation {
  AppElevation._();

  /// shadow-soft : `0 4px 12px rgba(15,23,42,0.06)`
  /// Cartes standard sur fond bg.
  static const List<BoxShadow> soft = [
    BoxShadow(
      offset: Offset(0, 4),
      blurRadius: 12,
      color: Color(0x0F0F172A), // rgba(15,23,42,0.06) ≈ 0x0F
    ),
  ];

  /// shadow-mid : `0 8px 24px rgba(15,23,42,0.08)`
  /// Modales, sheets remontées, cards de paywall.
  static const List<BoxShadow> mid = [
    BoxShadow(
      offset: Offset(0, 8),
      blurRadius: 24,
      color: Color(0x140F172A), // rgba(15,23,42,0.08) ≈ 0x14
    ),
  ];

  /// shadow-brand : `0 6px 18px rgba(37,99,235,0.35)`
  /// Logo + éléments de célébration (mention obtenue, montée de niveau).
  static const List<BoxShadow> brand = [
    BoxShadow(
      offset: Offset(0, 6),
      blurRadius: 18,
      color: Color(0x592563EB), // rgba(37,99,235,0.35) ≈ 0x59
    ),
  ];
}

class AppMotion {
  AppMotion._();

  // Durations
  static const Duration instant = Duration.zero;
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration standard = Duration(milliseconds: 200);
  static const Duration emphasis = Duration(milliseconds: 300);
  static const Duration celebration = Duration(milliseconds: 600);
  static const Duration stagger = Duration(milliseconds: 50);

  // Easings
  static const Curve standardOut = Curves.easeOut;
  static const Curve standardIn = Curves.easeIn;
  static const Curve emphasized = Curves.easeOutCubic;
}

/// Tailles de police responsives (en `.sp` via flutter_screenutil).
/// À utiliser dans `copyWith(fontSize: AppFontSize.xxx)` à la place de valeurs
/// numériques directes. Garantit un seul endroit de modification si la
/// typographie évolue.
class AppFontSize {
  AppFontSize._();

  static double get display    => 46.sp;
  static double get h1        => 30.sp;
  static double get h1Compact => 24.sp; // override h1 pour écrans compacts
  static double get h2        => 22.sp;
  static double get h2Compact => 20.sp; // override h2 pour sheets / modales
  static double get h3        => 18.sp;
  static double get h3Compact => 17.sp;
  static double get body      => 16.sp;
  static double get bodySmall => 14.sp; // sous-titres, corps secondaire
  static double get meta      => 13.sp; // métadonnées, labels compacts
  static double get caption   => 12.sp;
  static double get eyebrow   => 11.sp;
  static double get tiny      => 10.sp;
}

/// Tailles d'icônes responsives (en `.sp` via flutter_screenutil).
/// À utiliser dans `Icon(icon, size: AppIconSize.xxx)` à la place de valeurs
/// numériques directes.
class AppIconSize {
  AppIconSize._();

  static double get xs   => 11.sp; // recap / badge mini
  static double get sm   => 12.sp; // badge icons
  static double get md   => 14.sp; // icons inline dans du texte
  static double get lg   => 18.sp; // compact nav, icon buttons
  static double get xl   => 20.sp; // bouton / formulaire
  static double get xl2  => 22.sp; // déco icons, nav bar (responsive)
  static double get xl3  => 28.sp; // navigation large
  static double get xl4  => 32.sp; // loader / dashboard
  static double get xl5  => 36.sp; // large decoratif
  static double get xl6  => 40.sp; // account icons
  static double get xl7  => 44.sp; // error retry
  static double get xl8  => 48.sp; // heading icons
  static double get xl9  => 56.sp; // hero icons principaux
  static double get xl10 => 64.sp; // success overlay
  static double get xl11 => 72.sp; // level-up celebration
}

/// Constantes de la barre de navigation principale.
/// Intentionnellement en dp fixes (pas de ScreenUtil) : la nav bar est une
/// zone de touch à hauteur physique stable, indépendante de la densité texte.
class AppNavBar {
  AppNavBar._();

  static const double height       = 64;
  static const double iconSize     = 22;
  static const double labelSize    = 11;
  static const double iconLabelGap = 2;
}

/// Épaisseurs de bordure standardisées.
class AppBorderWidth {
  AppBorderWidth._();

  static const double hairline = 1;   // séparateur léger, input au repos
  static const double normal   = 1.5; // toast, cards légères
  static const double bold     = 2;   // input focus, sélection active
  static const double accent   = 4;   // left accent (inline alert)
}

/// Tailles d'avatar (photos de profil) en dp responsive via ScreenUtil.
class AppAvatarSize {
  AppAvatarSize._();

  /// Avatar profil standard (header dashboard).
  static double get profileMd => 72.0.w;

  /// Avatar profil large (profil public, sheet d'édition).
  static double get profileLg => 80.0.w;
}

/// Espacement lettre standardisés (en points, pas responsive).
class AppLetterSpacing {
  AppLetterSpacing._();

  /// Sections eyebrow ALL-CAPS avec tracking ouvert (0.8 pt).
  static const double wide = 0.8;
}

/// Dimensions UI spécifiques non couvertes par AppSpacing / AppIconSize.
class AppDimension {
  AppDimension._();

  // Barres de progression
  static const double progressBarThin = 3;  // barre lecture leçon
  static const double progressBarMed  = 5;  // barre progression chapitre

  // Layouts
  static const double lessonToolbarHeight = 68; // AppBar leçon avec breadcrumb
  static const double dialogMaxWidth      = 420; // largeur max modale

  // Champ de saisie
  static const double inputFieldHeight = 52; // height standard AppInput
}
