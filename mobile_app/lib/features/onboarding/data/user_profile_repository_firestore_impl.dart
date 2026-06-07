// Story 1.3 — Implementation Firestore du UserProfileRepository.
//
// Couche data : peut importer Firebase. Traduit FirebaseException -> ProfileFailure
// (NFR-7). Utilise FieldValue.serverTimestamp() pour les timestamps + set(merge:true)
// pour l'idempotence (un retap "C'est ma classe" apres echec reseau ne duplique
// pas le doc).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/logging/app_logger.dart';
import '../domain/profile_failure.dart';
import '../domain/sub_system.dart';
import '../domain/user_profile_repository.dart';

/// Source d'uid injectee — wrap FirebaseAuth en prod, retourne un uid mock
/// en test. Evite la dependance directe a `FirebaseAuth` dans le repo et
/// permet les tests sans `firebase_auth_mocks` (non present au pubspec).
typedef GetUidFn = String? Function();

class UserProfileRepositoryFirestoreImpl implements UserProfileRepository {
  UserProfileRepositoryFirestoreImpl({
    required FirebaseFirestore firestore,
    required GetUidFn getUid,
  })  : _firestore = firestore,
        _getUid = getUid;

  final FirebaseFirestore _firestore;
  final GetUidFn _getUid;

  static const String _kCollection = 'users';

  @override
  Future<Either<ProfileFailure, void>> createProfile({
    required SubSystem subSystem,
    required String filiereId,
    required String niveauId,
    required String serieId,
    required List<String> derivedSubjects,
    required List<String> examTargets,
  }) async {
    final uid = _getUid();
    if (uid == null) {
      AppLogger.w('createProfile() aborted: no current user uid');
      return const Left(ProfileFailure.notAuthenticated());
    }

    final payload = <String, dynamic>{
      'uid': uid,
      'subSystem': subSystem.id,
      'language': subSystem.languageCode,
      'filiere': filiereId,
      'niveau': niveauId,
      'serie': serieId,
      'derivedSubjects': derivedSubjects,
      'optedOutSubjects': <String>[],
      'examTargets': examTargets,
      'schoolId': null,
      'displayName': '',
      'photoUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'deletionRequestedAt': null,
    };

    try {
      await _firestore
          .collection(_kCollection)
          .doc(uid)
          .set(payload, SetOptions(merge: true));
      // CLAUDE.md § Securite : on log subSystem + niveau + count, JAMAIS l'uid.
      AppLogger.i(
        'Profile created: subSystem=${subSystem.id} '
        'niveau=$niveauId serie=$serieId '
        'subjects=${derivedSubjects.length} examTargets=${examTargets.length}',
      );
      return const Right(null);
    } on FirebaseException catch (e, st) {
      AppLogger.w(
        'createProfile() FirebaseException: ${e.code} ${e.message}',
        error: e,
      );
      AppLogger.w('createProfile() stack: $st');
      return Left(
        ProfileFailure.firestoreError(e.message ?? 'Firebase: ${e.code}'),
      );
    } catch (e, st) {
      AppLogger.w('createProfile() unexpected error: $e', error: e);
      AppLogger.w('createProfile() stack: $st');
      return Left(ProfileFailure.firestoreError(e.toString()));
    }
  }
}
