import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/tokens.dart';

enum BadgeTone { neutral, primary, success, warning, danger, info }

class AppBadge extends StatelessWidget {
  AppBadge({
    super.key,
    required this.label,
    this.tone = BadgeTone.neutral,
    this.icon,
  }) : assert(
          label.isNotEmpty,
          'UX-DR-5 : couleur jamais seule comme signal — un AppBadge doit toujours afficher un label.',
        );

  final String label;
  final BadgeTone tone;
  final IconData? icon;

  ({Color bg, Color fg, Color border}) get _colors {
    switch (tone) {
      case BadgeTone.neutral:
        return (bg: AppColors.bg, fg: AppColors.inkSoft, border: AppColors.border);
      case BadgeTone.primary:
        return (
          bg: AppColors.primarySoft,
          fg: AppColors.primaryDark,
          border: AppColors.primarySoftBorder,
        );
      case BadgeTone.success:
        return (bg: AppColors.successSoft, fg: AppColors.successInk, border: AppColors.successSoft);
      case BadgeTone.warning:
        return (bg: AppColors.warningSoft, fg: AppColors.warningInk, border: AppColors.warningSoft);
      case BadgeTone.danger:
        return (bg: AppColors.dangerSoft, fg: AppColors.dangerInk, border: AppColors.dangerSoft);
      case BadgeTone.info:
        return (bg: AppColors.skySoft, fg: AppColors.skyInk, border: AppColors.skySoft);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s3.w,
        vertical: AppSpacing.s1.h,
      ),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12.sp, color: c.fg),
            SizedBox(width: AppSpacing.s1.w),
          ],
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: c.fg,
              fontSize: AppTypography.caption.fontSize!.sp,
            ),
          ),
        ],
      ),
    );
  }
}
