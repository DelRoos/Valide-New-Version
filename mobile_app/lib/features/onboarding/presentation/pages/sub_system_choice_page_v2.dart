// Story E1bis-2 — Page step 0 du flow onboarding refonte (10 etapes).
//
// 2 SelectionCard(variant: hero) FR / EN. Le tap card pose le subSystem via
// OnboardingNotifier.setSubSystem (E1bis-1) qui persiste en SharedPreferences
// + avance automatiquement le currentStep a 1. Le CTA Continuer est cosmetique
// (confirmation visuelle) — il appelle notifier.next() pour cohabitation avec
// un flow ou le user veut taper deux fois (card + CTA). Disabled tant que
// subSystem null.
//
// Pas de modification du code Epic 1 (SubsystemChoicePage legacy intacte).
// Pas de bascule i18n auto : LocaleNotifier extension reportee E1bis-9.
//
// Responsive 4 form factors via le LayoutBuilder interne de SelectionCard
// (ConstrainedBox maxWidth 600 dp >= 840 dp deja gere par le composant).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/cards/selection_card.dart';
import '../../../../core/widgets/onboarding/onboarding_cta_footer.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/sub_system.dart';
import '../state/onboarding_providers.dart';

class SubSystemChoicePageV2 extends ConsumerWidget {
  const SubSystemChoicePageV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
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
        ),
      ),
      bottomNavigationBar: OnboardingCtaFooter(
        label: l10n.onboardingContinue,
        onPressed: state.subSystem != null ? notifier.next : null,
      ),
    );
  }
}
