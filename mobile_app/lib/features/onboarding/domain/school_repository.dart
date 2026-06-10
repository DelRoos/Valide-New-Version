// Story 1.7 — Interface SchoolRepository.
// Story 1.5.c — Refactor requestSchool -> createSchoolRequest avec collection
// racine school_requests + champ subSystem optionnel.
//
// Domain pur : pas d'import Firebase. Either<SchoolFailure, T> aux frontieres
// (NFR-7).

import 'package:fpdart/fpdart.dart';

import 'school.dart';
import 'school_failure.dart';

abstract interface class SchoolRepository {
  /// Recherche les ecoles `isValidated == true` dont les `keywords[]` contiennent
  /// le token normalise issu de `query`. Court-circuite si query trop courte
  /// (retourne liste vide). Limite a 10 resultats max (AC2 Story 1.7 + 1.5.b).
  Future<Either<SchoolFailure, List<School>>> searchByPrefix(String query);

  /// Story 1.5.c — Soumet une demande d'ajout d'ecole dans
  /// `school_requests/<auto>` (collection racine, autoId Firestore).
  ///
  /// Le champ `subSystem` est optionnel : l'utilisateur peut ne pas savoir.
  /// Idem `region`. Le champ `status` est force a `pending` par les rules
  /// au create — pas de parametre client (anti-escalade).
  ///
  /// Retourne `Right(void)` en cas de succes (le client n'a pas besoin du
  /// requestId pour V1 — un ecran "Mes demandes" futur lira via
  /// `where('requestedBy', '==', uid)`).
  Future<Either<SchoolFailure, void>> createSchoolRequest({
    required String name,
    required String city,
    String? region,
    String? subSystem,
  });
}
