// Story 1.5.c — Modele demande d'ajout d'ecole (collection school_requests).
//
// Domain pur : pas d'import Firebase. Cf. doc/partage/BASE-DE-DONNEES.md
// § school_requests/{requestId}.

import 'package:equatable/equatable.dart';

class SchoolRequest extends Equatable {
  const SchoolRequest({
    required this.requestId,
    required this.requestedBy,
    required this.name,
    required this.city,
    this.region,
    this.subSystem,
    this.status = 'pending',
  });

  final String requestId;
  final String requestedBy;
  final String name;
  final String city;
  final String? region;

  /// `francophone` | `anglophone` | `both` | `null` (utilisateur ne sait pas).
  final String? subSystem;

  /// `pending` | `approved` | `rejected`. Initial : `pending`.
  final String status;

  @override
  List<Object?> get props => [
        requestId,
        requestedBy,
        name,
        city,
        region,
        subSystem,
        status,
      ];
}
