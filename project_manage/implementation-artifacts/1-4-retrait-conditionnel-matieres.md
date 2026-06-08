---
story_id: 1.4
title: Retrait conditionnel matières (FR-3)
epic: 1
phase: P1
status: done
created: 2026-06-08
merged: 2026-06-08  # PR #48 -> commit 839d2c9
branch: feat/1.4-retrait-conditionnel-matieres
baseline_commit: 28ce9e0  # merge PR #47 (cloture 1.5 + contexte 1.4)
estimation: S (~3h)
dependencies:
  - 1.3   # Profil créé : users/{uid} avec derivedSubjects + optedOutSubjects:[] initial
  - 1.1c  # CatalogueRepository (lit DerivedProfile.canOptOut depuis dérivation_rules.canOptOut)
  - 0.9   # Règles Firestore users/{uid} update (Story 1.3 a fixé subSystem/filiere/niveau/serie ; Story 1.4 valide optedOutSubjects ⊆ derivedSubjects)
  - 0.13  # AppButton + AppCard
  - 0.14  # AppToast (toast erreur Firestore)
blocks:
  - 1.9   # Dashboard skeleton : filtrage matières utilise `derivedSubjects \ optedOutSubjects`
sourceArtifacts:
  - project_manage/planning-artifacts/epics/epic-1-onboarding.md § Story 1.4 (lignes 565-642)
  - project_manage/planning-artifacts/prds/prd-valide-mvp-2026-06-03/prd.md § FR-3 (lignes 133-141)
  - project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/EXPERIENCE.md § "Empty matières" (ligne 155) + "Profil incomplet" (ligne 96)
  - doc/partage/BASE-DE-DONNEES.md § users/{uid}.optedOutSubjects (ligne 70 — sous-ensemble strict de derivedSubjects)
  - doc/partage/ALGORITHMES.md § 1 (règles dérivation + canOptOut transitif via DerivationRule)
  - mobile_app/lib/core/catalogue/domain/models.dart § DerivedProfile (canOptOut bool — Story 1.1c lignes 240-252)
  - mobile_app/lib/features/onboarding/domain/user_profile_repository.dart (interface — Story 1.3 expose createProfile/watchProfile, Story 1.4 ajoute updateOptedOutSubjects)
  - mobile_app/lib/features/onboarding/data/user_profile_repository_firestore_impl.dart (impl Firestore à étendre)
  - mobile_app/lib/features/onboarding/presentation/profile_recap_page.dart (lien "Retirer une matière" Story 1.3 ligne 246-255 actuellement no-op à activer)
  - mobile_app/lib/core/routing/app_router.dart (ajout route /onboarding/profile/opt-out)
  - firestore.rules (racine — bloc users/{uid} update Story 1.3 à enrichir avec validation optedOutSubjects ⊆ derivedSubjects)
  - test/rules/users.test.mjs (helper validUserDoc + tests update à étendre)
---

# Story 1.4 — Retrait conditionnel matières (FR-3)

Status: **done**

## Objectif

Livrer **la dernière brique du profil scolaire** : permettre aux élèves dont les règles l'autorisent (anglophones ≥ Form 3, Lower/Upper Sixth toutes filières) de retirer des matières de leur liste dérivée — celles qu'ils ne présenteront pas à leur examen. Sur l'écran récap (Story 1.3), le lien « Retirer une matière » devient actif et ouvre une page de cases à cocher. La sélection persiste dans `users/{uid}.optedOutSubjects` Firestore.

**Pourquoi** : FR-3 + ALGORITHMES.md. Sans Story 1.4, un élève anglophone Form 5 voit ses 13 matières par défaut → dashboard pollué, classements faussés, expérience UX dégradée. Story 1.4 c'est la pertinence du contenu pour la moitié anglophone du marché.

**Critère de fin** :

- James (anglophone, Upper Sixth, série S2) ouvre son récap → voit ses 3 matières dérivées + lien « Retirer une matière » visible
- Il tape le lien → `SubjectsOptOutPage` s'ouvre avec 3 cases (toutes décochées par défaut)
- Il coche « Biology » → tap « Valider » → `users/{uid}.optedOutSubjects = ['anglophone_biology']` posé en Firestore
- Retour récap → grille filtrée affiche 2 matières restantes + libellé du lien devient « Modifier mes matières »

Fatou (francophone, Terminale D) : aucun lien visible, l'AC5 garantit l'absence du chemin.

## Story

**As a** élève dont le profil autorise le retrait (anglophone ≥ Form 3, ou Lower/Upper Sixth toutes filières),
**I want** pouvoir cocher les matières que je ne présenterai pas à mon examen pour les retirer de ma liste dérivée,
**so that** mon dashboard, mes classements et mes recommandations soient pertinents par rapport à ce que je prépare réellement (FR-3).

## Acceptance Criteria

### AC1 — `DerivedProfile.canOptOut` source autoritative (pas de helper Dart)

**Given** un profil créé en Story 1.3 (`derivedProfileProvider` retourne `Right(DerivedProfile)`)
**When** la page récap inspecte `profile.canOptOut`
**Then** la valeur vient **directement du catalogue Firestore** :

- `derivation_rules` matche le profil → l'attribut `canOptOut` de la règle est propagé sur `DerivedProfile.canOptOut`
- **Pas de helper Dart `_canOptOut(subSystem, niveau, filiere)`** — l'amendement sprint 2026-06-05 de l'epic supprime ce helper. La règle est dans le catalogue Firestore (script seed Story 1.1b), source unique de vérité.
- Mapping attendu (cohérent avec ALGORITHMES.md § 1 + DONNEES-REFERENCE.md) :
  - Francophone, 6ᵉ → Terminale toutes filières → `canOptOut = false`
  - Anglophone, Form 1-2 → `canOptOut = false`
  - Anglophone, Form 3-5 → `canOptOut = true`
  - Anglophone, Lower Sixth + Upper Sixth toutes séries → `canOptOut = true`

**And** un test smoketest Python ad-hoc (`scripts/firebase_seed/tests/test_canoptout_distribution.py` OU vérification manuelle ad-hoc avec firebase-admin) confirme que le seed Story 1.1b a bien posé `canOptOut` selon ces règles. **Hors scope Story 1.4** si déjà validé Story 1.1b — sinon ajouter une vérification rapide en cours de dev.

**Justification** : Story 1.1b a déjà seedé `derivation_rules` avec le champ `canOptOut`. Story 1.1c a déjà mappé ce champ vers `DerivedProfile.canOptOut`. Story 1.3 expose déjà la valeur via `derivedProfileProvider`. **Donc Story 1.4 NE TOUCHE PAS** au modèle, ni au repository catalogue, ni au script seed. Elle consomme l'existant.

### AC2 — `SubjectsOptOutPage` route `/onboarding/profile/opt-out`

**Given** route `/onboarding/profile/opt-out`
**When** la page se rend
**Then** elle affiche :

- Header : titre H2 « Choisis tes matières » (FR) / « Pick your subjects » (EN). Tutoiement.
- Sous-titre court : « Décoche celles que tu ne présentes pas. » (FR) / « Uncheck the ones you're not taking. » (EN)
- **Liste verticale** (`ListView.separated`) des matières de `DerivedProfile.subjects` avec :
  - Une `CheckboxListTile` par matière
  - **Coché par défaut = matière incluse** (présentée à l'examen)
  - **Décoché = retirée** (ajoutée à `optedOutSubjects`)
  - Subtitle de chaque ligne : icône Lucide (mapping Story 1.3 `_iconFor`) + nom localisé (`subject.name[langKey]`)
- Compteur en bas : « Tu présentes {N} matières sur {total} » (FR) / « You'll take {N} of {total} subjects » (EN) — pluralisé via ICU
- **Bouton primaire « Valider »** :
  - `disabled` si N == 0 (tout décoché = invalide)
  - `loading` pendant le save Firestore
- **Bouton secondaire « Annuler »** → retour sans modification (`context.pop()` ou nav explicit vers `/onboarding/profile/recap`)

**And** la page lit `derivedProfileProvider` (Story 1.3) pour obtenir la liste de matières — **pas de re-lecture catalogue**, on consomme le profil déjà dérivé.

**And** la page lit `users/{uid}.optedOutSubjects` (via `userProfileRepository.watchProfile()` — Story 1.5) pour pré-populer l'état des checkboxes (utile si l'utilisateur revient modifier après avoir déjà validé une fois).

**And** la page est responsive 3 form factors :

- Phone : ListView pleine largeur
- Tablet : ListView centrée `maxWidth: 720`
- Pas de pixel hardcodé hors `flutter_screenutil`

### AC3 — Persistance Firestore : `userProfileRepository.updateOptedOutSubjects(...)`

**Given** une sélection de matières retirées
**When** l'utilisateur tape « Valider »
**Then** un nouvel appel est exposé sur `UserProfileRepository` (extension Story 1.4) :

```dart
abstract interface class UserProfileRepository {
  // existant Stories 1.3 + 1.5
  Future<Either<ProfileFailure, void>> createProfile({...});
  Stream<Map<String, dynamic>?> watchProfile();

  // Story 1.4 — NEW
  /// Met à jour le champ `optedOutSubjects` du doc users/{uid}.
  /// Utilise update() partiel (pas set merge) pour ne toucher que ce champ
  /// + `updatedAt` serverTimestamp. Validation côté serveur (AC4) garantit
  /// `optedOutSubjects ⊆ derivedSubjects`.
  Future<Either<ProfileFailure, void>> updateOptedOutSubjects(
    List<String> optedOutSubjectIds,
  );
}
```

**Impl Firestore** (`UserProfileRepositoryFirestoreImpl`) :

```dart
@override
Future<Either<ProfileFailure, void>> updateOptedOutSubjects(
  List<String> optedOutSubjectIds,
) async {
  final uid = _getUid();
  if (uid == null) {
    AppLogger.w('updateOptedOutSubjects() aborted: no current user uid');
    return const Left(ProfileFailure.notAuthenticated());
  }
  try {
    await _firestore.collection(_kCollection).doc(uid).update({
      'optedOutSubjects': optedOutSubjectIds,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    AppLogger.i(
      'Subjects opted out: count=${optedOutSubjectIds.length}',
    );
    return const Right(null);
  } on FirebaseException catch (e, st) {
    AppLogger.w('updateOptedOutSubjects() FirebaseException: ${e.code}');
    return Left(ProfileFailure.firestoreError(e.message ?? e.code));
  } catch (e, st) {
    AppLogger.w('updateOptedOutSubjects() unexpected: $e');
    return Left(ProfileFailure.firestoreError(e.toString()));
  }
}
```

**Sécurité log (CLAUDE.md § 4)** : on log `count`, **JAMAIS** la liste des IDs (qui peut identifier l'utilisateur en croisant avec son profil scolaire si on suppose un attaquant qui aurait accès à des logs partiels). `subjects=N` est neutre.

**And** un test `user_profile_repository_test.dart` étendu avec 3 cas :

- (k) `updateOptedOutSubjects([])` sur doc existant → met à jour le champ + updatedAt
- (l) `updateOptedOutSubjects([...])` sans uid → `Left(ProfileFailure.notAuthenticated)`
- (m) `updateOptedOutSubjects([...])` sur doc absent → `Left(ProfileFailure.firestoreError)` (update sur doc inexistant échoue côté Firestore)

### AC4 — Règles Firestore : `optedOutSubjects ⊆ derivedSubjects`

**Given** le fichier `firestore.rules` racine (Story 1.3 a posé les immutabilités subSystem/filiere/niveau/serie/createdAt)
**When** on étend la règle `match /users/{uid}` update pour Story 1.4
**Then** ajouter une validation pour `optedOutSubjects` :

```javascript
allow update: if isOwner(uid)
  && request.resource.data.subSystem == resource.data.subSystem
  && request.resource.data.language == resource.data.language
  && request.resource.data.filiere == resource.data.filiere
  && request.resource.data.niveau == resource.data.niveau
  && request.resource.data.serie == resource.data.serie
  && request.resource.data.createdAt == resource.data.createdAt
  // Story 1.4 — NEW : optedOutSubjects doit être un sous-ensemble de derivedSubjects
  && (
    !('optedOutSubjects' in request.resource.data.diff(resource.data).affectedKeys())
    || request.resource.data.optedOutSubjects is list
    && request.resource.data.optedOutSubjects.toSet().difference(
         request.resource.data.derivedSubjects.toSet()
       ).size() == 0
  );
```

**Note technique Firestore Security Rules** :

- `diff()` + `affectedKeys()` permet de vérifier si le champ est modifié dans la requête courante (skip la validation si l'update ne touche pas `optedOutSubjects`)
- `toSet().difference()` → ensemble des éléments en trop dans `optedOutSubjects` qui ne sont pas dans `derivedSubjects`
- `.size() == 0` → autorisé seulement si l'ensemble en trop est vide (donc strict sous-ensemble)

**And** `test/rules/users.test.mjs` enrichi avec **2 nouveaux tests** :

- `(j) update optedOutSubjects valide (sous-ensemble strict) → OK`
- `(k) update optedOutSubjects invalide (matière non dans derivedSubjects) → KO`

**And** `cd test/rules && npm test` → 14 tests verts (12 existants + 2 nouveaux).

**And** déployer les règles : `firebase deploy --only firestore:rules --project valide-edu`.

### AC5 — Filtrage récap : `derivedSubjects \ optedOutSubjects`

**Given** l'utilisateur revient à l'écran récap (Story 1.3) après avoir validé une sélection avec opt-out
**When** `ProfileRecapPage` se rend
**Then** :

- La grille affiche **uniquement** les matières restantes (`derivedSubjects` filtré sans `optedOutSubjects`)
- Le compteur ICU « Tu présentes {N} matières » reflète le N filtré (ex. 7 → 5 si 2 matières retirées)
- Le libellé du lien change : `onboardingRecapModifyLink` au lieu de `onboardingRecapOptOutLink` quand `optedOutSubjects` est non vide (« Modifier mes matières » / « Edit my subjects »)
- Si l'utilisateur retire tout puis revient (cas théorique car AC2 bloque le bouton si N==0) — le compteur affiche « 0 matière » + alerte visuelle. **Hors scope V1** : le bouton « Valider » de SubjectsOptOutPage interdit déjà N==0, donc ce cas n'arrive pas en pratique.

**Implémentation** : dans `_RecapDataView`, lire `users/{uid}.optedOutSubjects` via un nouveau `Provider` ou en ajoutant `optedOutSubjects` au `DerivedProfile` consommé. **Option retenue** : un provider dédié `effectiveDerivedSubjectsProvider` qui combine `derivedProfileProvider` + `userProfileRepository.watchProfile()` → retourne `List<Subject>` filtrée.

```dart
final effectiveDerivedSubjectsProvider = StreamProvider<List<Subject>>((ref) {
  final derivedAsync = ref.watch(derivedProfileProvider);
  final profileStream = ref.watch(userProfileRepositoryProvider).watchProfile();

  return derivedAsync.maybeWhen(
    data: (either) => either.fold(
      (_) => const Stream<List<Subject>>.empty(),
      (profile) => profileStream.map((data) {
        final optedOut = (data?['optedOutSubjects'] as List?)?.cast<String>() ?? const [];
        return profile.subjects
            .where((s) => !optedOut.contains(s.subjectId))
            .toList(growable: false);
      }),
    ),
    orElse: () => const Stream<List<Subject>>.empty(),
  );
});
```

### AC6 — Cas francophone Première C : pas de lien

**Given** un profil francophone Première série C (`derivedRules.canOptOut == false`)
**When** `ProfileRecapPage` se charge
**Then** **aucun** lien « Retirer une matière » ou « Modifier mes matières » n'est affiché
**And** la route `/onboarding/profile/opt-out` reste techniquement accessible mais **garde in-component** : si `!profile.canOptOut`, `SubjectsOptOutPage` redirige immédiatement vers `/onboarding/profile/recap` + log warn (`AppLogger.w('OptOut tentée sur profil non éligible: subSystem=X niveau=Y')`)
**And** un test widget vérifie l'absence du lien pour Fatou (francophone Tle D) + un test widget vérifie sa présence pour James (anglophone Upper Sixth S2).

### AC7 — i18n + tests Flutter + qualité

**Given** la PR finalisée
**When** on exécute la validation
**Then** :

- **i18n** : ~5 nouvelles clés ARB FR + EN :
  - `onboardingOptOutTitle` ("Choisis tes matières" / "Pick your subjects")
  - `onboardingOptOutSubtitle` ("Décoche celles que tu ne présentes pas." / "Uncheck the ones you're not taking.")
  - `onboardingOptOutTakingCount` plural ICU ("{N} matières sur {total}" / "{N} of {total} subjects")
  - `onboardingOptOutValidateCta` ("Valider" / "Save")
  - `onboardingRecapModifyLink` ("Modifier mes matières" / "Edit my subjects")
- **Tests** :
  - `test/features/onboarding/data/user_profile_repository_test.dart` : +3 cas (k/l/m AC3)
  - `test/features/onboarding/presentation/subjects_opt_out_page_test.dart` : NEW ~3 cas (page rendue + tap save + bouton disabled si tout décoché)
  - `test/features/onboarding/presentation/profile_recap_page_test.dart` : +2 cas (lien visible canOptOut=true + filtrage grille post-optedOut)
- `flutter analyze` 0 issue
- `flutter test` vert (145 baseline Story 1.5 → ~155 cible Story 1.4)
- `cd test/rules && npm test` → 14/14 verts (12 existants + 2 nouveaux)
- **PR ≤ 250 lignes diff** hors l10n générée + .mjs tests
- Commit : `feat(onboarding): retrait conditionnel matieres FR-3 (Story 1.4)`

## Tasks / Subtasks

- [x] **T1 — Domain : étendre `UserProfileRepository` interface** (AC3)
  - [x] T1.1 — Ouvrir `mobile_app/lib/features/onboarding/domain/user_profile_repository.dart`
  - [x] T1.2 — Ajouter signature `Future<Either<ProfileFailure, void>> updateOptedOutSubjects(List<String>)` avec docstring
  - [x] T1.3 — Domain pur — pas d'import Firebase

- [x] **T2 — Data : implémenter `updateOptedOutSubjects()`** (AC3)
  - [x] T2.1 — Ouvrir `mobile_app/lib/features/onboarding/data/user_profile_repository_firestore_impl.dart`
  - [x] T2.2 — Ajouter méthode `updateOptedOutSubjects(List<String>)` :
    - `_getUid()` null → `Left(ProfileFailure.notAuthenticated)` + log warn
    - `_firestore.doc(...).update({'optedOutSubjects': ids, 'updatedAt': FieldValue.serverTimestamp()})`
    - try/catch FirebaseException → `Left(ProfileFailure.firestoreError)`
    - Log `count`, JAMAIS la liste des IDs (CLAUDE.md § 4)
  - [x] T2.3 — Test `user_profile_repository_test.dart` : 3 cas (k/l/m AC3) via `FakeFirebaseFirestore`

- [x] **T3 — Providers : `effectiveDerivedSubjectsProvider`** (AC5)
  - [x] T3.1 — Étendre `mobile_app/lib/features/onboarding/providers.dart`
  - [x] T3.2 — Créer `effectiveDerivedSubjectsProvider` : `StreamProvider<List<Subject>>` qui combine `derivedProfileProvider` + `userProfileRepository.watchProfile()` pour filtrer matières retirées
  - [x] T3.3 — Test unitaire dans `profile_completion_provider_test.dart` style (override deps + verify filtered output)

- [x] **T4 — Présentation : `SubjectsOptOutPage`** (AC2, AC6 garde in-component)
  - [x] T4.1 — Créer `mobile_app/lib/features/onboarding/presentation/subjects_opt_out_page.dart` : `ConsumerStatefulWidget`
  - [x] T4.2 — Guard : si `!derivedProfile.canOptOut` → redirect `/onboarding/profile/recap` + AppLogger.w (subSystem + niveau, jamais uid)
  - [x] T4.3 — Header titre + sous-titre i18n
  - [x] T4.4 — `ListView.separated` de `CheckboxListTile` :
    - Pré-populer état initial depuis `users/{uid}.optedOutSubjects` (watchProfile)
    - Coché = inclus, décoché = retiré
    - Icône Lucide (réutiliser `_iconFor` de Story 1.3 — extraire en helper partagé `lib/features/onboarding/presentation/_subject_icons.dart`)
  - [x] T4.5 — Compteur ICU « {N} matières sur {total} » en bas (sticky ou normal)
  - [x] T4.6 — Bouton primaire « Valider » :
    - `disabled` si N == 0 (toutes les matières décochées)
    - `loading` pendant le save
    - Appelle `userProfileRepository.updateOptedOutSubjects(opted)`
    - Succès → `context.go('/onboarding/profile/recap')`
    - Échec → AppToast.show + state local préservé
  - [x] T4.7 — Bouton secondaire « Annuler » → `context.go('/onboarding/profile/recap')` sans save
  - [x] T4.8 — Responsive : `LayoutBuilder` + `ConstrainedBox(maxWidth: 720)` sur tablet

- [x] **T5 — Routing : route `/onboarding/profile/opt-out`** (AC2)
  - [x] T5.1 — Étendre `mobile_app/lib/core/routing/app_router.dart`
  - [x] T5.2 — Ajouter `GoRoute(path: '/onboarding/profile/opt-out', builder: ...)` (bypass /onboarding/* dans le redirect Story 1.5, donc aucune garde supplémentaire)
  - [x] T5.3 — Activer le lien dans `profile_recap_page.dart` : remplacer le no-op + log par `context.go('/onboarding/profile/opt-out')`
  - [x] T5.4 — Adapter le libellé du lien selon `optedOutSubjects.isEmpty` :
    - `[]` → `onboardingRecapOptOutLink` ("Retirer une matière")
    - non vide → `onboardingRecapModifyLink` ("Modifier mes matières")

- [x] **T6 — Filtrage récap : grille basée sur `effectiveDerivedSubjects`** (AC5)
  - [x] T6.1 — Dans `profile_recap_page.dart`, remplacer `profile.subjects` par `ref.watch(effectiveDerivedSubjectsProvider)` (AsyncValue.when)
  - [x] T6.2 — Compteur `onboardingRecapSubjectsCount` reflète la liste filtrée
  - [x] T6.3 — Si la liste filtrée est en `loading`, fallback sur `profile.subjects` (évite flash)

- [x] **T7 — i18n** (AC7)
  - [x] T7.1 — Ajouter 5 clés dans `mobile_app/lib/l10n/app_fr.arb` (avec descriptions)
  - [x] T7.2 — Versions EN équivalentes (informal, UX-DR-39)
  - [x] T7.3 — `flutter gen-l10n` régénère AppLocalizations

- [x] **T8 — firestore.rules + tests rules** (AC4)
  - [x] T8.1 — Modifier `firestore.rules` racine pour étendre `match /users/{uid}` update avec validation `optedOutSubjects ⊆ derivedSubjects` (cf. AC4 syntax)
  - [x] T8.2 — Modifier `test/rules/users.test.mjs` :
    - Ajouter 2 tests : (j) update opted valide → OK, (k) update opted invalide → KO
  - [x] T8.3 — `cd test/rules && npm test` → 14 tests verts
  - [x] T8.4 — Déployer : `firebase deploy --only firestore:rules --project valide-edu`

- [x] **T9 — Tests Flutter** (AC7)
  - [x] T9.1 — `test/features/onboarding/data/user_profile_repository_test.dart` étendu (3 cas k/l/m)
  - [x] T9.2 — `test/features/onboarding/presentation/subjects_opt_out_page_test.dart` : NEW (3 cas — page rendue + tap save + disabled si vide)
  - [x] T9.3 — `test/features/onboarding/presentation/profile_recap_page_test.dart` étendu (2 cas — lien visible canOptOut=true + filtrage grille)

- [x] **T10 — Validation finale**
  - [x] T10.1 — `flutter analyze` → 0 issue
  - [x] T10.2 — `flutter test` → tous verts (~155 cible)
  - [x] T10.3 — `cd test/rules && npm test` → 14/14 verts
  - [x] T10.4 — Diff PR ≤ 250 lignes (hors l10n générée + .mjs)
  - [x] T10.5 — Update story file frontmatter status review + sprint-status backlog → ready-for-dev → review + commit + push

## Dev Notes

### Architecture compliance (ADR-001 + ADR-006 + ADR-015)

- **Règle d'or domaine** : pas d'import Firebase dans `domain/`. L'interface UserProfileRepository reste pure.
- **NFR-7** : aucune exception Firestore ne remonte à l'UI. `Either<ProfileFailure, void>` + traduction dans le repo impl.
- **ADR-015 (catalogue Firestore-driven)** : `canOptOut` vient du catalogue, pas d'un helper Dart. Aligné amendement sprint 2026-06-05.
- **ADR-006 (subSystem immutable)** : Story 1.4 ne touche pas subSystem/filiere/niveau/serie. Seul `optedOutSubjects` est modifiable.

### Anti-pattern : NE PAS créer de helper `_canOptOut(subSystem, niveau, filiere)`

L'epic V1 mentionnait un helper Dart hardcoded. **L'amendement sprint 2026-06-05 l'a supprimé**. La règle est dans Firestore (`derivation_rules.canOptOut`). Si tu écris un helper Dart, tu duplique la source de vérité — futur drift garanti.

**Si Story 1.1b a oublié de seeder `canOptOut` correctement**, ne PAS ajouter un fallback Dart. Au lieu de ça :

1. Documenter la lacune en suggestion ouverte
2. Mettre à jour `data/matrice.json` + re-seed via le script Python
3. Reprendre Story 1.4 après le re-seed

### Anti-pattern : NE PAS utiliser set(merge: true) pour l'update

Story 1.3 utilise `set(merge: true)` pour la création (idempotent). Story 1.4 utilise `update({...})` pour la modification :

- `update()` échoue si le doc n'existe pas → garde implicite contre les races
- `update()` partiel ne touche que les champs cités → preserve `displayName`, `schoolId`, etc.

### Anti-pattern : NE PAS logger la liste des IDs retirés

`AppLogger.i('Subjects opted out: anglophone_biology,anglophone_chemistry')` est une **fuite indirecte d'identité** : si l'attaquant a un fragment de log, il peut profiler l'utilisateur (combinaison niveau + matières retirées peut identifier une classe = un élève).

Pattern correct : `AppLogger.i('Subjects opted out: count=2')` — neutre.

### Pattern : `effectiveDerivedSubjectsProvider` plutôt que filtrer dans la widget

Tentation : filtrer la liste dans le `build()` du `_RecapDataView`. Mauvais pattern :

- Logique métier dans la présentation
- Difficile à tester
- Re-calcul à chaque rebuild

Pattern correct : un `StreamProvider` dédié qui combine `DerivedProfile.subjects` + `users/{uid}.optedOutSubjects` et expose une `List<Subject>` filtrée. Le widget consomme un AsyncValue → testable + mémoïsé Riverpod.

### Edge case : optedOutSubjects écrit AVANT que derivedSubjects soit posé

Théorique mais imaginable : un script externe écrit `optedOutSubjects` sur un doc sans `derivedSubjects`. La règle Firestore (AC4) doit gérer ce cas : si `derivedSubjects` absent ou vide, `toSet().difference(...)` lève une erreur ou retourne vide. **Comportement attendu** : refuser l'update (`difference.size() != 0` ou erreur).

**À tester via test rules** : créer un doc sans `derivedSubjects` (admin SDK bypass), puis tenter un update `optedOutSubjects = ['x']` côté client → doit échouer.

**Décision V1** : Story 1.3 garantit `derivedSubjects` posé à la création. Cas edge théorique non bloquant. Si la règle Firestore le couvre proprement (default vide + sous-ensemble OK), on est bon.

### Sécurité CLAUDE.md § 4

- **JAMAIS** logger l'uid complet
- **JAMAIS** logger la liste des optedOutSubjects (combinaison identifiante)
- **OK** de logger `subSystem`, `niveau`, `count` (statistiques agrégées)

### Réutilisation `_iconFor` Story 1.3

Le helper `_iconFor(String iconName) -> IconData` est privé dans `profile_recap_page.dart`. Story 1.4 a besoin du même mapping pour `SubjectsOptOutPage`.

**Refactor mineur** : extraire en helper public `lib/features/onboarding/presentation/_subject_icons.dart` :

```dart
IconData subjectIconFor(String iconName) {
  return switch (iconName) {
    'function-square' => LucideIcons.functionSquare,
    'atom' => LucideIcons.atom,
    // ... idem Story 1.3
    _ => LucideIcons.bookOpen,
  };
}
```

Et importer dans les 2 pages. Pas de regression — la liste reste identique.

### File List

**Nouveaux** :

- `mobile_app/lib/features/onboarding/presentation/subjects_opt_out_page.dart` (~180 lignes)
- `mobile_app/lib/features/onboarding/presentation/_subject_icons.dart` (~30 lignes — helper extrait)
- `mobile_app/test/features/onboarding/presentation/subjects_opt_out_page_test.dart` (~120 lignes — 3 cas)

**Modifiés** :

- `mobile_app/lib/features/onboarding/domain/user_profile_repository.dart` (+~10 lignes — signature updateOptedOutSubjects)
- `mobile_app/lib/features/onboarding/data/user_profile_repository_firestore_impl.dart` (+~30 lignes — impl + try/catch)
- `mobile_app/lib/features/onboarding/providers.dart` (+~30 lignes — effectiveDerivedSubjectsProvider)
- `mobile_app/lib/features/onboarding/presentation/profile_recap_page.dart` (+~20 lignes — switch link + use effectiveDerivedSubjects + extract _iconFor)
- `mobile_app/lib/core/routing/app_router.dart` (+~5 lignes — 1 GoRoute)
- `mobile_app/lib/l10n/app_fr.arb` (+~20 lignes — 5 clés avec descriptions)
- `mobile_app/lib/l10n/app_en.arb` (+~10 lignes — 5 clés)
- `mobile_app/lib/l10n/generated/app_localizations*.dart` (+~50 lignes auto gen-l10n)
- `firestore.rules` (+~10 lignes — validation optedOutSubjects ⊆ derivedSubjects)
- `test/rules/users.test.mjs` (+~50 lignes — 2 nouveaux tests j/k)
- `mobile_app/test/features/onboarding/data/user_profile_repository_test.dart` (+~70 lignes — 3 cas k/l/m)
- `mobile_app/test/features/onboarding/presentation/profile_recap_page_test.dart` (+~50 lignes — 2 cas canOptOut + filtrage)
- `project_manage/implementation-artifacts/1-4-retrait-conditionnel-matieres.md` (frontmatter + Tasks + Dev Agent Record)
- `project_manage/implementation-artifacts/sprint-status.yaml`

### Change Log

| Date | Auteur | Modification |
|---|---|---|
| 2026-06-08 | Claude Opus 4.7 | Story 1.4 contexte engine créé — comprehensive developer guide |
| 2026-06-08 | Claude Opus 4.7 (Amelia) | Dev complete — 10 tasks done. PR pending. |

## Dev Agent Record

### Implementation Plan
Workflow `/bmad-dev-story` exécuté sur baseline `28ce9e0` (merge PR #47). 10 tâches enchaînées dans l'ordre T1→T2→T3→T7→T4→T5→T6→T8→T9→T10 (T7 i18n avancé avant T4 pour que la page consomme les clés générées directement).

### Completion Notes

**T1 Domain** : Signature `updateOptedOutSubjects(List<String>)` ajoutée à l'interface `UserProfileRepository` (clean architecture — pas d'import Firebase dans le domain).

**T2 Data** : Impl Firestore avec `update()` partiel (pas `set(merge:true)` — anti-pattern documenté). Log `count` seul (jamais la liste des IDs — fuite identité CLAUDE.md § 4). 3 tests fake_cloud_firestore verts (k/l/m).

**T3 Providers** : `effectiveDerivedSubjectsProvider` (StreamProvider) combine `derivedProfileProvider` + `watchProfile()` pour exposer `List<Subject>` filtrée. 4 tests verts (override deps + polling pattern Story 1.5).

**T4 Page** : `SubjectsOptOutPage` (`ConsumerStatefulWidget`) + guard in-component `!profile.canOptOut` → redirect /onboarding/profile/recap. State local `Set<String>? _optedOut` initialisé une fois depuis stream `watchProfile()`. Helper `_subject_icons.dart` extrait (partagé recap + opt-out). Bug initial : StreamBuilder initialisait _optedOut avant 1er event → corrigé via guard `connectionState == waiting && !hasData`.

**T5 Routing** : Route `/onboarding/profile/opt-out` ajoutée (bypassée par la garde 1.5 — toutes `/onboarding/*` le sont). Lien dans recap remplace le no-op + log par `context.go(...)`. Libellé bascule `onboardingRecapOptOutLink` → `onboardingRecapModifyLink` via `StreamBuilder` sur `optedOutSubjects.isNotEmpty`.

**T6 Filtrage récap** : `_RecapDataView` consomme `effectiveDerivedSubjectsProvider` avec fallback `profile.subjects` si AsyncValue n'est pas en data (évite flash).

**T7 i18n** : 5 nouvelles clés FR + EN. Compteur ICU pluralisé `onboardingOptOutTakingCount` avec 2 placeholders (count + total). `flutter gen-l10n` régénéré silencieusement (l10n.yaml).

**T8 firestore.rules** : Validation `optedOutSubjects ⊆ derivedSubjects` ajoutée sur `match /users/{uid}` update, guardée par `diff().affectedKeys()` (skip si le champ n'est pas dans la requête). Déployée sur `valide-edu` via `firebase deploy --only firestore` (depuis racine, pas mobile_app). 14 tests rules verts (12 existants + j/k Story 1.4). Bug initial : test (j) avec `setDoc` complet violait l'immutabilité `createdAt` → switch en `updateDoc` partiel pour aligner sur l'impl Story 1.4.

**T9 Tests Flutter** : `_FakeRepo` ajouté à `profile_recap_page_test.dart` (override `userProfileRepositoryProvider` — sinon le watch sur `userProfileRepositoryProvider` instancie `FirebaseAuth.instance` qui crash en test sans init Firebase). 2 nouveaux tests (canOptOut=true lien visible + filtrage grille). `subjects_opt_out_page_test.dart` NEW (3 tests a/b/c). Test (c) corrigé : `widgetWithText(AppButton, 'Save')` au lieu de `ElevatedButton` (AppButton wrappe `Pressable`, pas Material).

**T10 Validation** :
- `flutter analyze` → 0 issue (incl. fix concrete impl manquante dans `profile_completion_provider_test.dart` _FakeRepo)
- `flutter test` → 156 passed + 1 skipped (vs baseline 144, +12)
- `cd test/rules && npm test` → 14/14 verts
- Règles déployées sur `valide-edu`

### File List

**Nouveaux** :
- `mobile_app/lib/features/onboarding/presentation/subjects_opt_out_page.dart`
- `mobile_app/lib/features/onboarding/presentation/_subject_icons.dart`
- `mobile_app/test/features/onboarding/presentation/subjects_opt_out_page_test.dart`
- `mobile_app/test/features/onboarding/providers/effective_derived_subjects_provider_test.dart`

**Modifiés** :
- `mobile_app/lib/features/onboarding/domain/user_profile_repository.dart` (signature updateOptedOutSubjects)
- `mobile_app/lib/features/onboarding/data/user_profile_repository_firestore_impl.dart` (impl + try/catch)
- `mobile_app/lib/features/onboarding/providers.dart` (effectiveDerivedSubjectsProvider)
- `mobile_app/lib/features/onboarding/presentation/profile_recap_page.dart` (effectiveSubjects + hasOptedOut + lien actif + helper partagé)
- `mobile_app/lib/core/routing/app_router.dart` (route + import)
- `mobile_app/lib/l10n/app_fr.arb` (5 clés + descriptions)
- `mobile_app/lib/l10n/app_en.arb` (5 clés)
- `mobile_app/lib/l10n/generated/app_localizations*.dart` (auto gen-l10n)
- `firestore.rules` (validation `optedOutSubjects ⊆ derivedSubjects`)
- `test/rules/users.test.mjs` (tests j/k + import updateDoc/serverTimestamp)
- `mobile_app/test/features/onboarding/data/user_profile_repository_test.dart` (tests k/l/m)
- `mobile_app/test/features/onboarding/presentation/profile_recap_page_test.dart` (_FakeRepo + 2 tests canOptOut + filtrage + jamesProfile)
- `mobile_app/test/features/onboarding/providers/profile_completion_provider_test.dart` (_FakeRepo etend updateOptedOutSubjects)
- `project_manage/implementation-artifacts/sprint-status.yaml`

---

**Story 1.4 livrée — prête pour code review.**

Cette story est `ready-for-dev`. Amelia (via `/bmad-dev-story`) a tout pour implémenter sans ambiguïté :

- Architecture clean (extension interface + impl + provider dérivé + page checkbox + route)
- 6 AC + 1 AC qualité (AC7) avec mapping i18n + tests
- Pattern Riverpod 3.x (StreamProvider qui combine derived + watchProfile)
- Pattern Firestore `update()` partiel (pas set merge — Story 1.3 fait set merge pour création, Story 1.4 fait update pour modif)
- Règle Firestore stricte `optedOutSubjects ⊆ derivedSubjects` via `diff().affectedKeys()` + `toSet().difference()`
- Anti-patterns LLM disaster prevention :
  - NE PAS créer de helper Dart `_canOptOut` (amendement sprint 2026-06-05 — Firestore est source de vérité)
  - NE PAS utiliser set(merge:true) pour update (utiliser update partiel)
  - NE PAS logger la liste des optedOutSubjects (fuite identité — count uniquement)
  - NE PAS filtrer dans la widget (logique dans provider dédié)
- Intelligence Stories 1.1c + 1.2 + 1.3 + 1.5 (patterns réutilisés)
- File List explicite par tâche + estimation diff ≤ 250 lignes
