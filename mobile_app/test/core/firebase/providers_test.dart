import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valide_school/core/firebase/providers.dart';

/// Tests Story 0.6 Phase A : valide que les providers Firebase existent et
/// que `firebaseAvailableProvider` retourne `false` tant que
/// `Firebase.initializeApp()` n'a pas été appelé (cas de cette suite de tests).
void main() {
  group('firebaseAvailableProvider', () {
    test('retourne false sans Firebase init (cas tests + Phase A)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(firebaseAvailableProvider), isFalse);
    });
  });

  group('Providers Firebase — symbol présents', () {
    test('tous les providers sont déclarés', () {
      // Smoke : on vérifie que les symbols existent (compilation OK)
      // sans les `read` pour éviter d'appeler `Firebase.app()` sans init.
      expect(firebaseAuthProvider, isNotNull);
      expect(firestoreProvider, isNotNull);
      expect(firebaseStorageProvider, isNotNull);
      expect(cloudFunctionsProvider, isNotNull);
      expect(firebaseMessagingProvider, isNotNull);
      expect(firebaseAnalyticsProvider, isNotNull);
      expect(firebaseRemoteConfigProvider, isNotNull);
      expect(firebaseAppCheckProvider, isNotNull);
      expect(firebaseAIProvider, isNotNull);
    });
  });

  // ===================================================================
  // Story 0.7 — Cache offline Firestore (AC2)
  // ===================================================================
  // Le test d'integration AC2 (lecture cache apres coupure reseau) demande
  // Firebase initialise + reseau pilotable. Il est code ici comme procedure
  // documentee a executer manuellement sur emulateur Android apres Phase B
  // (modules Firebase Console actifs). En CI il reste skip pour eviter les
  // faux echecs (token App Check absent, reseau lab).
  //
  // Procedure manuelle :
  //   1. `flutter run` sur emulateur Android
  //   2. Ouvrir /_smoketest si dispo, sinon depuis la console Firebase
  //      ajouter manuellement un doc `_smoketest/launch`
  //   3. Couper le wifi sur l'emulateur (adb shell svc wifi disable)
  //   4. Re-lire le doc → la lecture doit reussir et
  //      `snapshot.metadata.isFromCache == true`
  //   5. Rallumer le wifi (adb shell svc wifi enable)
  group('Firestore cache offline (AC2)', () {
    test(
      'lecture cache apres coupure reseau retourne isFromCache=true',
      () {
        // Procedure ci-dessus. Non automatisable sans Firebase init reel.
      },
      skip: 'AC2 = procedure manuelle sur device, voir commentaire ci-dessus.',
    );
  });
}
