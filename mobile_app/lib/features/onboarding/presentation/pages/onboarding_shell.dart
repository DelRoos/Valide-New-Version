// Story E1bis-2 — Wrapper racine du flow onboarding refonte.
//
// Au initState, appelle OnboardingNotifier.loadFromPersistence() pour
// hydrater subSystem depuis SharedPreferences si dispo (Story 1.2 cle
// onboarding.subsystem). Le build observe currentStep et rend la page
// correspondante.
//
// Pour cette story (E1bis-2), seuls cases 0 + 1 sont implementes. Cases
// 2 a 9 affichent un placeholder de debug ("Etape X — a venir") qui sera
// remplace au fil des stories E1bis-3 a E1bis-7.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens.dart';
import '../state/onboarding_providers.dart';
import 'hero_intro_page.dart';
import 'sub_system_choice_page_v2.dart';

class OnboardingShell extends ConsumerStatefulWidget {
  const OnboardingShell({super.key});

  @override
  ConsumerState<OnboardingShell> createState() => _OnboardingShellState();
}

class _OnboardingShellState extends ConsumerState<OnboardingShell> {
  @override
  void initState() {
    super.initState();
    // Restauration post-kill app : si subSystem persiste, le notifier hydrate
    // + avance currentStep a 1 (l'utilisateur a deja choisi son sub-system,
    // on saute le step 0).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(onboardingNotifierProvider.notifier).loadFromPersistence();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentStep =
        ref.watch(onboardingNotifierProvider.select((s) => s.currentStep));

    switch (currentStep) {
      case 0:
        return const SubSystemChoicePageV2();
      case 1:
        return const HeroIntroPage();
      default:
        return _StepPlaceholder(stepIndex: currentStep);
    }
  }
}

/// Placeholder de debug pour les steps 2 a 9 non encore livres par E1bis-2.
/// Remplaces au fil des stories E1bis-3 a E1bis-7.
class _StepPlaceholder extends StatelessWidget {
  const _StepPlaceholder({required this.stepIndex});

  final int stepIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Etape $stepIndex — a venir (E1bis-3+)',
            style: AppTypography.h3,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
