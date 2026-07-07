import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../providers.dart';
import '../widgets/quiz_result_screen.dart';
import 'quiz_extra.dart';

class QuizResultPage extends ConsumerWidget {
  const QuizResultPage({
    super.key,
    required this.subjectId,
    required this.chapterId,
    this.lessonId,
    required this.extra,
  });

  final String subjectId;
  final String chapterId;
  final String? lessonId;
  final QuizResultExtra extra;

  bool get _isLessonQuiz => lessonId != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pct =
        extra.total > 0 ? (extra.score / extra.total * 100).round() : 0;

    void replay() {
      if (_isLessonQuiz) {
        ref.invalidate(lessonQuizSessionProvider(lessonId!));
      } else {
        ref.invalidate(chapterQuizSessionProvider(chapterId));
      }
      context.go(
        _isLessonQuiz
            ? AppRoutes.lessonQuiz(subjectId, chapterId, lessonId!)
            : AppRoutes.chapterQuiz(subjectId, chapterId),
      );
    }

    void goBack() {
      context.go(
        _isLessonQuiz
            ? AppRoutes.lesson(subjectId, chapterId, lessonId!)
            : AppRoutes.chapter(subjectId, chapterId),
      );
    }

    void goReview() {
      context.push(
        _isLessonQuiz
            ? AppRoutes.lessonQuizReview(subjectId, chapterId, lessonId!)
            : AppRoutes.chapterQuizReview(subjectId, chapterId),
        extra: extra,
      );
    }

    return Scaffold(
      backgroundColor: QuizResultScreen.bgFor(pct),
      body: SafeArea(
        child: QuizResultScreen(
          score: extra.score,
          total: extra.total,
          onReplay: replay,
          onBack: goBack,
          onReview: goReview,
        ),
      ),
    );
  }
}
