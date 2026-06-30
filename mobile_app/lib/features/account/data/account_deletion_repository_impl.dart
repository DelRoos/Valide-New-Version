// Story 1.10 — Impl de la suppression de compte (FR-7).
//
// 3 methodes :
//   - requestAccountDeletion / cancelAccountDeletion : via Cloud Functions callable
//   - deleteAccountNow : suppression immediate Firestore + Firebase Auth (sans CF)
//   - reauthenticateWithGoogle : re-auth via GoogleSignIn avant un deleteAccountNow
//     qui a echoue avec requires-recent-login
//
// Ordre deleteAccountNow :
//   0. Snapshot du doc Firestore (backup pour rollback).
//   1. Delete Firestore users/{uid} (auth encore valide -> permission OK).
//   2. Delete Firebase Auth user (peut echouer avec requires-recent-login).
//   Si etape 2 echoue -> rollback etape 1 (restaure le doc Firestore) pour
//   maintenir la coherence d'etat. Sans rollback, le router verrait filiereMissing
//   apres reset() et redirigerait vers /onboarding alors que le compte Google
//   est encore actif (Bug C 2026-06-30).
//
// CLAUDE.md securite 4 : aucun log d'uid, juste des booleens metier.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/logging/app_logger.dart';
import '../domain/account_deletion_failure.dart';
import '../domain/account_deletion_repository.dart';

/// Obtient un `GoogleSignInAccount` via le flux UI Google.
/// Throw `GoogleSignInException` si l'utilisateur annule ou si une erreur reseau
/// survient (code canceled / networkError / etc.).
typedef GoogleSignInForDeletionFn = Future<GoogleSignInAccount> Function();

class AccountDeletionRepositoryImpl implements AccountDeletionRepository {
  AccountDeletionRepositoryImpl(
    this._functions,
    this._auth,
    this._firestore, {
    required GoogleSignInForDeletionFn googleSignIn,
  }) : _googleSignIn = googleSignIn;

  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignInForDeletionFn _googleSignIn;

  static const String _kRequestFnName = 'requestAccountDeletion';
  static const String _kCancelFnName = 'cancelAccountDeletion';

  @override
  Future<Either<AccountDeletionFailure, void>> requestAccountDeletion() async {
    return _callFunction(
      fnName: _kRequestFnName,
      successLog: 'Account deletion requested',
    );
  }

  @override
  Future<Either<AccountDeletionFailure, void>> cancelAccountDeletion() async {
    return _callFunction(
      fnName: _kCancelFnName,
      successLog: 'Account deletion cancelled',
    );
  }

  @override
  Future<Either<AccountDeletionFailure, void>> deleteAccountNow() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return const Right(null);
      final uid = user.uid;

      // Etape 0 : snapshot avant suppression (backup pour rollback si Auth echoue).
      final snapshot = await _firestore.collection('users').doc(uid).get();
      final backup = snapshot.data();

      // Etape 1 : suppression Firestore pendant que l'auth est valide.
      await _firestore.collection('users').doc(uid).delete();

      // Etape 2 : suppression Firebase Auth (peut lever requires-recent-login).
      try {
        await user.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          AppLogger.w('Account delete requires recent login');
          // Rollback etape 1 : restaure le doc pour maintenir la coherence.
          if (backup != null) {
            try {
              await _firestore.collection('users').doc(uid).set(backup);
              AppLogger.i('Account delete rollback: Firestore doc restored');
            } catch (restoreErr) {
              AppLogger.w(
                'Account delete rollback failed: ${restoreErr.runtimeType}',
              );
            }
          }
          return const Left(AccountDeletionFailure.requiresRecentLogin());
        }
        AppLogger.w('Auth delete failed: code=${e.code}');
        return Left(AccountDeletionFailure.unknown('auth: ${e.code}'));
      }

      // Vide le cache Firestore offline pour ne pas exposer les donnees
      // de l'ancien compte aux futurs utilisateurs sur le meme appareil.
      try {
        await _firestore.terminate();
        await _firestore.clearPersistence();
        AppLogger.i('Account deleted, Firestore cache cleared');
      } catch (cacheErr) {
        AppLogger.w('Firestore cache clear failed: ${cacheErr.runtimeType}');
        AppLogger.i('Account deleted (cache clear skipped)');
      }
      return const Right(null);
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
        AppLogger.w('Firestore delete network failure');
        return const Left(AccountDeletionFailure.network());
      }
      AppLogger.w('Firestore delete failed: code=${e.code}');
      return Left(AccountDeletionFailure.unknown('firestore: ${e.code}'));
    } catch (e) {
      AppLogger.w('Account delete failed: ${e.runtimeType}');
      return Left(AccountDeletionFailure.unknown(e.toString()));
    }
  }

  @override
  Future<Either<AccountDeletionFailure, void>> reauthenticateWithGoogle() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        AppLogger.w('Reauth Google: no current user');
        return Left(AccountDeletionFailure.unknown('no current user'));
      }

      final account = await _googleSignIn();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        AppLogger.w('Reauth Google: idToken null after authenticate()');
        return Left(AccountDeletionFailure.unknown('Google idToken absent'));
      }

      // accessToken optionnel (identique au pattern linkGoogle).
      String? accessToken;
      try {
        final auth = await account.authorizationClient.authorizationForScopes(
          const ['email', 'profile'],
        );
        accessToken = auth?.accessToken;
      } catch (_) {
        // Non-bloquant : on continue avec idToken seul.
      }

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );
      await user.reauthenticateWithCredential(credential);
      AppLogger.i('Reauth Google succeeded');
      return const Right(null);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        AppLogger.w('Reauth Google: user cancelled');
        return const Left(AccountDeletionFailure.requiresRecentLogin());
      }
      AppLogger.w('Reauth Google failed: ${e.code}');
      return Left(AccountDeletionFailure.unknown('google: ${e.code}'));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-mismatch') {
        AppLogger.w('Reauth Google: user-mismatch — mauvais compte Google sélectionné');
        return const Left(AccountDeletionFailure.wrongAccount());
      }
      AppLogger.w('Reauth Firebase failed: code=${e.code}');
      return Left(AccountDeletionFailure.unknown('auth: ${e.code}'));
    } catch (e) {
      AppLogger.w('Reauth failed: ${e.runtimeType}');
      return Left(AccountDeletionFailure.unknown(e.toString()));
    }
  }

  Future<Either<AccountDeletionFailure, void>> _callFunction({
    required String fnName,
    required String successLog,
  }) async {
    try {
      await _functions.httpsCallable(fnName).call<dynamic>(<String, dynamic>{});
      AppLogger.i(successLog);
      return const Right(null);
    } on FirebaseFunctionsException catch (e) {
      return Left(_mapFunctionsException(fnName, e));
    } catch (e) {
      AppLogger.w('$fnName failed: ${e.runtimeType}');
      return Left(AccountDeletionFailure.unknown(e.toString()));
    }
  }

  AccountDeletionFailure _mapFunctionsException(
    String fnName,
    FirebaseFunctionsException e,
  ) {
    switch (e.code) {
      case 'not-found':
        AppLogger.w('$fnName not deployed (backend pending)');
        return const AccountDeletionFailure.functionNotFound();
      case 'unavailable':
      case 'deadline-exceeded':
        AppLogger.w('$fnName network failure');
        return const AccountDeletionFailure.network();
      default:
        AppLogger.w('$fnName failed: code=${e.code}');
        return AccountDeletionFailure.unknown('${e.code}: ${e.message ?? ''}');
    }
  }
}
