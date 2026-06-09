// Models domain du catalogue scolaire — Story 1.1c + extension v2 Story 1.13.
//
// 7 classes immutables Equatable + 1 enum PickerMode. Couche DOMAIN pure :
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
// « Catalogue scolaire (6 collections — Story 1.1a) » + extension v2 ADR-016.
// Conventions IDs snake_case prefixe subSystem.

import 'package:equatable/equatable.dart';

/// Mode de sélection des matières — Story 1.11a / ADR-016 Décision 3.
///
/// 5 valeurs alignées sur `series.pickerMode` Firestore (snake_case côté JSON,
/// `lowerCamelCase` côté Dart). Le mapper [PickerMode.fromString] parse la
/// valeur Firestore et fallback sur [PickerMode.derived] si valeur inconnue
/// (rétrocompat v1 / défense en profondeur).
///
/// Sémantique :
/// - [derived] — default : matières dérivées non modifiables (Tle franco).
/// - [optOut] — legacy Story 1.4 : retrait simple (Anglo Lower/Upper Sixth
///   avant le refactor Story 1.16).
/// - [freeWithObligatory] — O-Level Form 3-5 : sélection libre 6-11 +
///   obligatoires EN+FR+Math.
/// - [seriesPlusOptional] — A-Level Lower/Upper Sixth : Series fixe +
///   transversales optionnelles.
/// - [tvePicker] — TVEE : Professional + Related obligatoires + Other libres.
enum PickerMode {
  derived,
  optOut,
  freeWithObligatory,
  seriesPlusOptional,
  tvePicker;

  /// Parse une string Firestore (`derived` / `opt_out` / `free_with_obligatory`
  /// / `series_plus_optional` / `tve_picker`) en [PickerMode].
  ///
  /// Fallback sur [PickerMode.derived] si valeur inconnue (rétrocompat v1 où
  /// le champ Firestore `pickerMode` est absent → defaults safe).
  static PickerMode fromString(String? raw) {
    return switch (raw) {
      'derived' => PickerMode.derived,
      'opt_out' => PickerMode.optOut,
      'free_with_obligatory' => PickerMode.freeWithObligatory,
      'series_plus_optional' => PickerMode.seriesPlusOptional,
      'tve_picker' => PickerMode.tvePicker,
      _ => PickerMode.derived,
    };
  }

  /// Sérialise vers la string Firestore (utile pour `toJson` debug).
  String toFirestoreString() {
    return switch (this) {
      PickerMode.derived => 'derived',
      PickerMode.optOut => 'opt_out',
      PickerMode.freeWithObligatory => 'free_with_obligatory',
      PickerMode.seriesPlusOptional => 'series_plus_optional',
      PickerMode.tvePicker => 'tve_picker',
    };
  }
}

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

/// Niveau scolaire (ex. `francophone_terminale`, `anglophone_form_5`,
/// `anglophone_tve_il`).
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

/// Série / stream (ex. `francophone_terminale_d`, `anglophone_upper_sixth_s2`,
/// `anglophone_tve_al_elet`).
///
/// **Story 1.13 — v2** : 6 nouveaux champs ajoutés (rétrocompat v1 via defaults
/// safe) pour supporter le panier polymorphe ADR-016 :
/// - [pickerMode] : default [PickerMode.derived] (comportement v1).
/// - [minSubjects] / [maxSubjects] : null si pas de borne (mode derived).
/// - [professionalSubjectIds] / [relatedProfessionalSubjectIds] /
///   [otherSubjectIds] : spécifiques TVEE (`pickerMode == tvePicker`), listes
///   vides pour autres modes.
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
    // NEW v2 — Story 1.13 (defaults safe pour rétrocompat v1).
    this.pickerMode = PickerMode.derived,
    this.minSubjects,
    this.maxSubjects,
    this.professionalSubjectIds = const [],
    this.relatedProfessionalSubjectIds = const [],
    this.otherSubjectIds = const [],
  });

  final String serieId;
  final String subSystem;
  final String niveauId;
  final String filiereId;
  final Map<String, String> name;
  final bool canOptOut; // Story 1.4
  final bool isActive;
  final int sortOrder;

  // NEW v2 — Story 1.13
  final PickerMode pickerMode;
  final int? minSubjects;
  final int? maxSubjects;
  final List<String> professionalSubjectIds;
  final List<String> relatedProfessionalSubjectIds;
  final List<String> otherSubjectIds;

  Map<String, dynamic> toJson() => {
        'serieId': serieId,
        'subSystem': subSystem,
        'niveauId': niveauId,
        'filiereId': filiereId,
        'name': name,
        'canOptOut': canOptOut,
        'isActive': isActive,
        'sortOrder': sortOrder,
        // v2
        'pickerMode': pickerMode.toFirestoreString(),
        'minSubjects': minSubjects,
        'maxSubjects': maxSubjects,
        'professionalSubjectIds': professionalSubjectIds,
        'relatedProfessionalSubjectIds': relatedProfessionalSubjectIds,
        'otherSubjectIds': otherSubjectIds,
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
        pickerMode,
        minSubjects,
        maxSubjects,
        professionalSubjectIds,
        relatedProfessionalSubjectIds,
        otherSubjectIds,
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

/// Examen visé (ex. `exam_bac_francophone_d`, `exam_gce_a_level_anglophone_s2`,
/// `exam_tve_al_anglophone_elet`).
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
///
/// **Story 1.13 — v2** : 2 nouveaux champs (rétrocompat v1 via listes vides) :
/// - [obligatorySubjectIds] : matières non décochables (mode panier).
/// - [optionalSubjectIds] : matières ajoutables (mode `series_plus_optional` /
///   `free_with_obligatory`).
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
    // NEW v2 — Story 1.13.
    this.obligatorySubjectIds = const [],
    this.optionalSubjectIds = const [],
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

  // NEW v2 — Story 1.13
  final List<String> obligatorySubjectIds;
  final List<String> optionalSubjectIds;

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
        // v2
        'obligatorySubjectIds': obligatorySubjectIds,
        'optionalSubjectIds': optionalSubjectIds,
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
        obligatorySubjectIds,
        optionalSubjectIds,
      ];
}

/// Résultat de `CatalogueRepository.derive()` — profil dérivé.
///
/// **Story 1.13 — v2** : 5 nouveaux champs exposant le panier polymorphe
/// ADR-016 aux widgets consommateurs (Stories 1.14-1.17) :
/// - [pickerMode] : default [PickerMode.derived] (comportement v1).
/// - [obligatorySubjects] : sous-ensemble non décochable (`pickerMode ==
///   freeWithObligatory` / `tvePicker`).
/// - [optionalSubjects] : matières ajoutables (`pickerMode ==
///   seriesPlusOptional` / `freeWithObligatory`).
/// - [minSubjects] / [maxSubjects] : null si pas de borne (mode derived).
class DerivedProfile extends Equatable {
  const DerivedProfile({
    required this.subjects,
    required this.examTargets,
    required this.canOptOut,
    // NEW v2 — Story 1.13.
    this.pickerMode = PickerMode.derived,
    this.obligatorySubjects = const [],
    this.optionalSubjects = const [],
    this.minSubjects,
    this.maxSubjects,
  });

  final List<Subject> subjects;
  final List<ExamTarget> examTargets;
  final bool canOptOut;

  // NEW v2 — Story 1.13
  final PickerMode pickerMode;
  final List<Subject> obligatorySubjects;
  final List<Subject> optionalSubjects;
  final int? minSubjects;
  final int? maxSubjects;

  @override
  List<Object?> get props => [
        subjects,
        examTargets,
        canOptOut,
        pickerMode,
        obligatorySubjects,
        optionalSubjects,
        minSubjects,
        maxSubjects,
      ];
}

/// Snapshot agrégé des 6 collections catalogue à un instant t.
///
/// **Story 1.13 — refactor** : utilisé par `catalogueProvider` (désormais
/// `FutureProvider`, ex-`StreamProvider`) pour exposer l'état complet du
/// catalogue aux widgets consommateurs (Story 1.3 flow profil 3 étapes).
/// Cf. CLAUDE.md règle 10.g + BASE-DE-DONNEES.md audit 2026-06-09.
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
