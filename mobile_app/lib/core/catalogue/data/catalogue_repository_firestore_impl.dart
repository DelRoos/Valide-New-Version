// CatalogueRepositoryFirestoreImpl — Story 1.1c + refactor Story 1.13.
//
// Implémentation Firestore du `CatalogueRepository`. Couche DATA — peut
// importer Firebase, log et fpdart.
//
// Règles d'implémentation :
//   - Filtrer systématiquement `where('isActive', '==', true)`
//   - `orderBy('sortOrder')` quand applicable
//   - Traduire toute `Exception` en `CatalogueFailure` (NFR-7)
//   - Logger `AppLogger.i` au 1er succès, `AppLogger.w` aux erreurs gérables
//
// **Story 1.13 — refactor `snapshots()` → `get()`** :
// - Cohérent CLAUDE.md règle 10.g + BASE-DE-DONNEES.md audit 2026-06-09
// - 1 read facturé par doc à la première requête, puis cache offline natif
// - Économie estimée ~80 % reads Firestore vs pattern stream v1
// - Pas de réactivité runtime à l'admin Console (acceptable trade-off,
//   admin agit rarement, redémarrage app suffit)
//
// **Story 1.13 — `derive()` v2** :
// - DerivedProfile enrichi (pickerMode + obligatorySubjects + optionalSubjects
//   + min/maxSubjects)
// - 5 futures parallélisées via `Future.wait` (série + subjects + examTargets
//   + obligatorySubjects + optionalSubjects)
// - Helper privé `_fetchSubjectsByIds` factorisé 3×
// - `canOptOut` source = série v2 (fallback rule)

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
  Future<List<Filiere>> fetchFilieres() async {
    final qs = await _firestore
        .collection(_kFilieres)
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .get();
    return qs.docs.map(filiereFromFirestore).toList(growable: false);
  }

  @override
  Future<List<Niveau>> fetchNiveaux({
    String? subSystem,
    String? filiereId,
  }) async {
    Query<Map<String, dynamic>> query =
        _firestore.collection(_kNiveaux).where('isActive', isEqualTo: true);
    if (subSystem != null) {
      query = query.where('subSystem', isEqualTo: subSystem);
    }
    if (filiereId != null) {
      query = query.where('filiereIds', arrayContains: filiereId);
    }
    final qs = await query.orderBy('sortOrder').get();
    return qs.docs.map(niveauFromFirestore).toList(growable: false);
  }

  @override
  Future<List<Serie>> fetchSeries({
    String? subSystem,
    String? niveauId,
    String? filiereId,
  }) async {
    Query<Map<String, dynamic>> query =
        _firestore.collection(_kSeries).where('isActive', isEqualTo: true);
    if (subSystem != null) {
      query = query.where('subSystem', isEqualTo: subSystem);
    }
    if (niveauId != null) {
      query = query.where('niveauId', isEqualTo: niveauId);
    }
    if (filiereId != null) {
      query = query.where('filiereId', isEqualTo: filiereId);
    }
    final qs = await query.orderBy('sortOrder').get();
    return qs.docs.map(serieFromFirestore).toList(growable: false);
  }

  @override
  Future<List<Subject>> fetchSubjects({String? subSystem}) async {
    Query<Map<String, dynamic>> query =
        _firestore.collection(_kSubjects).where('isActive', isEqualTo: true);
    if (subSystem != null) {
      query = query.where('subSystem', isEqualTo: subSystem);
    }
    final qs = await query.orderBy('sortOrder').get();
    return qs.docs.map(subjectFromFirestore).toList(growable: false);
  }

  @override
  Future<List<ExamTarget>> fetchExamTargets({String? subSystem}) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(_kExamTargets)
        .where('isActive', isEqualTo: true);
    if (subSystem != null) {
      query = query.where('subSystem', isEqualTo: subSystem);
    }
    final qs = await query.orderBy('sortOrder').get();
    return qs.docs.map(examTargetFromFirestore).toList(growable: false);
  }

  @override
  Future<List<DerivationRule>> fetchDerivationRules({String? subSystem}) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(_kDerivationRules)
        .where('isActive', isEqualTo: true);
    if (subSystem != null) {
      query = query.where('matchSubSystem', isEqualTo: subSystem);
    }
    // Pas de orderBy('sortOrder') — derivation_rules n'a pas ce champ.
    final qs = await query.get();
    return qs.docs.map(derivationRuleFromFirestore).toList(growable: false);
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

      // 2. NEW v2 — Récupérer la série en parallèle des subjects/examTargets/
      //    obligatorySubjects/optionalSubjects (5 futures via Future.wait).
      //    Pattern critique : latence max(5 reads) au lieu de sum(5 reads) —
      //    gain ~3 RTT sur 3G Cameroun (~1.5s).
      final Future<Serie?> serieFuture = (serie != null)
          ? _firestore.collection(_kSeries).doc(serie).get().then(
              (snap) => snap.exists ? serieFromFirestore(snap) : null,
            )
          : Future.value(null);

      final subjectsFuture = _fetchSubjectsByIds(rule.subjectIds);
      final examTargetsFuture = _fetchExamTargetsByIds(rule.examTargetIds);
      final obligatorySubjectsFuture =
          _fetchSubjectsByIds(rule.obligatorySubjectIds);
      final optionalSubjectsFuture =
          _fetchSubjectsByIds(rule.optionalSubjectIds);

      final results = await Future.wait<dynamic>([
        serieFuture,
        subjectsFuture,
        examTargetsFuture,
        obligatorySubjectsFuture,
        optionalSubjectsFuture,
      ]);

      final Serie? serieDoc = results[0] as Serie?;
      final subjects = results[1] as List<Subject>;
      final examTargets = results[2] as List<ExamTarget>;
      final obligatorySubjects = results[3] as List<Subject>;
      final optionalSubjects = results[4] as List<Subject>;

      // 3. NEW v2 — canOptOut source de vérité = série (fallback rule)
      final canOptOut = serieDoc?.canOptOut ?? rule.canOptOut;
      // pickerMode default derived si pas de série (niveau sans série, ex.
      // Form 5 anglo) — comportement v1 compat.
      final pickerMode = serieDoc?.pickerMode ?? PickerMode.derived;

      AppLogger.i(
        'derive() OK: profile=($subSystem/$filiere/$niveau/${serie ?? "-"}) '
        'subjects=${subjects.length} examTargets=${examTargets.length} '
        'obligatory=${obligatorySubjects.length} '
        'optional=${optionalSubjects.length} '
        'pickerMode=${pickerMode.name} '
        'min=${serieDoc?.minSubjects ?? "-"} max=${serieDoc?.maxSubjects ?? "-"}',
      );

      return Right(
        DerivedProfile(
          subjects: subjects,
          examTargets: examTargets,
          canOptOut: canOptOut,
          pickerMode: pickerMode,
          obligatorySubjects: obligatorySubjects,
          optionalSubjects: optionalSubjects,
          minSubjects: serieDoc?.minSubjects,
          maxSubjects: serieDoc?.maxSubjects,
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

  /// Helper privé v2 — résout une liste d'IDs subjects vers leurs models.
  ///
  /// Factorisé 3× dans `derive()` : subjects (dérivés), obligatorySubjects,
  /// optionalSubjects. Filtre `isActive == true` côté serveur.
  /// Limite Firestore `whereIn` = 30 IDs (toutes rules v2 ≤ 17 — cf. Form 5
  /// optionalSubjectIds 17 matières au choix O-Level).
  Future<List<Subject>> _fetchSubjectsByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final qs = await _firestore
        .collection(_kSubjects)
        .where(FieldPath.documentId, whereIn: ids)
        .where('isActive', isEqualTo: true)
        .get();
    return qs.docs.map(subjectFromFirestore).toList(growable: false);
  }

  /// Helper privé v2 — résout une liste d'IDs exam_targets vers leurs models.
  ///
  /// Symétrique de `_fetchSubjectsByIds` pour les examens visés. Filtre
  /// `isActive == true` côté serveur.
  Future<List<ExamTarget>> _fetchExamTargetsByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final qs = await _firestore
        .collection(_kExamTargets)
        .where(FieldPath.documentId, whereIn: ids)
        .where('isActive', isEqualTo: true)
        .get();
    return qs.docs.map(examTargetFromFirestore).toList(growable: false);
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
