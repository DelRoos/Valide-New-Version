---
story_id: 0.7
title: Setup cache offline Firestore (40 MB persistance)
epic: 0
phase: P0
status: ready-for-dev
created: 2026-06-04
branch: feature/0.7-cache-offline-firestore
estimation: XS (~1h)
dependencies:
  - 0.6  # Firebase providers + init
sourceArtifacts:
  - project_manage/planning-artifacts/epics/epic-0-foundation.md § Story 0.7
  - project_manage/planning-artifacts/architecture/adrs/ADR-010-zero-cache-custom.md
---

# Story 0.7 — Cache offline Firestore

## Objectif

Appliquer `Settings(persistenceEnabled: true, cacheSizeBytes: 40 MB)` sur le
provider Firestore avant tout appel `get()` / `snapshots()`, pour garantir
NFR-5 (zéro cache custom) et FR-14 (lecture hors-ligne) dès la première
lecture.

## Implementation

### `lib/core/firebase/providers.dart`

`firestoreProvider` modifié pour appliquer les settings + emettre un log :

```dart
const int _firestoreCacheSizeBytes = 40 * 1024 * 1024;

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  final firestore = FirebaseFirestore.instance;
  firestore.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: _firestoreCacheSizeBytes,
  );
  AppLogger.i('Firestore cache: 40MB, persistence on');
  return firestore;
});
```

L'ordre est critique : `firestore.settings = ...` lock les settings au
premier `get()` / `snapshots()`. Le `Provider` Riverpod cache l'instance, le
bloc s'exécute donc une seule fois par container.

### Tests

`test/core/firebase/providers_test.dart` : ajouté un test skip qui documente
la procédure AC2 (test cache après coupure réseau) pour exécution manuelle
sur émulateur Android après Phase B Console activée.

## Acceptance Criteria (état)

| AC | Implementation | Status |
|---|---|---|
| AC1 — Settings appliqués au boot | `firestoreProvider` applique `Settings` + log `AppLogger.i('Firestore cache: 40MB, persistence on')` | ✅ |
| AC2 — Lecture cached vérifiée (`isFromCache == true` offline) | Test skip documenté en procédure manuelle (demande device + réseau pilotable + Console activée) | 🟡 manuel après Phase B Console |
| AC3 — Pas de cache custom dans `lib/` | grep `package:(hive\|drift\|isar\|sqflite)` → 0 résultat dans `lib/` ; pubspec.yaml ne déclare aucun de ces packages | ✅ |

## Definition of Done

- [x] `firestoreProvider` applique Settings 40 MB + persistance ON
- [x] Log `AppLogger.i('Firestore cache: 40MB, persistence on')` confirmant
- [x] Test skip + procédure AC2 documentée dans le fichier de test
- [x] AC3 — grep négatif validé
- [x] `flutter analyze` = 0, `flutter test` = vert (test AC2 skipped)
- [ ] PR ≤ 80 lignes diff
- [ ] Commit `feat(core): cache offline Firestore 40MB persistence on`

## Notes

- `cacheSizeBytes` à 40 MB (vs défaut 100 MB) : aligné NFR-1 + NFR-2 pour
  les téléphones modestes du marché cible. Marge confortable pour stocker
  ~500-1000 documents matières/contenu avant éviction LRU.
- `Settings.persistenceEnabled` existe aussi en `Settings.CACHE_SIZE_UNLIMITED`
  — non utilisé ici (politique de borne explicite).
- Le test AC2 sera potentiellement automatisé en Story 0.19 (R2 tests précoces)
  via `integration_test/` si la procédure se révèle stable.
