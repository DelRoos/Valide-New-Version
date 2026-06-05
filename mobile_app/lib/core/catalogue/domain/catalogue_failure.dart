// CatalogueFailure — Story 1.1c.
//
// Hiérarchie d'erreurs spécifiques au catalogue scolaire, étend `Failure`
// (lib/core/error/failures.dart) pour rester compatible avec le pattern
// `Either<Failure, T>` global (NFR-7).
//
// Couche domain pure : import equatable + Failure de core/error uniquement.

import '../../error/failures.dart';

/// Erreurs métier du `CatalogueRepository`.
sealed class CatalogueFailure extends Failure {
  const CatalogueFailure(super.message);

  /// Catalogue Firestore vide ET cache offline vide (1er lancement strictement
  /// hors-ligne sans seed initial). Affiché par l'écran `/catalogue-waiting`.
  const factory CatalogueFailure.empty() = CatalogueEmptyFailure;

  /// Erreur de communication avec Firestore (permission-denied, unavailable,
  /// timeout, etc.).
  const factory CatalogueFailure.networkError(String message) =
      CatalogueNetworkFailure;

  /// Aucune `derivation_rule` Firestore ne matche le profil fourni. Indique
  /// soit un trou dans la matrice (à corriger côté admin), soit un profil
  /// invalide (à corriger côté Story 1.3 flow profil).
  const factory CatalogueFailure.noMatchingRule({
    required String subSystem,
    required String filiere,
    required String niveau,
    String? serie,
  }) = CatalogueNoMatchingRuleFailure;
}

class CatalogueEmptyFailure extends CatalogueFailure {
  const CatalogueEmptyFailure()
      : super('Catalogue scolaire indisponible (offline + cache vide)');

  @override
  List<Object?> get props => [message];
}

class CatalogueNetworkFailure extends CatalogueFailure {
  const CatalogueNetworkFailure(super.message);

  @override
  List<Object?> get props => [message];
}

class CatalogueNoMatchingRuleFailure extends CatalogueFailure {
  const CatalogueNoMatchingRuleFailure({
    required this.subSystem,
    required this.filiere,
    required this.niveau,
    this.serie,
  }) : super(
          'Aucune règle de dérivation pour ce profil scolaire',
        );

  final String subSystem;
  final String filiere;
  final String niveau;
  final String? serie;

  @override
  List<Object?> get props => [subSystem, filiere, niveau, serie, message];
}
