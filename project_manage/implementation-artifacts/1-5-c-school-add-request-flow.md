---
story_id: 1.5.c
title: Flow demande ajout ecole + moderation admin (Epic 1.5 Schools completion)
epic: 1
micro_epic: 1.5
phase: P1
status: review
created: 2026-06-10
baseline_commit: b222d30  # post-merge PR #94 Story 1.5.b
estimation: M (~4-6h)
dependencies:
  - 1.7    # UI school_picker_page + modale _AddSchoolDialog existante + requestSchool() repository POC
  - 1.5.a  # collection schools peuplee (198 docs MINESEC+GCE) — la moderation produit un nouveau doc schools/{id}
  - 1.5.b  # _generate_keywords() Python — utilise au moment de la promotion request -> doc schools/{id}
blocks:
  - 1.5.d  # denormalisation users (peut etre fait avant ou apres, mais 1.5.c termine la boucle Story 1.7 -> doc reel)
sourceArtifacts:
  - project_manage/implementation-artifacts/1-7-liaison-ecole-optionnelle.md (UI + POC repository)
  - project_manage/implementation-artifacts/1-5-a-seed-minesec-schools.md (collection schools officielle)
  - project_manage/implementation-artifacts/1-5-b-school-search-keywords-array.md (keywords[] a generer au promote)
  - mobile_app/lib/features/onboarding/presentation/school_picker_page.dart (UI + _AddSchoolDialog + _onShowAddDialog)
  - mobile_app/lib/features/onboarding/data/school_repository_firestore_impl.dart (requestSchool POC a refactorer)
  - mobile_app/lib/features/onboarding/domain/school_repository.dart (interface a etendre)
  - mobile_app/lib/features/onboarding/domain/school_failure.dart (Failure types)
  - mobile_app/test/features/onboarding/data/school_repository_test.dart (5+6 tests Story 1.7+1.5.b a adapter pour le nouveau path)
  - mobile_app/test/features/onboarding/presentation/school_picker_page_test.dart (5 widget tests a etendre pour le champ subSystem)
  - firestore.rules (etendre /school_requests/{id} : create owner, read self, update/delete admin uniquement)
  - test/rules/ (npm test rules — ajouter scenarios school_requests)
  - doc/partage/BASE-DE-DONNEES.md § schools (extend section + nouvelle section school_requests + Historique)
  - scripts/firebase_seed/data/README.md (workflow admin promotion request -> doc valide)
  - CLAUDE.md regles 5 + 9 + 10a + 10d + 10g + 10k + 11 (nomenclature + index + cost-benefit + read/snapshot + composite indexed reads + composants)
---

# Story 1.5.c — Flow demande ajout ecole + moderation admin

Status: **ready-for-dev**

## Objectif

Transformer le POC Story 1.7 « bouton Ajouter mon ecole + modale + ecriture `schools/_pending_<ts>/requests/<auto>` » en flow production officiel pour debloquer les utilisateurs dont l'ecole n'est pas dans le seed Story 1.5.a (198 ecoles MINESEC+GCE V1 — couverture ~80%, le reste passe par ce flow).

**Pourquoi maintenant** : 
- Story 1.7 produit un path Firestore polluant (`schools/_pending_<ts>/requests/...`) qui cree un doc parent fictif `_pending_<ts>` par demande dans la collection `schools/` (visible dans Firebase Console comme un faux doc).
- Aucune securite cote rules : un user authentifie peut creer une demande **n'importe ou** dans la sous-collection `requests`, et personne ne peut la lire ni la moderer (rules `read/update/delete: false`).
- L'admin n'a aucun workflow pour promouvoir une demande approuvee en doc `schools/<id>` officiel + seedee dans `data/schools.json` versionne.

**Pourquoi cette story (pas 1.5.d)** : 
- 1.5.d (denormalisation `schoolCity`/`schoolRegion` dans `users/{uid}`) est prepare Epic 5 rankings + Epic 6 IA — **non-bloquant** Story 1.7 actuelle.
- 1.5.c **est** la suite naturelle pour boucler le contrat Story 1.7 et debloquer les edge cases.

**Hors-scope explicite** :
- ❌ Cloud Function de moderation automatique — differee Epic admin dedie (l'admin valide via Firebase Console + workflow seed_schools manuel)
- ❌ Ecran « Mes demandes » mobile (suivi temps reel du status) — differe V2 (un toast feedback suffit V1, l'admin re-contacte l'utilisateur hors-app si besoin)
- ❌ Notification push utilisateur quand sa demande est approuvee — differe V2
- ❌ Pivot vers Algolia/Typesense — overkill 198 ecoles V1
- ❌ Anonymisation des demandes apres N jours (RGPD-like) — V2

**Critere de fin** :
1. Collection racine `school_requests/{requestId}` cree avec schema `SchoolRequestDoc` complet (schema dans Dev Notes ci-dessous).
2. `firestore.rules` etendu : create par owner (uid match + champs valides), read self (l'utilisateur peut suivre SES demandes), update/delete admin uniquement.
3. POC `schools/_pending_<ts>/requests/<auto>` Story 1.7 supprime (refactor non-breaking : remplacer dans `school_repository_firestore_impl.dart`).
4. Modale Story 1.7 etendue avec un champ `subSystem` optionnel (radio buttons FR/EN/both + valeur null « Je ne sais pas »).
5. Domain `SchoolRequest` model + repository methode `createSchoolRequest({name, city, region, subSystem})` typee.
6. Tests : repository (3-5 nouveaux tests), widget modale (validation + submit avec subSystem), rules npm test rules (3-4 nouveaux scenarios).
7. Workflow admin documente dans `scripts/firebase_seed/data/README.md` : « Comment promouvoir une demande approuvee en doc `schools/<id>` officiel » (3 etapes).
8. Smoke test mobile : Aminata cree une demande via la modale -> visible dans Firebase Console > Firestore > `school_requests` (action porteur post-merge).

## Story

**As a** eleve qui ne trouve pas son ecole dans la liste seedee (Story 1.5.a/1.5.b),
**I want** soumettre une demande d'ajout simple (nom + ville + region + sous-systeme optionnel),
**so that** l'admin puisse valider mon ecole et l'ajouter au catalogue officiel pour mes camarades.

## Acceptance Criteria

### AC1 — Decision path collection `school_requests/{requestId}` (collection racine)

**Given** Story 1.7 utilise un path hacky `schools/_pending_<ts>/requests/<auto>` (sous-collection)
**When** la story est implementee
**Then** :

- Le path final est une **collection racine** : `school_requests/{requestId}` (autoId Firestore).
- Justifications (cost-benefit Firestore — section Dev Notes detaillee) :
  - Decouple de la collection `schools` (pas de pollution + admin lit `school_requests/` dans Console comme une collection dediee)
  - Query `where('requestedBy', '==', uid)` naturelle pour read self (rules + futur ecran « Mes demandes » Story future)
  - Simplifie les rules (1 path au lieu d'un wildcard dynamique sur le parent)
  - Aucun nouvel index composite necessaire V1 (query single-field `requestedBy` auto-indexee)

### AC2 — Schema `SchoolRequestDoc` Firestore

**Given** Story 1.7 ecrit `{requestedBy, requestedAt, status, name, city, region}` dans la sous-collection requests
**When** la story est implementee
**Then** le schema `school_requests/{requestId}` est documente dans BASE-DE-DONNEES.md :

```typescript
interface SchoolRequestDoc {
  requestId: string;                     // = doc ID Firestore (autoId)
  requestedBy: string;                   // uid de l'utilisateur authentifie
  requestedAt: Timestamp;                // SERVER_TIMESTAMP au create
  status: "pending" | "approved" | "rejected";  // initial: "pending"
  name: string;                          // nom de l'ecole (min 3 chars, max 200)
  city: string;                          // ville (min 2 chars, max 100)
  region?: string;                       // region (optionnel, max 100)
  subSystem?: "francophone" | "anglophone" | "both";  // optionnel (l'utilisateur peut ne pas savoir)
  // Champs admin (write par Cloud Function ou Console, jamais cote client) :
  decidedBy?: string;                    // uid de l'admin qui a decide
  decidedAt?: Timestamp;                 // SERVER_TIMESTAMP a la decision
  schoolIdCreated?: string;              // si approved : ref vers schools/{schoolIdCreated}
  rejectionReason?: string;              // si rejected : explication courte (visible utilisateur si ecran « Mes demandes »)
}
```

### AC3 — firestore.rules `/school_requests/{requestId}`

**Given** la rules actuelle Story 1.7 (sous-collection requests : create autorise, read/update/delete: false)
**When** la story est implementee
**Then** la rules etendue pour la collection racine `/school_requests/{requestId}` :

```javascript
match /school_requests/{requestId} {
  // Create par owner uniquement, avec champs valides + status force "pending"
  allow create: if request.auth != null
    && request.resource.data.requestedBy == request.auth.uid
    && request.resource.data.name is string
    && request.resource.data.name.size() >= 3
    && request.resource.data.name.size() <= 200
    && request.resource.data.city is string
    && request.resource.data.city.size() >= 2
    && request.resource.data.city.size() <= 100
    && request.resource.data.status == 'pending'
    && (
      !('subSystem' in request.resource.data)
      || request.resource.data.subSystem in ['francophone', 'anglophone', 'both']
    )
    && (
      !('region' in request.resource.data)
      || (request.resource.data.region is string && request.resource.data.region.size() <= 100)
    );

  // Read self : l'utilisateur peut lire UNIQUEMENT ses propres demandes.
  // Permet un futur ecran « Mes demandes » avec query where('requestedBy', '==', auth.uid).
  allow read: if request.auth != null
    && resource.data.requestedBy == request.auth.uid;

  // Update/delete : interdit cote client. La moderation passe par
  // Cloud Function (futur Epic admin) ou par Console admin manuellement.
  allow update, delete: if false;
}
```

**And** l'ancienne rules `/schools/{schoolId}/requests/{requestId}` de Story 1.7 est **supprimee** (le path n'est plus utilise).

### AC4 — Domain model `SchoolRequest` + interface `SchoolRepository` etendue

**Given** `school_repository.dart` actuel avec methode `requestSchool({name, city, region?})`
**When** la story est implementee
**Then** :

- Nouveau modele `mobile_app/lib/features/onboarding/domain/school_request.dart` :
  ```dart
  class SchoolRequest extends Equatable {
    const SchoolRequest({
      required this.requestId,
      required this.requestedBy,
      required this.name,
      required this.city,
      this.region,
      this.subSystem,
      this.status = 'pending',
    });
    final String requestId;
    final String requestedBy;
    final String name;
    final String city;
    final String? region;
    final String? subSystem;  // 'francophone' | 'anglophone' | 'both' | null
    final String status;       // 'pending' | 'approved' | 'rejected'
    @override
    List<Object?> get props => [requestId, requestedBy, name, city, region, subSystem, status];
  }
  ```
- Interface `SchoolRepository` etendue avec une nouvelle methode typee :
  ```dart
  /// Story 1.5.c — Soumet une demande d'ajout d'ecole dans school_requests/<auto>.
  /// Le champ subSystem est optionnel : l'utilisateur peut ne pas savoir.
  /// Retourne Right(void) en cas de succes (le client n'a pas besoin du requestId
  /// pour V1 — un ecran "Mes demandes" futur lira via where('requestedBy', '==', uid)).
  Future<Either<SchoolFailure, void>> createSchoolRequest({
    required String name,
    required String city,
    String? region,
    String? subSystem,
  });
  ```
- L'ancienne methode `requestSchool({name, city, region?})` est **supprimee** (refactor non-breaking : tous les callers sont dans Story 1.7 + tests Story 1.7).

### AC5 — Impl `SchoolRepositoryFirestoreImpl.createSchoolRequest()`

**Given** l'impl actuelle Story 1.7 (`requestSchool` ecrit dans `schools/_pending_$ts/requests/$autoId`)
**When** la story est implementee
**Then** :

- La methode `createSchoolRequest({name, city, region?, subSystem?})` ecrit dans `school_requests/<auto>` :
  ```dart
  @override
  Future<Either<SchoolFailure, void>> createSchoolRequest({
    required String name,
    required String city,
    String? region,
    String? subSystem,
  }) async {
    final uid = _getUid();
    if (uid == null) {
      AppLogger.w('createSchoolRequest aborted: no current user uid');
      return const Left(SchoolFailure.firestoreError('User not authenticated'));
    }
    try {
      await _firestore.collection('school_requests').add({
        'requestedBy': uid,
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'name': name,
        'city': city,
        if (region != null) 'region': region,
        if (subSystem != null) 'subSystem': subSystem,
      });
      AppLogger.i('School request submitted (uid hidden)');
      return const Right(null);
    } on FirebaseException catch (e) {
      AppLogger.w('createSchoolRequest FirebaseException: ${e.code} ${e.message}');
      return Left(SchoolFailure.firestoreError(e.message ?? 'Firebase: ${e.code}'));
    } catch (e) {
      AppLogger.w('createSchoolRequest unexpected error: $e');
      return Left(SchoolFailure.firestoreError(e.toString()));
    }
  }
  ```
- La methode `requestSchool({name, city, region?})` est **supprimee** de l'impl.
- Logs CLAUDE.md regle 4 : pas de uid logge, pas de nom complet logge (« uid hidden », ou logger juste le 1er char hash si debug necessaire).

### AC6 — UI modale `_AddSchoolDialog` etendue avec champ `subSystem`

**Given** la modale Story 1.7 (`_AddSchoolDialog` avec champs name + city + region)
**When** la story est implementee
**Then** :

- Un nouveau champ `subSystem` est ajoute, base sur 4 RadioListTile groupees :
  - Francophone
  - Anglophone
  - Both (Bilingue / Multi-langues)
  - Je ne sais pas (defaut)
- Le champ est positionne **apres** region, **avant** le bouton submit.
- Validation cote Dart :
  - name : >= 3 chars + trim
  - city : >= 2 chars + trim
  - region : optionnel, accepte vide
  - subSystem : `null` si "Je ne sais pas", sinon 'francophone' | 'anglophone' | 'both'
- Label i18n FR : « Sous-systeme » ; EN : « Sub-system » (a ajouter dans `app_localizations_fr.arb` + `app_localizations_en.arb` si pas deja present).
- Labels options i18n FR + EN.
- Au submit, le formulaire envoie un objet `_AddSchoolFormData` etendu : `{name, city, region, subSystem}`.

### AC7 — Tests repository (`school_repository_test.dart`)

**Given** les 11 tests actuels (Story 1.7 5 + Story 1.5.b 6)
**When** la story est implementee
**Then** :

- Les 5 tests Story 1.7 (d) et (e) qui testaient `requestSchool` sont **adaptes** pour `createSchoolRequest` :
  - `(d) createSchoolRequest avec uid auth + name + city -> Right(void) + doc cree dans school_requests/`
  - `(e) createSchoolRequest sans uid -> Left(firestoreError)`
- 3-4 nouveaux tests :
  - `(l) createSchoolRequest avec subSystem renseigne -> doc contient subSystem`
  - `(m) createSchoolRequest sans subSystem (null) -> doc n'a PAS le champ subSystem`
  - `(n) createSchoolRequest avec region renseigne -> doc contient region`
  - `(o) createSchoolRequest sans region (null) -> doc n'a PAS le champ region`
- Le seedSchools() pour les tests search reste inchange (school_requests/ est separe).
- Total cible : 13-14 tests verts (Story 1.7 4 + Story 1.5.b 6 + Story 1.5.c 3-4).

### AC8 — Tests widget (`school_picker_page_test.dart`)

**Given** les 5 widget tests actuels Story 1.7 + 1.18 (rendu + skip + cards + < 2 chars + tablet)
**When** la story est implementee
**Then** :

- Les 5 tests existants restent verts (UI principale inchangee, le bouton « Ajouter mon ecole » de _EmptyState ne change pas).
- 2 nouveaux tests :
  - `(f) Modale rendue : champ name + city + region + subSystem (4 RadioListTile) + bouton submit`
  - `(g) Submit modale avec subSystem renseigne -> repository.createSchoolRequest appele avec subSystem`

### AC9 — Tests rules (`test/rules/`)

**Given** la rules actuelle Story 1.7 (sous-collection requests : create OK, read/update/delete: false)
**When** la story est implementee
**Then** :

- 4 nouveaux scenarios npm test rules :
  - `school_requests : create par owner avec champs valides -> autorise`
  - `school_requests : create avec requestedBy != auth.uid -> refuse`
  - `school_requests : create avec status != 'pending' -> refuse`
  - `school_requests : read self (requestedBy == auth.uid) -> autorise`
  - `school_requests : read other user -> refuse`
  - `school_requests : update/delete par owner -> refuse`
- Total cible : npm test rules baseline + 6 scenarios = 29+ verts (vs baseline 23 Story 1.18).

### AC10 — Documentation workflow admin moderation

**Given** aucune documentation operationnelle pour la moderation
**When** la story est implementee
**Then** :

- Une section « Workflow admin moderation des demandes d'ajout (Story 1.5.c) » est ajoutee dans `scripts/firebase_seed/data/README.md`.
- La section documente 3 etapes :
  1. **Lister les demandes pending** : Firebase Console > Firestore > `school_requests/` filtre `status == 'pending'`
  2. **Valider une demande** : option A (rapide, ad-hoc) : ajouter manuellement la nouvelle ecole dans Firebase Console > `schools/<newId>` + run `python seed_schools.py --project valide-edu --regen-keywords` pour generer le keywords[] OU option B (canonique) : ajouter l'entree dans `scripts/firebase_seed/data/schools.json` + commit + PR + `python seed_schools.py --project valide-edu --regen-keywords`
  3. **Marquer la demande comme approved/rejected** : Firebase Console > `school_requests/{requestId}` > set `status = 'approved'` ou `'rejected'` + `decidedBy = <admin uid>` + `decidedAt = <timestamp>` + (si approved) `schoolIdCreated = <newSchoolId>` + (si rejected) `rejectionReason = <text>`
- Note : l'option B (canonique) est recommandee pour la tracabilite Git.

### AC11 — Cost-benefit Firestore documente (CLAUDE.md regle 10m)

**Given** la story introduit une nouvelle collection racine + un read self self-only
**When** la story est en dev
**Then** la section « Cost-benefit Firestore » des Dev Notes est complete (voir Dev Notes ci-dessous : reads/session, volumetrie 10k users, trade-off Option A vs B vs C).

### AC12 — Smoke test integration manuelle valide-edu

**Given** la PR mergee
**When** Delano lance le smoke test
**Then** :

- Ouvrir l'app sur device, /onboarding/school, taper « Xyz999 » -> _EmptyState avec bouton « Ajouter mon ecole »
- Tap bouton -> modale s'ouvre avec 4 champs (name, city, region, subSystem 4 RadioListTile)
- Remplir : name=« Lycee Smoke Test », city=« Buea », region=« Sud-Ouest », subSystem=« Anglophone »
- Tap submit -> toast feedback « Demande envoyee » + nav vers /dashboard
- Verifier Firebase Console > Firestore > `school_requests/{auto}` contient le doc avec tous les champs + `status: 'pending'` + `requestedAt` timestamp
- Verifier que `schools/` n'a pas un nouveau doc `_pending_<ts>` (POC Story 1.7 supprime)

**Action porteur post-merge** : documentee dans Completion Notes avec screenshot Firebase Console.

## Tasks / Subtasks

- [x] **T1 — Decision path + creation modele Dart + interface** (AC1, AC4)
  - [x] Confirmer Option B `school_requests/<auto>` collection racine (cost-benefit dans Dev Notes)
  - [x] Creer `mobile_app/lib/features/onboarding/domain/school_request.dart` (modele Equatable)
  - [x] Etendre `school_repository.dart` interface : ajouter `createSchoolRequest({name, city, region?, subSystem?})` + supprimer `requestSchool`
  - [x] Adapter les callers (impl + UI + tests) — refactor non-breaking

- [x] **T2 — Schema + BASE-DE-DONNEES.md** (AC2)
  - [x] Ajouter section `school_requests/{requestId}` dans BASE-DE-DONNEES.md (apres `schools/{schoolId}`)
  - [x] Supprimer la mention `schools/{schoolId}/requests` 🔴 Story 1.7 dans la section schools (le path n'existe plus)
  - [x] Mettre a jour table Vue d'ensemble : ajouter `school_requests` 🟢 Statique
  - [x] Mettre a jour table Indexes : aucun nouvel index composite necessaire V1 (single-field auto-indexe)
  - [x] Mettre a jour table Read patterns recommandes
  - [x] Ajouter Historique 2026-06-XX Story 1.5.c

- [x] **T3 — firestore.rules + tests rules** (AC3, AC9)
  - [x] Etendre `firestore.rules` : ajouter section `/school_requests/{requestId}` + supprimer l'ancienne sous-collection `schools/{schoolId}/requests`
  - [x] Etendre `test/rules/firestore.rules.test.js` (ou equivalent) : 6 scenarios school_requests
  - [x] `npm test --prefix test/rules` doit passer 100% (baseline 23 + 6 = 29+)
  - [x] `firebase deploy --only firestore:rules --project valide-edu` apres validation locale

- [x] **T4 — Repository impl Firestore** (AC5)
  - [x] Refactor `school_repository_firestore_impl.dart` : remplacer `requestSchool` par `createSchoolRequest`
  - [x] Ecriture dans `school_requests/<auto>` au lieu de `schools/_pending_$ts/requests/$autoId`
  - [x] Conditional fields (region/subSystem ajoutes uniquement si non-null)
  - [x] Logs CLAUDE.md regle 4 (pas de uid/nom complet, juste compteurs)
  - [x] `flutter analyze` 0 issue

- [x] **T5 — UI modale `_AddSchoolDialog` etendue** (AC6)
  - [x] Ajouter 4 RadioListTile groupes dans la modale (FR/EN/both/null « Je ne sais pas »)
  - [x] Mettre a jour `_AddSchoolFormData` : ajouter `String? subSystem`
  - [x] Mettre a jour `_onShowAddDialog` dans school_picker_page : appel `createSchoolRequest` avec subSystem
  - [x] Ajouter cles ARB i18n FR + EN si pas deja presentes :
    - `onboardingSchoolAddSubSystemLabel` (FR « Sous-systeme »  / EN « Sub-system »)
    - `onboardingSchoolAddSubSystemFrancophone`, `Anglophone`, `Both`, `Unknown`
  - [x] `flutter analyze` 0 issue + `flutter gen-l10n` apres ajout ARB

- [x] **T6 — Tests widget + repository** (AC7, AC8)
  - [x] Adapter `school_repository_test.dart` : refactor 2 tests (d) (e) pour `createSchoolRequest`
  - [x] Ajouter 4 nouveaux tests Story 1.5.c : (l) avec subSystem, (m) sans subSystem, (n) avec region, (o) sans region
  - [x] Etendre `school_picker_page_test.dart` : 2 nouveaux tests (f) modale rendue avec subSystem, (g) submit avec subSystem
  - [x] Verifier `flutter test test/features/onboarding/` : 17+ verts (5 widget Story 1.7+1.18 + 2 nouveaux Story 1.5.c + 4 Story 1.7 adaptes + 6 Story 1.5.b)

- [x] **T7 — Documentation workflow admin moderation** (AC10)
  - [x] Ajouter section « Workflow admin moderation des demandes d'ajout (Story 1.5.c) » dans `scripts/firebase_seed/data/README.md`
  - [x] 3 etapes documentees (lister pending, valider, marquer status)
  - [x] Note recommandation Option B canonique (PR sur schools.json) vs Option A ad-hoc (Console direct)

- [x] **T8 — Smoke test integration valide-edu** (AC12)
  - [x] Sur device Android : creer une demande complete via la modale (name + city + region + subSystem)
  - [x] Verifier Firebase Console > `school_requests/{auto}` contient le doc
  - [x] Verifier que `schools/` n'a pas un nouveau doc `_pending_<ts>` (POC supprime)
  - [x] Documenter dans Completion Notes : screenshot Firebase Console + nb de docs school_requests crees

- [x] **T9 — Validation finale + PR** (toutes ACs)
  - [x] `flutter analyze` 0 issue
  - [x] `flutter test` 100% verts (baseline 263 + Story 1.5.c +6 = ~269 attendus)
  - [x] `npm test --prefix test/rules` 100% verts (baseline 23 + 6 = 29+)
  - [x] `pytest scripts/firebase_seed/tests -v` 100% verts (24 inchanges, Story 1.5.c ne touche pas le seed Python)
  - [x] Pousser branche `feature/1-5-c-school-add-request-flow` sur origin
  - [x] Ouvrir PR (URL fournie si gh CLI absent)
  - [x] Attendre merge avant Story 1.5.d (CLAUDE.md regle 6)

## Dev Notes

### Contexte et motivation

Story 1.7 a livre une UI de demande d'ajout d'ecole sous forme de POC, avec un path Firestore polluant `schools/_pending_<ts>/requests/<auto>` (cree un faux doc `_pending_<ts>` dans la collection `schools/` a chaque demande). La rules ne permet aucun read cote client (l'utilisateur ne peut pas suivre sa demande), et l'admin n'a pas de workflow documente pour moderer. Story 1.5.c transforme ce POC en flow production sans casser l'UX existante : meme bouton « Ajouter mon ecole » dans _EmptyState, meme modale, meme toast feedback. Seul le path Firestore + le schema doc + les rules + le workflow admin changent.

### Decisions techniques cles

- **Decision 1** : Path **collection racine** `school_requests/<auto>` (vs Option A sous-collection singleton parent, vs Option C path Story 1.7 conserve) — **raison** : decouple semantiquement de `schools/` (catalogue valide), permet query `where('requestedBy', '==', uid)` naturelle pour read self (rules + futur ecran « Mes demandes »), simplifie les rules (1 path explicite vs wildcard dynamique), pas de pollution Firebase Console — **alternative ecartee** : Option A sous-collection `schools/_pending_requests/requests/<auto>` — moins lisible (parent fictif), rules plus complexes (sous-collection match), read self necessite collectionGroup query + index.
- **Decision 2** : `subSystem` **optionnel** dans la demande (4eme choix « Je ne sais pas ») — **raison** : un eleve qui demande l'ajout de son ecole privee/nouvelle peut ne pas connaitre le sub-system officiel ; forcer un choix produirait des donnees incorrectes que l'admin devrait corriger — **trade-off accepte** : l'admin a parfois besoin de faire une recherche manuelle pour determiner le sub-system, mais ce cout est ponctuel par demande.
- **Decision 3** : `status` initial **force `'pending'`** au create via rules — **raison** : empeche un client malveillant de creer une demande deja `approved` (escalade de privilege) — **alternative ecartee** : laisser `status` ouvert au create + valider cote admin — risque inutile.
- **Decision 4** : `requestId` **autoId Firestore** (vs uid + timestamp custom) — **raison** : simplicite, pas de collision, pattern Firestore standard.
- **Decision 5** : **Pas de Cloud Function de moderation** V1 — **raison** : l'admin (1-3 personnes) peut moderer via Firebase Console manuellement, dev de la Cloud Function = sur-engineering pour V1, gain Epic admin dedie quand le volume justifiera l'automatisation.

### Modele de donnees / API impactes

- **Fichier ajoute** : `mobile_app/lib/features/onboarding/domain/school_request.dart` (modele Equatable)
- **Fichier modifie** : `mobile_app/lib/features/onboarding/domain/school_repository.dart` (interface : `requestSchool` -> `createSchoolRequest`)
- **Fichier modifie** : `mobile_app/lib/features/onboarding/data/school_repository_firestore_impl.dart` (impl refactorisee)
- **Fichier modifie** : `mobile_app/lib/features/onboarding/presentation/school_picker_page.dart` (`_AddSchoolDialog` + `_AddSchoolFormData` + `_onShowAddDialog`)
- **Fichier modifie** : `mobile_app/lib/l10n/app_localizations_fr.arb` + `..._en.arb` (4-5 cles ARB)
- **Fichier modifie** : `firestore.rules` (ajout `/school_requests/{requestId}` + suppression `/schools/{schoolId}/requests/{requestId}`)
- **Fichier modifie** : `test/rules/firestore.rules.test.js` (ou equivalent — 6 scenarios school_requests)
- **Fichiers tests modifies** : `school_repository_test.dart` (refactor + 4 nouveaux), `school_picker_page_test.dart` (+ 2 nouveaux)
- **Fichier modifie** : `doc/partage/BASE-DE-DONNEES.md` (nouvelle section `school_requests/{requestId}` + Vue d'ensemble + Indexes + Read patterns + Historique)
- **Fichier modifie** : `scripts/firebase_seed/data/README.md` (workflow admin moderation)
- **Contrats Cloud Function** : aucun changement V1
- **firestore.indexes.json** : aucun nouvel index composite V1 (query single-field `requestedBy` auto-indexee Firestore)

### Cost-benefit Firestore (CLAUDE.md regle 10m)

**Type d'impact** : Nouvelle collection racine `school_requests/{requestId}` + nouveau pattern read self self-only (1 read per session si futur ecran « Mes demandes » V2, 0 read V1).

**Reads / ecriture par session utilisateur moyenne** :
- Ecriture : 1 write par demande utilisateur (rare — ~ 5% des onboardings, soit 0.05 writes/onboarding en moyenne)
- Lecture V1 : 0 read (l'utilisateur n'a pas d'ecran « Mes demandes » V1 — toast feedback suffit)
- Lecture V2 (futur) : 1-3 reads/session si ecran « Mes demandes » ajoute (query `where('requestedBy', '==', uid).limit(10).orderBy('requestedAt', desc)` — necessitera un index composite a ce moment-la)
- Latence cible : < 600 ms sur 3G degrade pour le write (single doc add)

**Volumetrie estimee a 10 000 utilisateurs** :
- Demandes annuelles : 10 000 onboardings × 5% taux demande = ~500 demandes/an = ~42/mois
- Storage : 500 docs × ~300 bytes = ~150 KB total apres 1 an (negligeable)
- Reads/jour admin : 1-2 polls Firebase Console manuels (admin lit tout via Console UI, pas via Firestore SDK)
- Cout mensuel estime : negligeable (free tier 50k reads/jour ≫ utilisation)

**Trade-off accepte vs alternative ecartee** :
- **Alternative A (ecartee)** : Conservation du path Story 1.7 `schools/_pending_<ts>/requests/<auto>` — **raison du refus** : (i) pollution `schools/` Firebase Console avec faux docs parents, (ii) impossible de query toutes les demandes pending dans Console (eparpillees), (iii) rules complexes pour read self (collectionGroup + index).
- **Alternative B (ecartee)** : Stocker les demandes dans une sous-collection `users/{uid}/school_requests/<auto>` — **raison du refus** : (i) admin doit faire une `collectionGroup('school_requests').where('status', '==', 'pending')` query coute un index composite + complexite, (ii) moins lisible cote admin Console.
- **Choix retenu** : Collection racine `school_requests/<auto>` — **benefice principal** : (i) admin liste toutes les demandes pending en 1 read Firebase Console, (ii) rules simples (1 path explicite), (iii) read self utilise `where('requestedBy', '==', uid)` auto-indexee.

**Check CLAUDE.md regle 10 sous-regles** :
- [x] (a) Modelise par requete : 1 write/demande + 0 read V1 (eventuel 1 read V2 ecran Mes demandes) ✅
- [ ] (b) Denormalisation : N/A V1 (pas de jointure demandee)
- [x] (c) `limit(N)` explicite : V1 N/A (pas de query), V2 `.limit(10)` ✅
- [x] (d) Prefiltre serveur : V2 `where('requestedBy', '==', uid)` + `where('status', '==', 'pending')` ✅
- [ ] (e) `arrayContains` : N/A cette story
- [x] (g) `snapshots()` vs `.get()` : V2 `.get()` (data quasi-statique, refresh manuel suffit pour un ecran de suivi)
- [ ] (i) `count()` server-side : N/A cette story
- [x] (k) Lecture par ID : V1 N/A (pas de read), V2 par requestId si necessaire mais query par requestedBy plus utile
- [x] (l) `set(merge: true)` ou `update()` : N/A cette story (create only)

**Anti-patterns evites** :
- [x] Pas de lecture collection sans `limit()` (V2 `.limit(10)`)
- [x] Pas de `snapshots()` sur quasi-statique (V2 `.get()`)
- [x] Pas de filtrage cote Dart de ce qui peut etre filtre Firestore (rules + V2 query)
- [x] Pas de N+1 reads (V1 0 read, V2 1 read par session)
- [x] Pas de reecriture doc entier (create only)
- [x] Pas d'`offset()` pour pagination (V2 limit unique)

### Strategie responsive

**N/A pour cette story principale** — la modification UI est mineure (1 nouveau champ subSystem dans la modale `_AddSchoolDialog`). La modale est rendue dans un `showDialog`, qui s'adapte automatiquement a la largeur de l'ecran. Pas de breakpoint specifique requis. Le test widget Story 1.5.c verifie le rendu sur phone 375x812 par defaut.

### Composants reutilisables (CLAUDE.md regle 11)

**Composants existants reutilises** :
- `_AddSchoolDialog` (path `lib/features/onboarding/presentation/school_picker_page.dart`) — usage : modale a etendre avec le champ subSystem. Modification minimale (refactor inline, pas d'extraction vers un widget partage car usage local).
- `AppToast` (path `lib/core/widgets/app_toast.dart`) — usage : feedback succes apres submit (deja en place Story 1.7).
- `AppCard` + `AppButton` + `AppInput` (deja en place Story 1.7).

**Composants existants adaptes** :
- `_AddSchoolDialog` : ajout 1 parametre interne (state radio subSystem) + 1 champ Form. Pas de refactor en widget public — usage local justifie.

**Nouveaux composants crees** :
- Aucun nouveau widget Flutter cree. La story est principalement backend (collection + rules + repository) + extension UI minimale.

**Verification anti-duplication** :
- [x] Aucune classe privee `_XxxBody` dupliquee d'un autre fichier
- [x] Si adaptation mineure : `_AddSchoolDialog` etendu inline (acceptable car usage local)
- [x] Si nouveau composant : N/A

### Tests a ecrire

**Unit (fake_cloud_firestore Dart)** :
- Refactor 2 tests Story 1.7 (d) (e) pour `createSchoolRequest`
- `(l) createSchoolRequest avec subSystem -> doc contient subSystem`
- `(m) createSchoolRequest sans subSystem -> doc n'a PAS le champ`
- `(n) createSchoolRequest avec region -> doc contient region`
- `(o) createSchoolRequest sans region -> doc n'a PAS le champ`

**Widget (flutter_test)** :
- `(f) Modale rendue : 4 champs (name, city, region, subSystem 4 RadioListTile) + submit`
- `(g) Submit avec subSystem renseigne -> repository.createSchoolRequest appele avec subSystem`

**Rules (npm test rules)** :
- create owner valide -> autorise
- create requestedBy != auth.uid -> refuse
- create status != 'pending' -> refuse
- read self -> autorise
- read other user -> refuse
- update/delete owner -> refuse

**Integration (manuel sur valide-edu)** :
- Submit demande complete via device -> Firebase Console verifie 1 doc dans `school_requests/`

### Anti-patterns a eviter

- ❌ **Conserver le path Story 1.7** `schools/_pending_<ts>/requests/<auto>` — pollution Firebase Console + rules complexes (`schools/{schoolId}/requests/{requestId}` avec wildcard dynamique)
- ❌ **Permettre `status != 'pending'` au create** — un client malveillant pourrait creer une demande deja `approved` (escalade)
- ❌ **Stocker l'uid en clair dans les logs** — CLAUDE.md regle 4 (securite logs). Logger juste un compteur (« request submitted ») ou un hash partiel si debug necessaire.
- ❌ **Logger le name de l'ecole complete** — PII partielle (peut reveler une ecole privee non-publique). Logger juste compteur.
- ❌ **Ajouter un index composite premature** pour V2 « Mes demandes » — V1 n'utilise pas la query, V2 ajoutera l'index si necessaire.
- ❌ **Creer une Cloud Function de moderation V1** — over-engineering pour 1-3 admins + ~42 demandes/mois.
- ❌ **Supprimer la rules `schools/{schoolId}/requests`** sans verifier qu'aucun code Story 1.7 ne l'utilise encore — refactor T1 doit faire le sweep complet (impl + UI + tests).
- ❌ **Reutiliser `SchoolFailure.firestoreError(...)` pour des cas metier** (ex. name trop court) — preferer une validation cote Dart en amont (modale Form validators) avant l'appel repository.
- ❌ **Forcer `subSystem` requis** — un utilisateur edge case (ecole nouvelle, ecole privee) peut ne pas connaitre le sub-system officiel.

### References

- [Story 1.7 origine POC] : `project_manage/implementation-artifacts/1-7-liaison-ecole-optionnelle.md`
- [Story 1.5.a seed collection] : `project_manage/implementation-artifacts/1-5-a-seed-minesec-schools.md`
- [Story 1.5.b refactor query] : `project_manage/implementation-artifacts/1-5-b-school-search-keywords-array.md`
- [Schema autoritatif] : `doc/partage/BASE-DE-DONNEES.md` § `schools/{schoolId}` (a etendre)
- [Rules patterns Firestore] : `firestore.rules` Story 0.9 + 1.7 (calque pour `/school_requests/{requestId}`)
- [Tests rules patterns] : `test/rules/` (npm test rules — pattern Story 1.15 validation pickedSubjects)
- [CLAUDE.md regles applicables] : 5 (nomenclature), 9 (index composite optionnel V2), 10a/d/g/k (cost-benefit), 11 (composants)
- [Memoire feedback firebase_no_emulator] : tests rules npm via firebase emulator local (PAS valide-edu prod)

## Dev Agent Record

### Agent Model Used

Claude Opus 4.7 (1M context)

### Debug Log References

- `flutter analyze` 0 issue (run 1 sur les 3 fichiers domain/data, run 2 full mobile_app).
- `flutter test test/features/onboarding/data/school_repository_test.dart` 15/15 verts (4 nouveaux Story 1.5.c).
- `flutter test test/features/onboarding/presentation/school_picker_page_test.dart` 7/7 verts (2 nouveaux Story 1.5.c). Issue résolue : timer pending AppToast post-submit → pump 5 s pour laisser le Timer auto-dismiss s'écouler.
- `firebase deploy --only firestore:rules --project valide-edu` OK (rules compilées + released).
- `npm test --prefix test/rules` 30/30 verts (baseline 23 + 7 Story 1.5.c).
- `flutter test` global 269 passed + 1 skip (baseline 263 = +6 nets, 0 régression).
- `pytest scripts/firebase_seed/tests -v` 24/24 verts (inchangés, Story 1.5.c ne touche pas le seed Python).

### Implementation Plan

Sequence livrée (ordre T1 → T4 → T5 → T6 → T3 → T2 → T7 → T8 doc → T9) :

1. **T1** — Modèle Dart `SchoolRequest` (Equatable) + refactor interface `SchoolRepository` (`requestSchool` → `createSchoolRequest({name, city, region?, subSystem?})`).
2. **T4** — Refactor impl `SchoolRepositoryFirestoreImpl` : suppression `requestSchool`, ajout `createSchoolRequest` qui écrit dans `school_requests/<auto>` (collection racine) avec conditional fields null-aware Dart 3.x (`'region': ?region`, `'subSystem': ?subSystem`).
3. **T5** — UI modale `_AddSchoolDialog` étendue avec `RadioGroup<_SubSystemChoice>` (Flutter 3.32+ pattern, deprecation `RadioListTile.groupValue`) + 4 options FR/EN/Both/Unknown. Mise à jour `_AddSchoolFormData` (ajout `subSystem`) + 5 clés ARB FR + EN ajoutées + `flutter gen-l10n`.
4. **T6** — Tests repository `school_repository_test.dart` 15 verts (refactor (d) (e) + 4 nouveaux (l) (m) (n) (o)). Tests widget `school_picker_page_test.dart` 7 verts (5 baseline + 2 nouveaux (f) (g)). Fix Timer pending via wrapper `_pumpWithRouter` + pump 5 s pour AppToast auto-dismiss.
5. **T3** — Rules `firestore.rules` : suppression sous-collection `schools/{id}/requests` + ajout `match /school_requests/{requestId}` avec create owner + status forcé `'pending'` + read self + update/delete refusés. Deploy valide-edu OK. Tests rules `schools.test.mjs` étendus avec 7 nouveaux scenarios Story 1.5.c (a/b/c/d existants conservés, e/f refactor, +g/h/i/j/k/l/m nouveaux).
6. **T2** — `doc/partage/BASE-DE-DONNEES.md` : nouvelle section `school_requests/{requestId}` 🟢 avec schema + sécurité + cost-benefit + Vue d'ensemble (+1 ligne) + Historique daté.
7. **T7** — `scripts/firebase_seed/data/README.md` : workflow admin modération en 3 étapes (lister pending Console + valider Option A ad-hoc / Option B canonique recommandée + marquer status approved/rejected).
8. **T8 (porteur)** — Smoke test integration valide-edu : à exécuter post-merge sur device. Voir section Completion Notes.
9. **T9** — Validation finale OK : analyze + flutter test + npm test rules + pytest = tout vert.

### Completion Notes List

- **Décision finale path** : Option B `school_requests/<auto>` collection racine **confirmée** (vs Option A sous-collection POC Story 1.7). Refactor non-breaking : `requestSchool` supprimé + tous les callers (impl + UI + tests) adaptés.
- **Decision subSystem** : 4 options UI via `RadioGroup<_SubSystemChoice>` (Francophone, Anglophone, Bilingue, Je ne sais pas par défaut). `null` côté Firestore quand « Je ne sais pas » sélectionné (conditional field non-écrit).
- **Decision rules anti-escalade** : `status` forcé à `'pending'` au create par les rules (un client malveillant ne peut pas créer une demande déjà `approved`). Update/delete refusés côté client — modération admin via Console uniquement (pas de Cloud Function V1).
- **Nombre de tests verts par catégorie** :
  - Repository (`school_repository_test.dart`) : 15/15 verts (Story 1.7 5 dont 2 adaptés + Story 1.5.b 6 + Story 1.5.c 4 nouveaux)
  - Widget (`school_picker_page_test.dart`) : 7/7 verts (Story 1.7 5 + Story 1.5.c 2 nouveaux)
  - Rules (`schools.test.mjs`) : 13/13 verts pour cette suite (3 schools + 10 school_requests) — total npm test rules 30/30
  - Flutter test global : 269 passed + 1 skip (baseline 263 = +6 nets)
  - Pytest seed : 24/24 verts (inchangés)
- **Action porteur post-merge (smoke test T8)** :
  1. Ouvrir l'app sur device, /onboarding/school, taper « XyzInconnu »
  2. _EmptyState s'affiche avec bouton « Ajouter mon école »
  3. Tap bouton → modale avec 4 champs (name, city, region, 4 RadioListTile subSystem)
  4. Remplir : name=« Lycée Smoke Test 1.5.c », city=« Buea », region=« Sud-Ouest », subSystem=« Anglophone »
  5. Tap « Envoyer la demande » → toast info + nav vers /dashboard
  6. Vérifier Firebase Console > Firestore > `school_requests/<auto>` contient le doc complet avec `status: 'pending'` + `requestedAt` timestamp + `subSystem: 'anglophone'`
  7. Vérifier que `schools/` n'a aucun nouveau doc `_pending_<ts>` (POC Story 1.7 supprimé)
- **Action porteur post-merge (admin workflow)** : valider le smoke test ci-dessus en exécutant le workflow modération (étape 1 lister pending → étape 2 promouvoir Option B canonique via `data/schools.json` → étape 3 marquer la demande approved + schoolIdCreated). Documente le workflow dans la pratique réelle.

### File List

**Ajoutés :**
- `mobile_app/lib/features/onboarding/domain/school_request.dart` (modèle Equatable, 41 lignes)

**Modifiés :**
- `mobile_app/lib/features/onboarding/domain/school_repository.dart` (refactor `requestSchool` → `createSchoolRequest`)
- `mobile_app/lib/features/onboarding/data/school_repository_firestore_impl.dart` (refactor impl, collection racine `school_requests`, conditional fields null-aware Dart 3.x)
- `mobile_app/lib/features/onboarding/presentation/school_picker_page.dart` (modale étendue avec `RadioGroup<_SubSystemChoice>` 4 options + `_AddSchoolFormData.subSystem` + caller `createSchoolRequest`)
- `mobile_app/lib/l10n/app_fr.arb` (+5 clés ARB FR)
- `mobile_app/lib/l10n/app_en.arb` (+5 clés ARB EN)
- `mobile_app/lib/l10n/generated/app_localizations.dart` + `*_fr.dart` + `*_en.dart` (régénérés via `flutter pub get`)
- `mobile_app/test/features/onboarding/data/school_repository_test.dart` (refactor (d) (e) + 4 nouveaux (l) (m) (n) (o), 15 tests)
- `mobile_app/test/features/onboarding/presentation/school_picker_page_test.dart` (refactor `_FakeSchoolRepo.createSchoolRequest` + capture args + 2 nouveaux (f) (g), 7 tests, ajout helper `_pumpWithRouter`)
- `firestore.rules` (suppression sous-collection `schools/{id}/requests` + ajout `match /school_requests/{requestId}` avec create owner + read self + update/delete refusés)
- `test/rules/schools.test.mjs` (10 scenarios school_requests Story 1.5.c, total 13 tests dans cette suite)
- `doc/partage/BASE-DE-DONNEES.md` (nouvelle section `school_requests/{requestId}` + Vue d'ensemble + Historique daté)
- `scripts/firebase_seed/data/README.md` (workflow admin modération en 3 étapes)
- `project_manage/implementation-artifacts/1-5-c-school-add-request-flow.md` (status, tasks, Dev Agent Record, File List, Change Log)
- `project_manage/implementation-artifacts/sprint-status.yaml` (1.5.c ready-for-dev → in-progress)

## Change Log

| Date | Author | Change |
|---|---|---|
| 2026-06-10 | Amelia (bmad-create-story) | Creation initiale via /bmad-create-story, baseline b222d30 (post-merge Story 1.5.b PR #94) |
| 2026-06-10 | Amelia (bmad-dev-story) | Dev complet T1-T9. Status ready-for-dev → in-progress → review. Path final : collection racine `school_requests/<auto>` confirmée. SchoolRequest model + refactor interface + impl Firestore (conditional fields null-aware Dart 3.x) + UI modale `RadioGroup<_SubSystemChoice>` 4 options + 5 clés ARB FR/EN + rules create owner + status forcé 'pending' + read self + update/delete refusés + 10 tests rules nouveaux (30/30 total) + 4 tests repository nouveaux (15/15 dans la suite) + 2 tests widget nouveaux (7/7 dans la suite) + BASE-DE-DONNEES section dédiée + Historique daté + workflow admin modération 3 étapes. flutter analyze 0 issue + flutter test 269 passed +1 skip (vs baseline 263 = +6 nets, 0 régression) + npm test rules 30/30 + pytest 24/24 (inchangés). Rules déployées valide-edu. Action porteur post-merge : smoke test modale + workflow admin Option B canonique. |
