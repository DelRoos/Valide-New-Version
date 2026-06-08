// Story 1.5 AC2 — Tests integration de la logique redirect du router.
//
// Pattern : la logique redirect est extraite dans `evaluateRedirect()`
// (@visibleForTesting), donc on teste la fonction pure directement sans
// monter un MaterialApp.router complet.
//
// 5 cas AC2 (a-e) + 4 cas bonus pour couvrir les paliers ProfileCompletionState
// + le bypass /catalogue-waiting + le cas catalogue empty redirige.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:valide_school/core/routing/app_router.dart';
import 'package:valide_school/features/onboarding/domain/profile_completion_state.dart';

AsyncValue<bool> _catalogueOk = const AsyncData(true);
const AsyncValue<bool> _catalogueEmpty = AsyncData(false);

AsyncValue<ProfileCompletionState> _completion(ProfileCompletionState s) =>
    AsyncData(s);

void main() {
  group('evaluateRedirect — Story 1.5 AC2', () {
    test('(a) subSystem null + /hello -> /onboarding/subsystem', () {
      final result = evaluateRedirect(
        location: '/hello',
        catalogueCheck: _catalogueOk,
        hasSubSystem: false,
        profileCompletion:
            _completion(ProfileCompletionState.subsystemMissing),
      );
      expect(result, '/onboarding/subsystem');
    });

    test('(b) subSystem OK + profil incomplet + /lessons/maths -> '
        '/onboarding/profile/filiere', () {
      final result = evaluateRedirect(
        location: '/lessons/maths_derivees',
        catalogueCheck: _catalogueOk,
        hasSubSystem: true,
        profileCompletion: _completion(ProfileCompletionState.filiereMissing),
      );
      expect(result, '/onboarding/profile/filiere');
    });

    test('(c) profil complet + /hello -> null (passe)', () {
      final result = evaluateRedirect(
        location: '/hello',
        catalogueCheck: _catalogueOk,
        hasSubSystem: true,
        profileCompletion: _completion(ProfileCompletionState.complete),
      );
      expect(result, isNull);
    });

    test('(d) profil complet + /onboarding/profile/recap -> null '
        '(bypass /onboarding/*)', () {
      final result = evaluateRedirect(
        location: '/onboarding/profile/recap',
        catalogueCheck: _catalogueOk,
        hasSubSystem: true,
        profileCompletion: _completion(ProfileCompletionState.complete),
      );
      expect(result, isNull);
    });

    test('(e) subSystem null + /_crash -> null (bypass /_*)', () {
      final result = evaluateRedirect(
        location: '/_crash',
        catalogueCheck: _catalogueOk,
        hasSubSystem: false,
        profileCompletion:
            _completion(ProfileCompletionState.subsystemMissing),
      );
      expect(result, isNull);
    });
  });

  group('evaluateRedirect — couverture supplementaire', () {
    test('catalogue empty + /hello -> /catalogue-waiting (prioritaire)', () {
      final result = evaluateRedirect(
        location: '/hello',
        catalogueCheck: _catalogueEmpty,
        hasSubSystem: true,
        profileCompletion: _completion(ProfileCompletionState.complete),
      );
      expect(result, '/catalogue-waiting');
    });

    test('catalogue empty + /catalogue-waiting -> null (deja sur place)', () {
      final result = evaluateRedirect(
        location: '/catalogue-waiting',
        catalogueCheck: _catalogueEmpty,
        hasSubSystem: false,
        profileCompletion:
            _completion(ProfileCompletionState.subsystemMissing),
      );
      expect(result, isNull);
    });

    test('Story 1.2 anti-replay : subSystem present + /onboarding/subsystem '
        '-> /', () {
      final result = evaluateRedirect(
        location: '/onboarding/subsystem',
        catalogueCheck: _catalogueOk,
        hasSubSystem: true,
        profileCompletion: _completion(ProfileCompletionState.complete),
      );
      expect(result, '/');
    });

    test('niveauMissing -> /onboarding/profile/niveau', () {
      final result = evaluateRedirect(
        location: '/lessons/maths',
        catalogueCheck: _catalogueOk,
        hasSubSystem: true,
        profileCompletion: _completion(ProfileCompletionState.niveauMissing),
      );
      expect(result, '/onboarding/profile/niveau');
    });

    test('serieMissing -> /onboarding/profile/serie', () {
      final result = evaluateRedirect(
        location: '/dashboard',
        catalogueCheck: _catalogueOk,
        hasSubSystem: true,
        profileCompletion: _completion(ProfileCompletionState.serieMissing),
      );
      expect(result, '/onboarding/profile/serie');
    });

    test('profileCompletion loading -> null (laisse passer, evite flash)', () {
      final result = evaluateRedirect(
        location: '/hello',
        catalogueCheck: _catalogueOk,
        hasSubSystem: true,
        profileCompletion:
            const AsyncLoading<ProfileCompletionState>(),
      );
      expect(result, isNull);
    });

    test('profileCompletion error -> /onboarding/subsystem (fail-safe)', () {
      final result = evaluateRedirect(
        location: '/hello',
        catalogueCheck: _catalogueOk,
        hasSubSystem: true,
        profileCompletion: AsyncError<ProfileCompletionState>(
          Exception('boom'),
          StackTrace.current,
        ),
      );
      expect(result, '/onboarding/subsystem');
    });

    test('catalogue loading -> bypass (ne bloque pas)', () {
      final result = evaluateRedirect(
        location: '/hello',
        catalogueCheck: const AsyncLoading<bool>(),
        hasSubSystem: true,
        profileCompletion: _completion(ProfileCompletionState.complete),
      );
      expect(result, isNull);
    });

    test('catalogue error -> /catalogue-waiting (fail-safe)', () {
      final result = evaluateRedirect(
        location: '/hello',
        catalogueCheck: AsyncError<bool>(
          Exception('firestore down'),
          StackTrace.current,
        ),
        hasSubSystem: true,
        profileCompletion: _completion(ProfileCompletionState.complete),
      );
      expect(result, '/catalogue-waiting');
    });
  });
}
