// Story 1.9 AC1-AC5 — Widget tests DashboardPage.
//
// 5 cas :
//   (a) Profil complet Fatou (displayName='Fatou Mballa', 9 subjects, 1 exam)
//       -> hero "Bienvenue Fatou !" + sous-titre exam + 9 cards + compteur 9
//   (b) Visiteur (isAnonymous=true, displayName=null)
//       -> hero "Bienvenue !" + badge "Visiteur" + encadre "Crée ton compte"
//   (c) OptedOut (effective emit 2 subjects au lieu de 3)
//       -> grille 2 cards + compteur 2 matieres
//   (d) Loading state (derivedProfile loading)
//       -> Animate widgets visibles (skeleton shimmer)
//   (e) Empty state (derivedProfile Left)
//       -> texte "Termine ton profil" + CTA "Continuer mon onboarding"

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:valide_school/core/catalogue/domain/catalogue_failure.dart';
import 'package:valide_school/core/catalogue/domain/models.dart';
import 'package:valide_school/core/firebase/providers.dart';
import 'package:valide_school/features/dashboard/presentation/dashboard_page.dart';
import 'package:valide_school/features/onboarding/domain/sub_system.dart';
import 'package:valide_school/features/onboarding/providers.dart';
import 'package:valide_school/l10n/generated/app_localizations.dart';

import '../../../_helpers/fakes.dart';

class _StubSubSystemNotifier extends SubSystemNotifier {
  _StubSubSystemNotifier(this._initial);
  final SubSystem? _initial;
  @override
  SubSystem? build() => _initial;
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
      Subject(
        subjectId: 'francophone_svt',
        subSystem: 'francophone',
        name: {'fr': 'SVT', 'en': 'Biology'},
        icon: 'dna',
        isActive: true,
        sortOrder: 30,
      ),
      Subject(
        subjectId: 'francophone_francais',
        subSystem: 'francophone',
        name: {'fr': 'Français', 'en': 'French'},
        icon: 'book-open-text',
        isActive: true,
        sortOrder: 40,
      ),
      Subject(
        subjectId: 'francophone_anglais',
        subSystem: 'francophone',
        name: {'fr': 'Anglais', 'en': 'English'},
        icon: 'languages',
        isActive: true,
        sortOrder: 50,
      ),
      Subject(
        subjectId: 'francophone_lv2',
        subSystem: 'francophone',
        name: {'fr': 'LV2', 'en': 'LV2'},
        icon: 'globe',
        isActive: true,
        sortOrder: 60,
      ),
      Subject(
        subjectId: 'francophone_philo',
        subSystem: 'francophone',
        name: {'fr': 'Philosophie', 'en': 'Philosophy'},
        icon: 'brain',
        isActive: true,
        sortOrder: 70,
      ),
      Subject(
        subjectId: 'francophone_hist_geo',
        subSystem: 'francophone',
        name: {'fr': 'Histoire-Géo', 'en': 'History-Geo'},
        icon: 'landmark',
        isActive: true,
        sortOrder: 80,
      ),
      Subject(
        subjectId: 'francophone_eps',
        subSystem: 'francophone',
        name: {'fr': 'EPS', 'en': 'PE'},
        icon: 'dumbbell',
        isActive: true,
        sortOrder: 90,
      ),
    ],
    examTargets: const [
      ExamTarget(
        examTargetId: 'exam_bac_francophone_d',
        subSystem: 'francophone',
        name: {'fr': 'BAC D', 'en': 'BAC D'},
        isActive: true,
        sortOrder: 10,
      ),
    ],
    canOptOut: false,
  );
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

Future<SharedPreferences> _prefsFr() async {
  SharedPreferences.setMockInitialValues({
    'onboarding.subsystem': 'francophone',
    'onboarding.language': 'fr',
  });
  return SharedPreferences.getInstance();
}

Future<void> _pumpDashboard(
  WidgetTester tester, {
  required SharedPreferences prefs,
  required FakeAuth auth,
  required FakeUserProfileRepository repo,
  required AsyncValue<Either<CatalogueFailure, DerivedProfile>> derivedAsync,
  required AsyncValue<List<Subject>> effectiveAsync,
  SubSystem subSystem = SubSystem.francophone,
  bool isLoading = false,
}) async {
  // Pour le cas loading : on utilise Completer.future (jamais resolu, pas de
  // Timer) pour eviter "A Timer is still pending after dispose" sur les
  // animations shimmer + le derivedProfile loading.
  final loadingCompleter = Completer<Either<CatalogueFailure, DerivedProfile>>();
  addTearDown(() {
    if (!loadingCompleter.isCompleted) {
      loadingCompleter.completeError(StateError('test torn down'));
    }
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        firebaseAuthProvider.overrideWithValue(auth),
        userProfileRepositoryProvider.overrideWithValue(repo),
        subSystemNotifierProvider
            .overrideWith(() => _StubSubSystemNotifier(subSystem)),
        derivedProfileProvider.overrideWith((ref) {
          return derivedAsync.when(
            data: (either) async => either,
            loading: () => loadingCompleter.future,
            error: (e, st) =>
                Future<Either<CatalogueFailure, DerivedProfile>>.error(e, st),
          );
        }),
        effectiveDerivedSubjectsProvider.overrideWith((ref) {
          return effectiveAsync.when(
            data: (list) => Stream.value(list),
            loading: () => const Stream<List<Subject>>.empty(),
            error: (e, st) => Stream<List<Subject>>.error(e, st),
          );
        }),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: const DashboardPage(),
        ),
      ),
    ),
  );
  if (isLoading) {
    // Le skeleton anime des shimmer.repeat() infinis -> pumpAndSettle
    // boucle a l'infini. On pump 2 frames + un peu de delta pour laisser
    // le 1er rebuild se faire, puis on assert.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  } else {
    // Etat data ou error : pas d'animation infinie, pumpAndSettle est sur.
    await tester.pumpAndSettle();
  }
}

void main() {
  group('DashboardPage — Story 1.9', () {
    testWidgets(
      '(a) Profil complet Fatou : hero "Bienvenue Fatou !" + 9 cards + compteur 9',
      (tester) async {
        final prefs = await _prefsFr();
        final profile = _fatouProfile();
        await _pumpDashboard(
          tester,
          prefs: prefs,
          auth: FakeAuth(isAnonymous: false, displayName: 'Fatou Mballa'),
          repo: FakeUserProfileRepository(
            profileData: const {'displayName': 'Fatou Mballa'},
          ),
          derivedAsync: AsyncValue.data(Right(profile)),
          effectiveAsync: AsyncValue.data(profile.subjects),
        );

        // Hero + sous-titre + compteur.
        expect(find.text('Bienvenue Fatou !'), findsOneWidget);
        expect(find.textContaining('Voici tes matières'), findsOneWidget);
        expect(find.textContaining('BAC D'), findsOneWidget);
        expect(find.text('9 matières'), findsOneWidget);
        // Premieres cards visibles (le GridView lazy-build : les 3 derniers
        // subjects sont hors viewport en 375x812 et pas dans le tree).
        expect(find.text('Mathématiques'), findsOneWidget);
        expect(find.text('PCT'), findsOneWidget);
        expect(find.text('SVT'), findsOneWidget);
        // Pas de badge visiteur ni encadre invite.
        expect(find.text('Visiteur'), findsNothing);
        expect(find.text('Créer mon compte'), findsNothing);
      },
    );

    testWidgets(
      '(b) Visiteur : hero "Bienvenue !" + badge Visiteur + invite compte',
      (tester) async {
        final prefs = await _prefsFr();
        await _pumpDashboard(
          tester,
          prefs: prefs,
          auth: FakeAuth(isAnonymous: true, displayName: null),
          repo: FakeUserProfileRepository(profileData: null),
          derivedAsync: AsyncValue.data(Right(_jamesProfile())),
          effectiveAsync: AsyncValue.data(_jamesProfile().subjects),
        );

        expect(find.text('Bienvenue !'), findsOneWidget);
        expect(find.text('Visiteur'), findsOneWidget);
        expect(
          find.text('Crée ton compte pour sauvegarder ta progression'),
          findsOneWidget,
        );
        expect(find.text('Créer mon compte'), findsOneWidget);
      },
    );

    testWidgets(
      '(c) OptedOut : effective emit 2 subjects (Chemistry+Physics) + compteur 2',
      (tester) async {
        final prefs = await _prefsFr();
        final profile = _jamesProfile();
        final filtered =
            profile.subjects.where((s) => s.subjectId != 'anglophone_biology').toList();
        await _pumpDashboard(
          tester,
          prefs: prefs,
          auth: FakeAuth(isAnonymous: false, displayName: 'James'),
          repo: FakeUserProfileRepository(
            profileData: const {
              'displayName': 'James',
              'optedOutSubjects': ['anglophone_biology'],
            },
          ),
          derivedAsync: AsyncValue.data(Right(profile)),
          effectiveAsync: AsyncValue.data(filtered),
        );

        expect(find.text('2 matières'), findsOneWidget);
        expect(find.text('Chimie'), findsOneWidget);
        expect(find.text('Physique'), findsOneWidget);
        expect(find.text('Biologie'), findsNothing);
      },
    );

    testWidgets(
      '(d) Loading : skeleton shimmer visible (Animate widgets)',
      (tester) async {
        final prefs = await _prefsFr();
        await _pumpDashboard(
          tester,
          prefs: prefs,
          auth: FakeAuth(isAnonymous: false, displayName: 'Fatou'),
          repo: FakeUserProfileRepository(
            profileData: const {'displayName': 'Fatou'},
          ),
          derivedAsync: const AsyncValue.loading(),
          effectiveAsync: const AsyncValue.loading(),
          isLoading: true,
        );

        // Le skeleton utilise flutter_animate -> au moins un widget Animate.
        expect(find.byType(Animate), findsWidgets);
        // Hero reste rendu en loading.
        expect(find.text('Bienvenue Fatou !'), findsOneWidget);

        // Detache le widget tree pour disposer les Timer shimmer.repeat
        // (sinon "A Timer is still pending" en fin de test).
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets(
      '(e) Empty state : derived Left -> texte "Termine ton profil" + CTA',
      (tester) async {
        final prefs = await _prefsFr();
        await _pumpDashboard(
          tester,
          prefs: prefs,
          auth: FakeAuth(isAnonymous: false, displayName: 'Fatou'),
          repo: FakeUserProfileRepository(
            profileData: const {'displayName': 'Fatou'},
          ),
          derivedAsync: AsyncValue.data(
            Left(
              CatalogueFailure.noMatchingRule(
                subSystem: 'francophone',
                filiere: 'generale',
                niveau: 'francophone_terminale',
                serie: null,
              ),
            ),
          ),
          effectiveAsync: const AsyncValue.data([]),
        );

        expect(
          find.text('Termine ton profil pour voir tes matières.'),
          findsOneWidget,
        );
        expect(find.text('Continuer mon onboarding'), findsOneWidget);
      },
    );
  });
}
