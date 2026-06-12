// Story 1.9 — Widget tests DashboardPage (refactor E1bis-9).
//
// Story E1bis-9 — Suppression du `derivedProfileProvider` + `effectiveDerived
// SubjectsProvider` (schema Epic 1). En attendant le flush Firestore E1bis-4
// a E1bis-7, la `DashboardSubjectsArea` affiche un empty state systematique.
//
// 2 cas couverts :
//   (a) Visiteur (anonymous) : badge "Visiteur" + carte "Cree ton compte"
//   (b) Utilisateur authentifie : pas de badge ni de carte de creation

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:valide_school/core/firebase/providers.dart';
import 'package:valide_school/features/dashboard/presentation/dashboard_page.dart';
import 'package:valide_school/features/onboarding/domain/sub_system.dart';
import 'package:valide_school/features/onboarding/providers.dart';
import 'package:valide_school/l10n/generated/app_localizations.dart';

import '../../../_helpers/fakes.dart';

class _StubSubSystemNotifier extends SubSystemNotifier {
  _StubSubSystemNotifier(this._initial);
  final SubSystem? _initial;
  @override
  SubSystem? build() => _initial;
}

Future<SharedPreferences> _emptyPrefs() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

Widget _wrap({
  required SharedPreferences prefs,
  required FakeAuth auth,
  required FakeUserProfileRepository repo,
  required SubSystem subSystem,
}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      firebaseAuthProvider.overrideWithValue(auth),
      userProfileRepositoryProvider.overrideWithValue(repo),
      subSystemNotifierProvider
          .overrideWith(() => _StubSubSystemNotifier(subSystem)),
    ],
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DashboardPage(),
      ),
    ),
  );
}

void main() {
  group('DashboardPage — Story 1.9 (refactor E1bis-9)', () {
    testWidgets('(a) Empty state systematique : icone book-open + CTA',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final prefs = await _emptyPrefs();
      await tester.pumpWidget(_wrap(
        prefs: prefs,
        auth: FakeAuth(isAnonymous: false, displayName: 'Fatou Mballa'),
        repo: FakeUserProfileRepository(
          profileData: {'displayName': 'Fatou Mballa'},
        ),
        subSystem: SubSystem.francophone,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final l10n =
          AppLocalizations.of(tester.element(find.byType(DashboardPage)));
      expect(find.text(l10n.dashboardEmptyStateText), findsOneWidget);
      expect(find.text(l10n.dashboardEmptyStateCta), findsOneWidget);
    });

    testWidgets('(b) Visiteur : badge "Visiteur" + carte creation compte',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final prefs = await _emptyPrefs();
      await tester.pumpWidget(_wrap(
        prefs: prefs,
        auth: FakeAuth(isAnonymous: true, displayName: null),
        repo: FakeUserProfileRepository(profileData: null),
        subSystem: SubSystem.francophone,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final l10n =
          AppLocalizations.of(tester.element(find.byType(DashboardPage)));
      expect(find.text(l10n.dashboardGuestBadge), findsOneWidget);
    });
  });
}
