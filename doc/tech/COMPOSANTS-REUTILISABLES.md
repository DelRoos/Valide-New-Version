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

Périmètre Story 1.18 : extraire les 4 widgets privés `_LegacyOptOutBody`, `_FreeWithObligatoryBody`, `_SeriesPlusOptionalBody`, `_TvePickerBody` de `mobile_app/lib/features/onboarding/presentation/subjects_picker_page.dart` (1297 lignes) en **composants partagés** réutilisables.

### Composants candidats à extraire

| Composant cible | Path cible | Source actuelle | Présent dans |
|---|---|---|---|
| `PickerSectionCard(title, subtitle?, child)` | `lib/core/widgets/picker/picker_section_card.dart` | wrapper section reconstruit 4× dans chaque `_Body` | `subjects_picker_page.dart` lignes ~250-280, ~520-550, ~750-780, ~1000-1030 |
| `ObligatorySubjectChipList(subjects, locked: true)` | `lib/core/widgets/picker/obligatory_subject_chip_list.dart` | chips lockées reconstruites 4× | `subjects_picker_page.dart` lignes ~300, ~570, ~800, ~1050 |
| `OptionalSubjectChipGrid(subjects, picked, onToggle, max?, dangerBannerOnOverpick: true)` | `lib/core/widgets/picker/optional_subject_chip_grid.dart` | grille toggleable + danger banner reconstruite 3× (1.4, 1.15, 1.16) | `subjects_picker_page.dart` lignes ~350, ~620, ~850 |
| `PickerValidateBar(picked, total, onValidate, isValid)` | `lib/core/widgets/picker/picker_validate_bar.dart` | bar CTA reconstruite 4× | `subjects_picker_page.dart` lignes ~430, ~700, ~930, ~1180 |
| `PickerToastFeedback(message)` | `lib/core/widgets/feedback/picker_toast_feedback.dart` | pattern toast locked-out dupliqué | `subjects_picker_page.dart` lignes ~140-160 (helper privé) + handlers dans chaque `_Body` |

### Objectifs de l'extraction

1. **Tests Stories 1.4 / 1.15 / 1.16 / 1.17 : 100% préservés.** Le refactor ne doit casser aucun test existant (236 baseline post-1.17).
2. **Réduction `subjects_picker_page.dart` de ~1297 lignes à ≤ ~500 lignes** (l'orchestrateur + le `switch (pickerMode)` + assemblage de composants).
3. **Tests unitaires nouveaux** : 1 test par composant extrait avec golden test ≥ 1 breakpoint tablet (CLAUDE.md règle 5).
4. **Documentation catalogue alimentée** : chaque composant extrait reçoit son entrée dans la section [Catalogue actuel](#catalogue-actuel) ci-dessus.
5. **Audit responsive screens existants (A7)** : `subjects_picker`, `school_picker`, `dashboard_placeholder` reçoivent un `LayoutBuilder` + golden test baseline tablet pendant le refactor.

### Composants Story 1.7 à auditer pour réutilisation

Le `school_picker_page.dart` (Story 1.7) contient sans doute des widgets équivalents (chips matières → chips écoles, validate bar, etc.). Lors de Story 1.18, vérifier si les composants à extraire de `subjects_picker_page.dart` peuvent **également** servir le `school_picker_page.dart` (chips de résultats de recherche école, par exemple).

---

## Historique

| Date | Action | Story / PR | Auteur |
|---|---|---|---|
| 2026-06-10 | Création du catalogue (PR discipline composants + responsive) — squelette + section dette Epic 1 v2 | PR discipline-composants-responsive | Amelia |
