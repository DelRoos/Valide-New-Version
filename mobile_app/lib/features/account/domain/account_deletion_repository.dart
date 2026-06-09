// Story 1.10 — Interface domain de la suppression de compte (FR-7).
//
// 2 methodes appellent les Cloud Functions backend :
//   - requestAccountDeletion : pose users/{uid}.deletionRequestedAt = now cote serveur
//   - cancelAccountDeletion : pose users/{uid}.deletionRequestedAt = null (idempotent)
//
// Implementation : `data/account_deletion_repository_impl.dart` (Cloud Functions callable).

import 'package:fpdart/fpdart.dart';

import 'account_deletion_failure.dart';

abstract class AccountDeletionRepository {
  /// Demande la suppression du compte au backend. Cote serveur la function
  /// pose `users/{uid}.deletionRequestedAt = FieldValue.serverTimestamp()`.
  /// Le cron quotidien backend supprime effectivement apres 7 jours sauf si
  /// l'utilisateur a appele `cancelAccountDeletion` entre temps.
  Future<Either<AccountDeletionFailure, void>> requestAccountDeletion();

  /// Annule la demande de suppression. Idempotent : pas d'erreur si la
  /// demande n'existe pas ou a deja ete annulee.
  Future<Either<AccountDeletionFailure, void>> cancelAccountDeletion();
}
