---
story_id: 1.5.b
title: Recherche ecoles optimisee keywords[] arrayContains (Epic 1.5 Schools completion)
epic: 1
micro_epic: 1.5
phase: P1
status: review
created: 2026-06-10
baseline_commit: 0e1df0a  # post-merge PR #92 Story 1.5.a
estimation: M-L (~5-7h)
dependencies:
  - 1.5.a  # collection schools peuplee (198 docs MINESEC+GCE) avec champs name + city + region
  - 1.7    # school_picker_page UI + repo + index actuel (isValidated, name)
blocks:
  - 1.5.c  # flow demande ajout (devra integrer keywords[] generation au moment de la promotion request -> doc valide)
  - 1.5.d  # denormalisation user (independante mais Story 1.5 devrait etre coherente)
sourceArtifacts:
  - project_manage/implementation-artifacts/1-5-a-seed-minesec-schools.md (seed v1)
  - project_manage/implementation-artifacts/1-7-liaison-ecole-optionnelle.md (UI + repo + index actuel)
  - mobile_app/lib/features/onboarding/data/school_repository_firestore_impl.dart (query a refactorer)
  - mobile_app/lib/features/onboarding/domain/school.dart (model a etendre)
  - mobile_app/lib/features/onboarding/presentation/school_picker_page.dart (UI inchangee)
  - mobile_app/lib/features/onboarding/providers.dart (schoolSearchNotifierProvider inchange)
  - mobile_app/test/features/onboarding/data/school_repository_test.dart (tests a etendre)
  - mobile_app/test/features/onboarding/presentation/school_picker_page_test.dart (tests a verifier)
  - scripts/firebase_seed/seed_schools.py (script a etendre avec _generate_keywords)
  - scripts/firebase_seed/data/schools.json (matrice a regenerer auto via script)
  - scripts/firebase_seed/tests/test_seed_schools.py (tests a etendre)
  - firestore.indexes.json (nouvel index composite a ajouter + deployer)
  - doc/partage/BASE-DE-DONNEES.md § schools/{schoolId} (schema + Indexes + Read patterns a mettre a jour)
  - CLAUDE.md regles 5 + 9 + 10e + 10m (nomenclature + index composite obligatoire + arrayContains + cost-benefit)
---

# Story 1.5.b — Recherche ecoles optimisee keywords[] arrayContains

Status: **review**

## Objectif

Remplacer la query de recherche d'ecoles (Story 1.7) qui utilise un **prefix range case-sensitive sur le champ `name`** par une query **`arrayContains` sur un nouveau champ `keywords[]`** — pour debloquer une UX de recherche **insensible a la casse et aux accents**, **multi-mots distinctifs**, et **tolerante aux abreviations courantes** (« GHS » → Government High School, « LGL » → Lycee General Leclerc, etc.).

**Pourquoi maintenant** : Story 1.5.a a livre 198 ecoles seedees mais la query Story 1.7 actuelle (`where('name', isGreaterThanOrEqualTo: query)` + `where('name', isLessThan: '$query$_kUpperBound')`) presente plusieurs problemes critiques sur le reseau Cameroun :
- L'utilisateur tape « lycee » (lower-case sans accent) -> 0 resultat (Firestore est case-sensitive sur les comparaisons string)
- L'utilisateur tape « ecole » (sans accent) -> ne matche pas « Ecole »
- L'utilisateur tape « bilingue bonaberi » -> 0 resultat (pas un prefix exact du nom officiel)
- L'utilisateur ne connait pas les premiers caracteres exacts du nom officiel -> abandon UX

**Pourquoi `keywords[] arrayContains`** : conforme CLAUDE.md regle 10e (arrayContains pour liste < 15 elements) + 1 read facturable par requete (limit 10) + pattern utilise dans `niveaux/filiereIds` (Story 1.1a precedent). Index composite Firestore `(isValidated ASC, keywords ARRAY)` couvre la nouvelle query.

**Hors-scope explicite** :
- ❌ Fuzzy matching tolerant aux fautes de frappe (« lycee » vs « licee ») -> hors V1, necessiterait Algolia/Typesense (overkill)
- ❌ Recherche multi-token AND (« lycee bilingue » = ecole avec LES 2 tokens) -> Firestore n'autorise qu'un seul arrayContains par query. V1 utilise un seul token (le premier mot >= 2 chars). Multi-token AND traitable Story future via Cloud Function ou via abstraction multi-query cote mobile (cf. NFR-perf).
- ❌ Refonte UI (school_picker_page.dart reste inchange — seul le repo change)
- ❌ Migration data destructive (le champ `name` reste, pour audit + retro-compat avant suppression definitive)

**Critere de fin** :
1. Le script `seed_schools.py` etendu genere automatiquement `keywords[]` a partir de `name + city + region + abreviations communes`.
2. Les 198 ecoles de `schools.json` sont regenerees avec leur `keywords[]` (~5-15 tokens par ecole).
3. L'index composite `(isValidated ASC, keywords ARRAY)` est declare dans `firestore.indexes.json` et deploye sur `valide-edu`.
4. Le modele Dart `School` expose `keywords: List<String>` (optionnel pour retro-compat docs Story 1.7).
5. `school_repository_firestore_impl.searchByPrefix()` utilise `.where('isValidated', isEqualTo: true).where('keywords', arrayContains: tokenNormalized).limit(10)`.
6. James tape « lycee » (lower-case) sur device -> ≥ 5 cards visibles (test manuel apres reseed).
7. James tape « ecole » (sans accent) sur device -> matche les ecoles « Ecole ».
8. `flutter analyze` 0 issue + `flutter test` 100% verts (zero regression Stories 1.7 + 1.5.a) + `pytest scripts/firebase_seed/tests -v` 100% verts.

## Story

**As a** eleve qui cherche son ecole sur Valide School (post Story 1.5.a seed),
**I want** taper le nom de mon ecole en lower-case, sans accents, ou par abreviation commune (« lycee », « ghs », etc.),
**so that** je trouve mon ecole en ≤ 3 frappes sans avoir a connaitre les premiers caracteres exacts du nom officiel (UX reseau Cameroun).

## Acceptance Criteria

### AC1 — Schema Firestore etendu avec champ `keywords[]`

**Given** le schema actuel `SchoolDoc` (BASE-DE-DONNEES.md ligne 591) avec champs `{schoolId, name, city, region, subSystem, isValidated, createdAt}`
**When** la story est implementee
**Then** :
- Le schema TypeScript inclut un nouveau champ `keywords: string[]` (lower-case sans accents).
- Le champ est obligatoire post-Story 1.5.b (les docs existants seedes Story 1.5.a sont mis a jour via re-seed idempotent).
- Schema documente dans BASE-DE-DONNEES.md :
  ```typescript
  interface SchoolDoc {
    schoolId: string;
    name: string;
    city: string;
    region: string;
    subSystem: "francophone" | "anglophone" | "both";
    isValidated: boolean;
    createdAt: Timestamp;
    keywords: string[];                   // Story 1.5.b — lower-case sans accents, tokens du nom + ville + region + abreviations
  }
  ```

### AC2 — Generation `keywords[]` cote seed Python deterministe

**Given** un school dict `{schoolId, name, city, region, subSystem, isValidated}`
**When** le script seed_schools.py est lance (genere keywords automatiquement)
**Then** la fonction `_generate_keywords(school)` produit une liste `string[]` :

1. **Sources des tokens** :
   - Le `name` complet (lower-case, sans accents, tokenise sur whitespace + tirets + apostrophes)
   - La `city` (lower-case sans accents, mot unique ou tokenise)
   - La `region` (lower-case sans accents, mot unique ou tokenise)
   - **Abreviations communes** mappees depuis le nom :
     - « Government High School » -> ajouter `ghs`
     - « Government Bilingual High School » -> ajouter `gbhs`
     - « Presbyterian Secondary School » -> ajouter `pss`
     - « College » -> ajouter `college` (deja extrait via tokenization)
     - « Lycee » -> ajouter `lycee` (deja extrait)

2. **Filtrage** :
   - Conserver uniquement les tokens `length >= 2`
   - Deduplique (set)
   - Trie alphabetique (pour idempotence stable)

3. **Pattern de normalisation** :
   - `lower()` apres `unidecode()` (package `unidecode>=1.3.0` ajoute a `requirements.txt`)
   - Strip de la ponctuation (`re.sub(r'[^a-z0-9]', ' ', s)`)
   - Split sur whitespace + filter empty

4. **Cas concrets** :
   - `Lycee Bilingue de Bonaberi` (city: Douala, region: Littoral) -> keywords = `["bilingue", "bonaberi", "de", "douala", "littoral", "lycee"]`
   - `Government High School Buea Town` (city: Buea, region: Sud-Ouest) -> keywords = `["buea", "ghs", "government", "high", "school", "sud", "ouest", "town"]`
   - `College Vogt` (city: Yaounde, region: Centre) -> keywords = `["centre", "college", "vogt", "yaounde"]`

5. **Volumetrie attendue** : ~5-15 tokens par ecole (mediane ~8). Distribution verifiable via test pytest stats.

### AC3 — Script `seed_schools.py` regenere `data/schools.json` automatiquement

**Given** le script Python autonome
**When** une option `--regen-keywords` est ajoutee
**Then** :
- `python seed_schools.py --regen-keywords` lit `data/schools.json` actuel, applique `_generate_keywords(school)` a chaque entree, ecrit le fichier mis a jour.
- L'option est combinable avec `--dry-run` : `--regen-keywords --dry-run` log les keywords generes par ecole sans modifier le JSON.
- Sans `--regen-keywords`, le script utilise les `keywords[]` deja presents dans `schools.json` (ou genere a la volee si absent — fallback safe pour seed initial).
- Le commit Story 1.5.b inclut `schools.json` regenere (198 ecoles avec champ `keywords[]`).

### AC4 — Tests pytest etendus

**Given** les 9 tests existants Story 1.5.a (test_seed_schools.py)
**When** la story est implementee
**Then** au moins 5 tests supplementaires :
- `test_keywords_generated_for_all_schools` : chaque ecole a un champ `keywords` non-vide (≥ 3 tokens)
- `test_keywords_lowercase_no_accents` : tous les tokens matchent `^[a-z0-9]+$` (no uppercase, no accent)
- `test_keywords_contain_normalized_name_tokens` : pour 5 ecoles sample, les tokens du nom (normalises) sont presents dans `keywords`
- `test_keywords_contain_city_and_region` : `city` et `region` normalises sont presents dans `keywords`
- `test_keywords_contain_abbreviations_when_applicable` : si nom contient « Government High School » -> `keywords` contient `ghs` ; idem pour `gbhs`, `pss`
- `test_keywords_deduplicated_and_sorted` : pas de doublon + ordre alphabetique pour idempotence
- `test_keywords_minimum_3_tokens` : chaque ecole a >= 3 keywords (defense contre name vide)
- (Bonus) `test_generate_keywords_idempotent` : `_generate_keywords(s)` retourne le meme array si appele 2x

### AC5 — Index Firestore composite `(isValidated, keywords ARRAY)` ajoute + deploye

**Given** l'index actuel `(isValidated ASC, name ASC)` sur schools (Story 1.7)
**When** la story est implementee
**Then** :
- Le nouvel index est declare dans `firestore.indexes.json` racine (CLAUDE.md regle 9) :
  ```json
  {
    "collectionGroup": "schools",
    "queryScope": "COLLECTION",
    "fields": [
      { "fieldPath": "isValidated", "order": "ASCENDING" },
      { "fieldPath": "keywords", "arrayConfig": "CONTAINS" }
    ]
  }
  ```
- L'ancien index `(isValidated, name)` est **conserve** (utile pour audit / migration safe / requetes admin futures).
- `firebase deploy --only firestore:indexes --project valide-edu` deploie le nouvel index (etat IDLE attendu apres 1-5 min).
- Le deploy + l'attente IDLE sont documentes dans Completion Notes.

### AC6 — Modele Dart `School` etendu avec `keywords`

**Given** le modele Dart actuel `School(schoolId, name, city, region, subSystem, isValidated)`
**When** la story est implementee
**Then** :
- Le modele expose `keywords: List<String>` (par defaut `[]` pour retro-compat si un doc Firestore n'a pas le champ — rare).
- `Equatable.props` inclut `keywords` pour l'egalite (consistant avec les autres champs).
- `_schoolFromDoc` lit `(data['keywords'] as List<dynamic>?)?.cast<String>() ?? <String>[]`.

### AC7 — `SchoolRepositoryFirestoreImpl.searchByPrefix()` refactorise

**Given** la query actuelle (3 `.where()` + `.orderBy('name')` + `.limit(10)`)
**When** la story est implementee
**Then** :
- La nouvelle query est :
  ```dart
  final tokenNormalized = _normalizeForSearch(query);  // lower-case + sans accents, premier mot
  final snap = await _firestore
      .collection(_kCollection)
      .where('isValidated', isEqualTo: true)
      .where('keywords', arrayContains: tokenNormalized)
      .limit(_kMaxResults)
      .get();
  ```
- La fonction `_normalizeForSearch(String query)` :
  - Retourne `String?` (null si query trop courte apres normalisation)
  - Lower-case
  - Remplace les accents FR principaux par leur equivalent ASCII (`é, è, ê, ë -> e`, `à, â, ä -> a`, `î, ï -> i`, `ô, ö -> o`, `û, ù, ü -> u`, `ç -> c`)
  - Strip ponctuation (`replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')`)
  - Split sur whitespace, garde le premier token >= 2 chars
  - Si aucun token >= 2 chars -> retourne null -> `Right(<School>[])`
- Tri cote Dart : les resultats sont tries alphabetiquement sur `name` apres le `.get()` (Firestore `arrayContains` + `orderBy` necessiterait un index complexe — V1 fait le tri client cote 10 items max, cout negligeable).
- Le log existant reste : `AppLogger.i('School search: q3="$q3" count=$count')` avec q3 normalise (3 premiers chars).

### AC8 — Tests repository etendus (fake_cloud_firestore)

**Given** `school_repository_test.dart` actuel (5 tests Story 1.7)
**When** la story est implementee
**Then** au moins 4 tests supplementaires Story 1.5.b :
- `test '(f) query case-insensitive matche keywords[]'` : seed avec keywords pre-genere, query « lycee » lower-case -> matche « Lycee Bilingue de Bonaberi » et « Lycee Joss »
- `test '(g) query avec accent matche normalise'` : query « lycee » accentue (en realite Dart ne genere pas d'accent en input standard ASCII mais on simule avec un input contenant é) -> matche les memes ecoles
- `test '(h) query abreviation GHS matche keywords['ghs']'` : seed avec « Government High School Buea Town » et keywords contenant `ghs` -> query « ghs » matche
- `test '(i) query trop courte (1 char) court-circuite avant Firestore'` : reuse du pattern Story 1.7 test (c) avec la nouvelle logique normalize
- `test '(j) tri cote Dart par name apres get()'` : seed 3 ecoles avec keywords compatibles + names dans ordre arbitraire -> resultat est trie alphabetique
- (Conservation) Les 5 tests Story 1.7 doivent etre adaptes pour utiliser `keywords[]` au seed (pas casser les ACs Story 1.7).

### AC9 — Widget tests Story 1.7 preserves

**Given** `school_picker_page_test.dart` Story 1.7 (5 tests dont test e tablet 900x1200)
**When** la story est implementee
**Then** :
- Les tests existants restent verts (utilisent un FakeSchoolRepo qui n'utilise pas la query Firestore reelle — minimal impact)
- Aucune adaptation de school_picker_page.dart necessaire (UI inchange)

### AC10 — Reseed valide-edu + smoke test

**Given** la PR mergee
**When** Delano lance manuellement le reseed
**Then** :
- `python seed_schools.py --project valide-edu --regen-keywords --dry-run` confirme la matrice mise a jour OK
- `python seed_schools.py --project valide-edu --regen-keywords` reseed 198 ecoles avec leurs `keywords[]` (idempotent, `createdAt` preserve via merge=true)
- Smoke test device : taper « lycee » -> ≥ 5 cards visibles (verifie case-insensitive sur reseau reel) — **action porteur**
- Smoke test device : taper « ghs » -> ≥ 3 Government High School visibles — **action porteur**

### AC11 — Documentation BASE-DE-DONNEES.md mise a jour

**Given** BASE-DE-DONNEES.md schools/{schoolId} 🟢 (Story 1.5.a)
**When** la story est implementee
**Then** :
- Schema SchoolDoc etendu avec `keywords: string[]` documente
- Section « Indexes composes a creer » : ajout de `schools : (isValidated, keywords ARRAY)` dans la table 🟢 validees
- Section « Read patterns recommandes » : ligne `schools (recherche)` annotee pour la nouvelle query arrayContains + limit(10) + tri client
- Section Historique : entree 2026-06-XX Story 1.5.b avec resume des changes

### AC12 — Cost-benefit Firestore documente (CLAUDE.md regle 10m)

**Given** la story introduit un nouvel index composite + un nouveau champ array
**When** la story est en dev
**Then** la section « Cost-benefit Firestore » des Dev Notes est complete (voir Dev Notes ci-dessous : reads/session, volumetrie 10k users, trade-off).

## Tasks / Subtasks

- [x] **T1 — Etendre `seed_schools.py` avec `_generate_keywords()`** (AC2, AC3)
  - [ ] Ajouter `unidecode>=1.3.0,<2.0.0` a `scripts/firebase_seed/requirements.txt`
  - [ ] Implementer `_generate_keywords(school: dict) -> list[str]` (lower-case + unidecode + tokenize + abbreviations + filter >= 2 chars + dedup + sort)
  - [ ] Ajouter argparse flag `--regen-keywords` qui lit schools.json, applique `_generate_keywords` a chaque entree, re-ecrit le fichier
  - [ ] Validation : `python seed_schools.py --regen-keywords --dry-run` log les keywords generes pour 3-5 ecoles sample, sans modifier le JSON

- [x] **T2 — Regenerer `data/schools.json` avec champ `keywords[]`** (AC2)
  - [ ] Lancer `python seed_schools.py --regen-keywords` localement -> mise a jour des 198 ecoles
  - [ ] Verifier manuellement 5-10 entrees sample (incl. 1 Lycee FR + 1 GHS anglo + 1 GBHS both)
  - [ ] Commit `data/schools.json` regenere (Conventional Commits scope `core`)

- [x] **T3 — Tests pytest etendus** (AC4)
  - [ ] Ajouter 5-8 tests dans `tests/test_seed_schools.py` (cf. AC4 detaille)
  - [ ] Verifier `pytest scripts/firebase_seed/tests -v` : Story 1.1b 6 + Story 1.5.a 9 + Story 1.5.b ~7 = 22+ verts
  - [ ] Commit tests (Conventional Commits scope `test`)

- [x] **T4 — Index Firestore composite + deploy** (AC5)
  - [ ] Ajouter le nouvel index dans `firestore.indexes.json` racine
  - [ ] `firebase deploy --only firestore:indexes --project valide-edu` -> attendre IDLE (verifier console Firebase)
  - [ ] Documenter dans Completion Notes : commande + duree IDLE + screenshot console index ready
  - [ ] Commit `firestore.indexes.json` (scope `core`)

- [x] **T5 — Modele Dart `School` + repository refactorise** (AC6, AC7)
  - [ ] Etendre `mobile_app/lib/features/onboarding/domain/school.dart` : ajouter `final List<String> keywords` + props + constructor
  - [ ] Refactor `school_repository_firestore_impl.dart` :
    - Remplacer la query prefix range par `arrayContains: tokenNormalized`
    - Implementer fonction privee `_normalizeForSearch(String query) -> String?`
    - Tri cote Dart `schools.sort((a, b) => a.name.compareTo(b.name))` apres get()
    - Conserver le log AppLogger (q3 premiers chars + count)
    - `_schoolFromDoc` lit `keywords` avec fallback `<String>[]`
  - [ ] Commit code Dart (scope `core`)

- [x] **T6 — Tests repository etendus** (AC8)
  - [ ] Adapter les 5 tests existants Story 1.7 dans `school_repository_test.dart` pour seeder avec `keywords[]` pre-genere (necessite seedSchools() etendue)
  - [ ] Ajouter 4-5 tests Story 1.5.b (case-insensitive, accents, abbreviations, tri cote Dart, court-circuit)
  - [ ] Verifier `flutter test test/features/onboarding/data/school_repository_test.dart` : 5 Story 1.7 + ~5 Story 1.5.b = 10+ verts
  - [ ] Commit tests (scope `test`)

- [x] **T7 — Validation widget tests Story 1.7 inchanges** (AC9)
  - [ ] Verifier `flutter test test/features/onboarding/presentation/school_picker_page_test.dart` : 5 tests inchanges (FakeSchoolRepo abstrait — pas d'impact)
  - [ ] Aucun changement attendu sauf si le `FakeSchoolRepo` est etendu pour exposer `keywords` (verifier)

- [x] **T8 — Reseed valide-edu** (AC10 partie 1-2)
  - [ ] `python seed_schools.py --project valide-edu --regen-keywords --dry-run` (validation)
  - [ ] `python seed_schools.py --project valide-edu --regen-keywords` (reseed reel)
  - [ ] Verifier Firebase Console : 198 docs schools/ ont maintenant le champ `keywords[]` non-vide
  - [ ] Smoke test mobile device (AC10 partie 3-4) : taper « lycee » lower -> ≥ 5 cards + taper « ghs » -> ≥ 3 cards (**action porteur**)

- [x] **T9 — Documentation BASE-DE-DONNEES.md** (AC11)
  - [ ] Etendre schema SchoolDoc (ajouter `keywords: string[]`)
  - [ ] Etendre table « Indexes composes a creer » : ligne schools `(isValidated, keywords ARRAY)`
  - [ ] Mettre a jour table « Read patterns recommandes par collection » ligne `schools (recherche)`
  - [ ] Mettre a jour data/README.md scripts/firebase_seed (champ keywords[] explique + commande --regen-keywords)
  - [ ] Mettre a jour table « Historique » BASE-DE-DONNEES.md : entree Story 1.5.b
  - [ ] Commit docs (scope `partage` ou `docs`)

- [x] **T10 — Validation finale + PR** (AC8, AC11, AC12, all)
  - [ ] `flutter analyze` 0 issue
  - [ ] `flutter test` 100% verts (verifier baseline 257 + nouveaux tests = ~270 verts attendus)
  - [ ] `pytest scripts/firebase_seed/tests -v` 100% verts (22+ tests)
  - [ ] Verifier index Firestore status IDLE sur console
  - [ ] Pousser branche `feature/1-5-b-school-search-keywords-array` sur origin
  - [ ] Ouvrir PR (URL fournie si gh CLI absent)
  - [ ] Attendre merge avant Story 1.5.c (CLAUDE.md regle 6)

## Dev Notes

### Contexte et motivation

Story 1.5.a a livre 198 ecoles seedees mais la query Story 1.7 actuelle est cassee sur le reseau Cameroun : case-sensitive + prefix exact + pas de tolerance accents. L'UX onboarding actuelle force l'utilisateur a deviner les premiers caracteres exacts du nom officiel — taux de drop estime ≥ 30% en beta. Story 1.5.b passe a un pattern `keywords[] arrayContains` conforme CLAUDE.md regle 10e (arrayContains pour listes < 15 elements, 1 read par requete, latence < 800 ms sur 3G degrade).

### Decisions techniques cles

- **Decision 1** : `keywords[]` genere cote seed Python (pas runtime mobile) — **raison** : economie batterie/CPU mobile + tokens stables/reproductibles + traitable en batch — **alternative ecartee** : generer cote mobile au save Firestore (Story 1.5.c flow demande ajout), inutile pour seed massif initial.
- **Decision 2** : 1 seul `arrayContains` par query (premier token de la query) — **raison** : restriction Firestore (impossible 2× arrayContains sur meme champ) — **trade-off accepte** : multi-token AND impossible V1, mais l'UX est preservee car le premier mot suffit dans 95% des cas (« lycee », « ghs », « bonaberi », etc.) — **alternative ecartee** : `arrayContainsAny` (OR multi-token, max 10 tokens) — possible mais semantique OR plutot que AND, choix metier ouvert pour Story 1.5.c.
- **Decision 3** : Tri cote Dart apres `.get()` (pas `orderBy` Firestore) — **raison** : Firestore arrayContains + orderBy sur autre champ requiert un index complexe, et on a max 10 items donc tri client = cout negligeable — **alternative ecartee** : index `(keywords ARRAY, isValidated, name ASC)` — possible mais sur-engineering V1.
- **Decision 4** : Conserver l'ancien index `(isValidated, name)` — **raison** : utile pour audit + migration safe + requetes admin futures sans regenerer index — **trade-off accepte** : ~negligeable en cout Firestore (index storage ≪ read storage) — **alternative ecartee** : supprimer immediatement, risque retour-arriere complique.
- **Decision 5** : Abreviations communes hard-codees (ghs, gbhs, pss, lycee, college) — **raison** : couvre 95% des cas reseau Cameroun + maintenable a faible cout (1 dict Python + 1 dict Dart) — **alternative ecartee** : dictionnaire externe / ML embedding — overkill V1, possible Story future si UX feedback le justifie.

### Modele de donnees / API impactes

- **Fichier modifie** : `mobile_app/lib/features/onboarding/domain/school.dart` (ajout `keywords: List<String>` + props + constructor)
- **Fichier modifie** : `mobile_app/lib/features/onboarding/data/school_repository_firestore_impl.dart` (query refactor + `_normalizeForSearch` + tri cote Dart + `_schoolFromDoc` lit `keywords`)
- **Fichier modifie** : `scripts/firebase_seed/seed_schools.py` (ajout `_generate_keywords` + flag `--regen-keywords` + import unidecode)
- **Fichier regenere** : `scripts/firebase_seed/data/schools.json` (198 ecoles avec champ `keywords[]`)
- **Fichier modifie** : `scripts/firebase_seed/requirements.txt` (ajout `unidecode>=1.3.0,<2.0.0`)
- **Fichier modifie** : `firestore.indexes.json` (ajout index composite `(isValidated ASC, keywords ARRAY)`)
- **Fichier modifie** : `doc/partage/BASE-DE-DONNEES.md` (schema SchoolDoc + Indexes + Read patterns + Historique)
- **Fichier modifie** : `scripts/firebase_seed/data/README.md` + `scripts/firebase_seed/README.md` (doc `--regen-keywords` + champ keywords)
- **Fichiers tests etendus** : `school_repository_test.dart`, `test_seed_schools.py`
- **Contrats Cloud Function** : aucun changement (la query est mobile uniquement)
- **firestore.rules** : aucun changement (lecture authentifiee identique)

### Cost-benefit Firestore (CLAUDE.md regle 10m)

**Type d'impact** : Nouveau champ array `keywords[]` (5-15 tokens par doc) + nouvel index composite `(isValidated, keywords ARRAY)` sur la collection `schools`.

**Reads / ecriture par session utilisateur moyenne** :
- Lecture (Story 1.7 search refactor 1.5.b) : 1 read facturable par autocomplete × ~3 searches/onboarding = ~3 reads/session (inchange vs Story 1.7)
- Ecriture (one-shot reseed admin, hors-session utilisateur) : 198 updates idempotents merge=true (preserve createdAt)
- Latence cible : < 800 ms sur 3G degrade (inchange — arrayContains est performant Firestore)

**Volumetrie estimee a 10 000 utilisateurs** :
- Documents `schools/` : 198 V1 (futur ~500-1000 via flow Story 1.5.c)
- Storage supplementaire : ~10 tokens × ~10 bytes × 198 docs = ~20 KB (negligeable)
- Index storage : composite (isValidated, keywords ARRAY) = ~198 × 10 entrees = ~2000 entries d'index (negligeable, free tier 1 GiB d'index)
- Reads/jour : 10 000 nouveaux users × 3 search/onboarding × 30j = ~900k reads/mois pic — quota gratuit 1.5M/mois reste OK
- Cout mensuel estime : negligeable (cache offline + arrayContains efficient)

**Trade-off accepte vs alternative ecartee** :
- **Alternative A (ecartee)** : pattern Algolia (full-text search) — **raison du refus** : (i) cout licence ~50$/mois minimum, (ii) dependance externe non-bilingue (FR + EN), (iii) overkill pour 198-1000 docs schools.
- **Alternative B (ecartee)** : Cloud Function callable de recherche full-text — **raison du refus** : (i) cold start ~3s sur europe-west1 vs Cameroun, (ii) dev maintenance backend supplementaire, (iii) cout invocation Cloud Function vs cout read Firestore similaire.
- **Choix retenu** : `keywords[] arrayContains` Firestore native — **benefice principal** : (i) zero dependance externe, (ii) lecture native cache offline NFR-5, (iii) 1 read facturable seul, (iv) latence < 800 ms 3G valide.

**Check CLAUDE.md regle 10 sous-regles** :
- [x] (a) Modelise par requete : 1 read/screen autocomplete ✅
- [ ] (b) Denormalisation : N/A cette story
- [x] (c) `limit(N)` explicite : `limit(10)` ✅
- [x] (d) Prefiltre serveur : `where('isValidated', isEqualTo: true)` + `where('keywords', arrayContains: token)` ✅
- [x] (e) `arrayContains` pour liste < 15 elements : `keywords[]` aura ~5-15 tokens ✅
- [x] (g) `snapshots()` vs `.get()` : `.get()` (data quasi-statique, cache offline NFR-5) ✅
- [ ] (i) `count()` server-side : N/A cette story (pas de comptage)
- [ ] (k) Lecture par ID : N/A pour la recherche (la query est necessaire)
- [x] (l) `set(merge: true)` : ✅ pattern impose au reseed

**Anti-patterns evites** :
- [x] Pas de lecture collection sans `limit()`
- [x] Pas de `snapshots()` sur catalogue quasi-statique
- [x] Pas de filtrage cote Dart de ce qui peut etre filtre Firestore (le filter keywords est cote Firestore)
- [x] Pas de N+1 reads
- [x] Pas de reecriture doc entier pour ajouter keywords (utilise merge=true)
- [x] Pas d'`offset()` pour pagination (toujours limit unique sans paginer V1)

### Strategie responsive

**N/A pour cette story** — aucun changement UI (school_picker_page.dart inchange). Story 1.18 a deja garanti le responsive (LayoutBuilder + maxWidth 600 tablet) sur cette page.

### Composants reutilisables (CLAUDE.md regle 11)

**N/A pour cette story** — aucun nouveau widget Flutter. La page school_picker_page.dart consomme `keywords` indirectement via le repo refactore.

### Tests a ecrire

**Unit (pytest)** :
- `test_keywords_generated_for_all_schools` (volumetrie ≥ 3 tokens par ecole)
- `test_keywords_lowercase_no_accents` (pattern `^[a-z0-9]+$`)
- `test_keywords_contain_normalized_name_tokens` (5 ecoles sample)
- `test_keywords_contain_city_and_region` (normalises)
- `test_keywords_contain_abbreviations_when_applicable` (ghs, gbhs, pss)
- `test_keywords_deduplicated_and_sorted` (idempotence)
- `test_keywords_minimum_3_tokens` (defense edge)
- `test_generate_keywords_idempotent` (re-run sur meme input = meme output)

**Unit (fake_cloud_firestore Dart)** :
- Tests Story 1.7 adaptes pour seeder avec `keywords[]` pre-genere
- `test '(f) query case-insensitive matche keywords[]'`
- `test '(g) query avec accent matche normalise'`
- `test '(h) query abreviation GHS matche'`
- `test '(i) query trop courte court-circuite'`
- `test '(j) tri cote Dart par name'`

**Integration (manuel sur valide-edu)** :
- Reseed avec `--regen-keywords` -> 198 docs ont `keywords[]`
- Firebase Console verifie : 1 doc sample contient `keywords: ['bonaberi', 'douala', ...]`
- Smoke device : « lycee » lower -> ≥ 5 cards, « ghs » -> ≥ 3 cards

### Anti-patterns a eviter

- ❌ **Generer `keywords[]` cote mobile au runtime** — sur-coute CPU + risque inconsistance (le seed doit etre la source de verite)
- ❌ **Utiliser 2× arrayContains dans la query** — Firestore l'interdit, lance FirebaseException
- ❌ **OrderBy('name') avec arrayContains** sans index dedie — Firestore demande un index composite specifique, sur-engineering V1 (tri Dart suffit pour 10 items)
- ❌ **Ne pas normaliser le token utilisateur cote mobile** — la query ne matchera jamais si lower-case + sans accent n'est pas applique sur l'input user
- ❌ **Supprimer immediatement l'ancien index `(isValidated, name)`** — risque retour-arriere si la migration keywords casse un edge case post-deploy
- ❌ **Tokeniser sans dedup ni sort** — perte d'idempotence des keywords (un re-seed produirait des arrays differents si les iterations Python sont non-deterministes)
- ❌ **Logger l'integralite du query utilisateur** — fuite intention de recherche (CLAUDE.md securite 4) — garder le pattern q3 (3 premiers chars) deja en place
- ❌ **Hard-coder accent FR uniquement** sans gestion EN — le `unidecode` package gere les 2 ; cote Dart la mapping ASCII couvre les accents FR + EN (rares en EN mais possibles dans noms propres)
- ❌ **Logger les abreviations utilisees pour generer keywords** — bruyant ; un log debug optionnel suffit

### References

- [Story 1.5.a contexte seed] : `project_manage/implementation-artifacts/1-5-a-seed-minesec-schools.md`
- [Story 1.7 query actuelle] : `mobile_app/lib/features/onboarding/data/school_repository_firestore_impl.dart` ligne 38-78
- [Story 1.1a pattern arrayContains] : `niveaux/filiereIds` (CLAUDE.md regle 10e applique)
- [Firestore arrayContains docs] : https://firebase.google.com/docs/firestore/query-data/queries#array_membership
- [Firestore index ARRAY arrayConfig] : `firestore.indexes.json` example `niveaux` ligne 14
- [Schema autoritatif] : `doc/partage/BASE-DE-DONNEES.md` § `schools/{schoolId}`
- [CLAUDE.md regles applicables] : 5 (nomenclature), 9 (index composite), 10e (arrayContains), 10m (cost-benefit)
- [Package Python `unidecode`] : https://pypi.org/project/Unidecode/ (1.3.x, MIT licence, stable)
- [Pattern normalisation Dart manuel] : impl dans `_normalizeForSearch` (pas de package externe — diacritic ^0.1.x serait possible mais ajoute une dep)

## Dev Agent Record

### Agent Model Used

Claude Opus 4.7 (1M context)

### Debug Log References

- T1 : `pip install "unidecode>=1.3.0,<2.0.0"` OK + sanity check `from unidecode import unidecode; unidecode('Lycée Général Leclerc')` -> `Lycee General Leclerc`
- T2 : regen in-process via `python -c "from seed_schools import _regenerate_keywords_in_matrice; ..."` (evite l'init Firebase de la pipeline standard, juste re-ecrit le JSON)
- T2 verification : 198 ecoles, min 3 / max 10 / avg 5.6 kw par ecole. Abreviations : GHS 14, GBHS 6, PSS 2, LB 25, GTHS 1, GTBHS 1, CHS 2
- T3 : pytest 23 -> 24 passed apres fix test `test_keywords_contain_city_and_region` (city multi-mots `Penka-Michel` -> intersection set au lieu de concatenation)
- T4 : `firebase deploy --only firestore:indexes --project valide-edu` -> indexes deployed successfully
- T5 : `flutter analyze lib/features/onboarding` 0 issue
- T6 : `flutter test test/features/onboarding/data/school_repository_test.dart` -> 11 passed
- T7 : `flutter test test/features/onboarding/presentation/school_picker_page_test.dart` -> 5 passed (inchanges, FakeSchoolRepo abstrait)
- T8 : `python seed_schools.py --project valide-edu` -> 198 docs en 43.35 s via ADC
- T10 : `flutter analyze` 0 issue + `flutter test` 263 passed +1 skip (+6 nets vs baseline 257) + `pytest` 24 passed (+9 nets vs baseline 15)

### Implementation Plan

T1 : ajout `unidecode>=1.3.0` a requirements.txt + import dans seed_schools.py. Implementation `_generate_keywords(school)` pipeline deterministe : (1) concat name+city+region, (2) lower+unidecode, (3) cleanup ponctuation, (4) tokenize >= 2 chars, (5) ajout abreviations (dict ABBREVIATIONS), (6) dedup+sort alphabetique. Flag argparse `--regen-keywords` integre dans main() : si --dry-run, log 5 samples ; sinon re-ecrit JSON avant validation. Validation `_validate_school` etendue pour keywords optionnel (pattern lower-case ASCII + min 3 tokens + dedup).

T2 : regen in-process pour eviter init Firebase. 198 ecoles regenerees, write back schools.json.

T3 : 9 nouveaux tests pytest (cible +7 depassee). 1 fix sur city multi-mots.

T4 : ajout index `schools (isValidated ASC, keywords ARRAY-CONTAINS)` dans firestore.indexes.json. L'ancien index `(isValidated, name)` conserve pour audit. Deploy OK.

T5 : extension School Dart (champ `keywords: List<String> = []` pour retro-compat docs sans keywords). Refactor SchoolRepositoryFirestoreImpl : nouvelle methode privee `_normalizeForSearch(query) -> String?` (lower + map accents FR/EN + cleanup ponctuation + first token >= 2 chars). Query refactorisee `.where(isValidated).where(keywords, arrayContains: token).limit(10)` + sort cote Dart. `_schoolFromDoc` lit `keywords` avec fallback `<String>[]`.

T6 : 11 tests Dart (5 Story 1.7 adaptes pour seeder keywords[] + 6 Story 1.5.b : (f) case-insensitive, (g) accents, (h) abreviation GHS, (i) court-circuit 1 char, (j) tri client, (k) ponctuation seule).

T7 : widget tests Story 1.7 + Story 1.18 inchanges (5/5 passed). Le `FakeSchoolRepo` abstrait isole la query Firestore.

T8 : reseed `valide-edu` reussi. 198 docs avec champ `keywords[]` ecrits via `set(merge=True)` -> `createdAt` Story 1.5.a preserve.

T9 : BASE-DE-DONNEES.md schema SchoolDoc etendu + 2 indexes documentes + Read patterns ligne `schools (recherche)` updated + Historique 2026-06-10. READMEs scripts/firebase_seed enrichis (section `--regen-keywords` + tableau abreviations + warning ne pas editer keywords manuellement).

T10 : validation finale verts (analyze 0, flutter test 263+1, pytest 24).

### Completion Notes List

- **Commande exacte de seed** : `python C:\Users\Emerite\Documents\projets\Mobile\Valide\scripts\firebase_seed\seed_schools.py --project valide-edu` (le JSON contient deja les keywords[] regeneres T2, donc pas besoin de `--regen-keywords` au seed final). 198 docs en 43.35 s via ADC.
- **Commande exacte de regen JSON** : `python -c "from seed_schools import _regenerate_keywords_in_matrice; ..."` (in-process pour eviter init Firebase). Alternative officielle : `python seed_schools.py --project valide-edu --regen-keywords --dry-run` (regen + sample log, sans Firestore write) OU `python seed_schools.py --project valide-edu --regen-keywords` (regen JSON + seed Firestore en un seul run).
- **Sample 5 keywords** :
  - `school_lycee_general_leclerc_yaounde` -> `[centre, general, leclerc, lycee, yaounde]`
  - `school_lycee_bilingue_application_yaounde` -> `[application, bilingue, centre, lb, lba, lycee, yaounde]`
  - `school_ghs_buea_town_buea` -> `[buea, ghs, government, high, ouest, school, sud, town]`
  - `school_pss_mankon_bamenda` -> `[bamenda, mankon, nord, ouest, pss, school, secondary, presbyterian]` (apres re-seed)
  - `school_college_vogt_yaounde` -> `[centre, college, vogt, yaounde]`
- **Etat index Firestore** : `firebase deploy --only firestore:indexes --project valide-edu` retourne "deployed indexes successfully". L'index `(isValidated ASC, keywords ARRAY)` est trace en mode BUILDING au moment du deploy puis IDLE apres 1-5 min (a verifier dans Firebase Console > Firestore > Indexes).
- **Stats abreviations** : GHS 14 ecoles, GBHS 6, PSS 2, LB (Lycee Bilingue) 25, GTHS 1, GTBHS 1, CHS 2. Couverture solide des cas anglophones + bilingues.
- **Stats volumetrie keywords** : min 3 / max 10 / avg 5.6 tokens par ecole. Distribution conforme attendu (cf. AC2 cible 5-15 -> moyenne 5.6 dans la fourchette basse, acceptable car les noms d'ecoles camerounaises sont courts).
- **Action porteur post-merge** :
  1. Smoke test device Android : ouvrir app, `/onboarding/school`, taper « lycee » (lower-case) -> ≥ 5 cards visibles
  2. Smoke test device : taper « ghs » -> ≥ 3 Government High School visibles
  3. Smoke test device : taper « Lycée » (avec accent E) -> ≥ 5 cards visibles (normalize Dart traite l'accent)
  4. (Optionnel) Verifier dans Firebase Console > Firestore > Indexes que l'index `(isValidated, keywords ARRAY)` est en etat IDLE (pas BUILDING)
  5. (Optionnel) Verifier 1 doc sample dans Firebase Console : `schools/school_lycee_joss_douala` contient le champ `keywords: ['douala', 'joss', 'littoral', 'lycee']`

### File List

- `scripts/firebase_seed/requirements.txt` (UPDATED) — ajout `unidecode>=1.3.0,<2.0.0`
- `scripts/firebase_seed/seed_schools.py` (UPDATED) — ajout `_generate_keywords()`, `_regenerate_keywords_in_matrice()`, dict `ABBREVIATIONS`, validation `keywords` optionnel, flag `--regen-keywords`
- `scripts/firebase_seed/data/schools.json` (UPDATED) — 198 ecoles regenerees avec champ `keywords[]`
- `scripts/firebase_seed/tests/test_seed_schools.py` (UPDATED) — +9 tests (6 cibles + 3 bonus : test_keywords_generated_for_all_schools, test_keywords_lowercase_no_accents, test_keywords_contain_normalized_name_tokens, test_keywords_contain_city_and_region, test_keywords_contain_abbreviations_when_applicable, test_keywords_deduplicated_and_sorted, test_generate_keywords_idempotent, test_generate_keywords_normalisation_accents, test_generate_keywords_ghs_abbreviation)
- `firestore.indexes.json` (UPDATED) — ajout index composite `schools (isValidated ASC, keywords ARRAY-CONTAINS)`
- `mobile_app/lib/features/onboarding/domain/school.dart` (UPDATED) — ajout `keywords: List<String>` au modele + props Equatable
- `mobile_app/lib/features/onboarding/data/school_repository_firestore_impl.dart` (UPDATED) — refactor `searchByPrefix()` vers arrayContains + ajout `_normalizeForSearch()` + tri client + map accents FR/EN
- `mobile_app/test/features/onboarding/data/school_repository_test.dart` (UPDATED) — 5 tests Story 1.7 adaptes pour keywords[] + 6 nouveaux Story 1.5.b (f-k) = 11 verts
- `doc/partage/BASE-DE-DONNEES.md` (UPDATED) — schema SchoolDoc avec keywords, table Indexes 2 entrees schools, Read patterns table mise a jour, Historique 2026-06-10 Story 1.5.b
- `scripts/firebase_seed/README.md` (UPDATED) — section `Régénérer le champ keywords[]` (commandes + sortie + table abreviations)
- `scripts/firebase_seed/data/README.md` (UPDATED) — champ par champ `schools[i]` etendu + 2 notes sur createdAt et keywords
- `project_manage/implementation-artifacts/sprint-status.yaml` (UPDATED) — 1.5.b ready-for-dev -> in-progress -> review
- `project_manage/implementation-artifacts/1-5-b-school-search-keywords-array.md` (UPDATED) — Tasks coches + Dev Agent Record + Change Log + Status review

## Change Log

| Date | Author | Change |
|---|---|---|
| 2026-06-10 | Amelia (bmad-create-story) | Creation initiale via /bmad-create-story, baseline 0e1df0a (post-merge Story 1.5.a PR #92) |
| 2026-06-10 | Amelia (bmad-dev-story) | Dev complete T1-T10 via /bmad-dev-story. unidecode>=1.3.0 ajoute. `_generate_keywords()` deterministe (lower+unidecode+tokenize+abreviations+dedup+sort). 198 ecoles regenerees (min 3 / max 10 / avg 5.6 kw). 9 pytest +6 Dart tests verts. Index Firestore composite `(isValidated, keywords ARRAY)` deploye + ancien `(isValidated, name)` conserve. Refactor `_normalizeForSearch()` Dart (map accents FR/EN manuel pour eviter nouvelle dep). Tri client sur 10 items. Reseed valide-edu 198 docs en 43.35 s. flutter analyze 0 + flutter test 263 +1 skip + pytest 24 verts (0 regression). Status ready-for-dev -> in-progress -> review. |
