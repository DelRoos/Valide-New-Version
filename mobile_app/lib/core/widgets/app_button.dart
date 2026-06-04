import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/tokens.dart';
import 'pressable.dart';

enum _ButtonVariant { primary, secondary }

class AppButton extends StatelessWidget {
  const AppButton._({
    required this.label,
    required this.onPressed,
    required _ButtonVariant variant,
    this.loading = false,
    this.icon,
    super.key,
  }) : _variant = variant;

  factory AppButton.primary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    bool loading = false,
    IconData? icon,
  }) =>
      AppButton._(
        key: key,
        label: label,
        onPressed: onPressed,
        variant: _ButtonVariant.primary,
        loading: loading,
        icon: icon,
      );

  factory AppButton.secondary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    bool loading = false,
    IconData? icon,
  }) =>
      AppButton._(
        key: key,
        label: label,
        onPressed: onPressed,
        variant: _ButtonVariant.secondary,
        loading: loading,
        icon: icon,
      );

  final String label;
  final VoidCallback? onPressed;
  final _ButtonVariant _variant;
  final bool loading;
  final IconData? icon;

  bool get _isPrimary => _variant == _ButtonVariant.primary;
  bool get _enabled => onPressed != null && !loading;

  @override
  Widget build(BuildContext context) {
    final bg = _isPrimary ? AppColors.primary : AppColors.card;
    final fg = _isPrimary ? AppColors.card : AppColors.primary;
    final border = _isPrimary ? null : Border.all(color: AppColors.primarySoftBorder);

    return Pressable(
      onTap: _enabled ? onPressed : null,
      enabled: _enabled,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      hapticPreset: _isPrimary ? HapticPreset.light : HapticPreset.selection,
      minSize: Size.fromHeight(52.h),
      child: Container(
        height: 52.h,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.s5.w),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: border,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading) ...[
                SizedBox(
                  width: 18.sp,
                  height: 18.sp,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(fg),
                  ),
                ),
                SizedBox(width: AppSpacing.s2.w),
              ] else if (icon != null) ...[
                Icon(icon, size: 20.sp, color: fg),
                SizedBox(width: AppSpacing.s2.w),
              ],
              Flexible(
                child: Text(
                  loading ? 'Envoi…' : label,
                  style: AppTypography.bodyStrong.copyWith(
                    color: fg,
                    fontSize: AppTypography.bodyStrong.fontSize!.sp,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
