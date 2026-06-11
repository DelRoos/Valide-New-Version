// Tests Story E1bis-2bis AC2 + AC6 — SubSystemStepBody (refactor PR #103).
//
// Couvre :
//   - tap card Francophone -> state.subSystem == francophone + currentStep == 1
//   - tap card Anglophone -> state.subSystem == anglophone + currentStep == 1
//   - goldens phone 360x780 + tablet 800x1280 unselected
//
// Le widget body est teste en isolation dans un Scaffold de test (le footer
// CTA est rendu par le shell parent, hors de ce test).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:valide_school/core/theme/tokens.dart';
import 'package:valide_school/core/widgets/cards/selection_card.dart';
import 'package:valide_school/features/onboarding/domain/sub_system.dart';
import 'package:valide_school/features/onboarding/presentation/pages/sub_system_step_body.dart';
import 'package:valide_school/features/onboarding/presentation/state/onboarding_providers.dart';
import 'package:valide_school/features/onboarding/providers.dart'
    show sharedPreferencesProvider;
import 'package:valide_school/l10n/generated/app_localizations.dart';

const Size _phoneSize = Size(360, 780);
const Size _tabletSize = Size(800, 1280);

Future<Widget> _wrap({
  required Size viewportSize,
  ProviderContainer? container,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final overrides = [sharedPreferencesProvider.overrideWithValue(prefs)];

  final inner = MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('fr'),
    home: Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Builder(
          builder: (context) {
            ScreenUtil.init(context, designSize: viewportSize);
            return const SubSystemStepBody();
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
  WidgetTester tester, {
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
  final widget = await _wrap(viewportSize: viewportSize, container: container);
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();
}

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SubSystemStepBody — interactions', () {
    testWidgets('tap card Francophone -> setSubSystem francophone + step 1',
        (tester) async {
      final container = await _container();
      addTearDown(container.dispose);

      await _pump(tester, viewportSize: _phoneSize, container: container);

      await tester.tap(find.byType(SelectionCard).first);
      await tester.pumpAndSettle();

      final state = container.read(onboardingNotifierProvider);
      expect(state.subSystem, SubSystem.francophone);
      expect(state.currentStep, 1);
    });

    testWidgets('tap card Anglophone -> setSubSystem anglophone + step 1',
        (tester) async {
      final container = await _container();
      addTearDown(container.dispose);

      await _pump(tester, viewportSize: _phoneSize, container: container);

      await tester.tap(find.byType(SelectionCard).at(1));
      await tester.pumpAndSettle();

      final state = container.read(onboardingNotifierProvider);
      expect(state.subSystem, SubSystem.anglophone);
      expect(state.currentStep, 1);
    });
  });

  group('SubSystemStepBody — goldens', () {
    testWidgets('golden phone unselected', (tester) async {
      await _pump(tester, viewportSize: _phoneSize);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('__goldens__/sub_system_step_body_phone.png'),
      );
    });

    testWidgets('golden tablet unselected', (tester) async {
      await _pump(tester, viewportSize: _tabletSize);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('__goldens__/sub_system_step_body_tablet.png'),
      );
    });
  });
}
