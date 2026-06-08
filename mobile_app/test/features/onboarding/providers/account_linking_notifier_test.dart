// Story 1.6 — Tests AccountLinkingNotifier.
//
// Pattern : override `accountLinkingRepositoryProvider` avec un fake qui
// retourne Right/Left controlee. On observe les transitions de state via
// container.read apres await sur la methode du notifier.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:valide_school/features/onboarding/domain/account_linking_failure.dart';
import 'package:valide_school/features/onboarding/domain/account_linking_repository.dart';
import 'package:valide_school/features/onboarding/domain/account_linking_state.dart';
import 'package:valide_school/features/onboarding/domain/linked_account.dart';
import 'package:valide_school/features/onboarding/providers.dart';

class _StubRepo implements AccountLinkingRepository {
  _StubRepo({required this.googleResult, required this.appleResult});
  final Either<AccountLinkingFailure, LinkedAccount> googleResult;
  final Either<AccountLinkingFailure, LinkedAccount> appleResult;

  @override
  Future<Either<AccountLinkingFailure, LinkedAccount>> linkGoogle() async =>
      googleResult;

  @override
  Future<Either<AccountLinkingFailure, LinkedAccount>> linkApple() async =>
      appleResult;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AccountLinkingNotifier — Story 1.6', () {
    test('(a) state initial = idle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(accountLinkingNotifierProvider);
      expect(state, isA<AccountLinkingIdle>());
    });

    test('(b) linkGoogle succes -> state = success(LinkedAccount)', () async {
      const account = LinkedAccount(
        uid: 'uid_123',
        provider: AccountProvider.google,
        displayName: 'James Doe',
        photoUrl: 'https://example.com/photo.jpg',
      );
      final container = ProviderContainer(
        overrides: [
          accountLinkingRepositoryProvider.overrideWithValue(
            _StubRepo(
              googleResult: const Right(account),
              appleResult: Left(const AccountLinkingFailure.unknown('n/a')),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(accountLinkingNotifierProvider.notifier).linkGoogle();

      final state = container.read(accountLinkingNotifierProvider);
      expect(state, isA<AccountLinkingSuccess>());
      expect((state as AccountLinkingSuccess).account, account);
    });

    test('(c) linkApple cancelled -> state = error(cancelled)', () async {
      final container = ProviderContainer(
        overrides: [
          accountLinkingRepositoryProvider.overrideWithValue(
            _StubRepo(
              googleResult: Left(const AccountLinkingFailure.unknown('n/a')),
              appleResult: const Left(AccountLinkingFailure.cancelled()),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(accountLinkingNotifierProvider.notifier).linkApple();

      final state = container.read(accountLinkingNotifierProvider);
      expect(state, isA<AccountLinkingError>());
    });

    test('(d) reset() ramene state a idle', () async {
      final container = ProviderContainer(
        overrides: [
          accountLinkingRepositoryProvider.overrideWithValue(
            _StubRepo(
              googleResult: Left(const AccountLinkingFailure.unknown('n/a')),
              appleResult: const Left(AccountLinkingFailure.cancelled()),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(accountLinkingNotifierProvider.notifier).linkApple();
      expect(
        container.read(accountLinkingNotifierProvider),
        isA<AccountLinkingError>(),
      );

      container.read(accountLinkingNotifierProvider.notifier).reset();
      expect(
        container.read(accountLinkingNotifierProvider),
        isA<AccountLinkingIdle>(),
      );
    });
  });
}
