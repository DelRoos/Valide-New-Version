import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/firebase/providers.dart';
import 'core/logging/app_logger.dart';
import 'core/logging/perf_logger.dart';
import 'features/onboarding/providers.dart';
import 'firebase_options.dart';

/// Version build courante. Doit refléter `pubspec.yaml` § `version:`.
/// A migrer vers `package_info_plus` quand on aura un cas d'usage runtime
/// (telemetrie, crash reports). En attendant, constante manuelle.
const String kBuildVersion = '1.0.0+1';

// Web OAuth 2.0 client ID requis par google_sign_in v7 sur Android.
// Issu de google-services.json > oauth_client[client_type=3].
// Pas un secret : valeur publique distribuée avec l'APK.
const _kGoogleServerClientId =
    '410229733764-sdiv74q0ttjom4cndeicgrohai0onrhb.apps.googleusercontent.com';

Future<void> main() async {
  logPerfEvent('boot.main.start');
  final binding = WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Story 0.22 — garde le splash natif visible jusqu'a ce que la SplashPage
  // Flutter appelle FlutterNativeSplash.remove() au 1er postFrame. Sans
  // preserve, on retombe sur un fond noir entre splash natif et 1re frame.
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  // Story 1.2 — preload SharedPreferences AVANT runApp pour eviter le flash
  // de locale par defaut (FR) puis bascule (EN) au 1er build pour un user
  // anglophone qui relance l'app. Le splash natif reste visible pendant ce
  // preload (~10-100ms selon device). Le ProviderScope override injecte
  // l'instance dans `sharedPreferencesProvider` (sinon UnimplementedError).
  final prefs = await logPerf(
    'boot.sharedPreferences.load',
    SharedPreferences.getInstance,
  );

  // Story 0.22 — Firebase init en background (non bloquant) pour ne pas
  // retarder runApp. Le splash natif resterait fige tant que _bootstrap
  // n'a pas rendu la main, et l'utilisateur ne verrait jamais l'animation
  // Flutter (boot Firebase observe ~3-5s sur device entree de gamme).
  // SplashPage Flutter n'utilise pas Firebase ; HelloPage non plus
  // (sentinelle E0). Si /hello tente une operation Firebase avant init,
  // _e0SmokeTest le gere via AppLogger.w non bloquant.
  //
  // Audit 2026-06-14 — On garde la reference de la Future de _bootstrap
  // pour la propager dans `firebaseReadyProvider`. Le splash warm-up
  // catalogue (cf. splash_page.dart) et le catalogue check du router
  // (cf. catalogue/providers.dart) attendent cette Future avant d'acceder
  // a Firestore — sans ca, le warm-up echouait systematiquement avec
  // `[core/no-app] No Firebase App '[DEFAULT]'` (race ~2.9s).
  final bootstrapFuture = _bootstrap();
  unawaited(bootstrapFuture);
  // `_bootstrap` retourne `Future<void>` et catch ses erreurs en interne.
  // On mappe vers `Future<bool>` en re-checkant `Firebase.app()` apres
  // resolution : true si l'init a vraiment reussi, false si stub options
  // ou crash silencieux. Les consommateurs de `firebaseReadyProvider`
  // gardent ainsi un signal fiable.
  final firebaseReadyFuture = () async {
    await bootstrapFuture;
    try {
      Firebase.app();
      return true;
    } catch (_) {
      return false;
    }
  }();
  logPerfEvent('boot.runApp');
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        firebaseReadyProvider.overrideWith((ref) => firebaseReadyFuture),
      ],
      child: const ValideApp(),
    ),
  );
}

/// Init Firebase + Crashlytics + smoke test Firestore (Story 0.21 AC2).
/// Si l'init Firebase échoue (ex. options stub), on continue silencieusement
/// — les providers Firebase exposeront `firebaseAvailableProvider == false`.
Future<void> _bootstrap() async {
  try {
    await logPerf(
      'boot.firebase.initializeApp',
      () => Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
    );
    _setupCrashlytics();
    AppLogger.bindCrashlytics(FirebaseCrashlytics.instance);
    AppLogger.i('Firebase bootstrap OK');
    logPerfEvent('boot.firebase.ready');

    // google_sign_in v7 Android exige initialize() avec serverClientId avant
    // tout appel authenticate(). Non bloquant si ca echoue (iOS n'en a pas
    // besoin, et on continue sans Google Sign-In).
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: _kGoogleServerClientId,
      );
      AppLogger.i('GoogleSignIn.initialize OK');
    } catch (e) {
      AppLogger.w('GoogleSignIn.initialize failed (non-blocking): $e');
    }
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
