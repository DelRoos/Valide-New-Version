// Story 1.7 — Tests SchoolRepositoryFirestoreImpl avec fake_cloud_firestore.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:valide_school/features/onboarding/data/school_repository_firestore_impl.dart';

void main() {
  group('SchoolRepositoryFirestoreImpl — Story 1.7', () {
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
    });

    SchoolRepositoryFirestoreImpl buildRepo({String? uid}) {
      return SchoolRepositoryFirestoreImpl(
        firestore: firestore,
        getUid: () => uid,
      );
    }

    Future<void> seedSchools() async {
      await firestore.collection('schools').doc('s1').set({
        'name': 'Lycee Bilingue de Bonaberi',
        'city': 'Douala',
        'region': 'Littoral',
        'subSystem': 'both',
        'isValidated': true,
      });
      await firestore.collection('schools').doc('s2').set({
        'name': 'Lycee Joss',
        'city': 'Douala',
        'region': 'Littoral',
        'subSystem': 'francophone',
        'isValidated': true,
      });
      await firestore.collection('schools').doc('s3').set({
        'name': 'College Vogt',
        'city': 'Yaounde',
        'region': 'Centre',
        'subSystem': 'francophone',
        'isValidated': true,
      });
      // Ecole non-validee : ne doit JAMAIS apparaitre dans les resultats.
      await firestore.collection('schools').doc('s_pending').set({
        'name': 'Lycee Test Pending',
        'city': 'Test',
        'region': 'Test',
        'subSystem': 'both',
        'isValidated': false,
      });
    }

    test('(a) query "Ly" -> retourne les ecoles "Lycee*" validees uniquement',
        () async {
      await seedSchools();
      final repo = buildRepo(uid: 'alice');

      final result = await repo.searchByPrefix('Ly');

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('expected Right'),
        (schools) {
          // 2 lycees validees + pas le "Lycee Test Pending" non-valide.
          expect(schools.length, 2);
          expect(schools.map((s) => s.schoolId), ['s1', 's2']);
          expect(schools.every((s) => s.isValidated), isTrue);
        },
      );
    });

    test('(b) query "Xyz" no match -> liste vide', () async {
      await seedSchools();
      final repo = buildRepo(uid: 'alice');

      final result = await repo.searchByPrefix('Xyz');

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('expected Right'),
        (schools) => expect(schools, isEmpty),
      );
    });

    test('(c) query "" court-circuite avant Firestore -> liste vide',
        () async {
      // Pas de seed -> verifie qu'on ne touche pas Firestore (court-circuit
      // a query.length < 2).
      final repo = buildRepo(uid: 'alice');

      final result = await repo.searchByPrefix('');

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected Right'), (s) => expect(s, isEmpty));
    });

    test('(d) requestSchool : succes -> doc cree dans schools/_pending/requests',
        () async {
      final repo = buildRepo(uid: 'alice');

      final result = await repo.requestSchool(
        name: 'Lycee Inconnu',
        city: 'Buea',
        region: 'Sud-Ouest',
      );

      expect(result.isRight(), isTrue);
      final all = await firestore.collectionGroup('requests').get();
      expect(all.docs.length, 1);
      final data = all.docs.first.data();
      expect(data['requestedBy'], 'alice');
      expect(data['name'], 'Lycee Inconnu');
      expect(data['city'], 'Buea');
      expect(data['region'], 'Sud-Ouest');
      expect(data['status'], 'pending');
    });

    test('(e) requestSchool : pas d\'auth -> Left(firestoreError)', () async {
      final repo = buildRepo(uid: null);

      final result = await repo.requestSchool(name: 'X', city: 'Y');

      expect(result.isLeft(), isTrue);
    });
  });
}
