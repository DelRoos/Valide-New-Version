// Tests Story E1bis-0 AC4 + AC9 — SchoolSearchWithAdd.
//
// Couvre :
//   - Debounce 250 ms : 1 seul appel searchProvider apres une serie de chars
//   - Tap resultat -> onSelect propage le SchoolEntry
//   - Zero resultat + tap add -> onAddRequest await + onSelect(SchoolEntry(isPending: true))
//   - AsyncError reseau -> bandeau warning visible + add card toujours dispo
//   - 8 goldens (phone+tablet x 4 etats : vide / saisie / resultats / zero resultat)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:valide_school/core/theme/tokens.dart';
import 'package:valide_school/core/widgets/app_inline_alert.dart';
import 'package:valide_school/core/widgets/forms/school_entry.dart';
import 'package:valide_school/core/widgets/forms/school_search_with_add.dart';

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

const _placeholder = 'Cherche ton ecole...';
const _addTemplate = '+ Ajouter {name}';
const _offline = 'Pas de reseau. Re-essaye ou ajoute ton ecole.';

const _sampleResults = [
  SchoolEntry(id: 'sch_1', name: 'Lycee de Biyem-Assi'),
  SchoolEntry(id: 'sch_2', name: 'College Bilingue La Conquete'),
  SchoolEntry(id: 'sch_3', name: 'GBHS Bafoussam'),
];

void main() {
  group('SchoolSearchWithAdd - interactions', () {
    testWidgets('debounce 250 ms : 1 seul appel searchProvider', (tester) async {
      var callCount = 0;
      late String lastQuery;

      await _pump(
        tester,
        SchoolSearchWithAdd(
          selectedSchool: null,
          onSelect: (_) {},
          onAddRequest: (_) async => 'req_1',
          searchProvider: (q) {
            callCount++;
            lastQuery = q;
            return const SchoolSearchData(_sampleResults);
          },
          placeholder: _placeholder,
          emptyAddTemplate: _addTemplate,
          warningOfflineMessage: _offline,
        ),
        viewportSize: _phoneSize,
      );

      // Etat idle (saisie vide) -> 0 appel.
      expect(callCount, 0);

      // Frappe "Lyc" rapidement.
      await tester.enterText(find.byType(TextField), 'Lyc');
      // Avant 250 ms : pas encore d'appel.
      await tester.pump(const Duration(milliseconds: 100));
      expect(callCount, 0);
      // Apres 250 ms : 1 appel avec la valeur finale.
      await tester.pump(const Duration(milliseconds: 200));
      expect(callCount, 1);
      expect(lastQuery, 'Lyc');
    });

    testWidgets('tap resultat -> onSelect propage le SchoolEntry',
        (tester) async {
      SchoolEntry? captured;

      await _pump(
        tester,
        SchoolSearchWithAdd(
          selectedSchool: null,
          onSelect: (s) => captured = s,
          onAddRequest: (_) async => 'req_1',
          searchProvider: (q) => const SchoolSearchData(_sampleResults),
          placeholder: _placeholder,
          emptyAddTemplate: _addTemplate,
          warningOfflineMessage: _offline,
        ),
        viewportSize: _phoneSize,
      );

      await tester.enterText(find.byType(TextField), 'Lyc');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      await tester.tap(find.text('GBHS Bafoussam'));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.id, 'sch_3');
      expect(captured!.isPending, false);
    });

    testWidgets('zero resultat + tap add -> onAddRequest + onSelect pending',
        (tester) async {
      SchoolEntry? captured;
      var addRequestCount = 0;

      await _pump(
        tester,
        SchoolSearchWithAdd(
          selectedSchool: null,
          onSelect: (s) => captured = s,
          onAddRequest: (name) async {
            addRequestCount++;
            return 'req_42';
          },
          searchProvider: (q) => const SchoolSearchData([]),
          placeholder: _placeholder,
          emptyAddTemplate: _addTemplate,
          warningOfflineMessage: _offline,
        ),
        viewportSize: _phoneSize,
      );

      await tester.enterText(find.byType(TextField), 'Ecole inconnue');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Carte « + Ajouter ... » visible.
      expect(find.textContaining('Ajouter'), findsOneWidget);

      await tester.tap(find.byType(DottedBorderBox));
      await tester.pumpAndSettle();

      expect(addRequestCount, 1);
      expect(captured, isNotNull);
      expect(captured!.id, 'req_42');
      expect(captured!.name, 'Ecole inconnue');
      expect(captured!.isPending, true);
    });

    testWidgets('AsyncError reseau -> bandeau warning + add toujours dispo',
        (tester) async {
      await _pump(
        tester,
        SchoolSearchWithAdd(
          selectedSchool: null,
          onSelect: (_) {},
          onAddRequest: (_) async => 'req_42',
          searchProvider: (q) =>
              const SchoolSearchError(isNetwork: true),
          placeholder: _placeholder,
          emptyAddTemplate: _addTemplate,
          warningOfflineMessage: _offline,
        ),
        viewportSize: _phoneSize,
      );

      await tester.enterText(find.byType(TextField), 'Lyc');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Bandeau warning visible.
      expect(find.byType(AppInlineAlert), findsOneWidget);
      expect(find.text(_offline), findsOneWidget);

      // Carte « + Ajouter ... » toujours dispo.
      expect(find.byType(DottedBorderBox), findsOneWidget);
    });
  });

  group('SchoolSearchWithAdd - goldens', () {
    Future<void> pumpFixture(
      WidgetTester tester, {
      required Size size,
      required String fixture,
    }) async {
      await _pump(
        tester,
        SchoolSearchWithAdd(
          selectedSchool: null,
          onSelect: (_) {},
          onAddRequest: (_) async => 'req_1',
          searchProvider: (q) => switch (fixture) {
            'empty' => const SchoolSearchIdle(),
            'typing' => const SchoolSearchData(_sampleResults),
            'no_results' => const SchoolSearchData([]),
            'error' => const SchoolSearchError(isNetwork: true),
            _ => const SchoolSearchIdle(),
          },
          placeholder: _placeholder,
          emptyAddTemplate: _addTemplate,
          warningOfflineMessage: _offline,
        ),
        viewportSize: size,
      );

      if (fixture != 'empty') {
        await tester.enterText(
          find.byType(TextField),
          fixture == 'no_results' ? 'Ecole inconnue' : 'Lyc',
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
      }
    }

    const fixtures = ['empty', 'typing', 'no_results', 'error'];

    for (final form in const [
      (label: 'phone', size: _phoneSize),
      (label: 'tablet', size: _tabletSize),
    ]) {
      for (final fixture in fixtures) {
        testWidgets('golden ${form.label} $fixture', (tester) async {
          await pumpFixture(tester, size: form.size, fixture: fixture);
          await expectLater(
            find.byType(SchoolSearchWithAdd),
            matchesGoldenFile(
              '__goldens__/school_search_${form.label}_$fixture.png',
            ),
          );
        });
      }
    }
  });
}
