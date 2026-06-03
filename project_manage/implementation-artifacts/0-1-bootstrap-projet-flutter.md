---
storyId: 0.1
storyKey: 0-1-bootstrap-projet-flutter
epic: 0
epicTitle: Foundation & Bootstrap
phase: P0
status: in-progress
estimation: S (2-4h)
assignedTo: Amelia (BMAD dev agent)
sprint: P0-semaine-0
dependencies: []
createdAt: 2026-06-03
sourceEpic: project_manage/planning-artifacts/epics/epic-0-foundation.md
relatedADRs:
  - ADR-001-flutter-clean-architecture
  - ADR-002-riverpod-vs-getx
---

# Story 0.1 — Bootstrap projet Flutter

## User Story

**As a** tech lead Flutter,
**I want** un projet Flutter initialisé avec la structure clean architecture et un `pubspec.yaml` minimal versionné,
**so that** toutes les stories suivantes (0.2 à 0.21) puissent démarrer sur une base reproductible.

## Contexte technique étendu

Le projet n'a aucun code Flutter au moment de la story (cf. `CLAUDE.md` § Contexte projet). La structure cible suit la règle d'or `presentation → domain ← data` (cf. ADR-001) avec un découpage `core/` (transversal neutre) + `features/<feature>/` (vertical par feature).

Cette story ne crée que le **squelette** ; les sous-dossiers de `core/` seront remplis par les stories 0.2-0.5 (architecture state, AppLogger, Failure types, Dio) et 0.10-0.15 (theme, widgets, PedagogicalContent).

**Versions confirmées** :
- Flutter 3.41.9 stable (vérifié installé sur l'environnement dev le 2026-06-03)
- Dart 3.11.5

**Plateforme V1** : Android uniquement (cf. PRD § Out of scope). La commande `flutter create` doit être limitée à `--platforms android` pour éviter de générer iOS/web/desktop inutiles.

## Acceptance Criteria

### AC1 — Projet Flutter créé dans `mobile_app/`

**Given** un dépôt git existant à la racine projet (déjà initialisé en commit `5d25282`)
**When** le projet Flutter est créé dans le sous-dossier `mobile_app/` (via `flutter create --org com.valideStartup --project-name valide_school --platforms android .` puis déplacement, OU directement dans `mobile_app/`)
**Then** le dossier `mobile_app/lib/` existe avec `main.dart` qui affiche `Text('Valide School')` au lancement
**And** `mobile_app/android/` est présent et configuré
**And** `mobile_app/android/app/build.gradle.kts` a `namespace = "com.valideStartup.valideSchool"` ET `applicationId = "com.valideStartup.valideSchool"` (camelCase voulu, différent du défaut `valide_school` snake_case)
**And** `cd mobile_app && flutter analyze` retourne 0 issue
**And** `cd mobile_app && flutter pub get` réussit sans warning
**And** la racine du dépôt reste réservée aux artefacts projet (CLAUDE.md, doc/, project_manage/, futurs `firebase.json`, `firestore.rules`, etc.)

### AC2 — Structure clean architecture créée

**Given** le projet créé après AC1
**When** on liste `mobile_app/lib/`
**Then** les dossiers vides suivants existent avec un `.gitkeep` dans chaque :
- `mobile_app/lib/core/di/.gitkeep`
- `mobile_app/lib/core/error/.gitkeep`
- `mobile_app/lib/core/logging/.gitkeep`
- `mobile_app/lib/core/network/.gitkeep`
- `mobile_app/lib/core/theme/.gitkeep`
- `mobile_app/lib/core/widgets/.gitkeep`
- `mobile_app/lib/core/utils/.gitkeep`
- `mobile_app/lib/features/.gitkeep`
- `mobile_app/lib/l10n/.gitkeep`

**And** `mobile_app/lib/main.dart` est minimal : initialise `runApp(const ValideApp())`
**And** `ValideApp` est défini inline dans `main.dart` (un `lib/app.dart` séparé viendra Story 0.2 avec le routing)

### AC3 — pubspec versionné et propre

**Given** le `pubspec.yaml` initial
**When** on vérifie ses dépendances
**Then** seules sont déclarées : `flutter`, `cupertino_icons` (Material design)
**And** dev_dependencies : `flutter_lints`, `flutter_test`
**And** AUCUNE autre dépendance (les autres viendront avec leur story respective)
**And** `flutter pub get` réussit sans warning

### AC4 — README adapté pour onboarding dev

**Given** le `README.md` existant (du commit bootstrap initial)
**When** on l'enrichit
**Then** il contient une section « Démarrage rapide » avec :
- Prérequis (Flutter 3.41.x, Dart 3.11.x, Android SDK)
- `git clone`
- `cd mobile_app`
- `flutter pub get`
- `flutter run` (Android device/émulateur requis)
- Lien vers `CLAUDE.md` (structure du dépôt) et `doc/tools/CONTRIBUTING.md`

### AC5 — `flutter analyze` propre

**Given** le projet bootstrappé
**When** on exécute `cd mobile_app && flutter analyze`
**Then** la sortie est `No issues found!`

## Definition of Done

- [ ] AC1 à AC5 vérifiés
- [ ] `flutter analyze` retourne 0 issue
- [ ] `flutter pub get` réussit
- [ ] `flutter run` (smoke test sur émulateur) — si impossible localement, documenté pourquoi
- [ ] PR ≤ 200 lignes diff (hors fichiers Android autogénérés)
- [ ] Branche `feature/0.1-bootstrap-flutter`
- [ ] Commit Conventional FR : `chore(core): bootstrap projet Flutter clean architecture`
- [ ] `sprint-status.yaml` mis à jour : story `0-1-bootstrap-projet-flutter` → `review`

## Règles non négociables (rappel CLAUDE.md)

- Identifiers en **anglais**, commentaires en **français**
- Pas de TODO / FIXME sans issue (cette story est trackée, pas besoin de TODO ici)
- Pas de magic numbers — mais cette story n'introduit aucune logique métier, donc N/A
- Pas de Firebase / Dio dans `domain/` — pas de dépendance V1 ici de toute façon
- Pas de force-push sur `main`

## Notes pour l'implémenteur (Amelia)

### Particularité Windows + dépôt avec fichiers existants

`flutter create` peut renvoyer des warnings si des fichiers (README, .gitignore, etc.) existent déjà. Pas un problème — il fusionne. Vérifier que **notre** `README.md` n'est pas écrasé (si oui, restaurer + ajouter section « Démarrage rapide »).

### Pas de tests à coder dans cette story

Cette story est purement structurelle. Les tests viendront avec Story 0.2 (premier `test/widget_test.dart` adapté à la route `/hello`).

### Fichiers Flutter autogénérés

Sont OK à commit (vu en flux Flutter standard) :
- `analysis_options.yaml`
- `android/` (gradle, manifests, MainActivity Kotlin)
- `linux/`, `macos/`, `windows/`, `ios/`, `web/` — **À SUPPRIMER** : non requis V1, ajoute du bruit

### Vérifications avant PR (depuis `mobile_app/`)

```bash
cd mobile_app
flutter analyze
flutter pub get
flutter test
ls lib/core/  # 7 dossiers attendus avec .gitkeep
ls lib/features/  # vide avec .gitkeep
```

## Traçabilité

- **Epic** : 0 (Foundation & Bootstrap)
- **Phase MVP** : P0 (semaine 0)
- **ADRs implémentés** : ADR-001 (clean architecture) — structure ; ADR-002 (Riverpod) — non encore (Story 0.2)
- **FRs couverts** : aucun directement (story technique fondation)
- **NFRs préparés** : NFR-1, NFR-2, NFR-3 (lazy-load à venir Story 0.6)

## Statut de progression

| Date | Action | Auteur |
|---|---|---|
| 2026-06-03 | Story créée à partir de epic-0-foundation.md | Claude (Opus 4.7) |
| 2026-06-03 | Démarrage implémentation | Claude (en rôle Amelia) |
