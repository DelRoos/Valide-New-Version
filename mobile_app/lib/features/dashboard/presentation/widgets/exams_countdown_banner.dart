import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';

// ---------------------------------------------------------------------------
// Countdown banner — bandeau d'en-tête page examens
// ---------------------------------------------------------------------------

class ExamsCountdownBanner extends StatelessWidget {
  const ExamsCountdownBanner({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F766E), Color(0xFF0891B2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -24,
              bottom: -24,
              child: Container(
                width: 140.w,
                height: 140.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              right: 24,
              top: -30,
              child: Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.s5.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Chip exam
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.s3.w, vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            l10n.examsCountdownChip,
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: AppFontSize.caption,
                            ),
                          ),
                        ),
                        SizedBox(height: AppSpacing.s3.h),
                        Text(
                          l10n.examsCountdownHeadline,
                          style: AppTypography.h2.copyWith(
                            color: Colors.white,
                            fontSize: AppFontSize.h2,
                          ),
                        ),
                        SizedBox(height: AppSpacing.s1.h),
                        Text(
                          l10n.examsCountdownSubtitle,
                          style: AppTypography.body.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: AppFontSize.bodySmall,
                          ),
                        ),
                        SizedBox(height: AppSpacing.s4.h),
                        Text(
                          l10n.examsCountdownPrepared(35),
                          style: AppTypography.eyebrow.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w700,
                            fontSize: AppFontSize.eyebrow,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: LinearProgressIndicator(
                            value: 0.35,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: AppSpacing.s5.w),
                  // Countdown chiffre
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '4',
                        style: AppTypography.display.copyWith(
                          color: Colors.white,
                          fontSize: 48.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        l10n.examsCountdownMonths,
                        style: AppTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: AppFontSize.caption,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
