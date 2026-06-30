---
story: 2.4
title: "Intégration Firestore — module contenu (chapitres + leçons)"
status: review
baseline_commit: "44ba9ee8fdcb45d60744e87af4459bdc79731411"
---

# Story 2.4 : Intégration Firestore — module contenu (chapitres + leçons)

---

## User Story

En tant qu'élève, je veux que les pages de navigation dans mes matières (liste des chapitres, détail d'un chapitre avec ses leçons, lecture d'une leçon) affichent les vraies données Firestore seedées en Story 2.1, afin d'accéder au contenu pédagogique réel et de ne plus voir des données de démonstration inventées.

---

## Acceptance Criteria

**AC1 — Chapitres chargés depuis Firestore**
Donné que je suis sur la page d'une matière (`/subject/{subjectId}`),
Quand la page s'ouvre,
Alors la liste des chapitres est chargée depuis la collection Firestore `chapters` filtrée par `subjectId`, triée par `order` croissant. Un shimmer skeleton s'affiche pendant le chargement. Les données sont identiques à ce qui a été seedé par Story 2.1.

**AC2 — Leçons chargées depuis Firestore**
Donné que je suis sur la page d'un chapitre (`/subject/{subjectId}/chapter/{chapterId}`),
Quand le tab "Leçons" s'affiche,
Alors les leçons sont chargées depuis la collection Firestore `lessons` filtrée par `chapterId`, triées par `order` croissant. Un shimmer skeleton s'affiche pendant le chargement.

**AC3 — Contenu de leçon chargé depuis Firestore**
Donné que je suis sur la page d'une leçon (`/subject/{subjectId}/chapter/{chapterId}/lesson/{lessonId}`),
Quand la page s'ouvre,
Alors le contenu Markdown de la leçon est chargé depuis le document Firestore `lessons/{lessonId}` via lecture par ID (1 read). Le contenu est rendu par `PedagogicalContent`. Un shimmer skeleton s'affiche pendant le chargement.

**AC4 — Nom et icône de la matière depuis userSubjectsProvider**
Donné que la matière {subjectId} est dans la liste de mes matières,
Quand l'une des pages de contenu s'ouvre,
Alors le nom localisé et l'icône de la matière proviennent du `userSubjectsProvider` (pas de `kSubjectNames` fake). Si la matière n'est pas trouvée, afficher `subjectId` comme fallback.

**AC5 — États d'erreur localisés (CLAUDE.md règle 13)**
Donné qu'une erreur Firestore survient lors du chargement de chapitres ou de leçons,
Quand l'erreur est reçue,
Alors un message d'erreur localisé adapté au type d'erreur est affiché :
- `permission-denied` / non authentifié → clé ARB `errorPermissionDenied`
- `unavailable` / `network-request-failed` / `deadline-exceeded` → clé ARB `errorNetworkUnavailable`
- Autres → clé ARB `errorFirestoreUnknown`
Aucun log silencieux : chaque Failure est loggée avec `kind` + `message`.

**AC6 — Cache offline natif Firestore**
Les lectures utilisent `.get()` (pas `.snapshots()`). Le cache offline natif Firestore (Story 0.7) est appliqué par défaut. Après une première ouverture avec connexion, la page se charge instantanément hors connexion.

**AC7 — Suppression de fake_content_data.dart**
Le fichier `lib/features/content/data/fake/fake_content_data.dart` est supprimé. Aucun import résiduel dans les pages ni dans les providers.

**AC8 — Pas de régression**
`flutter analyze` = 0 issue. `flutter test` = 0 régression (tous les tests existants passent). Les routes `/subject/{subjectId}`, `/subject/{subjectId}/chapter/{chapterId}`, `/subject/{subjectId}/chapter/{chapterId}/lesson/{lessonId}` fonctionnent de bout en bout. La navigation depuis le dashboard (DashboardSubjectsArea) vers `/subject/{subjectId}` fonctionne toujours.

**AC9 — Responsive préservé (story 2.2)**
Les breakpoints responsives existants (LayoutBuilder 600/840 dp) sur les 3 pages sont préservés et non régressés. Les nouveaux états shimmer/erreur respectent le même layout centré tablet.

---

## Tasks / Subtasks

### T1 — Domain layer : ContentFailure + ContentRepository

- [x] T1.1 — Créer `lib/features/content/domain/failures/content_failure.dart`
  - `sealed class ContentFailure extends Failure`
  - `ContentFailure.networkError(String message)` → pour `unavailable`, `network-request-failed`, `deadline-exceeded`
  - `ContentFailure.permissionDenied()` → pour `permission-denied`, non authentifié
  - `ContentFailure.notFound(String id)` → pour doc inexistant
  - `ContentFailure.unknown(String message)` → fallback
  - Getter `FailureKind get kind` enum {networkUnavailable, permissionDenied, notFound, unknown}
- [x] T1.2 — Créer `lib/features/content/domain/repositories/content_repository.dart`
  - Interface `abstract interface class ContentRepository`
  - `Future<Either<ContentFailure, List<ChapterEntity>>> getChapters(String subjectId)`
  - `Future<Either<ContentFailure, List<LessonEntity>>> getLessons(String chapterId)`
  - `Future<Either<ContentFailure, LessonEntity>> getLessonById(String lessonId)`
  - Import fpdart + entities + failure uniquement (CLAUDE.md règle 1 domain pur)

### T2 — Data layer : models Firestore

- [x] T2.1 — Créer `lib/features/content/data/models/chapter_model.dart`
  - `ChapterModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc)`
  - Map Firestore `title: {fr, en}` → `ChapterEntity.titleFr` / `titleEn`
  - Map `description: {fr, en}` → nullable `descriptionFr` / `descriptionEn`
  - Map `lessonCount`, `quizCount`, `exerciseCount`, `progressPercent` (défaut 0), `studentCount` (défaut 0)
  - `toEntity()` → `ChapterEntity`
- [x] T2.2 — Créer `lib/features/content/data/models/lesson_model.dart`
  - `LessonModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc)`
  - Map Firestore `title: {fr, en}` → `LessonEntity.titleFr` / `titleEn`
  - Map Firestore `content: {fr, en}` → `LessonEntity.contentFr` / `contentEn`
  - Map `durationMinutes` (défaut 0), subtitles optionnels
  - `toEntity()` → `LessonEntity`

### T3 — Data layer : ContentFirestoreRepositoryImpl

- [x] T3.1 — Créer `lib/features/content/data/repositories/content_firestore_repository_impl.dart`
  - Constructeur : `FirebaseFirestore firestore` injecté
  - `getChapters(subjectId)` : `.collection('chapters').where('subjectId', isEqualTo: subjectId).orderBy('order').limit(100).get()` → `List<ChapterEntity>`
  - `getLessons(chapterId)` : `.collection('lessons').where('chapterId', isEqualTo: chapterId).orderBy('order').limit(50).get()` → `List<LessonEntity>`
  - `getLessonById(lessonId)` : `.collection('lessons').doc(lessonId).get()` → `LessonEntity`
  - Catch `FirebaseException` : mapper code vers `ContentFailure.kind` (voir T1.1)
  - Log chaque failure : `AppLogger.e('content.getChapters failed', kind=${failure.kind}, message=${e.message})`
  - Indexes existants Story 2.1 : `chapters(subjectId ASC, order ASC)` + `lessons(chapterId ASC, order ASC)` — pas de nouveaux indexes

### T4 — Providers : FutureProvider.family + contentRepositoryProvider

- [x] T4.1 — Dans `lib/features/content/presentation/providers.dart` :
  - Ajouter `final contentRepositoryProvider = Provider<ContentRepository>((ref) => ContentFirestoreRepositoryImpl(firestore: ref.watch(firestoreProvider)));`
  - `firestoreProvider` est dans `lib/core/firebase/providers.dart` (déjà importé dans d'autres features)
- [x] T4.2 — Remplacer `chaptersForSubjectProvider` : `Provider.family` → `FutureProvider.family<AsyncValue<List<ChapterEntity>>, String>` appel `ref.watch(contentRepositoryProvider).getChapters(subjectId)` → retour `Either` mappé vers throw en cas de Left
- [x] T4.3 — Remplacer `lessonsForChapterProvider` : même pattern
- [x] T4.4 — Remplacer `lessonByIdProvider` : `FutureProvider.family<LessonEntity?, String>` → `getLessonById(lessonId)` (Either → null sur Left, log)
- [x] T4.5 — Supprimer tous les imports `fake_content_data.dart` de `providers.dart`

### T5 — SubjectDetailPage : AsyncValue + vrai subject

- [x] T5.1 — Remplacer `ref.watch(chaptersForSubjectProvider(subjectId))` par `ref.watch(chaptersForSubjectProvider(subjectId))` sur `AsyncValue<List<ChapterEntity>>`
- [x] T5.2 — Remplacer `kSubjectNames[subjectId]` par données du `userSubjectsProvider` :
  - `final subject = subjectsAsync.maybeWhen(data: (list) => list.where((s) => s.subjectId == subjectId).firstOrNull, orElse: () => null)`
  - `subjectName` : `subject?.name[languageCode] ?? subject?.name['fr'] ?? subjectId`
  - `subjectIcon` : `subjectIconFor(subject?.icon ?? '')` (fallback `Icons.menu_book_outlined` si icon vide)
  - Supprimer les champs `level` (eyebrow ne montre plus le stream label) et `rank` (badge supprimé) — leur remplacement par des données réelles est hors scope Story 2.4
  - Eyebrow = `'${chapters.length} CHAPITRES'` (ou `'CHAPTERS'` EN) uniquement
- [x] T5.3 — Ajouter état loading (shimmer sur la liste de chapitres) : même squelette que `_SkeletonList` du DashboardSubjectsArea mais pour ChapterCard — ou `_SkeletonChapterList` local
- [x] T5.4 — Ajouter état error : `_ContentErrorView(failure: f)` widget centré avec message selon `kind` + bouton "Réessayer" qui invalide le provider
- [x] T5.5 — Supprimer `import fake_content_data.dart`

### T6 — ChapterPage : AsyncValue + vrai subject

- [x] T6.1 — `chaptersForSubjectProvider` → `AsyncValue` : chercher le chapter actuel dans la liste
- [x] T6.2 — `lessonsForChapterProvider` → `AsyncValue` : passer au `LessonsTab`
- [x] T6.3 — `subjectAbbrev` depuis `userSubjectsProvider` : prendre le nom localisé, uppercase, tronquer à 8 chars (ex. "MATHÉMAT" pour "Mathématiques") — préfixé breadcrumb
- [x] T6.4 — `LessonsTab` gère `AsyncValue<List<LessonEntity>>` : shimmer si loading, error view si erreur, liste si data
- [x] T6.5 — `progressPercent` + `studentCount` : issues du chapter trouvé dans l'AsyncValue (défaut 0 si non trouvé)
- [x] T6.6 — Supprimer `import fake_content_data.dart`

### T7 — LessonPage : AsyncValue

- [x] T7.1 — `lessonByIdProvider(widget.lessonId)` → `AsyncValue<LessonEntity?>` : gérer loading / error / data
- [x] T7.2 — `chaptersForSubjectProvider(widget.subjectId)` → `AsyncValue` : breadcrumb `chapterOrder`
- [x] T7.3 — `subjectAbbrev` depuis `userSubjectsProvider` (même logique que T6.3)
- [x] T7.4 — État loading : shimmer sur l'AppBar title + shimmer sur le body (rectangle pleine largeur)
- [x] T7.5 — État error : `_ContentErrorView` centré, bouton "Réessayer"
- [x] T7.6 — Supprimer `import fake_content_data.dart`

### T8 — Suppression fake data

- [x] T8.1 — Supprimer `lib/features/content/data/fake/fake_content_data.dart`
- [x] T8.2 — Vérifier qu'aucun autre fichier n'importe `fake_content_data.dart` (`flutter analyze` confirme)

### T9 — Tests unitaires

- [x] T9.1 — `test/features/content/data/models/chapter_model_test.dart`
  - Cas succès : `ChapterModel.fromFirestore()` sur map Firestore complète → `ChapterEntity` correct
  - Cas champ `description` absent (null) → entité sans description
  - Cas `title` partiel (seulement `fr`) → `titleEn` fallback vide
  - Cas `progressPercent` absent → défaut 0
- [x] T9.2 — `test/features/content/data/models/lesson_model_test.dart`
  - Cas succès : `LessonModel.fromFirestore()` sur map complète → entité correcte
  - Cas `content.en` absent → `contentEn` vide
  - Cas `durationMinutes` absent → défaut 0
- [x] T9.3 — `test/features/content/data/repositories/content_firestore_repository_impl_test.dart`
  - Mock `FirebaseFirestore` (package `fake_cloud_firestore` ou `mocktail`)
  - `getChapters` : succès retourne liste triée par order
  - `getChapters` : `FirebaseException(code: 'unavailable')` → `Left(ContentFailure.networkError(...))`
  - `getLessonById` : doc inexistant → `Left(ContentFailure.notFound(lessonId))`

### T10 — Tests widget

- [x] T10.1 — `test/features/content/presentation/pages/subject_detail_page_test.dart`
  - Loading state : shimmer affiché
  - Error state : message `errorNetworkUnavailable` visible (réseau)
  - Data state : chapitres correctement listés
- [x] T10.2 — `test/features/content/presentation/pages/lesson_page_test.dart`
  - Loading state : shimmer AppBar title
  - Data state : `PedagogicalContent` rendu avec le contenu Markdown

### T11 — Golden tests breakpoints

- [x] T11.1 — `test/features/content/presentation/goldens/subject_detail_page_goldens_test.dart`
  - Golden phone portrait (375×812) : état data avec 4 chapitres
  - Golden tablet portrait (768×1024) : même data, layout centré 720 dp — **obligatoire AC règle 5**
- [x] T11.2 — `test/features/content/presentation/goldens/lesson_page_goldens_test.dart`
  - Golden phone portrait (375×812)
  - Golden tablet portrait (768×1024)

### T12 — Sprint status

- [x] T12.1 — Mettre à jour `sprint-status.yaml` : `2-4-content-integration: ready-for-dev → in-progress`

---

## Dev Notes

### Contexte et motivation
Story 2.2 a livré les pages UI de navigation contenu (SubjectDetailPage, ChapterPage, LessonPage) avec des données hardcodées (`fake_content_data.dart`, providers `Provider.family` synchrones). Story 2.1 a seedé le contenu réel dans Firestore. Cette story branche l'UI sur les vraies données, conformément au principe UI-first-then-integrate (feedback memory). Le module contenu devient fonctionnel pour les élèves.

### Décisions techniques clés
- **ContentRepository interface** : cohérence avec le pattern `CatalogueRepository` / `SchoolRepository` déjà en place — `abstract interface class` + `Either<ContentFailure, T>` retours pour propager les erreurs jusqu'à la présentation.
- **`.get()` pas `.snapshots()`** : le contenu pédagogique (chapitres, leçons) est statique — changé 1-2× par an via admin. Anti-pattern CLAUDE.md règle 10.g. Cache offline Firestore natif (Story 0.7) absorbe la majorité des lectures (reconnexions).
- **`FutureProvider.family` pas `Provider.family`** : les providers existants retournent du sync fake ; Firestore est async. Migration obligatoire. Les pages passent de consommation directe à `.when(loading, error, data)`.
- **Suppression `kSubjectNames`** : les noms/icônes de matières proviennent de `userSubjectsProvider` (déjà watch'é dans SubjectDetailPage via `ref`). Les champs `level` et `rank` (stream label + classement) ne sont pas dans le scope de Story 2.4 — supprimés de l'eyebrow/badge temporairement. Aucun ADR nécessaire, décision locale UI.
- **Abbrev breadcrumb** : `subjectName.substring(0, min(8, subjectName.length)).toUpperCase()` — approximation acceptable pour V1. À raffiner si un champ `abbreviation` est ajouté aux Subject en Story future.

### Modèle de données / API impactés
- Fichiers domain : `lib/features/content/domain/failures/content_failure.dart` (NEW) + `lib/features/content/domain/repositories/content_repository.dart` (NEW)
- Fichiers data : `chapter_model.dart` (NEW) + `lesson_model.dart` (NEW) + `content_firestore_repository_impl.dart` (NEW)
- Schéma Firestore : renvoi à `doc/partage/BASE-DE-DONNEES.md` — collections `chapters` + `lessons` inchangées (Story 2.1 autoritaire)
- Indexes Firestore : déjà déployés en Story 2.1 — `chapters(subjectId ASC, order ASC)` + `lessons(chapterId ASC, order ASC)`. Aucun nouveau index requis.

### Cost-benefit Firestore

**Type d'impact** : première requête Firestore sur collections `chapters` et `lessons` (remplacement fake data)

**Reads / écriture par session utilisateur moyenne** :
- Lecture : 1 read `chapters?where=subjectId` (≤100 docs, 1 requête) par ouverture SubjectDetailPage
- Lecture : 1 read `lessons?where=chapterId` (≤50 docs, 1 requête) par ouverture ChapterPage
- Lecture : 1 read `lessons/{lessonId}` par doc par ouverture LessonPage
- Total session type (1 matière → 1 chapitre → 2 leçons) : ≈ 3 reads réels, 0 après cache
- Écriture : 0 (lecture pure)
- Latence cible : < 500 ms premier chargement (NFR-8 Markdown reader), < 50 ms cache offline

**Volumétrie estimée à 10 000 utilisateurs** :
- Seed Story 2.1 : ~100-200 docs chapters + ~400-800 docs lessons (contenu initial)
- 10k ouvertures SubjectDetailPage/jour = 10k reads chapitres (cache amplifié → ~2k reads réels)
- Coût mensuel estimé : < 0,01 $ (Firebase free tier 50k reads/jour)

**Trade-off accepté vs alternative écartée** :
- **Alternative A (écartée)** : `snapshots()` sur chapters → écoute temps réel — refus : contenu statique, gaspillage reads (CLAUDE.md règle 10.g)
- **Choix retenu** : `.get()` + cache offline Firestore — bénéfice : 1 read facturé au premier chargement uniquement, instantané ensuite

**Check CLAUDE.md règle 10** :
- [x] (a) 1-2 reads par écran cible
- [x] (c) `limit(100)` chapitres, `limit(50)` leçons
- [x] (d) Préfiltré côté serveur (`subjectId`, `chapterId`)
- [x] (g) `.get()` justifié (contenu statique)
- [x] (k) Lecture par ID pour `getLessonById`
- [x] Pas de `snapshots()` sur catalogue statique
- [x] Pas de filtrage Dart

### Stratégie responsive
**N/A pour les nouveaux fichiers** (domain/data). Pour les pages existantes (SubjectDetailPage, ChapterPage, LessonPage), les breakpoints LayoutBuilder 600/840 dp introduits en Story 2.2 sont **préservés tels quels**. Les nouveaux états shimmer/erreur sont injectés dans le même arbre de layout (Expanded > LayoutBuilder > ...). Golden tests au breakpoint 840 dp obligatoires (T11).

### Composants réutilisables
**Catalogue consulté** : `doc/tech/COMPOSANTS-REUTILISABLES.md`

**Composants existants réutilisés** :
- `PedagogicalContent` (`lib/core/widgets/pedagogical_content.dart`) — rendu Markdown leçons (inchangé)
- `subjectIconFor()` (`lib/core/widgets/picker/subject_icon_resolver.dart`) — icône matière (inchangé)

**Nouveaux composants créés** :
- `_ContentErrorView` (privé dans les pages respectives) — widget erreur avec kind + bouton retry. Si utilisé dans ≥ 2 pages : extraire vers `lib/core/widgets/errors/content_error_view.dart` et documenter dans catalogue.

### Tests à écrire
- Unit : ChapterModel.fromFirestore (succès + champs manquants), LessonModel.fromFirestore (idem), ContentFirestoreRepositoryImpl (mock Firestore, failures)
- Widget : SubjectDetailPage (loading + error + data), LessonPage (loading + data)
- Golden : SubjectDetailPage phone + tablet, LessonPage phone + tablet

### Anti-patterns à éviter
- ❌ Garder un import résiduel de `fake_content_data.dart` dans n'importe quel fichier
- ❌ `snapshots()` sur chapters/lessons
- ❌ Filtrer par subjectId côté Dart après `.get()` sur toute la collection
- ❌ Afficher `l10n.errorGeneric` sans dispatch sur `failure.kind`
- ❌ Log silencieux (`catch (_) {}`) sur les Failures Firestore
- ❌ Mettre un widget `_ContentErrorView` sans le proposer au catalogue si utilisé dans plusieurs fichiers

### Références
- Story d'origine : Story 2.2 (UI hardcodée)
- Story contenu seed : Story 2.1 (Firestore seed + schema)
- Schéma Firestore : `doc/partage/BASE-DE-DONNEES.md` (collections `chapters`, `lessons`)
- Pattern repository : `lib/core/catalogue/domain/catalogue_repository.dart` + `lib/features/onboarding/domain/school_repository.dart`
- Pattern Failure : `lib/core/error/failures.dart` + `lib/core/catalogue/domain/catalogue_failure.dart`
- Pattern erreur présentée UI : `lib/features/onboarding/presentation/_profile_failure_message.dart`
- CLAUDE.md règles 1, 2, 10.g, 13

---

## Dev Agent Record

### Debug Log

| # | Issue | Fix | Statut |
|---|-------|-----|--------|
| 1 | `Override` non exporté par `flutter_riverpod 3.3.1` → `List<Override>` provoque une erreur de compilation dans les tests | Supprimer toutes les annotations de type `Override` explicites ; Dart infère le type depuis le contexte `ProviderScope.overrides: [...]` | Résolu |
| 2 | Tests loading échouent : "A Timer is still pending" — `addTearDown(() async => tester.pumpWidget(SizedBox()))` inefficace | `_AnimateState._restart` crée un `Timer(Duration.zero, ...)` dans `initState`. `pump()` sans durée ne déclenche pas `fakeAsync.elapse()` → timer jamais consommé. Fix : (a) appeler `pump(Duration.zero)` après le premier `pump()` pour déclencher les timers de démarrage ; (b) résoudre le `Completer` en fin de test pour que la transition loading→data démonte le skeleton et annule son ticker shimmer repeat() | Résolu |
| 3 | Test "error networkUnavailable" : `ContentErrorView` not found — `AppLocalizations.of(context)` retourne nullable, `ContentErrorView.build()` plante si l10n pas encore chargée | Remplacer `pump() + pump(100ms)` par `pump() + pumpAndSettle()` — état erreur n'a pas de shimmer donc settle converge ; donne le temps à la délégation l10n de s'initialiser | Résolu |

### Completion Notes

- T1–T8 : couche domain/data complète (ContentFailure sealed, ContentRepository interface, ChapterModel/LessonModel, ContentFirestoreRepositoryImpl avec logging).
- T4 : providers migrés de `Provider.family` synchrone vers `FutureProvider.family` asynchrone ; `Either` fold vers throw sur Left.
- T5–T7 : pages SubjectDetailPage, ChapterPage, LessonPage migrent vers `.when(loading, error, data)` ; shimmer skeletons locaux ; `ContentErrorView` extrait vers `lib/core/widgets/errors/content_error_view.dart` (réutilisé dans 3 pages).
- T8 : `fake_content_data.dart` + `fake_content_provider.dart` supprimés, 0 import résiduel confirmé par `flutter analyze`.
- T9 : 15 tests unitaires (5 ChapterModel + 5 LessonModel + 5 repository) — 100% pass.
- T10–T11 : 13 tests widget/golden (`content_pages_test.dart`) — smoke ×3, états async ×5, goldens ×4 + token smoke ×1 — 100% pass après fix FakeAsync timers shimmer.
- Catalogue `COMPOSANTS-REUTILISABLES.md` mis à jour : `ContentErrorView` documenté.
- `flutter analyze` : 2 warnings pré-existants (hors scope Story 2.4) — aucun warning introduit.

### File List

**Nouveaux fichiers** :
- `lib/features/content/domain/failures/content_failure.dart`
- `lib/features/content/domain/repositories/content_repository.dart`
- `lib/features/content/data/models/chapter_model.dart`
- `lib/features/content/data/models/lesson_model.dart`
- `lib/features/content/data/repositories/content_firestore_repository_impl.dart`
- `lib/core/widgets/errors/content_error_view.dart`
- `test/features/content/data/models/chapter_model_test.dart`
- `test/features/content/data/models/lesson_model_test.dart`
- `test/features/content/data/repositories/content_firestore_repository_impl_test.dart`
- `test/features/content/presentation/__goldens__/subject_detail_phone.png`
- `test/features/content/presentation/__goldens__/subject_detail_tablet.png`
- `test/features/content/presentation/__goldens__/lesson_page_phone.png`
- `test/features/content/presentation/__goldens__/lesson_page_tablet.png`

**Fichiers modifiés** :
- `lib/features/content/presentation/providers.dart` — `Provider.family` → `FutureProvider.family`, ajout `contentRepositoryProvider`
- `lib/features/content/presentation/pages/subject_detail_page.dart` — migration AsyncValue, shimmer, erreur, sujet depuis `userSubjectsProvider`
- `lib/features/content/presentation/pages/chapter_page.dart` — migration AsyncValue
- `lib/features/content/presentation/pages/lesson_page.dart` — migration AsyncValue, `_LessonPageSkeleton`
- `lib/core/routing/app_router.dart` — suppression route `subject_detail_placeholder`
- `lib/l10n/app_fr.arb` + `lib/l10n/app_en.arb` — clés `errorNetworkUnavailable`, `errorPermissionDenied`, `errorFirestoreUnknown`, `retryLabel`
- `lib/l10n/generated/app_localizations.dart` + `_fr.dart` + `_en.dart` — regénérés
- `test/features/content/presentation/content_pages_test.dart` — réécriture complète Story 2.2 + Story 2.4
- `doc/tech/COMPOSANTS-REUTILISABLES.md` — ajout `ContentErrorView`

**Fichiers supprimés** :
- `lib/features/content/data/fake/fake_content_data.dart`
- `lib/features/dashboard/presentation/subject_detail_placeholder_page.dart`

### Change Log

| Date | Description |
|---|---|
| 2026-06-23 | T1–T4 : domain layer (ContentFailure, ContentRepository) + data layer (ChapterModel, LessonModel, ContentFirestoreRepositoryImpl) + providers FutureProvider.family |
| 2026-06-23 | T5–T7 : migration pages SubjectDetailPage/ChapterPage/LessonPage vers AsyncValue + shimmer + ContentErrorView extrait vers core/widgets/errors/ |
| 2026-06-23 | T8 : suppression fake_content_data.dart + subject_detail_placeholder_page.dart |
| 2026-06-23 | T9 : 15 tests unitaires ChapterModel + LessonModel + ContentFirestoreRepositoryImpl |
| 2026-06-23 | T10–T11 : 13 tests widget/golden content_pages_test.dart (smoke + états async + goldens phone/tablet) |
| 2026-06-23 | T12 : sprint-status mis à jour, COMPOSANTS-REUTILISABLES.md complété |
