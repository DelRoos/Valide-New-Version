// Story 1.7 — Widget tests SchoolPickerPage.
// Story 1.5.c — Adaptation _FakeSchoolRepo (createSchoolRequest +
// captureSubSystem) + 2 nouveaux tests (f) modale rendue avec subSystem +
// (g) submit avec subSystem renseigne -> repository appele avec la valeur.
//
// 7 cas :
//   (a) Page rendue : titre + sous-titre + champ search + bouton skip
//   (b) Etat vide apres recherche : message + bouton "Ajouter mon ecole"
//   (c) Resultats : 2 cards ecoles cliquables avec badge "Validee"
//   (d) Skip cta -> nav /hello (verifie via override repo qui n'est jamais appele)
//   (e) Story 1.18 AC8 — Tablet 900x1200 : rendu sans overflow + maxWidth 600dp applique
//   (f) Story 1.5.c — Modale rendue : champ name + city + region + 4 RadioListTile subSystem
//   (g) Story 1.5.c — Submit modale avec subSystem -> createSchoolRequest appele avec la valeur

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';

import 'package:valide_school/features/onboarding/domain/profile_failure.dart';
import 'package:valide_school/features/onboarding/domain/school.dart';
import 'package:valide_school/features/onboarding/domain/school_failure.dart';
import 'package:valide_school/features/onboarding/domain/school_repository.dart';
import 'package:valide_school/features/onboarding/domain/sub_system.dart';
import 'package:valide_school/features/onboarding/domain/user_profile_repository.dart';
import 'package:valide_school/features/onboarding/presentation/school_picker_page.dart';
import 'package:valide_school/features/onboarding/providers.dart';
import 'package:valide_school/l10n/generated/app_localizations.dart';

class _FakeSchoolRepo implements SchoolRepository {
  _FakeSchoolRepo({List<School> results = const []}) : _results = results;
  final List<School> _results;

  // Story 1.5.c — capture des derniers arguments de createSchoolRequest pour
  // les tests d'integration UI -> repo.
  String? lastName;
  String? lastCity;
  String? lastRegion;
  String? lastSubSystem;
  int createCallCount = 0;

  @override
  Future<Either<SchoolFailure, List<School>>> searchByPrefix(
    String query,
  ) async {
    if (query.length < 2) return const Right(<School>[]);
    return Right(_results);
  }

  @override
  Future<Either<SchoolFailure, void>> createSchoolRequest({
    required String name,
    required String city,
    String? region,
    String? subSystem,
  }) async {
    lastName = name;
    lastCity = city;
    lastRegion = region;
    lastSubSystem = subSystem;
    createCallCount += 1;
    return const Right(null);
  }
}

class _FakeUserProfileRepo implements UserProfileRepository {
  bool updateCalled = false;

  @override
  Stream<Map<String, dynamic>?> watchProfile() => Stream.value(null);

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
  Future<Either<ProfileFailure, void>> updateLinkedSchool(School? school) async {
    updateCalled = true;
    return const Right(null);
  }
}

const _lyceeBilingue = School(
  schoolId: 's1',
  name: 'Lycee Bilingue de Bonaberi',
  city: 'Douala',
  region: 'Littoral',
  subSystem: 'both',
  isValidated: true,
);

const _lyceeJoss = School(
  schoolId: 's2',
  name: 'Lycee Joss',
  city: 'Douala',
  region: 'Littoral',
  subSystem: 'francophone',
  isValidated: true,
);

Future<void> _pump(
  WidgetTester tester, {
  required SchoolRepository schoolRepo,
  UserProfileRepository? userRepo,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        schoolRepositoryProvider.overrideWithValue(schoolRepo),
        userProfileRepositoryProvider
            .overrideWithValue(userRepo ?? _FakeUserProfileRepo()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: const SchoolPickerPage(),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Story 1.5.c — Variante avec GoRouter pour les tests qui touchent au
/// submit modale (le repository success branch appelle
/// `GoRouter.of(context).go('/dashboard')` ; sans router, le test crash).
Future<void> _pumpWithRouter(
  WidgetTester tester, {
  required SchoolRepository schoolRepo,
  UserProfileRepository? userRepo,
}) async {
  final router = GoRouter(
    initialLocation: '/onboarding/school',
    routes: [
      GoRoute(
        path: '/onboarding/school',
        builder: (context, state) => const SchoolPickerPage(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('DASHBOARD_STUB'))),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        schoolRepositoryProvider.overrideWithValue(schoolRepo),
        userProfileRepositoryProvider
            .overrideWithValue(userRepo ?? _FakeUserProfileRepo()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          routerConfig: router,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('SchoolPickerPage — Story 1.7', () {
    testWidgets(
      '(a) Page rendue : titre + sous-titre + champ + bouton skip',
      (tester) async {
        await _pump(tester, schoolRepo: _FakeSchoolRepo());

        expect(find.text('Lie ton école (optionnel)'), findsOneWidget);
        expect(
          find.textContaining('classements de classe'),
          findsOneWidget,
        );
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Passer cette étape'), findsOneWidget);
      },
    );

    testWidgets(
      '(b) Recherche sans match -> etat vide + bouton "Ajouter mon ecole"',
      (tester) async {
        await _pump(tester, schoolRepo: _FakeSchoolRepo(results: const []));

        // Tape une query >= 2 chars puis attend debounce 300ms.
        await tester.enterText(find.byType(TextField), 'Xyz');
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump(); // settle apres state error/data

        expect(
          find.textContaining('Aucune école trouvée'),
          findsOneWidget,
        );
        expect(find.text('Ajouter mon école'), findsOneWidget);
      },
    );

    testWidgets(
      '(c) Resultats : 2 cards ecoles + badge "Validee"',
      (tester) async {
        await _pump(
          tester,
          schoolRepo: _FakeSchoolRepo(
            results: const [_lyceeBilingue, _lyceeJoss],
          ),
        );

        await tester.enterText(find.byType(TextField), 'Lyc');
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump();

        expect(find.text('Lycee Bilingue de Bonaberi'), findsOneWidget);
        expect(find.text('Lycee Joss'), findsOneWidget);
        expect(find.text('Douala, Littoral'), findsNWidgets(2));
        // 2 badges "Validee".
        expect(find.text('Validée'), findsNWidgets(2));
      },
    );

    testWidgets(
      '(d) Recherche < 2 chars -> court-circuit, aucune card',
      (tester) async {
        // Si le notifier renvoyait des resultats meme pour 1 char, on aurait
        // 1 card visible. Le court-circuit garantit liste vide.
        await _pump(
          tester,
          schoolRepo: _FakeSchoolRepo(results: const [_lyceeBilingue]),
        );

        await tester.enterText(find.byType(TextField), 'L');
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump();

        expect(find.text('Lycee Bilingue de Bonaberi'), findsNothing);
        // Pas non plus l'etat vide (qui ne se montre que si query.length >= 2).
        expect(find.text('Ajouter mon école'), findsNothing);
      },
    );

    testWidgets(
      '(e) Story 1.18 AC8 — Tablet 900x1200 : rendu sans overflow + maxWidth 600dp applique',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(900, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await _pump(tester, schoolRepo: _FakeSchoolRepo());

        // Rendu nominal preserve sur tablet (champ + bouton skip presents)
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Passer cette étape'), findsOneWidget);

        // SchoolPickerPage applique deja maxWidth: 600 en tablet (Story 1.7,
        // lignes 52-58). Story 1.18 AC8 verifie que ce comportement est
        // bien actif au-dessus du breakpoint 840dp.
        final constrainedBoxes = tester
            .widgetList<ConstrainedBox>(find.byType(ConstrainedBox))
            .toList();
        final has600maxWidth = constrainedBoxes.any(
          (cb) => cb.constraints.maxWidth == 600,
        );
        expect(
          has600maxWidth,
          isTrue,
          reason:
              'En tablet (900dp >= 840), SchoolPickerPage doit appliquer maxWidth 600',
        );

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '(f) Story 1.5.c — Modale rendue : champs name + city + region + 4 RadioListTile subSystem',
      (tester) async {
        final fakeRepo = _FakeSchoolRepo();
        await _pump(tester, schoolRepo: fakeRepo);

        // Declenche etat vide pour faire apparaitre le bouton "Ajouter mon ecole".
        await tester.enterText(find.byType(TextField), 'Xyz');
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump();

        await tester.tap(find.text('Ajouter mon école'));
        await tester.pumpAndSettle();

        // 3 TextField dans la modale (name + city + region).
        // Note : le TextField de recherche reste dans l'arbre, donc 4 au total.
        expect(find.byType(TextField), findsNWidgets(4));

        // Label groupe subSystem visible.
        expect(find.text('Sous-système (optionnel)'), findsOneWidget);

        // 4 RadioListTile dans la modale (verifie par les labels uniquement
        // car le type RadioListTile<_SubSystemChoice> est prive).
        expect(find.text('Francophone'), findsOneWidget);
        expect(find.text('Anglophone'), findsOneWidget);
        expect(find.text('Bilingue'), findsOneWidget);
        expect(find.text('Je ne sais pas'), findsOneWidget);

        // Bouton submit visible.
        expect(find.text('Envoyer la demande'), findsOneWidget);
      },
    );

    testWidgets(
      '(g) Story 1.5.c — Submit modale avec subSystem -> createSchoolRequest appele avec la valeur',
      (tester) async {
        final fakeRepo = _FakeSchoolRepo();
        // Story 1.5.c — _pumpWithRouter requis car le success branch nav vers /dashboard.
        await _pumpWithRouter(tester, schoolRepo: fakeRepo);

        await tester.enterText(find.byType(TextField), 'Xyz');
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump();

        await tester.tap(find.text('Ajouter mon école'));
        await tester.pumpAndSettle();

        // Remplit name + city dans la modale. Les TextField de la modale
        // sont les 3 derniers (le 1er est la barre de recherche).
        final textFields = find.byType(TextField);
        await tester.enterText(textFields.at(1), 'Lycee Smoke Test');
        await tester.enterText(textFields.at(2), 'Buea');
        await tester.enterText(textFields.at(3), 'Sud-Ouest');

        // Selectionne le radio Anglophone.
        await tester.tap(find.text('Anglophone'));
        await tester.pumpAndSettle();

        // Submit.
        await tester.tap(find.text('Envoyer la demande'));
        // Pump pour laisser le future repo.createSchoolRequest resoudre, le
        // dialog se fermer, AppToast.show + GoRouter.go vers /dashboard.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Verifie que createSchoolRequest a ete appele avec subSystem='anglophone'.
        expect(fakeRepo.createCallCount, 1);
        expect(fakeRepo.lastName, 'Lycee Smoke Test');
        expect(fakeRepo.lastCity, 'Buea');
        expect(fakeRepo.lastRegion, 'Sud-Ouest');
        expect(fakeRepo.lastSubSystem, 'anglophone');

        // AppToast a un Timer de ~4.4s pour auto-dismiss. Sans pump suffisant,
        // le test crash avec "Timer is still pending". On laisse le timer
        // s'ecouler.
        await tester.pump(const Duration(seconds: 5));
      },
    );
  });
}
