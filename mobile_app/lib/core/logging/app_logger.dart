// Point d'import UNIQUE pour `package:logger`. Voir CLAUDE.md § Architecture mobile 3 :
// aucun autre fichier ne doit importer `package:logger/logger.dart` directement.
// Toute donnée sensible (téléphone, JWT, PIN, password) est masquée via `redact` avant émission.
// Ne jamais logger un payload JSON entier — extraire et logger uniquement les champs identifiés.

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    filter: ProductionFilter(),
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      colors: false,
      printEmojis: false,
    ),
    level: resolveLevel(isRelease: kReleaseMode),
  );

  static void v(String message, {Object? error}) =>
      _logger.t(redact(message), error: error);

  static void d(String message, {Object? error}) =>
      _logger.d(redact(message), error: error);

  static void i(String message, {Object? error}) =>
      _logger.i(redact(message), error: error);

  static void w(String message, {Object? error}) =>
      _logger.w(redact(message), error: error);

  static void e(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.e(redact(message), error: error, stackTrace: stackTrace);

  @visibleForTesting
  static Level resolveLevel({required bool isRelease}) =>
      isRelease ? Level.warning : Level.trace;

  static String redact(String message) {
    return message
        .replaceAllMapped(
          _phoneWithPrefix,
          (m) => '${m.group(1)}***${m.group(3)}',
        )
        .replaceAllMapped(
          _phoneLocal,
          (m) => '${m.group(1)}***${m.group(3)}',
        )
        .replaceAllMapped(_credentials, (m) => '${m.group(1)}***');
  }

  static final RegExp _phoneWithPrefix =
      RegExp(r'(\+?237)([6-9]\d{4})(\d{4})\b');

  static final RegExp _phoneLocal =
      RegExp(r'(?<![\d+])([6-9]\d)(\d{3})(\d{4})\b');

  static final RegExp _credentials = RegExp(
    r'(\b(?:pin|password|pwd|token|api[_-]?key|secret|authorization|bearer)\s*[=:]\s*)([^\s,;}\]")]+)',
    caseSensitive: false,
  );
}
