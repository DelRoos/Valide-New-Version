---
storyId: 0.2
storyKey: 0-2-setup-architecture-state-routing
epic: 0
epicTitle: Foundation & Bootstrap
phase: P0
status: in-progress
estimation: M (4-6h)
assignedTo: Amelia (BMAD dev agent)
sprint: P0-semaine-0
dependencies: [0.1]
createdAt: 2026-06-03
sourceEpic: project_manage/planning-artifacts/epics/epic-0-foundation.md
relatedADRs:
  - ADR-002-riverpod-vs-getx
---

# Story 0.2 — Setup architecture state + routing

## User Story

**As a** tech lead Flutter,
**I want** Riverpod et go_router intégrés avec un shell d'app vide mais navigable,
**so that** chaque feature suivante puisse déclarer ses providers et routes sans toucher au bootstrap.

## Contexte technique étendu

ADR-002 acte le choix `flutter_riverpod` (et non GetX) pour des raisons de durabilité, testabilité et dépendances explicites. Le routing utilise `go_router` (cf. `doc/tech/Valide School Package Architecture.md`).

**Périmètre strict** :
- Cette story crée le shell racine + 1 route stub `/hello`
- Les routes métier viendront avec leurs features (E1-E6)
- Le wrap `ScreenUtilInit` viendra en Story 0.12 — pour l'instant `MaterialApp.router` direct

**Structure cible** :

```
mobile_app/lib/
├── main.dart                          # runApp(ProviderScope)
├── app.dart                           # ValideApp ConsumerWidget → MaterialApp.router
├── core/
│   ├── di/
│   │   └── providers.dart             # helloProvider (déchet test)
│   └── routing/
│       └── app_router.dart            # routerProvider (GoRouter)
└── features/
    └── hello/
        └── presentation/
            └── hello_page.dart        # HelloPage → "Hello Valide"
```

## Acceptance Criteria

### AC1 — Packages ajoutés

**Given** le `mobile_app/pubspec.yaml` issu de Story 0.1
**When** on ajoute `flutter_riverpod` et `go_router` aux dernières stables compatibles Flutter 3.41
**Then** `flutter pub get` réussit
**And** aucune autre dépendance n'est introduite

### AC2 — `ProviderScope` racine

**Given** `mobile_app/lib/main.dart`
**When** on lance l'app
**Then** `runApp(const ProviderScope(child: ValideApp()))` est exécuté
**And** un `helloProvider = Provider<String>((ref) => 'Valide')` est exposé depuis `core/di/providers.dart`
**And** ce provider est consommé par `HelloPage`

### AC3 — `go_router` avec route `/hello`

**Given** un `routerProvider` Riverpod défini dans `core/routing/app_router.dart`
**When** on lance l'app
**Then** la route initiale `/` redirige vers `/hello`
**And** `/hello` affiche `Text('Hello Valide')` (où `Valide` vient du `helloProvider`)
**And** un test widget vérifie ce rendu

### AC4 — Router accessible via provider

**Given** `routerProvider` Riverpod
**When** `MaterialApp.router(routerConfig: ref.watch(routerProvider))` est utilisé
**Then** la navigation `context.go('/hello')` marche depuis n'importe quel widget descendant de `ValideApp`
**And** un re-render du widget consommateur du `routerProvider` ne crée pas de nouveau `GoRouter` (Provider Riverpod garantit la singleton-ité pendant la vie du ProviderScope)

### AC5 — `flutter analyze` propre

**Given** le projet modifié
**When** `cd mobile_app && flutter analyze`
**Then** la sortie est `No issues found!`

### AC6 — `flutter test` passe

**Given** le test widget de la route `/hello`
**When** `cd mobile_app && flutter test`
**Then** `All tests passed!`

## Definition of Done

- [ ] AC1 à AC6 vérifiés
- [ ] 1 test widget (`/hello` rend `Hello Valide`)
- [ ] PR ≤ 150 lignes diff
- [ ] Branche `feature/0.2-setup-architecture-routing`
- [ ] Commit `feat(core): setup Riverpod et go_router avec shell minimal`
- [ ] `sprint-status.yaml` : `0-2-setup-architecture-state-routing` → `review` puis `done`

## Règles non négociables

- Pas de `flutter_riverpod_lint` / `custom_lint` ici (overhead pour P0)
- `routerProvider` = simple `Provider`, pas `AsyncNotifier` à ce stade
- Garde la route `/hello` même après la story 0.21 (sentinelle régression CI)
- Identifiers anglais, commentaires FR si nécessaires

## Notes pour l'implémenteur (Amelia)

### Versions cibles (à valider via `flutter pub outdated`)

- `flutter_riverpod: ^2.5.x` (stable)
- `go_router: ^14.x` (vérifier compat Flutter 3.41.9 ; sinon ^13.x)

### Architecture du wrap

Future structure post-Story 0.12 (pour info, **pas dans cette story**) :

```dart
runApp(
  ProviderScope(
    child: ScreenUtilInit(  // Story 0.12
      designSize: const Size(375, 812),
      child: const ValideApp(),
    ),
  ),
);
```

### Test widget — particularité

`MaterialApp.router` avec redirect `/` → `/hello` nécessite `pumpAndSettle()` après `pumpWidget()` pour que la redirection soit appliquée.

```dart
await tester.pumpWidget(const ProviderScope(child: ValideApp()));
await tester.pumpAndSettle();
expect(find.text('Hello Valide'), findsOneWidget);
```

## Traçabilité

- **Epic** : 0 (Foundation & Bootstrap)
- **Phase MVP** : P0 (semaine 0)
- **ADRs implémentés** : ADR-002 (Riverpod)
- **FRs préparés** : aucun (story technique, débloque les features E1+)
- **NFRs préparés** : NFR-7 (Either pattern à venir Story 0.4 utilisera Riverpod)
