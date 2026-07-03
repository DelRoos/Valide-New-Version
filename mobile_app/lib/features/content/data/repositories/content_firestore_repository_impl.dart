import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/chapter_entity.dart';
import '../../domain/entities/chapter_fiche_entity.dart';
import '../../domain/entities/lesson_content_entity.dart';
import '../../domain/entities/lesson_entity.dart';
import '../../domain/entities/notion_entity.dart';
import '../../domain/entities/quiz_question_entity.dart';
import '../../domain/failures/content_failure.dart';
import '../../domain/repositories/content_repository.dart';
import '../models/chapter_model.dart';
import '../models/lesson_model.dart';
import '../models/notion_model.dart';
import '../models/quiz_question_model.dart';

class ContentFirestoreRepositoryImpl implements ContentRepository {
  ContentFirestoreRepositoryImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  static const _kChapters = 'chapters';
  static const _kLessons = 'lessons';
  static const _kNotions = 'notions';
  static const _kContent = 'content';
  static const _kFiche = 'fiche';
  static const _kQuizzes = 'quizzes';
  static const _kMaxChapters = 30;
  static const _kMaxLessons = 50;

  @override
  Future<Either<ContentFailure, List<ChapterEntity>>> getChapters(
    String subjectId,
  ) async {
    try {
      final snap = await _firestore
          .collection(_kChapters)
          .where('subjectId', isEqualTo: subjectId)
          .orderBy('order')
          .limit(_kMaxChapters)
          .get();
      final entities = snap.docs
          .map((d) => ChapterModel.fromFirestore(d).toEntity())
          .toList();
      return Right(entities);
    } on FirebaseException catch (e) {
      final failure = _mapFirebaseException(e, context: 'getChapters($subjectId)');
      AppLogger.e('content.getChapters: kind=${failure.kind.name} message=${failure.message}');
      return Left(failure);
    } catch (e) {
      final failure = ContentFailure.unknown(e.toString());
      AppLogger.e('content.getChapters unexpected error', error: e);
      return Left(failure);
    }
  }

  @override
  Future<Either<ContentFailure, List<LessonEntity>>> getLessons(
    String chapterId,
  ) async {
    try {
      final snap = await _firestore
          .collection(_kLessons)
          .where('chapterId', isEqualTo: chapterId)
          .orderBy('order')
          .limit(_kMaxLessons)
          .get();
      final entities = snap.docs
          .map((d) => LessonModel.fromFirestore(d).toEntity())
          .toList();
      return Right(entities);
    } on FirebaseException catch (e) {
      final failure = _mapFirebaseException(e, context: 'getLessons($chapterId)');
      AppLogger.e('content.getLessons: kind=${failure.kind.name} message=${failure.message}');
      return Left(failure);
    } catch (e) {
      final failure = ContentFailure.unknown(e.toString());
      AppLogger.e('content.getLessons unexpected error', error: e);
      return Left(failure);
    }
  }

  @override
  Future<Either<ContentFailure, LessonEntity>> getLessonById(
    String lessonId,
  ) async {
    try {
      final doc = await _firestore.collection(_kLessons).doc(lessonId).get();
      if (!doc.exists) {
        final failure = ContentFailure.notFound(lessonId);
        AppLogger.w('content.getLessonById not found: $lessonId');
        return Left(failure);
      }
      return Right(LessonModel.fromFirestore(doc).toEntity());
    } on FirebaseException catch (e) {
      final failure = _mapFirebaseException(e, context: 'getLessonById($lessonId)');
      AppLogger.e('content.getLessonById: kind=${failure.kind.name} message=${failure.message}');
      return Left(failure);
    } catch (e) {
      final failure = ContentFailure.unknown(e.toString());
      AppLogger.e('content.getLessonById unexpected error', error: e);
      return Left(failure);
    }
  }

  @override
  Future<Either<ContentFailure, LessonContentEntity>> getLessonContent(
    String lessonId,
  ) async {
    try {
      final doc = await _firestore
          .collection(_kLessons)
          .doc(lessonId)
          .collection(_kContent)
          .doc('main')
          .get();
      if (!doc.exists) {
        final failure = ContentFailure.notFound('$lessonId/content/main');
        AppLogger.w('content.getLessonContent not found: $lessonId/content/main');
        return Left(failure);
      }
      final data = doc.data() ?? {};
      return Right(LessonContentEntity(
        lessonId: lessonId,
        contentFr: (data['fr'] as String?) ?? '',
        contentEn: (data['en'] as String?) ?? '',
      ));
    } on FirebaseException catch (e) {
      final failure = _mapFirebaseException(e, context: 'getLessonContent($lessonId)');
      AppLogger.e('content.getLessonContent: kind=${failure.kind.name} message=${failure.message}');
      return Left(failure);
    } catch (e) {
      final failure = ContentFailure.unknown(e.toString());
      AppLogger.e('content.getLessonContent unexpected error', error: e);
      return Left(failure);
    }
  }

  @override
  Future<Either<ContentFailure, List<QuizQuestionEntity>>> getQuizQuestions(
    String lessonId,
  ) async {
    try {
      final snap = await _firestore
          .collection(_kLessons)
          .doc(lessonId)
          .collection(_kQuizzes)
          .get();
      final questions = snap.docs
          .expand((doc) {
            final raw = doc.data()['questions'] as List? ?? [];
            return raw
                .whereType<Map<String, dynamic>>()
                .map(QuizQuestionModel.fromMap)
                .map((m) => m.toEntity());
          })
          .toList();
      AppLogger.d(
        'content.getQuizQuestions($lessonId): ${questions.length} questions',
      );
      return Right(questions);
    } on FirebaseException catch (e) {
      final failure =
          _mapFirebaseException(e, context: 'getQuizQuestions($lessonId)');
      AppLogger.e(
        'content.getQuizQuestions: kind=${failure.kind.name} message=${failure.message}',
      );
      return Left(failure);
    } catch (e) {
      final failure = ContentFailure.unknown(e.toString());
      AppLogger.e('content.getQuizQuestions unexpected error', error: e);
      return Left(failure);
    }
  }

  @override
  Future<Either<ContentFailure, NotionEntity>> getNotion(
    String notionId,
  ) async {
    try {
      final doc = await _firestore
          .collection(_kNotions)
          .doc(notionId)
          .get();
      if (!doc.exists) {
        final failure = ContentFailure.notFound(notionId);
        AppLogger.w('content.getNotion not found: $notionId');
        return Left(failure);
      }
      return Right(NotionModel.fromFirestore(doc).toEntity());
    } on FirebaseException catch (e) {
      final failure = _mapFirebaseException(e, context: 'getNotion($notionId)');
      AppLogger.e('content.getNotion: kind=${failure.kind.name} message=${failure.message}');
      return Left(failure);
    } catch (e) {
      final failure = ContentFailure.unknown(e.toString());
      AppLogger.e('content.getNotion unexpected error', error: e);
      return Left(failure);
    }
  }

  @override
  Future<Either<ContentFailure, ChapterFicheEntity>> getFiche(
    String chapterId,
  ) async {
    try {
      final doc = await _firestore
          .collection(_kChapters)
          .doc(chapterId)
          .collection(_kFiche)
          .doc('main')
          .get();
      if (!doc.exists) {
        AppLogger.w('content.getFiche not found: $chapterId/fiche/main');
        return Left(ContentFailure.notFound('$chapterId/fiche/main'));
      }
      final data = doc.data() ?? {};
      return Right(ChapterFicheEntity(
        chapterId: chapterId,
        contentFr: (data['fr'] as String?) ?? '',
        contentEn: (data['en'] as String?) ?? '',
      ));
    } on FirebaseException catch (e) {
      final failure = _mapFirebaseException(e, context: 'getFiche($chapterId)');
      AppLogger.e('content.getFiche: kind=${failure.kind.name} message=${failure.message}');
      return Left(failure);
    } catch (e) {
      AppLogger.e('content.getFiche unexpected error', error: e);
      return Left(ContentFailure.unknown(e.toString()));
    }
  }

  ContentFailure _mapFirebaseException(
    FirebaseException e, {
    required String context,
  }) {
    final code = e.code;
    if (code == 'permission-denied' || code == 'unauthenticated') {
      return const ContentFailure.permissionDenied();
    }
    if (code == 'unavailable' ||
        code == 'network-request-failed' ||
        code == 'deadline-exceeded') {
      return ContentFailure.networkError(
        'Réseau indisponible [$context]: ${e.message ?? code}',
      );
    }
    return ContentFailure.unknown('[$context] ${e.code}: ${e.message ?? ''}');
  }
}
