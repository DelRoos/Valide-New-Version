---
story_id: 0.13
title: Composants UX atomiques (Button, Input, Card, Badge, PillTabs, Progress, IconButton)
epic: 0
phase: P0
status: in-progress
created: 2026-06-04
branch: feature/0.13-composants-atomiques
estimation: L (~8h)
dependencies:
  - 0.10
  - 0.11
  - 0.12
sourceArtifacts:
  - project_manage/planning-artifacts/epics/epic-0-foundation.md § Story 0.13
  - project_manage/planning-artifacts/ux-designs/.../DESIGN.md § Components
  - project_manage/planning-artifacts/ux-designs/.../EXPERIENCE.md § Multisensoriel
---

# Story 0.13 — Composants UX atomiques

## Objectif

Implémenter 7 composants atomiques dans `lib/core/widgets/` consommables par tous les epics métier E1-E6. Chaque composant :

- utilise exclusivement `AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppElevation`
- supporte les 3 form factors via `flutter_screenutil` (`.w` / `.h` / `.sp`)
- a un touch target ≥ 48 dp (UX-DR-29)
- a un focus indicator visible
- a au moins un test widget behavior

## Acceptance Criteria (résumé)

| Composant | Fichier | AC clé |
|---|---|---|
| `AppButton.primary` / `AppButton.secondary` | `app_button.dart` | tap anim 120 ms + haptic light/selection + loading + disabled |
| `AppInput` | `app_input.dart` | label au-dessus, focus border 2 px primary, errorText rouge |
| `AppCard` | `app_card.dart` | padding 24, radius xl2, border 1 px, shadow soft, optional onTap |
| `AppBadge` | `app_badge.dart` | pill, tone enum, label obligatoire (debug assert) |
| `AppPillTabs` | `app_pill_tabs.dart` | indicator slide AppMotion.fast + selectionClick haptic |
| `AppProgressBar` | `app_progress_bar.dart` | AnimatedContainer 300 ms easeOutCubic |
| `AppIconButton` | `app_icon_button.dart` | 48×48, icon 20 stroke 2, ripple |

## Hors scope (différé)

- **Gallery démo** `/dev/widget_gallery.dart` + route `/_gallery` : différée — on attendra au moins un autre composant (Story 0.14 feedback) avant de la coder, pour ne pas avoir à la mettre à jour 2 fois.
- **Golden tests** : différés (epic les marque optionnels). On les ajoutera quand le rendu pixel-perfect deviendra critique (probablement E1+).
- **Lien avec `HapticService` de Story 0.14** : pour cette story, on appelle `HapticFeedback.*` Flutter directement. Quand `HapticService` sera dispo (0.14), on remplacera les appels directs par le service. TODO(0.14) ajouté dans le code.

## Plan d'implémentation

1. Ajouter `lucide_icons_flutter` au `pubspec.yaml` pour l'icon set.
2. Créer un fichier par composant dans `mobile_app/lib/core/widgets/`.
3. Tests behavior dans `mobile_app/test/core/widgets/` (1 widget test par composant).
4. `flutter analyze` + `flutter test`.

## Definition of Done

- [ ] 7 composants livrés, tous utilisent les tokens (pas de magic numbers)
- [ ] 7 widget tests verts
- [ ] `flutter analyze` = 0 issue
- [ ] PR ≤ 600 lignes diff (exception assumée : 7 composants ramassés)
- [ ] Commit : `feat(widgets): composants UX atomiques (button, input, card, badge, tabs, progress, iconbutton)`

## Notes

- **Tap feedback** au niveau atom (scale 0.96 → 1.0 + opacity 0.7 → 1.0 sur durée `AppMotion.fast`) implémenté via `StatefulWidget` + `AnimatedScale` + `AnimatedOpacity`. Pas de package externe (`flutter_animate` viendra en 0.14 pour les célébrations plus complexes).
- **Lucide icons** : `lucide_icons_flutter` retenu (plus à jour que `lucide_icons`). Permet `LucideIcons.arrowLeft` etc.
- **Pas de provider Riverpod** dans les composants atomiques — ils sont purement présentationnels, pilotés par leurs paramètres. Pas de couplage à l'état global ici.
- **Touch target 48 dp** : on utilise `Material` + `InkWell` avec une boîte au moins 48×48 même si le visuel est plus petit (pattern Flutter standard).
