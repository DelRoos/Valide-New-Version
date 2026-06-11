// Tests Story E1bis-0 AC3 + AC9 — PhoneInputWithCountryFlag.
//
// Couvre :
//   - Saisie "671234567" -> onChanged emet "+237671234567"
//   - Saisie vide -> onChanged emet ''
//   - Saisie filtre lettres -> garde uniquement les digits
//   - errorText affiche sous le champ + bordure danger
//   - maskedForLogs delegue a maskPhone (3 cas representatifs)
//   - 6 goldens phone+tablet x 3 etats (vide / rempli / erreur)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:valide_school/core/theme/tokens.dart';
import 'package:valide_school/core/widgets/forms/phone_input_with_country_flag.dart';

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
  group('PhoneInputWithCountryFlag - interactions', () {
    testWidgets('saisie "671234567" -> onChanged emet "+237671234567"',
        (tester) async {
      String? captured;
      await _pump(
        tester,
        PhoneInputWithCountryFlag(
          value: '',
          onChanged: (v) => captured = v,
        ),
        viewportSize: _phoneSize,
      );

      await tester.enterText(find.byType(TextField), '671234567');
      await tester.pumpAndSettle();

      expect(captured, '+237671234567');
    });

    testWidgets('saisie vide -> onChanged emet ""', (tester) async {
      String? captured;
      await _pump(
        tester,
        PhoneInputWithCountryFlag(
          value: '+237671234567',
          onChanged: (v) => captured = v,
        ),
        viewportSize: _phoneSize,
      );

      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      expect(captured, '');
    });

    testWidgets('saisie avec lettres -> garde uniquement digits',
        (tester) async {
      String? captured;
      await _pump(
        tester,
        PhoneInputWithCountryFlag(
          value: '',
          onChanged: (v) => captured = v,
        ),
        viewportSize: _phoneSize,
      );

      // Avec FilteringTextInputFormatter.digitsOnly, les lettres sont
      // supprimees AVANT meme d'atteindre onChanged.
      await tester.enterText(find.byType(TextField), 'abc6712def34567ghi');
      await tester.pumpAndSettle();

      expect(captured, '+237671234567');
    });

    testWidgets('errorText affiche + bordure danger', (tester) async {
      await _pump(
        tester,
        PhoneInputWithCountryFlag(
          value: '+2376',
          onChanged: (_) {},
          errorText: 'Numero trop court',
        ),
        viewportSize: _phoneSize,
      );

      expect(find.text('Numero trop court'), findsOneWidget);

      // Le Container racine du champ doit avoir une bordure danger.
      final container = tester
          .widgetList<Container>(find.byType(Container))
          .firstWhere((c) {
        final d = c.decoration;
        return d is BoxDecoration && d.border != null;
      });
      final border = (container.decoration! as BoxDecoration).border! as Border;
      expect(border.top.color, AppColors.danger);
    });

    testWidgets('+237 prefix figure affiche', (tester) async {
      await _pump(
        tester,
        PhoneInputWithCountryFlag(
          value: '',
          onChanged: (_) {},
        ),
        viewportSize: _phoneSize,
      );
      expect(find.text('+237'), findsOneWidget);
    });

    test('maskedForLogs delegue a maskPhone (3 cas)', () {
      // Cas valide
      expect(
        PhoneInputWithCountryFlag.maskedForLogs('+237671234567'),
        '+237 X XX XX 45 67',
      );
      // null -> sentinelle
      expect(
        PhoneInputWithCountryFlag.maskedForLogs(null),
        '<no-phone>',
      );
      // Invalide -> sentinelle
      expect(
        PhoneInputWithCountryFlag.maskedForLogs('+33612345678'),
        '<invalid-phone>',
      );
    });
  });

  group('PhoneInputWithCountryFlag - goldens', () {
    for (final form in const [
      (label: 'phone', size: _phoneSize),
      (label: 'tablet', size: _tabletSize),
    ]) {
      testWidgets('golden ${form.label} empty', (tester) async {
        await _pump(
          tester,
          PhoneInputWithCountryFlag(
            value: '',
            onChanged: (_) {},
          ),
          viewportSize: form.size,
        );
        await expectLater(
          find.byType(PhoneInputWithCountryFlag),
          matchesGoldenFile(
            '__goldens__/phone_input_${form.label}_empty.png',
          ),
        );
      });

      testWidgets('golden ${form.label} filled', (tester) async {
        await _pump(
          tester,
          PhoneInputWithCountryFlag(
            value: '+237671234567',
            onChanged: (_) {},
          ),
          viewportSize: form.size,
        );
        await expectLater(
          find.byType(PhoneInputWithCountryFlag),
          matchesGoldenFile(
            '__goldens__/phone_input_${form.label}_filled.png',
          ),
        );
      });

      testWidgets('golden ${form.label} error', (tester) async {
        await _pump(
          tester,
          PhoneInputWithCountryFlag(
            value: '+2376',
            onChanged: (_) {},
            errorText: 'Le numero doit comporter 9 chiffres',
          ),
          viewportSize: form.size,
        );
        await expectLater(
          find.byType(PhoneInputWithCountryFlag),
          matchesGoldenFile(
            '__goldens__/phone_input_${form.label}_error.png',
          ),
        );
      });
    }
  });
}
