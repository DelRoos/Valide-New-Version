import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valide_school/core/feedback/haptic_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Capture les MethodChannel calls vers HapticFeedback (canal `flutter/platform`).
  final invocations = <String>[];
  setUp(() {
    invocations.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          invocations.add(call.arguments as String? ?? 'standard');
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('HapticService — happy path', () {
    test('light() invoque HapticFeedbackType.lightImpact', () async {
      final service =
          HapticService(vibrationsEnabled: true, examModeActive: false);
      await service.light();
      expect(invocations, contains('HapticFeedbackType.lightImpact'));
    });

    test('selection() invoque selectionClick', () async {
      final service =
          HapticService(vibrationsEnabled: true, examModeActive: false);
      await service.selection();
      expect(invocations, contains('HapticFeedbackType.selectionClick'));
    });

    test('success() invoque light puis medium (séquence)', () async {
      final service =
          HapticService(vibrationsEnabled: true, examModeActive: false);
      await service.success();
      expect(invocations, [
        'HapticFeedbackType.lightImpact',
        'HapticFeedbackType.mediumImpact',
      ]);
    });

    test('fire() dispatch sur la bonne méthode', () async {
      final service =
          HapticService(vibrationsEnabled: true, examModeActive: false);
      await service.fire(HapticPreset.heavy);
      expect(invocations, contains('HapticFeedbackType.heavyImpact'));
    });
  });

  group('HapticService — coupures globales', () {
    test('vibrationsEnabled=false → aucune invocation', () async {
      final service =
          HapticService(vibrationsEnabled: false, examModeActive: false);
      await service.light();
      await service.medium();
      await service.success();
      expect(invocations, isEmpty);
    });

    test('examModeActive=true → aucune invocation', () async {
      final service =
          HapticService(vibrationsEnabled: true, examModeActive: true);
      await service.heavy();
      await service.error();
      expect(invocations, isEmpty);
    });
  });
}
