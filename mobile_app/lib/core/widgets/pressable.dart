import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../feedback/haptic_service.dart';
import '../theme/tokens.dart';

// Re-export pour préserver l'API publique pré-Story 0.14 (les widgets
// AppButton, AppCard, AppIconButton importent HapticPreset depuis ici).
export '../feedback/haptic_service.dart' show HapticPreset;

/// Wrapper qui applique le pattern "tap feedback" de DESIGN.md :
/// scale 0.96 → 1.0 + opacity 0.7 → 1.0 sur durée `AppMotion.fast`.
///
/// Délègue la sémantique tactile à `Material` + `InkWell` (ripple natif).
/// L'haptic est déclenché au `onTap` quand `hapticPreset` est non nul,
/// via [[haptic_service]] (respecte les prefs utilisateur + Mode Examen).
class Pressable extends ConsumerStatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.hapticPreset,
    this.enabled = true,
    this.minSize,
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final HapticPreset? hapticPreset;
  final bool enabled;

  /// Taille minimum imposée (touch target ≥ 48 dp recommandé UX-DR-29).
  final Size? minSize;

  @override
  ConsumerState<Pressable> createState() => _PressableState();
}

class _PressableState extends ConsumerState<Pressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled) return;
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _onTap() {
    if (!widget.enabled || widget.onTap == null) return;
    final preset = widget.hapticPreset;
    if (preset != null) {
      ref.read(hapticServiceProvider).fire(preset);
    }
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final inkWell = Material(
      color: Colors.transparent,
      borderRadius: widget.borderRadius,
      child: InkWell(
        borderRadius: widget.borderRadius,
        onTap: widget.enabled ? _onTap : null,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: widget.minSize?.width ?? 0,
            minHeight: widget.minSize?.height ?? 0,
          ),
          child: widget.child,
        ),
      ),
    );

    return AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: AppMotion.fast,
      curve: AppMotion.standardOut,
      child: AnimatedOpacity(
        opacity: widget.enabled ? (_pressed ? 0.7 : 1.0) : 0.5,
        duration: AppMotion.fast,
        curve: AppMotion.standardOut,
        child: inkWell,
      ),
    );
  }
}
