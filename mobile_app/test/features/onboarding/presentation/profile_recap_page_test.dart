// Story 1.3 — Widget tests ProfileRecapPage.
//
// Tests d'integration page : derivedProfileProvider override avec fake data,
// verifie le rendu (bandeau exam + grille matieres + boutons + lien opt-out)
// + le cas erreur noMatchingRule.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:valide_school/core/catalogue/domain/catalogue_failure.dart';
import 'package:valide_school/core/catalogue/domain/models.dart';
import 'package:valide_school/core/catalogue/providers.dart';
import 'package:valide_school/features/onboarding/domain/onboarding_flow_state.dart';
import 'package:valide_school/features/onboarding/domain/profile_failure.dart';
import 'package:valide_school/features/onboarding/domain/school.dart';
import 'package:valide_school/features/onboarding/domain/sub_system.dart';
import 'package:valide_school/features/onboarding/domain/user_profile_repository.dart';
import 'package:valide_school/features/onboarding/presentation/profile_recap_page.dart';
import 'package:valide_school/features/onboarding/providers.dart';
import 'package:valide_school/l10n/generated/app_localizations.dart';

/// Fake repo : retourne un stream sur users/{uid}.optedOutSubjects.
class _FakeRepo implements UserProfileRepository {
  _FakeRepo({List<String> optedOut = const []})
      : _data = <String, dynamic>{'optedOutSubjects': optedOut};
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
  Future<Either<ProfileFailure, void>> updatePickedSubjects(
    List<String> pickedSubjectIds,
  ) async =>
      const Right(null);

  @override
  Future<Either<ProfileFailure, void>> updateLinkedSchool(School? school) async =>
      const Right(null);
}

DerivedProfile _fatouProfile() {
  return DerivedProfile(
    subjects: const [
      Subject(
        subjectId: 'francophone_math',
        subSystem: 'francophone',
        name: {'fr': 'Mathématiques', 'en': 'Mathematics'},
        icon: 'function-square',
        isActive: true,
        sortOrder: 10,
      ),
      Subject(
        subjectId: 'francophone_pct',
        subSystem: 'francophone',
        name: {'fr': 'PCT', 'en': 'PCT'},
        icon: 'atom',
        isActive: true,
        sortOrder: 20,
      ),
    ],
    examTargets: const [
      ExamTarget(
        examTargetId: 'exam_bac_francophone_d',
        subSystem: 'francophone',
        name: {'fr': 'BAC D', 'en': 'BAC D'},
        isActive: true,
        sortOrder: 80,
      ),
    ],
    canOptOut: false,
  );
}

/// James : anglophone Upper Sixth S2 — canOptOut = true.
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

Future<SharedPreferences> _preparePrefs() async {
  SharedPreferences.setMockInitialValues({
    'onboarding.subsystem': 'francophone',
    'onboarding.language': 'fr',
  });
  return SharedPreferences.getInstance();
}

Future<void> _pumpRecapPage(
  WidgetTester tester, {
  required SharedPreferences prefs,
  required AsyncValue<Either<CatalogueFailure, DerivedProfile>> derivedAsync,
  List<String> optedOutSubjects = const [],
  OnboardingFlowState flowState = const OnboardingFlowState(
    filiereId: 'generale',
    niveauId: 'francophone_terminale',
    serieId: 'francophone_terminale_d',
  ),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appStartupCatalogueCheckProvider.overrideWith((ref) async => true),
        derivedProfileProvider.overrideWith((ref) => switch (derivedAsync) {
              AsyncData(value: final v) => v,
              AsyncError(error: final e) => throw e,
              _ => Future.delayed(const Duration(seconds: 10), () {
                  throw StateError('loading not handled in test');
                }),
            }),
        // Story 1.4 — override userProfileRepository pour eviter
        // FirebaseAuth.instance / FirebaseFirestore.instance (non-init en test).
        userProfileRepositoryProvider
            .overrideWithValue(_FakeRepo(optedOut: optedOutSubjects)),
        onboardingFlowProvider
            .overrideWith(() => _PreloadedOnboardingFlow(flowState)),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: const ProfileRecapPage(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _PreloadedOnboardingFlow extends OnboardingFlowNotifier {
  _PreloadedOnboardingFlow(this._initial);
  final OnboardingFlowState _initial;
  @override
  OnboardingFlowState build() => _initial;
}

void main() {
  group('ProfileRecapPage — Story 1.3', () {
    testWidgets(
      'AC5 data state : bandeau exam + grille matieres + CTA',
      (tester) async {
        final prefs = await _preparePrefs();
        await _pumpRecapPage(
          tester,
          prefs: prefs,
          derivedAsync: AsyncValue.data(Right(_fatouProfile())),
        );

        expect(find.textContaining('BAC D'), findsOneWidget);
        expect(find.text('Mathématiques'), findsOneWidget);
        expect(find.text('PCT'), findsOneWidget);
        expect(find.text('2 matières'), findsOneWidget);
        expect(find.text("C'est ma classe"), findsOneWidget);
        expect(find.text('Retour'), findsOneWidget);
      },
    );

    testWidgets(
      'AC5 error state : noMatchingRule -> message + bouton Retour',
      (tester) async {
        final prefs = await _preparePrefs();
        await _pumpRecapPage(
          tester,
          prefs: prefs,
          derivedAsync: AsyncValue.data(
            const Left(
              CatalogueFailure.noMatchingRule(
                subSystem: 'francophone',
                filiere: 'generale',
                niveau: 'francophone_terminale',
                serie: 'inconnue',
              ),
            ),
          ),
        );

        // Message d'erreur affiche + bouton retour.
        expect(
          find.textContaining('Aucune classe trouvée'),
          findsOneWidget,
        );
        expect(find.text('Retour'), findsOneWidget);
        // Pas de CTA de validation en cas d'erreur.
        expect(find.text("C'est ma classe"), findsNothing);
      },
    );

    // ================================================================
    // Story 1.4 — lien opt-out conditionnel + filtrage grille
    // ================================================================

    testWidgets(
      'Story 1.4 AC2 : canOptOut=true (James) -> lien "Retirer une matiere" visible',
      (tester) async {
        final prefs = await _preparePrefs();
        await _pumpRecapPage(
          tester,
          prefs: prefs,
          derivedAsync: AsyncValue.data(Right(_jamesProfile())),
          flowState: const OnboardingFlowState(
            filiereId: 'generale',
            niveauId: 'anglophone_upper_sixth',
            serieId: 'anglophone_upper_sixth_s2',
          ),
        );

        // 3 matieres affichees + lien actif (optedOut vide -> libelle "Retirer").
        expect(find.text('Chemistry'), findsNothing); // langue FR
        expect(find.text('Chimie'), findsOneWidget);
        expect(find.text('Physique'), findsOneWidget);
        expect(find.text('Biologie'), findsOneWidget);
        expect(find.text('Retirer une matière'), findsOneWidget);
        expect(find.text('Modifier mes matières'), findsNothing);
      },
    );

    testWidgets(
      'Story 1.4 AC5 : optedOutSubjects=[biology] -> grille filtree + libelle "Modifier"',
      (tester) async {
        final prefs = await _preparePrefs();
        await _pumpRecapPage(
          tester,
          prefs: prefs,
          derivedAsync: AsyncValue.data(Right(_jamesProfile())),
          optedOutSubjects: const ['anglophone_biology'],
          flowState: const OnboardingFlowState(
            filiereId: 'generale',
            niveauId: 'anglophone_upper_sixth',
            serieId: 'anglophone_upper_sixth_s2',
          ),
        );

        // 2 matieres restantes : Chimie + Physique. Biology filtree.
        expect(find.text('Chimie'), findsOneWidget);
        expect(find.text('Physique'), findsOneWidget);
        expect(find.text('Biologie'), findsNothing);
        expect(find.text('2 matières'), findsOneWidget);
        // Libelle bascule sur "Modifier".
        expect(find.text('Modifier mes matières'), findsOneWidget);
        expect(find.text('Retirer une matière'), findsNothing);
      },
    );
  });
}
