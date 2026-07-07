// Providers Riverpod feature content.
//
// Providers exposés :
//   1. `contentRepositoryProvider` — impl Firestore du ContentRepository.
//   2. `chaptersProvider(subjectId)` — FutureProvider.family chapitres filtrés par levelId utilisateur.
//   3. `lessonsProvider(chapterId)` — FutureProvider.family liste des leçons.
//   4. `lessonByIdProvider(lessonId)` — FutureProvider.family métadonnées leçon.
//   5. `lessonContentProvider(lessonId)` — FutureProvider.family blob Markdown (sous-doc).
//   6. `chapterFicheProvider(chapterId)` — FutureProvider.family fiche de révision (sous-doc).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firebase/providers.dart';
import '../../core/logging/app_logger.dart';
import '../onboarding/providers.dart';
import 'data/repositories/content_firestore_repository_impl.dart';
import 'domain/entities/chapter_entity.dart';
import 'domain/entities/chapter_fiche_entity.dart';
import 'domain/entities/lesson_content_entity.dart';
import 'domain/entities/lesson_entity.dart';
import 'domain/entities/notion_entity.dart';
import 'domain/entities/quiz_question_entity.dart';
import 'domain/failures/content_failure.dart';
import 'domain/repositories/content_repository.dart';
import 'domain/services/quiz_picker.dart';

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
    // ref.read (pas ref.watch) : évite d'invalider chaptersProvider à chaque
    // emit de profileDataProvider (StreamProvider Firestore). Le niveau est lu
    // une seule fois à la création du provider ; autoDispose garantit la fraîcheur
    // à la prochaine navigation.
    final profileData = ref.read(profileDataProvider).maybeWhen(
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

/// Questions piochées pour une session quiz leçon (≤ 15, 2/notion).
/// Throw `ContentFailure` en cas d'erreur Firestore. Retourne [] si aucune question.
final lessonQuizSessionProvider =
    FutureProvider.autoDispose.family<List<QuizQuestionEntity>, String>(
  (ref, lessonId) async {
    final result = await ref
        .watch(contentRepositoryProvider)
        .getQuizQuestions(lessonId);
    return result.fold(
      (failure) {
        AppLogger.e(
          'lessonQuizSessionProvider: kind=${failure.kind.name} message=${failure.message}',
        );
        throw failure;
      },
      QuizPicker.pickLessonSession,
    );
  },
);

/// Questions piochées pour une session quiz chapitre (≤ 20, 2/notion, toutes leçons).
/// Agrège les questions de toutes les leçons via Future.wait (reads parallèles).
/// Throw `ContentFailure` si la lecture des leçons échoue ; erreurs quiz par leçon silencieuses.
final chapterQuizSessionProvider =
    FutureProvider.autoDispose.family<List<QuizQuestionEntity>, String>(
  (ref, chapterId) async {
    final lessons = await ref.watch(lessonsProvider(chapterId).future);
    final repo = ref.read(contentRepositoryProvider);
    final results = await Future.wait(
      lessons.map((l) => repo.getQuizQuestions(l.lessonId)),
    );
    final allQuestions = results
        .expand((r) => r.fold((_) => <QuizQuestionEntity>[], (q) => q))
        .toList();
    AppLogger.d(
      'chapterQuizSessionProvider($chapterId): ${allQuestions.length} questions brutes',
    );
    return QuizPicker.pickChapterSession(allQuestions);
  },
);

/// Notion par son ID (unité atomique d'évaluation, collection racine `notions/`).
/// Chargé à la demande depuis le bouton "Besoin d'aide" du quiz.
/// Retourne null si le document n'existe pas (évite la boucle retry Riverpod 3.x).
/// Throw uniquement sur erreurs réseau / permission.
final notionProvider =
    FutureProvider.autoDispose.family<NotionEntity?, String>(
  (ref, notionId) async {
    final result =
        await ref.watch(contentRepositoryProvider).getNotion(notionId);
    return result.fold(
      (failure) {
        if (failure.kind == ContentFailureKind.notFound) {
          AppLogger.w(
            'notionProvider($notionId): notion introuvable — fallback affiché',
          );
          return null;
        }
        AppLogger.e(
          'notionProvider($notionId): kind=${failure.kind.name} message=${failure.message}',
        );
        throw failure;
      },
      (notion) => notion,
    );
  },
);

/// Fiche de révision d'un chapitre depuis chapters/{chapterId}/fiche/main.
/// Throw `ContentFailure` (incl. notFound) — le widget intercepte notFound
/// pour afficher l'état vide sans erreur rouge.
final chapterFicheProvider =
    FutureProvider.autoDispose.family<ChapterFicheEntity, String>(
  (ref, chapterId) async {
    final result =
        await ref.watch(contentRepositoryProvider).getFiche(chapterId);
    return result.fold(
      (failure) {
        // notFound = état normal (fiche pas encore seeded) → warning, pas d'erreur Crashlytics.
        if (failure.kind == ContentFailureKind.notFound) {
          AppLogger.w(
            'chapterFicheProvider($chapterId): fiche absente (notFound)',
          );
        } else {
          AppLogger.e(
            'chapterFicheProvider($chapterId): kind=${failure.kind.name} message=${failure.message}',
          );
        }
        throw failure;
      },
      (fiche) => fiche,
    );
  },
);
