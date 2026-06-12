// Story 1.5 AC1 — Test unitaire enum ProfileCompletionState (refactor E1bis-9).
//
// Le getter `nextOnboardingRoute` a ete supprime (le router consomme
// uniquement `isComplete`). On verifie `isComplete` sur les 5 etats.

import 'package:flutter_test/flutter_test.dart';

import 'package:valide_school/features/onboarding/domain/profile_completion_state.dart';

void main() {
  group('ProfileCompletionState.isComplete', () {
    test('complete only', () {
      expect(ProfileCompletionState.complete.isComplete, isTrue);
      for (final state in ProfileCompletionState.values
          .where((s) => s != ProfileCompletionState.complete)) {
        expect(state.isComplete, isFalse,
            reason: '$state should not be complete');
      }
    });
  });
}
