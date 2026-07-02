// Story A.1 — Tests widget NameEditSheet (remplace ProfileEditSheet supprimé).
//
// Cas couverts :
// (a) Champ displayName pré-rempli avec valeur initiale
// (b) Validation : nom trop court (< 2 chars) → message d'erreur inline
// (c) Succès : nom valide → updateDisplayName() appelé → toast "Profil mis à jour."

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:valide_school/features/account/domain/public_profile.dart';
import 'package:valide_school/features/onboarding/domain/profile_failure.dart';
import 'package:valide_school/features/onboarding/domain/school.dart';
import 'package:valide_school/features/onboarding/domain/sub_system.dart';
import 'package:valide_school/features/onboarding/domain/user_profile_repository.dart';
import 'package:valide_school/features/onboarding/providers.dart';
import 'package:valide_school/features/dashboard/presentation/widgets/name_edit_sheet.dart';
import 'package:valide_school/l10n/generated/app_localizations.dart';

class _TrackingRepo implements UserProfileRepository {
  String? lastDisplayName;
  String? lastPhoneNumber;
  bool failNext = false;

  @override
  Future<Either<ProfileFailure, void>> updateDisplayName(String name) async {
    lastDisplayName = name;
    return failNext ? const Left(ProfileFailure.firestoreError('err')) : const Right(null);
  }

  @override
  Future<Either<ProfileFailure, void>> updatePhoneNumber(String? phone) async {
    lastPhoneNumber = phone;
    return failNext ? const Left(ProfileFailure.firestoreError('err')) : const Right(null);
  }

  @override
  Future<Either<ProfileFailure, void>> createProfile({
    required SubSystem subSystem,
    required String filiereId,
    required String niveauId,
    required String serieId,
    required List<String> derivedSubjects,
    required List<String> examTargets,
  }) async => const Right(null);

  @override
  Stream<Map<String, dynamic>?> watchProfile() => Stream.value(null);

  @override
  Future<Either<ProfileFailure, void>> updateOptedOutSubjects(List<String> ids) async => const Right(null);

  @override
  Future<Either<ProfileFailure, void>> updatePickedSubjects(List<String> ids) async => const Right(null);

  @override
  Future<Either<ProfileFailure, void>> updateLinkedSchool(School? school) async => const Right(null);

  @override
  Future<Either<ProfileFailure, void>> updateSchoolProfile({
    required String trackId,
    required String levelId,
    required String streamId,
    required List<String> derivedSubjects,
    required List<String> examTargets,
    required List<String> pickedSubjects,
    required List<String> optedOutSubjects,
  }) async =>
      const Right(null);

  @override
  Future<Either<ProfileFailure, Map<String, dynamic>?>> fetchProfileOnce() async => const Right(null);

  @override
  Future<Either<ProfileFailure, PublicProfile?>> fetchPublicProfile(
    String uid,
  ) async =>
      const Right(null);
}

Future<void> _pumpSheet(
  WidgetTester tester, {
  required _TrackingRepo repo,
  String displayName = 'Fatou',
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userProfileRepositoryProvider.overrideWithValue(repo),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Scaffold(
            body: NameEditSheet(initialDisplayName: displayName),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('NameEditSheet — Story A.1', () {
    testWidgets(
      '(a) Champ displayName pré-rempli avec la valeur initiale',
      (tester) async {
        final repo = _TrackingRepo();
        await _pumpSheet(tester, repo: repo, displayName: 'Amina');

        expect(
          find.widgetWithText(TextField, 'Amina'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '(b) Nom trop court (1 char) → message d\'erreur inline',
      (tester) async {
        final repo = _TrackingRepo();
        await _pumpSheet(tester, repo: repo, displayName: 'A');

        await tester.tap(find.text('Enregistrer'));
        await tester.pumpAndSettle();

        expect(find.text('Au moins 2 caracteres.'), findsOneWidget);
        expect(repo.lastDisplayName, isNull);
      },
    );

    testWidgets(
      '(c) Nom valide → updateDisplayName() appelé avec le nom saisi',
      (tester) async {
        final repo = _TrackingRepo();
        await _pumpSheet(tester, repo: repo, displayName: '');

        await tester.enterText(find.byType(TextField).first, 'Paul');
        await tester.tap(find.text('Enregistrer'));
        // Drainer les microtasks de _onSave() (await repo.updateDisplayName)
        await tester.pump();
        await tester.pump();
        // Drainer le timer AppToast (hold = 4s + slide = 200ms)
        await tester.pump(const Duration(seconds: 5));

        expect(repo.lastDisplayName, 'Paul');
      },
    );
  });
}
