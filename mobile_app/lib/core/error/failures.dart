// Hiérarchie `Failure` sealed + helper `Failure.from(Object)`.
// NFR-7 : aucune exception ne remonte à l'UI. La traduction Exception → Failure
// se fait UNIQUEMENT dans `data/repositories/*_repository_impl.dart`.
// Voir doc/tech/Valide School App Architecture.md § 10.

import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';

// Story 1.1c : `Failure` était `sealed` (interdit d'étendre hors de la library)
// pour permettre l'exhaustive switch. Aucun consommateur n'exploitait cette
// garantie. Changé en `abstract` pour permettre aux features d'introduire
// leurs propres sous-types (ex. `CatalogueFailure` dans `core/catalogue/`).
abstract class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  /// Helper generique : utilise par les repository impls quand aucun mapping
  /// specifique n'est requis. Couvre les exceptions de transport bas niveau.
  /// Les couches data peuvent (et doivent) catcher avant pour produire des
  /// failures plus precises (ProfileFailure, AccountLinkingFailure, etc.).
  static Failure from(Object exception) {
    if (exception is TimeoutException) {
      return const NetworkFailure();
    }
    if (exception is SocketException) {
      return const NetworkFailure();
    }
    return const UnknownFailure();
  }
}

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
