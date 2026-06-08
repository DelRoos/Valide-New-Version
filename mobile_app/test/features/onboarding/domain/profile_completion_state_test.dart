// Story 1.5 AC1 — Test unitaire enum ProfileCompletionState.
//
// Verifie le mapping nextOnboardingRoute + isComplete pour les 5 etats.

import 'package:flutter_test/flutter_test.dart';

import 'package:valide_school/features/onboarding/domain/profile_completion_state.dart';

void main() {
  group('ProfileCompletionState.nextOnboardingRoute', () {
    test('subsystemMissing -> /onboarding/subsystem', () {
      expect(
        ProfileCompletionState.subsystemMissing.nextOnboardingRoute,
        '/onboarding/subsystem',
      );
    });

    test('filiereMissing -> /onboarding/profile/filiere', () {
      expect(
        ProfileCompletionState.filiereMissing.nextOnboardingRoute,
        '/onboarding/profile/filiere',
      );
    });

    test('niveauMissing -> /onboarding/profile/niveau', () {
      expect(
        ProfileCompletionState.niveauMissing.nextOnboardingRoute,
        '/onboarding/profile/niveau',
      );
    });

    test('serieMissing -> /onboarding/profile/serie', () {
      expect(
        ProfileCompletionState.serieMissing.nextOnboardingRoute,
        '/onboarding/profile/serie',
      );
    });

    test('complete -> /', () {
      expect(ProfileCompletionState.complete.nextOnboardingRoute, '/');
    });
  });

  group('ProfileCompletionState.isComplete', () {
    test('complete only', () {
      expect(ProfileCompletionState.complete.isComplete, isTrue);
      for (final state in ProfileCompletionState.values
          .where((s) => s != ProfileCompletionState.complete)) {
        expect(state.isComplete, isFalse, reason: '$state should not be complete');
      }
    });
  });
}
