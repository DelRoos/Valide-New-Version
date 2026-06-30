// Story 1.10 — State machine de l'UI de suppression / annulation de compte.
//
// Pattern sealed (Story 1.6 AccountLinkingState). Le notifier expose un seul
// state qui couvre les transitions :
//   idle -> requesting -> requested|error
//   idle (suite a banner dashboard) -> cancelling -> cancelled|error
//   idle -> deleting -> deleted|error   (suppression immediate)

import 'package:equatable/equatable.dart';

import 'account_deletion_failure.dart';

sealed class AccountDeletionStatus extends Equatable {
  const AccountDeletionStatus();

  const factory AccountDeletionStatus.idle() = AccountDeletionStatusIdle;

  const factory AccountDeletionStatus.requesting() =
      AccountDeletionStatusRequesting;

  const factory AccountDeletionStatus.requested() =
      AccountDeletionStatusRequested;

  const factory AccountDeletionStatus.cancelling() =
      AccountDeletionStatusCancelling;

  const factory AccountDeletionStatus.cancelled() =
      AccountDeletionStatusCancelled;

  /// Suppression immediate en cours (deleteAccountNow).
  const factory AccountDeletionStatus.deleting() = AccountDeletionStatusDeleting;

  /// Suppression immediate reussie — l'UI doit naviguer vers '/'.
  const factory AccountDeletionStatus.deleted() = AccountDeletionStatusDeleted;

  const factory AccountDeletionStatus.error(AccountDeletionFailure failure) =
      AccountDeletionStatusError;

  bool get isLoading => switch (this) {
        AccountDeletionStatusRequesting() => true,
        AccountDeletionStatusCancelling() => true,
        AccountDeletionStatusDeleting() => true,
        _ => false,
      };
}

class AccountDeletionStatusIdle extends AccountDeletionStatus {
  const AccountDeletionStatusIdle();
  @override
  List<Object?> get props => const ['idle'];
}

class AccountDeletionStatusRequesting extends AccountDeletionStatus {
  const AccountDeletionStatusRequesting();
  @override
  List<Object?> get props => const ['requesting'];
}

class AccountDeletionStatusRequested extends AccountDeletionStatus {
  const AccountDeletionStatusRequested();
  @override
  List<Object?> get props => const ['requested'];
}

class AccountDeletionStatusCancelling extends AccountDeletionStatus {
  const AccountDeletionStatusCancelling();
  @override
  List<Object?> get props => const ['cancelling'];
}

class AccountDeletionStatusCancelled extends AccountDeletionStatus {
  const AccountDeletionStatusCancelled();
  @override
  List<Object?> get props => const ['cancelled'];
}

class AccountDeletionStatusDeleting extends AccountDeletionStatus {
  const AccountDeletionStatusDeleting();
  @override
  List<Object?> get props => const ['deleting'];
}

class AccountDeletionStatusDeleted extends AccountDeletionStatus {
  const AccountDeletionStatusDeleted();
  @override
  List<Object?> get props => const ['deleted'];
}

class AccountDeletionStatusError extends AccountDeletionStatus {
  const AccountDeletionStatusError(this.failure);
  final AccountDeletionFailure failure;
  @override
  List<Object?> get props => ['error', failure];
}
