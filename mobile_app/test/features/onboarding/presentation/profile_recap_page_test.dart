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
import 'package:valide_school/features/onboarding/presentation/profile_recap_page.dart';
import 'package:valide_school/features/onboarding/providers.dart';
import 'package:valide_school/l10n/generated/app_localizations.dart';

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
  });
}
