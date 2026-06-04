import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Préférences multisensorielles (sons + vibrations) — par défaut activées,
/// l'écran Profil (Epic 1) consommera ce provider pour bascule utilisateur.
/// Persistées en `SharedPreferences` (clés `feedback.sounds`, `feedback.vibrations`).
class FeedbackPrefs {
  const FeedbackPrefs({
    required this.soundsEnabled,
    required this.vibrationsEnabled,
  });

  final bool soundsEnabled;
  final bool vibrationsEnabled;

  FeedbackPrefs copyWith({bool? soundsEnabled, bool? vibrationsEnabled}) {
    return FeedbackPrefs(
      soundsEnabled: soundsEnabled ?? this.soundsEnabled,
      vibrationsEnabled: vibrationsEnabled ?? this.vibrationsEnabled,
    );
  }

  static const _kSounds = 'feedback.sounds';
  static const _kVibrations = 'feedback.vibrations';
  static const defaults = FeedbackPrefs(
    soundsEnabled: true,
    vibrationsEnabled: true,
  );
}

class FeedbackPrefsNotifier extends AsyncNotifier<FeedbackPrefs> {
  @override
  Future<FeedbackPrefs> build() async {
    final prefs = await SharedPreferences.getInstance();
    return FeedbackPrefs(
      soundsEnabled: prefs.getBool(FeedbackPrefs._kSounds) ?? true,
      vibrationsEnabled: prefs.getBool(FeedbackPrefs._kVibrations) ?? true,
    );
  }

  Future<void> setSoundsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(FeedbackPrefs._kSounds, value);
    final current = state.value ?? FeedbackPrefs.defaults;
    state = AsyncValue.data(current.copyWith(soundsEnabled: value));
  }

  Future<void> setVibrationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(FeedbackPrefs._kVibrations, value);
    final current = state.value ?? FeedbackPrefs.defaults;
    state = AsyncValue.data(current.copyWith(vibrationsEnabled: value));
  }
}

final feedbackPrefsProvider =
    AsyncNotifierProvider<FeedbackPrefsNotifier, FeedbackPrefs>(
  FeedbackPrefsNotifier.new,
);
