import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/tokens.dart';

/// Spinner standardisé (3 px stroke, primary). À utiliser pour les attentes
/// courtes (< 3 s above-fold). Pour les attentes longues, préférer `AppSkeleton`.
class AppSpinner extends StatelessWidget {
  const AppSpinner({super.key, this.size = 18, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size.sp,
      height: size.sp,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppColors.primary,
        ),
      ),
    );
  }
}
