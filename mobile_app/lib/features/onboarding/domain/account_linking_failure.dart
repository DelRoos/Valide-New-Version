// Story 1.6 — Failures du linking de compte anonyme vers Google/Apple.
//
// Etend la hierarchie `Failure` (pattern Story 1.3/1.4 ProfileFailure).
// Either<Failure, LinkedAccount> aux frontieres du repository (NFR-7).
//
// Audit 2026-06-15 — Ajout de `kind` (CLAUDE.md regle 13) pour que la
// couche presentation mappe le type d'erreur sans inspecter le message brut.

import '../../../core/error/failures.dart';

/// Catégories de failure pour mapping UI (CLAUDE.md règle 13).
enum AccountLinkingFailureKind {
  /// Annulation explicite par l'utilisateur (silencieux en UI).
  cancelled,

  /// Pas de réseau ou service Google/Apple indisponible.
  network,

  /// Credential déjà lié à un autre compte Valide.
  credentialAlreadyInUse,

  /// Provider déjà lié à ce compte.
  alreadyLinked,

  /// Erreur technique inattendue (ne pas exposer le message brut à l'UI).
  unknown,
}

abstract class AccountLinkingFailure extends Failure {
  const AccountLinkingFailure(super.message);

  /// Type de failure pour dispatch UI. (CLAUDE.md règle 13)
  AccountLinkingFailureKind get kind;

  /// L'utilisateur a annule explicitement le picker OAuth (back, cancel).
  /// Doit etre traite comme silencieux dans le notifier (pas de toast).
  const factory AccountLinkingFailure.cancelled() = _AccountLinkingCancelled;

  /// Pas de connexion ou timeout reseau.
  const factory AccountLinkingFailure.network() = _AccountLinkingNetwork;

  /// FirebaseAuthException code `credential-already-in-use` — le compte
  /// Google/Apple est deja lie a un autre uid Firebase. Story 1.6 V1 affiche
  /// une modale info ; le flow switch est differe en Story 1.6bis.
  const factory AccountLinkingFailure.credentialAlreadyInUse() =
      _AccountLinkingCredentialAlreadyInUse;

  /// FirebaseAuthException code `provider-already-linked` — l'utilisateur a
  /// deja lie ce provider a son compte. Toast info, pas critique.
  const factory AccountLinkingFailure.alreadyLinked() =
      _AccountLinkingAlreadyLinked;

  /// Toute autre erreur inattendue. Le message est conserve pour debug
  /// (jamais affiche brut a l'UI — la widget mappe sur `errorGenericTitle`).
  const factory AccountLinkingFailure.unknown(String message) =
      _AccountLinkingUnknown;
}

class _AccountLinkingCancelled extends AccountLinkingFailure {
  const _AccountLinkingCancelled()
      : super('Connexion annulee par l\'utilisateur.');

  @override
  AccountLinkingFailureKind get kind => AccountLinkingFailureKind.cancelled;

  @override
  List<Object?> get props => const ['AccountLinkingFailure.cancelled'];
}

class _AccountLinkingNetwork extends AccountLinkingFailure {
  const _AccountLinkingNetwork()
      : super('Pas de connexion. Verifie ta connexion et reessaie.');

  @override
  AccountLinkingFailureKind get kind => AccountLinkingFailureKind.network;

  @override
  List<Object?> get props => const ['AccountLinkingFailure.network'];
}

class _AccountLinkingCredentialAlreadyInUse extends AccountLinkingFailure {
  const _AccountLinkingCredentialAlreadyInUse()
      : super('Ce compte est deja lie a un autre profil Valide.');

  @override
  AccountLinkingFailureKind get kind =>
      AccountLinkingFailureKind.credentialAlreadyInUse;

  @override
  List<Object?> get props =>
      const ['AccountLinkingFailure.credentialAlreadyInUse'];
}

class _AccountLinkingAlreadyLinked extends AccountLinkingFailure {
  const _AccountLinkingAlreadyLinked() : super('Tu as deja un compte.');

  @override
  AccountLinkingFailureKind get kind => AccountLinkingFailureKind.alreadyLinked;

  @override
  List<Object?> get props => const ['AccountLinkingFailure.alreadyLinked'];
}

class _AccountLinkingUnknown extends AccountLinkingFailure {
  const _AccountLinkingUnknown(super.message);

  @override
  AccountLinkingFailureKind get kind => AccountLinkingFailureKind.unknown;

  @override
  List<Object?> get props => ['AccountLinkingFailure.unknown', message];
}
