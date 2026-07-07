import 'package:fpdart/fpdart.dart';

import '../entities/chapter_entity.dart';
import '../entities/chapter_fiche_entity.dart';
import '../entities/lesson_content_entity.dart';
import '../entities/lesson_entity.dart';
import '../entities/notion_entity.dart';
import '../entities/quiz_question_entity.dart';
import '../failures/content_failure.dart';

abstract interface class ContentRepository {
  Future<Either<ContentFailure, List<ChapterEntity>>> getChapters(
    String subjectId,
  );

  Future<Either<ContentFailure, List<LessonEntity>>> getLessons(
    String chapterId,
  );

  Future<Either<ContentFailure, LessonEntity>> getLessonById(String lessonId);

  /// Lit le Markdown depuis lessons/{lessonId}/content/main (blob isolé).
  Future<Either<ContentFailure, LessonContentEntity>> getLessonContent(
    String lessonId,
  );

  /// Lit toutes les questions depuis lessons/{lessonId}/quizzes/ et les aplatit.
  Future<Either<ContentFailure, List<QuizQuestionEntity>>> getQuizQuestions(
    String lessonId,
  );

  /// Lit une notion depuis notions/{notionId} (unité atomique d'évaluation).
  Future<Either<ContentFailure, NotionEntity>> getNotion(String notionId);

  /// Lit la fiche de révision depuis chapters/{chapterId}/fiche/main.
  Future<Either<ContentFailure, ChapterFicheEntity>> getFiche(String chapterId);
}
