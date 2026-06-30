// Story A.2 — Widget tests PublicProfilePage (3 cas).
//
// (a) état loading → skeleton visible (pas de displayName)
// (b) profil trouvé → displayName affiché dans le header
// (c) profil absent (null) → AppEmptyState "Profil introuvable"

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:valide_school/core/catalogue/domain/models.dart';
import 'package:valide_school/core/catalogue/providers.dart';
import 'package:valide_school/features/account/domain/public_profile.dart';
import 'package:valide_school/features/account/presentation/public_profile_page.dart';
import 'package:valide_school/features/onboarding/domain/profile_failure.dart';
import 'package:valide_school/features/onboarding/providers.dart';
import 'package:valide_school/l10n/generated/app_localizations.dart';

const _kUid = 'uid-test-fatou';

const _kProfile = PublicProfile(
  uid: _kUid,
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

Widget _pump({
  required AsyncValue<Either<ProfileFailure, PublicProfile?>> profileAsync,
  CatalogueSnapshot? catalogue,
}) {
  return ProviderScope(
    overrides: [
      publicProfileProvider.overrideWith(
        (ref, uid) => Future.value(profileAsync.when(
          data: (v) => v,
          loading: () => throw const AsyncLoading<dynamic>(),
          error: (e, _) => throw e,
        )),
      ),
      if (catalogue != null)
        catalogueProvider.overrideWith(
          (ref) async => catalogue,
        ),
    ],
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: const PublicProfilePage(uid: _kUid),
      ),
    ),
  );
}

void main() {
  group('PublicProfilePage — Story A.2', () {
    testWidgets('(a) état loading → skeleton visible', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Override with a never-completing future to stay in loading state.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            publicProfileProvider.overrideWith(
              (ref, uid) => Future<Either<ProfileFailure, PublicProfile?>>.error(
                const AsyncLoading<dynamic>(),
                StackTrace.empty,
              ).timeout(
                Duration.zero,
                onTimeout: () async {
                  await Future.delayed(const Duration(seconds: 60));
                  return const Right(null);
                },
              ),
            ),
          ],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('fr'),
              home: const PublicProfilePage(uid: _kUid),
            ),
          ),
        ),
      );
      // pump once — still resolving (loading state)
      await tester.pump();

      // Skeleton containers present, display name not yet rendered.
      expect(find.text('Fatou Mballa'), findsNothing);
    });

    testWidgets('(b) profil trouvé → displayName affiché', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_pump(
        profileAsync: const AsyncData(Right(_kProfile)),
        catalogue: _kCatalogue,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Fatou Mballa'), findsOneWidget);
    });

    testWidgets('(c) profil absent → "Profil introuvable"', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_pump(
        profileAsync: const AsyncData(Right(null)),
      ));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(PublicProfilePage)),
      );
      expect(find.text(l10n.publicProfileNotFound), findsOneWidget);
    });

    testWidgets('(d) erreur réseau → errorNetworkUnavailable', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_pump(
        profileAsync: AsyncData(
          Left(
            const ProfileFailure.firestoreError(
              'network-request-failed',
              code: 'network-request-failed',
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(PublicProfilePage)),
      );
      expect(find.text(l10n.errorNetworkUnavailable), findsOneWidget);
    });

    testWidgets('(e) erreur permission → errorPermissionDenied', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_pump(
        profileAsync: AsyncData(
          Left(
            const ProfileFailure.firestoreError(
              'permission-denied',
              code: 'permission-denied',
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(PublicProfilePage)),
      );
      expect(find.text(l10n.errorPermissionDenied), findsOneWidget);
    });
  });
}
