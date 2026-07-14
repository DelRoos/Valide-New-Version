import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tokens.dart';

/// Card « folder » réutilisable pour la tab Examens.
///
/// Deux usages actuels : (a) une entrée par séquence pédagogique (S1..S6),
/// (b) le folder « Sujets d'examen » pour les classes d'examen. Affiche un
/// leading coloré + titre + progression (bar + label) + chip current optionnel.
class ExamsFolderCard extends StatelessWidget {
  const ExamsFolderCard({
    super.key,
    required this.title,
    required this.progressLabel,
    required this.progressValue,
    required this.leading,
    required this.leadingColor,
    required this.onTap,
    this.currentChipLabel,
  });

  final String title;
  final String progressLabel;
  final double progressValue;
  final Widget leading;
  final Color leadingColor;
  final VoidCallback onTap;

  /// Si fourni, affiche un petit chip « en cours » (vert) à droite du titre.
  final String? currentChipLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppElevation.mid,
      ),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.s4.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: AppSpacing.s12,
                  height: AppSpacing.s12,
                  decoration: BoxDecoration(
                    color: leadingColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  alignment: Alignment.center,
                  child: leading,
                ),
                SizedBox(width: AppSpacing.s3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: AppTypography.bodyStrong.copyWith(
                                fontSize: AppFontSize.body,
                                color: AppColors.ink,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (currentChipLabel != null) ...[
                            SizedBox(width: AppSpacing.s2.w),
                            _CurrentChip(label: currentChipLabel!),
                          ],
                        ],
                      ),
                      SizedBox(height: AppSpacing.s2.h),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                              child: LinearProgressIndicator(
                                value: progressValue,
                                backgroundColor:
                                    leadingColor.withValues(alpha: 0.12),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(leadingColor),
                                minHeight: AppDimension.progressBarMed,
                              ),
                            ),
                          ),
                          SizedBox(width: AppSpacing.s2.w),
                          Text(
                            progressLabel,
                            style: AppTypography.eyebrow.copyWith(
                              color: AppColors.muted,
                              fontSize: AppFontSize.eyebrow,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: AppSpacing.s2.w),
                Icon(
                  LucideIcons.chevronRight,
                  size: AppIconSize.md,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrentChip extends StatelessWidget {
  const _CurrentChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s2.w,
        vertical: 3.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.w,
            height: 6.w,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: AppTypography.eyebrow.copyWith(
              color: AppColors.successInk,
              fontWeight: FontWeight.w800,
              fontSize: AppFontSize.tiny,
            ),
          ),
        ],
      ),
    );
  }
}
