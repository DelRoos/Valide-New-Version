// Story 1.9 AC6 — Widget tests PlaceholderTabPage.
//
// 2 cas :
//   (a) Page rendue avec texte "Bientôt disponible" + AppBar titre
//   (b) Bottom nav 4 destinations visibles (Accueil + Matieres + Activites + Profil)

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:valide_school/features/dashboard/presentation/placeholder_tab_page.dart';
import 'package:valide_school/l10n/generated/app_localizations.dart';

Future<void> _pumpPlaceholder(
  WidgetTester tester, {
  required String title,
  required int tabIndex,
}) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: PlaceholderTabPage(title: title, tabIndex: tabIndex),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('PlaceholderTabPage — Story 1.9 AC6', () {
    testWidgets('(a) Page rendue avec "Bientôt disponible" + titre AppBar',
        (tester) async {
      await _pumpPlaceholder(tester, title: 'Matières', tabIndex: 1);
      // Le titre AppBar + le label d'onglet "Matières" sont 2 widgets.
      expect(find.text('Matières'), findsAtLeastNWidgets(1));
      expect(find.text('Bientôt disponible'), findsOneWidget);
    });

    testWidgets('(b) Page seule sans bottom nav : seul le titre et le body sont rendus',
        (tester) async {
      await _pumpPlaceholder(tester, title: 'Activités', tabIndex: 2);
      // PlaceholderTabPage ne porte plus sa propre NavigationBar depuis E1bis-7
      // (migration vers StatefulShellRoute + MainShell). La nav bar est dans
      // MainShell, testée via widget_test.dart et splash_page_test.dart.
      expect(find.text('Activités'), findsWidgets);
      expect(find.text('Bientôt disponible'), findsOneWidget);
    });
  });
}
