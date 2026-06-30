import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/tokens.dart';

// ---------------------------------------------------------------------------
// Fake data — section classmates uniquement
// ---------------------------------------------------------------------------

class _Classmate {
  const _Classmate(this.uid, this.initials, this.name, this.activity, this.since, this.color);
  final String uid;
  final String initials;
  final String name;
  final String activity;
  final String since;
  final Color color;
}

const _kClassmates = [
  _Classmate('uid-amina', 'AK', 'Amina K.', 'révise Chimie organique', '30 min', Color(0xFF7C3AED)),
  _Classmate('uid-jean', 'JN', 'Jean-Paul N.', 'a terminé Fonctions — Ch. 3', '1 h', Color(0xFF059669)),
  _Classmate('uid-mariam', 'MT', 'Mariam T.', 'a fait 5 exercices de Physique', '2 h', Color(0xFFD97706)),
];

// ---------------------------------------------------------------------------
// Section activité classmates
// ---------------------------------------------------------------------------

class ClassmatesSection extends StatelessWidget {
  const ClassmatesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activité récente',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: AppFontSize.h3,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
        SizedBox(height: AppSpacing.s3.h),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppElevation.soft,
          ),
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _kClassmates.length,
            separatorBuilder: (_, _) => const Divider(
              height: 1, indent: 68, color: AppColors.border,
            ),
            itemBuilder: (_, i) => _ClassmateRow(_kClassmates[i]),
          ),
        ),
      ],
    );
  }
}

// Utilisé uniquement par ClassmatesSection dans ce fichier — reste privé.
class _ClassmateRow extends StatelessWidget {
  const _ClassmateRow(this.classmate);
  final _Classmate classmate;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => GoRouter.of(context).push(AppRoutes.user(classmate.uid)),
      child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s4.w,
        vertical: AppSpacing.s3.h,
      ),
      child: Row(
        children: [
          Container(
            width: AppSpacing.s9.w,
            height: AppSpacing.s9.h,
            decoration: BoxDecoration(
              color: classmate.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              classmate.initials,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: AppFontSize.caption,
                fontWeight: FontWeight.w700,
                color: classmate.color,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.s3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  classmate.name,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: AppFontSize.bodySmall,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
                Text(
                  classmate.activity,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: AppFontSize.caption,
                    color: AppColors.muted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.s2.w),
          Text(
            classmate.since,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: AppFontSize.tiny,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    ),   // closes Padding
    );   // closes InkWell
  }
}
