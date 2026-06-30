// Story 1.10 — Tests AccountDeletionStatusNotifier.
//
// On override le repository avec un fake et on verifie les transitions
// d'etat du notifier. Pattern Story 1.6 AccountLinkingNotifier.
//
// SharedPreferences.getInstance() echoue en test (MissingPluginException)
// mais deleteNow() a un try/catch autour -> il continue vers le repo fake.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:valide_school/features/account/domain/account_deletion_failure.dart';
import 'package:valide_school/features/account/domain/account_deletion_repository.dart';
import 'package:valide_school/features/account/domain/account_deletion_status.dart';
import 'package:valide_school/features/account/providers.dart';

class _FakeRepo implements AccountDeletionRepository {
  _FakeRepo({
    this.requestResult,
    this.cancelResult,
    this.deleteNowResult,
  });

  Either<AccountDeletionFailure, void>? requestResult;
  Either<AccountDeletionFailure, void>? cancelResult;
  Either<AccountDeletionFailure, void>? deleteNowResult;

  int requestCalls = 0;
  int cancelCalls = 0;
  int deleteNowCalls = 0;

  @override
  Future<Either<AccountDeletionFailure, void>>
      requestAccountDeletion() async {
    requestCalls++;
    return requestResult ?? const Right(null);
  }

  @override
  Future<Either<AccountDeletionFailure, void>>
      cancelAccountDeletion() async {
    cancelCalls++;
    return cancelResult ?? const Right(null);
  }

  @override
  Future<Either<AccountDeletionFailure, void>> deleteAccountNow() async {
    deleteNowCalls++;
    return deleteNowResult ?? const Right(null);
  }

  @override
  Future<Either<AccountDeletionFailure, void>>
      reauthenticateWithGoogle() async => const Right(null);
}

void main() {
  group('AccountDeletionStatusNotifier — Story 1.10', () {
    test('(a) requestDeletion succes -> state transition vers requested',
        () async {
      final fake = _FakeRepo(requestResult: const Right(null));
      final container = ProviderContainer(
        overrides: [
          accountDeletionRepositoryProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(accountDeletionStatusNotifierProvider),
        const AccountDeletionStatus.idle(),
      );

      await container
          .read(accountDeletionStatusNotifierProvider.notifier)
          .requestDeletion();

      expect(
        container.read(accountDeletionStatusNotifierProvider),
        const AccountDeletionStatus.requested(),
      );
      expect(fake.requestCalls, 1);
    });

    test('(b) cancelDeletion succes -> state transition vers cancelled',
        () async {
      final fake = _FakeRepo(cancelResult: const Right(null));
      final container = ProviderContainer(
        overrides: [
          accountDeletionRepositoryProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(accountDeletionStatusNotifierProvider.notifier)
          .cancelDeletion();

      expect(
        container.read(accountDeletionStatusNotifierProvider),
        const AccountDeletionStatus.cancelled(),
      );
      expect(fake.cancelCalls, 1);
    });

    test('(c) request avec functionNotFound -> state error gracieux',
        () async {
      final fake = _FakeRepo(
        requestResult: const Left(
          AccountDeletionFailure.functionNotFound(),
        ),
      );
      final container = ProviderContainer(
        overrides: [
          accountDeletionRepositoryProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(accountDeletionStatusNotifierProvider.notifier)
          .requestDeletion();

      final state = container.read(accountDeletionStatusNotifierProvider);
      expect(state, isA<AccountDeletionStatusError>());
      expect(
        (state as AccountDeletionStatusError).failure.kind,
        AccountDeletionFailureKind.functionNotFound,
      );
    });

    test('(d) reset -> retour a idle', () async {
      final fake = _FakeRepo(cancelResult: const Right(null));
      final container = ProviderContainer(
        overrides: [
          accountDeletionRepositoryProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(accountDeletionStatusNotifierProvider.notifier)
          .cancelDeletion();
      expect(
        container.read(accountDeletionStatusNotifierProvider),
        const AccountDeletionStatus.cancelled(),
      );

      container.read(accountDeletionStatusNotifierProvider.notifier).reset();
      expect(
        container.read(accountDeletionStatusNotifierProvider),
        const AccountDeletionStatus.idle(),
      );
    });

    test('(e) deleteNow succes -> state transition vers deleted', () async {
      final fake = _FakeRepo(deleteNowResult: const Right(null));
      final container = ProviderContainer(
        overrides: [
          accountDeletionRepositoryProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(accountDeletionStatusNotifierProvider.notifier)
          .deleteNow();

      expect(
        container.read(accountDeletionStatusNotifierProvider),
        const AccountDeletionStatus.deleted(),
      );
      expect(fake.deleteNowCalls, 1);
    });

    test(
        '(f) deleteNow requiresRecentLogin -> state error kind=requiresRecentLogin',
        () async {
      final fake = _FakeRepo(
        deleteNowResult: const Left(
          AccountDeletionFailure.requiresRecentLogin(),
        ),
      );
      final container = ProviderContainer(
        overrides: [
          accountDeletionRepositoryProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(accountDeletionStatusNotifierProvider.notifier)
          .deleteNow();

      final state = container.read(accountDeletionStatusNotifierProvider);
      expect(state, isA<AccountDeletionStatusError>());
      expect(
        (state as AccountDeletionStatusError).failure.kind,
        AccountDeletionFailureKind.requiresRecentLogin,
      );
    });

    test('(g) deleteNow network -> state error kind=network', () async {
      final fake = _FakeRepo(
        deleteNowResult: const Left(AccountDeletionFailure.network()),
      );
      final container = ProviderContainer(
        overrides: [
          accountDeletionRepositoryProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(accountDeletionStatusNotifierProvider.notifier)
          .deleteNow();

      final state = container.read(accountDeletionStatusNotifierProvider);
      expect(state, isA<AccountDeletionStatusError>());
      expect(
        (state as AccountDeletionStatusError).failure.kind,
        AccountDeletionFailureKind.network,
      );
    });

    test(
        '(h) deleteNow idempotent : second call pendant deleting -> ignore',
        () async {
      final fake = _FakeRepo(deleteNowResult: const Right(null));
      final container = ProviderContainer(
        overrides: [
          accountDeletionRepositoryProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);

      // Premier appel
      final first = container
          .read(accountDeletionStatusNotifierProvider.notifier)
          .deleteNow();
      // Second appel immediat pendant que le premier tourne
      await container
          .read(accountDeletionStatusNotifierProvider.notifier)
          .deleteNow();
      await first;

      // Le repo ne doit etre appele qu'une seule fois (guard isLoading)
      expect(fake.deleteNowCalls, 1);
    });
  });
}
