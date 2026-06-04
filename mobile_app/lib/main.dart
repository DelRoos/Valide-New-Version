import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/logging/app_logger.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _bootstrap();
  runApp(const ProviderScope(child: ValideApp()));
}

/// Init Firebase + Crashlytics. Story 0.6 Phase A : tant que
/// `firebase_options.dart` est un stub (Phase B pas faite), l'init lève
/// `UnsupportedError` qu'on attrape silencieusement — l'app continue
/// avec les providers Firebase en mode `unavailable`.
Future<void> _bootstrap() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _setupCrashlytics();
    AppLogger.bindCrashlytics(FirebaseCrashlytics.instance);
    AppLogger.i('Firebase bootstrap OK');
  } catch (e, st) {
    // Erreur attendue tant que Phase B n'est pas faite (stub options).
    AppLogger.w(
      'Firebase bootstrap skipped — voir Story 0.6 Phase B. Erreur: $e',
      error: e,
    );
    if (kDebugMode) {
      // ignore: avoid_print
      print('Firebase bootstrap stack: $st');
    }
  }
}

void _setupCrashlytics() {
  // Crashlytics OFF en debug (sinon spam de crashes pendant le dev).
  FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);

  // Toutes les Flutter errors deviennent des crashes fatals Crashlytics.
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Erreurs zone hors widgets (futures non await, etc.).
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}
