---
story_id: 0.19.2
title: Styling enrichi + images + Mermaid via mermaid.ink + bloc code stylise
epic: 0
phase: P0
status: ready-for-dev
created: 2026-06-05
branch: feature/0.19.2-styling-mermaid-expandable
estimation: M (~4-6h)
dependencies:
  - 0.19  # pivot gpt_markdown
sourceArtifacts:
  - project_manage/planning-artifacts/architecture/adrs/ADR-014-gpt-markdown-replaces-smooth-markdown.md
  - project_manage/planning-artifacts/architecture/.decision-log.md § 2026-06-04 (soir) Story 0.19 R2 : pivot gpt_markdown
---

# Story 0.19.2 — Styling avancé + builders custom

## Objectif

Après le pivot vers `gpt_markdown` (ADR-014, Story 0.19), enrichir `PedagogicalContent` avec les builders custom qui couvrent les besoins de rendu V1 :

- **Images** : `imageBuilder` qui détecte raster vs SVG, applique cache disque, placeholder spinner + erreur graphique
- **Mermaid** : `codeBuilder` qui intercepte `language == 'mermaid'` et délègue au service `mermaid.ink` (rendu SVG serveur, un appel réseau par diagramme)
- **Bloc code générique** : `codeBuilder` styled avec en-tête langage, fond muted, monospace JetBrains Mono, scroll horizontal pour lignes longues
- **Cours de démo** : `assets/dev/test_courses/rendu_avance.md` qui exerce les 6 builders dans un seul fichier pour validation visuelle device

## Fichiers livrés

### `mobile_app/`

- `pubspec.yaml` — ajout `cached_network_image ^3.4.1` + `flutter_svg ^2.3.0`
- `lib/core/widgets/pedagogical_content.dart` — refactor avec `_imageBuilder`, `_codeBuilder`, `_MermaidBlock`, `_CodeBlock`, `_ImagePlaceholder`, `_ImageError`. API publique inchangée (constructeur + streaming).
- `lib/features/debug/presentation/test_courses_page.dart` — ajout `rendu_avance` en tête du catalogue
- `assets/dev/test_courses/rendu_avance.md` — démo mix image raster + SVG + LaTeX + code Python + Mermaid + tableau

### Pas modifié

- `analysis_options.yaml` — règle import-unique `gpt_markdown` déjà en place (ADR-014)
- Tests `pedagogical_content_test.dart` — toujours valides, builders custom transparents pour la signature publique

## Builders implémentés — détail

### Images

```dart
imageBuilder: (context, imageUrl, width, height) {
  final isSvg = imageUrl.toLowerCase().endsWith('.svg');
  if (isSvg) return SvgPicture.network(imageUrl, width, height, placeholderBuilder: ...);
  return CachedNetworkImage(imageUrl, width, height, placeholder: ..., errorWidget: ...);
}
```

Convention markdown : `![100x200](url)` — gpt_markdown parse `100x200` dans l'alt et passe les dimensions. Si pas de dim, l'image prend la largeur naturelle bornée par le parent.

### Mermaid

```dart
codeBuilder: (context, language, code, closed) {
  if (language.toLowerCase() == 'mermaid' && closed) {
    final b64 = base64UrlEncode(utf8.encode(code)).replaceAll('=', '');
    return SvgPicture.network('https://mermaid.ink/svg/$b64');
  }
  return _CodeBlock(language, code);
}
```

NFR-4 : un seul appel réseau par diagramme, cache disque géré par `flutter_svg`. URL signée par contenu = même diagramme dans deux cours = même cache hit.

### Bloc code

`_CodeBlock` : Container avec border + radius + fond `AppColors.muted.withValues(alpha:0.08)`. En-tête langage si non vide. `SelectableText` monospace, scroll horizontal.

## Phase terrain (Story 0.19 R2 ter)

Test sur Redmi A7 Pro (HC610L078156). Cours cible : `rendu_avance.md`. Build release.

### Mesures attendues

- Asset load : < 50 ms (~3 KB de markdown)
- First frame : ~200-400 ms (parse + render synchrone, images/Mermaid async)
- Images : visibles après ~1-2 s (latence réseau)
- Mermaid : visible après ~2-4 s (rendu serveur + DL SVG)

### Résultats device (2026-06-05 06:43, Redmi A7 Pro)

Bench `rendu_avance` : asset 9 ms / first frame 115 ms / **total 124 ms** (1ère ouverture) puis 4/62/**66 ms** (cache hit parse).

| Section | Status visuel | Notes |
| --- | --- | --- |
| Titre H1 + blockquote intro | ✅ | Blockquote stylisée, gras + italique respectés |
| Image raster Picsum (480×270) | ✅ | Visible après ~1-2s, ratio respecté, fit contain |
| Image SVG Wikipedia | ⏳ pas screenshoté | À valider (chargement asynchrone) |
| LaTeX inline `$f(x) = ax^2 + bx + c$` | ✅ | Hérité du pivot, déjà validé |
| LaTeX display (forme canonique) | ✅ | Idem |
| Bloc code Python | ✅ | Header `python`, monospace, scroll horizontal sur lignes longues |
| Diagramme Mermaid flowchart | ⚠️ → ✅ après fix | SVG initial : structure visible mais texte des nodes invisible (font non bundle dans flutter_svg). **Fix appliqué** : switch sur `mermaid.ink/img/?type=png` + `CachedNetworkImage` au lieu de `SvgPicture.network`. PNG rastérise le texte côté serveur → labels lisibles. Fallback offline : `_MermaidError` rend le source en bloc code brut. |
| Tableau récapitulatif | ✅ | gpt_markdown rend les tableaux nativement |

**Bonus** : sur le cours `info_algo_recherche` (Story 0.19), les blocs Mermaid existants sont également rendus via le nouveau builder + bloc pseudo-code avec header `text` parfait.

## Acceptance Criteria

| AC | Description | Status |
| --- | --- | --- |
| AC1 — Images raster + SVG affichées | imageBuilder custom + flutter_svg + CachedNetworkImage | ✅ raster validé, SVG à valider visuellement |
| AC2 — Mermaid rendu graphiquement | codeBuilder + mermaid.ink PNG + CachedNetworkImage | ✅ structure visible, fix PNG appliqué pour labels |
| AC3 — Bloc code stylise | _CodeBlock avec header + monospace + scroll horizontal | ✅ |
| AC4 — Fallback erreur image visible | _ImageError + _MermaidError affichent message clair | ✅ codé, validation offline pending |
| AC5 — Aucune régression sur LaTeX/markdown standard | les 3 cours Story 0.19 toujours OK | ✅ vu sur info_algo (Mermaid + code + LaTeX) |

## Definition of Done

- [x] Refactor `PedagogicalContent` avec imageBuilder + codeBuilder
- [x] Cours `rendu_avance.md` créé en tête du catalogue
- [x] `flutter analyze` 0 issue
- [x] Tests `pedagogical_content_test.dart` 4/4 pass
- [ ] Phase terrain : screencap rendu OK sur device
- [ ] Revert redirect temporaire `app_router.dart`
- [ ] Commit `feat(core): styling avance PedagogicalContent + images + Mermaid via mermaid.ink`
- [ ] Sprint-status mis à jour

## Cadrage scope V1

**Inclus dans cette PR** : images (raster + SVG) + Mermaid + bloc code stylisé.

**Reportés en stories futures** :

- Vidéos (`![video](url.mp4)`) — demande `video_player` + UI fullscreen. Story dédiée quand Mode 1/Mode 3 le requièrent.
- `<details>`/`<summary>` expandable — testable via `components`, à implémenter quand un cas pédagogique le justifie (FAQ, solutions cachées).
- Callouts custom (`> **Astuce** ...` → encadré coloré) — composable via `components` blockquote override. Décision UX à prendre (DESIGN.md ne définit pas encore ces variants).
- `selectable: true` — wrapper consommateur peut entourer de `SelectionArea` quand Mode 1 Mode 2 le demandent (E3).

## Notes

- Le service `mermaid.ink` est public et gratuit, hébergé par les mainteneurs Mermaid. Risque : si le service tombe, les diagrammes Mermaid deviennent placeholder. À surveiller en production. Plan B : héberger une instance sur Cloud Run / utiliser un fork local de mermaid.js dans une WebView.
- `cached_network_image` utilise SQLite + disk cache automatique. Pas de config additionnelle nécessaire pour respecter NFR-4 (data limitée).
- L'isolation `gpt_markdown` derrière `PedagogicalContent` reste stricte (cf. règle import-unique dans `analysis_options.yaml`).
