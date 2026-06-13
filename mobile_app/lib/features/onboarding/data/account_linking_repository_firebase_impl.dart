// Story 1.6 — Impl Firebase du linking de compte anonyme vers Google/Apple.
//
// Couche data : peut importer Firebase / Google / Apple. Traduit les
// exceptions en `AccountLinkingFailure` (NFR-7).
//
// Pattern de testabilite : les actions externes (signIn Google, signIn Apple,
// linkWithCredential, update Firestore) sont injectees via fonctions typedef.
// En prod : wrap les singletons. En test : injecte des fakes qui throw les
// exceptions cibles.

import 'dart:async';
import 'dart:io' show SocketException;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/logging/perf_logger.dart';
import '../domain/account_linking_failure.dart';
import '../domain/account_linking_repository.dart';
import '../domain/linked_account.dart';

/// Action de sign-in Google. Retourne `GoogleSignInAccount` ou throw
/// `GoogleSignInException` (canceled / network / etc.).
typedef GoogleSignInFn = Future<GoogleSignInAccount> Function();

/// Action de sign-in Apple. Retourne `AuthorizationCredentialAppleID` ou
/// throw `SignInWithAppleAuthorizationException` (canceled / etc.).
typedef AppleSignInFn = Future<AuthorizationCredentialAppleID> Function();

/// Action `linkWithCredential` sur le currentUser. Throw FirebaseAuthException
/// avec codes `credential-already-in-use`, `provider-already-linked`,
/// `network-request-failed`, etc.
typedef LinkCredentialFn = Future<UserCredential> Function(
  AuthCredential credential,
);

class AccountLinkingRepositoryFirebaseImpl implements AccountLinkingRepository {
  AccountLinkingRepositoryFirebaseImpl({
    required FirebaseFirestore firestore,
    required GoogleSignInFn googleSignIn,
    required AppleSignInFn appleSignIn,
    required LinkCredentialFn linkCredential,
  })  : _firestore = firestore,
        _googleSignIn = googleSignIn,
        _appleSignIn = appleSignIn,
        _linkCredential = linkCredential;

  final FirebaseFirestore _firestore;
  final GoogleSignInFn _googleSignIn;
  final AppleSignInFn _appleSignIn;
  final LinkCredentialFn _linkCredential;

  static const String _kCollection = 'users';

  @override
  Future<Either<AccountLinkingFailure, LinkedAccount>> linkGoogle() async {
    try {
      final account = await logPerf('auth.google.signIn', _googleSignIn);
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        AppLogger.w('linkGoogle: idToken null after authenticate()');
        return const Left(
          AccountLinkingFailure.unknown('Google idToken absent'),
        );
      }

      // accessToken optionnel pour GoogleAuthProvider.credential().
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
      final result = await logPerf(
        'auth.google.linkCredential',
        () => _linkCredential(credential),
      );

      final uid = result.user!.uid;
      final displayName = result.user!.displayName ?? account.displayName;
      final photoUrl = result.user!.photoURL ?? account.photoUrl;

      await _persistIdentity(
        uid,
        displayName,
        photoUrl,
        authProvider: 'google',
      );

      _logSuccess(provider: 'google', uid: uid);
      return Right(
        LinkedAccount(
          uid: uid,
          provider: AccountProvider.google,
          displayName: displayName,
          photoUrl: photoUrl,
        ),
      );
    } on GoogleSignInException catch (e) {
      return Left(_mapGoogleException(e));
    } on FirebaseAuthException catch (e, st) {
      return Left(_mapFirebaseAuth('google', e, st));
    } on SocketException catch (_) {
      AppLogger.w('linkGoogle: SocketException -> network');
      return const Left(AccountLinkingFailure.network());
    } catch (e, st) {
      AppLogger.w('linkGoogle: unexpected error: $e', error: e);
      AppLogger.w('linkGoogle stack: $st');
      return Left(AccountLinkingFailure.unknown(e.toString()));
    }
  }

  @override
  Future<Either<AccountLinkingFailure, LinkedAccount>> linkApple() async {
    try {
      final apple = await logPerf('auth.apple.signIn', _appleSignIn);
      final identityToken = apple.identityToken;
      if (identityToken == null) {
        AppLogger.w('linkApple: identityToken null');
        return const Left(
          AccountLinkingFailure.unknown('Apple identityToken absent'),
        );
      }

      final credential = OAuthProvider('apple.com').credential(
        idToken: identityToken,
        accessToken: apple.authorizationCode,
      );
      final result = await logPerf(
        'auth.apple.linkCredential',
        () => _linkCredential(credential),
      );

      final uid = result.user!.uid;
      // Apple ne fournit givenName/familyName qu'au PREMIER sign-in.
      // Au 2e, ils sont null -> fallback sur le displayName Firebase si pose.
      final composedName = [apple.givenName, apple.familyName]
          .where((s) => s != null && s.isNotEmpty)
          .join(' ');
      final displayName = composedName.isNotEmpty
          ? composedName
          : result.user!.displayName;
      // Apple ne fournit pas de photoUrl.
      const photoUrl = null;

      await _persistIdentity(
        uid,
        displayName,
        photoUrl,
        authProvider: 'apple',
      );

      _logSuccess(provider: 'apple', uid: uid);
      return Right(
        LinkedAccount(
          uid: uid,
          provider: AccountProvider.apple,
          displayName: displayName,
          photoUrl: photoUrl,
        ),
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      return Left(_mapAppleException(e));
    } on FirebaseAuthException catch (e, st) {
      return Left(_mapFirebaseAuth('apple', e, st));
    } on SocketException catch (_) {
      AppLogger.w('linkApple: SocketException -> network');
      return const Left(AccountLinkingFailure.network());
    } catch (e, st) {
      AppLogger.w('linkApple: unexpected error: $e', error: e);
      AppLogger.w('linkApple stack: $st');
      return Left(AccountLinkingFailure.unknown(e.toString()));
    }
  }

  Future<void> _persistIdentity(
    String uid,
    String? displayName,
    String? photoUrl, {
    String? authProvider,
  }) async {
    // Update partiel : displayName + photoUrl + authProvider + isAnonymous +
    // updatedAt. Les champs immuables (subSystem/trackId/levelId/streamId/
    // createdAt) restent inchanges.
    //
    // Audit PR5 2026-06-13 : on pose explicitement `isAnonymous: false` et
    // `authProvider: google|apple` pour signaler l'upgrade visiteur -> compte
    // permanent. Avant ce PR, le doc Firestore gardait isAnonymous=true alors
    // que le compte Auth etait passe en non-anonyme.
    final patch = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (displayName != null && displayName.isNotEmpty) {
      patch['displayName'] = displayName;
    }
    if (photoUrl != null && photoUrl.isNotEmpty) {
      patch['photoUrl'] = photoUrl;
    }
    if (authProvider != null) {
      patch['authProvider'] = authProvider;
      patch['isAnonymous'] = false;
    }
    try {
      // set(merge:true) au lieu de update() : tolère un doc inexistant
      // (cas linkGoogle au step 5 fresh, sans flush prealable).
      await _firestore
          .collection(_kCollection)
          .doc(uid)
          .set(patch, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      // Non-bloquant : le compte est cree cote Auth, on log mais on ne fail
      // pas l'operation. L'utilisateur peut re-tenter manuellement.
      AppLogger.w('_persistIdentity: Firestore set failed code=${e.code}');
    }
  }

  AccountLinkingFailure _mapGoogleException(GoogleSignInException e) {
    switch (e.code) {
      case GoogleSignInExceptionCode.canceled:
      case GoogleSignInExceptionCode.interrupted:
      case GoogleSignInExceptionCode.uiUnavailable:
        AppLogger.d('linkGoogle cancelled by user reason=${e.code.name}');
        return const AccountLinkingFailure.cancelled();
      default:
        AppLogger.w('linkGoogle GoogleSignInException code=${e.code.name}');
        return AccountLinkingFailure.unknown('Google: ${e.code.name}');
    }
  }

  AccountLinkingFailure _mapAppleException(
    SignInWithAppleAuthorizationException e,
  ) {
    switch (e.code) {
      case AuthorizationErrorCode.canceled:
        AppLogger.d('linkApple cancelled by user');
        return const AccountLinkingFailure.cancelled();
      default:
        AppLogger.w('linkApple AuthorizationException code=${e.code.name}');
        return AccountLinkingFailure.unknown('Apple: ${e.code.name}');
    }
  }

  AccountLinkingFailure _mapFirebaseAuth(
    String provider,
    FirebaseAuthException e,
    StackTrace st,
  ) {
    switch (e.code) {
      case 'credential-already-in-use':
        AppLogger.w(
          'Account linking conflict: provider=$provider credential-already-in-use',
        );
        return const AccountLinkingFailure.credentialAlreadyInUse();
      case 'provider-already-linked':
        AppLogger.w('Account already linked: provider=$provider');
        return const AccountLinkingFailure.alreadyLinked();
      case 'network-request-failed':
        AppLogger.w('Account linking failed: provider=$provider reason=network');
        return const AccountLinkingFailure.network();
      default:
        AppLogger.w(
          'Account linking failed: provider=$provider code=${e.code}',
          error: e,
        );
        AppLogger.w('stack: $st');
        return AccountLinkingFailure.unknown('Firebase: ${e.code}');
    }
  }

  void _logSuccess({required String provider, required String uid}) {
    // CLAUDE.md securite 4 : on log provider + uid_last4 (jamais l'uid complet
    // ni les tokens OAuth).
    final last4 = uid.length >= 4 ? uid.substring(uid.length - 4) : uid;
    AppLogger.i('Account linked: provider=$provider uid_last4=$last4');
  }
}
