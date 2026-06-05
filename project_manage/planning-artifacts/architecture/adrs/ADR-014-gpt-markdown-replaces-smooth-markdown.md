# ADR-014 — `gpt_markdown` remplace `flutter_smooth_markdown`

**Date** : 2026-06-04
**Statut** : 🟢 Accepté
**Supersède** : [ADR-009](ADR-009-flutter-smooth-markdown-wrapped.md)

## Contexte

[ADR-009](ADR-009-flutter-smooth-markdown-wrapped.md) retenait `flutter_smooth_markdown` (v0.7.x) pour le rendu pédagogique (Markdown + LaTeX + Mermaid + streaming), wrappé derrière `PedagogicalContent` (Story 0.15).

[Story 0.19 R2](../../../implementation-artifacts/0-19-tests-precoces-flutter-smooth-markdown.md) exigeait des **tests précoces obligatoires** sur 3 cours réels (maths/PCT/info) avant E2. La phase terrain a été exécutée sur Redmi A7 Pro (release build) le 2026-06-04. Résultat :

- ❌ **Les 3 cours réels rendent un bloc gris uniforme**, aucun contenu visible (titres, paragraphes, LaTeX, Mermaid, tableaux, code — rien)
- ✅ Le wrapper fonctionne sur markdown ultra-minimal (`# Hello\n\nWorld this is a **test**.`)
- 🟡 Aucune erreur Flutter visible en `adb logcat` (release mode silencieux)
- 🟡 Investigation 3 hypothèses (`SingleChildScrollView` au lieu de `ListView`, `MarkdownStyleSheet.light()` au lieu de `.fromTheme.copyWith`, content minimal) : seul H3 explique le rendu OK — H1/H2 KO. La cause racine sur contenu réel reste **non identifiée**.

Détails complets : voir `.decision-log.md § 2026-06-04 Story 0.19 R2` et `chore/0.19-investigation-singlechildscroll`.

## Décision

Basculer **immédiatement** sur **[`gpt_markdown`](https://pub.dev/packages/gpt_markdown)** (v1.1.7 au moment de la décision).

Le wrapper `PedagogicalContent` est ré-implémenté autour de `GptMarkdown` — l'API publique consommée par le projet ne change pas hors :

- `MarkdownStyleSheet` (ancienne API smooth_markdown) → `TextStyle` (style de base — gpt_markdown applique son scaling interne pour titres/code/etc)
- `selectable` → retiré (gpt_markdown n'expose pas l'option ; on l'ajoutera via `SelectableText.rich` si nécessaire)
- `onTapLink` (signature `(String url)`) → `onLinkTap` (signature `(String url, String title)`)

Mermaid n'est **pas supporté nativement** par `gpt_markdown` — les blocs ```` ```mermaid ```` tomberont en bloc code brut. Pour le rendu graphique des flowcharts en E2+ : ouvrir une story qui décide entre WebView (mermaid.js) ou builder custom (codeBuilder qui intercepte `language == 'mermaid'`).

## Conséquences

### Positives

- ✅ Rendu LaTeX **éprouvé** : `gpt_markdown` utilise `flutter_math_fork`, la lib standard reconnue pour le rendu LaTeX en Flutter
- ✅ Streaming **natif** : conçu pour rendre du Markdown LLM (OpenAI/Claude/Gemini outputs) qui arrive en chunks — chaque mise à jour redessine sans crash, gère les markdown partiels (table mid-row, code block non fermé)
- ✅ **Maturité** : v1.1.7, ~700+ likes pub.dev, mainteneur actif, traction en hausse
- ✅ **Bug de rendu bloc gris** : éliminé (à confirmer via phase terrain bis)
- ✅ Pas de dépendance Mermaid native → moins de surface d'attaque pour les bugs

### Négatives / nouvelles dettes

- ❌ Mermaid perdu nativement → dette technique reportée à E2+ (impact mineur : Mermaid n'est dans aucun contenu V1 confirmé, on peut documenter avec PlantUML ou texte structuré en attendant)
- ❌ Styling moins fin que la copyWith de smooth_markdown : `gpt_markdown` accepte un seul `TextStyle` de base, le scaling des titres est interne. À surveiller si le design diverge sensiblement de la cascade par défaut.
- ❌ `selectable: true` perdu sur le wrapper → si on a besoin (Mode 1 énoncé sélectionnable), envelopper dans `SelectionArea` en E3.

### Neutres

- 🟡 Taille APK : `gpt_markdown` (~150 KB) légèrement plus petit que `flutter_smooth_markdown` (~500 KB + assets Mermaid). Net positif.
- 🟡 Couplage : `gpt_markdown` dépend explicitement de `flutter_math_fork` qu'on aurait possiblement intégré quand même.

## Plan d'exécution

1. ✅ Refactor `PedagogicalContent` (cette PR)
2. ✅ Remplacer la règle d'isolation dans `analysis_options.yaml` (`flutter_smooth_markdown` → `gpt_markdown`)
3. ✅ Update tests `pedagogical_content_test.dart`
4. ✅ Retirer `flutter_smooth_markdown` du `pubspec.yaml`
5. ✅ Update `pubspec.lock` via `flutter pub get`
6. ⏳ Re-tester les 3 cours sur device (phase terrain bis) — déclenche AC4 final
7. ⏳ Mettre à jour Story 0.21 (sentinelle E0) pour valider le rendu via les 3 cours réels avant clôture E0

## Décisions liées

- [ADR-009](ADR-009-flutter-smooth-markdown-wrapped.md) — superseded
- [ADR-012](ADR-012-firebase-ai-logic-replace-claude.md) — précédent pivot package critique (Claude SDK → Firebase AI Logic)
- Story 0.19 — découverte du KO
- Story 0.15 — création du wrapper `PedagogicalContent` (à revalider après pivot)
- `.decision-log.md § 2026-06-04 Story 0.19 R2` — historique de l'investigation
