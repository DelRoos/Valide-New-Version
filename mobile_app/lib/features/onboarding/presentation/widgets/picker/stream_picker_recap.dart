import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/tokens.dart';

/// Banner recap affichant le parcours du user (Section / Filiere / Niveau /
/// Serie) au-dessus des chips matieres. Layout 2 colonnes par ligne : label
/// gris a gauche, valeur bold a droite.
class RecapBanner extends StatelessWidget {
  const RecapBanner({super.key, required this.entries});

  final List<({String label, String value, IconData icon})> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s4.w,
        vertical: AppSpacing.s4.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.16),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < entries.length; i += 2) ...[
            if (i > 0) SizedBox(height: AppSpacing.s4.h),
            if (i + 1 < entries.length)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: RecapCell(entry: entries[i])),
                  SizedBox(width: AppSpacing.s4.w),
                  Expanded(child: RecapCell(entry: entries[i + 1])),
                ],
              )
            else
              RecapCell(entry: entries[i]),
          ],
        ],
      ),
    );
  }
}

class RecapCell extends StatelessWidget {
  const RecapCell({super.key, required this.entry});

  final ({String label, String value, IconData icon}) entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(entry.icon, size: 11.sp, color: AppColors.inkSoft),
            SizedBox(width: AppSpacing.s1.w),
            Text(
              entry.label.toUpperCase(),
              style: AppTypography.body.copyWith(
                fontSize: 10.sp,
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          entry.value,
          style: AppTypography.bodyStrong.copyWith(
            fontSize: 14.sp,
            color: AppColors.ink,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
