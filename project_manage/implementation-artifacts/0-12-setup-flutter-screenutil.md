---
story_id: 0.12
title: Setup flutter_screenutil + helper Responsive 3 form factors
epic: 0
phase: P0
status: in-progress
created: 2026-06-04
branch: feature/0.10-design-tokens  # chaine sur PR 0.10 + 0.11 (theme foundation cohérente)
estimation: M (~4h)
dependencies:
  - 0.2
  - 0.10
sourceArtifacts:
  - project_manage/planning-artifacts/epics/epic-0-foundation.md § Story 0.12
  - project_manage/planning-artifacts/architecture/adrs/ADR-011-cross-platform-v1-android-ios-tablet.md § NFR-17
  - project_manage/planning-artifacts/ux-designs/.../EXPERIENCE.md § Responsive & Platform
---

# Story 0.12 — Setup `flutter_screenutil` + helper `Responsive` 3 form factors

## Objectif

1. Wrapper `MaterialApp.router` dans `ScreenUtilInit(designSize: 375×812)` pour que `.w` / `.h` / `.sp` / `.r` deviennent disponibles partout.
2. Créer `lib/core/responsive/responsive.dart` qui expose `FormFactor` (phone / phoneLandscape / tablet) + `Responsive.of(context)` + `ResponsiveBuilder` pour les compositions multi-colonnes.
3. Refactor `HelloPage` pour démontrer l'usage : `AppColors`, `AppTypography`, `.sp`, `.w`, `Responsive.select(...)`.

## Contexte

- ADR-011 acte V1 cross-platform avec **3 form factors** (phone < 600 dp, phone-landscape 600-840 dp, tablet ≥ 840 dp).
- `flutter_screenutil` gère l'échelle relative au gabarit 375×812 (taille iPhone 14 / Android entry phone) ; `Responsive` gère la composition (combien de colonnes, NavigationRail vs bottom tabs).
- Pas de hardcoded pixels dans les widgets (CLAUDE.md § Architecture mobile 7).

## Acceptance Criteria

### AC1 — Package ajouté

- **Status** : ✅ Done
- `flutter_screenutil: ^5.9.3` ajouté à `pubspec.yaml`
- `flutter pub get` réussit

### AC2 — `ScreenUtilInit` wrappé

- **Status** : ✅ Done
- `lib/app.dart` enveloppe `MaterialApp.router` dans `ScreenUtilInit(designSize: kDesignSize, minTextAdapt: true, splitScreenMode: true, builder: ...)`
- Constante `kDesignSize = Size(375, 812)` exposée pour traçabilité

### AC3 — `Responsive` helper

- **Status** : ✅ Done
- `lib/core/responsive/responsive.dart` expose :
  - `enum FormFactor { phone, phoneLandscape, tablet }`
  - `class Responsive` immutable avec `formFactor` (computed via `MediaQuery.sizeOf(context).width`)
  - getters `isPhone` / `isPhoneLandscape` / `isTablet`
  - `select<T>({required phone, phoneLandscape, required tablet})` retourne la valeur adaptée
  - `ResponsiveBuilder` (basé sur `LayoutBuilder`) pour layouts cross-form-factor

### AC4 — HelloPage refactored

- **Status** : ✅ Done
- `lib/features/hello/presentation/hello_page.dart` :
  - utilise `AppColors.bg` pour le `Scaffold.backgroundColor`
  - utilise `AppTypography.h1` (phone) ou `AppTypography.display` (tablet) via `Responsive.select`
  - utilise `AppSpacing.s6.w` / `AppSpacing.s2.h` pour les paddings
  - `ConstrainedBox` avec `maxWidth: 600.w` pour respecter la largeur de lecture max (cf. DESIGN.md § Layout tablette)
  - Affiche le form factor courant et la largeur pour démonstration

### AC5 — Tests Responsive

- **Given** `lib/core/responsive/responsive.dart`
- **When** on appelle `Responsive._classify(width)` à différentes largeurs
- **Then** 360 → phone, 700 → phoneLandscape, 900 → tablet
- **And** `select<int>(phone: 1, tablet: 3)` retourne 1 sur phone, 3 sur tablet, 1 sur phoneLandscape (fallback)

## Definition of Done

- [ ] Tests : 3 cas classification + 1 cas select + widget test HelloPage rend bien
- [ ] `flutter analyze` = 0 issue
- [ ] `flutter test` = tous verts
- [ ] PR ≤ 300 lignes diff (légèrement plus grosse à cause du helper + tests + refactor)
- [ ] Commit : `feat(theme): flutter_screenutil et helper Responsive 3 form factors`

## Notes

- Pas de lint custom contre pixels en dur dans cette story (fallback grep CI Story 0.17).
- `.sp` pour `fontSize` est appliqué uniquement quand on extrait la valeur d'un `TextStyle` constant (cf. HelloPage : `AppTypography.h1.fontSize!.sp`). Les `TextStyle` du theme restent en `double` brut (constants requis).
- `Responsive` est volontairement minimal — pas de provider Riverpod, juste un wrapper `MediaQuery`. Léger.
