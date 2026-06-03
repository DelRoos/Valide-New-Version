import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

/// Wrapper qui applique le pattern "tap feedback" de DESIGN.md :
/// scale 0.96 → 1.0 + opacity 0.7 → 1.0 sur durée `AppMotion.fast`.
///
/// Délègue la sémantique tactile à `Material` + `InkWell` (ripple natif).
/// L'haptic est déclenché au `onTap` quand `hapticPreset` est non nul.
///
/// TODO(0.14): remplacer l'appel direct `HapticFeedback.*` par `HapticService`
/// quand le service exposé par Story 0.14 sera disponible, pour respecter le
/// setting Profil « Vibrations activées ».
class Pressable extends StatefulWidget {
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
  State<Pressable> createState() => _PressableState();
}

enum HapticPreset { selection, light, medium, heavy }

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled) return;
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _onTap() {
    if (!widget.enabled || widget.onTap == null) return;
    switch (widget.hapticPreset) {
      case HapticPreset.selection:
        HapticFeedback.selectionClick();
      case HapticPreset.light:
        HapticFeedback.lightImpact();
      case HapticPreset.medium:
        HapticFeedback.mediumImpact();
      case HapticPreset.heavy:
        HapticFeedback.heavyImpact();
      case null:
        break;
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
