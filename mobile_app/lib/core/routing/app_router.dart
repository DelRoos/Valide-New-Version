import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../logging/perf_logger.dart';

import '../../features/catalogue/presentation/catalogue_waiting_page.dart';
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
  // Story E1bis-9 : suppression des listens Epic 1 (subSystemNotifier et
  // onboardingFlow legacy retires).
  final notifier = ValueNotifier<int>(0);
  ref.listen(appStartupCatalogueCheckProvider, (_, _) {
    notifier.value++;
  });
  ref.listen(profileCompletionProvider, (_, _) {
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
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/matieres',
        builder: (context, state) =>
            const PlaceholderTabPage(title: 'Matieres', tabIndex: 1),
      ),
      GoRoute(
        path: '/matieres/:subjectId',
        builder: (context, state) => SubjectDetailPlaceholderPage(
          subjectId: state.pathParameters['subjectId']!,
        ),
      ),
      GoRoute(
        path: '/activites',
        builder: (context, state) =>
            const PlaceholderTabPage(title: 'Activites', tabIndex: 2),
      ),
      GoRoute(
        path: '/profil',
        builder: (context, state) =>
            const PlaceholderTabPage(title: 'Profil', tabIndex: 3),
      ),
      // Story E1bis-2bis — UNE seule route pour le flow onboarding refonte.
      // Le `OnboardingShell` route en interne par `currentStep` du
      // `OnboardingNotifier` via AnimatedSwitcher slide transition.
      GoRoute(
        path: '/onboarding/v2',
        builder: (context, state) => const OnboardingShell(),
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
/// Story E1bis-9 — Routing simplifie : Epic 1 retire, seul le flow E1bis
/// (`/onboarding/v2`) subsiste.
///
/// Ordre d'evaluation :
///   1. Bypass systeme : `/`, `/splash`, `/_*` -> null.
///   2. Catalogue check (Story 1.1c) : si vide+offline -> /catalogue-waiting.
///   3. Sortie /catalogue-waiting quand catalogue OK -> /.
///   4. Anti-replay sur /onboarding/v2 quand profil complet -> /.
///   5. Garde profil-incomplet : sur routes metier (hors /onboarding/* + hors
///      /catalogue-waiting), si profil incomplet -> /onboarding/v2.
@visibleForTesting
String? evaluateRedirect({
  required String location,
  required AsyncValue<bool> catalogueCheck,
  required AsyncValue<ProfileCompletionState> profileCompletion,
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
  // Story 1bis-2bis fix : sortir de /catalogue-waiting quand le catalogue
  // redevient OK (post-retry ou post-auth ready).
  if (catalogueOk && location == '/catalogue-waiting') {
    return '/';
  }

  // 3. Anti-replay sur /onboarding/v2 : si profil complet, sortie directe
  //    vers /dashboard.
  //
  // Audit 2026-06-13 (bug visiteur dashboard) — Avant ce fix, on retournait
  // `/` qui mappe vers `/splash` (cf. GoRoute path: '/'). Resultat sur le
  // flow visiteur : router.go('/dashboard') voyait profileCompletion encore
  // `data: incomplete` (stream Firestore pas encore emis post-flush) ->
  // bounce vers /onboarding/v2 -> stream emet complete -> refresh router ->
  // anti-replay -> '/' -> '/splash' -> animation 2.1s -> /dashboard. Le user
  // voyait le splash avant le dashboard. En pointant direct sur /dashboard,
  // on saute le transit splash.
  if (location == '/onboarding/v2') {
    final complete = profileCompletion.maybeWhen(
      data: (s) => s.isComplete,
      orElse: () => false,
    );
    if (complete) return '/dashboard';
  }

  // 4. Garde profil-incomplet pour les routes metier.
  //
  // Audit 2026-06-13 (bug visiteur dashboard) — distinction explicite
  // loading vs incomplete confirme :
  //   - loading -> NE PAS rediriger (le stream watchProfile est encore en
  //     route apres signInAnonymously + flush ; rediriger ici renvoie le
  //     visiteur sur /onboarding/v2 alors qu'il vient de finir l'onboarding).
  //   - error -> rediriger /onboarding/v2 (safe fallback).
  //   - data incomplete -> rediriger.
  //   - data complete -> rester.
  if (!location.startsWith('/onboarding/') &&
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
