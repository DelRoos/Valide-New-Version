import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/tokens.dart';

enum ToastTone { success, info, warning, error }

/// Toast slide-in top, queue stricte : un seul toast visible à la fois,
/// les suivants attendent que le précédent se ferme (UX-DR-9 — pas d'overlap).
class AppToast {
  AppToast._();

  static const Duration _slide = Duration(milliseconds: 200);
  static const Duration _hold = Duration(seconds: 4);

  static final Queue<_ToastJob> _queue = Queue<_ToastJob>();
  static bool _showing = false;

  static void show(
    BuildContext context, {
    required String message,
    ToastTone tone = ToastTone.success,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    _queue.add(_ToastJob(overlay: overlay, message: message, tone: tone));
    if (!_showing) _runNext();
  }

  static void _runNext() {
    if (_queue.isEmpty) {
      _showing = false;
      return;
    }
    _showing = true;
    final job = _queue.removeFirst();
    final entry = OverlayEntry(
      builder: (_) => _ToastView(message: job.message, tone: job.tone),
    );
    job.overlay.insert(entry);
    Timer(_hold + _slide * 2, () {
      entry.remove();
      _runNext();
    });
  }
}

class _ToastJob {
  _ToastJob({
    required this.overlay,
    required this.message,
    required this.tone,
  });
  final OverlayState overlay;
  final String message;
  final ToastTone tone;
}

/// Palette de couleurs résolue selon le tone du toast.
({Color bg, Color border, Color icon, Color text}) _palette(ToastTone tone) {
  switch (tone) {
    case ToastTone.success:
      return (
        bg: AppColors.successSoft,
        border: AppColors.success,
        icon: AppColors.success,
        text: AppColors.successInk,
      );
    case ToastTone.info:
      return (
        bg: AppColors.skySoft,
        border: AppColors.sky,
        icon: AppColors.sky,
        text: AppColors.skyInk,
      );
    case ToastTone.warning:
      return (
        bg: AppColors.warningSoft,
        border: AppColors.warning,
        icon: AppColors.warning,
        text: AppColors.warningInk,
      );
    case ToastTone.error:
      return (
        bg: AppColors.dangerSoft,
        border: AppColors.danger,
        icon: AppColors.danger,
        text: AppColors.dangerInk,
      );
  }
}

class _ToastView extends StatefulWidget {
  const _ToastView({required this.message, required this.tone});
  final String message;
  final ToastTone tone;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: AppToast._slide,
  );

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
    Future<void>.delayed(AppToast._hold + AppToast._slide, () {
      if (mounted) _ctrl.reverse();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  IconData get _icon {
    switch (widget.tone) {
      case ToastTone.success:
        return LucideIcons.circleCheck;
      case ToastTone.info:
        return LucideIcons.info;
      case ToastTone.warning:
        return LucideIcons.triangleAlert;
      case ToastTone.error:
        return LucideIcons.circleAlert;
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final colors = _palette(widget.tone);
    return Positioned(
      top: media.padding.top + AppSpacing.s4.h,
      left: AppSpacing.s4.w,
      right: AppSpacing.s4.w,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _ctrl, curve: AppMotion.standardOut)),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.s4.w,
              vertical: AppSpacing.s3.h,
            ),
            decoration: BoxDecoration(
              color: colors.bg,
              border: Border.all(color: colors.border, width: 1.5),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppElevation.soft,
            ),
            child: Row(
              children: [
                Icon(_icon, size: 20.sp, color: colors.icon),
                SizedBox(width: AppSpacing.s3.w),
                Expanded(
                  child: Text(
                    widget.message,
                    style: AppTypography.body.copyWith(color: colors.text),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
