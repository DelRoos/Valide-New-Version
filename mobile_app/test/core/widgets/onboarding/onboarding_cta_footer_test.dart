// Tests Story E1bis-2 AC5 + AC11 + AC12 — OnboardingCtaFooter.
//
// Couvre :
//   - onPressed: null -> bouton AppButton.primary disabled (visuel + non-tap)
//   - tap -> callback appele
//   - secondaryAction passe -> rendu AU-DESSUS du CTA primaire
//   - 3 goldens phone : enabled / disabled / avec secondaryAction

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:valide_school/core/theme/tokens.dart';
import 'package:valide_school/core/widgets/app_button.dart';
import 'package:valide_school/core/widgets/onboarding/onboarding_cta_footer.dart';

const Size _phoneSize = Size(360, 200);

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
                bottomNavigationBar: child,
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
  group('OnboardingCtaFooter - interactions', () {
    testWidgets('onPressed != null -> tap propage au callback', (tester) async {
      var tapped = 0;
      await _pump(
        tester,
        OnboardingCtaFooter(
          label: 'Continuer',
          onPressed: () => tapped++,
        ),
        viewportSize: _phoneSize,
      );

      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      expect(tapped, 1);
    });

    testWidgets('onPressed: null -> AppButton.primary recoit onPressed null',
        (tester) async {
      await _pump(
        tester,
        const OnboardingCtaFooter(label: 'Continuer', onPressed: null),
        viewportSize: _phoneSize,
      );

      final button = tester.widget<AppButton>(find.byType(AppButton));
      expect(button.onPressed, isNull);
    });

    testWidgets(
        'secondaryAction passe -> widget rendu au-dessus du CTA primaire',
        (tester) async {
      await _pump(
        tester,
        OnboardingCtaFooter(
          label: 'Continuer',
          onPressed: () {},
          secondaryAction: const Text(
            'Passer pour l instant',
            key: Key('secondary-link'),
          ),
        ),
        viewportSize: _phoneSize,
      );

      final secondaryFinder = find.byKey(const Key('secondary-link'));
      final ctaFinder = find.byType(AppButton);

      expect(secondaryFinder, findsOneWidget);
      expect(ctaFinder, findsOneWidget);

      final secondaryY = tester.getCenter(secondaryFinder).dy;
      final ctaY = tester.getCenter(ctaFinder).dy;
      expect(secondaryY, lessThan(ctaY),
          reason: 'secondaryAction doit etre AU-DESSUS du CTA');
    });
  });

  group('OnboardingCtaFooter - goldens phone', () {
    testWidgets('golden phone enabled', (tester) async {
      await _pump(
        tester,
        OnboardingCtaFooter(
          label: 'Continuer',
          onPressed: () {},
        ),
        viewportSize: _phoneSize,
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('__goldens__/onboarding_cta_footer_phone_enabled.png'),
      );
    });

    testWidgets('golden phone disabled', (tester) async {
      await _pump(
        tester,
        const OnboardingCtaFooter(label: 'Continuer', onPressed: null),
        viewportSize: _phoneSize,
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
            '__goldens__/onboarding_cta_footer_phone_disabled.png'),
      );
    });

    testWidgets('golden phone avec secondaryAction', (tester) async {
      await _pump(
        tester,
        OnboardingCtaFooter(
          label: 'C\'est parti',
          onPressed: () {},
          secondaryAction: TextButton(
            onPressed: () {},
            child: const Text('Passer pour l\'instant'),
          ),
        ),
        viewportSize: _phoneSize,
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
            '__goldens__/onboarding_cta_footer_phone_with_secondary.png'),
      );
    });
  });
}
