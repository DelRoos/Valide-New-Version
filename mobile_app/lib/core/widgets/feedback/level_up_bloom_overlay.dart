import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../feedback/audio_service.dart';
import '../../feedback/haptic_service.dart';
import '../../theme/tokens.dart';

/// Overlay « palier débloqué » — bloom radial + icône étoile.
/// 1.2 s total. Déclenche Haptic.success + Audio.bloom en parallèle.
class LevelUpBloomOverlay {
  LevelUpBloomOverlay._();

  static Future<void> show(BuildContext context, WidgetRef ref) async {
    final overlay = Overlay.of(context, rootOverlay: true);
    final entry = OverlayEntry(builder: (_) => const _BloomView());
    overlay.insert(entry);
    unawaited(ref.read(hapticServiceProvider).success());
    unawaited(ref.read(audioServiceProvider).play(AppSfx.bloom));
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    entry.remove();
  }
}

class _BloomView extends StatelessWidget {
  const _BloomView();

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final badge = Container(
      width: 120.w,
      height: 120.w,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        boxShadow: AppElevation.brand,
      ),
      child: Icon(LucideIcons.star, size: 72.sp, color: AppColors.card),
    );
    return Positioned.fill(
      child: IgnorePointer(
        child: ColoredBox(
          color: AppColors.ink.withValues(alpha: 0.2),
          child: Center(
            child: reduceMotion
                ? badge
                : badge
                    .animate()
                    .scale(
                      begin: const Offset(0.2, 0.2),
                      end: const Offset(1.1, 1.1),
                      duration: AppMotion.celebration,
                      curve: AppMotion.emphasized,
                    )
                    .then()
                    .scale(
                      begin: const Offset(1.1, 1.1),
                      end: const Offset(1, 1),
                      duration: AppMotion.standard,
                    )
                    .fadeIn(duration: AppMotion.fast),
          ),
        ),
      ),
    );
  }
}
