import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tokens.dart';

// ---------------------------------------------------------------------------
// Fake data — header uniquement
// ---------------------------------------------------------------------------

const _kName = 'Fatou';
const _kClass = 'Terminale D';
const _kSchool = 'Lycée Général Leclerc';
const _kIsExamClass = true;
const _kDaysToExam = 47;
const _kExamLabel = 'BAC';

String _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Bonjour';
  if (h < 18) return 'Bon après-midi';
  return 'Bonsoir';
}

// ---------------------------------------------------------------------------
// Header — compact, sans gradient, tout sur 2 lignes
// ---------------------------------------------------------------------------

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final daysColor = _kDaysToExam < 14
        ? AppColors.danger
        : _kDaysToExam < 30
            ? AppColors.warning
            : AppColors.primary;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.s5.w,
        top + AppSpacing.s4.h,
        AppSpacing.s4.w,
        AppSpacing.s4.h,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()}, $_kName 👋',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: AppFontSize.h2,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                SizedBox(height: AppSpacing.s1.h),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: AppFontSize.bodySmall,
                      color: AppColors.muted,
                    ),
                    children: [
                      TextSpan(text: '$_kClass · '),
                      if (_kIsExamClass)
                        TextSpan(
                          text: '$_kExamLabel dans $_kDaysToExam jours',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: daysColor,
                          ),
                        )
                      else
                        TextSpan(text: _kSchool),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.s3.w),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: AppSpacing.s10.w,
              height: AppSpacing.s10.h,
              decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
                boxShadow: AppElevation.soft,
              ),
              child: Icon(
                LucideIcons.bell,
                size: AppIconSize.lg,
                color: AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
