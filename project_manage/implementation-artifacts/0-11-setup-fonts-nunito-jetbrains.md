---
story_id: 0.11
title: Setup fonts Nunito Sans + JetBrains Mono
epic: 0
phase: P0
status: in-progress
created: 2026-06-04
branch: feature/0.10-design-tokens  # chaine sur PR 0.10 (theme foundation cohérente)
estimation: S (~2h)
dependencies:
  - 0.10
sourceArtifacts:
  - project_manage/planning-artifacts/epics/epic-0-foundation.md § Story 0.11
  - project_manage/planning-artifacts/ux-designs/.../DESIGN.md § Typography
---

# Story 0.11 — Setup fonts Nunito Sans + JetBrains Mono

## Objectif

Embarquer les fonts Nunito Sans (variable weights 400/600/700/800/900) et JetBrains Mono (400/700) dans l'app et les déclarer dans `pubspec.yaml`, pour que la typographie rendue corresponde à DESIGN.md sans appel Google Fonts en runtime.

## Contexte

- DESIGN.md : Nunito Sans pour le texte, JetBrains Mono pour le code inline.
- **Pas de `google_fonts` package** : appel réseau au runtime = data + latence sur le marché cible.
- **Variable fonts** retenus : un seul fichier `.ttf` par famille couvre toutes les graisses → moins de fichiers à maintenir, taille bundle inférieure.
- Sources officielles : `github.com/google/fonts/ofl/` (mirror Google Fonts canonique).

## Acceptance Criteria

### AC1 — Fonts téléchargées et placées

- **Status** : ✅ Done
- **Given** `mobile_app/assets/fonts/`
- **When** on inspecte
- **Then** sont présents :
  - `NunitoSans-Variable.ttf` (571 KB, variable axes YTLC/opsz/wdth/wght)
  - `JetBrainsMono-Variable.ttf` (187 KB, variable axe wght)

### AC2 — Déclaration `pubspec.yaml`

- **Status** : ✅ Done
- **Given** `pubspec.yaml`
- **When** on lit la section `flutter.fonts`
- **Then** sont déclarées `Nunito Sans` et `JetBrains Mono` avec `asset:` correspondant
- **And** `flutter pub get` réussit sans erreur

### AC3 — Le textTheme charge la font

- **Status** : ⏳ à vérifier (par les tests existants + visuel sur device)
- **Given** `MaterialApp(theme: buildLightTheme())`
- **When** un widget rend `Text('test', style: AppTypography.h1)`
- **Then** la police affichée est Nunito Sans 30/900
- **And** `flutter analyze` reste vert
- **And** `flutter test` reste vert (les tests qui interrogent `fontFamily` doivent toujours passer)

## Plan d'implémentation

1. Télécharger les 2 variable fonts dans `mobile_app/assets/fonts/` (fait via curl depuis google/fonts repo)
2. Ajouter section `flutter.fonts:` dans `pubspec.yaml`
3. `flutter pub get`
4. `flutter analyze` + `flutter test`

## Definition of Done

- [x] 2 fichiers `.ttf` présents et non vides
- [x] Pubspec déclare les 2 familles
- [x] `flutter analyze` = 0 issue
- [ ] `flutter test` = vert (à valider après commit groupé avec 0.12)
- [ ] PR ≤ 200 lignes diff (binaires fonts comptent en bytes mais pas en lignes)
- [ ] Commit : `feat(theme): fonts Nunito Sans + JetBrains Mono embarquees`

## Notes

- Variable fonts : Flutter ne supporte pas encore tous les axes (uniquement `wght` est interpolable). Pour Nunito Sans on a aussi `YTLC`/`opsz`/`wdth` qui sont stockés mais ignorés. C'est OK : la graisse est l'axe principal utilisé.
- Taille totale embarquée : ~758 KB (acceptable, dans la cible NFR-1 « < 30 MB par device »).
- Si besoin de réduire : `font_subset` Flutter peut tailler les glyphes non utilisés au build release (gain ~50 %).
