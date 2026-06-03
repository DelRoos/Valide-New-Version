import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:valide_school/core/error/failures.dart';

void main() {
  group('Failure subclasses', () {
    test('NetworkFailure expose un message FR', () {
      const failure = NetworkFailure();
      expect(failure.message, equals('Pas de connexion internet'));
    });

    test('AuthFailure accepte un message custom', () {
      const failure = AuthFailure('Mot de passe incorrect');
      expect(failure.message, equals('Mot de passe incorrect'));
    });

    test('ServerFailure porte code + message', () {
      const failure = ServerFailure(code: 503, message: 'Service indisponible');
      expect(failure.code, equals(503));
      expect(failure.message, equals('Service indisponible'));
    });

    test('CacheFailure expose un message par défaut', () {
      const failure = CacheFailure();
      expect(failure.message, equals('Échec du cache local'));
    });

    test('ValidationFailure compose message à partir de field + reason', () {
      const failure = ValidationFailure(field: 'email', reason: 'format invalide');
      expect(failure.field, equals('email'));
      expect(failure.reason, equals('format invalide'));
      expect(failure.message, contains('email'));
      expect(failure.message, contains('format invalide'));
    });

    test('UnknownFailure expose un message générique', () {
      const failure = UnknownFailure();
      expect(failure.message, equals('Une erreur inattendue est survenue'));
    });
  });

  group('Failure.from', () {
    test('TimeoutException → NetworkFailure', () {
      final failure = Failure.from(TimeoutException('timeout'));
      expect(failure, isA<NetworkFailure>());
    });

    test('SocketException → NetworkFailure', () {
      final failure = Failure.from(const SocketException('no route'));
      expect(failure, isA<NetworkFailure>());
    });

    test('Exception inconnue → UnknownFailure', () {
      final failure = Failure.from(Exception('boom'));
      expect(failure, isA<UnknownFailure>());
    });
  });

  group('Either<Failure, T> (smoke fpdart)', () {
    test('Right compile et déballe la valeur', () {
      const Either<Failure, String> result = Right('ok');
      expect(result.getRight().getOrElse(() => 'fallback'), equals('ok'));
    });
  });
}
