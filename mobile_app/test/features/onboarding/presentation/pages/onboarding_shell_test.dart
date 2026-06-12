// Tests Story E1bis-2bis AC1 + AC6 — OnboardingShell refactor (vrai shell).
//
// Couvre :
//   - mount vide -> currentStep 0 + rend SubSystemStepBody
//   - mount + subSystem persiste -> loadFromPersistence + step 1 + rend HeroIntroStepBody
//   - step 0 + subSystem null -> footer disabled (onPressed null)
//   - step 0 + tap card -> subSystem mis a jour + step passe a 1 (animation)
//   - step 1 + tap CTA Decouvrir (depuis le shell) -> step passe a 2
//   - currentStep placeholder (2, 9) -> rend _StepPlaceholder + pas de footer

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:valide_school/core/catalogue/domain/models.dart';
import 'package:valide_school/core/catalogue/providers.dart';
import 'package:valide_school/core/widgets/app_button.dart';
import 'package:valide_school/core/widgets/cards/selection_card.dart';
import 'package:valide_school/features/onboarding/domain/sub_system.dart';
import 'package:valide_school/features/onboarding/presentation/pages/hero_intro_step_body.dart';
import 'package:valide_school/features/onboarding/presentation/pages/onboarding_shell.dart';
import 'package:valide_school/features/onboarding/presentation/pages/sub_system_step_body.dart';
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
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      // E1bis-3 : step 2-4 consument catalogueProvider qui declenche
      // catalogueRepositoryProvider -> firestoreProvider (Firebase non
      // configure en test). Override avec un snapshot vide pour permettre
      // au shell de transitionner sans crash.
      catalogueProvider.overrideWith((ref) async => const CatalogueSnapshot(
            filieres: [],
            niveaux: [],
            series: [],
            subjects: [],
            examTargets: [],
            derivationRules: [],
          )),
    ],
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
  group('OnboardingShell — structure shell + dispatch', () {
    testWidgets(
        'mount + prefs vide -> currentStep 0 + SubSystemStepBody visible',
        (tester) async {
      final container = await _buildContainer();
      addTearDown(container.dispose);

      await _pump(tester, container: container);

      expect(find.byType(SubSystemStepBody), findsOneWidget);
      expect(find.byType(HeroIntroStepBody), findsNothing);

      final state = container.read(onboardingNotifierProvider);
      expect(state.currentStep, 0);
      expect(state.subSystem, isNull);
    });

    testWidgets(
        'mount + subSystem persiste -> loadFromPersistence hydrate + step 1 + HeroIntroStepBody',
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

      expect(find.byType(HeroIntroStepBody), findsOneWidget);
      expect(find.byType(SubSystemStepBody), findsNothing);
    });

    testWidgets('step 0 + subSystem null -> footer CTA disabled (onPressed null)',
        (tester) async {
      final container = await _buildContainer();
      addTearDown(container.dispose);

      await _pump(tester, container: container);

      final btn = tester.widget<AppButton>(find.byType(AppButton));
      expect(btn.onPressed, isNull);
    });

    testWidgets(
        'step 0 + tap card Francophone -> setSubSystem + transition step 1',
        (tester) async {
      final container = await _buildContainer();
      addTearDown(container.dispose);

      await _pump(tester, container: container);

      await tester.tap(find.byType(SelectionCard).first);
      await tester.pumpAndSettle();

      final state = container.read(onboardingNotifierProvider);
      expect(state.subSystem, SubSystem.francophone);
      expect(state.currentStep, 1);

      expect(find.byType(HeroIntroStepBody), findsOneWidget);
      expect(find.byType(SubSystemStepBody), findsNothing);
    });

    testWidgets(
        'step 1 + tap CTA footer (shell) -> notifier.next() + step passe a 2',
        (tester) async {
      final container = await _buildContainer();
      addTearDown(container.dispose);
      container.read(onboardingNotifierProvider.notifier).state =
          const OnboardingState(
        currentStep: 1,
        subSystem: SubSystem.francophone,
      );

      await _pump(tester, container: container);

      expect(find.byType(HeroIntroStepBody), findsOneWidget);
      await tester.tap(find.byType(AppButton), warnIfMissed: false);
      await tester.pump(); // E1bis-3 : pas de pumpAndSettle car le picker
                          // tente de fetch derivedProfileV2 -> CatalogueRepo
                          // qui leve sans firebase configure en test.
      final state = container.read(onboardingNotifierProvider);
      expect(state.currentStep, 2);
    });

    // Story E1bis-7 — step 9 (success celebration) declenche un flush
    // Firestore qui requiert Firebase init. Test runtime sur appareil
    // (couvert par E2E manuels) ; pas de widget test ici car le harness
    // n'init pas Firebase.
  });
}
