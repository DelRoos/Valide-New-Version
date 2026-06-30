import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tokens.dart';

// ---------------------------------------------------------------------------
// Card exercice rapide
// ---------------------------------------------------------------------------

class QuickExerciseCard extends StatelessWidget {
  const QuickExerciseCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD97706), Color(0xFFEA580C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppElevation.soft,
          ),
          padding: EdgeInsets.all(AppSpacing.s4.w),
          child: Row(
            children: [
              Container(
                width: AppSpacing.s12.w,
                height: AppSpacing.s12.h,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(LucideIcons.zap, size: AppIconSize.xl2, color: Colors.white),
              ),
              SizedBox(width: AppSpacing.s4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exercice rapide',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: AppFontSize.h3,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: AppSpacing.s1.h),
                    Text(
                      '5 questions · ~3 min',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: AppFontSize.caption,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, size: AppIconSize.xl, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
