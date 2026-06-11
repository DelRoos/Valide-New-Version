// Story 1.3 — Failures de la creation du profil users/{uid}.
//
// Etend la hierarchie `Failure` (Story 1.1c a change sealed -> abstract pour
// permettre l'extension par feature). Coherent pattern Either<Failure, T>
// (NFR-7) — aucune exception ne remonte a l'UI.

import '../../../core/error/failures.dart';

/// Categorie d'erreur Firestore pour selectionner le message utilisateur.
/// Mappe FirebaseException.code -> categorie via [profileFailureKindForCode].
/// Permet au caller UI de choisir une cle ARB explicite (cf.
/// errorPermissionDenied / errorNetworkUnavailable / errorFirestoreUnknown).
enum ProfileFailureKind {
  notAuthenticated,
  permissionDenied,
  networkUnavailable,
  unknown,
}

/// Mappe un FirebaseException.code vers une [ProfileFailureKind] pour
/// driver le choix du message UI explicite.
ProfileFailureKind profileFailureKindForCode(String? code) {
  if (code == null) return ProfileFailureKind.unknown;
  switch (code) {
    case 'permission-denied':
      return ProfileFailureKind.permissionDenied;
    case 'unavailable':
    case 'network-request-failed':
    case 'deadline-exceeded':
      return ProfileFailureKind.networkUnavailable;
    default:
      return ProfileFailureKind.unknown;
  }
}

abstract class ProfileFailure extends Failure {
  const ProfileFailure(super.message);

  /// Categorie de l'erreur — utilise par le caller UI pour selectionner
  /// le bon message ARB (cf. profileFailureKindForCode).
  ProfileFailureKind get kind;

  const factory ProfileFailure.notAuthenticated() = _ProfileNotAuthenticated;
  const factory ProfileFailure.firestoreError(String message, {String? code}) =
      _ProfileFirestoreError;
}

class _ProfileNotAuthenticated extends ProfileFailure {
  const _ProfileNotAuthenticated()
      : super(
          'Utilisateur non authentifie : impossible de creer le profil.',
        );

  @override
  ProfileFailureKind get kind => ProfileFailureKind.notAuthenticated;

  @override
  List<Object?> get props => const ['ProfileFailure.notAuthenticated'];
}

class _ProfileFirestoreError extends ProfileFailure {
  const _ProfileFirestoreError(super.message, {this.code});

  /// FirebaseException.code original quand disponible (pour driver le
  /// message UI). Null si l'erreur n'est pas une FirebaseException.
  final String? code;

  @override
  ProfileFailureKind get kind => profileFailureKindForCode(code);

  @override
  List<Object?> get props => ['ProfileFailure.firestoreError', message, code];
}
