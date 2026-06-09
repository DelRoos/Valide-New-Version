// Tests helper _serie_family.dart — Story 1.14.
//
// Vérifient le mapping serieId → SerieFamily :
//  1. 6 séries Lettres : a1-a5 + abi
//  2. 1 série Sciences humaines : sh
//  3. 3 séries Sciences : c, d, e
//  4. 2 séries Sciences techniques : ac, ti
//  5. Cas hors Tle franco générale (v1 legacy `_a`, autre niveau / subsystem,
//     vide, malformé) → null
//
// + smoke labels FR/EN + icônes Lucide.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:valide_school/features/onboarding/presentation/_serie_family.dart';

void main() {
  group('serieFamilyFor — Story 1.14', () {
    test('Lettres : A1-A5', () {
      expect(serieFamilyFor('francophone_terminale_a1'), SerieFamily.lettres);
      expect(serieFamilyFor('francophone_terminale_a2'), SerieFamily.lettres);
      expect(serieFamilyFor('francophone_terminale_a3'), SerieFamily.lettres);
      expect(serieFamilyFor('francophone_terminale_a4'), SerieFamily.lettres);
      expect(serieFamilyFor('francophone_terminale_a5'), SerieFamily.lettres);
    });

    test('Lettres : ABI', () {
      expect(serieFamilyFor('francophone_terminale_abi'), SerieFamily.lettres);
    });

    test('Sciences humaines : SH', () {
      expect(
        serieFamilyFor('francophone_terminale_sh'),
        SerieFamily.sciencesHumaines,
      );
    });

    test('Sciences : C, D, E', () {
      expect(serieFamilyFor('francophone_terminale_c'), SerieFamily.sciences);
      expect(serieFamilyFor('francophone_terminale_d'), SerieFamily.sciences);
      expect(serieFamilyFor('francophone_terminale_e'), SerieFamily.sciences);
    });

    test('Sciences techniques : AC, TI', () {
      expect(
        serieFamilyFor('francophone_terminale_ac'),
        SerieFamily.sciencesTechniques,
      );
      expect(
        serieFamilyFor('francophone_terminale_ti'),
        SerieFamily.sciencesTechniques,
      );
    });

    test('v1 legacy `francophone_terminale_a` (DEPRECATED) → null (catch-all)',
        () {
      // La série A v1 ne matche pas le regex `a[1-5]` strict — graceful.
      expect(serieFamilyFor('francophone_terminale_a'), isNull);
    });

    test('Autre niveau francophone (Premiere) → null', () {
      expect(serieFamilyFor('francophone_premiere_a1'), isNull);
      expect(serieFamilyFor('francophone_premiere_d'), isNull);
    });

    test('Autre subsystem (anglophone) → null', () {
      expect(serieFamilyFor('anglophone_upper_sixth_s2'), isNull);
      expect(serieFamilyFor('anglophone_tve_al_elet'), isNull);
    });

    test('Cas vide / malformé → null (defensive)', () {
      expect(serieFamilyFor(''), isNull);
      expect(serieFamilyFor('not_a_serie'), isNull);
      expect(serieFamilyFor('francophone_terminale_zz'), isNull);
      // a6, a0 hors regex strict 1-5
      expect(serieFamilyFor('francophone_terminale_a6'), isNull);
      expect(serieFamilyFor('francophone_terminale_a0'), isNull);
    });
  });

  group('SerieFamily — labels FR/EN + icônes', () {
    test('labelFr couvre 4 familles', () {
      expect(SerieFamily.lettres.labelFr, 'Lettres');
      expect(SerieFamily.sciencesHumaines.labelFr, 'Sciences humaines');
      expect(SerieFamily.sciences.labelFr, 'Sciences');
      expect(SerieFamily.sciencesTechniques.labelFr, 'Sciences techniques');
    });

    test('labelEn couvre 4 familles', () {
      expect(SerieFamily.lettres.labelEn, 'Letters');
      expect(SerieFamily.sciencesHumaines.labelEn, 'Humanities');
      expect(SerieFamily.sciences.labelEn, 'Sciences');
      expect(SerieFamily.sciencesTechniques.labelEn, 'Technical Sciences');
    });

    test('Icônes Lucide alignées EXPERIENCE.md Flow 1a Aïssatou', () {
      expect(SerieFamily.lettres.icon, isA<IconData>());
      expect(SerieFamily.lettres.icon, LucideIcons.bookOpen);
      expect(SerieFamily.sciencesHumaines.icon, LucideIcons.users);
      expect(SerieFamily.sciences.icon, LucideIcons.atom);
      expect(SerieFamily.sciencesTechniques.icon, LucideIcons.wrench);
    });
  });
}
