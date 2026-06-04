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
}
