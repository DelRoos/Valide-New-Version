// CatalogueRepository — interface domain. Story 1.1c.
//
// Couche DOMAIN pure : seul `fpdart` (Either) + models locaux importés. PAS de
// Firebase ni Flutter ici. L'impl Firestore vit dans
// `lib/core/catalogue/data/catalogue_repository_firestore_impl.dart`.

import 'package:fpdart/fpdart.dart';

import 'catalogue_failure.dart';
import 'models.dart';

/// Accès au catalogue scolaire Firestore (ADR-015).
///
/// Tous les streams `watch*` appliquent systématiquement
/// `where('isActive', '==', true)` côté serveur et tient compte du cache offline
/// natif Firestore (Story 0.7, ADR-010 — NFR-5).
abstract interface class CatalogueRepository {
  Stream<List<Filiere>> watchFilieres();

  Stream<List<Niveau>> watchNiveaux({String? subSystem, String? filiereId});

  Stream<List<Serie>> watchSeries({
    String? subSystem,
    String? niveauId,
    String? filiereId,
  });

  Stream<List<Subject>> watchSubjects({String? subSystem});

  Stream<List<ExamTarget>> watchExamTargets({String? subSystem});

  Stream<List<DerivationRule>> watchDerivationRules({String? subSystem});

  /// Match la première `derivation_rule` active compatible avec le profil
  /// fourni et retourne le `DerivedProfile` (subjects + examTargets + canOptOut).
  ///
  /// Algorithme : cf. doc/partage/ALGORITHMES.md § 1.
  Future<Either<CatalogueFailure, DerivedProfile>> derive({
    required String subSystem,
    required String filiere,
    required String niveau,
    String? serie,
  });

  /// Détecte le cas « catalogue indisponible » au boot : vrai si au moins une
  /// `derivation_rule` active existe (= catalogue prêt à servir), faux si
  /// Firestore est vide ET le cache offline est vide.
  ///
  /// Utilisé par `appStartupCatalogueCheckProvider` pour rediriger vers
  /// `/catalogue-waiting` si nécessaire.
  Future<bool> hasNonEmptyCatalogue();
}
