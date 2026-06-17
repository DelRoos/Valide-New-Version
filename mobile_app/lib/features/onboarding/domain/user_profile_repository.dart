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
import 'school.dart';
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

  /// Story 1.15 — Persiste `pickedSubjects` (panier polymorphe, modes
  /// `free_with_obligatory`, `series_plus_optional`, `tve_picker`).
  ///
  /// La liste DOIT contenir OBLIGATOIRES + OPTIONNELS sélectionnés (pas
  /// uniquement les optionnels). Cohérent avec BASE-DE-DONNEES.md ligne 75
  /// (`obligatorySubjectIds ⊂ pickedSubjects`).
  ///
  /// Utilise `update()` partiel (CLAUDE.md règle 10.l) sur `{pickedSubjects,
  /// updatedAt}`. La validation côté serveur (firestore.rules Story 1.15
  /// `pickedSubjectsValid()`) garantit `pickedSubjects ⊆ derivedSubjects`
  /// (version pragmatique MVP, cf. Story 1.15 Décision 3).
  ///
  /// Retourne `Left(ProfileFailure)` si :
  ///   - currentUser absent (notAuthenticated)
  ///   - FirebaseException (rule violation, network, etc.) → firestoreError
  Future<Either<ProfileFailure, void>> updatePickedSubjects(
    List<String> pickedSubjectIds,
  );

  /// Story 1.5.d — Lie (ou délie) une école au doc users/{uid} en
  /// dénormalisant les 4 champs `{schoolId, schoolCity, schoolRegion,
  /// schoolName}` en 1 seul update partiel (CLAUDE.md règle 10.l). Préparation
  /// des features downstream (Epic 2+ dashboard, Epic 5 rankings régionaux,
  /// Epic 6 IA contextualisée) qui pourront lire ces champs sans N+1 reads
  /// sur la collection `schools`.
  ///
  /// - Si [school] est non-null : les 4 champs sont écrits cohérents
  ///   (`schoolId = school.schoolId`, `schoolCity = school.city`, etc.).
  /// - Si [school] est `null` : les 4 champs deviennent `null` ensemble
  ///   (unlink — pas de mismatch `schoolId=null` + `schoolName='Lycée X'`).
  ///
  /// L'entité [School] est passée par le caller (le tap sur une card du
  /// catalogue a déjà l'objet) — aucune lecture supplémentaire
  /// `schools/{schoolId}` n'est effectuée (CLAUDE.md règle 10.k).
  ///
  /// Les règles Story 1.3 (immuables : subSystem/filiere/niveau/serie/createdAt)
  /// ne touchent pas à ces 4 champs — l'update passe sans validation
  /// supplémentaire côté rules V1 (cf. firestore.rules § users/{uid}).
  ///
  /// Retourne `Left(ProfileFailure)` si :
  ///   - currentUser absent (notAuthenticated)
  ///   - FirebaseException remontée (firestoreError)
  Future<Either<ProfileFailure, void>> updateLinkedSchool(School? school);

  /// Lecture unique (`.get()`) du doc users/{uid}. Retourne null si le doc
  /// n'existe pas ou si uid est absent (utilisateur non authentifie).
  ///
  /// Utilise pour le cas "nouveau telephone, compte existant" : apres un
  /// sign-in Google/Apple, on verifie si un profil Firestore existe deja
  /// pour reprendre au bon step ou aller directement au dashboard.
  ///
  /// Cost : 1 read Firestore par sign-in social. Acceptable car declenche
  /// uniquement post-auth (pas a chaque frame). Utilise `.get()` et non
  /// `snapshots()` (profil statique pendant l'hydratation).
  ///
  /// Retourne `Left(ProfileFailure)` si :
  ///   - currentUser absent : retourne `Right(null)` (pas d'erreur)
  ///   - FirebaseException remontée (firestoreError)
  Future<Either<ProfileFailure, Map<String, dynamic>?>> fetchProfileOnce();
}
