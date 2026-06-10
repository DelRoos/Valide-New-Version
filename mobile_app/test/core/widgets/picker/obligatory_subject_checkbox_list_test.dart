// Tests Story 1.18 — ObligatorySubjectCheckboxList (AC2).
//
// Couvre :
//   - rendu N CheckboxListTile + cadenas (LucideIcons.lock)
//   - tap declenche onTapBlocked (matiere obligatoire = non decochable)
//   - isSaving=true => onChanged null (CheckboxListTile inactif)
//   - langKey "fr" vs "en" fallback fr puis subjectId
//   - responsive tablet (900x1200) : pas de debordement layout

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:valide_school/core/catalogue/domain/models.dart';
import 'package:valide_school/core/widgets/picker/obligatory_subject_checkbox_list.dart';

Subject _sub({
  required String id,
  String fr = 'Matiere FR',
  String en = 'Subject EN',
  String icon = 'book-open',
  String subSystem = 'francophone',
}) =>
    Subject(
      subjectId: id,
      subSystem: subSystem,
      name: {'fr': fr, 'en': en},
      icon: icon,
      isActive: true,
      sortOrder: 0,
    );

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (_, _) => MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('ObligatorySubjectCheckboxList', () {
    testWidgets('rend N CheckboxListTile + cadenas (LucideIcons.lock)',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrap(
        ObligatorySubjectCheckboxList(
          subjects: [
            _sub(id: 's1', fr: 'Anglais', en: 'English'),
            _sub(id: 's2', fr: 'Francais', en: 'French'),
            _sub(id: 's3', fr: 'Maths', en: 'Maths'),
          ],
          langKey: 'fr',
          isSaving: false,
          onTapBlocked: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CheckboxListTile), findsNWidgets(3));
      expect(find.text('Anglais'), findsOneWidget);
      expect(find.text('Francais'), findsOneWidget);
      expect(find.text('Maths'), findsOneWidget);
      // 3 cadenas LucideIcons.lock comme secondary
      expect(find.byIcon(LucideIcons.lock), findsNWidgets(3));
    });

    testWidgets('tap declenche onTapBlocked avec subjectId', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final tapped = <String>[];

      await tester.pumpWidget(_wrap(
        ObligatorySubjectCheckboxList(
          subjects: [
            _sub(id: 's-en', fr: 'Anglais'),
            _sub(id: 's-fr', fr: 'Francais'),
          ],
          langKey: 'fr',
          isSaving: false,
          onTapBlocked: tapped.add,
        ),
      ));
      await tester.pumpAndSettle();

      // Tap sur la 1ere CheckboxListTile
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pumpAndSettle();

      expect(tapped, equals(['s-en']));
    });

    testWidgets('isSaving=true rend les CheckboxListTile inactifs',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final tapped = <String>[];

      await tester.pumpWidget(_wrap(
        ObligatorySubjectCheckboxList(
          subjects: [_sub(id: 's1', fr: 'Anglais')],
          langKey: 'fr',
          isSaving: true,
          onTapBlocked: tapped.add,
        ),
      ));
      await tester.pumpAndSettle();

      final tile = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );
      expect(tile.onChanged, isNull,
          reason: 'isSaving=true doit desactiver onChanged');
      // Even on tap, callback should not fire
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      expect(tapped, isEmpty);
    });

    testWidgets('langKey "en" affiche les noms anglais', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrap(
        ObligatorySubjectCheckboxList(
          subjects: [
            _sub(id: 's1', fr: 'Anglais', en: 'English'),
          ],
          langKey: 'en',
          isSaving: false,
          onTapBlocked: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('English'), findsOneWidget);
      expect(find.text('Anglais'), findsNothing);
    });

    testWidgets('responsive tablet (900x1200) : rendu sans overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrap(
        ObligatorySubjectCheckboxList(
          subjects: [
            _sub(id: 's1'),
            _sub(id: 's2'),
            _sub(id: 's3'),
          ],
          langKey: 'fr',
          isSaving: false,
          onTapBlocked: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CheckboxListTile), findsNWidgets(3));
      expect(tester.takeException(), isNull,
          reason: 'Pas d\'overflow attendu en tablet portrait');
    });
  });
}
