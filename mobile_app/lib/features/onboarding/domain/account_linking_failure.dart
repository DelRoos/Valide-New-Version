// Story 1.6 — Failures du linking de compte anonyme vers Google/Apple.
//
// Etend la hierarchie `Failure` (pattern Story 1.3/1.4 ProfileFailure).
// Either<Failure, LinkedAccount> aux frontieres du repository (NFR-7).

import '../../../core/error/failures.dart';

abstract class AccountLinkingFailure extends Failure {
  const AccountLinkingFailure(super.message);

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
  /// (jamais affiche brut a l'UI — la widget mappe sur `errorGeneric`).
  const factory AccountLinkingFailure.unknown(String message) =
      _AccountLinkingUnknown;
}

class _AccountLinkingCancelled extends AccountLinkingFailure {
  const _AccountLinkingCancelled()
      : super('Connexion annulee par l\'utilisateur.');

  @override
  List<Object?> get props => const ['AccountLinkingFailure.cancelled'];
}

class _AccountLinkingNetwork extends AccountLinkingFailure {
  const _AccountLinkingNetwork()
      : super('Pas de connexion. Verifie ta connexion et reessaie.');

  @override
  List<Object?> get props => const ['AccountLinkingFailure.network'];
}

class _AccountLinkingCredentialAlreadyInUse extends AccountLinkingFailure {
  const _AccountLinkingCredentialAlreadyInUse()
      : super(
          'Ce compte est deja lie a un autre profil Valide.',
        );

  @override
  List<Object?> get props =>
      const ['AccountLinkingFailure.credentialAlreadyInUse'];
}

class _AccountLinkingAlreadyLinked extends AccountLinkingFailure {
  const _AccountLinkingAlreadyLinked()
      : super('Tu as deja un compte.');

  @override
  List<Object?> get props => const ['AccountLinkingFailure.alreadyLinked'];
}

class _AccountLinkingUnknown extends AccountLinkingFailure {
  const _AccountLinkingUnknown(super.message);

  @override
  List<Object?> get props => ['AccountLinkingFailure.unknown', message];
}
