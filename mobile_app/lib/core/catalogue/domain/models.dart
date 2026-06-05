// Models domain du catalogue scolaire — Story 1.1c.
//
// 7 classes immutables Equatable. Couche DOMAIN pure :
//   - PAS d'import Flutter
//   - PAS d'import Firebase
//   - PAS d'import Riverpod
//   - PAS d'import fpdart
// Seul `package:equatable/equatable.dart` est autorisé ici.
//
// Les factories `fromFirestore(DocumentSnapshot)` vivent dans la couche data
// (lib/core/catalogue/data/firestore_mappers.dart) pour respecter ADR-001 §
// Règle d'or des dépendances.
//
// Schéma Firestore canonique : cf. doc/partage/BASE-DE-DONNEES.md §
// « Catalogue scolaire (6 collections — Story 1.1a) ».
// Conventions IDs snake_case prefixe subSystem.

import 'package:equatable/equatable.dart';

/// Filière scolaire (`generale` ou `technique`).
class Filiere extends Equatable {
  const Filiere({
    required this.filiereId,
    required this.name,
    required this.isActive,
    required this.sortOrder,
  });

  final String filiereId;
  final Map<String, String> name; // {fr, en}
  final bool isActive;
  final int sortOrder;

  Map<String, dynamic> toJson() => {
        'filiereId': filiereId,
        'name': name,
        'isActive': isActive,
        'sortOrder': sortOrder,
      };

  @override
  List<Object?> get props => [filiereId, name, isActive, sortOrder];
}

/// Niveau scolaire (ex. `francophone_terminale`, `anglophone_form_5`).
class Niveau extends Equatable {
  const Niveau({
    required this.niveauId,
    required this.subSystem,
    required this.name,
    required this.filiereIds,
    required this.isActive,
    required this.sortOrder,
  });

  final String niveauId;
  final String subSystem; // "francophone" | "anglophone"
  final Map<String, String> name;
  final List<String> filiereIds;
  final bool isActive;
  final int sortOrder;

  Map<String, dynamic> toJson() => {
        'niveauId': niveauId,
        'subSystem': subSystem,
        'name': name,
        'filiereIds': filiereIds,
        'isActive': isActive,
        'sortOrder': sortOrder,
      };

  @override
  List<Object?> get props =>
      [niveauId, subSystem, name, filiereIds, isActive, sortOrder];
}

/// Série / stream (ex. `francophone_terminale_d`, `anglophone_upper_sixth_s2`).
class Serie extends Equatable {
  const Serie({
    required this.serieId,
    required this.subSystem,
    required this.niveauId,
    required this.filiereId,
    required this.name,
    required this.canOptOut,
    required this.isActive,
    required this.sortOrder,
  });

  final String serieId;
  final String subSystem;
  final String niveauId;
  final String filiereId;
  final Map<String, String> name;
  final bool canOptOut; // Story 1.4
  final bool isActive;
  final int sortOrder;

  Map<String, dynamic> toJson() => {
        'serieId': serieId,
        'subSystem': subSystem,
        'niveauId': niveauId,
        'filiereId': filiereId,
        'name': name,
        'canOptOut': canOptOut,
        'isActive': isActive,
        'sortOrder': sortOrder,
      };

  @override
  List<Object?> get props => [
        serieId,
        subSystem,
        niveauId,
        filiereId,
        name,
        canOptOut,
        isActive,
        sortOrder,
      ];
}

/// Matière (ex. `francophone_math`, `anglophone_pure_maths`).
class Subject extends Equatable {
  const Subject({
    required this.subjectId,
    required this.subSystem,
    required this.name,
    required this.icon,
    required this.isActive,
    required this.sortOrder,
  });

  final String subjectId;
  final String subSystem;
  final Map<String, String> name;
  final String icon; // Nom Lucide (ex. "function-square")
  final bool isActive;
  final int sortOrder;

  Map<String, dynamic> toJson() => {
        'subjectId': subjectId,
        'subSystem': subSystem,
        'name': name,
        'icon': icon,
        'isActive': isActive,
        'sortOrder': sortOrder,
      };

  @override
  List<Object?> get props =>
      [subjectId, subSystem, name, icon, isActive, sortOrder];
}

/// Examen visé (ex. `exam_bac_francophone_d`, `exam_gce_a_level_anglophone_s2`).
class ExamTarget extends Equatable {
  const ExamTarget({
    required this.examTargetId,
    required this.subSystem,
    required this.name,
    required this.isActive,
    required this.sortOrder,
  });

  final String examTargetId;
  final String subSystem;
  final Map<String, String> name;
  final bool isActive;
  final int sortOrder;

  Map<String, dynamic> toJson() => {
        'examTargetId': examTargetId,
        'subSystem': subSystem,
        'name': name,
        'isActive': isActive,
        'sortOrder': sortOrder,
      };

  @override
  List<Object?> get props =>
      [examTargetId, subSystem, name, isActive, sortOrder];
}

/// Règle de dérivation (`subSystem, filiere, niveau, serie?`) → (subjects[], examTargets[]).
///
/// `matchFiliere == "*"` est un wildcard (utilisé pour les Forms anglophones
/// sans distinction filière). `matchSerie == null` est utilisé pour les niveaux
/// sans série (ex. 6ᵉ, Form 1).
class DerivationRule extends Equatable {
  const DerivationRule({
    required this.ruleId,
    required this.matchSubSystem,
    required this.matchFiliere,
    required this.matchNiveau,
    required this.matchSerie,
    required this.subjectIds,
    required this.examTargetIds,
    required this.canOptOut,
    required this.isActive,
  });

  final String ruleId;
  final String matchSubSystem;
  final String matchFiliere; // ref filieres/{id} ou "*"
  final String matchNiveau;
  final String? matchSerie; // null si niveau sans série
  final List<String> subjectIds;
  final List<String> examTargetIds;
  final bool canOptOut;
  final bool isActive;

  Map<String, dynamic> toJson() => {
        'ruleId': ruleId,
        'matchSubSystem': matchSubSystem,
        'matchFiliere': matchFiliere,
        'matchNiveau': matchNiveau,
        'matchSerie': matchSerie,
        'subjectIds': subjectIds,
        'examTargetIds': examTargetIds,
        'canOptOut': canOptOut,
        'isActive': isActive,
      };

  @override
  List<Object?> get props => [
        ruleId,
        matchSubSystem,
        matchFiliere,
        matchNiveau,
        matchSerie,
        subjectIds,
        examTargetIds,
        canOptOut,
        isActive,
      ];
}

/// Résultat de `CatalogueRepository.derive()` — profil dérivé.
class DerivedProfile extends Equatable {
  const DerivedProfile({
    required this.subjects,
    required this.examTargets,
    required this.canOptOut,
  });

  final List<Subject> subjects;
  final List<ExamTarget> examTargets;
  final bool canOptOut;

  @override
  List<Object?> get props => [subjects, examTargets, canOptOut];
}

/// Snapshot agrégé des 6 collections catalogue à un instant t.
///
/// Utilisé par `catalogueProvider` (StreamProvider) pour exposer l'état complet
/// du catalogue aux widgets consommateurs (Story 1.3 flow profil 3 étapes).
class CatalogueSnapshot extends Equatable {
  const CatalogueSnapshot({
    required this.filieres,
    required this.niveaux,
    required this.series,
    required this.subjects,
    required this.examTargets,
    required this.derivationRules,
  });

  const CatalogueSnapshot.empty()
      : filieres = const [],
        niveaux = const [],
        series = const [],
        subjects = const [],
        examTargets = const [],
        derivationRules = const [];

  final List<Filiere> filieres;
  final List<Niveau> niveaux;
  final List<Serie> series;
  final List<Subject> subjects;
  final List<ExamTarget> examTargets;
  final List<DerivationRule> derivationRules;

  bool get isEmpty =>
      filieres.isEmpty &&
      niveaux.isEmpty &&
      series.isEmpty &&
      subjects.isEmpty &&
      examTargets.isEmpty &&
      derivationRules.isEmpty;

  CatalogueSnapshot copyWith({
    List<Filiere>? filieres,
    List<Niveau>? niveaux,
    List<Serie>? series,
    List<Subject>? subjects,
    List<ExamTarget>? examTargets,
    List<DerivationRule>? derivationRules,
  }) {
    return CatalogueSnapshot(
      filieres: filieres ?? this.filieres,
      niveaux: niveaux ?? this.niveaux,
      series: series ?? this.series,
      subjects: subjects ?? this.subjects,
      examTargets: examTargets ?? this.examTargets,
      derivationRules: derivationRules ?? this.derivationRules,
    );
  }

  @override
  List<Object?> get props =>
      [filieres, niveaux, series, subjects, examTargets, derivationRules];
}
