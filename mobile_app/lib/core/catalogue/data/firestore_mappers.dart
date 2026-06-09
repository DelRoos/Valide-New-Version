// Factories `fromFirestore(DocumentSnapshot)` — Story 1.1c.
//
// Couche DATA : pont entre Firestore et les models domain. Isolée ici pour
// respecter ADR-001 § Règle d'or des dépendances (la couche domain ne connaît
// pas Firebase).
//
// Si un champ requis est manquant ou de mauvais type, on lève une `StateError`
// — capturée par le repository et traduite en `CatalogueFailure.networkError`.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/models.dart';

/// Helper pour extraire un `Map<String, String>` (bilingue fr/en) depuis un
/// `Map<String, dynamic>` Firestore. Tolère les valeurs `null` dans la map en
/// les remplaçant par une chaîne vide pour ne pas faire crasher la lecture.
Map<String, String> _readBilingualName(dynamic raw) {
  if (raw is! Map) {
    throw StateError('name field must be a map, got ${raw.runtimeType}');
  }
  return {
    'fr': (raw['fr'] ?? '') as String,
    'en': (raw['en'] ?? '') as String,
  };
}

List<String> _readStringList(dynamic raw) {
  if (raw == null) return const [];
  if (raw is! List) {
    throw StateError('expected list, got ${raw.runtimeType}');
  }
  return raw.cast<String>();
}

Filiere filiereFromFirestore(DocumentSnapshot<Map<String, dynamic>> snap) {
  final data = snap.data();
  if (data == null) {
    throw StateError('filiere doc ${snap.id} has no data');
  }
  return Filiere(
    filiereId: snap.id,
    name: _readBilingualName(data['name']),
    isActive: (data['isActive'] as bool?) ?? false,
    sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
  );
}

Niveau niveauFromFirestore(DocumentSnapshot<Map<String, dynamic>> snap) {
  final data = snap.data();
  if (data == null) {
    throw StateError('niveau doc ${snap.id} has no data');
  }
  return Niveau(
    niveauId: snap.id,
    subSystem: data['subSystem'] as String,
    name: _readBilingualName(data['name']),
    filiereIds: _readStringList(data['filiereIds']),
    isActive: (data['isActive'] as bool?) ?? false,
    sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
  );
}

Serie serieFromFirestore(DocumentSnapshot<Map<String, dynamic>> snap) {
  final data = snap.data();
  if (data == null) {
    throw StateError('serie doc ${snap.id} has no data');
  }
  return Serie(
    serieId: snap.id,
    subSystem: data['subSystem'] as String,
    niveauId: data['niveauId'] as String,
    filiereId: data['filiereId'] as String,
    name: _readBilingualName(data['name']),
    canOptOut: (data['canOptOut'] as bool?) ?? false,
    isActive: (data['isActive'] as bool?) ?? false,
    sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
    // NEW v2 — Story 1.13 (defaults safe pour docs v1 sans ces champs)
    pickerMode: PickerMode.fromString(data['pickerMode'] as String?),
    minSubjects: (data['minSubjects'] as num?)?.toInt(),
    maxSubjects: (data['maxSubjects'] as num?)?.toInt(),
    professionalSubjectIds: _readStringList(data['professionalSubjectIds']),
    relatedProfessionalSubjectIds:
        _readStringList(data['relatedProfessionalSubjectIds']),
    otherSubjectIds: _readStringList(data['otherSubjectIds']),
  );
}

Subject subjectFromFirestore(DocumentSnapshot<Map<String, dynamic>> snap) {
  final data = snap.data();
  if (data == null) {
    throw StateError('subject doc ${snap.id} has no data');
  }
  return Subject(
    subjectId: snap.id,
    subSystem: data['subSystem'] as String,
    name: _readBilingualName(data['name']),
    icon: (data['icon'] as String?) ?? 'circle',
    isActive: (data['isActive'] as bool?) ?? false,
    sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
  );
}

ExamTarget examTargetFromFirestore(
  DocumentSnapshot<Map<String, dynamic>> snap,
) {
  final data = snap.data();
  if (data == null) {
    throw StateError('exam_target doc ${snap.id} has no data');
  }
  return ExamTarget(
    examTargetId: snap.id,
    subSystem: data['subSystem'] as String,
    name: _readBilingualName(data['name']),
    isActive: (data['isActive'] as bool?) ?? false,
    sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
  );
}

DerivationRule derivationRuleFromFirestore(
  DocumentSnapshot<Map<String, dynamic>> snap,
) {
  final data = snap.data();
  if (data == null) {
    throw StateError('derivation_rule doc ${snap.id} has no data');
  }
  return DerivationRule(
    ruleId: snap.id,
    matchSubSystem: data['matchSubSystem'] as String,
    matchFiliere: data['matchFiliere'] as String,
    matchNiveau: data['matchNiveau'] as String,
    matchSerie: data['matchSerie'] as String?,
    subjectIds: _readStringList(data['subjectIds']),
    examTargetIds: _readStringList(data['examTargetIds']),
    canOptOut: (data['canOptOut'] as bool?) ?? false,
    isActive: (data['isActive'] as bool?) ?? false,
    // NEW v2 — Story 1.13 (defaults safe : listes vides si champs absents)
    obligatorySubjectIds: _readStringList(data['obligatorySubjectIds']),
    optionalSubjectIds: _readStringList(data['optionalSubjectIds']),
  );
}
