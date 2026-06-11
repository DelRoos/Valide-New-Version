// Helper : mappe une ProfileFailure vers le bon message utilisateur ARB.
//
// Centralise la logique de selection pour eviter la duplication dans chaque
// caller. Utilise par tous les ecrans qui consomment un repository
// retournant ProfileFailure (subjects_picker_page, school_picker_page,
// profile_recap_page, ...).
//
// CLAUDE.md regle 13 (a venir) : les erreurs Firestore doivent etre
// explicites pour l'utilisateur, pas un message generique opaque.

import '../../../l10n/generated/app_localizations.dart';
import '../domain/profile_failure.dart';

/// Retourne le message localise approprie pour une [ProfileFailure].
///
/// Mapping :
/// - permissionDenied -> errorPermissionDenied ("Session expiree, re-lance...")
/// - networkUnavailable -> errorNetworkUnavailable ("Pas de connexion...")
/// - notAuthenticated -> errorPermissionDenied (cas voisin, meme remede)
/// - unknown -> errorFirestoreUnknown ("Erreur technique...")
String profileFailureUserMessage(AppLocalizations l10n, ProfileFailure failure) {
  switch (failure.kind) {
    case ProfileFailureKind.permissionDenied:
    case ProfileFailureKind.notAuthenticated:
      return l10n.errorPermissionDenied;
    case ProfileFailureKind.networkUnavailable:
      return l10n.errorNetworkUnavailable;
    case ProfileFailureKind.unknown:
      return l10n.errorFirestoreUnknown;
  }
}
