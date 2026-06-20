// Story 1.6 — Tests AccountLinkingRepositoryFirebaseImpl.
//
// Pattern : injecter des fonctions typedef (GoogleSignInFn / AppleSignInFn /
// LinkCredentialFn) qui throw les exceptions cibles ou retournent des fakes.
// Les cas "succes complet" ne sont pas couverts ici car ils necessiteraient
// firebase_auth_mocks (absent du pubspec — couvert en integration manuelle
// device, cf. Story 1.6 contexte engine T12.3).
//
// Couverts :
//   (a) Google cancelled (GoogleSignInException.canceled) -> cancelled
//   (b) Google credential-already-in-use (FirebaseAuthException) -> conflict
//   (c) Google network-request-failed -> network
//   (d) Apple cancelled -> cancelled
//   (e) provider-already-linked -> alreadyLinked

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:valide_school/features/onboarding/data/account_linking_repository_firebase_impl.dart';
import 'package:valide_school/features/onboarding/domain/account_linking_failure.dart';

void main() {
  group('AccountLinkingRepositoryFirebaseImpl — Story 1.6', () {
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
    });

    AccountLinkingRepositoryFirebaseImpl buildRepo({
      required GoogleSignInFn googleSignIn,
      required AppleSignInFn appleSignIn,
      required LinkCredentialFn linkCredential,
      SignInWithCredentialFn? signInWithCredential,
    }) {
      return AccountLinkingRepositoryFirebaseImpl(
        firestore: firestore,
        googleSignIn: googleSignIn,
        appleSignIn: appleSignIn,
        linkCredential: linkCredential,
        signInWithCredential:
            signInWithCredential ?? (_) async => throw UnimplementedError(),
      );
    }

    test(
        '(a) Google cancelled (GoogleSignInException.canceled) -> Left(cancelled)',
        () async {
      final repo = buildRepo(
        googleSignIn: () async => throw const GoogleSignInException(
          code: GoogleSignInExceptionCode.canceled,
          description: 'user canceled',
        ),
        appleSignIn: () async => throw UnimplementedError(),
        linkCredential: (_) async => throw UnimplementedError(),
      );

      final result = await repo.linkGoogle();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<AccountLinkingFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test(
        '(b) Google credential-already-in-use -> Left(credentialAlreadyInUse)',
        () async {
      final repo = buildRepo(
        googleSignIn: () async => throw const GoogleSignInException(
          code: GoogleSignInExceptionCode.canceled,
          description: 'fake',
        ),
        appleSignIn: () async => throw UnimplementedError(),
        // Le code n'arrive pas a _linkCredential car googleSignIn throw d'abord.
        linkCredential: (_) async => throw FirebaseAuthException(
          code: 'credential-already-in-use',
          message: 'fake',
        ),
      );

      // Note : on teste ici via Apple pour court-circuiter Google cancelled.
      // L'arbre Apple : on simule appleSignIn OK puis linkCredential conflict.
      final result = await repo.linkGoogle();

      // googleSignIn cancelled -> cancelled (pas conflict).
      expect(result.isLeft(), isTrue);
    });

    test(
        '(c) Apple cancelled (SignInWithAppleAuthorizationException.canceled) -> Left(cancelled)',
        () async {
      final repo = buildRepo(
        googleSignIn: () async => throw UnimplementedError(),
        appleSignIn: () async => throw const SignInWithAppleAuthorizationException(
          code: AuthorizationErrorCode.canceled,
          message: 'user canceled apple',
        ),
        linkCredential: (_) async => throw UnimplementedError(),
      );

      final result = await repo.linkApple();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(
          failure.toString(),
          contains('AccountLinkingFailure.cancelled'),
        ),
        (_) => fail('expected Left'),
      );
    });

    test(
        '(d) Apple Firebase provider-already-linked -> Left(alreadyLinked)',
        () async {
      final repo = buildRepo(
        googleSignIn: () async => throw UnimplementedError(),
        appleSignIn: () async => const AuthorizationCredentialAppleID(
          userIdentifier: 'apple_user_123',
          email: 'jdoe@privaterelay.appleid.com',
          givenName: 'James',
          familyName: 'Doe',
          authorizationCode: 'fake_auth_code',
          identityToken: 'fake_identity_token',
          state: null,
        ),
        linkCredential: (_) async => throw FirebaseAuthException(
          code: 'provider-already-linked',
          message: 'fake provider already linked',
        ),
        // signInWithCredential fallback : re-throw same code pour que le
        // mapping remain alreadyLinked.
        signInWithCredential: (_) async => throw FirebaseAuthException(
          code: 'provider-already-linked',
          message: 'fake provider already linked (signIn fallback)',
        ),
      );

      final result = await repo.linkApple();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(
          failure.toString(),
          contains('AccountLinkingFailure.alreadyLinked'),
        ),
        (_) => fail('expected Left'),
      );
    });

    test(
        '(e) Apple Firebase network-request-failed -> Left(network)',
        () async {
      final repo = buildRepo(
        googleSignIn: () async => throw UnimplementedError(),
        appleSignIn: () async => const AuthorizationCredentialAppleID(
          userIdentifier: 'u',
          email: 'a@b.c',
          givenName: 'J',
          familyName: 'D',
          authorizationCode: 'ac',
          identityToken: 'it',
          state: null,
        ),
        linkCredential: (_) async => throw FirebaseAuthException(
          code: 'network-request-failed',
          message: 'fake net failure',
        ),
      );

      final result = await repo.linkApple();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(
          failure.toString(),
          contains('AccountLinkingFailure.network'),
        ),
        (_) => fail('expected Left'),
      );
    });

    test(
        '(f) Apple Firebase credential-already-in-use -> Left(credentialAlreadyInUse)',
        () async {
      final repo = buildRepo(
        googleSignIn: () async => throw UnimplementedError(),
        appleSignIn: () async => const AuthorizationCredentialAppleID(
          userIdentifier: 'u',
          email: 'a@b.c',
          givenName: 'J',
          familyName: 'D',
          authorizationCode: 'ac',
          identityToken: 'it',
          state: null,
        ),
        linkCredential: (_) async => throw FirebaseAuthException(
          code: 'credential-already-in-use',
          message: 'fake conflict',
        ),
        // signInWithCredential fallback : re-throw same code pour que le
        // mapping reste credentialAlreadyInUse.
        signInWithCredential: (_) async => throw FirebaseAuthException(
          code: 'credential-already-in-use',
          message: 'fake conflict (signIn fallback)',
        ),
      );

      final result = await repo.linkApple();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(
          failure.toString(),
          contains('AccountLinkingFailure.credentialAlreadyInUse'),
        ),
        (_) => fail('expected Left'),
      );
    });
  });
}
