import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/tokens.dart';

class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.label,
  }) : assert(
          value >= 0.0 && value <= 1.0,
          'value doit être entre 0.0 et 1.0',
        );

  /// Valeur entre 0.0 et 1.0.
  final double value;

  /// Légende optionnelle affichée en-dessous (ex. « 4/10 »).
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xs),
          child: Container(
            height: 8.h,
            color: AppColors.primaryLight,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: value.clamp(0.0, 1.0),
                child: AnimatedContainer(
                  duration: AppMotion.emphasis,
                  curve: AppMotion.emphasized,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (label != null) ...[
          SizedBox(height: AppSpacing.s1.h),
          Text(
            label!,
            style: AppTypography.meta.copyWith(
              color: AppColors.muted,
              fontSize: AppTypography.meta.fontSize!.sp,
            ),
          ),
        ],
      ],
    );
  }
}
