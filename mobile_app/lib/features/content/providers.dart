// Providers Riverpod feature content.
//
// Providers exposés :
//   1. `contentRepositoryProvider` — impl Firestore du ContentRepository.
//   2. `chaptersProvider(subjectId)` — FutureProvider.family chapitres filtrés par levelId utilisateur.
//   3. `lessonsProvider(chapterId)` — FutureProvider.family liste des leçons.
//   4. `lessonByIdProvider(lessonId)` — FutureProvider.family métadonnées leçon.
//   5. `lessonContentProvider(lessonId)` — FutureProvider.family blob Markdown (sous-doc).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firebase/providers.dart';
import '../../core/logging/app_logger.dart';
import '../onboarding/providers.dart';
import 'data/repositories/content_firestore_repository_impl.dart';
import 'domain/entities/chapter_entity.dart';
import 'domain/entities/lesson_content_entity.dart';
import 'domain/entities/lesson_entity.dart';
import 'domain/repositories/content_repository.dart';

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return ContentFirestoreRepositoryImpl(
    firestore: ref.watch(firestoreProvider),
  );
});

/// Liste des chapitres d'une matière filtrée par le levelId du profil utilisateur.
/// Un élève en 3e ne voit que les chapitres de 3e, même si la matière a du contenu
/// pour d'autres niveaux. Filtrage client-side (volume ≤ 30 docs — _kMaxChapters).
final chaptersProvider =
    FutureProvider.autoDispose.family<List<ChapterEntity>, String>(
  (ref, subjectId) async {
    final profileData = ref.watch(profileDataProvider).maybeWhen(
          data: (d) => d,
          orElse: () => null,
        );
    final userLevelId = profileData?['levelId'] as String?;

    final result =
        await ref.watch(contentRepositoryProvider).getChapters(subjectId);
    return result.fold(
      (failure) {
        AppLogger.e(
          'chaptersProvider: kind=${failure.kind.name} message=${failure.message}',
        );
        throw failure;
      },
      (chapters) {
        if (userLevelId == null || userLevelId.isEmpty) return chapters;
        return chapters.where((c) => c.levelId == userLevelId).toList();
      },
    );
  },
);

/// Liste des leçons d'un chapitre, triée par `order`.
/// Throw `ContentFailure` en cas d'erreur Firestore.
final lessonsProvider =
    FutureProvider.autoDispose.family<List<LessonEntity>, String>(
  (ref, chapterId) async {
    final result =
        await ref.watch(contentRepositoryProvider).getLessons(chapterId);
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

/// Métadonnées d'une leçon (titre, durée, ordre) — sans le blob Markdown.
/// Throw `ContentFailure` (notFound si doc inexistant).
final lessonByIdProvider =
    FutureProvider.autoDispose.family<LessonEntity, String>(
  (ref, lessonId) async {
    final result =
        await ref.watch(contentRepositoryProvider).getLessonById(lessonId);
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

/// Contenu Markdown d'une leçon lu depuis lessons/{id}/content/main.
/// Séparé de `lessonByIdProvider` pour ne pas charger les blobs lors des listes.
final lessonContentProvider =
    FutureProvider.autoDispose.family<LessonContentEntity, String>(
  (ref, lessonId) async {
    final result =
        await ref.watch(contentRepositoryProvider).getLessonContent(lessonId);
    return result.fold(
      (failure) {
        AppLogger.e(
          'lessonContentProvider: kind=${failure.kind.name} message=${failure.message}',
        );
        throw failure;
      },
      (content) => content,
    );
  },
);
