# ADR-009 — `flutter_smooth_markdown` wrappé dans un widget unique

**Date** : 2026-06-03
**Statut** : ⛔ **Superseded par [ADR-014](ADR-014-gpt-markdown-replaces-smooth-markdown.md)** (2026-06-04) — KO en phase terrain Story 0.19, basculé sur `gpt_markdown`.

## Contexte

Valide doit afficher **du contenu pédagogique riche** :

- **Markdown** (titres, listes, tableaux, blocs de code, citations) — pour tous les cours
- **LaTeX** (`$x^2$`, `$$\int_0^1 f(x)dx$$`) — essentiel pour maths, physique, chimie
- **Mermaid** (flowcharts, séquences, mindmaps) — utile pour algo, processus SVT/PCT, diagrammes
- **SVG** — schémas pédagogiques
- **Streaming** — pour le tuteur Mode 3 et le chat IA (effet « réponse qui s'écrit » que les élèves connaissent de ChatGPT)

L'approche classique consiste à empiler les libs : `flutter_markdown` + `flutter_math_fork` + WebView Mermaid + `flutter_svg`. Conséquences : multiplication des dépendances, intégrations à coder, complexité de rendu.

Une alternative existe : **`flutter_smooth_markdown`** — package qui couvre Markdown + LaTeX + Mermaid + SVG + streaming **dans un seul widget**.

**Points de vigilance majeurs sur ce package** :

- Version **0.7.x** (pré-1.0) au moment de la décision
- **Mainteneur unique**, éditeur non vérifié sur pub.dev
- Plusieurs fonctions Mermaid en `-beta`
- Téléchargements faibles, communauté restreinte
- **Breaking changes probables** avant la 1.0

## Décision

**Adopter `flutter_smooth_markdown`** pour le bénéfice d'un widget unique + streaming natif (idéal pour Mode 3).

**MAIS** : isoler le package derrière un **widget maison unique** :

```
lib/core/widgets/pedagogical_content.dart
```

**Règle non négociable** : `flutter_smooth_markdown` est **uniquement** importé dans ce fichier. Aucun écran de feature ne l'importe directement. La règle est vérifiée par lint et par revue.

Tout usage passe par :

```dart
PedagogicalContent(data: lesson.content)
PedagogicalContent.streaming(stream: chatStream)
```

## Conséquences

**Positives**

- **Rendu cohérent** sur tous les écrans pédagogiques (un seul code path).
- **Streaming natif** disponible pour Mode 3 et chat IA — pas de re-implementation.
- **Mitigation du risque mainteneur unique** : si le package est abandonné ou casse, **on remplace l'implémentation de `pedagogical_content.dart`** (par un assemblage de `flutter_markdown` + `flutter_math_fork` + WebView Mermaid + `flutter_svg`) **sans toucher aux 50+ endroits qui rendent du contenu**.
- **Suivi simple** : une seule version à monitorer.

**Négatives**

- **Risque résiduel** sur les breaking changes < 1.0 — à monitorer chaque montée de version.
- **Coverage** des cas réels (formules exotiques BAC, schémas Mermaid complexes) non garantie par l'éditeur — **test précoce obligatoire** sur 3 cours réels en P2.

## Tests précoces obligatoires

Avant la fin de la Phase 2 (Navigation et lecture du contenu) :

1. **Test rendu LaTeX** sur 3 cours réels BAC/Probatoire :
   - Maths : intégrales, sommes, vecteurs, matrices
   - PCT : équations chimiques, formules avec indices et exposants
   - SVT : symboles génétiques, formules biochimiques
2. **Test rendu Mermaid** sur :
   - Flowchart d'algorithme (info)
   - Diagramme de cycle (SVT)
   - Séquence ou Gantt (organisation)
3. **Test rendu streaming** sur :
   - Conversation chat IA avec mix Markdown + LaTeX + Mermaid
4. **Test performance** sur Android entrée de gamme (Tecno Spark 8 class) :
   - Cours de ~3000 mots avec 10 formules et 2 diagrammes : ouverture < 2 s en cache.

Si l'un de ces tests échoue → décision en revue archi cross-équipes (continuer + patcher, ou basculer sur l'assemblage classique).

## Lazy-load impératif

`flutter_smooth_markdown` n'est pas chargé au démarrage de l'app — uniquement quand un écran qui contient `PedagogicalContent` est ouvert. Cela contribue à respecter NFR-1 (APK < 30 MB) et NFR-2 (démarrage < 3 s).

## Dépendances embarquées (à ne pas déclarer en double)

`flutter_smooth_markdown` embarque déjà :

- `flutter_math_fork`
- `flutter_svg`
- `flutter_highlight`
- `cached_network_image`
- `url_launcher`

**Ne pas redéclarer** dans `pubspec.yaml` à moins d'utiliser ces packages hors du widget pédagogique (ce qui est le cas pour `cached_network_image` et `url_launcher`).

## Détail d'implémentation

Voir :

- [`doc/tech/Valide School Package Architecture.md`](../../../../doc/tech/Valide%20School%20Package%20Architecture.md) — section 5 (`flutter_smooth_markdown`, justifications et points de vigilance)
- [`doc/tech/Valide School App Architecture.md`](../../../../doc/tech/Valide%20School%20App%20Architecture.md) — section 17.7 (`PedagogicalContent` comme widget d'isolation)

## Décisions liées

Aucune dépendance directe à un autre ADR.
