// Story E1bis-2 — Page step 1 du flow onboarding refonte (10 etapes).
//
// Hero illustration placeholder : gradient AppColors.primary -> AppColors.sky
// + LucideIcons.bookOpen 96 sp centre. Asset image final reporte en story
// illustration future (OQ-E1bis-1 decidee 2026-06-11).
//
// 3 feature cards en colonne : Cours / Exercices / Chat IA. Cards decoratives
// pas interactives (`_FeatureCard` widget prive — extraction si reuse
// future). Tap CTA -> notifier.next() (transition step 1 -> 2 livree
// E1bis-3).
//
// Responsive : phone < 840 dp colonne unique pleine largeur ; tablet >= 840 dp
// ConstrainedBox maxWidth 600 dp centre.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/onboarding/onboarding_cta_footer.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../state/onboarding_providers.dart';

class HeroIntroPage extends ConsumerWidget {
  const HeroIntroPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 840;
            final content = SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _HeroBanner(),
                  SizedBox(height: AppSpacing.s6.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.s4.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          l10n.heroIntroTitle,
                          style: AppTypography.h1.copyWith(fontSize: 24.sp),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: AppSpacing.s3.h),
                        Text(
                          l10n.heroIntroSubtitle,
                          style: AppTypography.body.copyWith(
                            fontSize: 15.sp,
                            color: AppColors.inkSoft,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: AppSpacing.s5.h),
                        _FeatureCard(
                          icon: LucideIcons.bookOpen,
                          title: l10n.heroIntroFeatureCoursesTitle,
                          description: l10n.heroIntroFeatureCoursesDesc,
                        ),
                        SizedBox(height: AppSpacing.s3.h),
                        _FeatureCard(
                          icon: LucideIcons.penLine,
                          title: l10n.heroIntroFeatureExercisesTitle,
                          description: l10n.heroIntroFeatureExercisesDesc,
                        ),
                        SizedBox(height: AppSpacing.s3.h),
                        _FeatureCard(
                          icon: LucideIcons.messageCircle,
                          title: l10n.heroIntroFeatureChatTitle,
                          description: l10n.heroIntroFeatureChatDesc,
                        ),
                        SizedBox(height: AppSpacing.s5.h),
                      ],
                    ),
                  ),
                ],
              ),
            );

            if (!isTablet) return content;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 600.w),
                child: content,
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: OnboardingCtaFooter(
        label: l10n.heroIntroCta,
        onPressed: notifier.next,
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.sky],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          LucideIcons.bookOpen,
          size: 96.sp,
          color: AppColors.card,
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.s4.w),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 22.sp, color: AppColors.primary),
          ),
          SizedBox(width: AppSpacing.s3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.h3.copyWith(fontSize: 16.sp),
                ),
                SizedBox(height: AppSpacing.s1.h),
                Text(
                  description,
                  style: AppTypography.body.copyWith(
                    fontSize: 13.sp,
                    color: AppColors.inkSoft,
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
