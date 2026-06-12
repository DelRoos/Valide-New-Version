// Card invitation creation de compte (visible si user anonyme) — Story 1.9.
//
// CTA secondaire "Créer un compte" qui nav vers /onboarding/account.
// Affiche seulement quand l'utilisateur est anonyme (cf. DashboardPage qui
// conditionne le rendu).
//
// Extrait de dashboard_page.dart en juin 2026 (CLAUDE.md regle 12 max-lines).

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/generated/app_localizations.dart';

class DashboardGuestInviteCard extends StatelessWidget {
  const DashboardGuestInviteCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      padding: EdgeInsets.all(AppSpacing.s4.w),
      child: Row(
        children: [
          Icon(
            LucideIcons.bookmark,
            size: 28.sp,
            color: AppColors.primary,
          ),
          SizedBox(width: AppSpacing.s3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.dashboardGuestInviteText,
                  style: AppTypography.body.copyWith(
                    color: AppColors.inkSoft,
                  ),
                ),
                SizedBox(height: AppSpacing.s2.h),
                SizedBox(
                  width: double.infinity,
                  child: AppButton.secondary(
                    label: l10n.dashboardGuestInviteCta,
                    onPressed: () =>
                        GoRouter.of(context).go('/onboarding/v2'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
