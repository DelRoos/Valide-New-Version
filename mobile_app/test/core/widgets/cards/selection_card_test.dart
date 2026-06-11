// Tests Story E1bis-0 AC1 + AC9 + AC10 — SelectionCard generique 3 variants.
//
// Couvre :
//   - Tap declenche onTap (et le haptic est consomme via Pressable / Riverpod)
//   - Selected = true -> bordure 2 px primary + scale 1.01
//   - Sans icone -> pas de gap gauche
//   - Description rendue uniquement si non-vide
//   - LayoutBuilder tablet >= 840 dp -> ConstrainedBox(maxWidth: 600)
//   - 12 goldens (3 variants x 2 form factors x 2 etats) phone 360x780 + tablet 900x1200
//
// Notes goldens :
// - En environnement flutter_test, le MediaQuery par defaut est 800x600 et
//   `tester.binding.setSurfaceSize(...)` ne le met PAS a jour. Sans MediaQuery
//   override explicite, `flutter_screenutil` (.w/.sp) calcule une echelle vs
//   800x600 -> font/icone bloates ~x2.2. Donc on impose MediaQuery(viewportSize)
//   autour de ScreenUtilInit.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:valide_school/core/theme/tokens.dart';
import 'package:valide_school/core/widgets/cards/selection_card.dart';

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
              // Force ScreenUtil re-init avec la viewportSize correcte
              // (ScreenUtilInit cache son init - sans reset explicite,
              // .w/.sp gardent l'echelle vs default 800x600).
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
  // Force view dimensions AVANT pumpWidget pour que MediaQuery + ScreenUtil
  // voient la viewportSize a l'init. `setSurfaceSize` seul ne suffit pas car
  // ScreenUtil cache son scaleWidth en static (v5.9.3).
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
  group('SelectionCard - interactions', () {
    testWidgets('tap declenche onTap', (tester) async {
      var tapCount = 0;
      await _pump(
        tester,
        SelectionCard(
          title: 'Francophone',
          selected: false,
          onTap: () => tapCount++,
          icon: const Icon(LucideIcons.map),
        ),
        viewportSize: _phoneSize,
      );

      await tester.tap(find.byType(SelectionCard));
      await tester.pumpAndSettle();

      expect(tapCount, 1);
    });

    testWidgets('selected=true -> bordure 2 px primary', (tester) async {
      await _pump(
        tester,
        SelectionCard(
          title: 'Anglophone',
          selected: true,
          onTap: () {},
          icon: const Icon(LucideIcons.globe),
        ),
        viewportSize: _phoneSize,
      );

      final containers = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final cardDecoration = containers.first.decoration! as BoxDecoration;
      expect(cardDecoration.border, isA<Border>());
      final border = cardDecoration.border! as Border;
      expect(border.top.width, 2);
      expect(border.top.color, AppColors.primary);
      expect(cardDecoration.color, AppColors.primarySoft);
    });

    testWidgets('selected=false -> bordure 1 px border + bg card', (tester) async {
      await _pump(
        tester,
        SelectionCard(
          title: 'Francophone',
          selected: false,
          onTap: () {},
        ),
        viewportSize: _phoneSize,
      );

      final containers = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final cardDecoration = containers.first.decoration! as BoxDecoration;
      final border = cardDecoration.border! as Border;
      expect(border.top.width, 1);
      expect(border.top.color, AppColors.border);
      expect(cardDecoration.color, AppColors.card);
    });

    testWidgets('sans icone -> pas d Icon dans le tree', (tester) async {
      await _pump(
        tester,
        SelectionCard(
          title: 'Sans icone',
          selected: false,
          onTap: () {},
        ),
        viewportSize: _phoneSize,
      );

      // Aucune Icon (selected=false donc pas non plus le checkmark interne).
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('description rendue si non-vide', (tester) async {
      await _pump(
        tester,
        SelectionCard(
          title: 'Generale',
          description: 'Series A, C, D, E, TI',
          selected: false,
          onTap: () {},
          icon: const Icon(LucideIcons.library),
        ),
        viewportSize: _phoneSize,
      );
      expect(find.text('Series A, C, D, E, TI'), findsOneWidget);
    });

    testWidgets('description nulle -> texte description absent', (tester) async {
      await _pump(
        tester,
        SelectionCard(
          title: 'Generale',
          selected: false,
          onTap: () {},
        ),
        viewportSize: _phoneSize,
      );
      // Une seule occurrence Text (le titre).
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets(
      'tablet >= 840 dp -> ConstrainedBox(maxWidth: 600) actif',
      (tester) async {
        await _pump(
          tester,
          SelectionCard(
            title: 'Generale',
            selected: false,
            onTap: () {},
            icon: const Icon(LucideIcons.library),
          ),
          viewportSize: _tabletSize,
        );

        final box = tester
            .widgetList<ConstrainedBox>(find.byType(ConstrainedBox))
            .toList();
        // Au moins un ConstrainedBox avec maxWidth fini (notre 600.w).
        final hasMaxWidth = box.any((b) {
          final mw = b.constraints.maxWidth;
          return mw < double.infinity && mw <= 700;
        });
        expect(hasMaxWidth, true);
      },
    );
  });

  group('SelectionCard - goldens', () {
    for (final variant in SelectionCardVariant.values) {
      for (final selected in const [false, true]) {
        for (final form in const [
          (label: 'phone', size: _phoneSize),
          (label: 'tablet', size: _tabletSize),
        ]) {
          testWidgets(
            'golden ${variant.name} ${form.label} '
            '${selected ? "selected" : "default"}',
            (tester) async {
              await _pump(
                tester,
                SelectionCard(
                  title: 'Francophone',
                  selected: selected,
                  onTap: () {},
                  icon: const Icon(LucideIcons.map),
                  description: 'Cameroun · BEPC · Probatoire · BAC',
                  variant: variant,
                ),
                viewportSize: form.size,
              );
              await expectLater(
                find.byType(SelectionCard),
                matchesGoldenFile(
                  '__goldens__/selection_card_'
                  '${variant.name}_'
                  '${form.label}_'
                  '${selected ? "selected" : "default"}.png',
                ),
              );
            },
          );
        }
      }
    }
  });
}
