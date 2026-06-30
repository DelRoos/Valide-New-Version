import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_skeleton.dart';

class LessonPageSkeleton extends StatelessWidget {
  const LessonPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeleton(
            width: 200,
            height: 18,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          SizedBox(height: AppSpacing.s4),
          AppSkeleton(
            width: double.infinity,
            height: 14,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          SizedBox(height: AppSpacing.s2),
          AppSkeleton(
            width: double.infinity,
            height: 14,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          SizedBox(height: AppSpacing.s2),
          AppSkeleton(
            width: 260,
            height: 14,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          SizedBox(height: AppSpacing.s5),
          AppSkeleton(
            width: double.infinity,
            height: 14,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          SizedBox(height: AppSpacing.s2),
          AppSkeleton(
            width: double.infinity,
            height: 14,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          SizedBox(height: AppSpacing.s2),
          AppSkeleton(
            width: 180,
            height: 14,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ],
      ),
    );
  }
}
