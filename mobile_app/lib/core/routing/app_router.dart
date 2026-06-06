import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/catalogue/presentation/catalogue_waiting_page.dart';
import '../../features/debug/presentation/ai_smoke_page.dart';
import '../../features/debug/presentation/crash_smoke_page.dart';
import '../../features/debug/presentation/test_courses_page.dart';
import '../../features/hello/presentation/hello_page.dart';
import '../../features/splash/presentation/splash_page.dart';
import '../catalogue/providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Story 1.1c — refreshListenable cable au check catalogue. Le router
  // re-evalue le redirect des que le check passe de loading -> data(true|false).
  final notifier = ValueNotifier<int>(0);
  ref.listen(appStartupCatalogueCheckProvider, (_, _) {
    notifier.value++;
  });
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      // Routes qui contournent toujours le redirect catalogue :
      //  - /splash (animation de boot, c'est elle qui pousse vers /hello)
      //  - /catalogue-waiting (sinon boucle infinie)
      //  - /_* (routes debug)
      final loc = state.matchedLocation;
      if (loc == '/' ||
          loc.startsWith('/splash') ||
          loc.startsWith('/_') ||
          loc == '/catalogue-waiting') {
        return null;
      }

      final check = ref.read(appStartupCatalogueCheckProvider);
      return check.when(
        data: (ok) => ok ? null : '/catalogue-waiting',
        // Loading : on ne bloque pas (le splash gere la transition).
        loading: () => null,
        // Erreur : fail-safe vers l'ecran connexion bloquant.
        error: (_, _) => '/catalogue-waiting',
      );
    },
    routes: [
      GoRoute(
        path: '/',
        // Story 0.22 — redirect vers /splash (SplashPage anime puis navigue
        // vers /hello). Quand Story 1.5 (garde navigation) sera livree, la
        // SplashPage redirigera vers /onboarding ou /dashboard selon profil.
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
      // Story 1.1c — ecran « En attente de connexion » bloquant. Affiche par
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
