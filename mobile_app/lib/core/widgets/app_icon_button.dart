import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/tokens.dart';
import 'pressable.dart';

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.semanticLabel,
    this.tone = AppIconButtonTone.neutral,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final AppIconButtonTone tone;

  Color get _color {
    switch (tone) {
      case AppIconButtonTone.neutral:
        return AppColors.inkSoft;
      case AppIconButtonTone.primary:
        return AppColors.primary;
      case AppIconButtonTone.danger:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onPressed,
      enabled: onPressed != null,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      hapticPreset: HapticPreset.selection,
      minSize: const Size(48, 48),
      child: SizedBox(
        width: 48.w,
        height: 48.h,
        child: Center(
          child: Icon(
            icon,
            size: 20.sp,
            color: _color,
            semanticLabel: semanticLabel,
          ),
        ),
      ),
    );
  }
}

enum AppIconButtonTone { neutral, primary, danger }
