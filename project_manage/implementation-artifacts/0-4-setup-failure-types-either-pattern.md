---
story_id: 0.4
title: Setup Failure types + pattern Either<Failure, T>
epic: 0
phase: P0
status: in-progress
created: 2026-06-04
branch: feature/0.4-failure-either
estimation: S (~3h)
dependencies:
  - 0.2
sourceArtifacts:
  - project_manage/planning-artifacts/epics/epic-0-foundation.md § Story 0.4
  - doc/tech/Valide School App Architecture.md § 10. Gestion des erreurs
  - NFR-7 (aucune exception ne remonte à l'UI)
---

# Story 0.4 — Setup `Failure` types + pattern `Either<Failure, T>`

## Objectif

Mettre en place la hiérarchie `Failure` sealed et le pattern `Either<Failure, T>` (via `fpdart`) en sortie de repository pour appliquer mécaniquement NFR-7 (aucune exception ne remonte à l'écran).

## Contexte technique

- ADR-001 § Règle d'or : la traduction `Exception → Failure` se fait uniquement dans `data/repositories/*_repository_impl.dart`.
- Hiérarchie cible (de l'epic) : `Failure` (sealed) → `NetworkFailure`, `AuthFailure`, `ServerFailure(code, message)`, `CacheFailure`, `ValidationFailure(field, reason)`, `UnknownFailure`.
- Divergence avec doc archi § 10.2 existante (`NotFoundFailure`, `AccessDeniedFailure` plutôt que `CacheFailure`, `ValidationFailure`) — **résolution : on suit l'epic**, la doc archi est mise à jour en conséquence.
- Pas de package Dio/Firebase encore (Stories 0.5, 0.6) → `Failure.from` se limite aux exceptions Dart standard pour l'instant + commentaires `TODO(0.5)` / `TODO(0.6)`.

## Acceptance Criteria

### AC1 — Hiérarchie sealed
- **Given** un fichier `lib/core/error/failures.dart`
- **When** on déclare les classes
- **Then** `Failure` est `sealed`, étendue par 6 sous-classes : `NetworkFailure`, `AuthFailure`, `ServerFailure(code, message)`, `CacheFailure`, `ValidationFailure(field, reason)`, `UnknownFailure`
- **And** chaque sous-classe expose un `String message` lisible utilisateur (FR temporaire, `TODO(0.16): localiser`)

### AC2 — `fpdart` intégré
- **Given** `pubspec.yaml`
- **When** on ajoute `fpdart` à la dernière stable
- **Then** `flutter pub get` réussit
- **And** `Either<NetworkFailure, String> result = Right('ok');` compile sans warning

### AC3 — Helper de traduction Exception→Failure
- **Given** un helper `Failure.from(Object exception)`
- **When** on lui passe `TimeoutException`, `SocketException`, ou `Exception('boom')`
- **Then** il retourne respectivement `NetworkFailure`, `NetworkFailure`, `UnknownFailure`
- **And** chaque cas est testé unitairement
- **And** les cas `DioException` / `FirebaseAuthException` sont stubbés via `TODO(0.5)` / `TODO(0.6)`

### AC4 — Convention documentaire
- **Given** la story marquée done
- **When** on relit `doc/tech/Valide School App Architecture.md § 10. Gestion des erreurs`
- **Then** un paragraphe court documente la convention `Either<Failure, T>` (déjà présent)
- **And** la liste de Failures § 10.2 est alignée sur la nouvelle hiérarchie

## Plan d'implémentation

1. Ajouter `fpdart` et `equatable` dans `mobile_app/pubspec.yaml`
2. Créer `mobile_app/lib/core/error/failures.dart` :
   - `sealed class Failure extends Equatable`
   - 6 sous-classes ci-dessus avec `message` FR par défaut
   - `static Failure from(Object exception)` avec switch + TODOs Story 0.5/0.6
3. Créer `mobile_app/test/core/error/failures_test.dart` (9 tests)
4. Mettre à jour `doc/tech/Valide School App Architecture.md § 10.2`
5. `flutter analyze` + `flutter test` doivent passer

## Definition of Done

- [ ] 9 tests passent (6 instantiations + 3 `Failure.from`)
- [ ] `flutter analyze` = 0 issue
- [ ] PR ≤ 250 lignes diff
- [ ] Commit : `feat(core): Failure types et pattern Either<Failure,T>`
- [ ] Doc archi alignée
- [ ] `sprint-status.yaml` : `0-4-...: done` après merge

## Décisions

- **Hiérarchie epic vs doc archi** : on suit l'epic (6 classes : Network/Auth/Server/Cache/Validation/Unknown). `NotFoundFailure` et `AccessDeniedFailure` pourront être ajoutés ultérieurement si un besoin métier le justifie (probablement Stories 0.7 cache et 0.9 règles Firestore).
- **Pas de `originalException` dans Failure** : éviter qu'une `Exception` remonte par accident jusqu'à l'UI (cf. note epic).
- **Messages FR hardcodés** : `TODO(0.16): localiser via AppLocalizations`.
