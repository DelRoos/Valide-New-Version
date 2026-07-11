import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../theme/tokens.dart';
import 'performance_level.dart';

class PerformanceChip extends StatelessWidget {
  const PerformanceChip({super.key, required this.level});

  final PerformanceLevel level;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s2.w,
        vertical: 3.h,
      ),
      decoration: BoxDecoration(
        color: level.softBg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.w,
            height: 6.w,
            decoration: BoxDecoration(
              color: level.color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            level.label(l10n),
            style: AppTypography.eyebrow.copyWith(
              color: level.inkColor,
              fontWeight: FontWeight.w800,
              fontSize: AppFontSize.tiny,
            ),
          ),
        ],
      ),
    );
  }
}
