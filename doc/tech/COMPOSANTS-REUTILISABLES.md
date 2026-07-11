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

### SelectionCard

**Path** : `lib/core/widgets/cards/selection_card.dart`
**Story d'origine** : Story 1bis.0 (Foundation widgets onboarding — Epic E1bis)
**Catégorie** : `card`
**Responsive** : `tablet-adaptive` (LayoutBuilder + ConstrainedBox(maxWidth: 600 dp) ≥ 840 dp, centré)

**Quand l'utiliser** :

- Tous les pickers d'option unique du flow onboarding refonte E1bis : step 0 sub-system (variant `hero`), step 2 track, step 3 level, step 4 cards séries / spécialités TVE, step 8 résultats école.
- Pattern : icône optionnelle + titre + description optionnelle + radio indicateur droit + selected ring 2px primary + scale 1.01.
- Couvre 3 tailles via `variant` : `compact` (40×40 icon, 15 sp title, padding s3), `standard` (48×48, 17 sp, padding s4), `hero` (56×56, 18 sp, padding s5).

**Props (API publique)** :

- `title: String` — Texte H4 affiché.
- `selected: bool` — État sélection (contrôlé par le parent).
- `onTap: VoidCallback` — Callback déclenché au tap (haptic `selection` automatique via Pressable).
- `icon: Widget?` — Icône optionnelle (Lucide ou Material). Sans icône, la carte n'affiche pas le cercle gauche.
- `description: String?` — Description courte sous le titre (12 sp / 600 weight).
- `variant: SelectionCardVariant = standard` — Enum {compact, standard, hero}.

**Décision E1bis-0 AC2** : `SubSystemHeroCard` du catalogue v1 a été fusionné dans `SelectionCard(variant: hero)` (les specs DESIGN.md ne différaient que sur padding +4 dp et taille d'icône +8 dp, paramètres déjà portés par la variant).

**Exemple** :

```dart
SelectionCard(
  title: l10n.onboardingSubSystemFrancophone,
  description: l10n.onboardingSubSystemFrancophoneDesc,
  selected: state.subSystem == SubSystem.francophone,
  onTap: () => notifier.setSubSystem(SubSystem.francophone),
  icon: const Icon(LucideIcons.map),
  variant: SelectionCardVariant.hero,
)
```

**Tests associés** :

- `test/core/widgets/cards/selection_card_test.dart` — 7 interactions (tap, bordure selected/unselected, sans icône, description rendue/null, tablet ConstrainedBox actif) + 12 goldens (3 variants × 2 form factors × 2 états).

---

### PickerCounterBadge

**Path** : `lib/core/widgets/picker/picker_counter_badge.dart`
**Story d'origine** : Story 1bis.0 (Foundation widgets onboarding — Epic E1bis)
**Catégorie** : `picker`
**Responsive** : `phone + tablet` (sticky top, padding horizontal adapté)

**Quand l'utiliser** :

- Indicateur de progression compteur dans les pickers checkbox multi-sélection.
- Step 4 onboarding (modes `free_with_obligatory` / `series_plus_optional` / `tve_picker`).
- Pattern : label gauche (texte localisé) + badge droit « X / Y » avec couleurs conditionnelles warning-soft / success-soft selon `isValid`.

**Props (API publique)** :

- `currentCount: int` — Nombre courant (affiché dans le badge).
- `min: int` — Seuil minimum (informationnel, le parent calcule isValid).
- `max: int` — Seuil maximum (affiché dans le badge "X / max").
- `labelText: String` — Texte gauche pré-formaté FR/EN par le caller (pas d'i18n interne).
- `isValid: bool` — Calculé par le caller. Si true → bg `successSoft` + label `successInk` + icône Check. Si false → bg `warningSoft` + label `warningInk` + pas d'icône.

**Comportement** :

- Transition couleur 300 ms `AppMotion.standardOut` entre les états valid / invalid.
- Sticky : la responsabilité de wrapper dans `SliverPersistentHeader` ou `SliverAppBar` revient au parent.

**Exemple** :

```dart
SliverPersistentHeader(
  pinned: true,
  delegate: _CounterDelegate(
    child: PickerCounterBadge(
      currentCount: state.pickedSubjects.length,
      min: 6,
      max: 11,
      labelText: l10n.onboardingPickerCounterLive(state.pickedSubjects.length, 11),
      isValid: state.pickedSubjects.length >= 6 &&
               state.pickedSubjects.length <= 11,
    ),
  ),
)
```

**Tests associés** :

- `test/core/widgets/picker/picker_counter_badge_test.dart` — 3 interactions (couleurs isValid true/false + labelText passthrough) + 4 goldens (phone + tablet × 2 états).

---

### PhoneInputWithCountryFlag

**Path** : `lib/core/widgets/forms/phone_input_with_country_flag.dart`
**Story d'origine** : Story 1bis.0 (Foundation widgets onboarding — Epic E1bis)
**Catégorie** : `form`
**Responsive** : `phone + tablet` (hauteur 56 dp fixe, largeur fluide)

**Quand l'utiliser** :

- Step 7 onboarding (capture numéro Cameroun).
- Tout futur écran qui demande un numéro CM (recovery profil, paramètres, KYC paiement).
- Pattern : drapeau CM (CustomPaint tricolore + étoile) + indicatif `+237` figé + champ numérique avec mask logique 9 chiffres.

**Props (API publique)** :

- `value: String` — Valeur courante au format E.164 (`+237XXXXXXXXX`) ou vide.
- `onChanged: ValueChanged<String>` — Callback à chaque modification, valeur au format E.164.
- `errorText: String?` — Message d'erreur affiché sous le champ + bordure danger.
- `enabled: bool = true` — Désactivation (opacity 0.5, clavier non focus).
- `autofocus: bool = false` — Focus automatique au render.

**Méthode statique sécurité (CLAUDE.md règle 4)** :

- `static String maskedForLogs(String? e164)` — Helper à utiliser dans tout `AppLogger.x('phone=$maskedForLogs(value)')`. Délègue à [`log_safe.dart`](../../mobile_app/lib/core/logging/log_safe.dart) `maskPhone()` — **algorithme unique, zéro duplication**.

**Comportement non négociable** :

- Le composant **n'expose AUCUN log AppLogger** — il n'a aucune dépendance sur `package:logger`.
- Tout caller qui veut loguer le numéro passe par `maskPhone(value)` OU `PhoneInputWithCountryFlag.maskedForLogs(value)`.
- Filtrage `FilteringTextInputFormatter.digitsOnly` + `LengthLimitingTextInputFormatter(9)` — lettres et caractères supprimés à la saisie.

**Exemple** :

```dart
PhoneInputWithCountryFlag(
  value: state.phoneNumber,
  onChanged: (e164) {
    notifier.setPhoneNumber(e164);
    AppLogger.info('phone_changed phone=${PhoneInputWithCountryFlag.maskedForLogs(e164)}');
  },
  errorText: state.phoneError,
  autofocus: true,
)
```

**Tests associés** :

- `test/core/widgets/forms/phone_input_with_country_flag_test.dart` — 6 interactions (saisie → E.164, vide → '', lettres filtrées, errorText + bordure danger, +237 prefix, maskedForLogs delegation) + 6 goldens (phone + tablet × 3 états : empty / filled / error).
- `test/core/logging/log_safe_test.dart` — 10 tests `maskPhone()` (valide mobile/fixe, null, vide, format invalide, longueur invalide, caractères non-digits, sans prefix +, 3ème digit invalide, préservation 4 derniers digits).

---

### SchoolEntry + SchoolSearchWithAdd

**Path composant** : `lib/core/widgets/forms/school_search_with_add.dart`
**Path modèle** : `lib/core/widgets/forms/school_entry.dart` (record léger immutable)
**Story d'origine** : Story 1bis.0 (Foundation widgets onboarding — Epic E1bis)
**Catégorie** : `form`
**Responsive** : `tablet-adaptive` (consomme `SelectionCard` qui plafonne à 600 dp)

**Quand l'utiliser** :

- Step 8 onboarding (recherche école + fallback ajout custom).
- Profil édition école future (E1bis-8).
- Pattern : champ recherche avec icône Search + clear button + suggestions liste `SelectionCard` + carte « + Ajouter "<saisie>" » border-dashed si zéro résultat + bandeau warning `AppInlineAlert` si erreur réseau.

**Props (API publique)** :

- `selectedSchool: SchoolEntry?` — État courant (`SchoolEntry(id, name, isPending)`).
- `onSelect: void Function(SchoolEntry)` — Callback sélection résultat OU ajout custom (avec `isPending: true`).
- `onAddRequest: Future<String> Function(String name)` — Callback création request, retourne `pendingRequestId` (`school_requests/{autoId}`).
- `searchProvider: SchoolSearchAsync Function(String query)` — Source des suggestions, retourne sealed-like {idle, loading, data, error}. **Injecté par la page consommatrice** — composant pur, pas de lecture Firestore directe.
- `placeholder: String` — Texte d'aide (ARB localisé).
- `emptyAddTemplate: String` — Template `+ Ajouter "{name}"` ({name} remplacé par la saisie).
- `warningOfflineMessage: String` — Texte du bandeau erreur réseau (ARB localisé).

**Comportement** :

- Debounce 250 ms sur la saisie avant déclenchement `searchProvider`.
- Suggestions rendues comme `SelectionCard(variant: standard)`.
- Zéro résultat + saisie non-vide → carte « + Ajouter "..." » (border-dashed primary, `DottedBorderBox` interne CustomPaint).
- Tap « + Ajouter » → spinner inline + `await onAddRequest(saisie)` → `onSelect(SchoolEntry(id: pendingId, isPending: true))`.
- `SchoolSearchError(isNetwork: true)` → bandeau warning `AppInlineAlert` + carte ajouter toujours disponible.

**Exemple** :

```dart
final asyncSchools = ref.watch(schoolsSearchProvider(_query));

SchoolSearchWithAdd(
  selectedSchool: state.school,
  onSelect: (s) => notifier.setSchool(s),
  onAddRequest: (name) => ref.read(schoolRequestsRepoProvider).create(name),
  searchProvider: (q) => asyncSchools.when(
    data: (list) => SchoolSearchAsync.data(list),
    loading: () => SchoolSearchAsync.loading(),
    error: (e, _) => SchoolSearchAsync.error(isNetwork: e is NetworkFailure),
  ),
  placeholder: l10n.onboardingSchoolSearchPlaceholder,
  emptyAddTemplate: l10n.onboardingSchoolAddTemplate,
  warningOfflineMessage: l10n.errorNetworkUnavailable,
)
```

**Tests associés** :

- `test/core/widgets/forms/school_search_with_add_test.dart` — 4 interactions (debounce 250 ms 1 seul appel, tap résultat → onSelect, tap add → onAddRequest + onSelect pending, error réseau → bandeau + add dispo) + 8 goldens (phone + tablet × 4 états : empty / typing / no_results / error).

---

### CelebrationConfettiSuccess

**Path** : `lib/core/widgets/feedback/celebration_confetti_success.dart`
**Story d'origine** : Story 1bis.0 (Foundation widgets onboarding — Epic E1bis)
**Catégorie** : `feedback`
**Responsive** : `phone + tablet` (cercle central 128 dp constant, canvas confetti pleine largeur)

**Quand l'utiliser** :

- Step 9 onboarding success (variant `success` par défaut).
- Tout futur écran de célébration majeure (mention BAC obtenue, abonnement premium activé, niveau gamification débloqué).
- Pattern : cercle central 128×128 avec halo glow + checkmark + 2 ConfettiWidget (left/right blast 45°/135°) + titre H2 + sous-titre + CTA primary.

**Props (API publique)** :

- `title: String` — Titre H2 sous le cercle.
- `subtitle: String` — Sous-titre body inkSoft.
- `ctaLabel: String` — Texte du bouton primary.
- `onComplete: VoidCallback` — Appelé au tap CTA OU après `autoDismissDelay`.
- `autoDismissDelay: Duration? = const Duration(milliseconds: 3500)` — Délai avant onComplete auto (null pour désactiver).
- `variant: CelebrationVariant = success` — Enum {success vert, brand bleu, warning ambre}.

**Comportement multisensoriel** :

- Anim entrée : spring 600 ms delay 100 ms sur cercle (`flutter_animate`).
- Confetti : 2.5 s de génération, 4 particules/frame, 2 origines (left/right blast 45°/135°), couleurs `[primary, success, warning, sky]`.
- Audio : `AppSfx.bloom` à T+200 ms via `audioServiceProvider` (Riverpod).
- Haptic : séquence `success` (light + 100 ms + medium) via `hapticServiceProvider` (Riverpod).

**Coupures globales** (CLAUDE.md règle 1) :

- `MediaQuery.disableAnimationsOf == true` → pas de `ConfettiWidget` rendu + halo/titre/sous-titre rendus directement (sans `.animate()`).
- `AudioService.silent == true` → délégué service (pas de son).
- `HapticService.disabled == true` → délégué service (pas de vibration).

**Exemple** :

```dart
CelebrationConfettiSuccess(
  title: l10n.onboardingSuccessTitle(displayName: profile.displayName ?? 'élève'),
  subtitle: l10n.onboardingSuccessSubtitle,
  ctaLabel: profile.isAnonymous
      ? l10n.onboardingSuccessExploreCta
      : l10n.onboardingSuccessEnterCta,
  onComplete: () => context.go('/dashboard'),
)
```

**Package** : `confetti: ^0.8.0` (ajouté pubspec Story 1bis.0). Pas de fallback `CustomPaint` activé — mesurer impact APK en E1bis-7 avant prod.

**Tests associés** :

- `test/core/widgets/feedback/celebration_confetti_success_test.dart` — 5 interactions (tap CTA → onComplete, autoDismissDelay → onComplete, disableAnimations → ConfettiWidget absent / présent ×2, variant brand → bg primarySoft) + 4 goldens (phone + tablet × 2 instants).

---

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

### ProfileSetupSheet

**Path** : `lib/features/dashboard/presentation/widgets/profile_setup_sheet.dart`
**Story d'origine** : Dashboard — complétion profil post-linking Google/Apple
**Catégorie** : `form`
**Responsive** : `phone + tablet` (ConstrainedBox maxWidth 560.w centré via Center)

**Quand l'utiliser** :
- Après linking Google/Apple (via CompleteProfileDialog) si displayName est absent.
- Collecte nom pré-rempli + téléphone optionnel en une seule étape.

**Props (API publique)** :
- `initialDisplayName: String` — Nom initial (vide si absent, pré-rempli si fourni par Google/Apple).

**Exemple** :
```dart
ProfileSetupSheet.show(context, displayName: authDisplayName);
```

**Tests associés** :
- Aucun test widget — à ajouter dans une story dédiée.

---

## À créer — Refonte Onboarding 10 étapes (Epic E1bis, 2026-06-11)

> **Statut Story E1bis-0 (2026-06-11)** : ✅ Livrée. Les 6 composants prévus ont été créés et déplacés dans [§ Catalogue actuel](#catalogue-actuel) ci-dessus. **Décision AC2** : `SubSystemHeroCard` a été **fusionné dans `SelectionCard` via `variant: SelectionCardVariant.hero`** (specs DESIGN.md des deux composants ne différaient que sur padding +4 dp et taille d'icône +8 dp — paramètres déjà portés par la variant). 5 composants effectifs au catalogue + helper `maskPhone()` + `SchoolEntry` record.
>
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

### OnboardingCtaFooter

**Path** : `lib/core/widgets/onboarding/onboarding_cta_footer.dart`
**Story d'origine** : E1bis-2 — extrait pour les pages onboarding refonte (E1bis-2 à E1bis-7)
**Catégorie** : `onboarding`
**Responsive** : `phone + tablet` (composant pur — la page gère la contrainte de largeur)

**Quand l'utiliser** :
- Footer CTA sticky bas de tout écran du flow onboarding refonte (steps 0 à 9).
- Pose en `Scaffold.bottomNavigationBar` pour rester ancré bas avec safe area.

**Props** :
- `label: String` — Texte du CTA, déjà localisé par le caller.
- `onPressed: VoidCallback?` — `null` = bouton disabled (visuel + non interactif).
- `secondaryAction: Widget?` — Action secondaire optionnelle rendue AU-DESSUS du CTA (ex. `TextButton("Passer pour l'instant")` aux steps 7 / 8).

**Comportement** :
- Compose `AppButton.primary` (Story 0.13) en pleine largeur via `SizedBox(width: double.infinity)`.
- `BoxShadow` doux vers le haut (`Offset(0, -4)`, blur 12) + bg `AppColors.bg` pour démarquer du contenu scrollable.
- `SafeArea(top: false)` interne — protège uniquement le bord inférieur (notch / home indicator iOS).
- Pas de Riverpod, pas d'i18n interne.

**Exemple** :

```dart
Scaffold(
  body: SingleChildScrollView(...),
  bottomNavigationBar: OnboardingCtaFooter(
    label: l10n.onboardingContinue,
    onPressed: state.subSystem != null ? notifier.next : null,
    secondaryAction: TextButton(
      onPressed: notifier.skipPhone,
      child: const Text('Passer pour l\'instant'),
    ),
  ),
)
```

**Tests** :
- `test/core/widgets/onboarding/onboarding_cta_footer_test.dart` — 3 interactions (tap propage callback, `onPressed: null` → AppButton disabled, secondaryAction rendu au-dessus du CTA) + 3 goldens phone (enabled / disabled / avec secondaryAction).

---

### MainShell

**Path** : `lib/features/dashboard/presentation/_main_shell.dart`
**Story d'origine** : E1bis-7 — shell de navigation persistent (StatefulShellRoute)
**Catégorie** : `navigation`
**Responsive** : `phone + tablet` — hauteur nav bar 64 dp fixe en raw dp (pas de ScreenUtil)

**Quand l'utiliser** :
- Shell unique de toute l'app post-onboarding. Wrappé par `StatefulShellRoute.indexedStack` dans `app_router.dart`.
- Ne pas instancier directement — go_router passe `navigationShell` automatiquement.

**Props** :
- `navigationShell: StatefulNavigationShell` — fourni par go_router, expose `currentIndex` et `goBranch()`.

**Comportement** :
- Un seul `Scaffold` pour les 4 branches (Accueil / Cours / Examen / Profil). Seul le `body` change entre onglets — pas d'animation de page (`goBranch` remplace `context.go`).
- Re-tap onglet actif → `goBranch(i, initialLocation: true)` remonte à la racine de la branche.
- `_StyledNavBar` privé : `Row` de 4 `Expanded(InkWell)` + `AnimatedContainer` pill état sélectionné + `Text` label 11 dp.
- **Zéro ScreenUtil** — toutes les dimensions sont en dp bruts (`SizedBox(height: 64)`, `Icon(size: 22)`, `fontSize: 11`, `EdgeInsets` constants) pour éviter le scaling dans les tests et sur tablette.
- `SafeArea(top: false, bottom: false)` interne — `Scaffold.bottomNavigationBar` gère déjà l'inset bas.

**Tests** :
- Couvert par `test/widget_test.dart` (nav bar rendue avec 4 destinations) et `test/features/splash/splash_page_test.dart` (navigation post-splash).

---

### PlaceholderTabPage

**Path** : `lib/features/dashboard/presentation/placeholder_tab_page.dart`
**Story d'origine** : Story 1.9 — onglets dashboard non encore implémentés
**Catégorie** : `navigation`
**Responsive** : `phone + tablet` (contenu centré, pas de contrainte de largeur spécifique)

**Quand l'utiliser** :
- Placeholder pour un onglet du dashboard non encore livré (Matières, Activités).
- Vit à l'intérieur de `MainShell` via `StatefulShellRoute` — n'a pas de `NavigationBar` propre.

**Props** :
- `title: String` — Titre de l'`AppBar` (déjà localisé par l'appelant via `l10n`).
- `tabIndex: int` — Index dans la nav bar (non utilisé visuellement ; réservé pour analytics futures).

**Comportement** :
- `Scaffold` avec `AppBar` (titre) + body centré `Text(l10n.comingSoon)` ("Bientôt disponible" / "Coming soon").
- Pas de Riverpod, pas de state.

**Tests** :
- `test/features/dashboard/presentation/placeholder_tab_page_test.dart` — (a) titre AppBar + texte "Bientôt disponible", (b) page seule sans nav bar propre (nav bar dans `MainShell`).

---

### SocialButton

**Path** : `lib/core/widgets/auth/social_auth_widgets.dart`
**Story d'origine** : E1bis-4 (extrait de `auth_choice_step_body.dart` — chore R4 2026-06-17)
**Catégorie** : `auth`
**Responsive** : `phone + tablet` (hauteur fixe 56.h screenutil, pleine largeur)

**Quand l'utiliser** :

- Bouton social branded (Google, Apple) dans les flows d'authentification.
- Auth choice step body (step 5 onboarding) et tout futur écran de connexion.

**Props (API publique)** :

- `label: String` — Texte affiché.
- `iconWidget: Widget` — Logo brand (ex. `GoogleBrandIcon()`, `AppleBrandIcon()`).
- `loading: bool` — Si true, remplace l'icône par un `CircularProgressIndicator`.
- `onPressed: VoidCallback?` — null = bouton désactivé.
- `backgroundColor: Color` — Fond du bouton.
- `foregroundColor: Color` — Couleur texte + spinner.
- `border: BoxBorder?` — Bordure optionnelle (null = pas de bordure).

**Exemple** :

```dart
SocialButton(
  label: l10n.onboardingAuthGoogleLabel,
  iconWidget: const GoogleBrandIcon(),
  loading: linkState is AccountLinkingLoading,
  onPressed: linkingNotifier.linkGoogle,
  backgroundColor: AppColors.card,
  foregroundColor: AppColors.ink,
  border: Border.all(color: AppColors.border, width: 1),
)
```

**Tests associés** : aucun dédié (couvert par `auth_choice_step_body_test.dart`).

---

### AuthErrorBanner

**Path** : `lib/core/widgets/auth/social_auth_widgets.dart`
**Story d'origine** : E1bis-4 (extrait de `auth_choice_step_body.dart` — chore R4 2026-06-17)
**Catégorie** : `feedback`
**Responsive** : `phone + tablet` (pleine largeur, texte multi-ligne)

**Quand l'utiliser** :

- Bannière d'erreur inline dismissible dans les flows d'authentification.
- Distingue erreurs réseau, erreurs provider, erreurs flush visiteur.

**Props (API publique)** :

- `message: String` — Message d'erreur localisé.
- `onDismiss: VoidCallback` — Fermeture de la bannière (remonte l'action au parent).

**Exemple** :

```dart
AuthErrorBanner(
  message: l10n.errorNetworkUnavailable,
  onDismiss: () => setState(() => _guestError = null),
)
```

**Tests associés** : aucun dédié (couvert par `auth_choice_step_body_test.dart`).

---

### Famille StreamSubjectsPicker (picker étape 4)

> Widgets extraits de `stream_subjects_picker_step_body.dart` (1 245 → 438 L, -65%) lors du chore R4 2026-06-17. **Feature-specific** au step 4 onboarding — pas conçus pour réutilisation hors de ce contexte. Documentés ici pour visibilité catalogue (CLAUDE.md règle 11).

**Path** : `lib/features/onboarding/presentation/widgets/picker/`
**Story d'origine** : E1bis-3 (extrait — chore R4 2026-06-17)
**Catégorie** : `picker`
**Responsive** : `phone + tablet` (Wrap chips, full-width CTA)

| Fichier | Composants publics | Rôle |
|---|---|---|
| `stream_picker_chips.dart` | `SubjectCounterBadge`, `SectionLabel`, `ToggleChip`, `SubjectSummaryChip` | Chips atomiques du picker matières |
| `stream_picker_recap.dart` | `RecapBanner`, `RecapCell` | Banner recap parcours (Section/Filière/Niveau/Série) |
| `stream_picker_selector.dart` | `StreamPicker`, `StreamPickerEmpty` | Liste cards séries + fallback vide catalogue |
| `stream_picker_derived_view.dart` | `DerivedPreview` | Vue read-only modes derived + tvePicker |
| `stream_picker_interactive.dart` | `InteractiveSubjectPicker` | Vue interactive modes optOut + freeWithObligatory + seriesPlusOptional |
| `stream_picker_recap_helper.dart` | `buildRecapEntries()` | Fonction pure : construit les entrées recap depuis `OnboardingState` + `DerivedProfile` |

**Tests associés** : aucun dédié (couvert par intégration `stream_subjects_picker_step_body.dart`).

---

### ContentErrorView

**Path** : `lib/core/widgets/errors/content_error_view.dart`
**Story d'origine** : 2.4 (Intégration Firestore contenu pédagogique)
**Catégorie** : `feedback`
**Responsive** : `phone + tablet` (centré verticalement, padding horizontal `AppSpacing.s6.w`)

**Quand l'utiliser** :

- Toute page de contenu pédagogique (SubjectDetailPage, ChapterPage, LessonPage) qui consomme un `FutureProvider` Firestore et doit afficher un état erreur.
- Remplace l'affichage générique `AsyncValue.when(error:...)` par un message localisé + bouton retry.
- Ne pas utiliser hors des pages de contenu (`lib/features/content/`) : pour les erreurs onboarding, utiliser `AuthErrorBanner` ou `AppToast`.

**Props (API publique)** :

- `error: Object` — erreur provenant de `AsyncValue.when(error: (e, _) => ...)`. Si `ContentFailure`, le message est adapté au `ContentFailureKind`.
- `onRetry: VoidCallback` — callback appelé par le bouton « Réessayer » (typiquement `ref.invalidate(provider)`).

**Mapping erreur → message ARB** :

| `ContentFailureKind` | Clé ARB | Message FR |
|---|---|---|
| `networkUnavailable` | `errorNetworkUnavailable` | « Pas de connexion. Vérifie ton réseau et réessaie. » |
| `permissionDenied` | `errorPermissionDenied` | « Session expirée. Re-lance l'app pour rafraîchir. » |
| `notFound` / `unknown` / autre | `errorFirestoreUnknown` | « Erreur technique. Réessaie dans un instant. » |

**Exemple** :

```dart
chaptersAsync.when(
  loading: () => _SkeletonChapterList(),
  error: (error, _) => ContentErrorView(
    error: error,
    onRetry: () => ref.invalidate(chaptersForSubjectProvider(subjectId)),
  ),
  data: (chapters) => _ChapterList(chapters: chapters),
)
```

**Tests associés** :

- `test/features/content/presentation/content_pages_test.dart` — test T10.1 « error networkUnavailable : message réseau + bouton Réessayer » (couverture intégration dans SubjectDetailPage).

---

### Famille Dashboard cards (sections du dashboard home)

> Widgets créés en Story 2.3 (Dashboard home enrichi — données hardcodées). **Feature-specific** au dashboard — pas conçus pour réutilisation hors de ce contexte. Documentés ici pour visibilité catalogue (CLAUDE.md règle 11).
>
> **Note Phase 2** : les props `Fake*` sont temporaires (Story 2.3 = UI hardcodée). Stories 2.x suivantes remplaceront par des providers Riverpod réels. Lors de ce remplacement, l'API des widgets sera mise à jour ici.

**Path** : `lib/features/dashboard/presentation/widgets/`
**Story d'origine** : 2.3 (Dashboard home enrichi — données hardcodées)
**Catégorie** : `card`
**Responsive** : `phone + tablet` (pleine largeur dans `SingleChildScrollView` + `ConstrainedBox(maxWidth: 700)` sur tablet ≥ 840 dp — géré par `DashboardPage`, pas les widgets eux-mêmes)

| Fichier | Composant public | Rôle |
|---|---|---|
| `dashboard_daily_goal_card.dart` | `DashboardDailyGoalCard` | Objectif du jour : barre progression + tâche courante + CTA primary |
| `dashboard_recent_history_card.dart` | `DashboardRecentHistoryCard` | Dernière activité : icône matière + nom leçon + badge score coloré |
| `dashboard_recommended_card.dart` | `DashboardRecommendedCard` | Recommandation IA : titre + tag IA + 2 CTA (leçon / quiz) |
| `dashboard_leaderboard_card.dart` | `DashboardLeaderboardCard` | Classement : rang matière + gain hebdomadaire |

**Props clés** :

- `DashboardDailyGoalCard(goal: FakeDailyGoal, languageCode: String, onTap: VoidCallback)`
- `DashboardRecentHistoryCard(entry: FakeHistoryEntry, languageCode: String)`
- `DashboardRecommendedCard(rec: FakeRecommendation, languageCode: String, onLesson: VoidCallback, onQuiz: VoidCallback)`
- `DashboardLeaderboardCard(entry: FakeLeaderboardEntry, languageCode: String)`

**Tests associés** : goldens `test/features/dashboard/presentation/goldens/dashboard_home_phone.png` et `dashboard_home_tablet.png` (couverts par `dashboard_home_goldens_test.dart` — T11 Story 2.3).

### Famille Profile sheets (édition profil depuis l'onglet Profil)

> Widgets créés en Story A.1 (Édition profil utilisateur — nom, téléphone, école). **Feature-specific** au dashboard — pas conçus pour réutilisation hors de ce contexte en V1. Si réutilisés dans une autre feature, extraire vers `core/widgets/` + documenter en paramètres génériques.

**Path** : `lib/features/dashboard/presentation/widgets/`
**Story d'origine** : A.1 (Édition du profil utilisateur — nom, téléphone et école)
**Catégorie** : `form`
**Responsive** : `phone + tablet` (`ConstrainedBox(maxWidth: 560.w)` + `Center` sur tablet ≥ 840 dp — géré en interne par chaque sheet)

| Fichier | Composant public | Rôle |
|---|---|---|
| `profile_edit_sheet.dart` | `ProfileEditSheet` | Bottom sheet édition `displayName` + `phoneNumber` — validation inline + appel repo séquentiel |
| `school_edit_sheet.dart` | `SchoolEditSheet` | Bottom sheet changement d'école — `SchoolSearchWithAdd` + bouton "Retirer" conditionnel |

**API statique (factory show)** :

```dart
// Ouvre le sheet depuis n'importe quel BuildContext
ProfileEditSheet.show(context, displayName: 'Fatou', phoneNumber: '+237671234567');
SchoolEditSheet.show(context, schoolId: 'sch_001', schoolName: 'LYCÉE GÉNÉRAL LECLERC');
```

**Props `ProfileEditSheet`** :

- `initialDisplayName: String` — valeur pré-remplie dans le champ nom.
- `initialPhoneNumber: String?` — valeur pré-remplie dans le champ téléphone (vide si null).

**Props `SchoolEditSheet`** :

- `initialSchoolId: String?` — null si pas d'école liée (masque le bouton "Retirer").
- `initialSchoolName: String?` — nom affiché dans les résultats préchargés.

**Contraintes non négociables** :

- Consomment `userProfileRepositoryProvider` (Riverpod) directement — ne pas passer le repo en paramètre.
- `SchoolEditSheet` appelle `schoolSearchNotifierProvider.notifier.preload(limit: 300)` dans `initState`.
- Log du `phoneNumber` **obligatoirement** via `maskPhone()` (`core/logging/log_safe.dart`) — jamais le numéro brut.
- Padding keyboard : `EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom)`.

**Tests associés** :

- `test/features/dashboard/presentation/widgets/profile_edit_sheet_test.dart` — 3 widget tests (pré-remplissage, validation courte, succès + drain AppToast timer).
- `test/features/dashboard/presentation/profile_tab_goldens_test.dart` — 2 goldens : `profile_tab_phone.png` (375×812) + `profile_tab_tablet.png` (820×1180).

---

### Famille School Profile Edit (édition profil scolaire — Story A.3)

> Widget créé en Story A.3. **Feature-specific** dashboard — consomme `catalogueProvider` (en mémoire) + `userProfileRepositoryProvider`. Multi-étapes via `PageController` interne.

**Path** : `lib/features/dashboard/presentation/widgets/school_profile_edit_sheet.dart`
**Story d'origine** : A.3 (Édition profil scolaire classe → spécialité → matières)
**Catégorie** : `interaction`
**Responsive** : `phone + tablet` (`Center + ConstrainedBox(maxWidth: 560.w)` ; grille niveaux : `LayoutBuilder` 2 cols phone / 3 cols tablet ≥ 840 dp)

| Fichier | Composant public | Rôle |
|---|---|---|
| `school_profile_edit_sheet.dart` | `SchoolProfileEditSheet` | Bottom sheet 3 étapes (niveau grid → série list → matières chips). Factory `.show()` statique. |

**Props `SchoolProfileEditSheet`** :

| Prop | Type | Description |
|---|---|---|
| `subSystem` | `String` | Identifiant sous-système (immutable, pour filtrer niveaux). Ex: `'francophone'` |
| `trackId` | `String` | Identifiant filière (immutable). Ex: `'generale'` |
| `initialLevelId` | `String` | Niveau actuel pré-sélectionné. Ex: `'francophone_terminale'` |
| `initialStreamId` | `String` | Série actuelle pré-sélectionnée. Ex: `'francophone_terminale_d'` |
| `initialPickedSubjectIds` | `List<String>` | Matières actuellement sélectionnées (intersection conservée si compatible). |

**Exemple d'usage** :

```dart
SchoolProfileEditSheet.show(
  context,
  subSystem: 'francophone',
  trackId: 'generale',
  levelId: 'francophone_terminale',
  streamId: 'francophone_terminale_d',
  pickedSubjectIds: ['math', 'physique', 'svt'],
);
```

**Contraintes non négociables** :

- Consomme `catalogueProvider` (déjà chargé au boot — 0 read Firestore supplémentaire).
- Auto-skip étape série si 1 seule série disponible pour le niveau sélectionné.
- Dérivation `DerivedProfile` 100% en mémoire depuis `CatalogueSnapshot`.
- Fermeture via `Navigator.of(context, rootNavigator: true).maybePop()` (AppBottomSheet useRootNavigator: true).
- Obligatoires (`obligatorySubjects`) toujours inclus dans `pickedSubjects` — non décochables.
- `subSystem` et `trackId` immutables : le picker ne permet pas de les changer.

**Tests associés** :

- `test/features/dashboard/presentation/widgets/school_profile_edit_sheet_test.dart` — widget tests (step navigation, auto-skip, save + toast).
- Goldens : `school_profile_edit_phone.png` (375×812) + `school_profile_edit_tablet.png` (768×1024).

---

### SubjectProgressListCard

**Path** : `lib/core/widgets/cards/subject_progress_list_card.dart`
**Story d'origine** : Extrait de `features/dashboard/presentation/widgets/exams_subject_card.dart` (Story 2.5 — unification tabs Cours / Examens, 2026-07-11)
**Catégorie** : `card`
**Responsive** : `phone-only` (contrat existant — Row + Expanded, s'étend naturellement à tablette via padding parent)

**Quand l'utiliser** :

- Toute liste verticale de matières avec progression : tab **Cours** (chapitres terminés / total), tab **Examens** (exercices faits / total), et futures listes analytiques par matière (résultats, historique).
- Card horizontale : icône colorée (palette `subjectColorAt(index)`) + libellé matière + compteur textuel + barre de progression + chevron droit.
- Palette partagée avec la grille (via `lib/core/widgets/cards/subject_palette.dart`).

**Props (API publique)** :

- `subject: Subject` — Matière catalogue (name, abbreviation, icon).
- `index: int` — Index dans la liste, sert à choisir la couleur cyclique (`subjectColorAt`).
- `langKey: String` — Code langue courant (`fr` / `en`) pour résoudre nom + abréviation.
- `progressLabel: String` — Libellé compteur **déjà localisé** par le caller (ex. `l10n.coursesChaptersOf(3, 12)` ou `l10n.examsExercisesOf(6, 18)`).
- `progressValue: double` — Progression 0..1 pour la `LinearProgressIndicator`.
- `onTap: VoidCallback` — Callback tap (typiquement `context.push(AppRoutes.subject(...))`).

**Décision de design** : le libellé du compteur est passé en `String` prêt-à-afficher (pas `done`/`total` bruts) pour que le composant reste agnostique du domaine consommateur (chapitres, exercices, quiz, etc.) et de la logique de pluralisation ICU.

**Exemple** :

```dart
SubjectProgressListCard(
  subject: subjects[i],
  index: i,
  langKey: 'fr',
  progressLabel: l10n.coursesChaptersOf(done, total),
  progressValue: done / total,
  onTap: () => context.push(AppRoutes.subject(subjects[i].subjectId)),
)
```

**Tests associés** :

- À couvrir en Story 2.6+ (dette : goldens phone + tablet, tap → navigation).

---

### Famille Public Profile (profil public d'un pair — Story A.2)

> Widgets créés en Story A.2 (Profil public). **Feature-specific** à la feature `account` — consomment `PublicProfile` (domain entity) et `catalogueProvider`. Pas conçus pour réutilisation hors de ce contexte en V1.

**Path** : `lib/features/account/presentation/widgets/`
**Story d'origine** : A.2 (Page profil public utilisateur)
**Catégorie** : `display`
**Responsive** : `phone + tablet` (LayoutBuilder dans `PublicProfilePage` : hPad = `(width - 560) / 2` sur tablet ≥ 600 dp)

| Fichier | Composant public | Rôle |
|---|---|---|
| `public_profile_header.dart` | `PublicProfileHeader` | En-tête gradient primary→primaryDark — avatar initiales 80×80 + displayName + classLabel + schoolName optionnel |
| `public_profile_stats_section.dart` | `PublicProfileStatsSection` | Section stats hardcodées MVP — 2 badges leçons lues + quiz réussis |

**Props `PublicProfileHeader`** :

- `profile: PublicProfile` — entité domaine avec uid, displayName, levelId, streamId, schoolName, subSystem.
- `classLabel: String?` — label résolu par le parent depuis le catalogue (ex. « Terminale D »). Null → section omise.

**Props `PublicProfileStatsSection`** :

- `l10n: AppLocalizations` — labels traduits (Stats, leçons lues, quiz réussis).

**Contraintes** :

- `PublicProfileHeader` ne lit jamais le repo directement — données passées par le parent (`PublicProfilePage`).
- Champs sensibles (`phoneNumber`, `examTargets`, `pickedSubjects`) jamais transmis ni affichés.
- Stats hardcodées MVP (`30` leçons, `3` quiz) — remplacer par un provider réel en Story Epic 3+.

**Tests associés** :

- `test/features/account/data/user_profile_repository_public_profile_test.dart` — 4 tests unitaires `fetchPublicProfile`.
- `test/features/account/presentation/public_profile_page_test.dart` — 3 tests widget.
- `test/features/account/presentation/__goldens__/public_profile_page_phone.png` + `public_profile_page_tablet.png`.

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
| 2026-06-17 | Ajout `MainShell` + `PlaceholderTabPage` au catalogue actuel (navigation shell dashboard). Suppression doublons "à créer" `PhoneInputWithCountryFlag` et `SchoolSearchWithAdd` (composants livrés en Story 1bis-0, entrées planning devenues obsolètes). Aucune modification code. | fix/onboarding-tests | Amelia |
| 2026-06-11 | Story 1bis-0 livrée — 5 nouveaux composants au [Catalogue actuel](#catalogue-actuel) : `SelectionCard` (variant `hero` absorbe `SubSystemHeroCard` cf. décision AC2), `PickerCounterBadge`, `PhoneInputWithCountryFlag` (+ helper `maskPhone()` dans `lib/core/logging/log_safe.dart` + méthode statique passthrough `maskedForLogs`), `SchoolSearchWithAdd` (+ record `SchoolEntry`), `CelebrationConfettiSuccess` (package `confetti: ^0.8.0`). Tests : 38 goldens phone+tablet + 10 tests `maskPhone` + interactions par composant (7 + 3 + 6 + 4 + 5). `flutter analyze` 0 issue. Package `golden_toolkit: ^0.15.0` ajouté en dev_dependency (discontinued mais fonctionnel ; alternative future possible). Test setup pattern : `tester.view.physicalSize + devicePixelRatio = 1.0` AVANT `pumpWidget` pour que MediaQuery + ScreenUtilInit voient la viewportSize correcte (sinon ScreenUtil scale ×2.22 sur surface 800×600 default). | feat/1bis-0-foundation-widgets | Amelia |
| 2026-06-11 | Story 1bis-2 livrée — 1 nouveau composant au [Catalogue actuel](#catalogue-actuel) : `OnboardingCtaFooter` (footer CTA sticky bas avec safe area + secondary action optionnelle + shadow doux top). Réutilisé par les pages onboarding refonte E1bis-2 à E1bis-7. Tests : 3 goldens phone (enabled / disabled / avec secondaryAction) + 3 interactions. `_FeatureCard` reste widget privé dans `hero_intro_page.dart` (décision : pas réutilisé hors de cette page tant que `HeroIntroPage` reste seule à le consommer ; extraction au catalogue si besoin futur). | feat/1bis-2-pages-sub-system-hero | Amelia |
| 2026-06-11 | Story 1bis-2bis livrée — refactor structure PR #103 incorrecte (3 `Scaffold` autonomes + 2 routes parallèles) en vrai shell partagé : `OnboardingShell` devient UN SEUL `Scaffold` + `AnimatedSwitcher` slide+fade 300 ms + header partagé (`_OnboardingHeader` visible si `configStepsActive`) + footer partagé (`OnboardingCtaFooter` en `bottomNavigationBar` dispatched par `currentStep`). `SubSystemChoicePageV2` → `SubSystemStepBody`, `HeroIntroPage` → `HeroIntroStepBody` (widgets bodies purs sans Scaffold). 1 route unique `/onboarding/v2`. Le composant `OnboardingCtaFooter` lui-même est inchangé, sa composition migre des pages individuelles vers le shell. Pattern foundational pour E1bis-3 à E1bis-7 qui réutiliseront le shell sans dupliquer le footer. | feat/1bis-2bis-refactor-shell-slides | Amelia |
| 2026-06-12 | Story 1bis-3 livrée — 3 step bodies (`TrackChoiceStepBody`, `LevelChoiceStepBody`, `StreamSubjectsPickerStepBody` 5 modes) consument les composants Story 1.18 (`PickerSectionScaffold`, `Obligatory/OptionalSubjectCheckboxList`, `PickerValidateBar`) et `SelectionCard` (E1bis-0). Aucun nouveau composant catalogue ajouté — pur consume + extension `OnboardingShell.\_bodyForStep` cases 2/3/4. Nouveau provider `derivedProfileV2Provider` dans `state/onboarding_providers.dart` qui dérive depuis le state `OnboardingNotifier` (vs `derivedProfileProvider` legacy qui lit `onboardingFlowProvider` Epic 1). Dettes documentées : goldens 3 step bodies + tests interactions par body + sélecteur série multi pour optOut/seriesPlusOptional → story dédiée E1bis-3b. | feat/1bis-3-pages-track-level-stream-subjects | Amelia |
| 2026-06-17 | Chore R4 — Correction violations taille fichiers (CLAUDE.md règle 12) : `stream_subjects_picker_step_body.dart` 1 245 → 438 L (-65%), `auth_choice_step_body.dart` 530 → 426 L (-20%), `onboarding_notifier.dart` 544 → 477 L (-12%). 8 nouveaux fichiers créés : `stream_picker_chips.dart`, `stream_picker_recap.dart`, `stream_picker_selector.dart`, `stream_picker_derived_view.dart`, `stream_picker_interactive.dart`, `stream_picker_recap_helper.dart`, `social_auth_widgets.dart`, `onboarding_hydration.dart`. Fix bonus : `_buildContent(state: dynamic)` → `OnboardingState` (type safety). | feat/onboarding-step4-recap-cta-margin | Amelia |
| 2026-06-23 | Story 2.3 livrée — section « Famille Dashboard cards » ajoutée au Catalogue actuel : 4 composants feature-specific (`DashboardDailyGoalCard`, `DashboardRecentHistoryCard`, `DashboardRecommendedCard`, `DashboardLeaderboardCard`). Données temporaires `Fake*` — seront remplacées par providers Riverpod réels en Stories 2.x suivantes. Goldens T11 générés : phone 375×812 + tablet 768×1024. | feat/2-2-subject-navigation-ui | Amelia |
| 2026-06-23 | Story 2.4 livrée — ajout `ContentErrorView` au Catalogue actuel. Widget d'erreur centré pour les pages contenu Firestore : message localisé selon `ContentFailureKind` + bouton retry. Couvert par test intégration T10.1 dans `content_pages_test.dart`. | feat/2-2-subject-navigation-ui | Amelia |
| 2026-06-24 | Story A.1 livrée — section « Famille Profile sheets » ajoutée au Catalogue actuel : 2 composants feature-specific (`ProfileEditSheet`, `SchoolEditSheet`) dans `features/dashboard/presentation/widgets/`. Consomment `userProfileRepositoryProvider` + `schoolSearchNotifierProvider`. Factory `.show()` statique. Responsive tablette via `ConstrainedBox(maxWidth: 560.w)`. 3 widget tests + 2 goldens profil phone+tablet. | feat/2-2-subject-navigation-ui | Amelia |
| 2026-06-24 | Story A.2 livrée — section « Famille Public Profile » ajoutée au Catalogue actuel : 2 composants feature-specific (`PublicProfileHeader`, `PublicProfileStatsSection`) dans `features/account/presentation/widgets/`. Firestore rule `users/{uid}` élargie à `request.auth != null` (A.2-DR-01). Route `/user/:uid` hors shell. `_ClassmateRow` rendu tappable dans `home_tab_page.dart`. 4 tests unitaires + 3 tests widget + 2 goldens phone+tablet. | feat/A-2-public-profile | Amelia |
| 2026-07-11 | Unification tabs Cours / Examens — `SubjectProgressListCard` ajouté au Catalogue actuel (extrait de `exams_subject_card.dart`, désormais supprimé). Palette matière déplacée dans `lib/core/widgets/cards/subject_palette.dart` (partagée). Tab Cours passe d'une grille 2 colonnes (`SubjectGridCard` supprimé) à une liste verticale identique à la tab Examens. Nouveau banner `CoursesTermBanner` (calqué sur `ExamsCountdownBanner`, gradient bleu + CTA « Voir le programme ») remplace `CoursesRecommendationBanner` (supprimé). Données mock — chapitres terminés/total sur les cartes, progression trimestre dans le banner — à brancher sur Firestore en Story 2.x. | chore/tab-cours-alignement-examens | Amelia |
