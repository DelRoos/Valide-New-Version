import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/errors/content_error_view.dart';
import '../../domain/entities/quiz_question_entity.dart';
import '../../providers.dart';
import '../widgets/quiz_result_screen.dart';
import '../widgets/quiz_review_screen.dart';
import '../widgets/quiz_session_view.dart';
import '../widgets/quiz_support.dart';

class QuizPage extends ConsumerStatefulWidget {
  const QuizPage({
    super.key,
    required this.chapterId,
    this.lessonId,
  });

  /// ID du chapitre (toujours présent — nécessaire pour le quiz chapitre).
  final String chapterId;

  /// ID de la leçon. Si null → quiz chapitre ; sinon → quiz leçon.
  final String? lessonId;

  @override
  ConsumerState<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends ConsumerState<QuizPage> {
  int _currentIndex = 0;
  int? _selectedIndex;
  int _score = 0;
  bool _showResult = false;
  bool _showReview = false;
  final List<int?> _answers = [];

  bool get _isLessonQuiz => widget.lessonId != null;

  void _selectAnswer(int index, List<QuizQuestionEntity> questions) {
    if (_selectedIndex != null) return;
    final correct = questions[_currentIndex].correctIndex == index;
    setState(() {
      _selectedIndex = index;
      while (_answers.length <= _currentIndex) { _answers.add(null); }
      _answers[_currentIndex] = index;
      if (correct) _score++;
    });
  }

  void _next(List<QuizQuestionEntity> questions) {
    if (_currentIndex < questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedIndex = null;
      });
    } else {
      setState(() => _showResult = true);
    }
  }

  void _replay() {
    if (_isLessonQuiz) {
      ref.invalidate(lessonQuizSessionProvider(widget.lessonId!));
    } else {
      ref.invalidate(chapterQuizSessionProvider(widget.chapterId));
    }
    setState(() {
      _currentIndex = 0;
      _selectedIndex = null;
      _score = 0;
      _showResult = false;
      _showReview = false;
      _answers.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final sessionAsync = _isLessonQuiz
        ? ref.watch(lessonQuizSessionProvider(widget.lessonId!))
        : ref.watch(chapterQuizSessionProvider(widget.chapterId));

    // Peek at questions pour AppBar progress + theming résultat
    final questions =
        sessionAsync.maybeWhen(data: (q) => q, orElse: () => null);
    final total = questions?.length ?? 0;
    final showProgress =
        !_showResult && !_showReview && total > 0;
    final resultPct =
        _showResult && total > 0 ? (_score / total * 100).round() : -1;
    final scaffoldBg = resultPct >= 0
        ? QuizResultScreen.bgFor(resultPct)
        : AppColors.bg;

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
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.ink,
        bottom: showProgress
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
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: sessionAsync.when(
          loading: () => const QuizLoadingSkeleton(),
          error: (error, _) => ContentErrorView(
            error: error,
            onRetry: _replay,
          ),
          data: (questions) {
            if (questions.isEmpty) {
              return QuizEmptyState(isFr: isFr);
            }
            if (_showReview) {
              return QuizReviewScreen(
                questions: questions,
                answers: List<int?>.from(_answers),
                score: _score,
                isFr: isFr,
                onBack: () => setState(() => _showReview = false),
              );
            }
            if (_showResult) {
              return QuizResultScreen(
                score: _score,
                total: questions.length,
                isFr: isFr,
                onReplay: _replay,
                onBack: () => Navigator.of(context).maybePop(),
                onReview: () => setState(() => _showReview = true),
              );
            }
            return QuizSessionView(
              questions: questions,
              currentIndex: _currentIndex,
              selectedIndex: _selectedIndex,
              isFr: isFr,
              onSelect: (i) => _selectAnswer(i, questions),
              onNext: () => _next(questions),
            );
          },
        ),
      ),
    );
  }
}
