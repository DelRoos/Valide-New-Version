---
story_id: 1bis.0
title: Foundation widgets onboarding (6 composants + helper `maskPhone`)
epic: 1bis
phase: P1bis — Refonte intégrale du flow pré-dashboard
status: ready-for-dev
created: 2026-06-11
baseline_commit: 9a9de46  # refactor(onboarding): extraire widgets school_picker + serie_choice + CLAUDE.md regle 12+13
estimation: M (~3 jours)
sprint_change: project_manage/planning-artifacts/epics/epic-1bis-refonte-onboarding.md (Story E1bis-0)
dependencies:
  - Epic E1bis créé et `epics.md` mis à jour (PR précédente déjà mergée)
  - DESIGN.md + EXPERIENCE.md status: final (2026-06-11) — § « Composants Onboarding (refonte 2026-06-11) »
  - `doc/tech/COMPOSANTS-REUTILISABLES.md` § « À créer — Refonte Onboarding 10 étapes » (spécifications des 6 composants)
  - `doc/tech/STORY-TEMPLATES.md` (templates 1 Dev Notes condensé / 3 Stratégie responsive / 4 Composants réutilisables)
  - Stories 0.10 (`tokens.dart`), 0.12 (`flutter_screenutil`), 0.13/0.14 (composants atomiques + feedback) déjà livrées
  - Story 1.18 mergée — 4 composants picker existants à RÉUTILISER dans E1bis-3 (pas de duplication)
blocks:
  - E1bis-1 (state machine OnboardingNotifier — utilise `SelectionCard` dans ses tests)
  - E1bis-2 (pages 0+1 sub-system + hero — consomme `SubSystemHeroCard` ou variant `hero` + `SelectionCard`)
  - E1bis-3 (pages 2+3+4 picker 5 modes — consomme `SelectionCard` + `PickerCounterBadge`)
  - E1bis-4 (page 5 auth)
  - E1bis-5 (pages 6+7 — consomme `PhoneInputWithCountryFlag` + helper `maskPhone`)
  - E1bis-6 (page 8 — consomme `SchoolSearchWithAdd`)
  - E1bis-7 (page 9 — consomme `CelebrationConfettiSuccess`)
sourceArtifacts:
  - project_manage/planning-artifacts/epics/epic-1bis-refonte-onboarding.md § « Story E1bis-0 » (AC1-AC10 source)
  - project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/DESIGN.md § « Composants Onboarding (refonte 2026-06-11) » (tokens visuels, variants, états)
  - project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/EXPERIENCE.md § « Microcopie onboarding » (copies FR/EN pour goldens fixtures)
  - project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/.decision-log.md § Update 3 (D-UX-Update-15 phone +237 masquage logs, D-UX-Update-17 école optionnelle, D-UX-Update-20 catalogue 4 nouveaux composants)
  - doc/tech/COMPOSANTS-REUTILISABLES.md § « À créer — Refonte Onboarding 10 étapes » (spec détaillée des 6 composants — path, props, comportement, tests)
  - doc/templates/src/components/OnboardingFlow.tsx (template React — référence comportement steps 0, 5, 7, 8, 9)
  - doc/templates/src/types.ts (modèle `UserProfile` — référence champs)
  - mobile_app/lib/core/theme/tokens.dart (tokens canoniques — AppColors / AppSpacing / AppRadius / AppElevation / AppMotion)
  - mobile_app/lib/core/widgets/picker/picker_validate_bar.dart (pattern Story 1.18 — référence style composant + test layout)
  - mobile_app/lib/core/widgets/app_card.dart + app_button.dart + app_input.dart + app_toast.dart (composants atomiques Story 0.13/0.14 à composer)
---

# Story 1bis.0 — Foundation widgets onboarding (6 composants + `maskPhone`)

Status: **ready-for-dev**

## Objectif

Livrer la **fondation widget** de la refonte onboarding 10 étapes : 6 composants Flutter réutilisables (`SelectionCard`, `SubSystemHeroCard`, `PhoneInputWithCountryFlag`, `SchoolSearchWithAdd`, `CelebrationConfettiSuccess`, `PickerCounterBadge`) + helper sécurité `maskPhone()`, tous documentés au catalogue [`doc/tech/COMPOSANTS-REUTILISABLES.md`](../../doc/tech/COMPOSANTS-REUTILISABLES.md), couverts par golden tests phone (360×780) + tablet (900×1200) et tests unitaires.

**Pourquoi maintenant** : E1bis-1 (state machine) à E1bis-7 (page success) consomment toutes au moins un de ces composants. Commencer par les pages sans la fondation = duplication garantie (anti-pattern Stories 1.4 → 1.17 résorbé par Story 1.18). Cette story est la **seule** de l'epic E1bis qui n'a pas de prérequis amont — elle peut démarrer immédiatement après merge du contexte epic.

**Pourquoi pas plus tard** : sans cette fondation, chaque story page se débat avec ses propres widgets locaux, perd 30-50 % de son temps en duplication, et la rétro Epic E1bis livrera la même dette technique que Epic 1.

---

## User Story

**En tant que** développeur Flutter qui prépare la refonte E1bis (pages 0-9),
**je veux** disposer des 6 widgets réutilisables onboarding documentés au catalogue et couverts par tests goldens phone + tablet,
**afin que** les stories pages E1bis-2 à E1bis-7 consomment des briques stables sans réintroduire de classes privées dupliquées (anti-pattern résorbé Story 1.18).

---

## Acceptance Criteria

- **AC1 — `SelectionCard` générique**. Créer `mobile_app/lib/core/widgets/cards/selection_card.dart`. Props : `title: String`, `selected: bool`, `onTap: VoidCallback`, `icon: Widget?` (Lucide ou Material), `description: String?`, `variant: SelectionCardVariant = standard` (enum `compact` 40×40 icon + 15 sp title, `standard` 48×48 icon + 17 sp title, `hero` 56×56 icon + 18 sp title). Comportements : selected → ring 2 px `AppColors.primary` + scale 1.01 + radio coché (cercle 18 px droit) ; tap → `HapticFeedback.selectionClick` + `onTap()`. Couleurs strictement selon DESIGN.md § Composants Onboarding (bg `AppColors.card`, border `AppColors.border`, hover `AppColors.primarySoft`). Pas de dépendance Firebase / Riverpod / `dart:io`.

- **AC2 — `SubSystemHeroCard` (ou variant `hero` de `SelectionCard`)**. Si la différence visuelle avec `SelectionCard(variant: hero)` est négligeable (padding `AppSpacing.s5`, sans description, sans icône interne — icône externe est en hero step 0), **collapser dans `SelectionCard`** avec le variant `hero` et écrire dans Completion Notes « SubSystemHeroCard fusionné dans SelectionCard.variant=hero ». Sinon créer `mobile_app/lib/core/widgets/onboarding/sub_system_hero_card.dart` avec props : `title: String`, `selected: bool`, `onTap: VoidCallback`. Décision documentée au catalogue.

- **AC3 — `PhoneInputWithCountryFlag`**. Créer `mobile_app/lib/core/widgets/forms/phone_input_with_country_flag.dart`. Props : `value: String` (E.164), `onChanged: void Function(String e164Value)`, `errorText: String?`, `enabled: bool = true`, `autofocus: bool = false`. Comportements : drapeau CM (asset SVG ou emoji 🇨🇲 fallback) + indicatif `+237` figé en préfixe inerte + `TextField` numérique avec masque `6 XX XX XX XX` ; clavier `TextInputType.phone` ; validation regex `^\+237[26][0-9]{8}$` (le caller fournit `errorText` selon validation). Le composant **n'expose aucun log AppLogger**. **Static method publique** : `static String maskedForLogs(String e164)` qui retourne `'+237 XX XX XX 78 90'` (4 derniers digits visibles, ou `'<no-phone>'` si null/empty/format invalide) — cf. règle sécurité CLAUDE.md §4.

- **AC4 — `SchoolSearchWithAdd`**. Créer `mobile_app/lib/core/widgets/forms/school_search_with_add.dart`. Props : `selectedSchool: SchoolEntry?` (record/value class `({String id, String name, bool isPending})`), `onSelect: void Function(SchoolEntry school)`, `onAddRequest: Future<String> Function(String name)` (retourne `pendingRequestId` async), `searchProvider: AsyncValue<List<SchoolEntry>> Function(String query)`, `placeholder: String`. Comportements : `TextField` avec debounce **250 ms** sur la saisie ; suggestions rendues comme `SelectionCard(variant: standard)` ; si zéro résultat ET saisie non-vide → carte « + Ajouter "<saisie>" » (border-dashed `AppColors.primary`) ; tap « + Ajouter » → spinner inline + `await onAddRequest(saisie)` → `onSelect(SchoolEntry(id: pendingRequestId, name: saisie, isPending: true))` ; gestion `AsyncError` → bandeau warning `AppInlineAlert` + bouton « + Ajouter » toujours disponible. **Aucune lecture Firestore directe ici** — le `searchProvider` est injecté par la page consommatrice (E1bis-6).

- **AC5 — `CelebrationConfettiSuccess`**. Créer `mobile_app/lib/core/widgets/feedback/celebration_confetti_success.dart`. Props : `title: String`, `subtitle: String`, `ctaLabel: String`, `onComplete: VoidCallback`, `autoDismissDelay: Duration? = const Duration(milliseconds: 3500)` (null pour désactiver), `variant: CelebrationVariant = success` (enum `success` vert / `brand` bleu / `warning` ambre). Comportements : cercle 128 dp central + checkmark animé (spring entrée 600 ms via `AppMotion.celebration`) + 3 micro-icônes orbitantes fade-in delay 300/400/500 ms + canvas confetti (2.5 s, 4 particules/frame, 2 origines left/right, couleurs `[AppColors.primary, AppColors.success, AppColors.warning, AppColors.sky]`) + audio `complete.m4a` via `AudioService` (Story 0.14) à T+200 ms + haptic `success` via `HapticService` (Story 0.14). **Coupures globales** : `MediaQuery.disableAnimations == true` → confetti masqué + fade-in statique 200 ms ; `AudioService.silent` → pas de son ; `HapticService.disabled` → pas de vibration. CTA tap OU `autoDismissDelay` écoulé → `onComplete()`.

- **AC6 — `PickerCounterBadge`**. Créer `mobile_app/lib/core/widgets/picker/picker_counter_badge.dart`. Props : `currentCount: int`, `min: int`, `max: int`, `labelText: String` (texte pré-formaté FR/EN par l'appelant — pas d'i18n interne), `isValid: bool`. Comportements : `isValid == false` → bg `AppColors.warningSoft` + label `AppColors.warningInk` + badge droit `AppColors.warningInk` ; `isValid == true` → bg `AppColors.successSoft` + label `AppColors.successInk` + badge droit `AppColors.success` + `Icon(LucideIcons.check, size: 12)`. Transition couleur **300 ms** `AppMotion.standardOut`. Composant pensé pour usage **sticky** : encapsulable dans `SliverPersistentHeader` ou `SliverAppBar` selon la page (responsabilité du parent).

- **AC7 — Helper `maskPhone()`**. Créer `mobile_app/lib/core/logging/log_safe.dart` exposant `String maskPhone(String? e164)`. Comportement : si `null` ou empty → retourne `'<no-phone>'` ; si format E.164 valide Cameroun (`+237[26]\d{8}`) → retourne `'+237 XX XX XX X7 89'` (4 derniers visibles, séparateur espace par 2) ; si format invalide → retourne `'<invalid-phone>'`. Pas d'import `package:logger`. Helper utilisé par toute couche `presentation` / `data` qui logue un numéro téléphone (E1bis-5 AC5 + futures stories profil).

- **AC8 — Catalogue mis à jour dans la MÊME PR**. Dans `doc/tech/COMPOSANTS-REUTILISABLES.md` : (a) déplacer chaque entrée des 6 composants de § « À créer — Refonte Onboarding 10 étapes » vers § « Catalogue actuel » avec path final, props finales, exemple Dart concret et liens vers les tests ; (b) noter pour `SubSystemHeroCard` la décision de l'AC2 (fusionné ou créé séparément) ; (c) ajouter une entrée Historique datée 2026-06-XX avec le numéro de PR. Si l'AC2 a fusionné `SubSystemHeroCard` dans `SelectionCard`, marquer l'entrée « À créer » comme « Skippée — couvert par `SelectionCard.variant=hero` » plutôt que la supprimer (traçabilité décision).

- **AC9 — Tests obligatoires**. Pour chaque composant : **≥ 1 golden test phone 360×780 + ≥ 1 golden test tablet 900×1200** (CLAUDE.md règle 5). Plus en détail :
  - `SelectionCard` : 3 variants (`compact` / `standard` / `hero`) × 2 form factors × 2 états (selected / unselected) = 12 goldens minimum + 1 test unit tap → onTap + haptic + 1 test sans icône → padding gauche réduit.
  - `SubSystemHeroCard` (si créé séparé) : 2 form factors × 2 états = 4 goldens.
  - `PhoneInputWithCountryFlag` : 2 form factors × 3 états (vide / rempli / erreur) = 6 goldens + tests unit `maskedForLogs` 5 cas (valide `+237671234567` / null / empty / format invalide `+33612345678` / trop court `+2376123`) + test validation regex (vide / partiel / valide / mauvais préfixe → onChanged émet la valeur brute, errorText vient de l'extérieur).
  - `SchoolSearchWithAdd` : 2 form factors × 4 états (vide / saisie + résultats / zéro résultat + add card / erreur réseau) = 8 goldens + test unit debounce 250 ms (utiliser `FakeAsync`) + test `onSelect` propagé + test `onAddRequest` await + spinner inline + test `AsyncError` → bandeau visible + add toujours actif.
  - `CelebrationConfettiSuccess` : 2 form factors × 2 instants (état initial / post-autoDismiss simulé via `WidgetTester.pump(autoDismissDelay)`) = 4 goldens + test `MediaQuery.disableAnimations = true` → `find.byType(ConfettiWidget)` absent + test tap CTA → onComplete + test variants `success` / `brand` / `warning` → couleurs cercle correctes.
  - `PickerCounterBadge` : 2 form factors × 2 états (sous min / valide) = 4 goldens + test isValid → couleurs correctes + test labelText interpolation.
  - `maskPhone()` : 5 cas unit (cf. ci-dessus).
  
  Goldens sous `mobile_app/test/core/widgets/{subfolder}/__goldens__/` (convention existante Story 1.18). Régénérables via `flutter test --update-goldens`. Utiliser `golden_toolkit: ^0.15.0` déjà au `pubspec.yaml` (vérifier).

- **AC10 — Stratégie responsive documentée par composant**. Section « Stratégie responsive » des Dev Notes (cf. ci-dessous) : pour chaque composant, déclarer son comportement parmi {`phone-only` / `phone + tablet` / `tablet-adaptive`} et le justifier. Les 6 composants visent `phone + tablet` minimum ; `SchoolSearchWithAdd` et `SelectionCard` sont **`tablet-adaptive`** (largeur max contrainte 600 dp ≥ 840 dp via `ConstrainedBox` interne, pas de side-by-side). Aucun composant n'est `phone-only`.

- **AC11 — Identifiers anglais stricts (CLAUDE.md règle 5)**. Noms de fichiers, classes, enums, props, variables internes : 100 % anglais. Pas de `filiere`, `niveau`, `serie`, `matiere`. Glossaire interne au composant si pertinent (`stream` / `track` / `level`).

- **AC12 — Taille fichiers ≤ 300 lignes par composant (CLAUDE.md règle 12)**. Si un fichier dépasse 300 lignes en draft (typiquement `CelebrationConfettiSuccess` à cause de la choreography multisensorielle), extraire les helpers (`_ConfettiCanvas`, `_OrbitingMicroIcon`) dans le même dossier `feedback/` en fichiers frères publics. Aucun fichier de la story ne doit dépasser 500 lignes (plafond dur).

---

## Tasks / Subtasks

> Ordre recommandé (dépendances internes : `SelectionCard` est consommé par `SchoolSearchWithAdd`).

- [ ] **T1 — Setup paquetages + dossiers** (AC : tous)
  - [ ] Ajouter `confetti: ^0.7.0` au `mobile_app/pubspec.yaml` (vérifier impact APK ; si > 200 KB → noter en Completion Notes, fallback `CustomPaint` en sous-tâche). Vérifier `golden_toolkit: ^0.15.0` déjà présent (sinon ajouter).
  - [ ] Créer arborescence : `lib/core/widgets/cards/`, `lib/core/widgets/forms/`, `lib/core/widgets/onboarding/` (si AC2 fork séparé). Les dossiers `lib/core/widgets/picker/` et `lib/core/widgets/feedback/` existent déjà.
  - [ ] Créer arborescence tests miroir : `test/core/widgets/cards/__goldens__/`, `test/core/widgets/forms/__goldens__/`, `test/core/widgets/feedback/__goldens__/`, `test/core/widgets/picker/__goldens__/`, `test/core/logging/`.

- [ ] **T2 — `SelectionCard` générique** (AC1, AC10, AC11, AC12, AC9)
  - [ ] Implémenter `lib/core/widgets/cards/selection_card.dart` + enum `SelectionCardVariant { compact, standard, hero }`.
  - [ ] Tests : `test/core/widgets/cards/selection_card_test.dart` (interactions + variants) + 12 goldens phone+tablet × 3 variants × 2 états.
  - [ ] Vérifier `ConstrainedBox(maxWidth: 600 dp)` actif au-dessus de 840 dp via `LayoutBuilder`.

- [ ] **T3 — Décision `SubSystemHeroCard`** (AC2)
  - [ ] Comparer visuellement `SelectionCard(variant: hero)` vs le mock DESIGN.md § Sub-system hero. Si négligeable → **stop** : usage direct du variant `hero`, écrire la décision au catalogue (AC8). Sinon créer `lib/core/widgets/onboarding/sub_system_hero_card.dart` (≤ 100 lignes) + tests goldens phone+tablet × 2 états + tests unit.

- [ ] **T4 — `PickerCounterBadge`** (AC6, AC9)
  - [ ] Implémenter `lib/core/widgets/picker/picker_counter_badge.dart` (Animated container 300 ms entre warning-soft et success-soft).
  - [ ] Tests : `test/core/widgets/picker/picker_counter_badge_test.dart` + 4 goldens phone+tablet × 2 états.

- [ ] **T5 — `PhoneInputWithCountryFlag` + helper `maskPhone`** (AC3, AC7, AC9, AC11)
  - [ ] Implémenter d'abord `lib/core/logging/log_safe.dart` (`maskPhone`) + tests `test/core/logging/log_safe_test.dart` (5 cas).
  - [ ] Implémenter `lib/core/widgets/forms/phone_input_with_country_flag.dart`. Inclure `static String maskedForLogs(String e164)` qui délègue à `maskPhone(e164)` du helper (un seul algorithme — pas de duplication).
  - [ ] Tests : `test/core/widgets/forms/phone_input_with_country_flag_test.dart` + 6 goldens + tests `maskedForLogs` (qui re-vérifient le passthrough).

- [ ] **T6 — `SchoolSearchWithAdd`** (AC4, AC9, AC10)
  - [ ] Définir record/value `SchoolEntry` dans `lib/core/widgets/forms/school_entry.dart` (ou inline si court — vérifier ≤ 50 lignes) : `({String id, String name, bool isPending})`.
  - [ ] Implémenter `lib/core/widgets/forms/school_search_with_add.dart` avec debounce 250 ms (`Timer?` interne + `dispose()` propre). Consomme `SelectionCard(variant: standard)` pour chaque résultat. Bandeau erreur via `AppInlineAlert` existant.
  - [ ] Tests + 8 goldens.

- [ ] **T7 — `CelebrationConfettiSuccess`** (AC5, AC9, AC12)
  - [ ] Implémenter `lib/core/widgets/feedback/celebration_confetti_success.dart`. Si > 300 lignes → extraire `_OrbitingMicroIcon`, `_ConfettiCanvas` en fichiers publics frères dans `feedback/`.
  - [ ] Vérifier intégration `AudioService.playClipOnce('complete.m4a')` + `HapticService.success()` (APIs Story 0.14). Si elles n'existent pas avec ces signatures, noter l'écart en Completion Notes et utiliser les APIs réelles disponibles.
  - [ ] Tests + 4 goldens + test `MediaQuery.disableAnimations`.

- [ ] **T8 — Mise à jour catalogue** (AC8)
  - [ ] Dans `doc/tech/COMPOSANTS-REUTILISABLES.md` : déplacer les 6 entrées de § « À créer » → § « Catalogue actuel », avec path final, props finales, exemple Dart concret, lien tests.
  - [ ] Ajouter ligne Historique : `| 2026-06-XX | Story 1bis-0 livrée — 6 composants foundation onboarding + helper maskPhone | feat/1bis-0-foundation-widgets | Amelia |`.
  - [ ] Si `SubSystemHeroCard` fusionné dans `SelectionCard.variant=hero` → marquer l'entrée originale « Skippée » avec lien vers `SelectionCard`.

- [ ] **T9 — Audit final + push PR** (DoD)
  - [ ] `flutter analyze` propre.
  - [ ] `flutter test` tout vert (env Pixel Tablet golden_toolkit OK).
  - [ ] `wc -l` chaque fichier créé ≤ 300 lignes (ou ≤ 500 avec justification dans Completion Notes).
  - [ ] Grep zéro occurrence `filiere`, `niveau`, `serie`, `matiere` dans les fichiers de la story (CLAUDE.md règle 5).
  - [ ] Grep zéro `AppLogger.*phoneNumber` sans `maskPhone` dans les nouveaux fichiers.
  - [ ] Push PR `feat/1bis-0-foundation-widgets`. Description : récap des 6 composants + lien catalogue + récap goldens. Ne pas démarrer E1bis-1 avant merge (CLAUDE.md règle 6 Workflow Git).

---

## Dev Notes

### Contexte et motivation

Epic E1bis refond les 10 étapes pré-dashboard avec auth tardive (step 5), consolidation des 5 modes picker, mode visiteur explicite et téléphone +237 réintroduit. Stories E1bis-1 à E1bis-8 consomment toutes au moins un des 6 composants livrés ici. La rétro Epic 1 v2 a démontré que livrer les pages avant les composants partagés produit systématiquement de la dette (Stories 1.4-1.17 → résorption Story 1.18). Cette story applique l'apprentissage : **fondation d'abord, pages ensuite**.

### Décisions techniques clés

- **Décision 1** : `SelectionCard` avec enum `variant` plutôt que 3 classes distinctes — **raison** : DESIGN.md confirme que les 3 variants partagent 90 % du rendu (ring sélection, radio droit, padding) ; un enum évite la duplication. **Alternative écartée** : 3 widgets séparés (`CompactSelectionCard`, `StandardSelectionCard`, `HeroSelectionCard`) — refusé car maintenance × 3 et coût de réutilisation accru.
- **Décision 2** : `maskPhone()` exposé à la fois comme fonction libre `lib/core/logging/log_safe.dart` ET comme méthode statique sur `PhoneInputWithCountryFlag.maskedForLogs` — **raison** : la fonction libre est l'API canonique pour tout le projet (data layer + autres widgets futurs), la méthode statique est un raccourci ergonomique côté UI. Les deux délèguent au même algorithme (zéro duplication). **Alternative écartée** : seulement la statique sur le widget — refusé car la couche `data` ne doit pas importer un widget.
- **Décision 3** : `SchoolSearchWithAdd` reçoit un `searchProvider` injecté en prop plutôt que de lire Firestore directement — **raison** : sépare la responsabilité visuelle (composant pur) de la source de données (page consommatrice E1bis-6). Permet de tester avec un fake provider sans Firebase. **Alternative écartée** : composant Riverpod-aware avec `ConsumerWidget` interne — refusé car couple le composant à `flutter_riverpod` et complique les tests goldens.
- **Décision 4** : `CelebrationConfettiSuccess` utilise le package `confetti: ^0.7.0` — **raison** : maintenu, stable, < 50 KB APK selon doc pub.dev. **Alternative à mesurer en T1** : si APK delta > 200 KB → fallback `CustomPaint + AnimationController` (cf. epic R-E1bis-3). Décision finale documentée en Completion Notes.
- **Décision 5** : `PickerCounterBadge` reçoit son `labelText` pré-formaté plutôt que `min/max` brut + interpolation interne — **raison** : pas d'i18n interne au composant (responsabilité du parent qui a accès au `AppLocalizations`). **Alternative écartée** : injection d'un `(int, int) → String` formatter — refusé car ajoute une indirection sans valeur.

### Modèle de données / API impactés

- **Fichiers nouveaux** :
  - `lib/core/widgets/cards/selection_card.dart` + enum `SelectionCardVariant`
  - `lib/core/widgets/picker/picker_counter_badge.dart`
  - `lib/core/widgets/forms/phone_input_with_country_flag.dart`
  - `lib/core/widgets/forms/school_search_with_add.dart` (+ éventuellement `school_entry.dart` si record extrait)
  - `lib/core/widgets/feedback/celebration_confetti_success.dart` (+ helpers extraits si > 300 lignes)
  - `lib/core/widgets/onboarding/sub_system_hero_card.dart` UNIQUEMENT si AC2 décide création séparée
  - `lib/core/logging/log_safe.dart`
- **Fichiers modifiés** :
  - `mobile_app/pubspec.yaml` (ajout `confetti: ^0.7.0`)
  - `doc/tech/COMPOSANTS-REUTILISABLES.md` (déplacement 6 entrées + Historique)
- **Schéma Firestore** : intact (AC4 — searchProvider injecté, pas de lecture directe).
- **Contrats Cloud Function** : intact.

### Cost-benefit Firestore

**N/A pour cette story.** Tous les composants sont purement présentation. `SchoolSearchWithAdd` reçoit son `searchProvider` injecté (AC4) — la requête Firestore et son optimisation appartiennent à E1bis-6 (page school search), où le cost-benefit sera documenté.

### Stratégie responsive

**Form factors cibles (pour CHAQUE composant)** :

- Phone portrait < 600 dp : **OUI** — comportement par défaut, padding `AppSpacing.s4`, font scales `flutter_screenutil`.
- Phone landscape 600-840 dp : **OUI** — même rendu que portrait (composants atomiques, pas plein écran).
- Tablet portrait & paysage ≥ 840 dp : **OUI** — `ConstrainedBox(maxWidth: 600 dp)` interne sur `SelectionCard`, `SubSystemHeroCard`, `PhoneInputWithCountryFlag`, `SchoolSearchWithAdd`. `PickerCounterBadge` reste pleine largeur (sticky bar). `CelebrationConfettiSuccess` cercle central 128 dp inchangé, canvas confetti déborde proportionnellement.

**Breakpoints** : seuil unique **840 dp** via `LayoutBuilder` au sein du composant (encapsulé — la page consommatrice n'a pas à gérer). Aucune dépendance à une constante globale `kBreakpointTablet` à ce stade.

**Layout strategy par composant** :

| Composant | Responsive | Layout strategy |
|---|---|---|
| `SelectionCard` | `tablet-adaptive` | `ConstrainedBox(maxWidth: 600 dp)` ≥ 840 dp, centré ; padding constant `AppSpacing.s4` |
| `SubSystemHeroCard` (si créé) | `tablet-adaptive` | Idem `SelectionCard` mais padding `AppSpacing.s5` |
| `PhoneInputWithCountryFlag` | `tablet-adaptive` | `ConstrainedBox(maxWidth: 600 dp)` ≥ 840 dp |
| `SchoolSearchWithAdd` | `tablet-adaptive` | Idem ; results list scroll interne plafonné à 5 items visibles |
| `CelebrationConfettiSuccess` | `phone + tablet` | Cercle 128 dp constant ; canvas confetti `MediaQuery.sizeOf(context)` pleine largeur |
| `PickerCounterBadge` | `phone + tablet` | Pleine largeur (sticky bar) ; padding horizontal `AppSpacing.s4` |

**Goldens à inclure (≥ 1 viewport ≥ 840 dp obligatoire par composant — CLAUDE.md règle 5)** :

- [ ] `SelectionCard` : phone 360×780 + tablet 900×1200 × 3 variants × 2 états = 12 goldens.
- [ ] `SubSystemHeroCard` (si créé séparé) : phone 360×780 + tablet 900×1200 × 2 états = 4 goldens.
- [ ] `PhoneInputWithCountryFlag` : phone 360×780 + tablet 900×1200 × 3 états = 6 goldens.
- [ ] `SchoolSearchWithAdd` : phone 360×780 + tablet 900×1200 × 4 états = 8 goldens.
- [ ] `CelebrationConfettiSuccess` : phone 360×780 + tablet 900×1200 × 2 instants = 4 goldens.
- [ ] `PickerCounterBadge` : phone 360×780 + tablet 900×1200 × 2 états = 4 goldens.

**Acceptance Criteria responsive ajoutée** : voir AC9 et AC10 ci-dessus (chaque composant doit s'afficher correctement en tablet ≥ 840 dp sans gaspillage horizontal — vérifié par golden ≥ 1 viewport tablet).

### Composants réutilisables

**Catalogue consulté** : [`doc/tech/COMPOSANTS-REUTILISABLES.md`](../../doc/tech/COMPOSANTS-REUTILISABLES.md) § « À créer — Refonte Onboarding 10 étapes (Epic E1bis, 2026-06-11) ».

**Composants existants réutilisés** :

- `AppCard` (`lib/core/widgets/app_card.dart`, Story 0.13) — base visuelle interne de `SelectionCard` (rayon, ombre `AppElevation.soft`).
- `AppButton` (`lib/core/widgets/app_button.dart`, Story 0.13) — CTA de `CelebrationConfettiSuccess` (variant primary).
- `AppInput` (`lib/core/widgets/app_input.dart`, Story 0.13) — base interne de `PhoneInputWithCountryFlag` et du champ recherche de `SchoolSearchWithAdd`.
- `AppInlineAlert` (`lib/core/widgets/app_inline_alert.dart`, Story 0.14) — bandeau erreur réseau de `SchoolSearchWithAdd`.
- `AppToast` (`lib/core/widgets/app_toast.dart`, Story 0.14) — NON utilisé directement par les composants (la page consommatrice toaster post-action) ; mentionné pour rappel.
- `Pressable` (`lib/core/widgets/pressable.dart`, Story 0.13) — wrapper interactif avec haptic intégré pour `SelectionCard` et carte « + Ajouter » de `SchoolSearchWithAdd`.

**Composants existants adaptés (paramètre optionnel ajouté)** : Aucun.

**Nouveaux composants créés et ajoutés au catalogue** (cf. AC8) :

1. `SelectionCard` (`lib/core/widgets/cards/selection_card.dart`)
2. `SubSystemHeroCard` (`lib/core/widgets/onboarding/sub_system_hero_card.dart`) — UNIQUEMENT si AC2 décide création séparée ; sinon noté « Skippé — couvert par `SelectionCard.variant=hero` ».
3. `PhoneInputWithCountryFlag` (`lib/core/widgets/forms/phone_input_with_country_flag.dart`)
4. `SchoolSearchWithAdd` (`lib/core/widgets/forms/school_search_with_add.dart`)
5. `CelebrationConfettiSuccess` (`lib/core/widgets/feedback/celebration_confetti_success.dart`)
6. `PickerCounterBadge` (`lib/core/widgets/picker/picker_counter_badge.dart`)

**Vérification anti-duplication** :

- [ ] Aucune classe privée `_XxxBody` reproduisant un composant existant ou un autre composant E1bis-0.
- [ ] `maskPhone()` n'est implémenté qu'à un seul endroit (`log_safe.dart`) ; la méthode statique `PhoneInputWithCountryFlag.maskedForLogs` y délègue.
- [ ] `SubSystemHeroCard` n'existe que si AC2 décide création séparée — sinon usage `SelectionCard.variant=hero`.

### Tests à écrire

- **Unit** :
  - `maskPhone()` : 5 cas (`+237671234567` → masqué / `null` → `'<no-phone>'` / `''` → `'<no-phone>'` / `'+33612345678'` → `'<invalid-phone>'` / `'+2376123'` → `'<invalid-phone>'`).
  - `PhoneInputWithCountryFlag.maskedForLogs` : 2 cas de passthrough (vérifier qu'il appelle bien `maskPhone`).
  - `SelectionCard.tap` → `onTap()` invoqué + `HapticFeedback.selectionClick` (mock).
  - `PickerCounterBadge.isValid` → couleurs correctes via inspection `BoxDecoration`.
- **Widget** :
  - `SchoolSearchWithAdd` : saisie utilisateur → 250 ms attente (`FakeAsync`) → 1 seul appel `searchProvider`.
  - `SchoolSearchWithAdd` : zéro résultat + tap add → `onAddRequest` await + `onSelect(SchoolEntry(isPending: true))`.
  - `SchoolSearchWithAdd` : `AsyncError(networkUnavailable)` → bandeau visible + tap add toujours actif.
  - `CelebrationConfettiSuccess` : `autoDismissDelay` écoulé via `pump(3500ms)` → `onComplete()` invoqué.
  - `CelebrationConfettiSuccess` : `MediaQuery.disableAnimations = true` → `find.byType(ConfettiWidget)` absent.
- **Golden tests** : cf. tableau AC9 / Stratégie responsive — total estimé **38 goldens** si `SubSystemHeroCard` séparé, **34 goldens** si fusionné.

### Anti-patterns à éviter

- ❌ Re-créer une logique de masquage téléphone dans un widget data layer (toujours passer par `maskPhone` du helper canonique).
- ❌ Importer `flutter_riverpod` dans un composant `core/widgets/` (AC4 — searchProvider injecté).
- ❌ Importer `cloud_firestore`, `firebase_auth` ou `dart:io` dans un composant `core/widgets/` (CLAUDE.md règle 1).
- ❌ Logger directement le `value: String` du téléphone (toujours `maskPhone(value)`).
- ❌ Pixels hardcodés (`12`, `48`, `360`) sans `.w` / `.h` / `.sp` / `.r` `flutter_screenutil` (CLAUDE.md règle 7).
- ❌ Couleurs hardcodées (`Color(0xFF2563EB)`) au lieu de `AppColors.primary` (CLAUDE.md tokens).
- ❌ Golden test phone seulement (story renvoyée — CLAUDE.md règle 5).
- ❌ Dupliquer le pattern `LayoutBuilder + ConstrainedBox(maxWidth: 600 dp)` 4 fois (encapsuler dans une méthode `_tabletConstrained(Widget child)` privée par fichier si utilisée 2+ fois — pas d'utility partagée à ce stade).
- ❌ Mettre `confetti` package à un niveau global sans mesurer l'impact APK (T1 mesure).
- ❌ Ouvrir une 2e PR (E1bis-1) avant que celle-ci soit mergée (CLAUDE.md règle 6).

### Références

- Epic source : [`project_manage/planning-artifacts/epics/epic-1bis-refonte-onboarding.md`](../planning-artifacts/epics/epic-1bis-refonte-onboarding.md) § « Story E1bis-0 »
- UX visuel : [`project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/DESIGN.md`](../planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/DESIGN.md) § « Composants Onboarding (refonte 2026-06-11) »
- UX comportement : [`project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/EXPERIENCE.md`](../planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/EXPERIENCE.md) § « Flow 1 » + § « Multisensoriel » (AC5) + § « Microcopie onboarding » (fixtures goldens)
- Décisions : [`project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/.decision-log.md`](../planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/.decision-log.md) § Update 3 (D-UX-Update-15 phone masking / D-UX-Update-17 école skip / D-UX-Update-20 catalogue)
- Catalogue cible : [`doc/tech/COMPOSANTS-REUTILISABLES.md`](../../doc/tech/COMPOSANTS-REUTILISABLES.md) § « À créer — Refonte Onboarding 10 étapes »
- Template React référence : [`doc/templates/src/components/OnboardingFlow.tsx`](../../doc/templates/src/components/OnboardingFlow.tsx)
- Story canonique précédente (format + tests pattern) : [`project_manage/implementation-artifacts/1-18-refactor-extractif-body-composants-reutilisables.md`](./1-18-refactor-extractif-body-composants-reutilisables.md)
- Composants atomiques de base : [`mobile_app/lib/core/widgets/`](../../mobile_app/lib/core/widgets/) (`app_card.dart`, `app_button.dart`, `app_input.dart`, `app_inline_alert.dart`, `pressable.dart`)
- Tokens : [`mobile_app/lib/core/theme/tokens.dart`](../../mobile_app/lib/core/theme/tokens.dart)

---

## Definition of Done

- [ ] **Code** :
  - [ ] 5 ou 6 composants créés (selon décision AC2) + helper `maskPhone` dans les paths spécifiés.
  - [ ] Aucun composant > 500 lignes (cible ≤ 300). Si dépassement → extraction documentée en Completion Notes.
  - [ ] Aucune occurrence `filiere` / `niveau` / `serie` / `matiere` dans les fichiers de la story (grep — règle 5).
  - [ ] Aucune occurrence `cloud_firestore` / `firebase_auth` / `dart:io` dans `lib/core/widgets/**` (règle 1).
  - [ ] Tous les pixels et couleurs passent par `tokens.dart` et `flutter_screenutil` (règles 7).
- [ ] **Tests** :
  - [ ] `flutter test` vert (incl. 34-38 goldens phone + tablet).
  - [ ] Goldens régénérés (`--update-goldens`) + commit séparé pour faciliter la review (binaire isolé).
  - [ ] Test `maskPhone()` 5 cas + test passthrough `PhoneInputWithCountryFlag.maskedForLogs`.
  - [ ] Test `MediaQuery.disableAnimations` masque confetti dans `CelebrationConfettiSuccess`.
- [ ] **Doc** :
  - [ ] `doc/tech/COMPOSANTS-REUTILISABLES.md` mis à jour (entrées déplacées vers Catalogue actuel + Historique daté + PR cité).
  - [ ] Catalogue : décision AC2 documentée (fusion vs création séparée de `SubSystemHeroCard`).
- [ ] **Build** :
  - [ ] `flutter analyze` propre.
  - [ ] Mesurer impact APK release Android avec `confetti` package : `cd mobile_app && flutter build apk --release --analyze-size` → noter delta vs baseline en Completion Notes. Si > +200 KB, basculer fallback `CustomPaint` documenté en sous-tâche T7.
- [ ] **PR** :
  - [ ] Branche `feat/1bis-0-foundation-widgets`.
  - [ ] PR description : récap 6 composants + lien catalogue + récap goldens + delta APK.
  - [ ] Diff ≤ 400 lignes utile (les goldens binaires ne comptent pas — règle 6).
  - [ ] **Ne pas pousser E1bis-1 avant confirmation merge de cette PR** (CLAUDE.md règle 6 — séquencement strict).

---

## Dev Agent Record

### Agent Model Used

`<À remplir au démarrage de /bmad-dev-story>`

### Debug Log References

### Completion Notes List

- [ ] Décision AC2 : `SubSystemHeroCard` fusionné dans `SelectionCard.variant=hero` OU créé séparé — justification.
- [ ] Mesure APK delta package `confetti` : `+XXX KB`. Si > 200 KB → fallback `CustomPaint` activé ? OUI / NON.
- [ ] APIs `AudioService` + `HapticService` Story 0.14 confirmées avec signatures attendues OU adaptées (écart noté ici).
- [ ] Nombre total de goldens produits : XX (cible 34-38).
- [ ] Fichiers > 300 lignes (cible plafond 500) : liste + justification éventuelle.

### File List

`<À remplir : tous les fichiers créés / modifiés par la story>`
