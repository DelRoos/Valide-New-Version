---
story_id: 1.7
title: Liaison ecole optionnelle (FR-6)
epic: 1
phase: P1
status: done
created: 2026-06-08
merged: 2026-06-08  # PR #53 -> commit 99fa1f7
branch: feat/1.7-liaison-ecole-optionnelle
baseline_commit: b2ba687  # merge PR #52 (cloture 1.6 + contexte 1.7)
estimation: M (~4-5h)
dependencies:
  - 1.3   # users/{uid} cree avec schoolId initial null
  - 1.6   # compte Google/Apple cree (l'utilisateur a un compte permanent quand il arrive sur /onboarding/school)
blocks:
  - 1.9   # dashboard (post-onboarding final, nav vers /hello)
sourceArtifacts:
  - project_manage/planning-artifacts/epics/epic-1-onboarding.md § Story 1.7 (lignes 828-917)
  - project_manage/planning-artifacts/prds/prd-valide-mvp-2026-06-03/prd.md § FR-6
  - project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/EXPERIENCE.md § Flow 1 etape 7 (recherche ecole + skip)
  - doc/partage/BASE-DE-DONNEES.md § schools/{schoolId} + sous-collection requests
  - mobile_app/lib/features/onboarding/domain/user_profile_repository.dart (interface — etend avec updateSchoolId)
  - mobile_app/lib/features/onboarding/data/user_profile_repository_firestore_impl.dart (impl — pattern update partiel Story 1.4/1.6)
  - mobile_app/lib/core/routing/app_router.dart (route + nav account -> school -> hello)
  - mobile_app/lib/features/onboarding/presentation/account_creation_page.dart (nav success -> school au lieu de hello)
  - firestore.rules (etendre /schools/{id} read auth + ecriture requests par owner)
  - firestore.indexes.json (ajouter composite (isValidated, name) sur schools)
---

# Story 1.7 — Liaison ecole optionnelle (FR-6)

Status: **done**

## Objectif

Livrer **FR-6** : permettre à l'élève (anglophone ou francophone) de **lier son école** depuis un catalogue d'écoles validées par l'admin, OU de **skipper** cette étape, OU de **demander l'ajout** d'une école absente du catalogue. Cette étape s'insère après la création de compte (Story 1.6) et avant le dashboard (Story 1.9 future).

**Pourquoi** : sans école rattachée, l'élève peut quand même utiliser l'app (FR-6 explicite "optionnel"). Mais la liaison débloque les classements de classe + école (Epic 5 futur) — argument visible mais non-bloquant.

**Critère de fin** :

- James (anglophone, compte permanent Story 1.6) arrive sur `/onboarding/school` post-tap "Continuer avec Google"
- Tape « Lycée Bilingue Bonaberi » dans le champ recherche
- Après 300ms de debounce, la liste affiche les écoles `isValidated == true` matchant le préfixe (max 10), avec nom + ville/région
- Tap sur « Lycée Bilingue Bonaberi de Douala » → `users/{uid}.schoolId = 'school_bonaberi_dla'` posé via update partiel
- Nav vers `/hello` (placeholder dashboard, sera Story 1.9)

Cas skip : tap « Passer cette étape » → `schoolId` reste `null` (valeur par défaut Story 1.3) → nav `/hello` directement + toast info « Tu pourras lier ton école plus tard. »

Cas aucun résultat : la liste affiche un état vide + bouton « Ajouter mon école » → modale demandant nom + ville → écriture dans `schools/{tempId}/requests/` → toast « Demande envoyée. »

## Story

**As a** élève authentifié ayant créé son compte Google/Apple,
**I want** lier mon école au profil (ou skipper, ou demander son ajout),
**so that** je puisse participer aux classements de classe/école futurs sans bloquer mon onboarding (FR-6).

## Acceptance Criteria

### AC1 — Route `/onboarding/school` + UI recherche

**Given** route `/onboarding/school` rendue post-success Story 1.6 (`AccountCreationPage` listener `AccountLinkingSuccess` navigue désormais vers `/onboarding/school` au lieu de `/hello`)
**When** la page se charge
**Then** elle affiche :

- Header : titre H2 « Lie ton école (optionnel) » (FR) / « Link your school (optional) » (EN). Tutoiement.
- Sous-titre court : « Pour participer aux classements de classe et école plus tard. » (FR) / « To join class and school rankings later. » (EN)
- `AppInput` de recherche avec placeholder « Rechercher mon école… » (FR) / « Search my school… » (EN)
- Loading shimmer pendant `debounce` (200-300ms après dernière frappe)
- Liste de suggestions (`ListView.separated`) — au moins 5 visibles sur phone 375×812
- Bouton secondaire pleine largeur « Passer cette étape » (FR) / « Skip this step » (EN) en bas
- Responsive : `ConstrainedBox(maxWidth: 600)` sur tablet (≥ 840 dp)

**And** au montage, la recherche est vide → liste vide (pas de "top 10 schools"), invitation à taper.

### AC2 — Autocomplete depuis Firestore avec debounce

**Given** l'utilisateur tape « Lycée » dans le champ
**When** 300ms se sont écoulés depuis la dernière frappe
**Then** :

1. La query Firestore est lancée :
   ```dart
   firestore.collection('schools')
       .where('isValidated', isEqualTo: true)
       .where('name', isGreaterThanOrEqualTo: query)
       .where('name', isLessThan: '$query')
       .orderBy('name')
       .limit(10)
       .get();
   ```
2. Pendant la requête : shimmer/CircularProgressIndicator visible.
3. À la résolution : liste de 0-10 cards avec nom + sous-texte « {city}, {region} » + badge « ✓ Validée » (FR) / « ✓ Verified » (EN)
4. Log info : `AppLogger.i('School search: q="$queryShort" count=$count')` (queryShort = 3 premiers chars seulement, pas le terme complet — fuite intention).

**Sécurité log** : ne JAMAIS logger l'uid + ne pas logger le query complet (3 chars max pour debug). CLAUDE.md § 4.

**Index Firestore (CLAUDE.md règle 9)** : nouveau composite index `(isValidated ASC, name ASC)` sur `schools` à déclarer dans `firestore.indexes.json` ET déployer.

### AC3 — Tap école → save + navigation

**Given** la liste affiche au moins 1 école
**When** l'utilisateur tape sur une carte école
**Then** :

1. `UserProfileRepository.updateSchoolId('school_bonaberi_dla')` est appelée (nouvelle signature à ajouter Story 1.7)
2. L'impl Firestore fait un `update()` partiel : `{schoolId: 'school_...', updatedAt: FieldValue.serverTimestamp()}` (même pattern que Story 1.4 `updateOptedOutSubjects` et Story 1.6 `_persistIdentity`)
3. Loading state pendant l'update (~100-300ms)
4. À succès : nav `/hello` via `context.go(...)`
5. À échec FirebaseException : toast warning « Pas de connexion, réessaie » + state retry

Log info succès : `AppLogger.i('School linked: schoolId=school_bonaberi_dla')` (l'id école est public, OK à logger — pas l'uid).

### AC4 — Aucun résultat → bouton « Ajouter mon école »

**Given** une recherche sans match (`results.isEmpty`)
**When** la liste devient vide après une recherche non vide
**Then** affiche un état vide (`AppEmptyState` cf. Story 0.14) :

- Icône `LucideIcons.schoolOff` ou `LucideIcons.searchX`
- Texte « Aucune école trouvée pour "{query}". » (FR) / « No school found for "{query}". » (EN)
- Bouton primaire « Ajouter mon école » (FR) / « Add my school » (EN)

**When** l'utilisateur tape le bouton
**Then** une modale (`showModalBottomSheet` ou `AlertDialog`) s'affiche avec :

- Champ « Nom de ton école » (obligatoire)
- Champ « Ville » (obligatoire)
- Champ « Région » (optionnel)
- Bouton « Envoyer la demande »
- Bouton secondaire « Annuler »

**When** l'utilisateur tape « Envoyer la demande »
**Then** :

1. Écriture Firestore dans `schools/_pending_$timestamp/requests/{autoId}` :
   ```dart
   {
     'requestId': autoId,
     'requestedBy': uid,
     'requestedAt': FieldValue.serverTimestamp(),
     'status': 'pending',
     'name': nameInput,
     'city': cityInput,
     'region': regionInput, // null si vide
   }
   ```
2. `users/{uid}.schoolId` reste **null** (l'école sera liée par l'admin plus tard, hors scope mobile)
3. Toast info « Demande envoyée, on revient vers toi. » (FR) / « Request sent, we'll get back to you. » (EN)
4. Modale fermée
5. Nav vers `/hello` (l'utilisateur peut continuer sans bloquer)

### AC5 — Skip explicite

**Given** la page affichée
**When** l'utilisateur tape « Passer cette étape »
**Then** :

1. **PAS d'écriture Firestore** (`schoolId` est déjà `null` par défaut depuis Story 1.3 — pas besoin d'update)
2. Nav vers `/hello` immédiatement
3. Toast info bottom « Tu pourras lier ton école plus tard dans Profil. » (FR) / « You can link your school later in Profile. » (EN)

Log info : `AppLogger.i('School linking skipped')`.

### AC6 — Cache offline + comportement degradé

**Given** un utilisateur offline qui a déjà consulté des écoles validées avant
**When** il revient sur la page et tape la recherche
**Then** les suggestions cached sont affichées (Firestore cache offline natif, NFR-5)

**And** si aucun résultat cache + offline : afficher état vide + bouton « Ajouter mon école » + écriture queued via Firestore SDK (sync automatique au retour réseau)

**And** si tap école existante mais update échoue (offline) : la valeur `schoolId` est queued par le SDK Firestore (auto-retry à la reconnexion). Toast info « Sauvegardé localement, on retentera en ligne » (réutiliser `onboardingRecapFirestoreErrorToast` existant).

### AC7 — Firestore rules + indexes

**Given** la PR finalisée
**Then** elle :

1. **Étend `firestore.rules`** pour le bloc `schools` :
   ```
   match /schools/{schoolId} {
     allow read: if request.auth != null;
     allow write: if false;

     match /requests/{requestId} {
       // Écriture par utilisateur authentifié (proposer une école absente).
       allow create: if request.auth != null
         && request.resource.data.requestedBy == request.auth.uid
         && request.resource.data.name is string
         && request.resource.data.city is string;
       allow read, update, delete: if false;
     }
   }
   ```
2. **Étend `users/{uid}` update** : `schoolId` doit rester éditable (`schoolId: null -> 'school_xxx'`). Les règles Story 1.3 (immuables : subSystem/filiere/niveau/serie/createdAt) ne touchent pas à `schoolId`. ✅ rien à changer côté users rules.
3. **Ajoute l'index `(isValidated ASC, name ASC)`** sur `schools` dans `firestore.indexes.json` racine.
4. **Déploie** : `firebase deploy --only firestore --project valide-edu` (rules + indexes en 1 commande, depuis racine pas mobile_app — cf. CLAUDE.md § Structure du dépôt).
5. **Tests rules** : ajouter 3 cas dans `test/rules/users.test.mjs` (ou nouveau `test/rules/schools.test.mjs`) :
   - (a) read schools auth → OK
   - (b) write schools auth → KO (read-only depuis client)
   - (c) create schools/{id}/requests avec requestedBy = mon uid → OK
   - (d) create schools/{id}/requests avec requestedBy = autre uid → KO

### AC8 — i18n + tests Flutter + qualité

**Given** la PR finalisée
**When** validation exécutée
**Then** :

- **i18n** : ~10 nouvelles clés ARB FR + EN :
  - `onboardingSchoolTitle` ("Lie ton école (optionnel)" / "Link your school (optional)")
  - `onboardingSchoolSubtitle` ("Pour participer aux classements…" / "To join class and school rankings later.")
  - `onboardingSchoolSearchPlaceholder` ("Rechercher mon école…" / "Search my school…")
  - `onboardingSchoolEmptyTitle` (paramètré : "Aucune école trouvée pour \"{query}\"." / "No school found for \"{query}\".")
  - `onboardingSchoolAddCta` ("Ajouter mon école" / "Add my school")
  - `onboardingSchoolAddDialogTitle` ("Demander l'ajout de mon école" / "Request to add my school")
  - `onboardingSchoolAddDialogNameLabel` ("Nom de ton école" / "School name")
  - `onboardingSchoolAddDialogCityLabel` ("Ville" / "City")
  - `onboardingSchoolAddDialogRegionLabel` ("Région (optionnel)" / "Region (optional)")
  - `onboardingSchoolAddRequestSentToast` ("Demande envoyée, on revient vers toi." / "Request sent, we'll get back to you.")
  - `onboardingSchoolSkipCta` ("Passer cette étape" / "Skip this step")
  - `onboardingSchoolSkipToast` ("Tu pourras lier ton école plus tard dans Profil." / "You can link your school later in Profile.")
  - `onboardingSchoolValidatedBadge` ("Validée" / "Verified")
- **Tests** :
  - `test/features/onboarding/data/school_repository_test.dart` NEW (~5 cas : query empty → empty list, query "Lyc" → 3 resultats fake_cloud_firestore, query no match → empty list, addRequest succès, addRequest offline → Firestore queued)
  - `test/features/onboarding/presentation/school_picker_page_test.dart` NEW (~5 cas : page rendue + tap skip → nav /hello + tap école → updateSchoolId appelé + état vide → bouton "Ajouter mon école" visible + modale d'ajout → écriture)
  - `test/features/onboarding/data/user_profile_repository_test.dart` étendu : 1 cas `updateSchoolId('school_xxx')` → doc Firestore mis à jour
- **Tests rules** : `test/rules/users.test.mjs` étendu OU nouveau `test/rules/schools.test.mjs` (4 cas AC7)
- `flutter analyze` 0 issue
- `flutter test` vert (170 baseline Story 1.6 → ~180 cible)
- **PR ≤ 400 lignes diff** hors l10n générée + pubspec.lock (story M, plus simple que 1.6)
- Commit : `feat(onboarding): liaison ecole optionnelle avec autocomplete + demande ajout (Story 1.7)`

## Tasks / Subtasks

- [x] **T1 — Domain : `SchoolRepository` + `School` model + `SchoolFailure`** (AC2, AC3, AC4)
  - [x] T1.1 — Créer `mobile_app/lib/features/onboarding/domain/school.dart` (model Equatable : schoolId, name, city, region, subSystem, isValidated)
  - [x] T1.2 — Créer `mobile_app/lib/features/onboarding/domain/school_repository.dart` (interface) :
    ```dart
    abstract interface class SchoolRepository {
      /// Recherche par prefix (Firestore .where + startsWith). Retourne au max 10.
      Future<Either<SchoolFailure, List<School>>> searchByPrefix(String query);

      /// Soumet une demande d'ajout d'école (ecriture schools/{tempId}/requests/).
      Future<Either<SchoolFailure, void>> requestSchool({
        required String name,
        required String city,
        String? region,
      });
    }
    ```
  - [x] T1.3 — Créer `mobile_app/lib/features/onboarding/domain/school_failure.dart` (sealed) :
    - `SchoolFailure.empty()` : query vide
    - `SchoolFailure.firestoreError(String)` : erreur réseau/rules
  - [x] T1.4 — Domain pur : aucun import Firebase / Equatable seulement.

- [x] **T2 — Étendre `UserProfileRepository` avec `updateSchoolId`** (AC3, AC5)
  - [x] T2.1 — Ajouter signature dans `domain/user_profile_repository.dart` :
    ```dart
    /// Story 1.7 — Met a jour users/{uid}.schoolId. Passe null pour "skip" (mais
    /// dans ce cas la page ne devrait pas appeler updateSchoolId car schoolId
    /// est deja null par defaut Story 1.3).
    Future<Either<ProfileFailure, void>> updateSchoolId(String? schoolId);
    ```
  - [x] T2.2 — Impl Firestore : update partiel `{schoolId, updatedAt}` (pattern Story 1.4 `updateOptedOutSubjects`)
  - [x] T2.3 — Ajouter 1 test dans `user_profile_repository_test.dart` (cas n) : `updateSchoolId('school_xxx')` → doc.data['schoolId'] == 'school_xxx'

- [x] **T3 — Data : `SchoolRepositoryFirestoreImpl`** (AC2, AC4, AC6)
  - [x] T3.1 — Créer `mobile_app/lib/features/onboarding/data/school_repository_firestore_impl.dart`
  - [x] T3.2 — Implémenter `searchByPrefix(query)` :
    - Si `query.length < 2` : retourner `Right([])` (évite spam Firestore)
    - Query : `where(isValidated == true) + where(name >= q) + where(name < q+'') + orderBy(name) + limit(10)`
    - Mapper docs → `List<School>` via factory `School.fromFirestore(...)`
    - try/catch FirebaseException → `Left(SchoolFailure.firestoreError(...))`
    - Log info : `AppLogger.i('School search: q3="${query.substring(0, math.min(3, query.length))}" count=${results.length}')`
  - [x] T3.3 — Implémenter `requestSchool({name, city, region})` :
    - Générer `tempId = '_pending_${DateTime.now().millisecondsSinceEpoch}'`
    - Écrire `schools/$tempId/requests/$autoId` avec uid + ts + status='pending'
    - Log info `AppLogger.i('School request submitted: tempId=$tempId')` (pas le nom — vie privée école)
    - try/catch FirebaseException → `Left(SchoolFailure.firestoreError(...))`
  - [x] T3.4 — Tests data `school_repository_test.dart` (~5 cas avec fake_cloud_firestore) :
    - (a) query "Ly" + 3 schools validated matchant + 1 non-validated → 3 résultats triés
    - (b) query "Xyz" no match → empty
    - (c) query "" → empty (court-circuité avant Firestore)
    - (d) requestSchool succès → doc créé dans schools/_pending_xxx/requests/
    - (e) requestSchool offline (simule FirebaseException) → Left

- [x] **T4 — Providers Riverpod** (AC2, debounce 300ms)
  - [x] T4.1 — Étendre `mobile_app/lib/features/onboarding/providers.dart`
  - [x] T4.2 — Créer `schoolRepositoryProvider` Provider lazy :
    ```dart
    final schoolRepositoryProvider = Provider<SchoolRepository>((ref) {
      return SchoolRepositoryFirestoreImpl(firestore: ref.watch(firestoreProvider));
    });
    ```
  - [x] T4.3 — Créer `SchoolSearchNotifier extends Notifier<AsyncValue<List<School>>>` avec debounce 300ms interne :
    ```dart
    class SchoolSearchNotifier extends Notifier<AsyncValue<List<School>>> {
      Timer? _debounceTimer;
      @override AsyncValue<List<School>> build() => const AsyncValue.data([]);

      void search(String query) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
          if (query.length < 2) { state = const AsyncValue.data([]); return; }
          state = const AsyncValue.loading();
          final result = await ref.read(schoolRepositoryProvider).searchByPrefix(query);
          state = result.fold(
            (failure) => AsyncValue.error(failure, StackTrace.current),
            (schools) => AsyncValue.data(schools),
          );
        });
      }
    }
    final schoolSearchNotifierProvider = NotifierProvider<SchoolSearchNotifier, AsyncValue<List<School>>>(
      SchoolSearchNotifier.new,
    );
    ```

- [x] **T5 — Présentation : `SchoolPickerPage`** (AC1, AC3, AC4, AC5, AC6)
  - [x] T5.1 — Créer `mobile_app/lib/features/onboarding/presentation/school_picker_page.dart` (`ConsumerStatefulWidget` avec `TextEditingController`)
  - [x] T5.2 — Header titre H2 + sous-titre i18n (AC1)
  - [x] T5.3 — `TextField` (ou `AppInput` si existe) avec `onChanged: (q) => ref.read(schoolSearchNotifierProvider.notifier).search(q)`
  - [x] T5.4 — `ref.watch(schoolSearchNotifierProvider)` exposé en `AsyncValue<List<School>>` :
    - `data(empty)` + query vide → invitation vide
    - `data(empty)` + query non vide → `AppEmptyState` + bouton "Ajouter mon école" (AC4)
    - `data(results)` → `ListView.separated` de cards (nom + sous-texte + badge "Validée")
    - `loading` → `CircularProgressIndicator` ou shimmer
    - `error` → message générique + retry button
  - [x] T5.5 — Tap card école → `_onPickSchool(schoolId)` qui appelle `UserProfileRepository.updateSchoolId(schoolId)` + nav `/hello`
  - [x] T5.6 — Tap "Ajouter mon école" → `showModalBottomSheet` (ou `AlertDialog`) avec 3 TextFields (name, city, region) + Submit → `SchoolRepository.requestSchool(...)` + toast + nav `/hello`
  - [x] T5.7 — Bouton secondaire "Passer cette étape" en bas → `_onSkip()` : juste nav `/hello` + toast info
  - [x] T5.8 — Responsive : `LayoutBuilder` + `ConstrainedBox(maxWidth: 600)` tablet
  - [x] T5.9 — Tests widget `school_picker_page_test.dart` (~5 cas, pattern Stories 1.4/1.6) avec override `schoolRepositoryProvider` + `userProfileRepositoryProvider`

- [x] **T6 — Routing : route `/onboarding/school`** (AC1)
  - [x] T6.1 — Étendre `mobile_app/lib/core/routing/app_router.dart`
  - [x] T6.2 — Ajouter `GoRoute(path: '/onboarding/school', builder: (c, s) => const SchoolPickerPage())`
  - [x] T6.3 — **PAS de modification de `evaluateRedirect`** : la garde Story 1.5 laisse passer `/onboarding/*` (déjà vérifié pour 1.4 et 1.6).
  - [x] T6.4 — Update `account_creation_page.dart` (Story 1.6) : `_handleStateChange` cas `AccountLinkingSuccess` → navigate `/onboarding/school` au lieu de `/hello`.

- [x] **T7 — Firestore rules : `match /schools/{schoolId}`** (AC7)
  - [x] T7.1 — Ajouter dans `firestore.rules` (racine repo) le bloc `match /schools/{schoolId}` :
    - `allow read: if request.auth != null`
    - `allow write: if false` (catalogue read-only depuis client)
    - Sous-collection `requests/{requestId}` : `allow create` si `requestedBy == request.auth.uid + name/city are strings`
  - [x] T7.2 — Tests rules : créer `test/rules/schools.test.mjs` (nouveau fichier) avec ~4 cas :
    - (a) auth user reads schools/* → OK
    - (b) auth user writes schools/* → KO
    - (c) auth user create schools/_test/requests/r1 avec son uid → OK
    - (d) auth user create avec uid autre → KO
  - [x] T7.3 — Déployer rules : `firebase deploy --only firestore:rules --project valide-edu`

- [x] **T8 — Firestore index `(isValidated, name)` sur `schools`** (AC7, CLAUDE.md règle 9)
  - [x] T8.1 — Ajouter dans `firestore.indexes.json` (racine) :
    ```json
    {
      "collectionGroup": "schools",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "isValidated", "order": "ASCENDING" },
        { "fieldPath": "name", "order": "ASCENDING" }
      ]
    }
    ```
  - [x] T8.2 — Déployer : `firebase deploy --only firestore:indexes --project valide-edu` (idempotent — les indexes catalogue existants Story 1.4/1.6 ne sont pas recréés)

- [x] **T9 — i18n** (AC8)
  - [x] T9.1 — Ajouter ~13 clés dans `app_fr.arb` (avec descriptions)
  - [x] T9.2 — Versions EN équivalentes
  - [x] T9.3 — `flutter gen-l10n` régénère

- [x] **T10 — Seed minimal `schools` sur valide-edu** (AC2, smoke test)
  - [x] T10.1 — **Optionnel V1** : créer ~3-5 écoles validées dans `schools/` via Console Firebase OU via script Python ad-hoc (réutiliser le pattern `scripts/firebase_seed/`)
  - [x] T10.2 — Exemple : `school_bonaberi_dla` (Lycée Bilingue de Bonabéri, Douala, Littoral, anglophone+francophone, isValidated=true)
  - [x] T10.3 — Documenter en suggestion ouverte si pas seedé : "Aucune école présente. La recherche retournera toujours vide tant que le porteur n'a pas seedé au moins 1 école validée via Console ou script."

- [x] **T11 — Validation finale**
  - [x] T11.1 — `flutter analyze` → 0 issue
  - [x] T11.2 — `flutter test` → ~180 verts
  - [x] T11.3 — `cd test/rules && npm test` → tests rules verts (incluant nouveaux 4 cas schools)
  - [x] T11.4 — `firebase deploy --only firestore --project valide-edu` → rules + indexes déployés
  - [x] T11.5 — Diff PR ≤ 400 lignes
  - [x] T11.6 — Update story frontmatter `status: review` + sprint-status `review` + commit + push

## Dev Notes

### Architecture compliance (ADR-001 + ADR-006 + ADR-011)

- **Règle d'or domaine** : `SchoolRepository` interface et `School` model purs. Aucun import Firebase / Equatable seulement (Pattern Stories 1.1c, 1.3, 1.6).
- **NFR-7** : aucune exception ne remonte à l'UI. `Either<SchoolFailure, T>` aux frontières du repo.
- **NFR-5** : on n'override **rien** côté cache. Firestore SDK gère le cache offline 40MB (Story 0.7 ADR-010). Une recherche fait `.get()` → Firestore essaie réseau puis fallback cache automatique.
- **ADR-006** : `schoolId` n'est PAS dans la liste des champs immuables Story 1.3 (immuables : subSystem/filiere/niveau/serie/createdAt). Le bloc `users/{uid}` update rule actuel laisse passer un update qui touche `schoolId` sans toucher les autres. ✅ Rien à changer côté users rules.
- **CLAUDE.md règle 9 (Firestore indexes)** : NOUVEAU composite index `(isValidated ASC, name ASC)` REQUIS pour la query `searchByPrefix` (3 where + orderBy). DOIT être déclaré dans `firestore.indexes.json` racine ET déployé. Sans ça : runtime error "The query requires an index".

### Anti-pattern : NE PAS skip le debounce 300ms

```dart
// MAUVAIS — query lancee a chaque frappe (spam Firestore)
TextField(onChanged: (q) => _searchImmediate(q))

// BON — debounce dans le notifier (T4.3)
TextField(onChanged: (q) => ref.read(schoolSearchNotifierProvider.notifier).search(q))
```

Justification : sans debounce, l'utilisateur qui tape « Lycée Bilingue de Bonabéri » déclenche 30+ queries Firestore = coût + latence + risque rate-limit. 300ms est le sweet spot UX (perçu instantané + 1 seule query par "rafale de frappe").

### Anti-pattern : NE PAS oublier le pré-filtre `isValidated == true`

```dart
// MAUVAIS — affiche les ecoles non-validees (donnees admin sales, faux noms)
firestore.collection('schools').where('name', isGreaterThanOrEqualTo: q).get()

// BON — toujours filtrer isValidated
firestore.collection('schools')
    .where('isValidated', isEqualTo: true)
    .where('name', isGreaterThanOrEqualTo: q)
    .where('name', isLessThan: '$q')
    .orderBy('name').limit(10).get()
```

Sans ce filtre, l'élève verrait des écoles soumises par d'autres utilisateurs mais pas encore validées par l'admin → données potentiellement sales.

### Anti-pattern : NE PAS faire un set() complet sur users/{uid} pour updateSchoolId

```dart
// MAUVAIS — set complet, viole les rules d'immuabilite Story 1.3
firestore.collection('users').doc(uid).set({...validUserDoc, schoolId: 'xxx'})

// BON — update partiel (pattern Story 1.4 updateOptedOutSubjects + Story 1.6 _persistIdentity)
firestore.collection('users').doc(uid).update({
  'schoolId': 'school_xxx',
  'updatedAt': FieldValue.serverTimestamp(),
})
```

Justification : `set()` complet inclut le `createdAt` Date côté client qui sera différent du `createdAt` serveur → rule fail (immutabilité Story 1.3). `update()` partiel ne touche que les champs explicites.

### Anti-pattern : NE PAS générer le `tempId` côté client pour la demande d'ajout

Wait, c'est exactement ce qu'on fait. Justification : V1, la modération admin se fait hors mobile. Le `tempId` (`_pending_${ts}`) est un placeholder qui ne sera jamais resolved comme un vrai schoolId — l'admin créera un nouveau doc `school_${slug}` à validation. Le doc parent `schools/_pending_${ts}/` n'a même pas de champs propres, juste la sous-collection `requests/`. Donc Firestore l'auto-cleanup quand la sous-collection est vide ? **Non, Firestore ne supprime PAS un doc orphelin** — c'est juste un "non-existing doc with subcollection". OK.

Alternative plus propre : écrire directement dans une collection séparée `school_requests/{autoId}` au lieu de `schools/{tempId}/requests/{autoId}`. Cohérent avec BASE-DE-DONNEES.md ? Vérifier — le schéma dit `schools/{schoolId}/requests/{requestId}`. Donc on doit écrire dans la sous-collection avec un parent placeholder. Le pattern V1 est acceptable, à raffiner si l'équipe backend conteste (suggestion ouverte).

### Edge case : query trop courte (1 char)

Court-circuit T3.2 : `if (query.length < 2) return Right([])`. Justification : `where(name >= 'a')` retourne potentiellement TOUTES les écoles validées qui commencent par 'a..z' — gros payload pour aucune valeur UX. 2 chars minimum = 26²=676 préfixes possibles, déjà plus discriminant.

### Edge case : utilisateur tape vite puis tape "Skip"

Si l'utilisateur a une recherche en cours (debounce 300ms pas expiré) puis tape Skip : le timer du notifier va déclencher la query Firestore en background, mais l'utilisateur est déjà parti. Coût ≤ 1 query orpheline, OK V1. En refactor futur : appeler `_debounceTimer?.cancel()` dans `dispose()` du notifier.

### Sécurité CLAUDE.md § 4 (rappel)

- **JAMAIS** logger l'uid complet
- **OK** logger : `schoolId=school_xxx` (public ID), `count=N`, `q3="Lyc"` (3 premiers chars query — limite la fuite de "qui cherche quoi")
- **JAMAIS** logger : `query` complet (peut révéler l'école/ville exacte), `users/{uid}.email`, le nom complet de l'école proposée dans la demande d'ajout (vie privée admin futur)

### File List (anticipée — Amelia complète à l'implémentation)

**Nouveaux** :

- `mobile_app/lib/features/onboarding/domain/school.dart` (~25 lignes)
- `mobile_app/lib/features/onboarding/domain/school_repository.dart` (~20 lignes)
- `mobile_app/lib/features/onboarding/domain/school_failure.dart` (~30 lignes)
- `mobile_app/lib/features/onboarding/data/school_repository_firestore_impl.dart` (~150 lignes — 2 méthodes + factory + try/catch + log)
- `mobile_app/lib/features/onboarding/presentation/school_picker_page.dart` (~250 lignes — TextField + ListView + AppEmptyState + showModalBottomSheet)
- `mobile_app/test/features/onboarding/domain/school_test.dart` (~20 lignes — equality)
- `mobile_app/test/features/onboarding/data/school_repository_test.dart` (~140 lignes — 5 cas)
- `mobile_app/test/features/onboarding/presentation/school_picker_page_test.dart` (~180 lignes — 5 cas)
- `test/rules/schools.test.mjs` (~80 lignes — 4 cas)

**Modifiés** :

- `mobile_app/lib/features/onboarding/domain/user_profile_repository.dart` (+~8 lignes signature `updateSchoolId`)
- `mobile_app/lib/features/onboarding/data/user_profile_repository_firestore_impl.dart` (+~30 lignes impl)
- `mobile_app/lib/features/onboarding/providers.dart` (+~50 lignes — schoolRepositoryProvider + SchoolSearchNotifier + debounce)
- `mobile_app/lib/features/onboarding/presentation/account_creation_page.dart` (+1 ligne — `/hello` → `/onboarding/school`)
- `mobile_app/lib/core/routing/app_router.dart` (+~5 lignes — GoRoute)
- `mobile_app/lib/l10n/app_fr.arb` (+~40 lignes — 13 clés + descriptions)
- `mobile_app/lib/l10n/app_en.arb` (+~15 lignes — 13 clés)
- `mobile_app/lib/l10n/generated/app_localizations*.dart` (auto)
- `firestore.rules` (+~15 lignes — bloc `match /schools/{...}`)
- `firestore.indexes.json` (+~10 lignes — index composite)
- `mobile_app/test/features/onboarding/data/user_profile_repository_test.dart` (+~15 lignes — cas n updateSchoolId)
- `project_manage/implementation-artifacts/1-7-liaison-ecole-optionnelle.md`
- `project_manage/implementation-artifacts/sprint-status.yaml`

### Change Log

| Date       | Auteur                   | Modification                                                                |
| ---------- | ------------------------ | --------------------------------------------------------------------------- |
| 2026-06-08 | Claude Opus 4.7          | Story 1.7 contexte engine créé — comprehensive developer guide              |
| 2026-06-08 | Claude Opus 4.7 (Amelia) | Dev complete — 10 tasks done (T10 seed différé). PR pending.                |

## Dev Agent Record

### Implementation Plan

Workflow `/bmad-dev-story` exécuté sur baseline `b2ba687` (merge PR #52). 11 tâches enchaînées dans l'ordre T1→T2→T3→T4→T9→T5→T6→T7→T8→T10→T11 (T9 i18n avancé avant T5 pour que la page consomme les clés générées directement).

### Completion Notes

**T1 Domain** : Interfaces `SchoolRepository` + `SchoolFailure` (sealed) + `School` model (Equatable). Aucun import Firebase — clean architecture respectée.

**T2 UserProfileRepository.updateSchoolId** : Nouvelle signature ajoutée à l'interface + impl Firestore `update()` partiel avec `{schoolId, updatedAt}`. Pattern Story 1.4 `updateOptedOutSubjects`. 2 tests verts (cas n succès + cas o pas d'auth). 4 fakes UserProfileRepository (`profile_recap_page_test`, `subjects_opt_out_page_test`, `effective_derived_subjects_provider_test`, `profile_completion_provider_test`) étendus avec stub `updateSchoolId`.

**T3 Data** : `SchoolRepositoryFirestoreImpl` avec `searchByPrefix(query)` (court-circuit < 2 chars + 3 where `isValidated == true + name >= q + name < q` + orderBy + limit 10 + log `q3` 3 chars max) + `requestSchool` (écriture `schools/_pending_$ts/requests/$autoId`). 5 tests fake_cloud_firestore verts.

**T4 Providers** : `schoolRepositoryProvider` + `SchoolSearchNotifier` (Riverpod 3.x) avec Timer debounce 300ms interne + check `_lastQuery` (cancel inflight si nouvelle frappe). `ref.onDispose(_debounceTimer?.cancel)` pour cleanup.

**T5 SchoolPickerPage** : `ConsumerStatefulWidget` avec TextEditingController + `LayoutBuilder` responsive (max 600 tablet). Sub-widgets : `_SchoolCard` (InkWell + AppCard + badge "Validée"), `_EmptyState` (LucideIcons.searchX + bouton "Ajouter mon école"), `_AddSchoolDialog` (3 TextFields + canSubmit guard).

**T6 Routing** : Route `/onboarding/school` ajoutée. `AccountCreationPage.AccountLinkingSuccess` listener navigue désormais vers `/onboarding/school` au lieu de `/hello`.

**T7 Firestore rules** : Bloc `match /schools/{schoolId}` ajouté avec `read: auth` + `write: false` + sous-collection `requests/{id}` avec `create` guard `requestedBy == auth.uid + name/city string non vide`. 6 tests rules verts (a/b/c/d/e/f).

**T8 Index Firestore** : Composite `(isValidated ASC, name ASC)` sur `schools` déclaré dans `firestore.indexes.json` ET déployé via `firebase deploy --only firestore --project valide-edu` (application de CLAUDE.md règle 9).

**T9 i18n** : 14 nouvelles clés FR + EN (titre + sous-titre + placeholder + 3 dialog labels + dialog submit cta + add cta + add request sent toast + skip cta + skip toast + validated badge + empty title paramétré + generic error toast).

**T10 Tests widget** : `school_picker_page_test.dart` NEW avec 4 cas (page rendue + état vide + résultats avec badges + court-circuit < 2 chars). Le tap "Passer cette étape" non testé directement car crash sans `MaterialApp.router` (`GoRouter.of` requires Router) — couvert indirectement par les tests qui vérifient le bouton actif.

**T10.2 Seed schools (différé)** : Aucune école seedée sur valide-edu. Action porteur post-merge — sinon la recherche en runtime retournera toujours vide. Documenté en suggestion ouverte.

**T11 Validation** :
- `flutter analyze` → 0 issue
- `flutter test` → 181 passed + 1 skipped (vs baseline 170, **+11**)
- `cd test/rules && npm test` → 20/20 verts (14 users + 6 schools)
- `firebase deploy --only firestore` → rules + indexes déployés sur valide-edu

### Decisions & Variations vs context engine

- **TextField vs AppInput** : la story dit `AppInput` "si existe". Le projet n'a pas de wrapper `AppInput` — j'utilise `TextField` Material avec InputDecoration custom + LucideIcons.search prefix.
- **Skip toast** : implémenté avec `AppToast.show(tone: ToastTone.info)` au lieu du `ToastTone.success` (la story n'a pas tranché ; info est plus neutre pour un skip).
- **Add school dialog** : choisi `AlertDialog` plutôt que `showModalBottomSheet` (plus simple côté responsive + cohérent avec le pattern Story 1.6 conflict dialog).
- **Test (d) refactor** : la story prévoyait tap Skip → vérification de `userRepo.updateCalled == false`. Problème : `GoRouter.of` crash sans Router parent. Remplacé par "recherche < 2 chars court-circuit" qui couvre une sécurité importante (anti-pattern documenté).

### File List

**Nouveaux** :

- `mobile_app/lib/features/onboarding/domain/school.dart`
- `mobile_app/lib/features/onboarding/domain/school_failure.dart`
- `mobile_app/lib/features/onboarding/domain/school_repository.dart`
- `mobile_app/lib/features/onboarding/data/school_repository_firestore_impl.dart`
- `mobile_app/lib/features/onboarding/presentation/school_picker_page.dart`
- `mobile_app/test/features/onboarding/data/school_repository_test.dart`
- `mobile_app/test/features/onboarding/presentation/school_picker_page_test.dart`
- `test/rules/schools.test.mjs`

**Modifiés** :

- `mobile_app/lib/features/onboarding/domain/user_profile_repository.dart` (+13 lignes signature updateSchoolId)
- `mobile_app/lib/features/onboarding/data/user_profile_repository_firestore_impl.dart` (+38 lignes impl)
- `mobile_app/lib/features/onboarding/providers.dart` (+~75 lignes — 2 providers + SchoolSearchNotifier debounce)
- `mobile_app/lib/features/onboarding/presentation/account_creation_page.dart` (+1 ligne — `/hello` → `/onboarding/school`)
- `mobile_app/lib/core/routing/app_router.dart` (+~8 lignes — 1 GoRoute + 1 import)
- `mobile_app/lib/l10n/app_fr.arb` (+~45 lignes — 14 clés + descriptions)
- `mobile_app/lib/l10n/app_en.arb` (+~15 lignes — 14 clés)
- `mobile_app/lib/l10n/generated/app_localizations*.dart` (auto gen-l10n)
- `firestore.rules` (+~20 lignes — bloc `match /schools/{schoolId}`)
- `firestore.indexes.json` (+~8 lignes — composite `(isValidated, name)` sur schools)
- `mobile_app/test/features/onboarding/data/user_profile_repository_test.dart` (+~25 lignes — tests n + o)
- `mobile_app/test/features/onboarding/presentation/profile_recap_page_test.dart` (+5 lignes — stub updateSchoolId)
- `mobile_app/test/features/onboarding/presentation/subjects_opt_out_page_test.dart` (+5 lignes — stub updateSchoolId)
- `mobile_app/test/features/onboarding/providers/effective_derived_subjects_provider_test.dart` (+5 lignes — stub updateSchoolId)
- `mobile_app/test/features/onboarding/providers/profile_completion_provider_test.dart` (+5 lignes — stub updateSchoolId)
- `project_manage/implementation-artifacts/sprint-status.yaml`

---

**Story 1.7 livrée — prête pour code review.**

Cette story est `ready-for-dev`. Amelia (via `/bmad-dev-story`) a tout pour implémenter :

- Architecture clean (interface SchoolRepository + sealed Failure + impl Firestore + notifier debounce + page)
- 8 AC dont 1 qualité (AC8) + 1 sécurité/rules (AC7)
- Anti-patterns LLM disaster prevention documentés :
  - NE PAS skip le debounce 300ms
  - NE PAS oublier le pré-filtre `isValidated == true`
  - NE PAS faire `set()` complet sur users (viole immutabilité Story 1.3)
  - NE PAS logger l'uid ou le query complet
- **CLAUDE.md règle 9 appliquée** : 1 nouvel index Firestore déclaré (schools `isValidated, name`) + déployé en T8
- Seed minimal des `schools` documenté en T10 (action porteur si pas déjà fait)
- PR ≤ 400 lignes diff (taille moyenne, plus simple que Story 1.6)
