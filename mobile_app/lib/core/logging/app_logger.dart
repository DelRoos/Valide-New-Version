// Point d'import UNIQUE pour `package:logger`. Voir CLAUDE.md § Architecture mobile 3 :
// aucun autre fichier ne doit importer `package:logger/logger.dart` directement.
// Toute donnée sensible (téléphone, JWT, PIN, password) est masquée via `redact` avant émission.
// Ne jamais logger un payload JSON entier — extraire et logger uniquement les champs identifiés.

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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

  /// Instance Crashlytics liée par `bindCrashlytics(...)` au boot (Story 0.6).
  /// Si null (init Firebase pas faite — ex. tests, Phase B pending), les
  /// erreurs ne sont pas forwardées — `_logger.e()` continue de tracer en local.
  static FirebaseCrashlytics? _crashlytics;

  /// À appeler une fois au boot après `Firebase.initializeApp()`. Branche
  /// `AppLogger.e()` sur `FirebaseCrashlytics.recordError()` pour la collecte
  /// d'erreurs distantes.
  static void bindCrashlytics(FirebaseCrashlytics instance) {
    _crashlytics = instance;
  }

  /// Pour les tests : reset l'instance Crashlytics liée.
  @visibleForTesting
  static void resetCrashlyticsBinding() {
    _crashlytics = null;
  }

  static void v(String message, {Object? error}) =>
      _logger.t(redact(message), error: error);

  static void d(String message, {Object? error}) =>
      _logger.d(redact(message), error: error);

  static void i(String message, {Object? error}) =>
      _logger.i(redact(message), error: error);

  static void w(String message, {Object? error}) =>
      _logger.w(redact(message), error: error);

  static void e(String message, {Object? error, StackTrace? stackTrace}) {
    final redacted = redact(message);
    _logger.e(redacted, error: error, stackTrace: stackTrace);
    final cl = _crashlytics;
    if (cl != null) {
      // Forward best-effort vers Crashlytics. Non-fatal pour qu'un seul
      // appel `e()` ne fasse pas remonter une erreur fatale.
      cl.recordError(
        error ?? redacted,
        stackTrace,
        reason: redacted,
        fatal: false,
      );
    }
  }

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
