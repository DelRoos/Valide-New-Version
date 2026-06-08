// Story 1.7 — Failures de la recherche / demande d'ajout d'ecole.
//
// Etend `Failure` (pattern Stories 1.3 ProfileFailure, 1.4 CatalogueFailure,
// 1.6 AccountLinkingFailure).

import '../../../core/error/failures.dart';

abstract class SchoolFailure extends Failure {
  const SchoolFailure(super.message);

  /// Erreur Firestore (reseau, regles, indexes manquants).
  const factory SchoolFailure.firestoreError(String message) =
      _SchoolFirestoreError;
}

class _SchoolFirestoreError extends SchoolFailure {
  const _SchoolFirestoreError(super.message);

  @override
  List<Object?> get props => ['SchoolFailure.firestoreError', message];
}
