---
story_id: 0.19
title: Risk R2 — Tests precoces flutter_smooth_markdown sur 3 cours reels
epic: 0
phase: P0
status: phase-terrain-en-attente
created: 2026-06-04
branch: feature/0.19-tests-precoces-pedagogical-content
estimation: M (~4-6h)
risk: R2
dependencies:
  - 0.15  # PedagogicalContent wrapper
sourceArtifacts:
  - project_manage/planning-artifacts/epics/epic-0-foundation.md § Story 0.19
  - project_manage/planning-artifacts/architecture/adrs/ADR-009-flutter-smooth-markdown.md
  - project_manage/planning-artifacts/architecture/.decision-log.md § 2026-06-04 Story 0.19 R2
---

# Story 0.19 — Tests précoces R2

## Objectif

ADR-009 § Tests précoces obligatoires : valider que `flutter_smooth_markdown` rend correctement 3 cours réels (mix Markdown + LaTeX + Mermaid + code) et tient l'objectif de **< 2 s à l'ouverture** sur Android entrée de gamme (Tecno Spark 8). Décision go/no-go avant E2.

## Approche en 2 phases

### Phase agent (cette PR)

- ✅ 3 cours `.md` dans `assets/dev/test_courses/`
- ✅ Route debug `/_test_courses` + `/_test_courses/:slug`
- ✅ Mesure intégrée : `Stopwatch` autour de `rootBundle.loadString` + first-frame via `addPostFrameCallback`
- ✅ Banner de bench affiché en haut de chaque page détail (vert si total < 2000 ms, ambre sinon)
- ✅ Section R2 dans `.decision-log.md` avec tableau à remplir + grille de décision

### Phase porteur (terrain)

1. `flutter run --release -d <device>` sur Tecno Spark 8 (ou équivalent ≤ Snapdragon 460, 3-4 GB RAM)
2. Naviguer vers `/_test_courses`
3. Pour chaque cours :
   - Noter `asset load`, `first frame`, `total` (visibles dans le banner)
   - Screenshoter le rendu, annoter OK/KO par bloc (LaTeX, Mermaid, tableau, code)
   - Si KO : ouvrir issue GitHub sur `flutter_smooth_markdown`
4. Remplir le tableau dans `.decision-log.md § 2026-06-04`
5. Arbitrer la décision AC4 (continuer / optimiser / fallback)

## Acceptance Criteria (état)

| AC | Implementation | Status |
| --- | --- | --- |
| AC1 — 3 cours préparés (maths/PCT/info) | `assets/dev/test_courses/{maths_derivees,pct_acide_base,info_algo_recherche}.md`, chacun > 1500 mots, ≥ 5 formules LaTeX (maths), équations chimiques (PCT), 2 flowcharts Mermaid + 4 blocs code (info) | ✅ |
| AC2 — Rendu visuel validé sur les 3 | Route `/_test_courses` + détail par slug, mesures + banner. Validation visuelle sur device. | ⏳ phase terrain |
| AC3 — Benchmark < 2 s sur Tecno Spark 8 | Stopwatch intégré, total = `asset load + first frame` affiché. Mesure réelle sur device. | ⏳ phase terrain |
| AC4 — Décision go/no-go documentée | Section R2 dans `.decision-log.md` avec grille de décision + table à remplir. | ⏳ phase terrain |

## Definition of Done

- [x] 3 fichiers `.md` dans `assets/dev/test_courses/`
- [x] Route debug `/_test_courses` + détail `/_test_courses/:slug`
- [x] Banner de mesure avec seuil 2000 ms
- [x] Section R2 dans `.decision-log.md` avec template + grille
- [x] Implementation artifact (ce fichier)
- [x] sprint-status : 0.19 in-progress
- [x] `flutter analyze` 0 issue, `flutter test` vert
- [ ] **Phase porteur** : run release sur device cible, remplir tableau, prendre décision
- [ ] Commit `test(widgets): tests precoces PedagogicalContent sur 3 cours reels`

## Cadrage

- **Pas de tests automatisés sur le rendu** : la validation visuelle est intrinsèquement humaine (un test golden ne capture pas un rendu LaTeX cassé qui s'affiche quand même comme du texte). Le `flutter test` ne couvre que l'absence de crash.
- **Stopwatch first-frame approximé** : on mesure `loadString` (fiable) + un proxy `addPostFrameCallback` (peu précis car dépend du temps de mount mais utilisable comme borne sup). Pour un benchmark précis, utiliser DevTools > Performance et lire le frame budget — c'est à faire en complément côté porteur si l'AC3 est tendu.
- **Pas d'optimisation prématurée** : si AC3 fail, on documente AVANT d'optimiser. La décision go/no-go (AC4) dicte la suite.
- **`flutter_smooth_markdown` LaTeX/Mermaid** : le wrapper `PedagogicalContent` (Story 0.15) annonce "Markdown + LaTeX + Mermaid". Si le package ne supporte pas réellement Mermaid (ou seulement partiellement), c'est précisément le KO attendu de cette story.

## Liens

- ADR-009 — `flutter_smooth_markdown` retenu (Story 0.15)
- ADR-010 — Pas de cache custom (les `.md` sont chargés à la volée, pas de cache app-level)
- Story 0.15 — `PedagogicalContent` wrapper
- Story 0.21 — clôture E0 : retirer `_test_courses` + assets `dev/`
