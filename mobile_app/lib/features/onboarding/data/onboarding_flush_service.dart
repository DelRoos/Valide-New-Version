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
import '../../../core/logging/log_safe.dart';
import '../../../core/logging/perf_logger.dart';
import '../presentation/state/onboarding_state.dart';
import 'onboarding_draft_prefs.dart';

class OnboardingFlushFailure {
  const OnboardingFlushFailure(this.message, {this.code});
  final String message;
  final String? code;
}

class OnboardingFlushService {
  OnboardingFlushService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required OnboardingDraftPrefs draftPrefs,
  })  : _auth = auth,
        _firestore = firestore,
        _draftPrefs = draftPrefs;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final OnboardingDraftPrefs _draftPrefs;

  /// Flush l'etat onboarding dans Firestore. Idempotent grace au
  /// `set(merge: true)` (peut etre rejoue si echec partiel).
  ///
  /// Logs : avant ecriture, on dump la cle de chaque champ du payload pour
  /// diagnostiquer permission-denied (regle Firestore qui rejette un champ
  /// requis manquant). Le numero de telephone passe par `maskPhone()`
  /// (CLAUDE.md regle 4 securite).
  Future<Either<OnboardingFlushFailure, void>> flush(
      OnboardingState state) async {
    final user = _auth.currentUser;
    if (user == null) {
      AppLogger.w('flush: no current user (auth required)');
      return const Left(OnboardingFlushFailure('not-authenticated'));
    }
    final uid = user.uid;
    final uidShort = uid.length >= 6 ? '${uid.substring(0, 6)}...' : uid;

    try {
      final docRef = _firestore.collection('users').doc(uid);

      // Fix runtime 2026-06-13 : verifier l'existence AVANT d'inclure
      // `createdAt` dans le payload. La regle UPDATE exige `createdAt`
      // immuable — un set(merge: true) qui ecrit serverTimestamp() a chaque
      // flush ferait toujours echouer la regle (nouvelle timestamp != stockee).
      final existing = await docRef.get();
      final isCreate = !existing.exists;

      final payload = <String, dynamic>{
        'uid': uid,
        ...state.toFirestorePayload(),
        'language': state.subSystem?.languageCode ?? 'fr',
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (isCreate) {
        payload['createdAt'] = FieldValue.serverTimestamp();
      }

      AppLogger.i(
        'flush START uid=$uidShort '
        'isAuthUser=${!user.isAnonymous} firebaseAnonymous=${user.isAnonymous} '
        'docExists=${!isCreate} -> ${isCreate ? "CREATE" : "UPDATE"}',
      );
      AppLogger.i(
        'flush PAYLOAD '
        'subSystem=${payload['subSystem']} '
        'language=${payload['language']} '
        'trackId=${payload['trackId']} '
        'levelId=${payload['levelId']} '
        'streamId=${payload['streamId'] ?? "<null>"} '
        'pickedSubjects=${(payload['pickedSubjects'] as List).length} items '
        'displayName=${maskName(payload['displayName'] as String?)} '
        'phoneNumber=${maskPhone(payload['phoneNumber'] as String?)} '
        'schoolId=${payload['schoolId'] ?? "<null>"} '
        'schoolName=${payload['schoolName'] ?? "<null>"} '
        'pendingSchoolRequestId=${payload['pendingSchoolRequestId'] ?? "<null>"} '
        'authProvider=${payload['authProvider'] ?? "<null>"} '
        'isAnonymous=${payload['isAnonymous']}',
      );
      AppLogger.i(
        'flush MISSING_FIELDS_CHECK '
        'subSystem=${payload.containsKey('subSystem')} '
        'language=${payload.containsKey('language')} '
        'trackId=${payload.containsKey('trackId')} '
        'levelId=${payload.containsKey('levelId')} '
        'pickedSubjects=${payload.containsKey('pickedSubjects')} '
        'displayName=${payload.containsKey('displayName')} '
        'authProvider=${payload.containsKey('authProvider')} '
        'isAnonymous=${payload.containsKey('isAnonymous')}',
      );

      await logPerf(
        'onboarding.flush.users',
        () => _firestore
            .collection('users')
            .doc(uid)
            .set(payload, SetOptions(merge: true)),
      );

      AppLogger.i(
        'flush OK uid=$uidShort '
        'authProvider=${state.authProvider?.id} '
        'isAnonymous=${state.isVisitor} '
        'trackId=${state.trackId} levelId=${state.levelId} '
        'streamId=${state.streamId ?? "-"} '
        'subjects=${state.pickedSubjects.length} '
        'phone=${maskPhone(state.phoneNumber)} '
        'schoolSet=${state.schoolId != null || state.pendingSchoolRequestId != null}',
      );
      // Audit 2026-06-13 (PR1) — Apres flush success, le doc users/{uid}
      // est source de verite : on clear le draft persiste pour eviter
      // que loadFromPersistence le restaure au prochain boot.
      try {
        await _draftPrefs.clear();
      } catch (e) {
        AppLogger.w('flush draft clear failed (non-blocking): $e');
      }
      return const Right(null);
    } on FirebaseException catch (e, st) {
      AppLogger.w(
        'flush Firebase error code=${e.code} '
        'message="${e.message}" plugin=${e.plugin} uid=$uidShort',
        error: e,
      );
      AppLogger.w('flush stack: $st');
      return Left(
        OnboardingFlushFailure(e.message ?? 'firebase-error', code: e.code),
      );
    } catch (e, st) {
      AppLogger.w('flush unexpected: $e uid=$uidShort', error: e);
      AppLogger.w('flush stack: $st');
      return Left(OnboardingFlushFailure(e.toString()));
    }
  }
}
