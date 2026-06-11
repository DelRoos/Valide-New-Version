// Story E1bis-2bis — Step body 0 du shell onboarding refonte.
//
// Widget body PUR : pas de Scaffold, pas de footer. Le shell parent
// (OnboardingShell) fournit le Scaffold, la SafeArea, et le footer CTA
// dispatched par currentStep. Refactor du SubSystemChoicePageV2 (PR #103)
// qui posait son propre Scaffold + footer (anti-pattern corrige par E1bis-2bis).
//
// 2 SelectionCard(variant: hero) FR / EN. Le tap card pose le subSystem via
// OnboardingNotifier.setSubSystem (E1bis-1) qui persiste en SharedPreferences
// + avance le currentStep a 1 implicitement (logique notifier).
//
// Pas de modification du code Epic 1 (SubsystemChoicePage legacy intacte).
// Pas de bascule i18n auto : LocaleNotifier extension reportee E1bis-9.

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
          Icon(
            LucideIcons.map,
            size: 48.sp,
            color: AppColors.primary,
          ),
          SizedBox(height: AppSpacing.s5.h),
          Text(
            l10n.onboardingSubSystemTitle,
            style: AppTypography.h1.copyWith(fontSize: 28.sp),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.s3.h),
          Text(
            l10n.onboardingSubSystemSubtitle,
            style: AppTypography.body.copyWith(
              fontSize: 15.sp,
              color: AppColors.inkSoft,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.s8.h),
          SelectionCard(
            title: l10n.onboardingSubSystemFrancophone,
            selected: state.subSystem == SubSystem.francophone,
            onTap: () => notifier.setSubSystem(SubSystem.francophone),
            variant: SelectionCardVariant.hero,
          ),
          SizedBox(height: AppSpacing.s3.h),
          SelectionCard(
            title: l10n.onboardingSubSystemAnglophone,
            selected: state.subSystem == SubSystem.anglophone,
            onTap: () => notifier.setSubSystem(SubSystem.anglophone),
            variant: SelectionCardVariant.hero,
          ),
          SizedBox(height: AppSpacing.s5.h),
        ],
      ),
    );
  }
}
