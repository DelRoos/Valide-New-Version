// Story A.3 — Tests updateSchoolProfile() dans UserProfileRepositoryFirestoreImpl.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:valide_school/features/onboarding/data/user_profile_repository_firestore_impl.dart';

void main() {
  group('UserProfileRepositoryFirestoreImpl — Story A.3 updateSchoolProfile()', () {
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

    Future<void> seedUser(String uid) async {
      await firestore.collection('users').doc(uid).set({
        'uid': uid,
        'subSystem': 'francophone',
        'trackId': 'generale',
        'levelId': 'francophone_premiere',
        'streamId': 'francophone_premiere_d',
        'derivedSubjects': ['math', 'physique'],
        'examTargets': ['probatoire'],
        'pickedSubjects': ['math', 'physique'],
        'optedOutSubjects': <String>[],
      });
    }

    // ── succès ────────────────────────────────────────────────────────────────

    test('succès → Right(null) + 7 champs mis à jour en Firestore', () async {
      const uid = 'uid_test';
      await seedUser(uid);
      final repo = buildRepo(uid: uid);

      final result = await repo.updateSchoolProfile(
        trackId: 'generale',
        levelId: 'francophone_terminale',
        streamId: 'francophone_terminale_d',
        derivedSubjects: ['math', 'physique', 'svt'],
        examTargets: ['bac'],
        pickedSubjects: ['math', 'physique', 'svt'],
        optedOutSubjects: [],
      );

      expect(result.isRight(), isTrue);
      final snap = await firestore.collection('users').doc(uid).get();
      final data = snap.data()!;
      expect(data['levelId'], 'francophone_terminale');
      expect(data['streamId'], 'francophone_terminale_d');
      expect(data['derivedSubjects'], ['math', 'physique', 'svt']);
      expect(data['examTargets'], ['bac']);
      expect(data['pickedSubjects'], ['math', 'physique', 'svt']);
      expect(data['optedOutSubjects'], isEmpty);
      // subSystem est inchangé (immuable)
      expect(data['subSystem'], 'francophone');
    });

    // ── erreur auth ───────────────────────────────────────────────────────────

    test('uid absent → Left(notAuthenticated)', () async {
      final repo = buildRepo(uid: null);
      final result = await repo.updateSchoolProfile(
        trackId: 'generale',
        levelId: 'francophone_terminale',
        streamId: 'francophone_terminale_d',
        derivedSubjects: ['math'],
        examTargets: ['bac'],
        pickedSubjects: ['math'],
        optedOutSubjects: [],
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f.kind.name, 'notAuthenticated'),
        (_) => fail('attendu Left'),
      );
    });

    // ── idempotence ───────────────────────────────────────────────────────────

    test('double appel → seul le dernier état est persisité', () async {
      const uid = 'uid_idem';
      await seedUser(uid);
      final repo = buildRepo(uid: uid);

      await repo.updateSchoolProfile(
        trackId: 'generale',
        levelId: 'francophone_terminale',
        streamId: 'francophone_terminale_d',
        derivedSubjects: ['math'],
        examTargets: ['bac'],
        pickedSubjects: ['math'],
        optedOutSubjects: [],
      );
      final result = await repo.updateSchoolProfile(
        trackId: 'generale',
        levelId: 'francophone_terminale',
        streamId: 'francophone_terminale_s2',
        derivedSubjects: ['physique', 'svt'],
        examTargets: ['bac'],
        pickedSubjects: ['physique', 'svt'],
        optedOutSubjects: [],
      );

      expect(result.isRight(), isTrue);
      final snap = await firestore.collection('users').doc(uid).get();
      expect(snap.data()?['streamId'], 'francophone_terminale_s2');
      expect(snap.data()?['derivedSubjects'], ['physique', 'svt']);
    });
  });
}
