# Story 2.2 : Navigation contenu — SubjectDetailPage → ChapterPage → LessonPage → NotionPage (UI hardcodée)

Status: ready-for-dev

## Story

En tant qu'élève authentifié,
je veux naviguer depuis la page détail d'une matière jusqu'aux notions individuelles (matière → chapitres → leçons → notions),
afin de pouvoir explorer la structure du contenu pédagogique avant l'intégration Firebase.

## Acceptance Criteria

1. **AC1 — SubjectDetailPage** : La route `/subject/:subjectId` affiche une page avec le nom de la matière en titre et la liste des chapitres de cette matière. Chaque chapitre est cliquable et navigue vers `/subject/:subjectId/chapter/:chapterId`. L'ancien placeholder est supprimé.

2. **AC2 — ChapterPage** : La route `/subject/:subjectId/chapter/:chapterId` affiche le titre du chapitre et la liste des leçons. Chaque leçon est cliquable et navigue vers `.../lesson/:lessonId`.

3. **AC3 — LessonPage** : La route `/subject/:subjectId/chapter/:chapterId/lesson/:lessonId` affiche le titre de la leçon et la liste des notions. Chaque notion est cliquable et navigue vers `.../notion/:notionId`.

4. **AC4 — NotionPage** : La route `.../notion/:notionId` affiche le titre de la notion et le widget `PedagogicalContent` avec le contenu Markdown de la leçon parente (hardcodé). Le contenu inclut du texte riche, du LaTeX bloc (`$$...$$`), du LaTeX inline (`$...$`) et un diagramme Mermaid (rendu via mermaid.ink).

5. **AC5 — Données hardcodées bilingues** : Les données fake correspondent exactement aux entrées de `content_demo.json` (francophone_math + anglophone_physics). La langue d'affichage est déterminée par `user.subSystem` (`fr` pour francophone, `en` pour anglophone) via le provider existant. Aucun appel Firestore dans cette story.

6. **AC6 — Responsive** : Chaque page s'adapte aux 3 breakpoints :
   - **phone (<600 dp)** : liste mono-colonne, bottom navigation visible
   - **phone landscape / tablet narrow (600–839 dp)** : liste mono-colonne centrée max 600 dp
   - **tablet (≥840 dp)** : split-view optionnel (TOC gauche ~300 dp + contenu droit) sur SubjectDetailPage et ChapterPage ; NavigationRail remplace bottom tabs
   Golden test obligatoire pour phone et tablet (≥840 dp) sur chaque nouvelle page.

7. **AC7 — Navigation back** : Le bouton retour OS et l'AppBar back button fonctionnent sur toutes les pages. La barre de navigation reste visible en bas (ou NavigationRail en tablet) sur SubjectDetailPage et ChapterPage.

8. **AC8 — Analyse statique** : `flutter analyze` = 0 warning / 0 error. `flutter test` = 0 régression vs baseline. Les nouvelles pages ont au minimum 1 widget test (smoke test + golden phone + golden tablet).

9. **AC9 — HALT après UI** : L'agent dev s'arrête après validation de l'UI hardcodée. Aucune intégration Firestore dans cette story (réservé Story 2.4).

## Tasks / Subtasks

- [ ] **T1 — Entités domain** (AC5)
  - [ ] T1.1 Créer `mobile_app/lib/features/content/domain/entities/chapter_entity.dart` — freezed : `chapterId`, `subjectId`, `order`, `titleFr`, `titleEn`, `descriptionFr`, `descriptionEn`
  - [ ] T1.2 Créer `mobile_app/lib/features/content/domain/entities/lesson_entity.dart` — freezed : `lessonId`, `chapterId`, `order`, `titleFr`, `titleEn`, `contentFr`, `contentEn`
  - [ ] T1.3 Créer `mobile_app/lib/features/content/domain/entities/notion_entity.dart` — freezed : `notionId`, `lessonId`, `order`, `titleFr`, `titleEn`
  - [ ] T1.4 Lancer `dart run build_runner build --delete-conflicting-outputs` et vérifier génération `.freezed.dart` et `.g.dart`

- [ ] **T2 — Données fake** (AC5)
  - [ ] T2.1 Créer `mobile_app/lib/features/content/data/fake/fake_content_data.dart` — constantes `kFakeChapters`, `kFakeLessons`, `kFakeNotions` calquées sur `content_demo.json` (francophone_math + anglophone_physics)
  - [ ] T2.2 Vérifier que `kFakeChapters` contient exactement 8 chapitres (4 franco_math + 4 anglo_physics), `kFakeLessons` 16, `kFakeNotions` 32
  - [ ] T2.3 S'assurer qu'au moins une leçon `contentFr`/`contentEn` contient : titre H2, paragraphe, LaTeX bloc, LaTeX inline, Mermaid

- [ ] **T3 — Providers fake** (AC5)
  - [ ] T3.1 Créer `mobile_app/lib/features/content/presentation/providers.dart` avec Riverpod `@riverpod`:
    - `chaptersForSubject(String subjectId)` → `List<ChapterEntity>` filtrée depuis `kFakeChapters`
    - `lessonsForChapter(String chapterId)` → `List<LessonEntity>` filtrée depuis `kFakeLessons`
    - `notionsForLesson(String lessonId)` → `List<NotionEntity>` filtrée depuis `kFakeNotions`
    - `lessonById(String lessonId)` → `LessonEntity?`
  - [ ] T3.2 Lancer build_runner pour générer `.g.dart`

- [ ] **T4 — Widgets réutilisables feature** (AC1–AC4)
  - [ ] T4.1 Créer `mobile_app/lib/features/content/presentation/widgets/chapter_card.dart` — `ChapterCard({required ChapterEntity chapter, required VoidCallback onTap})` — titre, sous-titre optionnel (description), icône flèche
  - [ ] T4.2 Créer `mobile_app/lib/features/content/presentation/widgets/lesson_tile.dart` — `LessonTile({required LessonEntity lesson, required String languageCode, required VoidCallback onTap})` — titre localisé, icône
  - [ ] T4.3 Créer `mobile_app/lib/features/content/presentation/widgets/notion_tile.dart` — `NotionTile({required NotionEntity notion, required String languageCode, required VoidCallback onTap})` — titre localisé

- [ ] **T5 — SubjectDetailPage** (AC1, AC6, AC7)
  - [ ] T5.1 Créer `mobile_app/lib/features/content/presentation/pages/subject_detail_page.dart` — `ConsumerWidget`, paramètre `subjectId`
  - [ ] T5.2 Récupérer les chapitres via `ref.watch(chaptersForSubjectProvider(subjectId))`
  - [ ] T5.3 Afficher liste de `ChapterCard` — tap → `context.push('/subject/$subjectId/chapter/$chapterId')`
  - [ ] T5.4 Titre AppBar = nom de la matière (hardcodé via `subjectId` lookup dans une map locale) + back button
  - [ ] T5.5 Implémenter stratégie responsive (voir Dev Notes § Responsive)

- [ ] **T6 — ChapterPage** (AC2, AC6, AC7)
  - [ ] T6.1 Créer `mobile_app/lib/features/content/presentation/pages/chapter_page.dart` — `ConsumerWidget`, paramètres `subjectId` + `chapterId`
  - [ ] T6.2 Récupérer les leçons via `ref.watch(lessonsForChapterProvider(chapterId))`
  - [ ] T6.3 Afficher liste de `LessonTile` — tap → `context.push('/subject/$subjectId/chapter/$chapterId/lesson/$lessonId')`
  - [ ] T6.4 Titre AppBar = titre du chapitre (depuis `chaptersForSubjectProvider` ou map locale)

- [ ] **T7 — LessonPage** (AC3, AC6, AC7)
  - [ ] T7.1 Créer `mobile_app/lib/features/content/presentation/pages/lesson_page.dart` — `ConsumerWidget`, paramètres `subjectId` + `chapterId` + `lessonId`
  - [ ] T7.2 Récupérer les notions via `ref.watch(notionsForLessonProvider(lessonId))`
  - [ ] T7.3 Afficher liste de `NotionTile` — tap → `context.push('.../notion/$notionId')`
  - [ ] T7.4 Titre AppBar = titre de la leçon

- [ ] **T8 — NotionPage** (AC4, AC6, AC7)
  - [ ] T8.1 Créer `mobile_app/lib/features/content/presentation/pages/notion_page.dart` — `ConsumerWidget`, paramètres `subjectId` + `chapterId` + `lessonId` + `notionId`
  - [ ] T8.2 Récupérer la leçon parente via `ref.watch(lessonByIdProvider(lessonId))`
  - [ ] T8.3 Afficher `PedagogicalContent(content: lesson.contentFr)` ou `.contentEn` selon `languageCode`
  - [ ] T8.4 Titre AppBar = titre de la notion

- [ ] **T9 — Router : remplacer placeholder + nouvelles routes** (AC1–AC4)
  - [ ] T9.1 Dans `mobile_app/lib/core/routing/app_router.dart`, remplacer l'import et la route `/subject/:subjectId` qui pointe vers `subject_detail_placeholder_page.dart` par `SubjectDetailPage`
  - [ ] T9.2 Ajouter route `/subject/:subjectId/chapter/:chapterId` → `ChapterPage`
  - [ ] T9.3 Ajouter route `/subject/:subjectId/chapter/:chapterId/lesson/:lessonId` → `LessonPage`
  - [ ] T9.4 Ajouter route `/subject/:subjectId/chapter/:chapterId/lesson/:lessonId/notion/:notionId` → `NotionPage`
  - [ ] T9.5 Supprimer `subject_detail_placeholder_page.dart` (ou déplacer en archive si référencé ailleurs)
  - [ ] T9.6 Vérifier que `flutter analyze` = 0 après suppression du placeholder

- [ ] **T10 — Tests** (AC8)
  - [ ] T10.1 Smoke test `SubjectDetailPage` : renders sans erreur avec `subjectId = 'francophone_math'`
  - [ ] T10.2 Smoke test `ChapterPage` : renders sans erreur avec `chapterId = 'franco_math_ch01'`
  - [ ] T10.3 Smoke test `LessonPage` : renders sans erreur avec `lessonId = 'franco_math_ch01_l01'`
  - [ ] T10.4 Smoke test `NotionPage` : renders sans erreur, `PedagogicalContent` présent dans tree
  - [ ] T10.5 Golden phone (375×812) pour `SubjectDetailPage` + `NotionPage`
  - [ ] T10.6 Golden tablet (1024×1366) pour `SubjectDetailPage` + `NotionPage`
  - [ ] T10.7 `flutter test` = 0 régression vs baseline (compter tests avant + après)
  - [ ] T10.8 `flutter analyze` = 0 warning

- [ ] **T11 — HALT : attendre validation porteur** (AC9)
  - [ ] T11.1 Préparer PR avec les 4 pages + routes + données fake
  - [ ] T11.2 HALT — ne pas avancer vers l'intégration Firestore (Story 2.4) sans validation porteur

## Dev Notes

### Contexte Epic 2 — Workflow UI-first

**Règle porteur (2026-06-21)** : Livrer l'UI avec données simulées, stopper après PR merge et validation, puis Story 2.4 remplace TOUT le code fake par l'intégration Firestore. L'agent dev doit s'arrêter à T11.1 et ne pas coder de repository réel.

Cette story crée la feature `lib/features/content/` (n'existe pas encore). La structure cible :

```
lib/features/content/
├── domain/
│   └── entities/
│       ├── chapter_entity.dart
│       ├── chapter_entity.freezed.dart  # généré
│       ├── lesson_entity.dart
│       ├── lesson_entity.freezed.dart   # généré
│       ├── notion_entity.dart
│       └── notion_entity.freezed.dart   # généré
├── data/
│   └── fake/
│       └── fake_content_data.dart       # constantes List<Entity> hardcodées
└── presentation/
    ├── pages/
    │   ├── subject_detail_page.dart
    │   ├── chapter_page.dart
    │   ├── lesson_page.dart
    │   └── notion_page.dart
    ├── widgets/
    │   ├── chapter_card.dart
    │   ├── lesson_tile.dart
    │   └── notion_tile.dart
    └── providers.dart
```

**Pas de couche `data/repositories/` ni `domain/use_cases/`** dans cette story — réservé Story 2.4.

---

### Router existant — état actuel

`mobile_app/lib/core/routing/app_router.dart` (ligne 12) :
```dart
import '../../features/dashboard/presentation/subject_detail_placeholder_page.dart';
```
Route `/subject/:subjectId` (lignes 111–113) : pointe vers ce placeholder. **T9 doit remplacer** cet import et cette destination.

Les 4 branches du stateful shell : `/dashboard` (branch 0), `/courses` (branch 1), `/exams` (branch 2), `/profile` (branch 3). La barre de navigation est gérée par `MainShell` — les nouvelles routes sont des push GoRouter classiques, **pas** des branches shell.

```dart
// Pattern de route imbriquée GoRouter à utiliser :
GoRoute(
  path: '/subject/:subjectId',
  builder: (ctx, state) => SubjectDetailPage(
    subjectId: state.pathParameters['subjectId']!,
  ),
  routes: [
    GoRoute(
      path: 'chapter/:chapterId',
      builder: (ctx, state) => ChapterPage(
        subjectId: state.pathParameters['subjectId']!,
        chapterId: state.pathParameters['chapterId']!,
      ),
      routes: [
        GoRoute(
          path: 'lesson/:lessonId',
          builder: (ctx, state) => LessonPage(
            subjectId: state.pathParameters['subjectId']!,
            chapterId: state.pathParameters['chapterId']!,
            lessonId: state.pathParameters['lessonId']!,
          ),
          routes: [
            GoRoute(
              path: 'notion/:notionId',
              builder: (ctx, state) => NotionPage(
                subjectId: state.pathParameters['subjectId']!,
                chapterId: state.pathParameters['chapterId']!,
                lessonId: state.pathParameters['lessonId']!,
                notionId: state.pathParameters['notionId']!,
              ),
            ),
          ],
        ),
      ],
    ),
  ],
),
```

---

### PedagogicalContent — widget existant

`mobile_app/lib/core/widgets/pedagogical_content.dart` (396 lignes). **Ne pas réimplémenter.** Usage dans NotionPage :

```dart
// Constructeur statique (pas streaming — contenu hardcodé, disponible immédiatement)
PedagogicalContent(content: lesson.contentFr) // ou .contentEn
```

Ce widget gère nativement : Markdown via `gpt_markdown`, LaTeX via `flutter_math_fork`, Mermaid via mermaid.ink (rendu PNG cached), SVG, blocs de code. Aucune dépendance à importer dans NotionPage — `PedagogicalContent` est déjà dans `core/widgets/`.

**ADR-014** : `gpt_markdown` remplace `flutter_smooth_markdown` depuis Story 0.19. Mermaid N'EST PAS supporté nativement par gpt_markdown — il est géré par un regex custom dans `pedagogical_content.dart`. Ne pas ré-ouvrir ce sujet.

---

### Données fake — correspondance content_demo.json

Les constantes `kFakeChapters`, `kFakeLessons`, `kFakeNotions` dans `fake_content_data.dart` doivent correspondre EXACTEMENT aux données seedées en Story 2.1 (`content_demo.json`) pour faciliter Story 2.4 (remplacement fake → Firestore).

IDs à utiliser (issus de content_demo.json) :
- Matière franco : `subjectId = 'francophone_math'`, chapitres `franco_math_ch01`…`franco_math_ch04`
- Matière anglo : `subjectId = 'anglophone_physics'`, chapitres `anglo_physics_ch01`…`anglo_physics_ch04`
- Leçons : `{chapterId}_l01`, `{chapterId}_l02`
- Notions : `{lessonId}_n01`, `{lessonId}_n02`

**Langue d'affichage** : récupérer `userProfileProvider` (déjà existant, Epic 1) → champ `subSystem` → `'fr'` si francophone, `'en'` si anglophone ou GCE.

---

### Composants réutilisables — consultation catalogue

Avant de créer un widget, consulter `doc/tech/COMPOSANTS-REUTILISABLES.md` (14 composants) :

| Composant Story 2.2 | Catalogue ? | Décision |
|---|---|---|
| `ChapterCard` | Non (spécifique contenu) | Créer dans `features/content/presentation/widgets/` — pas d'entrée catalogue |
| `LessonTile` | Non (spécifique contenu) | Idem |
| `NotionTile` | Non (spécifique contenu) | Idem |
| AppBar back button | Via GoRouter + Scaffold | Rien à créer |
| Layout scaffold pages | `Scaffold` standard Flutter | `PickerSectionScaffold` (catalogue) non applicable ici |

Les 3 widgets feature restent dans `features/content/presentation/widgets/` — ils ne sont pas réutilisables cross-feature → pas d'entrée catalogue requise.

---

### Responsive — Template 3 (obligatoire)

| Breakpoint | Condition | Layout SubjectDetailPage + ChapterPage | Layout LessonPage + NotionPage |
|---|---|---|---|
| **Phone** | `width < 600 dp` | Liste mono-colonne plein-écran | Liste/contenu plein-écran |
| **Phone landscape / narrow tablet** | `600 ≤ width < 840 dp` | Liste mono-colonne, max-width 600 dp, centrée | Idem, max-width 600 dp |
| **Tablet** | `width ≥ 840 dp` | Split-view : liste gauche ~300 dp fixe + espace droit pour contenu (optionnel MVP — peut être mono-col si complexité trop haute, mais golden test tablet obligatoire) | Contenu max-width 720 dp centré |

**LayoutBuilder** ou `MediaQuery.sizeOf(context).width` pour dispatcher. Règle CLAUDE.md § Cross-platform — aucun pixel hardcodé en dehors des tokens (`AppSpacing`, `AppFontSize`, `AppIconSize`, `AppRadius`).

Golden tests obligatoires : `phone_375x812` et `tablet_1024x1366` pour `SubjectDetailPage` et `NotionPage` au minimum.

---

### Taille fichiers Dart — règle CLAUDE.md §12

- Pages : max 300 lignes cible, 500 lignes plafond dur
- Si une page dépasse 400 lignes avec ≥3 widgets privés → extraire vers `widgets/<role>.dart`
- `providers.dart` peut dépasser si catalogue de providers (exception §12)

---

### Historique d'apprentissage Epic 1 / E1bis pertinent

- **Riverpod `@riverpod` + `ref.watch`** : pattern établi Stories 1.2–1.18. Les providers family (param String) utilisent `@riverpod` avec argument typé — voir `chaptersForSubjectProvider(subjectId)`.
- **GoRouter `context.push` vs `context.go`** : `push` pour navigation push classique (back button préservé). Les pages de détail utilisent `push`.
- **Freezed** : pattern établi depuis Story 0.2. `build_runner build` après ajout d'entités.
- **Tokens** : `AppSpacing.s4.h`, `AppFontSize.bodyMedium`, `AppIconSize.md`, `AppRadius.md` — voir `core/theme/tokens.dart`. Aucune valeur numérique brute.
- **ARB i18n** : les titres hardcodés dans cette story ne passent PAS par ARB (données fake = valeurs directes depuis entités). Les labels UI fixes (ex. "Chapitres", "Leçons") passent par ARB si utilisés comme titres de section.

---

### Coût Firestore

**N/A — aucun appel Firestore dans cette story.** L'analyse cost-benefit est reportée à Story 2.4 (intégration).

## Dev Agent Record

### Debug Log

_(vide — story non démarrée)_

### Completion Notes

_(vide)_

## File List

_(à remplir par l'agent dev)_

## Change Log

| Date | Changement |
|---|---|
| 2026-06-21 | Création story via `/bmad-create-story` |
