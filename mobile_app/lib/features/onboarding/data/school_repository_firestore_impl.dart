// Story 1.7 — Impl Firestore du SchoolRepository (creation initiale).
// Story 1.5.b — Refactor query : prefix range case-sensitive -> arrayContains
// sur keywords[] lower-case sans accents. Permet une UX insensible a la casse,
// aux accents (« lycee » matche « Lycée »), et aux abreviations communes
// (« ghs » matche « Government High School »).
// Story 1.5.c — Refactor demande d'ajout : sous-collection
// schools/_pending_$ts/requests -> collection racine school_requests/<auto>.
// Le champ subSystem est optionnel + le status est force a 'pending' par les
// rules au create (anti-escalade).

import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/logging/perf_logger.dart';
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
  static const String _kRequestsCollection = 'school_requests';
  static const int _kMaxResults = 10;
  static const int _kMinTokenLength = 2;

  /// Story 1.5.b — Map des accents FR/EN courants vers leur equivalent ASCII.
  /// Couvre les caracteres rencontres dans les noms d'ecoles camerounaises
  /// (français + quelques empruntes latines). Pour des caracteres exotiques,
  /// le runtime laisse le caractere tel quel (ne matchera pas keywords[] mais
  /// ne crash pas).
  static const Map<String, String> _kAccentMap = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
    'ÿ': 'y', 'ý': 'y',
    'À': 'a', 'Á': 'a', 'Â': 'a', 'Ä': 'a',
    'È': 'e', 'É': 'e', 'Ê': 'e', 'Ë': 'e',
    'Ì': 'i', 'Í': 'i', 'Î': 'i', 'Ï': 'i',
    'Ò': 'o', 'Ó': 'o', 'Ô': 'o', 'Ö': 'o',
    'Ù': 'u', 'Ú': 'u', 'Û': 'u', 'Ü': 'u',
    'Ç': 'c',
    'Ñ': 'n',
  };

  /// Story 1.5.b — Normalise la query utilisateur pour qu'elle matche
  /// `keywords[]` cote Firestore. Retourne `null` si aucun token valide
  /// (query trop courte ou ponctuation seule).
  ///
  /// Pipeline :
  ///   1. lower-case
  ///   2. remplacement des accents par leur equivalent ASCII (FR/EN)
  ///   3. remplacement de la ponctuation par espace
  ///   4. split sur whitespace
  ///   5. premier token de longueur >= 2 (Firestore arrayContains accepte 1
  ///      seul predicat -> on prend le 1er mot distinctif)
  static String? _normalizeForSearch(String query) {
    if (query.isEmpty) return null;
    final lower = query.toLowerCase();
    final buf = StringBuffer();
    for (final char in lower.split('')) {
      buf.write(_kAccentMap[char] ?? char);
    }
    final ascii = buf.toString();
    final cleaned = ascii.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
    final tokens = cleaned
        .split(RegExp(r'\s+'))
        .where((t) => t.length >= _kMinTokenLength)
        .toList(growable: false);
    if (tokens.isEmpty) return null;
    return tokens.first;
  }

  @override
  Future<Either<SchoolFailure, List<School>>> searchByPrefix(
    String query,
  ) async {
    final token = _normalizeForSearch(query);
    if (token == null) {
      return const Right(<School>[]);
    }

    try {
      final snap = await logPerf(
        'schools.search',
        () => _firestore
            .collection(_kCollection)
            .where('isValidated', isEqualTo: true)
            .where('keywords', arrayContains: token)
            .limit(_kMaxResults)
            .get(),
      );

      final schools = snap.docs.map(_schoolFromDoc).toList()
        // Story 1.5.b — Firestore ne permet pas arrayContains + orderBy sur
        // un autre champ sans index complexe. Tri client cote Dart sur 10
        // items max = cout negligeable.
        ..sort((a, b) => a.name.compareTo(b.name));

      // CLAUDE.md securite 4 : on log les 3 premiers chars seulement (limite
      // la fuite de l'intention de recherche). Pas l'uid.
      final q3 = token.substring(0, math.min(3, token.length));
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
  Future<Either<SchoolFailure, List<School>>> listFirst(int limit) async {
    try {
      final snap = await logPerf(
        'schools.listFirst',
        () => _firestore
            .collection(_kCollection)
            .where('isValidated', isEqualTo: true)
            .limit(limit)
            .get(),
      );
      final schools = snap.docs.map(_schoolFromDoc).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      AppLogger.i('schools.listFirst count=${schools.length}');
      return Right(schools);
    } on FirebaseException catch (e, st) {
      AppLogger.w('listFirst() FirebaseException: ${e.code}', error: e);
      AppLogger.w('listFirst() stack: $st');
      return Left(SchoolFailure.firestoreError(e.message ?? e.code));
    } catch (e, st) {
      AppLogger.w('listFirst() unexpected: $e', error: e);
      AppLogger.w('listFirst() stack: $st');
      return Left(SchoolFailure.firestoreError(e.toString()));
    }
  }

  @override
  Future<Either<SchoolFailure, void>> createSchoolRequest({
    required String name,
    String? city,
    String? region,
    String? subSystem,
  }) async {
    final uid = _getUid();
    if (uid == null) {
      AppLogger.w('createSchoolRequest() aborted: no current user uid');
      return const Left(
        SchoolFailure.firestoreError('User not authenticated'),
      );
    }

    try {
      await logPerf(
        'school_requests.create',
        () => _firestore.collection(_kRequestsCollection).add({
          'requestedBy': uid,
          'requestedAt': FieldValue.serverTimestamp(),
          'status': 'pending',
          'name': name,
          // city/region/subSystem : optionnels, non envoyes si null/vide.
          'city': ?(city?.isNotEmpty == true ? city : null),
          'region': ?region,
          'subSystem': ?subSystem,
        }),
      );
      // CLAUDE.md regle 4 (logs) : ni uid, ni nom complet ecole, ni ville
      // logges. Le compteur suffit pour la trace d'usage.
      AppLogger.i('School request submitted');
      return const Right(null);
    } on FirebaseException catch (e, st) {
      AppLogger.w(
        'createSchoolRequest() FirebaseException: ${e.code} ${e.message}',
        error: e,
      );
      AppLogger.w('createSchoolRequest() stack: $st');
      return Left(
        SchoolFailure.firestoreError(e.message ?? 'Firebase: ${e.code}'),
      );
    } catch (e, st) {
      AppLogger.w('createSchoolRequest() unexpected error: $e', error: e);
      AppLogger.w('createSchoolRequest() stack: $st');
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
      // Story 1.5.b — keywords optionnel pour retro-compat docs Story 1.7
      // (les docs seedes Story 1.5.a sans keywords n'ont juste pas le champ
      // tant que --regen-keywords n'a pas tourne ; defaut [] safe).
      keywords:
          (data['keywords'] as List<dynamic>?)?.cast<String>() ?? <String>[],
    );
  }
}
