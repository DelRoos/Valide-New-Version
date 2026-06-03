import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/di/providers.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/tokens.dart';

class HelloPage extends ConsumerWidget {
  const HelloPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greetingTarget = ref.watch(helloProvider);
    final responsive = Responsive.of(context);

    final titleStyle = AppTypography.h1.copyWith(
      fontSize: responsive.select<double>(
        phone: AppTypography.h1.fontSize!.sp,
        tablet: AppTypography.display.fontSize!.sp,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.s6.w),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 600.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello $greetingTarget',
                  style: titleStyle,
                ),
                SizedBox(height: AppSpacing.s2.h),
                Text(
                  '${responsive.formFactor.name} · ${responsive.width.toStringAsFixed(0)} dp',
                  style: AppTypography.meta.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
