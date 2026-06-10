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

## À extraire — dette Epic 1 v2

> **✅ Résorbée Story 1.18 (2026-06-10)** — voir [Catalogue actuel](#catalogue-actuel) ci-dessus. Les 4 widgets privés `_LegacyOptOutBody`, `_FreeWithObligatoryBody`, `_SeriesPlusOptionalBody`, `_TvePickerBody` ont été supprimés de `subjects_picker_page.dart` (1309 → 621 lignes, -52%) et remplacés par compositions de 4 composants extraits (`PickerSectionScaffold` + `ObligatorySubjectCheckboxList` + `OptionalSubjectCheckboxList` + `PickerValidateBar`) + un wrapper privé `_PickerStreamGate` qui factorise le StreamBuilder + init state. La 5e candidate `PickerToastFeedback` a été **skippée** (`AppToast` existant Stories 0.14 suffit, pattern déjà unifié dans le source d'origine).

---

## Historique

| Date | Action | Story / PR | Auteur |
|---|---|---|---|
| 2026-06-10 | Création du catalogue (PR discipline composants + responsive) — squelette + section dette Epic 1 v2 | PR discipline-composants-responsive | Amelia |
| 2026-06-10 | Révision 2 section « À extraire — dette Epic 1 v2 » post-discovery code source : renommage `Chip*` → `Checkbox*` (réel = `CheckboxListTile`, pas `Chip`), `PickerSectionCard` → `PickerSectionScaffold` (réel = LayoutBuilder+ConstrainedBox+Padding+Column, pas Card visuel), suppression `PickerToastFeedback` (`AppToast` existant suffit). 5 composants → 4 composants. AC8 audit responsive sur `subjects_picker_page` réduit (LayoutBuilder déjà présent lignes 376/559). | PR docs/1.18-correction-scope | Amelia |
| 2026-06-10 | Story 1.18 livrée — 4 composants extraits ajoutés au [Catalogue actuel](#catalogue-actuel) : `PickerSectionScaffold`, `ObligatorySubjectCheckboxList`, `OptionalSubjectCheckboxList`, `PickerValidateBar`. `subjects_picker_page.dart` réduit 1309 → 621 lignes (-52%) ; 4 ex-`_XxxBody` supprimés. Audit responsive A7 : 2 golden tests tablet 900x1200 ajoutés (`subjects_picker_page` mode opt-out + `school_picker_page`). Placeholders Story 1.9 skippés (transients Epic 2). | PR feat/1-18-refacto | Amelia |
