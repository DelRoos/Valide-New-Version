import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../logging/perf_logger.dart';

import '../../features/catalogue/presentation/catalogue_waiting_page.dart';
import '../../features/account/presentation/profile_settings_page.dart';
import '../../features/dashboard/presentation/_main_shell.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/dashboard/presentation/placeholder_tab_page.dart';
import '../../features/dashboard/presentation/subject_detail_placeholder_page.dart';
import '../../features/debug/presentation/ai_smoke_page.dart';
import '../../features/debug/presentation/crash_smoke_page.dart';
import '../../features/debug/presentation/test_courses_page.dart';
import '../../features/hello/presentation/hello_page.dart';
import '../../features/onboarding/domain/profile_completion_state.dart';
import '../../features/onboarding/presentation/pages/onboarding_shell.dart';
import '../../features/onboarding/providers.dart';
import '../../features/splash/presentation/splash_page.dart';
import '../catalogue/providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Story 1.1c — refreshListenable cable au check catalogue + completion profil.
  final notifier = ValueNotifier<int>(0);
  ref.listen(appStartupCatalogueCheckProvider, (_, _) {
    notifier.value++;
  });
  ref.listen(profileCompletionProvider, (_, _) {
    notifier.value++;
  });
  ref.listen(profileUpgradeInProgressProvider, (_, _) {
    notifier.value++;
  });
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    observers: [_PerfNavigatorObserver()],
    redirect: (context, state) => evaluateRedirect(
      location: state.matchedLocation,
      catalogueCheck: ref.read(appStartupCatalogueCheckProvider),
      profileCompletion: ref.read(profileCompletionProvider),
      upgradeInProgress: ref.read(profileUpgradeInProgressProvider),
    ),
    routes: [
      GoRoute(
        path: '/',
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

      // Shell persistant — 4 branches avec NavigationBar fixe.
      // Chaque branche conserve son propre stack de navigation.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          // Branche 0 — Accueil (/dashboard)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          // Branche 1 — Cours (/courses)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/courses',
                builder: (context, state) =>
                    const PlaceholderTabPage(title: 'Cours', tabIndex: 1),
              ),
            ],
          ),
          // Branche 2 — Examen (/exams)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/exams',
                builder: (context, state) =>
                    const PlaceholderTabPage(title: 'Examen', tabIndex: 2),
              ),
            ],
          ),
          // Branche 3 — Profil (/profile)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) =>
                    const PlaceholderTabPage(title: 'Profil', tabIndex: 3),
              ),
            ],
          ),
        ],
      ),

      // Détail matière — page plein écran hors shell (pas de bottom nav).
      GoRoute(
        path: '/subject/:subjectId',
        builder: (context, state) => SubjectDetailPlaceholderPage(
          subjectId: state.pathParameters['subjectId']!,
        ),
      ),

      // Story E1bis-2bis — UNE seule route pour le flow onboarding refonte.
      GoRoute(
        path: '/onboarding/v2',
        builder: (context, state) => const OnboardingShell(),
      ),
      // Story 1.10 — page paramètres (suppression compte FR-7).
      GoRoute(
        path: '/profil/settings',
        builder: (context, state) => const ProfileSettingsPage(),
      ),
      GoRoute(
        path: '/catalogue-waiting',
        builder: (context, state) => const CatalogueWaitingPage(),
      ),
      GoRoute(
        path: '/_crash',
        builder: (context, state) => const CrashSmokePage(),
      ),
      GoRoute(
        path: '/_ai_smoke',
        builder: (context, state) => const AISmokePage(),
      ),
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

class _PerfNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final name = _routeName(route);
    if (name != null) logPerfEvent('nav.push.$name');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    final name = _routeName(route);
    if (name != null) logPerfEvent('nav.pop.$name');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    final newName = _routeName(newRoute);
    if (newName != null) logPerfEvent('nav.replace.$newName');
  }

  String? _routeName(Route<dynamic>? route) {
    if (route == null) return null;
    return route.settings.name ?? route.runtimeType.toString();
  }
}

/// Pure helper qui calcule la redirect target pour une location donnee.
///
/// Ordre d'evaluation :
///   1. Bypass systeme : `/`, `/splash`, `/_*` -> null.
///   2. Catalogue check : si vide+offline -> /catalogue-waiting.
///   3. Sortie /catalogue-waiting quand catalogue OK -> /.
///   4. Anti-replay sur /onboarding/v2 quand profil complet -> /dashboard.
///   5. Garde profil-incomplet : sur routes metier, si profil incomplet -> /onboarding/v2.
@visibleForTesting
String? evaluateRedirect({
  required String location,
  required AsyncValue<bool> catalogueCheck,
  required AsyncValue<ProfileCompletionState> profileCompletion,
  bool upgradeInProgress = false,
}) {
  // 1. Bypass inconditionnel : routes systeme + debug.
  if (location == '/' ||
      location.startsWith('/splash') ||
      location.startsWith('/_')) {
    return null;
  }

  // 2. Story 1.1c — catalogue check prioritaire.
  final catalogueOk = catalogueCheck.when(
    data: (ok) => ok,
    loading: () => true,
    error: (_, _) => false,
  );
  if (!catalogueOk && location != '/catalogue-waiting') {
    return '/catalogue-waiting';
  }
  if (catalogueOk && location == '/catalogue-waiting') {
    return '/';
  }

  // 3. Anti-replay sur /onboarding/v2 : si profil complet, sortie directe
  //    vers /dashboard. Exception upgradeInProgress (visiteur qui upgrade).
  if (location == '/onboarding/v2' && !upgradeInProgress) {
    final complete = profileCompletion.maybeWhen(
      data: (s) => s.isComplete,
      orElse: () => false,
    );
    if (complete) return '/dashboard';
  }

  // 4. Garde profil-incomplet pour les routes metier.
  //    loading -> NE PAS rediriger (stream post-flush encore en route).
  //    error -> rediriger /onboarding/v2 (safe fallback).
  //    data incomplete -> rediriger.
  if (!upgradeInProgress &&
      !location.startsWith('/onboarding/') &&
      location != '/catalogue-waiting') {
    final shouldBlock = profileCompletion.when(
      data: (s) => !s.isComplete,
      loading: () => false,
      error: (_, _) => true,
    );
    if (shouldBlock) return '/onboarding/v2';
  }

  return null;
}
