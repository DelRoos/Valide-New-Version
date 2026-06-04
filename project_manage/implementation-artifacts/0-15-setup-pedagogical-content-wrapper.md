---
story_id: 0.15
title: Setup PedagogicalContent wrapper (flutter_smooth_markdown isolation)
epic: 0
phase: P0
status: in-progress
created: 2026-06-04
branch: feature/0.15-pedagogical-content-wrapper
estimation: M (~5h)
dependencies:
  - 0.10  # design tokens (typography)
  - 0.13  # composants atomiques (consistance API)
sourceArtifacts:
  - project_manage/planning-artifacts/epics/epic-0-foundation.md § Story 0.15
  - project_manage/planning-artifacts/architecture/adrs/ADR-009-flutter-smooth-markdown-wrapped.md
---

# Story 0.15 — PedagogicalContent wrapper

## Objectif

Implémenter ADR-009 : `flutter_smooth_markdown` 0.7.2 isolé derrière un widget
unique `PedagogicalContent` dans `lib/core/widgets/pedagogical_content.dart`.
**Aucun autre fichier** n'est autorisé à importer le package — si demain le
mainteneur abandonne le projet, on remplace l'implémentation interne sans
toucher aux écrans consommateurs.

## Décisions de cadrage (2026-06-04)

| Sujet | Décision | Justification |
|---|---|---|
| Version | `flutter_smooth_markdown: ^0.7.2` | Dernière 0.7.x sur pub.dev au moment de la story |
| Deferred import | **Skippé pour P0** | Story note autorise « accepte le coût initial (documente) ». Flutter AOT + deferred imports demande une plomberie qui n'est pas justifiée en P0 |
| Mermaid | Cas non testé en P0 (story 0.19 R2 testera sur cours réels) | Story note limite à 5h, exotiques en 0.19 |
| Enforce lint | CI grep dans Story 0.17 (documenté `analysis_options.yaml`) | Cohérent avec les autres règles import-unique du projet (`package:logger`) |

## Acceptance Criteria

| AC | Surface | Implémentation |
|---|---|---|
| AC1 | pubspec.yaml | `flutter_smooth_markdown: ^0.7.2` ajouté. `flutter pub get` réussit |
| AC2 | `PedagogicalContent(data: String)` | Wrapper sur `SmoothMarkdown` (API du package). Test : 1 cas MD pur + 1 cas LaTeX inline |
| AC3 | `PedagogicalContent.streaming(stream: Stream<String>)` | Accumule les chunks en `StatefulWidget`, re-rend à chaque émission. Test : stream émet `#`, ` Ti`, `tre` → rendu final équivalent à `data: '# Titre'` |
| AC4 | Règle import-unique | Documentée dans `analysis_options.yaml` (commentaire) + check CI grep prévu Story 0.17 |
| AC5 | Lazy-load | **Reporté V2** — story note autorise le fallback (coût initial documenté ici) |

## Definition of Done

- [x] Story file (ce fichier)
- [ ] `flutter_smooth_markdown: ^0.7.2` dans pubspec.yaml
- [ ] `lib/core/widgets/pedagogical_content.dart` créé (≤ 80 lignes)
- [ ] `analysis_options.yaml` met à jour le commentaire avec la règle import-unique
- [ ] Tests : 3+ (static MD, static LaTeX inline, streaming)
- [ ] `flutter analyze` = 0 issue, `flutter test` = tout passe
- [ ] PR ≤ 250 lignes diff

## Notes implémentation

- API publique du wrapper :

  ```dart
  PedagogicalContent({required String data, TextStyle? defaultStyle});
  PedagogicalContent.streaming({required Stream<String> stream, TextStyle? defaultStyle});
  ```

- Style cohérent : si `defaultStyle == null`, on hérite de `Theme.of(context).textTheme.bodyMedium` qui est lui-même alimenté par `AppTypography.body` via `buildLightTheme()`.
- Streaming : un `StatefulWidget` accumule un `StringBuffer` à chaque chunk, force un rebuild via `setState`.
- Tests Mermaid : pas dans cette story (cours réels = Story 0.19 R2).
