import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';

class QuizTab extends StatelessWidget {
  const QuizTab({
    super.key,
    required this.subjectId,
    required this.chapterId,
  });

  final String subjectId;
  final String chapterId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: AppIconSize.xl8,
              color: AppColors.primary,
            ),
            SizedBox(height: AppSpacing.s3),
            Text(
              l10n.quizTabTitle,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: AppFontSize.h3Compact,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.s1),
            Text(
              l10n.quizTabSubtitle,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: AppFontSize.bodySmall,
                color: AppColors.muted,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.s5),
            ElevatedButton(
              onPressed: () =>
                  context.push(AppRoutes.chapterQuiz(subjectId, chapterId)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: Size(double.infinity, AppSpacing.s12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                elevation: 0,
              ),
              child: Text(
                l10n.quizTabStart,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: AppFontSize.body,
                  fontWeight: FontWeight.w700,
                  color: AppColors.card,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
