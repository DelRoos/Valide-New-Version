import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'exam_mode.dart';
import 'feedback_prefs.dart';

/// Catalogue des 12 sons UX (DESIGN.md § Audio catalogue). Pour P0, tous
/// pointent vers `silence.m4a` (production audio = story future).
///
/// Tous les chemins sont relatifs au dossier `assets/audio/` — c'est
/// `AudioService._assetFor` qui résout le path final pour `audioplayers`.
enum AppSfx {
  /// Validation douce (réponse correcte, tap utile)
  successSoft,

  /// Validation forte (mention obtenue, palier débloqué)
  successStrong,

  /// Erreur douce (réponse partielle / rephrase)
  errorSoft,

  /// Erreur forte (refus, blocage)
  errorBlock,

  /// Click neutre (sélection, navigation)
  click,

  /// Pop d'apparition (toast, badge)
  pop,

  /// Whoosh (transitions, swipe)
  whoosh,

  /// Tick (compte à rebours, métronome)
  tick,

  /// Ouverture (sheet, modale)
  open,

  /// Fermeture (sheet, modale)
  close,

  /// Cha-ching (gain de crédit / récompense)
  reward,

  /// Bloom (level-up, fête)
  bloom,
}

/// Service audio centralisé. UNIQUE point d'appel autorisé pour
/// `audioplayers` dans le projet.
///
/// Coupures globales : `soundsEnabled == false`, Mode Examen actif.
/// P0 ne détecte PAS le mode silencieux Android (story note autorise).
class AudioService {
  AudioService({
    required this.soundsEnabled,
    required this.examModeActive,
    AudioPlayer? player,
  }) : _player = player ?? AudioPlayer();

  final bool soundsEnabled;
  final bool examModeActive;
  final AudioPlayer _player;

  bool get _suppressed => !soundsEnabled || examModeActive;

  /// Mapping AppSfx → path d'asset. En P0, tous renvoient le placeholder
  /// `silence.m4a` ; à remplacer en production audio (TODO story future).
  String _assetFor(AppSfx sfx) {
    // ignore: unused_local_variable
    final _ = sfx;
    return 'audio/silence.m4a';
  }

  Future<void> play(AppSfx sfx) async {
    if (_suppressed) return;
    await _player.stop();
    await _player.play(AssetSource(_assetFor(sfx)));
  }

  Future<void> dispose() => _player.dispose();
}

final audioServiceProvider = Provider<AudioService>((ref) {
  final prefsAsync = ref.watch(feedbackPrefsProvider);
  final prefs = prefsAsync.asData?.value ?? FeedbackPrefs.defaults;
  final examActive = ref.watch(examModeProvider);
  final service = AudioService(
    soundsEnabled: prefs.soundsEnabled,
    examModeActive: examActive,
  );
  ref.onDispose(service.dispose);
  return service;
});
