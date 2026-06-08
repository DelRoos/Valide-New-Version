// Story 1.6 — State machine du linking de compte anonyme.
//
// 4 etats : idle | loading(provider) | success(LinkedAccount) | error(failure)
// Consomme par `AccountCreationPage` via `ref.listen` (transitions reactives).

import 'package:equatable/equatable.dart';

import 'account_linking_failure.dart';
import 'linked_account.dart';

sealed class AccountLinkingState extends Equatable {
  const AccountLinkingState();

  const factory AccountLinkingState.idle() = AccountLinkingIdle;
  const factory AccountLinkingState.loading(AccountProvider provider) =
      AccountLinkingLoading;
  const factory AccountLinkingState.success(LinkedAccount account) =
      AccountLinkingSuccess;
  const factory AccountLinkingState.error(AccountLinkingFailure failure) =
      AccountLinkingError;

  bool get isLoading => this is AccountLinkingLoading;
}

class AccountLinkingIdle extends AccountLinkingState {
  const AccountLinkingIdle();
  @override
  List<Object?> get props => const ['idle'];
}

class AccountLinkingLoading extends AccountLinkingState {
  const AccountLinkingLoading(this.provider);
  final AccountProvider provider;
  @override
  List<Object?> get props => ['loading', provider];
}

class AccountLinkingSuccess extends AccountLinkingState {
  const AccountLinkingSuccess(this.account);
  final LinkedAccount account;
  @override
  List<Object?> get props => ['success', account];
}

class AccountLinkingError extends AccountLinkingState {
  const AccountLinkingError(this.failure);
  final AccountLinkingFailure failure;
  @override
  List<Object?> get props => ['error', failure];
}
