// Story 0.22 AC6 — sentinelle responsive de la SplashPage.
//
// On verifie sur 3 tailles d'ecran representatives que la SplashPage :
//  - rend le scaffold avec le fond brand (AppColors.primary)
//  - n'affiche PAS le logo image (animation non-liee au logo, verdict
//    2026-06-05)
//  - rend un CustomPaint (le mot VALIDE qui se dessine au trait)
//  - navigue vers /hello apres l'animation (~2100 ms)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:valide_school/app.dart';
import 'package:valide_school/core/catalogue/providers.dart';
import 'package:valide_school/core/theme/tokens.dart';
import 'package:valide_school/features/onboarding/providers.dart';

// Story 1.2 — pre-populate subSystem=francophone pour que le splash navigue
// direct vers /hello (sinon il irait sur /onboarding/subsystem). Cela conserve
// l'intention initiale du test : verifier l'animation puis la nav.
Future<SharedPreferences> _prefsWithFrancophoneSubsystem() async {
  SharedPreferences.setMockInitialValues({
    'onboarding.subsystem': 'francophone',
    'onboarding.language': 'fr',
  });
  return SharedPreferences.getInstance();
}

void main() {
  group('SplashPage responsive — Story 0.22', () {
    Future<void> pumpAtSize(WidgetTester tester, Size size) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final prefs = await _prefsWithFrancophoneSubsystem();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            appStartupCatalogueCheckProvider.overrideWith((ref) async => true),
          ],
          child: const ValideApp(),
        ),
      );
      await tester.pump();
    }

    void expectSplashRendered(WidgetTester tester) {
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, AppColors.primary);

      // Story 0.22 verdict 2026-06-05 : pas de logo image dans la SplashPage
      // (animation non-liee au logo, le logo est deja vu sur le natif).
      expect(find.byType(Image), findsNothing);

      // Le mot VALIDE est dessine via CustomPaint.
      expect(find.byType(CustomPaint), findsWidgets);
    }

    testWidgets('Phone 375×812 : fond brand + CustomPaint, pas de logo image',
        (tester) async {
      await pumpAtSize(tester, const Size(375, 812));
      expectSplashRendered(tester);
    });

    testWidgets('Tablet 1024×1366 : fond brand + CustomPaint, pas de logo',
        (tester) async {
      await pumpAtSize(tester, const Size(1024, 1366));
      expectSplashRendered(tester);
    });

    testWidgets('Phone landscape 812×375 : fond brand + CustomPaint',
        (tester) async {
      await pumpAtSize(tester, const Size(812, 375));
      expectSplashRendered(tester);
    });

    testWidgets('Navigation auto vers /hello apres ~2100 ms',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final prefs = await _prefsWithFrancophoneSubsystem();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            appStartupCatalogueCheckProvider.overrideWith((ref) async => true),
          ],
          child: const ValideApp(),
        ),
      );
      await tester.pump();
      expect(find.text('Bonjour Valide'), findsNothing);

      await tester.pump(const Duration(milliseconds: 2200));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Bonjour Valide'), findsOneWidget);
    });
  });
}
