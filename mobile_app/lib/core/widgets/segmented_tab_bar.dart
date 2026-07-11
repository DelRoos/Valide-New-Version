import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/tokens.dart';

class SegmentedTabBar extends StatelessWidget {
  const SegmentedTabBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onTap,
    this.currentIndex,
    this.trackColor,
    this.activeBackgroundColor,
    this.activeTextColor,
    this.inactiveTextColor,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  /// Index de l'onglet marqué "en cours" (dot vert). Optionnel.
  final int? currentIndex;

  /// Couleur du container pill (par défaut `AppColors.bg` — variant clair).
  final Color? trackColor;

  /// Couleur de la pastille active (par défaut `AppColors.card`).
  final Color? activeBackgroundColor;

  /// Couleur du label actif (par défaut `AppColors.ink`).
  final Color? activeTextColor;

  /// Couleur du label inactif (par défaut `AppColors.muted`).
  final Color? inactiveTextColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.s9,
      padding: const EdgeInsets.all(AppSpacing.s1),
      decoration: BoxDecoration(
        color: trackColor ?? AppColors.bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isActive = i == selectedIndex;
          final isCurrent = currentIndex != null && i == currentIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isActive
                      ? (activeBackgroundColor ?? AppColors.card)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  boxShadow: isActive ? AppElevation.soft : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isCurrent) ...[
                      Container(
                        width: 6.w,
                        height: 6.w,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4.w),
                    ],
                    Flexible(
                      child: Text(
                        labels[i],
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: AppFontSize.meta,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w500,
                          color: isActive
                              ? (activeTextColor ?? AppColors.ink)
                              : (inactiveTextColor ?? AppColors.muted),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
