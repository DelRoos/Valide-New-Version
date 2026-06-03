import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valide_school/core/responsive/responsive.dart';

Future<Responsive> _buildResponsive(WidgetTester tester, Size size) async {
  Responsive? captured;
  await tester.binding.setSurfaceSize(size);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            captured = Responsive.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  addTearDown(() => tester.binding.setSurfaceSize(null));
  return captured!;
}

void main() {
  group('Responsive form factor classification', () {
    testWidgets('375 dp → phone', (tester) async {
      final r = await _buildResponsive(tester, const Size(375, 812));
      expect(r.formFactor, equals(FormFactor.phone));
      expect(r.isPhone, isTrue);
    });

    testWidgets('700 dp → phoneLandscape', (tester) async {
      final r = await _buildResponsive(tester, const Size(700, 1024));
      expect(r.formFactor, equals(FormFactor.phoneLandscape));
      expect(r.isPhoneLandscape, isTrue);
    });

    testWidgets('900 dp → tablet', (tester) async {
      final r = await _buildResponsive(tester, const Size(900, 1366));
      expect(r.formFactor, equals(FormFactor.tablet));
      expect(r.isTablet, isTrue);
    });

    testWidgets('breakpoint exact 600 → phoneLandscape', (tester) async {
      final r = await _buildResponsive(tester, const Size(600, 1024));
      expect(r.formFactor, equals(FormFactor.phoneLandscape));
    });

    testWidgets('breakpoint exact 840 → tablet', (tester) async {
      final r = await _buildResponsive(tester, const Size(840, 1024));
      expect(r.formFactor, equals(FormFactor.tablet));
    });
  });

  group('Responsive.select', () {
    testWidgets('retourne la valeur du form factor courant', (tester) async {
      final phone = await _buildResponsive(tester, const Size(375, 812));
      expect(
        phone.select<int>(phone: 1, tablet: 3),
        equals(1),
      );

      final tablet = await _buildResponsive(tester, const Size(900, 1366));
      expect(
        tablet.select<int>(phone: 1, tablet: 3),
        equals(3),
      );
    });

    testWidgets('phoneLandscape fallback sur phone si non fourni',
        (tester) async {
      final landscape = await _buildResponsive(tester, const Size(700, 1024));
      expect(
        landscape.select<int>(phone: 1, tablet: 3),
        equals(1),
      );
    });

    testWidgets('phoneLandscape utilise la valeur dédiée si fournie',
        (tester) async {
      final landscape = await _buildResponsive(tester, const Size(700, 1024));
      expect(
        landscape.select<int>(phone: 1, phoneLandscape: 2, tablet: 3),
        equals(2),
      );
    });
  });
}
