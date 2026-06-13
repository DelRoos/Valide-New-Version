// Card invitation creation de compte (visible si user anonyme) — Story 1.9.
//
// Audit PR5 2026-06-13 : le tap CTA ouvre maintenant un bottomsheet
// d'upgrade (linkWithCredential Google/Apple) au lieu de nav vers
// /onboarding/v2. Justification : l'upgrade preserve l'uid + le profil
// Firestore existant; renvoyer dans onboarding aurait force a tout
// recommencer (track/level/stream/subjects).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/generated/app_localizations.dart';
import 'account_upgrade_sheet.dart';

class DashboardGuestInviteCard extends ConsumerWidget {
  const DashboardGuestInviteCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    onPressed: () => _onUpgradeTap(context, l10n),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onUpgradeTap(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await showAccountUpgradeSheet(context);
    if (success == true) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.accountUpgradeSuccess),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
