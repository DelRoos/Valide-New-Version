import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/quiz_question_entity.dart';
import 'quiz_help_sheet.dart';

class QuizSessionView extends StatelessWidget {
  const QuizSessionView({
    super.key,
    required this.questions,
    required this.currentIndex,
    required this.selectedIndex,
    required this.isFr,
    required this.onSelect,
    required this.onNext,
  });

  final List<QuizQuestionEntity> questions;
  final int currentIndex;
  final int? selectedIndex;
  final bool isFr;
  final ValueChanged<int> onSelect;
  final VoidCallback onNext;

  bool get _hasAnswered => selectedIndex != null;
  bool get _isLast => currentIndex == questions.length - 1;
  String get _langCode => isFr ? 'fr' : 'en';

  static const _labels = ['A', 'B', 'C', 'D', 'E', 'F'];

  void _openHelp(BuildContext context, String? notionId) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => QuizHelpSheet(
        notionId: notionId,
        isFr: isFr,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth >= 840.w
            ? 720.w
            : constraints.maxWidth >= 600.w
                ? 600.w
                : constraints.maxWidth;
        final question = questions[currentIndex];
        final options = question.optionsFor(_langCode);
        final explanation = question.explanationFor(_langCode);

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Zone scrollable : question + options + explication ───
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.s4,
                      AppSpacing.s4,
                      AppSpacing.s4,
                      AppSpacing.s3,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Question
                        QuizMathText(
                          question.textFor(_langCode),
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: AppFontSize.h3Compact,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                            height: 1.45,
                          ),
                        ),
                        SizedBox(height: AppSpacing.s2),

                        // Bouton aide
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton.icon(
                            onPressed: () =>
                                _openHelp(context, question.notionId),
                            icon: Icon(
                              Icons.help_outline,
                              size: AppIconSize.md,
                              color: AppColors.primary,
                            ),
                            label: Text(
                              l10n.quizNeedHelp,
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: AppFontSize.bodySmall,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                        SizedBox(height: AppSpacing.s4),

                        // Options
                        ...List.generate(options.length, (i) {
                          final isSelected = selectedIndex == i;
                          final isCorrect = i == question.correctIndex;
                          Color borderColor = AppColors.border;
                          Color bgColor = AppColors.card;
                          Color textColor = AppColors.ink;
                          Color badgeBg = AppColors.border;
                          Color badgeFg = AppColors.muted;
                          bool showIcon = false;
                          bool iconIsCheck = false;

                          if (_hasAnswered) {
                            if (isCorrect) {
                              borderColor = AppColors.success;
                              bgColor = AppColors.successSoft;
                              textColor = AppColors.successInk;
                              badgeBg = AppColors.success;
                              badgeFg = Colors.white;
                              showIcon = true;
                              iconIsCheck = true;
                            } else if (isSelected) {
                              borderColor = AppColors.danger;
                              bgColor = AppColors.dangerSoft;
                              textColor = AppColors.dangerInk;
                              badgeBg = AppColors.danger;
                              badgeFg = Colors.white;
                              showIcon = true;
                              iconIsCheck = false;
                            }
                          }

                          return Padding(
                            padding: EdgeInsets.only(bottom: AppSpacing.s3),
                            child: GestureDetector(
                              onTap: _hasAnswered ? null : () => onSelect(i),
                              child: AnimatedContainer(
                                duration: AppMotion.standard,
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.s3,
                                  vertical: AppSpacing.s3,
                                ),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  border: Border.all(
                                    color: borderColor,
                                    width: AppBorderWidth.normal,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.lg),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    AnimatedContainer(
                                      duration: AppMotion.standard,
                                      width: AppSpacing.s8,
                                      height: AppSpacing.s8,
                                      decoration: BoxDecoration(
                                        color: badgeBg,
                                        borderRadius:
                                            BorderRadius.circular(AppRadius.xs),
                                      ),
                                      child: Center(
                                        child: showIcon
                                            ? Icon(
                                                iconIsCheck
                                                    ? Icons.check_rounded
                                                    : Icons.close_rounded,
                                                size: AppIconSize.md,
                                                color: badgeFg,
                                              )
                                            : Text(
                                                i < _labels.length
                                                    ? _labels[i]
                                                    : '${i + 1}',
                                                style: TextStyle(
                                                  fontFamily:
                                                      AppTypography.fontFamily,
                                                  fontSize:
                                                      AppFontSize.bodySmall,
                                                  fontWeight: FontWeight.w700,
                                                  color: badgeFg,
                                                ),
                                              ),
                                      ),
                                    ),
                                    SizedBox(width: AppSpacing.s3),
                                    Expanded(
                                      child: QuizMathText(
                                        options[i],
                                        style: TextStyle(
                                          fontFamily: AppTypography.fontFamily,
                                          fontSize: AppFontSize.body,
                                          fontWeight: FontWeight.w500,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),

                        // Explication (après réponse)
                        if (_hasAnswered &&
                            explanation != null &&
                            explanation.isNotEmpty) ...[
                          SizedBox(height: AppSpacing.s1),
                          Container(
                            padding: EdgeInsets.all(AppSpacing.s3),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: AppIconSize.md,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: AppSpacing.s2),
                                Expanded(
                                  child: QuizMathText(
                                    explanation,
                                    style: TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      fontSize: AppFontSize.bodySmall,
                                      color: AppColors.primary,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // ── Footer sticky : bouton suivant ──────────────────────
                AnimatedSize(
                  duration: AppMotion.standard,
                  child: _hasAnswered
                      ? Container(
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.s4,
                            AppSpacing.s3,
                            AppSpacing.s4,
                            AppSpacing.s4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.bg,
                            border: Border(
                              top: BorderSide(
                                color: AppColors.border,
                                width: AppBorderWidth.normal,
                              ),
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: onNext,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              minimumSize:
                                  Size(double.infinity, AppSpacing.s12),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.lg),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              _isLast ? l10n.quizSeeResult : l10n.quizNextQuestion,
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: AppFontSize.body,
                                fontWeight: FontWeight.w700,
                                color: AppColors.card,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Rend du texte contenant du LaTeX inline délimité par `$...$`.
/// - Expression entièrement LaTeX : [Math.tex] dans [FittedBox] pour contraindre la largeur.
/// - Texte mixte : [Text.rich] + [WidgetSpan] pour garder le LaTeX dans le flux de texte.
class QuizMathText extends StatelessWidget {
  const QuizMathText(this.text, {super.key, required this.style});

  final String text;
  final TextStyle style;

  static final _mathRegex = RegExp(r'\$([^$]+)\$');

  @override
  Widget build(BuildContext context) {
    final matches = _mathRegex.allMatches(text).toList();
    if (matches.isEmpty) return Text(text, style: style);

    // Expression purement LaTeX (toute la chaîne = $…$)
    if (matches.length == 1 &&
        matches[0].start == 0 &&
        matches[0].end == text.length) {
      return LayoutBuilder(
        builder: (_, c) => FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Math.tex(
            matches[0].group(1)!,
            textStyle: style,
            onErrorFallback: (_) => Text(matches[0].group(1)!, style: style),
          ),
        ),
      );
    }

    // Texte mixte : LayoutBuilder + Text.rich + WidgetSpan pour contraindre Math.tex
    return LayoutBuilder(
      builder: (_, c) {
        final maxW = c.hasBoundedWidth ? c.maxWidth : double.infinity;
        final spans = <InlineSpan>[];
        int lastEnd = 0;
        for (final match in matches) {
          if (match.start > lastEnd) {
            spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
          }
          final mathWidget = Math.tex(
            match.group(1)!,
            textStyle: style,
            onErrorFallback: (_) => Text(match.group(1)!, style: style),
          );
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: maxW.isFinite
                ? ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxW),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: mathWidget,
                    ),
                  )
                : mathWidget,
          ));
          lastEnd = match.end;
        }
        if (lastEnd < text.length) {
          spans.add(TextSpan(text: text.substring(lastEnd)));
        }
        return Text.rich(TextSpan(style: style, children: spans));
      },
    );
  }
}
