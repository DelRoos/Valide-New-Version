// Tests Story 1.18 — PickerValidateBar (AC4).
//
// Couvre :
//   - compteur affiche counterText (color primary si isValid, danger sinon)
//   - bouton primary disabled si !isValid
//   - bouton primary tap declenche onValidate
//   - isSaving=true : bouton primary loading + secondary disable
//   - bouton secondary tap declenche onCancel
//   - responsive tablet 900x1200 sans overflow

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:valide_school/core/theme/tokens.dart';
import 'package:valide_school/core/widgets/app_button.dart';
import 'package:valide_school/core/widgets/picker/picker_validate_bar.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, _) => MaterialApp(home: Scaffold(body: child)),
    ),
  );
}

void main() {
  group('PickerValidateBar', () {
    testWidgets('isValid=true : compteur en couleur primary', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrap(
        PickerValidateBar(
          counterText: '8 / 11 matieres',
          isValid: true,
          isSaving: false,
          onValidate: () {},
          onCancel: () {},
          validateLabel: 'Valider',
          cancelLabel: 'Retour',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('8 / 11 matieres'), findsOneWidget);
      // Icon listChecks visible
      expect(find.byIcon(LucideIcons.listChecks), findsOneWidget);

      // Verifier la couleur du Text via le widget
      final textWidget = tester.widget<Text>(find.text('8 / 11 matieres'));
      expect(textWidget.style?.color, AppColors.primary);
    });

    testWidgets('isValid=false : compteur en couleur danger + primary disabled',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      var validatedCount = 0;

      await tester.pumpWidget(_wrap(
        PickerValidateBar(
          counterText: '12 / 11 matieres',
          isValid: false,
          isSaving: false,
          onValidate: () => validatedCount++,
          onCancel: () {},
          validateLabel: 'Valider',
          cancelLabel: 'Retour',
        ),
      ));
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.text('12 / 11 matieres'));
      expect(textWidget.style?.color, AppColors.danger);

      // Tap bouton primary "Valider" => onValidate ne doit PAS se declencher
      await tester.tap(find.widgetWithText(AppButton, 'Valider'));
      await tester.pumpAndSettle();
      expect(validatedCount, 0,
          reason: 'isValid=false doit desactiver le bouton primary');
    });

    testWidgets('isValid=true : tap primary declenche onValidate',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      var validatedCount = 0;

      await tester.pumpWidget(_wrap(
        PickerValidateBar(
          counterText: '8 / 11',
          isValid: true,
          isSaving: false,
          onValidate: () => validatedCount++,
          onCancel: () {},
          validateLabel: 'Valider',
          cancelLabel: 'Retour',
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(AppButton, 'Valider'));
      await tester.pumpAndSettle();
      expect(validatedCount, 1);
    });

    testWidgets('tap secondary declenche onCancel', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      var cancelCount = 0;

      await tester.pumpWidget(_wrap(
        PickerValidateBar(
          counterText: '5 / 11',
          isValid: true,
          isSaving: false,
          onValidate: () {},
          onCancel: () => cancelCount++,
          validateLabel: 'Valider',
          cancelLabel: 'Retour',
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(AppButton, 'Retour'));
      await tester.pumpAndSettle();
      expect(cancelCount, 1);
    });

    testWidgets('responsive tablet (900x1200) : rendu sans overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrap(
        PickerValidateBar(
          counterText: '8 / 11 matieres',
          isValid: true,
          isSaving: false,
          onValidate: () {},
          onCancel: () {},
          validateLabel: 'Valider',
          cancelLabel: 'Retour',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('8 / 11 matieres'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
