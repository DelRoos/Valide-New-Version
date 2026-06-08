// Story 1.6 — Interface du linking de compte anonyme vers Google/Apple.
//
// Couche domain pure : pas d'import Firebase / Google / Apple.
// Either<AccountLinkingFailure, LinkedAccount> aux frontieres (NFR-7).

import 'package:fpdart/fpdart.dart';

import 'account_linking_failure.dart';
import 'linked_account.dart';

abstract interface class AccountLinkingRepository {
  /// Lance le picker Google + linkWithCredential sur l'utilisateur courant.
  ///
  /// L'uid Firebase reste inchange (compte anonyme PROMU en permanent).
  /// `users/{uid}` mis a jour : displayName + photoUrl + updatedAt.
  ///
  /// Retourne :
  /// - `Right(LinkedAccount)` : succes
  /// - `Left(AccountLinkingFailure.cancelled())` : utilisateur annule (AC4)
  /// - `Left(AccountLinkingFailure.network())` : pas de connexion (AC6)
  /// - `Left(AccountLinkingFailure.credentialAlreadyInUse())` : conflit (AC5)
  /// - `Left(AccountLinkingFailure.alreadyLinked())` : provider deja lie
  /// - `Left(AccountLinkingFailure.unknown(msg))` : autre erreur
  Future<Either<AccountLinkingFailure, LinkedAccount>> linkGoogle();

  /// Idem mais pour Apple Sign-In. `photoUrl` est toujours `null`.
  /// `displayName` peut etre null si l'utilisateur a deja signe une fois
  /// (Apple ne fournit givenName/familyName qu'au premier sign-in).
  Future<Either<AccountLinkingFailure, LinkedAccount>> linkApple();
}
