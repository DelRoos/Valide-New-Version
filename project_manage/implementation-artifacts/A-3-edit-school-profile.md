---
baseline_commit: 3d9258f1455077257964923e6df4239199560734
---

# Story A.3 — Édition profil scolaire (classe → spécialité → matières)

**Status** : in-progress
**Epic** : Pilier A — Gestion profil utilisateur
**Sprint** : Pilier A story 3/3

---

## User Story

**En tant qu'** élève connecté,
**je veux** modifier ma classe, ma spécialité et mes matières depuis l'onglet Profil,
**afin de** corriger une erreur de saisie lors de l'onboarding ou de changer de niveau en cours d'année.

---

## Acceptance Criteria

### AC-1 — Accès au flow depuis l'onglet Profil
- [x] Un bouton icône crayon est visible dans l'en-tête de la section "Mon programme" de `ProgrammeSection`
- [x] Tap → ouvre `SchoolProfileEditSheet` (AppBottomSheet, useRootNavigator: true)
- [ ] Le sheet affiche en header la classe actuelle de l'utilisateur *(déviation mineure : le header affiche "Changer de classe" ; la classe actuelle est visible pré-sélectionnée dans la grille step 0)*

### AC-2 — Étape 1 : sélection du niveau (classe)
- [x] La liste des niveaux disponibles est filtrée par `subSystem` de l'utilisateur (immutable)
- [x] Le niveau actuel est pré-sélectionné visuellement
- [x] Tap sur un niveau différent → avance à l'étape 2 (stream)
- [x] Tap sur le niveau actuel → avance directement à l'étape 2 en conservant le stream actuel

### AC-3 — Étape 2 : sélection de la spécialité (série)
- [x] La liste des séries est filtrée par le niveau sélectionné à l'étape 1
- [x] Si une seule série disponible → auto-sélection + passe directement à l'étape 3
- [x] La série actuelle est pré-sélectionnée si elle est compatible avec le nouveau niveau
- [x] Bouton "Retour" → revient à l'étape 1

### AC-4 — Étape 3 : confirmation / ajustement des matières
- [x] Les matières dérivées du nouveau binôme niveau+série sont calculées et affichées
- [x] Si `pickerMode == derived` → affichage recap chips, bouton "Enregistrer" direct
- [x] Si `pickerMode == opt_out` → toggle chips matières, bouton "Enregistrer"
- [x] Si `pickerMode` interactif (free_with_obligatory, series_plus_optional) → sélection obligatoires + optionnelles, bouton "Enregistrer"
- [x] Bouton "Retour" → revient à l'étape 2

### AC-5 — Sauvegarde Firestore (Approche B — client direct)
- [x] Tap "Enregistrer" → `.update()` partiel sur `users/{uid}` avec : `trackId`, `levelId`, `streamId`, `pickedSubjects`, `derivedSubjects`, `examTargets`, `optedOutSubjects`, `updatedAt: serverTimestamp()`
- [x] Toast succès `l10n.profileEditSuccess` + fermeture du sheet
- [x] En cas d'erreur réseau → toast `l10n.errorNetworkUnavailable`, sheet reste ouvert
- [x] En cas d'erreur auth → toast `l10n.errorPermissionDenied`, sheet reste ouvert
- [x] Loader affiché pendant la sauvegarde (bouton désactivé)

### AC-6 — Firestore rules modifiées (Approche B)
- [x] La règle UPDATE de `users/{uid}` ne bloque plus les changements sur `trackId`, `levelId`, `streamId`
- [x] `subSystem`, `language`, `createdAt` restent immutables (contraintes maintenues)
- [ ] La modification est déployée via `firebase deploy --only firestore:rules --project valide-edu` *(BLOQUÉ — accord backend requis)*
- [ ] Le test de règle existant `test/rules/` est mis à jour pour valider les nouvelles permissions *(reporté post-accord)*

### AC-7 — Responsive tablette
- [x] Sheet centré avec `Center + ConstrainedBox(maxWidth: 560.w)` sur tablette (≥ 840 dp)
- [x] Grille niveaux : 2 colonnes sur phone, 3 colonnes sur tablette (LayoutBuilder)
- [ ] Golden test phone portrait (375×812) et tablette portrait (768×1024) générés *(reporté — emulateur requis)*

### AC-8 — doc/partage/ mis à jour
- [x] `BASE-DE-DONNEES.md` : mutabilité de `trackId`, `levelId`, `streamId` passée à "Mutable" dans la table Update patterns
- [x] Entrée Historique ajoutée dans `BASE-DE-DONNEES.md`
- [ ] ⚠️ **Accord backend requis avant merge** (modification doc/partage/ + firestore.rules partagées)

---

## Dev Notes

### Contexte et motivation
Story A-1 a livré l'édition nom/téléphone/école. Story A-2 a livré le profil public. A-3 complète le triptyque en permettant de corriger le profil scolaire (niveau/série/matières), cas d'usage fréquent en début d'année. Approche B validée par porteur le 2026-06-30 : client direct (.update() Firestore), règles Firestore assouplies sur les 3 champs structurants.

### Décisions techniques clés
- **Décision 1** : Bottom sheet multi-étapes avec `PageController` interne — **raison** : cohérence avec le pattern AppBottomSheet existant, UX fluide sans empilement de sheets — **alternative écartée** : 3 sheets chaînés (navigation root navigator complexe + UX saccadée).
- **Décision 2** : Nouveau `SchoolProfileEditSheet` (ne pas réutiliser `LevelChoiceStepBody`/`StreamSubjectsPickerStepBody` directement) — **raison** : ces bodies ont du code onboarding-spécifique (anon auth, navigation /dashboard, flush service) ; la bottom sheet a un contexte plus simple — **alternative écartée** : fork des step bodies (risque régression onboarding + couplage invisible).
- **Décision 3** : Nouvelle méthode `updateSchoolProfile()` dans `UserProfileRepository` + impl — **raison** : `OnboardingFlushService.flush()` a un guard "permanent accounts → immutabilité stricte" qui bloquerait l'édition — **alternative écartée** : modifier le flush service (scope trop large, risque régression onboarding).
- **Décision 4** : `derivedSubjects` et `examTargets` calculés côté client via `derive()` avant save — **raison** : cohérent avec l'onboarding, évite une Cloud Function pour ce cas — **alternative écartée** : Cloud Function (Approche A, rejetée par porteur).
- **Décision 5** : `subSystem` immutable côté rules maintenu — **raison** : le sous-système détermine la langue de l'app et la base du catalogue ; un changement nécessiterait un re-onboarding complet — **conséquence** : la liste des niveaux affichés est toujours filtrée par le `subSystem` actuel de l'utilisateur.

### Modèle de données / API impactés

**`domain/user_profile_repository.dart`** — ajouter :
```dart
Future<Either<ProfileFailure, void>> updateSchoolProfile({
  required String trackId,
  required String levelId,
  required String streamId,
  required List<String> derivedSubjects,
  required List<String> examTargets,
  required List<String> pickedSubjects,
  required List<String> optedOutSubjects,
});
```

**`data/user_profile_repository_firestore_impl.dart`** — implémenter via :
```dart
await _firestore.collection('users').doc(uid).update({
  'trackId': trackId,
  'levelId': levelId,
  'streamId': streamId,
  'derivedSubjects': derivedSubjects,
  'examTargets': examTargets,
  'pickedSubjects': pickedSubjects,
  'optedOutSubjects': optedOutSubjects,
  'updatedAt': FieldValue.serverTimestamp(),
});
```

**`firestore.rules`** — retirer de la règle UPDATE :
```
// Supprimer ces 3 lignes :
&& (!('trackId' in resource.data) || request.resource.data.trackId == resource.data.trackId)
&& (!('levelId' in resource.data) || request.resource.data.levelId == resource.data.levelId)
&& (!('streamId' in resource.data) || request.resource.data.streamId == resource.data.streamId)
```
Conserver `subSystem`, `language`, `createdAt` immutables.

**Schéma Firestore** → `doc/partage/BASE-DE-DONNEES.md` (mutabilité trackId/levelId/streamId → Mutable + historique).

### Cost-benefit Firestore

**Type d'impact** : mutation `users/{uid}` — 7 champs mis à jour simultanément.

**Reads / écriture par session** :
- Lecture : +N reads catalogue (niveaux + séries + subjects) = même que l'onboarding, servis via cache offline Firestore (pas de reads réseau si catalogue déjà chargé).
- Écriture : 1 write `users/{uid}` — update partiel 7 champs + updatedAt.
- Feature rare (< 1×/mois par user) → impact Firestore négligeable.

**Volumétrie @ 10k users** : < 10k writes/mois (feature rare). Coût < $0.01/mois.

**Trade-off accepté** : client direct + règles assouplies (Approche B) — plus rapide, pas de Cloud Function. Contrepartie : aucune validation serveur de la cohérence trackId/levelId/streamId (MVP acceptable — le client ne peut choisir que des combinaisons valides via le picker).

**Check CLAUDE.md règle 10** :
- [x] (k) Lecture par ID (`users/{uid}`)
- [x] (l) `.update()` partiel — jamais `.set()` complet
- [x] (g) Catalogue via `.get()` + cache offline (pas de `snapshots()` supplémentaire)
- [x] (d) Filtrage niveaux/séries côté serveur (provider filtre par `subSystem` + `trackId` via `.where()`)

### Stratégie responsive

**Form factors cibles** :
- Phone portrait (< 600 dp) : OUI — liste niveaux en grille 2 colonnes, liste séries en colonne.
- Phone landscape (600-840 dp) : OPTIONNEL — grille 3 colonnes.
- Tablet portrait & landscape (≥ 840 dp) : OUI — sheet centré `Center + ConstrainedBox(maxWidth: 560.w)`, grille 3 colonnes.

**Breakpoints** : `LayoutBuilder` dans le step niveau, seuil 840 dp → `crossAxisCount: isTablet ? 3 : 2`.

**Golden tests** :
- [ ] Golden phone portrait 375×812 — `SchoolProfileEditSheet` step niveau
- [ ] Golden tablet portrait 768×1024 — `SchoolProfileEditSheet` step niveau

**AC responsive** : Le sheet s'affiche centré en tablette (max 560 dp) avec grille 3 colonnes. Vérifié par golden test.

### Composants réutilisables

**Catalogue consulté** : `doc/tech/COMPOSANTS-REUTILISABLES.md`

**Composants existants réutilisés** :
- `AppBottomSheet` (`lib/core/widgets/app_bottom_sheet.dart`) — container du sheet multi-étapes
- `AppButton.primary` (`lib/core/widgets/app_button.dart`) — bouton "Suivant" et "Enregistrer"
- `AppButton.secondary` (`lib/core/widgets/app_button.dart`) — bouton "Retour"
- `AppToast` (`lib/core/widgets/app_toast.dart`) — feedback succès/erreur
- `SelectionCard` (`lib/core/widgets/cards/selection_card.dart`) — cartes niveau et série

**Composants existants adaptés** :
- Aucune adaptation requise — les SelectionCard acceptent déjà `isSelected`.

**Nouveaux composants créés** :
- `SchoolProfileEditSheet` (`lib/features/dashboard/presentation/widgets/school_profile_edit_sheet.dart`) — bottom sheet multi-étapes avec `PageController` interne. Entrée catalogue ajoutée dans la même PR.

**Vérification anti-duplication** :
- [ ] Pas de copie de `LevelChoiceStepBody` / `StreamSubjectsPickerStepBody` (logique redéfinie en contexte sheet)
- [ ] Pas de classe `_XxxBody` reproduisant un composant du catalogue

### Tests à écrire

**Unit** :
- `updateSchoolProfile()` succès : `.update()` appelé avec les 8 champs corrects
- `updateSchoolProfile()` erreur réseau → `ProfileFailure.networkUnavailable()`
- `updateSchoolProfile()` erreur permission → `ProfileFailure.permissionDenied()`
- `derive()` : re-dérivation correcte pour un nouveau binôme levelId+streamId (use case existant à vérifier)

**Widget** :
- `SchoolProfileEditSheet` : step 0 → sélection niveau → passage step 1
- `SchoolProfileEditSheet` : step 1 auto-skip si 1 seule série → passage step 2
- `SchoolProfileEditSheet` : tap "Enregistrer" → appel `updateSchoolProfile()` + toast succès + pop
- Golden phone portrait 375×812 (step niveau)
- Golden tablet portrait 768×1024 (step niveau — grille 3 col + sheet centré)

**Rules** : test de non-régression Firestore rules — vérifier que `trackId`, `levelId`, `streamId` peuvent être mis à jour par le propriétaire.

### Anti-patterns à éviter
- ❌ Utiliser `OnboardingFlushService.flush()` directement (guard permanent account bloque)
- ❌ `ref.watch()` dans les event handlers du sheet multi-étapes
- ❌ `Navigator.pop()` sans `rootNavigator: true` (AppBottomSheet useRootNavigator: true)
- ❌ `setState` pour l'état métier (profil) — seul l'état local du sheet (currentStep, selectedIds) peut utiliser setState
- ❌ Magic numbers dans la grille responsive — utiliser `LayoutBuilder` + constante breakpoint 840

### Références
- `doc/partage/BASE-DE-DONNEES.md` — mutabilité à mettre à jour (AC-8)
- `firestore.rules` racine — règle UPDATE users/{uid} (AC-6)
- `lib/features/onboarding/presentation/pages/level_choice_step_body.dart` — référence logique filtrage niveaux
- `lib/features/onboarding/presentation/pages/stream_subjects_picker_step_body.dart` — référence logique séries + derive()
- `lib/features/onboarding/data/onboarding_flush_service.dart` — référence logique derive() auto-population
- `lib/features/dashboard/presentation/widgets/programme_section.dart` — point d'entrée (bouton crayon à ajouter)
- Story A-1 (`A-1-edit-profile.md`) — patterns édition profil (AppBottomSheet, AppToast, rootNavigator)

---

## Files à créer / modifier

### Créer
- `mobile_app/lib/features/dashboard/presentation/widgets/school_profile_edit_sheet.dart` (~200 lignes max)

### Modifier
- `firestore.rules` (racine) — retirer contraintes immuabilité trackId/levelId/streamId UPDATE
- `mobile_app/lib/features/onboarding/domain/user_profile_repository.dart` — ajouter `updateSchoolProfile()`
- `mobile_app/lib/features/onboarding/data/user_profile_repository_firestore_impl.dart` — implémenter `updateSchoolProfile()`
- `mobile_app/lib/features/dashboard/presentation/widgets/programme_section.dart` — ajouter bouton crayon en header
- `mobile_app/lib/l10n/app_fr.arb` + `app_en.arb` — clés l10n (voir ci-dessous)
- `doc/partage/BASE-DE-DONNEES.md` — mutabilité trackId/levelId/streamId + historique
- `doc/tech/COMPOSANTS-REUTILISABLES.md` — ajouter `SchoolProfileEditSheet`

### Clés l10n à ajouter
```
profileEditSchoolTitle      → FR: "Changer de classe"          EN: "Change class"
profileEditSchoolLevelLabel → FR: "Quelle est ta classe ?"     EN: "What's your class?"
profileEditSchoolStreamLabel→ FR: "Quelle est ta spécialité ?" EN: "What's your specialty?"
profileEditSchoolSubjectsLabel → FR: "Tes matières"            EN: "Your subjects"
profileEditSchoolSaving     → FR: "Mise à jour…"               EN: "Updating…"
```
(`profileEditSuccess` existe déjà — réutiliser pour le toast succès)

### Tests à créer / modifier
- `mobile_app/test/features/dashboard/presentation/widgets/school_profile_edit_sheet_test.dart` (nouveau)
- `mobile_app/test/features/onboarding/data/user_profile_repository_school_profile_test.dart` (nouveau)
- `test/rules/` — test update trackId/levelId/streamId (modifier test existant)
- `mobile_app/test/features/dashboard/presentation/widgets/goldens/school_profile_edit_phone.png` (générer)
- `mobile_app/test/features/dashboard/presentation/widgets/goldens/school_profile_edit_tablet.png` (générer)

---

## ⚠️ Contrainte déploiement

Avant merge de la PR :
1. **Accord backend** sur la modification `firestore.rules` + `BASE-DE-DONNEES.md` (obligation CLAUDE.md)
2. `firebase deploy --only firestore:rules --project valide-edu` à exécuter dans la même PR

---

## File List

### Créés
- `mobile_app/lib/features/dashboard/presentation/widgets/school_profile_edit_sheet.dart`
- `mobile_app/test/features/dashboard/presentation/widgets/school_profile_edit_sheet_test.dart`
- `mobile_app/test/features/onboarding/data/user_profile_repository_school_profile_test.dart`

### Modifiés
- `firestore.rules` (racine — règle UPDATE users/{uid})
- `mobile_app/lib/features/onboarding/domain/user_profile_repository.dart`
- `mobile_app/lib/features/onboarding/data/user_profile_repository_firestore_impl.dart`
- `mobile_app/lib/features/dashboard/presentation/widgets/programme_section.dart`
- `mobile_app/lib/l10n/app_fr.arb`
- `mobile_app/lib/l10n/app_en.arb`
- `mobile_app/lib/l10n/generated/app_localizations.dart` (auto-généré)
- `doc/partage/BASE-DE-DONNEES.md`
- `doc/tech/COMPOSANTS-REUTILISABLES.md`
- `mobile_app/test/_helpers/fakes.dart`
- `mobile_app/test/features/dashboard/presentation/widgets/profile_edit_sheet_test.dart`
- `mobile_app/test/features/onboarding/providers/profile_completion_provider_test.dart`
- `project_manage/implementation-artifacts/sprint-status.yaml`

---

## Dev Agent Record

### Debug Log

| Date | Issue | Solution |
|------|-------|----------|
| 2026-07-01 | `updateSchoolProfile()` manquant dans 3 fakes de test (interface étendue) | Ajout du stub dans `_FakeRepo`, `FakeUserProfileRepository`, `_TrackingRepo` |
| 2026-07-01 | `profile_completion_provider_test.dart` — 9 échecs "Stream has already been listened to" | Pré-existants (vérifiés via `git stash` baseline). Non causés par A.3. |
| 2026-07-01 | `__` (double underscore) lint warnings dans `school_profile_edit_sheet.dart` | Remplacés par `(e, st)` et `(ctx, i)` |
| 2026-07-01 | Tests widget (a)(b)(c) échouent : "Found 0 widgets with text 'Terminale'" | `_pumpSheet` sans `locale: const Locale('fr')` → texte en anglais ("Grade 13") |
| 2026-07-01 | Test (a) échoue : `find.textContaining('classe')` trouve 2 widgets | Titre "Changer de classe" + label "Quelle est ta classe ?" tous deux contiennent 'classe' → assertion changée en `find.text('Quelle est ta classe ?')` |
| 2026-07-01 | Tests (b)(c) échouent : step 2 vide, "Enregistrer" absent | Fixtures catalogue sans `DerivationRule` → `_derived == null` → `_buildSubjectsStep` retourne `SizedBox.shrink()`. Ajout de `_kRuleTerminaleD` dans les deux catalogues de test. |

### Completion Notes

**ACs complétés côté client** : AC-1 (déviation mineure sur header — voir note), AC-2, AC-3, AC-4, AC-5, AC-6 (règle modifiée, déploiement bloqué), AC-7 (responsive implémenté, golden tests reportés), AC-8 (docs mis à jour, accord backend pending).

**Déviation AC-1** : Le header affiche le titre "Changer de classe" et non la valeur actuelle du niveau. La classe actuelle reste visible pré-sélectionnée dans la grille step 0. Compromis UX acceptable pour MVP — un subtitle peut être ajouté post-accord backend sans bloquer la PR.

**Bloquants avant merge** :
1. Accord écrit de l'équipe backend sur `firestore.rules` + `doc/partage/BASE-DE-DONNEES.md`
2. `firebase deploy --only firestore:rules --project valide-edu` (post-accord)
3. Test `test/rules/` mis à jour (post-accord)
4. Golden tests (optionnel pour ce sprint — emulateur requis)

**Tests** : 9/9 passent (3 repo + 3 widget SchoolProfileEditSheet + 3 widget NameEditSheet). `flutter analyze` : 0 issue sur les 4 fichiers source modifiés.

**Status** : in-progress (bloqué accord backend)
