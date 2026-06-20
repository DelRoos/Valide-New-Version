// Story 1.10 — Tests ProfileSettingsPage (3 cas).
//
// (a) compte permanent : section Zone de danger + bouton danger visible
// (b) visiteur Anonymous : message info + CTA "Creer mon compte"
// (c) tap "Supprimer mon compte" -> modale ouverte

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:valide_school/core/firebase/providers.dart';
import 'package:valide_school/features/account/presentation/profile_settings_page.dart';
import 'package:valide_school/l10n/generated/app_localizations.dart';

import '../../../_helpers/fakes.dart';

Future<void> _pumpSettings(
  WidgetTester tester, {
  required bool isAnonymous,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        firebaseAuthProvider.overrideWithValue(
          FakeAuth(isAnonymous: isAnonymous, displayName: 'Fatou Mballa'),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: const ProfileSettingsPage(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ProfileSettingsPage — Story 1.10', () {
    testWidgets(
      '(a) Compte permanent : section "Zone de danger" + bouton "Supprimer mon compte"',
      (tester) async {
        await _pumpSettings(tester, isAnonymous: false);

        expect(find.text('Paramètres'), findsAtLeastNWidgets(1));
        expect(find.text('Mon compte'), findsOneWidget);
        expect(find.text('Zone de danger'), findsOneWidget);
        expect(find.text('Supprimer mon compte'), findsOneWidget);
        // Pas de message visiteur.
        expect(
          find.textContaining('Crée d\'abord un compte permanent'),
          findsNothing,
        );
      },
    );

    testWidgets(
      '(b) Visiteur Anonymous : message info + bouton "Créer mon compte"',
      (tester) async {
        await _pumpSettings(tester, isAnonymous: true);

        expect(
          find.textContaining('Crée d\'abord un compte permanent'),
          findsOneWidget,
        );
        expect(find.text('Créer mon compte'), findsOneWidget);
        // Pas de zone de danger.
        expect(find.text('Zone de danger'), findsNothing);
        expect(find.text('Supprimer mon compte'), findsNothing);
      },
    );

    testWidgets(
      '(c) Tap "Supprimer mon compte" -> modale confirmation ouverte',
      (tester) async {
        await _pumpSettings(tester, isAnonymous: false);

        // Tap sur le bouton danger principal de la page.
        await tester.tap(find.text('Supprimer mon compte'));
        await tester.pumpAndSettle();

        // La modale affiche son titre + body + 2 boutons.
        expect(find.text('Es-tu sûr ?'), findsOneWidget);
        expect(
          find.textContaining('Ton compte sera supprimé dans 7 jours'),
          findsOneWidget,
        );
        // Le bouton de confirmation est dans la modale.
        expect(find.text('Confirmer la suppression'), findsOneWidget);
      },
    );
  });
}
