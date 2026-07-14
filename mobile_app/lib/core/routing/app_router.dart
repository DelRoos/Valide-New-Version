import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../logging/app_logger.dart';
import '../logging/perf_logger.dart';
import 'app_routes.dart';

import '../../features/account/domain/account_deletion_status.dart';
import '../../features/account/presentation/public_profile_page.dart';
import '../../features/account/providers.dart';
import '../../features/catalogue/presentation/catalogue_waiting_page.dart';
import '../../features/dashboard/presentation/main_shell.dart';
import '../../features/dashboard/presentation/home_tab_page.dart';
import '../../features/dashboard/presentation/exams_tab_page.dart';
import '../../features/dashboard/presentation/profile_tab_page.dart';
import '../../features/content/presentation/pages/courses_page.dart';
import '../../features/content/presentation/pages/exam_sujets_page.dart';
import '../../features/content/presentation/pages/subject_detail_page.dart';
import '../../features/content/presentation/pages/chapter_page.dart';
import '../../features/content/presentation/pages/lesson_page.dart';
import '../../features/content/presentation/pages/quiz_page.dart';
import '../../features/content/presentation/pages/quiz_extra.dart';
import '../../features/content/presentation/pages/quiz_result_page.dart';
import '../../features/content/presentation/pages/quiz_review_page.dart';
import '../../features/debug/presentation/ai_smoke_page.dart';
import '../../features/debug/presentation/content_showcase_page.dart';
import '../../features/debug/presentation/crash_smoke_page.dart';
import '../../features/debug/presentation/test_courses_page.dart';
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
  ref.listen(accountDeletionStatusNotifierProvider, (_, _) {
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
      deletionStatus: ref.read(accountDeletionStatusNotifierProvider),
    ),
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => AppRoutes.splash,
      ),
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
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
                path: AppRoutes.dashboard,
                builder: (context, state) => const HomeTabPage(),
              ),
            ],
          ),
          // Branche 1 — Cours (/courses)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.courses,
                builder: (context, state) => const CoursesPage(),
              ),
            ],
          ),
          // Branche 2 — Examen (/exams)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.exams,
                builder: (context, state) => const ExamsTabPage(),
              ),
            ],
          ),
          // Branche 3 — Profil (/profile)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileTabPage(),
              ),
            ],
          ),
        ],
      ),

      // Sujets d'examen — page scopée (matière, séquence).
      GoRoute(
        path: AppRoutes.examSujetsPath,
        builder: (context, state) {
          // Valide le sequenceNumber : accepte 0 (sentinel annales) et 1..6
          // (séquences pédagogiques). Fallback silencieux à 1 pour tout deep
          // link malformé (non-numérique ou hors bornes).
          final rawSeq = state.pathParameters['sequenceNumber'];
          final parsedSeq = int.tryParse(rawSeq ?? '');
          final sequenceNumber = (parsedSeq != null &&
                  parsedSeq >= AppRoutes.examSujetsAnnalesSequence &&
                  parsedSeq <= AppRoutes.examSujetsMaxSequence)
              ? parsedSeq
              : 1;
          return ExamSujetsPage(
            sequenceNumber: sequenceNumber,
            subjectId: state.pathParameters['subjectId']!,
          );
        },
      ),

      // Navigation contenu — pile hors shell (Story 2.2).
      GoRoute(
        path: AppRoutes.subjectPath,
        builder: (context, state) => SubjectDetailPage(
          subjectId: state.pathParameters['subjectId']!,
        ),
        routes: [
          GoRoute(
            path: AppRoutes.chapterSegment,
            builder: (context, state) => ChapterPage(
              subjectId: state.pathParameters['subjectId']!,
              chapterId: state.pathParameters['chapterId']!,
            ),
            routes: [
              // Quiz chapitre — /subject/:id/chapter/:id/quiz
              GoRoute(
                path: AppRoutes.quizSegment,
                builder: (context, state) => QuizPage(
                  subjectId: state.pathParameters['subjectId']!,
                  chapterId: state.pathParameters['chapterId']!,
                ),
                routes: [
                  GoRoute(
                    path: AppRoutes.quizResultSegment,
                    builder: (context, state) => QuizResultPage(
                      subjectId: state.pathParameters['subjectId']!,
                      chapterId: state.pathParameters['chapterId']!,
                      extra: state.extra as QuizResultExtra,
                    ),
                  ),
                  GoRoute(
                    path: AppRoutes.quizReviewSegment,
                    builder: (context, state) => QuizReviewPage(
                      extra: state.extra as QuizResultExtra,
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: AppRoutes.lessonSegment,
                builder: (context, state) => LessonPage(
                  subjectId: state.pathParameters['subjectId']!,
                  chapterId: state.pathParameters['chapterId']!,
                  lessonId: state.pathParameters['lessonId']!,
                ),
                routes: [
                  // Quiz leçon — /subject/:id/chapter/:id/lesson/:id/quiz
                  GoRoute(
                    path: AppRoutes.quizSegment,
                    builder: (context, state) => QuizPage(
                      subjectId: state.pathParameters['subjectId']!,
                      chapterId: state.pathParameters['chapterId']!,
                      lessonId: state.pathParameters['lessonId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: AppRoutes.quizResultSegment,
                        builder: (context, state) => QuizResultPage(
                          subjectId: state.pathParameters['subjectId']!,
                          chapterId: state.pathParameters['chapterId']!,
                          lessonId: state.pathParameters['lessonId'],
                          extra: state.extra as QuizResultExtra,
                        ),
                      ),
                      GoRoute(
                        path: AppRoutes.quizReviewSegment,
                        builder: (context, state) => QuizReviewPage(
                          extra: state.extra as QuizResultExtra,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // Story E1bis-2bis — UNE seule route pour le flow onboarding.
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingShell(),
      ),
      // Story A.2 — profil public d'un pair (hors shell).
      GoRoute(
        path: AppRoutes.userPath,
        builder: (context, state) => PublicProfilePage(
          uid: state.pathParameters['uid']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.catalogueWaiting,
        builder: (context, state) => const CatalogueWaitingPage(),
      ),
      GoRoute(
        path: AppRoutes.crash,
        builder: (context, state) => const CrashSmokePage(),
      ),
      GoRoute(
        path: AppRoutes.showcase,
        builder: (context, state) => const ContentShowcasePage(),
      ),
      GoRoute(
        path: AppRoutes.aiSmoke,
        builder: (context, state) => const AISmokePage(),
      ),
      GoRoute(
        path: AppRoutes.testCourses,
        builder: (context, state) => const TestCoursesPage(),
        routes: [
          GoRoute(
            path: AppRoutes.testCourseSlugSegment,
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
///   4. Anti-replay sur /onboarding quand profil complet -> /dashboard.
///   5. Garde profil-incomplet : sur routes metier, si profil incomplet -> /onboarding.
@visibleForTesting
String? evaluateRedirect({
  required String location,
  required AsyncValue<bool> catalogueCheck,
  required AsyncValue<ProfileCompletionState> profileCompletion,
  bool upgradeInProgress = false,
  AccountDeletionStatus? deletionStatus,
}) {
  // 1. Bypass inconditionnel : routes systeme + debug.
  if (location == '/' ||
      location.startsWith('/splash') ||
      location.startsWith('/_')) {
    AppLogger.d('redirect: bypass $location');
    return null;
  }

  // 2. Story 1.1c — catalogue check prioritaire.
  final catalogueOk = catalogueCheck.when(
    data: (ok) => ok,
    loading: () => true,
    error: (_, _) => false,
  );
  if (!catalogueOk && location != AppRoutes.catalogueWaiting) {
    AppLogger.d('redirect: catalogue→ /catalogue-waiting (from $location)');
    return AppRoutes.catalogueWaiting;
  }
  if (catalogueOk && location == AppRoutes.catalogueWaiting) {
    AppLogger.d('redirect: catalogue-ok exit /catalogue-waiting → /');
    return '/';
  }

  // 3. Anti-replay sur /onboarding : si profil complet, sortie directe
  //    vers /dashboard. Exception upgradeInProgress (visiteur qui upgrade).
  if (location == AppRoutes.onboarding && !upgradeInProgress) {
    final complete = profileCompletion.maybeWhen(
      data: (s) => s.isComplete,
      orElse: () => false,
    );
    if (complete) {
      AppLogger.d('redirect: anti-replay /onboarding → /dashboard (profile complete)');
      return AppRoutes.dashboard;
    }
  }

  // 4. Garde profil-incomplet pour les routes metier.
  //    loading -> NE PAS rediriger (stream post-flush encore en route).
  //    error -> rediriger /onboarding (safe fallback).
  //    data incomplete -> rediriger.
  //    Exception : si suppression en cours (deleting) ou en erreur partielle
  //    (auth delete failed apres Firestore delete), ne pas rediriger — sinon
  //    SuccessCelebrationStepBody (step 9 en memoire) se monterait et recrée
  //    le doc Firestore supprime (Bug B 2026-06-29).
  final completionLabel = profileCompletion.maybeWhen(
    data: (s) => s.name,
    orElse: () => profileCompletion.isLoading ? 'loading' : 'error',
  );
  AppLogger.d(
    'redirect[check4]: location=$location '
    'upgradeInProgress=$upgradeInProgress '
    'completion=$completionLabel '
    'deletion=${deletionStatus?.runtimeType}',
  );
  if (!upgradeInProgress &&
      !location.startsWith(AppRoutes.onboarding) &&
      location != AppRoutes.catalogueWaiting) {
    // Reauthing inclus : pendant la réauth Google pour suppression, le doc Firestore
    // peut émettre null (suppression en cours) ce qui déclencherait un redirect
    // spurieux vers /onboarding.
    final isDeletionActive = deletionStatus is AccountDeletionStatusDeleting ||
        deletionStatus is AccountDeletionStatusReauthing ||
        deletionStatus is AccountDeletionStatusError;
    if (!isDeletionActive) {
      final shouldBlock = profileCompletion.when(
        data: (s) => !s.isComplete,
        loading: () => false,
        error: (_, _) => true,
      );
      if (shouldBlock) {
        AppLogger.d(
            'redirect: guard $location → /onboarding (state=$completionLabel)');
        return AppRoutes.onboarding;
      }
    }
  }

  AppLogger.d('redirect: pass $location'
      '${upgradeInProgress ? ' [upgradeInProgress]' : ''}');
  return null;
}
