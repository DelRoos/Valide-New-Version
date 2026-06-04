import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:valide_school/core/theme/tokens.dart';
import 'package:valide_school/core/widgets/app_badge.dart';
import 'package:valide_school/core/widgets/app_button.dart';
import 'package:valide_school/core/widgets/app_card.dart';
import 'package:valide_school/core/widgets/app_icon_button.dart';
import 'package:valide_school/core/widgets/app_input.dart';
import 'package:valide_school/core/widgets/app_pill_tabs.dart';
import 'package:valide_school/core/widgets/app_progress_bar.dart';

Future<void> pumpHarness(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) => MaterialApp(
        home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
      ),
    ),
  );
  // pump unique court : évite pumpAndSettle qui timeout sur les animations
  // continues (spinner CircularProgressIndicator) tout en laissant le temps
  // aux AnimatedScale/Opacity de stabiliser pour les tests de tap.
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  group('AppButton', () {
    testWidgets('primary affiche label et déclenche onPressed', (tester) async {
      var taps = 0;
      await pumpHarness(
        tester,
        AppButton.primary(
          label: 'Continuer',
          onPressed: () => taps++,
        ),
      );
      expect(find.text('Continuer'), findsOneWidget);
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();
      expect(taps, equals(1));
    });

    testWidgets('loading=true affiche spinner + texte Envoi…', (tester) async {
      await pumpHarness(
        tester,
        AppButton.primary(label: 'Continuer', onPressed: () {}, loading: true),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Envoi…'), findsOneWidget);
    });

    testWidgets('onPressed=null désactive le tap', (tester) async {
      await pumpHarness(
        tester,
        AppButton.secondary(label: 'Annuler', onPressed: null),
      );
      // Pas d'exception attendue au tap.
      await tester.tap(find.byType(AppButton), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Annuler'), findsOneWidget);
    });
  });

  group('AppInput', () {
    testWidgets('affiche label et errorText quand fourni', (tester) async {
      await pumpHarness(
        tester,
        const AppInput(
          label: 'Email',
          errorText: 'Format invalide',
        ),
      );
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Format invalide'), findsOneWidget);
    });

    testWidgets('onChanged est appelé en saisissant', (tester) async {
      String? captured;
      await pumpHarness(
        tester,
        AppInput(
          label: 'Email',
          onChanged: (v) => captured = v,
        ),
      );
      await tester.enterText(find.byType(TextField), 'fatou@example.cm');
      expect(captured, equals('fatou@example.cm'));
    });
  });

  group('AppCard', () {
    testWidgets('rend child et déclenche onTap si fourni', (tester) async {
      var taps = 0;
      await pumpHarness(
        tester,
        AppCard(
          onTap: () => taps++,
          child: const Text('Carte'),
        ),
      );
      expect(find.text('Carte'), findsOneWidget);
      await tester.tap(find.byType(AppCard));
      await tester.pumpAndSettle();
      expect(taps, equals(1));
    });
  });

  group('AppBadge', () {
    testWidgets('rend label avec tone warning', (tester) async {
      await pumpHarness(
        tester,
        AppBadge(label: 'À renforcer', tone: BadgeTone.warning),
      );
      expect(find.text('À renforcer'), findsOneWidget);
    });

    test('assert si label vide (UX-DR-5)', () {
      expect(
        () => AppBadge(label: ''),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('AppPillTabs', () {
    testWidgets('rend les onglets et déclenche onTabSelected', (tester) async {
      int selected = 0;
      await pumpHarness(
        tester,
        StatefulBuilder(
          builder: (context, setState) => AppPillTabs(
            labels: const ['Tout', 'En cours', 'Fini'],
            selectedIndex: selected,
            onTabSelected: (i) => setState(() => selected = i),
          ),
        ),
      );
      expect(find.text('Tout'), findsOneWidget);
      expect(find.text('En cours'), findsOneWidget);
      await tester.tap(find.text('En cours'));
      await tester.pumpAndSettle();
      expect(selected, equals(1));
    });
  });

  group('AppProgressBar', () {
    testWidgets('rend label et clamp la valeur', (tester) async {
      await pumpHarness(
        tester,
        const AppProgressBar(value: 0.4, label: '4/10'),
      );
      expect(find.text('4/10'), findsOneWidget);
    });

    test('assert si value hors [0..1]', () {
      expect(
        () => AppProgressBar(value: 1.5),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('AppIconButton', () {
    testWidgets('rend icon et déclenche onPressed', (tester) async {
      var taps = 0;
      await pumpHarness(
        tester,
        AppIconButton(
          icon: LucideIcons.arrowLeft,
          onPressed: () => taps++,
          semanticLabel: 'Retour',
          tone: AppIconButtonTone.primary,
        ),
      );
      expect(find.byType(Icon), findsOneWidget);

      // L'icône occupe la quasi-totalité de la zone du bouton ;
      // on tape directement l'InkWell pour éviter qu'elle n'intercepte le hit.
      await tester.tap(
        find.descendant(
          of: find.byType(AppIconButton),
          matching: find.byType(InkWell),
        ),
      );
      await tester.pumpAndSettle();
      expect(taps, equals(1));

      final iconWidget = tester.widget<Icon>(find.byType(Icon));
      expect(iconWidget.color, equals(AppColors.primary));
    });
  });
}
