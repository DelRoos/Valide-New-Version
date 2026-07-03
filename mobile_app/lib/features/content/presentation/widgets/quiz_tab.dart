import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/tokens.dart';

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
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
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
              isFr ? 'Teste tes connaissances' : 'Test your knowledge',
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
              isFr
                  ? 'Un quiz personnalisé sur ce chapitre'
                  : 'A personalized quiz for this chapter',
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
                isFr ? 'Commencer le quiz' : 'Start quiz',
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
