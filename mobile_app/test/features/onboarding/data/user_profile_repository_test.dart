// Story 1.3 — Tests UserProfileRepositoryFirestoreImpl avec fake_cloud_firestore.
//
// Le repo recoit une `getUid` callback (typedef GetUidFn) injectee — pas de
// dependance directe a FirebaseAuth, donc pas besoin de firebase_auth_mocks
// (absent du pubspec).

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:valide_school/features/onboarding/data/user_profile_repository_firestore_impl.dart';
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
  });
}
