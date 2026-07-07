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

import '../logging/app_logger.dart';

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

/// Future qui resout `true` quand `Firebase.initializeApp()` a fini avec
/// succes, `false` si l'init a echoue ou n'a jamais ete tentee.
///
/// Override-e dans `main.dart` avec la Future reelle de `_bootstrap()`. En
/// dehors de `main.dart` (tests widgets, tests unitaires), le defaut `false`
/// signifie « Firebase indisponible » — les consommateurs critiques skippent
/// proprement sans throw.
///
/// Pourquoi : `main.dart` lance `_bootstrap()` en `unawaited` (~2.9s sur
/// device entree de gamme) en parallele de `runApp` pour ne pas retarder
/// l'affichage du splash. Tout provider qui touche Firestore/Auth AVANT que
/// cette Future ne resolve throw `[core/no-app] No Firebase App ...`. Les
/// consommateurs critiques au boot (splash warm-up catalogue, catalogue
/// check du router) doivent `await ref.watch(firebaseReadyProvider.future)`
/// avant d'instancier le repository.
final firebaseReadyProvider = FutureProvider<bool>((ref) async => false);

/// Région Cloud Functions cible. Confirmée après Story 0.20 R3 (benchmark
/// latence Cameroun → europe-west1).
const String _functionsRegion = 'europe-west1';

/// Auth — utilisateur courant + sign-in. Lazy.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Audit NEW-BUG-17 2026-06-13 — Stream du `User?` courant qui propage les
/// changements d'authentification (signIn, signOut, anonymous link).
///
/// Pourquoi : avant ce provider, `profileCompletionProvider` lisait
/// `firebaseAuthProvider.currentUser?.uid` directement. Comme
/// `firebaseAuthProvider` est un `Provider` STATIQUE (l'instance
/// `FirebaseAuth` ne change jamais), Riverpod ne rebuild PAS les watchers
/// quand `currentUser` change. Resultat : apres `signInAnonymously()` au
/// step 5, le router restait bloque avec uid=null.
///
/// `userChanges()` (et non `authStateChanges()`) : `authStateChanges` ne
/// fire PAS lors d'un `linkWithCredential()` car ce n'est pas un
/// sign-in/sign-out. `userChanges()` couvre signIn, signOut, linkWithCredential,
/// unlink, updateProfile — nécessaire pour que `_AccountInfoCard` (qui lit
/// `user.isAnonymous` + `user.providerData`) se mette a jour apres le linking
/// Google/Apple sur un compte anonyme.
final currentUserProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).userChanges();
});

/// Taille du cache Firestore en octets. 40 MB borne adaptee aux telephones
/// modestes du marche cible (NFR-1 stockage limite, NFR-2 perf).
const int _firestoreCacheSizeBytes = 40 * 1024 * 1024;

/// Firestore — cache offline 40 MB persistance activee (Story 0.7, ADR-010).
///
/// Les `settings` doivent etre appliques AVANT tout `get()` / `snapshots()` :
/// Firestore lock les settings au premier acces. Le Provider est cache par
/// Riverpod donc le bloc s'execute une seule fois.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  final firestore = FirebaseFirestore.instance;
  firestore.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: _firestoreCacheSizeBytes,
  );
  AppLogger.i('Firestore cache: 40MB, persistence on');
  return firestore;
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
