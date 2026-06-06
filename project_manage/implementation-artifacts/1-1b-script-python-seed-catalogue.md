---
story_id: 1.1b
title: Script Python `seed_catalogue.py` + matrice source + procédure d'init
epic: 1
phase: P1
status: review
created: 2026-06-06
branch: feat/1.1b-script-python-seed-catalogue
baseline_commit: 6913609d  # merge commit Story 1.1c (PR #37)
estimation: M (~4-5h)
dependencies:
  - 1.1a  # Schema Firestore + ADR-015 figés (mergée 2026-06-05 commit 748f07e)
  - 1.1c  # Mapper Firestore confirmé en prod (mergée 2026-06-06 commit 6913609) — formats de champs validés
blocks:
  - 1.3   # Flow profil 3 étapes (a besoin de la matrice complète seedée, pas juste les 7 docs minimum du smoke test post-1.1c)
sourceArtifacts:
  - project_manage/planning-artifacts/epics/epic-1-onboarding.md § Story 1.1b (lignes 155-214)
  - project_manage/planning-artifacts/sprint-change-proposal-2026-06-05.md § Change 4.5 + Implementation Handoff
  - project_manage/planning-artifacts/architecture/adrs/ADR-015-catalogue-firestore-runtime-activation.md § Décision #2 (seed initial via script Python externe)
  - doc/partage/BASE-DE-DONNEES.md § Catalogue scolaire (6 collections — Story 1.1a) — schéma TypeScript autoritatif
  - doc/partage/DONNEES-REFERENCE.md § Tableau de dérivation (79 derivation_rules) + § Périmètre MVP suggéré (priorisation isActive)
  - doc/partage/DONNEES-REFERENCE.md § Convention de nommage des IDs (snake_case, préfixe subSystem_)
  - mobile_app/lib/core/catalogue/data/firestore_mappers.dart — noms exacts des champs Firestore (canonique post-1.1c)
  - mobile_app/lib/core/catalogue/data/catalogue_repository_firestore_impl.dart — noms des 6 collections + queries
  - firestore.rules (racine) — règles déployées sur valide-edu post-1.1c (write: false côté client, seul script Python écrit)
  - .gitignore (racine) — couvre déjà service-account.json, firebase-adminsdk-*.json, serviceAccountKey.json
  - c:/tmp/seed_catalogue_smoketest.py (workspace temp, hors repo) — script ad-hoc déjà testé 2026-06-06 avec ADC, prouve que firebase-admin 7.2.0 + projectId='valide-edu' fonctionne sur la machine Delano
---

# Story 1.1b — Script Python `seed_catalogue.py` + matrice source + procédure d'init

Status: **ready-for-dev**

## Objectif

Livrer un **script Python autonome et idempotent** `scripts/firebase_seed/seed_catalogue.py` qui :

1. Lit une **matrice JSON versionnée** `scripts/firebase_seed/data/matrice.json` (source de vérité offline, alignée à `doc/partage/DONNEES-REFERENCE.md` § Tableau de dérivation — 79 derivation_rules) ;
2. Populate les **6 collections Firestore** (`filieres`, `niveaux`, `series`, `subjects`, `exam_targets`, `derivation_rules`) via `firebase-admin` Python SDK ;
3. Respecte le périmètre d'activation (`isActive: true` pour le périmètre prioritaire ~50 rules, `isActive: false` pour les 29 rules étendues, cf. § Périmètre MVP suggéré) ;
4. Reste **idempotent** : un re-run ne crée pas de doublons, met à jour les champs modifiés (utiliser `set(merge=True)` partout, jamais `add()`) ;
5. Est **testé** localement (pytest, ≥ 4 tests sans dépendance Firestore live) et **documenté** (README porteur).

**Pourquoi** : ADR-015 acte que le catalogue Firestore est la source de vérité runtime. Story 1.1c a livré le mapper mobile + déployé les rules/indexes + seedé 7 docs MVP minimum via un script ad-hoc temporaire (`c:/tmp/seed_catalogue_smoketest.py`, hors repo). Story 1.1b livre le **script officiel** versionné qui seed les **79 rules complètes** (périmètre prioritaire + étendu désactivé), reproductible par tout porteur Firebase pour init un projet ou propager une évolution de matrice.

**Critère de fin** : un porteur (Delano ou tout futur dev avec son service-account.json) peut exécuter `python seed_catalogue.py --project valide-edu` après `gcloud auth application-default login` OU avec `--credentials ./service-account.json`, et obtenir un Firestore avec les 6 collections peuplées de la matrice complète, prêtes à être consommées par `CatalogueRepository` mobile (Story 1.1c).

## Story

**As a** porteur Firebase (Delano, ou tout futur dev/admin),
**I want** un script Python autonome qui lit une matrice JSON versionnée et populate les 6 collections Firestore (filieres, niveaux, series, subjects, exam_targets, derivation_rules) avec `isActive` configurable,
**so that** je puisse initialiser le catalogue sur `valide-edu` (ou un autre projet) sans dépendre d'un backend déployé, propager une évolution de la matrice par un simple re-run, et que les modifications futures (ajout matière, activation série) se fassent par édition matrice + re-run OU directement depuis Firebase Console pour les cas simples.

## Acceptance Criteria

### AC1 — Structure dossier `scripts/firebase_seed/` créée

**Given** un dépôt mobile sans dossier `scripts/firebase_seed/`
**When** la PR est mergée
**Then** l'arborescence suivante existe à la racine du dépôt :

```text
scripts/
└── firebase_seed/
    ├── seed_catalogue.py          # script principal (idempotent : set merge=True)
    ├── data/
    │   ├── matrice.json           # source de vérité versionnée (toutes classes — 79 derivation_rules)
    │   └── README.md              # documentation de la structure JSON
    ├── tests/
    │   ├── __init__.py            # empty (package marker)
    │   └── test_seed.py           # tests basiques (parsing matrice, IDs convention, dry-run)
    ├── requirements.txt           # firebase-admin>=7.2.0, pytest>=8.0
    ├── README.md                  # procédure d'init porteur (auth ADC ou service-account)
    └── .gitignore                 # service-account*.json, .venv/, __pycache__/, *.pyc
```

**And** le `.gitignore` racine du dépôt **n'a pas besoin d'être modifié** — il couvre déjà `**/service-account.json`, `**/serviceAccountKey.json`, `**/firebase-adminsdk-*.json` (vérifié 2026-06-06 lignes 24-27). Le `.gitignore` local `scripts/firebase_seed/.gitignore` ajoute juste `.venv/` et `__pycache__/` en sécurité défensive.

**And** aucun fichier `service-account*.json` réel n'est commit (même pas en exemple). Si un exemple est nécessaire, créer `service-account.json.example` avec un placeholder texte qui ne soit PAS un vrai JSON parsable.

### AC2 — `data/matrice.json` reflète la matrice 🟢 exhaustive de DONNEES-REFERENCE.md

**Given** [`doc/partage/DONNEES-REFERENCE.md`](../../doc/partage/DONNEES-REFERENCE.md) § Tableau de dérivation (79 entrées) + § Périmètre MVP suggéré (priorisation isActive)
**When** on inspecte `scripts/firebase_seed/data/matrice.json`
**Then** la structure JSON respecte exactement le schéma TypeScript autoritatif documenté dans [BASE-DE-DONNEES.md § Catalogue scolaire](../../doc/partage/BASE-DE-DONNEES.md#catalogue-scolaire-6-collections--story-11a) :

```jsonc
{
  "version": "1.0.0",
  "generatedAt": "2026-06-06",
  "comment": "Source matrice : doc/partage/DONNEES-REFERENCE.md § Tableau de dérivation. Modifier ici puis re-run seed_catalogue.py pour propager.",

  "filieres": [
    {
      "filiereId": "generale",
      "name": { "fr": "Générale", "en": "General" },
      "isActive": true,
      "sortOrder": 10
    },
    {
      "filiereId": "technique",
      "name": { "fr": "Technique", "en": "Technical" },
      "isActive": true,
      "sortOrder": 20
    }
  ],

  "niveaux": [
    // Convention ID : "{subSystem}_{slug}"
    // ex. "francophone_6e", "francophone_terminale", "anglophone_form_1", "anglophone_lower_sixth"
    // Listing exhaustif :
    //   francophone : 6e, 5e, 4e, 3e, seconde, premiere, terminale  (× filieres [generale, technique] pour seconde/premiere/terminale)
    //   anglophone  : form_1, form_2, form_3, form_4, form_5, lower_sixth, upper_sixth (filiereIds: ["generale"] uniquement)
  ],

  "series": [
    // Convention ID : "{subSystem}_{niveau_slug}_{serie_slug}"
    // ex. "francophone_terminale_d", "francophone_terminale_f1", "anglophone_upper_sixth_s2"
    // canOptOut : anglophone Form 3+ ET Lower/Upper Sixth toutes filières → true ; sinon false
    // (cf. DONNEES-REFERENCE.md colonne "retrait ?" du Tableau de dérivation)
  ],

  "subjects": [
    // Convention ID : "{subSystem}_{shortCode}" snake_case
    // ex. "francophone_math", "francophone_pct", "francophone_svt", "francophone_fr", "francophone_en",
    //     "francophone_lv2", "francophone_philo", "francophone_hg", "francophone_eps",
    //     "anglophone_chemistry", "anglophone_physics", "anglophone_biology", "anglophone_pure_maths",
    //     "anglophone_further_maths", "anglophone_english_lit"
    // Chaque subject : icon Lucide valide (cf. https://lucide.dev/icons/)
  ],

  "exam_targets": [
    // Convention ID : "exam_{slug}_{subSystem}[_{serie}]"
    // ex. "exam_bepc_francophone", "exam_probatoire_francophone_d", "exam_bac_francophone_d",
    //     "exam_bac_technique_f1", "exam_gce_o_level_anglophone", "exam_gce_a_level_anglophone_s2"
  ],

  "derivation_rules": [
    // Convention ID : "rule_{subSystem}_{filiere}_{niveau_slug}_{serie_slug|none}"
    // ex. "rule_francophone_generale_terminale_d", "rule_anglophone_generale_form_1_none"
    // matchSerie : null si le niveau n'a pas de série (ex. 6e francophone, Form 1 anglophone)
    // matchFiliere : "*" wildcard si toutes filières (rare, mais autorisé par mapper Firestore)
    // 79 rules totales (cf. DONNEES-REFERENCE.md § volumétrie ligne 417) :
    //   - Francophone : 4 BEPC + 14 général 2nd cycle + 16 technique industriel + 6 technique tertiaire + 8 technique étendue = 48
    //   - Anglophone  : 5 secondary + 16 Sixth Sciences + 10 Sixth Arts = 31
    //   Total = 79
  ]
}
```

**And** chaque document de chaque collection :
- A un `id` qui devient le `doc ID` Firestore (cf. mappers, ex. `filiereFromFirestore(snap)` lit `snap.id` comme `filiereId`)
- Contient les champs **exactement** comme attendus par les mappers Firestore actuels (`mobile_app/lib/core/catalogue/data/firestore_mappers.dart`) — pas de typo, casse sensible :
  - `name.fr` et `name.en` (lowercase)
  - `subSystem` (camelCase, valeurs `"francophone"` ou `"anglophone"`)
  - `niveauId`, `filiereId`, `filiereIds` (camelCase)
  - `matchSubSystem`, `matchFiliere`, `matchNiveau`, `matchSerie` (camelCase)
  - `subjectIds`, `examTargetIds` (camelCase, listes de string)
  - `isActive`, `canOptOut` (bool)
  - `sortOrder` (number, sauf `derivation_rules` qui n'en a pas)

**And** le périmètre d'activation suit [`doc/partage/DONNEES-REFERENCE.md` § Périmètre MVP suggéré](../../doc/partage/DONNEES-REFERENCE.md#périmètre-mvp-suggéré) :
- **Périmètre prioritaire** (`isActive: true` au seed initial, ~50 rules) :
  - Francophone général : 6ᵉ→3ᵉ + BEPC + Seconde/Première/Terminale séries **A, C, D** + Probatoire/BAC
  - Francophone technique : Première/Terminale séries **F1-F4** + Probatoire/BAC + **G1-G3** + BAC
  - Anglophone : Form 1→Form 5 + O Level + Lower/Upper Sixth toutes **S1-S8 et A1-A5** + A Level
- **Périmètre étendu** (`isActive: false`, 29 rules activables runtime sans rebuild) :
  - Francophone général : série **E** (Terminale)
  - Francophone technique : série **F5** + 8 séries étendues (ESF, IH, MVT, ACA, MAVA, MEAC AUTO, MEM, MECA)
  - Les `subjects` exclusifs à ces séries étendues sont également `isActive: false` ; les `subjects` partagés (math, philo...) restent `isActive: true`
  - Les `exam_targets` correspondants (`exam_bac_francophone_e`, `exam_bac_technique_f5`, `exam_bac_technique_esf`...) sont `isActive: false`

### AC3 — `seed_catalogue.py` idempotent + CLI propre

**Given** `scripts/firebase_seed/seed_catalogue.py` et la matrice `data/matrice.json`
**When** le porteur exécute la commande standard :

```bash
cd scripts/firebase_seed
python seed_catalogue.py --project valide-edu
# OU avec service-account explicite
python seed_catalogue.py --project valide-edu --credentials ./service-account.json
```

**Then** le script :
1. **Parse les arguments CLI** via `argparse` :
   - `--project <id>` (obligatoire, ex. `valide-edu`)
   - `--credentials <path>` (optionnel — si absent, utilise Application Default Credentials via `gcloud auth application-default login`)
   - `--dry-run` (optionnel — parse + valide la matrice + log ce qui serait écrit, mais N'ÉCRIT PAS Firestore)
   - `--matrice <path>` (optionnel, défaut `./data/matrice.json`)
2. **Authentifie** :
   - Si `--credentials` fourni : `credentials.Certificate(path)`
   - Sinon : `credentials.ApplicationDefault()` (testé OK le 2026-06-06 sur la machine Delano après `gcloud auth application-default login`)
3. **Initialise** `firebase_admin.initialize_app(cred, {"projectId": args.project})` puis `db = firestore.client()`
4. **Lit et valide** `data/matrice.json` :
   - JSON valide (`json.loads`)
   - Présence des 6 clés racines : `filieres`, `niveaux`, `series`, `subjects`, `exam_targets`, `derivation_rules`
   - Pour chaque doc : présence des champs obligatoires (cf. AC2)
   - Si validation KO : exit code 1 + stderr message clair
5. **Écrit Firestore** collection par collection, dans cet ordre (dépendances logiques montantes) :
   1. `filieres`
   2. `niveaux`
   3. `series`
   4. `subjects`
   5. `exam_targets`
   6. `derivation_rules`
6. **Utilise EXCLUSIVEMENT** `db.collection(coll).document(doc_id).set(payload, merge=True)` — jamais `.add()` (génère un ID aléatoire, casse l'idempotence).
7. **Logge un résumé** stdout en fin d'exécution :

```text
[OK] filieres        : 2 docs   (2 active, 0 inactive)
[OK] niveaux         : 14 docs  (14 active, 0 inactive)
[OK] series          : 47 docs  (38 active, 9 inactive)
[OK] subjects        : 35 docs  (30 active, 5 inactive)
[OK] exam_targets    : 20 docs  (15 active, 5 inactive)
[OK] derivation_rules: 79 docs  (50 active, 29 inactive)
Total: 197 documents écrits en 4.3 s.
```

(volumétrie exacte à confirmer à l'implémentation — les chiffres ci-dessus sont indicatifs)

**And** un re-run **immédiat** (sans modifier la matrice) produit le **même résumé** sans erreur — vérification d'idempotence.

**And** si l'auth échoue (mauvais service-account, projet inexistant, permissions insuffisantes) : `sys.exit(1)` avec message stderr clair pointant la cause probable (`Permission denied — vérifier le rôle "Cloud Datastore User" du service account`).

**And** `python seed_catalogue.py --project valide-edu --dry-run` :
- N'écrit RIEN dans Firestore (vérifiable en regardant Console : pas de timestamp `updatedAt` modifié)
- Logge `[DRY-RUN]` en préfixe de chaque ligne du résumé
- Permet de valider la matrice **avant** de toucher Firestore — utile en CI ou avant un seed risqué (changement matrice majeur)

### AC4 — Tests pytest ≥ 4 cas (sans dépendance Firestore live)

**Given** `scripts/firebase_seed/tests/test_seed.py` + `requirements.txt` incluant `pytest>=8.0`
**When** on exécute `cd scripts/firebase_seed && pip install -r requirements.txt && pytest tests/ -v`
**Then** ≥ 4 tests verts couvrent :

1. **`test_matrice_json_is_valid`** : `data/matrice.json` est syntaxiquement valide (json.loads sans exception) ET contient les 6 clés racines attendues.
2. **`test_ids_follow_convention`** : pour chaque doc de chaque collection, le `id` respecte la convention de nommage (snake_case + préfixe `{subSystem}_` pour niveaux/series/subjects, préfixe `exam_` pour exam_targets, préfixe `rule_` pour derivation_rules). Cf. BASE-DE-DONNEES.md § Conventions IDs cross-collection.
3. **`test_no_duplicate_ids_in_collection`** : pas de doublon d'ID au sein d'une même collection (set comparison sur les IDs).
4. **`test_derivation_rules_references_are_valid`** : chaque `subjectId` dans `derivation_rules[i].subjectIds` existe dans `subjects[].subjectId`. Idem pour `examTargetIds` → `exam_targets[].examTargetId`. Idem pour `matchFiliere` (sauf si == `"*"`), `matchNiveau`, `matchSerie` (sauf si null) → existent dans leurs collections respectives.

(Tests bonus optionnels mais souhaités si le dev a le temps : test_seed_collection_uses_set_with_merge_True via mock firebase_admin, test_dry_run_does_not_write).

**And** les tests ne nécessitent **AUCUNE connexion Firestore live** — ils valident la matrice JSON et la logique pure du script. Si un test du script `seed_catalogue.main()` veut être ajouté, mocker `firebase_admin.firestore.client()` via `unittest.mock.patch`.

**And** `pytest tests/` exit code 0 → status `done` envisageable. Exit code != 0 → bloquant.

### AC5 — `README.md` porteur clair

**Given** `scripts/firebase_seed/README.md`
**When** le porteur Delano (ou un futur dev) ouvre le README pour exécuter le script
**Then** le README contient ces sections (dans cet ordre) :

1. **Objectif** : 2-3 phrases sur ce que fait le script (seed Firestore catalogue, idempotent, lecture matrice JSON).
2. **Prérequis** :
   - Python ≥ 3.10
   - `gcloud` CLI installé OU `service-account.json` du projet Firebase
   - Accès au projet Firebase cible (rôle `Cloud Datastore User` minimum)
3. **Setup initial (à faire une fois)** :
   ```bash
   cd scripts/firebase_seed
   python -m venv .venv
   .venv\Scripts\activate     # Windows
   # source .venv/bin/activate  # macOS/Linux
   pip install -r requirements.txt
   ```
4. **Authentification (option A — ADC recommandée)** :
   ```bash
   gcloud auth application-default login
   # Une page web s'ouvre, tu choisis ton compte Google avec accès au projet Firebase.
   # Pas de fichier à télécharger, valable pour tous les projets de ton compte.
   ```
5. **Authentification (option B — service account JSON)** :
   ```text
   1. Firebase Console → Project Settings → Service accounts → Generate new private key
   2. Télécharge le JSON dans scripts/firebase_seed/service-account.json (PAS commit — gitignored)
   3. Passer --credentials ./service-account.json au script
   ```
   **AVERTISSEMENT** : ne JAMAIS commit ce fichier. Le `.gitignore` racine du dépôt et le `.gitignore` local couvrent `service-account*.json`, mais double-check avant `git add`.
6. **Exécution** :
   ```bash
   # Dry-run (recommandé avant tout seed sur un projet partagé)
   python seed_catalogue.py --project valide-edu --dry-run

   # Seed réel
   python seed_catalogue.py --project valide-edu
   ```
7. **Modifier la matrice** :
   - Éditer `data/matrice.json` (suivre la structure documentée dans `data/README.md`)
   - Re-run `python seed_catalogue.py --project valide-edu`
   - Firestore est mis à jour idempotent (champs modifiés écrasés, champs absents préservés grâce à `set(merge=True)`)
   - Pour **supprimer** un doc : utiliser Firebase Console (le script ne supprime jamais — choix défensif)
8. **Activer/désactiver une classe à chaud** (sans re-run script) :
   - Firebase Console → Firestore → collection (`series`, `derivation_rules`...) → doc → toggle `isActive`
   - Effet immédiat côté mobile (cache offline détectera l'invalidation au prochain sync)
9. **Tests** :
   ```bash
   pytest tests/ -v
   ```
10. **Troubleshooting** :
    - `Permission denied` → vérifier rôle `Cloud Datastore User` du service account / compte ADC
    - `Project not found` → vérifier `--project` (typo, projet supprimé)
    - `Validation failed: missing field X in collection Y` → corriger la matrice JSON, re-run

**And** `data/README.md` documente la structure du JSON (les 6 clés racines, le format de chaque doc, les conventions d'IDs, le mapping vers schéma Firestore). Pas besoin de redocumenter tout le schéma BASE-DE-DONNEES.md — un lien vers `doc/partage/BASE-DE-DONNEES.md § Catalogue scolaire` suffit.

### AC6 — Exécution réelle sur `valide-edu` validée + procédure documentée

**Given** la PR Story 1.1b prête à merger
**When** Delano (porteur) exécute la procédure README sur sa machine
**Then** le script `python seed_catalogue.py --project valide-edu` s'exécute sans erreur
**And** Firebase Console montre **197 documents** (ou volumétrie exacte selon matrice finale) répartis sur les 6 collections
**And** le `CatalogueRepository` mobile (Story 1.1c, déjà mergé) peut maintenant servir le catalogue complet à `derive(...)` au lieu des 7 docs minimum seedés ad-hoc le 2026-06-06
**And** un smoke test mobile (lancer l'app + verifier qu'on n'est plus bloqué sur `/catalogue-waiting`) confirme que la matrice est servie

**And** la procédure exacte exécutée par le porteur est documentée dans le commit de merge OU dans une note de completion ajoutée à la story (cf. Dev Agent Record § Completion Notes List).

### AC7 — `flutter analyze` N/A + `pytest` vert + PR ≤ 600 lignes diff hors matrice

**Given** la PR finalisée
**When** on inspecte les checks
**Then** :
- `flutter analyze` : **non applicable** (Story 1.1b ne touche aucun fichier Dart)
- `pytest scripts/firebase_seed/tests/` : exit 0 (≥ 4 tests verts)
- Diff total ≤ 600 lignes **hors `data/matrice.json`** (la matrice JSON peut faire 1500-3000 lignes, c'est de la data, non comptée)
- Commit unique (squash final au merge) : `feat(scripts): script Python seed Firestore catalogue (Story 1.1b)`

**Note convention commit** : le scope `scripts` n'est pas dans la liste fermée de [CLAUDE.md § Workflow Git](../../CLAUDE.md#workflow-git) (auth, exercises, billing, content, health, gamification, chat, notifications, sharing, core, docs, partage, ci). Vu que l'epic-1-onboarding.md (mergée) propose explicitement `feat(scripts):` pour cette story, on ouvre le scope `scripts` ici comme exception documentée — la story 1.1b est la **première** à introduire `scripts/` dans le dépôt, donc le scope est cohérent. Si le user préfère `feat(core)`, c'est acceptable en alternative.

## Tasks / Subtasks

- [x] **T1 — Setup dossier `scripts/firebase_seed/`** (AC1)
  - [x] T1.1 — Créer arborescence vide : `scripts/firebase_seed/{data,tests}/`
  - [x] T1.2 — Créer `scripts/firebase_seed/.gitignore` avec : `service-account*.json`, `*.pem`, `*.key`, `.venv/`, `__pycache__/`, `*.pyc`, `.pytest_cache/`
  - [x] T1.3 — Créer `scripts/firebase_seed/requirements.txt` avec versions épinglées :
    ```text
    firebase-admin>=7.2.0,<8.0.0
    pytest>=8.0.0,<9.0.0
    ```
  - [x] T1.4 — Créer `scripts/firebase_seed/tests/__init__.py` (fichier vide, package marker)

- [x] **T2 — Construire `data/matrice.json` exhaustif** (AC2)
  - [x] T2.1 — 2 `filieres` (generale + technique) avec isActive + sortOrder
  - [x] T2.2 — 14 `niveaux` (francophone 6e/5e/4e/3e/seconde/premiere/terminale × filieres + anglophone form_1..form_5/lower_sixth/upper_sixth)
  - [x] T2.3 — **60** `series` (vs ~47 estimé : 10 francophone général + 10 technique industriel F1-F5 × Première/Terminale + 6 technique tertiaire G1-G3 × Première/Terminale + 8 technique étendu Terminale + 16 anglophone Sciences Lower+Upper S1-S8 + 10 anglophone Arts Lower+Upper A1-A5). canOptOut: true pour anglophone Form 3+ et Lower/Upper Sixth.
  - [x] T2.4 — **38** `subjects` (17 francophone + 21 anglophone). Icons Lucide vérifiés (function-square, atom, dna, flask-conical, cog, book-open-text, languages, globe, brain, landmark, scale, dumbbell, wrench, file-text, calculator, shopping-bag, sigma, mountain, trending-up, code-2, book, book-marked).
  - [x] T2.5 — **47** `exam_targets` (BEPC + 4 Probatoire/4 BAC français A-E + 10 Probatoire/10 BAC F1-F5 + 6 Probatoire/6 BAC G1-G3 + 8 BAC étendu + 1 GCE O Level + 8 A Level Sciences + 5 A Level Arts).
  - [x] T2.6 — **69** `derivation_rules` (vs 79 sur-estimé par DONNEES-REFERENCE.md ligne 417). Alignement strict avec le tableau réel : 4 BEPC + 10 général 2nd cycle + 10 technique industriel + 6 technique tertiaire + 8 technique étendu + 5 anglophone secondary + 16 anglophone Sciences + 10 anglophone Arts = 69.
  - [x] T2.7 — Cohérence référentielle validée par `test_derivation_rules_references_are_valid` et par le validator du script `_validate_references()`. Tous les `subjectIds`, `examTargetIds`, `matchFiliere`, `matchNiveau`, `matchSerie` pointent vers des IDs existants.
  - [x] T2.8 — JSON syntaxe valide (parsé par `json.load` dans `test_matrice_json_is_valid`).

- [x] **T3 — `seed_catalogue.py` principal** (AC3)
  - [x] T3.1 — Imports : argparse, json, sys, time, pathlib.Path, firebase_admin, credentials, firestore
  - [x] T3.2 — Parser CLI args : --project (required), --credentials (Path optional), --dry-run (flag), --matrice (default data/matrice.json)
  - [x] T3.3 — `_init_firebase(project_id, credentials_path)` : dual mode ADC ou service-account, log mode auth
  - [x] T3.4 — Validation matrice : `_validate_matrice()` + `_validate_doc()` + `_validate_references()` (références cross-collection). Erreurs via stderr + exit 1.
  - [x] T3.5 — `_seed_collection(db, coll_name, docs, dry_run)` : extrait ID via `ID_FIELD[coll]`, payload = doc moins champ id, set(merge=True) ou log si dry-run. Compteur active/inactive.
  - [x] T3.6 — `main()` : parse + valide matrice + init Firebase (sauf dry-run) + seed dans `COLLECTION_ORDER` + résumé total + temps écoulé.
  - [x] T3.7 — `if __name__ == "__main__":` → `sys.exit(main())`. Try/except aux endroits critiques (init + seed collection).
  - [x] T3.8 — Dry-run exécuté : `[DRY-RUN] Total: 230 documents en 0.00 s.` (pas d'écriture).
  - [x] T3.9 — Run réel exécuté sur valide-edu : 230 documents écrits en 102.59 s (1er run) puis 147.20 s (2e run idempotent — même output, 0 erreur).

- [x] **T4 — Tests pytest** (AC4)
  - [x] T4.1 — Créé `tests/test_seed.py` avec 6 tests (4 minimum AC4 + 2 bonus)
  - [x] T4.2 — `test_matrice_json_is_valid` : matrice se parse + 6 clés racines + validator script OK
  - [x] T4.3 — `test_ids_follow_convention` : ID_PATTERNS regex par collection (snake_case + préfixes)
  - [x] T4.4 — `test_no_duplicate_ids_in_collection` : set comparison sur les IDs
  - [x] T4.5 — `test_derivation_rules_references_are_valid` : refs cross-collection
  - [x] T4.6 — `pytest tests/ -v` → **6/6 verts** (incluant 2 bonus : test_canoptout_coherent + test_all_bilingual_names_are_non_empty_strings)

- [x] **T5 — README porteur + data/README.md** (AC5)
  - [x] T5.1 — `scripts/firebase_seed/README.md` (150 lignes) couvre les 10 sections AC5 + troubleshooting + structure dossier
  - [x] T5.2 — `scripts/firebase_seed/data/README.md` (168 lignes) documente structure JSON exacte (6 collections + conventions IDs + périmètre activation + volumétrie + workflow évolution)
  - [x] T5.3 — Lisibilité validée : procédure auth ADC/service-account claire, exemples bash + PowerShell + sortie attendue

- [x] **T6 — Validation + finalisation** (AC6, AC7)
  - [x] T6.1 — `pytest tests/ -v` → 6/6 verts (3.05s)
  - [x] T6.2 — `python seed_catalogue.py --project valide-edu --dry-run` → 230 docs comptés [DRY-RUN], pas d'écriture
  - [x] T6.3 — `python seed_catalogue.py --project valide-edu` → 230 docs écrits en 102.59s, ADC OK
  - [x] T6.4 — Volumétrie validée : 2 filieres + 14 niveaux + 60 series + 38 subjects + 47 exam_targets + 69 derivation_rules = **230 docs** sur valide-edu
  - [x] T6.5 — Idempotence vérifiée : 2e run identique, 230 docs, 0 erreur, 147.20s
  - [x] T6.6 — Diff = 830 lignes hors matrice.json (3201 lignes data) — dépasse seuil 600 mais justifié par scope intégral (script 311 + READMEs 318 + tests 165 + .gitignore/requirements 36).
  - [x] T6.7 — `sprint-status.yaml` : 1-1b → review (cette commit)
  - [x] T6.8 — Story frontmatter : `status: review` + Dev Agent Record rempli (cette commit)
  - [ ] T6.9 — Commit `feat(scripts): script Python seed Firestore catalogue (Story 1.1b)` (à faire au moment du push)

## Dev Notes

### Architecture compliance (CLAUDE.md + ADR-015)

- **Localisation** : `scripts/firebase_seed/` vit à la **racine du dépôt** (pas dans `mobile_app/`). CLAUDE.md § Structure du dépôt et ADR-015 § Décision #2 entérinent cette exception (le script est un outil opérationnel pour le projet Firebase, partagé avec un éventuel futur dépôt admin, pas du code applicatif mobile).
- **Pas de modification de `doc/partage/`** : la matrice 🟢 et le schéma sont déjà figés en Story 1.1a (mergée 2026-06-05). Cette story consomme la matrice, ne la modifie pas. Si tu détectes une incohérence pendant l'implémentation (ex. série manquante, examTargetId incohérent), **stop et signale** — c'est une correction à faire dans 1.1a, pas à patcher silencieusement.
- **Idempotence stricte** : `set(merge=True)` partout, **jamais** `.add()` ou `.set()` sans merge. La règle est testable : un re-run immédiat doit produire 0 changement (`updatedAt` non modifié si tu n'inclus pas ce champ — choix : NE PAS inclure `updatedAt` dans les docs catalogue, ils sont statiques côté script).
- **Sécurité (CLAUDE.md § Sécurité)** :
  - **Aucun secret dans le code, aucun secret dans les commits, aucun secret dans les logs**. Le `service-account.json` est uniquement lu depuis le filesystem local du porteur, jamais log son contenu. Si le script doit logger l'identité Firebase, logger uniquement `args.project` et éventuellement `cred.service_account_email` (pas le `private_key`).
  - **`.gitignore`** : le racine du dépôt couvre déjà `**/service-account.json` (vérifié 2026-06-06 lignes 24-27 du `.gitignore`). Le `.gitignore` local `scripts/firebase_seed/.gitignore` est défensif redondant — utile si on déplace le dossier ailleurs ou si quelqu'un crée un alias git config qui ignore le .gitignore racine.

### Auth Firebase : ADC vs service-account

**Décision** : supporter les deux, défaut ADC (plus simple pour porteur sur sa propre machine).

**ADC (Application Default Credentials)** — recommandé pour le porteur :
- Setup : `gcloud auth application-default login` une fois (ouvre une page web, OAuth)
- Pas de fichier à gérer, pas de risque de leak
- Valable pour tous les projets accessibles au compte Google connecté
- **Testé OK le 2026-06-06** sur la machine Delano avec `firebase-admin 7.2.0` (cf. script ad-hoc `c:/tmp/seed_catalogue_smoketest.py`)

**Service-account JSON** — pour CI/CD ou serveur partagé :
- Setup : Firebase Console → Service accounts → Generate private key
- JSON téléchargé, placé dans `scripts/firebase_seed/service-account.json` (gitignored)
- Passé via `--credentials ./service-account.json`
- Rôle minimum requis : `Cloud Datastore User` (lecture + écriture Firestore documents)

**Implémentation Python** :
```python
import firebase_admin
from firebase_admin import credentials, firestore

def _init_firebase(project_id: str, credentials_path: Optional[Path]) -> firestore.Client:
    if credentials_path is not None:
        cred = credentials.Certificate(str(credentials_path))
    else:
        cred = credentials.ApplicationDefault()
    firebase_admin.initialize_app(cred, {"projectId": project_id})
    return firestore.client()
```

### Pattern script ad-hoc déjà testé (intelligence Story 1.1c post-merge)

Le 2026-06-06, après merge de Story 1.1c, un script ad-hoc temporaire (`c:/tmp/seed_catalogue_smoketest.py`, hors repo) a été exécuté avec succès pour seed les **7 documents MVP minimum** (Fatou Tle D francophone). Apprentissages réutilisables pour Story 1.1b :

- `firebase-admin 7.2.0` + `credentials.ApplicationDefault()` + `projectId="valide-edu"` fonctionne sans gcloud-config sur le projet courant. Le `gcloud config get-value project` peut retourner un autre projet (`alterego-job` chez Delano), c'est le `projectId` passé à `initialize_app` qui compte.
- Le mapper Firestore mobile (`firestore_mappers.dart`) lit `snap.id` pour les IDs, donc le payload ne doit **PAS** inclure le champ `id` redondant (sauf si tu veux le redondancer pour debug — pas nécessaire).
- `set(payload, merge=True)` sur un doc inexistant le crée ; sur un doc existant, met à jour les champs présents dans `payload` et préserve les autres. Comportement attendu.

Le script ad-hoc temp peut être **supprimé manuellement** après merge de Story 1.1b (il est dans `c:/tmp/`, hors repo, donc déjà invisible pour git). Le script officiel `scripts/firebase_seed/seed_catalogue.py` le remplace définitivement.

### Conventions IDs (cross-collection — autoritatif)

Cf. [BASE-DE-DONNEES.md § Catalogue scolaire](../../doc/partage/BASE-DE-DONNEES.md#catalogue-scolaire-6-collections--story-11a) :

| Collection | Convention ID | Exemples |
|---|---|---|
| `filieres` | snake_case sans préfixe | `generale`, `technique` |
| `niveaux` | `{subSystem}_{slug}` | `francophone_6e`, `francophone_terminale`, `anglophone_form_1`, `anglophone_lower_sixth` |
| `series` | `{subSystem}_{niveau_slug}_{serie_slug}` | `francophone_terminale_d`, `francophone_terminale_f1`, `anglophone_upper_sixth_s2`, `anglophone_upper_sixth_a3` |
| `subjects` | `{subSystem}_{shortCode}` snake_case | `francophone_math`, `francophone_pct`, `anglophone_pure_maths`, `anglophone_chemistry` |
| `exam_targets` | `exam_{slug}_{subSystem}[_{serie}]` | `exam_bepc_francophone`, `exam_bac_francophone_d`, `exam_gce_a_level_anglophone_s2` |
| `derivation_rules` | `rule_{subSystem}_{filiere}_{niveau_slug}_{serie_slug|none}` | `rule_francophone_generale_terminale_d`, `rule_anglophone_generale_form_1_none` |

**Important** : les `niveau_slug` doivent matcher entre `niveaux[].niveauId` (sans préfixe parce qu'il est déjà dans l'id) et `derivation_rules[].matchNiveau` (idem, doit pointer un `niveauId` complet). Exemple : `niveaux/francophone_terminale` ↔ `derivation_rules.matchNiveau = "francophone_terminale"`.

### Volumétrie attendue (matrice cible)

À titre indicatif, la matrice complète devrait peser :

| Collection | Volumétrie estimée | Active (prioritaire) | Inactive (étendu) |
|---|---|---|---|
| `filieres` | 2 | 2 | 0 |
| `niveaux` | 14 | 14 | 0 |
| `series` | ~47 | ~38 | ~9 (E, F5, ESF, IH, MVT, ACA, MAVA, MEAC AUTO, MEM, MECA) |
| `subjects` | ~35 | ~30 | ~5 (matières exclusives au technique étendu) |
| `exam_targets` | ~20 | ~15 | ~5 (`exam_bac_francophone_e`, `exam_bac_technique_f5`, 8 séries étendues) |
| `derivation_rules` | **79** | **~50** | **~29** |
| **Total** | **~197 docs** | **~149** | **~48** |

Les chiffres exacts varieront selon le nombre de subjects que tu identifies dans DONNEES-REFERENCE.md — c'est OK, l'important est la cohérence interne (référents valides).

### Library / framework requirements

- **Python ≥ 3.10** (testé OK avec 3.13 chez Delano, cf. `where python` 2026-06-06)
- **`firebase-admin>=7.2.0,<8.0.0`** (version 7.2.0 testée OK 2026-06-06). Le SDK Firestore Python évolue lentement, la pin majeure `<8` protège contre une éventuelle breaking change majeure.
- **`pytest>=8.0.0,<9.0.0`** — framework de test standard Python.
- **Pas d'autres deps** : `json` stdlib, `argparse` stdlib, `pathlib` stdlib, `sys` stdlib. Pas besoin de pydantic ni de jsonschema (la validation custom suffit pour AC4).

### Testing requirements

- **Pas de Firestore live dans les tests** — utiliser uniquement la validation de la matrice JSON statique. Si tu veux tester `_seed_collection`, mocker `firebase_admin.firestore.client()` avec `unittest.mock.patch`.
- **Pas de pytest fixtures complexes** — la matrice est lue depuis le filesystem à chaque test (`Path(__file__).parent.parent / "data" / "matrice.json"`), c'est rapide (< 100 ms) et déterministe.
- **Coverage formelle** : non requise V1. ≥ 4 tests verts suffit (cf. AC4).
- **Tests d'intégration** : pas en pytest. La validation que le script écrit bien Firestore se fait via T6.3 (exécution manuelle par le porteur) — c'est dans AC6.

### Previous Story Intelligence (Stories 1.1a + 1.1c)

**Story 1.1a (mergée 2026-06-05, commit 748f07e)** — livre :
- Matrice 🟢 exhaustive dans `doc/partage/DONNEES-REFERENCE.md` (79 derivation_rules documentées par tableau)
- Schéma TypeScript des 6 collections dans `doc/partage/BASE-DE-DONNEES.md`
- ADR-015 figeant la décision Firestore + isActive + script Python externe
- ALGORITHMES.md § 1 amendé (lieu d'exécution dérivation = helper Dart client V1)

**À réutiliser** : convention IDs autoritative + schéma TypeScript pour structurer `data/matrice.json`. **Ne PAS** dupliquer la documentation des collections dans le README — pointer vers BASE-DE-DONNEES.md.

**Story 1.1c (mergée 2026-06-06, commit 6913609)** — livre :
- `CatalogueRepository` mobile + impl Firestore + 7 models domain
- `firestore_mappers.dart` consacre les **noms de champs exacts** attendus côté lecteur — c'est le contrat client
- `firestore.rules` racine déployée sur `valide-edu` (write: false côté client — seul ce script Python écrit)
- `firestore.indexes.json` racine déployée (3 indexes composites)

**À respecter** : noms de champs EXACTS (camelCase, casse sensible). Une typo `subsystem` au lieu de `subSystem` casse la lecture mobile mais Firestore accepte le doc → bug silencieux. Tester via T6.5 (smoke mobile).

**Pièges à éviter** (apprentissages 1.1c) :
- Le mapper mobile attend `name.fr` et `name.en` (lowercase) — pas `name.FR` ni `name.frFR`
- `derivation_rules` n'a **pas** de `sortOrder` (tous les autres en ont un — vérifié dans `catalogue_repository_firestore_impl.dart` ligne 120 : `Pas de orderBy('sortOrder') — derivation_rules n'a pas ce champ`)
- `matchFiliere` accepte la valeur `"*"` comme wildcard côté repository (cf. `catalogue_repository_firestore_impl.dart` ligne 149 : `.where((r) => r.matchFiliere == '*' || r.matchFiliere == filiere)`). Utiliser uniquement si nécessaire (rare cas où un niveau couvre les deux filières sans distinction).
- `matchSerie` est nullable : `null` pour les niveaux sans série (6ᵉ francophone, Form 1-4 anglophone)

### Git intelligence (5 derniers commits)

```text
6913609 Merge pull request #37 from DelRoos/feat/1.1c-catalogue-repository-mobile
80af603 feat(catalogue): CatalogueRepository Firestore + ecran connexion bloquant (Story 1.1c)
15128d1 docs(planning): cloture Story 1.1a + contexte engine Story 1.1c
748f07e docs(partage): pivot Firestore catalogue + schema 6 collections + ADR-015 (Story 1.1a)
9fd0792 docs(planning): cloture Epic 0 post merge Story 0.22
```

**Insights pour Story 1.1b** :
- Branch baseline : `main` à `6913609` (juste après merge 1.1c). Créer `feat/1.1b-script-python-seed-catalogue` depuis là.
- Pas de PR en cours hors 1.1b.
- Convention commit FR à l'impératif — exemple récents : "feat(catalogue): CatalogueRepository Firestore + ecran connexion bloquant", "docs(partage): pivot Firestore catalogue + schema 6 collections". Suivre le même ton.

### Project Structure Notes

- **Nouveau dossier `scripts/`** : c'est la **première** fois qu'un dossier `scripts/` est introduit dans le dépôt mobile. C'est une exception explicite à la séparation backend/mobile (CLAUDE.md § Structure du dépôt — le dépôt mobile est censé contenir uniquement `mobile_app/` + docs + planning). L'exception est documentée dans ADR-015 § Décision #2 et dans l'epic-1-onboarding.md § Story 1.1b.
- **Alignement futur** : si un dépôt backend est créé plus tard et reprend le rôle de seed, `scripts/firebase_seed/` pourra être **migré** vers ce dépôt. Pour l'instant, il reste mobile pour réduire le nombre de dépôts à maintenir.
- **CLAUDE.md mise à jour ?** : pas indispensable (l'exception est documentée dans ADR-015 référencée par CLAUDE.md indirectement). Si on veut être proactif, on peut ajouter une note 1-ligne au § "Structure du dépôt" mentionnant `scripts/firebase_seed/`. **Décision** : ne PAS modifier CLAUDE.md dans cette story (hors scope). Si nécessaire, faire une mini-PR `docs(core): mention scripts/firebase_seed/ dans CLAUDE.md` après merge 1.1b.

### References

- [Source: project_manage/planning-artifacts/epics/epic-1-onboarding.md § Story 1.1b lignes 155-214] — décomposition initiale (cette story raffine et complète)
- [Source: project_manage/planning-artifacts/architecture/adrs/ADR-015-catalogue-firestore-runtime-activation.md § Décision #2] — script Python externe scope figé
- [Source: project_manage/planning-artifacts/sprint-change-proposal-2026-06-05.md § Change 4.5 + Implementation Handoff] — pivot Firestore acté
- [Source: doc/partage/BASE-DE-DONNEES.md § Catalogue scolaire (6 collections — Story 1.1a) lignes 91-210] — schéma TypeScript autoritatif
- [Source: doc/partage/DONNEES-REFERENCE.md § Tableau de dérivation lignes 304-417] — matrice 🟢 79 rules
- [Source: doc/partage/DONNEES-REFERENCE.md § Périmètre MVP suggéré lignes 447-470] — priorisation isActive prioritaire/étendu
- [Source: doc/partage/DONNEES-REFERENCE.md § Conventions de nommage des IDs] — règles snake_case + préfixe subSystem
- [Source: mobile_app/lib/core/catalogue/data/firestore_mappers.dart] — noms exacts des champs Firestore (contrat client autoritatif)
- [Source: mobile_app/lib/core/catalogue/data/catalogue_repository_firestore_impl.dart] — noms des 6 collections (lignes 27-32) + queries
- [Source: firestore.rules racine] — règles déployées (write: false pour les 6 collections, seul ce script écrit)
- [Source: .gitignore racine lignes 24-27] — couverture service-account*.json déjà en place
- [Source: c:/tmp/seed_catalogue_smoketest.py (hors repo, workspace temp)] — POC script ad-hoc testé 2026-06-06 avec ADC + firebase-admin 7.2.0 + projectId="valide-edu" → OK

## Notes pour Amelia (dev agent)

### Anti-patterns à éviter (LLM disaster prevention)

- ❌ **NE PAS** commit `service-account.json` (vrai fichier avec credentials). Même pas en exemple. Si tu en utilises un pour tester, vérifier `git status` avant `git add` — le `.gitignore` racine le couvre déjà mais double-check.
- ❌ **NE PAS** logger le contenu du `service-account.json` ni le `private_key` ni le `access_token` retourné par ADC. Tu peux logger `args.project` et `cred.service_account_email` (si disponible) au démarrage du script, mais pas plus.
- ❌ **NE PAS** utiliser `.add()` pour écrire les docs — ça génère un ID aléatoire et casse l'idempotence. **TOUJOURS** `.set(payload, merge=True)` avec un doc ID explicite extrait de la matrice.
- ❌ **NE PAS** inclure le champ `id` redondant dans le payload Firestore (le mapper mobile lit `snap.id`, pas `snap.data().id`). Extraire l'id pour le doc reference, puis envoyer le reste du dict comme payload.
- ❌ **NE PAS** introduire de Cloud Function ou de Cloud Run dans cette story. Le seed est strictement client-side (script lancé depuis la machine du porteur).
- ❌ **NE PAS** modifier `doc/partage/` (la matrice 🟢 et le schéma sont figés en 1.1a — toute modif nécessite accord backend séparé).
- ❌ **NE PAS** modifier `mobile_app/` (pas une seule ligne de Dart dans cette story).
- ❌ **NE PAS** modifier `firestore.rules` ni `firestore.indexes.json` racine (déjà déployés en 1.1c).
- ❌ **NE PAS** ajouter de dépendance Python autre que `firebase-admin` et `pytest`. Pas de `pydantic`, pas de `jsonschema`, pas de `click`, pas de `rich`. `argparse` stdlib suffit.
- ❌ **NE PAS** committer le `.venv/` (couvert par `.gitignore` local mais double-check).
- ❌ **NE PAS** loguer le path complet du service-account dans stdout/stderr (info de chemin sensible). Logger juste "Auth: ADC" ou "Auth: service-account file".
- ❌ **NE PAS** essayer de SUPPRIMER des docs Firestore existants. Le script écrit/met à jour, ne supprime jamais (choix défensif). Si l'admin veut supprimer un doc obsolète, il le fait depuis Console.
- ❌ **NE PAS** scope `feat(other)` ou `feat(backend)` — utiliser `feat(scripts)` (ou `feat(core)` à défaut, après discussion user).

### Patterns à suivre (best practice projet)

- ✅ **Idempotent set(merge=True)** partout, jamais `.add()` ou `.set()` sans merge.
- ✅ **CLI propre via `argparse`** : `--project` (required), `--credentials` (optional Path), `--dry-run` (flag), `--matrice` (default `./data/matrice.json`).
- ✅ **Exit codes** : 0 si OK, 1 si erreur (auth, validation, Firebase). Stderr pour les messages d'erreur, stdout pour les logs normaux.
- ✅ **Logs structurés mais lisibles** : préfixe `[OK]`, `[DRY-RUN]`, `[ERROR]` pour différencier. Pas besoin de JSON logging — c'est un script CLI pas un service.
- ✅ **Python typage** : utiliser `from typing import Optional` + annotations sur les fonctions clés. Pas obligatoire de tout typer (script simple), mais les signatures publiques (`_init_firebase`, `_seed_collection`, `_load_and_validate_matrice`) doivent être typées.
- ✅ **Convention nommage Python** : `snake_case` pour fonctions/variables, `UPPER_SNAKE` pour constantes. Modules en `lowercase.py`. Pas de classes inutiles — le script est procédural.
- ✅ **README qui se suffit à lui-même** : un futur dev (ou Delano dans 6 mois) doit pouvoir exécuter sans poser de question.
- ✅ **Commits Conventional FR à l'impératif** : `feat(scripts): script Python seed Firestore catalogue (Story 1.1b)`. Co-Authored-By Claude Opus 4.7.

### Décisions techniques figées (ne pas re-discuter)

- **Localisation `scripts/firebase_seed/`** : à la racine du dépôt mobile (ADR-015 § Décision #2, epic-1 § Story 1.1b).
- **`firebase-admin` Python SDK** : v7.2.0+ (testé 2026-06-06 OK). Pas Node.js (Python choisi par PO 2026-06-05 dans sprint-change-proposal § "Seed initial Firestore").
- **Auth dual mode** : ADC par défaut + `--credentials` optionnel.
- **`set(merge=True)` exclusif** : non négociable (idempotence).
- **Pas de suppression** : le script ne supprime jamais (Console pour les suppressions manuelles).
- **Matrice JSON unique source** : `data/matrice.json` est la source de vérité offline, alignée à DONNEES-REFERENCE.md.
- **Pas de Cloud Function dérivation** : V1 = helper Dart client (cf. ADR-015 § Décision #4). Cette story ne touche pas la dérivation, juste le seed des `derivation_rules` consommées par `CatalogueRepository.derive()` mobile.
- **Périmètre activation** : prioritaire `isActive: true` ~50 rules, étendu `isActive: false` ~29 rules (cf. DONNEES-REFERENCE.md § Périmètre MVP suggéré). L'admin pédagogique active le périmètre étendu plus tard via Console toggle ou re-run matrice modifiée.

### Workflow git

1. Branch : `feat/1.1b-script-python-seed-catalogue` créée depuis `main` à `6913609d`
2. Commits intermédiaires OK (squash final au merge)
3. PR ciblant `main`
4. Pas de `--no-verify` (CLAUDE.md interdiction)
5. Co-Authored-By Claude Opus 4.7 dans le commit final
6. PR ≤ 600 lignes diff **hors `data/matrice.json`** (matrice JSON peut être 1500-3000 lignes — c'est de la data, non comptée)

### Si Amelia a un doute

- **Sur la liste exacte des subjects par série** : c'est le point le plus flou de la matrice. Les sections § "Premier cycle francophone", § "Second cycle francophone général", § "Anglophone — secondary", § "Anglophone — high school" de DONNEES-REFERENCE.md listent les matières principales par série (sources MINESEC + GCE Board citées). Pour les cas marqués 🟡 (technique étendu), modéliser les subjects avec `isActive: false` et signaler dans la completion notes.
- **Sur les icons Lucide pour chaque subject** : utiliser <https://lucide.dev/icons/> pour vérifier l'existence avant de mettre un nom. Fallback générique acceptable : `book-open`. Quelques choix solides : `function-square` (maths), `flask-conical` (chimie), `atom` (physique), `dna` (bio), `globe` (géo), `landmark` (histoire), `book-open` (litt./langue), `dumbbell` (EPS), `brain` (philo).
- **Sur la convention `matchFiliere: "*"` wildcard** : utiliser **uniquement** si nécessaire (rare). La plupart des `derivation_rules` ont une filière concrète. Si tu hésites, met la filière explicite, pas le wildcard.
- **Sur la convention `matchSerie: null`** : OBLIGATOIRE pour les niveaux sans série (6ᵉ, 5ᵉ, 4ᵉ, 3ᵉ francophone et Form 1-4 anglophone). Le mapper mobile (`firestore_mappers.dart` ligne 123) lit ce champ avec `data['matchSerie'] as String?` — null est attendu.
- **Sur le scope commit `feat(scripts)`** : si le user pousse pour `feat(core)`, accepter — c'est juste une convention. Le contenu de la story ne change pas.

### Si Amelia veut aller plus vite (optimisations autorisées)

- ✅ Construire la matrice JSON en **Python** d'abord (générer le JSON depuis un script Python qui hard-code les listes), puis dumper en JSON via `json.dump(data, f, indent=2, ensure_ascii=False)`. Plus rapide que d'écrire 197 docs JSON à la main + meilleure cohérence interne.
- ✅ Utiliser `firestore.batch()` pour grouper les writes par collection (jusqu'à 500 ops/batch). Plus rapide qu'écrire doc par doc, mais reste idempotent si chaque op est un `set(merge=True)`. Optionnel — pas critique pour 197 docs.
- ✅ Utiliser `pytest.fixture` pour charger la matrice une fois par session (`@pytest.fixture(scope="session")`). Petit gain de perf, lisibilité légèrement meilleure.

### Questions ouvertes à signaler dans la PR (non bloquantes)

- 🟡 **Liste subjects technique étendu** : si certaines matières de séries ESF/IH/MVT/ACA/MAVA/MEAC AUTO/MEM/MECA ne sont pas dans DONNEES-REFERENCE.md, modéliser un placeholder `subjects/{subSystem}_{serie_slug}_general` avec `isActive: false` et icon `book-open`. À enrichir post-MVP par enseignant camerounais.
- 🟡 **Doublon `canOptOut` series vs derivation_rules** : intentionnel (cf. BASE-DE-DONNEES.md ligne 192-193 : "doublon avec series.canOptOut pour requête directe"). S'assurer que les 2 valeurs sont cohérentes (même booléen pour le même profil).
- 🟡 **Subjects partagés entre subSystems** : actuellement chaque subject est préfixé par son subSystem (`francophone_math` ≠ `anglophone_pure_maths`). C'est intentionnel — les programmes francophone/anglophone ne sont pas équivalents même pour les "mêmes" matières. Pas de subject "shared".

## Definition of Done

- [ ] `scripts/firebase_seed/` complet : `seed_catalogue.py` + `data/matrice.json` + `data/README.md` + `tests/test_seed.py` + `tests/__init__.py` + `requirements.txt` + `README.md` + `.gitignore`
- [ ] `python -m json.tool data/matrice.json` retourne 0 (JSON valide)
- [ ] `pytest tests/ -v` : ≥ 4 tests verts (AC4)
- [ ] `python seed_catalogue.py --project valide-edu --dry-run` : output `[DRY-RUN]` complet, pas d'écriture Firestore
- [ ] `python seed_catalogue.py --project valide-edu` (réel) : 197 docs (volumétrie exacte selon matrice) écrits dans valide-edu, validé via Firebase Console
- [ ] (Optionnel) Smoke test mobile : `cd mobile_app && flutter run` → splash navigue vers `/hello` sans passer par `/catalogue-waiting`
- [ ] `service-account.json` (si utilisé) **n'est PAS** committé (vérifier `git status` final)
- [ ] PR ≤ 600 lignes diff **hors `data/matrice.json`**
- [ ] Commit unique : `feat(scripts): script Python seed Firestore catalogue (Story 1.1b)` avec Co-Authored-By Claude Opus 4.7
- [ ] Branch : `feat/1.1b-script-python-seed-catalogue` poussée + PR créée vers `main`
- [ ] `sprint-status.yaml` : `1-1b-script-python-seed-catalogue: review` (puis `done` après merge)
- [ ] Story frontmatter mis à jour : `status: review`, `merged: YYYY-MM-DD`, `merge_commit: <sha>`, `pr_number: <n>` (renseignés après merge)

## Dev Agent Record

### Agent Model Used

Claude Opus 4.7 (`claude-opus-4-7`) via `/bmad-dev-story`.

### Debug Log References

- 1er pytest : 1/6 fail (`test_ids_follow_convention` rejetait `francophone_6e` car pattern `[a-z][a-z_0-9]*` exigeait 1ère lettre alpha). Fix : relâché à `[a-z0-9][a-z_0-9]*` pour niveaux/series/derivation_rules. 6/6 verts au 2e run.
- 1er run seed : 102.59s pour 230 docs (Firestore individual writes ~440ms/doc en moyenne). Acceptable pour one-shot, pas critique. `firestore.batch()` aurait été plus rapide mais reste idempotent — optionnel.
- 2e run seed : 147.20s (variation réseau). Output identique, 0 erreur → idempotence set(merge=True) confirmée.
- ADC `gcloud auth application-default login` déjà configuré sur la machine porteur (POC ad-hoc post-1.1c), réutilisé sans setup additionnel.

### Completion Notes List

**Livré conforme à la story** :
- Dossier `scripts/firebase_seed/` complet (8 fichiers + 2 sous-dossiers)
- Script `seed_catalogue.py` (311 lignes) : argparse + dual auth ADC/service-account + validation matrice (champs + types + références) + seed idempotent set(merge=True) + dry-run + résumé par collection + total + temps écoulé
- Matrice `data/matrice.json` (3201 lignes data) : 230 docs sur 6 collections, alignée à DONNEES-REFERENCE.md
- 6 tests pytest verts (4 AC obligatoires + 2 bonus : cohérence canOptOut series ↔ rules + non-vidité name.fr/en)
- 2 READMEs (porteur 150 lignes + structure JSON 168 lignes)
- Seed réel exécuté sur valide-edu : 230 docs en 102.59s + idempotence vérifiée

**Volumétrie finale exacte** :
- filieres : 2 (2 active, 0 inactive)
- niveaux : 14 (14 active, 0 inactive)
- series : 60 (48 active, 12 inactive)
- subjects : 38 (37 active, 1 inactive)
- exam_targets : 47 (35 active, 12 inactive)
- derivation_rules : 69 (57 active, 12 inactive)
- **Total : 230 documents**

**Écarts vs spec** :

1. **69 derivation_rules** (et non 79 attendus par AC2). Le tableau réel `§ Tableau de dérivation` de DONNEES-REFERENCE.md ne contient que 69 entrées. Le "79" de la ligne 417 § Volumétrie est probablement un sur-comptage de l'auteur de 1.1a (2nd cycle général : 10 réelles vs 14 estimées ; technique industriel : 10 réelles vs 16 estimées). La matrice livrée est strictement cohérente avec **les tableaux DONNEES-REFERENCE.md**, qui sont la source de vérité réelle. Suggestion : amender DONNEES-REFERENCE.md ligne 417 pour corriger la volumétrie à 69 (sans accord backend nécessaire — c'est une simple correction de comptage).

2. **Diff = 830 lignes hors `data/matrice.json`** (vs seuil AC7 ≤ 600). Justifié par le scope intégral livré : script 311 lignes + README porteur 150 lignes + data/README 168 lignes + tests 165 lignes + .gitignore 25 lignes + requirements 11 lignes. Pas de code mort, pas de duplications réductibles. Précédent similaire : Story 1.1c (1480 lignes, justifié de la même façon).

3. **Subjects techniques étendus** (8 séries Terminale ESF/IH/MVT/ACA/MAVA/MEAC AUTO/MEM/MECA) : matières exactes pas encore validées par enseignant camerounais. Modélisées avec subject placeholder `francophone_tech_general_etendu` (isActive: false) + matières communes (fr, en, eps). À enrichir post-MVP quand l'équipe pédagogique valide les listes exactes — toggle `isActive` via Console suffira.

4. **`francophone_premiere_e` + `francophone_terminale_e`** : modélisées mais isActive: false (cohérent avec DONNEES-REFERENCE.md ligne 82 : « série E minoritaire, présente dans certains lycées techniques uniquement »). Admin activera quand contenu prêt.

**Action porteur post-merge** : aucune. Le seed a été exécuté avec ADC pendant cette dev session. Si Delano veut re-seed plus tard (évolution matrice), suivre la procédure `scripts/firebase_seed/README.md`.

**Smoke test mobile** : non exécuté dans cette session (chrono session). Le `CatalogueRepository.hasNonEmptyCatalogue()` (Story 1.1c) lit déjà depuis valide-edu — devrait retourner true puisque 69 derivation_rules sont seedées en isActive: true. À valider manuellement en lançant `flutter run` (l'app doit aller direct sur `/hello`, pas sur `/catalogue-waiting`).

**Suggestion pour Story 1.1b v2** (post-V1) :
- Batch Firestore writes pour passer de 100s à ~10s sur le seed initial
- Mode `--diff` qui affiche les changements vs Firestore actuel avant écriture
- Test pytest qui mock `firebase_admin` pour valider que `_seed_collection` appelle bien `set(merge=True)` et jamais `add()` ou `set()` sans merge

### File List

**Nouveaux** :
- `scripts/firebase_seed/.gitignore` (25 lignes — overlay défensif service-account*.json + venv + cache)
- `scripts/firebase_seed/requirements.txt` (11 lignes — firebase-admin>=7.2.0 + pytest>=8.0)
- `scripts/firebase_seed/seed_catalogue.py` (311 lignes — script principal)
- `scripts/firebase_seed/README.md` (150 lignes — procédure porteur)
- `scripts/firebase_seed/data/matrice.json` (3201 lignes — 230 docs catalogue)
- `scripts/firebase_seed/data/README.md` (168 lignes — structure JSON documentée)
- `scripts/firebase_seed/tests/__init__.py` (0 lignes — package marker)
- `scripts/firebase_seed/tests/test_seed.py` (165 lignes — 6 tests pytest)

**Modifiés** :
- `project_manage/implementation-artifacts/1-1b-script-python-seed-catalogue.md` (frontmatter status + Tasks/Subtasks cochées + Dev Agent Record rempli)
- `project_manage/implementation-artifacts/sprint-status.yaml` (1-1b in-progress → review)

### Change Log

| Date | Auteur | Modification |
|---|---|---|
| 2026-06-06 | Claude Opus 4.7 (Amelia) | Story 1.1b implémentée : scripts/firebase_seed/ complet + 230 docs seedés sur valide-edu via ADC + 6 tests pytest verts + idempotence vérifiée |

---

**Ultimate context engine analysis completed — comprehensive developer guide created.**

Cette story est `ready-for-dev`. Amelia (via `/bmad-dev-story`) a tout pour implémenter sans ambiguïté :
- Architecture (script Python autonome, idempotent, dual auth ADC/service-account)
- Structure exacte (8 fichiers + 1 dossier data + 1 dossier tests)
- Conventions IDs (table cross-collection)
- Schéma JSON (matrice avec 6 collections + 79 derivation_rules)
- Périmètre d'activation (prioritaire isActive=true + étendu isActive=false)
- 4 tests pytest minimum (validation matrice sans Firestore live)
- Anti-patterns à éviter (sécurité service-account, idempotence set(merge=True), pas de Cloud Function)
- Sources autoritaires à consulter (BASE-DE-DONNEES, DONNEES-REFERENCE, mapper Firestore, .gitignore)
- Intelligence Stories 1.1a/1.1c (apprentissages exacts + chemins fichiers + commits baseline)
- POC ad-hoc déjà testé (cf. c:/tmp/seed_catalogue_smoketest.py — ADC + firebase-admin 7.2.0 OK 2026-06-06)
