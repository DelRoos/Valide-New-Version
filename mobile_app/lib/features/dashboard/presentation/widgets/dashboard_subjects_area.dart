// Zone matieres du dashboard — Story 1.9 (refactor E1bis-9).
//
// Story E1bis-9 — Le flush Firestore du profil (champs trackId/levelId/
// streamId/pickedSubjects) sera livre par E1bis-4 a E1bis-7. En attendant,
// aucun user n'a un profil exploitable cote dashboard : on affiche un empty
// state systematique avec un CTA vers `/onboarding/v2`.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// 3 colonnes en phone (<600 dp), 4 en small tablet (600-840), 5 en tablet.
int dashboardCrossAxisCountFor(double maxWidth) {
  if (maxWidth >= 840) return 5;
  if (maxWidth >= 600) return 4;
  return 3;
}

class DashboardSubjectsArea extends StatelessWidget {
  const DashboardSubjectsArea({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
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
              l10n.dashboardEmptyStateText,
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.s5.h),
            AppButton.primary(
              label: l10n.dashboardEmptyStateCta,
              onPressed: () => GoRouter.of(context).go('/onboarding/v2'),
            ),
          ],
        ),
      ),
    );
  }
}
