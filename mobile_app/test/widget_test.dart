import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:valide_school/app.dart';
import 'package:valide_school/core/catalogue/providers.dart';
import 'package:valide_school/features/onboarding/providers.dart';

// Story 0.22 — le splash anime 1800 ms + 300 ms de hold avant de
// rediriger. Les tests qui ciblent HelloPage doivent attendre cette
// transition (marge de securite : 2200 ms).
const Duration _kSplashSettleDuration = Duration(milliseconds: 2200);

Future<void> _settleSplashToHello(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(_kSplashSettleDuration);
  await tester.pump(const Duration(milliseconds: 200));
}

// Story 1.2 — la locale derive desormais du sous-systeme. Pour rejoindre
// /hello apres le splash, il faut pre-populer subSystem en SharedPreferences
// (sinon le splash navigue vers /onboarding/subsystem).
Future<SharedPreferences> _prefsWith({
  required String subSystem,
  required String language,
}) async {
  SharedPreferences.setMockInitialValues({
    'onboarding.subsystem': subSystem,
    'onboarding.language': language,
  });
  return SharedPreferences.getInstance();
}

void main() {
  testWidgets(
    'Locale FR par défaut : affiche « Bonjour Valide » apres splash',
    (WidgetTester tester) async {
      final prefs =
          await _prefsWith(subSystem: 'francophone', language: 'fr');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            appStartupCatalogueCheckProvider.overrideWith((ref) async => true),
          ],
          child: const ValideApp(),
        ),
      );
      await _settleSplashToHello(tester);

      expect(find.text('Bonjour Valide'), findsOneWidget);
      expect(find.text('Hello Valide'), findsNothing);
    },
  );

  testWidgets(
    'Locale EN dérivée de subSystem anglophone : affiche « Hello Valide »',
    (WidgetTester tester) async {
      // Story 1.2 — la bascule i18n passe par le sous-systeme. Pas d'override
      // de localeProvider possible : LocaleNotifier.build() ref.watch
      // subSystemNotifierProvider donc une sous-classe ferait planter le watch.
      final prefs =
          await _prefsWith(subSystem: 'anglophone', language: 'en');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            appStartupCatalogueCheckProvider.overrideWith((ref) async => true),
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
      final prefs =
          await _prefsWith(subSystem: 'francophone', language: 'fr');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            appStartupCatalogueCheckProvider.overrideWith((ref) async => true),
          ],
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
