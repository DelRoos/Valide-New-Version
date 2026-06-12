// Story E1bis-7 — Service qui ecrit le profil onboarding dans Firestore
// post-completion du flow (step 9). WriteBatch :
//   1. users/{uid} : set(merge: true) avec tous les champs E1bis schema
//      (trackId, levelId, streamId, pickedSubjects, phoneNumber, schoolId,
//      displayName, authProvider, isAnonymous, createdAt, updatedAt).
//   2. Pas de write school_requests ici : la demande d'ajout (si tapee)
//      est creee LIVE par SchoolSearchWithAdd via SchoolRepository au tap.
//
// Pattern fail-safe : si write echoue, retourne Left(OnboardingFlushFailure)
// — la SuccessCelebrationStepBody affiche un toast + retry.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/logging/perf_logger.dart';
import '../presentation/state/onboarding_state.dart';

class OnboardingFlushFailure {
  const OnboardingFlushFailure(this.message, {this.code});
  final String message;
  final String? code;
}

class OnboardingFlushService {
  OnboardingFlushService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Flush l'etat onboarding dans Firestore. Idempotent grace au
  /// `set(merge: true)` (peut etre rejoue si echec partiel).
  Future<Either<OnboardingFlushFailure, void>> flush(
      OnboardingState state) async {
    final user = _auth.currentUser;
    if (user == null) {
      AppLogger.w('flush: no current user');
      return const Left(OnboardingFlushFailure('not-authenticated'));
    }
    final uid = user.uid;

    try {
      final payload = <String, dynamic>{
        'uid': uid,
        ...state.toFirestorePayload(),
        'language': state.subSystem?.languageCode ?? 'fr',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await logPerf(
        'onboarding.flush.users',
        () => _firestore
            .collection('users')
            .doc(uid)
            .set(payload, SetOptions(merge: true)),
      );

      AppLogger.i(
        'flush OK uid=${uid.substring(0, 6)}... '
        'authProvider=${state.authProvider?.id} '
        'isAnonymous=${state.isVisitor} '
        'trackId=${state.trackId} levelId=${state.levelId} '
        'streamId=${state.streamId ?? "-"} '
        'subjects=${state.pickedSubjects.length} '
        'phoneSet=${state.phoneNumber != null} '
        'schoolSet=${state.schoolId != null || state.pendingSchoolRequestId != null}',
      );
      return const Right(null);
    } on FirebaseException catch (e, st) {
      AppLogger.w('flush Firebase error code=${e.code}', error: e);
      AppLogger.w('flush stack: $st');
      return Left(
        OnboardingFlushFailure(e.message ?? 'firebase-error', code: e.code),
      );
    } catch (e, st) {
      AppLogger.w('flush unexpected: $e', error: e);
      AppLogger.w('flush stack: $st');
      return Left(OnboardingFlushFailure(e.toString()));
    }
  }
}
