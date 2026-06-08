import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/catalogue/presentation/catalogue_waiting_page.dart';
import '../../features/debug/presentation/ai_smoke_page.dart';
import '../../features/debug/presentation/crash_smoke_page.dart';
import '../../features/debug/presentation/test_courses_page.dart';
import '../../features/hello/presentation/hello_page.dart';
import '../../features/onboarding/domain/profile_completion_state.dart';
import '../../features/onboarding/presentation/filiere_choice_page.dart';
import '../../features/onboarding/presentation/niveau_choice_page.dart';
import '../../features/onboarding/presentation/profile_recap_page.dart';
import '../../features/onboarding/presentation/serie_choice_page.dart';
import '../../features/onboarding/presentation/subjects_opt_out_page.dart';
import '../../features/onboarding/presentation/subsystem_choice_page.dart';
import '../../features/onboarding/providers.dart';
import '../../features/splash/presentation/splash_page.dart';
import '../catalogue/providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Story 1.1c — refreshListenable cable au check catalogue. Story 1.2
  // l'etend pour ecouter aussi subSystemNotifierProvider, sinon le tap
  // « Continuer » persiste mais le router ne re-evalue pas son redirect.
  final notifier = ValueNotifier<int>(0);
  ref.listen(appStartupCatalogueCheckProvider, (_, _) {
    notifier.value++;
  });
  ref.listen(subSystemNotifierProvider, (_, _) {
    notifier.value++;
  });
  // Story 1.3 — refresh router quand le flow profil avance (pas critique
  // car les pages naviguent via context.go explicite, mais coherent avec
  // pattern Stories 1.1c + 1.2).
  ref.listen(onboardingFlowProvider, (_, _) {
    notifier.value++;
  });
  // Story 1.5 — refresh router quand la completion profil change (post-tap
  // « C'est ma classe » -> users/{uid} cree -> profileCompletion passe a
  // `complete` -> les routes metier deviennent accessibles).
  ref.listen(profileCompletionProvider, (_, _) {
    notifier.value++;
  });
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) => evaluateRedirect(
      location: state.matchedLocation,
      catalogueCheck: ref.read(appStartupCatalogueCheckProvider),
      hasSubSystem: ref.read(subSystemNotifierProvider) != null,
      profileCompletion: ref.read(profileCompletionProvider),
    ),
    routes: [
      GoRoute(
        path: '/',
        // Story 0.22 — redirect vers /splash (SplashPage anime puis navigue
        // vers /hello ou /onboarding/subsystem selon subSystem Story 1.2).
        redirect: (context, state) => '/splash',
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/hello',
        builder: (context, state) => const HelloPage(),
      ),
      // Story 1.2 — premier ecran utilisateur (FR-1 + ADR-006). Affichee par
      // le redirect global ci-dessus quand subSystem absent en SharedPreferences.
      GoRoute(
        path: '/onboarding/subsystem',
        builder: (context, state) => const SubsystemChoicePage(),
      ),
      // Story 1.3 — flow profil scolaire 3 etapes (Filiere -> Niveau ->
      // Serie -> Recap). Chaque page a son propre guard de coherence (si
      // l'etape precedente n'a pas pose son champ, redirect vers la 1ere
      // etape manquante).
      GoRoute(
        path: '/onboarding/profile/filiere',
        builder: (context, state) => const FiliereChoicePage(),
      ),
      GoRoute(
        path: '/onboarding/profile/niveau',
        builder: (context, state) => const NiveauChoicePage(),
      ),
      GoRoute(
        path: '/onboarding/profile/serie',
        builder: (context, state) => const SerieChoicePage(),
      ),
      GoRoute(
        path: '/onboarding/profile/recap',
        builder: (context, state) => const ProfileRecapPage(),
      ),
      // Story 1.4 — page de retrait conditionnel des matieres (FR-3).
      // Bypassee par le redirect Story 1.5 (toutes les routes /onboarding/* le
      // sont). Guard in-component verifie derivedProfile.canOptOut.
      GoRoute(
        path: '/onboarding/profile/opt-out',
        builder: (context, state) => const SubjectsOptOutPage(),
      ),
      // Story 1.1c — ecran « En attente de connexion » bloquant. Affichee par
      // le redirect global ci-dessus quand le catalogue Firestore est vide ET
      // le cache offline est vide (1er lancement strictement hors-ligne).
      GoRoute(
        path: '/catalogue-waiting',
        builder: (context, state) => const CatalogueWaitingPage(),
      ),
      // Story 0.6 — routes debug. Retirees a la cloture E0 (Story 0.21).
      GoRoute(
        path: '/_crash',
        builder: (context, state) => const CrashSmokePage(),
      ),
      GoRoute(
        path: '/_ai_smoke',
        builder: (context, state) => const AISmokePage(),
      ),
      // Story 0.19 R2 — tests precoces flutter_smooth_markdown.
      GoRoute(
        path: '/_test_courses',
        builder: (context, state) => const TestCoursesPage(),
        routes: [
          GoRoute(
            path: ':slug',
            builder: (context, state) =>
                TestCourseDetailPage(slug: state.pathParameters['slug']!),
          ),
        ],
      ),
    ],
  );
});

/// Pure helper qui calcule la redirect target pour une location donnee.
/// Extrait pour testabilite (cf. test/core/routing/app_router_redirect_test.dart).
///
/// Ordre d'evaluation (cf. Story 1.5 AC2) :
///   1. Bypass systeme : `/`, `/splash`, `/_*` -> null.
///   2. Catalogue check (Story 1.1c) : si vide+offline -> /catalogue-waiting.
///   3. Story 1.2 anti-replay : si subSystem present + loc == /onboarding/subsystem -> /.
///   4. Story 1.5 garde profil-incomplet : sur routes metier (hors /onboarding/* +
///      hors /catalogue-waiting), si profile incomplet -> nextOnboardingRoute.
///      Loading -> null (laisse passer, evite flash). Error -> /onboarding/subsystem.
///   5. Routes /onboarding/* -> bypass (guards in-component Story 1.3 gerent
///      la coherence mi-flow).
@visibleForTesting
String? evaluateRedirect({
  required String location,
  required AsyncValue<bool> catalogueCheck,
  required bool hasSubSystem,
  required AsyncValue<ProfileCompletionState> profileCompletion,
}) {
  // 1. Bypass inconditionnel : routes systeme + debug.
  if (location == '/' ||
      location.startsWith('/splash') ||
      location.startsWith('/_')) {
    return null;
  }

  // 2. Story 1.1c — catalogue check prioritaire.
  if (location != '/catalogue-waiting') {
    final catalogueOk = catalogueCheck.when(
      data: (ok) => ok,
      loading: () => true,
      error: (_, _) => false,
    );
    if (!catalogueOk) return '/catalogue-waiting';
  }

  // 3. Story 1.2 — anti-replay sur subsystem-choice.
  if (hasSubSystem && location == '/onboarding/subsystem') {
    return '/';
  }

  // 4. Story 1.5 — garde profil-incomplet pour les routes metier uniquement.
  if (!location.startsWith('/onboarding/') &&
      location != '/catalogue-waiting') {
    final nextRoute = profileCompletion.when(
      data: (state) => state.isComplete ? null : state.nextOnboardingRoute,
      loading: () => null,
      error: (_, _) => '/onboarding/subsystem',
    );
    if (nextRoute != null) return nextRoute;
  }

  return null;
}
