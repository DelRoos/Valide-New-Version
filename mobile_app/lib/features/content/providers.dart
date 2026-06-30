// Providers Riverpod feature content.
//
// Providers exposés :
//   1. `contentRepositoryProvider` — impl Firestore du ContentRepository.
//   2. `chaptersProvider(subjectId)` — FutureProvider.family liste des chapitres.
//   3. `lessonsProvider(chapterId)` — FutureProvider.family liste des leçons.
//   4. `lessonByIdProvider(lessonId)` — FutureProvider.family leçon unique par ID.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firebase/providers.dart';
import '../../core/logging/app_logger.dart';
import 'data/repositories/content_firestore_repository_impl.dart';
import 'domain/entities/chapter_entity.dart';
import 'domain/entities/lesson_entity.dart';
import 'domain/repositories/content_repository.dart';

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return ContentFirestoreRepositoryImpl(
    firestore: ref.watch(firestoreProvider),
  );
});

/// Liste des chapitres d'une matière, triée par `order`.
/// Throw `ContentFailure` en cas d'erreur Firestore (capturé par `.when(error:)`).
final chaptersProvider =
    FutureProvider.autoDispose.family<List<ChapterEntity>, String>(
  (ref, subjectId) async {
    final result =
        await ref.read(contentRepositoryProvider).getChapters(subjectId);
    return result.fold(
      (failure) {
        AppLogger.e(
          'chaptersProvider: kind=${failure.kind.name} message=${failure.message}',
        );
        throw failure;
      },
      (chapters) => chapters,
    );
  },
);

/// Liste des leçons d'un chapitre, triée par `order`.
/// Throw `ContentFailure` en cas d'erreur Firestore.
final lessonsProvider =
    FutureProvider.autoDispose.family<List<LessonEntity>, String>(
  (ref, chapterId) async {
    final result =
        await ref.read(contentRepositoryProvider).getLessons(chapterId);
    return result.fold(
      (failure) {
        AppLogger.e(
          'lessonsProvider: kind=${failure.kind.name} message=${failure.message}',
        );
        throw failure;
      },
      (lessons) => lessons,
    );
  },
);

/// Leçon unique par ID de document Firestore.
/// Throw `ContentFailure` (notFound si doc inexistant).
final lessonByIdProvider =
    FutureProvider.autoDispose.family<LessonEntity, String>(
  (ref, lessonId) async {
    final result =
        await ref.read(contentRepositoryProvider).getLessonById(lessonId);
    return result.fold(
      (failure) {
        AppLogger.e(
          'lessonByIdProvider: kind=${failure.kind.name} message=${failure.message}',
        );
        throw failure;
      },
      (lesson) => lesson,
    );
  },
);
