// Tests exhaustifs de evaluateRedirect.
//
// Couverture des 4 règles dans l'ordre d'évaluation :
//   1. Bypass inconditionnel (routes système + debug).
//   2. Catalogue check prioritaire.
//   3. Anti-replay /onboarding si profil complet (sauf upgradeInProgress).
//   4. Garde profil-incomplet → /onboarding (sauf upgradeInProgress).
//
// Le groupe "Story E1bis-9" garde les tests originaux. Les groupes suivants
// couvrent les cas manquants, notamment upgradeInProgress (fix ProfileGuestBody).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:valide_school/core/routing/app_router.dart';
import 'package:valide_school/core/routing/app_routes.dart';
import 'package:valide_school/features/account/domain/account_deletion_failure.dart';
import 'package:valide_school/features/account/domain/account_deletion_status.dart';
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
        location: AppRoutes.dashboard,
        catalogueCheck: _catalogueOk(false),
        profileCompletion: _completionData(ProfileCompletionState.complete),
      );
      expect(result, AppRoutes.catalogueWaiting);
    });

    test('(e) Catalogue erreur (offline+vide) -> /catalogue-waiting', () {
      final result = evaluateRedirect(
        location: AppRoutes.dashboard,
        catalogueCheck: _catalogueError(),
        profileCompletion: _completionData(ProfileCompletionState.complete),
      );
      expect(result, AppRoutes.catalogueWaiting);
    });

    test('(f) Catalogue loading + dashboard -> null (laisse passer)', () {
      final result = evaluateRedirect(
        location: AppRoutes.dashboard,
        catalogueCheck: _catalogueLoading(),
        profileCompletion: _completionData(ProfileCompletionState.complete),
      );
      expect(result, isNull);
    });

    test('(g) /catalogue-waiting + catalogue redevient OK -> /', () {
      final result = evaluateRedirect(
        location: AppRoutes.catalogueWaiting,
        catalogueCheck: _catalogueOk(true),
        profileCompletion: _completionData(ProfileCompletionState.complete),
      );
      expect(result, '/');
    });

    test('(h) Profil incomplet sur route metier -> /onboarding', () {
      final result = evaluateRedirect(
        location: AppRoutes.dashboard,
        catalogueCheck: _catalogueOk(true),
        profileCompletion:
            _completionData(ProfileCompletionState.filiereMissing),
      );
      expect(result, AppRoutes.onboarding);
    });

    test('(i) Profil complet + dashboard -> null', () {
      final result = evaluateRedirect(
        location: AppRoutes.dashboard,
        catalogueCheck: _catalogueOk(true),
        profileCompletion: _completionData(ProfileCompletionState.complete),
      );
      expect(result, isNull);
    });

    test(
        '(j) Anti-replay /onboarding si profil complet -> /dashboard '
        '(audit 2026-06-13 : bypass /splash transit pour flow visiteur)',
        () {
      // Avant l'audit, retournait `/` qui mappe vers /splash. Resultat pour
      // le flow visiteur : transit /splash visible (2.1s animation) au lieu
      // d'aller direct sur /dashboard. Cf. evaluateRedirect rule 3.
      final result = evaluateRedirect(
        location: AppRoutes.onboarding,
        catalogueCheck: _catalogueOk(true),
        profileCompletion: _completionData(ProfileCompletionState.complete),
      );
      expect(result, AppRoutes.dashboard);
    });

    test('(k) /onboarding si profil incomplet -> null (laisse passer)', () {
      final result = evaluateRedirect(
        location: AppRoutes.onboarding,
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
      // /onboarding. Resultat : apres signInAnonymously + flush + go(
      // /dashboard), le stream watchProfile n'a pas encore emis ; le redirect
      // confond loading et incomplete -> bounce. Maintenant on differencie
      // explicitement les 3 cas (data/loading/error) — voir _shouldBlock.
      final result = evaluateRedirect(
        location: AppRoutes.dashboard,
        catalogueCheck: _catalogueOk(true),
        profileCompletion: _completionLoading(),
      );
      expect(result, isNull);
    });

    test('(m) Profil error + route metier -> /onboarding (safe fallback)',
        () {
      final result = evaluateRedirect(
        location: AppRoutes.dashboard,
        catalogueCheck: _catalogueOk(true),
        profileCompletion: AsyncValue.error(
          Exception('stream-error'),
          StackTrace.current,
        ),
      );
      expect(result, AppRoutes.onboarding);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // upgradeInProgress — fix ProfileGuestBody (visiteur → créer compte)
  //
  // Avant le fix, le visiteur avec profil académique complet cliquait
  // "Créer mon compte" → go(/onboarding) → anti-replay (règle 3) redirectait
  // vers /dashboard au lieu d'afficher AuthChoiceStepBody.
  // ────────────────────────────────────────────────────────────────────────────
  group('evaluateRedirect — upgradeInProgress', () {
    test(
        '(n) /onboarding + complet + upgradeInProgress=true → null '
        '(anti-replay bypassé : visiteur peut accéder au flow d\'auth)',
        () {
      final result = evaluateRedirect(
        location: AppRoutes.onboarding,
        catalogueCheck: _catalogueOk(true),
        profileCompletion: _completionData(ProfileCompletionState.complete),
        upgradeInProgress: true,
      );
      expect(result, isNull);
    });

    test(
        '(o) /dashboard + filiereMissing + upgradeInProgress=true → null '
        '(garde profil-incomplet bypassée : upgrade autorisé même sans profil)',
        () {
      final result = evaluateRedirect(
        location: AppRoutes.dashboard,
        catalogueCheck: _catalogueOk(true),
        profileCompletion:
            _completionData(ProfileCompletionState.filiereMissing),
        upgradeInProgress: true,
      );
      expect(result, isNull);
    });

    test(
        '(p) /profile + filiereMissing + upgradeInProgress=true → null',
        () {
      final result = evaluateRedirect(
        location: AppRoutes.profile,
        catalogueCheck: _catalogueOk(true),
        profileCompletion:
            _completionData(ProfileCompletionState.filiereMissing),
        upgradeInProgress: true,
      );
      expect(result, isNull);
    });

    test(
        '(q) /courses + filiereMissing + upgradeInProgress=true → null',
        () {
      final result = evaluateRedirect(
        location: AppRoutes.courses,
        catalogueCheck: _catalogueOk(true),
        profileCompletion:
            _completionData(ProfileCompletionState.filiereMissing),
        upgradeInProgress: true,
      );
      expect(result, isNull);
    });

    test(
        '(r) /profile + filiereMissing + upgradeInProgress=true → null',
        () {
      final result = evaluateRedirect(
        location: AppRoutes.profile,
        catalogueCheck: _catalogueOk(true),
        profileCompletion:
            _completionData(ProfileCompletionState.filiereMissing),
        upgradeInProgress: true,
      );
      expect(result, isNull);
    });

    test(
        '(s) /dashboard + error + upgradeInProgress=true → null '
        '(erreur stream + upgrade : garde bypassée, pas de bounce)',
        () {
      final result = evaluateRedirect(
        location: AppRoutes.dashboard,
        catalogueCheck: _catalogueOk(true),
        profileCompletion: AsyncValue.error(
          Exception('stream-error'),
          StackTrace.current,
        ),
        upgradeInProgress: true,
      );
      expect(result, isNull);
    });

    test(
        '(t) Catalogue bad + upgradeInProgress=true → /catalogue-waiting '
        '(règle 2 catalogue est prioritaire sur upgradeInProgress)',
        () {
      final result = evaluateRedirect(
        location: AppRoutes.dashboard,
        catalogueCheck: _catalogueOk(false),
        profileCompletion:
            _completionData(ProfileCompletionState.filiereMissing),
        upgradeInProgress: true,
      );
      expect(result, AppRoutes.catalogueWaiting);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // Règle 4 — tous les états ProfileCompletionState incomplets sur /dashboard
  // ────────────────────────────────────────────────────────────────────────────
  group('evaluateRedirect — tous les états ProfileCompletionState', () {
    for (final (label, state) in [
      ('niveauMissing', ProfileCompletionState.niveauMissing),
      ('serieMissing', ProfileCompletionState.serieMissing),
      ('subsystemMissing', ProfileCompletionState.subsystemMissing),
      ('filiereMissing', ProfileCompletionState.filiereMissing),
    ]) {
      test('(u-x) /dashboard + $label → /onboarding', () {
        final result = evaluateRedirect(
          location: AppRoutes.dashboard,
          catalogueCheck: _catalogueOk(true),
          profileCompletion: _completionData(state),
        );
        expect(result, AppRoutes.onboarding,
            reason: '$label doit déclencher la garde → /onboarding');
      });
    }

    test('(y) /dashboard + complete → null (aucun état incomplet ne bloque)',
        () {
      final result = evaluateRedirect(
        location: AppRoutes.dashboard,
        catalogueCheck: _catalogueOk(true),
        profileCompletion: _completionData(ProfileCompletionState.complete),
      );
      expect(result, isNull);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // Règle 4 — toutes les routes métier avec profil incomplet/complet
  // ────────────────────────────────────────────────────────────────────────────
  group('evaluateRedirect — toutes les routes métier', () {
    final routesBusiness = [
      AppRoutes.dashboard,
      AppRoutes.courses,
      AppRoutes.exams,
      AppRoutes.profile,
      '/user/someUid123',
      '/subject/math101',
    ];

    for (final route in routesBusiness) {
      test('(z-af) $route + filiereMissing → /onboarding', () {
        final result = evaluateRedirect(
          location: route,
          catalogueCheck: _catalogueOk(true),
          profileCompletion:
              _completionData(ProfileCompletionState.filiereMissing),
        );
        expect(result, AppRoutes.onboarding,
            reason: 'Profil incomplet sur $route doit rediriger vers /onboarding');
      });

      test('(ag-am) $route + complete → null', () {
        final result = evaluateRedirect(
          location: route,
          catalogueCheck: _catalogueOk(true),
          profileCompletion: _completionData(ProfileCompletionState.complete),
        );
        expect(result, isNull,
            reason: 'Profil complet sur $route ne doit pas rediriger');
      });
    }
  });

  // ────────────────────────────────────────────────────────────────────────────
  // Règle 3 — cas limites anti-replay /onboarding
  // ────────────────────────────────────────────────────────────────────────────
  group('evaluateRedirect — règle 3 anti-replay /onboarding (cas limites)', () {
    test(
        '(an) /onboarding + loading → null '
        '(maybeWhen orElse=false : pas de bounce en transit)',
        () {
      final result = evaluateRedirect(
        location: AppRoutes.onboarding,
        catalogueCheck: _catalogueOk(true),
        profileCompletion: _completionLoading(),
      );
      expect(result, isNull);
    });

    test(
        '(ao) /onboarding + error → null '
        '(maybeWhen orElse=false : stream erreur ne bloque pas l\'accès)',
        () {
      final result = evaluateRedirect(
        location: AppRoutes.onboarding,
        catalogueCheck: _catalogueOk(true),
        profileCompletion: AsyncValue.error(
          Exception('stream-error'),
          StackTrace.current,
        ),
      );
      expect(result, isNull);
    });

    for (final (label, state) in [
      ('niveauMissing', ProfileCompletionState.niveauMissing),
      ('serieMissing', ProfileCompletionState.serieMissing),
      ('subsystemMissing', ProfileCompletionState.subsystemMissing),
    ]) {
      test('(ap-ar) /onboarding + $label → null (profil incomplet peut accéder)',
          () {
        final result = evaluateRedirect(
          location: AppRoutes.onboarding,
          catalogueCheck: _catalogueOk(true),
          profileCompletion: _completionData(state),
        );
        expect(result, isNull,
            reason: '$label ne doit pas déclencher l\'anti-replay');
      });
    }
  });

  // ────────────────────────────────────────────────────────────────────────────
  // Règle 2 — catalogue check : cas limites
  // ────────────────────────────────────────────────────────────────────────────
  group('evaluateRedirect — règle 2 catalogue (cas limites)', () {
    test(
        '(as) Catalogue bad + déjà sur /catalogue-waiting → null '
        '(pas de boucle de redirection)',
        () {
      final result = evaluateRedirect(
        location: AppRoutes.catalogueWaiting,
        catalogueCheck: _catalogueOk(false),
        profileCompletion:
            _completionData(ProfileCompletionState.filiereMissing),
      );
      expect(result, isNull);
    });

    test(
        '(at) Catalogue bad + /onboarding → /catalogue-waiting '
        '(règle 2 prioritaire sur règle 3)',
        () {
      final result = evaluateRedirect(
        location: AppRoutes.onboarding,
        catalogueCheck: _catalogueOk(false),
        profileCompletion:
            _completionData(ProfileCompletionState.filiereMissing),
      );
      expect(result, AppRoutes.catalogueWaiting);
    });

    test(
        '(au) Catalogue loading + /catalogue-waiting → / '
        '(loading traité comme ok → exit /catalogue-waiting)',
        () {
      final result = evaluateRedirect(
        location: AppRoutes.catalogueWaiting,
        catalogueCheck: _catalogueLoading(),
        profileCompletion: _completionData(ProfileCompletionState.complete),
      );
      expect(result, '/');
    });

    test(
        '(av) Route debug + catalogue bad → null '
        '(règle 1 bypass prioritaire sur règle 2)',
        () {
      for (final route in [
        AppRoutes.crash,
        AppRoutes.showcase,
        AppRoutes.aiSmoke,
        AppRoutes.testCourses,
      ]) {
        final result = evaluateRedirect(
          location: route,
          catalogueCheck: _catalogueOk(false),
          profileCompletion:
              _completionData(ProfileCompletionState.filiereMissing),
        );
        expect(result, isNull,
            reason: 'Route debug $route doit bypasser même si catalogue bad');
      }
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // Règle 4 — garde désactivée pendant suppression de compte (Bug B 2026-06-29)
  //
  // Pendant deleteAccountNow() : Firestore doc supprimé → filiereMissing →
  // sans cette garde, SuccessCelebrationStepBody se monterait (step 9 en
  // mémoire) et recrée le doc. La garde `deleting|error` coupe le redirect.
  // ────────────────────────────────────────────────────────────────────────────
  group('evaluateRedirect — deletionStatus guard (Bug B)', () {
    test(
        '(aw) /dashboard + filiereMissing + deleting → null '
        '(doc Firestore supprimé pendant deleteNow → ne pas rediriger)',
        () {
      final result = evaluateRedirect(
        location: AppRoutes.dashboard,
        catalogueCheck: _catalogueOk(true),
        profileCompletion:
            _completionData(ProfileCompletionState.filiereMissing),
        deletionStatus: const AccountDeletionStatus.deleting(),
      );
      expect(result, isNull);
    });

    test(
        '(ax) /profile + filiereMissing + error(requiresRecentLogin) → null '
        '(Auth delete échoué après Firestore delete → ne pas forcer re-onboarding)',
        () {
      final result = evaluateRedirect(
        location: AppRoutes.profile,
        catalogueCheck: _catalogueOk(true),
        profileCompletion:
            _completionData(ProfileCompletionState.filiereMissing),
        deletionStatus: const AccountDeletionStatus.error(
          AccountDeletionFailure.requiresRecentLogin(),
        ),
      );
      expect(result, isNull);
    });

    test(
        '(ay) /dashboard + filiereMissing + idle → /onboarding '
        '(garde inactive hors suppression : comportement normal)',
        () {
      final result = evaluateRedirect(
        location: AppRoutes.dashboard,
        catalogueCheck: _catalogueOk(true),
        profileCompletion:
            _completionData(ProfileCompletionState.filiereMissing),
        deletionStatus: const AccountDeletionStatus.idle(),
      );
      expect(result, AppRoutes.onboarding);
    });

    test(
        '(az) /dashboard + filiereMissing + deleting + catalogue bad → /catalogue-waiting '
        '(règle 2 catalogue reste prioritaire sur la garde suppression)',
        () {
      final result = evaluateRedirect(
        location: AppRoutes.dashboard,
        catalogueCheck: _catalogueOk(false),
        profileCompletion:
            _completionData(ProfileCompletionState.filiereMissing),
        deletionStatus: const AccountDeletionStatus.deleting(),
      );
      expect(result, AppRoutes.catalogueWaiting);
    });
  });
}
