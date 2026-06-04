---
story_id: 0.14
title: Composants UX feedback + services Haptic & Audio + overlays célébration
epic: 0
phase: P0
status: in-progress
created: 2026-06-04
branch: feature/0.14-composants-feedback
estimation: L+ (~10-12h)
dependencies:
  - 0.10  # design tokens
  - 0.11  # fonts
  - 0.12  # screenutil + Responsive
  - 0.13  # composants atomiques (AppButton consommé par EmptyState CTA + Toast)
sourceArtifacts:
  - project_manage/planning-artifacts/epics/epic-0-foundation.md § Story 0.14
  - project_manage/planning-artifacts/ux-designs/.../DESIGN.md § Animations & motion + Audio + Haptics
  - project_manage/planning-artifacts/ux-designs/.../EXPERIENCE.md § Multisensoriel + Emotional Posture
---

# Story 0.14 — Composants feedback + Haptic/Audio + célébrations

## Objectif

Livrer la couche feedback complète : **7 widgets** d'affichage d'état, **2 services** Riverpod
(haptic, audio) avec coupures globales, et **3 overlays** célébration animés. Le tout consommable
par les epics métier E1-E6 via providers et `static show()`.

## Décisions de cadrage prises au démarrage (2026-06-04)

| Sujet | Décision | Justification |
|---|---|---|
| Format audio | `.m4a` (AAC) | Cross-platform Android + iOS (ADR-011, CLAUDE.md). OGG impossible iOS. |
| Détection mode silencieux Android | **Skippée pour P0** | Fallback prefs utilisateur seul (story note + simplification deps). À monter en Epic 5 si besoin. |
| Détection batterie faible | **Skippée pour P0** | Idem ci-dessus, scope déjà L+. |
| Détection Mode Examen | Provider stub (`examModeProvider` retourne `false`) | Sera wiré en E6, story le note explicitement. |
| Assets audio | **1 fichier `silence.m4a` partagé** | 12 entrées `AppSfx` pointent toutes vers le même fichier en placeholder. TODO production audio = story future. |
| Refactor existant (Pressable, AppPillTabs) | **Inclus** | Le TODO(0.14) de pressable.dart impose la migration `HapticFeedback.*` → `HapticService`. |
| PR diff size | **Exception ≤ 700 lignes accepté** | Confirmé par porteur 2026-06-04 (« 1 PR globale comme 0.13 »). |

## Acceptance Criteria (résumé — voir epic-0-foundation.md § Story 0.14 pour le détail)

| AC | Surface | Implémentation |
|---|---|---|
| AC1 | `AppToast.show(...)` | `OverlayEntry` queue, 200 ms slide-in top, 4 s display, `LucideIcons.checkCircle/circleAlert/triangleAlert` |
| AC2 | `AppModal.show(...)` | `showDialog` wrapper, max-width 420.w, padding 24.w, `AppRadius.xl2`, au moins 1 bouton (UX-DR-10) |
| AC3 | `AppBottomSheet.show(...)` | `showModalBottomSheet`, handle 36×4.h top, safe-area, primaire en bas |
| AC4 | `AppEmptyState` | Icon 64.sp + h3 + body muted + `AppButton.primary` optionnel |
| AC5 | `AppSkeleton` | `AnimationController` shimmer 1.4 s loop, statique si `disableAnimations` |
| AC6 | `AppSpinner` | `CircularProgressIndicator` styled (3 dp stroke, primary, 0.7 s rotation) |
| AC7 | `AppInlineAlert` | Bordure gauche 4 px tone + bg soft + texte ink |
| AC8 | `HapticService` | 6 méthodes, cuts pref + exam mode, séquences success/error |
| AC9 | `AudioService` | `AppSfx` enum 12 valeurs, cuts pref + exam mode, queue parallèle |
| AC10 | 3 overlays célébration | `flutter_animate`, fallback statique si `disableAnimations`, orchestre Haptic+Audio |

## Definition of Done

- [x] Story file (ce fichier)
- [ ] 7 widgets dans `lib/core/widgets/`
- [ ] 3 overlays dans `lib/core/widgets/feedback/`
- [ ] 2 services dans `lib/core/feedback/`
- [ ] Provider `feedbackPrefsProvider` (SharedPreferences) avec defaults sons/vibrations ON
- [ ] Provider stub `examModeProvider`
- [ ] Asset `assets/audio/silence.m4a` (~ 1 KB AAC silence, 100 ms)
- [ ] Pubspec : `audioplayers`, `flutter_animate`, `shared_preferences` ajoutés
- [ ] Pressable + AppPillTabs migrés sur HapticService (TODO supprimé)
- [ ] Tests : 13+ (services + widgets + overlays)
- [ ] `flutter analyze` = 0 issue, `flutter test` = tout passe
- [ ] PR sur GitHub

## Notes implémentation

- HapticService teste les coupures via Riverpod overrides (pas de mock de `HapticFeedback` directement).
- AudioService teste les coupures de la même manière, et mocke `audioplayers.AudioPlayer` côté happy path.
- Overlays célébration utilisent `Animate` de `flutter_animate` pour rester courts (~30 lignes par overlay).
- Le `silence.m4a` est généré une fois via `ffmpeg -f lavfi -i anullsrc=r=44100:cl=mono -t 0.1 -c:a aac -b:a 32k assets/audio/silence.m4a` puis committé.
