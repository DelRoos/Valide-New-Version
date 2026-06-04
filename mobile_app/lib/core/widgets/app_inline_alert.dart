import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/tokens.dart';

enum AlertTone { info, warning, error, success }

/// Encadré inline pour messages contextuels (warning de bandwidth,
/// info pédagogique, erreur de validation). Bordure gauche 4 px du ton,
/// bg soft du même ton, texte ink du ton.
class AppInlineAlert extends StatelessWidget {
  const AppInlineAlert({
    super.key,
    required this.message,
    this.tone = AlertTone.info,
    this.title,
    this.actions,
  });

  final String message;
  final String? title;
  final AlertTone tone;
  final List<Widget>? actions;

  ({Color border, Color bg, Color ink, IconData icon}) get _palette {
    switch (tone) {
      case AlertTone.info:
        return (
          border: AppColors.sky,
          bg: AppColors.skySoft,
          ink: AppColors.skyInk,
          icon: LucideIcons.info,
        );
      case AlertTone.warning:
        return (
          border: AppColors.warning,
          bg: AppColors.warningSoft,
          ink: AppColors.warningInk,
          icon: LucideIcons.triangleAlert,
        );
      case AlertTone.error:
        return (
          border: AppColors.danger,
          bg: AppColors.dangerSoft,
          ink: AppColors.dangerInk,
          icon: LucideIcons.circleAlert,
        );
      case AlertTone.success:
        return (
          border: AppColors.success,
          bg: AppColors.successSoft,
          ink: AppColors.successInk,
          icon: LucideIcons.circleCheck,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _palette;
    return Container(
      padding: EdgeInsets.all(AppSpacing.s4.w),
      decoration: BoxDecoration(
        color: p.bg,
        border: Border(
          left: BorderSide(color: p.border, width: 4),
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(p.icon, size: 20.sp, color: p.ink),
          SizedBox(width: AppSpacing.s3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(title!, style: AppTypography.bodyStrong.copyWith(color: p.ink)),
                  SizedBox(height: AppSpacing.s1.h),
                ],
                Text(message, style: AppTypography.body.copyWith(color: p.ink)),
                if (actions != null && actions!.isNotEmpty) ...[
                  SizedBox(height: AppSpacing.s3.h),
                  Wrap(
                    spacing: AppSpacing.s2.w,
                    children: actions!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
