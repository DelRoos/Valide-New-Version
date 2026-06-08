// Story 1.6 — Resultat d'un linkWithCredential reussi.
//
// Modele immutable Equatable. Domain pur (pas d'import Firebase).

import 'package:equatable/equatable.dart';

/// Provider OAuth utilise pour le linking. Story 1.6 V1 : google ou apple.
enum AccountProvider {
  google,
  apple;

  String get id => switch (this) {
        AccountProvider.google => 'google',
        AccountProvider.apple => 'apple',
      };
}

class LinkedAccount extends Equatable {
  const LinkedAccount({
    required this.uid,
    required this.provider,
    this.displayName,
    this.photoUrl,
  });

  /// Uid Firebase — IDENTIQUE a celui d'avant linkWithCredential (l'uid
  /// est preserve : le compte anonyme est PROMU, pas remplace).
  final String uid;

  /// Provider qui vient d'etre lie.
  final AccountProvider provider;

  /// Nom affiche depuis le compte OAuth. Peut etre null (Apple 2e sign-in).
  final String? displayName;

  /// Photo de profil. Toujours null pour Apple (Apple ne fournit pas).
  final String? photoUrl;

  @override
  List<Object?> get props => [uid, provider, displayName, photoUrl];
}
