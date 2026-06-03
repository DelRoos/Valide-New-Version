---
story_id: 0.5
title: Setup Dio + retry + connectivity_plus
epic: 0
phase: P0
status: in-progress
created: 2026-06-04
branch: feature/0.5-dio-retry-connectivity
estimation: M (~4-5h)
dependencies:
  - 0.3
  - 0.4
sourceArtifacts:
  - project_manage/planning-artifacts/epics/epic-0-foundation.md § Story 0.5
  - NFR-15 (retry backoff exponentiel)
  - CLAUDE.md § Architecture mobile règle 3 (logging via AppLogger)
---

# Story 0.5 — Setup Dio + retry + connectivity_plus

## Objectif

Mettre en place `DioClient` (HTTP client) avec interceptor de log via `AppLogger` et interceptor de retry exponentiel (3 tentatives, 500 ms / 1 s / 2 s sur 5xx + timeouts + 429), plus `NetworkInfo` provider basé sur `connectivity_plus` (online/offline/unknown + stream).

## Contexte

- **NFR-15** : toute action réseau doit avoir un retry backoff + message d'erreur clair + état restituable.
- Marché cible = connectivité fluctuante (cf. SPEC Constraints).
- **Dio = appels HTTP non Firebase** (Cloud Functions custom, APIs externes). Les appels Firebase passent par les SDK Firebase (Story 0.6).
- Pas de `dio_smart_retry` — implémentation manuelle pour ne pas dépendre d'un package fragile.
- Pas de `pretty_dio_logger` — `AppLogger` suffit.

## Acceptance Criteria

### AC1 — Packages ajoutés

- **Given** `mobile_app/pubspec.yaml`
- **When** on ajoute `dio` et `connectivity_plus` aux dernières stables
- **Then** `flutter pub get` réussit

### AC2 — `DioClient` créé

- **Given** `lib/core/network/dio_client.dart`
- **When** on instancie `DioClient`
- **Then** il expose une `Dio` avec base URL configurable via env, timeout 30 s
- **And** un interceptor de log appelle `AppLogger.d/i/w/e` (pas de log du body si > 1 KB)

### AC3 — Retry interceptor

- **Given** un endpoint qui renvoie 503 deux fois puis 200
- **When** on `dioClient.dio.get('/test')`
- **Then** la requête réussit en 3 tentatives au total (backoff 500 ms, 1 s)
- **And** un log `AppLogger.w` indique chaque retry avec le délai
- **And** tests unitaires : `503→503→200` succès, `503×4` échec final, `200` direct sans retry

### AC4 — `NetworkInfo` provider exposé

- **Given** `lib/core/network/network_info.dart`
- **When** on `ref.watch(networkStatusProvider)`
- **Then** on reçoit un `AsyncValue<NetworkStatus>` (`online | offline | unknown`)
- **And** le stream émet à chaque changement de connectivité
- **And** tests unitaires : 2 cas mock (online + offline)

## Plan d'implémentation

1. Ajouter `dio` et `connectivity_plus` dans `pubspec.yaml`
2. Créer `lib/core/utils/env.dart` exposant `Env.apiBaseUrl` via `String.fromEnvironment`
3. Créer `lib/core/network/dio_client.dart` :
   - `class DioClient` avec constructeur configurable
   - `_LogInterceptor` interne (utilise `AppLogger`)
   - `_RetryInterceptor` interne (3 tentatives, backoff exponentiel, `delay` injectable pour tests)
4. Créer `lib/core/network/network_info.dart` :
   - `enum NetworkStatus { online, offline, unknown }`
   - `class NetworkInfo` avec `Future<NetworkStatus> get status` et `Stream<NetworkStatus> get statusStream`
   - `networkInfoProvider` (Provider) + `networkStatusProvider` (StreamProvider)
5. Tests :
   - `test/core/network/dio_client_test.dart` — 3 cas retry via FakeAdapter
   - `test/core/network/network_info_test.dart` — 2 cas mock Connectivity

## Definition of Done

- [ ] Tests unitaires : retry (3 cas) + NetworkInfo (2 cas mock) — 5+ tests
- [ ] `flutter analyze` = 0 issue
- [ ] `flutter test` = tous verts
- [ ] PR ≤ 350 lignes diff
- [ ] Commit : `feat(core): DioClient avec retry et NetworkInfo`
- [ ] `sprint-status.yaml` : `0-5-setup-dio-retry-connectivity: done` après merge

## Notes

- Base URL via `--dart-define=API_BASE_URL=https://api.valide.school` au build. Default sentinel `https://api.valide.school` en attendant Story 0.6 / 0.18 qui fixera la vraie URL.
- Le retry propage `DioException` après épuisement — la traduction en `NetworkFailure` se fait dans les repository impls (déjà prévue dans `Failure.from(Object)` Story 0.4 — il faudra ajouter une branche `DioException` quand on intégrera ; pour cette story, on laisse le `TODO(0.5)` du failures.dart se résoudre — voir ajout possible si propre).
- Le `_RetryInterceptor` accepte un `Future<void> Function(Duration) sleep` injectable pour permettre des tests rapides (no-op sleep).
