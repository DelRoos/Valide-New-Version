// Story 1.4 AC2/AC7 — Widget tests SubjectsOptOutPage.
//
// 3 cas :
//   (a) page rendue avec 3 checkboxes initialement cochees (toutes incluses)
//   (b) decoche 1 matiere -> compteur ICU "Tu presentes 2 matieres sur 3"
//   (c) decoche TOUTES les matieres -> bouton "Valider" disabled

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:valide_school/core/catalogue/domain/models.dart';
import 'package:valide_school/core/catalogue/providers.dart';
import 'package:valide_school/core/widgets/app_button.dart';
import 'package:valide_school/features/onboarding/domain/onboarding_flow_state.dart';
import 'package:valide_school/features/onboarding/domain/profile_failure.dart';
import 'package:valide_school/features/onboarding/domain/sub_system.dart';
import 'package:valide_school/features/onboarding/domain/user_profile_repository.dart';
import 'package:valide_school/features/onboarding/presentation/subjects_opt_out_page.dart';
import 'package:valide_school/features/onboarding/providers.dart';
import 'package:valide_school/l10n/generated/app_localizations.dart';

class _FakeRepo implements UserProfileRepository {
  _FakeRepo({List<String> initialOptedOut = const []})
      : _data = <String, dynamic>{'optedOutSubjects': initialOptedOut};
  final Map<String, dynamic> _data;

  @override
  Stream<Map<String, dynamic>?> watchProfile() => Stream.value(_data);

  @override
  Future<Either<ProfileFailure, void>> createProfile({
    required SubSystem subSystem,
    required String filiereId,
    required String niveauId,
    required String serieId,
    required List<String> derivedSubjects,
    required List<String> examTargets,
  }) async =>
      const Right(null);

  @override
  Future<Either<ProfileFailure, void>> updateOptedOutSubjects(
    List<String> optedOutSubjectIds,
  ) async =>
      const Right(null);

  @override
  Future<Either<ProfileFailure, void>> updateSchoolId(String? schoolId) async =>
      const Right(null);
}

class _PreloadedFlow extends OnboardingFlowNotifier {
  _PreloadedFlow(this._initial);
  final OnboardingFlowState _initial;
  @override
  OnboardingFlowState build() => _initial;
}

DerivedProfile _jamesProfile() {
  return DerivedProfile(
    subjects: const [
      Subject(
        subjectId: 'anglophone_chemistry',
        subSystem: 'anglophone',
        name: {'fr': 'Chimie', 'en': 'Chemistry'},
        icon: 'flask-conical',
        isActive: true,
        sortOrder: 10,
      ),
      Subject(
        subjectId: 'anglophone_physics',
        subSystem: 'anglophone',
        name: {'fr': 'Physique', 'en': 'Physics'},
        icon: 'atom',
        isActive: true,
        sortOrder: 20,
      ),
      Subject(
        subjectId: 'anglophone_biology',
        subSystem: 'anglophone',
        name: {'fr': 'Biologie', 'en': 'Biology'},
        icon: 'dna',
        isActive: true,
        sortOrder: 30,
      ),
    ],
    examTargets: const [],
    canOptOut: true,
  );
}

Future<SharedPreferences> _prefsAnglophone() async {
  SharedPreferences.setMockInitialValues({
    'onboarding.subsystem': 'anglophone',
    'onboarding.language': 'en',
  });
  return SharedPreferences.getInstance();
}

Future<void> _pumpOptOut(
  WidgetTester tester, {
  required SharedPreferences prefs,
  required DerivedProfile profile,
  List<String> initialOptedOut = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appStartupCatalogueCheckProvider.overrideWith((ref) async => true),
        derivedProfileProvider.overrideWith((ref) async => Right(profile)),
        userProfileRepositoryProvider.overrideWithValue(
          _FakeRepo(initialOptedOut: initialOptedOut),
        ),
        onboardingFlowProvider.overrideWith(
          () => _PreloadedFlow(
            const OnboardingFlowState(
              filiereId: 'generale',
              niveauId: 'anglophone_upper_sixth',
              serieId: 'anglophone_upper_sixth_s2',
            ),
          ),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const SubjectsOptOutPage(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('SubjectsOptOutPage — Story 1.4', () {
    testWidgets(
      '(a) Page rendue : 3 checkboxes cochees + compteur "3 of 3 subjects"',
      (tester) async {
        final prefs = await _prefsAnglophone();
        await _pumpOptOut(tester, prefs: prefs, profile: _jamesProfile());

        expect(find.text('Pick your subjects'), findsOneWidget);
        expect(find.text('Chemistry'), findsOneWidget);
        expect(find.text('Physics'), findsOneWidget);
        expect(find.text('Biology'), findsOneWidget);
        // 3 CheckboxListTile, toutes cochees.
        final checkboxes = find.byType(CheckboxListTile);
        expect(checkboxes, findsNWidgets(3));
        // Compteur ICU.
        expect(find.textContaining("3 of 3"), findsOneWidget);
      },
    );

    testWidgets(
      '(b) Decoche Biology -> compteur "2 of 3 subjects"',
      (tester) async {
        final prefs = await _prefsAnglophone();
        await _pumpOptOut(tester, prefs: prefs, profile: _jamesProfile());

        // Tap sur la checkbox de Biology (3eme matiere).
        await tester.tap(find.text('Biology'));
        await tester.pump();

        expect(find.textContaining("2 of 3"), findsOneWidget);
      },
    );

    testWidgets(
      '(c) Decoche tout -> bouton Save disabled',
      (tester) async {
        final prefs = await _prefsAnglophone();
        await _pumpOptOut(
          tester,
          prefs: prefs,
          profile: _jamesProfile(),
          initialOptedOut: const [
            'anglophone_chemistry',
            'anglophone_physics',
            'anglophone_biology',
          ],
        );

        // Compteur 0 of 3.
        expect(find.textContaining("0 of 3"), findsOneWidget);
        // Bouton Save disabled : AppButton.onPressed == null.
        final saveButton = find.widgetWithText(AppButton, 'Save');
        expect(saveButton, findsOneWidget);
        final AppButton btn = tester.widget(saveButton);
        expect(btn.onPressed, isNull);
      },
    );
  });
}
