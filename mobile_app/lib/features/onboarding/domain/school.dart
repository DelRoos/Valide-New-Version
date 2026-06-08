// Story 1.7 — Modele Ecole (catalogue schools/{schoolId}).
//
// Domain pur : pas d'import Firebase. Cf. doc/partage/BASE-DE-DONNEES.md
// § schools/{schoolId}.

import 'package:equatable/equatable.dart';

class School extends Equatable {
  const School({
    required this.schoolId,
    required this.name,
    required this.city,
    required this.region,
    required this.subSystem,
    required this.isValidated,
  });

  final String schoolId;
  final String name;
  final String city;
  final String region;

  /// `francophone` | `anglophone` | `both`.
  final String subSystem;

  final bool isValidated;

  @override
  List<Object?> get props =>
      [schoolId, name, city, region, subSystem, isValidated];
}
