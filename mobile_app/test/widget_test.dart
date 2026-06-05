import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:valide_school/app.dart';

void main() {
  testWidgets(
    'Locale FR par défaut : affiche « Bonjour Valide »',
    (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: ValideApp()));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Bonjour Valide'), findsOneWidget);
      expect(find.text('Hello Valide'), findsNothing);
    },
  );

  testWidgets(
    'Locale EN forcée : affiche « Hello Valide »',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localeProvider.overrideWith(() => _EnglishLocaleNotifier()),
          ],
          child: const ValideApp(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Hello Valide'), findsOneWidget);
      expect(find.text('Bonjour Valide'), findsNothing);
    },
  );

  // Story 0.21 AC5 — sentinelle régression : la page /hello doit rester verte
  // sur 3 tailles d'écran représentatives (phone, tablet portrait, large).
  group('HelloPage responsive — sentinelle E0', () {
    Future<void> pumpAtSize(WidgetTester tester, Size size) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const ProviderScope(child: ValideApp()));
      await tester.pump(const Duration(milliseconds: 200));
    }

    testWidgets('Phone 375×812 : titre + sélecteur langue + 2 boutons',
        (tester) async {
      await pumpAtSize(tester, const Size(375, 812));
      expect(find.text('Bonjour Valide'), findsOneWidget);
      expect(find.text('Langue'), findsOneWidget);
      expect(find.text('Continuer'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
    });

    testWidgets('Tablet 1024×1366 : titre + sélecteur + 2 boutons',
        (tester) async {
      await pumpAtSize(tester, const Size(1024, 1366));
      expect(find.text('Bonjour Valide'), findsOneWidget);
      expect(find.text('Langue'), findsOneWidget);
      expect(find.text('Continuer'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
    });

    testWidgets('Phone landscape 812×375 : titre + boutons toujours présents',
        (tester) async {
      await pumpAtSize(tester, const Size(812, 375));
      expect(find.text('Bonjour Valide'), findsOneWidget);
      expect(find.text('Continuer'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
    });
  });
}

class _EnglishLocaleNotifier extends LocaleNotifier {
  @override
  Locale build() => const Locale('en');
}
