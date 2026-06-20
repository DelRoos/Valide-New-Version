// Story 1.10 — Failures de la suppression / annulation de compte (FR-7).
//
// Pattern Failure (Story 1.3/1.4/1.6) : Either<Failure, void> a la frontiere
// du repository (NFR-7).

import '../../../core/error/failures.dart';

abstract class AccountDeletionFailure extends Failure {
  const AccountDeletionFailure(super.message);

  /// Cloud Function non deployee cote backend (`HttpsError.not-found`). Le
  /// mobile gere gracefully : toast "Fonctionnalite bientot disponible" +
  /// log warn. L'app reste utilisable.
  const factory AccountDeletionFailure.functionNotFound() =
      _AccountDeletionFunctionNotFound;

  /// Reseau coupe / timeout (`HttpsError.unavailable` ou `deadline-exceeded`).
  /// Le user peut re-essayer.
  const factory AccountDeletionFailure.network() = _AccountDeletionNetwork;

  /// Toute autre erreur. Message conserve pour debug, jamais affiche brut.
  const factory AccountDeletionFailure.unknown(String message) =
      _AccountDeletionUnknown;
}

class _AccountDeletionFunctionNotFound extends AccountDeletionFailure {
  const _AccountDeletionFunctionNotFound()
      : super('Fonctionnalite bientot disponible.');

  @override
  List<Object?> get props => const ['AccountDeletionFailure.functionNotFound'];
}

class _AccountDeletionNetwork extends AccountDeletionFailure {
  const _AccountDeletionNetwork()
      : super('Pas de connexion. Reessaie plus tard.');

  @override
  List<Object?> get props => const ['AccountDeletionFailure.network'];
}

class _AccountDeletionUnknown extends AccountDeletionFailure {
  const _AccountDeletionUnknown(super.message);

  @override
  List<Object?> get props => ['AccountDeletionFailure.unknown', message];
}
