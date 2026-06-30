import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

class LessonReadingTimePill extends StatelessWidget {
  const LessonReadingTimePill({
    super.key,
    required this.duration,
    required this.isFr,
  });

  final int duration;
  final bool isFr;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: AppSpacing.s1,
      ),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, size: AppIconSize.sm, color: AppColors.muted),
          SizedBox(width: AppSpacing.s1),
          Text(
            isFr ? '$duration min de lecture' : '$duration min read',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: AppFontSize.meta,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
