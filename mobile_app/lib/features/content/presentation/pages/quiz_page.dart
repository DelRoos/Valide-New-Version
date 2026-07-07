import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/errors/content_error_view.dart';
import '../../domain/entities/quiz_question_entity.dart';
import '../../providers.dart';
import '../widgets/quiz_session_view.dart';
import '../widgets/quiz_support.dart';
import 'quiz_extra.dart';

class QuizPage extends ConsumerStatefulWidget {
  const QuizPage({
    super.key,
    required this.subjectId,
    required this.chapterId,
    this.lessonId,
  });

  final String subjectId;
  final String chapterId;
  final String? lessonId;

  @override
  ConsumerState<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends ConsumerState<QuizPage> {
  int _currentIndex = 0;
  int? _selectedIndex;
  int _score = 0;
  final List<int?> _answers = [];

  bool get _isLessonQuiz => widget.lessonId != null;

  void _selectAnswer(int index, List<QuizQuestionEntity> questions) {
    if (_selectedIndex != null) return;
    final correct = questions[_currentIndex].correctIndex == index;
    setState(() {
      _selectedIndex = index;
      while (_answers.length <= _currentIndex) {
        _answers.add(null);
      }
      _answers[_currentIndex] = index;
      if (correct) _score++;
    });
  }

  void _next(BuildContext context, List<QuizQuestionEntity> questions) {
    if (_currentIndex < questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedIndex = null;
      });
    } else {
      final route = _isLessonQuiz
          ? AppRoutes.lessonQuizResult(
              widget.subjectId, widget.chapterId, widget.lessonId!)
          : AppRoutes.chapterQuizResult(widget.subjectId, widget.chapterId);
      context.push(
        route,
        extra: QuizResultExtra(
          score: _score,
          total: questions.length,
          questions: questions,
          answers: List<int?>.from(_answers),
        ),
      );
    }
  }

  void _retryLoad() {
    if (_isLessonQuiz) {
      ref.invalidate(lessonQuizSessionProvider(widget.lessonId!));
    } else {
      ref.invalidate(chapterQuizSessionProvider(widget.chapterId));
    }
    setState(() {
      _currentIndex = 0;
      _selectedIndex = null;
      _score = 0;
      _answers.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final sessionAsync = _isLessonQuiz
        ? ref.watch(lessonQuizSessionProvider(widget.lessonId!))
        : ref.watch(chapterQuizSessionProvider(widget.chapterId));

    final questions =
        sessionAsync.maybeWhen(data: (q) => q, orElse: () => null);
    final total = questions?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quiz',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: AppFontSize.h3,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.ink,
        bottom: total > 0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.s4,
                    0,
                    AppSpacing.s4,
                    AppSpacing.s3,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isFr
                                ? 'Question ${_currentIndex + 1} sur $total'
                                : 'Question ${_currentIndex + 1} of $total',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: AppFontSize.bodySmall,
                              fontWeight: FontWeight.w600,
                              color: AppColors.muted,
                            ),
                          ),
                          Text(
                            '${((_currentIndex + 1) / total * 100).round()}%',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: AppFontSize.bodySmall,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.s2),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: LinearProgressIndicator(
                          value: (_currentIndex + 1) / total,
                          backgroundColor: AppColors.border,
                          color: AppColors.primary,
                          minHeight: AppDimension.progressBarMed.toDouble(),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: sessionAsync.when(
          loading: () => const QuizLoadingSkeleton(),
          error: (error, _) => ContentErrorView(
            error: error,
            onRetry: _retryLoad,
          ),
          data: (questions) {
            if (questions.isEmpty) return QuizEmptyState(isFr: isFr);
            return QuizSessionView(
              questions: questions,
              currentIndex: _currentIndex,
              selectedIndex: _selectedIndex,
              isFr: isFr,
              onSelect: (i) => _selectAnswer(i, questions),
              onNext: () => _next(context, questions),
            );
          },
        ),
      ),
    );
  }
}
