// Story 1.3 — Implementation Firestore du UserProfileRepository.
//
// Couche data : peut importer Firebase. Traduit FirebaseException -> ProfileFailure
// (NFR-7). Utilise FieldValue.serverTimestamp() pour les timestamps + set(merge:true)
// pour l'idempotence (un retap "C'est ma classe" apres echec reseau ne duplique
// pas le doc).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/logging/perf_logger.dart';
import '../domain/profile_failure.dart';
import '../domain/school.dart';
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
      await logPerf(
        'users.create',
        () => _firestore
            .collection(_kCollection)
            .doc(uid)
            .set(payload, SetOptions(merge: true)),
      );
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
        ProfileFailure.firestoreError(e.message ?? "Firebase: ${e.code}", code: e.code),
      );
    } catch (e, st) {
      AppLogger.w('createProfile() unexpected error: $e', error: e);
      AppLogger.w('createProfile() stack: $st');
      return Left(ProfileFailure.firestoreError(e.toString()));
    }
  }

  // ===================================================================
  // Story 1.5 — watchProfile() : stream users/{uid} pour garde nav (FR-4)
  // ===================================================================

  @override
  Stream<Map<String, dynamic>?> watchProfile() {
    final uid = _getUid();
    if (uid == null) {
      // Auth absente : on emet null immediatement. Le provider en aval
      // traduira en ProfileCompletionState.filiereMissing avec un log warn.
      return Stream.value(null);
    }
    return _firestore
        .collection(_kCollection)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null)
        .handleError((Object e, StackTrace st) {
      // L'erreur est attrappee ici (log) mais re-propagee au stream pour
      // que le provider la traduise en filiereMissing fail-safe (AC6).
      // CLAUDE.md securite 4 : on ne logue JAMAIS l'uid complet, seulement
      // le code d'erreur et le type d'exception.
      final reason = e is FirebaseException ? e.code : e.runtimeType.toString();
      AppLogger.w('watchProfile() stream error reason=$reason');
    });
  }

  // ===================================================================
  // Story 1.4 — updateOptedOutSubjects() : retrait conditionnel matieres (FR-3)
  // ===================================================================

  @override
  Future<Either<ProfileFailure, void>> updateOptedOutSubjects(
    List<String> optedOutSubjectIds,
  ) async {
    final uid = _getUid();
    if (uid == null) {
      AppLogger.w('updateOptedOutSubjects() aborted: no current user uid');
      return const Left(ProfileFailure.notAuthenticated());
    }

    try {
      await logPerf(
        'users.update.optedOut',
        () => _firestore.collection(_kCollection).doc(uid).update({
          'optedOutSubjects': optedOutSubjectIds,
          'updatedAt': FieldValue.serverTimestamp(),
        }),
      );
      // CLAUDE.md securite 4 : on log count, JAMAIS la liste des IDs
      // (combinaison niveau + matieres retirees peut identifier un eleve).
      AppLogger.i(
        'Subjects opted out: count=${optedOutSubjectIds.length}',
      );
      return const Right(null);
    } on FirebaseException catch (e, st) {
      AppLogger.w(
        'updateOptedOutSubjects() FirebaseException: ${e.code} ${e.message}',
        error: e,
      );
      AppLogger.w('updateOptedOutSubjects() stack: $st');
      return Left(
        ProfileFailure.firestoreError(e.message ?? "Firebase: ${e.code}", code: e.code),
      );
    } catch (e, st) {
      AppLogger.w('updateOptedOutSubjects() unexpected error: $e', error: e);
      AppLogger.w('updateOptedOutSubjects() stack: $st');
      return Left(ProfileFailure.firestoreError(e.toString()));
    }
  }

  // ===================================================================
  // Story 1.15 — updatePickedSubjects() : panier polymorphe (FR-3 mode
  // free_with_obligatory / series_plus_optional / tve_picker)
  // ===================================================================

  @override
  Future<Either<ProfileFailure, void>> updatePickedSubjects(
    List<String> pickedSubjectIds,
  ) async {
    final uid = _getUid();
    if (uid == null) {
      AppLogger.w('updatePickedSubjects() aborted: no current user uid');
      return const Left(ProfileFailure.notAuthenticated());
    }

    try {
      await logPerf(
        'users.update.picked',
        () => _firestore.collection(_kCollection).doc(uid).update({
          'pickedSubjects': pickedSubjectIds,
          'updatedAt': FieldValue.serverTimestamp(),
        }),
      );
      // CLAUDE.md securite 4 : on log count uniquement, JAMAIS les IDs
      // (combinaison niveau + matieres peut identifier un eleve).
      AppLogger.i(
        'Subjects picked: count=${pickedSubjectIds.length}',
      );
      return const Right(null);
    } on FirebaseException catch (e, st) {
      AppLogger.w(
        'updatePickedSubjects() FirebaseException: ${e.code} ${e.message}',
        error: e,
      );
      AppLogger.w('updatePickedSubjects() stack: $st');
      return Left(
        ProfileFailure.firestoreError(e.message ?? "Firebase: ${e.code}", code: e.code),
      );
    } catch (e, st) {
      AppLogger.w('updatePickedSubjects() unexpected error: $e', error: e);
      AppLogger.w('updatePickedSubjects() stack: $st');
      return Left(ProfileFailure.firestoreError(e.toString()));
    }
  }

  // ===================================================================
  // Story 1.5.d — updateLinkedSchool() : liaison ecole + denorm 4 champs (FR-6)
  //
  // Ecrit en 1 seul update partiel (CLAUDE.md regle 10.l) les 4 champs
  // schoolId/schoolCity/schoolRegion/schoolName (ou tous null si unlink).
  // L'entite School est passee par le caller (school_picker_page : tap card
  // -> entite deja disponible) -> 0 read supplementaire schools/{id} (regle
  // 10.k). Prepare downstream : Epic 2+ dashboard, Epic 5 rankings regionaux,
  // Epic 6 IA contextualisee.
  // ===================================================================

  @override
  Future<Either<ProfileFailure, void>> updateLinkedSchool(School? school) async {
    final uid = _getUid();
    if (uid == null) {
      AppLogger.w('updateLinkedSchool() aborted: no current user uid');
      return const Left(ProfileFailure.notAuthenticated());
    }

    try {
      await logPerf(
        'users.update.linkedSchool',
        () => _firestore.collection(_kCollection).doc(uid).update({
          'schoolId': school?.schoolId,
          'schoolCity': school?.city,
          'schoolRegion': school?.region,
          'schoolName': school?.name,
          'updatedAt': FieldValue.serverTimestamp(),
        }),
      );
      // schoolId est public (identifiant catalogue), OK a logger. city OK
      // (catalogue public). CLAUDE.md securite 4 : on ne logue PAS l'uid
      // ni le nom complet du user.
      AppLogger.i(
        'School linked: schoolId=${school?.schoolId ?? "(null)"} '
        'city=${school?.city ?? "(null)"}',
      );
      return const Right(null);
    } on FirebaseException catch (e, st) {
      AppLogger.w(
        'updateLinkedSchool() FirebaseException: ${e.code} ${e.message}',
        error: e,
      );
      AppLogger.w('updateLinkedSchool() stack: $st');
      return Left(
        ProfileFailure.firestoreError(e.message ?? "Firebase: ${e.code}", code: e.code),
      );
    } catch (e, st) {
      AppLogger.w('updateLinkedSchool() unexpected error: $e', error: e);
      AppLogger.w('updateLinkedSchool() stack: $st');
      return Left(ProfileFailure.firestoreError(e.toString()));
    }
  }
}
