// Story E1bis-2bis — Step body 1 du shell onboarding refonte.
//
// Widget body PUR : pas de Scaffold, pas de footer. Le shell parent
// (OnboardingShell) fournit le Scaffold, la SafeArea, et le footer CTA
// dispatched par currentStep. Refactor du HeroIntroPage (PR #103) qui
// posait son propre Scaffold + footer (anti-pattern corrige par E1bis-2bis).
//
// Hero illustration placeholder : gradient AppColors.primary -> AppColors.sky
// + LucideIcons.bookOpen 96 sp centre. Asset image final reporte en story
// illustration future (OQ-E1bis-1 decidee 2026-06-11).
//
// 3 feature cards en colonne : Cours / Exercices / Chat IA. Cards decoratives.
// Le tap du CTA "Decouvrir" est gere par le shell (footer dispatch sur step 1).
//
// Responsive (audit BUG-04 2026-06-13) :
// - phone < 700 dp width : hero compact (200 dp height) pour garantir que
//   les 3 feature cards tiennent dans le viewport sans scroll silencieux.
// - phone >= 700 dp et < 840 dp : hero moyen (260 dp).
// - tablet >= 840 dp : ConstrainedBox 600 dp centre + hero AspectRatio 4/3.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';

class HeroIntroStepBody extends StatelessWidget {
  const HeroIntroStepBody({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isTablet = width >= 840;
        final isSmallPhone = width < 700;

        final content = SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeroBanner(
                heightOverride: isTablet
                    ? null
                    : (isSmallPhone ? 200.0 : 260.0),
              ),
              SizedBox(height: isSmallPhone ? AppSpacing.s4.h : AppSpacing.s6.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.s4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      l10n.heroIntroTitle,
                      style: AppTypography.h1
                          .copyWith(fontSize: isSmallPhone ? 22.sp : 24.sp),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSpacing.s2.h),
                    Text(
                      l10n.heroIntroSubtitle,
                      style: AppTypography.body.copyWith(
                        fontSize: isSmallPhone ? 14.sp : 15.sp,
                        color: AppColors.inkSoft,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                        height: isSmallPhone ? AppSpacing.s3.h : AppSpacing.s5.h),
                    _FeatureCard(
                      icon: LucideIcons.bookOpen,
                      title: l10n.heroIntroFeatureCoursesTitle,
                      description: l10n.heroIntroFeatureCoursesDesc,
                      compact: isSmallPhone,
                    ),
                    SizedBox(height: AppSpacing.s2.h),
                    _FeatureCard(
                      icon: LucideIcons.penLine,
                      title: l10n.heroIntroFeatureExercisesTitle,
                      description: l10n.heroIntroFeatureExercisesDesc,
                      compact: isSmallPhone,
                    ),
                    SizedBox(height: AppSpacing.s2.h),
                    _FeatureCard(
                      icon: LucideIcons.messageCircle,
                      title: l10n.heroIntroFeatureChatTitle,
                      description: l10n.heroIntroFeatureChatDesc,
                      compact: isSmallPhone,
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
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({this.heightOverride});

  /// Si fourni : hauteur fixe (en dp). Si null : AspectRatio 4/3 (tablet).
  /// Audit BUG-04 : sur phone, on contraint la hauteur pour garder de la
  /// place aux 3 feature cards en dessous.
  final double? heightOverride;

  @override
  Widget build(BuildContext context) {
    final banner = Container(
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
        size: 80.sp,
        color: AppColors.card,
      ),
    );

    if (heightOverride != null) {
      return SizedBox(height: heightOverride!.h, child: banner);
    }
    return AspectRatio(aspectRatio: 4 / 3, child: banner);
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String description;

  /// Audit BUG-04 : sur small phone (<700 dp), padding/font reduits pour
  /// que les 3 cards tiennent dans le viewport.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 36.w : 40.w;
    return Container(
      padding: EdgeInsets.all(
        compact ? AppSpacing.s3.w : AppSpacing.s4.w,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon,
                size: compact ? 20.sp : 22.sp, color: AppColors.primary),
          ),
          SizedBox(width: AppSpacing.s3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.h3
                      .copyWith(fontSize: compact ? 15.sp : 16.sp),
                ),
                SizedBox(height: AppSpacing.s1.h),
                Text(
                  description,
                  style: AppTypography.body.copyWith(
                    fontSize: compact ? 12.sp : 13.sp,
                    color: AppColors.inkSoft,
                  ),
                  maxLines: compact ? 2 : null,
                  overflow:
                      compact ? TextOverflow.ellipsis : TextOverflow.clip,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
