import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/tokens.dart';
import 'pressable.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.xl2);
    final container = Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: radius,
        border: Border.all(color: AppColors.border),
        boxShadow: AppElevation.soft,
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.all(AppSpacing.s6.w),
        child: child,
      ),
    );

    if (onTap == null) return container;
    return Pressable(
      onTap: onTap,
      borderRadius: radius,
      hapticPreset: HapticPreset.selection,
      child: container,
    );
  }
}
