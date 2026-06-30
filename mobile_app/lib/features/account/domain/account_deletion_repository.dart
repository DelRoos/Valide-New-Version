// Story 1.10 — Interface domain de la suppression de compte (FR-7).
//
// 3 methodes :
//   - requestAccountDeletion : pose users/{uid}.deletionRequestedAt = now cote serveur
//   - cancelAccountDeletion : pose users/{uid}.deletionRequestedAt = null (idempotent)
//   - deleteAccountNow : supprime immediatement le doc Firestore + le user Firebase Auth
//
// Implementation : `data/account_deletion_repository_impl.dart`.

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

  /// Supprime immediatement :
  ///   1. Le doc Firestore `users/{uid}` (pendant que l'auth est encore valide).
  ///   2. Le user Firebase Auth (`currentUser.delete()`).
  ///
  /// Erreur `requiresRecentLogin` : Firebase exige une re-authentification
  /// recente. L'UI doit inviter l'utilisateur a se reconnecter et reessayer.
  /// Dans ce cas, le doc Firestore est supprime mais l'Auth reste intact.
  Future<Either<AccountDeletionFailure, void>> deleteAccountNow();
}
