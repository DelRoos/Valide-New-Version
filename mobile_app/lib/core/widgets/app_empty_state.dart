import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/tokens.dart';
import 'app_button.dart';

/// Empty state pattern (EXPERIENCE.md UX-DR-11) : icône + titre + sous-titre
/// + CTA optionnel. Couvre les écrans vides « pas encore d'historique »,
/// « aucune notification », « pas de favori », etc.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.ctaLabel,
    this.onCtaPressed,
  }) : assert(
          (ctaLabel == null) == (onCtaPressed == null),
          'ctaLabel et onCtaPressed doivent être fournis ensemble',
        );

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? ctaLabel;
  final VoidCallback? onCtaPressed;

  bool get _hasCta => ctaLabel != null && onCtaPressed != null;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.s6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 64.sp, color: AppColors.mute2),
            SizedBox(height: AppSpacing.s4.h),
            Text(
              title,
              style: AppTypography.h3,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: AppSpacing.s2.h),
              Text(
                subtitle!,
                style: AppTypography.body.copyWith(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
            ],
            if (_hasCta) ...[
              SizedBox(height: AppSpacing.s5.h),
              AppButton.primary(label: ctaLabel!, onPressed: onCtaPressed),
            ],
          ],
        ),
      ),
    );
  }
}
