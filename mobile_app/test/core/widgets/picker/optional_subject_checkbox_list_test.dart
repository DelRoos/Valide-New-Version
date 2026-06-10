// Tests Story 1.18 — OptionalSubjectCheckboxList (AC3).
//
// Couvre :
//   - rendu N CheckboxListTile interactifs
//   - picked.contains(subjectId) controle l'etat cochee/decochee
//   - tap declenche onToggle(subjectId, selected)
//   - isSaving=true => onChanged null
//   - iconResolver est appele avec s.icon
//   - responsive tablet 900x1200 sans overflow

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:valide_school/core/catalogue/domain/models.dart';
import 'package:valide_school/core/widgets/picker/optional_subject_checkbox_list.dart';

Subject _sub({
  required String id,
  String fr = 'Matiere FR',
  String en = 'Subject EN',
  String icon = 'book-open',
}) =>
    Subject(
      subjectId: id,
      subSystem: 'francophone',
      name: {'fr': fr, 'en': en},
      icon: icon,
      isActive: true,
      sortOrder: 0,
    );

IconData _fakeResolver(String name) {
  switch (name) {
    case 'function-square':
      return LucideIcons.functionSquare;
    case 'atom':
      return LucideIcons.atom;
    default:
      return LucideIcons.bookOpen;
  }
}

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (_, _) => MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('OptionalSubjectCheckboxList', () {
    testWidgets('picked.contains => CheckboxListTile.value=true sinon false',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrap(
        OptionalSubjectCheckboxList(
          subjects: [
            _sub(id: 's1', fr: 'Maths'),
            _sub(id: 's2', fr: 'Physique'),
            _sub(id: 's3', fr: 'Chimie'),
          ],
          picked: {'s1', 's3'},
          onToggle: (_, _) {},
          langKey: 'fr',
          isSaving: false,
          iconResolver: _fakeResolver,
        ),
      ));
      await tester.pumpAndSettle();

      final tiles = tester
          .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
          .toList();
      expect(tiles.length, 3);
      expect(tiles[0].value, isTrue, reason: 's1 picked');
      expect(tiles[1].value, isFalse, reason: 's2 non picked');
      expect(tiles[2].value, isTrue, reason: 's3 picked');
    });

    testWidgets('tap declenche onToggle(subjectId, selected)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final toggled = <(String, bool)>[];

      await tester.pumpWidget(_wrap(
        OptionalSubjectCheckboxList(
          subjects: [_sub(id: 's-maths', fr: 'Maths')],
          picked: const <String>{},
          onToggle: (id, sel) => toggled.add((id, sel)),
          langKey: 'fr',
          isSaving: false,
          iconResolver: _fakeResolver,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();

      expect(toggled, equals([('s-maths', true)]));
    });

    testWidgets('isSaving=true rend les CheckboxListTile inactifs',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final toggled = <(String, bool)>[];

      await tester.pumpWidget(_wrap(
        OptionalSubjectCheckboxList(
          subjects: [_sub(id: 's1', fr: 'Maths')],
          picked: const <String>{},
          onToggle: (id, sel) => toggled.add((id, sel)),
          langKey: 'fr',
          isSaving: true,
          iconResolver: _fakeResolver,
        ),
      ));
      await tester.pumpAndSettle();

      final tile = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );
      expect(tile.onChanged, isNull);
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      expect(toggled, isEmpty);
    });

    testWidgets('iconResolver est appele avec s.icon', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrap(
        OptionalSubjectCheckboxList(
          subjects: [
            _sub(id: 's-maths', fr: 'Maths', icon: 'function-square'),
            _sub(id: 's-phy', fr: 'Physique', icon: 'atom'),
          ],
          picked: const <String>{},
          onToggle: (_, _) {},
          langKey: 'fr',
          isSaving: false,
          iconResolver: _fakeResolver,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.functionSquare), findsOneWidget);
      expect(find.byIcon(LucideIcons.atom), findsOneWidget);
    });

    testWidgets('responsive tablet (900x1200) : rendu sans overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrap(
        OptionalSubjectCheckboxList(
          subjects: [_sub(id: 's1'), _sub(id: 's2'), _sub(id: 's3')],
          picked: const {'s2'},
          onToggle: (_, _) {},
          langKey: 'fr',
          isSaving: false,
          iconResolver: _fakeResolver,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CheckboxListTile), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });
  });
}
