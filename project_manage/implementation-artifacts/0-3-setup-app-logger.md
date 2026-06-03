---
story_id: 0.3
title: Setup AppLogger
epic: 0
phase: P0
status: in-progress
created: 2026-06-04
branch: feature/0.3-app-logger
estimation: M (~4h)
dependencies:
  - 0.2
sourceArtifacts:
  - project_manage/planning-artifacts/epics/epic-0-foundation.md § Story 0.3
  - CLAUDE.md § Architecture mobile règles 3 & 4
---

# Story 0.3 — Setup `AppLogger`

## Objectif

Mettre en place le wrapper `AppLogger` (single point of import) au-dessus de `package:logger` avec redaction systématique des données sensibles, conformément aux règles non-négociables CLAUDE.md § Architecture mobile 3 et 4.

## Contexte technique

- **CLAUDE.md § Architecture mobile 3** : `package:logger` n'est importé que dans `lib/core/logging/app_logger.dart`.
- **CLAUDE.md § Architecture mobile 4** : ne jamais logger mots de passe, jetons, codes PIN, numéros de téléphone complets, données personnelles sensibles.
- **Niveaux** : debug = `verbose`, release = `warning`.
- **Formats téléphone CM à gérer** : `+237XXXXXXXXX`, `237XXXXXXXXX`, 9 chiffres locaux.

## Acceptance Criteria

### AC1 — Wrapper créé
- **Given** un nouveau fichier `lib/core/logging/app_logger.dart`
- **When** on importe `AppLogger`
- **Then** il expose `v(String message, {Object? error})`, `d`, `i`, `w`, `e(String message, {Object? error, StackTrace? stackTrace})`
- **And** il instancie un `Logger` de `package:logger` en interne (jamais exposé)

### AC2 — Redaction données sensibles
- **Given** `AppLogger.i('Login attempt for user +237698765432 with token=abc.def.ghi')`
- **When** on log via `AppLogger`
- **Then** la sortie contient `+237***5432` (masquage milieu) et `token=***`
- **And** 3 patterns testés : téléphone, JWT, `pin=`/`password=`

### AC3 — Niveau par environnement
- **Given** `kReleaseMode == true`
- **When** `AppLogger.v('detail')` est appelé
- **Then** rien n'est émis (filtré au niveau `warning`)

### AC4 — Lint interdit import direct `package:logger`
- **Given** un fichier `lib/features/foo/foo.dart` qui importerait directement `package:logger`
- **When** la vérification CI est exécutée
- **Then** un échec est produit pointant la ligne d'import
- **And** un commentaire dans `analysis_options.yaml` documente la règle (fallback grep en CI Story 0.17)

## Plan d'implémentation

1. Ajouter `logger: ^2.x` dans `mobile_app/pubspec.yaml`
2. Créer `mobile_app/lib/core/logging/app_logger.dart` :
   - Classe `AppLogger` statique avec méthodes `v`/`d`/`i`/`w`/`e`
   - Helper privé `_redact(String message)` appliquant 3 regex (phone, JWT, credentials)
   - Filtre `Level.warning` si `kReleaseMode`, sinon `Level.trace`
3. Ajouter commentaire dans `mobile_app/analysis_options.yaml` documentant la règle d'import unique
4. Créer `mobile_app/test/core/logging/app_logger_test.dart` avec 4 tests :
   - Redaction téléphone (`+237698765432` → `+237***5432`)
   - Redaction JWT (`token=abc.def.ghi` → `token=***`)
   - Redaction credentials (`pin=1234`, `password=secret` → `***`)
   - Niveau filtré en release (out de scope automatique : test du filtre seul)
5. `flutter analyze` + `flutter test` doivent passer

## Definition of Done

- [ ] Tests unitaires : 4 tests passent
- [ ] `flutter analyze` = 0 issue
- [ ] PR ≤ 200 lignes diff
- [ ] Commit : `feat(core): AppLogger avec redaction donnees sensibles`
- [ ] `sprint-status.yaml` mis à jour (`0-3-setup-app-logger: done` après merge)

## Notes

- Pas de règle `custom_lint` à ce stade (fallback grep CI Story 0.17 documenté en commentaire `analysis_options.yaml`).
- Ne jamais logger un payload JSON entier — extraire et logger des champs identifiés (documenté en commentaire de tête du fichier).
- La doc longue (`doc/tech/Valide School App Architecture.md § Logging`) sera mise à jour si le paragraphe n'existe pas encore (vérification à faire).
