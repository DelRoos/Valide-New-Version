---
story_id: 1bis.2bis
title: Refactor OnboardingShell — 1 Scaffold + AnimatedSwitcher slides + header/footer partagés + route unique
epic: 1bis
phase: P1bis — Refonte intégrale du flow pré-dashboard
status: review
created: 2026-06-11
baseline_commit: 59889df  # merge PR #104 chore/logger-colors-by-level (main aligné post-livraison E1bis-2 PR #103 + couleurs logger)
estimation: M (~1.5 jour)
sprint_change: PR #103 mergée mais structure incorrecte (3 Scaffold + 2 routes parallèles + 0 transition) — feedback porteur produit 2026-06-11 : "tu n'as pas utilisé les slides, ce sont des pages séparées, respecte exactement le parcours". Cette story corrige le gap vs `doc/templates/src/components/OnboardingFlow.tsx` (1 composant + 1 state `step` + `AnimatePresence` slide transitions).
dependencies:
  - E1bis-0 mergée (PR #101) — consomme `SelectionCard(variant: hero)`
  - E1bis-1 mergée (PR #102) — consomme `onboardingNotifierProvider`, `setSubSystem`, `loadFromPersistence`, `next()`, `back()`
  - E1bis-2 mergée (PR #103) — fichiers à refactorer : `OnboardingShell`, `SubSystemChoicePageV2`, `HeroIntroPage`, `OnboardingCtaFooter` ; routes parallèles à supprimer
  - Story 0.13 livrée — `AppButton.primary`
  - Story 0.16 livrée — i18n FR/EN
blocks:
  - E1bis-3 (pages 2+3+4) — étendra `OnboardingShell` avec cases `currentStep >= 2` dans l'`AnimatedSwitcher`
  - Toute story E1bis-* future (réutilise le shell)
sourceArtifacts:
  - doc/templates/src/components/OnboardingFlow.tsx l.690-762 (référence comportement : 1 Scaffold + AnimatePresence + footer partagé)
  - mobile_app/lib/features/onboarding/presentation/pages/onboarding_shell.dart (E1bis-2 — à refactorer)
  - mobile_app/lib/features/onboarding/presentation/pages/sub_system_choice_page_v2.dart (E1bis-2 — à transformer en step body)
  - mobile_app/lib/features/onboarding/presentation/pages/hero_intro_page.dart (E1bis-2 — à transformer en step body)
  - mobile_app/lib/core/widgets/onboarding/onboarding_cta_footer.dart (E1bis-2 — conservé, sera composé depuis le shell au lieu des pages)
  - mobile_app/lib/core/routing/app_router.dart (E1bis-2 — supprimer 2 routes parallèles, garder 1 route unique)
---

# Story 1bis.2bis — Refactor OnboardingShell en vrai shell partagé + slides

Status: **ready-for-dev**

## Objectif

Corriger la structure livrée par PR #103 pour qu'elle corresponde **strictement** au template `OnboardingFlow.tsx` : **UN seul** `Scaffold` racine partagé entre tous les steps, header (back + progress bar conditionnel) et footer (`OnboardingCtaFooter`) **partagés**, transition **slide** (`AnimatedSwitcher` avec `SlideTransition`) entre steps, et **UNE seule** route `/onboarding/v2` qui consomme le state interne `currentStep` du `OnboardingNotifier`.

**Pourquoi maintenant** : sans cette correction structurelle, chaque story E1bis-3+ dupliquerait le footer dans une nouvelle page Scaffold autonome (anti-pattern PR #103). Bloquer maintenant = corriger 2 pages ; bloquer dans 4 stories = corriger 8 pages.

**Pourquoi pas plus tard** : le pattern est foundational. Chaque PR qui ajoute un step référence ce shell. Toute autre story E1bis-* est bloquée tant que le shell n'est pas refactoré.

---

## User Story

**En tant qu'** élève camerounais qui navigue dans le flow onboarding,
**je veux** voir des transitions slides fluides entre les étapes avec un header de progression cohérent et un footer CTA toujours au même endroit,
**afin de** percevoir le flow comme un parcours guidé continu (et non comme une suite de pages qui se chargent indépendamment).

---

## Scope (décisions porteur produit 2026-06-11)

- ✅ **1 seul `Scaffold` racine** dans `OnboardingShell`. Tous les step bodies sont juste des widgets, plus de Scaffold dans chaque step.
- ✅ **`AnimatedSwitcher` + `SlideTransition`** (Offset(1, 0) → Offset.zero → Offset(-1, 0)) avec duration 300 ms easeOut, fidèle au template `motion.div` (initial x:20 / animate x:0 / exit x:-20).
- ✅ **Header partagé** dans le shell : `Row` (back button + progress bar + step counter). Visible uniquement pour `currentStep ≥ 2 && ≤ 4` ou `≥ 6 && ≤ 8` (cf. `configStepsActive` template). Step 0 + step 1 + step 5 + step 9 = pas de header progress.
- ✅ **Footer partagé** dans le shell : `OnboardingCtaFooter` placé en `bottomNavigationBar`. `label` et `onPressed` dispatchent sur `currentStep` via switch dans le shell. Visible partout sauf step 5 (auth choice — pattern template `showFooterCta = step !== 5`).
- ✅ **UNE seule route** : `/onboarding/v2` → `OnboardingShell`. Supprime `/onboarding/sub-system-v2` et `/onboarding/hero` (vestiges PR #103).
- ✅ **Renommer fichiers + classes** : `SubSystemChoicePageV2` → `SubSystemStepBody` (`sub_system_step_body.dart`), `HeroIntroPage` → `HeroIntroStepBody` (`hero_intro_step_body.dart`). Justification : ce sont des widgets bodies, pas des Pages. Le `V2` n'a plus de sens (l'ancien Epic 1 a `SubsystemChoicePage` legacy intact).
- ✅ **Conserver `OnboardingCtaFooter`** : composant catalogue inchangé, juste composé depuis le shell au lieu des pages individuelles. Entrée catalogue conservée.
- ✅ **Pattern prefetch documenté** : ajouter section « Pattern prefetch » dans la story et dans `STORY-TEMPLATES.md` pour application E1bis-3+ quand les data sources catalogue arriveront. Pas d'implémentation prefetch dans cette story (pas de catalogue data source côté E1bis encore).
- ❌ **PAS de modification du `OnboardingNotifier`** (E1bis-1) : le state machine reste tel quel.
- ❌ **PAS de modification du `OnboardingCtaFooter`** lui-même (composant catalogue stable).
- ❌ **PAS de changement du feature flag** `useNewOnboardingFlow` : reste OFF par défaut.

---

## Acceptance Criteria

- **AC1 — `OnboardingShell` est le vrai shell**. `mobile_app/lib/features/onboarding/presentation/pages/onboarding_shell.dart` doit :
  - Avoir **UN SEUL** `Scaffold` (vérifié par grep `Scaffold(` dans les step bodies = 0 hits).
  - `appBar` = `null` (le header progress est dans le body pour pouvoir être conditionnel par step).
  - `body` = `Column` avec 2 parties : (a) `_OnboardingHeader` widget partagé (visible si `configStepsActive`) + (b) `Expanded` + `AnimatedSwitcher(duration: Duration(milliseconds: 300), transitionBuilder: (child, anim) => SlideTransition + FadeTransition, child: _bodyForStep(state.currentStep) with ValueKey(state.currentStep))`.
  - `bottomNavigationBar` = `_OnboardingFooter` widget partagé qui compose `OnboardingCtaFooter` avec props dispatched par `currentStep` (visible sauf step 5).
  - `loadFromPersistence` reste en `initState` via `addPostFrameCallback` (logique E1bis-2 conservée).

- **AC2 — `SubSystemStepBody` est un widget body**. Renommer `sub_system_choice_page_v2.dart` → `sub_system_step_body.dart` et `SubSystemChoicePageV2` → `SubSystemStepBody`. Le widget retourne **directement** un `Column` ou `SafeArea` contenant le contenu visible (icône `LucideIcons.map`, titre, 2 `SelectionCard`), **sans Scaffold ni footer**. Le footer CTA est rendu par le shell.

- **AC3 — `HeroIntroStepBody` est un widget body**. Renommer `hero_intro_page.dart` → `hero_intro_step_body.dart` et `HeroIntroPage` → `HeroIntroStepBody`. Le widget retourne **directement** le `SingleChildScrollView` contenant `_HeroBanner` + titre + sous-titre + 3 `_FeatureCard`, **sans Scaffold ni footer**.

- **AC4 — Route unique `/onboarding/v2`**. Dans `mobile_app/lib/core/routing/app_router.dart` :
  - Supprimer les routes `/onboarding/sub-system-v2` et `/onboarding/hero`.
  - Ajouter UNE seule route `/onboarding/v2` → `OnboardingShell`.
  - `evaluateRedirect` : conserver les 2 checks E1bis (forward flag ON + anti-replay), mais cibler la nouvelle route `/onboarding/v2`.

- **AC5 — Tests redirect mis à jour**. Les 3 cas E1bis dans `app_router_redirect_test.dart` doivent cibler `/onboarding/v2` :
  - (a) flag ON + `/onboarding/subsystem` → `/onboarding/v2`
  - (b) flag ON + `hasSubSystem` + `/onboarding/v2` → `/`
  - (c) flag OFF + `/onboarding/subsystem` → null (préservation Epic 1)

- **AC6 — Tests widgets step bodies**. Refactorer les tests existants :
  - `sub_system_choice_page_v2_test.dart` → `sub_system_step_body_test.dart` : assert le widget en isolation sans Scaffold (utiliser `MaterialApp.home: Scaffold(body: SubSystemStepBody())` dans la pump si nécessaire pour le contexte Material).
  - `hero_intro_page_test.dart` → `hero_intro_step_body_test.dart` : idem.
  - `onboarding_shell_test.dart` : tests d'animation = vérifier que la transition step 0 → step 1 invoque bien `AnimatedSwitcher` (mock minimal : pump initial, change state, verify presence du nouveau body après duration).

- **AC7 — Goldens regen**. Les 4 goldens onboarding existants (phone + tablet x 2) doivent être regénérés pour refléter le rendu shell-wrappé (le footer apparait toujours au même endroit, pas dans chaque step). Goldens à mettre à jour :
  - `sub_system_choice_v2_phone_unselected.png` → `sub_system_step_body_phone_unselected.png`
  - `sub_system_choice_v2_tablet_unselected.png` → `sub_system_step_body_tablet_unselected.png`
  - `hero_intro_page_phone.png` → `hero_intro_step_body_phone.png`
  - `hero_intro_page_tablet.png` → `hero_intro_step_body_tablet.png`
  - Goldens `onboarding_cta_footer_*` inchangés (composant lui-même non modifié).

- **AC8 — Zero régression**. `flutter analyze` 0 issue + `flutter test` ≥ 391 verts (baseline E1bis-1) — on accepte que le compte total varie selon les tests refactorés mais aucune régression hors scope refactor.

- **AC9 — Story doc + sprint-status + COMPOSANTS-REUTILISABLES**. Mettre à jour : (a) cette story file status `review` avec Dev Agent Record en fin de PR, (b) `sprint-status.yaml` ajoute ligne `1bis-2bis` review, (c) `COMPOSANTS-REUTILISABLES.md` : ligne historique 2026-06-11 mentionnant le refactor pages → step bodies (le composant `OnboardingCtaFooter` reste mais sa composition migre vers le shell).

- **AC10 — Pattern prefetch documenté**. Ajouter dans `doc/tech/STORY-TEMPLATES.md` une section « Pattern prefetch données » (entrée dans la Dev Notes template) qui rappelle : lancer les `FutureProvider` data **dans le step N-1** via `addPostFrameCallback`, jamais en `initState` de la page consommatrice. Inclut snippet code Flutter Riverpod et lien vers feedback memory `feedback_prefetch_before_screen`.

---

## Stratégie responsive

- **Phone < 600 dp** : layout par défaut. AnimatedSwitcher prend toute la largeur, footer collé bas safe area.
- **Phone landscape 600-840 dp** : verrouillé portrait (cohérent CLAUDE.md règle 4 — V1 peut verrouiller portrait phone).
- **Tablet ≥ 840 dp** : le shell contraint `ConstrainedBox(maxWidth: 600.w)` centré horizontalement pour éviter que le hero gradient s'étire sur toute la largeur (mauvaise lecture). Header + footer suivent la même contrainte.

Goldens obligatoires (règle 5) : phone 360×740 + tablet 800×1280 minimum. Phone landscape optionnel (verrouillage).

---

## Composants réutilisés (CLAUDE.md règle 11)

| Composant | Path | Source | Usage |
|---|---|---|---|
| `OnboardingCtaFooter` | `lib/core/widgets/onboarding/onboarding_cta_footer.dart` | E1bis-2 | Composé depuis le shell (`bottomNavigationBar`), label/onPressed dispatch par currentStep |
| `SelectionCard(variant: hero)` | `lib/core/widgets/cards/selection_card.dart` | E1bis-0 | Step 0 — 2 cards FR/EN |
| `AppButton.primary` | `lib/core/widgets/app_button.dart` | Story 0.13 | Indirectement via `OnboardingCtaFooter` |
| `LucideIconsFlutter` | package | — | `LucideIcons.map` (step 0 header), `LucideIcons.bookOpen` (step 1 hero), `LucideIcons.arrowLeft` (header back), icônes feature cards |

Nouveaux widgets (privés au shell, pas de catalogue) :
- `_OnboardingHeader` (dans `onboarding_shell.dart`) : back button + progress bar + step counter. ≤ 50 lignes.
- `_OnboardingFooter` (dans `onboarding_shell.dart`) : `Visibility(visible: step != 5, child: OnboardingCtaFooter(...))`. ≤ 30 lignes.

---

## Cost-benefit Firestore (CLAUDE.md règle 10m)

**N/A** — Cette story est un refactor structurel pur, **pas** d'accès Firestore introduit. Le `loadFromPersistence` consomme SharedPreferences (E1bis-1). Pas de nouveau snapshot listener, pas de nouvel index, pas de dénormalisation.

---

## Test plan

Tests à livrer dans cette PR :

| Catégorie | Détail | Cible |
|---|---|---:|
| `evaluateRedirect` E1bis-2bis | Réécriture des 3 cas E1bis pour cibler `/onboarding/v2` | 3 |
| `OnboardingShell` shell behavior | (a) initState appelle loadFromPersistence ; (b) build affiche header conditionnel ; (c) build affiche footer conditionnel ; (d) AnimatedSwitcher change body sur currentStep change | 4 |
| `SubSystemStepBody` widget | (a) tap card francophone → setSubSystem ; (b) tap card anglophone → setSubSystem ; (c) golden phone unselected ; (d) golden tablet unselected | 4 |
| `HeroIntroStepBody` widget | (a) tap CTA → next() (testé via shell) ; (b) golden phone ; (c) golden tablet | 3 |
| **Total** | | **14** |

Le nombre est inférieur à PR #103 (22 tests) car certains tests pages → step bodies se simplifient (plus de header/footer à tester par step body, ils sont dans le shell).

---

## Risques & suivi

- ⚠️ **Tests d'animation flaky** : `AnimatedSwitcher` peut nécessiter `tester.pumpAndSettle()` au lieu de `pump()` simple. À vérifier en cours d'implémentation.
- ⚠️ **Goldens platform-dependent** : déjà connu PR #103, persisterait. Générer sur Windows, CI Linux première run peut mismatch.
- ⚠️ **`Visibility(maintainState: true)` vs `if (step != 5)`** : préférer `Visibility(visible: ..., maintainSize: false)` pour ne pas garder le footer monté quand caché — sinon AppButton garde focus FocusNode.
- ℹ️ **Prefetch pas implémenté dans cette story** : pattern documenté seulement. Première application réelle = E1bis-3 (prefetch catalogue streams + subjects au passage hero → track choice).

---

## Directive backend Firestore (à valider équipe backend)

**Feedback porteur produit 2026-06-11** : « les interfaces doivent être la même chose que sur le template, fais en sorte que le backend puisse fournir ça ».

**Implication pour E1bis-3+** : toute `SelectionCard` du flow onboarding (track / level / stream / subjects) doit afficher **descriptions + abréviations** comme dans le template `OnboardingFlow.tsx`. Ces données **ne doivent PAS être hard-codées** en ARB ni en Dart — elles viennent de **Firestore**.

**Schéma proposé à valider avec backend** :

- Collection `streams/{streamId}` (séries scolaires) — ajouter champs :
  - `descriptionFr: string` — ex. "Mathématiques + Physique-Chimie + SVT"
  - `descriptionEn: string` — ex. "Mathematics + Physics-Chemistry + Biology"
  - `abbreviation: string` — ex. "D", "C", "A1", "TI"
- Collection `subjects/{subjectId}` (matières) — ajouter champs :
  - `descriptionFr: string` — ex. "Mathématiques générales"
  - `descriptionEn: string`
  - `abbreviation: string` — ex. "M", "PC", "SVT", "PH"
- Collection `levels/{levelId}` (niveaux) — ajouter si pertinent :
  - `descriptionFr: string` — ex. "Classe d'examen BAC général"
  - `descriptionEn: string`
- Collection `tracks/{trackId}` (filières Général/Technique) :
  - `descriptionFr: string` — ex. "Programme académique général (Lettres, Sciences)"
  - `descriptionEn: string`

**Sub-system (Francophone / Anglophone)** : reste hard-codé ARB (2 options binaires fixes, pas besoin de Firestore). Description ajoutée dans `app_fr.arb` / `app_en.arb` (clés `onboardingSubSystem*Desc`).

**Workflow à valider avant E1bis-3** :

1. PR séparée `chore(partage): proposer schema enrichi descriptions+abreviations streams/subjects/levels/tracks` qui modifie `doc/partage/BASE-DE-DONNEES.md` avec ces nouveaux champs + accord backend (commentaire mainteneur).
2. Script seed Python (`scripts/firebase_seed/seed_streams.py`, etc.) mis à jour pour populer les nouveaux champs FR/EN/abbreviation à partir des sources MINESEC/GCE.
3. Migration des données existantes (script one-shot admin).
4. Models domain Dart adaptés (`Stream`, `Subject`) avec champs `description` + `abbreviation` localisés via `subSystem` ou langue active.
5. E1bis-3 consomme ces nouveaux champs dans les `SelectionCard` step 2/3/4.

⚠️ **CLAUDE.md règle** : toute modification de contrat backend doit avoir l'accord écrit de l'équipe backend. Cette section est une **proposition** à valider, pas un fait acquis.

Lié à feedback memory `feedback_card_descriptions_from_firestore`.

---

## Séquence E1bis post-merge

1. ✅ E1bis-0 PR #101 mergée
2. ✅ E1bis-1 PR #102 mergée
3. ⚠️ E1bis-2 PR #103 mergée mais structure incorrecte
4. **🔄 E1bis-2bis (cette story) — corrige la structure** ← en cours
5. ⏭️ E1bis-3 (pages 2+3+4 picker 5 modes) — étend le shell refactoré
6. E1bis-4 → E1bis-9 — toutes consomment le shell

---

## Dev Agent Record

**Date** : 2026-06-11. **Branche** : `feat/1bis-2bis-refactor-shell-slides`. **Baseline** : `59889df` (post-merge PR #104).

### Fichiers livrés

**Modifiés (3)** :

- `mobile_app/lib/features/onboarding/presentation/pages/onboarding_shell.dart` (80 → 197 l) — Refactor en vrai shell : `Scaffold` unique + `_OnboardingHeader` partagé + `AnimatedSwitcher` slide+fade 300 ms + `_footerForStep()` dispatch + `_StepPlaceholder` interne.
- `mobile_app/lib/core/routing/app_router.dart` — Supprime 2 routes parallèles `/onboarding/sub-system-v2` + `/onboarding/hero`, ajoute 1 route unique `/onboarding/v2`. Update 2 checks `evaluateRedirect` (forward + anti-replay) pour cibler `/onboarding/v2`.
- `mobile_app/test/core/routing/app_router_redirect_test.dart` — 3 cas E1bis-2bis ciblent `/onboarding/v2`.

**Créés (5)** :

- `mobile_app/lib/features/onboarding/presentation/pages/sub_system_step_body.dart` (84 l) — body pur sans Scaffold.
- `mobile_app/lib/features/onboarding/presentation/pages/hero_intro_step_body.dart` (162 l) — body pur sans Scaffold, conserve `_HeroBanner` + `_FeatureCard` privés.
- `mobile_app/test/features/onboarding/presentation/pages/sub_system_step_body_test.dart` (135 l) — 2 interactions + 2 goldens.
- `mobile_app/test/features/onboarding/presentation/pages/hero_intro_step_body_test.dart` (105 l) — 1 render + 2 goldens.
- `mobile_app/test/features/onboarding/presentation/pages/onboarding_shell_test.dart` (192 l) — 7 tests shell (mount vide / mount persiste / step 0 footer disabled / tap card / step 1 tap CTA / step 2 placeholder / step 9 placeholder).

**Supprimés (8)** :

- `mobile_app/lib/features/onboarding/presentation/pages/sub_system_choice_page_v2.dart` (obsolète, refactor → `sub_system_step_body.dart`).
- `mobile_app/lib/features/onboarding/presentation/pages/hero_intro_page.dart` (obsolète, refactor → `hero_intro_step_body.dart`).
- `mobile_app/test/features/onboarding/presentation/pages/sub_system_choice_page_v2_test.dart` (remplacé).
- `mobile_app/test/features/onboarding/presentation/pages/hero_intro_page_test.dart` (remplacé).
- `mobile_app/test/features/onboarding/presentation/pages/onboarding_shell_test.dart` (remplacé).
- 4 PNG goldens obsolètes : `sub_system_choice_v2_phone_unselected.png`, `sub_system_choice_v2_tablet_unselected.png`, `hero_intro_page_phone.png`, `hero_intro_page_tablet.png`.

**Regénérés (4)** : `sub_system_step_body_phone.png`, `sub_system_step_body_tablet.png`, `hero_intro_step_body_phone.png`, `hero_intro_step_body_tablet.png`.

### Documents mis à jour

- `project_manage/implementation-artifacts/sprint-status.yaml` — `1bis-2-pages-sub-system-hero` review → done (avec note structure incorrecte corrigée par 1bis-2bis) + nouvelle ligne `1bis-2bis-refactor-shell-slides: review`.
- `doc/tech/COMPOSANTS-REUTILISABLES.md` — ligne Historique 2026-06-11 documentant le refactor pages → step bodies. `OnboardingCtaFooter` lui-même reste au catalogue inchangé (sa composition migre des pages vers le shell).

### Résultats validation

- `flutter analyze` : **0 issue** (ran in 171.8 s).
- `flutter test` sur `onboarding/presentation/pages/` + `core/routing/` : **35 tests passés** (16 redirect + 7 shell + 2 SubSystemStepBody interactions + 2 SubSystemStepBody goldens + 1 HeroIntroStepBody render + 2 HeroIntroStepBody goldens + 5 tests préexistants restants).
- `flutter test` full suite : voir résumé final PR (target ≥ 391 verts baseline, en cours).

### Décisions techniques

- **`AnimatedSwitcher` + `SlideTransition(Offset(0.08, 0) → zero)` + `FadeTransition`** : mimique du template `motion.div` (initial x:20 → animate x:0). Offset 0.08 préféré à 1.0 pour transition plus subtile (le template utilise 20 px sur viewport ~400 px = ~5 %).
- **`KeyedSubtree(key: ValueKey<int>(step))`** : indispensable à `AnimatedSwitcher` pour détecter le changement de child et déclencher la transition.
- **`_footerForStep()` retourne `Widget?`** : `null` quand pas de footer (step 5 auth ou steps placeholder), `Scaffold.bottomNavigationBar` masqué automatiquement. Plus simple que `Visibility(visible: ...)`.
- **`_OnboardingHeader.configStepsActive` computé inline** : `(step >= 2 && step <= 4) || (step >= 6 && step <= 8)`. Reproduit verbatim la logique template ligne 206. Étape 0, 1, 5, 9 = pas de header.
- **`SafeArea(bottom: false)` dans le shell** : couvre le notch top. Le footer gère son propre safe area bottom via `OnboardingCtaFooter` (composant catalogue inchangé).
- **Coexistence step 0/1 sans header** : pour cette story, le `_OnboardingHeader` retourne `SizedBox.shrink()` (pas affiché). Pattern prêt pour E1bis-3 qui activera le header sur steps 2-4.

### Hors-scope respecté

- ❌ Pas de touche à `OnboardingNotifier` (state machine E1bis-1).
- ❌ Pas de touche à `OnboardingCtaFooter` (composant catalogue stable).
- ❌ Pas d'implémentation prefetch (documenté pour application E1bis-3+ quand les data sources catalogue arriveront).
- ❌ Pas de changement du feature flag (`useNewOnboardingFlow = false`).
- ❌ Pas de touche au code Epic 1 (`subsystem_choice_page.dart`, `LocaleNotifier`, `OnboardingFlowNotifier` legacy intacts).

### Commits livrés

À compléter après push (6 commits prévus : refactor shell + step bodies / suppression anciens fichiers / route unique + redirect / tests refactor / goldens regen / docs cloture).
