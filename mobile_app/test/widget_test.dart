import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:valide_school/app.dart';
import 'package:valide_school/core/catalogue/providers.dart';

// Story 0.22 — le splash anime 1800 ms + 300 ms de hold avant de
// rediriger vers /hello. Les tests qui ciblent HelloPage doivent attendre
// cette transition (marge de securite : 2200 ms).
const Duration _kSplashSettleDuration = Duration(milliseconds: 2200);

Future<void> _settleSplashToHello(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(_kSplashSettleDuration);
  await tester.pump(const Duration(milliseconds: 200));
}

// Story 1.1c — bypass du redirect /catalogue-waiting en environnement test.
// Sans Firestore initialise, `appStartupCatalogueCheckProvider` echouerait et
// le router redirigerait vers /catalogue-waiting. On force `true` pour rester
// sur le flow normal Splash -> Hello.
final _bypassCatalogueCheck = [
  appStartupCatalogueCheckProvider.overrideWith((ref) async => true),
];

void main() {
  testWidgets(
    'Locale FR par défaut : affiche « Bonjour Valide » apres splash',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _bypassCatalogueCheck,
          child: const ValideApp(),
        ),
      );
      await _settleSplashToHello(tester);

      expect(find.text('Bonjour Valide'), findsOneWidget);
      expect(find.text('Hello Valide'), findsNothing);
    },
  );

  testWidgets(
    'Locale EN forcée : affiche « Hello Valide » apres splash',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._bypassCatalogueCheck,
            localeProvider.overrideWith(() => _EnglishLocaleNotifier()),
          ],
          child: const ValideApp(),
        ),
      );
      await _settleSplashToHello(tester);

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
      await tester.pumpWidget(
        ProviderScope(
          overrides: _bypassCatalogueCheck,
          child: const ValideApp(),
        ),
      );
      await _settleSplashToHello(tester);
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
