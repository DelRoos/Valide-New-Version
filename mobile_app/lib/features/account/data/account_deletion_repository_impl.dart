// Story 1.10 — Impl Cloud Functions de la suppression de compte (FR-7).
//
// Appelle les 2 functions callable :
//   - requestAccountDeletion (deja documente CONTRATS-API.md Phase 1)
//   - cancelAccountDeletion (NEW Story 1.10 — CONTRATS-API.md UPDATE)
//
// Mapping FirebaseFunctionsException -> AccountDeletionFailure :
//   - not-found -> functionNotFound (backend pas deploye, fallback gracefull)
//   - unavailable / deadline-exceeded -> network
//   - autres -> unknown
//
// CLAUDE.md securite 4 : aucun log d'uid, juste un booleen metier
// ("Account deletion requested" / "Account deletion cancelled").

import 'package:cloud_functions/cloud_functions.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/logging/app_logger.dart';
import '../domain/account_deletion_failure.dart';
import '../domain/account_deletion_repository.dart';

class AccountDeletionRepositoryImpl implements AccountDeletionRepository {
  AccountDeletionRepositoryImpl(this._functions);

  final FirebaseFunctions _functions;

  static const String _kRequestFnName = 'requestAccountDeletion';
  static const String _kCancelFnName = 'cancelAccountDeletion';

  @override
  Future<Either<AccountDeletionFailure, void>>
      requestAccountDeletion() async {
    return _callFunction(
      fnName: _kRequestFnName,
      successLog: 'Account deletion requested',
    );
  }

  @override
  Future<Either<AccountDeletionFailure, void>>
      cancelAccountDeletion() async {
    return _callFunction(
      fnName: _kCancelFnName,
      successLog: 'Account deletion cancelled',
    );
  }

  Future<Either<AccountDeletionFailure, void>> _callFunction({
    required String fnName,
    required String successLog,
  }) async {
    try {
      await _functions.httpsCallable(fnName).call<dynamic>(<String, dynamic>{});
      AppLogger.i(successLog);
      return const Right(null);
    } on FirebaseFunctionsException catch (e) {
      return Left(_mapException(fnName, e));
    } catch (e) {
      AppLogger.w('$fnName failed: ${e.runtimeType}');
      return Left(AccountDeletionFailure.unknown(e.toString()));
    }
  }

  AccountDeletionFailure _mapException(
    String fnName,
    FirebaseFunctionsException e,
  ) {
    switch (e.code) {
      case 'not-found':
        AppLogger.w('$fnName not deployed (backend pending)');
        return const AccountDeletionFailure.functionNotFound();
      case 'unavailable':
      case 'deadline-exceeded':
        AppLogger.w('$fnName network failure');
        return const AccountDeletionFailure.network();
      default:
        AppLogger.w('$fnName failed: code=${e.code}');
        return AccountDeletionFailure.unknown('${e.code}: ${e.message ?? ''}');
    }
  }
}
