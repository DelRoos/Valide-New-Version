import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/tokens.dart';

/// Bouton social branded (Google, Apple) pour les flows d'authentification.
class SocialButton extends StatelessWidget {
  const SocialButton({
    super.key,
    required this.label,
    required this.iconWidget,
    required this.loading,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.border,
  });

  final String label;
  final Widget iconWidget;
  final bool loading;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          height: 56.h,
          decoration: BoxDecoration(
            border: border,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.s5.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(foregroundColor),
                  ),
                )
              else
                SizedBox(width: 22.sp, height: 22.sp, child: iconWidget),
              SizedBox(width: AppSpacing.s3.w),
              Text(
                label,
                style: AppTypography.bodyStrong.copyWith(
                  fontSize: 16.sp,
                  color: foregroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bannière d'erreur dismissible pour les flows d'authentification.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.s3.w),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(LucideIcons.triangleAlert,
              color: AppColors.danger, size: 20),
          SizedBox(width: AppSpacing.s2.w),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body.copyWith(
                color: AppColors.danger,
                fontSize: 13.sp,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.x, size: 18),
            color: AppColors.danger,
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
