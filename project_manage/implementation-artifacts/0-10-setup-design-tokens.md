---
story_id: 0.10
title: Setup design tokens (core/theme/tokens.dart + app_theme.dart)
epic: 0
phase: P0
status: in-progress
created: 2026-06-04
branch: feature/0.10-design-tokens
estimation: M (~5h)
dependencies:
  - 0.2
sourceArtifacts:
  - project_manage/planning-artifacts/epics/epic-0-foundation.md § Story 0.10
  - project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/DESIGN.md (source canonique des valeurs)
---

# Story 0.10 — Setup design tokens

## Objectif

Cristalliser les tokens (couleurs, typo, spacing, radii, élévations, motion) du DESIGN.md dans `lib/core/theme/tokens.dart` + `lib/core/theme/app_theme.dart`, et brancher le tout sur `MaterialApp.router` via un `ThemeData`.

## Contexte

- Source canonique : `DESIGN.md` (toutes les valeurs hex / px / weights / durations sont à reprendre 1:1).
- Pas de `flutter_screenutil` ici (Story 0.12) → les valeurs spacing sont des `double` purs.
- Fonts non encore installées (Story 0.11) → on déclare `fontFamily: 'Nunito Sans'` qui fallback Material par défaut tant que les `.ttf` ne sont pas dans `assets/fonts/`. Pas de blocage.
- Pas de magic numbers dans les widgets — règle CLAUDE.md § Code & qualité 3.

## Acceptance Criteria

### AC1 — Tokens structurés

- **Given** `lib/core/theme/tokens.dart`
- **When** on inspecte le fichier
- **Then** il expose des classes statiques `AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppElevation`, `AppMotion`
- **And** chaque token mappe 1:1 sur DESIGN.md

### AC2 — Palette complète

- **Given** `AppColors`
- **When** on liste les valeurs
- **Then** sont définies : `primary`, `primaryDark`, `primaryLight`, `primarySoft`, `primarySoftBorder`, `ink`, `inkSoft`, `muted`, `mute2`, `border`, `bg`, `card`, `success`, `successSoft`, `successInk`, `warning`, `warningSoft`, `warningInk`, `danger`, `dangerSoft`, `dangerInk`, `sky`, `skySoft`, `skyInk` (24 couleurs)
- **And** chaque hex match DESIGN.md exact (sauf `skyInk` dérivé `#075985` car non défini dans DESIGN.md — pattern cohérent avec les autres `*Ink` de la palette Tailwind)

### AC3 — Typographie complète

- **Given** `AppTypography`
- **When** on liste les styles
- **Then** sont définis : `display`, `h1`, `h2`, `h3`, `body`, `bodyStrong`, `meta`, `caption`, `eyebrow` (9 styles)
- **And** chaque style a `fontFamily: 'Nunito Sans'`, `fontWeight`, `fontSize`, `height` selon DESIGN.md

### AC4 — Spacing, Radius, Elevation

- **Given** les autres tokens
- **When** on liste
- **Then** `AppSpacing.s1..s10..s16` (valeurs 4/8/12/16/20/24/32/40/48/64 en `double`), `AppRadius.xs..pill` (6/9/11/14/16/18/999), `AppElevation.soft/mid/brand` (List&lt;BoxShadow&gt;)
- **And** chaque valeur match DESIGN.md

### AC5 — Motion tokens

- **Given** `AppMotion`
- **When** on liste les tokens
- **Then** sont définis : `instant` (0 ms), `fast` (120 ms), `standard` (200 ms), `emphasis` (300 ms), `celebration` (600 ms), `stagger` (50 ms) en `Duration` ; `standardOut` (`Curves.easeOut`), `standardIn` (`Curves.easeIn`), `emphasized` (`Curves.easeOutCubic`)

### AC6 — ThemeData consommable

- **Given** un `appTheme = buildLightTheme()` dans `lib/core/theme/app_theme.dart`
- **When** appliqué à `MaterialApp.router(theme: appTheme)`
- **Then** un `Container(color: AppColors.primary)` rend en `#2563EB`
- **And** un test widget vérifie via `MaterialApp(theme: ...)` que `Theme.of(context).colorScheme.primary == AppColors.primary`

## Plan d'implémentation

1. Créer `mobile_app/lib/core/theme/tokens.dart` avec les 6 classes statiques (AppColors, AppTypography, AppSpacing, AppRadius, AppElevation, AppMotion)
2. Créer `mobile_app/lib/core/theme/app_theme.dart` avec `buildLightTheme()` qui retourne un `ThemeData` Material 3 (`useMaterial3: true`)
3. Mettre à jour `mobile_app/lib/app.dart` pour appliquer `buildLightTheme()` à `MaterialApp.router(theme: ...)`
4. Tests :
   - `test/core/theme/tokens_test.dart` — vérif hex primary + motion durations
   - `test/core/theme/app_theme_test.dart` — vérif ThemeData.colorScheme.primary

## Definition of Done

- [ ] Tests : 1 widget (theme primary) + 2 unitaires (token color + motion duration)
- [ ] `flutter analyze` = 0 issue
- [ ] `flutter test` = tous verts
- [ ] PR ≤ 400 lignes diff
- [ ] Commit `feat(theme): design tokens alignes sur DESIGN.md`

## Notes

- **`Color.fromARGB` interdit** (CLAUDE.md), `Color(0xFF2563EB)` à la place.
- **`Color.fromRGBO`** autorisé pour les ombres (nécessite l'alpha < 1.0).
- **Pas de `fontFamily` en dur** dans les widgets → toujours via `AppTypography.*`.
- **Spacing en `double`** pour compatibilité `flutter_screenutil` futur (`.w`).
