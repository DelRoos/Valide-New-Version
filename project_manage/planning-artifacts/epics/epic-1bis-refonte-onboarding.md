---
epic: 1bis
title: Refonte intégrale du flow pré-dashboard (templates `doc/templates/`)
phase: P1bis
status: Stories drafted
generatedAt: 2026-06-11
sourceArtifacts:
  - project_manage/planning-artifacts/prds/prd-valide-mvp-2026-06-03/prd.md
  - project_manage/planning-artifacts/architecture/architecture.md
  - project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/DESIGN.md
  - project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/EXPERIENCE.md
  - project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/.decision-log.md
  - doc/templates/src/components/OnboardingFlow.tsx
  - doc/templates/src/data/educationData.ts
  - doc/templates/src/types.ts
  - doc/tech/COMPOSANTS-REUTILISABLES.md
  - doc/partage/BASE-DE-DONNEES.md
  - doc/partage/ALGORITHMES.md
  - doc/partage/DONNEES-REFERENCE.md
storyCount: 10
predecessor: epic-1-onboarding
trigger: "Directive porteur produit 2026-06-11 — Epic 1 livré (Stories 1.1-1.18) mais workflow d'onboarding ne donne pas le ressenti voulu. Templates React/TS fournis comme source de vérité du flow."
---

# Epic 1bis — Refonte intégrale du flow pré-dashboard

## Goal

Reconstruire l'expérience pré-dashboard (10 écrans consolidés) en alignement strict avec les templates `doc/templates/src/components/OnboardingFlow.tsx`, en améliorant le contenu textuel (titres plus courts, sous-titres actionnables, ton bienveillant adapté aux élèves camerounais 12-19 ans, FR + EN), en inversant l'ordre Auth ↔ Onboarding (auth déclenchée step 5 après le picker), en consolidant les 5 modes de picker (`derived` / `series_only` / `free_with_obligatory` / `series_plus_optional` / `tve_picker`) dans une seule page conditionnelle, en réintroduisant la capture du numéro de téléphone Cameroun avec masquage logs strict, et en homogénéisant tous les identifiers code en anglais (`trackId`, `levelId`, `streamId`).

**Critère de sortie d'epic** :

- Les **5 personas** Epic 1 (Fatou Mballa, James Tanyi, Aïssatou Diop, Mariam Bakari, Eyong Eboa) complètent le nouveau flow en < 90 s sur Tecno Spark 8, iPhone SE, Pixel Tablet (portrait + paysage).
- **Tests goldens** passent sur les 4 form factors par page : phone 360×780, phone-landscape 700×400, tablet portrait 800×1280, tablet paysage 1280×800.
- **Identifiers anglais** : aucune occurrence de `filiereId`, `niveauId`, `serieId` dans `lib/features/onboarding/`, `lib/features/auth/`, `lib/features/profile/`.
- **Step 9 success** déclenche confetti + audio `complete.m4a` + haptic `success` + auto-dispatch 3.5 s vers `/dashboard` (couper si `MediaQuery.disableAnimations` / silencieux).
- **Inversion auth** : Firebase Auth + écriture Firestore `users/{uid}` ne se produisent QU'au step 5 ; profil partiel steps 0-4 vit en mémoire (Riverpod) jusqu'à l'auth.
- **Mode visiteur** : `Firebase signInAnonymously()` → écriture profil partiel + skip steps 6-8 → step 9 success simplifié.
- **École optionnelle** : skip autorisé avec micro-friction (toast nudge) ; collection `school_requests` opérationnelle pour les ajouts custom.
- **Téléphone +237** : helper `maskPhone()` garantit qu'aucun log AppLogger n'expose le numéro complet.

**Note non-régression** : les composants existants Story 1.18 (`PickerSectionScaffold`, `ObligatorySubjectCheckboxList`, `OptionalSubjectCheckboxList`, `PickerValidateBar`) sont **réutilisés** dans la nouvelle step 4 — pas de duplication.

## Out of scope (E1bis)

- ❌ **Dashboard** : explicitement EXCLU (directive porteur produit 2026-06-11). Le step 9 navigue vers `/dashboard` mais le dashboard lui-même reste inchangé.
- ❌ **Recommandations, mini-carte rang, santé scolaire** : restent E5.
- ❌ **Navigation matière → chapitre → leçon → notion** : reste E2.
- ❌ **Quiz, Mode 1, Mode 2, paywall, paiement** : restent E3-E4.
- ❌ **Rename dette Epic 1** (filiereId → trackId rétroactif dans le code livré Stories 1.1-1.17) : reste Story 1.19 dédiée. E1bis utilise les identifiers anglais en **nouveau code** uniquement.
- ❌ **Migration des utilisateurs Epic 1 existants** : les profils créés avec `serieId` (ancien schéma) restent valides post-migration. Le code de lecture Firestore traite `serieId` ET `streamId` en lecture (fallback) jusqu'à la résorption Story 1.19.
- ⚠️ **Cloud Function de modération `school_requests`** : E1bis livre uniquement le côté client (écriture de la requête). La modération admin (action enseignant pédagogique) est backend/admin — story séparée hors mobile.

## Dependency graph

```text
        E1bis-0 Foundation widgets onboarding
        (6 composants + helper maskPhone)
        ┌──────────────────────────────────────┐
        │                                      │
        ▼                                      ▼
   E1bis-1 State machine                  E1bis-9 Migration Firestore
   (OnboardingNotifier Riverpod)          (schema users + collection
                                           school_requests + retire
        │                                  routes Epic 1 mortes)
        ▼
   E1bis-2 Pages 0-1
   (sub-system + hero)
        │
        ▼
   E1bis-3 Pages 2-3-4
   (track + level + stream/subjects 5 modes)
        │
        ▼
   E1bis-4 Page 5 (auth)
   (inversion auth, 3 boutons,
    écriture profil post-auth)
        │
        ▼
   E1bis-5 Pages 6-7 (name + phone)
        │
        ▼
   E1bis-6 Page 8 (school)
        │
        ▼
   E1bis-7 Page 9 (success)
        │
        ▼
   E1bis-8 Profil édition post-onboarding
   (réutilisation pages individuelles)
```

**Story bloquantes parallèles** : E1bis-0 et E1bis-9 peuvent démarrer en parallèle (pas de dépendance code). E1bis-1 dépend de E1bis-0 (utilise `SelectionCard`). Les pages 2-8 enchaînent linéairement sur E1bis-1.

---

## Story E1bis-0 — Foundation widgets onboarding (6 composants + helpers)

**Statut** : Drafted
**Estimation** : 3 jours
**Prérequis** : aucun
**Bloque** : E1bis-1, E1bis-2, E1bis-3, E1bis-4, E1bis-5, E1bis-6, E1bis-7
**Référence catalogue** : [`doc/tech/COMPOSANTS-REUTILISABLES.md` § « À créer — Refonte Onboarding 10 étapes »](../../../doc/tech/COMPOSANTS-REUTILISABLES.md)

### As a

développeur Flutter qui prépare la refonte E1bis, je veux disposer des 6 widgets réutilisables onboarding documentés au catalogue, avec tests goldens phone + tablet, pour que les stories pages (E1bis-2 à E1bis-7) consomment des briques stables sans dupliquer de code privé.

### Acceptance Criteria

- **AC1** Créer `lib/core/widgets/cards/selection_card.dart` avec API : `title`, `selected`, `onTap`, `icon?`, `description?`, `variant` enum (compact / standard / hero). Couleurs/dimensions strictes selon `DESIGN.md § Composants Onboarding > Selection card`.
- **AC2** Créer `lib/core/widgets/onboarding/sub_system_hero_card.dart` OU intégrer le variant `hero` dans `SelectionCard` (décision en début de story selon similarité). Documenter le choix au catalogue.
- **AC3** Créer `lib/core/widgets/forms/phone_input_with_country_flag.dart` : drapeau CM SVG + indicatif `+237` figé + champ numérique mask `6 XX XX XX XX`. Validation regex `^\\+237[26][0-9]{8}$`. Expose `static String maskedForLogs(String e164)` retournant `+237 XX XX XX X7 89`.
- **AC4** Créer `lib/core/widgets/forms/school_search_with_add.dart` : champ recherche + suggestions Firestore (via `searchProvider` injecté) + carte "+Ajouter <saisie>" si zéro résultat. Debounce 250 ms. Gestion offline via état `AsyncError`.
- **AC5** Créer `lib/core/widgets/feedback/celebration_confetti_success.dart` : cercle central success + 3 micro-icônes orbitantes + canvas confetti (package `confetti`) + auto-dispatch onComplete + variants enum (success/brand/warning). Coupures globales via `MediaQuery.disableAnimations` + Stories 0.14 `AudioService.silent` + `HapticService.disabled`.
- **AC6** Créer `lib/core/widgets/picker/picker_counter_badge.dart` : sticky top counter avec couleurs conditionnelles warning-soft / success-soft selon `isValid`.
- **AC7** Créer `lib/core/logging/log_safe.dart` avec helper `String maskPhone(String? e164)` qui retourne `+237 XX XX XX X7 89` (4 derniers visibles) ou `'<no-phone>'` si null. Tests : 5 cas (E164 valide / null / format invalide / vide / trop court).
- **AC8** Ajouter entrée détaillée pour chaque composant créé dans `doc/tech/COMPOSANTS-REUTILISABLES.md § Catalogue actuel` (déplacé depuis § À créer). Mettre à jour le tableau Historique avec la date 2026-06-XX et la PR.
- **AC9** **Tests** : pour chaque composant, au moins 1 golden phone 360×780 + 1 golden tablet 900×1200. Pour `PhoneInputWithCountryFlag` : tests `maskedForLogs` (5 cas) + validation regex (vide / partiel / valide / mauvais préfixe). Pour `CelebrationConfettiSuccess` : test que `MediaQuery.disableAnimations = true` masque le confetti.
- **AC10** **Responsive** : section "Stratégie responsive" dans Dev Notes confirmant les 4 form factors par composant. Décision documentée pour chaque composant : `phone-only` / `phone + tablet` / `tablet-adaptive`.

### Dev Notes

**Composants à créer (ordre recommandé)** :
1. `SelectionCard` (utilisé par 3 autres)
2. `PickerCounterBadge`
3. `SubSystemHeroCard` (ou variant `hero` de `SelectionCard`)
4. `PhoneInputWithCountryFlag`
5. `SchoolSearchWithAdd` (dépend de `SelectionCard`)
6. `CelebrationConfettiSuccess`

**Package recommandé** : `confetti: ^0.7.0` (pub.dev). Évaluer l'impact APK (+200 KB ?) ; si trop lourd, implémentation manuelle `CustomPaint` + `AnimationController`.

**Tokens à utiliser strictement (`lib/core/theme/tokens.dart`)** :
- Couleurs : `AppColors.primary`, `AppColors.success`, `AppColors.warning*`, `AppColors.bg`, `AppColors.card`, `AppColors.border`
- Spacing : `AppSpacing.s3`, `AppSpacing.s4`, `AppSpacing.s5`
- Radius : `AppRadius.lg`, `AppRadius.xl`, `AppRadius.xl2`
- Elevation : `AppElevation.soft`, `AppElevation.brand`
- Motion : `AppMotion.standard`, `AppMotion.celebration`

**Identifiers anglais (CLAUDE.md règle 5)** : noms de fichiers, classes, props, variables — 100% anglais. Pas de `filiere`, `niveau`, `serie`, `matiere`.

**Cost-benefit Firestore** : N/A (story foundation widgets, pas de lecture Firestore directe). `SchoolSearchWithAdd` ne lit pas Firestore, elle reçoit un `searchProvider` injecté.

---

## Story E1bis-1 — State machine onboarding (Riverpod OnboardingNotifier)

**Statut** : Drafted
**Estimation** : 2 jours
**Prérequis** : E1bis-0 (utilise `SelectionCard` dans tests)
**Bloque** : E1bis-2, E1bis-3, E1bis-4, E1bis-5, E1bis-6, E1bis-7

### As a

développeur Flutter qui implémente le nouveau flow 10 étapes, je veux une state machine Riverpod déterministe qui gère `currentStep`, les transitions `next` / `back` (avec branches conditionnelles), la persistance partielle, et la résilience kill app, pour que chaque page se concentre sur le rendu et non sur l'orchestration.

### Acceptance Criteria

- **AC1** Créer `lib/features/onboarding/presentation/state/onboarding_notifier.dart` (Riverpod `Notifier<OnboardingState>`) avec `OnboardingState` immutable : `currentStep: int`, `subSystem: SubSystem?`, `trackId: String?`, `levelId: String?`, `streamId: String?`, `pickedSubjects: Set<String>`, `authProvider: AuthProvider?`, `displayName: String?`, `phoneNumber: String?`, `schoolId: String?`, `schoolName: String?`, `pendingSchoolRequestId: String?`, `isAnonymous: bool`.
- **AC2** Méthodes `next()`, `back()`, `setSubSystem(SubSystem)`, `setTrackId(String)`, `setLevelId(String)`, `setStreamAndSubjects({String? streamId, required Set<String> pickedSubjects})`, `setAuth(AuthProvider, {String? displayName})`, `setName(String)`, `setPhoneNumber(String?)`, `setSchool({String? schoolId, String? schoolName, String? pendingRequestId})`, `markGuest()`. Chaque mutation respecte CLAUDE.md règle 10.l (`copyWith` partiel, pas réécriture complète).
- **AC3** Transitions conditionnelles : `next()` depuis step 3 → step 4 si `level.requiresOrientation == true`, sinon step 5. `next()` depuis step 4 → step 5. `next()` depuis step 5 → step 6 si `displayName == null`, sinon step 7. `next()` depuis step 7 → step 8 (sauf si visiteur → skip à 9). `back()` symétrique.
- **AC4** Persistance `subSystem` en `SharedPreferences` dès la mutation (clé `onboarding.subSystem`). Aucune autre persistance Riverpod (le draft profile vit en mémoire jusqu'à l'auth).
- **AC5** Au démarrage app, si `subSystem` SharedPreferences présent ET `Firebase.currentUser == null` → restart à step 0 avec `subSystem` pré-rempli. Si `Firebase.currentUser != null` ET `users/{uid}.onboardingCompleted == true` → skip onboarding → direct dashboard.
- **AC6** Méthode `flushToFirestore({required String uid, required bool isAnonymous})` qui écrit le profil partiel + champs identité en `users/{uid}` via `WriteBatch` atomique. Appelée au step 5 (post-auth) et au step 8 (post-school).
- **AC7** Tests unitaires couvrant : (i) transitions next/back avec `requiresOrientation` true/false, (ii) skip step 6 si OAuth fournit displayName, (iii) skip steps 6-8 si visiteur, (iv) persistance subSystem SharedPreferences (fake_shared_preferences), (v) restart logic au démarrage app.
- **AC8** Tests d'intégration : un parcours complet Fatou (step 0 → 4 → 5 Google → skip 6 → 7 → 8 → 9) écrit le bon payload Firestore.
- **AC9** **Identifiers anglais** : `trackId`, `levelId`, `streamId`, `subSystem`, `subjectIds`, `pickedSubjects`, `schoolId`, `phoneNumber`, `displayName`, `authProvider`, `isAnonymous`. Zéro français.
- **AC10** **Erreurs Firestore** : `flushToFirestore` retourne `Future<Either<Failure, Unit>>`. Les `FirebaseException` sont mappés en `FirestoreFailure(kind: Failure.kind)` selon la convention CLAUDE.md règle 13.

### Dev Notes

**Dépendances** : `flutter_riverpod`, `shared_preferences`, `dartz` (ou `fpdart`), `cloud_firestore`, `firebase_auth`.

**Pattern existant à réutiliser** : si Epic 1 a un `OnboardingNotifier` existant, le déprécier proprement (renommer en `LegacyOnboardingNotifier` avec annotation `@Deprecated`) plutôt que supprimer. Suppression définitive en E1bis-9.

**Cost-benefit Firestore (AC6 `flushToFirestore`)** :
- Écritures par user lors d'un onboarding complet : 2 (step 5 post-auth + step 8 post-school). À 10 000 onboardings/mois, ~20k writes/mois — négligeable.
- Lecture au démarrage : 1 `users/{uid}.get()` par cold start (cache offline OK). À 10k DAU × 1 cold start/jour, ~10k reads/jour — bien dans la free tier.
- Trade-off accepté : écriture en 2 phases (post-auth + post-school) plutôt qu'en 1 (post-school avec auth en attente) car cela permet le mode visiteur où step 8 est skippé.

---

## Story E1bis-2 — Pages 0 + 1 (sub-system + hero intro)

**Statut** : Drafted
**Estimation** : 2 jours
**Prérequis** : E1bis-0, E1bis-1
**Bloque** : E1bis-3

### As a

élève camerounais qui ouvre l'app pour la première fois, je veux choisir mon sous-système (francophone ou anglophone) en un tap et voir immédiatement ce que l'app va m'apporter (cours, exercices, chat IA), pour comprendre la valeur avant d'investir 4 écrans de profil.

### Acceptance Criteria

- **AC1** Page `lib/features/onboarding/presentation/pages/sub_system_choice_page.dart` (step 0) : icône Map en hero + titre H2 + 2 `SelectionCard` (Francophone / Anglophone) sans icône secondaire. Tap → `OnboardingNotifier.setSubSystem()` + langue app bascule immédiatement. Footer CTA `Continuer` désactivé tant que `subSystem == null`.
- **AC2** Page `lib/features/onboarding/presentation/pages/hero_intro_page.dart` (step 1) : illustration hero ratio 4/3 + dégradé bg vers le bas + titre display + 3 feature cards glassmorphic (Cours / Exercices / Chat IA) + footer CTA `C'est parti`.
- **AC3** Routes `go_router` : `/onboarding/sub-system` et `/onboarding/hero` (anglais, cf. CLAUDE.md règle 5).
- **AC4** Microcopie ARB FR + EN strictement selon table `EXPERIENCE.md § Microcopie onboarding` (steps 0 et 1).
- **AC5** Stratégie responsive 4 form factors : `LayoutBuilder` + `ConstrainedBox(maxWidth: 600 dp)` ≥ 840 dp + ratio illustration 4/3 plein largeur jusqu'à 720 dp ≥ tablette.
- **AC6** Goldens : phone 360×780, phone-landscape 700×400, tablet portrait 800×1280, tablet paysage 1280×800 (4 goldens × 2 pages = 8 goldens).
- **AC7** Tests d'intégration : tap Francophone → bascule i18n FR + state mis à jour + step suivant accessible.
- **AC8** Asset illustration : placeholder `assets/illustrations/onboarding_hero.png` (à remplacer ultérieurement par illustration propre, cf. OQ-UX-11 — story illustration séparée hors E1bis).
- **AC9** Aucun emoji décoratif dans les copies (cf. D9 + microcopie onboarding).
- **AC10** Taille fichiers : chaque page ≤ 300 lignes. Extraction des feature cards de `HeroIntroPage` vers `lib/features/onboarding/presentation/widgets/hero_intro_feature_card.dart` si > 50 lignes.

### Dev Notes

**Réutilisation composants** : `SelectionCard` (E1bis-0), `SubSystemHeroCard` (si choix variant séparé), footer CTA via composant `OnboardingCtaFooter` (à créer ici, simple wrapper bouton + gradient) — documenter au catalogue.

**Pas de Firebase ici** : steps 0 et 1 ne lisent / n'écrivent rien à Firestore. Tout en mémoire Riverpod + SharedPreferences (subSystem).

**Cost-benefit Firestore** : N/A.

---

## Story E1bis-3 — Pages 2 + 3 + 4 (track + level + stream/subjects picker 5 modes)

**Statut** : Drafted
**Estimation** : 4 jours
**Prérequis** : E1bis-0, E1bis-1
**Bloque** : E1bis-4

### As a

élève qui a choisi son sous-système, je veux préciser mon enseignement (Général / Technique), mon niveau (classe), et selon ce niveau soit voir mes matières dérivées automatiquement, soit choisir ma série, soit picker mes matières dans un panier, pour finaliser mon profil scolaire en restant focus.

### Acceptance Criteria

- **AC1** Page `track_choice_page.dart` (step 2) : sticky progress (`1/3`) + back + titre H2 + 2 `SelectionCard` (Général / Technique avec icônes Library / Wrench). Tap → `setTrackId`.
- **AC2** Page `level_choice_page.dart` (step 3) : sticky progress (`2/3`) + liste scrollable `SelectionCard` selon table `(subSystem, trackId)` → 4 listes possibles (7 niveaux chacune, cf. `EXPERIENCE.md § Step 3`). Tap → `setLevelId` + recalcul `requiresOrientation`.
- **AC3** Page `stream_subjects_picker_page.dart` (step 4) : page conditionnelle selon `pickerMode` calculé par `derivation_rules` (lecture Firestore `levels/{levelId}/derivationRule` via `CatalogueRepository` existant Story 1.1c) :
  - `derived` → **skip immédiat** vers step 5 (pas de rendu de page).
  - `series_only` → liste `SelectionCard` séries groupées par famille via headings si > 6 séries (Tle franco Lettres / Sciences humaines / Sciences / Sciences techniques cf. Story 1.14).
  - `free_with_obligatory` → `PickerSectionScaffold` + `ObligatorySubjectCheckboxList` + `OptionalSubjectCheckboxList` + `PickerCounterBadge` + `PickerValidateBar` (réutilisation 4 widgets Story 1.18).
  - `series_plus_optional` → `SelectionCard` row series + `ObligatorySubjectCheckboxList` series locked + `OptionalSubjectCheckboxList` transversales + `PickerCounterBadge`.
  - `tve_picker` → `SelectionCard` spécialité TVE + 2× `ObligatorySubjectCheckboxList` (Pro + Related) + `OptionalSubjectCheckboxList` Other + `PickerCounterBadge` avec validation `≥3 Pro ∧ ≥3 Related`.
- **AC4** Validation Firestore (cf. `firestore.rules` Story 1.15) : `pickedSubjects ⊂ derivedSubjects ∪ optionalSubjectIds ∧ obligatorySubjectIds ⊂ pickedSubjects`. Vérification CLIENT avant `next()`, vérification SERVEUR au flush.
- **AC5** Edge case `pickerMode == tve_picker` mais aucune spécialité `isActive: true` → encadré warning + bouton secondaire "Continuer en visiteur Lower Sixth Général" (fallback) qui écrase track/level/pickerMode + navigue step 5.
- **AC6** Routes : `/onboarding/track`, `/onboarding/level`, `/onboarding/stream-subjects` (anglais).
- **AC7** Stratégie responsive : 4 form factors. Pour `series_only` 12 cards Tle franco → grille 2 colonnes ≥ 840 dp. Goldens phone + tablet × 5 modes = 10 goldens minimum + 6 goldens pages track/level.
- **AC8** Microcopie ARB strictement selon table `EXPERIENCE.md § Microcopie onboarding` (steps 2, 3, 4 + sections locked/electives + compteur).
- **AC9** Identifiers anglais : `trackId`, `levelId`, `streamId`, `pickedSubjects`, `obligatorySubjectIds`, `optionalSubjectIds`, `pickerMode`. Refactor des modèles consommés depuis Firestore si nécessaire (Mapper `serieId` → `streamId` en lecture, cf. note Out of scope migration).
- **AC10** Taille fichiers : `stream_subjects_picker_page.dart` ≤ 500 lignes (plafond dur). Si dépassement, extraire chaque mode en `picker_mode_*.dart` widget séparé.

### Dev Notes

**Réutilisation massive** : 4 widgets Story 1.18 (`PickerSectionScaffold`, `ObligatorySubjectCheckboxList`, `OptionalSubjectCheckboxList`, `PickerValidateBar`) + `SelectionCard` E1bis-0 + nouveau `PickerCounterBadge`. Pas de duplication.

**État picker mode** : le `pickerMode` n'est pas en state Riverpod — c'est un computed du `DerivedProfile` lu depuis `CatalogueRepository`. Pattern existant Story 1.13.

**Cost-benefit Firestore** :
- Lectures par session onboarding : 1 lecture `derivation_rules/{levelId+trackId+subSystem}` (cache OK) + N lectures `streams/*` filtrées par `where('levelId', '=', ...)` `where('isActive', '=', true)` `limit(15)`.
- À 10k onboardings/mois : ~20k reads/mois — négligeable.
- Pas de `snapshots()` (catalogue statique cf. CLAUDE.md règle 10.g).
- Anti-pattern évité : zéro `.where((doc) => ...)` côté Dart. Tous les filtres en `.where(...)` Firestore.

---

## Story E1bis-4 — Page 5 (auth choice) — inversion auth

**Statut** : Drafted
**Estimation** : 3 jours
**Prérequis** : E1bis-1, E1bis-3
**Bloque** : E1bis-5

### As a

élève qui a complété son profil scolaire, je veux créer mon compte (Google / Apple) ou continuer comme visiteur, et que mes choix faits aux étapes précédentes soient préservés et écrits dans mon profil après l'authentification.

### Acceptance Criteria

- **AC1** Page `auth_choice_page.dart` (step 5) : pas de header progress + back flottant (retour step 4 ou 3 selon `requiresOrientation`) + icône User cercle primary-soft + titre H1 + sous-titre + 3 boutons empilés (Google + Apple iOS-only + Visiteur). Divider centré "Ou" entre Apple et Visiteur.
- **AC2** Bouton Google : déclenche `firebase_auth` Google Sign-In. Sur succès → `setAuth(google, displayName: googleUser.displayName)` + `flushToFirestore(uid, isAnonymous: false)` + `next()`.
- **AC3** Bouton Apple : visible **uniquement** sur iOS (`Platform.isIOS`, isolé dans `core/platform/`). Sur succès → `setAuth(apple, displayName: appleUser.displayName)` + flush + next.
- **AC4** Bouton Visiteur : confirmation inline avec bouton "Confirmer" + lien "Retour". Sur confirmation → `firebase_auth signInAnonymously()` + `setAuth(guest)` + `markGuest()` + `flushToFirestore(uid, isAnonymous: true)` + `next()`.
- **AC5** Gestion erreurs par `failure.kind` (CLAUDE.md règle 13) :
  - `permissionDenied` → toast `errorPermissionDenied` (ARB "Session expirée, recommence.")
  - `networkUnavailable` (codes `unavailable`, `network-request-failed`, `deadline-exceeded`) → toast `errorNetworkUnavailable`
  - `unknown` → toast `errorFirestoreUnknown` ("Erreur technique. Réessaie.")
  - User reste step 5, aucune écriture Firestore.
- **AC6** Logs AppLogger : tout `failure.fold((f) → ...)` log `kind=${f.kind.name} message=${f.message} code=${f.code}`. Pas de log silencieux. Helper dédié `_logOnboardingAuthFailure(failure)`.
- **AC7** Edge case réinstallation : si `firebase_auth.currentUser != null` au démarrage step 5 (cas non attendu mais défensif) → bypass flow → direct dashboard.
- **AC8** Route : `/onboarding/auth` (anglais).
- **AC9** Microcopie ARB FR + EN strictement selon table `EXPERIENCE.md § Microcopie onboarding step 5` + table `Microcopie erreurs onboarding`.
- **AC10** Goldens 4 form factors × 2 plateformes (Apple visible iOS / masqué Android) = 8 goldens.
- **AC11** Tests d'intégration : (i) tap Google succès → profil partiel écrit Firestore avec `isAnonymous: false` ; (ii) tap Visiteur succès → écriture avec `isAnonymous: true` + skip steps 6-8 ; (iii) erreur OAuth networkUnavailable → toast localisé + state inchangé.

### Dev Notes

**Packages** : `google_sign_in: ^6.x`, `sign_in_with_apple: ^5.x`, `firebase_auth`.

**Inversion auth — détails** : `flushToFirestore` est appelé deux fois :
1. **Step 5 post-auth** : écrit le profil partiel (subSystem, trackId, levelId, streamId, pickedSubjects, isAnonymous, authProvider).
2. **Step 8 post-school** (story E1bis-6) : update partiel avec phoneNumber + schoolId + displayName + onboardingCompleted: true.

**Apple Sign-In Android masqué** : utiliser `Platform.isIOS` dans `core/platform/auth_platform.dart` (wrapper). Le widget AuthChoicePage importe ce wrapper.

**Cost-benefit Firestore** :
- 1 `set()` par profil partiel post-auth. À 10k onboardings/mois, 10k writes — négligeable.
- 0 lecture supplémentaire (le profil partiel vient de Riverpod, pas de re-fetch).

---

## Story E1bis-5 — Pages 6 + 7 (name + phone)

**Statut** : Drafted
**Estimation** : 2 jours
**Prérequis** : E1bis-0 (PhoneInputWithCountryFlag), E1bis-4
**Bloque** : E1bis-6

### As a

élève authentifié qui n'avait pas de nom OAuth (ou veut le modifier), je veux saisir mon nom et optionnellement mon numéro de téléphone Cameroun, pour personnaliser mon espace et sécuriser mon compte.

### Acceptance Criteria

- **AC1** Page `name_input_page.dart` (step 6) : sticky progress (`1/3` segment "identité") + back + titre H1 + label + champ texte autofocus avec placeholder. Validation `name.trim().length ∈ [2, 80]`.
- **AC2** Page `phone_input_page.dart` (step 7) : sticky progress (`2/3`) + back + titre H1 + sous-titre + composant `PhoneInputWithCountryFlag` + bouton tertiaire "Passer pour l'instant".
- **AC3** Skip auto step 6 si OAuth a fourni `displayName` non-vide (transition E1bis-1 AC3). Si l'utilisateur revient via back depuis step 7 → step 6 avec le nom OAuth pré-rempli (éditable).
- **AC4** Skip phone (step 7) avec micro-friction : tap "Passer" → toast "Tu pourras l'ajouter plus tard depuis ton profil" + `setPhoneNumber(null)` + `next()`.
- **AC5** Logs sécurité : **aucun** log AppLogger ne reçoit le numéro complet. Tous les logs passent par `maskPhone(phoneNumber)` (E1bis-0 AC7). Vérification : grep -r "phoneNumber" dans les logs source → masqué partout.
- **AC6** Routes : `/onboarding/name`, `/onboarding/phone` (anglais).
- **AC7** Microcopie ARB FR + EN selon table `EXPERIENCE.md § Microcopie onboarding steps 6 et 7` + erreurs nom trop court / phone invalide.
- **AC8** Stratégie responsive 4 form factors + container `ConstrainedBox(maxWidth: 600 dp)` centré tablette. Goldens phone + tablet × 2 pages × 2 états (vide / rempli) = 8 goldens.
- **AC9** Tests : (i) saisie nom 1 char → CTA disabled ; (ii) saisie phone "671234567" → onChanged reçoit `+237671234567` ; (iii) tap skip phone → state phoneNumber == null + toast affiché ; (iv) `maskPhone('+237671234567')` retourne format masqué (vérifier dans logs test).
- **AC10** Taille fichiers ≤ 300 lignes / page.

### Dev Notes

**Logs masking** : ajouter test goldens dans `core/logging/log_safe_test.dart` qui vérifie 5 cas (E164 valide / null / format invalide / vide / trop court).

**Cost-benefit Firestore** : aucune écriture à ce stade. Les valeurs vivent en Riverpod. Le flush a lieu step 8.

---

## Story E1bis-6 — Page 8 (school search) + collection `school_requests`

**Statut** : Drafted
**Estimation** : 3 jours
**Prérequis** : E1bis-0 (SchoolSearchWithAdd), E1bis-5
**Bloque** : E1bis-7
**Accord backend requis** : nouvelle collection `school_requests` à documenter dans `doc/partage/BASE-DE-DONNEES.md` + Cloud Function de modération admin (hors mobile scope).

### As a

élève authentifié qui veut être classé avec ses camarades, je veux trouver mon école ou en ajouter une si elle n'existe pas, ou simplement passer pour l'instant si je préfère.

### Acceptance Criteria

- **AC1** Page `school_search_page.dart` (step 8) : sticky progress (`3/3`) + back + titre H2 + sous-titre + composant `SchoolSearchWithAdd` (E1bis-0).
- **AC2** Source des suggestions : Riverpod `schoolsSearchProvider(query)` qui requête `schools` collection Firestore avec `where('name_tokens', arrayContains: query.toLowerCase())` + `where('isActive', '=', true)` + `limit(10)`. Debounce 250 ms côté composant.
- **AC3** Tap résultat → `setSchool(schoolId, schoolName)` → CTA "C'est mon école" activé → tap → step 9.
- **AC4** Tap "+ Ajouter <saisie>" → écriture `school_requests/{autoId}` avec payload `{name, subSystem, requestedBy: uid, status: 'pending', createdAt: serverTimestamp}` → toast + `setSchool(schoolId: null, schoolName: saisie, pendingRequestId: autoId)` → step 9.
- **AC5** Tap "Passer pour l'instant" → toast micro-friction "Tu pourras l'ajouter plus tard depuis ton profil" → `setSchool(schoolId: null)` → step 9.
- **AC6** Edge case offline : si `schoolsSearchProvider` retourne `AsyncError(networkUnavailable)` → encadré warning visible + bouton "+ Ajouter" toujours fonctionnel.
- **AC7** Édge case visiteur : la page step 8 est skippée pour les comptes anonymous (cf. E1bis-1 AC3 transition). Test à couvrir.
- **AC8** `flushToFirestore` final : update `users/{uid}` avec `{displayName, phoneNumber, schoolId, schoolName, pendingSchoolRequestId, onboardingCompleted: true}` via `set(merge: true)` (CLAUDE.md règle 10.l).
- **AC9** Documentation `doc/partage/BASE-DE-DONNEES.md` : ajouter section `school_requests` (champs + indexes + règles Firestore) avec accord backend (commentaire mainteneur dans la PR).
- **AC10** `firestore.indexes.json` : si la requête `schools` nécessite un index composite (`isActive` + `name_tokens` arrayContains), le déclarer (CLAUDE.md règle 9).
- **AC11** Microcopie + goldens 4 form factors × 4 états (vide / saisie / résultats / zéro résultat) = 16 goldens.

### Dev Notes

**Schema `school_requests`** (proposition à valider backend) :
```
school_requests/{autoId}
  - name: string (saisie utilisateur)
  - normalizedName: string (lowercase, sans accents)
  - subSystem: 'francophone' | 'anglophone'
  - requestedBy: string (uid)
  - status: 'pending' | 'approved' | 'rejected' | 'duplicate'
  - createdAt: serverTimestamp
  - reviewedBy: string? (admin uid post-modération)
  - reviewedAt: serverTimestamp?
  - mergedIntoSchoolId: string? (si status='duplicate' ou 'approved' → ID de l'école finale)
```

**Index composite à créer** : `schools` `(isActive ASC, name_tokens ARRAY)` pour la recherche live.

**Cost-benefit Firestore** :
- Lectures par session onboarding : 1 à 3 (debounce limite à 1 requête par saisie complète + `limit(10)`). À 10k onboardings/mois, ~30k reads/mois — négligeable.
- Écritures : 1 `school_requests` (cas custom) + 1 `users/{uid}` update final. À 10k onboardings, ~20k writes — négligeable.
- Pas de `snapshots()` (data statique).

---

## Story E1bis-7 — Page 9 (success celebration)

**Statut** : Drafted
**Estimation** : 1 jour
**Prérequis** : E1bis-0 (CelebrationConfettiSuccess), E1bis-6
**Bloque** : E1bis-8 (le profil édition réutilise les pages mais peut démarrer sans E1bis-7)

### As a

élève qui a complété l'onboarding (ou un visiteur qui a confirmé), je veux voir une page de célébration qui me confirme que mon espace est prêt et qui m'amène au dashboard.

### Acceptance Criteria

- **AC1** Page `success_celebration_page.dart` (step 9) : utilise `CelebrationConfettiSuccess` (E1bis-0). Variants compte (titre + sous-titre + CTA "Entrer dans mon espace") vs visiteur (titre + sous-titre + CTA "Explorer").
- **AC2** Auto-dispatch onComplete après 3.5 s OU tap CTA → `context.go('/dashboard')` (replace, pas de back).
- **AC3** Choreography multisensorielle (greffe sur `EXPERIENCE.md § Multisensoriel`) :
  - Anim : `celebration` 600 ms (spring sur cercle + fade-in titres).
  - Audio : `complete.m4a` 200 ms après ouverture via `AudioService` (Story 0.14).
  - Haptic : `success` séquence via `HapticService` (Story 0.14).
- **AC4** Coupures globales : si `MediaQuery.disableAnimations` → fade-in 200 ms statique. Si silencieux → pas de son. Cf. D-UX-Update-3.
- **AC5** Ajouter entrée dans la table choreography multisensorielle de `EXPERIENCE.md § Multisensoriel > Choreography par moment clé` : « Step 9 célébration onboarding ».
- **AC6** Route : `/onboarding/success` (anglais).
- **AC7** Microcopie ARB FR + EN selon table `EXPERIENCE.md § Microcopie onboarding step 9` (4 lignes : compte titre/sous-titre, visiteur titre/sous-titre).
- **AC8** Goldens : phone 360×780 + tablet 900×1200 × variant compte + variant visiteur = 4 goldens.
- **AC9** Test crash crashlytics interruption : crash pendant les 3.5 s → next cold start `users/{uid}.onboardingCompleted == true` → bypass tout l'onboarding → direct dashboard.

### Dev Notes

**Package** : `confetti` (E1bis-0 AC5).

**Cost-benefit Firestore** : 0 lecture / 0 écriture (le flush a eu lieu step 8).

**Audio asset** : `complete.m4a` existe déjà (Story 0.14). Vérifier `pubspec.yaml` declaration.

---

## Story E1bis-8 — Profil édition post-onboarding

**Statut** : Drafted
**Estimation** : 3 jours
**Prérequis** : E1bis-2 à E1bis-7 (toutes les pages onboarding livrées)
**Bloque** : —

### As a

élève qui a déjà finalisé son onboarding, je veux pouvoir modifier individuellement n'importe quelle information de mon profil (sous-système non, niveau oui, série, école, nom, téléphone) depuis Profil > Édition, sans avoir à refaire tout le flow.

### Acceptance Criteria

- **AC1** Écran d'index `lib/features/profile/presentation/pages/profile_edit_page.dart` accessible depuis Dashboard > Profil > Édition (route `/profile/edit`). Liste les champs éditables : Niveau, Série & matières, Nom, Téléphone, École.
- **AC2** Tap sur "Niveau" → navigue vers une variante de `LevelChoicePage` (E1bis-3) en mode édition : back retourne au profil au lieu de step 2. Sauvegarde directe Firestore via `set(merge: true)`.
- **AC3** Idem pour "Série & matières" → `StreamSubjectsPickerPage` mode édition. Si changement de niveau a invalidé le streamId → flow obligatoire de re-pick.
- **AC4** Idem pour "Nom" → `NameInputPage` mode édition. Pour "Téléphone" → `PhoneInputPage` mode édition (skip non offert ici, le user a explicitement tapé pour éditer). Pour "École" → `SchoolSearchPage` mode édition.
- **AC5** Sub-system **non éditable** depuis le profil (cf. ADR-006). Le champ est en lecture seule avec un encadré info "Pour changer de sous-système, contacte le support."
- **AC6** Toutes les pages mode édition réutilisent les mêmes composants (E1bis-0 + widgets existants) que le flow onboarding. Pas de duplication.
- **AC7** Identifiers anglais (CLAUDE.md règle 5) : `/profile/edit/level`, `/profile/edit/stream-subjects`, etc.
- **AC8** Tests d'intégration : (i) changement niveau → matières dérivées invalidées + re-pick obligatoire si stream incompatible ; (ii) saisie nouveau téléphone → masquage logs ; (iii) tap modifier école → SchoolSearchPage avec sélection actuelle pré-affichée.
- **AC9** Goldens 4 form factors × écran index profile_edit_page = 4 goldens.

### Dev Notes

**Pattern « mode édition »** : ajouter un paramètre `EditMode mode` (enum onboarding/edit) aux pages partagées. `OnboardingNotifier` n'est pas utilisé en mode édition ; à la place, un `ProfileEditNotifier` distinct qui lit/écrit Firestore directement.

**Pas de back vers onboarding** : si user navigue back depuis une page mode édition, retour au profil pas à l'étape précédente du flow.

**Cost-benefit Firestore** :
- 1 lecture `users/{uid}` à l'entrée de profile_edit_page (cache OK).
- 1 update par modification (set merge true). À 10k DAU × 0.1 modification/mois, ~1k writes/mois — négligeable.

---

## Story E1bis-9 — Migration Firestore + déprécation routes Epic 1

**Statut** : Drafted
**Estimation** : 2 jours
**Prérequis** : aucun (peut démarrer en parallèle de E1bis-0)
**Bloque** : —
**Accord backend requis** : modification `firestore.rules` + `firestore.indexes.json` + suppression routes go_router obsolètes.

### As a

développeur Flutter qui veut une codebase propre post-refonte, je veux que les anciens champs Firestore (`serieId` → `streamId` minimum, dual-read en transition), les anciennes routes (`/onboarding/sub-system-choice` etc.), et les anciens widgets non utilisés post-Story 1.18 soient nettoyés ou dépréciés proprement.

### Acceptance Criteria

- **AC1** Schema `users/{uid}` étendu (documenté `doc/partage/BASE-DE-DONNEES.md`) :
  - Ajout `phoneNumber: string?` (E164 format, peut être null)
  - Ajout `isAnonymous: bool` (default false)
  - Ajout `authProvider: 'google' | 'apple' | 'guest'` (initialisé au step 5)
  - Ajout `onboardingCompleted: bool` (initialisé true au step 8 ou step 5 pour visiteur)
  - Ajout `pendingSchoolRequestId: string?` (si école pas dans le catalogue)
  - Le champ `displayName` est nullable pour visiteur.
- **AC2** Schema lecture rétrocompatible : tous les repositories lisent `streamId` OU `serieId` (fallback). Tous les nouveaux writes écrivent **uniquement** `streamId`. La double-écriture (`streamId` + `serieId`) est rejetée (interdite). Implémentation via un helper `users_doc_decoder.dart`.
- **AC3** Cloud Function migration ponctuelle (backend — story séparée hors mobile) : rename `serieId` → `streamId` sur tous les `users/{uid}` existants en un batch. Côté mobile, surveiller logs de fallback "serieId encore lu" sur 7 jours après merge — si > 0 occurrence par jour, alerter.
- **AC4** Collection `school_requests` créée avec index composite si nécessaire (cf. E1bis-6 AC10).
- **AC5** Routes `go_router` obsolètes supprimées : `/onboarding/sub-system-choice`, `/onboarding/filiere`, `/onboarding/niveau`, `/onboarding/serie`, `/onboarding/profil-recap`, `/onboarding/school-link`. Redirections `redirect:` vers les nouvelles routes anglaises pendant 1 semaine puis suppression.
- **AC6** Widgets non utilisés post-Story 1.18 supprimés : ré-audit `lib/features/onboarding/presentation/` après livraison E1bis-7 pour identifier les pages mortes (anciennes versions sub_system_choice, filiere_choice, etc.).
- **AC7** `firestore.indexes.json` à jour avec les nouveaux indexes (cf. E1bis-6 AC10 + tout autre besoin émergé).
- **AC8** Tests de non-régression : utilisateurs Epic 1 existants en base de test → après déploiement E1bis, peuvent toujours se logger et accéder au dashboard avec leur profil intact (lecture `serieId` legacy).
- **AC9** Documentation `doc/partage/BASE-DE-DONNEES.md § Historique` à mettre à jour.
- **AC10** `doc/partage/CONTRATS-API.md` mis à jour : ajouter le contrat de modération `school_requests` (Cloud Function admin, hors scope mobile).

### Dev Notes

**Séquencement obligatoire** : E1bis-9 peut être codée en parallèle de E1bis-0 mais ne doit être **déployée** qu'après E1bis-7 (sinon les anciennes pages cassent en lisant `streamId` qui n'existe pas encore).

**Accord backend obligatoire** : commentaire de mainteneur backend dans la PR pour AC1 (schema) + AC3 (Cloud Function migration) + AC4 (collection) + AC10 (contrat).

**Cost-benefit Firestore** : la migration ponctuelle = 1 write par user existant (~3000 users actuels). 3k writes one-shot — négligeable.

---

## Récapitulatif estimation E1bis

| Story | Estimation | Dépendances |
|---|---|---|
| E1bis-0 Foundation widgets | 3 j | — |
| E1bis-1 State machine | 2 j | E1bis-0 |
| E1bis-2 Pages 0+1 | 2 j | E1bis-0, E1bis-1 |
| E1bis-3 Pages 2+3+4 | 4 j | E1bis-0, E1bis-1 |
| E1bis-4 Page 5 (auth) | 3 j | E1bis-1, E1bis-3 |
| E1bis-5 Pages 6+7 | 2 j | E1bis-0, E1bis-4 |
| E1bis-6 Page 8 (school) | 3 j | E1bis-0, E1bis-5 |
| E1bis-7 Page 9 (success) | 1 j | E1bis-0, E1bis-6 |
| E1bis-8 Profil édition | 3 j | E1bis-2 à E1bis-7 |
| E1bis-9 Migration | 2 j | parallèle E1bis-0 |
| **Total** | **25 jours** | **(séquencement 1 PR à la fois ~3-4 semaines)** |

## Risques

- **R-E1bis-1** — Divergence PRD : FR-5 (mode visiteur), FR-6 (école optionnelle), ordre Auth/Onboarding ne sont pas alignés avec le PRD existant. Mitigation : lancer `/bmad-prd Update` en parallèle ou en amont de E1bis-2.
- **R-E1bis-2** — Backend non disponible pour validation `school_requests` schema (AC E1bis-6 AC9) → blocage merge. Mitigation : commencer la story PR en draft, demander review backend tôt.
- **R-E1bis-3** — Package `confetti` trop lourd (+200 KB APK) → impact NFR-1 (taille app < 30 MB). Mitigation : mesurer en E1bis-0 ; si > 200 KB, implémentation manuelle `CustomPaint`.
- **R-E1bis-4** — Rétrocompat `serieId` lecture : si la Cloud Function migration ne tourne pas en temps, les utilisateurs Epic 1 voient leur profil mal interprété. Mitigation : helper `users_doc_decoder.dart` avec fallback explicite + logs alerting.
- **R-E1bis-5** — Apple Sign-In sur Android : si la doc dev n'est pas claire sur le masquage Apple, un bouton inutile s'affiche sur Android. Mitigation : test goldens Android + iOS séparés (AC E1bis-4 AC10).

## Décisions ouvertes

- **OQ-E1bis-1** — Asset illustration step 1 hero : commander à un freelance ou utiliser le placeholder template ? (cf. OQ-UX-11)
- **OQ-E1bis-2** — `OnboardingCtaFooter` : extraire en composant catalogue ou inline dans chaque page ?
- **OQ-E1bis-3** — Mode édition profil : le user peut-il revenir aux pages onboarding via deep link admin (debug seulement) ?

## Critère de Done global E1bis

- 10 stories livrées et mergées (PR séquentielles, cf. CLAUDE.md règle 6).
- Les 5 personas Epic 1 complètent le nouveau flow en < 90 s sur 4 form factors.
- Tests goldens passent (estimation ~80 goldens cumulés).
- Aucun `filiereId` / `niveauId` / `serieId` dans le nouveau code E1bis (lecture rétrocompat OK).
- Doc à jour : `doc/partage/BASE-DE-DONNEES.md`, `doc/partage/CONTRATS-API.md`, `doc/tech/COMPOSANTS-REUTILISABLES.md`, `firestore.indexes.json`.
- `OnboardingNotifier` ancien déprécié et supprimé (E1bis-9).
- Routes obsolètes supprimées.

## Note méthodologique — déviation du flow `/bmad-create-epics-and-stories`

Cette story sheet n'a pas été générée via le step-by-step strict de la skill `bmad-create-epics-and-stories` (qui assume un projet from-scratch). Elle a été produite en mode pragmatique : extension d'un `epics.md` existant qui suit déjà ce pattern (Epic 0 et Epic 1 antérieurs).

**Couverture qualité équivalente** :
- Les FRs (FR-1 à FR-8) sont reflétées et **refondues** dans les 10 stories.
- L'UX (DESIGN.md + EXPERIENCE.md) est référencée explicitement (Voice & Tone, microcopie, composants visuels).
- Les contraintes architecturales (CLAUDE.md règles 1-13) sont injectées story par story dans les AC + Dev Notes.
- Le `.decision-log.md` UX (D-UX-Update-12 à 20) est cité comme source de vérité.
- Cost-benefit Firestore documenté par story (CLAUDE.md règle 10.m).

**Prochaine étape recommandée** : exécuter `/bmad-create-story E1bis-0` pour préparer le fichier `story-E1bis-0.md` dans `project_manage/implementation-artifacts/` avec Dev Notes complètes (composants existants, AC tests, exemples de code, fichiers cibles). Puis `/bmad-dev-story` pour implémenter. Respecter la règle 6 CLAUDE.md (1 PR à la fois, attendre merge).
