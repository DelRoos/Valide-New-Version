// Tests widget CatalogueWaitingPage — Story 1.1c AC6.
//
// Vérifient :
//  1. La page affiche bien le titre + icône wifi-off + bouton Réessayer
//  2. Tap sur Réessayer invalide appStartupCatalogueCheckProvider

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:valide_school/core/catalogue/providers.dart';
import 'package:valide_school/features/catalogue/presentation/catalogue_waiting_page.dart';
import 'package:valide_school/l10n/generated/app_localizations.dart';

Future<void> _pumpPage(
  WidgetTester tester, {
  required ProviderContainer container,
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: const CatalogueWaitingPage(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle(const Duration(milliseconds: 300));
}

void main() {
  group('CatalogueWaitingPage — Story 1.1c', () {
    testWidgets(
      'affiche titre FR + icone wifi-off + bouton Reessayer',
      (tester) async {
        // Override le provider pour retourner false (offline+vide).
        final container = ProviderContainer(
          overrides: [
            appStartupCatalogueCheckProvider.overrideWith((ref) async => false),
          ],
        );
        addTearDown(container.dispose);

        await _pumpPage(tester, container: container);

        expect(find.text('En attente de connexion'), findsOneWidget);
        expect(find.text('Réessayer'), findsOneWidget);
        expect(find.byIcon(LucideIcons.wifiOff), findsOneWidget);
      },
    );

    testWidgets(
      'tap sur Reessayer relit appStartupCatalogueCheckProvider',
      (tester) async {
        // Compteur d'invocations du provider — incremente a chaque
        // (re)build du FutureProvider apres invalidate.
        var calls = 0;
        final container = ProviderContainer(
          overrides: [
            appStartupCatalogueCheckProvider.overrideWith((ref) async {
              calls++;
              return false;
            }),
          ],
        );
        addTearDown(container.dispose);

        await _pumpPage(tester, container: container);

        // 1 build initial du provider (lazy ou pas, le widget ne le watch pas
        // directement, donc on force la lecture explicitement).
        await container.read(appStartupCatalogueCheckProvider.future);
        final callsBefore = calls;

        await tester.tap(find.text('Réessayer'));
        await tester.pump();
        // Apres invalidate, on re-read pour declencher le re-build.
        await container.read(appStartupCatalogueCheckProvider.future);

        expect(calls, greaterThan(callsBefore));
      },
    );
  });
}
