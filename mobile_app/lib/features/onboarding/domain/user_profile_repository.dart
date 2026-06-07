// Story 1.3 — Interface UserProfileRepository.
//
// Encapsule la creation du doc users/{uid} Firestore (AC6). Couche domain :
// signature stable pour permettre :
//   - une impl Firestore (Story 1.3, UserProfileRepositoryFirestoreImpl)
//   - une impl mock pour les tests widget (T11)
//   - une eventuelle migration future vers Cloud Function deriveProfile sans
//     refactor des consommateurs (cf. ADR-015 § Decisions liees ADR-001).

import 'package:fpdart/fpdart.dart';

import 'profile_failure.dart';
import 'sub_system.dart';

abstract interface class UserProfileRepository {
  /// Cree (ou met a jour idempotent) le doc users/{uid} Firestore avec les
  /// champs fournis. Utilise set(merge: true) pour permettre les retry.
  ///
  /// Retourne `Left(ProfileFailure)` si :
  ///   - currentUser absent (notAuthenticated)
  ///   - FirebaseException remontee (firestoreError)
  ///
  /// Les timestamps `createdAt` et `updatedAt` sont calcules cote serveur via
  /// FieldValue.serverTimestamp() — JAMAIS DateTime.now() client.
  Future<Either<ProfileFailure, void>> createProfile({
    required SubSystem subSystem,
    required String filiereId,
    required String niveauId,
    required String serieId, // peut etre '-' si niveau sans serie
    required List<String> derivedSubjects,
    required List<String> examTargets,
  });
}
