---
story: 2.6
title: "Quiz — intégration contenu"
status: review
created: 2026-07-02
baseline_commit: a3f436d2452016381e50bc9ac557292353a571cb
---

## Story 2.6 : Quiz — intégration contenu

---

## User Story

En tant qu'élève, je veux pouvoir faire un quiz interactif sur une leçon ou un chapitre, afin de tester et consolider mes connaissances avec un retour immédiat sur chaque réponse.

---

## Acceptance Criteria

**AC1 — Entrée depuis la leçon**
Donné que je suis sur la page d'une leçon et que des questions existent dans `lessons/{lessonId}/quizzes/`,
Quand je tape le bouton "S'exercer" (`LessonCtaRow`),
Alors j'arrive sur `QuizPage` avec une session ≤ 15 questions issues de cette leçon.

**AC2 — Entrée depuis l'onglet Quiz du chapitre**
Donné que je suis sur l'onglet "Quiz" d'un chapitre,
Quand je tape "Commencer le quiz",
Alors j'arrive sur `QuizPage` avec une session ≤ 20 questions agrégées depuis toutes les leçons du chapitre.

**AC3 — Algorithme de pioche (client-side, offline-first)**
Donné un pool de questions issues d'un ou plusieurs quiz Firestore,
Quand `QuizPicker.pick*(questions)` est appelé,
Alors : (a) au plus 2 questions sont piochées par `notionId` non-null (questions sans notion regroupées ensemble, ≤ 2 également), (b) les groupes sont mélangés aléatoirement, (c) les questions dans chaque groupe sont mélangées aléatoirement, (d) la liste finale est tronquée à `max` si elle dépasse, puis mélangée une dernière fois, (e) les **options ne sont pas mélangées** — `correctIndex` reste valide tel quel.

**AC4 — Session quiz interactive**
Donné que j'ai une liste de questions piochées,
Quand je suis sur `QuizPage`,
Alors : (a) une question est affichée à la fois avec sa progression ("Question N/Total"), (b) je vois 4 options en boutons, (c) après avoir tapé une option, la bonne réponse est mise en évidence (vert) et ma mauvaise réponse (si applicable) en rouge, (d) l'explication s'affiche sous les options, (e) un bouton "Suivant" / "Voir le résultat" avance.

**AC5 — Écran de résultat**
Quand j'ai répondu à toutes les questions,
Alors un écran de résultat affiche mon score (X/N bonnes réponses) et deux actions : "Rejouer" (re-pioche une nouvelle session) et "Retour" (pop GoRouter).

**AC6 — État vide**
Donné que `lessons/{lessonId}/quizzes/` est vide ou que le chapitre n'a aucune question piochable (pool vide),
Quand j'ouvre la quiz (page ou onglet),
Alors un état vide "Questions bientôt disponibles" / "Questions coming soon" s'affiche — pas d'erreur rouge.

**AC7 — Gestion des erreurs réseau**
Donné qu'une erreur Firestore survient lors de la lecture des quizzes,
Quand `QuizPage` ou `QuizTab` tente de charger les données,
Alors `ContentErrorView` avec bouton "Réessayer" est affiché. `Right([])` (liste vide) ne produit pas d'erreur.

**AC8 — Score local uniquement**
Le score n'est jamais persisté en Firestore dans cette story. Epic 5 gère la persistance dans `users/{uid}/health/`. Aucun appel `users/{uid}` dans cette story.

**AC9 — Responsive**
`QuizPage` utilise `LayoutBuilder` avec breakpoints 600/840 dp (identiques à `LessonPage`). La zone de question est centrée dans 720 dp max sur tablette.

**AC10 — Pas de régression**
`flutter analyze` = 0 issue. `flutter test` = 0 régression. Les onglets Leçons, Exercices et Fiche sont inchangés. `LessonCtaRow` reste conforme Riverpod/GoRouter (pas de `Navigator.push`).

---

## Dev Notes

### État actuel (avant cette story)

**`ChapterPage`** (`presentation/pages/chapter_page.dart`) : `TabController(length: 4)`. Onglet "Quiz" (index 1) = `_PlaceholderTab` avec texte "Quiz bientôt disponibles" (à remplacer).

**`LessonPage`** (`presentation/pages/lesson_page.dart`) : widget `LessonCtaRow(isFr: isFr)` en bas du scroll. Paramètre unique `isFr` — "Faire le quiz" a `onPressed: () {}` (stub vide). `LessonPage` a déjà `subjectId`, `chapterId`, `lessonId`.

**`LessonCtaRow`** (`presentation/widgets/lesson_cta_row.dart`) : `StatelessWidget` avec param `isFr` uniquement. Boutons "Résumé" et "Faire le quiz" tous les deux à `onPressed: () {}`.

**`ContentRepository`** (`domain/repositories/content_repository.dart`) : 4 méthodes existantes. Pas de `getQuizQuestions`.

**`ContentFirestoreRepositoryImpl`** : constantes l.19-23 (`_kChapters`, `_kLessons`, `_kContent`). Pattern `collection().get()` + flatten dans `getNotions` si présent, sinon dupliquer le pattern `getLessons`. Ajouter `_kQuizzes = 'quizzes'`.

**`app_routes.dart`** : routes existantes `subjectPath`, `chapterSegment`, `lessonSegment` + builders. Pas de routes quiz.

**Données Firestore seedées** (Story 2.1) : `lessons/{lessonId}/quizzes/{quizId}` avec champs :

```json
{
  "lessonId": "...",
  "version": 1,
  "questions": [
    {
      "id": "chinois_3e_q01_1",
      "notionId": null,
      "text": { "fr": "...", "en": "..." },
      "type": "mcq",
      "options": { "fr": ["A", "B", "C", "D"], "en": ["A", "B", "C", "D"] },
      "correctIndex": 0,
      "explanation": { "fr": "...", "en": "..." }
    }
  ]
}
```

`notionId` peut être `null` (question liée à la leçon mais pas à une notion spécifique) ou une string (ex. `"n01"`).

### Ce que la story change

| Fichier | Changement |
| --- | --- |
| `domain/entities/quiz_question_entity.dart` | **NOUVEAU** — `QuizQuestionEntity` Equatable |
| `domain/services/quiz_picker.dart` | **NOUVEAU** — algorithme de pioche pur Dart |
| `data/models/quiz_question_model.dart` | **NOUVEAU** — `QuizQuestionModel.fromMap()` + `toEntity()` |
| `domain/repositories/content_repository.dart` | Ajouter `getQuizQuestions(lessonId)` |
| `data/repositories/content_firestore_repository_impl.dart` | Implémenter `getQuizQuestions` |
| `features/content/providers.dart` | Ajouter `lessonQuizSessionProvider` + `chapterQuizSessionProvider` |
| `presentation/pages/quiz_page.dart` | **NOUVEAU** — session quiz UI (≤ 300 lignes) |
| `presentation/widgets/quiz_tab.dart` | **NOUVEAU** — onglet Quiz chapitre (CTA + état vide) |
| `presentation/pages/chapter_page.dart` | Remplacer `_PlaceholderTab` Quiz (index 1) par `QuizTab` |
| `presentation/widgets/lesson_cta_row.dart` | Ajouter `subjectId`, `chapterId`, `lessonId` + wirer "Faire le quiz" |
| `core/routing/app_routes.dart` | Ajouter `quizSegment` + builders `chapterQuiz` / `lessonQuiz` |
| `core/routing/app_router.dart` | Ajouter 2 `GoRoute` quiz (chapitre + leçon) |

### Règles architecture

- **Règle 1** : `QuizQuestionEntity` et `QuizPicker` domain-only — aucun import Flutter/Firebase/Riverpod.
- **Règle 2** : mapping `FirebaseException → ContentFailure` uniquement dans `content_firestore_repository_impl.dart`.
- **Règle 3** : log obligatoire dans `lessonQuizSessionProvider` et `chapterQuizSessionProvider` : `kind=... message=...`.
- **Règle 6** : `flutter_smooth_markdown` / `PedagogicalContent` non utilisés dans cette story (quiz = texte brut, pas Markdown).
- **Règle 11** : `QuizTab` et `QuizPage` dans des fichiers séparés. Aucune classe privée géante dans `chapter_page.dart`.
- **Règle 12** : `QuizPage` cible ≤ 300 lignes. `QuizTab` cible ≤ 80 lignes. Si `QuizPage` dépasse, extraire `_QuizQuestionCard` et `_QuizResultScreen` en widgets privés dans le même fichier.
- **Règle 14** : navigation via `context.push(AppRoutes.lessonQuiz(...))` et `context.push(AppRoutes.chapterQuiz(...))` — pas de `Navigator.push`.
- **Règle 15** : `ref.watch(lessonQuizSessionProvider(lessonId))` dans `build()`. Providers `autoDispose.family`. `ref.invalidate(provider)` pour "Rejouer".

### Cost-benefit Firestore (règle 10.m)

- **Lecture par session** : `lessons/{lessonId}/quizzes/` = 1 `collection.get()` → lit N docs quiz (N ≤ 5 par leçon en pratique). Pas de `limit()` nécessaire car le nombre de quiz docs est borné par le seed (~2-5 par leçon).
- **Quiz chapitre** : `Future.wait(lessons.map((l) => repo.getQuizQuestions(l.lessonId)))` → M leçons × N quiz = M×N reads. Exemple : 5 leçons × 3 quizzes = 15 reads. Acceptable par session.
- **Cache offline** : quiz docs sont statiques (pas de `snapshots()`). `.get()` → cache Firestore actif. Répétition de session = 0 reads supplémentaires.
- **À 10 000 DAU, 10% ouvrent quiz** : 1 000 sessions × ~10 reads moyens = 10 000 reads/jour feature quiz. Négligeable vs. baseline lecture contenu.
- **Pas de nouvel index Firestore** : `collection().get()` sur `quizzes/` = lecture complète sous-collection, auto-indexée par Firestore.
- **Trade-off accepté** : pour le quiz chapitre, on re-lit les quizzes de chaque leçon même si une partie était déjà en cache (accès par chemin différent). Alternative évitée : collection globale `quizzes/{quizId}` avec index composite `lessonId + chapterId` = plus coûteux en index + migration schema.

### Algorithme de pioche — détail

```dart
// domain/services/quiz_picker.dart

const _kQuestionsPerNotion = 2;
const _kMaxLessonSession = 15;
const _kMaxChapterSession = 20;

abstract final class QuizPicker {
  static List<QuizQuestionEntity> pickLessonSession(
    List<QuizQuestionEntity> questions,
  ) =>
      _pick(questions, _kMaxLessonSession);

  static List<QuizQuestionEntity> pickChapterSession(
    List<QuizQuestionEntity> questions,
  ) =>
      _pick(questions, _kMaxChapterSession);

  static List<QuizQuestionEntity> _pick(
    List<QuizQuestionEntity> questions,
    int max,
  ) {
    final Map<String, List<QuizQuestionEntity>> groups = {};
    for (final q in questions) {
      groups.putIfAbsent(q.notionId ?? '_none_', () => []).add(q);
    }

    final rng = Random();
    final keys = groups.keys.toList()..shuffle(rng);
    final picked = <QuizQuestionEntity>[];
    for (final key in keys) {
      final pool = [...groups[key]!]..shuffle(rng);
      picked.addAll(pool.take(_kQuestionsPerNotion));
    }

    if (picked.length > max) picked.shuffle(rng);
    return picked.length > max ? picked.sublist(0, max) : picked;
  }
}
```

Les **options** ne sont **pas** mélangées — `correctIndex` fait référence à la position originale stockée en Firestore.

### Implémentation `getQuizQuestions` dans le repo

```dart
static const _kQuizzes = 'quizzes';

@override
Future<Either<ContentFailure, List<QuizQuestionEntity>>> getQuizQuestions(
  String lessonId,
) async {
  try {
    final snapshot = await _firestore
        .collection(_kLessons)
        .doc(lessonId)
        .collection(_kQuizzes)
        .get();
    final questions = snapshot.docs
        .expand((doc) {
          final raw = doc.data()['questions'] as List? ?? [];
          return raw
              .whereType<Map<String, dynamic>>()
              .map(QuizQuestionModel.fromMap)
              .map((m) => m.toEntity());
        })
        .toList();
    AppLogger.d(
      'content.getQuizQuestions($lessonId): ${questions.length} questions',
    );
    return Right(questions);
  } on FirebaseException catch (e) {
    final failure = _mapFirebaseException(e, context: 'getQuizQuestions($lessonId)');
    AppLogger.e('content.getQuizQuestions: kind=${failure.kind.name} message=${failure.message}');
    return Left(failure);
  } catch (e) {
    AppLogger.e('content.getQuizQuestions unexpected error', error: e);
    return Left(ContentFailure.unknown(e.toString()));
  }
}
```

### Providers à ajouter dans `providers.dart`

```dart
/// Questions piochées pour une session quiz leçon (≤ 15, 2/notion).
final lessonQuizSessionProvider =
    FutureProvider.autoDispose.family<List<QuizQuestionEntity>, String>(
  (ref, lessonId) async {
    final result =
        await ref.watch(contentRepositoryProvider).getQuizQuestions(lessonId);
    return result.fold(
      (failure) {
        AppLogger.e(
          'lessonQuizSessionProvider: kind=${failure.kind.name} message=${failure.message}',
        );
        throw failure;
      },
      QuizPicker.pickLessonSession,
    );
  },
);

/// Questions piochées pour une session quiz chapitre (≤ 20, 2/notion, toutes leçons).
final chapterQuizSessionProvider =
    FutureProvider.autoDispose.family<List<QuizQuestionEntity>, String>(
  (ref, chapterId) async {
    final lessons = await ref.watch(lessonsProvider(chapterId).future);
    final repo = ref.read(contentRepositoryProvider);
    final results = await Future.wait(
      lessons.map((l) => repo.getQuizQuestions(l.lessonId)),
    );
    final allQuestions = results
        .expand((r) => r.fold((_) => <QuizQuestionEntity>[], (q) => q))
        .toList();
    AppLogger.d(
      'chapterQuizSessionProvider($chapterId): ${allQuestions.length} questions brutes',
    );
    return QuizPicker.pickChapterSession(allQuestions);
  },
);
```

### Routes quiz (structure GoRouter)

```text
/subject/:subjectId
  /chapter/:chapterId
    /quiz                          ← chapterQuiz
    /lesson/:lessonId
      /quiz                        ← lessonQuiz
```

Dans `app_routes.dart`, ajouter :

```dart
static const quizSegment = 'quiz';
static String chapterQuiz(String subjectId, String chapterId) =>
    '/subject/$subjectId/chapter/$chapterId/quiz';
static String lessonQuiz(String subjectId, String chapterId, String lessonId) =>
    '/subject/$subjectId/chapter/$chapterId/lesson/$lessonId/quiz';
```

Dans `app_router.dart`, ajouter deux `GoRoute(path: 'quiz')` :

- Un dans les enfants du `GoRoute` `chapter/:chapterId` → `QuizPage(chapterId: state.pathParameters['chapterId']!)`
- Un dans les enfants du `GoRoute` `lesson/:lessonId` → `QuizPage(chapterId: ..., lessonId: state.pathParameters['lessonId'])`

### Stratégie responsive

`QuizPage` utilise `LayoutBuilder` + `effectiveMaxWidth` identique à `LessonPage` (720 dp tablet / 600 dp phone large / full width phone). Centrage avec `Center > ConstrainedBox(maxWidth: effectiveMaxWidth)`.

### Composants à consommer

`ContentErrorView` (retry sur erreur réseau), `AppSkeleton` (skeleton chargement quiz), tokens `AppColors / AppSpacing / AppFontSize / AppIconSize / AppRadius / AppTypography / AppBorderWidth`. Pas de `PedagogicalContent` (quiz = texte brut, pas Markdown).

---

## Tasks / Subtasks

### T1 — Domain : QuizQuestionEntity

- [x] T1.1 — Créer `lib/features/content/domain/entities/quiz_question_entity.dart`
  - `class QuizQuestionEntity extends Equatable`
  - Champs : `id`, `notionId?`, `textFr`, `textEn`, `optionsFr`, `optionsEn`, `correctIndex`, `explanationFr?`, `explanationEn?`
  - Méthodes : `textFor(languageCode)`, `optionsFor(languageCode)`, `explanationFor(languageCode)`
  - `props` Equatable complet

### T2 — Domain : QuizPicker

- [x] T2.1 — Créer `lib/features/content/domain/services/quiz_picker.dart`
  - Constantes `_kQuestionsPerNotion = 2`, `_kMaxLessonSession = 15`, `_kMaxChapterSession = 20`
  - `abstract final class QuizPicker` avec méthodes statiques `pickLessonSession` et `pickChapterSession`
  - Algorithme `_pick` : grouper par `notionId ?? '_none_'`, mélanger groupes, 2 par groupe, mélanger final, cap `max`
  - Import `dart:math` uniquement (pas Flutter/Firebase/Riverpod)

### T3 — Data : QuizQuestionModel

- [x] T3.1 — Créer `lib/features/content/data/models/quiz_question_model.dart`
  - `class QuizQuestionModel` avec `fromMap(Map<String, dynamic>)` factory
  - Parsing : `text.fr`, `text.en`, `options.fr` (List), `options.en` (List), `correctIndex`, `explanation.fr?`, `explanation.en?`, `notionId?`
  - Méthode `toEntity()` → `QuizQuestionEntity`

### T4 — Domain : ContentRepository

- [x] T4.1 — `lib/features/content/domain/repositories/content_repository.dart`
  - Ajouter import `quiz_question_entity.dart`
  - Ajouter : `Future<Either<ContentFailure, List<QuizQuestionEntity>>> getQuizQuestions(String lessonId);`

### T5 — Data : ContentFirestoreRepositoryImpl

- [x] T5.1 — `lib/features/content/data/repositories/content_firestore_repository_impl.dart`
  - Ajouter import `quiz_question_model.dart` et `quiz_question_entity.dart`
  - Ajouter `static const _kQuizzes = 'quizzes';`
  - Implémenter `getQuizQuestions(String lessonId)` — pattern `collection().get()` + `expand` questions arrays + `fromMap().toEntity()`

### T6 — Providers

- [x] T6.1 — `lib/features/content/providers.dart`
  - Ajouter imports `quiz_question_entity.dart`, `quiz_picker.dart`
  - Ajouter `lessonQuizSessionProvider` (`FutureProvider.autoDispose.family<List<QuizQuestionEntity>, String>`)
  - Ajouter `chapterQuizSessionProvider` (idem, avec `Future.wait` sur toutes les leçons)

### T7 — Routing

- [x] T7.1 — `lib/core/routing/app_routes.dart`
  - Ajouter `static const quizSegment = 'quiz';`
  - Ajouter `static String chapterQuiz(String subjectId, String chapterId) => '/subject/$subjectId/chapter/$chapterId/quiz';`
  - Ajouter `static String lessonQuiz(String subjectId, String chapterId, String lessonId) => '/subject/$subjectId/chapter/$chapterId/lesson/$lessonId/quiz';`

- [x] T7.2 — `lib/core/routing/app_router.dart`
  - Dans les `routes:` du `GoRoute` `chapter/:chapterId` : ajouter `GoRoute(path: 'quiz', builder: (_, state) => QuizPage(chapterId: state.pathParameters['chapterId']!))`
  - Dans les `routes:` du `GoRoute` `lesson/:lessonId` : ajouter `GoRoute(path: 'quiz', builder: (_, state) => QuizPage(chapterId: state.pathParameters['chapterId']!, lessonId: state.pathParameters['lessonId']))`

### T8 — Présentation : QuizPage

- [x] T8.1 — Créer `lib/features/content/presentation/pages/quiz_page.dart`
  - `class QuizPage extends ConsumerStatefulWidget` avec `chapterId` (required) et `lessonId?` (nullable — null = quiz chapitre)
  - State : `_currentIndex`, `_selectedIndex?`, `_score`, `_showResult`
  - Si `lessonId != null` : `ref.watch(lessonQuizSessionProvider(lessonId!))`
  - Si `lessonId == null` : `ref.watch(chapterQuizSessionProvider(chapterId))`
  - `.when(loading:, error:, data:)` :
    - `loading:` → `_QuizLoadingSkeleton` (3 `AppSkeleton`)
    - `error:` → `ContentErrorView` avec retry (via `ref.invalidate`)
    - `data: (questions)` → si vide → `_QuizEmptyState` ; sinon → session quiz
  - Session : question card (texte + 4 boutons options), feedback couleur (vert/rouge post-sélection), explication, bouton Suivant/Voir résultat, `_QuizResultScreen` en fin
  - "Rejouer" : `ref.invalidate(provider)` + reset state
  - Responsive via `LayoutBuilder`

### T9 — Présentation : QuizTab

- [x] T9.1 — Créer `lib/features/content/presentation/widgets/quiz_tab.dart`
  - `class QuizTab extends StatelessWidget` avec `subjectId`, `chapterId` (required)
  - CTA card centré : icône `Icons.quiz_outlined`, titre "Teste tes connaissances" / "Test your knowledge", sous-titre, bouton "Commencer le quiz" / "Start quiz"
  - `onPressed:` → `context.push(AppRoutes.chapterQuiz(subjectId, chapterId))`
  - Pas de prefetch (chargement à l'ouverture de `QuizPage`)

### T10 — Présentation : ChapterPage

- [x] T10.1 — `lib/features/content/presentation/pages/chapter_page.dart`
  - Ajouter import `quiz_tab.dart`
  - Remplacer le 2e enfant du `TabBarView` (index 1, `_PlaceholderTab` "Quiz bientôt disponibles") par :

```dart
QuizTab(
  subjectId: widget.subjectId,
  chapterId: widget.chapterId,
),
```

### T11 — Présentation : LessonCtaRow

- [x] T11.1 — `lib/features/content/presentation/widgets/lesson_cta_row.dart`
  - Changer en `ConsumerWidget` ou garder `StatelessWidget` avec `BuildContext` (context.push ne nécessite pas `ref` — `StatelessWidget` suffit)
  - Ajouter params `subjectId`, `chapterId`, `lessonId` (tous `required String`)
  - Ajouter import `go_router/go_router.dart` et `app_routes.dart`
  - Wirer le bouton "S'exercer" (ex "Faire le quiz") : `onPressed: () => context.push(AppRoutes.lessonQuiz(subjectId, chapterId, lessonId))`
  - Le bouton "Résumé" a été supprimé (redesign validé post code-review — bouton redondant avec l'onglet Fiche du chapitre)

- [x] T11.2 — `lib/features/content/presentation/pages/lesson_page.dart`
  - Mettre à jour l'appel de `LessonCtaRow` pour passer les 3 nouveaux params :

```dart
LessonCtaRow(
  isFr: isFr,
  subjectId: widget.subjectId,
  chapterId: widget.chapterId,
  lessonId: widget.lessonId,
),
```

### T12 — Tests unitaires

- [x] T12.1 — Créer `test/features/content/domain/services/quiz_picker_test.dart`
  - `group('QuizPicker', () {`
  - Test : pool vide → retourne `[]`
  - Test : 1 notion avec 5 questions → retourne exactement 2 questions
  - Test : 2 notions avec 3 questions chacune → retourne 4 questions (2+2)
  - Test : pool de 30 questions variées → retourne ≤ 15 pour `pickLessonSession`
  - Test : pool de 30 questions variées → retourne ≤ 20 pour `pickChapterSession`
  - Test : `correctIndex` des questions retournées inchangé (options pas mélangées)

- [x] T12.2 — `test/features/content/data/repositories/content_firestore_repository_impl_test.dart`
  - Étendre avec `group('getQuizQuestions', () {`
  - Cas succès multi-docs : 2 quiz docs avec 3 questions chacun → `Right(List<QuizQuestionEntity>)` avec 6 éléments
  - Cas sous-collection vide : `getQuizQuestions('lesson_sans_quiz')` → `Right([])`

### T13 — Sprint status

- [x] T13.1 — `project_manage/implementation-artifacts/sprint-status.yaml` : `2-6-quiz-content-integration: backlog → in-progress → review`

### Review Findings

- [x] \[Review\]\[Decision\] LessonCtaRow redesign — bouton "Résumé" supprimé (T11.1 : garder en stub) et libellé changé en "S'exercer" au lieu de "Faire le quiz" (AC1) — **validé** : redesign intentionnel, AC1 + T11.1 mis à jour \[lesson_cta_row.dart\]
- [ ] \[Review\]\[Patch\] (High) `_selectAnswer` sans garde `_currentIndex < questions.length` après replay — crash potentiel si rebuild intervient pendant transition \[quiz_session_view.dart\]
- [ ] \[Review\]\[Patch\] (High) `correctIndex` non validé contre `options.length` — crash sur données Firestore corrompues \[quiz_question_model.dart, quiz_session_view.dart\]
- [ ] \[Review\]\[Patch\] (Med) `ref.invalidate` avant `setState` dans `_replay()` — flash 1 frame d'état `_answers` périmé \[quiz_session_view.dart\]
- [ ] \[Review\]\[Patch\] (Med) Breakpoints LayoutBuilder avec `.w` (`840.w`/`600.w`) — doit être raw dp `840`/`600` sans ScreenUtil \[quiz_session_view.dart\]
- [ ] \[Review\]\[Patch\] (Med) `lessonQuizSessionProvider` utilise `ref.watch(contentRepositoryProvider)` mais `chapterQuizSessionProvider` utilise `ref.read` — harmoniser en `ref.watch` \[providers.dart\]
- [ ] \[Review\]\[Patch\] (Med) `QuizQuestionModel.fromMap` : fallback `id: ''` si champ absent — utiliser l'ID du document Firestore comme fallback \[quiz_question_model.dart\]
- [ ] \[Review\]\[Patch\] (Med) `chapterQuizSessionProvider` ne logue pas `kind=` quand `lessonsProvider` throw — CLAUDE.md règle 3 \[providers.dart\]
- [ ] \[Review\]\[Patch\] (Med) `getQuizQuestions` sans `.limit()` — CLAUDE.md règle 10c (ajouter `.limit(50)`) \[content_firestore_repository_impl.dart\]
- [ ] \[Review\]\[Patch\] (Low) QuizPicker pas de shuffle final quand `picked.length ≤ max` — AC3(d) exige shuffle de la liste finale \[quiz_picker.dart\]
- [ ] \[Review\]\[Patch\] (Low) `EdgeInsets.all(24)` magic number → `EdgeInsets.all(AppSpacing.s6)` \[quiz_session_view.dart\]
- [ ] \[Review\]\[Patch\] (Low) `Colors.white` hardcodé (6+ occurrences) → token `AppColors.card` ou équivalent \[quiz_session_view.dart, quiz_result_screen.dart, quiz_review_screen.dart\]
- [ ] \[Review\]\[Patch\] (Low) `QuizResultScreen` et `QuizReviewScreen` sans contrainte tablet `SizedBox(width: maxWidth)` — AC9 non couvert pour ces écrans \[quiz_result_screen.dart, quiz_review_screen.dart\]
- [x] \[Review\]\[Defer\] Collection `notions/` non seedée — `getNotion` retourne toujours `notFound`, "Besoin d'aide" affiche toujours le fallback — deferred, infrastructure seed
- [x] \[Review\]\[Defer\] `lessonsProvider autoDispose` double-read potentiel dans `chapterQuizSessionProvider` — deferred, comportement Riverpod pré-existant
- [x] \[Review\]\[Defer\] i18n debt — ternaires `isFr ? 'fr' : 'en'` non externalisés en ARB dans les widgets quiz — deferred, pattern pré-existant codebase
- [x] \[Review\]\[Defer\] `QuizMathText` défini dans `quiz_session_view.dart` au lieu de `core/widgets/` — deferred, usage unique à ce stade
- [x] \[Review\]\[Defer\] `QuizHelpSheet.notionId` contrat nullable implicite (paramètre `String` alors que sémantiquement nullable) — deferred, pre-existing
- [x] \[Review\]\[Defer\] `.w` scaling dans les fichiers test sans init ScreenUtil — deferred, tests passent actuellement
- [x] \[Review\]\[Defer\] `QuizReviewScreen` bottom inset implicite (SafeArea parent atténue) — deferred, low risk
- [x] \[Review\]\[Defer\] 3e action "Voir mes réponses" sur écran résultat — non spécifiée dans AC5 (scope creep bénin) — deferred, non-blocking
- [x] \[Review\]\[Defer\] `LayoutBuilder` dans `QuizSessionView` au lieu de `QuizPage` (déviation structurelle mineure vs spec) — deferred, fonctionnellement équivalent
- [x] \[Review\]\[Defer\] `_answers` sans garde longueur (race condition fast-tap faible risque) — deferred, low risk
- [x] \[Review\]\[Defer\] `Size.fromHeight(52)` dans AppBar — couvert par exception AppNavBar (hauteur physique stable) — deferred, intentionnel

---

## Definition of Done

- [x] `flutter analyze` = 0 issue
- [x] `flutter test` = 0 régression induite (422 pass vs 420 baseline; 28 échecs pré-existants sur baseline) + `quiz_picker_test.dart` vert (7 tests) + extension repo test verte (2 tests)
- [x] Onglet "Quiz" du chapitre affiche la CTA et navigue vers `QuizPage` (quiz chapitre)
- [x] Bouton "Faire le quiz" en bas d'une leçon navigue vers `QuizPage` (quiz leçon)
- [x] Session quiz complète fonctionnelle : question → réponse → feedback + explication → suivant → résultat → rejouer
- [x] État vide "Questions bientôt disponibles" si aucune question disponible
- [x] Score non persisté (aucun appel `users/{uid}`)
- [ ] PR ≤ 400 lignes de diff (à vérifier avant push)
