// Card resultat de recherche d'ecole (Story 1.7).
//
// Affiche nom + ville/region + badge "validée" si school.isValidated. Tap
// callback delegue au parent (school_picker_page._onPickSchool).
//
// Extrait de school_picker_page.dart en juin 2026 (CLAUDE.md regle 12).

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/school.dart';

class SchoolSearchCard extends StatelessWidget {
  const SchoolSearchCard({
    super.key,
    required this.school,
    required this.onTap,
    required this.validatedLabel,
  });

  final School school;
  final VoidCallback? onTap;
  final String validatedLabel;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AppCard(
        padding: EdgeInsets.all(AppSpacing.s4.w),
        child: Row(
          children: [
            Icon(
              LucideIcons.school,
              color: AppColors.primary,
              size: 28.sp,
            ),
            SizedBox(width: AppSpacing.s3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(school.name, style: AppTypography.bodyStrong),
                  SizedBox(height: AppSpacing.s1.h),
                  Text(
                    '${school.city}, ${school.region}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.s2.w),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.s2.w,
                vertical: AppSpacing.s1.h,
              ),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.badgeCheck,
                    size: 14.sp,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: AppSpacing.s1.w),
                  Text(
                    validatedLabel,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
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
