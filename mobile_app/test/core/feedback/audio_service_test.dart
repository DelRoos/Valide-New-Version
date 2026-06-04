import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valide_school/core/feedback/audio_service.dart';

/// `_FakePlayer` enregistre les appels `stop` et `play` sans déclencher
/// d'IO réelle — permet de vérifier la sémantique des coupures sans toucher
/// au plugin natif.
class _FakePlayer implements AudioPlayer {
  final List<String> stopCalls = [];
  final List<String> playSources = [];

  @override
  Future<void> stop() async {
    stopCalls.add('stop');
  }

  @override
  Future<void> play(
    Source source, {
    double? volume,
    double? balance,
    AudioContext? ctx,
    Duration? position,
    PlayerMode? mode,
  }) async {
    if (source is AssetSource) {
      playSources.add(source.path);
    } else {
      playSources.add(source.toString());
    }
  }

  @override
  Future<void> dispose() async {}

  @override
  dynamic noSuchMethod(Invocation i) => null;
}

void main() {
  group('AudioService — happy path', () {
    test('play(successSoft) déclenche stop+play sur le player', () async {
      final fake = _FakePlayer();
      final service = AudioService(
        soundsEnabled: true,
        examModeActive: false,
        player: fake,
      );
      await service.play(AppSfx.successSoft);
      expect(fake.stopCalls, ['stop']);
      expect(fake.playSources, hasLength(1));
      expect(fake.playSources.first, contains('silence.m4a'));
    });
  });

  group('AudioService — coupures', () {
    test('soundsEnabled=false → ni stop ni play', () async {
      final fake = _FakePlayer();
      final service = AudioService(
        soundsEnabled: false,
        examModeActive: false,
        player: fake,
      );
      await service.play(AppSfx.click);
      expect(fake.stopCalls, isEmpty);
      expect(fake.playSources, isEmpty);
    });

    test('examModeActive=true → ni stop ni play', () async {
      final fake = _FakePlayer();
      final service = AudioService(
        soundsEnabled: true,
        examModeActive: true,
        player: fake,
      );
      await service.play(AppSfx.reward);
      expect(fake.stopCalls, isEmpty);
      expect(fake.playSources, isEmpty);
    });
  });
}
