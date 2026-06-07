// Story 1.3 — Failures de la creation du profil users/{uid}.
//
// Etend la hierarchie `Failure` (Story 1.1c a change sealed -> abstract pour
// permettre l'extension par feature). Coherent pattern Either<Failure, T>
// (NFR-7) — aucune exception ne remonte a l'UI.

import '../../../core/error/failures.dart';

abstract class ProfileFailure extends Failure {
  const ProfileFailure(super.message);

  const factory ProfileFailure.notAuthenticated() = _ProfileNotAuthenticated;
  const factory ProfileFailure.firestoreError(String message) =
      _ProfileFirestoreError;
}

class _ProfileNotAuthenticated extends ProfileFailure {
  const _ProfileNotAuthenticated()
      : super(
          'Utilisateur non authentifie : impossible de creer le profil.',
        );

  @override
  List<Object?> get props => const ['ProfileFailure.notAuthenticated'];
}

class _ProfileFirestoreError extends ProfileFailure {
  const _ProfileFirestoreError(super.message);

  @override
  List<Object?> get props => ['ProfileFailure.firestoreError', message];
}
