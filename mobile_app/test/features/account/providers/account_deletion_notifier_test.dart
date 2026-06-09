// Story 1.10 — Tests AccountDeletionStatusNotifier (3 cas).
//
// On override le repository avec un fake et on verifie les transitions
// d'etat du notifier. Pattern Story 1.6 AccountLinkingNotifier.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:valide_school/features/account/domain/account_deletion_failure.dart';
import 'package:valide_school/features/account/domain/account_deletion_repository.dart';
import 'package:valide_school/features/account/domain/account_deletion_status.dart';
import 'package:valide_school/features/account/providers.dart';

class _FakeRepo implements AccountDeletionRepository {
  _FakeRepo({this.requestResult, this.cancelResult});

  Either<AccountDeletionFailure, void>? requestResult;
  Either<AccountDeletionFailure, void>? cancelResult;

  int requestCalls = 0;
  int cancelCalls = 0;

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
        (state as AccountDeletionStatusError).failure,
        const AccountDeletionFailure.functionNotFound(),
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
  });
}
