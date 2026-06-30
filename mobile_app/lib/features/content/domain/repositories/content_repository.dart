import 'package:fpdart/fpdart.dart';

import '../entities/chapter_entity.dart';
import '../entities/lesson_content_entity.dart';
import '../entities/lesson_entity.dart';
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
}
