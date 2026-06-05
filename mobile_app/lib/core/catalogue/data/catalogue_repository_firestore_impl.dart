// CatalogueRepositoryFirestoreImpl — Story 1.1c.
//
// Implémentation Firestore du `CatalogueRepository`. Couche DATA — peut
// importer Firebase, log et fpdart.
//
// Règles d'implémentation :
//   - Filtrer systématiquement `where('isActive', '==', true)`
//   - `orderBy('sortOrder')` quand applicable
//   - Traduire toute `Exception` en `CatalogueFailure` (NFR-7)
//   - Logger `AppLogger.i` au 1er succès, `AppLogger.w` aux erreurs gérables

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';

import '../../logging/app_logger.dart';
import '../domain/catalogue_failure.dart';
import '../domain/catalogue_repository.dart';
import '../domain/models.dart';
import 'firestore_mappers.dart';

class CatalogueRepositoryFirestoreImpl implements CatalogueRepository {
  CatalogueRepositoryFirestoreImpl(this._firestore);

  final FirebaseFirestore _firestore;

  // Names canoniques des 6 collections — figés en Story 1.1a (BASE-DE-DONNEES).
  static const String _kFilieres = 'filieres';
  static const String _kNiveaux = 'niveaux';
  static const String _kSeries = 'series';
  static const String _kSubjects = 'subjects';
  static const String _kExamTargets = 'exam_targets';
  static const String _kDerivationRules = 'derivation_rules';

  @override
  Stream<List<Filiere>> watchFilieres() {
    return _firestore
        .collection(_kFilieres)
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .snapshots()
        .map(
          (qs) => qs.docs.map(filiereFromFirestore).toList(growable: false),
        );
  }

  @override
  Stream<List<Niveau>> watchNiveaux({String? subSystem, String? filiereId}) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(_kNiveaux)
        .where('isActive', isEqualTo: true);
    if (subSystem != null) {
      query = query.where('subSystem', isEqualTo: subSystem);
    }
    if (filiereId != null) {
      query = query.where('filiereIds', arrayContains: filiereId);
    }
    return query.orderBy('sortOrder').snapshots().map(
          (qs) => qs.docs.map(niveauFromFirestore).toList(growable: false),
        );
  }

  @override
  Stream<List<Serie>> watchSeries({
    String? subSystem,
    String? niveauId,
    String? filiereId,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(_kSeries)
        .where('isActive', isEqualTo: true);
    if (subSystem != null) {
      query = query.where('subSystem', isEqualTo: subSystem);
    }
    if (niveauId != null) {
      query = query.where('niveauId', isEqualTo: niveauId);
    }
    if (filiereId != null) {
      query = query.where('filiereId', isEqualTo: filiereId);
    }
    return query.orderBy('sortOrder').snapshots().map(
          (qs) => qs.docs.map(serieFromFirestore).toList(growable: false),
        );
  }

  @override
  Stream<List<Subject>> watchSubjects({String? subSystem}) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(_kSubjects)
        .where('isActive', isEqualTo: true);
    if (subSystem != null) {
      query = query.where('subSystem', isEqualTo: subSystem);
    }
    return query.orderBy('sortOrder').snapshots().map(
          (qs) => qs.docs.map(subjectFromFirestore).toList(growable: false),
        );
  }

  @override
  Stream<List<ExamTarget>> watchExamTargets({String? subSystem}) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(_kExamTargets)
        .where('isActive', isEqualTo: true);
    if (subSystem != null) {
      query = query.where('subSystem', isEqualTo: subSystem);
    }
    return query.orderBy('sortOrder').snapshots().map(
          (qs) =>
              qs.docs.map(examTargetFromFirestore).toList(growable: false),
        );
  }

  @override
  Stream<List<DerivationRule>> watchDerivationRules({String? subSystem}) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(_kDerivationRules)
        .where('isActive', isEqualTo: true);
    if (subSystem != null) {
      query = query.where('matchSubSystem', isEqualTo: subSystem);
    }
    // Pas de orderBy('sortOrder') — derivation_rules n'a pas ce champ.
    return query.snapshots().map(
          (qs) => qs.docs
              .map(derivationRuleFromFirestore)
              .toList(growable: false),
        );
  }

  @override
  Future<Either<CatalogueFailure, DerivedProfile>> derive({
    required String subSystem,
    required String filiere,
    required String niveau,
    String? serie,
  }) async {
    try {
      // 1. Récupérer les rules actives matchant subSystem + niveau (côté serveur).
      //    Le wildcard "*" sur matchFiliere et le matchSerie nullable sont
      //    filtrés côté client (Firestore ne supporte pas les OR cross-field
      //    sans index dédié — pas la peine pour <100 rules par subSystem).
      final rulesSnap = await _firestore
          .collection(_kDerivationRules)
          .where('matchSubSystem', isEqualTo: subSystem)
          .where('matchNiveau', isEqualTo: niveau)
          .where('isActive', isEqualTo: true)
          .get();

      final candidates = rulesSnap.docs
          .map(derivationRuleFromFirestore)
          .where((r) => r.matchFiliere == '*' || r.matchFiliere == filiere)
          .where((r) => r.matchSerie == null || r.matchSerie == serie)
          .toList(growable: false);

      if (candidates.isEmpty) {
        AppLogger.w(
          'derive() noMatchingRule: subSystem=$subSystem filiere=$filiere '
          'niveau=$niveau serie=${serie ?? "(none)"}',
        );
        return Left(
          CatalogueFailure.noMatchingRule(
            subSystem: subSystem,
            filiere: filiere,
            niveau: niveau,
            serie: serie,
          ),
        );
      }

      final rule = candidates.first;

      // 2. Résoudre subjects + exam_targets en parallèle (filtrer isActive).
      //    Firestore `whereIn` limité à 30 — une rule typique a 5-10 subjects.
      final subjectsFuture = rule.subjectIds.isEmpty
          ? Future.value(<Subject>[])
          : _firestore
              .collection(_kSubjects)
              .where(FieldPath.documentId, whereIn: rule.subjectIds)
              .where('isActive', isEqualTo: true)
              .get()
              .then(
                (qs) =>
                    qs.docs.map(subjectFromFirestore).toList(growable: false),
              );

      final examTargetsFuture = rule.examTargetIds.isEmpty
          ? Future.value(<ExamTarget>[])
          : _firestore
              .collection(_kExamTargets)
              .where(FieldPath.documentId, whereIn: rule.examTargetIds)
              .where('isActive', isEqualTo: true)
              .get()
              .then(
                (qs) => qs.docs
                    .map(examTargetFromFirestore)
                    .toList(growable: false),
              );

      final results = await Future.wait([subjectsFuture, examTargetsFuture]);
      final subjects = results[0] as List<Subject>;
      final examTargets = results[1] as List<ExamTarget>;

      AppLogger.i(
        'derive() OK: profile=($subSystem/$filiere/$niveau/${serie ?? "-"}) '
        'subjects=${subjects.length} examTargets=${examTargets.length}',
      );

      return Right(
        DerivedProfile(
          subjects: subjects,
          examTargets: examTargets,
          canOptOut: rule.canOptOut,
        ),
      );
    } on FirebaseException catch (e, st) {
      AppLogger.w('derive() Firebase error: ${e.code}', error: e);
      AppLogger.w('derive() stack: $st');
      return Left(
        CatalogueFailure.networkError(e.message ?? 'Firebase: ${e.code}'),
      );
    } catch (e, st) {
      AppLogger.w('derive() unexpected error: $e', error: e);
      AppLogger.w('derive() stack: $st');
      return Left(CatalogueFailure.networkError(e.toString()));
    }
  }

  @override
  Future<bool> hasNonEmptyCatalogue() async {
    try {
      // On lit 1 doc de derivation_rules — si au moins 1 rule active existe,
      // le catalogue est servable. Sinon (vide réseau + vide cache) → false.
      final snap = await _firestore
          .collection(_kDerivationRules)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      final hasOne = snap.docs.isNotEmpty;
      if (hasOne) {
        AppLogger.i('Catalogue check: at least 1 derivation_rule active');
      } else {
        AppLogger.w('Catalogue empty (offline+cache vide ou pas seed)');
      }
      return hasOne;
    } catch (e, st) {
      AppLogger.w('hasNonEmptyCatalogue() error: $e', error: e);
      AppLogger.w('hasNonEmptyCatalogue() stack: $st');
      // Fail-safe : on retourne false pour déclencher l'écran connexion bloquant
      // plutôt que de laisser l'app continuer sur un catalogue indéterminé.
      return false;
    }
  }
}
