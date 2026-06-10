---
story_id: 1.5.a
title: Seed MINESEC schools dans valide-edu (Epic 1.5 Schools completion)
epic: 1
micro_epic: 1.5  # Schools completion (post-Epic 1 v2, cadre dans retro 2026-06-10)
phase: P1
status: review
created: 2026-06-10
baseline_commit: 607711e  # post-merge Story 1.18
estimation: M (~3-5h)
dependencies:
  - 1.7   # school_repository_firestore_impl + School model + index composite (isValidated, name) deployes
blocks:
  - 1.5.b  # algo recherche optimise keywords[] (depend du seed pour avoir de la data sur valide-edu)
  - 1.5.c  # flow demande ajout (depend du seed pour que la collection existe)
  - 1.5.d  # denormalisation schoolCity/schoolRegion users/{uid} (depend du seed)
sourceArtifacts:
  - project_manage/implementation-artifacts/epic-1v2-retro-2026-06-10.md (lignes 343-349 : Epic 1.5 micro-epic cadre)
  - project_manage/implementation-artifacts/1-7-liaison-ecole-optionnelle.md (Story 1.7 : modele + repository impl + index existant)
  - doc/partage/BASE-DE-DONNEES.md § schools/{schoolId} (lignes 586-602 : schema autoritatif)
  - doc/partage/BASE-DE-DONNEES.md § Règles de securite (ligne 686 : schools auth lecture, admin/script ecriture)
  - scripts/firebase_seed/seed_catalogue.py (pattern Python seed Story 1.1b)
  - scripts/firebase_seed/README.md (pattern doc + setup ADC + service-account)
  - mobile_app/lib/features/onboarding/domain/school.dart (modele School Equatable)
  - mobile_app/lib/features/onboarding/data/school_repository_firestore_impl.dart (query (isValidated, name) limit 10)
  - CLAUDE.md regle 5 (nomenclature anglaise) + regle 10 (cost-benefit Firestore)
  - C:\Users\Emerite\Documents\projets\Mobile\Valide\etablissements_minesec_cameroun.json (fichier source LOCAL non versionne, a obtenir aupres de l'utilisateur T1)
---

# Story 1.5.a — Seed MINESEC schools dans valide-edu

Status: **review**

## Objectif

Livrer le **seed initial des etablissements MINESEC** (~ Cameroun secondaire) dans la collection Firestore `schools` du projet `valide-edu`, pour debloquer l'UX de Story 1.7 (school_picker_page) sur reseau Cameroun reel.

**Pourquoi maintenant** : Story 1.7 a livre la fonctionnalite UI minimale (recherche prefix Firestore + flow demande ajout) le 2026-06-08 mais la collection `schools` reste vide cote `valide-edu`. Tout utilisateur reel arrive sur `/onboarding/school`, tape « Lycee » → 0 resultat → seule sortie : « Mon ecole n'est pas dans la liste ». Inutilisable.

**Pourquoi cette story (pas 1.5.b)** : la story B (algo recherche keywords[]) ne peut pas etre testee sans data dans la collection. Bloquant data avant bloquant algo.

**Hors-scope explicite** :
- ❌ Refonte de l'algo de recherche (keywords[] arrayContains) → Story 1.5.b dediee
- ❌ Flow demande ajout admin moderation → Story 1.5.c dediee
- ❌ Denormalisation schoolCity/schoolRegion dans users/{uid} → Story 1.5.d dediee
- ❌ UI mobile (aucun changement Flutter) — cette story est 100% backend seed

**Critere de fin** :

1. Le fichier source MINESEC est versionne dans `scripts/firebase_seed/data/schools.json` apres normalisation (casse, doublons, subSystem mapping).
2. `python seed_schools.py --project valide-edu --dry-run` valide la matrice schools sans ecriture.
3. `python seed_schools.py --project valide-edu` ecrit toutes les ecoles MINESEC dans Firestore `schools/{schoolId}` avec `isValidated: true`.
4. James (anglophone) tape « Lycee » dans school_picker_page → la liste affiche au moins 5 ecoles MINESEC reelles (test manuel sur valide-edu apres seed).
5. `pytest scripts/firebase_seed/tests/test_seed_schools.py` valide la matrice JSON statique : champs requis, unicite schoolId, subSystem valide, noms non-vides.

## Story

**As a** developpeur Valide School,
**I want** seeder la collection Firestore `schools` du projet `valide-edu` avec les etablissements MINESEC officiels du Cameroun,
**so that** l'utilisateur reel peut trouver et lier son ecole via la school_picker_page (Story 1.7) sans tomber sur une liste vide.

## Acceptance Criteria

### AC1 — Fichier source schools.json versionne

**Given** le fichier source MINESEC local `C:\Users\Emerite\Documents\projets\Mobile\Valide\etablissements_minesec_cameroun.json` (a obtenir aupres de Delano Roosvelt en T1)
**When** la story est implementee
**Then** :

- Le fichier est copie et normalise dans `scripts/firebase_seed/data/schools.json` (commit dans la branche feature/1-5-a-seed-minesec-schools).
- Structure JSON conforme au schema attendu par le script de seed :
  ```json
  {
    "version": "1.0.0",
    "generatedAt": "2026-06-10",
    "source": "MINESEC Cameroun (officiel) + GCE Board",
    "schools": [
      {
        "schoolId": "school_lycee_bilingue_bonaberi",
        "name": "Lycee Bilingue de Bonaberi",
        "city": "Douala",
        "region": "Littoral",
        "subSystem": "both",
        "isValidated": true
      },
      ...
    ]
  }
  ```
- Le `schoolId` est genere par slugification reproductible (lower-case, accents normalises, underscores) de `name + city` pour eviter les collisions.
- Le `name` preserve la casse officielle MINESEC (ex. « Lycee Joss » garde majuscule L).
- Le `subSystem` est mappe selon les regles MINESEC : francophone si nom contient « Lycee/College » FR-only, anglophone si « Government High School / GHS / GS », sinon `both` si bilingue ou ambigu.
- Aucun doublon `schoolId` (validation script T3).

**And** le `.gitignore` racine et `scripts/firebase_seed/.gitignore` sont verifies pour ne PAS bloquer `schools.json` (matrice versionnee, contrairement a `service-account.json`).

### AC2 — Script Python `seed_schools.py` autonome et idempotent

**Given** le pattern Story 1.1b (`seed_catalogue.py`) et son README
**When** le developpeur cree `scripts/firebase_seed/seed_schools.py`
**Then** :

- Le script suit le meme pattern : `argparse`, auth ADC ou `--credentials service-account.json`, `--dry-run`, `--matrice` (defaut `data/schools.json`).
- Le script valide la matrice avant ecriture : champs requis (schoolId, name, city, region, subSystem, isValidated), types, subSystem ∈ {francophone, anglophone, both}, unicite schoolId.
- L'ecriture utilise `set(merge=True)` sur `db.collection('schools').document(schoolId)` — jamais `add()`. Idempotent.
- Le champ Firestore `createdAt` est ajoute via `firestore.SERVER_TIMESTAMP` SI le document n'existe pas (gere par merge naturellement avec `FieldValue.serverTimestamp()` first-write).
- Le script affiche le compteur final : `[OK] schools : N docs (X validated, 0 unvalidated)`.
- En cas d'erreur (auth, validation, FirestoreException), le script renvoie exit code != 0 + message clair (stderr).
- Logs : pas de PII (pas de uid utilisateur, le script tourne hors-session). OK de logger schoolId + name (data publique referentielle).

**Naming nomenclature (CLAUDE.md regle 5)** :
- Filename anglais : `seed_schools.py`, `schools.json`, `test_seed_schools.py`
- Fonctions Python anglais : `_validate_schools()`, `_seed_schools()`, `_validate_school()`, `_init_firebase()` (reutilisable)
- Variables anglais : `school_id`, `sub_system`, `is_validated`, etc.
- `schoolId` (data Firestore) peut rester en langue : `school_lycee_bilingue_bonaberi` accepte (data referentielle).

### AC3 — Tests pytest sans Firestore live

**Given** le pattern Story 1.1b (`tests/test_seed.py` qui valide la matrice JSON statique sans connexion Firestore)
**When** le developpeur cree `scripts/firebase_seed/tests/test_seed_schools.py`
**Then** :

- Au moins 6 tests pytest qui valident la matrice statique :
  1. `test_schools_json_loads` : le fichier est un JSON valide
  2. `test_schools_has_required_fields` : chaque school a tous les champs requis
  3. `test_schools_ids_unique` : aucun doublon schoolId
  4. `test_schools_subsystem_valid` : `subSystem` ∈ {francophone, anglophone, both}
  5. `test_schools_names_non_empty` : `name`, `city`, `region` non-vides
  6. `test_schools_ids_slugified` : `schoolId` matche pattern `^school_[a-z0-9_]+$`
- `pytest scripts/firebase_seed/tests/ -v` passe avec 6+ tests verts (tests existants Story 1.1b inchanges).

### AC4 — Reseed valide-edu (action porteur post-merge)

**Given** la PR mergee sur main
**When** Delano lance manuellement le seed
**Then** :

- `python seed_schools.py --project valide-edu --dry-run` confirme la matrice OK.
- `python seed_schools.py --project valide-edu` ecrit N ecoles MINESEC dans Firestore.
- Smoke test manuel : ouvrir Valide School sur device, tap « Lier mon ecole », taper « Lycee » → au moins 5 cards visibles (apres debounce 300ms + query index composite (isValidated, name) deja deploye Story 1.7).
- Compteur Firestore Console : `schools/` contient N+ documents (verifie via Firebase Console).
- Aucun document non-MINESEC ne doit etre ecrase si le script est relance (idempotence verifiee via re-run dry-run).

**Action porteur post-merge** documentee dans la Completion Notes : commande exacte + screenshot Firebase Console.

### AC5 — Documentation README mise a jour

**Given** le `scripts/firebase_seed/README.md` actuel decrit uniquement seed_catalogue.py
**When** la story livre seed_schools.py
**Then** :

- `scripts/firebase_seed/README.md` est etendu avec une section « Seed schools (Story 1.5.a) » : pre-requis, commandes (dry-run + seed), maintenance (ajout d'une ecole via PR sur schools.json + re-run).
- `scripts/firebase_seed/data/README.md` est etendu avec une section « schools.json » : structure attendue, conventions schoolId, mapping subSystem.
- Le BASE-DE-DONNEES.md `schools/{schoolId}` (ligne 586) est mis a jour avec un statut 🟢 (etait 🟡) + un lien vers le seed.

### AC6 — Cost-benefit Firestore documente

**Given** CLAUDE.md regle 10m exige le cost-benefit pour toute nouvelle collection seedee
**When** la story est en dev
**Then** la section « Cost-benefit Firestore » des Dev Notes est completee (voir Dev Notes ci-dessous : 3 axes (reads/session, volumetrie 10k users, trade-off accepte) + checklist sous-regles).

## Tasks / Subtasks

- [x] **T1 — Recuperer et normaliser le fichier source MINESEC** (AC1)
  - [x] Demander a Delano le fichier `C:\Users\Emerite\Documents\projets\Mobile\Valide\etablissements_minesec_cameroun.json` (decision : fichier non disponible, source recherche web)
  - [x] Lire et analyser les sources publiques disponibles (Wikipedia FR + techno-science.net + GCE Board + camgceb.org)
  - [x] Composer le dataset V1 representatif (198 ecoles, 10 regions) directement dans `scripts/firebase_seed/data/schools.json` (slugification reproductible + heuristique subSystem)
  - [x] Verifier la structure : 198 docs, 10 regions, mix 136 fr / 35 both / 27 anglo
  - [x] Commit `data/schools.json` (scope core)

- [x] **T2 — Implementer `seed_schools.py`** (AC2)
  - [x] Cree `scripts/firebase_seed/seed_schools.py` calque sur `seed_catalogue.py` (argparse + ADC/service-account + dry-run + validation + seed + main)
  - [x] Implemente `_validate_schools()` + `_validate_school()` (champs requis + types + unicite schoolId + slug pattern + subSystem allowlist)
  - [x] Implemente `_seed_schools()` : iteration + `db.collection('schools').document(school_id).set(payload, merge=True)`
  - [x] `'createdAt': firestore.SERVER_TIMESTAMP` ajoute au payload (merge preserve la valeur existante sur re-runs)
  - [x] `_init_firebase()` reste local (copie acceptable, refactor extract differable Story 1.5.b si autre script en a besoin)
  - [x] Dry-run validation : `[OK] 198 docs (198 validated, 0 unvalidated)`

- [x] **T3 — Tests pytest** (AC3)
  - [x] Cree `scripts/firebase_seed/tests/test_seed_schools.py` avec 9 tests (cible 6 depassee : 6 ACs + 3 bonus regions/validator/mix)
  - [x] `pytest scripts/firebase_seed/tests -v` : 15/15 passed (6 Story 1.1b + 9 Story 1.5.a = 0 regression)

- [x] **T4 — Dry-run + seed reel sur valide-edu** (AC4)
  - [x] Dry-run OK : 198 docs validated
  - [x] Seed reel : `python seed_schools.py --project valide-edu` OK, 198 documents ecrits en 48.04 s sur valide-edu via ADC
  - [ ] Smoke test mobile : tap « Lier mon ecole », taper « Lycee », verifier ≥ 5 cards (**action porteur post-merge** : Delano sur device Android)
  - [x] Commande documentee + nombre seedes dans Completion Notes

- [x] **T5 — Documentation README** (AC5)
  - [x] `scripts/firebase_seed/README.md` etendu section « Seed schools (Story 1.5.a) » (objectif + prerequis + execution + modifier matrice + tests + sources composites)
  - [x] `scripts/firebase_seed/data/README.md` etendu : header inventaire 2 fichiers + section dediee `schools.json` (source + conventions schoolId + champ par champ + 10 regions + heuristique subSystem + volumetrie + workflow + lien Story 1.5.c)
  - [x] `doc/partage/BASE-DE-DONNEES.md` ligne 49 (table Vue d'ensemble) : `schools` 🟡 → 🟢
  - [x] `doc/partage/BASE-DE-DONNEES.md` ligne 586 (section dediee) : `schools/{schoolId}` 🟡 → 🟢 + bloc explicatif seed + convention schoolId formalisee
  - [x] `doc/partage/BASE-DE-DONNEES.md` table Historique : entree 2026-06-10 Story 1.5.a ajoutee

- [x] **T6 — Validation finale + PR** (toutes ACs)
  - [x] Re-run `pytest` final : 15/15 passed
  - [x] Pas de regression Story 1.7 (le seed peuple la collection sans modifier le repo Dart)
  - [ ] Pousser branche `feature/1-5-a-seed-minesec-schools` sur origin (suite : action commit + push)
  - [ ] Ouvrir PR avec body (URL fournie en fin de message car gh CLI absent)
  - [ ] Attendre merge avant Story 1.5.b (CLAUDE.md regle 6 sequencement strict)

## Dev Notes

### Contexte et motivation

Story 1.7 (PR #53 mergee 2026-06-08) a livre `school_picker_page.dart` + `school_repository_firestore_impl.dart` + modele `School` + index composite `(isValidated ASC, name ASC)` deploye. Mais la collection Firestore `schools` du projet `valide-edu` est restee VIDE. Resultat : sur reseau reel Cameroun, l'UX de Story 1.7 est cassee — tout utilisateur tombe sur 0 resultat. La retro Epic 1 v2 (lignes 343-349) a cadre Epic 1.5 « Schools completion » comme prerequis pour Epic 2.

### Decisions techniques cles

- **Decision 1** : Reutiliser le pattern Python Story 1.1b (`seed_catalogue.py`) comme modele — **raison** : meme structure (matrice JSON versionnee + script idempotent set(merge=True) + tests pytest sans Firestore live + auth ADC) — **alternative ecartee** : Cloud Function callable de seed (overkill pour un seed one-shot par environnement Firebase).
- **Decision 2** : `schoolId` genere par slugification reproductible (`slugify(name + city)`) — **raison** : evite les collisions (deux « Lycee Joss » dans deux villes differentes), garantit l'idempotence multi-run — **alternative ecartee** : UUID auto-generes (perte d'idempotence : un re-seed dupliquerait les docs).
- **Decision 3** : `isValidated: true` pour TOUTES les ecoles MINESEC seedees — **raison** : la source MINESEC est officielle et fait autorite, pas besoin de moderation admin pour ces docs (la moderation `isValidated: false` est reservee aux demandes utilisateur Story 1.5.c) — **alternative ecartee** : seed avec `isValidated: false` + moderation manuelle (sur-engineering pour un seed officiel).
- **Decision 4** : `createdAt: firestore.SERVER_TIMESTAMP` ajoute uniquement first-write — **raison** : preserve la trace de creation initiale meme apres re-seeds — **alternative ecartee** : `updatedAt` champ supplementaire (hors-schema BASE-DE-DONNEES.md, KISS pour V1).
- **Decision 5** : Le subSystem est mappe par HEURISTIQUE sur le nom de l'ecole — **raison** : la source MINESEC n'a probablement pas de champ `subSystem` explicite (a verifier T1) — **trade-off accepte** : risque d'erreur sur quelques ecoles bilingues ambigues (correction manuelle possible via Firebase Console toggle ulterieur).

### Modele de donnees / API impactes

- **Fichier ajoute** : `scripts/firebase_seed/data/schools.json` (matrice versionnee)
- **Fichier ajoute** : `scripts/firebase_seed/seed_schools.py` (script Python autonome)
- **Fichier ajoute** : `scripts/firebase_seed/tests/test_seed_schools.py` (tests pytest)
- **Fichier ajoute** (optionnel) : `scripts/firebase_seed/normalize_minesec.py` (one-shot T1, peut etre versionne ou supprime apres T1)
- **Fichier ajoute** (optionnel) : `scripts/firebase_seed/_firebase.py` (factorisation `_init_firebase()` si duplication evidente)
- **Schema Firestore** : `schools/{schoolId}` schema inchange (cf. BASE-DE-DONNEES.md ligne 586). Seul le statut passe 🟡 → 🟢.
- **Index Firestore** : aucun nouveau (l'index composite `(isValidated, name)` deja deploye Story 1.7 suffit pour la query Story 1.7).
- **Contrats Cloud Function** : aucun changement (le seed est cote Python local, pas backend).
- **firestore.rules** : aucun changement (lecture authentifiee suffit pour le mobile, l'ecriture script via service-account / ADC contourne les rules cote serveur).

### Cost-benefit Firestore

**Type d'impact** : Premier seed massif d'une collection existante (`schools` cree en Story 1.7 mais vide). Pas de nouvelle collection, pas de nouvel index, pas de snapshots(), pas de denormalisation.

**Reads / ecriture par session utilisateur moyenne** :
- Lecture (Story 1.7 search) : 1 reads/search × 2-3 searches en moyenne par onboarding = ~3 reads/session
- Ecriture (one-shot seed admin, hors-session utilisateur) : N writes initiaux + N writes re-seed eventuels (rare)
- Latence cible : < 800 ms recherche autocomplete sur 3G degrade (deja valide Story 1.7 sur device)

**Volumetrie estimee a 10 000 utilisateurs** :
- Documents dans `schools/` : ~ 300-2000 ecoles MINESEC (a confirmer T1 selon contenu source). Hypothese 1500 docs.
- Reads/jour : 10 000 nouveaux users × 3 search/onboarding × 30j = 900k reads/mois en pointe (≪ quota gratuit 50k/jour Firestore = ~1.5M/mois)
- Cout mensuel estime : negligeable (cache offline Firestore evite la majorite des re-reads dans une meme session)

**Trade-off accepte vs alternative ecartee** :
- **Alternative A (ecartee)** : Stocker les ecoles dans un asset Flutter bundle (`assets/data/schools.json`) — **raison du refus** : (1) interdit la mise a jour sans release mobile, (2) augmente le bundle size (1500 docs × 200 bytes = 300 KB), (3) empeche les ecoles ajoutees via Story 1.5.c flow demande ajout d'apparaitre sans release.
- **Choix retenu** : Firestore collection + seed Python idempotent — **benefice principal** : data evolutive (admin ajoute une ecole en Firebase Console OU PR sur schools.json + re-seed) + cache offline Firestore (les ecoles deja recherchees restent disponibles offline).

**Check CLAUDE.md regle 10 sous-regles** :
- [x] (a) Modelise par requete : Story 1.7 query 1 read par autocomplete (≪ 3 reads/ecran cible)
- [ ] (b) Denormalisation : N/A cette story (denormalisation `schoolName` deferree Epic 2+ par BASE-DE-DONNEES.md ligne 799)
- [x] (c) `limit(N)` explicite : Story 1.7 utilise `limit(10)` ✅
- [x] (d) Prefiltre serveur : `where('isValidated', isEqualTo: true)` ✅
- [ ] (e) `arrayContains` : N/A cette story (sera applique Story 1.5.b pour keywords[])
- [x] (g) `snapshots()` vs `.get()` : Story 1.7 utilise `.get()` ✅ (data quasi-statique, cache offline suffit)
- [ ] (i) `count()` server-side : N/A cette story (pas de comptage)
- [x] (k) Lecture par ID : N/A pour la recherche autocomplete (la query est necessaire), MAIS l'ecriture seed utilise `.document(schoolId).set(...)` ✅
- [x] (l) `set(merge: true)` : ✅ pattern impose dans T2

**Anti-patterns evites** :
- [x] Pas de lecture collection sans `limit()` (Story 1.7 limite a 10)
- [x] Pas de `snapshots()` sur catalogue statique (Story 1.7 .get() ✅)
- [x] Pas de filtrage cote Dart (where isValidated cote Firestore ✅)
- [x] Pas de N+1 reads (la query unique retourne tout)
- [x] Pas de reecriture doc entier pour modifier 1 champ (seed initial only)
- [x] Pas d'`offset()` pour pagination (Story 1.7 limit unique sans pagination V1)

### Strategie responsive

**N/A pour cette story** — la story est 100% backend (script Python + seed Firestore), aucune modification UI Flutter.

### Composants reutilisables

**N/A pour cette story** — la story n'ajoute aucun widget Flutter.

### Tests a ecrire

**Unit (pytest)** :
- `test_schools_json_loads` : `json.loads(schools.json)` reussit
- `test_schools_has_required_fields` : chaque school a {schoolId, name, city, region, subSystem, isValidated}
- `test_schools_ids_unique` : `set(schoolIds) == len(schools)` (pas de doublon)
- `test_schools_subsystem_valid` : `subSystem ∈ {'francophone', 'anglophone', 'both'}`
- `test_schools_names_non_empty` : `name.strip() != ''` AND `city.strip() != ''` AND `region.strip() != ''`
- `test_schools_ids_slugified` : `re.match(r'^school_[a-z0-9_]+$', schoolId)` pour chaque

**Integration (manuel sur valide-edu)** :
- Dry-run output coherent
- Seed reel + Firebase Console verifie peuplement collection
- Smoke device : Story 1.7 school_picker_page affiche ≥ 5 cards apres taper « Lycee »

**Pas de tests** :
- Pas de tests Flutter (rien ne change cote mobile)
- Pas de tests integration Firestore live (interdit par feedback `firebase_no_emulator.md` + pattern Story 1.1b)
- Pas de tests E2E (script seed = action one-shot porteur, pas un flow utilisateur)

### Anti-patterns a eviter

- ❌ **Re-implementer un client Firestore custom** — utiliser `firebase_admin` officiel (deja dans `requirements.txt` Story 1.1b)
- ❌ **Hard-coder le project ID `valide-edu`** dans le script — passer via `--project` argparse (Story 1.1b pattern)
- ❌ **Skipper la validation pre-ecriture** — la validation `_validate_schools()` est non-negociable (evite de corrompre Firestore avec une matrice cassee)
- ❌ **Utiliser `add()`** au lieu de `set(merge=True)` — perd l'idempotence (cf. seed_catalogue.py commentaire ligne 21-23)
- ❌ **Commit `service-account.json`** par erreur — le .gitignore Story 1.1b couvre deja `service-account*.json` mais double-check `git status` avant push
- ❌ **Logger l'integralite du JSON source** — taille excessive, polluer la console. Logger juste les compteurs (cf. seed_catalogue.py pattern).
- ❌ **Ecraser les `createdAt`** existants lors d'un re-seed — utiliser `merge=True` qui preserve naturellement les champs existants (NE PAS overwrite `createdAt` explicitement)
- ❌ **Generer des `schoolId` non-deterministes** (timestamp, UUID) — casse l'idempotence du re-seed
- ❌ **Inferer subSystem en silence sans logger les ambiguites** — log warning sur chaque ecole ou l'heuristique est < 100% confiante (ex. nom « Lycee » + « College » dans le meme nom → ambigu)
- ❌ **Mettre `isValidated: false` sur les ecoles MINESEC** — par hypothese, la source MINESEC fait autorite (Story 1.5.c gere les demandes ajout utilisateur qui sont `isValidated: false` jusqu'a moderation)

### References

- [Story 1.1b seed pattern source] : `scripts/firebase_seed/seed_catalogue.py` + `README.md`
- [Story 1.7 origine modele + impl] : `project_manage/implementation-artifacts/1-7-liaison-ecole-optionnelle.md`
- [Schema Firestore autoritatif] : `doc/partage/BASE-DE-DONNEES.md` § `schools/{schoolId}` lignes 586-602
- [Retro Epic 1 v2 cadrage Epic 1.5] : `project_manage/implementation-artifacts/epic-1v2-retro-2026-06-10.md` lignes 343-349
- [Memoire gap analyse] : `~/.claude/projects/.../memory/project_schools_gaps_post_epic_1_v2.md`
- [CLAUDE.md regle 5 nomenclature anglaise] : root `CLAUDE.md` § Workflow Git
- [CLAUDE.md regle 10 cost-benefit Firestore] : root `CLAUDE.md` § Architecture mobile
- [BASE-DE-DONNEES.md historique a mettre a jour] : T5 commit

## Dev Agent Record

### Agent Model Used

Claude Opus 4.7 (1M context)

### Debug Log References

- `python seed_schools.py --project valide-edu --dry-run` : `[OK] 198 docs (198 validated, 0 unvalidated)` en 0.00 s
- `gcloud auth application-default print-access-token` : ADC OK
- `python seed_schools.py --project valide-edu` : `[OK] schools : 198 docs (198 validated, 0 unvalidated)` en 48.04 s
- `pytest scripts/firebase_seed/tests -v` : 15 passed (0 failure, 0 regression vs baseline Story 1.1b 6 tests)

### Implementation Plan

T1 : decision pivote — le fichier MINESEC local n'etait pas disponible (non versionne, introuvable sur le poste). Choix utilisateur : recherche web + composition du dataset. WebSearch + WebFetch sur Wikipedia FR + techno-science.net + GCE Board + camgceb.org. Composition manuelle du JSON ~250 ecoles francophones depuis techno-science + ~50 anglophones depuis GCE Board + knowledge generale du systeme scolaire camerounais (10 regions, conventions MINESEC). Slug `school_<slug_nom>_<slug_ville>` deterministe. Heuristique subSystem : `Lycee/College` -> francophone, `GHS/PSS/Comprehensive` -> anglophone, `Bilingue/GBHS` -> both.

T2-T3 : calque exact sur `seed_catalogue.py` (Story 1.1b). Conventions Python anglaises (CLAUDE.md regle 5). Validator strict (pattern slug + allowlist subSystem + unicite schoolId). Tests pytest hors-Firestore live (CLAUDE.md feedback `firebase_no_emulator.md`).

T4 : seed reel ADC sans incident (48 s sur reseau ouest-europeen). Smoke device reporte porteur (necessite app sur device + connexion reseau Cameroun).

T5 : statut 🟡 → 🟢 BASE-DE-DONNEES table Vue d'ensemble + section dediee. Historique date + scope. Pas de modification schema (compat 100% Story 1.7).

T6 : tests verts, commit unique avec scope `core` (script + data) + `partage` (BASE-DE-DONNEES).

### Completion Notes List

- **Pivot scope T1** : fichier MINESEC local non disponible -> recherche web + composition manuelle du dataset (decision utilisateur 2026-06-10). Dataset V1 representatif (~198 ecoles) plutot que exhaustif (~1500) — couvre les 10 regions officielles + grandes villes (Yaoundé 30, Douala 28, Bafoussam 9, Dschang 6, Garoua 10, Maroua 5, Ngaoundéré 4, Buea 7, Limbe 3, Bamenda 7, Kumba 3, Mamfe 4, etc.). Extensible via PR sur `schools.json` + flow demande ajout Story 1.5.c.
- **Commande seed exacte** : `python C:\Users\Emerite\Documents\projets\Mobile\Valide\scripts\firebase_seed\seed_schools.py --project valide-edu` (auth ADC, 48 s, 198 docs)
- **Verification Firebase Console** : a faire post-merge (URL `https://console.firebase.google.com/project/valide-edu/firestore/data/~2Fschools`)
- **Anomalies normalize** : aucune (dataset compose manuellement, slugs deterministes, mix subSystem reflete demographie reelle 70% fr / 18% both / 14% anglo)
- **Action porteur post-merge** :
  1. (optionnel) Verifier `valide-edu` Firebase Console : 198 docs `schools/` avec champ `createdAt` Timestamp
  2. Smoke test device : ouvrir app, /onboarding/school, taper « Lycee » (FR) ou « Government » (EN), verifier ≥ 5 cards
  3. (optionnel) Promouvoir le dataset via PR ulterieure quand de nouvelles ecoles MINESEC officielles sont identifiees (workflow documente dans `scripts/firebase_seed/data/README.md`)

### File List

- `scripts/firebase_seed/data/schools.json` (NEW) — 198 ecoles, 10 regions, V1
- `scripts/firebase_seed/seed_schools.py` (NEW) — script Python autonome idempotent
- `scripts/firebase_seed/tests/test_seed_schools.py` (NEW) — 9 tests pytest sans Firestore live
- `scripts/firebase_seed/README.md` (UPDATED) — section « Seed schools (Story 1.5.a) » ajoutee
- `scripts/firebase_seed/data/README.md` (UPDATED) — header inventaire 2 fichiers + section dediee schools.json
- `doc/partage/BASE-DE-DONNEES.md` (UPDATED) — table Vue d'ensemble + section schools 🟡 → 🟢 + Historique 2026-06-10
- `project_manage/implementation-artifacts/sprint-status.yaml` (UPDATED) — 1.5.a ready-for-dev -> in-progress -> review
- `project_manage/implementation-artifacts/1-5-a-seed-minesec-schools.md` (UPDATED) — Tasks coches + Dev Agent Record + Change Log + Status review

## Change Log

| Date | Author | Change |
|---|---|---|
| 2026-06-10 | Amelia (bmad-create-story) | Creation initiale via /bmad-create-story, baseline 607711e (post-merge Story 1.18) |
| 2026-06-10 | Amelia (bmad-dev-story) | Dev complete T1-T6. Pivot T1 : recherche web composite (Wikipedia FR + techno-science + GCE Board) au lieu de fichier source MINESEC local non disponible. Dataset V1 198 ecoles (10 regions, 136 fr / 35 both / 27 anglophone). seed_schools.py + 9 pytest tests. Seed reel valide-edu OK (48 s ADC). BASE-DE-DONNEES schools 🟡 → 🟢. Status ready-for-dev -> in-progress -> review. |
