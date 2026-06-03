// Hiérarchie `Failure` sealed + helper `Failure.from(Object)`.
// NFR-7 : aucune exception ne remonte à l'UI. La traduction Exception → Failure
// se fait UNIQUEMENT dans `data/repositories/*_repository_impl.dart`.
// Voir doc/tech/Valide School App Architecture.md § 10.

import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  static Failure from(Object exception) {
    if (exception is TimeoutException) {
      return const NetworkFailure();
    }
    if (exception is SocketException) {
      return const NetworkFailure();
    }
    // TODO(0.5): DioException.timeout → NetworkFailure ; DioException.badResponse → ServerFailure(code, msg).
    // TODO(0.6): FirebaseAuthException → AuthFailure(code) ; FirebaseException(permission-denied) → ServerFailure(403, ...).
    return const UnknownFailure();
  }
}

// TODO(0.16): localiser les messages via AppLocalizations.

class NetworkFailure extends Failure {
  const NetworkFailure() : super('Pas de connexion internet');
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentification refusée']);
}

class ServerFailure extends Failure {
  const ServerFailure({
    required this.code,
    String message = 'Le serveur a renvoyé une erreur',
  }) : super(message);

  final int code;

  @override
  List<Object?> get props => [code, message];
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Échec du cache local']);
}

class ValidationFailure extends Failure {
  const ValidationFailure({
    required this.field,
    required this.reason,
  }) : super('Champ « $field » invalide : $reason');

  final String field;
  final String reason;

  @override
  List<Object?> get props => [field, reason];
}

class UnknownFailure extends Failure {
  const UnknownFailure() : super('Une erreur inattendue est survenue');
}
