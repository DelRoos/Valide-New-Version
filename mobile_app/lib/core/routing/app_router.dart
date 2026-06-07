import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/catalogue/presentation/catalogue_waiting_page.dart';
import '../../features/debug/presentation/ai_smoke_page.dart';
import '../../features/debug/presentation/crash_smoke_page.dart';
import '../../features/debug/presentation/test_courses_page.dart';
import '../../features/hello/presentation/hello_page.dart';
import '../../features/onboarding/presentation/filiere_choice_page.dart';
import '../../features/onboarding/presentation/niveau_choice_page.dart';
import '../../features/onboarding/presentation/profile_recap_page.dart';
import '../../features/onboarding/presentation/serie_choice_page.dart';
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
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // Bypass inconditionnel : routes systeme + debug.
      if (loc == '/' ||
          loc.startsWith('/splash') ||
          loc.startsWith('/_')) {
        return null;
      }

      final subSystem = ref.read(subSystemNotifierProvider);

      // Story 1.2 — subsystem prioritaire sur catalogue.
      // Cas 1 : subSystem absent (1er lancement).
      if (subSystem == null) {
        // Deja sur la bonne route OU sur l'ecran catalogue offline : ok.
        if (loc == '/onboarding/subsystem' ||
            loc == '/catalogue-waiting') {
          return null;
        }
        return '/onboarding/subsystem';
      }

      // Cas 2 : subSystem present.
      // Garde first-launch-only : si l'utilisateur tente d'acceder
      // manuellement a /onboarding/subsystem, on le renvoie au home.
      if (loc == '/onboarding/subsystem') {
        return '/';
      }

      // Story 1.1c — logique catalogue preservee pour les autres routes.
      if (loc == '/catalogue-waiting') return null;
      final check = ref.read(appStartupCatalogueCheckProvider);
      return check.when(
        data: (ok) => ok ? null : '/catalogue-waiting',
        loading: () => null,
        error: (_, _) => '/catalogue-waiting',
      );
    },
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
