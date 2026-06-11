// Tests Story E1bis-2 AC3 + AC10 + AC11 — HeroIntroPage.
//
// Couvre :
//   - rendu hero banner + titre + sous-titre + 3 feature cards + CTA
//   - tap CTA -> notifier.next() (state.currentStep passe a 2)
//   - goldens phone 360x780 + tablet 800x1280

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:valide_school/core/widgets/app_button.dart';
import 'package:valide_school/features/onboarding/presentation/pages/hero_intro_page.dart';
import 'package:valide_school/features/onboarding/presentation/state/onboarding_providers.dart';
import 'package:valide_school/features/onboarding/presentation/state/onboarding_state.dart';
import 'package:valide_school/features/onboarding/providers.dart'
    show sharedPreferencesProvider;
import 'package:valide_school/l10n/generated/app_localizations.dart';

const Size _phoneSize = Size(360, 780);
const Size _tabletSize = Size(800, 1280);

Future<Widget> _wrap(
  Widget child, {
  required Size viewportSize,
  ProviderContainer? container,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final overrides = [sharedPreferencesProvider.overrideWithValue(prefs)];

  final inner = MediaQuery(
    data: MediaQueryData(size: viewportSize),
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: MediaQuery(
        data: MediaQueryData(size: viewportSize),
        child: Builder(
          builder: (context) {
            ScreenUtil.init(context, designSize: viewportSize);
            return child;
          },
        ),
      ),
    ),
  );

  if (container != null) {
    return UncontrolledProviderScope(container: container, child: inner);
  }
  return ProviderScope(overrides: overrides, child: inner);
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required Size viewportSize,
  ProviderContainer? container,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = viewportSize;
  await tester.binding.setSurfaceSize(viewportSize);
  addTearDown(() {
    tester.binding.setSurfaceSize(null);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final widget =
      await _wrap(child, viewportSize: viewportSize, container: container);
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HeroIntroPage - interactions', () {
    testWidgets('rendu hero banner + titre + sous-titre + 3 feature cards + CTA',
        (tester) async {
      await _pump(
        tester,
        const HeroIntroPage(),
        viewportSize: _phoneSize,
      );

      // Titre + sous-titre presents.
      expect(find.textContaining('Apprends'), findsOneWidget);
      expect(find.textContaining('Cours, exercices'), findsOneWidget);
      // Feature cards : Cours / Exercices / Chat IA.
      expect(find.text('Cours'), findsOneWidget);
      expect(find.text('Exercices'), findsOneWidget);
      expect(find.text('Chat IA'), findsOneWidget);
      // CTA dans le bottom navigation bar.
      expect(find.byType(AppButton), findsOneWidget);
    });

    testWidgets('tap CTA -> notifier.next() (state.currentStep 1 -> 2)',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      // Demarre l'etat a currentStep == 1 (apres setSubSystem).
      container.read(onboardingNotifierProvider.notifier).state =
          const OnboardingState(currentStep: 1);

      await _pump(
        tester,
        const HeroIntroPage(),
        viewportSize: _phoneSize,
        container: container,
      );

      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      final state = container.read(onboardingNotifierProvider);
      expect(state.currentStep, 2);
    });
  });

  group('HeroIntroPage - goldens', () {
    testWidgets('golden phone', (tester) async {
      await _pump(
        tester,
        const HeroIntroPage(),
        viewportSize: _phoneSize,
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('__goldens__/hero_intro_page_phone.png'),
      );
    });

    testWidgets('golden tablet', (tester) async {
      await _pump(
        tester,
        const HeroIntroPage(),
        viewportSize: _tabletSize,
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('__goldens__/hero_intro_page_tablet.png'),
      );
    });
  });
}
