import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'exam_mode.dart';
import 'feedback_prefs.dart';

/// Catalogue des presets haptic (cf. DESIGN.md § Haptics).
///
/// `light`/`medium`/`heavy` = `HapticFeedback.*Impact()` natifs.
/// `selection` = clic léger pour navigation/onglets.
/// `success`/`error` = séquences orchestrées (cf. méthodes dédiées).
enum HapticPreset { selection, light, medium, heavy, success, error }

/// Service haptic centralisé — UNIQUE point d'appel autorisé pour
/// `HapticFeedback.*` dans tout le projet (cf. CLAUDE.md § interdiction
/// `HapticFeedback` hors core/feedback).
///
/// Coupures globales appliquées :
/// - `vibrationsEnabled == false` dans le profil utilisateur ([[feedback_prefs]])
/// - Mode Examen actif ([[exam_mode]])
///
/// Pour P0 : pas de détection batterie (story note autorise le fallback).
class HapticService {
  HapticService({
    required this.vibrationsEnabled,
    required this.examModeActive,
  });

  final bool vibrationsEnabled;
  final bool examModeActive;

  bool get _suppressed => !vibrationsEnabled || examModeActive;

  Future<void> selection() async {
    if (_suppressed) return;
    await HapticFeedback.selectionClick();
  }

  Future<void> light() async {
    if (_suppressed) return;
    await HapticFeedback.lightImpact();
  }

  Future<void> medium() async {
    if (_suppressed) return;
    await HapticFeedback.mediumImpact();
  }

  Future<void> heavy() async {
    if (_suppressed) return;
    await HapticFeedback.heavyImpact();
  }

  /// Séquence success — light → (100 ms) → medium.
  /// Utilisée par SuccessCheckmarkOverlay et célébrations courtes.
  Future<void> success() async {
    if (_suppressed) return;
    await HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
  }

  /// Séquence error — heavy → (80 ms) → heavy.
  /// Utilisée par ErrorShakeWrapper.
  Future<void> error() async {
    if (_suppressed) return;
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.heavyImpact();
  }

  Future<void> fire(HapticPreset preset) {
    switch (preset) {
      case HapticPreset.selection:
        return selection();
      case HapticPreset.light:
        return light();
      case HapticPreset.medium:
        return medium();
      case HapticPreset.heavy:
        return heavy();
      case HapticPreset.success:
        return success();
      case HapticPreset.error:
        return error();
    }
  }
}

final hapticServiceProvider = Provider<HapticService>((ref) {
  final prefsAsync = ref.watch(feedbackPrefsProvider);
  final prefs = prefsAsync.asData?.value ?? FeedbackPrefs.defaults;
  final examActive = ref.watch(examModeProvider);
  return HapticService(
    vibrationsEnabled: prefs.vibrationsEnabled,
    examModeActive: examActive,
  );
});
