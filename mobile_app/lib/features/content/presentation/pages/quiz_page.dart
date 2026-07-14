import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/firebase/providers.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/errors/content_error_view.dart';
import '../../../dashboard/presentation/widgets/account_upgrade_sheet.dart' show showAccountUpgradeDialog;
import '../../../../l10n/generated/app_localizations.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isAnonymous =
          ref.read(firebaseAuthProvider).currentUser?.isAnonymous ?? true;
      if (isAnonymous) {
        Navigator.of(context).pop();
        showAccountUpgradeDialog(context);
      }
    });
  }

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

  Future<void> _confirmExit(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.quizQuitDialogTitle,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: AppFontSize.h3,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        content: Text(
          l10n.quizQuitDialogBody,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: AppFontSize.body,
            color: AppColors.muted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l10n.continueLabel,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.quizQuitLabel,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontWeight: FontWeight.w600,
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      Navigator.of(context).pop();
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
    final l10n = AppLocalizations.of(context);
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final sessionAsync = _isLessonQuiz
        ? ref.watch(lessonQuizSessionProvider(widget.lessonId!))
        : ref.watch(chapterQuizSessionProvider(widget.chapterId));

    final questions =
        sessionAsync.maybeWhen(data: (q) => q, orElse: () => null);
    final total = questions?.length ?? 0;

    return PopScope(
      // Libre si aucune réponse donnée, confirmation sinon.
      canPop: _answers.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _confirmExit(context);
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.quizPageTitle,
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
                            l10n.quizProgressLabel(_currentIndex + 1, total),
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
            if (questions.isEmpty) return const QuizEmptyState();
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
      ),
    );
  }
}
