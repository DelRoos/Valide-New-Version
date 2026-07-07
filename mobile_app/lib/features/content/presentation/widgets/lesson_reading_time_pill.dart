import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';

class LessonReadingTimePill extends StatelessWidget {
  const LessonReadingTimePill({
    super.key,
    required this.duration,
  });

  final int duration;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
            l10n.lessonReadingTime(duration),
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
