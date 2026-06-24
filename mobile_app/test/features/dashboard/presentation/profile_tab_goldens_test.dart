// Story A.1 — Golden tests ProfileTabPage (onglet profil authentifié).
//
// T10 : 2 golden snapshots :
//   (a) phone portrait  375×812  → goldens/profile_tab_phone.png
//   (b) tablet portrait 820×1180 → goldens/profile_tab_tablet.png
//
// Pour (re-)générer les goldens :
//   cd mobile_app && flutter test test/features/dashboard/presentation/profile_tab_goldens_test.dart --update-goldens

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:valide_school/core/catalogue/providers.dart';
import 'package:valide_school/core/firebase/providers.dart';
import 'package:valide_school/features/dashboard/presentation/profile_tab_page.dart';
import 'package:valide_school/features/onboarding/domain/sub_system.dart';
import 'package:valide_school/features/onboarding/providers.dart';
import 'package:valide_school/l10n/generated/app_localizations.dart';

import '../../../_helpers/fakes.dart';

final _fakeProfileData = <String, dynamic>{
  'displayName': 'Fatou',
  'phoneNumber': '+237671234567',
  'levelId': null,
  'streamId': null,
  'schoolId': null,
  'schoolName': null,
};

Widget _wrap(Size size) {
  SharedPreferences.setMockInitialValues({});
  return ProviderScope(
    overrides: [
      firebaseAuthProvider.overrideWithValue(
        FakeAuth(isAnonymous: false, displayName: 'Fatou'),
      ),
      currentUserProvider.overrideWith(
        (ref) => Stream.value(
          FakeAuth(isAnonymous: false, displayName: 'Fatou').currentUser,
        ),
      ),
      userProfileRepositoryProvider.overrideWithValue(
        FakeUserProfileRepository(profileData: _fakeProfileData),
      ),
      subSystemNotifierProvider.overrideWith(
        () => _StubSubSystemNotifier(SubSystem.francophone),
      ),
      catalogueProvider.overrideWith(
        (ref) async => throw UnimplementedError('catalogue not needed'),
      ),
    ],
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(1.0),
          ),
          child: child!,
        ),
        home: const Scaffold(body: ProfileTabPage()),
      ),
    ),
  );
}

class _StubSubSystemNotifier extends SubSystemNotifier {
  _StubSubSystemNotifier(this._initial);
  final SubSystem? _initial;
  @override
  SubSystem? build() => _initial;
}

void main() {
  group('ProfileTabPage — Story A.1 goldens', () {
    testWidgets('(a) phone portrait 375×812', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap(const Size(375, 812)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/profile_tab_phone.png'),
      );
    });

    testWidgets('(b) tablet portrait 820×1180', (tester) async {
      tester.view.physicalSize = const Size(820, 1180);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap(const Size(820, 1180)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/profile_tab_tablet.png'),
      );
    });
  });
}
