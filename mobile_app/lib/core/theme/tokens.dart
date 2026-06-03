// Design tokens cristallisés depuis DESIGN.md (source canonique).
// Voir project_manage/planning-artifacts/ux-designs/.../DESIGN.md.
// Toute extension passe par mise à jour de DESIGN.md d'abord.

import 'package:flutter/material.dart';

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

  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s10 = 40;
  static const double s12 = 48;
  static const double s16 = 64;
}

class AppRadius {
  AppRadius._();

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
