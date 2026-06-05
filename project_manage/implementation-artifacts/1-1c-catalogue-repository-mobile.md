---
story_id: 1.1c
title: CatalogueRepository mobile + écran connexion bloquant + tests
epic: 1
phase: P1
status: ready-for-dev
created: 2026-06-05
branch: feat/1.1c-catalogue-repository-mobile
estimation: M (~4-5h)
dependencies:
  - 1.1a  # Schema Firestore + ADR-015 figés (mergée 2026-06-05 commit 748f07e)
  - 0.2   # AppRouter (go_router) — ajout route /catalogue-waiting
  - 0.4   # Failure types + Either<Failure, T>
  - 0.6   # Firebase providers (firestoreProvider, firebaseAuthProvider)
  - 0.7   # Cache offline Firestore 40 MB persistance
  - 0.13  # AppEmptyState + AppButton (réutilisés pour écran connexion bloquant)
  - 0.16  # i18n FR/EN gen-l10n
blocks:
  - 1.3   # Flow profil 3 étapes (consomme CatalogueRepository.watch* + derive())
  - 1.4   # Retrait conditionnel matières (consomme series.canOptOut via repository)
  - 1.9   # Dashboard skeleton (consomme subjects filtrés isActive via repository)
sourceArtifacts:
  - project_manage/planning-artifacts/epics/epic-1-onboarding.md § Story 1.1c (lignes 217-283)
  - project_manage/planning-artifacts/sprint-change-proposal-2026-06-05.md
  - project_manage/planning-artifacts/architecture/adrs/ADR-015-catalogue-firestore-runtime-activation.md (mergée 2026-06-05)
  - project_manage/planning-artifacts/architecture/adrs/ADR-001-flutter-clean-architecture.md
  - project_manage/planning-artifacts/architecture/adrs/ADR-002-riverpod-vs-getx.md
  - project_manage/planning-artifacts/architecture/adrs/ADR-010-no-custom-cache.md
  - doc/partage/BASE-DE-DONNEES.md § Catalogue scolaire (6 collections — Story 1.1a) (mergée 2026-06-05)
  - doc/partage/ALGORITHMES.md § 1 (lieu d'exécution V1 helper Dart client + pseudo-code derivation_rules)
  - doc/partage/DONNEES-REFERENCE.md (matrice 🟢 — sert de référence pour les tests avec exemples figés)
  - mobile_app/lib/core/error/failures.dart (hiérarchie Failure sealed existante)
  - mobile_app/lib/core/firebase/providers.dart (firestoreProvider + firebaseAuthProvider existants)
  - mobile_app/lib/core/widgets/app_empty_state.dart (réutiliser pour écran « En attente de connexion »)
  - mobile_app/lib/core/widgets/app_button.dart (AppButton.primary pour CTA « Réessayer »)
  - mobile_app/lib/core/routing/app_router.dart (ajouter route /catalogue-waiting)
  - mobile_app/lib/l10n/app_fr.arb + app_en.arb (ajouter 3 clés i18n)
---

# Story 1.1c — CatalogueRepository mobile + écran connexion bloquant + tests

Status: **ready-for-dev**

## Objectif

Livrer la couche d'accès Dart au catalogue Firestore (6 collections + flag `isActive`) avec :

1. **7 modèles immutables** (`Filiere`, `Niveau`, `Serie`, `Subject`, `ExamTarget`, `DerivationRule`, `DerivedProfile`) basés sur `equatable` + factories `fromFirestore(DocumentSnapshot)` + `toJson()`.
2. **`CatalogueRepository`** clean architecture (interface domain + impl Firestore data) qui expose :
   - `Stream<List<X>> watchX()` pour chaque collection (filtre systématique `where('isActive', '==', true)` + `orderBy('sortOrder')`)
   - `Future<Either<CatalogueFailure, DerivedProfile>> derive(...)` qui matche la première `derivation_rule` Firestore compatible (algorithme cf. ALGORITHMES.md § 1)
3. **Providers Riverpod** : `catalogueRepositoryProvider` + `catalogueProvider` (AsyncValue) + `appStartupCatalogueCheckProvider` (true si catalogue chargé, false si offline+vide).
4. **Écran `/catalogue-waiting`** : page bloquante affichée si AsyncValue est offline+vide. Pattern UX-DR-24, réutilise `AppEmptyState` avec icône `wifi-off`, texte i18n FR/EN, bouton `AppButton.primary` « Réessayer ».
5. **3 clés i18n ARB FR+EN** : `catalogueWaitingTitle`, `catalogueWaitingMessage`, `catalogueWaitingRetry`.
6. **9+ tests** : 4 unitaires modèles (fromFirestore), 3 repository (mocks `fake_cloud_firestore` ou similaire) — streams filtrés + derive() match + derive() noMatchingRule, 2 widget pour écran bloquant.
7. **firestore.rules + firestore.indexes.json racine** : ajouter règles d'accès (read: auth / write: false) + 3 indexes composites (cf. BASE-DE-DONNEES.md § Catalogue scolaire).

**Pourquoi** : sans cette story, Stories 1.3 (flow profil 3 étapes), 1.4 (retrait matières) et 1.9 (dashboard filtré) n'ont pas d'accès au catalogue Firestore. C'est la dernière brique du pivot Firestore-driven catalogue (sprint-change-proposal-2026-06-05.md, Stories 1.1a/b/c).

**Critère de fin** : `flutter analyze` 0 issue + `flutter test` vert (incluant les 9+ nouveaux tests) + build APK release OK + smoke test device :
- avec catalogue Firestore vide → écran « En attente de connexion » s'affiche
- avec catalogue Firestore peuplé (manuellement ou via 1.1b) → l'app traverse `/splash` → `/hello` normalement, le repository expose les bonnes données dans les logs

## Story

**As a** dev Flutter,
**I want** un `CatalogueRepository` qui lit les 6 collections Firestore avec cache offline natif (NFR-5) + filtre `isActive == true` + helper `derive(subSystem, filiere, niveau, serie)`, et un écran « En attente de connexion » bloquant si Firestore est vide au 1er lancement (Firestore offline + cache vide),
**so that** Stories 1.3, 1.4, 1.9 puissent consommer le catalogue de manière transparente sans connaître la couche Firestore, et que le marché Cameroun avec connectivité instable ait un comportement clair au 1er lancement offline.

## Acceptance Criteria

### AC1 — 7 modèles immutables (`lib/core/catalogue/domain/models.dart` ou fichiers séparés)

**Given** le schéma documenté dans [BASE-DE-DONNEES.md § Catalogue scolaire (6 collections — Story 1.1a)](../../doc/partage/BASE-DE-DONNEES.md#catalogue-scolaire-6-collections--story-11a)
**When** on crée les modèles Dart
**Then** chaque classe étend `Equatable` (déjà au pubspec ^2.0.8) avec :
- `Filiere` : `String filiereId`, `Map<String, String> name` (fr/en), `bool isActive`, `int sortOrder`
- `Niveau` : `String niveauId`, `String subSystem`, `Map<String, String> name`, `List<String> filiereIds`, `bool isActive`, `int sortOrder`
- `Serie` : `String serieId`, `String subSystem`, `String niveauId`, `String filiereId`, `Map<String, String> name`, `bool canOptOut`, `bool isActive`, `int sortOrder`
- `Subject` : `String subjectId`, `String subSystem`, `Map<String, String> name`, `String icon`, `bool isActive`, `int sortOrder`
- `ExamTarget` : `String examTargetId`, `String subSystem`, `Map<String, String> name`, `bool isActive`, `int sortOrder`
- `DerivationRule` : `String ruleId`, `String matchSubSystem`, `String matchFiliere`, `String matchNiveau`, `String? matchSerie`, `List<String> subjectIds`, `List<String> examTargetIds`, `bool canOptOut`, `bool isActive`
- `DerivedProfile` : `List<Subject> subjects`, `List<ExamTarget> examTargets`, `bool canOptOut` (résultat de `derive()`)

**And** chaque classe (sauf `DerivedProfile`) a une factory `fromFirestore(DocumentSnapshot)` qui parse robustement (tolère `null` sur champs optionnels mais lance une `ValidationFailure` si champ requis manquant — capturée par le repository et traduite en `CatalogueFailure`).

**And** chaque classe a un `toJson()` (utile pour debug + futur cache si nécessaire — pas requis pour V1 mais bonne pratique).

**And** **AUCUN import Flutter, Firebase, Riverpod, fpdart dans la couche domain** (`lib/core/catalogue/domain/`) — seulement `package:equatable/equatable.dart`. Les factories `fromFirestore` vivent dans la couche **data** (`lib/core/catalogue/data/`) pour respecter ADR-001 § Règle d'or des dépendances.

### AC2 — `CatalogueRepository` interface (domain) + impl Firestore (data)

**Given** la structure clean architecture ADR-001
**When** on crée le repository
**Then** une interface abstraite `CatalogueRepository` est définie dans `lib/core/catalogue/domain/catalogue_repository.dart` exposant :

```dart
abstract interface class CatalogueRepository {
  Stream<List<Filiere>> watchFilieres();
  Stream<List<Niveau>> watchNiveaux({String? subSystem, String? filiereId});
  Stream<List<Serie>> watchSeries({String? subSystem, String? niveauId, String? filiereId});
  Stream<List<Subject>> watchSubjects({String? subSystem});
  Stream<List<ExamTarget>> watchExamTargets({String? subSystem});
  Stream<List<DerivationRule>> watchDerivationRules({String? subSystem});

  /// Match la première `derivation_rule` active compatible avec le profil
  /// et retourne `Either<CatalogueFailure, DerivedProfile>`.
  Future<Either<CatalogueFailure, DerivedProfile>> derive({
    required String subSystem,
    required String filiere,
    required String niveau,
    String? serie,
  });

  /// Charge le catalogue une fois (utilisé par appStartupCatalogueCheckProvider
  /// pour détecter le cas offline + vide). Retourne `true` si au moins 1
  /// `derivation_rule` active existe (= catalogue prêt à servir), `false` sinon.
  Future<bool> hasNonEmptyCatalogue();
}
```

**And** une impl `CatalogueRepositoryFirestoreImpl` est définie dans `lib/core/catalogue/data/catalogue_repository_firestore_impl.dart` :
- Constructeur reçoit `FirebaseFirestore firestore` injectée via le provider (cf. `firestoreProvider` existant `lib/core/firebase/providers.dart`)
- Applique systématiquement `where('isActive', isEqualTo: true)` sur toutes les queries `.snapshots()`
- Applique `.orderBy('sortOrder')` (sauf pour `derivation_rules` qui n'a pas de sortOrder — utilise ordre Firestore par défaut)
- Pour les filtres optionnels (`subSystem`, `niveauId`, `filiereId`), ajoute `.where(...)` conditionnellement
- Traduit toutes les `FirebaseException` et autres `Exception` en `CatalogueFailure` via try/catch dans la méthode `derive()` et via `Stream.handleError` dans les `watch*()` (cf. NFR-7 + pattern Story 0.6/0.7)
- Log au moins 1 fois au succès initial : `AppLogger.i('Catalogue loaded: X filieres, Y niveaux, ...')`. Au démarrage du `hasNonEmptyCatalogue()` qui retourne false : `AppLogger.w('Catalogue empty (offline+cache vide)')`.

**And** `derive()` implémente exactement l'algorithme documenté dans [ALGORITHMES.md § 1](../../doc/partage/ALGORITHMES.md#1-d%C3%A9rivation-profil--mati%C3%A8res--examens) :
1. Récupère la première `derivation_rule` Firestore active matchant `(subSystem, filiere, niveau, serie)` (avec `matchFiliere == "*"` wildcard + `matchSerie == null` autorisé si serie non fournie)
2. Si pas de match : retourne `Left(CatalogueFailure.noMatchingRule(profile))`
3. Si match : résout `subjectIds[]` → `List<Subject>` filtrés `isActive` + `examTargetIds[]` → `List<ExamTarget>` filtrés `isActive`
4. Retourne `Right(DerivedProfile(subjects, examTargets, canOptOut: rule.canOptOut))`

**And** une `sealed class CatalogueFailure extends Failure` est définie dans `lib/core/catalogue/domain/catalogue_failure.dart` avec sous-classes :
- `CatalogueFailure.empty()` — catalogue Firestore vide ET cache offline vide (1er lancement offline)
- `CatalogueFailure.networkError(String message)` — `FirebaseException` autre (permission-denied, unavailable)
- `CatalogueFailure.noMatchingRule({required String subSystem, required String filiere, required String niveau, String? serie})` — aucune `derivation_rule` ne matche

`CatalogueFailure` doit hériter de `Failure` (sealed class existante `lib/core/error/failures.dart`) pour rester compatible avec le pattern `Either<Failure, T>` global.

### AC3 — Providers Riverpod (`lib/core/catalogue/providers.dart`)

**Given** Riverpod 3.3.1 + le pattern existant (cf. `lib/core/firebase/providers.dart`)
**When** on crée les providers catalogue
**Then** les 3 providers suivants sont définis :

```dart
/// Repository — injection FirebaseFirestore.
final catalogueRepositoryProvider = Provider<CatalogueRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return CatalogueRepositoryFirestoreImpl(firestore);
});

/// Catalogue chargé lazy — utilisé par les widgets qui consomment toute la liste
/// (Story 1.3 flow profil). Stream combiné via Rx.combineLatest ou équivalent
/// Riverpod (StreamProvider qui yield un record).
final catalogueProvider = StreamProvider<CatalogueSnapshot>((ref) {
  final repo = ref.watch(catalogueRepositoryProvider);
  // Combiner les 6 streams en 1 CatalogueSnapshot complet.
  // Implémentation détaillée dans Dev Notes ci-dessous.
  ...
});

/// Vérifie au boot que le catalogue est servable. Utilisé par AppRouter pour
/// rediriger vers /catalogue-waiting si false. Retourne true si au moins 1
/// derivation_rule active existe ; false si offline+vide.
final appStartupCatalogueCheckProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(catalogueRepositoryProvider);
  return repo.hasNonEmptyCatalogue();
});
```

**And** `CatalogueSnapshot` est une classe simple (`@immutable`) regroupant les 6 listes : `List<Filiere> filieres`, `List<Niveau> niveaux`, etc. + `bool isEmpty` getter (vrai si toutes les listes sont vides).

**And** `appStartupCatalogueCheckProvider` est résolu AVANT que `SplashPage` ne navigue vers `/hello` — soit en attendant son `AsyncValue.when` dans `SplashPage`, soit via un redirect `go_router` (préférer le redirect pour rester déclaratif).

### AC4 — Écran `/catalogue-waiting` (`lib/features/catalogue/presentation/catalogue_waiting_page.dart`)

**Given** le pattern UX-DR-24 (loading/empty/error/offline) + le composant existant `AppEmptyState` (`lib/core/widgets/app_empty_state.dart`)
**When** on crée la page d'attente
**Then** la page est un `ConsumerStatefulWidget` (utilise Riverpod) qui :
- Affiche un `Scaffold` avec `backgroundColor: AppColors.primary` ou neutre (à confirmer en T4 selon brand consistency avec SplashPage)
- Centre un `AppEmptyState` avec :
  - `icon: LucideIcons.wifiOff` (pack `lucide_icons_flutter` ^3.1.14 déjà au pubspec)
  - `title: AppLocalizations.of(context).catalogueWaitingTitle`
  - `subtitle: AppLocalizations.of(context).catalogueWaitingMessage`
  - `ctaLabel: AppLocalizations.of(context).catalogueWaitingRetry`
  - `onCtaPressed: () { ref.invalidate(appStartupCatalogueCheckProvider); }` — re-trigger le check

**And** la page écoute `appStartupCatalogueCheckProvider` — dès qu'il retourne `true`, elle navigue vers la route suivante (`/hello` en P0, sera `/onboarding/subsystem` en Story 1.2 mais hors scope ici).

**And** la route `/catalogue-waiting` est ajoutée dans `lib/core/routing/app_router.dart` :

```dart
GoRoute(
  path: '/catalogue-waiting',
  builder: (context, state) => const CatalogueWaitingPage(),
),
```

**And** un `redirect` global du `GoRouter` envoie vers `/catalogue-waiting` SI `appStartupCatalogueCheckProvider.valueOrNull == false` ET la route demandée n'est pas `/splash` ni `/_*` (debug). Le `redirect` doit être idempotent (pas de boucle quand on est déjà sur `/catalogue-waiting`).

**Important** : ne PAS bloquer la SplashPage. Le splash s'affiche d'abord (animation 0.22), PUIS la SplashPage navigue (à la fin de son animation) vers `/hello` OU `/catalogue-waiting` selon le résultat de `appStartupCatalogueCheckProvider`. Si le check est encore en cours (`AsyncValue.loading`), continuer à attendre dans le splash (mais avec un timeout raisonnable, ex. 5 s, sinon assumer offline).

### AC5 — i18n FR/EN (`lib/l10n/app_fr.arb` + `app_en.arb`)

**Given** le setup gen-l10n (cf. `mobile_app/l10n.yaml`) et les conventions de microcopie UX-DR-31 (tutoiement FR, informal EN)
**When** on ajoute les 3 nouvelles clés
**Then** `app_fr.arb` reçoit :

```json
"catalogueWaitingTitle": "En attente de connexion",
"@catalogueWaitingTitle": { "description": "Titre de l'écran bloquant affiché quand le catalogue Firestore est vide ET le cache offline est vide (1er lancement offline). Cf. Story 1.1c, UX-DR-24." },

"catalogueWaitingMessage": "Pour démarrer, Valide doit se connecter une première fois. Vérifie ta connexion et réessaie.",
"@catalogueWaitingMessage": { "description": "Sous-titre rassurant qui explique pourquoi une connexion est nécessaire au 1er lancement et invite à l'action." },

"catalogueWaitingRetry": "Réessayer",
"@catalogueWaitingRetry": { "description": "CTA primaire pour re-tenter le chargement du catalogue." }
```

**And** `app_en.arb` reçoit les mêmes clés en anglais informel :

```json
"catalogueWaitingTitle": "Waiting for connection",
"catalogueWaitingMessage": "To get started, Valide needs to connect once. Check your connection and try again.",
"catalogueWaitingRetry": "Retry"
```

**And** la régénération `AppLocalizations` est faite via `flutter gen-l10n` (ou le boot Flutter le fait automatiquement avec `flutter:` `generate: true` déjà actif au pubspec).

### AC6 — Tests (`mobile_app/test/core/catalogue/` + `mobile_app/test/features/catalogue/`)

**Given** le framework `flutter_test` existant + introduction du package `fake_cloud_firestore` (nouvelle dépendance dev à ajouter au pubspec)
**When** on écrit les tests
**Then** au moins 9 tests verts couvrent :

**4 tests unitaires modèles** (`mobile_app/test/core/catalogue/data/models_test.dart`) — 1 par classe représentative :
1. `Filiere.fromFirestore(snap)` valide avec name fr+en + isActive + sortOrder
2. `Subject.fromFirestore(snap)` valide avec icon Lucide
3. `DerivationRule.fromFirestore(snap)` valide avec subjectIds[] + examTargetIds[] + matchSerie nullable
4. `Niveau.fromFirestore(snap)` valide avec filiereIds[] multiple

**3 tests repository** (`mobile_app/test/core/catalogue/data/catalogue_repository_firestore_impl_test.dart`) — utilisent `FakeFirebaseFirestore` :
1. `watchSubjects(subSystem: 'francophone')` ne retourne que les subjects `isActive: true` + `subSystem: 'francophone'` triés par `sortOrder`
2. `derive(subSystem: 'francophone', filiere: 'generale', niveau: 'francophone_terminale', serie: 'francophone_terminale_d')` retourne `Right(DerivedProfile)` avec les 9 matières attendues (cf. DONNEES-REFERENCE.md exemple Tle D) — seed la fake firestore avec la matrice minimale nécessaire au test
3. `derive(subSystem: 'francophone', filiere: 'generale', niveau: 'francophone_terminale', serie: 'unknown_serie')` retourne `Left(CatalogueFailure.noMatchingRule(...))`

**2 tests widget écran bloquant** (`mobile_app/test/features/catalogue/presentation/catalogue_waiting_page_test.dart`) :
1. Quand `appStartupCatalogueCheckProvider` retourne `false`, la page affiche `catalogueWaitingTitle` + icône `wifi-off` + bouton `Réessayer`
2. Quand le bouton est tapé, `appStartupCatalogueCheckProvider` est invalidé (vérifier via `ProviderContainer` ou observer un re-render)

**And** `flutter test` complet (incluant les 82 tests existants de Story 0.22) reste vert (0 régression).

### AC7 — firestore.rules + firestore.indexes.json + flutter analyze 0 issue

**Given** les fichiers `firestore.rules` et `firestore.indexes.json` à la racine du dépôt (cf. Story 0.9 pour les règles initiales)
**When** on étend les règles + indexes pour le catalogue
**Then** `firestore.rules` ajoute :

```javascript
// Story 1.1c — Catalogue scolaire (6 collections — ADR-015)
// Lecture par tout utilisateur authentifié (anonyme inclus).
// Écriture interdite côté client : seul le script Python seed_catalogue.py
// (Story 1.1b, avec service-account.json) ou la Firebase Console admin écrit.
match /filieres/{filiereId} {
  allow read: if request.auth != null;
  allow write: if false;
}
match /niveaux/{niveauId} {
  allow read: if request.auth != null;
  allow write: if false;
}
match /series/{serieId} {
  allow read: if request.auth != null;
  allow write: if false;
}
match /subjects/{subjectId} {
  allow read: if request.auth != null;
  allow write: if false;
}
match /exam_targets/{examTargetId} {
  allow read: if request.auth != null;
  allow write: if false;
}
match /derivation_rules/{ruleId} {
  allow read: if request.auth != null;
  allow write: if false;
}
```

**And** `firestore.indexes.json` ajoute les 3 indexes composites documentés dans BASE-DE-DONNEES.md § Catalogue scolaire :

```json
{
  "indexes": [
    {
      "collectionGroup": "series",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "subSystem", "order": "ASCENDING" },
        { "fieldPath": "niveauId", "order": "ASCENDING" },
        { "fieldPath": "filiereId", "order": "ASCENDING" },
        { "fieldPath": "isActive", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "subjects",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "subSystem", "order": "ASCENDING" },
        { "fieldPath": "isActive", "order": "ASCENDING" },
        { "fieldPath": "sortOrder", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "derivation_rules",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "matchSubSystem", "order": "ASCENDING" },
        { "fieldPath": "matchFiliere", "order": "ASCENDING" },
        { "fieldPath": "matchNiveau", "order": "ASCENDING" },
        { "fieldPath": "matchSerie", "order": "ASCENDING" },
        { "fieldPath": "isActive", "order": "ASCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

(Si `firestore.indexes.json` existe déjà avec d'autres indexes, fusionner sans écraser.)

**And** les règles sont déployées sur le projet `valide-edu` via `firebase deploy --only firestore:rules,firestore:indexes` (le porteur Delano exécute cette commande post-merge, à documenter dans le commit message + Dev Agent Record).

**And** `flutter analyze` retourne 0 issue sur tout le dépôt mobile (`mobile_app/`).

**And** `flutter test` retourne 0 failure (les 82 existants + les 9+ nouveaux).

**And** la PR est ≤ 500 lignes diff hors i18n généré (i18n_generated `app_localizations*.dart` peut être ignoré du compteur — c'est du code généré).

## Definition of Done

- [ ] `lib/core/catalogue/domain/` créé avec models (7 classes Equatable) + interface `CatalogueRepository` + `catalogue_failure.dart`
- [ ] `lib/core/catalogue/data/` créé avec `CatalogueRepositoryFirestoreImpl` + factories `fromFirestore` (séparées des models si domain pure)
- [ ] `lib/core/catalogue/providers.dart` créé avec `catalogueRepositoryProvider` + `catalogueProvider` (StreamProvider snapshot) + `appStartupCatalogueCheckProvider` (FutureProvider bool)
- [ ] `lib/features/catalogue/presentation/catalogue_waiting_page.dart` créé (ConsumerStatefulWidget réutilisant `AppEmptyState`)
- [ ] `lib/core/routing/app_router.dart` étendu avec route `/catalogue-waiting` + redirect conditionnel
- [ ] `lib/l10n/app_fr.arb` + `app_en.arb` : 3 clés ARB ajoutées (`catalogueWaitingTitle`, `catalogueWaitingMessage`, `catalogueWaitingRetry`)
- [ ] `mobile_app/pubspec.yaml` : ajout `fake_cloud_firestore` en `dev_dependencies` (version stable)
- [ ] `firestore.rules` (racine dépôt) étendu : 6 règles `match` pour catalogue (read: auth / write: false)
- [ ] `firestore.indexes.json` (racine dépôt) : 3 indexes composites ajoutés
- [ ] 9+ tests verts : 4 unit models + 3 repo + 2 widget catalogue_waiting_page
- [ ] `flutter analyze` 0 issue
- [ ] `flutter test` vert (incluant les 82 tests existants — pas de régression)
- [ ] Validation device Android (smoke test : kill app + relance avec Firestore vide → écran connexion bloquant s'affiche)
- [ ] iOS deferred (cf. 0.4bis carry-over) si pas de Mac disponible
- [ ] PR ≤ 500 lignes diff (hors i18n_generated)
- [ ] Commit unique : `feat(catalogue): CatalogueRepository Firestore + ecran connexion bloquant (Story 1.1c)`
- [ ] Action porteur post-merge documentée : `firebase deploy --only firestore:rules,firestore:indexes` sur `valide-edu`

## Tasks / Subtasks

- [ ] **T1 — Models domain (AC1)** ~45-60 min
  - [ ] T1.1 Créer `lib/core/catalogue/domain/models/filiere.dart` (Equatable, sans Firebase import)
  - [ ] T1.2 Créer les 6 autres models (Niveau, Serie, Subject, ExamTarget, DerivationRule, DerivedProfile) — 1 fichier par classe ou tous dans `models.dart` selon préférence dev (rester cohérent)
  - [ ] T1.3 `toJson()` sur chaque classe pour debug
  - [ ] T1.4 Tests unitaires basiques d'égalité Equatable (couverts par AC6)

- [ ] **T2 — Repository interface + impl Firestore (AC2)** ~80-100 min
  - [ ] T2.1 Créer `lib/core/catalogue/domain/catalogue_repository.dart` — interface abstraite
  - [ ] T2.2 Créer `lib/core/catalogue/domain/catalogue_failure.dart` — sealed CatalogueFailure extends Failure
  - [ ] T2.3 Créer `lib/core/catalogue/data/firestore_mappers.dart` (ou intégré à l'impl) — factories `fromFirestore(DocumentSnapshot)` séparées du domain pour respecter ADR-001
  - [ ] T2.4 Créer `lib/core/catalogue/data/catalogue_repository_firestore_impl.dart` — implémentation des 6 watchX() + derive() + hasNonEmptyCatalogue()
  - [ ] T2.5 Logging : `AppLogger.i('Catalogue loaded: ...')` au 1er succès, `AppLogger.w('Catalogue empty...')` si vide
  - [ ] T2.6 Traduction Exception → CatalogueFailure dans derive() (try/catch) et watch*() (handleError)

- [ ] **T3 — Providers Riverpod (AC3)** ~30-40 min
  - [ ] T3.1 Créer `lib/core/catalogue/providers.dart`
  - [ ] T3.2 `catalogueRepositoryProvider` (Provider lazy)
  - [ ] T3.3 `catalogueProvider` (StreamProvider<CatalogueSnapshot>) — combinaison des 6 streams
  - [ ] T3.4 `appStartupCatalogueCheckProvider` (FutureProvider<bool>) — lit hasNonEmptyCatalogue()
  - [ ] T3.5 Créer `CatalogueSnapshot` (@immutable record/class avec 6 listes + getter isEmpty)

- [ ] **T4 — Écran /catalogue-waiting + route + redirect (AC4)** ~60-80 min
  - [ ] T4.1 Créer `lib/features/catalogue/presentation/catalogue_waiting_page.dart` (ConsumerStatefulWidget)
  - [ ] T4.2 Réutiliser `AppEmptyState` (pas réinventer) — icon LucideIcons.wifiOff + i18n + CTA Réessayer
  - [ ] T4.3 Bouton Réessayer : `ref.invalidate(appStartupCatalogueCheckProvider)`
  - [ ] T4.4 Modifier `lib/core/routing/app_router.dart` : ajouter route `/catalogue-waiting` + redirect conditionnel
  - [ ] T4.5 Modifier `lib/features/splash/presentation/splash_page.dart` : attendre `appStartupCatalogueCheckProvider` ou laisser le redirect global décider (préférer redirect)
  - [ ] T4.6 Adapter SplashPage : si check === false → navigate /catalogue-waiting au lieu de /hello

- [ ] **T5 — i18n FR+EN ARB (AC5)** ~15-20 min
  - [ ] T5.1 Ajouter 3 clés dans `lib/l10n/app_fr.arb` (avec descriptions UX)
  - [ ] T5.2 Ajouter 3 clés dans `lib/l10n/app_en.arb` (même structure, EN informel)
  - [ ] T5.3 Vérifier régénération `AppLocalizations` (build automatique ou `flutter gen-l10n`)

- [ ] **T6 — Tests (AC6)** ~60-90 min
  - [ ] T6.1 Ajouter `fake_cloud_firestore: ^X.Y.Z` (dernière stable) en `dev_dependencies` du pubspec
  - [ ] T6.2 4 tests unitaires models (`test/core/catalogue/data/models_test.dart`)
  - [ ] T6.3 3 tests repository avec FakeFirebaseFirestore (`test/core/catalogue/data/catalogue_repository_firestore_impl_test.dart`)
  - [ ] T6.4 2 tests widget catalogue_waiting_page (`test/features/catalogue/presentation/catalogue_waiting_page_test.dart`)
  - [ ] T6.5 `flutter test` vert sur l'ensemble (82 existants + 9+ nouveaux)
  - [ ] T6.6 `flutter analyze` 0 issue

- [ ] **T7 — firestore.rules + firestore.indexes.json + smoke device + commit + PR (AC7)** ~45-60 min
  - [ ] T7.1 Étendre `firestore.rules` (racine) avec les 6 match blocks catalogue
  - [ ] T7.2 Étendre `firestore.indexes.json` (racine) avec les 3 indexes composites
  - [ ] T7.3 Tester `firebase deploy --only firestore:rules --dry-run` (optionnel, si CLI dispo localement)
  - [ ] T7.4 Build APK release (`flutter build apk --release`) + smoke device Android : vérifier qu'avec Firestore vide → écran connexion bloquant + retry → si Firestore peuplé manuellement, le retry charge OK et l'app continue vers /hello
  - [ ] T7.5 Commit unique avec message conventionnel + push branche
  - [ ] T7.6 Ouvrir PR avec body référençant ADR-015 + sprint-change-proposal + AC1-AC7 + action porteur post-merge (`firebase deploy`)

## Dev Notes

### Architecture clean (ADR-001) — règle d'or des dépendances

```
lib/core/catalogue/
├── domain/                           # PURE — pas d'import Flutter/Firebase/Riverpod/fpdart
│   ├── models/
│   │   ├── filiere.dart
│   │   ├── niveau.dart
│   │   ├── serie.dart
│   │   ├── subject.dart
│   │   ├── exam_target.dart
│   │   ├── derivation_rule.dart
│   │   └── derived_profile.dart
│   ├── catalogue_repository.dart     # interface abstraite
│   └── catalogue_failure.dart        # sealed extends Failure (lib/core/error/)
├── data/
│   ├── catalogue_repository_firestore_impl.dart   # implementation Firestore
│   └── firestore_mappers.dart        # fromFirestore(DocumentSnapshot) factories
└── providers.dart                    # Riverpod providers (Provider + StreamProvider + FutureProvider)
```

**Important** : `domain/` ne peut importer QUE `package:equatable/equatable.dart` + le `Failure` de `lib/core/error/failures.dart`. PAS d'`import 'package:cloud_firestore/cloud_firestore.dart'` dans domain.

**Pattern Failure** : `CatalogueFailure` étend `Failure` (sealed existante). Permet à `derive()` de retourner `Either<Failure, DerivedProfile>` mais aussi `Either<CatalogueFailure, DerivedProfile>` selon ce que l'appelant attend (le générique étend Failure).

### Stack technique disponible (déjà au pubspec)

| Package | Version | Usage 1.1c |
|---|---|---|
| `equatable` | ^2.0.8 | Models immutables avec égalité |
| `fpdart` | ^1.2.0 | `Either<Failure, T>` (NFR-7) |
| `cloud_firestore` | ^6.5.0 | Firestore queries `.snapshots()` + `.get()` |
| `firebase_auth` | ^6.5.2 | (indirect) auth pour read autorisé |
| `flutter_riverpod` | ^3.3.1 | Provider + StreamProvider + FutureProvider |
| `go_router` | ^17.3.0 | Route `/catalogue-waiting` + redirect global |
| `lucide_icons_flutter` | ^3.1.14+2 | `LucideIcons.wifiOff` pour l'icône |
| `flutter_screenutil` | ^5.9.3 | Pas spécifique 1.1c (AppEmptyState le gère déjà) |
| `flutter_localizations` + `intl` | sdk + ^0.20.2 | gen-l10n pour 3 nouvelles clés ARB |

**Nouvelle dépendance à ajouter** :
| Package | Version | Where |
|---|---|---|
| `fake_cloud_firestore` | ^4.x (dernière stable) | `dev_dependencies` pour tests repository |

### Algorithme `derive()` — référence canonique

Cf. [ALGORITHMES.md § 1](../../doc/partage/ALGORITHMES.md#1-d%C3%A9rivation-profil--mati%C3%A8res--examens). Pseudo-code en TypeScript dans le doc — implémentation Dart équivalente :

```dart
Future<Either<CatalogueFailure, DerivedProfile>> derive({
  required String subSystem,
  required String filiere,
  required String niveau,
  String? serie,
}) async {
  try {
    // 1. Récupérer toutes les rules actives matchant subSystem + niveau
    //    (filtre côté serveur, le reste côté client pour gérer wildcard "*")
    final rulesSnap = await _firestore
        .collection('derivation_rules')
        .where('matchSubSystem', isEqualTo: subSystem)
        .where('matchNiveau', isEqualTo: niveau)
        .where('isActive', isEqualTo: true)
        .get();

    // 2. Filtrer côté client sur filiere (wildcard "*") + serie nullable
    final rules = rulesSnap.docs
        .map((d) => DerivationRule.fromFirestore(d))
        .where((r) => r.matchFiliere == '*' || r.matchFiliere == filiere)
        .where((r) => r.matchSerie == null || r.matchSerie == serie)
        .toList();

    if (rules.isEmpty) {
      return Left(CatalogueFailure.noMatchingRule(
        subSystem: subSystem, filiere: filiere, niveau: niveau, serie: serie,
      ));
    }
    final rule = rules.first;

    // 3. Résoudre subjects + exam_targets (filtrer isActive)
    final subjectsSnap = await _firestore
        .collection('subjects')
        .where(FieldPath.documentId, whereIn: rule.subjectIds)
        .where('isActive', isEqualTo: true)
        .get();
    final examTargetsSnap = await _firestore
        .collection('exam_targets')
        .where(FieldPath.documentId, whereIn: rule.examTargetIds)
        .where('isActive', isEqualTo: true)
        .get();

    return Right(DerivedProfile(
      subjects: subjectsSnap.docs.map((d) => Subject.fromFirestore(d)).toList(),
      examTargets: examTargetsSnap.docs.map((d) => ExamTarget.fromFirestore(d)).toList(),
      canOptOut: rule.canOptOut,
    ));
  } on FirebaseException catch (e) {
    AppLogger.w('derive() Firebase error: ${e.code}', error: e);
    return Left(CatalogueFailure.networkError(e.message ?? e.code));
  } catch (e) {
    AppLogger.w('derive() unexpected error: $e', error: e);
    return Left(CatalogueFailure.networkError(e.toString()));
  }
}
```

**Note Firestore `whereIn`** : limite 30 éléments. Une rule typique a 5-10 subjects, donc OK pour V1. Si une rule a > 30 subjects (improbable), il faudra chunker la query — pas requis ici.

### Combinaison des 6 streams pour `catalogueProvider`

Option simple Riverpod 3 : utiliser `Stream.fromFutures` n'est pas idéal. Préférer un `StreamProvider.family` ou combiner manuellement :

```dart
final catalogueProvider = StreamProvider<CatalogueSnapshot>((ref) async* {
  final repo = ref.watch(catalogueRepositoryProvider);

  // Combiner via async* — yield chaque fois qu'un sous-stream émet
  // Simplification : on garde un état local mutable + on yield à chaque update
  var snap = CatalogueSnapshot.empty();

  // Subscribe aux 6 streams
  final subs = <StreamSubscription>[];

  void emit() => snap; // helper

  subs.add(repo.watchFilieres().listen((list) {
    snap = snap.copyWith(filieres: list);
  }));
  // ... pareil pour les 5 autres ...

  ref.onDispose(() {
    for (final s in subs) {
      s.cancel();
    }
  });

  // Yield initial puis re-yield manuellement quand chaque sub émet
  // (implémentation alternative : utiliser rxdart CombineLatestStream si vraiment nécessaire,
  //  mais ajouter rxdart juste pour ça est lourd. Préférer la version manuelle ci-dessus avec StreamController.)
});
```

**Alternative pragmatique** : utiliser un `StateNotifier` + 6 `StreamSubscription` qui mettent à jour un `CatalogueSnapshot`. Le dev choisira la forme la plus lisible à l'implémentation.

**Plus pragmatique encore pour V1** : exposer `catalogueProvider` comme une *façade lazy* qui ne combine pas les streams mais retourne directement le `CatalogueRepository`, et les widgets consomment directement `ref.watch(catalogueRepositoryProvider).watchFilieres()`. Cela évite la complexité de combinaison. Décision laissée au dev en T3.3 — si simplification, mettre à jour AC3 dans la PR.

### Pattern `appStartupCatalogueCheckProvider` + redirect go_router

```dart
final appStartupCatalogueCheckProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(catalogueRepositoryProvider);
  return repo.hasNonEmptyCatalogue();
});

// Dans app_router.dart :
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final check = ref.read(appStartupCatalogueCheckProvider);

      // Routes qui contournent toujours le redirect catalogue
      final bypass = state.matchedLocation.startsWith('/splash') ||
                     state.matchedLocation.startsWith('/_') ||  // routes debug
                     state.matchedLocation == '/catalogue-waiting';
      if (bypass) return null;

      return check.when(
        data: (ok) => ok ? null : '/catalogue-waiting',
        loading: () => null,  // laisse passer pendant le check, le splash gère
        error: (_, __) => '/catalogue-waiting',  // fail-safe
      );
    },
    routes: [ /* ... */ ],
  );
});
```

**Important** : `ref.read` dans le redirect (pas `ref.watch`) — go_router a son propre listenable via `refreshListenable` qu'on doit câbler avec Riverpod. Pattern classique :

```dart
final routerProvider = Provider<GoRouter>((ref) {
  // Forcer le router à se re-évaluer quand le check change
  final notifier = ValueNotifier<int>(0);
  ref.listen(appStartupCatalogueCheckProvider, (_, __) {
    notifier.value++;
  });

  return GoRouter(
    refreshListenable: notifier,
    redirect: (context, state) {
      final check = ref.read(appStartupCatalogueCheckProvider);
      // ...
    },
    routes: [ /* ... */ ],
  );
});
```

### Tests avec `fake_cloud_firestore`

```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  test('watchSubjects filtre isActive == true et subSystem', () async {
    final fakeFirestore = FakeFirebaseFirestore();

    // Seed
    await fakeFirestore.collection('subjects').doc('francophone_math').set({
      'subjectId': 'francophone_math',
      'subSystem': 'francophone',
      'name': {'fr': 'Mathématiques', 'en': 'Mathematics'},
      'icon': 'function-square',
      'isActive': true,
      'sortOrder': 10,
    });
    await fakeFirestore.collection('subjects').doc('francophone_inactive').set({
      'subjectId': 'francophone_inactive',
      'subSystem': 'francophone',
      'name': {'fr': 'Désactivée', 'en': 'Inactive'},
      'icon': 'circle',
      'isActive': false,
      'sortOrder': 20,
    });

    final repo = CatalogueRepositoryFirestoreImpl(fakeFirestore);
    final result = await repo.watchSubjects(subSystem: 'francophone').first;
    expect(result.length, 1);
    expect(result.first.subjectId, 'francophone_math');
  });
}
```

### Réutiliser `AppEmptyState` — anti-réinvention

Le composant `AppEmptyState` (`lib/core/widgets/app_empty_state.dart`) existe déjà depuis Story 0.13 et supporte exactement le pattern requis :
- `icon: IconData`
- `title: String`
- `subtitle: String?`
- `ctaLabel: String?` + `onCtaPressed: VoidCallback?`

**Anti-pattern** : créer un nouveau widget custom pour l'écran connexion bloquant. **Pattern correct** : construire `CatalogueWaitingPage` comme un Scaffold qui contient juste un `AppEmptyState` configuré.

### Pattern `Failure` Either

`fpdart` est déjà au pubspec ^1.2.0. Usage :

```dart
import 'package:fpdart/fpdart.dart';

Future<Either<CatalogueFailure, DerivedProfile>> derive(...) async {
  try {
    // ...
    return Right(DerivedProfile(...));
  } catch (e) {
    return Left(CatalogueFailure.networkError(...));
  }
}

// Consommateur :
final result = await ref.read(catalogueRepositoryProvider).derive(...);
result.fold(
  (failure) => /* handle */,
  (profile) => /* use */,
);
```

### Anti-patterns interdits

- ❌ Importer `cloud_firestore` ou `flutter` dans `lib/core/catalogue/domain/` (ADR-001 § Règle d'or)
- ❌ Réinventer un widget pour l'écran connexion bloquant (réutiliser `AppEmptyState`)
- ❌ Ajouter `freezed` ou `json_serializable` (`equatable` + factories manuelles suffisent, cf. instructions epic)
- ❌ Faire un cache custom des collections catalogue (cache Firestore offline natif suffit — ADR-010)
- ❌ Implémenter `derive()` côté serveur via Cloud Function (V1 = helper Dart client per ADR-015)
- ❌ Lire le catalogue depuis un asset JSON local (le seed JSON a été cancelled en Story 1.1)
- ❌ Modifier `firestore.rules` règles existantes (users self-only, _smoketest, etc.) — seulement ajouter les 6 nouveaux match blocks
- ❌ Lever des exceptions au lieu de retourner `Left(Failure)` depuis le repository (NFR-7)
- ❌ Logger des données sensibles (uid complet, données personnelles — pas applicable ici mais reste vigilant)
- ❌ Modifier les ADRs existants (ADR-015 mergée 2026-06-05 — référence figée)
- ❌ Modifier les 4 fichiers `doc/partage/*` ou architecture.md (déjà mergés en Story 1.1a — ne pas re-toucher)
- ❌ Story 1.1b (script Python seed) reste à faire — ne PAS l'implémenter ici, mais documenter dans le commit message qu'elle est encore en backlog

### Cohérence avec ADRs

| ADR | Application 1.1c |
|---|---|
| ADR-001 Clean architecture | Domain pure / Data Firestore / Presentation widgets séparés |
| ADR-002 Riverpod | Providers exclusivement Riverpod (pas de Provider package, pas de BLoC) |
| ADR-003 Firebase full | `cloud_firestore` consommé via `firestoreProvider` existant |
| ADR-010 Pas de cache custom | Cache offline Firestore natif (déjà actif Story 0.7) |
| ADR-015 Catalogue Firestore | Implémentation directe de la décision (CatalogueRepository + isActive filter + derive() côté client) |

### Conventions IDs à respecter

Les conventions snake_case prefixe subSystem ont été figées en Story 1.1a (cf. [BASE-DE-DONNEES.md § Catalogue scolaire](../../doc/partage/BASE-DE-DONNEES.md#catalogue-scolaire-6-collections--story-11a)) :

- `filieres/{id}` : `generale`, `technique`
- `niveaux/{id}` : `francophone_terminale`, `anglophone_form_5`
- `series/{id}` : `francophone_terminale_d`, `anglophone_upper_sixth_s2`
- `subjects/{id}` : `francophone_math`, `anglophone_pure_maths`
- `exam_targets/{id}` : `exam_bac_francophone_d`, `exam_gce_a_level_anglophone_s2`
- `derivation_rules/{id}` : `rule_francophone_generale_terminale_d`

Les tests doivent utiliser ces conventions exactes (les modèles ne valident PAS la forme de l'ID — c'est la responsabilité du script seed 1.1b).

### Action porteur post-merge (à documenter dans la PR)

Une fois la PR mergée, le porteur (Delano) doit :

1. **Déployer firestore.rules + firestore.indexes.json** :
   ```bash
   firebase deploy --only firestore:rules,firestore:indexes --project valide-edu
   ```
2. **Peupler manuellement quelques documents** (pour tester avant que Story 1.1b ne livre le script Python automatique) :
   - Au minimum 1 `filiere`, 1 `niveau`, 1 `serie`, 2 `subjects`, 1 `exam_target`, 1 `derivation_rule` — tous avec `isActive: true`
   - Permet de vérifier en device que `appStartupCatalogueCheckProvider` retourne `true` et que l'app traverse SplashPage → HelloPage normalement

3. **Tester device** : APK release + smoke test 2 scénarios (Firestore vide → écran bloquant ; Firestore peuplé → app continue).

### Project Structure Notes

Création de 2 nouveaux dossiers `lib/core/catalogue/` et `lib/features/catalogue/` cohérents avec la structure existante (cf. `lib/core/feedback/`, `lib/features/hello/`, etc.). Pas de conflit avec CLAUDE.md § Structure du dépôt.

### References

- [Epic 1 § Story 1.1c (lignes 217-283)](../planning-artifacts/epics/epic-1-onboarding.md) — définition canonique
- [ADR-015](../planning-artifacts/architecture/adrs/ADR-015-catalogue-firestore-runtime-activation.md) — décision pivot + helper Dart client V1
- [BASE-DE-DONNEES.md § Catalogue scolaire](../../doc/partage/BASE-DE-DONNEES.md#catalogue-scolaire-6-collections--story-11a) — schema 6 collections + indexes + règles
- [ALGORITHMES.md § 1](../../doc/partage/ALGORITHMES.md#1-d%C3%A9rivation-profil--mati%C3%A8res--examens) — algorithme derive() canonique
- [DONNEES-REFERENCE.md § Tableau de dérivation](../../doc/partage/DONNEES-REFERENCE.md) — exemples de dérivation pour tests (Tle D, Upper Sixth S2)
- [lib/core/error/failures.dart](../../mobile_app/lib/core/error/failures.dart) — `Failure` sealed class existante (CatalogueFailure étend)
- [lib/core/firebase/providers.dart](../../mobile_app/lib/core/firebase/providers.dart) — `firestoreProvider` à injecter dans CatalogueRepositoryFirestoreImpl
- [lib/core/widgets/app_empty_state.dart](../../mobile_app/lib/core/widgets/app_empty_state.dart) — composant à réutiliser
- [lib/core/widgets/app_button.dart](../../mobile_app/lib/core/widgets/app_button.dart) — AppButton.primary (utilisé via AppEmptyState)
- [lib/core/routing/app_router.dart](../../mobile_app/lib/core/routing/app_router.dart) — étendre avec route + redirect
- [lib/l10n/app_fr.arb](../../mobile_app/lib/l10n/app_fr.arb) — pattern existant pour les 3 nouvelles clés
- [Story 1.1a](./1-1a-audit-matrice-firestore-schema.md) — contexte + Dev Notes des conventions IDs et anti-patterns
- [sprint-change-proposal-2026-06-05.md](../planning-artifacts/sprint-change-proposal-2026-06-05.md) — pivot Firestore-driven (décisions PO)
- [CLAUDE.md § Architecture mobile](../../CLAUDE.md) — règles d'or (couches, cache Firestore, AppLogger, screenutil)

## Dev Agent Record

### Agent Model Used

(à remplir au démarrage de l'implémentation)

### Debug Log References

(à remplir pendant l'implémentation — décisions tranchées à chaud, choix techniques, problèmes Firestore vs FakeFirebaseFirestore, etc.)

### Completion Notes List

(à remplir à la fin — synthèse 7 ACs cochés, smoke test device, action porteur post-merge à exécuter)

### File List

**Files created (NEW)** :
- `mobile_app/lib/core/catalogue/domain/models/filiere.dart`
- `mobile_app/lib/core/catalogue/domain/models/niveau.dart`
- `mobile_app/lib/core/catalogue/domain/models/serie.dart`
- `mobile_app/lib/core/catalogue/domain/models/subject.dart`
- `mobile_app/lib/core/catalogue/domain/models/exam_target.dart`
- `mobile_app/lib/core/catalogue/domain/models/derivation_rule.dart`
- `mobile_app/lib/core/catalogue/domain/models/derived_profile.dart`
- `mobile_app/lib/core/catalogue/domain/catalogue_repository.dart`
- `mobile_app/lib/core/catalogue/domain/catalogue_failure.dart`
- `mobile_app/lib/core/catalogue/data/firestore_mappers.dart`
- `mobile_app/lib/core/catalogue/data/catalogue_repository_firestore_impl.dart`
- `mobile_app/lib/core/catalogue/providers.dart`
- `mobile_app/lib/features/catalogue/presentation/catalogue_waiting_page.dart`
- `mobile_app/test/core/catalogue/data/models_test.dart`
- `mobile_app/test/core/catalogue/data/catalogue_repository_firestore_impl_test.dart`
- `mobile_app/test/features/catalogue/presentation/catalogue_waiting_page_test.dart`

**Files modified (UPDATE)** :
- `mobile_app/pubspec.yaml` (+1 ligne dev_dependencies: `fake_cloud_firestore`)
- `mobile_app/lib/l10n/app_fr.arb` (+3 keys)
- `mobile_app/lib/l10n/app_en.arb` (+3 keys)
- `mobile_app/lib/core/routing/app_router.dart` (+1 route + redirect global + refreshListenable)
- `mobile_app/lib/features/splash/presentation/splash_page.dart` (navigation conditionnelle vers /catalogue-waiting si check === false)
- `firestore.rules` (racine — +6 match blocks catalogue, ~30 lignes)
- `firestore.indexes.json` (racine — +3 indexes composites)

**Story files (UPDATE)** :
- `project_manage/implementation-artifacts/1-1c-catalogue-repository-mobile.md` (frontmatter status + Dev Agent Record + DoD checkboxes + tasks/subtasks T1-T7 + Change Log)
- `project_manage/implementation-artifacts/sprint-status.yaml` (`1-1c-catalogue-repository-mobile` `ready-for-dev` → `in-progress` → `review` → `done`)

### Change Log

- **2026-06-05 (Step Create-Story)** : Story file généré via `/bmad-create-story 1.1c`. Status `backlog` → `ready-for-dev`. Estimation M (~4-5h). Code Dart + tests + écran + i18n + firestore.rules/indexes racine.
