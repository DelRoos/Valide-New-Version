// Story E1bis-9 — Tests redirect router simplifie.
//
// Epic 1 routes legacy + smart resume + flag useNewOnboardingFlow ont ete
// supprimes (cf. lib/core/routing/app_router.dart). Le routing se reduit a 4
// regles : bypass system, catalogue check, anti-replay /onboarding/v2 si
// profil complet, garde profil-incomplet vers /onboarding/v2.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:valide_school/core/routing/app_router.dart';
import 'package:valide_school/features/onboarding/domain/profile_completion_state.dart';

AsyncValue<bool> _catalogueOk(bool ok) => AsyncValue.data(ok);
AsyncValue<bool> _catalogueLoading() => const AsyncValue.loading();
AsyncValue<bool> _catalogueError() =>
    AsyncValue.error(Exception('boom'), StackTrace.current);

AsyncValue<ProfileCompletionState> _completionData(
        ProfileCompletionState state) =>
    AsyncValue.data(state);
AsyncValue<ProfileCompletionState> _completionLoading() =>
    const AsyncValue.loading();

void main() {
  group('evaluateRedirect — Story E1bis-9', () {
    test('(a) "/" -> bypass (null)', () {
      final result = evaluateRedirect(
        location: '/',
        catalogueCheck: _catalogueOk(true),
        profileCompletion: _completionData(ProfileCompletionState.complete),
      );
      expect(result, isNull);
    });

    test('(b) "/splash" -> bypass', () {
      final result = evaluateRedirect(
        location: '/splash',
        catalogueCheck: _catalogueOk(true),
        profileCompletion: _completionData(ProfileCompletionState.complete),
      );
      expect(result, isNull);
    });

    test('(c) "/_crash" debug -> bypass', () {
      final result = evaluateRedirect(
        location: '/_crash',
        catalogueCheck: _catalogueOk(true),
        profileCompletion: _completionData(ProfileCompletionState.complete),
      );
      expect(result, isNull);
    });

    test('(d) Catalogue vide -> /catalogue-waiting', () {
      final result = evaluateRedirect(
        location: '/dashboard',
        catalogueCheck: _catalogueOk(false),
        profileCompletion: _completionData(ProfileCompletionState.complete),
      );
      expect(result, '/catalogue-waiting');
    });

    test('(e) Catalogue erreur (offline+vide) -> /catalogue-waiting', () {
      final result = evaluateRedirect(
        location: '/dashboard',
        catalogueCheck: _catalogueError(),
        profileCompletion: _completionData(ProfileCompletionState.complete),
      );
      expect(result, '/catalogue-waiting');
    });

    test('(f) Catalogue loading + dashboard -> null (laisse passer)', () {
      final result = evaluateRedirect(
        location: '/dashboard',
        catalogueCheck: _catalogueLoading(),
        profileCompletion: _completionData(ProfileCompletionState.complete),
      );
      expect(result, isNull);
    });

    test('(g) /catalogue-waiting + catalogue redevient OK -> /', () {
      final result = evaluateRedirect(
        location: '/catalogue-waiting',
        catalogueCheck: _catalogueOk(true),
        profileCompletion: _completionData(ProfileCompletionState.complete),
      );
      expect(result, '/');
    });

    test('(h) Profil incomplet sur route metier -> /onboarding/v2', () {
      final result = evaluateRedirect(
        location: '/dashboard',
        catalogueCheck: _catalogueOk(true),
        profileCompletion:
            _completionData(ProfileCompletionState.filiereMissing),
      );
      expect(result, '/onboarding/v2');
    });

    test('(i) Profil complet + dashboard -> null', () {
      final result = evaluateRedirect(
        location: '/dashboard',
        catalogueCheck: _catalogueOk(true),
        profileCompletion: _completionData(ProfileCompletionState.complete),
      );
      expect(result, isNull);
    });

    test(
        '(j) Anti-replay /onboarding/v2 si profil complet -> /dashboard '
        '(audit 2026-06-13 : bypass /splash transit pour flow visiteur)',
        () {
      // Avant l'audit, retournait `/` qui mappe vers /splash. Resultat pour
      // le flow visiteur : transit /splash visible (2.1s animation) au lieu
      // d'aller direct sur /dashboard. Cf. evaluateRedirect rule 3.
      final result = evaluateRedirect(
        location: '/onboarding/v2',
        catalogueCheck: _catalogueOk(true),
        profileCompletion: _completionData(ProfileCompletionState.complete),
      );
      expect(result, '/dashboard');
    });

    test('(k) /onboarding/v2 si profil incomplet -> null (laisse passer)', () {
      final result = evaluateRedirect(
        location: '/onboarding/v2',
        catalogueCheck: _catalogueOk(true),
        profileCompletion:
            _completionData(ProfileCompletionState.filiereMissing),
      );
      expect(result, isNull);
    });

    test(
        '(l) Profil loading + route metier -> null (audit 2026-06-13 : laisse '
        'passer pour fixer la race condition visiteur flush -> dashboard)',
        () {
      // Avant l'audit, le loading etait traite comme fail-safe -> redirect
      // /onboarding/v2. Resultat : apres signInAnonymously + flush + go(
      // /dashboard), le stream watchProfile n'a pas encore emis ; le redirect
      // confond loading et incomplete -> bounce. Maintenant on differencie
      // explicitement les 3 cas (data/loading/error) — voir _shouldBlock.
      final result = evaluateRedirect(
        location: '/dashboard',
        catalogueCheck: _catalogueOk(true),
        profileCompletion: _completionLoading(),
      );
      expect(result, isNull);
    });

    test('(m) Profil error + route metier -> /onboarding/v2 (safe fallback)',
        () {
      final result = evaluateRedirect(
        location: '/dashboard',
        catalogueCheck: _catalogueOk(true),
        profileCompletion: AsyncValue.error(
          Exception('stream-error'),
          StackTrace.current,
        ),
      );
      expect(result, '/onboarding/v2');
    });
  });
}
