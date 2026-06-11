import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/tokens.dart';

/// Indicateur de progression compteur pour les pickers checkbox multi-selection
/// (steps 4 `free_with_obligatory` / `series_plus_optional` / `tve_picker` du
/// flow onboarding E1bis).
///
/// Visuel (cf. DESIGN.md § Composants Onboarding > Picker counter badge) :
/// * `isValid == false` -> bg `warning-soft`, label `warning-ink`,
///   badge droit `warning-ink`.
/// * `isValid == true` -> bg `success-soft`, label `success-ink`,
///   badge droit `success` + icone Check 12 px.
///
/// Transition couleur 300 ms `AppMotion.standardOut`.
///
/// Pas d'i18n interne : le caller passe `labelText` deja localise et
/// interpole (ex. "Tu as choisi 2 / 5 matieres").
///
/// Sticky : la responsabilite de wrapper dans un `SliverPersistentHeader`
/// ou `SliverAppBar` revient au parent (selon le contexte de scroll).
class PickerCounterBadge extends StatelessWidget {
  const PickerCounterBadge({
    super.key,
    required this.currentCount,
    required this.min,
    required this.max,
    required this.labelText,
    required this.isValid,
  });

  final int currentCount;
  final int min;
  final int max;

  /// Texte pre-formate par l'appelant (ex. "8 / 11 matieres").
  /// Pas d'interpolation interne au composant (separation de
  /// responsabilites avec l'i18n du caller).
  final String labelText;

  /// `true` -> apparence success ; `false` -> apparence warning.
  /// Calcule par l'appelant (ex. `current >= min && current <= max`).
  final bool isValid;

  @override
  Widget build(BuildContext context) {
    final bg = isValid ? AppColors.successSoft : AppColors.warningSoft;
    final ink = isValid ? AppColors.successInk : AppColors.warningInk;
    final badgeColor = isValid ? AppColors.success : AppColors.warningInk;

    return AnimatedContainer(
      duration: AppMotion.emphasis,
      curve: AppMotion.standardOut,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s4.w,
        vertical: AppSpacing.s3.h,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppElevation.soft,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              labelText,
              style: AppTypography.caption.copyWith(
                color: ink,
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          SizedBox(width: AppSpacing.s2.w),
          _CountBadge(
            currentCount: currentCount,
            max: max,
            isValid: isValid,
            badgeColor: badgeColor,
            ink: ink,
          ),
        ],
      ),
    );
  }
}

/// Pastille droite « 8 / 11 ✓ » avec icone Check si isValid.
class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.currentCount,
    required this.max,
    required this.isValid,
    required this.badgeColor,
    required this.ink,
  });

  final int currentCount;
  final int max;
  final bool isValid;
  final Color badgeColor;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.emphasis,
      curve: AppMotion.standardOut,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s2.w,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$currentCount / $max',
            style: AppTypography.caption.copyWith(
              color: ink,
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (isValid) ...[
            SizedBox(width: AppSpacing.s1.w),
            Icon(
              LucideIcons.check,
              size: 12.sp,
              color: badgeColor,
            ),
          ],
        ],
      ),
    );
  }
}
