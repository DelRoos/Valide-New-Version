// Tests Story 1.18 — PickerSectionScaffold (AC1).
//
// Couvre :
//   - rendu titre + sous-titre + child
//   - rendu sans subtitle (null)
//   - responsive phone portrait (375x812) : pas de contrainte 720dp visible
//   - responsive tablet portrait (900x1200) : ConstrainedBox 720dp applique

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:valide_school/core/widgets/picker/picker_section_scaffold.dart';

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (_, _) => MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('PickerSectionScaffold', () {
    testWidgets('rend titre + sous-titre + child sur phone portrait',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrap(
        const PickerSectionScaffold(
          title: 'Choisis tes matieres',
          subtitle: 'Sous-titre indicatif',
          child: Text('Body du picker'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Choisis tes matieres'), findsOneWidget);
      expect(find.text('Sous-titre indicatif'), findsOneWidget);
      expect(find.text('Body du picker'), findsOneWidget);
    });

    testWidgets('omet le sous-titre si subtitle == null', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrap(
        const PickerSectionScaffold(
          title: 'Sans sous-titre',
          child: Text('Body seul'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Sans sous-titre'), findsOneWidget);
      expect(find.text('Body seul'), findsOneWidget);
    });

    testWidgets('responsive tablet (>= 840dp) : ConstrainedBox 720dp applique',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrap(
        const PickerSectionScaffold(
          title: 'Titre tablet',
          subtitle: 'Sous-titre tablet',
          child: SizedBox(
            key: ValueKey('body-key'),
            height: 100,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Le titre est visible
      expect(find.text('Titre tablet'), findsOneWidget);
      // Le child est rendu
      expect(find.byKey(const ValueKey('body-key')), findsOneWidget);
      // Verifier le ConstrainedBox interne avec maxWidth 720
      final constrainedBoxes = tester.widgetList<ConstrainedBox>(
        find.byType(ConstrainedBox),
      );
      final has720maxWidth = constrainedBoxes.any(
        (cb) => cb.constraints.maxWidth == 720,
      );
      expect(has720maxWidth, isTrue,
          reason:
              'En tablet (>=840dp), un ConstrainedBox maxWidth: 720 doit etre present');
    });

    testWidgets('responsive phone (< 840dp) : pas de contrainte 720dp',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrap(
        const PickerSectionScaffold(
          title: 'Titre phone',
          child: SizedBox(height: 100),
        ),
      ));
      await tester.pumpAndSettle();

      // En phone, le ConstrainedBox a maxWidth infinity (pas 720)
      final constrainedBoxes = tester.widgetList<ConstrainedBox>(
        find.byType(ConstrainedBox),
      );
      final has720maxWidth = constrainedBoxes.any(
        (cb) => cb.constraints.maxWidth == 720,
      );
      expect(has720maxWidth, isFalse,
          reason:
              'En phone (<840dp), ConstrainedBox maxWidth ne doit PAS etre 720');
    });
  });
}
