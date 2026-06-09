// Story 1.17 AC4/AC5/AC6/AC7 — Widget tests SubjectsPickerPage mode
// `tve_picker` TVEE (Eyong Eboa TVE AL Electrotechnique artificial).
//
// 5 cas :
//   (a) page rendue : 3 Pro checked+lock (ELET theory/practical/Electrical
//       machines) + 3 Related checked+lock (Math Industrial/Physics/Drawing)
//       + 2 EN/FR checked+lock + 3 Hist/Geo/RS decochees + compteur 8/8
//       primary + Valider activable (8 ∈ [6, 8])
//   (b) tap History -> compteur 9/8 danger + Valider disabled (saturation)
//   (c) tap ELET theory (Pro obligatoire) -> toast warning + reste checked
//       + compteur statu quo 8/8
//   (d) tap EN (Obligatoire Other) -> toast warning + reste checked + statu
//       quo 8/8
//   (e) tap Valider sans cocher d'optionnels -> _FakeRepo.pickedCalls.single
//       == [ELET theory, ELET practical, Electrical machines, Math Industrial,
//          Physics, Drawing, EN, FR] (ordre TVEE Decision 5 figee)
//
// Decision 1 Story 1.17 figee : matrice.json INCHANGEE en prod. DerivedProfile
// fabrique artificiellement avec pickerMode: PickerMode.tvePicker + 3 listes
// Subject NEW Story 1.17.

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
  Future<Either<ProfileFailure, void>> updateSchoolId(String? schoolId) async =>
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

DerivedProfile _eyongProfile() {
  // Eyong TVE AL ELET anglo ARTIFICIAL : pickerMode tvePicker explicite
  // (matrice.json prod = isActive false cf. Decision 1 figee Story 1.17).
  final pro = [
    _subj('anglophone_elet_theory', 'Electrotechnique theorie',
        'Electrotechnique theory',
        icon: 'zap'),
    _subj('anglophone_elet_practical', 'Electrotechnique pratique',
        'Electrotechnique practical',
        icon: 'wrench'),
    _subj('anglophone_electrical_machines', 'Machines electriques',
        'Electrical machines',
        icon: 'cog'),
  ];
  final related = [
    _subj('anglophone_math_industrial', 'Maths industrielles',
        'Mathematics for Industrial',
        icon: 'sigma'),
    _subj('anglophone_physics_tve', 'Physique', 'Physics', icon: 'atom'),
    _subj('anglophone_drawing', 'Dessin technique', 'Drawing',
        icon: 'pencil-ruler'),
  ];
  final oblig = [
    _subj('anglophone_english_lang', 'Anglais', 'English Language',
        icon: 'book-marked'),
    _subj('anglophone_french', 'Francais', 'French', icon: 'languages'),
  ];
  final opt = [
    _subj('anglophone_history', 'Histoire', 'History', icon: 'scroll'),
    _subj('anglophone_geography', 'Geographie', 'Geography',
        icon: 'globe'),
    _subj('anglophone_religious_studies', 'Religion', 'Religious Studies',
        icon: 'scroll-text'),
  ];
  return DerivedProfile(
    subjects: [...pro, ...related, ...oblig, ...opt],
    examTargets: const [],
    canOptOut: false,
    pickerMode: PickerMode.tvePicker,
    obligatorySubjects: oblig,
    optionalSubjects: opt,
    minSubjects: 6,
    maxSubjects: 8,
    professionalSubjects: pro,
    relatedProfessionalSubjects: related,
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
  // Viewport tres large (cf. Stories 1.15+1.16 fix : ScreenUtil scaling).
  await tester.binding.setSurfaceSize(const Size(800, 4000));
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
              filiereId: 'technique',
              niveauId: 'anglophone_tve_al',
              serieId: 'anglophone_tve_al_elet',
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
  group('SubjectsPickerPage — Story 1.17 mode tve_picker', () {
    testWidgets(
      '(a) Page rendue : 3 Pro + 3 Related + 2 EN/FR checked+lock + 3 '
      'Hist/Geo/RS unchecked + compteur 8/8 primary + Valider activable',
      (tester) async {
        final prefs = await _prefsAnglophone();
        await _pumpPicker(tester, prefs: prefs, profile: _eyongProfile());

        expect(find.text('Choose your subjects'), findsOneWidget);

        // 3 Pro presents.
        expect(find.text('Electrotechnique theory'), findsOneWidget);
        expect(find.text('Electrotechnique practical'), findsOneWidget);
        expect(find.text('Electrical machines'), findsOneWidget);

        // 3 Related presents.
        expect(find.text('Mathematics for Industrial'), findsOneWidget);
        expect(find.text('Physics'), findsOneWidget);
        expect(find.text('Drawing'), findsOneWidget);

        // 2 EN/FR Obligatoires Other presents.
        expect(find.text('English Language'), findsOneWidget);
        expect(find.text('French'), findsOneWidget);

        // 3 Au choix presents.
        expect(find.text('History'), findsOneWidget);
        expect(find.text('Geography'), findsOneWidget);
        expect(find.text('Religious Studies'), findsOneWidget);

        // Total 11 CheckboxListTile.
        expect(find.byType(CheckboxListTile), findsNWidgets(11));

        // Compteur live "8/8".
        expect(find.textContaining('8/8'), findsOneWidget);

        // Bouton activable (8 ∈ [6, 8]).
        final btnFinder = find.widgetWithText(AppButton, 'Confirm my choice');
        final AppButton btn = tester.widget(btnFinder);
        expect(btn.onPressed, isNotNull);
      },
    );

    testWidgets(
      '(b) Tap History -> compteur 9/8 danger + Valider disabled',
      (tester) async {
        final prefs = await _prefsAnglophone();
        await _pumpPicker(tester, prefs: prefs, profile: _eyongProfile());

        await tester.ensureVisible(find.text('History'));
        await tester.pump();
        await tester.tap(find.text('History'));
        await tester.pump();

        expect(find.textContaining('9/8'), findsOneWidget);

        final cta = find.widgetWithText(AppButton, 'Confirm my choice');
        await tester.ensureVisible(cta);
        await tester.pump();
        final AppButton btn = tester.widget(cta);
        expect(btn.onPressed, isNull);
      },
    );

    testWidgets(
      '(c) Tap Electrotechnique theory (Pro obligatoire) -> toast warning '
      '+ reste checked',
      (tester) async {
        final prefs = await _prefsAnglophone();
        await _pumpPicker(tester, prefs: prefs, profile: _eyongProfile());

        await tester.tap(find.text('Electrotechnique theory'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          find.text('This subject is mandatory and cannot be removed.'),
          findsOneWidget,
        );

        // Compteur statu quo 8/8.
        expect(find.textContaining('8/8'), findsOneWidget);

        await tester.pumpAndSettle(const Duration(seconds: 5));
      },
    );

    testWidgets(
      '(d) Tap English Language (Obligatoire Other) -> toast warning + '
      'reste checked',
      (tester) async {
        final prefs = await _prefsAnglophone();
        await _pumpPicker(tester, prefs: prefs, profile: _eyongProfile());

        await tester.ensureVisible(find.text('English Language'));
        await tester.pump();
        await tester.tap(find.text('English Language'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          find.text('This subject is mandatory and cannot be removed.'),
          findsOneWidget,
        );

        expect(find.textContaining('8/8'), findsOneWidget);

        await tester.pumpAndSettle(const Duration(seconds: 5));
      },
    );

    testWidgets(
      '(e) Tap Valider sans optionnels -> persiste [Pro, Related, EN, FR] '
      'ordre TVEE Decision 5',
      (tester) async {
        final prefs = await _prefsAnglophone();
        final repo = await _pumpPicker(
          tester,
          prefs: prefs,
          profile: _eyongProfile(),
        );

        final cta = find.widgetWithText(AppButton, 'Confirm my choice');
        await tester.ensureVisible(cta);
        await tester.pump();
        await tester.tap(cta);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(repo.pickedCalls.length, 1);
        expect(repo.pickedCalls.single, [
          // Pro first
          'anglophone_elet_theory',
          'anglophone_elet_practical',
          'anglophone_electrical_machines',
          // Related second
          'anglophone_math_industrial',
          'anglophone_physics_tve',
          'anglophone_drawing',
          // Obligatoires Other EN+FR third
          'anglophone_english_lang',
          'anglophone_french',
          // Pas d'au-choix selectionnes (test e nominal)
        ]);
      },
    );
  });
}
