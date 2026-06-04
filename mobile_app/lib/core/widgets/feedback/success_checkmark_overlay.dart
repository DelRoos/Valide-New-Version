import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../feedback/audio_service.dart';
import '../../feedback/haptic_service.dart';
import '../../theme/tokens.dart';

/// Overlay de validation rapide (réponse correcte, action effectuée).
/// 700 ms total : pop-in 200 ms + hold 300 ms + fade-out 200 ms.
/// Déclenche en parallèle : `HapticService.success()` + `AudioService.play(successSoft)`.
class SuccessCheckmarkOverlay {
  SuccessCheckmarkOverlay._();

  static Future<void> show(BuildContext context, WidgetRef ref) async {
    final overlay = Overlay.of(context, rootOverlay: true);
    final entry = OverlayEntry(builder: (_) => const _SuccessCheckmarkView());
    overlay.insert(entry);

    unawaited(ref.read(hapticServiceProvider).success());
    unawaited(ref.read(audioServiceProvider).play(AppSfx.successSoft));

    await Future<void>.delayed(const Duration(milliseconds: 700));
    entry.remove();
  }
}

class _SuccessCheckmarkView extends StatelessWidget {
  const _SuccessCheckmarkView();

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final badge = Container(
      width: 96.w,
      height: 96.w,
      decoration: const BoxDecoration(
        color: AppColors.success,
        shape: BoxShape.circle,
        boxShadow: AppElevation.mid,
      ),
      child: Icon(LucideIcons.check, size: 56.sp, color: AppColors.card),
    );
    return Positioned.fill(
      child: IgnorePointer(
        child: ColoredBox(
          color: AppColors.ink.withValues(alpha: 0.15),
          child: Center(
            child: reduceMotion
                ? badge
                : badge
                    .animate()
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1, 1),
                      duration: AppMotion.standard,
                      curve: AppMotion.emphasized,
                    )
                    .fadeIn(duration: AppMotion.fast),
          ),
        ),
      ),
    );
  }
}

