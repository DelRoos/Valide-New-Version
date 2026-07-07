import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/quiz_question_entity.dart';

class QuizReviewScreen extends StatelessWidget {
  const QuizReviewScreen({
    super.key,
    required this.questions,
    required this.answers,
    required this.score,
    required this.isFr,
    required this.onBack,
  });

  final List<QuizQuestionEntity> questions;
  final List<int?> answers;
  final int score;
  final bool isFr;
  final VoidCallback onBack;

  String get _lang => isFr ? 'fr' : 'en';
  static const _labels = ['A', 'B', 'C', 'D', 'E', 'F'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── En-tête ──────────────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.s4,
            AppSpacing.s3,
            AppSpacing.s4,
            AppSpacing.s3,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.quizReviewTitle(score, questions.length),
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: AppFontSize.h3Compact,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: AppColors.border),

        // ── Liste ────────────────────────────────────────────────────────
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.all(AppSpacing.s4),
            itemCount: questions.length,
            separatorBuilder: (_, _) => SizedBox(height: AppSpacing.s3),
            itemBuilder: (_, i) {
              final q = questions[i];
              final userIdx = i < answers.length ? answers[i] : null;
              final isCorrect = userIdx == q.correctIndex;
              return QuizReviewCard(
                number: i + 1,
                questionText: q.textFor(_lang),
                options: q.optionsFor(_lang),
                userIndex: userIdx,
                correctIndex: q.correctIndex,
                isCorrect: isCorrect,
                labels: _labels,
              );
            },
          ),
        ),

        // ── Bouton retour ─────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.s4,
            AppSpacing.s2,
            AppSpacing.s4,
            AppSpacing.s4,
          ),
          child: OutlinedButton(
            onPressed: onBack,
            style: OutlinedButton.styleFrom(
              minimumSize: Size(double.infinity, AppSpacing.s12),
              side: BorderSide(
                color: AppColors.border,
                width: AppBorderWidth.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
            child: Text(
              l10n.quizReviewBack,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: AppFontSize.body,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class QuizReviewCard extends StatelessWidget {
  const QuizReviewCard({
    super.key,
    required this.number,
    required this.questionText,
    required this.options,
    required this.userIndex,
    required this.correctIndex,
    required this.isCorrect,
    required this.labels,
  });

  final int number;
  final String questionText;
  final List<String> options;
  final int? userIndex;
  final int correctIndex;
  final bool isCorrect;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final accent = isCorrect ? AppColors.success : AppColors.danger;
    final accentSoft = isCorrect ? AppColors.successSoft : AppColors.dangerSoft;
    final accentInk = isCorrect ? AppColors.successInk : AppColors.dangerInk;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: AppBorderWidth.normal),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── En-tête question ─────────────────────────────────────────
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.s3,
              vertical: AppSpacing.s2,
            ),
            decoration: BoxDecoration(
              color: accentSoft,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg - 1),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: AppSpacing.s6,
                  height: AppSpacing.s6,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      isCorrect ? Icons.check_rounded : Icons.close_rounded,
                      size: AppIconSize.xs,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.s2),
                Expanded(
                  child: Text(
                    'Q$number · $questionText',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: AppFontSize.bodySmall,
                      fontWeight: FontWeight.w600,
                      color: accentInk,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // ── Options ──────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.all(AppSpacing.s3),
            child: Column(
              children: List.generate(options.length, (i) {
                final isUser = i == userIndex;
                final isRight = i == correctIndex;
                final isWrongUser = isUser && !isRight;

                Color badgeBg = AppColors.border;
                Color badgeFg = AppColors.muted;
                Color textColor = AppColors.muted;
                FontWeight textWeight = FontWeight.normal;
                IconData? badgeIcon;

                if (isRight) {
                  badgeBg = AppColors.success;
                  badgeFg = Colors.white;
                  textColor = AppColors.successInk;
                  textWeight = FontWeight.w600;
                  badgeIcon = Icons.check_rounded;
                } else if (isWrongUser) {
                  badgeBg = AppColors.danger;
                  badgeFg = Colors.white;
                  textColor = AppColors.dangerInk;
                  textWeight = FontWeight.w600;
                  badgeIcon = Icons.close_rounded;
                }

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: i < options.length - 1 ? AppSpacing.s2 : 0,
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: AppMotion.standard,
                        width: AppSpacing.s6,
                        height: AppSpacing.s6,
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Center(
                          child: badgeIcon != null
                              ? Icon(badgeIcon, size: AppIconSize.xs, color: badgeFg)
                              : Text(
                                  i < labels.length ? labels[i] : '${i + 1}',
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: AppFontSize.caption,
                                    fontWeight: FontWeight.w700,
                                    color: badgeFg,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(width: AppSpacing.s2),
                      Expanded(
                        child: Text(
                          options[i],
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: AppFontSize.bodySmall,
                            fontWeight: textWeight,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
