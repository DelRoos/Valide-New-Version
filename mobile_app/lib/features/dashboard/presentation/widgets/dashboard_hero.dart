// Hero banner haut du dashboard — Story 1.9.
//
// Banniere primarySoft avec : badge "Visiteur" (si anonyme), salutation
// "Salut {firstName}" (ou guest fallback), sous-titre avec examLabel
// (ou fallback no-exam). Pas de provider Riverpod : recoit toutes ses
// donnees via constructeur (composition propre).
//
// Extrait de dashboard_page.dart en juin 2026 (CLAUDE.md regle 12 max-lines).

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';

class DashboardHero extends StatelessWidget {
  const DashboardHero({
    super.key,
    required this.firstName,
    required this.examLabel,
    required this.isAnonymous,
  });

  final String? firstName;
  final String? examLabel;
  final bool isAnonymous;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final welcome = firstName != null
        ? l10n.dashboardWelcomeWithName(firstName!)
        : l10n.dashboardWelcomeGuest;
    final subtitle = examLabel != null
        ? l10n.dashboardSubtitleWithExam(examLabel!)
        : l10n.dashboardSubtitleNoExam;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primarySoft,
        border: Border(
          bottom: BorderSide(color: AppColors.primarySoftBorder),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.s5.w,
        AppSpacing.s5.h,
        AppSpacing.s5.w,
        AppSpacing.s6.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAnonymous)
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.s3.w,
                  vertical: AppSpacing.s1.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warningSoft,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  l10n.dashboardGuestBadge,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.warningInk,
                  ),
                ),
              ),
            ),
          SizedBox(height: AppSpacing.s2.h),
          Text(
            welcome,
            style: AppTypography.h1.copyWith(
              color: AppColors.primaryDark,
              fontSize: AppTypography.h1.fontSize!.sp,
            ),
          ),
          SizedBox(height: AppSpacing.s2.h),
          Text(
            subtitle,
            style: AppTypography.body.copyWith(color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}
