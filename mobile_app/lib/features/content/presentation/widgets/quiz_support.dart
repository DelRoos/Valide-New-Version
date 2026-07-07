import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../l10n/generated/app_localizations.dart';

class QuizEmptyState extends StatelessWidget {
  const QuizEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: AppIconSize.xl8,
              color: AppColors.muted,
            ),
            SizedBox(height: AppSpacing.s3),
            Text(
              AppLocalizations.of(context).quizQuestionsComingSoon,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: AppFontSize.h3Compact,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class QuizLoadingSkeleton extends StatelessWidget {
  const QuizLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSkeleton(height: AppSpacing.s3, width: 120.w),
          SizedBox(height: AppSpacing.s2),
          AppSkeleton(
            height: AppSpacing.s2,
            width: double.infinity,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          SizedBox(height: AppSpacing.s4),
          AppSkeleton(height: AppSpacing.s10, width: double.infinity),
          SizedBox(height: AppSpacing.s4),
          for (var i = 0; i < 4; i++) ...[
            AppSkeleton(height: AppSpacing.s12, width: double.infinity),
            SizedBox(height: AppSpacing.s2),
          ],
        ],
      ),
    );
  }
}
