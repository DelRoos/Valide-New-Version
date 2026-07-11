import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/tokens.dart';

const double _kBannerH = 130;
const double _kTitleSkeletonW = 140;
const double _kTitleSkeletonH = 22;
const double _kItemSkeletonH = 72;

class CoursesLoadingSkeleton extends StatelessWidget {
  const CoursesLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.s4.w, AppSpacing.s2.h, AppSpacing.s4.w, AppSpacing.s8.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: _kBannerH.h,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
          ).animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1400.ms, color: AppColors.bg),
          SizedBox(height: AppSpacing.s6.h),
          Container(
            width: _kTitleSkeletonW.w, height: _kTitleSkeletonH.h,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ).animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1400.ms, color: AppColors.bg),
          SizedBox(height: AppSpacing.s3.h),
          ...List.generate(4, (i) => Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.s3.h),
            child: Container(
              height: _kItemSkeletonH.h,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppElevation.soft,
              ),
            ).animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 1400.ms, color: AppColors.bg),
          )),
        ],
      ),
    );
  }
}
