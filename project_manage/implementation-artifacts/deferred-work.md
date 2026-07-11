# Deferred Work

Findings différés lors des code reviews — à traiter dans des stories futures.

---

## Deferred from: code review of 2-4-content-integration (2026-07-02)

- SVG dans gallery sans httpHeaders : `SvgPicture.network` ne supporte pas `httpHeaders`, aucun SVG Wikimedia actuellement en gallery. Risque réel seulement si du contenu SVG est ajouté. Fix : télécharger via `http.get` + `SvgPicture.memory`. ([gallery_block.dart](../../mobile_app/lib/core/widgets/pedagogical_content/gallery_block.dart))
- TODO sans lien issue dans `lesson_content_tab.dart:120` : `// TODO: réactiver quand la logique de progression est prête`. À lier à la story de progression quand elle sera créée.
- `_RecommendedCard` dead code + `// ignore: unused_element` dans `lesson_content_tab.dart:176` : gardé pour réactivation future avec la logique de recommandation. À supprimer ou activer dans la story progression/recommandations.
- Extension audio fragile `Uri.parse(url).path.split('.').last` dans `audio_block.dart` : peut retourner un segment incorrect sur des URLs sans extension ou avec query params. Acceptable pour V1 (URLs contrôlées par les seeds). À robustifier si des sources audio tierces sont ajoutées.
- `MediaQuery.sizeOf` sans `LayoutBuilder` dans `lesson_page.dart` : pré-existant (Story 2.2). La réactivité aux changements de taille widget-level n'est pas garantie. À corriger dans la story responsive dédiée (Story 2.5 ou suivante).

---

## Deferred from: code review of 2-5-fiches-de-lecture (2026-07-03)

- **F3 — Strings hardcodées hors ARB** (`fiche_tab.dart:89-94`) : "Fiche bientôt disponible" / "Study sheet coming soon" sont hors ARB. Pré-existant dans `lesson_content_tab.dart`. À traiter dans la story i18n complète de l'Epic 2.
- **F4 — Skeleton heights 28/80/120 non tokenisées** (`fiche_tab.dart:119-133`) : les hauteurs de skeleton ne passent pas par les tokens. Même pattern pré-existant dans les autres tabs. À harmoniser dans une story tokens dédiée.
- **F5 — Incohérence validation `_require_bilingual` vs fallback `seed_content`** (`seed_3e_content.py`) : la validation exige FR+EN mais l'écriture a un fallback `fiche.get('fr','')` pour EN. Dead code en pratique — `build_seed_3e.py` force toujours les deux champs. Risque réel seulement si le seed est alimenté manuellement.
- **F6 — Pré-rendu `FicheTab` depuis onglet Exercices (TabBarView ±1)** (`chapter_page.dart:101`) : `TabBarView` pré-render les onglets adjacents ; depuis Exercices (index 2), `FicheTab` (index 3) se lance. Impact V1 négligeable car Exercices est encore un placeholder. À surveiller quand Exercices sera actif.
- **F7 — Duplication `_PlaceholderTab` / `_FicheEmptyState` (règle 11)** (`chapter_page.dart:134` / `fiche_tab.dart:74`) : les deux widgets partagent la même structure icône+texte centré sans être le même composant. Refactor cross-story vers un `EmptyStateWidget` générique dans `core/widgets/`.
- **F8 — Asymétrie fallback EN : fiche a fallback leçon non** (`seed_3e_content.py`) : `seed_3e_content.py` applique `fiche.get('en', fiche.get('fr',''))` pour la fiche mais pas de fallback équivalent pour le contenu leçon. Scope limité aux seeds, acceptable V1.
- **F9 — Aucun test `contentFor()` cas langue inconnue** (`chapter_fiche_entity.dart`) : pas de test pour `contentFor('de')` ou `contentFor('')`. Comportement attendu : retourner `contentEn` (branche else). À couvrir dans une story tests dédiée.
- **F10 — Aucun test `FirebaseException` path pour `getFiche`** (`content_firestore_repository_impl_test.dart`) : `FakeFirebaseFirestore` ne peut pas simuler `FirebaseException`. Même limitation documentée pour `getChapters` dans le fichier test (commentaire l.112-115). À couvrir avec un mock `FirebaseFirestore` si une story tests Firebase est créée.

---

## Deferred from: code review of 2-6-quiz-content-integration (2026-07-03)

- **D1 — Collection `notions/` non seedée** : `getNotion` retourne toujours `Left(notFound)` → `notionProvider` retourne `null` → "Besoin d'aide" affiche toujours le fallback texte. La feature est implémentée côté code mais non fonctionnelle sans seed. À traiter dans la story seed notions (Epic 2 ou Epic 5).
- **D2 — `lessonsProvider autoDispose` double-read dans `chapterQuizSessionProvider`** (`providers.dart`) : si `lessonsProvider` est disposed entre deux appels, un second `Firestore.get()` est déclenché. Comportement Riverpod normal mais coût réseau non nul. À monitorer en Epic 5 (optimisation reads).
- **D3 — i18n debt : ternaires `isFr ? '...' : '...'` non externalisés en ARB** (`quiz_session_view.dart`, `quiz_result_screen.dart`, `quiz_review_screen.dart`, `quiz_help_sheet.dart`) : pattern pré-existant dans le codebase. À traiter dans la story i18n complète de l'Epic 2 ou une story dédiée ARB.
- **D4 — `QuizMathText` défini dans `quiz_session_view.dart`** : widget LaTeX réutilisable mais actuellement usage unique. À extraire vers `lib/core/widgets/quiz_math_text.dart` si d'autres écrans ont besoin du rendu LaTeX. CLAUDE.md règle 11.
- **D5 — `QuizHelpSheet.notionId` contrat nullable implicite** (`quiz_help_sheet.dart`) : paramètre déclaré `String notionId` alors que sémantiquement il peut être absent. Rendre explicitement `String? notionId` et gérer le guard à la déclaration plutôt que dans l'appelant.
- **D6 — `.w` scaling dans les fichiers test** (`test/features/content/...`) : utilisation de `.w` (ScreenUtil) sans initialisation dans le contexte de test. Les tests passent car les breakpoints `.w` se comportent comme des valeurs en dp sans init ScreenUtil mais la sémantique est incorrecte.
- **D7 — `QuizReviewScreen` bottom inset implicite** (`quiz_review_screen.dart`) : la hauteur de barre système en bas n'est pas ajoutée au padding du `SingleChildScrollView`. Atténué par le `SafeArea` parent dans `QuizPage`. À corriger si `QuizReviewScreen` est consommé dans un contexte sans SafeArea.
- **D8 — 3e action "Voir mes réponses" hors spec AC5** (`quiz_result_screen.dart`) : bouton "Voir mes réponses" / "Review answers" non spécifié dans AC5. Amélioration UX bénine mais scope creep formel. À confirmer avec le PM dans la story de retro ou Epic 5.
- **D9 — `LayoutBuilder` dans `QuizSessionView` au lieu de `QuizPage`** (`quiz_session_view.dart`) : spec AC9 dit que `QuizPage` porte le `LayoutBuilder`. Fonctionnellement équivalent. À réaligner structurellement dans une story refacto si nécessaire.
- **D10 — `_answers` sans garde sur longueur** (`quiz_session_view.dart`) : race condition fast-tap entre `ref.invalidate` et `setState` en `_replay()` peut laisser `_answers` avec une entrée stale avant le rebuild. Risque faible. Défense : initialiser `_answers` à liste vide dans le `setState` de replay avant l'invalidation.
- **D11 — `Size.fromHeight(52)` dans AppBar** (`quiz_page.dart`) : valeur numérique brute. Couvert par l'exception AppNavBar (CLAUDE.md règle 7) car la hauteur d'AppBar est une zone de touch physique. Acceptable en V1.

## Deferred from: code review (2026-07-11) — PR #154 feat/courses-tab-alignment-exams

- **Verrouillage portrait sur tablette** — `AndroidManifest.xml`, `Info.plist`, `main.dart` : viole CLAUDE.md règle 3 (« Tablette doit fonctionner en portrait ET paysage »). Fichiers pré-existants dans le working tree, non touchés par cette PR — à trancher hors scope.
- **Duplication `_kFakeTotal`/`_kFakeDone`** — arrays mock identiques dans `courses_content.dart` et `exams_body.dart`. À résorber en helper mock partagé au moment du branchement Firestore (Story 2.x).
- **`context` capturé après `Navigator.pop` dans `quiz_page.dart:44-52`** — dette pré-existante (fichier M non touché cette PR). Refonte navigation quiz à traiter à part.
- **Deep link direct sur quiz page — `Navigator.pop()` sans check `canPop()`** — même fichier `quiz_page.dart:49`. Pile vide en deep link → crash potentiel.
- **`mockSequenceFor` avec `c.order == 0`** — donnée Firestore mal seedée fausse la répartition (clamp masque). Validation contrat Firestore à ajouter côté data layer quand branchement.
- **Division par zéro future sur `done/total` dans `SubjectProgressListCard`** — mocks garantissent `total > 0`, mais aucun guard côté widget. Ajouter guard avant branchement Firestore Story 2.x.
- **`showAccountUpgradeDialog` — `addPostFrameCallback` sans `mounted` check** — `account_upgrade_sheet.dart:139` pré-existant. Dette héritée.
- **`context.mounted` protège pop mais pas `ref.read` et logs** — même fichier `account_upgrade_sheet.dart:132-142`. Dette héritée.
- **Import order incohérent dans `quiz_page.dart:8`** — pré-existant, cleanup possible dans une chore PR séparée.
- **`SegmentedTabBar` edge cases : `labels.isEmpty` et `selectedIndex` hors bornes** — composant réutilisable exposé, mais tous les callers actuels garantissent la validité. Ajouter asserts en durcissement futur.
- **Rotation écran entre openSummary et startExercise** — cas rare, non testé. À couvrir en Story tests responsives Story A.7 à venir.
- **Sheet 90% hauteur en paysage phone** — 360dp restant peut être serré avec clavier ouvert. Flutter `viewInsets` compense partiellement. À revoir si feedback utilisateurs.
