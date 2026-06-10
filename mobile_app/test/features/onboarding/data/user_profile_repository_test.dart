// Story 1.3 — Tests UserProfileRepositoryFirestoreImpl avec fake_cloud_firestore.
//
// Le repo recoit une `getUid` callback (typedef GetUidFn) injectee — pas de
// dependance directe a FirebaseAuth, donc pas besoin de firebase_auth_mocks
// (absent du pubspec).

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:valide_school/features/onboarding/data/user_profile_repository_firestore_impl.dart';
import 'package:valide_school/features/onboarding/domain/school.dart';
import 'package:valide_school/features/onboarding/domain/sub_system.dart';

void main() {
  group('UserProfileRepositoryFirestoreImpl — Story 1.3', () {
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
    });

    UserProfileRepositoryFirestoreImpl buildRepo({String? uid}) {
      return UserProfileRepositoryFirestoreImpl(
        firestore: firestore,
        getUid: () => uid,
      );
    }

    test('createProfile : succes -> doc users/{uid} ecrit', () async {
      final repo = buildRepo(uid: 'test_uid_123');
      final result = await repo.createProfile(
        subSystem: SubSystem.francophone,
        filiereId: 'generale',
        niveauId: 'francophone_terminale',
        serieId: 'francophone_terminale_d',
        derivedSubjects: const [
          'francophone_math',
          'francophone_pct',
          'francophone_svt',
        ],
        examTargets: const ['exam_bac_francophone_d'],
      );

      expect(result.isRight(), isTrue);

      final snap =
          await firestore.collection('users').doc('test_uid_123').get();
      expect(snap.exists, isTrue);
      final data = snap.data();
      expect(data, isNotNull);
      expect(data!['uid'], 'test_uid_123');
      expect(data['subSystem'], 'francophone');
      expect(data['language'], 'fr');
      expect(data['filiere'], 'generale');
      expect(data['niveau'], 'francophone_terminale');
      expect(data['serie'], 'francophone_terminale_d');
      expect(data['derivedSubjects'], [
        'francophone_math',
        'francophone_pct',
        'francophone_svt',
      ]);
      expect(data['examTargets'], ['exam_bac_francophone_d']);
      expect(data['optedOutSubjects'], <String>[]);
      expect(data['schoolId'], isNull);
      expect(data['displayName'], '');
    });

    test(
        'createProfile : pas d\'auth -> Left(ProfileFailure.notAuthenticated)',
        () async {
      final repo = buildRepo(uid: null);

      final result = await repo.createProfile(
        subSystem: SubSystem.francophone,
        filiereId: 'generale',
        niveauId: 'francophone_terminale',
        serieId: '-',
        derivedSubjects: const [],
        examTargets: const [],
      );

      expect(result.isLeft(), isTrue);
    });

    test('createProfile : idempotent — 2 calls -> 1 seul doc', () async {
      final repo = buildRepo(uid: 'test_uid_123');
      await repo.createProfile(
        subSystem: SubSystem.anglophone,
        filiereId: 'generale',
        niveauId: 'anglophone_upper_sixth',
        serieId: 'anglophone_upper_sixth_s2',
        derivedSubjects: const [
          'anglophone_chemistry',
          'anglophone_physics',
          'anglophone_biology',
        ],
        examTargets: const ['exam_gce_a_level_anglophone_s2'],
      );
      final result2 = await repo.createProfile(
        subSystem: SubSystem.anglophone,
        filiereId: 'generale',
        niveauId: 'anglophone_upper_sixth',
        serieId: 'anglophone_upper_sixth_s2',
        derivedSubjects: const [
          'anglophone_chemistry',
          'anglophone_physics',
          'anglophone_biology',
        ],
        examTargets: const ['exam_gce_a_level_anglophone_s2'],
      );
      expect(result2.isRight(), isTrue);

      final all = await firestore.collection('users').get();
      expect(all.docs.length, 1);
      expect(all.docs.first.id, 'test_uid_123');
    });

    // ================================================================
    // Story 1.5 — watchProfile()
    // ================================================================

    test('(h) watchProfile : doc present -> emet la Map data', () async {
      await firestore.collection('users').doc('alice').set(<String, dynamic>{
        'uid': 'alice',
        'subSystem': 'francophone',
        'filiere': 'generale',
        'niveau': 'francophone_terminale',
        'serie': 'francophone_terminale_d',
      });
      final repo = buildRepo(uid: 'alice');

      final emitted = await repo.watchProfile().first;
      expect(emitted, isNotNull);
      expect(emitted!['filiere'], 'generale');
      expect(emitted['niveau'], 'francophone_terminale');
      expect(emitted['serie'], 'francophone_terminale_d');
    });

    test('(i) watchProfile : doc absent -> emet null', () async {
      final repo = buildRepo(uid: 'bob_no_doc');

      final emitted = await repo.watchProfile().first;
      expect(emitted, isNull);
    });

    test('(j) watchProfile : uid absent -> emet null immediatement', () async {
      final repo = buildRepo(uid: null);

      final emitted = await repo.watchProfile().first;
      expect(emitted, isNull);
    });

    // ================================================================
    // Story 1.4 — updateOptedOutSubjects()
    // ================================================================

    test(
        '(k) updateOptedOutSubjects : doc existant -> met a jour le champ + updatedAt',
        () async {
      // Doc deja seede (Story 1.3 createProfile a depose optedOutSubjects:[]).
      await firestore.collection('users').doc('charlie').set(<String, dynamic>{
        'uid': 'charlie',
        'subSystem': 'anglophone',
        'derivedSubjects': const [
          'anglophone_chemistry',
          'anglophone_physics',
          'anglophone_biology',
        ],
        'optedOutSubjects': <String>[],
      });
      final repo = buildRepo(uid: 'charlie');

      final result =
          await repo.updateOptedOutSubjects(const ['anglophone_biology']);

      expect(result.isRight(), isTrue);
      final snap = await firestore.collection('users').doc('charlie').get();
      expect(snap.data()!['optedOutSubjects'], ['anglophone_biology']);
      expect(snap.data()!['updatedAt'], isNotNull);
    });

    test(
        '(l) updateOptedOutSubjects : pas d\'auth -> Left(ProfileFailure.notAuthenticated)',
        () async {
      final repo = buildRepo(uid: null);

      final result =
          await repo.updateOptedOutSubjects(const ['anglophone_biology']);

      expect(result.isLeft(), isTrue);
    });

    test(
        '(m) updateOptedOutSubjects : doc absent -> Left(ProfileFailure.firestoreError)',
        () async {
      // Aucun doc seede pour 'ghost' -> update() leve FirebaseException.
      final repo = buildRepo(uid: 'ghost');

      final result =
          await repo.updateOptedOutSubjects(const ['anglophone_biology']);

      expect(result.isLeft(), isTrue);
    });

    // ================================================================
    // Story 1.5.d — updateLinkedSchool() : denormalisation 4 champs
    // (schoolId + schoolCity + schoolRegion + schoolName) en 1 update partiel.
    // Refactor de updateSchoolId(String?) Story 1.7 -> updateLinkedSchool(School?).
    // ================================================================

    const testSchool = School(
      schoolId: 'school_bonaberi_dla',
      name: 'Lycee Bonaberi',
      city: 'Douala',
      region: 'Littoral',
      subSystem: 'francophone',
      isValidated: true,
    );

    test(
        '(d) Story 1.5.d — updateLinkedSchool(school) avec uid auth -> 4 champs coherents ecrits',
        () async {
      await firestore.collection('users').doc('delta').set(<String, dynamic>{
        'uid': 'delta',
        'schoolId': null,
        'schoolCity': null,
        'schoolRegion': null,
        'schoolName': null,
      });
      final repo = buildRepo(uid: 'delta');

      final result = await repo.updateLinkedSchool(testSchool);

      expect(result.isRight(), isTrue);
      final snap = await firestore.collection('users').doc('delta').get();
      final data = snap.data()!;
      expect(data['schoolId'], 'school_bonaberi_dla');
      expect(data['schoolCity'], 'Douala');
      expect(data['schoolRegion'], 'Littoral');
      expect(data['schoolName'], 'Lycee Bonaberi');
      expect(data['updatedAt'], isNotNull);
    });

    test(
        '(e) Story 1.5.d — updateLinkedSchool(null) avec uid auth -> 4 champs deviennent null (unlink coherent)',
        () async {
      // Seed un user deja lie (post Story 1.5.d, 4 champs cosmetiques renseignes).
      await firestore.collection('users').doc('epsilon').set(<String, dynamic>{
        'uid': 'epsilon',
        'schoolId': 'school_bonaberi_dla',
        'schoolCity': 'Douala',
        'schoolRegion': 'Littoral',
        'schoolName': 'Lycee Bonaberi',
      });
      final repo = buildRepo(uid: 'epsilon');

      final result = await repo.updateLinkedSchool(null);

      expect(result.isRight(), isTrue);
      final snap = await firestore.collection('users').doc('epsilon').get();
      final data = snap.data()!;
      expect(data['schoolId'], isNull);
      expect(data['schoolCity'], isNull);
      expect(data['schoolRegion'], isNull);
      expect(data['schoolName'], isNull);
      expect(data['updatedAt'], isNotNull);
    });

    test(
        '(f) Story 1.5.d — updateLinkedSchool sans uid -> Left(notAuthenticated) + aucune ecriture',
        () async {
      final repo = buildRepo(uid: null);

      final result = await repo.updateLinkedSchool(testSchool);

      expect(result.isLeft(), isTrue);
      // Aucun doc cree (preconditions getUid() == null -> early return).
      final all = await firestore.collection('users').get();
      expect(all.docs, isEmpty);
    });
  });
}
