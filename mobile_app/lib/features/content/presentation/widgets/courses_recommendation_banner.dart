import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';

class CoursesRecommendationBanner extends StatelessWidget {
  const CoursesRecommendationBanner({
    super.key,
    required this.l10n,
  });

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.all(AppSpacing.s5.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Chip "Recommandé"
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.s2.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: AppIconSize.xs,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              l10n.dashboardRecommendedTitle,
                              style: AppTypography.eyebrow.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: AppFontSize.eyebrow,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: AppSpacing.s3.h),
                      // Titre
                      Text(
                        l10n.coursesRecommendedBannerTitle,
                        style: AppTypography.bodyStrong.copyWith(
                          fontSize: AppFontSize.body,
                          color: Colors.white,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: AppSpacing.s4.h),
                      // CTA
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.s4.w,
                          vertical: AppSpacing.s2.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.play,
                              size: AppIconSize.sm,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: AppSpacing.s1.w),
                            Text(
                              l10n.coursesStartLesson,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: AppFontSize.caption,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: AppSpacing.s4.w),
                // Icône décorative
                Container(
                  width: 64.w,
                  height: 64.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Icon(
                    LucideIcons.bookOpen,
                    size: AppIconSize.xl5,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
