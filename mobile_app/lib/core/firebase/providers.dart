// Providers Riverpod lazy pour les modules Firebase. Cf. ADR-003 + Story 0.6.
//
// Règle NFR-3 : aucun module Firebase autre que `firebase_core` + `crashlytics`
// n'est importé dans `main.dart`. Chaque module est instancié à la 1ère lecture
// du provider — pas avant.
//
// Story 0.6 Phase A : `Firebase.app()` peut lever `FirebaseException` tant que
// Phase B (flutterfire configure) n'est pas faite. Les providers sont écrits
// pour echouer proprement avec `firebaseUnavailableProvider` qui expose un
// flag — les écrans qui dépendent de Firebase doivent gracefully degrader.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `true` si l'app Firebase par défaut est initialisée (Phase B faite).
/// Les écrans consommateurs lisent ce flag pour basculer en degraded mode.
final firebaseAvailableProvider = Provider<bool>((ref) {
  try {
    Firebase.app();
    return true;
  } catch (_) {
    return false;
  }
});

/// Région Cloud Functions cible. Confirmée après Story 0.20 R3 (benchmark
/// latence Cameroun → europe-west1).
const String _functionsRegion = 'europe-west1';

/// Auth — utilisateur courant + sign-in. Lazy.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Firestore — cache offline activé automatiquement (cf. ADR-010).
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Storage — buckets media. Lazy.
final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

/// Cloud Functions — callables. Région figée europe-west1.
final cloudFunctionsProvider = Provider<FirebaseFunctions>((ref) {
  return FirebaseFunctions.instanceFor(region: _functionsRegion);
});

/// Messaging — FCM. Lazy.
final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

/// Analytics — events tracking. Lazy.
final firebaseAnalyticsProvider = Provider<FirebaseAnalytics>((ref) {
  return FirebaseAnalytics.instance;
});

/// Remote Config — feature flags + texte distant. Lazy.
final firebaseRemoteConfigProvider = Provider<FirebaseRemoteConfig>((ref) {
  return FirebaseRemoteConfig.instance;
});

/// App Check — protection contre les requêtes non autorisées. Debug provider
/// en Story 0.6 ; enforce activé en Story 0.8.
final firebaseAppCheckProvider = Provider<FirebaseAppCheck>((ref) {
  return FirebaseAppCheck.instance;
});

/// Firebase AI Logic (Gemini Developer API). Modèle initial : `gemini-2.5-flash`
/// (rapide + économique, suffisant pour cas pédagogiques). À ajuster en E3 / E6
/// après mesures qualité.
///
/// ADR-012 : tous les appels IA sont client-side, pas de Cloud Function IA
/// (askTutor, chatMessage, correctMode1 retirés).
final firebaseAIProvider = Provider<GenerativeModel>((ref) {
  return FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash');
});
