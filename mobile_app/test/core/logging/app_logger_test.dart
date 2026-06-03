import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:valide_school/core/logging/app_logger.dart';

void main() {
  group('AppLogger.redact', () {
    test('masque un numéro de téléphone camerounais préfixé +237', () {
      final result = AppLogger.redact(
        'Login attempt for user +237698765432 succeeded',
      );
      expect(result, contains('+237***5432'));
      expect(result, isNot(contains('698765432')));
    });

    test('masque un token (JWT-like)', () {
      final result = AppLogger.redact('Auth header token=abc.def.ghi sent');
      expect(result, contains('token=***'));
      expect(result, isNot(contains('abc.def.ghi')));
    });

    test('masque pin= et password=', () {
      final result = AppLogger.redact('payload pin=1234 password=hunter2!');
      expect(result, contains('pin=***'));
      expect(result, contains('password=***'));
      expect(result, isNot(contains('1234')));
      expect(result, isNot(contains('hunter2!')));
    });
  });

  group('AppLogger.resolveLevel', () {
    test(
      'retourne Level.warning en release et Level.trace en debug',
      () {
        expect(
          AppLogger.resolveLevel(isRelease: true),
          equals(Level.warning),
        );
        expect(
          AppLogger.resolveLevel(isRelease: false),
          equals(Level.trace),
        );
      },
    );
  });
}
