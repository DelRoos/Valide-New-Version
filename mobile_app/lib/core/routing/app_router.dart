import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/feature_flags.dart';
import '../logging/perf_logger.dart';

import '../../features/catalogue/presentation/catalogue_waiting_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/dashboard/presentation/placeholder_tab_page.dart';
import '../../features/dashboard/presentation/subject_detail_placeholder_page.dart';
import '../../features/debug/presentation/ai_smoke_page.dart';
import '../../features/debug/presentation/crash_smoke_page.dart';
import '../../features/debug/presentation/test_courses_page.dart';
import '../../features/hello/presentation/hello_page.dart';
import '../../features/onboarding/domain/onboarding_flow_state.dart';
import '../../features/onboarding/domain/profile_completion_state.dart';
import '../../features/onboarding/presentation/filiere_choice_page.dart';
import '../../features/onboarding/presentation/niveau_choice_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_shell.dart';
import '../../features/onboarding/presentation/profile_recap_page.dart';
import '../../features/onboarding/presentation/account_creation_page.dart';
import '../../features/onboarding/presentation/school_picker_page.dart';
import '../../features/onboarding/presentation/serie_choice_page.dart';
import '../../features/onboarding/presentation/subjects_picker_page.dart';
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
    observers: [_PerfNavigatorObserver()],
    redirect: (context, state) => evaluateRedirect(
      location: state.matchedLocation,
      catalogueCheck: ref.read(appStartupCatalogueCheckProvider),
      hasSubSystem: ref.read(subSystemNotifierProvider) != null,
      profileCompletion: ref.read(profileCompletionProvider),
      flowState: ref.read(onboardingFlowProvider),
      useNewOnboardingFlow: FeatureFlags.useNewOnboardingFlow,
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
      // Story 1.9 — dashboard skeleton + 3 onglets placeholder + detail matiere.
      // Premier ecran metier post-onboarding. Remplace `/hello` comme cible
      // par defaut depuis splash + subsystem-choice + school-picker.
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
      // Story 1.2 — premier ecran utilisateur (FR-1 + ADR-006). Affichee par
      // le redirect global ci-dessus quand subSystem absent en SharedPreferences.
      GoRoute(
        path: '/onboarding/subsystem',
        builder: (context, state) => const SubsystemChoicePage(),
      ),
      // Story E1bis-2bis — UNE seule route pour le flow onboarding refonte.
      // Le `OnboardingShell` route en interne par `currentStep` du
      // `OnboardingNotifier` (E1bis-1) via AnimatedSwitcher slide transition.
      // Le redirect ci-dessous aiguille vers `/onboarding/v2` quand
      // `FeatureFlags.useNewOnboardingFlow=true`. Refactor des 2 routes
      // paralleles PR #103 (`/onboarding/sub-system-v2` + `/onboarding/hero`)
      // qui dupliquaient l'URL pour la meme destination.
      GoRoute(
        path: '/onboarding/v2',
        builder: (context, state) => const OnboardingShell(),
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
      // Story 1.4 + 1.15 — page de selection des matieres polymorphe (FR-3).
      // Bypassee par le redirect Story 1.5 (toutes les routes /onboarding/* le
      // sont). Guard in-component dispatche sur DerivedProfile.pickerMode :
      //   - derived            -> redirect recap (Fatou Tle D)
      //   - optOut             -> _LegacyOptOutBody (James Upper Sixth S2)
      //   - freeWithObligatory -> _FreeWithObligatoryBody (Mariam Form 5)
      //   - seriesPlusOptional -> placeholder Story 1.16
      //   - tvePicker          -> placeholder Story 1.17
      GoRoute(
        path: '/onboarding/profile/picker',
        builder: (context, state) => const SubjectsPickerPage(),
      ),
      // Story 1.6 — creation de compte Google/Apple (FR-5). Affichee
      // post-recap (Story 1.3 _onValidate succes navigue ici au lieu de
      // /hello). Bypassee par la garde Story 1.5 (route /onboarding/*).
      GoRoute(
        path: '/onboarding/account',
        builder: (context, state) => const AccountCreationPage(),
      ),
      // Story 1.7 — liaison ecole optionnelle (FR-6). Affichee post-success
      // Story 1.6 (AccountCreationPage success navigue ici au lieu de /hello).
      // Bypassee par la garde Story 1.5 (route /onboarding/*).
      GoRoute(
        path: '/onboarding/school',
        builder: (context, state) => const SchoolPickerPage(),
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

/// Dev audit toolkit — NavigatorObserver qui trace entree / sortie de chaque
/// route GoRouter. Permet de chiffrer le temps utilisateur dans chaque page
/// (subSystem -> filiere -> niveau -> serie -> recap -> picker -> school ->
/// dashboard) en croisant les timestamps `event:nav.push.<route>` et
/// `event:nav.pop.<route>` dans la console.
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
    // GoRouter expose la path config via `route.settings.name` (settable via
    // GoRoute.name) ou via `route.settings.arguments`. En pratique pour notre
    // setup actuel sans `name:` declare, on retombe sur le runtimeType — c'est
    // suffisant pour distinguer les pages dans la console.
    return route.settings.name ?? route.runtimeType.toString();
  }
}

/// Pure helper qui calcule la redirect target pour une location donnee.
/// Extrait pour testabilite (cf. test/core/routing/app_router_redirect_test.dart).
///
/// Ordre d'evaluation (cf. Story 1.5 AC2 + Story 1.8 smart resume) :
///   1. Bypass systeme : `/`, `/splash`, `/_*` -> null.
///   2. Catalogue check (Story 1.1c) : si vide+offline -> /catalogue-waiting.
///   3. Story 1.2 anti-replay : si subSystem present + loc == /onboarding/subsystem -> /.
///   4. Story 1.5 + 1.8 garde profil-incomplet smart resume : sur routes metier (hors
///      /onboarding/* + hors /catalogue-waiting), si profile incomplet -> route vers
///      la VRAIE prochaine etape (le flowState SharedPreferences restaure permet de
///      sauter directement a /niveau ou /serie ou /recap au lieu de toujours /filiere).
///      Loading -> null (laisse passer, evite flash). Error -> /onboarding/subsystem.
///   5. Routes /onboarding/* -> bypass (guards in-component Story 1.3 gerent
///      la coherence mi-flow).
@visibleForTesting
String? evaluateRedirect({
  required String location,
  required AsyncValue<bool> catalogueCheck,
  required bool hasSubSystem,
  required AsyncValue<ProfileCompletionState> profileCompletion,
  required OnboardingFlowState flowState,
  bool useNewOnboardingFlow = false,
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

  // 2.bis Story E1bis-2bis — feature flag refonte onboarding (route unique).
  // Si flag ON, force l'aiguillage vers le nouveau flow E1bis a partir de
  // la route legacy Epic 1. Anti-replay symetrique pour la nouvelle route :
  // si subSystem deja choisi, on sort du flow refonte vers `/`.
  if (useNewOnboardingFlow && location == '/onboarding/subsystem') {
    return '/onboarding/v2';
  }
  if (hasSubSystem && location == '/onboarding/v2') {
    return '/';
  }

  // 3. Story 1.2 — anti-replay sur subsystem-choice.
  if (hasSubSystem && location == '/onboarding/subsystem') {
    return '/';
  }

  // 4. Story 1.5 + 1.8 — garde profil-incomplet pour les routes metier
  // uniquement, avec smart resume basee sur le flowState SharedPreferences.
  if (!location.startsWith('/onboarding/') &&
      location != '/catalogue-waiting') {
    final nextRoute = profileCompletion.when(
      data: (state) =>
          state.isComplete ? null : _smartResumeRoute(state, flowState),
      loading: () => null,
      error: (_, _) => '/onboarding/subsystem',
    );
    if (nextRoute != null) return nextRoute;
  }

  return null;
}

/// Story 1.8 — Calcule la route de reprise en combinant le profileCompletion
/// (Firestore-based, source de verite apres createProfile) et le flowState
/// SharedPreferences-based (in-flight pendant les 3 etapes profile).
///
/// Quand `users/{uid}` n'existe pas encore mais que le user a deja tape
/// filiere et/ou niveau en local, on saute directement a l'etape suivante au
/// lieu de le renvoyer systematiquement a `/onboarding/profile/filiere`.
String _smartResumeRoute(
  ProfileCompletionState completion,
  OnboardingFlowState flowState,
) {
  // serie set -> recap (apres tap serie, avant tap "C'est ma classe")
  if (flowState.serieId != null) return '/onboarding/profile/recap';
  // niveau set sans serie -> serie (le user va choisir sa serie, ou la
  // SerieChoicePage skip vers recap si le niveau n'a pas de serie applicable)
  if (flowState.niveauId != null) return '/onboarding/profile/serie';
  // filiere set sans niveau -> niveau
  if (flowState.filiereId != null) return '/onboarding/profile/niveau';
  // Rien en flight : default sur la 1ere etape manquante selon
  // profileCompletion (filiere/niveau/serie/subsystemMissing).
  return completion.nextOnboardingRoute;
}
