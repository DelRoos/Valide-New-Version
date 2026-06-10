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

> **À ce jour (2026-06-10)** : catalogue vide — aucun composant réutilisable n'a encore été extrait. La dette Epic 1 v2 (4 `_Body` dupliqués) sera résorbée en Story 1.18 et alimentera le catalogue.

*Les composants seront ajoutés ici au fur et à mesure de leur extraction (Story 1.18) ou de leur création (stories futures).*

### `<placeholder>` — entrée type

*À remplacer par une vraie entrée lors de la première extraction.*

---

## À extraire — dette Epic 1 v2

Périmètre Story 1.18 (révision 2 post-discovery 2026-06-10) : extraire les 4 widgets privés `_LegacyOptOutBody`, `_FreeWithObligatoryBody`, `_SeriesPlusOptionalBody`, `_TvePickerBody` de `mobile_app/lib/features/onboarding/presentation/subjects_picker_page.dart` (1309 lignes confirmées) en **composants partagés** réutilisables.

### Composants candidats à extraire (révision 2 — noms corrigés)

| Composant cible | Path cible | Source actuelle | Présent dans |
|---|---|---|---|
| `PickerSectionScaffold(title, subtitle?, child)` | `lib/core/widgets/picker/picker_section_scaffold.dart` | wrapper `LayoutBuilder + Center + ConstrainedBox(maxWidth: isTablet ? 720 : ∞) + Padding + Column` reconstruit 4× dans chaque `_Body` (responsive déjà fait — cf. Discovery 2026-06-10) | `subjects_picker_page.dart` lignes 376-395 (`_LegacyOptOutBody`), 559-578 (`_FreeWithObligatoryBody`), équivalent dans `_SeriesPlusOptionalBody` et `_TvePickerBody` |
| `ObligatorySubjectCheckboxList(subjects, langKey, isSaving, onTapBlocked)` | `lib/core/widgets/picker/obligatory_subject_checkbox_list.dart` | `ListView.separated` + `CheckboxListTile(value: true, secondary: Icon(LucideIcons.lock))` reconstruit 3× (1.15, 1.16, 1.17 — pas 1.4 qui n'a pas d'obligatoires) | `subjects_picker_page.dart` lignes 599-629 + équivalents 1.16/1.17 |
| `OptionalSubjectCheckboxList(subjects, picked, onToggle, langKey, isSaving, maxPicks?)` | `lib/core/widgets/picker/optional_subject_checkbox_list.dart` | `ListView.separated` + `CheckboxListTile` interactif reconstruit 4× (1.4 optedOut + 1.15 optionnels + 1.16 transversales + 1.17 sub-loop interactif) | `subjects_picker_page.dart` lignes 405-435, 639+, équivalents 1.16/1.17 |
| `PickerValidateBar(pickedCount, totalCount?, onValidate, onCancel, isValid, isSaving, validateLabel, cancelLabel)` | `lib/core/widgets/picker/picker_validate_bar.dart` | `Row(Icon + Text counter)` + `AppButton.primary(loading: isSaving)` + `AppButton.secondary` reconstruit 4× | `subjects_picker_page.dart` lignes 438-468 + équivalents |
| ~~`PickerToastFeedback`~~ **N/A** | — | Déjà unifié via `AppToast.show(context, message, tone: ToastTone.warning)` existant (ligne 261-265 + équivalents). Pas de duplication réelle. | — |

### Objectifs de l'extraction (révision 2)

1. **Tests Stories 1.4 / 1.15 / 1.16 / 1.17 : 100% préservés.** Le refactor ne doit casser aucun test existant (236 baseline post-1.17).
2. **Réduction `subjects_picker_page.dart` de 1309 lignes à ≤ ~550 lignes** (orchestrateur + `switch (pickerMode)` + assemblage de composants).
3. **Tests unitaires nouveaux** : 1 test par composant extrait avec golden test ≥ 1 breakpoint tablet (CLAUDE.md règle 5).
4. **Documentation catalogue alimentée** : 4 entrées dans la section [Catalogue actuel](#catalogue-actuel) ci-dessus (réduit de 5 à 4 — skip `PickerToastFeedback` car `AppToast` existant suffit).
5. **Audit responsive screens existants (A7)** :
   - `subjects_picker_page` : **partiellement déjà fait** (LayoutBuilder en place lignes 376/559). Reste à ajouter golden test baseline tablet ≥ 840 dp.
   - `school_picker_page` (~428 lignes) : audit complet à faire — vérifier présence/absence `LayoutBuilder` + ajouter si manquant + golden test tablet.
   - `dashboard_page` + `placeholder_tab_page` : audit complet à faire.

### Composants Story 1.7 à auditer pour réutilisation

Le `school_picker_page.dart` (Story 1.7) contient probablement des widgets équivalents (listes résultats recherche école, validate bar). Lors de Story 1.18, vérifier si `OptionalSubjectCheckboxList` (renommé `SelectableItemCheckboxList` si générique) peut servir aussi pour les résultats de recherche école (Epic 1.5 future).

---

## Historique

| Date | Action | Story / PR | Auteur |
|---|---|---|---|
| 2026-06-10 | Création du catalogue (PR discipline composants + responsive) — squelette + section dette Epic 1 v2 | PR discipline-composants-responsive | Amelia |
| 2026-06-10 | Révision 2 section « À extraire — dette Epic 1 v2 » post-discovery code source : renommage `Chip*` → `Checkbox*` (réel = `CheckboxListTile`, pas `Chip`), `PickerSectionCard` → `PickerSectionScaffold` (réel = LayoutBuilder+ConstrainedBox+Padding+Column, pas Card visuel), suppression `PickerToastFeedback` (`AppToast` existant suffit). 5 composants → 4 composants. AC8 audit responsive sur `subjects_picker_page` réduit (LayoutBuilder déjà présent lignes 376/559). | PR docs/1.18-correction-scope | Amelia |
