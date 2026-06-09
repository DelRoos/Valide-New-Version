import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/tokens.dart';
import 'pressable.dart';

enum _ButtonVariant { primary, secondary, danger }

class AppButton extends StatelessWidget {
  const AppButton._({
    required this.label,
    required this.onPressed,
    required _ButtonVariant variant,
    this.loading = false,
    this.icon,
    this.iconWidget,
    super.key,
  }) : _variant = variant;

  factory AppButton.primary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    bool loading = false,
    IconData? icon,
    Widget? iconWidget,
  }) =>
      AppButton._(
        key: key,
        label: label,
        onPressed: onPressed,
        variant: _ButtonVariant.primary,
        loading: loading,
        icon: icon,
        iconWidget: iconWidget,
      );

  factory AppButton.secondary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    bool loading = false,
    IconData? icon,
    Widget? iconWidget,
  }) =>
      AppButton._(
        key: key,
        label: label,
        onPressed: onPressed,
        variant: _ButtonVariant.secondary,
        loading: loading,
        icon: icon,
        iconWidget: iconWidget,
      );

  /// Story 1.10 — variant rouge pour actions destructives (suppression compte,
  /// reset, etc.). Haptic medium pour souligner l'intention destructive.
  factory AppButton.danger({
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
        variant: _ButtonVariant.danger,
        loading: loading,
        icon: icon,
      );

  final String label;
  final VoidCallback? onPressed;
  final _ButtonVariant _variant;
  final bool loading;
  final IconData? icon;
  final Widget? iconWidget;

  bool get _enabled => onPressed != null && !loading;

  Color get _bg => switch (_variant) {
        _ButtonVariant.primary => AppColors.primary,
        _ButtonVariant.secondary => AppColors.card,
        _ButtonVariant.danger => AppColors.danger,
      };

  Color get _fg => switch (_variant) {
        _ButtonVariant.primary => AppColors.card,
        _ButtonVariant.secondary => AppColors.primary,
        _ButtonVariant.danger => AppColors.card,
      };

  Border? get _border => switch (_variant) {
        _ButtonVariant.primary => null,
        _ButtonVariant.secondary => Border.all(color: AppColors.primarySoftBorder),
        _ButtonVariant.danger => null,
      };

  HapticPreset get _haptic => switch (_variant) {
        _ButtonVariant.primary => HapticPreset.light,
        _ButtonVariant.secondary => HapticPreset.selection,
        _ButtonVariant.danger => HapticPreset.medium,
      };

  @override
  Widget build(BuildContext context) {
    final bg = _bg;
    final fg = _fg;
    final border = _border;

    return Pressable(
      onTap: _enabled ? onPressed : null,
      enabled: _enabled,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      hapticPreset: _haptic,
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
              ] else if (iconWidget != null) ...[
                SizedBox(width: 20.sp, height: 20.sp, child: iconWidget),
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
