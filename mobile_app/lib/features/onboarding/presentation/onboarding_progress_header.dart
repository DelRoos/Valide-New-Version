// Story 1.3 — Header reutilisable pour les 3 pages du flow profil.
// Affiche la progression (AppProgressBar) + le label "Etape X sur Y" i18n.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_progress_bar.dart';
import '../../../l10n/generated/app_localizations.dart';

class OnboardingProgressHeader extends StatelessWidget {
  const OnboardingProgressHeader({
    super.key,
    required this.step,
    required this.total,
  })  : assert(step >= 1 && step <= total),
        assert(total >= 1);

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppProgressBar(value: step / total),
        SizedBox(height: AppSpacing.s2.h),
        Text(
          l10n.onboardingStepLabel(step, total),
          style: AppTypography.meta.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}
