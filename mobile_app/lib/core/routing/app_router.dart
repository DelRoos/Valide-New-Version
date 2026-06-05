import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/debug/presentation/ai_smoke_page.dart';
import '../../features/debug/presentation/crash_smoke_page.dart';
import '../../features/debug/presentation/test_courses_page.dart';
import '../../features/hello/presentation/hello_page.dart';
import '../../features/splash/presentation/splash_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
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
