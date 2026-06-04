import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../feedback/audio_service.dart';
import '../../feedback/haptic_service.dart';
import '../../theme/tokens.dart';

/// Wrapper qui secoue son enfant en cas d'erreur. Méthode statique
/// `ErrorShakeWrapper.shake(...)` qui prend une `GlobalKey<_ShakeState>`
/// pour cibler le widget à secouer + déclenche Haptic.error() + Audio.errorSoft.
class ErrorShakeWrapper extends StatefulWidget {
  const ErrorShakeWrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  static Future<void> trigger(
    GlobalKey<ErrorShakeWrapperState> key,
    WidgetRef ref,
  ) async {
    unawaited(ref.read(hapticServiceProvider).error());
    unawaited(ref.read(audioServiceProvider).play(AppSfx.errorSoft));
    await key.currentState?.shake();
  }

  @override
  State<ErrorShakeWrapper> createState() => ErrorShakeWrapperState();
}

class ErrorShakeWrapperState extends State<ErrorShakeWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: AppMotion.emphasis,
  );

  Future<void> shake() async {
    if (!mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    await _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final t = _ctrl.value;
        // Damped oscillation : 3 aller-retour qui s'attenuent.
        final dx = (t == 0)
            ? 0.0
            : (1 - t) * 8 * (t * 6 % 2 < 1 ? -1 : 1);
        return Transform.translate(
          offset: Offset(dx, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
