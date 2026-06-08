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

  /// Story 1.5 — Stream du doc users/{uid}. Emet le snapshot (possiblement
  /// absent ou partiel) a chaque update Firestore. Lecture en cache offline
  /// (NFR-5 + ADR-010 : cache Firestore natif 40MB Story 0.7).
  ///
  /// Emet `null` si :
  ///   - l'utilisateur n'est pas authentifie (Stream.value(null))
  ///   - le doc users/{uid} n'existe pas encore (cas visiteur mi-flow)
  ///
  /// Emet `Map<String, dynamic>` sinon (data brute du doc).
  ///
  /// Le mapping vers `ProfileCompletionState` est fait par
  /// `profileCompletionProvider` — ce repo retourne la donnee brute pour
  /// preserver la separation des concerns (clean architecture).
  Stream<Map<String, dynamic>?> watchProfile();

  /// Story 1.4 — Met a jour le champ `optedOutSubjects` du doc users/{uid}.
  ///
  /// Utilise `update()` partiel (pas set merge) pour ne toucher que ce champ
  /// + `updatedAt` serverTimestamp. La validation cote serveur (firestore.rules
  /// Story 1.4 AC4) garantit `optedOutSubjects ⊆ derivedSubjects`.
  ///
  /// Retourne `Left(ProfileFailure)` si :
  ///   - currentUser absent (notAuthenticated)
  ///   - FirebaseException (doc absent, rule violation, etc.) -> firestoreError
  Future<Either<ProfileFailure, void>> updateOptedOutSubjects(
    List<String> optedOutSubjectIds,
  );
}
