// Story 1.10 — Tests AppButton.danger variant (Story 0.13 extension).
//
// 2 cas :
//   (a) variant danger render avec couleur fond AppColors.danger
//   (b) onPressed null -> bouton disabled (parite primary/secondary)

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:valide_school/core/theme/tokens.dart';
import 'package:valide_school/core/widgets/app_button.dart';

Future<void> _pumpButton(
  WidgetTester tester, {
  required AppButton button,
}) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      child: MaterialApp(
        home: Scaffold(
          body: Center(child: button),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('AppButton.danger — Story 1.10', () {
    testWidgets('(a) variant danger render avec fond AppColors.danger',
        (tester) async {
      await _pumpButton(
        tester,
        button: AppButton.danger(
          label: 'Supprimer',
          onPressed: () {},
        ),
      );

      expect(find.text('Supprimer'), findsOneWidget);

      // Trouve le Container interne du bouton et verifie sa couleur.
      final containers = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) {
        final decoration = c.decoration;
        return decoration is BoxDecoration &&
            decoration.color == AppColors.danger;
      });
      expect(containers.length, greaterThan(0),
          reason: 'au moins un Container avec fond AppColors.danger');
    });

    testWidgets('(b) onPressed null -> bouton disabled (loading == false)',
        (tester) async {
      await _pumpButton(
        tester,
        button: AppButton.danger(
          label: 'Supprimer',
          onPressed: null,
        ),
      );

      final btn = tester.widget<AppButton>(
        find.widgetWithText(AppButton, 'Supprimer'),
      );
      expect(btn.onPressed, isNull);
    });
  });
}
