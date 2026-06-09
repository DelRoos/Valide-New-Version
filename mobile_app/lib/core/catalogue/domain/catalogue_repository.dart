// CatalogueRepository — interface domain. Story 1.1c + refactor v2 Story 1.13.
//
// Couche DOMAIN pure : seul `fpdart` (Either) + models locaux importés. PAS de
// Firebase ni Flutter ici. L'impl Firestore vit dans
// `lib/core/catalogue/data/catalogue_repository_firestore_impl.dart`.
//
// **Story 1.13 — refactor `watchXxx` → `fetchXxx`** : le catalogue scolaire
// est une donnée statique (changée 1-2× par an via Console admin). Le pattern
// `.snapshots()` v1 était anti-pattern CLAUDE.md règle 10.g (cf. audit
// BASE-DE-DONNEES.md 2026-06-09). On passe à `.get()` + cache offline natif
// Firestore : ~80 % économie reads à 10k users (600k → 110k reads/mois).

import 'package:fpdart/fpdart.dart';

import 'catalogue_failure.dart';
import 'models.dart';

/// Accès au catalogue scolaire Firestore (ADR-015).
///
/// Toutes les méthodes `fetch*` appliquent systématiquement
/// `where('isActive', '==', true)` côté serveur et tirent parti du cache offline
/// natif Firestore (Story 0.7, ADR-010 — NFR-5). Lecture instantanée sur les
/// docs déjà chargés au prochain appel — 1 read facturé par doc à la première
/// requête uniquement.
abstract interface class CatalogueRepository {
  Future<List<Filiere>> fetchFilieres();

  Future<List<Niveau>> fetchNiveaux({String? subSystem, String? filiereId});

  Future<List<Serie>> fetchSeries({
    String? subSystem,
    String? niveauId,
    String? filiereId,
  });

  Future<List<Subject>> fetchSubjects({String? subSystem});

  Future<List<ExamTarget>> fetchExamTargets({String? subSystem});

  Future<List<DerivationRule>> fetchDerivationRules({String? subSystem});

  /// Match la première `derivation_rule` active compatible avec le profil
  /// fourni et retourne le `DerivedProfile` enrichi v2 (subjects + examTargets
  /// + canOptOut + pickerMode + obligatorySubjects + optionalSubjects +
  /// min/maxSubjects).
  ///
  /// Algorithme : cf. doc/partage/ALGORITHMES.md § 1 v2 (Story 1.11a AC4).
  ///
  /// **Story 1.13 — v2** : 5 futures parallélisées via `Future.wait` (série +
  /// subjects + examTargets + obligatorySubjects + optionalSubjects). Latence
  /// max(reads) au lieu de sum(reads) — gain critique réseau 3G Cameroun.
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
