// Story 1.7 — Impl Firestore du SchoolRepository.
//
// Recherche autocomplete via `startsWith` Firestore (3 where + orderBy + limit
// 10). Demande d'ajout via ecriture sous-collection
// `schools/_pending_$ts/requests/$autoId`.

import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/logging/app_logger.dart';
import '../domain/school.dart';
import '../domain/school_failure.dart';
import '../domain/school_repository.dart';

/// Source d'uid injectee (meme typedef que UserProfileRepository).
typedef GetUidFn = String? Function();

class SchoolRepositoryFirestoreImpl implements SchoolRepository {
  SchoolRepositoryFirestoreImpl({
    required FirebaseFirestore firestore,
    required GetUidFn getUid,
  })  : _firestore = firestore,
        _getUid = getUid;

  final FirebaseFirestore _firestore;
  final GetUidFn _getUid;

  static const String _kCollection = 'schools';
  static const int _kMaxResults = 10;
  static const int _kMinQueryLength = 2;

  /// Caractere de borne haute Firestore (max code point Unicode usuel).
  /// `name < "$query"` capture tous les noms qui commencent par `query`.
  static const String _kUpperBound = '';

  @override
  Future<Either<SchoolFailure, List<School>>> searchByPrefix(
    String query,
  ) async {
    if (query.length < _kMinQueryLength) {
      return const Right(<School>[]);
    }

    try {
      final snap = await _firestore
          .collection(_kCollection)
          .where('isValidated', isEqualTo: true)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '$query$_kUpperBound')
          .orderBy('name')
          .limit(_kMaxResults)
          .get();

      final schools = snap.docs.map(_schoolFromDoc).toList(growable: false);

      // CLAUDE.md securite 4 : on log les 3 premiers chars seulement (limite
      // la fuite de l'intention de recherche). Pas l'uid.
      final q3 = query.substring(0, math.min(3, query.length));
      AppLogger.i('School search: q3="$q3" count=${schools.length}');

      return Right(schools);
    } on FirebaseException catch (e, st) {
      AppLogger.w(
        'searchByPrefix() FirebaseException: ${e.code} ${e.message}',
        error: e,
      );
      AppLogger.w('searchByPrefix() stack: $st');
      return Left(
        SchoolFailure.firestoreError(e.message ?? 'Firebase: ${e.code}'),
      );
    } catch (e, st) {
      AppLogger.w('searchByPrefix() unexpected error: $e', error: e);
      AppLogger.w('searchByPrefix() stack: $st');
      return Left(SchoolFailure.firestoreError(e.toString()));
    }
  }

  @override
  Future<Either<SchoolFailure, void>> requestSchool({
    required String name,
    required String city,
    String? region,
  }) async {
    final uid = _getUid();
    if (uid == null) {
      AppLogger.w('requestSchool() aborted: no current user uid');
      return const Left(
        SchoolFailure.firestoreError('User not authenticated'),
      );
    }

    final tempId = '_pending_${DateTime.now().millisecondsSinceEpoch}';
    try {
      await _firestore
          .collection(_kCollection)
          .doc(tempId)
          .collection('requests')
          .add({
        'requestedBy': uid,
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'name': name,
        'city': city,
        'region': region,
      });
      // tempId est public (pas de PII), OK a logger. Le nom de l'ecole NON.
      AppLogger.i('School request submitted: tempId=$tempId');
      return const Right(null);
    } on FirebaseException catch (e, st) {
      AppLogger.w(
        'requestSchool() FirebaseException: ${e.code} ${e.message}',
        error: e,
      );
      AppLogger.w('requestSchool() stack: $st');
      return Left(
        SchoolFailure.firestoreError(e.message ?? 'Firebase: ${e.code}'),
      );
    } catch (e, st) {
      AppLogger.w('requestSchool() unexpected error: $e', error: e);
      AppLogger.w('requestSchool() stack: $st');
      return Left(SchoolFailure.firestoreError(e.toString()));
    }
  }

  School _schoolFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return School(
      schoolId: doc.id,
      name: (data['name'] as String?) ?? '',
      city: (data['city'] as String?) ?? '',
      region: (data['region'] as String?) ?? '',
      subSystem: (data['subSystem'] as String?) ?? 'both',
      isValidated: (data['isValidated'] as bool?) ?? false,
    );
  }
}
