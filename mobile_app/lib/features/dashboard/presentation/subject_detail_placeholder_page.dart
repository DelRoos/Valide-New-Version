// Story 1.9 — Placeholder pour la route /matieres/:subjectId. Le contenu
// reel d'une matiere arrive en Epic 2. Pas de bottom nav (page detail).

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/tokens.dart';
import '../../../l10n/generated/app_localizations.dart';

class SubjectDetailPlaceholderPage extends StatelessWidget {
  const SubjectDetailPlaceholderPage({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text(subjectId, style: AppTypography.h3),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.s6.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.bookOpen,
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
