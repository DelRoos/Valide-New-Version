---
story: 2.5
title: "Fiches de lecture — onglet chapitre"
status: done
created: 2026-07-02
---

## Story 2.5 : Fiches de lecture — onglet chapitre

---

## User Story

En tant qu'élève, je veux pouvoir accéder à la fiche de lecture d'un chapitre via l'onglet "Fiche" de la page chapitre, afin de consulter un résumé condensé de référence rendu comme le contenu d'une leçon ordinaire.

---

## Acceptance Criteria

**AC1 — Fiche lue depuis Firestore**
Donné que `chapters/{chapterId}/fiche/main` existe en Firestore avec des champs `fr` et `en`,
Quand j'ouvre l'onglet "Fiche" de la page chapitre,
Alors le contenu Markdown est rendu via `PedagogicalContent` dans la langue de l'app. Un skeleton s'affiche pendant le chargement.

**AC2 — État vide si fiche absente**
Donné que `chapters/{chapterId}/fiche/main` n'existe pas (la plupart des chapitres seedés par Story 2.1),
Quand j'ouvre l'onglet "Fiche",
Alors un état vide "Fiche bientôt disponible" / "Study sheet coming soon" s'affiche (icône + texte centré). `ContentFailure.notFound` est intercepté et traité comme état vide, pas comme erreur.

**AC3 — États d'erreur réseau**
Donné qu'une erreur réseau ou permission survient lors de la lecture de la fiche,
Quand l'onglet "Fiche" est affiché,
Alors `ContentErrorView` avec bouton "Réessayer" est affiché (même pattern que `LessonsTab`). `ContentFailure.notFound` n'est PAS traité comme erreur réseau.

**AC4 — Responsive**
Donné que j'ouvre l'onglet "Fiche" sur tablette (≥ 840 dp) ou phone large (≥ 600 dp),
Quand le contenu s'affiche,
Alors il est centré dans une `SizedBox(width: maxWidth)` avec les breakpoints 720/600 dp comme `LessonPage`.

**AC5 — Seed Python : fiche optionnelle sur chapitres**
Donné qu'un chapitre dans `content_demo/` a un champ `"fiche": {"fr": "...", "en": "..."}`,
Quand `build_seed_3e.py` est exécuté,
Alors `seed_3e.json` inclut la fiche sur ce chapitre.
Quand `seed_3e_content.py` est exécuté,
Alors `chapters/{chapterId}/fiche/main` est écrit en Firestore. Les chapitres sans `fiche` ne produisent aucun sous-document.

**AC6 — Validation seed**
`seed_3e_content.py --dry-run` valide que si `fiche` est présent sur un chapitre, il est bilingue `{fr, en}`. Une structure invalide lève `ValueError` avant toute écriture.

**AC7 — Placeholder supprimé**
Le `_PlaceholderTab` de l'onglet "Fiche" dans `chapter_page.dart` est remplacé par `FicheTab`. Le texte "Fiche de révision bientôt disponible" disparaît.

**AC8 — BASE-DE-DONNEES.md mis à jour**
`doc/partage/BASE-DE-DONNEES.md` documente `chapters/{chapterId}/fiche/main` et ses champs `{fr, en}`. Accord backend requis avant merge.

**AC9 — Pas de régression**
`flutter analyze` = 0 issue. `flutter test` = 0 régression. Les 3 autres onglets (Leçons, Quiz, Exercices) sont inchangés.

---

## Dev Notes

### État actuel (avant cette story)

**`ChapterPage`** (`presentation/pages/chapter_page.dart:32`) : `TabController(length: 4)`. Tabs l.70-75 : `['Leçons', 'Quiz', 'Exercices', 'Fiche']`. Onglet "Fiche" (index 3) = `_PlaceholderTab` (l.121-126), label "Fiche de révision bientôt disponible".

**`ContentRepository`** (`domain/repositories/content_repository.dart`) : 4 méthodes — `getChapters`, `getLessons`, `getLessonById`, `getLessonContent`. Pas de `getFiche`.

**`ContentFirestoreRepositoryImpl`** (`data/repositories/content_firestore_repository_impl.dart`) : lit `lessons/{id}/content/main` dans `getLessonContent` (l.101-131). Pattern exact à dupliquer pour `chapters/{id}/fiche/main`. Constantes l.19-23 : `_kChapters = 'chapters'`, `_kLessons`, `_kContent`. Ajouter `_kFiche = 'fiche'`.

**`providers.dart`** : `lessonContentProvider` (FutureProvider.autoDispose.family) — pattern à dupliquer pour `chapterFicheProvider`.

**Seed** : `build_seed_3e.py` ne traite pas de champ `fiche` sur les chapitres. `seed_3e_content.py` n'écrit pas de sous-collection `fiche`.

### Ce que la story change

| Fichier | Changement |
| --- | --- |
| `domain/entities/chapter_fiche_entity.dart` | **NOUVEAU** — `chapterId, contentFr, contentEn, contentFor()` |
| `domain/repositories/content_repository.dart` | Ajouter `getFiche(chapterId)` |
| `data/repositories/content_firestore_repository_impl.dart` | Implémenter `getFiche` (lit `chapters/{id}/fiche/main`) |
| `features/content/providers.dart` | Ajouter `chapterFicheProvider` |
| `presentation/widgets/fiche_tab.dart` | **NOUVEAU** — `FicheTab` (loading / empty / content) |
| `presentation/pages/chapter_page.dart` | Remplacer `_PlaceholderTab` fiche par `FicheTab(chapterId)` |
| `scripts/firebase_seed/build_seed_3e.py` | Résoudre `fiche` sur chapitres → output JSON |
| `scripts/firebase_seed/seed_3e_content.py` | Écrire `chapters/{id}/fiche/main`, valider structure |
| `doc/partage/BASE-DE-DONNEES.md` | Ajouter schéma `chapters/{id}/fiche/main` |

### Règles architecture

- **Règle 1** : `ChapterFicheEntity` domain-only — pas d'import Flutter/Firebase. Equatable.
- **Règle 2** : mapping `FirebaseException → ContentFailure` uniquement dans `content_firestore_repository_impl.dart`.
- **Règle 3** : log obligatoire dans `chapterFicheProvider` : `kind=... message=...`.
- **Règle 6** : `PedagogicalContent` importé uniquement depuis `core/widgets/pedagogical_content.dart`.
- **Règle 11** : `FicheTab` = fichier dédié `presentation/widgets/fiche_tab.dart`. Pas de classe privée géante dans `chapter_page.dart`.
- **Règle 12** : `FicheTab` cible ≤ 120 lignes.
- **Règle 13** : `ContentFailure.notFound` → état vide ; autres failures → `ContentErrorView` avec retry.
- **Règle 15** : `ref.watch(chapterFicheProvider(chapterId))` dans `build()`. `autoDispose.family`.

### Cost-benefit Firestore (règle 10.m)

- Lecture déclenchée uniquement si l'utilisateur clique sur l'onglet "Fiche" (`TabBarView` lazy).
- 1 `doc().get()` par session si la tab est ouverte. Cache Firestore offline actif.
- À 10 000 élèves, 20 chapitres par matière, 10 matières : ~200 docs fiches potentiels. Volume négligeable.
- Pas de nouvel index (lecture par chemin direct : `chapters/{id}/fiche/main`).
- Trade-off accepté : `chapters/{id}` et `chapters/{id}/fiche/main` = 2 reads distincts. Acceptable — même isolation que le pattern leçon.

### Rétrocompatibilité Firestore

Les 56 docs actuels n'ont pas de sous-collection `fiche`. `getFiche` retourne `Left(ContentFailure.notFound(...))` → `FicheTab` affiche l'état vide. **Pas de migration requise.**

### Stratégie responsive

`FicheTab` utilise `LayoutBuilder` + breakpoints 600/840 dp identiques à `LessonPage.effectiveMaxWidth`. Phone portrait : pleine largeur, padding `AppSpacing.s4`. Tablet : centré dans 720 dp max.

### Composants à consommer

`PedagogicalContent`, `ContentErrorView`, `AppSkeleton`, tokens `AppColors / AppSpacing / AppFontSize / AppIconSize / AppRadius / AppTypography`.

### Implémentation `getFiche` dans le repo (pattern exact)

```dart
static const _kFiche = 'fiche';

@override
Future<Either<ContentFailure, ChapterFicheEntity>> getFiche(
  String chapterId,
) async {
  try {
    final doc = await _firestore
        .collection(_kChapters)
        .doc(chapterId)
        .collection(_kFiche)
        .doc('main')
        .get();
    if (!doc.exists) {
      AppLogger.w('content.getFiche not found: $chapterId/fiche/main');
      return Left(ContentFailure.notFound('$chapterId/fiche/main'));
    }
    final data = doc.data() ?? {};
    return Right(ChapterFicheEntity(
      chapterId: chapterId,
      contentFr: (data['fr'] as String?) ?? '',
      contentEn: (data['en'] as String?) ?? '',
    ));
  } on FirebaseException catch (e) {
    final failure = _mapFirebaseException(e, context: 'getFiche($chapterId)');
    AppLogger.e('content.getFiche: kind=${failure.kind.name} message=${failure.message}');
    return Left(failure);
  } catch (e) {
    AppLogger.e('content.getFiche unexpected error', error: e);
    return Left(ContentFailure.unknown(e.toString()));
  }
}
```

### Gestion du `notFound` dans `FicheTab`

```dart
ficheAsync.when(
  loading: () => const _FicheLoadingSkeleton(),
  error: (error, _) {
    if (error is ContentFailure &&
        error.kind == ContentFailureKind.notFound) {
      return _FicheEmptyState(languageCode: languageCode);
    }
    return ContentErrorView(
      error: error,
      onRetry: () => ref.invalidate(chapterFicheProvider(chapterId)),
    );
  },
  data: (fiche) {
    final content = fiche.contentFor(languageCode);
    if (content.isEmpty) return _FicheEmptyState(languageCode: languageCode);
    // ... SingleChildScrollView + PedagogicalContent
  },
)
```

---

## Tasks / Subtasks

### T1 — Domain : ChapterFicheEntity

- [ ] T1.1 — Créer `lib/features/content/domain/entities/chapter_fiche_entity.dart`
  - `class ChapterFicheEntity extends Equatable`
  - Champs : `chapterId`, `contentFr`, `contentEn`
  - Méthode : `String contentFor(String languageCode)`
  - `props` Equatable complet

### T2 — Domain : ContentRepository

- [ ] T2.1 — `lib/features/content/domain/repositories/content_repository.dart`
  - Ajouter import `chapter_fiche_entity.dart`
  - Ajouter : `Future<Either<ContentFailure, ChapterFicheEntity>> getFiche(String chapterId);`

### T3 — Data : ContentFirestoreRepositoryImpl

- [ ] T3.1 — `lib/features/content/data/repositories/content_firestore_repository_impl.dart`
  - Ajouter import `chapter_fiche_entity.dart`
  - Ajouter `static const _kFiche = 'fiche';`
  - Implémenter `getFiche(String chapterId)` — pattern identique à `getLessonContent`, chemin `chapters/{chapterId}/fiche/main`

### T4 — Providers

- [ ] T4.1 — `lib/features/content/providers.dart` — ajouter import `chapter_fiche_entity.dart` et :

```dart
final chapterFicheProvider =
    FutureProvider.autoDispose.family<ChapterFicheEntity, String>(
  (ref, chapterId) async {
    final result =
        await ref.watch(contentRepositoryProvider).getFiche(chapterId);
    return result.fold(
      (failure) {
        AppLogger.e(
          'chapterFicheProvider: kind=${failure.kind.name} message=${failure.message}',
        );
        throw failure;
      },
      (fiche) => fiche,
    );
  },
);
```

### T5 — Présentation : FicheTab

- [ ] T5.1 — Créer `lib/features/content/presentation/widgets/fiche_tab.dart`
  - `class FicheTab extends ConsumerWidget` — params `chapterId`, `languageCode`
  - `LayoutBuilder` avec breakpoints 600/840 dp
  - `ref.watch(chapterFicheProvider(chapterId)).when(loading:, error:, data:)`
  - `loading:` → `_FicheLoadingSkeleton` (3 `AppSkeleton`)
  - `error:` → si `notFound` → `_FicheEmptyState` ; sinon `ContentErrorView` avec retry
  - `data:` → si `content.isEmpty` → `_FicheEmptyState` ; sinon `SingleChildScrollView` + `PedagogicalContent`
  - `_FicheEmptyState` : `Icons.description_outlined` (taille `AppIconSize.xl8`) + texte localisé FR/EN, identique au style du `_PlaceholderTab` existant

### T6 — Présentation : ChapterPage

- [ ] T6.1 — `lib/features/content/presentation/pages/chapter_page.dart`
  - Ajouter import `fiche_tab.dart`
  - Remplacer le 4e enfant du `TabBarView` (l.121-126, `_PlaceholderTab` "Fiche") par :

```dart
FicheTab(
  chapterId: widget.chapterId,
  languageCode: langCode,
),
```

### T7 — Python seed

- [ ] T7.1 — `scripts/firebase_seed/build_seed_3e.py` : dans `transform_subject()`, boucle chapitres, résoudre le champ `fiche` optionnel via `resolve_content` (supporte chemin `.md` ou string inline), puis l'inclure dans `chapters_out.append` si non None.

```python
fiche_raw = ch_raw.get("fiche")
ch_fiche = resolve_content(fiche_raw, base_dir) if fiche_raw else None
# Dans chapters_out.append({...}) : ajouter "fiche": ch_fiche si ch_fiche is not None
```

- [ ] T7.2 — `scripts/firebase_seed/seed_3e_content.py` : ajouter `"chapterFiches": 0` dans `counts`. Dans `validate_seed()`, valider que `fiche` est bilingue si présent. Dans `seed_content()`, écrire `chapters/{id}/fiche/main` si la fiche existe :

```python
fiche = ch.get("fiche")
if fiche and (fiche.get("fr") or fiche.get("en")):
    fiche_payload = {
        "fr": fiche.get("fr", ""),
        "en": fiche.get("en", fiche.get("fr", "")),
    }
    if not dry_run:
        (db.collection("chapters").document(ch_id)
           .collection("fiche").document("main")
           .set(fiche_payload, merge=True))
    counts["chapterFiches"] += 1
```

- [ ] T7.3 (optionnel) — Ajouter `"fiche": {"fr": "# Résumé\n\nContenu test.", "en": "# Summary\n\nTest content."}` sur un chapitre de `content_demo/3e/math_3e.json` pour valider visuellement. Run `--dry-run` uniquement.

### T8 — Documentation

- [ ] T8.1 — `doc/partage/BASE-DE-DONNEES.md` : après la section `notions/{notionId}`, ajouter une section `chapters/{chapterId}/fiche/main` (statut 🟡, facultative) avec les champs `fr: string` et `en: string` (Markdown rendu via PedagogicalContent). ⚠️ **Accord backend requis avant merge.**

### T9 — Tests unitaires

- [ ] T9.1 — `test/features/content/data/repositories/content_firestore_repository_impl_test.dart` — étendre avec un group `getFiche` :
  - Cas succès : `fakeFirestore.collection('chapters').doc('ch01').collection('fiche').doc('main').set({'fr': '# FR', 'en': '# EN'})` → `getFiche('ch01')` retourne `Right(ChapterFicheEntity)` avec `contentFr == '# FR'`
  - Cas doc inexistant : `getFiche('ch_inconnu')` → `Left(...)` avec `kind == ContentFailureKind.notFound`

- [ ] T9.2 — `test/features/content/presentation/widgets/fiche_tab_test.dart` (nouveau) :
  - Stub `chapterFicheProvider` avec `ContentFailure.notFound(...)` → texte "Fiche bientôt disponible" visible
  - Stub `chapterFicheProvider` avec `ChapterFicheEntity(chapterId: 'ch01', contentFr: '# Titre', contentEn: '# Title')` → widget `PedagogicalContent` présent

### T10 — Sprint status

- [ ] T10.1 — `project_manage/implementation-artifacts/sprint-status.yaml` : `2-5-fiches-de-lecture: ready-for-dev → in-progress`

### Review Findings

*Code review : 2026-07-03 — 0 decision\_needed · 2 patch · 8 defer · 6 dismissed*

#### Patches

- [x] **\[Review\]\[Patch\] (Med) F1 — Pas de fallback cross-langue dans `contentFor()`** (`chapter_fiche_entity.dart:14`)
  Si `languageCode == 'en'` et `contentEn` est vide mais `contentFr` est rempli, l'utilisateur voit un état vide alors que la donnée existe. Fix : `if (languageCode == 'fr') return contentFr.isNotEmpty ? contentFr : contentEn; return contentEn.isNotEmpty ? contentEn : contentFr;`

- [x] **\[Review\]\[Patch\] (Low) F2 — `ConstrainedBox` au lieu de `SizedBox` — diverge du pattern `LessonPage`** (`fiche_tab.dart:60-67`)
  `LessonPage` utilise `SizedBox(width: maxWidth)`. `FicheTab` utilise `ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth))`. Fix : `Center(child: SizedBox(width: maxWidth, child: body))`.

#### Deferred

- [x] **\[Review\]\[Defer\] (Low) F3 — Strings hardcodées hors ARB** (`fiche_tab.dart:89-94`) — pré-existant, même pattern que `lesson_content_tab.dart` ; à traiter dans la story i18n complète
- [x] **\[Review\]\[Defer\] (Low) F4 — Skeleton heights 28/80/120 non tokenisées** (`fiche_tab.dart:119-133`) — pré-existant dans les autres tabs ; à harmoniser dans une story tokens
- [x] **\[Review\]\[Defer\] (Low) F5 — Incohérence validation `_require_bilingual` vs fallback `seed_content`** (`seed_3e_content.py`) — dead code en pratique (`build_seed_3e.py` force toujours les deux champs)
- [x] **\[Review\]\[Defer\] (Low) F6 — Pré-rendu `FicheTab` depuis onglet Exercices (TabBarView ±1)** (`chapter_page.dart:101`) — impact V1 négligeable (Exercices est encore placeholder)
- [x] **\[Review\]\[Defer\] (Low) F7 — Duplication `_PlaceholderTab` / `_FicheEmptyState` (règle 11)** (`chapter_page.dart:134` / `fiche_tab.dart:74`) — refactor cross-story requis
- [x] **\[Review\]\[Defer\] (Low) F8 — Asymétrie fallback EN : fiche a fallback, leçon non** (`seed_3e_content.py`) — scope limité aux seeds, acceptable V1
- [x] **\[Review\]\[Defer\] (Low) F9 — Aucun test `contentFor()` cas langue inconnue** (`chapter_fiche_entity.dart`) — à couvrir dans story tests dédiée
- [x] **\[Review\]\[Defer\] (Low) F10 — Aucun test `FirebaseException` path pour `getFiche`** (`content_firestore_repository_impl_test.dart`) — couvert par pattern documenté dans le bloc `getChapters`

---

## Definition of Done

- [ ] `flutter analyze` = 0 issue
- [ ] `flutter test` = 0 régression + nouveaux tests verts
- [ ] `python build_seed_3e.py` passe sur un JSON avec `"fiche"` sur un chapitre
- [ ] `python seed_3e_content.py --project valide-edu --dry-run` affiche `chapterFiches: 1`
- [ ] Onglet "Fiche" affiche l'état vide pour les chapitres sans fiche (pas d'erreur rouge)
- [ ] AC8 : `doc/partage/BASE-DE-DONNEES.md` mis à jour + accord backend signalé
- [ ] PR ≤ 400 lignes de diff
