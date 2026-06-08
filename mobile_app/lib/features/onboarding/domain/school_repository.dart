// Story 1.7 — Interface SchoolRepository.
//
// Domain pur : pas d'import Firebase. Either<SchoolFailure, T> aux frontieres
// (NFR-7).

import 'package:fpdart/fpdart.dart';

import 'school.dart';
import 'school_failure.dart';

abstract interface class SchoolRepository {
  /// Recherche les ecoles `isValidated == true` dont le nom commence par
  /// `query`. Court-circuite si `query.length < 2` (retourne liste vide).
  /// Limite a 10 resultats max (AC2).
  Future<Either<SchoolFailure, List<School>>> searchByPrefix(String query);

  /// Soumet une demande d'ajout d'ecole (ecriture
  /// `schools/_pending_$ts/requests/$autoId`). L'admin la traitera hors mobile.
  /// Retourne Right(void) en cas de succes (le client n'a pas besoin du
  /// requestId).
  Future<Either<SchoolFailure, void>> requestSchool({
    required String name,
    required String city,
    String? region,
  });
}
