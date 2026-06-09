// Story 1.10 — State machine de l'UI de suppression / annulation de compte.
//
// Pattern sealed (Story 1.6 AccountLinkingState). Le notifier expose un seul
// state qui couvre les transitions :
//   idle -> requesting -> requested|error
//   idle (suite a banner dashboard) -> cancelling -> cancelled|error

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

  const factory AccountDeletionStatus.error(AccountDeletionFailure failure) =
      AccountDeletionStatusError;

  bool get isLoading => switch (this) {
        AccountDeletionStatusRequesting() => true,
        AccountDeletionStatusCancelling() => true,
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

class AccountDeletionStatusError extends AccountDeletionStatus {
  const AccountDeletionStatusError(this.failure);
  final AccountDeletionFailure failure;
  @override
  List<Object?> get props => ['error', failure];
}
