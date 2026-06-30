// Story A.2 — Entité domaine profil public.
//
// Sous-ensemble lisible de users/{uid} sans champs sensibles
// (deletionRequestedAt, examTargets, pickedSubjects non exposés).
// Lecture via UserProfileRepository.fetchPublicProfile(uid) (T3).

import 'package:equatable/equatable.dart';

class PublicProfile extends Equatable {
  const PublicProfile({
    required this.uid,
    required this.displayName,
    required this.levelId,
    required this.streamId,
    this.schoolName,
    required this.subSystem,
  });

  final String uid;
  final String displayName;

  /// ID du niveau scolaire (ex. 'terminale'). Mappe Firestore 'levelId'
  /// (schema E1bis) ou 'niveau' (schema legacy Epic 1).
  final String levelId;

  /// ID de la série (ex. 'francophone_terminale_d'). Mappe Firestore 'streamId'
  /// (E1bis) ou 'serie' (legacy). Peut être vide pour niveaux sans série.
  final String streamId;

  /// Nom de l'école dénormalisé depuis users/{uid}.schoolName. Null si non lié.
  final String? schoolName;

  final String subSystem;

  @override
  List<Object?> get props => [uid, displayName, levelId, streamId, schoolName, subSystem];
}
