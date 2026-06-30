import 'package:fpdart/fpdart.dart';

import '../entities/chapter_entity.dart';
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
}
