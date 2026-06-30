// Story A.2 — Golden tests PublicProfilePage.
//
// T15 : 2 snapshots (profil trouvé) :
//   (a) phone portrait  375×812  → goldens/public_profile_page_phone.png
//   (b) tablet portrait 820×1180 → goldens/public_profile_page_tablet.png
//
// Pour (re-)générer :
//   cd mobile_app && flutter test test/features/account/presentation/public_profile_page_goldens_test.dart --update-goldens

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:valide_school/core/catalogue/domain/models.dart';
import 'package:valide_school/core/catalogue/providers.dart';
import 'package:valide_school/features/account/domain/public_profile.dart';
import 'package:valide_school/features/account/presentation/public_profile_page.dart';
import 'package:valide_school/features/onboarding/providers.dart';
import 'package:valide_school/l10n/generated/app_localizations.dart';

const _kProfile = PublicProfile(
  uid: 'uid-fatou-golden',
  displayName: 'Fatou Mballa',
  levelId: 'terminale',
  streamId: 'francophone_terminale_d',
  schoolName: 'Lycée Leclerc',
  subSystem: 'francophone',
);

final _kCatalogue = CatalogueSnapshot(
  filieres: const [],
  niveaux: const [
    Niveau(
      niveauId: 'terminale',
      subSystem: 'francophone',
      name: {'fr': 'Terminale', 'en': 'Grade 13'},
      filiereIds: [],
      isActive: true,
      sortOrder: 0,
    ),
  ],
  series: const [
    Serie(
      serieId: 'francophone_terminale_d',
      subSystem: 'francophone',
      niveauId: 'terminale',
      filiereId: '',
      name: {'fr': 'Série D', 'en': 'Series D'},
      canOptOut: false,
      isActive: true,
      sortOrder: 0,
    ),
  ],
  subjects: const [],
  examTargets: const [],
  derivationRules: const [],
);

Widget _wrap() {
  return ProviderScope(
    overrides: [
      publicProfileProvider.overrideWith(
        (ref, uid) async => const Right(_kProfile),
      ),
      catalogueProvider.overrideWith(
        (ref) async => _kCatalogue,
      ),
    ],
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(1.0),
          ),
          child: child!,
        ),
        home: const PublicProfilePage(uid: 'uid-fatou-golden'),
      ),
    ),
  );
}

void main() {
  group('PublicProfilePage — Story A.2 goldens', () {
    testWidgets('(a) phone portrait 375×812', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/public_profile_page_phone.png'),
      );
    });

    testWidgets('(b) tablet portrait 820×1180', (tester) async {
      tester.view.physicalSize = const Size(820, 1180);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/public_profile_page_tablet.png'),
      );
    });
  });
}
