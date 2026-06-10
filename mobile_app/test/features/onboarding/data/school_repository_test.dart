// Story 1.7 — Tests SchoolRepositoryFirestoreImpl avec fake_cloud_firestore.
// Story 1.5.b — Adaptation : seed avec keywords[] pre-genere + nouveaux tests
// case-insensitive + accents + abreviations + tri client.
// Story 1.5.c — Refactor (d) (e) pour createSchoolRequest + collection racine
// school_requests + 4 nouveaux tests (l) (m) (n) (o) (subSystem/region opt).

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:valide_school/features/onboarding/data/school_repository_firestore_impl.dart';

void main() {
  group('SchoolRepositoryFirestoreImpl — Story 1.7 + 1.5.b', () {
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

    // Story 1.5.b — seed avec keywords[] pre-genere (pipeline equivalent
    // a `_generate_keywords` cote Python : lower-case + sans accents +
    // tokens + abreviations).
    Future<void> seedSchools() async {
      await firestore.collection('schools').doc('s1').set({
        'name': 'Lycee Bilingue de Bonaberi',
        'city': 'Douala',
        'region': 'Littoral',
        'subSystem': 'both',
        'isValidated': true,
        'keywords': [
          'bilingue', 'bonaberi', 'de', 'douala', 'lb', 'littoral', 'lycee',
        ],
      });
      await firestore.collection('schools').doc('s2').set({
        'name': 'Lycee Joss',
        'city': 'Douala',
        'region': 'Littoral',
        'subSystem': 'francophone',
        'isValidated': true,
        'keywords': ['douala', 'joss', 'littoral', 'lycee'],
      });
      await firestore.collection('schools').doc('s3').set({
        'name': 'College Vogt',
        'city': 'Yaounde',
        'region': 'Centre',
        'subSystem': 'francophone',
        'isValidated': true,
        'keywords': ['centre', 'college', 'vogt', 'yaounde'],
      });
      // Ecole non-validee : ne doit JAMAIS apparaitre dans les resultats.
      await firestore.collection('schools').doc('s_pending').set({
        'name': 'Lycee Test Pending',
        'city': 'Test',
        'region': 'Test',
        'subSystem': 'both',
        'isValidated': false,
        'keywords': ['lycee', 'pending', 'test'],
      });
      // Story 1.5.b — ecole anglophone avec abreviation GHS.
      await firestore.collection('schools').doc('s_ghs').set({
        'name': 'Government High School Buea Town',
        'city': 'Buea',
        'region': 'Sud-Ouest',
        'subSystem': 'anglophone',
        'isValidated': true,
        'keywords': [
          'buea', 'ghs', 'government', 'high', 'ouest', 'school', 'sud', 'town',
        ],
      });
    }

    // ===================================================================
    // Tests Story 1.7 (adaptes pour keywords[])
    // ===================================================================

    test(
        '(a) query "Lycee" -> retourne les ecoles avec keyword "lycee" validees uniquement',
        () async {
      await seedSchools();
      final repo = buildRepo(uid: 'alice');

      final result = await repo.searchByPrefix('Lycee');

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('expected Right'),
        (schools) {
          // s1, s2 : valides avec keyword "lycee". s_pending : invalide,
          // filtre cote Firestore par where isValidated. s3, s_ghs : pas
          // de keyword "lycee".
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
      // a query token normalise null).
      final repo = buildRepo(uid: 'alice');

      final result = await repo.searchByPrefix('');

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected Right'), (s) => expect(s, isEmpty));
    });

    test(
        '(d) createSchoolRequest : succes -> doc cree dans school_requests/<auto>',
        () async {
      final repo = buildRepo(uid: 'alice');

      final result = await repo.createSchoolRequest(
        name: 'Lycee Inconnu',
        city: 'Buea',
        region: 'Sud-Ouest',
      );

      expect(result.isRight(), isTrue);
      // Story 1.5.c — collection racine school_requests, plus de
      // schools/_pending_<ts>/requests
      final all = await firestore.collection('school_requests').get();
      expect(all.docs.length, 1);
      final data = all.docs.first.data();
      expect(data['requestedBy'], 'alice');
      expect(data['name'], 'Lycee Inconnu');
      expect(data['city'], 'Buea');
      expect(data['region'], 'Sud-Ouest');
      expect(data['status'], 'pending');
      // Verifie qu'on n'a PAS pollue la collection schools/ (POC Story 1.7
      // supprime).
      final schoolsDocs = await firestore.collection('schools').get();
      expect(
        schoolsDocs.docs.where((d) => d.id.startsWith('_pending_')).length,
        0,
      );
    });

    test('(e) createSchoolRequest : pas d\'auth -> Left(firestoreError)',
        () async {
      final repo = buildRepo(uid: null);

      final result = await repo.createSchoolRequest(name: 'X', city: 'Y');

      expect(result.isLeft(), isTrue);
      // Verifie qu'aucun doc n'est cree.
      final all = await firestore.collection('school_requests').get();
      expect(all.docs, isEmpty);
    });

    // ===================================================================
    // Story 1.5.b — Nouveaux tests case-insensitive + accents + abrev + tri
    // ===================================================================

    test('(f) query lower-case "lycee" matche les keywords[] lower-case',
        () async {
      await seedSchools();
      final repo = buildRepo(uid: 'alice');

      final result = await repo.searchByPrefix('lycee');

      result.fold(
        (_) => fail('expected Right'),
        (schools) {
          expect(schools.length, 2);
          expect(schools.map((s) => s.schoolId).toSet(), {'s1', 's2'});
        },
      );
    });

    test(
        '(g) query avec accent FR "Lycée" -> normalisee en "lycee" -> matche keywords[]',
        () async {
      await seedSchools();
      final repo = buildRepo(uid: 'alice');

      final result = await repo.searchByPrefix('Lycée');

      result.fold(
        (_) => fail('expected Right'),
        (schools) {
          expect(schools.length, 2);
          expect(schools.map((s) => s.schoolId).toSet(), {'s1', 's2'});
        },
      );
    });

    test('(h) query abreviation "GHS" matche les ecoles Government High School',
        () async {
      await seedSchools();
      final repo = buildRepo(uid: 'alice');

      final result = await repo.searchByPrefix('GHS');

      result.fold(
        (_) => fail('expected Right'),
        (schools) {
          expect(schools.length, 1);
          expect(schools.first.schoolId, 's_ghs');
          expect(schools.first.keywords, contains('ghs'));
        },
      );
    });

    test('(i) query 1 char -> court-circuite avant Firestore -> liste vide',
        () async {
      await seedSchools();
      final repo = buildRepo(uid: 'alice');

      final result = await repo.searchByPrefix('L');

      result.fold(
        (_) => fail('expected Right'),
        (schools) => expect(schools, isEmpty),
      );
    });

    test(
        '(j) tri cote Dart : resultats tries alphabetiquement par name apres get()',
        () async {
      // Seed dans un ordre arbitraire pour verifier le tri client.
      await firestore.collection('schools').doc('z_lycee_zedou').set({
        'name': 'Lycee de Zedou',
        'city': 'Test',
        'region': 'Test',
        'subSystem': 'francophone',
        'isValidated': true,
        'keywords': ['lycee', 'de', 'test', 'zedou'],
      });
      await firestore.collection('schools').doc('a_lycee_aaa').set({
        'name': 'Lycee de Aaa',
        'city': 'Test',
        'region': 'Test',
        'subSystem': 'francophone',
        'isValidated': true,
        'keywords': ['aaa', 'lycee', 'de', 'test'],
      });
      await firestore.collection('schools').doc('m_lycee_mmm').set({
        'name': 'Lycee de Mmm',
        'city': 'Test',
        'region': 'Test',
        'subSystem': 'francophone',
        'isValidated': true,
        'keywords': ['lycee', 'de', 'mmm', 'test'],
      });

      final repo = buildRepo(uid: 'alice');
      final result = await repo.searchByPrefix('lycee');

      result.fold(
        (_) => fail('expected Right'),
        (schools) {
          expect(schools.length, 3);
          // Tri alphabetique cote Dart : Aaa < Mmm < Zedou.
          expect(schools.map((s) => s.name).toList(), [
            'Lycee de Aaa',
            'Lycee de Mmm',
            'Lycee de Zedou',
          ]);
        },
      );
    });

    test(
        '(k) query ponctuation seule "..." -> token null -> court-circuit liste vide',
        () async {
      await seedSchools();
      final repo = buildRepo(uid: 'alice');

      final result = await repo.searchByPrefix('...');

      result.fold(
        (_) => fail('expected Right'),
        (schools) => expect(schools, isEmpty),
      );
    });

    // ===================================================================
    // Story 1.5.c — Tests createSchoolRequest avec subSystem + region opt
    // ===================================================================

    test(
        '(l) createSchoolRequest avec subSystem renseigne -> doc contient subSystem',
        () async {
      final repo = buildRepo(uid: 'alice');

      final result = await repo.createSchoolRequest(
        name: 'Lycee Bilingue Test',
        city: 'Buea',
        region: 'Sud-Ouest',
        subSystem: 'both',
      );

      expect(result.isRight(), isTrue);
      final all = await firestore.collection('school_requests').get();
      expect(all.docs.length, 1);
      final data = all.docs.first.data();
      expect(data['subSystem'], 'both');
      expect(data['name'], 'Lycee Bilingue Test');
    });

    test(
        '(m) createSchoolRequest sans subSystem (null) -> doc n\'a PAS le champ subSystem',
        () async {
      final repo = buildRepo(uid: 'alice');

      final result = await repo.createSchoolRequest(
        name: 'Lycee Sans SubSystem',
        city: 'Yaounde',
      );

      expect(result.isRight(), isTrue);
      final all = await firestore.collection('school_requests').get();
      expect(all.docs.length, 1);
      final data = all.docs.first.data();
      // Le champ ne doit PAS etre present (conditional field). Important
      // pour les rules : `!('subSystem' in request.resource.data)`.
      expect(data.containsKey('subSystem'), isFalse);
    });

    test('(n) createSchoolRequest avec region renseigne -> doc contient region',
        () async {
      final repo = buildRepo(uid: 'alice');

      final result = await repo.createSchoolRequest(
        name: 'Lycee Avec Region',
        city: 'Bamenda',
        region: 'Nord-Ouest',
      );

      expect(result.isRight(), isTrue);
      final all = await firestore.collection('school_requests').get();
      expect(all.docs.length, 1);
      final data = all.docs.first.data();
      expect(data['region'], 'Nord-Ouest');
    });

    test(
        '(o) createSchoolRequest sans region (null) -> doc n\'a PAS le champ region',
        () async {
      final repo = buildRepo(uid: 'alice');

      final result = await repo.createSchoolRequest(
        name: 'Lycee Sans Region',
        city: 'Garoua',
      );

      expect(result.isRight(), isTrue);
      final all = await firestore.collection('school_requests').get();
      expect(all.docs.length, 1);
      final data = all.docs.first.data();
      expect(data.containsKey('region'), isFalse);
    });
  });
}
