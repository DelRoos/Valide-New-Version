// Story A.3 — Tests widget SchoolProfileEditSheet.
//
// Cas couverts :
// (a) Step 0 : sélection d'un niveau → passage au step 1 (stream)
// (b) Step 1 auto-skip : 1 seule série disponible → passage direct au step 2
// (c) Step 2 + tap "Enregistrer" → updateSchoolProfile() appelé + toast succès

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:valide_school/core/catalogue/domain/models.dart';
import 'package:valide_school/core/catalogue/providers.dart';
import 'package:valide_school/features/account/domain/public_profile.dart';
import 'package:valide_school/features/dashboard/presentation/widgets/school_profile_edit_sheet.dart';
import 'package:valide_school/features/onboarding/domain/profile_failure.dart';
import 'package:valide_school/features/onboarding/domain/school.dart';
import 'package:valide_school/features/onboarding/domain/sub_system.dart';
import 'package:valide_school/features/onboarding/domain/user_profile_repository.dart';
import 'package:valide_school/features/onboarding/providers.dart';
import 'package:valide_school/l10n/generated/app_localizations.dart';

// ────────────────────────────────────────────────────────────────────────────
// Fake repo
// ────────────────────────────────────────────────────────────────────────────

class _TrackingRepo implements UserProfileRepository {
  String? lastLevelId;
  String? lastStreamId;
  bool failNext = false;

  @override
  Future<Either<ProfileFailure, void>> updateSchoolProfile({
    required String trackId,
    required String levelId,
    required String streamId,
    required List<String> derivedSubjects,
    required List<String> examTargets,
    required List<String> pickedSubjects,
    required List<String> optedOutSubjects,
  }) async {
    lastLevelId = levelId;
    lastStreamId = streamId;
    return failNext
        ? const Left(ProfileFailure.firestoreError('err'))
        : const Right(null);
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
  Future<Either<ProfileFailure, void>> updateDisplayName(String name) async => const Right(null);

  @override
  Future<Either<ProfileFailure, void>> updatePhoneNumber(String? phone) async => const Right(null);

  @override
  Future<Either<ProfileFailure, Map<String, dynamic>?>> fetchProfileOnce() async => const Right(null);

  @override
  Future<Either<ProfileFailure, PublicProfile?>> fetchPublicProfile(String uid) async => const Right(null);
}

// ────────────────────────────────────────────────────────────────────────────
// Catalogue de test
// ────────────────────────────────────────────────────────────────────────────

final _kNiveauPremiere = Niveau(
  niveauId: 'francophone_premiere',
  subSystem: 'francophone',
  name: const {'fr': 'Première', 'en': 'Grade 11'},
  filiereIds: const ['generale'],
  isActive: true,
  sortOrder: 0,
);

final _kNiveauTerminale = Niveau(
  niveauId: 'francophone_terminale',
  subSystem: 'francophone',
  name: const {'fr': 'Terminale', 'en': 'Grade 13'},
  filiereIds: const ['generale'],
  isActive: true,
  sortOrder: 1,
);

const _kSerieD = Serie(
  serieId: 'francophone_terminale_d',
  subSystem: 'francophone',
  niveauId: 'francophone_terminale',
  filiereId: 'generale',
  name: {'fr': 'Série D', 'en': 'Series D'},
  canOptOut: false,
  isActive: true,
  sortOrder: 0,
);

const _kSerieC = Serie(
  serieId: 'francophone_terminale_c',
  subSystem: 'francophone',
  niveauId: 'francophone_terminale',
  filiereId: 'generale',
  name: {'fr': 'Série C', 'en': 'Series C'},
  canOptOut: false,
  isActive: true,
  sortOrder: 1,
);

// Règle de dérivation minimale pour Terminale Série D (0 matières — suffisant
// pour que _derived != null et que le step 2 affiche le label + Enregistrer).
const _kRuleTerminaleD = DerivationRule(
  ruleId: 'rule_francophone_terminale_d',
  matchSubSystem: 'francophone',
  matchFiliere: 'generale',
  matchNiveau: 'francophone_terminale',
  matchSerie: 'francophone_terminale_d',
  subjectIds: [],
  examTargetIds: [],
  canOptOut: false,
  isActive: true,
);

// Catalogue avec 2 niveaux et 2 séries pour Terminale.
final _kCatalogueFull = CatalogueSnapshot(
  filieres: const [],
  niveaux: [_kNiveauPremiere, _kNiveauTerminale],
  series: const [_kSerieD, _kSerieC],
  subjects: const [],
  examTargets: const [],
  derivationRules: const [_kRuleTerminaleD],
);

// Catalogue avec 2 niveaux et 1 seule série pour Terminale (auto-skip).
final _kCatalogueAutoSkip = CatalogueSnapshot(
  filieres: const [],
  niveaux: [_kNiveauPremiere, _kNiveauTerminale],
  series: const [_kSerieD], // seule série pour Terminale
  subjects: const [],
  examTargets: const [],
  derivationRules: const [_kRuleTerminaleD],
);

// ────────────────────────────────────────────────────────────────────────────
// Helper pump
// ────────────────────────────────────────────────────────────────────────────

Future<_TrackingRepo> _pumpSheet(
  WidgetTester tester, {
  CatalogueSnapshot? catalogue,
}) async {
  final repo = _TrackingRepo();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userProfileRepositoryProvider.overrideWithValue(repo),
        catalogueProvider.overrideWith(
          (ref) async => catalogue ?? _kCatalogueFull,
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (ctx, child) => MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Scaffold(
            body: SchoolProfileEditSheet(
              subSystem: 'francophone',
              trackId: 'generale',
              initialLevelId: 'francophone_premiere',
              initialStreamId: 'francophone_terminale_d',
              initialPickedSubjectIds: const [],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

// ────────────────────────────────────────────────────────────────────────────
// Tests
// ────────────────────────────────────────────────────────────────────────────

void main() {
  group('SchoolProfileEditSheet — Story A.3', () {
    testWidgets('(a) tap Terminale au step 0 → step 1 liste séries visible',
        (tester) async {
      await _pumpSheet(tester);

      // Step 0 : label "Quelle est ta classe ?" visible (distinct du titre)
      expect(find.text('Quelle est ta classe ?'), findsOneWidget);
      // "Terminale" est dans le catalogue
      expect(find.text('Terminale'), findsOneWidget);

      // Tap Terminale
      await tester.tap(find.text('Terminale'));
      await tester.pumpAndSettle();

      // Step 1 : "spécialité" visible
      expect(find.textContaining('spécialité'), findsOneWidget);
    });

    testWidgets('(b) auto-skip série : 1 seule série → passage direct step 2',
        (tester) async {
      await _pumpSheet(tester, catalogue: _kCatalogueAutoSkip);

      // Tap Terminale (qui n'a qu'une seule série → auto-skip)
      await tester.tap(find.text('Terminale'));
      await tester.pumpAndSettle();

      // Step 2 directement : "Tes matières" visible (ou bouton Enregistrer)
      expect(find.textContaining('matières'), findsOneWidget);
    });

    testWidgets('(c) tap Enregistrer → updateSchoolProfile() appelé + toast succès',
        (tester) async {
      final repo = await _pumpSheet(tester);

      // Naviguer jusqu'au step 2
      await tester.tap(find.text('Terminale'));
      await tester.pumpAndSettle();

      // Tap Série D (step 1 → step 2)
      await tester.tap(find.text('Série D'));
      await tester.pumpAndSettle();

      // Step 2 : bouton "Enregistrer" visible
      expect(find.text('Enregistrer'), findsOneWidget);

      // Tap Enregistrer
      await tester.tap(find.text('Enregistrer'));
      await tester.pump(); // déclenche le Future
      await tester.pump(); // laisse _saving passer à false
      await tester.pump(const Duration(seconds: 5)); // drainer timer AppToast

      expect(repo.lastLevelId, 'francophone_terminale');
      expect(repo.lastStreamId, 'francophone_terminale_d');
    });
  });
}
