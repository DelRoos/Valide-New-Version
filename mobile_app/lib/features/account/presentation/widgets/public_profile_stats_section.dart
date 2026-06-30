// Story A.2 — Section statistiques hardcodées du profil public.
//
// Affiche 2 badges : leçons lues + quiz réussis (valeurs fictives MVP).
// Extraite de PublicProfilePage pour respecter la limite ≤ 300 lignes
// (CLAUDE.md règle 12).

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';

class PublicProfileStatsSection extends StatelessWidget {
  const PublicProfileStatsSection({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s4.w,
        vertical: AppSpacing.s5.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.publicProfileStatsTitle.toUpperCase(),
            style: AppTypography.eyebrow.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
              fontSize: AppFontSize.eyebrow,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: AppSpacing.s3.h),
          Row(
            children: [
              Expanded(
                child: _StatBadge(
                  icon: LucideIcons.bookOpen,
                  iconColor: AppColors.primary,
                  value: '30',
                  label: l10n.publicProfileLessonsRead,
                ),
              ),
              SizedBox(width: AppSpacing.s3.w),
              Expanded(
                child: _StatBadge(
                  icon: LucideIcons.target,
                  iconColor: const Color(0xFF10B981),
                  value: '3',
                  label: l10n.publicProfileQuizPassed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.s4.w),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppElevation.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppIconSize.lg, color: iconColor),
          SizedBox(height: AppSpacing.s2.h),
          Text(
            value,
            style: AppTypography.h2.copyWith(
              color: AppColors.primaryDark,
              fontSize: AppFontSize.h2,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: AppSpacing.s1.h),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.muted,
              fontSize: AppFontSize.caption,
            ),
          ),
        ],
      ),
    );
  }
}
