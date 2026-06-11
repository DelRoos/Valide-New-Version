// Tests Story E1bis-0 AC5 + AC9 — CelebrationConfettiSuccess.
//
// Couvre :
//   - Tap CTA -> onComplete invoque
//   - autoDismissDelay ecoule -> onComplete invoque
//   - MediaQuery.disableAnimations = true -> ConfettiWidget absent
//   - Variants success/brand/warning -> cercle de la bonne couleur
//   - 4 goldens phone+tablet x 2 instants (initial / post-anim)

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:valide_school/core/feedback/audio_service.dart';
import 'package:valide_school/core/feedback/haptic_service.dart';
import 'package:valide_school/core/theme/tokens.dart';
import 'package:valide_school/core/widgets/feedback/celebration_confetti_success.dart';

/// AudioService noop : evite l'instanciation de `AudioPlayer()` (qui appelle
/// les channels natifs absents en environnement test).
class _NoopAudioService implements AudioService {
  @override
  bool get soundsEnabled => false;

  @override
  bool get examModeActive => false;

  @override
  Future<void> play(AppSfx sfx) async {}

  @override
  Future<void> dispose() async {}

  // Couvre les membres prives generes par Dart : pas d'usage hors le mock.
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// HapticService stub : disabled -> aucun appel HapticFeedback, aucun timer
/// pending (la sequence success/error utilise Future.delayed).
class _NoopHapticService extends HapticService {
  _NoopHapticService()
      : super(vibrationsEnabled: false, examModeActive: false);
}

const Size _phoneSize = Size(360, 780);
const Size _tabletSize = Size(900, 1200);

Widget _wrap(
  Widget child, {
  required Size viewportSize,
  bool disableAnimations = false,
}) {
  return ProviderScope(
    overrides: [
      // Override direct des services (pas du FeedbackPrefs en amont) :
      // (a) evite l'instanciation de `AudioPlayer()` -> MissingPluginException,
      // (b) garantit qu'aucun timer Future.delayed n'est cree par
      //     HapticService.success() pendant les tests.
      audioServiceProvider.overrideWithValue(_NoopAudioService()),
      hapticServiceProvider.overrideWithValue(_NoopHapticService()),
    ],
    child: MediaQuery(
      data: MediaQueryData(
        size: viewportSize,
        disableAnimations: disableAnimations,
      ),
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: viewportSize,
            disableAnimations: disableAnimations,
          ),
          child: Builder(
            builder: (context) {
              ScreenUtil.init(context, designSize: viewportSize);
              return child;
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
  bool disableAnimations = false,
  Duration settle = const Duration(milliseconds: 600),
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = viewportSize;
  await tester.binding.setSurfaceSize(viewportSize);
  addTearDown(() {
    tester.binding.setSurfaceSize(null);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(_wrap(
    child,
    viewportSize: viewportSize,
    disableAnimations: disableAnimations,
  ));
  await tester.pump();
  await tester.pump(settle);
}

void main() {
  group('CelebrationConfettiSuccess - interactions', () {
    testWidgets('tap CTA -> onComplete invoque', (tester) async {
      var completeCount = 0;

      await _pump(
        tester,
        CelebrationConfettiSuccess(
          title: 'Bienvenue !',
          subtitle: 'Ton espace est pret.',
          ctaLabel: 'Entrer dans mon espace',
          onComplete: () => completeCount++,
          autoDismissDelay: null,
        ),
        viewportSize: _phoneSize,
      );

      await tester.tap(find.text('Entrer dans mon espace'));
      await tester.pump();

      expect(completeCount, 1);
    });

    testWidgets('autoDismissDelay ecoule -> onComplete invoque', (tester) async {
      var completeCount = 0;

      await _pump(
        tester,
        CelebrationConfettiSuccess(
          title: 'Bienvenue !',
          subtitle: 'Ton espace est pret.',
          ctaLabel: 'OK',
          onComplete: () => completeCount++,
          autoDismissDelay: const Duration(milliseconds: 800),
        ),
        viewportSize: _phoneSize,
      );

      // Avant le delay : pas encore appele.
      expect(completeCount, 0);

      // Apres le delay : onComplete declenche.
      await tester.pump(const Duration(milliseconds: 900));
      expect(completeCount, 1);

      // Cleanup pending timer pour eviter le warning.
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('disableAnimations=true -> ConfettiWidget absent', (tester) async {
      await _pump(
        tester,
        CelebrationConfettiSuccess(
          title: 'OK',
          subtitle: 'OK',
          ctaLabel: 'OK',
          onComplete: () {},
          autoDismissDelay: null,
        ),
        viewportSize: _phoneSize,
        disableAnimations: true,
      );

      expect(find.byType(ConfettiWidget), findsNothing);
    });

    testWidgets('disableAnimations=false -> 2 ConfettiWidget (left + right)',
        (tester) async {
      await _pump(
        tester,
        CelebrationConfettiSuccess(
          title: 'OK',
          subtitle: 'OK',
          ctaLabel: 'OK',
          onComplete: () {},
          autoDismissDelay: null,
        ),
        viewportSize: _phoneSize,
      );

      expect(find.byType(ConfettiWidget), findsNWidgets(2));

      // Cleanup confetti animation timers.
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('variant brand -> cercle bg primarySoft', (tester) async {
      await _pump(
        tester,
        CelebrationConfettiSuccess(
          title: 'OK',
          subtitle: 'OK',
          ctaLabel: 'OK',
          onComplete: () {},
          autoDismissDelay: null,
          variant: CelebrationVariant.brand,
        ),
        viewportSize: _phoneSize,
        disableAnimations: true, // pour rendu deterministe
      );

      // Le Container du cercle a bg = primarySoft (variant brand).
      final container = tester
          .widgetList<Container>(find.byType(Container))
          .firstWhere((c) {
        final d = c.decoration;
        return d is BoxDecoration && d.shape == BoxShape.circle;
      });
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, AppColors.primarySoft);
    });
  });

  group('CelebrationConfettiSuccess - goldens', () {
    Future<void> pumpFixture(
      WidgetTester tester, {
      required Size size,
      required String fixture,
    }) async {
      await _pump(
        tester,
        CelebrationConfettiSuccess(
          title: 'Bienvenue, Fatou !',
          subtitle: 'Ton espace est pret. Decouvre tes cours.',
          ctaLabel: 'Entrer dans mon espace',
          onComplete: () {},
          // Goldens deterministes : pas d'auto-dismiss (evite timer pending).
          autoDismissDelay: null,
        ),
        viewportSize: size,
        disableAnimations: true,
        // Pump 600 ms suffit pour fixture initial (audio 200 ms +
        // haptic 100 ms ecoules).
        settle: fixture == 'post_anim'
            ? const Duration(milliseconds: 1200)
            : const Duration(milliseconds: 600),
      );
    }

    for (final form in const [
      (label: 'phone', size: _phoneSize),
      (label: 'tablet', size: _tabletSize),
    ]) {
      for (final fixture in const ['initial', 'post_anim']) {
        testWidgets('golden ${form.label} $fixture', (tester) async {
          await pumpFixture(tester, size: form.size, fixture: fixture);
          await expectLater(
            find.byType(CelebrationConfettiSuccess),
            matchesGoldenFile(
              '__goldens__/celebration_${form.label}_$fixture.png',
            ),
          );
        });
      }
    }
  });
}
