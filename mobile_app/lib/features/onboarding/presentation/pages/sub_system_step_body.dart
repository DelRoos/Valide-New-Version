// Story E1bis-2bis — Step body 0 du shell onboarding refonte.
//
// Selection sous-systeme : SelectionCard FR/EN, auto-avance step 0 -> 1
// au tap (setSubSystem() declenche la transition dans le notifier).
//
// Resume flow (nouveau telephone) : le bouton "J'ai un compte" est sur
// step 1 (hero intro footer), pas ici.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/cards/selection_card.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/sub_system.dart';
import '../state/onboarding_providers.dart';

class SubSystemStepBody extends ConsumerWidget {
  const SubSystemStepBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.s4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: AppSpacing.s10.h),
          Icon(LucideIcons.map, size: 48.sp, color: AppColors.primary),
          SizedBox(height: AppSpacing.s5.h),
          Text(
            l10n.onboardingSubSystemTitle,
            style: AppTypography.h1.copyWith(fontSize: 28.sp),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.s8.h),
          SelectionCard(
            title: l10n.onboardingSubSystemFrancophone,
            description: l10n.onboardingSubSystemFrancophoneDesc,
            selected: state.subSystem == SubSystem.francophone,
            onTap: () => notifier.setSubSystem(SubSystem.francophone),
            variant: SelectionCardVariant.hero,
            showRadio: false,
          ),
          SizedBox(height: AppSpacing.s3.h),
          SelectionCard(
            title: l10n.onboardingSubSystemAnglophone,
            description: l10n.onboardingSubSystemAnglophoneDesc,
            selected: state.subSystem == SubSystem.anglophone,
            onTap: () => notifier.setSubSystem(SubSystem.anglophone),
            variant: SelectionCardVariant.hero,
            showRadio: false,
          ),
          SizedBox(height: AppSpacing.s5.h),
        ],
      ),
    );
  }
}
