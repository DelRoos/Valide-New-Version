// Story 1.5 AC2 + Story 1.8 smart resume — Tests integration redirect router.
//
// Pattern : la logique redirect est extraite dans `evaluateRedirect()`
// (@visibleForTesting), donc on teste la fonction pure directement sans
// monter un MaterialApp.router complet.
//
// Story 1.8 : ajout du parametre `flowState` pour le smart resume + 3 nouveaux
// cas (filiere set -> /niveau, filiere+niveau set -> /serie, tout set -> /recap).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:valide_school/core/routing/app_router.dart';
import 'package:valide_school/features/onboarding/domain/onboarding_flow_state.dart';
import 'package:valide_school/features/onboarding/domain/profile_completion_state.dart';

AsyncValue<bool> _catalogueOk = const AsyncData(true);
const AsyncValue<bool> _catalogueEmpty = AsyncData(false);

AsyncValue<ProfileCompletionState> _completion(ProfileCompletionState s) =>
    AsyncData(s);

const _emptyFlow = OnboardingFlowState();

void main() {
  group('evaluateRedirect — Story 1.5 AC2', () {
    test('(a) subSystem null + /hello -> /onboarding/subsystem', () {
      final result = evaluateRedirect(
        location: '/hello',
        catalogueCheck: _catalogueOk,
        hasSubSystem: false,
        profileCompletion:
            _completion(ProfileCompletionState.subsystemMissing),
        flowState: _emptyFlow,
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
        flowState: _emptyFlow,
      );
      expect(result, '/onboarding/profile/filiere');
    });

    test('(c) profil complet + /hello -> null (passe)', () {
      final result = evaluateRedirect(
        location: '/hello',
        catalogueCheck: _catalogueOk,
        hasSubSystem: true,
        profileCompletion: _completion(ProfileCompletionState.complete),
        flowState: _emptyFlow,
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
        flowState: _emptyFlow,
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
        flowState: _emptyFlow,
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
        flowState: _emptyFlow,
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
        flowState: _emptyFlow,
      );
      expect(result, isNull);
    });

    test('Story 1bis-2bis fix : catalogue OK + /catalogue-waiting -> / '
        '(eject post-retry succes)', () {
      final result = evaluateRedirect(
        location: '/catalogue-waiting',
        catalogueCheck: _catalogueOk,
        hasSubSystem: false,
        profileCompletion:
            _completion(ProfileCompletionState.subsystemMissing),
        flowState: _emptyFlow,
      );
      expect(result, '/');
    });

    test('Story 1.2 anti-replay : subSystem present + /onboarding/subsystem '
        '-> /', () {
      final result = evaluateRedirect(
        location: '/onboarding/subsystem',
        catalogueCheck: _catalogueOk,
        hasSubSystem: true,
        profileCompletion: _completion(ProfileCompletionState.complete),
        flowState: _emptyFlow,
      );
      expect(result, '/');
    });

    test('niveauMissing -> /onboarding/profile/niveau', () {
      final result = evaluateRedirect(
        location: '/lessons/maths',
        catalogueCheck: _catalogueOk,
        hasSubSystem: true,
        profileCompletion: _completion(ProfileCompletionState.niveauMissing),
        flowState: _emptyFlow,
      );
      expect(result, '/onboarding/profile/niveau');
    });

    test('serieMissing -> /onboarding/profile/serie', () {
      final result = evaluateRedirect(
        location: '/dashboard',
        catalogueCheck: _catalogueOk,
        hasSubSystem: true,
        profileCompletion: _completion(ProfileCompletionState.serieMissing),
        flowState: _emptyFlow,
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
        flowState: _emptyFlow,
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
        flowState: _emptyFlow,
      );
      expect(result, '/onboarding/subsystem');
    });

    test('catalogue loading -> bypass (ne bloque pas)', () {
      final result = evaluateRedirect(
        location: '/hello',
        catalogueCheck: const AsyncLoading<bool>(),
        hasSubSystem: true,
        profileCompletion: _completion(ProfileCompletionState.complete),
        flowState: _emptyFlow,
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
        flowState: _emptyFlow,
      );
      expect(result, '/catalogue-waiting');
    });
  });

  group('evaluateRedirect — Story 1.8 smart resume', () {
    test(
      '(smart-a) filiereMissing Firestore + flowState.filiereId set -> '
      '/onboarding/profile/niveau (saute /filiere)',
      () {
        final result = evaluateRedirect(
          location: '/dashboard',
          catalogueCheck: _catalogueOk,
          hasSubSystem: true,
          profileCompletion:
              _completion(ProfileCompletionState.filiereMissing),
          flowState: const OnboardingFlowState(filiereId: 'generale'),
        );
        expect(result, '/onboarding/profile/niveau');
      },
    );

    test(
      '(smart-b) filiereMissing Firestore + flowState.filiere+niveau set -> '
      '/onboarding/profile/serie',
      () {
        final result = evaluateRedirect(
          location: '/dashboard',
          catalogueCheck: _catalogueOk,
          hasSubSystem: true,
          profileCompletion:
              _completion(ProfileCompletionState.filiereMissing),
          flowState: const OnboardingFlowState(
            filiereId: 'generale',
            niveauId: 'francophone_terminale',
          ),
        );
        expect(result, '/onboarding/profile/serie');
      },
    );

    test(
      '(smart-c) filiereMissing Firestore + flowState complet -> '
      '/onboarding/profile/recap (cas kill avant tap "C est ma classe")',
      () {
        final result = evaluateRedirect(
          location: '/dashboard',
          catalogueCheck: _catalogueOk,
          hasSubSystem: true,
          profileCompletion:
              _completion(ProfileCompletionState.filiereMissing),
          flowState: const OnboardingFlowState(
            filiereId: 'generale',
            niveauId: 'francophone_terminale',
            serieId: 'francophone_terminale_d',
          ),
        );
        expect(result, '/onboarding/profile/recap');
      },
    );

    test(
      '(smart-d) profil complet Firestore + flowState complet -> null '
      '(profileCompletion prime, flowState ignored)',
      () {
        final result = evaluateRedirect(
          location: '/dashboard',
          catalogueCheck: _catalogueOk,
          hasSubSystem: true,
          profileCompletion: _completion(ProfileCompletionState.complete),
          flowState: const OnboardingFlowState(
            filiereId: 'generale',
            niveauId: 'francophone_terminale',
            serieId: 'francophone_terminale_d',
          ),
        );
        expect(result, isNull);
      },
    );
  });

  group('evaluateRedirect — Story E1bis-2bis feature flag refonte (route unique)', () {
    test(
        '(e1bis-a) flag ON + /onboarding/subsystem -> /onboarding/v2',
        () {
      final result = evaluateRedirect(
        location: '/onboarding/subsystem',
        catalogueCheck: _catalogueOk,
        hasSubSystem: false,
        profileCompletion:
            _completion(ProfileCompletionState.subsystemMissing),
        flowState: _emptyFlow,
        useNewOnboardingFlow: true,
      );
      expect(result, '/onboarding/v2');
    });

    test(
        '(e1bis-b) flag ON + profil complet + /onboarding/v2 -> /'
        ' (sortie naturelle post-completion)', () {
      final result = evaluateRedirect(
        location: '/onboarding/v2',
        catalogueCheck: _catalogueOk,
        hasSubSystem: true,
        profileCompletion: _completion(ProfileCompletionState.complete),
        flowState: _emptyFlow,
        useNewOnboardingFlow: true,
      );
      expect(result, '/');
    });

    test(
        '(e1bis-b2) flag ON + hasSubSystem + profil incomplet + /onboarding/v2'
        ' -> null (mid-flow, on reste sur le shell)', () {
      final result = evaluateRedirect(
        location: '/onboarding/v2',
        catalogueCheck: _catalogueOk,
        hasSubSystem: true,
        profileCompletion: _completion(ProfileCompletionState.filiereMissing),
        flowState: _emptyFlow,
        useNewOnboardingFlow: true,
      );
      expect(result, isNull);
    });

    test(
        '(e1bis-c) flag OFF + /onboarding/subsystem -> null (preservation Epic 1)',
        () {
      final result = evaluateRedirect(
        location: '/onboarding/subsystem',
        catalogueCheck: _catalogueOk,
        hasSubSystem: false,
        profileCompletion:
            _completion(ProfileCompletionState.subsystemMissing),
        flowState: _emptyFlow,
        useNewOnboardingFlow: false,
      );
      expect(result, isNull);
    });

    test(
        '(e1bis-c2) flag OFF + hasSubSystem + /onboarding/v2 -> /'
        ' (deep link rejete cohabitation Epic 1)', () {
      final result = evaluateRedirect(
        location: '/onboarding/v2',
        catalogueCheck: _catalogueOk,
        hasSubSystem: true,
        profileCompletion: _completion(ProfileCompletionState.complete),
        flowState: _emptyFlow,
        useNewOnboardingFlow: false,
      );
      expect(result, '/');
    });
  });

  group('evaluateRedirect — fix routing E1bis englobe Epic 1 (2026-06-12)', () {
    test(
        '(englobe-a) flag ON + /onboarding/profile/filiere -> /onboarding/v2',
        () {
      final result = evaluateRedirect(
        location: '/onboarding/profile/filiere',
        catalogueCheck: _catalogueOk,
        hasSubSystem: true,
        profileCompletion: _completion(ProfileCompletionState.filiereMissing),
        flowState: _emptyFlow,
        useNewOnboardingFlow: true,
      );
      expect(result, '/onboarding/v2');
    });

    test(
        '(englobe-b) flag ON + /onboarding/profile/niveau -> /onboarding/v2',
        () {
      final result = evaluateRedirect(
        location: '/onboarding/profile/niveau',
        catalogueCheck: _catalogueOk,
        hasSubSystem: true,
        profileCompletion: _completion(ProfileCompletionState.niveauMissing),
        flowState: _emptyFlow,
        useNewOnboardingFlow: true,
      );
      expect(result, '/onboarding/v2');
    });

    test(
        '(englobe-c) flag ON + /onboarding/profile/serie -> /onboarding/v2',
        () {
      final result = evaluateRedirect(
        location: '/onboarding/profile/serie',
        catalogueCheck: _catalogueOk,
        hasSubSystem: true,
        profileCompletion: _completion(ProfileCompletionState.serieMissing),
        flowState: _emptyFlow,
        useNewOnboardingFlow: true,
      );
      expect(result, '/onboarding/v2');
    });

    test(
        '(englobe-d) flag ON + /onboarding/profile/recap -> /onboarding/v2',
        () {
      final result = evaluateRedirect(
        location: '/onboarding/profile/recap',
        catalogueCheck: _catalogueOk,
        hasSubSystem: true,
        profileCompletion: _completion(ProfileCompletionState.complete),
        flowState: _emptyFlow,
        useNewOnboardingFlow: true,
      );
      expect(result, '/onboarding/v2');
    });

    test(
        '(englobe-e) flag ON + /onboarding/account -> /onboarding/v2',
        () {
      final result = evaluateRedirect(
        location: '/onboarding/account',
        catalogueCheck: _catalogueOk,
        hasSubSystem: true,
        profileCompletion: _completion(ProfileCompletionState.complete),
        flowState: _emptyFlow,
        useNewOnboardingFlow: true,
      );
      expect(result, '/onboarding/v2');
    });

    test(
        '(englobe-f) flag ON + /onboarding/school -> /onboarding/v2',
        () {
      final result = evaluateRedirect(
        location: '/onboarding/school',
        catalogueCheck: _catalogueOk,
        hasSubSystem: true,
        profileCompletion: _completion(ProfileCompletionState.complete),
        flowState: _emptyFlow,
        useNewOnboardingFlow: true,
      );
      expect(result, '/onboarding/v2');
    });

    test(
        '(englobe-g) flag ON + /dashboard + profil incomplet -> /onboarding/v2'
        ' (smart resume reroute)', () {
      final result = evaluateRedirect(
        location: '/dashboard',
        catalogueCheck: _catalogueOk,
        hasSubSystem: true,
        profileCompletion: _completion(ProfileCompletionState.niveauMissing),
        flowState: _emptyFlow,
        useNewOnboardingFlow: true,
      );
      expect(result, '/onboarding/v2');
    });

    test(
        '(englobe-h) flag ON + /dashboard + profil complet -> null'
        ' (pas de redirect, acces metier ok)', () {
      final result = evaluateRedirect(
        location: '/dashboard',
        catalogueCheck: _catalogueOk,
        hasSubSystem: true,
        profileCompletion: _completion(ProfileCompletionState.complete),
        flowState: _emptyFlow,
        useNewOnboardingFlow: true,
      );
      expect(result, isNull);
    });

    test(
        '(englobe-i) flag OFF + /onboarding/profile/filiere -> null'
        ' (preservation Epic 1, bypass /onboarding/*)', () {
      final result = evaluateRedirect(
        location: '/onboarding/profile/filiere',
        catalogueCheck: _catalogueOk,
        hasSubSystem: true,
        profileCompletion: _completion(ProfileCompletionState.filiereMissing),
        flowState: _emptyFlow,
        useNewOnboardingFlow: false,
      );
      expect(result, isNull);
    });
  });
}
