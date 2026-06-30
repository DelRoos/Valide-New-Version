import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';

class ProfileStatsRow extends StatelessWidget {
  const ProfileStatsRow({
    super.key,
    required this.l10n,
    required this.subjectsCount,
    required this.examsCount,
  });

  final AppLocalizations l10n;
  final int subjectsCount;
  final int examsCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.card,
      padding: EdgeInsets.symmetric(
        vertical: AppSpacing.s4.h,
        horizontal: AppSpacing.s4.w,
      ),
      child: Row(
        children: [
          _StatCell(
            value: '$subjectsCount',
            unit: '',
            label: l10n.profileSubjects,
            icon: LucideIcons.bookOpen,
            iconColor: AppColors.primary,
          ),
          _Divider(),
          _StatCell(
            value: '$examsCount',
            unit: '',
            label: l10n.profileExams,
            icon: LucideIcons.target,
            iconColor: const Color(0xFF10B981),
          ),
          _Divider(),
          _StatCell(
            value: '—',
            unit: '',
            label: l10n.profileStreak,
            icon: LucideIcons.flame,
            iconColor: const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.unit,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  final String value;
  final String unit;
  final String label;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIconSize.lg, color: iconColor),
          SizedBox(height: AppSpacing.s1.h),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: AppTypography.h3.copyWith(
                    color: AppColors.ink,
                    fontSize: AppFontSize.h3,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.muted,
                      fontSize: AppFontSize.caption,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.s1.h / 2),
          Text(
            label,
            style: AppTypography.eyebrow.copyWith(
              color: AppColors.muted,
              fontSize: AppFontSize.eyebrow,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppBorderWidth.hairline,
      height: AppSpacing.s12.h,
      color: AppColors.border,
    );
  }
}
