// Story A.2 — Tests fetchPublicProfile() dans UserProfileRepositoryFirestoreImpl.
//
// Cas couverts :
// (a) doc existant (schema E1bis levelId/streamId) → Right(PublicProfile)
// (b) doc existant (schema legacy niveau/serie) → Right(PublicProfile) rétrocompat
// (c) doc absent → Right(null)
// (d) caller non authentifié → Left(notAuthenticated)

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:valide_school/features/onboarding/data/user_profile_repository_firestore_impl.dart';
import 'package:valide_school/features/onboarding/domain/profile_failure.dart';

void main() {
  group('UserProfileRepositoryFirestoreImpl — fetchPublicProfile() (Story A.2)',
      () {
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
    });

    UserProfileRepositoryFirestoreImpl buildRepo({String? callerUid}) {
      return UserProfileRepositoryFirestoreImpl(
        firestore: firestore,
        getUid: () => callerUid,
      );
    }

    // (a) doc E1bis ──────────────────────────────────────────────────────────

    test('(a) doc E1bis → Right(PublicProfile) avec champs corrects', () async {
      const targetUid = 'uid-fatou';
      await firestore.collection('users').doc(targetUid).set({
        'displayName': 'Fatou',
        'levelId': 'terminale',
        'streamId': 'francophone_terminale_d',
        'schoolName': 'Lycée Leclerc',
        'subSystem': 'francophone',
      });

      final repo = buildRepo(callerUid: 'uid-caller');
      final result = await repo.fetchPublicProfile(targetUid);

      expect(result.isRight(), isTrue);
      final profile = result.getOrElse((_) => throw AssertionError());
      expect(profile, isNotNull);
      expect(profile!.uid, targetUid);
      expect(profile.displayName, 'Fatou');
      expect(profile.levelId, 'terminale');
      expect(profile.streamId, 'francophone_terminale_d');
      expect(profile.schoolName, 'Lycée Leclerc');
      expect(profile.subSystem, 'francophone');
    });

    // (b) doc legacy ─────────────────────────────────────────────────────────

    test('(b) doc legacy (niveau/serie) → Right(PublicProfile) rétrocompat',
        () async {
      const targetUid = 'uid-jean';
      await firestore.collection('users').doc(targetUid).set({
        'displayName': 'Jean-Paul',
        'niveau': 'terminale',
        'serie': 'francophone_terminale_a1',
        'subSystem': 'francophone',
      });

      final repo = buildRepo(callerUid: 'uid-caller');
      final result = await repo.fetchPublicProfile(targetUid);

      expect(result.isRight(), isTrue);
      final profile = result.getOrElse((_) => throw AssertionError());
      expect(profile, isNotNull);
      expect(profile!.levelId, 'terminale');
      expect(profile.streamId, 'francophone_terminale_a1');
    });

    // (c) doc absent ─────────────────────────────────────────────────────────

    test('(c) doc absent → Right(null)', () async {
      final repo = buildRepo(callerUid: 'uid-caller');
      final result = await repo.fetchPublicProfile('uid-inexistant');

      expect(result.isRight(), isTrue);
      final profile = result.getOrElse((_) => throw AssertionError());
      expect(profile, isNull);
    });

    // (d) caller non authentifié ─────────────────────────────────────────────

    test('(d) caller uid absent → Left(notAuthenticated)', () async {
      final repo = buildRepo(callerUid: null);
      final result = await repo.fetchPublicProfile('uid-quelconque');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(
          failure.kind,
          ProfileFailureKind.notAuthenticated,
        ),
        (_) => throw AssertionError('Expected Left'),
      );
    });
  });
}
