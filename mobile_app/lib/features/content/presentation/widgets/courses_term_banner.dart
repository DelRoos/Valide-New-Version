import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';

// Mock — remplacé par un provider Firestore en Story 2.x.
const int _kMockTermNumber = 1;
const int _kMockChaptersDone = 8;
const int _kMockChaptersTotal = 20;

class CoursesTermBanner extends StatelessWidget {
  const CoursesTermBanner({
    super.key,
    required this.l10n,
    this.onCtaTap,
  });

  final AppLocalizations l10n;
  final VoidCallback? onCtaTap;

  @override
  Widget build(BuildContext context) {
    final progress = _kMockChaptersDone / _kMockChaptersTotal;
    final pct = (progress * 100).round();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: EdgeInsets.all(AppSpacing.s4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    l10n.coursesTermChip(_kMockTermNumber),
                    style: AppTypography.h2.copyWith(
                      color: Colors.white,
                      fontSize: AppFontSize.h3,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.s3.w),
                Text(
                  '$pct%',
                  style: AppTypography.h1.copyWith(
                    color: Colors.white,
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.s3.h),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                l10n.coursesTermChaptersProgress(
                  _kMockChaptersDone,
                  _kMockChaptersTotal,
                ),
                style: AppTypography.eyebrow.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                  fontSize: AppFontSize.eyebrow,
                ),
              ),
            ),
            SizedBox(height: AppSpacing.s1.h + 2),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 6,
              ),
            ),
            SizedBox(height: AppSpacing.s4.h),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: InkWell(
                  onTap: onCtaTap ?? () {},
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: AppSpacing.s3.h,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.play,
                          size: AppIconSize.sm,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: AppSpacing.s2.w),
                        Text(
                          l10n.coursesTermCtaLabel,
                          style: AppTypography.bodyStrong.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: AppFontSize.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
