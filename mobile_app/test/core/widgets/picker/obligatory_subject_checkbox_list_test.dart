// Tests Story 1.18 — ObligatorySubjectCheckboxList (AC2).
//
// Couvre :
//   - rendu N CheckboxListTile + icone matiere (via iconResolver)
//   - tap declenche onTapBlocked (matiere obligatoire = non decochable)
//   - isSaving=true => onChanged null (CheckboxListTile inactif)
//   - langKey "fr" vs "en" fallback fr puis subjectId
//   - responsive tablet (900x1200) : pas de debordement layout
//
// Audit 2026-06-13 — remplacement du lock generique par l'icone Firestore
// de chaque matiere (cf. subject_icon_resolver.dart).

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:valide_school/core/catalogue/domain/models.dart';
import 'package:valide_school/core/widgets/picker/obligatory_subject_checkbox_list.dart';

IconData _fakeIconResolver(String name) => LucideIcons.bookOpen;

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
          iconResolver: _fakeIconResolver,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CheckboxListTile), findsNWidgets(3));
      expect(find.text('Anglais'), findsOneWidget);
      expect(find.text('Francais'), findsOneWidget);
      expect(find.text('Maths'), findsOneWidget);
      // Audit 2026-06-13 : la secondary affiche maintenant l'icone matiere
      // (book-open pour les 3 dans ce test). Le cadenas a ete retire.
      expect(find.byIcon(LucideIcons.bookOpen), findsNWidgets(3));
      expect(find.byIcon(LucideIcons.lock), findsNothing);
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
          iconResolver: _fakeIconResolver,
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
          iconResolver: _fakeIconResolver,
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
          iconResolver: _fakeIconResolver,
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
          iconResolver: _fakeIconResolver,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CheckboxListTile), findsNWidgets(3));
      expect(tester.takeException(), isNull,
          reason: 'Pas d\'overflow attendu en tablet portrait');
    });
  });
}
