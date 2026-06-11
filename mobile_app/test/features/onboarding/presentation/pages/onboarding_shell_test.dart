// Tests Story E1bis-2 AC1 + AC12 — OnboardingShell.
//
// Couvre :
//   - mount appelle loadFromPersistence (subSystem persiste -> currentStep 1)
//   - currentStep 0 -> rend SubSystemChoicePageV2
//   - currentStep 1 -> rend HeroIntroPage
//   - currentStep 2 -> rend placeholder "Etape 2 — a venir"

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:valide_school/features/onboarding/domain/sub_system.dart';
import 'package:valide_school/features/onboarding/presentation/pages/hero_intro_page.dart';
import 'package:valide_school/features/onboarding/presentation/pages/onboarding_shell.dart';
import 'package:valide_school/features/onboarding/presentation/pages/sub_system_choice_page_v2.dart';
import 'package:valide_school/features/onboarding/presentation/state/onboarding_providers.dart';
import 'package:valide_school/features/onboarding/presentation/state/onboarding_state.dart';
import 'package:valide_school/features/onboarding/providers.dart'
    show sharedPreferencesProvider;
import 'package:valide_school/l10n/generated/app_localizations.dart';

const Size _phoneSize = Size(360, 780);

Future<ProviderContainer> _buildContainer({
  Map<String, Object> initial = const {},
}) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required ProviderContainer container,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = _phoneSize;
  await tester.binding.setSurfaceSize(_phoneSize);
  addTearDown(() {
    tester.binding.setSurfaceSize(null);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MediaQuery(
        data: const MediaQueryData(size: _phoneSize),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Builder(
            builder: (context) {
              ScreenUtil.init(context, designSize: _phoneSize);
              return const OnboardingShell();
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('OnboardingShell', () {
    testWidgets(
        'mount + SharedPreferences vide -> currentStep reste 0 + rend SubSystemChoicePageV2',
        (tester) async {
      final container = await _buildContainer();
      addTearDown(container.dispose);

      await _pump(tester, container: container);

      expect(find.byType(SubSystemChoicePageV2), findsOneWidget);
      expect(find.byType(HeroIntroPage), findsNothing);

      final state = container.read(onboardingNotifierProvider);
      expect(state.currentStep, 0);
      expect(state.subSystem, isNull);
    });

    testWidgets(
        'mount + subSystem persiste -> loadFromPersistence hydrate + step 1 + rend HeroIntroPage',
        (tester) async {
      final container = await _buildContainer(initial: {
        'onboarding.subsystem': 'francophone',
        'onboarding.language': 'fr',
      });
      addTearDown(container.dispose);

      await _pump(tester, container: container);

      final state = container.read(onboardingNotifierProvider);
      expect(state.subSystem, SubSystem.francophone);
      expect(state.currentStep, 1);

      expect(find.byType(HeroIntroPage), findsOneWidget);
      expect(find.byType(SubSystemChoicePageV2), findsNothing);
    });

    testWidgets('currentStep 2 -> placeholder "Etape 2 — a venir"',
        (tester) async {
      final container = await _buildContainer();
      addTearDown(container.dispose);
      container.read(onboardingNotifierProvider.notifier).state =
          const OnboardingState(currentStep: 2);

      await _pump(tester, container: container);

      expect(find.textContaining('Etape 2'), findsOneWidget);
      expect(find.byType(SubSystemChoicePageV2), findsNothing);
      expect(find.byType(HeroIntroPage), findsNothing);
    });

    testWidgets('currentStep 9 -> placeholder "Etape 9 — a venir"',
        (tester) async {
      final container = await _buildContainer();
      addTearDown(container.dispose);
      container.read(onboardingNotifierProvider.notifier).state =
          const OnboardingState(currentStep: 9);

      await _pump(tester, container: container);

      expect(find.textContaining('Etape 9'), findsOneWidget);
    });
  });
}
