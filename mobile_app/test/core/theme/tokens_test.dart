import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valide_school/core/theme/tokens.dart';

void main() {
  group('AppColors', () {
    test('primary == #2563EB (source DESIGN.md)', () {
      expect(AppColors.primary.toARGB32(), equals(0xFF2563EB));
    });

    test('ink == #0F172A (source DESIGN.md)', () {
      expect(AppColors.ink.toARGB32(), equals(0xFF0F172A));
    });

    test('success, warning, danger sont distincts (anti palette confuse)', () {
      expect(AppColors.success, isNot(equals(AppColors.warning)));
      expect(AppColors.warning, isNot(equals(AppColors.danger)));
    });
  });

  group('AppSpacing (grille 4 px)', () {
    test('échelle 4/8/12/16/20/24/32/40/48/64', () {
      expect(AppSpacing.s1, equals(4));
      expect(AppSpacing.s2, equals(8));
      expect(AppSpacing.s3, equals(12));
      expect(AppSpacing.s4, equals(16));
      expect(AppSpacing.s5, equals(20));
      expect(AppSpacing.s6, equals(24));
      expect(AppSpacing.s8, equals(32));
      expect(AppSpacing.s10, equals(40));
      expect(AppSpacing.s12, equals(48));
      expect(AppSpacing.s16, equals(64));
    });
  });

  group('AppRadius', () {
    test('échelle xs..xl2 + pill', () {
      expect(AppRadius.xs, equals(6));
      expect(AppRadius.sm, equals(9));
      expect(AppRadius.md, equals(11));
      expect(AppRadius.lg, equals(14));
      expect(AppRadius.xl, equals(16));
      expect(AppRadius.xl2, equals(18));
      expect(AppRadius.pill, equals(999));
    });
  });

  group('AppMotion', () {
    test('durations 0/120/200/300/600/50 ms', () {
      expect(AppMotion.instant, equals(Duration.zero));
      expect(AppMotion.fast, equals(const Duration(milliseconds: 120)));
      expect(AppMotion.standard, equals(const Duration(milliseconds: 200)));
      expect(AppMotion.emphasis, equals(const Duration(milliseconds: 300)));
      expect(AppMotion.celebration, equals(const Duration(milliseconds: 600)));
      expect(AppMotion.stagger, equals(const Duration(milliseconds: 50)));
    });

    test('easings standardOut / standardIn / emphasized', () {
      expect(AppMotion.standardOut, equals(Curves.easeOut));
      expect(AppMotion.standardIn, equals(Curves.easeIn));
      expect(AppMotion.emphasized, equals(Curves.easeOutCubic));
    });
  });

  group('AppElevation', () {
    test('soft / mid / brand non vides et offsets cohérents', () {
      expect(AppElevation.soft, isNotEmpty);
      expect(AppElevation.soft.first.offset, equals(const Offset(0, 4)));
      expect(AppElevation.mid.first.offset, equals(const Offset(0, 8)));
      expect(AppElevation.brand.first.offset, equals(const Offset(0, 6)));
    });
  });

  group('AppTypography', () {
    test('display=46/900, h1=30/900, body=16/500, eyebrow=11/800', () {
      expect(AppTypography.display.fontSize, equals(46));
      expect(AppTypography.display.fontWeight, equals(FontWeight.w900));
      expect(AppTypography.h1.fontSize, equals(30));
      expect(AppTypography.h1.fontWeight, equals(FontWeight.w900));
      expect(AppTypography.body.fontSize, equals(16));
      expect(AppTypography.body.fontWeight, equals(FontWeight.w500));
      expect(AppTypography.eyebrow.fontSize, equals(11));
      expect(AppTypography.eyebrow.fontWeight, equals(FontWeight.w800));
    });

    test('tous les styles utilisent fontFamily Nunito Sans', () {
      final styles = [
        AppTypography.display,
        AppTypography.h1,
        AppTypography.h2,
        AppTypography.h3,
        AppTypography.body,
        AppTypography.bodyStrong,
        AppTypography.meta,
        AppTypography.caption,
        AppTypography.eyebrow,
      ];
      for (final style in styles) {
        expect(style.fontFamily, equals('Nunito Sans'));
      }
    });
  });
}
