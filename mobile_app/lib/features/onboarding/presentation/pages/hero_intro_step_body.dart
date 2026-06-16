// Story E1bis-2bis — Step body 1 du shell onboarding refonte.
//
// Widget body PUR : pas de Scaffold, pas de footer. Le shell parent
// (OnboardingShell) fournit le Scaffold, la SafeArea, et le footer CTA
// dispatched par currentStep. Refactor du HeroIntroPage (PR #103) qui
// posait son propre Scaffold + footer (anti-pattern corrige par E1bis-2bis).
//
// Hero illustration : asset local full-bleed (pas de reseau — data limitee
// Cameroun). Le back button est superpose en top-left avec offset status bar.
// Shell desactive SafeArea top sur step 1 pour que l'image passe derriere
// la barre de statut.
//
// 3 feature tiles informatifs : Cours / Exercices / Chat IA.
// PAS de bouton / ripple / chevron — ce sont des descriptions, pas des CTA.
//
// Responsive (audit BUG-04 2026-06-13) :
// - phone < 700 dp width : hero compact (220 dp height).
// - phone >= 700 dp et < 840 dp : hero moyen (280 dp).
// - tablet >= 840 dp : ConstrainedBox 600 dp centre + hero AspectRatio 16/9.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../state/onboarding_providers.dart';

class HeroIntroStepBody extends ConsumerWidget {
  const HeroIntroStepBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isTablet = width >= 840;
        final isSmallPhone = width < 700;

        final heroHeight = isTablet ? null : (isSmallPhone ? 220.0 : 280.0);

        final content = SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeroBanner(
                heightOverride: heroHeight,
                onBack: notifier.back,
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
                    _FeatureItem(
                      icon: LucideIcons.bookOpen,
                      title: l10n.heroIntroFeatureCoursesTitle,
                      description: l10n.heroIntroFeatureCoursesDesc,
                      compact: isSmallPhone,
                    ),
                    SizedBox(height: AppSpacing.s2.h),
                    _FeatureItem(
                      icon: LucideIcons.penLine,
                      title: l10n.heroIntroFeatureExercisesTitle,
                      description: l10n.heroIntroFeatureExercisesDesc,
                      compact: isSmallPhone,
                    ),
                    SizedBox(height: AppSpacing.s2.h),
                    _FeatureItem(
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
  const _HeroBanner({this.heightOverride, required this.onBack});

  final double? heightOverride;
  final VoidCallback onBack;

  // Asset local : deposer une photo dans mobile_app/assets/images/hero_intro.jpg.
  // 0 requete reseau = experience stable sur connexions camerounaises.
  static const _assetPath = 'assets/images/hero_intro.jpg';

  @override
  Widget build(BuildContext context) {
    // Offset status bar : le shell desactive SafeArea top sur step 1
    // => le back button doit compenser manuellement la hauteur de la barre.
    final topInset = MediaQuery.of(context).padding.top;

    final banner = Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          _assetPath,
          fit: BoxFit.cover,
          // Fallback reseau tant que hero_intro.jpg n'est pas dans assets/.
          // Remplacer par un vrai asset local avant la prod (CLAUDE.md data).
          errorBuilder: (_, _, _) => Image.network(
            'https://images.unsplash.com/photo-1758270704663-9d002a4b42a2'
            '?w=900&q=80&fit=crop&crop=faces',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const _GradientPlaceholder(),
          ),
        ),
        // Overlay degrade bas : fond fusionne avec AppColors.bg.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, AppColors.bg],
              begin: Alignment(0, 0.4),
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        // Back button positionne en tenant compte de la status bar.
        Positioned(
          top: topInset + AppSpacing.s2,
          left: AppSpacing.s2,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onTap: onBack,
              child: Container(
                padding: EdgeInsets.all(AppSpacing.s2.w),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.30),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.arrowLeft,
                  color: AppColors.card,
                  size: 22.sp,
                ),
              ),
            ),
          ),
        ),
      ],
    );

    if (heightOverride != null) {
      return SizedBox(height: heightOverride!.h, child: banner);
    }
    return AspectRatio(aspectRatio: 16 / 9, child: banner);
  }
}

/// Gradient affiché tant que assets/images/hero_intro.jpg n'est pas fourni.
/// Pas d'icone — juste le fond couleur brand.
class _GradientPlaceholder extends StatelessWidget {
  const _GradientPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary, AppColors.sky],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}

/// Tile informatif : icone + titre + description.
/// PAS de bouton, PAS de ripple, PAS de chevron — affiche ce que l'app
/// offre, sans affordance de navigation (audit 2026-06-15).
class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 36.w : 42.w;
    return Container(
      padding: EdgeInsets.all(compact ? AppSpacing.s3.w : AppSpacing.s4.w),
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
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: compact ? 20.sp : 22.sp,
              color: AppColors.primary,
            ),
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
