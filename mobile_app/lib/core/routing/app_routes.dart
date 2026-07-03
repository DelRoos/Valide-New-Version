abstract final class AppRoutes {
  // Système
  static const splash = '/splash';

  // Shell tabs
  static const dashboard = '/dashboard';
  static const courses = '/courses';
  static const exams = '/exams';
  static const profile = '/profile';

  // Onboarding
  static const onboarding = '/onboarding';

  // Catalogue
  static const catalogueWaiting = '/catalogue-waiting';

  // Contenu — templates de path pour GoRoute `path:` (paramètres GoRouter)
  static const subjectPath = '/subject/:subjectId';
  static const chapterSegment = 'chapter/:chapterId';
  static const lessonSegment = 'lesson/:lessonId';
  static const quizSegment = 'quiz';

  // Contenu — builders de navigation (interpolation des IDs)
  static String subject(String subjectId) => '/subject/$subjectId';
  static String chapter(String subjectId, String chapterId) =>
      '/subject/$subjectId/chapter/$chapterId';
  static String lesson(String subjectId, String chapterId, String lessonId) =>
      '/subject/$subjectId/chapter/$chapterId/lesson/$lessonId';
  static String chapterQuiz(String subjectId, String chapterId) =>
      '/subject/$subjectId/chapter/$chapterId/quiz';
  static String lessonQuiz(
    String subjectId,
    String chapterId,
    String lessonId,
  ) =>
      '/subject/$subjectId/chapter/$chapterId/lesson/$lessonId/quiz';

  // Profil public
  static const userPath = '/user/:uid';
  static String user(String uid) => '/user/$uid';

  // Debug
  static const crash = '/_crash';
  static const showcase = '/_showcase';
  static const aiSmoke = '/_ai_smoke';
  static const testCourses = '/_test_courses';
  static const testCourseSlugSegment = ':slug';
  static String testCourseDetail(String slug) => '/_test_courses/$slug';
}
