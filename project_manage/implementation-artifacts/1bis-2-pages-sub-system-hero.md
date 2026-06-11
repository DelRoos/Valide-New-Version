---
story_id: 1bis.2
title: Pages 0+1 (sub-system choice + hero intro) + branchement router feature flag
epic: 1bis
phase: P1bis — Refonte intégrale du flow pré-dashboard
status: review
created: 2026-06-11
baseline_commit: 8439235  # merge PR #102 (feat/1bis-1-state-machine-onboarding) - main aligné post-livraison OnboardingNotifier + OnboardingState
estimation: M (~2 jours)
sprint_change: project_manage/planning-artifacts/epics/epic-1bis-refonte-onboarding.md (Story E1bis-2)
dependencies:
  - E1bis-0 mergée (PR #101) — consomme `SelectionCard(variant: hero)` (`lib/core/widgets/cards/selection_card.dart`)
  - E1bis-1 mergée (PR #102) — consomme `onboardingNotifierProvider`, `setSubSystem`, `loadFromPersistence`
  - Story 0.13 livrée — `AppButton.primary` à composer dans `OnboardingCtaFooter`
  - Story 0.16 livrée — i18n FR/EN via `flutter_localizations` + gen-l10n + clés ARB
  - Story 1.2 livrée — `subSystemNotifierProvider` legacy (à NE PAS toucher, coexistence via flag)
  - `doc/tech/STORY-TEMPLATES.md` (templates 3 Stratégie responsive + 4 Composants réutilisables)
blocks:
  - E1bis-3 (pages 2+3+4 track + level + stream/subjects — étend `OnboardingShell` pour router currentStep ≥ 2)
  - E1bis-4 (page 5 auth)
  - E1bis-5, E1bis-6, E1bis-7, E1bis-8 (toutes les pages onboarding suivantes)
sourceArtifacts:
  - project_manage/planning-artifacts/epics/epic-1bis-refonte-onboarding.md § « Story E1bis-2 » (AC1-AC10 source)
  - project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/DESIGN.md § « Step 0 — Sub-system choice » + § « Step 1 — Hero intro » + § « Tokens »
  - project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/EXPERIENCE.md § « Microcopie onboarding » (steps 0 + 1 FR/EN canoniques)
  - project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/.decision-log.md § Update 3 (D-UX-Update-12 inversion auth, D-UX-Update-13 hero card, D-UX-Update-20 catalogue OnboardingCtaFooter)
  - doc/templates/src/components/OnboardingFlow.tsx (référence comportement React steps 0 + 1)
  - mobile_app/lib/core/widgets/cards/selection_card.dart (E1bis-0 — `SelectionCard(variant: hero)` consommé)
  - mobile_app/lib/core/widgets/app_button.dart (Story 0.13 — `AppButton.primary` composé)
  - mobile_app/lib/core/routing/app_router.dart (UPDATE — ajout 2 routes + check redirect feature flag minimal)
  - mobile_app/lib/features/onboarding/presentation/state/onboarding_providers.dart (E1bis-1 — `onboardingNotifierProvider`)
  - mobile_app/lib/features/onboarding/providers.dart (Story 1.2 — `subSystemNotifierProvider` legacy à NE PAS toucher)
  - mobile_app/lib/features/onboarding/presentation/subsystem_choice_page.dart (référence visuelle Epic 1 — légèrement différente, ne PAS modifier)
---

# Story 1bis.2 — Pages 0+1 (sub-system choice + hero intro) + branchement router feature flag

Status: **ready-for-dev**

## Objectif

Livrer les **deux premières pages UI du nouveau flow onboarding E1bis** : `SubSystemChoicePageV2` (step 0 — choix FR/EN avec `SelectionCard(variant: hero)`) et `HeroIntroPage` (step 1 — illustration placeholder gradient + 3 feature cards). Livrer le **wrapper `OnboardingShell`** qui orchestre la restauration via `loadFromPersistence()` + route interne par `currentStep`. Livrer le **composant catalogue `OnboardingCtaFooter`** réutilisé par toutes les pages E1bis-2 à E1bis-7. Brancher le router avec un **feature flag `useNewOnboardingFlow` OFF par défaut** qui permet de tester runtime sans casser le flow Epic 1 live.

**Pourquoi maintenant** : E1bis-0 (foundation widgets) et E1bis-1 (state machine) sont mergées. C'est la première story qui valide visuellement le flow refondu et qui débloque les 5 pages restantes (E1bis-3 à E1bis-7) qui réutiliseront `OnboardingShell` + `OnboardingCtaFooter`.

**Pourquoi pas plus tard** : sans cette story, le flow refondu reste théorique. La validation porteur produit (microcopie FR/EN + look-and-feel hero) doit se faire au plus tôt — risque de devoir reprendre 5 pages si la direction visuelle ne convient pas.

---

## User Story

**En tant qu'** élève camerounais qui ouvre l'app pour la première fois,
**je veux** choisir mon sous-système (Francophone ou Anglophone) en un tap, puis voir une page hero qui me montre ce que l'app va m'apporter (Cours / Exercices / Chat IA),
**afin de** comprendre la valeur de l'app en moins de 30 s avant d'investir 8 écrans de profil supplémentaires.

---

## Scope (décisions porteur produit 2026-06-11)

- ✅ **2 nouvelles pages UI** : `SubSystemChoicePageV2` + `HeroIntroPage`. Identifiants en anglais (suffixe `V2` pour éviter collision avec la `SubsystemChoicePage` Epic 1 legacy ; `HeroIntroPage` n'a pas d'équivalent legacy, pas de suffixe).
- ✅ **Wrapper `OnboardingShell`** : Riverpod stateful qui appelle `loadFromPersistence()` au `initState` puis route interne par `currentStep`.
- ✅ **Composant catalogue `OnboardingCtaFooter`** : extrait dans `lib/core/widgets/onboarding/` + documenté `COMPOSANTS-REUTILISABLES.md` dans cette PR (CLAUDE.md règle 11).
- ✅ **Feature flag `useNewOnboardingFlow` (constante hard-codée OFF)** dans `lib/core/config/feature_flags.dart`. Permet le toggle au build. Migration runtime (SharedPreferences) reportée à story dette future si besoin.
- ✅ **Redirect router minimal** : 1 ligne ajoutée à `evaluateRedirect` qui, si flag ON et location `/onboarding/subsystem` (legacy), redirect vers `/onboarding/sub-system-v2`. + symétrique anti-replay si `hasSubSystem` et location `/onboarding/sub-system-v2` → `/`.
- ✅ **Placeholder hero** : illustration step 1 = gradient `AppColors.primary → AppColors.sky` + `LucideIcons.bookOpen` centré 96 sp. Pas d'asset image livré dans cette PR (OQ-E1bis-1 décidée). Asset final = story illustration séparée hors E1bis.
- ❌ **PAS de modification des pages legacy Epic 1** : `subsystem_choice_page.dart` + `filiere_choice_page.dart` + `niveau_choice_page.dart` etc. restent intactes. Coexistence via flag.
- ❌ **PAS de Firebase / Firestore** dans cette story (la persistance `subSystem` SharedPreferences est déjà gérée par `OnboardingNotifier.setSubSystem` E1bis-1).
- ❌ **PAS de mise à jour du splash routing** : le splash continue de pointer vers `/hello` ou `/onboarding/subsystem` legacy. Le test du nouveau flow se fait via deep link `/onboarding/sub-system-v2` (ou via toggle build du flag).

---

## Acceptance Criteria

- **AC1 — `OnboardingShell` wrapper**. Créer `mobile_app/lib/features/onboarding/presentation/pages/onboarding_shell.dart`. `ConsumerStatefulWidget`. Au `initState`, appel `await ref.read(onboardingNotifierProvider.notifier).loadFromPersistence()` (récupère `subSystem` SharedPreferences si présent → `currentStep = 1`). Build : `switch (state.currentStep)` retournant la page appropriée. Pour cette story, seuls les cases 0 (→ `SubSystemChoicePageV2`) et 1 (→ `HeroIntroPage`) sont implémentés. Cases 2-9 → placeholder `Scaffold` avec texte « Étape X — à venir (E1bis-3+) » (debug helper, pas livré en prod final). Le shell est la **racine du flow E1bis** — toutes les pages internes consomment `OnboardingNotifier` via `ref.watch` mais ne gèrent pas leur propre navigation step.

- **AC2 — `SubSystemChoicePageV2` (step 0)**. Créer `mobile_app/lib/features/onboarding/presentation/pages/sub_system_choice_page_v2.dart`. Composition : `SafeArea` + scroll vertical + en-tête (`Icon(LucideIcons.map, 48 sp, color: AppColors.primary)` + titre H1 18 sp + sous-titre body 14 sp `AppColors.inkSoft`) + spacing `AppSpacing.s5` + 2 `SelectionCard(variant: hero, icon: null, description: null)` côte à côte verticalement (Francophone / Anglophone) + spacing `AppSpacing.s4` + `OnboardingCtaFooter(label: l10n.onboardingContinue, onPressed: subSystem != null ? _onContinue : null)`. Tap card → `await notifier.setSubSystem(SubSystem.francophone | anglophone)` (qui persiste + currentStep 0→1 implicite). Tap CTA `Continuer` → no-op si subSystem null, sinon `notifier.next()` (mais `setSubSystem` a déjà avancé à step 1, donc CTA = bypass cosmétique uniquement pour confirmer le choix). Stratégie alternative : le tap card peut auto-avancer (transition 200 ms) sans CTA — laisser le dev choisir l'UX la plus fluide après vérification DESIGN.md § Step 0. Bascule i18n : au `setSubSystem`, le `subSystemNotifierProvider` legacy n'est PAS mis à jour (coexistence flag). Pour cette story, la bascule i18n du flow refondu sera prise en charge par l'extension de `LocaleNotifier` E1bis-9 — ici on accepte que la langue reste la langue système / précédente. Documenter ce trade-off dans Dev Notes.

- **AC3 — `HeroIntroPage` (step 1)**. Créer `mobile_app/lib/features/onboarding/presentation/pages/hero_intro_page.dart`. Composition : `SafeArea` + scroll vertical + zone hero (ratio 4/3, `Container` avec `LinearGradient(AppColors.primary → AppColors.sky, begin: topCenter, end: bottomCenter)` + `Icon(LucideIcons.bookOpen, 96 sp, color: Colors.white)` centré) + spacing `AppSpacing.s6` + titre display H1 24 sp (`l10n.heroIntroTitle`) + sous-titre body 14 sp `AppColors.inkSoft` (`l10n.heroIntroSubtitle`) + spacing `AppSpacing.s5` + 3 `HeroIntroFeatureCard` (Cours / Exercices / Chat IA) en colonne + spacing `AppSpacing.s5` + `OnboardingCtaFooter(label: l10n.heroIntroCta, onPressed: _onContinue)`. Tap CTA → `notifier.next()` (transition step 1 → 2). Si flag E1bis-3 pas encore mergée, le shell rendra le placeholder « Étape 2 — à venir » — c'est attendu.

- **AC4 — `HeroIntroFeatureCard` widget**. Créer `mobile_app/lib/features/onboarding/presentation/widgets/hero_intro_feature_card.dart`. Composition : `Container` avec bg semi-transparent `AppColors.card` + border `AppColors.border` + `BorderRadius.circular(AppRadius.lg)` + padding `AppSpacing.s4`. Contenu : `Row` (icône Lucide à gauche 32 sp dans cercle `AppColors.primarySoft` + spacing `AppSpacing.s3` + `Column` titre + description). Props : `icon: IconData`, `title: String`, `description: String`. Pas d'`onTap` (cards décoratives, pas interactives). **Décision dev** : si la card simple suffit sans extraction (≤ 30 lignes inline), reste en widget privé `_FeatureCard` dans `hero_intro_page.dart`. Si dépassement → extraction publique + entrée catalogue. Cf. CLAUDE.md règle 11.

- **AC5 — `OnboardingCtaFooter` composant catalogue**. Créer `mobile_app/lib/core/widgets/onboarding/onboarding_cta_footer.dart`. Props : `label: String`, `onPressed: VoidCallback?` (null = disabled), `secondaryAction: Widget?` (optionnel, lien tertiaire — affiché au-dessus du CTA, ex. « Passer pour l'instant » pour steps 7/8). Composition : `Container` bg `AppColors.bg` + `BoxShadow` doux haut (`AppElevation.soft` inversé) + `SafeArea(top: false)` + padding `AppSpacing.s4` + `Column(mainAxisSize: min, children: [secondaryAction if not null, spacing, AppButton.primary(label: label, onPressed: onPressed, fullWidth: true)])`. **Sticky bas** : posé en `bottomNavigationBar` du `Scaffold` parent, pas dans le scroll. Pas d'i18n interne (le caller passe le label déjà localisé). Pas de dépendance Riverpod (composant pur, props in).

- **AC6 — Feature flag `useNewOnboardingFlow`**. Créer `mobile_app/lib/core/config/feature_flags.dart`. Contenu : classe `FeatureFlags` avec **constante hard-codée** `static const bool useNewOnboardingFlow = false`. Commentaire en tête : « Toggle au build pour QA. Migration runtime SharedPreferences si besoin → story dette future. Défaut OFF pour ne pas casser le flow Epic 1 en prod. ». Pas de provider Riverpod (constante = compile-time, accessible partout sans injection).

- **AC7 — Routes parallèles dans `app_router.dart`**. **UPDATE** `mobile_app/lib/core/routing/app_router.dart`. Ajouter 2 routes :
  - `GoRoute(path: '/onboarding/sub-system-v2', builder: (_, _) => const OnboardingShell())`
  - `GoRoute(path: '/onboarding/hero', builder: (_, _) => const OnboardingShell())`
  
  **Note importante** : ces deux routes pointent toutes vers `OnboardingShell` qui route internement selon `currentStep`. La distinction d'URL est cosmétique (debug, deep link). En pratique, tap CTA navigue via `notifier.next()` qui met à jour `currentStep` — le shell re-render la bonne page sans changer d'URL. C'est volontaire (un seul wrapper pour tout le flow E1bis). Le testeur peut deep-linker `/onboarding/sub-system-v2` OU `/onboarding/hero` indifféremment — le shell affichera la page correspondant au `currentStep` courant.

- **AC8 — Redirect router minimal**. **UPDATE** `evaluateRedirect` dans `app_router.dart`. Ajouter 2 checks juste après le bypass system (Story 1.2) :
  1. Si `FeatureFlags.useNewOnboardingFlow && location == '/onboarding/subsystem'` → return `/onboarding/sub-system-v2` (force le nouveau flow si flag ON).
  2. Si `hasSubSystem && location == '/onboarding/sub-system-v2'` → return `/` (anti-replay symétrique à la règle Story 1.2 existante).
  
  Pas d'autre modification du redirect. La garde Story 1.5 (profil-incomplet) continue de pointer vers les routes legacy `/onboarding/profile/*` — c'est attendu tant que les autres pages E1bis-3+ ne sont pas livrées.

- **AC9 — Microcopie ARB FR + EN**. Ajouter clés ARB dans `lib/l10n/app_fr.arb` + `app_en.arb` :
  - `onboardingSubSystemTitle` : « Bienvenue ! » / « Welcome! »
  - `onboardingSubSystemSubtitle` : « Choisis ton système scolaire pour démarrer. » / « Choose your school system to get started. »
  - `onboardingSubSystemFrancophone` : « Francophone » / « Francophone »
  - `onboardingSubSystemAnglophone` : « Anglophone » / « Anglophone »
  - `onboardingContinue` : « Continuer » / « Continue »
  - `heroIntroTitle` : « Apprends à ton rythme, à ton niveau. » / « Learn at your pace, your level. »
  - `heroIntroSubtitle` : « Cours, exercices, et un assistant IA toujours disponible. » / « Courses, exercises, and an AI assistant always available. »
  - `heroIntroFeatureCoursesTitle` : « Cours » / « Courses »
  - `heroIntroFeatureCoursesDesc` : « Tout le programme, expliqué simplement. » / « All curricula, explained simply. »
  - `heroIntroFeatureExercisesTitle` : « Exercices » / « Exercises »
  - `heroIntroFeatureExercisesDesc` : « Entraîne-toi avec correction immédiate. » / « Practice with instant feedback. »
  - `heroIntroFeatureChatTitle` : « Chat IA » / « AI Chat »
  - `heroIntroFeatureChatDesc` : « Pose toutes tes questions, à toute heure. » / « Ask any question, anytime. »
  - `heroIntroCta` : « C'est parti » / « Let's go »

  Microcopie ton bienveillant, niveau lecture lycée camerounais 12-19 ans. Adapter en cas de remontée porteur produit.

- **AC10 — Stratégie responsive 4 form factors**. **OBLIGATOIRE** (CLAUDE.md règle 3 + 5). Section « Stratégie responsive » dans Dev Notes (cf. template 3).
  - Phone portrait < 600 dp : colonne unique scrollable, footer CTA sticky bottom avec safe area.
  - Phone landscape 600-840 dp : OPTIONNEL — verrouillage portrait acceptable V1 (cf. Stories Epic 1 antérieures). Documenter dans Dev Notes le verrouillage si retenu.
  - Tablet portrait ≥ 840 dp : `ConstrainedBox(maxWidth: 600.w)` centré horizontalement + marges latérales `AppSpacing.s8`. Footer CTA reste sticky bottom plein largeur.
  - Tablet paysage ≥ 840 dp : idem tablet portrait (pas de split-view ni side panel — flow linéaire court).
  - Détection : `LayoutBuilder` à la racine du `Scaffold` de chaque page (pas dans `OnboardingShell` car le contenu varie par page).

- **AC11 — Golden tests obligatoires**. **OBLIGATOIRE** breakpoint tablet ≥ 840 dp (règle 5 enforced). Minimum :
  - `SubSystemChoicePageV2` : phone 360×780 + tablet 800×1280 = 2 goldens. Plus 1 golden phone state « subSystem sélectionné » (CTA enabled) = 3 total.
  - `HeroIntroPage` : phone 360×780 + tablet 800×1280 = 2 goldens.
  - `OnboardingCtaFooter` : phone 360×80 (composant seul) état enabled + disabled + avec secondaryAction = 3 goldens.
  - `HeroIntroFeatureCard` (si extrait) : phone 360×120 = 1 golden.
  - **Total cible** : 9-10 goldens minimum. Acceptable de descendre à 6-8 si plafond PR diff serré.
  - Tablet paysage 1280×800 + phone landscape 700×400 : optionnel — à ajouter si dev pense que le rendu mérite vérification.

- **AC12 — Widget tests interactions**. Cibles :
  - `OnboardingShell` : (a) mount → `loadFromPersistence` appelé (vérifier via SharedPreferences mock + state hydraté) ; (b) state `currentStep == 0` → `SubSystemChoicePageV2` rendue ; (c) state `currentStep == 1` → `HeroIntroPage` rendue ; (d) state `currentStep == 2` → placeholder « à venir ».
  - `SubSystemChoicePageV2` : (a) initial CTA disabled ; (b) tap Francophone → state `subSystem == francophone` + `currentStep == 1` (via `setSubSystem` qui auto-avance) ; (c) tap Anglophone → idem en anglais.
  - `HeroIntroPage` : (a) rendu hero + 3 feature cards + CTA ; (b) tap CTA → `notifier.next()` appelé (state `currentStep == 2`).
  - `OnboardingCtaFooter` : (a) `onPressed: null` → button disabled (Material visual disabled) ; (b) `onPressed: callback` → tap appelle callback ; (c) `secondaryAction: Text('Skip')` → rendu au-dessus du CTA.
  - **`evaluateRedirect`** : ajouter cas tests dans `test/core/routing/app_router_redirect_test.dart` (fichier existant) :
    - flag ON + location `/onboarding/subsystem` → return `/onboarding/sub-system-v2`.
    - flag ON + location `/onboarding/sub-system-v2` + hasSubSystem == true → return `/`.
    - flag OFF + location `/onboarding/subsystem` → return null (comportement Epic 1 préservé).

- **AC13 — Identifiers anglais 100% (CLAUDE.md règle 5)**. Noms de fichiers, classes, props, routes : 100% anglais. `SubSystemChoicePageV2`, `HeroIntroPage`, `OnboardingShell`, `OnboardingCtaFooter`, `HeroIntroFeatureCard`, `FeatureFlags.useNewOnboardingFlow`, `/onboarding/sub-system-v2`, `/onboarding/hero`. Pas de `filiere`, `niveau`, `serie`, `matiere`.

- **AC14 — Taille fichiers ≤ 300 lignes cible / 500 plafond (CLAUDE.md règle 12)**. Cibles :
  - `onboarding_shell.dart` : ~80 lignes
  - `sub_system_choice_page_v2.dart` : ~150 lignes
  - `hero_intro_page.dart` : ~200 lignes (incl. `_FeatureCard` privé si pas extrait, sinon ~140)
  - `hero_intro_feature_card.dart` (si extrait) : ~80 lignes
  - `onboarding_cta_footer.dart` : ~80 lignes
  - `feature_flags.dart` : ~30 lignes
  
  Aucun fichier ne doit dépasser 300 cible / 500 plafond.

- **AC15 — Catalogue mis à jour dans la MÊME PR (CLAUDE.md règle 11)**. Dans `doc/tech/COMPOSANTS-REUTILISABLES.md` :
  - Ajouter entrée § « Catalogue actuel » pour `OnboardingCtaFooter` avec : path, props (`label` / `onPressed` / `secondaryAction`), comportement responsive (`phone + tablet` — sticky bottom partout), exemple Dart minimal, lien vers les goldens, story d'origine.
  - Ajouter entrée pour `HeroIntroFeatureCard` SI le dev décide de l'extraire (sinon mention « décision dev : reste widget privé dans hero_intro_page.dart, pas catalogué »).
  - Ajouter entrée historique datée 2026-06-XX avec le numéro de PR.

---

## Tasks / Subtasks

> Ordre recommandé (dépendances internes).

- [x] **T1 — `FeatureFlags` constante** (AC6)
  - Fichier `lib/core/config/feature_flags.dart`.
  - Classe `FeatureFlags` avec `static const bool useNewOnboardingFlow = false`.
  - Commentaire toggle build + future migration runtime documentée.

- [x] **T2 — `OnboardingCtaFooter` composant catalogue** (AC5, AC11, AC15)
  - Fichier `lib/core/widgets/onboarding/onboarding_cta_footer.dart`.
  - Props `label` / `onPressed` / `secondaryAction?`.
  - Compose `AppButton.primary(fullWidth: true)`.
  - 3 goldens phone (enabled / disabled / avec secondaryAction).
  - Tests interactions : tap appelle callback, null = disabled, secondaryAction rendu.

- [x] **T3 — `HeroIntroFeatureCard` widget** (AC4)
  - Fichier `lib/features/onboarding/presentation/widgets/hero_intro_feature_card.dart` SI extraction (décision dev).
  - Props `icon` / `title` / `description`.
  - Rendu `Container` avec bg `AppColors.card` + border + radius + icône cerclée + texte.
  - 1 golden phone (si extrait).

- [x] **T4 — `SubSystemChoicePageV2` page step 0** (AC2, AC9 partiel, AC10, AC11)
  - Fichier `lib/features/onboarding/presentation/pages/sub_system_choice_page_v2.dart`.
  - Consomme `onboardingNotifierProvider` via `ref.watch` (subSystem) + `ref.read.notifier` (setSubSystem).
  - 2 `SelectionCard(variant: hero)` Francophone + Anglophone.
  - Footer via `OnboardingCtaFooter`.
  - Layout responsive 4 form factors via `LayoutBuilder` + `ConstrainedBox(maxWidth: 600.w)` ≥ 840 dp.
  - Clés ARB onboardingSubSystem*.
  - 2-3 goldens (phone unselected + phone selected + tablet).
  - Widget tests : tap cards → state mis à jour.

- [x] **T5 — `HeroIntroPage` page step 1** (AC3, AC4, AC9 partiel, AC10, AC11)
  - Fichier `lib/features/onboarding/presentation/pages/hero_intro_page.dart`.
  - Zone hero placeholder gradient + `LucideIcons.bookOpen` 96 sp.
  - 3 `HeroIntroFeatureCard` (Cours BookOpen / Exercices PenLine / Chat IA MessageCircle).
  - Footer `OnboardingCtaFooter(label: l10n.heroIntroCta, onPressed: _next)`.
  - Layout responsive 4 form factors.
  - Clés ARB heroIntro*.
  - 2 goldens (phone + tablet).
  - Widget test : tap CTA → `notifier.next()` appelé.

- [x] **T6 — `OnboardingShell` wrapper** (AC1)
  - Fichier `lib/features/onboarding/presentation/pages/onboarding_shell.dart`.
  - `ConsumerStatefulWidget` avec `initState` async appelant `loadFromPersistence`.
  - `build` : `switch (state.currentStep)` retournant page appropriée.
  - Cases 0 → `SubSystemChoicePageV2`, 1 → `HeroIntroPage`, 2-9 → `_StepPlaceholder('Étape X — à venir (E1bis-3+)')`.
  - Widget tests : (a) mount appelle loadFromPersistence, (b) state currentStep 0/1/2 → rend la bonne page.

- [x] **T7 — Routes parallèles + redirect router** (AC7, AC8, AC12 partiel)
  - **UPDATE** `lib/core/routing/app_router.dart` : ajouter 2 `GoRoute` (`/onboarding/sub-system-v2`, `/onboarding/hero`) pointant vers `OnboardingShell`.
  - **UPDATE** `evaluateRedirect` : ajouter check `useNewOnboardingFlow && location == '/onboarding/subsystem' → '/onboarding/sub-system-v2'` + anti-replay symétrique `hasSubSystem && location == '/onboarding/sub-system-v2' → '/'`.
  - Tests `test/core/routing/app_router_redirect_test.dart` : 3 nouveaux cas (flag ON forward / flag ON anti-replay / flag OFF preservation Epic 1).

- [x] **T8 — Microcopie ARB FR + EN** (AC9)
  - **UPDATE** `lib/l10n/app_fr.arb` + `app_en.arb` : 14 clés (cf. AC9 liste).
  - Lancer `flutter gen-l10n` après modification (validation : `AppLocalizations.of(context).heroIntroTitle` compile).

- [x] **T9 — Catalogue COMPOSANTS-REUTILISABLES.md MAJ** (AC15)
  - Ajouter entrée `OnboardingCtaFooter` § « Catalogue actuel ».
  - Décider `HeroIntroFeatureCard` : entrée si extrait, sinon mention dans Dev Notes.
  - Historique datée 2026-06-XX.

- [x] **T10 — `flutter analyze` + `flutter test` propres**
  - `cd mobile_app && flutter analyze` → 0 issue (baseline E1bis-1 = 0).
  - `cd mobile_app && flutter test` → tous verts. Baseline E1bis-1 = 391 passed + 1 skipped. Cible E1bis-2 = 391 + ~20-30 nouveaux ≈ 410-420 verts + 1 skipped.

- [x] **T11 — Mise à jour sprint-status + commit + push**
  - `1bis-1` `review` → `done` (PR #102 mergée commit `8439235`) + `1bis-2` `ready-for-dev` → `in-progress` au début dev, puis `review` en fin.
  - Commits Conventional Commits (à enchaîner) :
    1. `feat(core): ajouter FeatureFlags + OnboardingCtaFooter composant catalogue`
    2. `feat(onboarding): ajouter SubSystemChoicePageV2 + HeroIntroPage + HeroIntroFeatureCard (refonte E1bis)`
    3. `feat(onboarding): ajouter OnboardingShell wrapper + extension router 2 routes parallèles + feature flag`
    4. `feat(l10n): ajouter clés ARB onboarding refonte (sub-system + hero intro)`
    5. `docs(core): catalogue COMPOSANTS-REUTILISABLES.md - entrée OnboardingCtaFooter`
    6. `docs(planning): finaliser story E1bis-2 - status ready-for-dev -> review`
  - Push `feat/1bis-2-pages-sub-system-hero` → ouvrir PR. **Attendre merge avant E1bis-3** (CLAUDE.md règle 6).

---

## Dev Notes

### Contexte et motivation

E1bis-1 (PR #102 mergée `8439235`) a livré la state machine `OnboardingNotifier` mais sans UI. Cette story est le **premier rendu visuel** du flow refondu : steps 0 (sub-system choice) + 1 (hero intro). Validation porteur produit attendue sur :

1. **Look-and-feel hero** (placeholder gradient acceptable vs asset image requis).
2. **Microcopie FR/EN** (ton bienveillant adapté lycéens camerounais 12-19 ans).
3. **Fluidité tap card** (auto-avance après `setSubSystem` ou CTA explicite ?).

### Décisions techniques clés

- **Décision 1** : **Feature flag constante hard-codée** (`FeatureFlags.useNewOnboardingFlow = false`) plutôt que SharedPreferences. — **raison** : minimise la surface de bugs (pas de provider à override, pas de toggle UI à construire). Suffit pour V1 QA via build dédié. — **alternative écartée** : provider Riverpod + clé SharedPreferences `feature.onboarding.v2`. Refusé : adds complexity sans bénéfice tant qu'on n'a pas de toggle runtime exposé.

- **Décision 2** : **`OnboardingShell` est unique wrapper pour tout le flow**, routage interne par `currentStep`. — **raison** : centralise `loadFromPersistence` + observation `OnboardingNotifier`. Les pages n'ont pas à connaître leur step ni à gérer la navigation. — **alternative écartée** : une `GoRoute` par step (`/onboarding/track`, `/onboarding/level`, etc.). Refusé : 10 routes à maintenir + désynchro possible entre URL et `currentStep` du Notifier.

- **Décision 3** : **`SubSystemChoicePageV2.tap card → setSubSystem + auto-avance + CTA cosmétique disabled**. — **raison** : conforme template React (`OnboardingFlow.tsx` step 0 — le tap card persiste + avance sans CTA). — **alternative écartée** : tap card pose just la valeur, le user doit taper CTA `Continuer` pour avancer. Refusé : ajoute friction inutile (2 taps au lieu d'1) sur un step à fort engagement.

- **Décision 4** : **Hero illustration = placeholder gradient + LucideIcon, pas d'asset image**. — **raison** : OQ-E1bis-1 décidée. Découple le timing freelance asset du dev. Permet de valider la microcopie immédiatement. — **alternative écartée** : commander un asset PNG avant la story. Refusé : bloquerait la PR pendant 1-2 semaines (sourcing freelance).

- **Décision 5** : **Bascule i18n NON faite dans cette story** au tap sub-system. — **raison** : le `LocaleNotifier` Epic 1 (Story 0.16) lit `subSystemNotifierProvider` legacy pas `onboardingNotifierProvider`. Patcher ça dans cette story = touche à du code Epic 1 (rupture coexistence flag). Reporté E1bis-9 (migration globale). — **alternative écartée** : étendre `LocaleNotifier` pour lire les deux providers. Refusé : casse principe « pas de modification du code Epic 1 actif ». Workaround pour tester en runtime : changer la langue système avant test (Android Settings) OU activer le flag E1bis ET utiliser le `SubSystemNotifier` legacy en parallèle (cohabite OK, même clé SharedPreferences).

- **Décision 6** : **Redirect router minimal** (1 check forward + 1 anti-replay). — **raison** : suffit pour tester le nouveau flow runtime via deep link sans casser le redirect Story 1.5 profil-incomplet. — **alternative écartée** : remplacer toute la garde profil-incomplet par une garde E1bis basée sur `OnboardingNotifier.currentStep`. Refusé : ce serait E1bis-4 (post-auth Firestore) car le `users/{uid}` n'est écrit qu'à ce stade.

### Modèle de données / API impactés

- Fichiers `domain/` : aucun.
- Fichiers `data/` : aucun.
- Fichiers `presentation/` (nouveaux) :
  - `lib/core/config/feature_flags.dart` (~30 l).
  - `lib/core/widgets/onboarding/onboarding_cta_footer.dart` (~80 l).
  - `lib/features/onboarding/presentation/pages/onboarding_shell.dart` (~80 l).
  - `lib/features/onboarding/presentation/pages/sub_system_choice_page_v2.dart` (~150 l).
  - `lib/features/onboarding/presentation/pages/hero_intro_page.dart` (~200 l, avec `_FeatureCard` privé) OU 140 l + `hero_intro_feature_card.dart` 80 l séparé.
- Fichiers modifiés :
  - `lib/core/routing/app_router.dart` : +2 GoRoute + 2 lignes dans `evaluateRedirect` + 2 imports.
  - `lib/l10n/app_fr.arb` + `app_en.arb` : +14 clés.
  - `doc/tech/COMPOSANTS-REUTILISABLES.md` : +1 entrée (ou +2 si HeroIntroFeatureCard extrait).
- Schéma Firestore : aucun changement (pas de Firestore touché).
- Contrats Cloud Function : N/A.

### Cost-benefit Firestore

**N/A pour cette story** — aucune lecture/écriture Firestore. La persistance `subSystem` SharedPreferences est gérée par `OnboardingNotifier.setSubSystem` E1bis-1 via `SubsystemPrefs` existant Story 1.2.

### Stratégie responsive

**Form factors cibles** :
- Phone portrait (< 600 dp) : OUI — colonne unique scrollable, `OnboardingCtaFooter` sticky bottom via `Scaffold.bottomNavigationBar`.
- Phone landscape (600-840 dp) : OPTIONNEL — verrouillage portrait OK V1 (cohérent avec Epic 1 antérieures).
- Tablet portrait & landscape (≥ 840 dp) : OUI — `ConstrainedBox(maxWidth: 600.w)` centré horizontalement, marges latérales `AppSpacing.s8`. Footer reste plein largeur.

**Breakpoints à utiliser** :
- `LayoutBuilder` à la racine du `Scaffold.body` de chaque page (pas dans `OnboardingShell` qui ne gère que le routing step).
- Seuil unique 840 dp (tablet threshold).
- Pas de constantes `kBreakpointPhone` / `kBreakpointTablet` dans `tokens.dart` à introduire dans cette story (peut faire ça en story dette dédiée si jugé utile — pas critique pour 2 pages).

**Layout strategy par form factor** :
- Phone < 840 dp : colonne unique scrollable plein largeur, padding latéral `AppSpacing.s4`.
- Tablet ≥ 840 dp : colonne unique max width 600.w, padding latéral `AppSpacing.s4` interne, marges externes via `Center` + `ConstrainedBox`.

**Golden tests à inclure** (≥ 1 viewport ≥ 840 dp obligatoire — règle 5) :
- [x] Golden phone portrait (360×780) — `SubSystemChoicePageV2` unselected + selected
- [x] Golden phone portrait (360×780) — `HeroIntroPage`
- [x] Golden tablet portrait (800×1280) — `SubSystemChoicePageV2`
- [x] Golden tablet portrait (800×1280) — `HeroIntroPage`
- [x] Goldens `OnboardingCtaFooter` (3 états)
- [ ] (Optionnel) Tablet paysage 1280×800
- [ ] (Optionnel) Phone landscape 700×400

**Acceptance Criteria responsive à ajouter à la story** :
- « `SubSystemChoicePageV2` et `HeroIntroPage` s'affichent correctement en tablette portrait sans gaspillage d'espace horizontal — vérifié par golden test au breakpoint 800×1280. »

### Composants réutilisables

**Catalogue consulté** : [doc/tech/COMPOSANTS-REUTILISABLES.md](../../doc/tech/COMPOSANTS-REUTILISABLES.md) § « Catalogue actuel » — entrées `SelectionCard` (E1bis-0), `AppButton` (Story 0.13).

**Composants existants réutilisés** :
- `SelectionCard(variant: hero)` (`lib/core/widgets/cards/selection_card.dart`) — usage : 2 cards Francophone / Anglophone dans `SubSystemChoicePageV2`.
- `AppButton.primary` (`lib/core/widgets/app_button.dart`) — usage : composé dans `OnboardingCtaFooter`.
- `onboardingNotifierProvider` (E1bis-1) — usage : `ref.watch(...).subSystem` + `ref.watch(...).currentStep` + `ref.read(...).notifier.setSubSystem(...)` + `notifier.next()` + `notifier.loadFromPersistence()`.

**Composants existants adaptés (paramètre optionnel ajouté)** : Aucun. `SelectionCard(variant: hero)` accepte déjà nativement `icon: null` et `description: null`.

**Nouveaux composants créés et ajoutés au catalogue** :
- `OnboardingCtaFooter` (path `lib/core/widgets/onboarding/onboarding_cta_footer.dart`) — entrée catalogue ajoutée dans la même PR (T9). Réutilisé par E1bis-3 à E1bis-7.
- `HeroIntroFeatureCard` (path `lib/features/onboarding/presentation/widgets/hero_intro_feature_card.dart`) **SI extraction décidée** — entrée catalogue conditionnelle. Sinon reste widget privé `_FeatureCard` dans `hero_intro_page.dart`.

**Vérification anti-duplication** :
- [ ] Pas de classe privée `_SubSystemCard` ou `_HeroCard` dupliquant `SelectionCard`.
- [ ] Pas de classe privée `_CtaButton` dupliquant `AppButton`.
- [ ] Si `OnboardingCtaFooter` créé, entrée catalogue présente dans la PR.

### Tests à écrire

- **Widget tests** :
  - `OnboardingShell` (`test/features/onboarding/presentation/pages/onboarding_shell_test.dart`, ~4 cas) : (a) mount appelle loadFromPersistence — vérifier via SharedPreferences mock préalable ; (b) `state.currentStep == 0` → rend `SubSystemChoicePageV2` (vérifier `find.byType`) ; (c) `state.currentStep == 1` → rend `HeroIntroPage` ; (d) `state.currentStep == 2` → rend placeholder « à venir ».
  - `SubSystemChoicePageV2` (`test/features/onboarding/presentation/pages/sub_system_choice_page_v2_test.dart`, ~4 cas) : (a) initial CTA disabled (assert `onPressed == null` via `tester.widget<AppButton>`) ; (b) tap Francophone → state `subSystem == francophone` + `currentStep == 1` ; (c) tap Anglophone → state anglophone ; (d) tablet 800×1280 → `maxWidth: 600` respecté (vérifier via finder + parent constraints).
  - `HeroIntroPage` (`test/features/onboarding/presentation/pages/hero_intro_page_test.dart`, ~3 cas) : (a) rendu hero + 3 feature cards + CTA ; (b) tap CTA → `state.currentStep == 2` ; (c) tablet 800×1280 → layout respecté.
  - `OnboardingCtaFooter` (`test/core/widgets/onboarding/onboarding_cta_footer_test.dart`, ~3 cas) : (a) `onPressed: null` → button disabled (vérifier propagation au `AppButton`) ; (b) tap → callback appelé ; (c) `secondaryAction: Text('Skip')` rendu au-dessus.
  
- **Golden tests** : voir AC11 (9-10 goldens phone + tablet minimum).

- **Tests router** (`test/core/routing/app_router_redirect_test.dart` — fichier existant) :
  - (a) flag ON + location `/onboarding/subsystem` → return `/onboarding/sub-system-v2`.
  - (b) flag ON + location `/onboarding/sub-system-v2` + hasSubSystem true → return `/`.
  - (c) flag OFF + location `/onboarding/subsystem` → return null (Epic 1 préservé).

### Anti-patterns à éviter

- ❌ **NE PAS** modifier `subsystem_choice_page.dart` (Epic 1 legacy). Coexistence via flag uniquement.
- ❌ **NE PAS** modifier `LocaleNotifier` (Story 0.16) pour qu'il écoute `onboardingNotifierProvider`. Bascule i18n reportée E1bis-9.
- ❌ **NE PAS** patcher la garde Story 1.5 (profil-incomplet) — elle reste Epic 1 jusqu'à E1bis-4.
- ❌ **NE PAS** créer une `_FeatureCard` privée dans plusieurs fichiers (anti-pattern Story 1.18). Si réutilisée par 2+ pages, extraire vers `lib/core/widgets/onboarding/`.
- ❌ **NE PAS** logger `subSystem` ou autre données utilisateur sensibles dans les tests (CLAUDE.md règle 4).
- ❌ **NE PAS** mettre `LayoutBuilder` autour de `OnboardingCtaFooter` — composant pur, le caller (la page) gère le responsive.

### Références

- Story d'origine : E1bis-2 dans `project_manage/planning-artifacts/epics/epic-1bis-refonte-onboarding.md` lignes 184-216 (AC source).
- Story précédente : E1bis-1 (`OnboardingNotifier` + `OnboardingState` + `loadFromPersistence` consommés ici).
- Template React : `doc/templates/src/components/OnboardingFlow.tsx` (référence comportement steps 0 + 1).
- Composant E1bis-0 : `SelectionCard(variant: hero)` (`lib/core/widgets/cards/selection_card.dart`) — réutilisé pour les 2 cards Francophone / Anglophone.
- Pattern `LocaleNotifier` Story 0.16 (`lib/features/i18n/`) : référence i18n existant — NE PAS toucher cette story.
- Pattern router redirect Stories 1.2 + 1.5 + 1.8 : `evaluateRedirect` testé dans `test/core/routing/app_router_redirect_test.dart`.

---

## Definition of Done

- [ ] **AC1-AC15** validés.
- [ ] `flutter analyze` : 0 issue.
- [ ] `flutter test` : ≥ 391 passed (baseline E1bis-1) + ≥ 20 nouveaux tests verts.
- [ ] 6 nouveaux fichiers `lib/` (FeatureFlags + OnboardingCtaFooter + OnboardingShell + SubSystemChoicePageV2 + HeroIntroPage + HeroIntroFeatureCard si extrait) + 1 fichier modifié (`app_router.dart`) + 2 fichiers ARB modifiés.
- [ ] 9-10 goldens phone + tablet livrés.
- [ ] Entrée catalogue `OnboardingCtaFooter` ajoutée (et `HeroIntroFeatureCard` si extrait).
- [ ] Aucune modification du code Epic 1 (`subsystem_choice_page.dart`, `LocaleNotifier`, `OnboardingFlowNotifier`).
- [ ] Identifiers anglais 100% — pas de `filiere`/`niveau`/`serie`/`matiere` dans les nouveaux fichiers (CLAUDE.md règle 5).
- [ ] `FeatureFlags.useNewOnboardingFlow == false` au merge (default OFF).
- [ ] Story file `1bis-2-pages-sub-system-hero.md` status `review` + Dev Agent Record complété.
- [ ] Sprint-status `1bis-1` → `done` (PR #102 mergée commit `8439235`) + `1bis-2` → `review`.
- [ ] PR poussée sur `feat/1bis-2-pages-sub-system-hero`. **Attendre merge avant E1bis-3** (CLAUDE.md règle 6).

---

## Risques

- **R-E1bis-2.1 — Coexistence i18n imparfaite** : tap sub-system ne bascule pas la langue tant que `LocaleNotifier` n'est pas étendu. Tester runtime nécessite langue système préréglée OU bascule manuelle via `SubSystemNotifier` legacy. Mitigation : documenter dans Completion Notes + ajouter checkpoint « bascule i18n » dans E1bis-9.

- **R-E1bis-2.2 — Routes `/onboarding/sub-system-v2` + `/onboarding/hero` partagent le même builder** (`OnboardingShell`). Si un testeur deep-link `/onboarding/hero` alors que `currentStep == 0`, il verra `SubSystemChoicePageV2` (cohérent avec state machine). Cela peut surprendre. Mitigation : documenter dans Dev Notes que l'URL est cosmétique (debug) — c'est `currentStep` du Notifier qui décide.

- **R-E1bis-2.3 — Placeholder hero pas accepté par porteur produit** → asset image requis avant merge. Mitigation : valider rapidement la microcopie + le ton avec porteur. Si refus du placeholder, la story passe en blocage jusqu'à livraison asset (1-2 semaines).

- **R-E1bis-2.4 — Goldens platform-dependent** : générés sur Windows. Si CI Linux → première run risque mismatch anti-aliasing. À surveiller (cohérent avec risque E1bis-0).

- **R-E1bis-2.5 — `loadFromPersistence` lit la même clé que `SubSystemNotifier` legacy** : si en mode coexistence (flag OFF actif sur device), le legacy a déjà écrit la clé → `OnboardingNotifier.loadFromPersistence` la lira aussi. C'est le comportement attendu (cohabitation safe), mais cela signifie qu'un user Epic 1 qui passe au nouveau flow (flag ON) voit son sub-system déjà rempli. Mitigation : documenter ce comportement = feature, pas bug.

---

## Dev Agent Record

### Agent Model Used

Claude Opus 4.7 (claude-opus-4-7) via Claude Code CLI, skill `bmad-dev-story`, exécuté en une session continue.

### Debug Log References

Aucun bug bloquant identifié pendant le dev. Issues mineures résolues sans détour :

1. **Imports inutilisés dans `sub_system_choice_page_v2_test.dart`** (`flutter_localizations` + `tokens`) — fix : retirés.
2. **Warning hit test sur tap CTA dans `hero_intro_page_test.dart` + `onboarding_cta_footer_test.dart`** — le tap fonctionne, le warning vient du `BottomNavigationBar` qui place le bouton très en bas du viewport. Non bloquant. Pourrait être silencié avec `warnIfMissed: false` mais non nécessaire (tous les tests passent).

### Completion Notes List

1. **Décision T3 — `HeroIntroFeatureCard` **non extrait**, reste widget privé `_FeatureCard` dans `hero_intro_page.dart`** (~28 lignes). Justification : un seul consommateur actuel (la HeroIntroPage), extraction = ajout fichier + entrée catalogue pour zéro gain en réutilisation. Page finale 184 lignes (sous cible 200). Si E1bis-3+ a besoin de feature cards similaires, extraction en story dédiée.

2. **Décision AC2 — `SubSystemChoicePageV2` : `setSubSystem` auto-avance le `currentStep` à 1, le CTA `Continuer` reste cosmétique** (appelle `notifier.next()` au cas où user veut confirmer). Cohérent avec le template React (OnboardingFlow.tsx step 0). Si le user tap la card puis le CTA, le `next()` au step 1 → step 2 — mais à cette étape la page est déjà rendue par `OnboardingShell` qui rend `HeroIntroPage`, donc le tap CTA disparaît (la page n'est plus à l'écran). Comportement OK.

3. **Décision T7 — flag `useNewOnboardingFlow` passé en paramètre nommé optionnel** (`bool useNewOnboardingFlow = false`) au lieu de constante implicite, pour permettre le test de la fonction pure `evaluateRedirect` avec les 2 valeurs sans dépendance sur `FeatureFlags`. Les tests verbosent explicitement chaque cas.

4. **Décision AC8 (redirect) — Le check `useNewOnboardingFlow` est placé AVANT le check Story 1.2 (anti-replay subsystem)** car si flag ON et `/onboarding/subsystem`, on veut forcer la nouvelle route AVANT d'évaluer hasSubSystem (sinon on irait à `/` direct sans passer par le nouveau flow). L'anti-replay sur `/onboarding/sub-system-v2` est placé juste après, pour préserver la symétrie.

5. **Décision T6 — `loadFromPersistence` appelée via `addPostFrameCallback`** dans `initState` du `OnboardingShell` (pas directement) car `ref.read` au `initState` synchrone peut déclencher des erreurs Riverpod si le widget n'est pas encore monté. Le `postFrameCallback` garantit le mount + l'accès au container.

6. **Décision T2 — `OnboardingCtaFooter` se pose en `Scaffold.bottomNavigationBar`** (pas dans le body) pour bénéficier du comportement natif Material (sticky bottom avec safe area) et éviter d'avoir à gérer `Positioned` + `Stack` + listeners de scroll.

7. **AC15 — Catalogue MAJ avec entrée `OnboardingCtaFooter`** + ligne Historique 2026-06-11 + mention explicite que `_FeatureCard` reste privé pour traçabilité.

8. **Coexistence i18n imparfaite assumée** : tap sub-system → state E1bis hydraté mais `LocaleNotifier` Epic 1 ne réagit pas (il lit `subSystemNotifierProvider` legacy, pas `onboardingNotifierProvider`). Trade-off accepté (Décision 5 de la story). Le testing runtime du nouveau flow nécessitera soit (a) langue système préréglée, soit (b) toggle Epic 1 en parallèle. À résoudre E1bis-9 (extension `LocaleNotifier`).

9. **Coexistence SharedPreferences** : `SubsystemPrefs` Epic 1 + `OnboardingNotifier` E1bis lisent/écrivent la même clé `onboarding.subsystem` — cohabitation safe testée via `OnboardingShell` `loadFromPersistence` (test « subSystem persiste -> hydrate + step 1 »).

10. **Résultats tests** : `flutter analyze` 0 issue. `flutter test` 413 passed + 1 skipped (baseline E1bis-1 = 391+1 → delta +22 : 6 OnboardingCtaFooter + 5 SubSystemChoicePageV2 + 4 HeroIntroPage + 4 OnboardingShell + 3 router redirect). Zero régression sur baseline `8439235`.

11. **Goldens livrés** : 7 PNG (3 OnboardingCtaFooter phone + 2 SubSystemChoicePageV2 phone/tablet + 2 HeroIntroPage phone/tablet). Sous cible 9-10 — justifié : `SubSystemChoicePageV2` n'a pas de golden « selected » (couvert par les tests d'interaction qui vérifient les `SelectionCard.selected`). Pas de `tablet landscape` ni `phone landscape` (optionnels selon AC11).

### File List

**Nouveaux fichiers (8)** :

- `mobile_app/lib/core/config/feature_flags.dart` (22 l) — `FeatureFlags.useNewOnboardingFlow` constante.
- `mobile_app/lib/core/widgets/onboarding/onboarding_cta_footer.dart` (~78 l) — composant catalogue.
- `mobile_app/lib/features/onboarding/presentation/pages/onboarding_shell.dart` (~80 l) — wrapper Riverpod + switch case.
- `mobile_app/lib/features/onboarding/presentation/pages/sub_system_choice_page_v2.dart` (~95 l) — page step 0.
- `mobile_app/lib/features/onboarding/presentation/pages/hero_intro_page.dart` (~184 l) — page step 1 + `_HeroBanner` + `_FeatureCard` privés.
- `mobile_app/test/core/widgets/onboarding/onboarding_cta_footer_test.dart` (~165 l) — 6 cas (3 interactions + 3 goldens).
- `mobile_app/test/features/onboarding/presentation/pages/sub_system_choice_page_v2_test.dart` (~205 l) — 5 cas (3 interactions + 2 goldens).
- `mobile_app/test/features/onboarding/presentation/pages/hero_intro_page_test.dart` (~150 l) — 4 cas (2 interactions + 2 goldens).
- `mobile_app/test/features/onboarding/presentation/pages/onboarding_shell_test.dart` (~125 l) — 4 cas (mount loadFromPersistence + 3 routage).

**Goldens livrés (7 PNG)** :

- `test/core/widgets/onboarding/__goldens__/onboarding_cta_footer_phone_enabled.png`
- `test/core/widgets/onboarding/__goldens__/onboarding_cta_footer_phone_disabled.png`
- `test/core/widgets/onboarding/__goldens__/onboarding_cta_footer_phone_with_secondary.png`
- `test/features/onboarding/presentation/pages/__goldens__/sub_system_choice_v2_phone_unselected.png`
- `test/features/onboarding/presentation/pages/__goldens__/sub_system_choice_v2_tablet_unselected.png`
- `test/features/onboarding/presentation/pages/__goldens__/hero_intro_page_phone.png`
- `test/features/onboarding/presentation/pages/__goldens__/hero_intro_page_tablet.png`

**Fichiers modifiés (5)** :

- `mobile_app/lib/core/routing/app_router.dart` — +1 import `feature_flags.dart` + 1 import `onboarding_shell.dart` + 2 nouvelles `GoRoute` + 1 param nommé `useNewOnboardingFlow` à `evaluateRedirect` + 2 nouveaux checks redirect (forward conditionnel flag + anti-replay symétrique).
- `mobile_app/lib/l10n/app_fr.arb` — +14 clés ARB onboarding refonte (avec descriptions).
- `mobile_app/lib/l10n/app_en.arb` — +14 clés ARB (sans description — pattern existant).
- `mobile_app/test/core/routing/app_router_redirect_test.dart` — +3 cas (flag ON forward + flag ON anti-replay + flag OFF préservation Epic 1).
- `doc/tech/COMPOSANTS-REUTILISABLES.md` — +1 entrée `OnboardingCtaFooter` + 1 ligne Historique 2026-06-11.
- `project_manage/implementation-artifacts/1bis-2-pages-sub-system-hero.md` — status `ready-for-dev` → `in-progress` → `review` + tasks cochées + Dev Agent Record rempli.
- `project_manage/implementation-artifacts/sprint-status.yaml` — `1bis-1` `review` → `done` + `1bis-2` `ready-for-dev` → `in-progress` → `review`.

### Change Log

| Commit | Message | Fichiers |
|---|---|---|
| 1 | `feat(core): ajouter FeatureFlags + OnboardingCtaFooter composant catalogue` | `feature_flags.dart` + `onboarding_cta_footer.dart` + `onboarding_cta_footer_test.dart` + 3 goldens |
| 2 | `feat(onboarding): ajouter SubSystemChoicePageV2 + HeroIntroPage (refonte E1bis)` | `sub_system_choice_page_v2.dart` + `hero_intro_page.dart` + 2 tests + 4 goldens |
| 3 | `feat(onboarding): ajouter OnboardingShell wrapper + routes paralleles + feature flag redirect` | `onboarding_shell.dart` + `app_router.dart` + tests router + `onboarding_shell_test.dart` |
| 4 | `feat(l10n): ajouter cles ARB onboarding refonte (sub-system + hero intro)` | `app_fr.arb` + `app_en.arb` |
| 5 | `docs(core): catalogue COMPOSANTS-REUTILISABLES.md - entree OnboardingCtaFooter` | `COMPOSANTS-REUTILISABLES.md` |
| 6 | `docs(planning): finaliser story E1bis-2 - status ready-for-dev -> review` | `1bis-2-pages-sub-system-hero.md` + `sprint-status.yaml` |
