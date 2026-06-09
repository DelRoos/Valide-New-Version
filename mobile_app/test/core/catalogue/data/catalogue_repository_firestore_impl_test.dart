// Tests CatalogueRepositoryFirestoreImpl — Story 1.1c AC2+AC6 + refactor Story 1.13.
//
// Vérifient :
//  1. fetchSubjects filtre `isActive == true` + `subSystem` + ordonne par sortOrder
//  2. derive(francophone, generale, Tle D) → Right(DerivedProfile) avec 3 subjects
//  3. derive(francophone, generale, Tle, "unknown_serie") → Left(noMatchingRule)

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:valide_school/core/catalogue/data/catalogue_repository_firestore_impl.dart';
import 'package:valide_school/core/catalogue/domain/catalogue_failure.dart';

Future<void> _seedSubjects(FakeFirebaseFirestore fs) async {
  await fs.collection('subjects').doc('francophone_math').set({
    'subSystem': 'francophone',
    'name': {'fr': 'Mathématiques', 'en': 'Mathematics'},
    'icon': 'function-square',
    'isActive': true,
    'sortOrder': 10,
  });
  await fs.collection('subjects').doc('francophone_pct').set({
    'subSystem': 'francophone',
    'name': {'fr': 'PCT', 'en': 'PCT'},
    'icon': 'flask',
    'isActive': true,
    'sortOrder': 20,
  });
  await fs.collection('subjects').doc('francophone_svt').set({
    'subSystem': 'francophone',
    'name': {'fr': 'SVT', 'en': 'Life Science'},
    'icon': 'leaf',
    'isActive': true,
    'sortOrder': 30,
  });
  // Inactive : ne doit jamais apparaitre dans watchSubjects
  await fs.collection('subjects').doc('francophone_disabled').set({
    'subSystem': 'francophone',
    'name': {'fr': 'Désactivée', 'en': 'Disabled'},
    'icon': 'circle',
    'isActive': false,
    'sortOrder': 5,
  });
  // Autre subSystem : ne doit pas apparaitre quand on filtre francophone
  await fs.collection('subjects').doc('anglophone_chemistry').set({
    'subSystem': 'anglophone',
    'name': {'fr': 'Chimie', 'en': 'Chemistry'},
    'icon': 'flask',
    'isActive': true,
    'sortOrder': 10,
  });
}

Future<void> _seedDerivationForTleD(FakeFirebaseFirestore fs) async {
  // Rule pour Tle D — francophone générale
  await fs
      .collection('derivation_rules')
      .doc('rule_francophone_generale_terminale_d')
      .set({
    'matchSubSystem': 'francophone',
    'matchFiliere': 'generale',
    'matchNiveau': 'francophone_terminale',
    'matchSerie': 'francophone_terminale_d',
    'subjectIds': [
      'francophone_math',
      'francophone_pct',
      'francophone_svt',
    ],
    'examTargetIds': ['exam_bac_francophone_d'],
    'canOptOut': false,
    'isActive': true,
  });
  // Exam target associé
  await fs.collection('exam_targets').doc('exam_bac_francophone_d').set({
    'subSystem': 'francophone',
    'name': {'fr': 'BAC D', 'en': 'BAC D'},
    'isActive': true,
    'sortOrder': 100,
  });
}

void main() {
  group('CatalogueRepositoryFirestoreImpl — Story 1.1c', () {
    test('fetchSubjects filtre isActive=true + subSystem francophone, '
        'ordonne par sortOrder', () async {
      final fs = FakeFirebaseFirestore();
      await _seedSubjects(fs);

      final repo = CatalogueRepositoryFirestoreImpl(fs);
      final result = await repo.fetchSubjects(subSystem: 'francophone');

      // 3 subjects francophones actifs, l'anglophone et le disabled sont filtrés
      expect(result.length, 3);
      // Ordre attendu par sortOrder ASC
      expect(result.map((s) => s.subjectId).toList(), [
        'francophone_math',
        'francophone_pct',
        'francophone_svt',
      ]);
    });

    test('derive(Tle D) → Right(DerivedProfile) avec 3 subjects + 1 examTarget',
        () async {
      final fs = FakeFirebaseFirestore();
      await _seedSubjects(fs);
      await _seedDerivationForTleD(fs);

      final repo = CatalogueRepositoryFirestoreImpl(fs);
      final result = await repo.derive(
        subSystem: 'francophone',
        filiere: 'generale',
        niveau: 'francophone_terminale',
        serie: 'francophone_terminale_d',
      );

      expect(result.isRight(), true);
      final profile = result.getRight().toNullable()!;
      expect(profile.subjects.length, 3);
      expect(
        profile.subjects.map((s) => s.subjectId).toSet(),
        {'francophone_math', 'francophone_pct', 'francophone_svt'},
      );
      expect(profile.examTargets.length, 1);
      expect(profile.examTargets.first.examTargetId, 'exam_bac_francophone_d');
      expect(profile.canOptOut, false);
    });

    test('derive(serie inconnue) → Left(CatalogueFailure.noMatchingRule)',
        () async {
      final fs = FakeFirebaseFirestore();
      await _seedSubjects(fs);
      await _seedDerivationForTleD(fs);

      final repo = CatalogueRepositoryFirestoreImpl(fs);
      final result = await repo.derive(
        subSystem: 'francophone',
        filiere: 'generale',
        niveau: 'francophone_terminale',
        serie: 'unknown_serie',
      );

      expect(result.isLeft(), true);
      final failure = result.getLeft().toNullable()!;
      expect(failure, isA<CatalogueNoMatchingRuleFailure>());
      final nmr = failure as CatalogueNoMatchingRuleFailure;
      expect(nmr.subSystem, 'francophone');
      expect(nmr.filiere, 'generale');
      expect(nmr.niveau, 'francophone_terminale');
      expect(nmr.serie, 'unknown_serie');
    });

    test('hasNonEmptyCatalogue : false si aucune rule active', () async {
      final fs = FakeFirebaseFirestore();
      // Seed uniquement des rules inactives
      await fs.collection('derivation_rules').doc('rule_inactive').set({
        'matchSubSystem': 'francophone',
        'matchFiliere': 'generale',
        'matchNiveau': 'francophone_terminale',
        'matchSerie': null,
        'subjectIds': [],
        'examTargetIds': [],
        'canOptOut': false,
        'isActive': false,
      });

      final repo = CatalogueRepositoryFirestoreImpl(fs);
      expect(await repo.hasNonEmptyCatalogue(), false);
    });

    test('hasNonEmptyCatalogue : true si au moins 1 rule active', () async {
      final fs = FakeFirebaseFirestore();
      await _seedDerivationForTleD(fs);

      final repo = CatalogueRepositoryFirestoreImpl(fs);
      expect(await repo.hasNonEmptyCatalogue(), true);
    });
  });
}
