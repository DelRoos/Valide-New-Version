// Tests Story E1bis-2bis AC3 + AC6 — HeroIntroStepBody (refactor PR #103).
//
// Couvre :
//   - rendu : hero banner + titre + sous-titre + 3 feature cards
//   - goldens phone 360x780 + tablet 800x1280
//
// Le tap CTA est teste au niveau du shell (footer dispatched par
// OnboardingShell), pas ici — ce widget est un body pur sans CTA propre.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:valide_school/core/theme/tokens.dart';
import 'package:valide_school/features/onboarding/presentation/pages/hero_intro_step_body.dart';
import 'package:valide_school/features/onboarding/providers.dart'
    show sharedPreferencesProvider;
import 'package:valide_school/l10n/generated/app_localizations.dart';

const Size _phoneSize = Size(360, 780);
const Size _tabletSize = Size(800, 1280);

Future<Widget> _wrap({required Size viewportSize}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: MaterialApp(
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
              return const HeroIntroStepBody();
            },
          ),
        ),
      ),
    ),
  );
}

Future<void> _pump(WidgetTester tester, {required Size viewportSize}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = viewportSize;
  await tester.binding.setSurfaceSize(viewportSize);
  addTearDown(() {
    tester.binding.setSurfaceSize(null);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final widget = await _wrap(viewportSize: viewportSize);
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HeroIntroStepBody — rendu', () {
    testWidgets('titre + sous-titre + 3 feature cards visibles',
        (tester) async {
      await _pump(tester, viewportSize: _phoneSize);

      expect(find.text('Cours'), findsOneWidget);
      expect(find.text('Exercices'), findsOneWidget);
      expect(find.text('Chat IA'), findsOneWidget);
    });
  });

  group('HeroIntroStepBody — goldens', () {
    testWidgets('golden phone', (tester) async {
      await _pump(tester, viewportSize: _phoneSize);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('__goldens__/hero_intro_step_body_phone.png'),
      );
    });

    testWidgets('golden tablet', (tester) async {
      await _pump(tester, viewportSize: _tabletSize);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('__goldens__/hero_intro_step_body_tablet.png'),
      );
    });
  });
}
