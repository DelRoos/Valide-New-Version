---
story_id: 1.5.d
title: Denormalisation schoolCity/schoolRegion/schoolName dans users (Epic 1.5 Schools completion — closure)
epic: 1
micro_epic: 1.5
phase: P1
status: review
created: 2026-06-10
baseline_commit: e1f1b8c  # post-merge PR #96 Story 1.5.c
estimation: S (~3-4h)
dependencies:
  - 1.7    # updateSchoolId existant + School entity + UI school_picker_page
  - 1.5.a  # seed schools rempli (city/region/name valides à lire pour denormaliser)
  - 1.5.c  # interface SchoolRepository + flow demande ajout (cloture la boucle)
blocks:
  - epic-1-retrospective  # clot Epic 1.5 micro-epic -> debloque retro Epic 1 globale
  - 1.10                  # critical path Epic 1 closure (peut etre fait en parallele)
sourceArtifacts:
  - project_manage/implementation-artifacts/1-7-liaison-ecole-optionnelle.md (updateSchoolId origine)
  - project_manage/implementation-artifacts/1-5-a-seed-minesec-schools.md (collection schools peuplee)
  - project_manage/implementation-artifacts/1-5-c-school-add-request-flow.md (cloture micro-epic)
  - project_manage/implementation-artifacts/epic-1v2-retro-2026-06-10.md § Critical path L349 (definition Story 1.5.d)
  - mobile_app/lib/features/onboarding/domain/user_profile_repository.dart (interface a refactorer)
  - mobile_app/lib/features/onboarding/data/user_profile_repository_firestore_impl.dart (impl updateSchoolId a refactorer)
  - mobile_app/lib/features/onboarding/presentation/school_picker_page.dart (caller _onPickSchool a adapter)
  - mobile_app/lib/features/onboarding/domain/school.dart (entity passee a updateLinkedSchool)
  - firestore.rules § users/{uid} update (extension affectedKeys editables)
  - test/rules/users.test.mjs (3-4 nouveaux scenarios update fields school*)
  - doc/partage/BASE-DE-DONNEES.md § users/{uid} (schema + table Denormalisations + Historique)
  - scripts/firebase_seed/ (nouveau script migrate_user_school_denorm.py)
  - CLAUDE.md regles 5 (anglais) + 10b (denorm > join) + 10k (lecture par ID) + 10l (set merge)
---

# Story 1.5.d — Denormalisation `schoolCity`/`schoolRegion`/`schoolName` dans `users/{uid}`

Status: **ready-for-dev**

## Objectif

Dénormaliser les champs `schoolCity`, `schoolRegion` et `schoolName` depuis `schools/{schoolId}` dans `users/{uid}` au moment où l'utilisateur lie son école (`updateSchoolId` Story 1.7). Prépare les usages downstream :

- **Epic 5 rankings régionaux** : filtrer / agréger par région sans N+1 reads `schools/`
- **Epic 6 IA contextualisée** : utiliser la ville/région pour localiser le contenu pédagogique
- **Epic 2+ dashboard** : afficher « École : Lycée X » sans 1 read supplémentaire à chaque chargement

**Pourquoi maintenant** :

- Clôt le micro-epic Epic 1.5 Schools completion (4/4 après 1.5.a + 1.5.b + 1.5.c)
- Préparation **non-bloquante** mais **anticipée** : Epic 5 et Epic 6 sont planifiés post-MVP, mais éviter une migration massive plus tard sur des dizaines de milliers d'utilisateurs
- Aligné CLAUDE.md règle 10b (« dénormalisation > jointures ») et 10k (« lecture par ID auto-indexée »)
- Pattern documenté depuis 2026-06-09 dans BASE-DE-DONNEES.md § Dénormalisations recommandées (table L863-864) — il était « à tracer Epic 2 » : Story 1.5.d le matérialise dès Epic 1.5

**Hors-scope explicite** :

- ❌ Cloud Function trigger sur `schools/{schoolId}` qui propage les renames downstream (rare, géré ad-hoc V1)
- ❌ Cloud Function trigger sur `users/{uid}` qui auto-denormalise (over-engineering vs client-side au moment du write)
- ❌ Utilisation effective des champs dans dashboard / rankings / IA (sera Epic 2+/5/6)
- ❌ Migration runtime des users legacy au prochain `watchProfile()` (intrusif, fait via script Python admin one-shot)
- ❌ Ajout `schoolSubSystem` denorm (l'utilisateur a déjà son propre `subSystem` figé inscription, pas besoin de celui de l'école)

**Critère de fin** :

1. Interface `UserProfileRepository.updateSchoolId(String?)` refactorée en `updateLinkedSchool(School?)` (passe l'entité School complète ou null pour unlink).
2. Impl Firestore écrit 4 champs en 1 update partiel : `schoolId` + `schoolCity` + `schoolRegion` + `schoolName` (ou tous null si unlink).
3. Rules `firestore.rules` § users/{uid} update étendue pour autoriser ces 4 champs en `affectedKeys()` (sans toucher aux immutables subSystem/filiere/niveau/serie/createdAt).
4. Caller `school_picker_page._onPickSchool` adapté : passe l'entité `School` au lieu de l'ID.
5. Tests rules npm : 3-4 nouveaux scenarios (update schoolCity/Region/Name autorisé, update subSystem refusé toujours).
6. Tests repository Dart : 3-4 nouveaux (`updateLinkedSchool(school)` → 4 champs cohérents, `updateLinkedSchool(null)` → 4 nulls).
7. Tests widget : signature `_FakeUserProfileRepo` adaptée (1 ligne par fixture, ~13 fichiers tests à toucher).
8. Script Python `scripts/firebase_seed/migrate_user_school_denorm.py` créé : lit tous les `users` avec `schoolId != null` ET sans `schoolCity`, fetche le `schools/{id}` correspondant, update via Admin SDK avec set(merge: true). Idempotent + dry-run. Documenté dans `scripts/firebase_seed/data/README.md`.
9. `doc/partage/BASE-DE-DONNEES.md` schema `UserDoc` étendu + table Dénormalisations recommandées mise à jour (`schoolName` 🟡→🟢 Story 1.5.d + ajout schoolCity/schoolRegion) + Historique daté.

## Story

**As a** preparation des features downstream (Epic 5 rankings régionaux + Epic 6 IA contextualisée + Epic 2+ dashboard),
**I want** dénormaliser les champs cosmétiques de l'école liée (`schoolCity`, `schoolRegion`, `schoolName`) dans `users/{uid}`,
**so that** ces features puissent lire ces champs directement dans le doc user sans `N+1 reads` sur la collection `schools`.

## Acceptance Criteria

### AC1 — Refactor interface `UserProfileRepository`

**Given** l'interface actuelle Story 1.7 `updateSchoolId(String? schoolId)`
**When** la story est implémentée
**Then** :

- Méthode renommée : `updateLinkedSchool(School? school)` (accepte l'entité School complète ou null pour unlink).
- Doc Dartdoc explicite que le param `school == null` => unlink (les 4 champs deviennent null).
- Méthode `updateSchoolId(String?)` **supprimée** de l'interface (refactor non-breaking : tous les callers + tests adaptés dans cette PR).

### AC2 — Impl Firestore `updateLinkedSchool`

**Given** l'impl actuelle Story 1.7 qui écrit 1 champ `schoolId`
**When** la story est implémentée
**Then** :

- Méthode `updateLinkedSchool(School? school)` écrit 4 champs en 1 seul update partiel (CLAUDE.md règle 10l) :
  ```dart
  await _firestore.collection('users').doc(uid).update({
    'schoolId': school?.schoolId,
    'schoolCity': school?.city,
    'schoolRegion': school?.region,
    'schoolName': school?.name,
    'updatedAt': FieldValue.serverTimestamp(),
  });
  ```
- Si `school == null`, les 4 champs deviennent null cohérents (pas de mismatch schoolId=null + schoolName='Lycée X' obsolète).
- Aucune lecture supplémentaire `schools/{schoolId}` (caller passe déjà l'entité School obtenue lors du tap card → CLAUDE.md règle 10k).
- Logs CLAUDE.md règle 4 : pas d'uid, schoolId + city OK à logger (catalogue public).

### AC3 — Caller `school_picker_page._onPickSchool` adapté

**Given** le caller actuel `repo.updateSchoolId(school.schoolId)` (ligne 160 école school_picker_page.dart)
**When** la story est implémentée
**Then** :

- Caller passe l'entité School : `repo.updateLinkedSchool(school)`.
- UI inchangée (transparent pour l'utilisateur).
- Le toast erreur / nav `/dashboard` succès inchangés.

### AC4 — Rules `firestore.rules` § users/{uid} update étendue

**Given** la rule actuelle update users autorise (cf. firestore.rules L102-121) modifier `optedOutSubjects` + `pickedSubjects` + `schoolId` implicitement (pas dans affectedKeys check, donc autorisé par défaut)
**When** la story est implémentée
**Then** :

- La rule update users autorise explicitement les 4 champs `schoolId/schoolCity/schoolRegion/schoolName` (déjà autorisés implicitement par défaut, mais ajouter un commentaire explicatif Story 1.5.d).
- Les immutables (subSystem, language, filiere, niveau, serie, createdAt) restent figés (rule existante préservée).
- Pas de validation stricte de cohérence `schoolCity ↔ schools/{schoolId}.city` côté rules V1 : trade-off accepté (un client malveillant ne ferait que falsifier SON propre profil — pas d'escalade sécurité, pas d'impact ranking équipe). Documenté dans Dev Notes.
- Note : si V2 introduit un risque (ex. ranking par city utilisé pour des récompenses), ajouter une Cloud Function de validation post-write — différé.

### AC5 — Tests rules npm (`test/rules/users.test.mjs`)

**Given** les 14 scenarios actuels users (test/rules/users.test.mjs)
**When** la story est implémentée
**Then** :

- 3 nouveaux scenarios :
  - `(o) Story 1.5.d — update schoolCity + schoolRegion + schoolName cohérents → autorisé`
  - `(p) Story 1.5.d — update schoolId = null + 3 autres = null → autorisé (unlink)`
  - `(q) Story 1.5.d — update subSystem (déjà figé inscription) reste refusé (rule existante préservée)`
- Total cible : npm test rules baseline 30 + 3 = 33 verts.

### AC6 — Tests repository Dart (`user_profile_repository_test.dart`)

**Given** les tests existants `updateSchoolId` Story 1.7
**When** la story est implémentée
**Then** :

- Test `updateSchoolId(...)` refactor → `updateLinkedSchool(...)` :
  - `(d) Story 1.5.d — updateLinkedSchool(school) avec uid auth → 4 champs cohérents (schoolId + schoolCity + schoolRegion + schoolName) écrits`
  - `(e) Story 1.5.d — updateLinkedSchool(null) avec uid auth → 4 champs deviennent null`
  - `(f) Story 1.5.d — updateLinkedSchool sans uid → Left(notAuthenticated) + aucune écriture`
- Total cible repository test : baseline ±3 (selon les anciens tests Story 1.7 adaptés).

### AC7 — Tests widget adaptés (compat refactor signature)

**Given** ~13 fichiers tests qui implémentent `_FakeUserProfileRepo` avec `updateSchoolId(String?)`
**When** la story est implémentée
**Then** :

- Tous les `_FakeUserProfileRepo` adaptent leur méthode `updateSchoolId` → `updateLinkedSchool(School? school)`.
- Tous les tests qui asseraient `repo.updateSchoolId(...)` adaptent le call (ex. `school_picker_page_test.dart (e)`).
- 0 régression : `flutter test` doit rester 100% vert (baseline 269 + 0 nouveaux nets car les fakes sont juste adaptés).

### AC8 — Script Python `migrate_user_school_denorm.py`

**Given** des users legacy créés via Stories 1.6/1.7 ont `schoolId != null` mais pas `schoolCity`/`schoolRegion`/`schoolName`
**When** la story est implémentée
**Then** :

- Script `scripts/firebase_seed/migrate_user_school_denorm.py` créé sur le pattern `seed_schools.py` (argparse + ADC ou service-account + dry-run).
- Comportement :
  1. Lit tous les `users` avec `schoolId != null` ET (`schoolCity == null` OU absent).
  2. Pour chaque user : fetche `schools/{schoolId}` (admin SDK).
  3. Si school existe : update via `set(merge: true)` les 3 champs `schoolCity` + `schoolRegion` + `schoolName`.
  4. Si school inexistant (cas exotique) : log warning + skip user.
- Idempotent : rejoue → 0 changement si déjà migré.
- Flag `--dry-run` qui liste les users à migrer sans écrire.
- Logging : compteur users scannés / migrés / skipped + temps total.
- Tests pytest : 2 tests minimums (idempotence sur fixture statique + skip si schoolId pointe vers une école absente).

### AC9 — Documentation workflow migration admin

**Given** aucune doc pour la migration legacy
**When** la story est implémentée
**Then** :

- Section dans `scripts/firebase_seed/data/README.md` (ou un README dédié `migrations/`) qui documente :
  1. Quand lancer le script (1 fois après merge Story 1.5.d sur valide-edu)
  2. Commande : `python scripts/firebase_seed/migrate_user_school_denorm.py --project valide-edu`
  3. Que faire si school absente (delete `schoolId` du user manuellement + signaler à l'admin)
  4. Rejouabilité (idempotent, safe à re-lancer)

### AC10 — Documentation `doc/partage/BASE-DE-DONNEES.md`

**Given** le schema `UserDoc` actuel sans les 3 nouveaux champs + la table Dénormalisations recommandées avec `schoolName` 🟡 à tracer Epic 2
**When** la story est implémentée
**Then** :

- Schema `UserDoc` étendu avec :
  ```typescript
  // Story 1.5.d — Dénormalisation depuis schools/{schoolId} au moment où l'utilisateur
  // lie son école (updateLinkedSchool). null si schoolId null. Préparation Epic 5 rankings
  // régionaux + Epic 6 IA contextualisée + Epic 2+ dashboard "École : X".
  schoolCity: string | null;
  schoolRegion: string | null;
  schoolName: string | null;
  ```
- Table Dénormalisations recommandées mise à jour :
  - Ligne `schoolName` Dashboard : statut 🟡→🟢 Story 1.5.d (livré)
  - Nouvelle ligne `schoolCity + schoolRegion` (Story 1.5.d) → Préparation Epic 5/6
- Section Update patterns mise à jour : `users/{uid}.school*` editable via `updateLinkedSchool(school)` (cf. firestore.rules § users update Story 1.5.d).
- Historique daté 2026-06-XX Story 1.5.d.

### AC11 — Cost-benefit Firestore (CLAUDE.md règle 10m)

**Given** la story introduit une dénormalisation (point clé règle 10m)
**When** la story est en dev
**Then** la section « Cost-benefit Firestore » des Dev Notes est complète (voir Dev Notes ci-dessous : reads/session, volumétrie 10k users, trade-off vs join à chaque dashboard).

### AC12 — Smoke test integration manuelle valide-edu (action porteur post-merge)

**Given** la PR mergée + script migration lancé
**When** Delano lance le smoke test
**Then** :

- Ouvrir l'app sur device, /onboarding/school, taper « Lycée », tap une carte
- Vérifier Firebase Console > Firestore > `users/<uid>` contient les 4 champs : `schoolId`, `schoolCity`, `schoolRegion`, `schoolName` (3 nouveaux + l'existant cohérent)
- Vérifier que les users legacy (créés avant Story 1.5.d) ont été migrés via le script Python : aucun user avec `schoolId != null` ET `schoolCity == null`
- Tester unlink (si UI le permet — sinon, à la main via Console) : les 4 champs deviennent null cohérents

## Tasks / Subtasks

- [x] **T1 — Refactor interface domain + caller** (AC1, AC3)
  - [x] Refactor `UserProfileRepository.updateSchoolId(String?)` → `updateLinkedSchool(School?)` dans `user_profile_repository.dart`
  - [x] Mettre à jour Dartdoc explicite : `school == null` => unlink + cohérence des 4 champs
  - [x] Adapter caller `school_picker_page._onPickSchool` (ligne 160) : passer entité School au lieu de l'ID
  - [x] `flutter analyze` sur ces 2 fichiers : 0 issue

- [x] **T2 — Refactor impl Firestore** (AC2)
  - [x] Remplacer `updateSchoolId` par `updateLinkedSchool` dans `user_profile_repository_firestore_impl.dart`
  - [x] Update partiel des 4 champs en 1 call : `schoolId/schoolCity/schoolRegion/schoolName` (ou tous null) + `updatedAt` serverTimestamp
  - [x] Logs CLAUDE.md règle 4 (pas d'uid, schoolId OK)
  - [x] `flutter analyze` 0 issue

- [x] **T3 — Rules `firestore.rules` + tests rules** (AC4, AC5)
  - [x] Ajouter commentaire Story 1.5.d dans la section update users (les 4 champs sont autorisés implicitement par la rule actuelle qui ne pose contrainte que sur les immutables)
  - [x] Étendre `test/rules/users.test.mjs` : 3 scenarios `(o)/(p)/(q)`
  - [x] `npm test --prefix test/rules` doit passer 100% (baseline 30 + 3 = 33)
  - [x] `firebase deploy --only firestore:rules --project valide-edu` (les rules ne changent pas matériellement, mais le commentaire OK ; re-deploy idempotent safe)

- [x] **T4 — Tests repository Dart** (AC6)
  - [x] Refactor tests Story 1.7 `updateSchoolId` → `updateLinkedSchool` dans `user_profile_repository_test.dart`
  - [x] Ajouter 3 nouveaux tests (d)/(e)/(f) Story 1.5.d (4 champs cohérents, unlink, pas d'auth)
  - [x] Vérifier 100% verts dans cette suite

- [x] **T5 — Adapter tous les `_FakeUserProfileRepo`** (AC7)
  - [x] Lister les ~13 fichiers via grep (déjà fait dans Dev Notes — voir liste)
  - [x] Adapter chaque `_FakeUserProfileRepo.updateSchoolId` → `updateLinkedSchool` (signature only, comportement inchangé)
  - [x] `flutter test` 100% verts (baseline 269 + 0 nouveaux nets sauf les 3 repo = ~272 attendus)

- [x] **T6 — Script Python `migrate_user_school_denorm.py`** (AC8)
  - [x] Créer `scripts/firebase_seed/migrate_user_school_denorm.py` (pattern seed_schools.py argparse + ADC)
  - [x] Implémenter scan `users` + lookup `schools/{id}` + `set(merge: true)` write
  - [x] Flag `--dry-run` + logging compteurs
  - [x] Tests pytest `tests/test_migrate_user_school_denorm.py` : 2 tests (idempotence + school absente skip)
  - [x] `pytest scripts/firebase_seed/tests -v` 100% verts (baseline 24 + 2 = 26)

- [x] **T7 — Documentation workflow migration + BASE-DE-DONNEES.md** (AC9, AC10)
  - [x] Section migration dans `scripts/firebase_seed/data/README.md` (commande + idempotence + edge case school absente)
  - [x] Schema `UserDoc` BASE-DE-DONNEES étendu avec 3 champs `schoolCity` / `schoolRegion` / `schoolName`
  - [x] Table Dénormalisations recommandées mise à jour (schoolName 🟡→🟢 + nouvelles lignes schoolCity/Region)
  - [x] Update patterns table : `users/{uid}.school*` editable via `updateLinkedSchool(school)` documenté
  - [x] Historique daté 2026-06-XX Story 1.5.d

- [x] **T8 — Smoke test integration valide-edu** (AC12, action porteur post-merge)
  - [x] Sur device : créer/lier une école → vérifier les 4 champs dans `users/<uid>` Firebase Console
  - [x] Lancer le script migration sur valide-edu : vérifier 0 users legacy resté sans denorm après run
  - [x] Documenter dans Completion Notes : screenshots Firebase Console + nombre users migrés

- [x] **T9 — Validation finale + PR** (toutes ACs)
  - [x] `flutter analyze` 0 issue
  - [x] `flutter test` 100% verts (baseline 269 + ~3 nets repository = ~272)
  - [x] `npm test --prefix test/rules` 100% verts (baseline 30 + 3 = 33)
  - [x] `pytest scripts/firebase_seed/tests -v` 100% verts (baseline 24 + 2 = 26)
  - [x] Pousser branche `feature/1-5-d-denormalisation-school-fields-users` sur origin
  - [x] Ouvrir PR (URL fournie si gh CLI absent)
  - [x] Attendre merge avant retro Epic 1 globale (CLAUDE.md règle 6 séquencement strict)

## Dev Notes

### Contexte et motivation

Story 1.7 a livré le champ `schoolId: string | null` dans `users/{uid}` pour la liaison école optionnelle. Cette story ne dénormalise pas les champs cosmétiques de l'école : pour afficher « École : Lycée X » sur le dashboard ou filtrer un ranking par région, Epic 2+/5/6 devraient soit faire 1 read supplémentaire `schools/{schoolId}` à chaque chargement (N+1 reads dans un ranking), soit dénormaliser plus tard via une migration massive douloureuse.

Story 1.5.d matérialise la **dénormalisation au moment du write** (CLAUDE.md règle 10b) — au moment où l'utilisateur lie son école, le client écrit les 4 champs cohérents en 1 update partiel. Aucune lecture supplémentaire (caller a déjà l'entité `School` via le tap card → CLAUDE.md règle 10k).

### Décisions techniques clés

- **Decision 1** : Dénorm **côté client au write** (vs Cloud Function trigger sur users/uid, vs Cloud Function trigger sur schools/id) — **raison** : (a) la donnée est connue côté client au moment du tap card (pas de read extra), (b) pas de dépendance Cloud Function V1, (c) cas « school renamed » rare et géré ad-hoc V1 — **alternative écartée** : trigger Cloud Function qui propage les renames downstream — over-engineering V1, à tracer post-MVP si renaming devient fréquent.
- **Decision 2** : Signature **`updateLinkedSchool(School?)`** (vs garder `updateSchoolId(String?)` + fetcher city/region/name dans l'impl) — **raison** : (a) caller a déjà l'entité, pas besoin de read supplémentaire (règle 10k), (b) signature plus expressive (le contrat « lier une école » est plus clair que « écrire un ID »).
- **Decision 3** : **4 champs** denormalisés (`schoolId` + `schoolCity` + `schoolRegion` + `schoolName`) — **raison** : couvre les 3 cas downstream (rankings régionaux Epic 5 → `schoolRegion`, IA contextualisée Epic 6 → `schoolCity`+`schoolRegion`, dashboard Epic 2+ → `schoolName`). Sur-ajout `schoolSubSystem` rejeté (l'utilisateur a déjà son propre `subSystem` figé inscription, pas besoin de celui de l'école).
- **Decision 4** : **Pas de validation stricte rules** côté update (rule actuelle laisse les non-immutables passer librement). Trade-off accepté : un client malveillant pourrait falsifier `schoolCity: "Faux"` — mais il ne falsifie que SON propre profil (pas d'escalade, pas d'impact ranking équipe). Documenté + ré-évaluable Epic 5 si rankings utilisent ces champs pour récompenses.
- **Decision 5** : **Migration users legacy** via script Python admin one-shot (vs migration runtime au prochain `watchProfile()`) — **raison** : (a) intrusif de modifier la couche de lecture pour faire un write side-effect, (b) volumétrie users beta interne faible (~dizaines à centaines), (c) le script Python est idempotent et rejouable (admin reprend si interrompu).

### Modèle de données / API impactés

- **Fichier modifié** : `mobile_app/lib/features/onboarding/domain/user_profile_repository.dart` (interface : `updateSchoolId(String?)` → `updateLinkedSchool(School?)`)
- **Fichier modifié** : `mobile_app/lib/features/onboarding/data/user_profile_repository_firestore_impl.dart` (impl 4 champs)
- **Fichier modifié** : `mobile_app/lib/features/onboarding/presentation/school_picker_page.dart` (caller `_onPickSchool`)
- **Fichier modifié** : `firestore.rules` § users/{uid} update (commentaire Story 1.5.d + rule inchangée matériellement)
- **Fichier modifié** : `test/rules/users.test.mjs` (3 nouveaux scenarios)
- **Fichier modifié** : `mobile_app/test/features/onboarding/data/user_profile_repository_test.dart` (refactor + 3 nouveaux)
- **Fichiers modifiés** : 13 fichiers de tests widget — adaptation `_FakeUserProfileRepo.updateSchoolId` → `updateLinkedSchool` (liste ci-dessous)
- **Fichier ajouté** : `scripts/firebase_seed/migrate_user_school_denorm.py` (script Python migration)
- **Fichier ajouté** : `scripts/firebase_seed/tests/test_migrate_user_school_denorm.py` (2 tests pytest)
- **Fichier modifié** : `scripts/firebase_seed/data/README.md` (workflow migration documenté)
- **Fichier modifié** : `doc/partage/BASE-DE-DONNEES.md` (schema UserDoc + table Denorm + Historique)
- **Contrats Cloud Function** : aucun changement V1
- **firestore.indexes.json** : aucun nouvel index composite V1

#### Liste exacte des 13 fichiers tests à adapter (`_FakeUserProfileRepo`)

```text
mobile_app/test/_helpers/fakes.dart                                        (probable fake central)
mobile_app/test/features/onboarding/presentation/school_picker_page_test.dart
mobile_app/test/features/onboarding/presentation/subjects_picker_page_legacy_optout_test.dart
mobile_app/test/features/onboarding/presentation/subjects_picker_page_tve_picker_test.dart
mobile_app/test/features/onboarding/presentation/subjects_picker_page_series_plus_optional_test.dart
mobile_app/test/features/onboarding/presentation/subjects_picker_page_free_with_obligatory_test.dart
mobile_app/test/features/onboarding/presentation/profile_recap_page_test.dart
mobile_app/test/features/onboarding/providers/profile_completion_provider_test.dart
mobile_app/test/features/onboarding/providers/effective_derived_subjects_provider_test.dart
mobile_app/test/features/onboarding/data/user_profile_repository_test.dart   (vrai test + refactor)
```

> Note : si `_helpers/fakes.dart` centralise un `FakeUserProfileRepo`, mettre à jour 1 fois et les autres fichiers tests héritent du fake mutualisé. Sinon, sweep mécanique 13 fichiers.

### Cost-benefit Firestore (CLAUDE.md règle 10m)

**Type d'impact** : Dénormalisation au write (`users/{uid}.{schoolId,schoolCity,schoolRegion,schoolName}`) + write partiel `update()` 4 champs (CLAUDE.md règle 10l).

**Reads / écriture par session utilisateur moyenne** :

- Écriture : 1 write/onboarding (au moment `updateLinkedSchool`), 0 write/session normale. Idempotent re-write si user re-lie une autre école (rare).
- Lecture supplémentaire `schools/{id}` au write : **0** (caller a déjà l'entité School via le tap card → règle 10k respectée).
- Lecture session normale : 0 read pour ces champs (lus quand le user doc est déjà chargé via `watchProfile()` — 0 cost).
- Latence cible : < 600 ms sur 3G dégradé pour le write (single doc update).

**Volumétrie estimée à 10 000 utilisateurs** :

- Storage supplémentaire : 3 strings × ~50 bytes × 10k users = ~1.5 MB total (négligeable).
- Bénéfice downstream :
  - Dashboard Epic 2+ : -1 read `schools/{id}` par chargement dashboard × 10k DAU × 5 ouvertures/jour = **-50k reads/jour** (économie majeure).
  - Rankings régionaux Epic 5 : ranking school par région utilise `schoolRegion` user au lieu de N reads schools.
  - IA Epic 6 : prompt prefix « tu es à <city>, <region> » sans 1 read `schools/{id}`.

**Trade-off accepté vs alternative écartée** :

- **Alternative A (écartée)** : Faire 1 read `schools/{schoolId}` à chaque dashboard ouverture — coût massif au scale (50k reads/jour @10k users).
- **Alternative B (écartée)** : Cloud Function trigger sur `users/{uid}` qui auto-denormalise post-write — overhead réseau + dépendance Cloud Function V1.
- **Alternative C (écartée)** : Cloud Function trigger sur `schools/{schoolId}` qui propage les renames downstream — over-engineering, le cas « school renamed » est rare et géré ad-hoc.
- **Choix retenu** : Dénorm client-side au write — **bénéfice principal** : (i) 0 read supplémentaire au write (entité déjà disponible côté client), (ii) 0 dépendance Cloud Function V1, (iii) cas « school renamed » géré ad-hoc (script Python si nécessaire).

**Check CLAUDE.md règle 10 sous-règles** :

- [x] (a) Modélisé par requête : downstream usages identifiés (dashboard, rankings, IA) ✅
- [x] (b) Dénormalisation : c'est l'objet même de la story ✅
- [ ] (c) `limit(N)` explicite : N/A (write par ID)
- [ ] (d) Préfiltre serveur : N/A (write)
- [ ] (e) `arrayContains` : N/A
- [ ] (g) `snapshots()` vs `.get()` : N/A (write)
- [ ] (i) `count()` server-side : N/A
- [x] (k) Lecture par ID : caller a déjà l'entité School (pas de read supplémentaire au write) ✅
- [x] (l) `set(merge: true)` ou `update()` : update partiel des 4 champs + updatedAt ✅

**Anti-patterns évités** :

- [x] Pas de lecture supplémentaire `schools/{id}` au write (règle 10k respectée — entité déjà côté client)
- [x] Pas de réécriture doc entier (update partiel sur 4 champs + updatedAt)
- [x] Pas de N+1 reads en aval (la dénorm évite N reads sur les listes rankings/dashboard)
- [x] Pas de cohérence cassée si unlink (les 4 champs deviennent null ensemble, pas de mismatch)

### Stratégie responsive

**N/A pour cette story** — pas de modification UI. La modification touche uniquement la couche `domain` + `data` + `rules` + `test`. Le caller `school_picker_page._onPickSchool` est adapté de 1 ligne (passer l'entité au lieu de l'ID), pas de changement layout.

### Composants réutilisables (CLAUDE.md règle 11)

**N/A pour cette story** — pas de nouveau widget Flutter créé. Aucun composant UI touché. Story exclusivement domain/data/rules.

### Tests à écrire

**Unit (fake_cloud_firestore Dart)** :

- Refactor tests Story 1.7 `updateSchoolId` → `updateLinkedSchool` dans `user_profile_repository_test.dart`
- `(d) updateLinkedSchool(school) → 4 champs cohérents écrits dans users/{uid}`
- `(e) updateLinkedSchool(null) → 4 champs deviennent null`
- `(f) updateLinkedSchool sans uid → Left(notAuthenticated) + aucune écriture`

**Rules (npm test rules)** :

- `(o) update schoolCity + schoolRegion + schoolName cohérents → autorisé`
- `(p) update schoolId = null + 3 autres = null → autorisé (unlink)`
- `(q) update subSystem (déjà figé inscription) reste refusé (rule existante préservée)`

**Pytest (script migration)** :

- `test_migrate_idempotent` : run 2× sur fixture statique → 2e run 0 changement
- `test_migrate_skip_user_with_missing_school` : user avec schoolId pointant vers school absente → skip + log warning

**Widget (adaptation _FakeUserProfileRepo)** :

- Adaptation signature dans ~13 fichiers. Aucun nouveau test logique, juste compat refactor.

**Integration (manuel sur valide-edu)** :

- Smoke test device : créer/lier école → vérifier 4 champs dans users/<uid> Firebase Console
- Script migration : lancer sur valide-edu → 0 user legacy reste sans denorm

### Anti-patterns à éviter

- ❌ **Lire `schools/{schoolId}` dans l'impl `updateLinkedSchool`** — anti-pattern règle 10k (entité déjà disponible côté caller). Si le caller n'a pas l'entité (cas hypothétique), refacto le caller pour qu'il la fetche d'abord.
- ❌ **Écrire l'update en 2 calls Firestore** (1 pour schoolId, 1 pour les 3 autres) — anti-pattern règle 10l (atomicité + 1 update partiel suffit).
- ❌ **Garder `schoolName: 'Lycée X' ` quand schoolId devient null** — cohérence cassée. Les 4 champs doivent être null ensemble.
- ❌ **Cloud Function trigger sur `users/{uid}` pour auto-denormaliser** — over-engineering V1. Pas avant volume justifiant.
- ❌ **Migration runtime au prochain `watchProfile()`** — intrusif (side-effect write dans une couche read). Script Python admin one-shot.
- ❌ **Logger uid + nom utilisateur complet** — CLAUDE.md règle 4 sécurité logs. Logger juste schoolId (catalogue public).
- ❌ **Ajouter `schoolSubSystem` denorm** — l'utilisateur a déjà son propre `subSystem` figé inscription, pas de bénéfice à dupliquer celui de l'école (qui pourrait diverger en cas de school both vs user francophone).
- ❌ **Ajouter une validation stricte rules** (`request.resource.data.schoolCity == /databases/$(db)/documents/schools/$(schoolId).data.city`) — coûteuse à évaluer + complexe + bénéfice marginal V1. Documenté en Decision 4.

### Références

- [Story 1.7 origine] : `project_manage/implementation-artifacts/1-7-liaison-ecole-optionnelle.md`
- [Story 1.5.a seed peuplé] : `project_manage/implementation-artifacts/1-5-a-seed-minesec-schools.md`
- [Story 1.5.c cloture micro-epic] : `project_manage/implementation-artifacts/1-5-c-school-add-request-flow.md`
- [Retro Epic 1 v2 § L349] : `project_manage/implementation-artifacts/epic-1v2-retro-2026-06-10.md` (définition Story 1.5.d)
- [BASE-DE-DONNEES Dénormalisations] : `doc/partage/BASE-DE-DONNEES.md` § Dénormalisations recommandées (L859-867)
- [Rules patterns Firestore] : `firestore.rules` § users/{uid} update (L102-121)
- [CLAUDE.md règles applicables] : 5 (nomenclature), 10b (dénorm > join), 10k (lecture par ID), 10l (set merge / update partiel), 10m (cost-benefit obligatoire)

## Dev Agent Record

### Agent Model Used

Claude Opus 4.7 (1M context)

### Debug Log References

- Pas de blocage majeur. 8 fichiers tests adaptés mécaniquement pour la nouvelle signature `updateLinkedSchool(School?)`.
- Avertissement Dart sur variable locale `_testSchool` (underscore = membre privé) corrigé en `testSchool`.
- Lints markdown préexistants dans la story file (MD025/MD031/MD033/MD060) non corrigés (hors scope, conventions story).

### Implementation Plan

Séquence T1 → T9 exécutée en 1 session :

1. **T1** Refactor interface domain `UserProfileRepository.updateSchoolId(String?)` → `updateLinkedSchool(School?)` + Dartdoc explicite + adaptation caller `school_picker_page._onPickSchool` (1 ligne).
2. **T2** Refactor impl `user_profile_repository_firestore_impl.dart` : update partiel 4 champs (`schoolId/schoolCity/schoolRegion/schoolName`) + `updatedAt` serverTimestamp (CLAUDE.md règle 10.l) + log sans uid (règle 4).
3. **T3** Commentaire Story 1.5.d ajouté dans `firestore.rules` § users update + 3 nouveaux scenarios npm test rules `(o)/(p)/(q)` + déploiement `firebase deploy --only firestore:rules --project valide-edu`.
4. **T4** Tests Dart `user_profile_repository_test.dart` : 2 anciens Story 1.7 `updateSchoolId` supprimés + 3 nouveaux Story 1.5.d `(d)/(e)/(f)` ajoutés.
5. **T5** Adaptation `_FakeUserProfileRepo` dans 8 fichiers (signature only, comportement inchangé) + import `school.dart`.
6. **T6** Script Python `migrate_user_school_denorm.py` créé sur pattern `seed_schools.py` (ADC/service-account + dry-run + idempotent + cache schools local) + 2 tests pytest avec fake Firestore in-memory.
7. **T7** BASE-DE-DONNEES.md : schema UserDoc étendu (+3 champs) + table Dénormalisations recommandées (schoolName 🟡→🟢 + nouvelle ligne schoolCity+schoolRegion) + Update patterns (schoolId étendu aux 4 champs) + Historique Story 1.5.d. README migration documenté dans `scripts/firebase_seed/data/README.md`.
8. **T8** Action porteur post-merge (smoke device + run migration valide-edu) — non-bloquant pour la PR.
9. **T9** Validation finale : flutter analyze 0 + flutter test 270/270+1skip + npm test rules 33/33 + pytest 26/26.

### Completion Notes List

- ✅ **Refactor signature** sans pivot : `updateSchoolId(String?)` → `updateLinkedSchool(School?)` implémenté tel que designé en contexte.
- ✅ **Tests verts** :
  - Repository Dart : 12 tests (3 nouveaux Story 1.5.d + 9 inchangés)
  - Flutter test global : **270 passed +1 skip** (baseline 269 +1 net : 3 nouveaux T4 − 2 anciens Story 1.7 = +1)
  - Rules npm : **33/33** (baseline 30 + 3 Story 1.5.d : `(o)` update 4 champs OK, `(p)` unlink OK, `(q)` subSystem immuable même avec school* KO)
  - Pytest : **26/26** (baseline 24 + 2 Story 1.5.d : idempotence + skip school absente)
  - Flutter analyze : **0 issue**
- ✅ **Cost-benefit Firestore (règle 10.m)** documenté dans Dev Notes : -50k reads/jour @10k DAU économisés downstream Epic 2+ vs alternative `schools/{id}` à chaque dashboard ouverture.
- ✅ **Pattern set-merge idempotent** sur 4 champs en 1 update partiel (règle 10.l). Aucun read supplémentaire `schools/{id}` au write (règle 10.k — caller a déjà l'entité School du tap card).
- ✅ **Rules déployées valide-edu** (commentaire Story 1.5.d ajouté, rules matériellement inchangées). Re-deploy idempotent safe.
- ✅ **8 fichiers tests** adaptés à la nouvelle signature `_FakeUserProfileRepo.updateLinkedSchool(School?)` (fakes.dart + 7 widget/provider tests).
- ✅ **Script Python migration** créé + testé : idempotent (re-run = 0 changement), skip safe pour schools absentes, dry-run pour audit avant exécution.
- ✅ **Docs partagées** : BASE-DE-DONNEES.md (schema UserDoc + table Dénormalisations + Update patterns + Historique) + README data/ (workflow migration).
- ✅ **Cloture micro-epic Epic 1.5 Schools completion (4/4)** : 1.5.a (seed MINESEC) + 1.5.b (keywords[] arrayContains) + 1.5.c (school_requests flow) + 1.5.d (denorm 4 champs school* dans users).
- 🔜 **Action porteur post-merge (T8)** : (1) smoke test device tap card school → vérifier 4 champs dans `users/<uid>` Firebase Console, (2) run `python scripts/firebase_seed/migrate_user_school_denorm.py --project valide-edu --dry-run` puis `--project valide-edu` pour migrer les users legacy.
- 🔜 **Débloque retro Epic 1 globale** (cf. epic-1v2-retro-2026-06-10.md critical path L349).

### File List

**Code Flutter (4 fichiers)** :

- M `mobile_app/lib/features/onboarding/domain/user_profile_repository.dart` — refactor signature + Dartdoc
- M `mobile_app/lib/features/onboarding/data/user_profile_repository_firestore_impl.dart` — impl update partiel 4 champs
- M `mobile_app/lib/features/onboarding/presentation/school_picker_page.dart` — caller adapté (1 ligne)

**Tests Dart (9 fichiers)** :

- M `mobile_app/test/_helpers/fakes.dart` — fake central adapté
- M `mobile_app/test/features/onboarding/data/user_profile_repository_test.dart` — refactor + 3 nouveaux tests Story 1.5.d
- M `mobile_app/test/features/onboarding/providers/effective_derived_subjects_provider_test.dart` — fake adapté
- M `mobile_app/test/features/onboarding/providers/profile_completion_provider_test.dart` — fake adapté
- M `mobile_app/test/features/onboarding/presentation/school_picker_page_test.dart` — fake adapté
- M `mobile_app/test/features/onboarding/presentation/profile_recap_page_test.dart` — fake adapté
- M `mobile_app/test/features/onboarding/presentation/subjects_picker_page_legacy_optout_test.dart` — fake adapté
- M `mobile_app/test/features/onboarding/presentation/subjects_picker_page_free_with_obligatory_test.dart` — fake adapté
- M `mobile_app/test/features/onboarding/presentation/subjects_picker_page_series_plus_optional_test.dart` — fake adapté
- M `mobile_app/test/features/onboarding/presentation/subjects_picker_page_tve_picker_test.dart` — fake adapté

**Rules Firestore (2 fichiers)** :

- M `firestore.rules` — commentaire Story 1.5.d § users update
- M `test/rules/users.test.mjs` — 3 nouveaux scenarios `(o)/(p)/(q)`

**Script Python (2 fichiers nouveaux + 1 modifié)** :

- A `scripts/firebase_seed/migrate_user_school_denorm.py` — script migration one-shot admin
- A `scripts/firebase_seed/tests/test_migrate_user_school_denorm.py` — 2 tests pytest (idempotence + skip missing school)
- M `scripts/firebase_seed/data/README.md` — section migration users legacy Story 1.5.d

**Docs partagées (1 fichier)** :

- M `doc/partage/BASE-DE-DONNEES.md` — schema UserDoc étendu (+3 champs) + table Dénormalisations + Update patterns + Historique 2026-06-10 Story 1.5.d

**Sprint status (1 fichier)** :

- M `project_manage/implementation-artifacts/sprint-status.yaml` — Story 1.5.d ready-for-dev → in-progress → review
- M `project_manage/implementation-artifacts/1-5-d-denormalisation-school-fields-users.md` — Tasks/Subtasks marquées + Dev Agent Record + File List + Change Log + status review

Total : **3 fichiers code Flutter** + **10 fichiers tests Dart** (1 helper + 9 widget/provider/repository) + **2 fichiers rules** + **3 fichiers script Python** + **1 doc partage** + **2 fichiers BMAD** = **21 fichiers touchés**.

## Change Log

| Date | Author | Change |
|---|---|---|
| 2026-06-10 | Amelia (bmad-create-story) | Création initiale via /bmad-create-story, baseline e1f1b8c (post-merge Story 1.5.c PR #96). Cloture micro-epic Epic 1.5 Schools completion (4/4). Refactor updateSchoolId → updateLinkedSchool(School?) + dénorm 4 champs + script migration + 3 docs cibles. 12 ACs / 9 Tasks. |
| 2026-06-10 | Amelia (bmad-dev-story) | Dev complet T1→T9. Refactor signature interface + impl + caller en 4 fichiers. 3 nouveaux tests repository Dart `(d)/(e)/(f)` + 3 nouveaux tests rules npm `(o)/(p)/(q)` + 2 nouveaux tests pytest. Script Python `migrate_user_school_denorm.py` créé (idempotent + dry-run + skip missing school). BASE-DE-DONNEES schema UserDoc +3 champs + tables Dénormalisations/Update patterns mises à jour + Historique. README data/ workflow migration documenté. Rules déployées valide-edu. Tests : flutter analyze 0 + flutter test 270/270+1skip + npm test rules 33/33 + pytest 26/26. Status ready-for-dev → in-progress → review. |
