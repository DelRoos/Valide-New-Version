import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/tokens.dart';
import 'app_button.dart';

/// BottomSheet stylé : handle top, top-rounded `AppRadius.xl2`, safe-area
/// bottom respectée, bouton primaire en bas accessible au pouce.
class AppBottomSheet {
  AppBottomSheet._();

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    ({String label, ValueChanged<BuildContext> onTap})? primary,
    String? title,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.ink.withValues(alpha: 0.4),
      builder: (ctx) => SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl2),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.s5.w,
            AppSpacing.s3.h,
            AppSpacing.s5.w,
            AppSpacing.s5.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: AppSpacing.s9.w,
                  height: AppSpacing.s1.h,
                  decoration: BoxDecoration(
                    color: AppColors.mute2,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.s4.h),
              if (title != null) ...[
                Text(title, style: AppTypography.h3),
                SizedBox(height: AppSpacing.s3.h),
              ],
              child,
              if (primary != null) ...[
                SizedBox(height: AppSpacing.s5.h),
                AppButton.primary(
                  label: primary.label,
                  onPressed: () => primary.onTap(ctx),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
