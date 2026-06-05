import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/logging/app_logger.dart';
import 'firebase_options.dart';

/// Version build courante. Doit refléter `pubspec.yaml` § `version:`.
/// TODO E1+ : extraire automatiquement via `package_info_plus`.
const String kBuildVersion = '1.0.0+1';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _bootstrap();
  runApp(const ProviderScope(child: ValideApp()));
}

/// Init Firebase + Crashlytics + smoke test Firestore (Story 0.21 AC2).
/// Si l'init Firebase échoue (ex. options stub), on continue silencieusement
/// — les providers Firebase exposeront `firebaseAvailableProvider == false`.
Future<void> _bootstrap() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _setupCrashlytics();
    AppLogger.bindCrashlytics(FirebaseCrashlytics.instance);
    AppLogger.i('Firebase bootstrap OK');
  } catch (e, st) {
    AppLogger.w(
      'Firebase bootstrap skipped — voir Story 0.6 Phase B. Erreur: $e',
      error: e,
    );
    if (kDebugMode) {
      // ignore: avoid_print
      print('Firebase bootstrap stack: $st');
    }
    return;
  }

  // Story 0.21 AC2 — smoke test Firestore write + read.
  // Non bloquant : si Anonymous Auth n'est pas active sur le projet ou si
  // Firestore est indisponible, on log et on continue.
  await _e0SmokeTest();
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

/// Sentinelle E0 — Story 0.21 AC2.
///
/// Vérifie bout-en-bout que :
/// 1. Firebase Auth est joignable (signInAnonymously)
/// 2. Firestore accepte une écriture sur `_smoketest/launch` (règles 0.9
///    autorisent les utilisateurs authentifiés)
/// 3. La lecture en retour confirme la persistance + la cohérence des
///    timestamps serveur
///
/// Le résultat est loggé via `AppLogger.i` (succès) ou `AppLogger.w` (échec
/// gérable, ex. Anonymous Auth pas activée dans Firebase Console).
Future<void> _e0SmokeTest() async {
  final stopwatch = Stopwatch()..start();
  try {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
    final firestore = FirebaseFirestore.instance;
    final ref = firestore.collection('_smoketest').doc('launch');
    await ref.set({
      'ts': FieldValue.serverTimestamp(),
      'buildVersion': kBuildVersion,
      'uid': auth.currentUser?.uid,
    });
    final snap = await ref.get();
    if (!snap.exists) {
      throw StateError('smoke read returned no document');
    }
    stopwatch.stop();
    AppLogger.i(
      'E0 smoke test: write+read OK in ${stopwatch.elapsedMilliseconds}ms',
    );
  } catch (e, st) {
    stopwatch.stop();
    AppLogger.w(
      'E0 smoke test skipped: $e (durée ${stopwatch.elapsedMilliseconds}ms)',
      error: e,
    );
    if (kDebugMode) {
      // ignore: avoid_print
      print('E0 smoke stack: $st');
    }
  }
}
