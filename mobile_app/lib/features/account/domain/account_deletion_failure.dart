// Story 1.10 — Failures de la suppression / annulation de compte (FR-7).
//
// Pattern Failure (Story 1.3/1.4/1.6) : Either<Failure, void> a la frontiere
// du repository (NFR-7).
//
// AccountDeletionFailureKind : enum public pour dispatch UI sans briser
// l'encapsulation des sous-classes privees.

import '../../../core/error/failures.dart';

enum AccountDeletionFailureKind {
  functionNotFound,
  network,
  requiresRecentLogin,
  /// Firebase `user-mismatch` : compte Google ≠ compte à supprimer.
  wrongAccount,
  unknown,
}

abstract class AccountDeletionFailure extends Failure {
  const AccountDeletionFailure(super.message);

  AccountDeletionFailureKind get kind;

  /// Cloud Function non déployée côté backend — toast info, app reste fonctionnelle.
  const factory AccountDeletionFailure.functionNotFound() =
      _AccountDeletionFunctionNotFound;

  /// Réseau coupé ou timeout — l'utilisateur peut réessayer.
  const factory AccountDeletionFailure.network() = _AccountDeletionNetwork;

  /// Firebase `requires-recent-login` — l'UI propose de se reconnecter.
  const factory AccountDeletionFailure.requiresRecentLogin() =
      _AccountDeletionRequiresRecentLogin;

  /// Firebase `user-mismatch` — l'UI garde le dialogue ouvert pour retry.
  const factory AccountDeletionFailure.wrongAccount() =
      _AccountDeletionWrongAccount;

  /// Toute autre erreur. Message conserve pour debug, jamais affiche brut.
  const factory AccountDeletionFailure.unknown(String message) =
      _AccountDeletionUnknown;
}

class _AccountDeletionFunctionNotFound extends AccountDeletionFailure {
  const _AccountDeletionFunctionNotFound()
      : super('Fonctionnalite bientot disponible.');

  @override
  AccountDeletionFailureKind get kind =>
      AccountDeletionFailureKind.functionNotFound;

  @override
  List<Object?> get props => const ['AccountDeletionFailure.functionNotFound'];
}

class _AccountDeletionNetwork extends AccountDeletionFailure {
  const _AccountDeletionNetwork()
      : super('Pas de connexion. Reessaie plus tard.');

  @override
  AccountDeletionFailureKind get kind => AccountDeletionFailureKind.network;

  @override
  List<Object?> get props => const ['AccountDeletionFailure.network'];
}

class _AccountDeletionRequiresRecentLogin extends AccountDeletionFailure {
  const _AccountDeletionRequiresRecentLogin()
      : super('Reconnecte-toi et reessaie.');

  @override
  AccountDeletionFailureKind get kind =>
      AccountDeletionFailureKind.requiresRecentLogin;

  @override
  List<Object?> get props =>
      const ['AccountDeletionFailure.requiresRecentLogin'];
}

class _AccountDeletionWrongAccount extends AccountDeletionFailure {
  const _AccountDeletionWrongAccount()
      : super('Mauvais compte Google. Reconnecte-toi avec le bon compte.');

  @override
  AccountDeletionFailureKind get kind =>
      AccountDeletionFailureKind.wrongAccount;

  @override
  List<Object?> get props => const ['AccountDeletionFailure.wrongAccount'];
}

class _AccountDeletionUnknown extends AccountDeletionFailure {
  const _AccountDeletionUnknown(super.message);

  @override
  AccountDeletionFailureKind get kind => AccountDeletionFailureKind.unknown;

  @override
  List<Object?> get props => ['AccountDeletionFailure.unknown', message];
}
