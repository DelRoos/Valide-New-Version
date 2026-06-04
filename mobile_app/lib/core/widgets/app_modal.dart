import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/tokens.dart';
import 'app_button.dart';

/// Modale plein écran centrée, UX-DR-10 : au moins UN bouton explicite —
/// pas de close X seul. `primary` est obligatoire, `secondary` optionnel.
class AppModal {
  AppModal._();

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    required ({String label, ValueChanged<BuildContext> onTap}) primary,
    ({String label, ValueChanged<BuildContext> onTap})? secondary,
    String? title,
    bool barrierDismissible = false,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: AppColors.ink.withValues(alpha: 0.5),
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 420.w),
          child: Material(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.xl2),
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.s6.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (title != null) ...[
                    Text(title, style: AppTypography.h3),
                    SizedBox(height: AppSpacing.s3.h),
                  ],
                  child,
                  SizedBox(height: AppSpacing.s6.h),
                  if (secondary != null) ...[
                    AppButton.secondary(
                      label: secondary.label,
                      onPressed: () => secondary.onTap(ctx),
                    ),
                    SizedBox(height: AppSpacing.s2.h),
                  ],
                  AppButton.primary(
                    label: primary.label,
                    onPressed: () => primary.onTap(ctx),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
