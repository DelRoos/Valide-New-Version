// Story 1.9 — Page placeholder pour les onglets Matieres/Activites/Profil
// du bottom tab bar V1. Affiche un message "Bientot disponible" + l'onglet
// actif dans le bottom nav (permet retour vers /dashboard).

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/tokens.dart';
import '../../../l10n/generated/app_localizations.dart';

class PlaceholderTabPage extends StatelessWidget {
  const PlaceholderTabPage({
    super.key,
    required this.title,
    required this.tabIndex,
  });

  final String title;
  final int tabIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text(title, style: AppTypography.h3),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.s6.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.construction,
                  size: 56.sp,
                  color: AppColors.muted,
                ),
                SizedBox(height: AppSpacing.s4.h),
                Text(
                  l10n.dashboardComingSoon,
                  style: AppTypography.h3.copyWith(color: AppColors.inkSoft),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
