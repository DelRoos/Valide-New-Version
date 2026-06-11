// Story E1bis-2bis — Shell racine partage du flow onboarding refonte.
//
// Refactor PR #103 (E1bis-2) : un SEUL Scaffold pour tout le flow, header
// (back + progress) et footer (OnboardingCtaFooter) partages, transitions
// slide AnimatedSwitcher entre steps. Fidele au template
// doc/templates/src/components/OnboardingFlow.tsx (1 composant + 1 state
// step + AnimatePresence motion.div).
//
// Au initState : loadFromPersistence() via addPostFrameCallback (restauration
// post-kill app : si subSystem persiste, le notifier hydrate + avance
// currentStep a 1).
//
// Pour cette story, seuls les step bodies 0 + 1 sont livres (SubSystemStepBody
// + HeroIntroStepBody). Steps 2-9 affichent un placeholder remplace au fil
// des stories E1bis-3 a E1bis-7.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/onboarding/onboarding_cta_footer.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../state/onboarding_notifier.dart';
import '../state/onboarding_providers.dart';
import '../state/onboarding_state.dart';
import 'hero_intro_step_body.dart';
import 'sub_system_step_body.dart';

class OnboardingShell extends ConsumerStatefulWidget {
  const OnboardingShell({super.key});

  @override
  ConsumerState<OnboardingShell> createState() => _OnboardingShellState();
}

class _OnboardingShellState extends ConsumerState<OnboardingShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(onboardingNotifierProvider.notifier).loadFromPersistence();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _OnboardingHeader(step: state.currentStep, onBack: notifier.back),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  final slide = Tween<Offset>(
                    begin: const Offset(0.08, 0),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: slide, child: child),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(state.currentStep),
                  child: _bodyForStep(state.currentStep),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _footerForStep(
        step: state.currentStep,
        state: state,
        notifier: notifier,
        l10n: l10n,
      ),
    );
  }

  Widget _bodyForStep(int step) => switch (step) {
        0 => const SubSystemStepBody(),
        1 => const HeroIntroStepBody(),
        _ => _StepPlaceholder(stepIndex: step),
      };

  Widget? _footerForStep({
    required int step,
    required OnboardingState state,
    required OnboardingNotifier notifier,
    required AppLocalizations l10n,
  }) {
    // Template `showFooterCta = step !== 5` (step 5 = auth choice = pas de
    // footer CTA, les boutons d'auth sont dans le body).
    if (step == 5) return null;

    switch (step) {
      case 0:
        return OnboardingCtaFooter(
          label: l10n.onboardingContinue,
          onPressed: state.subSystem != null ? notifier.next : null,
        );
      case 1:
        return OnboardingCtaFooter(
          label: l10n.heroIntroCta,
          onPressed: notifier.next,
        );
      default:
        // Steps 2-9 (hors 5) : seront livres par E1bis-3 a E1bis-7. Pour
        // l'instant pas de footer (placeholder visible).
        return null;
    }
  }
}

/// Header partage : back button + progress bar + step counter.
///
/// Visible uniquement pour les steps de configuration (2-4 et 6-8 cf.
/// template `configStepsActive`). Steps 0, 1, 5, 9 = pas de header
/// (entree, hero, auth choice, success celebration).
class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({required this.step, required this.onBack});

  final int step;
  final VoidCallback onBack;

  bool get _configStepsActive =>
      (step >= 2 && step <= 4) || (step >= 6 && step <= 8);

  @override
  Widget build(BuildContext context) {
    if (!_configStepsActive) return const SizedBox.shrink();

    final progress = step <= 4 ? (step - 1) / 3.0 : (step - 5) / 3.0;
    final counter = step <= 4 ? step - 1 : step - 5;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s4.w,
        vertical: AppSpacing.s3.h,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            color: AppColors.ink,
            onPressed: onBack,
            tooltip: 'Retour',
          ),
          SizedBox(width: AppSpacing.s2.w),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 8.h,
                backgroundColor: AppColors.border,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.s3.w),
          Text(
            '$counter/3',
            style: AppTypography.body.copyWith(
              fontSize: 13.sp,
              color: AppColors.inkSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder de debug pour les steps non encore livres (E1bis-3 a E1bis-7).
class _StepPlaceholder extends StatelessWidget {
  const _StepPlaceholder({required this.stepIndex});

  final int stepIndex;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Etape $stepIndex — a venir (E1bis-3+)',
          style: AppTypography.h3,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
