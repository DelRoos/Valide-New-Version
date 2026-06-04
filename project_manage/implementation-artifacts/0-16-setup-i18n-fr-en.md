---
story_id: 0.16
title: Setup i18n FR/EN (AppLocalizations + ARB)
epic: 0
phase: P0
status: in-progress
created: 2026-06-04
branch: feature/0.16-i18n-fr-en
estimation: M (~4h)
dependencies:
  - 0.2
sourceArtifacts:
  - project_manage/planning-artifacts/epics/epic-0-foundation.md § Story 0.16
  - NFR-14 (bilinguisme intégral)
  - UX-DR-31
---

# Story 0.16 — Setup i18n FR/EN

## Objectif

Configurer Flutter Localizations avec ARB FR + EN, gen-l10n, ~20 chaînes de base traduites, brancher `MaterialApp.router` avec locale par défaut `fr`, et démontrer le pattern dans `HelloPage` (qui affiche désormais « Bonjour Valide » / « Hello Valide » selon la locale).

## Contexte

- **NFR-14** : bilinguisme intégral — pas de chaîne hardcodée affichée à l'utilisateur.
- **CLAUDE.md** : tutoiement FR / informal EN.
- **Pas de `easy_localization`** : `flutter_localizations` + `gen-l10n` (Material standard) suffisent.

## Acceptance Criteria

### AC1 — `l10n.yaml` + ARB générant `AppLocalizations`

- **Given** `mobile_app/l10n.yaml` + `mobile_app/lib/l10n/app_fr.arb` + `mobile_app/lib/l10n/app_en.arb`
- **When** `flutter pub get` (qui déclenche gen-l10n via `generate: true`)
- **Then** `AppLocalizations` (importable depuis `package:flutter_gen/gen_l10n/app_localizations.dart`) est généré sans warning
- **And** `MaterialApp.router(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, locale: const Locale('fr'))` configuré

### AC2 — ~20 chaînes de base

- **Given** les fichiers ARB
- **When** on liste les clés
- **Then** existent au minimum : `appTitle`, `helloValide`, `continueLabel`, `cancelLabel`, `closeLabel`, `okLabel`, `back`, `next`, `confirmYes`, `confirmNo`, `loadingLabel`, `sendingLabel`, `loadingMore`, `retryLabel`, `tryAgain`, `errorGeneric`, `errorNoConnection`, `successCopied`, `emptyStateGeneric`, `pageNotFound`
- **And** chaque clé a sa traduction FR (tutoiement) + EN (informal)
- **And** `@helloValide` documente le placeholder `{target}`

### AC3 — Linting hardcoded strings (fallback grep CI)

- **Given** la règle CLAUDE.md (pas de chaîne en dur affichée)
- **When** un futur PR introduit `Text('Hello')`
- **Then** la note documentée dans `analysis_options.yaml` rappelle la règle et pointe vers le grep CI (Story 0.17)

### AC4 — `HelloPage` bilingue

- **Given** la route `/hello`
- **When** la locale est `fr` → texte « Bonjour Valide » ; locale `en` → texte « Hello Valide »
- **And** widget tests vérifient les deux

## Plan d'implémentation

1. Ajouter `flutter_localizations` (SDK Flutter) + `intl` à `pubspec.yaml`
2. Activer `generate: true` dans la section `flutter:` de `pubspec.yaml`
3. Créer `mobile_app/l10n.yaml` (arb-dir, template-arb-file, output-localization-file)
4. Créer `mobile_app/lib/l10n/app_fr.arb` (FR, ~20 clés, tutoiement)
5. Créer `mobile_app/lib/l10n/app_en.arb` (EN, mêmes clés)
6. `flutter pub get` → gen-l10n s'exécute → `AppLocalizations` disponible
7. Mettre à jour `app.dart` : `MaterialApp.router(localizationsDelegates, supportedLocales, locale: Locale('fr'), onGenerateTitle: ...)`
8. Refactor `HelloPage` : remplacer `Text('Hello $greetingTarget')` par `Text(l10n.helloValide(greetingTarget))`
9. Mettre à jour `widget_test.dart` : 2 cas (FR + EN) en switching la locale
10. Ajouter note dans `analysis_options.yaml`

## Definition of Done

- [ ] 2 widget tests (FR + EN) verts
- [ ] `flutter analyze` = 0 issue
- [ ] PR ≤ 250 lignes diff
- [ ] Commit : `feat(l10n): setup AppLocalizations FR EN`

## Notes

- Le **placeholder** `{target}` de `helloValide` est typé `String` (pas `Object`) dans l'ARB pour générer un paramètre typé propre.
- Le **tutoiement FR** est non négociable (CLAUDE.md).
- **`onGenerateTitle`** plutôt que `title` statique pour que le titre de la barre des tâches Android suive la locale.
