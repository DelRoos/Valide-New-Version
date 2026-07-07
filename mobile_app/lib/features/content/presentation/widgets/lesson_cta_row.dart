import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';

class LessonCtaRow extends StatelessWidget {
  const LessonCtaRow({
    super.key,
    required this.subjectId,
    required this.chapterId,
    required this.lessonId,
  });

  final String subjectId;
  final String chapterId;
  final String lessonId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => context.push(
          AppRoutes.lessonQuiz(subjectId, chapterId, lessonId),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          padding: EdgeInsets.symmetric(vertical: AppSpacing.s3),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center_rounded,
              size: AppIconSize.md,
              color: AppColors.card,
            ),
            SizedBox(width: AppSpacing.s2),
            Text(
              l10n.lessonPractice,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: AppFontSize.body,
                fontWeight: FontWeight.w700,
                color: AppColors.card,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
