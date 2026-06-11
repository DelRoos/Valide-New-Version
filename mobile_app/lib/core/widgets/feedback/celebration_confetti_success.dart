import 'dart:async';
import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../feedback/audio_service.dart';
import '../../feedback/haptic_service.dart';
import '../../theme/tokens.dart';
import '../app_button.dart';

/// Variant visuelle de la celebration — primary color pour le cercle et le
/// halo glow.
enum CelebrationVariant { success, brand, warning }

/// Plein-ecran de celebration (step 9 success onboarding E1bis).
///
/// Composition (cf. DESIGN.md § Composants Onboarding > Celebration confetti
/// success) :
/// * Cercle central 128×128 avec halo glow + checkmark anime spring.
/// * 3 micro-icones orbitantes (PartyPopper / Sparkles / CheckCircle2).
/// * Confetti canvas (package `confetti`) : 4 particules/frame, 2 origines
///   (left/right), 2.5 s, couleurs primary / success / warning / sky.
/// * Audio `bloom` (cf. AudioService Story 0.14) a T+200 ms.
/// * Haptic `success` (light + 100 ms + medium) via HapticService Story 0.14.
/// * Titre + sous-titre (delay 300/400 ms) + CTA primaire en bas.
///
/// Coupures globales (cf. DESIGN.md + D-UX-Update-3/8) :
/// * `MediaQuery.disableAnimations == true` -> pas de confetti, fade-in 200 ms
///   statique du checkmark + titres ; AnimationController disabled.
/// * `AudioService.silent == true` -> pas de son (gere par AudioService).
/// * `HapticService.disabled == true` -> pas de vibration (gere par HapticService).
///
/// L'appel a [onComplete] survient :
/// * Au tap CTA, OU
/// * Apres [autoDismissDelay] (defaut 3500 ms ; passer `null` pour desactiver).
class CelebrationConfettiSuccess extends ConsumerStatefulWidget {
  const CelebrationConfettiSuccess({
    super.key,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.onComplete,
    this.autoDismissDelay = const Duration(milliseconds: 3500),
    this.variant = CelebrationVariant.success,
  });

  final String title;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback onComplete;
  final Duration? autoDismissDelay;
  final CelebrationVariant variant;

  @override
  ConsumerState<CelebrationConfettiSuccess> createState() =>
      _CelebrationConfettiSuccessState();
}

class _CelebrationConfettiSuccessState
    extends ConsumerState<CelebrationConfettiSuccess> {
  late final ConfettiController _leftController;
  late final ConfettiController _rightController;
  Timer? _audioTimer;
  Timer? _autoDismissTimer;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _leftController = ConfettiController(
      duration: const Duration(milliseconds: 2500),
    );
    _rightController = ConfettiController(
      duration: const Duration(milliseconds: 2500),
    );
    // Differe le declenchement multisensoriel apres le 1er frame pour avoir
    // un MediaQuery accessible (coupures globales).
    WidgetsBinding.instance.addPostFrameCallback(_kickOff);
  }

  void _kickOff(Duration _) {
    if (_disposed || !mounted) return;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    if (!reduceMotion) {
      _leftController.play();
      _rightController.play();
    }

    // Audio bloom a T+200 ms (delegue a AudioService = coupure silent geree).
    _audioTimer = Timer(const Duration(milliseconds: 200), () {
      if (_disposed) return;
      unawaited(ref.read(audioServiceProvider).play(AppSfx.bloom));
    });

    // Haptic success (delegue a HapticService = coupure disabled geree).
    unawaited(ref.read(hapticServiceProvider).success());

    // Auto-dismiss.
    if (widget.autoDismissDelay != null) {
      _autoDismissTimer = Timer(widget.autoDismissDelay!, () {
        if (_disposed || !mounted) return;
        widget.onComplete();
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _audioTimer?.cancel();
    _autoDismissTimer?.cancel();
    _leftController.dispose();
    _rightController.dispose();
    super.dispose();
  }

  Color get _accentColor {
    switch (widget.variant) {
      case CelebrationVariant.success:
        return AppColors.success;
      case CelebrationVariant.brand:
        return AppColors.primary;
      case CelebrationVariant.warning:
        return AppColors.warning;
    }
  }

  Color get _accentSoft {
    switch (widget.variant) {
      case CelebrationVariant.success:
        return AppColors.successSoft;
      case CelebrationVariant.brand:
        return AppColors.primarySoft;
      case CelebrationVariant.warning:
        return AppColors.warningSoft;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          if (!reduceMotion) _ConfettiCanvas(
            leftController: _leftController,
            rightController: _rightController,
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.s5.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(),
                  _SuccessHalo(
                    accent: _accentColor,
                    accentSoft: _accentSoft,
                    reduceMotion: reduceMotion,
                  ),
                  SizedBox(height: AppSpacing.s8.h),
                  _Title(
                    text: widget.title,
                    reduceMotion: reduceMotion,
                  ),
                  SizedBox(height: AppSpacing.s3.h),
                  _Subtitle(
                    text: widget.subtitle,
                    reduceMotion: reduceMotion,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 320.w,
                    child: AppButton.primary(
                      label: widget.ctaLabel,
                      onPressed: widget.onComplete,
                    ),
                  ),
                  SizedBox(height: AppSpacing.s4.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiCanvas extends StatelessWidget {
  const _ConfettiCanvas({
    required this.leftController,
    required this.rightController,
  });

  final ConfettiController leftController;
  final ConfettiController rightController;

  static const List<Color> _confettiColors = [
    AppColors.primary,
    AppColors.success,
    AppColors.warning,
    AppColors.sky,
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 0,
          child: ConfettiWidget(
            confettiController: leftController,
            blastDirection: math.pi / 4, // 45 deg vers bas-droite
            emissionFrequency: 0.03,
            numberOfParticles: 4,
            maxBlastForce: 30,
            minBlastForce: 15,
            colors: _confettiColors,
            shouldLoop: false,
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: ConfettiWidget(
            confettiController: rightController,
            blastDirection: 3 * math.pi / 4, // 135 deg vers bas-gauche
            emissionFrequency: 0.03,
            numberOfParticles: 4,
            maxBlastForce: 30,
            minBlastForce: 15,
            colors: _confettiColors,
            shouldLoop: false,
          ),
        ),
      ],
    );
  }
}

class _SuccessHalo extends StatelessWidget {
  const _SuccessHalo({
    required this.accent,
    required this.accentSoft,
    required this.reduceMotion,
  });

  final Color accent;
  final Color accentSoft;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      width: 128.w,
      height: 128.w,
      decoration: BoxDecoration(
        color: accentSoft,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.3),
            blurRadius: 60,
            spreadRadius: 0,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        LucideIcons.check,
        size: 64.sp,
        color: accent,
      ),
    );

    if (reduceMotion) {
      // Pas d'animation -> rendu direct opaque (evite le bug
      // flutter_animate qui laisse l'opacity a 0 en test env sans
      // controller tick).
      return circle;
    }
    return circle
        .animate()
        .scale(
          begin: const Offset(0, 0),
          end: const Offset(1, 1),
          duration: AppMotion.celebration,
          curve: AppMotion.emphasized,
          delay: const Duration(milliseconds: 100),
        )
        .fadeIn(duration: AppMotion.standard);
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.text, required this.reduceMotion});

  final String text;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final widget = Text(
      text,
      style: AppTypography.h2.copyWith(fontSize: 24.sp),
      textAlign: TextAlign.center,
    );
    if (reduceMotion) return widget;
    return widget
        .animate()
        .slideY(
          begin: 0.5,
          end: 0,
          duration: const Duration(milliseconds: 400),
          delay: const Duration(milliseconds: 300),
          curve: AppMotion.emphasized,
        )
        .fadeIn(delay: const Duration(milliseconds: 300));
  }
}

class _Subtitle extends StatelessWidget {
  const _Subtitle({required this.text, required this.reduceMotion});

  final String text;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final widget = Text(
      text,
      style: AppTypography.body.copyWith(
        color: AppColors.inkSoft,
        fontSize: 16.sp,
      ),
      textAlign: TextAlign.center,
    );
    if (reduceMotion) return widget;
    return widget
        .animate()
        .slideY(
          begin: 0.5,
          end: 0,
          duration: const Duration(milliseconds: 400),
          delay: const Duration(milliseconds: 400),
          curve: AppMotion.emphasized,
        )
        .fadeIn(delay: const Duration(milliseconds: 400));
  }
}
