// Story 1.16 AC2/AC3/AC4/AC5 — Widget tests SubjectsPickerPage mode
// `series_plus_optional` A-Level (James Upper Sixth S2 + ICT artificial).
//
// 5 cas :
//   (a) page rendue : 3 Series checked+lock (Chem/Phy/Bio) + 4 transversales
//       decochees (CS/ICT/RS/Com) + compteur 3/5 primary + Valider active
//       (3 ∈ [3, 5])
//   (b) tap ICT -> compteur 4/5 primary + Valider active
//   (c) tap CS + ICT + RS (3 transversales) -> compteur 6/5 danger + Valider
//       disabled (max 5 saturated)
//   (d) tap Chemistry (Series obligatoire) -> toast warning visible +
//       Chemistry reste checked + compteur statu quo 3/5
//   (e) tap ICT puis Valider -> _FakeRepo.updatePickedSubjectsCalls contient
//       [Chemistry, Physics, Biology, ICT] (Series d'abord, transversales
//       selectionnees ensuite)
//
// Decision 1 Story 1.16 figee : matrice.json INCHANGEE en prod. DerivedProfile
// fabrique artificiellement avec pickerMode: PickerMode.seriesPlusOptional
// explicite (sinon default derived -> redirect recap).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:valide_school/core/catalogue/domain/models.dart';
import 'package:valide_school/core/catalogue/providers.dart';
import 'package:valide_school/core/widgets/app_button.dart';
import 'package:valide_school/features/onboarding/domain/onboarding_flow_state.dart';
import 'package:valide_school/features/onboarding/domain/profile_failure.dart';
import 'package:valide_school/features/onboarding/domain/school.dart';
import 'package:valide_school/features/onboarding/domain/sub_system.dart';
import 'package:valide_school/features/onboarding/domain/user_profile_repository.dart';
import 'package:valide_school/features/onboarding/presentation/subjects_picker_page.dart';
import 'package:valide_school/features/onboarding/providers.dart';
import 'package:valide_school/l10n/generated/app_localizations.dart';

class _FakeRepo implements UserProfileRepository {
  _FakeRepo({List<String> initialPicked = const []})
      : _data = <String, dynamic>{
          'optedOutSubjects': <String>[],
          'pickedSubjects': initialPicked,
        };
  final Map<String, dynamic> _data;
  final List<List<String>> pickedCalls = [];

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
  Future<Either<ProfileFailure, void>> updatePickedSubjects(
    List<String> pickedSubjectIds,
  ) async {
    pickedCalls.add(List<String>.from(pickedSubjectIds));
    return const Right(null);
  }

  @override
  Future<Either<ProfileFailure, void>> updateLinkedSchool(School? school) async =>
      const Right(null);
}

class _PreloadedFlow extends OnboardingFlowNotifier {
  _PreloadedFlow(this._initial);
  final OnboardingFlowState _initial;
  @override
  OnboardingFlowState build() => _initial;
}

Subject _subj(String id, String fr, String en, {String icon = 'book-open'}) {
  return Subject(
    subjectId: id,
    subSystem: 'anglophone',
    name: {'fr': fr, 'en': en},
    icon: icon,
    isActive: true,
    sortOrder: 10,
  );
}

DerivedProfile _jamesProfile() {
  // James Upper Sixth S2 anglo ARTIFICIAL : pickerMode seriesPlusOptional
  // explicite (matrice.json prod = opt_out cf. Decision 1 figee Story 1.16).
  final series = [
    _subj('anglophone_chemistry', 'Chimie', 'Chemistry',
        icon: 'flask-conical'),
    _subj('anglophone_physics', 'Physique', 'Physics', icon: 'atom'),
    _subj('anglophone_biology', 'Biologie', 'Biology', icon: 'dna'),
  ];
  final transversales = [
    _subj('anglophone_computer_science', 'Informatique', 'Computer Science',
        icon: 'cpu'),
    _subj('anglophone_ict', 'TIC', 'ICT', icon: 'laptop'),
    _subj('anglophone_religious_studies', 'Religion', 'Religious Studies',
        icon: 'scroll-text'),
    _subj('anglophone_commerce', 'Commerce', 'Commerce', icon: 'briefcase'),
  ];
  return DerivedProfile(
    subjects: [...series, ...transversales],
    examTargets: const [],
    canOptOut: false,
    pickerMode: PickerMode.seriesPlusOptional,
    obligatorySubjects: series,
    optionalSubjects: transversales,
    minSubjects: 3,
    maxSubjects: 5,
  );
}

Future<SharedPreferences> _prefsAnglophone() async {
  SharedPreferences.setMockInitialValues({
    'onboarding.subsystem': 'anglophone',
    'onboarding.language': 'en',
  });
  return SharedPreferences.getInstance();
}

Future<_FakeRepo> _pumpPicker(
  WidgetTester tester, {
  required SharedPreferences prefs,
  required DerivedProfile profile,
  List<String> initialPicked = const [],
}) async {
  // Viewport tres large (cf. Story 1.15 fix : ScreenUtil scaling).
  await tester.binding.setSurfaceSize(const Size(800, 3000));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final repo = _FakeRepo(initialPicked: initialPicked);
  final router = GoRouter(
    initialLocation: '/onboarding/profile/picker',
    routes: [
      GoRoute(
        path: '/onboarding/profile/picker',
        builder: (context, state) => const SubjectsPickerPage(),
      ),
      GoRoute(
        path: '/onboarding/profile/recap',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('RECAP_STUB'))),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appStartupCatalogueCheckProvider.overrideWith((ref) async => true),
        derivedProfileProvider.overrideWith((ref) async => Right(profile)),
        userProfileRepositoryProvider.overrideWithValue(repo),
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
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          routerConfig: router,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  group('SubjectsPickerPage — Story 1.16 mode series_plus_optional', () {
    testWidgets(
      '(a) Page rendue : 3 Series checked+lock + 4 transversales unchecked '
      '+ compteur 3/5 + Valider active',
      (tester) async {
        final prefs = await _prefsAnglophone();
        await _pumpPicker(tester, prefs: prefs, profile: _jamesProfile());

        expect(find.text('Choose your subjects'), findsOneWidget);

        // 3 Series obligatoires presents.
        expect(find.text('Chemistry'), findsOneWidget);
        expect(find.text('Physics'), findsOneWidget);
        expect(find.text('Biology'), findsOneWidget);

        // 4 transversales optionnelles presentes.
        expect(find.text('Computer Science'), findsOneWidget);
        expect(find.text('ICT'), findsOneWidget);
        expect(find.text('Religious Studies'), findsOneWidget);
        expect(find.text('Commerce'), findsOneWidget);

        // Total 7 CheckboxListTile.
        expect(find.byType(CheckboxListTile), findsNWidgets(7));

        // Compteur live "3/5".
        expect(find.textContaining('3/5'), findsOneWidget);

        // Bouton "Confirm my choice" active car 3 ∈ [3, 5].
        final btnFinder = find.widgetWithText(AppButton, 'Confirm my choice');
        expect(btnFinder, findsOneWidget);
        final AppButton btn = tester.widget(btnFinder);
        expect(btn.onPressed, isNotNull);
      },
    );

    testWidgets(
      '(b) Tap ICT -> compteur 4/5 + Valider active',
      (tester) async {
        final prefs = await _prefsAnglophone();
        await _pumpPicker(tester, prefs: prefs, profile: _jamesProfile());

        await tester.tap(find.text('ICT'));
        await tester.pump();

        expect(find.textContaining('4/5'), findsOneWidget);

        final btnFinder = find.widgetWithText(AppButton, 'Confirm my choice');
        final AppButton btn = tester.widget(btnFinder);
        expect(btn.onPressed, isNotNull);
      },
    );

    testWidgets(
      '(c) Tap 3 transversales (CS+ICT+RS) -> compteur 6/5 danger + Valider '
      'disabled (max 5 saturated)',
      (tester) async {
        final prefs = await _prefsAnglophone();
        await _pumpPicker(tester, prefs: prefs, profile: _jamesProfile());

        for (final label in ['Computer Science', 'ICT', 'Religious Studies']) {
          await tester.ensureVisible(find.text(label));
          await tester.pump();
          await tester.tap(find.text(label));
          await tester.pump();
        }

        expect(find.textContaining('6/5'), findsOneWidget);

        final cta = find.widgetWithText(AppButton, 'Confirm my choice');
        await tester.ensureVisible(cta);
        await tester.pump();
        final AppButton btn = tester.widget(cta);
        expect(btn.onPressed, isNull);
      },
    );

    testWidgets(
      '(d) Tap Chemistry (Series obligatoire) -> toast warning + Chemistry '
      'reste checked',
      (tester) async {
        final prefs = await _prefsAnglophone();
        await _pumpPicker(tester, prefs: prefs, profile: _jamesProfile());

        await tester.tap(find.text('Chemistry'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          find.text('This subject is mandatory and cannot be removed.'),
          findsOneWidget,
        );

        // Compteur statu quo 3/5 (rien n'a change).
        expect(find.textContaining('3/5'), findsOneWidget);

        // pumpAndSettle pour AppToast auto-dismiss (cf. Story 1.15 fix).
        await tester.pumpAndSettle(const Duration(seconds: 5));
      },
    );

    testWidgets(
      '(e) Tap ICT + Valider -> updatePickedSubjects appele avec '
      '[Chemistry, Physics, Biology, ICT] (Series d ordre fixe)',
      (tester) async {
        final prefs = await _prefsAnglophone();
        final repo = await _pumpPicker(
          tester,
          prefs: prefs,
          profile: _jamesProfile(),
        );

        await tester.ensureVisible(find.text('ICT'));
        await tester.pump();
        await tester.tap(find.text('ICT'));
        await tester.pump();

        expect(find.textContaining('4/5'), findsOneWidget);

        final cta = find.widgetWithText(AppButton, 'Confirm my choice');
        await tester.ensureVisible(cta);
        await tester.pump();
        await tester.tap(cta);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Repo appele avec liste Series+optionnels (4 elements, Series d'abord
        // dans l'ordre des obligatorySubjects, transversales selectionnees
        // ensuite).
        expect(repo.pickedCalls.length, 1);
        expect(repo.pickedCalls.single, [
          'anglophone_chemistry',
          'anglophone_physics',
          'anglophone_biology',
          'anglophone_ict',
        ]);
      },
    );
  });
}
