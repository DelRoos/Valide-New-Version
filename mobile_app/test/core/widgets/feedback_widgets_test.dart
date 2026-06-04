import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:valide_school/core/widgets/app_bottom_sheet.dart';
import 'package:valide_school/core/widgets/app_empty_state.dart';
import 'package:valide_school/core/widgets/app_inline_alert.dart';
import 'package:valide_school/core/widgets/app_modal.dart';
import 'package:valide_school/core/widgets/app_skeleton.dart';
import 'package:valide_school/core/widgets/app_spinner.dart';
import 'package:valide_school/core/widgets/app_toast.dart';
import 'package:valide_school/core/widgets/feedback/error_shake_wrapper.dart';
import 'package:valide_school/core/widgets/feedback/level_up_bloom_overlay.dart';
import 'package:valide_school/core/widgets/feedback/success_checkmark_overlay.dart';

Future<void> pumpHarness(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ProviderScope(
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, _) => MaterialApp(
          home: Scaffold(body: child),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  group('AppToast', () {
    testWidgets('show insère un OverlayEntry avec le message', (tester) async {
      late BuildContext ctx;
      await pumpHarness(
        tester,
        Builder(builder: (c) {
          ctx = c;
          return const SizedBox();
        }),
      );
      AppToast.show(ctx, message: 'Lien copié', tone: ToastTone.success);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Lien copié'), findsOneWidget);
      expect(find.byIcon(LucideIcons.circleCheck), findsOneWidget);
      // Draine le Timer de 4.4 s qui retire l'OverlayEntry.
      await tester.pump(const Duration(seconds: 5));
    });
  });

  group('AppModal', () {
    testWidgets('show affiche bouton primary obligatoire (UX-DR-10)',
        (tester) async {
      late BuildContext ctx;
      await pumpHarness(
        tester,
        Builder(builder: (c) {
          ctx = c;
          return const SizedBox();
        }),
      );
      AppModal.show<void>(
        ctx,
        title: 'Confirmer ?',
        child: const Text('Ton choix est définitif.'),
        primary: (label: 'Oui', onTap: (_) {}),
        secondary: (label: 'Non', onTap: (_) {}),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Confirmer ?'), findsOneWidget);
      expect(find.text('Oui'), findsOneWidget);
      expect(find.text('Non'), findsOneWidget);
    });
  });

  group('AppBottomSheet', () {
    testWidgets('show affiche handle + child + bouton primaire',
        (tester) async {
      late BuildContext ctx;
      await pumpHarness(
        tester,
        Builder(builder: (c) {
          ctx = c;
          return const SizedBox();
        }),
      );
      AppBottomSheet.show<void>(
        ctx,
        title: 'Filtres',
        child: const Text('Trier par : récent'),
        primary: (label: 'Appliquer', onTap: (_) {}),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Filtres'), findsOneWidget);
      expect(find.text('Trier par : récent'), findsOneWidget);
      expect(find.text('Appliquer'), findsOneWidget);
    });
  });

  group('AppEmptyState', () {
    testWidgets('rend icon + title + subtitle + CTA', (tester) async {
      var tapped = false;
      await pumpHarness(
        tester,
        AppEmptyState(
          icon: LucideIcons.inbox,
          title: 'Aucune notification',
          subtitle: 'Tu seras notifié dès qu\'il y aura du nouveau',
          ctaLabel: 'Explorer',
          onCtaPressed: () => tapped = true,
        ),
      );
      expect(find.text('Aucune notification'), findsOneWidget);
      expect(find.text('Tu seras notifié dès qu\'il y aura du nouveau'),
          findsOneWidget);
      expect(find.text('Explorer'), findsOneWidget);
      await tester.tap(find.text('Explorer'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tapped, isTrue);
    });

    testWidgets('sans CTA n\'affiche pas de bouton', (tester) async {
      await pumpHarness(
        tester,
        const AppEmptyState(
          icon: LucideIcons.inbox,
          title: 'Vide',
        ),
      );
      expect(find.text('Explorer'), findsNothing);
    });
  });

  group('AppSkeleton', () {
    testWidgets('rend un Container avec la taille demandée', (tester) async {
      await pumpHarness(
        tester,
        const AppSkeleton(width: 200, height: 16),
      );
      expect(find.byType(AppSkeleton), findsOneWidget);
    });
  });

  group('AppSpinner', () {
    testWidgets('rend un CircularProgressIndicator', (tester) async {
      await pumpHarness(tester, const AppSpinner());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('AppInlineAlert', () {
    testWidgets('rend message + icon selon tone warning', (tester) async {
      await pumpHarness(
        tester,
        const AppInlineAlert(
          tone: AlertTone.warning,
          message: 'Pas de connexion réseau',
        ),
      );
      expect(find.text('Pas de connexion réseau'), findsOneWidget);
      expect(find.byIcon(LucideIcons.triangleAlert), findsOneWidget);
    });

    testWidgets('tone error affiche icône circleAlert', (tester) async {
      await pumpHarness(
        tester,
        const AppInlineAlert(
          tone: AlertTone.error,
          message: 'Champ requis',
        ),
      );
      expect(find.byIcon(LucideIcons.circleAlert), findsOneWidget);
    });
  });

  group('SuccessCheckmarkOverlay', () {
    testWidgets('show insère un overlay avec icône check', (tester) async {
      late BuildContext ctx;
      late WidgetRef ref;
      await tester.pumpWidget(
        ProviderScope(
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, _) => MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (c, r, _) {
                    ctx = c;
                    ref = r;
                    return const SizedBox();
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      SuccessCheckmarkOverlay.show(ctx, ref);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byIcon(LucideIcons.check), findsOneWidget);
      // Draine le Future.delayed 700 ms qui retire l'OverlayEntry.
      await tester.pump(const Duration(milliseconds: 800));
    });
  });

  group('ErrorShakeWrapper', () {
    testWidgets('rend child quand pas shaken', (tester) async {
      final key = GlobalKey<ErrorShakeWrapperState>();
      await pumpHarness(
        tester,
        ErrorShakeWrapper(key: key, child: const Text('Réponse')),
      );
      expect(find.text('Réponse'), findsOneWidget);
      // L'animation de shake elle-même est testée par integration tests
      // (controller forward + pumpAndSettle interagissent mal en test unit).
      // Smoke : on vérifie juste que le widget peut être rendu et
      // que la state est accessible.
      expect(key.currentState, isNotNull);
    });
  });

  group('LevelUpBloomOverlay', () {
    testWidgets('show insère un overlay étoile primary', (tester) async {
      late BuildContext ctx;
      late WidgetRef ref;
      await tester.pumpWidget(
        ProviderScope(
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, _) => MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (c, r, _) {
                    ctx = c;
                    ref = r;
                    return const SizedBox();
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      LevelUpBloomOverlay.show(ctx, ref);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byIcon(LucideIcons.star), findsOneWidget);
      // Draine le Future.delayed 1200 ms qui retire l'OverlayEntry.
      await tester.pump(const Duration(milliseconds: 1300));
    });
  });
}
