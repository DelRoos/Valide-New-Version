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
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/onboarding/onboarding_cta_footer.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../providers.dart' show profileUpgradeInProgressProvider;
import '../state/onboarding_notifier.dart';
import '../state/onboarding_providers.dart';
import '../state/onboarding_state.dart';
import 'auth_choice_step_body.dart';
import 'hero_intro_step_body.dart';
import 'level_choice_step_body.dart';
import 'name_input_step_body.dart';
import 'phone_input_step_body.dart';
import 'school_input_step_body.dart';
import 'stream_subjects_picker_step_body.dart';
import 'sub_system_step_body.dart';
import 'success_celebration_step_body.dart';
import 'track_choice_step_body.dart';

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
    final upgradeInProgress = ref.watch(profileUpgradeInProgressProvider);
    final l10n = AppLocalizations.of(context);

    // En mode upgrade (visiteur -> compte depuis le dashboard), le retour
    // au step 6 (nom) ne doit pas replonger dans le flow auth (step 5) —
    // l'utilisateur est deja authentifie. On intercept pour revenir au
    // dashboard et laisser le user completer son profil plus tard.
    void onBack() {
      if (upgradeInProgress && state.currentStep == 6) {
        ref
            .read(profileUpgradeInProgressProvider.notifier)
            .setInProgress(false);
        GoRouter.of(context).go('/dashboard');
        return;
      }
      notifier.back();
    }

    // Le footer est dans le Column du body (pas dans bottomNavigationBar) pour
    // qu'il remonte avec le body quand le clavier apparait (resizeToAvoidBottomInset
    // par defaut = true reduit la hauteur du body, donc le footer reste visible
    // au-dessus du clavier sans reglage supplementaire).
    final footer = _footerForStep(
      step: state.currentStep,
      state: state,
      notifier: notifier,
      l10n: l10n,
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        // Step 1 hero intro : image full-bleed derriere status bar.
        // HeroBanner compense le topInset via MediaQuery.of(context).padding.top.
        top: state.currentStep != 1,
        bottom: false,
        child: Column(
          children: [
            _OnboardingHeader(step: state.currentStep, onBack: onBack),
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
            if (footer != null) footer,
          ],
        ),
      ),
    );
  }

  Widget _bodyForStep(int step) => switch (step) {
        0 => const SubSystemStepBody(),
        1 => const HeroIntroStepBody(),
        2 => const TrackChoiceStepBody(),
        3 => const LevelChoiceStepBody(),
        4 => const StreamSubjectsPickerStepBody(),
        5 => const AuthChoiceStepBody(),
        6 => const NameInputStepBody(),
        7 => const PhoneInputStepBody(),
        8 => const SchoolInputStepBody(),
        9 => const SuccessCelebrationStepBody(),
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
        // Auto-avance : tap card appelle setSubSystem() qui transitione
        // directement step 0 -> 1. Pas de CTA intermediaire.
        return null;
      case 1:
        return OnboardingCtaFooter(
          label: l10n.heroIntroCta,
          onPressed: notifier.next,
          secondaryAction: SizedBox(
            width: double.infinity,
            child: AppButton.secondary(
              label: l10n.onboardingHaveAccount,
              icon: LucideIcons.logIn,
              onPressed: notifier.jumpToAuth,
            ),
          ),
        );
      case 2:
        // Auto-avance : tap card appelle setTrackId() -> step 3 direct.
        return null;
      case 3:
        // Auto-avance : tap card appelle setLevelId() -> step 4 direct.
        return null;
      case 4:
        // Step 4 picker : footer rendu par le step body (PickerValidateBar
        // gere son propre CTA avec compteur + validation).
        return null;
      case 6:
        // Step 6 name : CTA actif si le draft du nom est >= 2 chars.
        final hasName = (state.userDisplayName?.trim().length ?? 0) >= 2;
        return OnboardingCtaFooter(
          label: l10n.onboardingContinue,
          onPressed: hasName
              ? () => notifier.setUserDisplayName(state.userDisplayName!.trim())
              : null,
        );
      case 7:
        // Step 7 phone : CTA actif si le numero est valide. Skip est dans
        // le body via bouton tertiaire avec confirmation modale.
        final hasPhone = state.phoneNumber != null;
        return OnboardingCtaFooter(
          label: l10n.onboardingContinue,
          onPressed: hasPhone
              ? () => notifier.setPhoneNumber(state.phoneNumber!)
              : null,
        );
      case 8:
        // Step 8 school : CTA actif si une ecole (catalogue OU pending) a
        // ete posee. Skip est dans le body via bouton tertiaire.
        final hasSchool = state.schoolId != null ||
            state.pendingSchoolRequestId != null;
        return OnboardingCtaFooter(
          label: l10n.onboardingContinue,
          onPressed: hasSchool ? notifier.next : null,
        );
      case 9:
        // Step 9 success : footer rendu par CelebrationConfettiSuccess
        // (CTA "Decouvrir mon dashboard" dans le body).
        return null;
      case 5:
        // Step 5 auth : footer null par design (les 3 boutons d'auth sont
        // dans le body, pas de CTA generique). Cohere avec template.
        return null;
      default:
        return null;
    }
  }
}

/// Header partage : back button + progress bar + step counter.
///
/// Politique d'affichage :
/// - Step 0 (sub-system choice) : pas de header (rien en amont).
/// - Steps 1 (hero) et 5 (auth choice) : back arrow SEUL (pas de progress
///   bar — ce sont des interstitiels, pas des steps de configuration).
/// - Steps 2-4 + 6-8 : header complet (back + progress + counter X/3).
/// - Step 9 (success) : pas de header (fin du flow, pas de retour).
///
/// Audit 2026-06-13 — Avant ce PR, les steps 1 et 5 cachaient le header
/// entierement. Resultat : impossible de revenir au step 0 (changer FR/EN)
/// une fois la transition hero passee. Le notifier.back() supporte deja
/// la chaine 8 -> 0 ; il manquait juste l'affordance UI sur ces 2 steps.
class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({required this.step, required this.onBack});

  final int step;
  final VoidCallback onBack;

  // Step 1 (hero intro) : header masque — HeroIntroStepBody gere son propre
  // back button superpose sur l'image (full-bleed sans gap au-dessus).
  bool get _showHeader => step >= 2 && step <= 8;

  bool get _showProgress =>
      (step >= 2 && step <= 4) || (step >= 6 && step <= 8);

  @override
  Widget build(BuildContext context) {
    if (!_showHeader) return const SizedBox.shrink();

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
            // Audit 2026-06-14 — Tooltip retire : sur MIUI/Xiaomi le tooltip
            // reste affiche ~1.5s apres tap-and-release et donne l'impression
            // d'un bouton parasit (chip "Retour" grise flottante). L'icone
            // chevron-left etant universelle, le tooltip n'ajoutait rien.
          ),
          if (_showProgress) ...[
            SizedBox(width: AppSpacing.s2.w),
            Expanded(child: _ProgressBar(step: step)),
            SizedBox(width: AppSpacing.s3.w),
            Text(
              '${_counterFor(step)}/3',
              style: AppTypography.body.copyWith(
                fontSize: 13.sp,
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static int _counterFor(int step) => step <= 4 ? step - 1 : step - 5;
}

/// Barre de progression normalisee aux steps de configuration uniquement
/// (2-4 et 6-8) pour preserver la semantique "3 etapes par bloc" du template.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final progress = step <= 4 ? (step - 1) / 3.0 : (step - 5) / 3.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: LinearProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        minHeight: 8.h,
        backgroundColor: AppColors.border,
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
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
