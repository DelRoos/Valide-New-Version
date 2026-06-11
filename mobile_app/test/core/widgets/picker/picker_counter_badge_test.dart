// Tests Story E1bis-0 AC6 + AC9 + AC10 — PickerCounterBadge.
//
// Couvre :
//   - isValid=true -> bg successSoft + ink successInk + icone Check visible
//   - isValid=false -> bg warningSoft + ink warningInk + pas d icone Check
//   - labelText interpolation respectee (passthrough)
//   - 4 goldens phone 360x780 + tablet 900x1200 x 2 etats

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:valide_school/core/theme/tokens.dart';
import 'package:valide_school/core/widgets/picker/picker_counter_badge.dart';

const Size _phoneSize = Size(360, 780);
const Size _tabletSize = Size(900, 1200);

Widget _wrap(Widget child, {required Size viewportSize}) {
  return ProviderScope(
    child: MediaQuery(
      data: MediaQueryData(size: viewportSize),
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: viewportSize),
          child: Builder(
            builder: (context) {
              ScreenUtil.init(context, designSize: viewportSize);
              return Scaffold(
                backgroundColor: AppColors.bg,
                body: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [child],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required Size viewportSize,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = viewportSize;
  await tester.binding.setSurfaceSize(viewportSize);
  addTearDown(() {
    tester.binding.setSurfaceSize(null);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(_wrap(child, viewportSize: viewportSize));
  await tester.pumpAndSettle();
}

void main() {
  group('PickerCounterBadge - interactions', () {
    testWidgets('isValid=true -> bg successSoft + icone Check visible',
        (tester) async {
      await _pump(
        tester,
        const PickerCounterBadge(
          currentCount: 4,
          min: 3,
          max: 6,
          labelText: 'Tu as choisi 4 matieres',
          isValid: true,
        ),
        viewportSize: _phoneSize,
      );

      // Premier AnimatedContainer = pastille externe.
      final outer = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .first;
      final decoration = outer.decoration! as BoxDecoration;
      expect(decoration.color, AppColors.successSoft);

      // Icone Check visible quand isValid.
      expect(find.byIcon(LucideIcons.check), findsOneWidget);
    });

    testWidgets('isValid=false -> bg warningSoft + pas d icone Check',
        (tester) async {
      await _pump(
        tester,
        const PickerCounterBadge(
          currentCount: 1,
          min: 3,
          max: 6,
          labelText: 'Encore 2 matieres minimum',
          isValid: false,
        ),
        viewportSize: _phoneSize,
      );

      final outer = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .first;
      final decoration = outer.decoration! as BoxDecoration;
      expect(decoration.color, AppColors.warningSoft);

      expect(find.byIcon(LucideIcons.check), findsNothing);
    });

    testWidgets('labelText affiche tel quel (passthrough i18n caller)',
        (tester) async {
      await _pump(
        tester,
        const PickerCounterBadge(
          currentCount: 8,
          min: 6,
          max: 11,
          labelText: 'You picked 8 / 11 subjects',
          isValid: true,
        ),
        viewportSize: _phoneSize,
      );

      expect(find.text('You picked 8 / 11 subjects'), findsOneWidget);
      expect(find.text('8 / 11'), findsOneWidget);
    });
  });

  group('PickerCounterBadge - goldens', () {
    Future<void> pumpFixture(
      WidgetTester tester, {
      required bool isValid,
      required Size size,
    }) async {
      await _pump(
        tester,
        PickerCounterBadge(
          currentCount: isValid ? 5 : 1,
          min: 3,
          max: 6,
          labelText: isValid
              ? 'Tu as choisi 5 matieres'
              : 'Encore 2 matieres minimum',
          isValid: isValid,
        ),
        viewportSize: size,
      );
    }

    for (final isValid in const [false, true]) {
      for (final form in const [
        (label: 'phone', size: _phoneSize),
        (label: 'tablet', size: _tabletSize),
      ]) {
        testWidgets(
          'golden ${form.label} ${isValid ? "valid" : "invalid"}',
          (tester) async {
            await pumpFixture(tester, isValid: isValid, size: form.size);
            await expectLater(
              find.byType(PickerCounterBadge),
              matchesGoldenFile(
                '__goldens__/picker_counter_badge_'
                '${form.label}_'
                '${isValid ? "valid" : "invalid"}.png',
              ),
            );
          },
        );
      }
    }
  });
}
