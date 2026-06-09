// Story 1.15 AC2/AC3 — Widget tests SubjectsPickerPage mode
// `free_with_obligatory` (Mariam Form 5 anglo panier O-Level).
//
// 4 cas :
//   (a) page rendue : 3 obligatoires (EN+FR+Math) checked+lock + 8 optionnels
//       decoches + compteur "3/11" + bouton Valider disabled (3 < min 6)
//   (b) tap 3 optionnels (Phy, Chem, Bio) -> compteur "6/11", bouton Valider
//       active (6 in [6, 11])
//   (c) tap obligatoire (English) -> toast warning visible + obligatoire reste
//       checked + bouton Valider statu quo
//   (d) tap Valider avec 5 optionnels (8/11) -> _FakeRepo.updatePickedCalls
//       contient [EN, FR, Math, Phy, Chem, Bio, Geo, Hist] (oblig d'abord)

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

DerivedProfile _mariamProfile() {
  // Mariam Form 5 anglo : 3 obligatoires + 8 optionnels = 11 max.
  final obligatory = [
    _subj('anglophone_english_lang', 'Anglais', 'English Language'),
    _subj('anglophone_french', 'Francais', 'French'),
    _subj('anglophone_math', 'Mathematiques', 'Mathematics'),
  ];
  final optional = [
    _subj('anglophone_physics', 'Physique', 'Physics'),
    _subj('anglophone_chemistry', 'Chimie', 'Chemistry'),
    _subj('anglophone_biology', 'Biologie', 'Biology'),
    _subj('anglophone_geography', 'Geographie', 'Geography'),
    _subj('anglophone_history', 'Histoire', 'History'),
    _subj('anglophone_citizenship', 'Citoyennete', 'Citizenship'),
    _subj('anglophone_computer_science', 'Informatique', 'Computer Science'),
    _subj('anglophone_religion', 'Religion', 'Religious Studies'),
  ];
  return DerivedProfile(
    subjects: [...obligatory, ...optional],
    examTargets: const [],
    canOptOut: false,
    pickerMode: PickerMode.freeWithObligatory,
    obligatorySubjects: obligatory,
    optionalSubjects: optional,
    minSubjects: 6,
    maxSubjects: 11,
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
  // Viewport TRES large pour eviter offscreen apres ScreenUtil scaling
  // (surface haute -> scale .h/.sp x ratio surface/design 812 -> tout
  // s'agrandit, le bouton Valider final reste hors viewport en 1800px).
  await tester.binding.setSurfaceSize(const Size(800, 3000));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final repo = _FakeRepo(initialPicked: initialPicked);
  // GoRouter minimal pour les `GoRouter.of(context).go(...)` post-save
  // (route picker initiale + recap minimale).
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
              niveauId: 'anglophone_form_5',
              serieId: '-',
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
  group('SubjectsPickerPage — Story 1.15 mode free_with_obligatory', () {
    testWidgets(
      '(a) Page rendue : 3 obligatoires checked + 8 optionnels uncheched + '
      'compteur 3/11 + Valider disabled',
      (tester) async {
        final prefs = await _prefsAnglophone();
        await _pumpPicker(tester, prefs: prefs, profile: _mariamProfile());

        // Titre + sous-titre.
        expect(find.text('Choose your subjects'), findsOneWidget);

        // 3 obligatoires presents.
        expect(find.text('English Language'), findsOneWidget);
        expect(find.text('French'), findsOneWidget);
        expect(find.text('Mathematics'), findsOneWidget);

        // 8 optionnels presents (verifions 3 representatifs).
        expect(find.text('Physics'), findsOneWidget);
        expect(find.text('Chemistry'), findsOneWidget);
        expect(find.text('Religious Studies'), findsOneWidget);

        // Total 11 CheckboxListTile.
        expect(find.byType(CheckboxListTile), findsNWidgets(11));

        // Compteur live "3/11".
        expect(find.textContaining('3/11'), findsOneWidget);

        // Bouton "Confirm my choice" disabled car 3 < min 6.
        final btnFinder = find.widgetWithText(AppButton, 'Confirm my choice');
        expect(btnFinder, findsOneWidget);
        final AppButton btn = tester.widget(btnFinder);
        expect(btn.onPressed, isNull);
      },
    );

    testWidgets(
      '(b) Tap Physics+Chemistry+Biology -> compteur 6/11 + Valider active',
      (tester) async {
        final prefs = await _prefsAnglophone();
        await _pumpPicker(tester, prefs: prefs, profile: _mariamProfile());

        await tester.tap(find.text('Physics'));
        await tester.pump();
        await tester.tap(find.text('Chemistry'));
        await tester.pump();
        await tester.tap(find.text('Biology'));
        await tester.pump();

        expect(find.textContaining('6/11'), findsOneWidget);

        final btnFinder = find.widgetWithText(AppButton, 'Confirm my choice');
        final AppButton btn = tester.widget(btnFinder);
        expect(btn.onPressed, isNotNull);
      },
    );

    testWidgets(
      '(c) Tap obligatoire English -> toast warning + reste checked',
      (tester) async {
        final prefs = await _prefsAnglophone();
        await _pumpPicker(tester, prefs: prefs, profile: _mariamProfile());

        // Tap sur le titre obligatoire.
        await tester.tap(find.text('English Language'));
        await tester.pump(); // toast en cours d'animation
        await tester.pump(const Duration(milliseconds: 100));

        // Toast warning visible (AppToast affiche le SnackBar/overlay avec
        // ce texte).
        expect(
          find.text('This subject is mandatory and cannot be removed.'),
          findsOneWidget,
        );

        // Compteur statu quo 3/11 (rien n'a change).
        expect(find.textContaining('3/11'), findsOneWidget);

        // pumpAndSettle pour laisser le toast s'auto-dismiss et eviter
        // "Timer is still pending" warning au teardown.
        await tester.pumpAndSettle(const Duration(seconds: 5));
      },
    );

    testWidgets(
      '(d) Tap Valider avec 5 optionnels -> updatePickedSubjects appele avec '
      '[EN, FR, Math, Phy, Chem, Bio, Geo, Hist]',
      (tester) async {
        final prefs = await _prefsAnglophone();
        final repo = await _pumpPicker(
          tester,
          prefs: prefs,
          profile: _mariamProfile(),
        );

        // Tap 5 optionnels. Geography + History peuvent etre offscreen meme
        // avec viewport 1800px -> ensureVisible (scrolle le ListView parent).
        for (final label in [
          'Physics',
          'Chemistry',
          'Biology',
          'Geography',
          'History',
        ]) {
          await tester.ensureVisible(find.text(label));
          await tester.pump();
          await tester.tap(find.text(label));
          await tester.pump();
        }

        // Compteur 8/11.
        expect(find.textContaining('8/11'), findsOneWidget);

        // Tap Valider (peut etre offscreen apres scroll des optionnels).
        final cta = find.widgetWithText(AppButton, 'Confirm my choice');
        await tester.ensureVisible(cta);
        await tester.pump();
        await tester.tap(cta);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Repo appele avec liste oblig+optionnels (8 elements, oblig d'abord).
        expect(repo.pickedCalls.length, 1);
        expect(repo.pickedCalls.single, [
          'anglophone_english_lang',
          'anglophone_french',
          'anglophone_math',
          'anglophone_physics',
          'anglophone_chemistry',
          'anglophone_biology',
          'anglophone_geography',
          'anglophone_history',
        ]);
      },
    );
  });
}
