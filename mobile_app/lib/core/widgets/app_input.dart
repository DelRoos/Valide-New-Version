import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/tokens.dart';

class AppInput extends StatelessWidget {
  const AppInput({
    super.key,
    required this.label,
    this.controller,
    this.hintText,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
  });

  final String label;
  final TextEditingController? controller;
  final String? hintText;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;

  bool get _hasError => errorText != null && errorText!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.meta.copyWith(
            color: AppColors.inkSoft,
            fontSize: AppTypography.meta.fontSize!.sp,
          ),
        ),
        SizedBox(height: AppSpacing.s2.h),
        SizedBox(
          height: AppDimension.inputFieldHeight.h,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            obscureText: obscureText,
            keyboardType: keyboardType,
            enabled: enabled,
            autofocus: autofocus,
            focusNode: focusNode,
            style: AppTypography.body.copyWith(
              fontSize: AppTypography.body.fontSize!.sp,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppTypography.body.copyWith(
                color: AppColors.mute2,
                fontSize: AppTypography.body.fontSize!.sp,
              ),
              filled: true,
              fillColor: AppColors.card,
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.s4.w,
                vertical: 0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide(
                  color: _hasError ? AppColors.danger : AppColors.border,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide(
                  color: _hasError ? AppColors.danger : AppColors.primary,
                  width: AppBorderWidth.bold,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: const BorderSide(color: AppColors.danger),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: const BorderSide(color: AppColors.danger, width: 2),
              ),
            ),
          ),
        ),
        if (_hasError) ...[
          SizedBox(height: AppSpacing.s1.h),
          Text(
            errorText!,
            style: AppTypography.meta.copyWith(
              color: AppColors.danger,
              fontSize: AppTypography.meta.fontSize!.sp,
            ),
          ),
        ],
      ],
    );
  }
}
