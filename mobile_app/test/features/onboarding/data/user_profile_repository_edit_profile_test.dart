// Story A.1 — Tests updateDisplayName() + updatePhoneNumber()
// dans UserProfileRepositoryFirestoreImpl.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:valide_school/features/onboarding/data/user_profile_repository_firestore_impl.dart';

void main() {
  group('UserProfileRepositoryFirestoreImpl — Story A.1', () {
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
        'displayName': 'Ancien nom',
        'phoneNumber': null,
      });
    }

    // ── updateDisplayName ───────────────────────────────────────────────────

    group('updateDisplayName()', () {
      test('succès → Right(null) et champ Firestore mis à jour', () async {
        const uid = 'test_uid';
        await seedUser(uid);
        final repo = buildRepo(uid: uid);

        final result = await repo.updateDisplayName('Fatou');

        expect(result.isRight(), isTrue);
        final snap = await firestore.collection('users').doc(uid).get();
        expect(snap.data()?['displayName'], 'Fatou');
      });

      test('uid absent → Left(notAuthenticated)', () async {
        final repo = buildRepo(uid: null);
        final result = await repo.updateDisplayName('Fatou');
        expect(result.isLeft(), isTrue);
      });
    });

    // ── updatePhoneNumber ───────────────────────────────────────────────────

    group('updatePhoneNumber()', () {
      test('numéro valide → Right(null) et champ Firestore mis à jour',
          () async {
        const uid = 'test_uid';
        await seedUser(uid);
        final repo = buildRepo(uid: uid);

        final result = await repo.updatePhoneNumber('+237671234567');

        expect(result.isRight(), isTrue);
        final snap = await firestore.collection('users').doc(uid).get();
        expect(snap.data()?['phoneNumber'], '+237671234567');
      });

      test('null efface le champ', () async {
        const uid = 'test_uid';
        await firestore.collection('users').doc(uid).set({
          'uid': uid,
          'phoneNumber': '+237671234567',
        });
        final repo = buildRepo(uid: uid);

        final result = await repo.updatePhoneNumber(null);

        expect(result.isRight(), isTrue);
        final snap = await firestore.collection('users').doc(uid).get();
        expect(snap.data()?['phoneNumber'], isNull);
      });

      test('uid absent → Left(notAuthenticated)', () async {
        final repo = buildRepo(uid: null);
        final result = await repo.updatePhoneNumber('+237671234567');
        expect(result.isLeft(), isTrue);
      });
    });
  });
}
