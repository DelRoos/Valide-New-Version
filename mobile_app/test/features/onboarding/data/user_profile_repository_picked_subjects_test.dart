// Story 1.15 AC4 — Tests UserProfileRepositoryFirestoreImpl.updatePickedSubjects
// avec fake_cloud_firestore.
//
// Couvre 2 cas :
//   (a) doc users/{uid} existant -> .update() partiel pose pickedSubjects +
//       updatedAt, retourne Right(null)
//   (b) doc absent -> FirebaseException -> Left(ProfileFailure.firestoreError)
//
// Pattern symetrique a `user_profile_repository_test.dart` Story 1.4
// updateOptedOutSubjects (test l, m). Le repo recoit une `getUid` callback
// injectee, donc pas besoin de firebase_auth_mocks.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:valide_school/features/onboarding/data/user_profile_repository_firestore_impl.dart';

void main() {
  group('UserProfileRepositoryFirestoreImpl.updatePickedSubjects — Story 1.15',
      () {
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

    test(
        '(a) doc existant -> pose pickedSubjects + updatedAt sans toucher '
        'aux autres champs',
        () async {
      // Mariam Form 5 : doc seede par createProfile (Story 1.3) qui n'a pas
      // encore pose pickedSubjects (champ optionnel BASE-DE-DONNEES.md ligne
      // 71-76 -- absent sur profils v1).
      await firestore.collection('users').doc('mariam').set(<String, dynamic>{
        'uid': 'mariam',
        'subSystem': 'anglophone',
        'language': 'en',
        'filiere': 'generale',
        'niveau': 'anglophone_form_5',
        'serie': '-',
        'derivedSubjects': const [
          'anglophone_english_lang',
          'anglophone_french',
          'anglophone_math',
          'anglophone_physics',
          'anglophone_chemistry',
          'anglophone_biology',
          'anglophone_geography',
          'anglophone_history',
          'anglophone_citizenship',
          'anglophone_computer_science',
          'anglophone_religion',
        ],
        'optedOutSubjects': <String>[],
        'displayName': 'Mariam',
      });

      final repo = buildRepo(uid: 'mariam');
      final result = await repo.updatePickedSubjects(const [
        'anglophone_english_lang',
        'anglophone_french',
        'anglophone_math',
        'anglophone_physics',
        'anglophone_chemistry',
        'anglophone_biology',
        'anglophone_geography',
        'anglophone_history',
      ]);

      expect(result.isRight(), isTrue);
      final snap = await firestore.collection('users').doc('mariam').get();
      final data = snap.data()!;
      // pickedSubjects pose en BD avec la liste oblig+optionnels.
      expect(data['pickedSubjects'], [
        'anglophone_english_lang',
        'anglophone_french',
        'anglophone_math',
        'anglophone_physics',
        'anglophone_chemistry',
        'anglophone_biology',
        'anglophone_geography',
        'anglophone_history',
      ]);
      // updatedAt pose par serverTimestamp.
      expect(data['updatedAt'], isNotNull);
      // Autres champs preserves (CLAUDE.md regle 10.l : update partiel).
      expect(data['subSystem'], 'anglophone');
      expect(data['niveau'], 'anglophone_form_5');
      expect(data['displayName'], 'Mariam');
    });

    test('(b) doc absent -> Left(ProfileFailure.firestoreError)', () async {
      final repo = buildRepo(uid: 'ghost');

      final result = await repo.updatePickedSubjects(const [
        'anglophone_english_lang',
        'anglophone_french',
        'anglophone_math',
      ]);

      expect(result.isLeft(), isTrue);
    });

    test('(c) pas d\'auth -> Left(ProfileFailure.notAuthenticated)', () async {
      final repo = buildRepo(uid: null);

      final result = await repo.updatePickedSubjects(const [
        'anglophone_english_lang',
      ]);

      expect(result.isLeft(), isTrue);
    });
  });
}
