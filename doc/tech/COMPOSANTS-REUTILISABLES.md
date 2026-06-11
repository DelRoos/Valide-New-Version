# Catalogue des composants Flutter réutilisables — Valide School

> **Règle non négociable** (CLAUDE.md règle 11) : avant d'écrire le moindre widget Flutter dans `lib/features/**/presentation/` ou `lib/core/widgets/`, consulter ce catalogue. Si un composant existant fait déjà le job (ou peut être adapté via un paramètre optionnel), le réutiliser. Sinon, créer + documenter ici dans la même PR.

---

## Sommaire

- [Workflow d'utilisation](#workflow-dutilisation)
- [Format d'entrée](#format-dentrée)
- [Catalogue actuel](#catalogue-actuel)
- [À extraire — dette Epic 1 v2](#à-extraire--dette-epic-1-v2)
- [Historique](#historique)

---

## Workflow d'utilisation

### Avant de coder un widget

1. **Chercher** dans la section [Catalogue actuel](#catalogue-actuel) un composant qui ressemble à ce que tu veux faire (par nom, par contexte d'usage, par story d'origine).
2. **Si trouvé** : le réutiliser directement, OU si une adaptation mineure est nécessaire, ajouter un **paramètre optionnel** au composant existant (jamais dupliquer). Cas frontière : si l'adaptation change la logique fondamentale (≠ visuel), créer un composant frère distinct dans le même dossier.
3. **Si pas trouvé** :
   - Décider du nom (anglais, PascalCase, descriptif fonctionnellement — pas par feature). Ex. ✅ `ObligatorySubjectChipList`, ❌ `PickerBodyForFatou`.
   - Décider du path : `lib/core/widgets/{semantic_subfolder}/{component_name}.dart`. Sous-dossiers sémantiques actuels : `picker/`, `cards/`, `forms/`, `feedback/`, `layout/`.
   - Implémenter le composant.
   - **Ajouter une entrée** dans [Catalogue actuel](#catalogue-actuel) dans la même PR (CLAUDE.md règle 11 : pas de widget réutilisable sans entrée catalogue = PR renvoyée).
   - Si responsive sensitive (chips, grilles, cartes redimensionnables), mentionner le comportement responsive dans l'entrée + ajouter ≥ 1 golden test breakpoint tablet (CLAUDE.md règle 5).

### Pendant la revue de PR

- Le reviewer vérifie que chaque nouveau widget réutilisable est documenté ici.
- Le reviewer vérifie que les widgets existants utilisés sont bien cités dans les Dev Notes de la story (preuve de consultation du catalogue).

### Quand un composant est extrait du code existant (refactor type Story 1.18)

- Déplacer le composant vers `lib/core/widgets/{semantic}/`.
- Ajouter l'entrée catalogue avec la mention « Extrait de : `<path origine>` (Story `<X.Y>`) ».
- Supprimer la version dupliquée du fichier d'origine.
- Préserver les tests : ajouter un test unitaire dédié au composant extrait + conserver les tests d'intégration du fichier d'origine.

---

## Format d'entrée

Chaque composant est documenté ainsi :

````markdown
### ComponentName

**Path** : `lib/core/widgets/{subfolder}/{file}.dart`
**Story d'origine** : `<X.Y>` (ou « Extrait de `<path>` (Story `<X.Y>`) » si refactor)
**Catégorie** : `picker` / `card` / `form` / `feedback` / `layout`
**Responsive** : `phone-only` / `phone + tablet` / `tablet-adaptive`

**Quand l'utiliser** :
- Cas d'usage 1
- Cas d'usage 2

**Props (API publique)** :
- `propName: Type` — description courte (obligatoire ou défaut)
- `optionalProp: Type?` — description (paramètre d'adaptation)

**Exemple** :
```dart
ComponentName(
  propName: ...,
  optionalProp: ...,
)
```

**Tests associés** :
- `mobile_app/test/.../component_name_test.dart` (unit + ≥ 1 golden test si responsive sensitive)
````

---

## Catalogue actuel

### PickerSectionScaffold

**Path** : `lib/core/widgets/picker/picker_section_scaffold.dart`
**Story d'origine** : Extrait de `lib/features/onboarding/presentation/subjects_picker_page.dart` (Story 1.18 — résorption dette Epic 1 v2 A5)
**Catégorie** : `picker`
**Responsive** : `phone + tablet` (LayoutBuilder + ConstrainedBox(maxWidth: 720) au-dessus de 840 dp)

**Quand l'utiliser** :
- Page de sélection de items (pickers : matières, écoles, séries) avec titre H2 + sous-titre + body scrollable + footer fixe.
- Wrapper structurel : la responsabilité du contenu interne (body + footer) reste à l'appelant.

**Props (API publique)** :
- `title: String` — Texte H2 affiché en tête de page.
- `subtitle: String?` — Texte body inkSoft optionnel sous le titre.
- `child: Widget` — Contenu après les titres (typiquement `Column([Expanded(ListView), SizedBox, PickerValidateBar])`). Le composant l'enveloppe dans un `Expanded` pour gérer le scroll.
- `tabletBreakpoint: double = 840` — Seuil d'activation de la contrainte maxWidth.
- `tabletMaxWidth: double = 720` — Largeur max appliquée au-dessus du breakpoint.

**Exemple** :
```dart
PickerSectionScaffold(
  title: l10n.onboardingPickerTitle,
  subtitle: l10n.onboardingPickerSubtitle,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(child: ListView(children: [...])),
      SizedBox(height: AppSpacing.s4.h),
      PickerValidateBar(...),
    ],
  ),
)
```

**Tests associés** :
- `test/core/widgets/picker/picker_section_scaffold_test.dart` (rendu phone + tablet + sans subtitle + ConstrainedBox 720dp en tablet).

---

### ObligatorySubjectCheckboxList

**Path** : `lib/core/widgets/picker/obligatory_subject_checkbox_list.dart`
**Story d'origine** : Extrait de `lib/features/onboarding/presentation/subjects_picker_page.dart` (Story 1.18 — résorption dette Epic 1 v2 A5)
**Catégorie** : `picker`
**Responsive** : `phone + tablet` (hauteur dynamique via shrinkWrap inside ListView parent)

**Quand l'utiliser** :
- Liste verticale de matières obligatoires verrouillées (cadenas + cochées en permanence).
- Tap sur une matière obligatoire déclenche `onTapBlocked` (typiquement un toast warning + log).
- Stories 1.15 / 1.16 / 1.17 (3 sections obligatoires + sous-section "Other" TVE).

**Props (API publique)** :
- `subjects: List<Subject>` — Matières à afficher comme obligatoires.
- `langKey: String` — Code langue ("fr" ou "en"). Fallback : fr puis subjectId.
- `isSaving: bool` — Si true, onChanged null (CheckboxListTile désactivé).
- `onTapBlocked: void Function(String subjectId)` — Callback déclenché quand l'utilisateur tente de décocher.

**Exemple** :
```dart
ObligatorySubjectCheckboxList(
  subjects: profile.obligatorySubjects,
  langKey: subSystem.languageCode,
  isSaving: _isSaving,
  onTapBlocked: _onTapObligatory,
)
```

**Tests associés** :
- `test/core/widgets/picker/obligatory_subject_checkbox_list_test.dart` (rendu + cadenas + tap + isSaving + langKey fr/en + tablet 900x1200).

---

### OptionalSubjectCheckboxList

**Path** : `lib/core/widgets/picker/optional_subject_checkbox_list.dart`
**Story d'origine** : Extrait de `lib/features/onboarding/presentation/subjects_picker_page.dart` (Story 1.18 — résorption dette Epic 1 v2 A5)
**Catégorie** : `picker`
**Responsive** : `phone + tablet` (paramètre `shrinkWrap` configurable selon contexte parent)

**Quand l'utiliser** :
- Liste verticale de matières optionnelles interactives (checkbox toggleable).
- Cas legacy opt-out (Story 1.4 — `shrinkWrap: false`, dans un `Expanded` direct).
- Cas pickers v2/v3 (Stories 1.15/1.16/1.17 — `shrinkWrap: true`, imbriqué dans un ListView parent multi-sections).

**Props (API publique)** :
- `subjects: List<Subject>` — Matières à afficher.
- `picked: Set<String>` — IDs actuellement cochés.
- `onToggle: void Function(String subjectId, bool selected)` — Callback toggle.
- `langKey: String` — Code langue ("fr" / "en"). Fallback fr puis subjectId.
- `isSaving: bool` — Si true, onChanged null.
- `iconResolver: IconData Function(String iconName)` — Resolver d'icône par nom Lucide (injecté pour éviter dépendance core → feature ; passer `subjectIconFor` côté onboarding).
- `shrinkWrap: bool = true` — Si true (défaut), la liste calcule sa hauteur (sub-section dans outer ListView). Si false, scroll interne (wrap dans Expanded direct).

**Exemple** :
```dart
// Sub-section (mode 1.15/1.16/1.17) :
OptionalSubjectCheckboxList(
  subjects: profile.optionalSubjects,
  picked: _pickedOptional!,
  onToggle: _onToggleOptional,
  langKey: 'en',
  isSaving: _isSaving,
  iconResolver: subjectIconFor,
)

// Standalone (mode 1.4 legacy opt-out) :
Expanded(
  child: OptionalSubjectCheckboxList(
    subjects: profile.subjects,
    picked: picked,
    onToggle: _onToggleOptOut,
    langKey: 'en',
    isSaving: _isSaving,
    iconResolver: subjectIconFor,
    shrinkWrap: false,
  ),
)
```

**Tests associés** :
- `test/core/widgets/picker/optional_subject_checkbox_list_test.dart` (picked toggle state + tap + isSaving + iconResolver + tablet 900x1200).

---

### PickerValidateBar

**Path** : `lib/core/widgets/picker/picker_validate_bar.dart`
**Story d'origine** : Extrait de `lib/features/onboarding/presentation/subjects_picker_page.dart` (Story 1.18 — résorption dette Epic 1 v2 A5)
**Catégorie** : `picker`
**Responsive** : `phone + tablet` (layout vertical fluide)

**Quand l'utiliser** :
- Footer de page picker : compteur + 2 boutons (Valider + Retour).
- Couleur conditionnelle compteur : primary si valide, danger sinon.
- Stories 1.4 (compteur taking/total), 1.15/1.16/1.17 (compteur live X/N).

**Props (API publique)** :
- `counterText: String` — Texte compteur pré-formaté par l'appelant (ARB key conditionnelle).
- `isValid: bool` — Contrôle la couleur (primary/danger) et l'activation du bouton primary.
- `isSaving: bool` — Si true : bouton primary en loading, secondary désactivé.
- `onValidate: VoidCallback?` — Callback primary (sera ignoré si !isValid).
- `onCancel: VoidCallback` — Callback secondary (retour écran précédent).
- `validateLabel: String` — Label primary (ex. l10n.onboardingPickerValidateCta).
- `cancelLabel: String` — Label secondary (ex. l10n.back).

**Exemple** :
```dart
PickerValidateBar(
  counterText: l10n.onboardingPickerCounterLive(pickedTotal, max),
  isValid: isWithinBounds,
  isSaving: _isSaving,
  onValidate: () => _onValidatePicked(profile),
  onCancel: () => GoRouter.of(context).go('/onboarding/profile/recap'),
  validateLabel: l10n.onboardingPickerValidateCta,
  cancelLabel: l10n.back,
)
```

**Tests associés** :
- `test/core/widgets/picker/picker_validate_bar_test.dart` (isValid primary/danger + tap callbacks + isSaving loading + tablet 900x1200).

---

## À créer — Refonte Onboarding 10 étapes (Epic E1bis, 2026-06-11)

> Composants à créer dans le cadre de la refonte intégrale du flow pré-dashboard (cf. [`.decision-log.md` D-UX-Update-20](../../project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/.decision-log.md) + [DESIGN.md § Composants Onboarding](../../project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/DESIGN.md)). Source de vérité du flow : `doc/templates/src/components/OnboardingFlow.tsx`. À déplacer dans § Catalogue actuel au fur et à mesure de leur création en story E1bis.

### SubSystemHeroCard *(à créer)*

**Path cible** : `lib/core/widgets/onboarding/sub_system_hero_card.dart`
**Story d'origine** : E1bis — refonte onboarding (à découper via `/bmad-create-story`)
**Catégorie** : `card`
**Responsive** : `phone + tablet` (largeur max 600 dp ≥ 840 dp, centrée)

**Quand l'utiliser** :
- Step 0 onboarding : choix Francophone / Anglophone.
- Pattern de carte de choix exclusif large avec radio indicateur droit.

**Props attendues** :
- `title: String`
- `selected: bool`
- `onTap: VoidCallback`
- `icon: IconData?` (optionnel, défaut null pour step 0 ; utilisé `Icons.map` en hero step 0 mais en-dehors de la carte)

**Différenciation vs SelectionCard générique** : SubSystemHeroCard est intentionnellement **plus grande** (padding `{spacing.5}` vs `{spacing.4}`) et **sans description**, car les 2 options sub-system sont primaires et structurantes. Si à la création la différence avec `SelectionCard` est négligeable, **collapser dans SelectionCard** avec un paramètre `variant: SelectionCardVariant.hero` (préféré à dupliquer).

**Tests requis** :
- Golden tests : phone 360x780, phone 412x892, tablet 900x1200 (au moins).
- Test : tap déclenche `onTap` + haptic `selection`.
- Test : selected → ring 2 px primary + scale 1.01 + radio coché.

---

### SelectionCard *(à créer — générique)*

**Path cible** : `lib/core/widgets/cards/selection_card.dart`
**Story d'origine** : E1bis
**Catégorie** : `card`
**Responsive** : `phone + tablet` (largeur max 600 dp ≥ 840 dp, centrée)

**Quand l'utiliser** :
- Tous les pickers d'option unique du flow : steps 0, 2, 3, 4 (cards séries / spécialités TVEE), 8 (résultats école).
- Pattern : icône optionnelle + titre + desc optionnel + radio indicateur droit.

**Props attendues** :
- `title: String`
- `selected: bool`
- `onTap: VoidCallback`
- `icon: Widget?` (optionnel, Lucide ou Material)
- `description: String?` (optionnel — desc 12 px sous le titre)
- `variant: SelectionCardVariant = standard` (enum : `compact` 40x40 icon + 15 px title, `standard` 48x48 icon + 17 px title, `hero` 56x56 icon + 18 px title)

**Différenciation vs `LevelCard` existant Epic 1** : si `LevelCard` peut être généralisé avec un paramètre `variant` couvrant tous les cas, **renommer `LevelCard` en `SelectionCard`** (rename massif avec dépréciation alias) plutôt que créer un nouveau composant. À évaluer dans la story de création.

**Tests requis** :
- Golden tests : 3 variants × 2 form factors min (phone 360x780 + tablet 900x1200) = 6 goldens.
- Test : selected ring + scale + radio coché.
- Test : tap déclenche `onTap` + haptic.
- Test : sans icône → titre aligné à gauche sans gap.
- Test : avec description → 2 lignes alignées.

---

### PhoneInputWithCountryFlag *(à créer)*

**Path cible** : `lib/core/widgets/forms/phone_input_with_country_flag.dart`
**Story d'origine** : E1bis — step 7 phone input
**Catégorie** : `form`
**Responsive** : `phone + tablet` (largeur max 600 dp ≥ 840 dp, centrée)

**Quand l'utiliser** :
- Step 7 onboarding : capture numéro Cameroun.
- Tout futur écran qui demande un numéro CM (recovery profil, paramètres).

**Props attendues** :
- `value: String` — Valeur courante au format E.164 (`+2376XXXXXXXX`) ou vide.
- `onChanged: void Function(String e164Value)` — Callback à chaque changement, valeur en E.164.
- `errorText: String?` — Message d'erreur sous le champ.
- `enabled: bool = true`
- `autofocus: bool = false`

**Comportement non négociable (CLAUDE.md règle 4 sécurité)** :
- Le composant **expose** un getter statique `static String maskedForLogs(String e164)` qui retourne `'+237 XX XX XX 78 90'` (4 derniers digits visibles).
- Tout code appelant qui logue le numéro **DOIT** passer par `maskedForLogs`. Le composant lui-même ne logue jamais via AppLogger.
- Hint validation : regex `^\\+237[26][0-9]{8}$`.

**Tests requis** :
- Golden tests : phone 360x780 + tablet 900x1200 (vide / rempli / erreur).
- Test : tap pavé → keyboard numérique uniquement.
- Test : saisie « 671234567 » → onChanged reçoit « +237671234567 ».
- Test : saisie incomplète → errorText affiché.
- Test : `maskedForLogs('+237671234567')` retourne `'+237 XX XX XX 67'` (ou format défini).

---

### SchoolSearchWithAdd *(à créer)*

**Path cible** : `lib/core/widgets/forms/school_search_with_add.dart`
**Story d'origine** : E1bis — step 8 school search
**Catégorie** : `form`
**Responsive** : `phone + tablet`

**Quand l'utiliser** :
- Step 8 onboarding : recherche école + fallback ajout custom.
- Profil édition école future (re-utilisable).

**Props attendues** :
- `selectedSchool: SchoolEntry?` — État courant (`SchoolEntry(id, name)`).
- `onSelect: void Function(SchoolEntry school)` — Callback sélection résultat.
- `onAddRequest: Future<String> Function(String name)` — Callback création request (retourne `pendingRequestId`).
- `searchProvider: AsyncValue<List<SchoolEntry>> Function(String query)` — Source des suggestions (typiquement un Riverpod provider Firestore).
- `placeholder: String` — ARB key contextuelle (FR/EN).

**Comportement** :
- Debounce 250 ms sur la saisie avant déclenchement `searchProvider`.
- Suggestions rendues comme `SelectionCard` (cf. ci-dessus, variant `standard`).
- Si zéro résultat ET saisie non-vide → carte « + Ajouter "<saisie>" » (style border-dashed primary).
- Tap sur « + Ajouter » → spinner local + `onAddRequest()` → toast succès + propagation `selected` avec `id: pendingRequestId` + flag `isPending: true`.
- Gestion offline : si `searchProvider` retourne `AsyncError(networkUnavailable)` → encadré warning + bouton « + Ajouter » toujours disponible.

**Tests requis** :
- Golden tests : 4 états × 2 form factors = 8 goldens (vide / saisie / résultats / zéro résultat).
- Test : sélection résultat propage `onSelect`.
- Test : zéro résultat + tap ajouter → `onAddRequest` appelé + spinner.
- Test : erreur réseau → encadré warning visible + add button toujours actif.

---

### CelebrationConfettiSuccess *(à créer)*

**Path cible** : `lib/core/widgets/feedback/celebration_confetti_success.dart`
**Story d'origine** : E1bis — step 9 success
**Catégorie** : `feedback`
**Responsive** : `phone + tablet` (cercle central reste 128 px, canvas confetti déborde proportionnellement)

**Quand l'utiliser** :
- Step 9 onboarding success.
- Tout futur écran de célébration majeure (mention BAC obtenue, abonnement premium activé première fois — à évaluer cas par cas).

**Props attendues** :
- `title: String` — Titre H2 affiché sous le cercle.
- `subtitle: String` — Sous-titre body inkSoft.
- `ctaLabel: String` — Texte du bouton primaire.
- `onComplete: VoidCallback` — Appelé au tap CTA OU après autoDismissDelay.
- `autoDismissDelay: Duration = const Duration(milliseconds: 3500)` — Délai avant onComplete auto (null pour désactiver).
- `variant: CelebrationVariant = success` (enum : `success` vert, `brand` bleu, `warning` ambre — pour future réutilisation).

**Comportement** :
- Anim entrée : spring 100 ms delay sur cercle + fade-in titres delay 300/400 ms.
- Confetti : 2.5 s de génération, 4 particules/frame, 2 origines (left/right), couleurs `[#2563EB, #16A34A, #D97706, #0EA5E9]`.
- Audio : `complete.m4a` via AudioService 200 ms après ouverture.
- Haptic : `success` séquence via HapticService.
- Coupures globales (cf. D-UX-Update-3/8) :
  - `MediaQuery.disableAnimations == true` → pas de confetti + spring → fade-in 200 ms statique + checkmark sans anim.
  - `AudioService.silent == true` → pas de son.
  - `HapticService.disabled == true` → pas de vibration.

**Package recommandé** : `confetti` (pub.dev). Évaluer l'impact APK (+200 KB ?) en story d'implémentation ; si trop lourd, implémentation manuelle `CustomPaint` + `AnimationController`.

**Tests requis** :
- Golden tests : phone 360x780 + tablet 900x1200 (état initial + état autoDismiss après 3.5 s).
- Test : tap CTA → onComplete appelé.
- Test : `autoDismissDelay` → onComplete appelé après le délai.
- Test : `MediaQuery.disableAnimations = true` → pas de confetti rendu (vérifier via `find.byType(ConfettiWidget)` absent).
- Test : variants `success` / `brand` / `warning` → couleurs cercle correctes.

---

### PickerCounterBadge *(à créer)*

**Path cible** : `lib/core/widgets/picker/picker_counter_badge.dart`
**Story d'origine** : E1bis — step 4 picker modes `free_with_obligatory` / `series_plus_optional` / `tve_picker`
**Catégorie** : `picker`
**Responsive** : `phone + tablet` (sticky top du scroll body)

**Quand l'utiliser** :
- Indicateur de progression compteur dans les pickers checkbox multi-sélection.
- Remplace l'ancien `_LegacyOptOutBody` compteur inline (Story 1.18 résorbée mais sans extraction du compteur).

**Props attendues** :
- `currentCount: int`
- `min: int`
- `max: int`
- `labelText: String` — ARB key avec interpolation `{n}/{max}` (FR/EN).
- `isValid: bool` — Calculé par le caller (`current ∈ [min, max] ∧ contraintes spécifiques`).

**Comportement** :
- `isValid == false` → background `{colors.warning-soft}` + label `{colors.warning-ink}` + badge droit `{colors.warning-ink}`.
- `isValid == true` → background `{colors.success-soft}` + label `{colors.success-ink}` + badge droit `{colors.success}` + icône `Check` 12 px à droite du compteur.
- Transition couleur : 300 ms ease standardOut.
- Sticky top via `SliverPersistentHeader` ou wrapper `SliverAppBar` selon le parent.

**Tests requis** :
- Golden tests : phone 360x780 + tablet 900x1200 × 2 états (sous min / valide) = 4 goldens.
- Test : isValid → couleurs correctes.
- Test : currentCount change → label texte mis à jour.

---

> **Ordre de création recommandé** (dépendances internes) :
> 1. `SelectionCard` (générique) — utilisé par 3 autres composants.
> 2. `PickerCounterBadge` — indépendant.
> 3. `SubSystemHeroCard` — dépend potentiellement de `SelectionCard` (à voir).
> 4. `PhoneInputWithCountryFlag` — indépendant.
> 5. `SchoolSearchWithAdd` — dépend de `SelectionCard`.
> 6. `CelebrationConfettiSuccess` — indépendant.
>
> Estimation : 1 story dédiée pour les 6 composants (E1bis-0 : foundation widgets onboarding), avec tous les goldens + tests unitaires. Puis stories par page consomment ces composants.

---

## Historique des composants extraits (post-création)

> **✅ Résorbée Story 1.18 (2026-06-10)** — voir [Catalogue actuel](#catalogue-actuel) ci-dessus. Les 4 widgets privés `_LegacyOptOutBody`, `_FreeWithObligatoryBody`, `_SeriesPlusOptionalBody`, `_TvePickerBody` ont été supprimés de `subjects_picker_page.dart` (1309 → 621 lignes, -52%) et remplacés par compositions de 4 composants extraits (`PickerSectionScaffold` + `ObligatorySubjectCheckboxList` + `OptionalSubjectCheckboxList` + `PickerValidateBar`) + un wrapper privé `_PickerStreamGate` qui factorise le StreamBuilder + init state. La 5e candidate `PickerToastFeedback` a été **skippée** (`AppToast` existant Stories 0.14 suffit, pattern déjà unifié dans le source d'origine).

---

## Historique

| Date | Action | Story / PR | Auteur |
|---|---|---|---|
| 2026-06-10 | Création du catalogue (PR discipline composants + responsive) — squelette + section dette Epic 1 v2 | PR discipline-composants-responsive | Amelia |
| 2026-06-10 | Révision 2 section « À extraire — dette Epic 1 v2 » post-discovery code source : renommage `Chip*` → `Checkbox*` (réel = `CheckboxListTile`, pas `Chip`), `PickerSectionCard` → `PickerSectionScaffold` (réel = LayoutBuilder+ConstrainedBox+Padding+Column, pas Card visuel), suppression `PickerToastFeedback` (`AppToast` existant suffit). 5 composants → 4 composants. AC8 audit responsive sur `subjects_picker_page` réduit (LayoutBuilder déjà présent lignes 376/559). | PR docs/1.18-correction-scope | Amelia |
| 2026-06-10 | Story 1.18 livrée — 4 composants extraits ajoutés au [Catalogue actuel](#catalogue-actuel) : `PickerSectionScaffold`, `ObligatorySubjectCheckboxList`, `OptionalSubjectCheckboxList`, `PickerValidateBar`. `subjects_picker_page.dart` réduit 1309 → 621 lignes (-52%) ; 4 ex-`_XxxBody` supprimés. Audit responsive A7 : 2 golden tests tablet 900x1200 ajoutés (`subjects_picker_page` mode opt-out + `school_picker_page`). Placeholders Story 1.9 skippés (transients Epic 2). | PR feat/1-18-refacto | Amelia |
| 2026-06-11 | Ajout section « À créer — Refonte Onboarding 10 étapes (Epic E1bis) » : spécifications de 6 composants à créer pour le flow refonte templates `doc/templates/` (`SubSystemHeroCard`, `SelectionCard` générique, `PhoneInputWithCountryFlag`, `SchoolSearchWithAdd`, `CelebrationConfettiSuccess`, `PickerCounterBadge`). Source : DESIGN.md § Composants Onboarding + EXPERIENCE.md § Flow 1 v3 + decision log D-UX-Update-20. Pas encore de code livré ; les composants seront créés en story E1bis-0 (foundation widgets) avant les pages. | bmad-ux Update 3 (pré-stories E1bis) | Sally |
