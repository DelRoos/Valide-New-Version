---
epic: 1
title: Onboarding & Profil scolaire
phase: P1
status: Stories drafted
generatedAt: 2026-06-05
sourceArtifacts:
  - project_manage/planning-artifacts/prds/prd-valide-mvp-2026-06-03/prd.md
  - project_manage/planning-artifacts/architecture/architecture.md
  - project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/DESIGN.md
  - project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/EXPERIENCE.md
  - project_manage/planning-artifacts/architecture/adrs/ADR-001-flutter-clean-architecture.md
  - project_manage/planning-artifacts/architecture/adrs/ADR-002-riverpod-vs-getx.md
  - project_manage/planning-artifacts/architecture/adrs/ADR-003-firebase-full-backend.md
  - project_manage/planning-artifacts/architecture/adrs/ADR-006-subsystem-fixed-at-signup.md
  - project_manage/planning-artifacts/architecture/adrs/ADR-011-cross-platform-v1-android-ios-tablet.md
  - doc/partage/BASE-DE-DONNEES.md
  - doc/partage/DONNEES-REFERENCE.md
  - doc/partage/ALGORITHMES.md
storyCount: 12  # 2026-06-05 sprint change : Story 1.1 cancelled, 1.1a/1.1b/1.1c ajoutees (cf sprint-change-proposal-2026-06-05.md). Net +2 stories.
amendments:
  - "2026-06-05 — sprint-change-proposal-2026-06-05.md : pivot Firestore-driven catalogue. Story 1.1 cancelled, remplacee par 1.1a (audit + Firestore schema + ADR-015 + BASE-DE-DONNEES.md update) + 1.1b (script Python seed) + 1.1c (CatalogueRepository mobile + ecran connexion bloquant). Stories 1.3/1.4/1.9 amendees (lecture catalogue depuis Firestore au lieu de seed JSON local)."
---

# Epic 1 — Onboarding & Profil scolaire

## Goal

Mettre en place le flow d'onboarding complet qui permet à un élève camerounais d'arriver sur l'app pour la 1ʳᵉ fois, de choisir son sous-système (francophone / anglophone), de remplir son profil scolaire en 3 étapes (filière → niveau → série), optionnellement de lier son école et de créer un compte Google/Apple, et d'atterrir sur un dashboard contextualisé avec ses matières filtrées.

**Critère de sortie d'epic** : Fatou Mballa (Tle D francophone) et James Tanyi (Upper Sixth S2 anglophone) peuvent chacun compléter le flow d'onboarding en moins de 2 minutes sur Android entrée de gamme et voir leur dashboard personnalisé avec leurs matières correctes (Maths/PCT/SVT/Français/Anglais/LV2/Philo/Hist-Géo/EPS pour Fatou ; Chemistry/Physics/Biology pour James) + leur examen visé en bandeau.

## Out of scope (Epic 1)

- ❌ Recommandations personnalisées sur dashboard (3 recos équilibrées) → **E5**
- ❌ Mini-carte de rang sur dashboard → **E5**
- ❌ Santé scolaire par notion → **E5**
- ❌ Notifications push d'inscription → **E5**
- ❌ Navigation hiérarchique matière → chapitre → leçon → notion → **E2** (Epic 1 livre uniquement la grille matières en sortie de profil)
- ❌ Liste exercices / sujets → **E2**
- ❌ Quiz, Mode 1, Mode 2 → **E3**
- ❌ Paywall, paiement, débits crédits → **E4**
- ❌ Edition du profil après création (changement de niveau en cours d'année, etc.) → reporté en post-MVP ou Epic settings dédié
- ⚠️ **Annulation suppression compte par cron quotidien** : la mécanique cron 7 jours est **backend** (Cloud Function `cleanupDeletedAccounts`). Story 1.10 livre uniquement le côté client (demande + détection + annulation par reconnexion).

## Dependency graph

> **Mis a jour 2026-06-05** suite au sprint change : Story 1.1 cancelled, remplacee par 1.1a → {1.1b, 1.1c}.

```text
        1.1a Audit matrice exhaustive + Firestore schema + ADR-015
        (research/docs only, accord backend requis)
              │
              ├──────────────────────┐
              ▼                      ▼
        1.1b Script Python      1.1c CatalogueRepository
        seed_catalogue.py       mobile + ecran connexion
        (peut paralleliser      bloquant + tests
         avec 1.1c)             (depend de 1.1a)
              │                      │
              └──────────┬───────────┘
                         ▼
              1.2 Choix sous-systeme (FR-1) + bascule i18n
                         │
                         ▼
              1.3 Flow profil scolaire 3 etapes + recap (FR-2)
              (depend desormais de 1.1c CatalogueRepository)
                         │
        ┌────────────┬───┴─────────┬─────────────┬──────────┐
        ▼            ▼             ▼             ▼          ▼
   1.4 Retrait     1.5 Garde     1.6 Compte    1.8 Persis  1.9 Dashboard
   matieres        nav (FR-4)    Google/Apple  -tance      skeleton +
   (FR-3)                        + merge       session     filtrage
   canOptOut                     visiteur      (FR-8)      isActive Firestore
   Firestore                     (FR-5)                    (FR-10)
                                        │
                            ┌──────────┴───────────┐
                            ▼                      ▼
                     1.7 Liaison ecole      1.10 Suppression compte
                     optionnelle (FR-6)     7j grace (FR-7)
```

## Stories

### ~~Story 1.1 : Audit R4 matrice MINESEC/GCE + seed catalogue local~~

> ⚠️ **CANCELLED 2026-06-05** — superseded par [sprint-change-proposal-2026-06-05.md](../../sprint-change-proposal-2026-06-05.md). Remplacee par **Stories 1.1a + 1.1b + 1.1c** ci-dessous suite au pivot Firestore-driven catalogue. Le fichier story `project_manage/implementation-artifacts/1-1-audit-r4-matrice-seed-catalogue.md` est conserve en archive avec banner SUPERSEDED.

---

### Story 1.1a : Audit matrice exhaustive + schema Firestore + ADR-015 + BASE-DE-DONNEES.md update

**Statut** : Draft
**Sprint** : P1 (semaine 1, J1 — bloquant pour 1.1b, 1.1c)
**Dependances** : aucune
**Estimation** : S (~3-4h)
**Accord requis** : backend team pour `doc/partage/BASE-DE-DONNEES.md` updates (CLAUDE.md regle § doc/partage)

**As a** product owner Valide,
**I want** une matrice exhaustive (sous-systeme, filiere, niveau, serie) → (matieres, examens) couvrant TOUTES les classes francophone (1er cycle + 2nd cycle A/C/D/E + technique F1-F5 + G1-G3 + autres ESF/IH/MVT) et anglophone (Form 1-5 + Lower/Upper Sixth complet S1-S8 + A1-A5), ET un schema Firestore documente (6 collections avec flag `isActive: bool`) + ADR-015 + mise a jour de `doc/partage/BASE-DE-DONNEES.md`,
**so that** Stories 1.1b (script Python seed) et 1.1c (CatalogueRepository mobile) puissent demarrer en parallele avec des contrats clairs, et que l'admin pedagogique puisse activer/desactiver les classes runtime depuis Firebase Console.

#### Contexte technique

Sprint change 2026-06-05 acte le pivot du seed JSON local statique vers Firestore source-of-truth dynamique. Cette story livre **uniquement les contrats** (docs, ADR, schema) — pas de code Dart ni Python.

**6 collections cibles** :
- `filieres/{id}` : `{id, name.fr, name.en, isActive, sortOrder}`
- `niveaux/{id}` : `{id, subSystem, name.fr, name.en, filiereIds[], isActive, sortOrder}`
- `series/{id}` : `{id, subSystem, niveauId, filiereId, name.fr, name.en, canOptOut, isActive, sortOrder}`
- `subjects/{id}` : `{id, subSystem, name.fr, name.en, icon, isActive, sortOrder}`
- `exam_targets/{id}` : `{id, subSystem, name.fr, name.en, isActive, sortOrder}`
- `derivation_rules/{id}` : `{matchSubSystem, matchFiliere, matchNiveau, matchSerie, subjectIds[], examTargetIds[], canOptOut, isActive}`

**Indexes composites** :
- `series.(subSystem, niveauId, filiereId, isActive)` — selection serie pour profil
- `subjects.(subSystem, isActive)` — grille matieres dashboard
- `derivation_rules.(matchSubSystem, matchFiliere, matchNiveau, matchSerie, isActive)` — derivation

**Regles d'acces** : `read: if request.auth != null` (catalogue public auth), `write: if false` (admin Console / script Python seulement).

#### Acceptance Criteria

**AC1 — Audit matrice exhaustive** : `doc/partage/DONNEES-REFERENCE.md` matrice completee pour TOUTES les classes (cf. perimetre user 2026-06-05). Statut 🟡 → 🟢 § Tableau de derivation + historique mis a jour.

**AC2 — Schema Firestore documente** : `doc/partage/BASE-DE-DONNEES.md` etendu avec les 6 collections (structure TypeScript-like comme les autres collections du doc), indexes composites listes, regles d'acces ecrites. Mise a jour de la table inventaire en haut du doc.

**AC3 — ADR-015 cree** : `project_manage/planning-artifacts/architecture/adrs/ADR-015-catalogue-firestore-runtime-activation.md` avec Statut Accepte, Contexte, Decision, Consequences positives/negatives, Alternatives rejetees (incl. seed JSON local). Reference au sprint-change-proposal.

**AC4 — Algorithmes update** : `doc/partage/ALGORITHMES.md § 1` mis a jour : algo derivation reste identique mais lieu d'execution precise (Cloud Function backend OU helper Dart client — decision figee dans Story 1.1c).

**AC5 — Accord backend** : PR commentee par backend lead approuvant les updates BASE-DE-DONNEES.md (peut etre async, mais bloquant pour merge).

#### Definition of Done

- [ ] `doc/partage/DONNEES-REFERENCE.md` matrice 🟢 complete (toutes classes)
- [ ] `doc/partage/BASE-DE-DONNEES.md` : 6 nouvelles collections documentees
- [ ] `doc/partage/ALGORITHMES.md § 1` mis a jour
- [ ] `architecture/adrs/ADR-015-catalogue-firestore-runtime-activation.md` cree
- [ ] `architecture/architecture.md § 14 Catalogue d'ADRs` mis a jour avec reference ADR-015
- [ ] Accord backend obtenu (commentaire PR)
- [ ] PR ≤ 600 lignes diff
- [ ] Commit `docs(partage): pivot Firestore catalogue + schema + ADR-015 (sprint change Story 1.1)`

#### Notes pour Amelia

- **Aucun code dans cette story** (ni Dart ni Python). Uniquement docs + ADR.
- **Aucune assumption Cloud Function** : on ne suppose pas qu'un backend existe. ADR-015 doit fonctionner mobile-only (seed via script Python externe + lecture Firestore au runtime).
- **Sources matrice** : MINESEC + GCE Board + Office du Bac (cf. DONNEES-REFERENCE.md § Sources autoritaires).
- **Decision derivation** : laisser ouverte en 1.1a (helper Dart client OU Cloud Function). Story 1.1c trance.
- **Update CLAUDE.md ?** : non, sauf si decision sur `scripts/firebase_seed/` location necessite (a discuter pendant l'implementation).

---

### Story 1.1b : Script Python `seed_catalogue.py` + matrice source + procedure d'init

**Statut** : Draft
**Sprint** : P1 (semaine 1, J2-J3 — parallele 1.1c possible)
**Dependances** : Story 1.1a (schema + ADR-015 figes)
**Estimation** : M (~4-5h)

**As a** porteur Firebase (Delano),
**I want** un script Python autonome qui lit une matrice JSON versionnee et populate les 6 collections Firestore (filieres, niveaux, series, subjects, exam_targets, derivation_rules) avec `isActive` configurables,
**so that** je puisse initialiser le catalogue sur `valide-edu` sans dependre d'un backend deploye et que les modifications futures (ajout matiere, activation serie) se fassent par re-run du script ou edition directe Console.

#### Contexte technique

Nouveau dossier `scripts/firebase_seed/` cree au niveau racine du depot (exception documentee dans CLAUDE.md — depot mobile inclut des scripts d'init Firebase). Le script utilise `firebase-admin` Python SDK (auth via service-account.json local, jamais commit).

Architecture du dossier :
```
scripts/firebase_seed/
├── seed_catalogue.py          # script principal (idempotent : set avec merge)
├── data/
│   ├── matrice.json           # source de verite versionnee (toutes classes)
│   └── README.md              # documentation de la structure
├── tests/
│   └── test_seed.py           # tests basiques (parsing matrice, validation IDs)
├── requirements.txt           # firebase-admin, pytest
├── README.md                  # procedure d'init pour porteur
└── .gitignore                 # service-account.json, __pycache__, .venv
```

#### Acceptance Criteria

**AC1 — Structure dossier scripts/firebase_seed/** : tous les fichiers ci-dessus crees. `.gitignore` couvre `service-account*.json`, `__pycache__/`, `.venv/`, `*.pyc`.

**AC2 — Matrice JSON source** : `data/matrice.json` reflete la matrice 🟢 de DONNEES-REFERENCE.md (Story 1.1a). Structure exacte selon schema Firestore Story 1.1a.

**AC3 — Script seed idempotent** : `python seed_catalogue.py --project valide-edu --credentials ./service-account.json` execute sans erreur. Idempotent : run 2x → memes documents (utilise `set` avec merge, pas `add`). Affiche un resume `Created/Updated X filieres, Y niveaux, ...`.

**AC4 — Tests basiques** : `pytest tests/` couvre : (a) parsing matrice JSON valide, (b) validation convention IDs (snake_case, prefix subSystem), (c) detection de doublons d'ID, (d) dry-run sans ecriture Firestore.

**AC5 — README porteur** : procedure d'init claire (creer service account, telecharger JSON, installer deps, run script, verifier Firestore Console). Avertissement : `service-account.json` jamais commit.

**AC6 — `flutter analyze` 0 issue** : non applicable (pas de code Dart). Tests Python verts.

#### Definition of Done

- [ ] Dossier `scripts/firebase_seed/` complet (script + matrice + tests + README + .gitignore + requirements)
- [ ] `python seed_catalogue.py --dry-run` execute sans erreur (CI)
- [ ] `pytest scripts/firebase_seed/tests/` vert (4+ tests)
- [ ] Procedure README testee par porteur (Delano) — note OK dans la PR
- [ ] PR ≤ 600 lignes diff hors matrice JSON
- [ ] Commit `feat(scripts): script Python seed Firestore catalogue (Story 1.1b)`

#### Notes pour Amelia

- **`firebase-admin` SDK Python** : version stable au moment du dev (~ 6.x).
- **Auth** : service-account.json fourni par porteur. Le script attend `--credentials` flag.
- **Idempotence critique** : `set(merge=True)` partout. Jamais `add()`.
- **NE PAS** commiter `service-account.json` — verifier `.gitignore`.
- **Action porteur post-merge** : Delano run le script une fois. Documenter le run dans la PR.

---

### Story 1.1c : CatalogueRepository mobile + ecran connexion bloquant + tests

**Statut** : Draft
**Sprint** : P1 (semaine 1, J2-J4 — parallele 1.1b possible)
**Dependances** : Story 1.1a (schema Firestore + ADR-015 figes)
**Estimation** : M (~4-5h)

**As a** dev Flutter,
**I want** un `CatalogueRepository` qui lit les 6 collections Firestore avec cache offline natif (NFR-5) + filtre `isActive == true` + helper `derive(subSystem, filiere, niveau, serie)`, et un ecran « En attente de connexion » bloquant si Firestore est vide au 1er lancement (Firestore offline + cache vide),
**so that** Stories 1.3, 1.4, 1.9 puissent consommer le catalogue de maniere transparente sans connaitre la couche Firestore.

#### Contexte technique

**Clean architecture** (ADR-001) :
- Modeles immutables (`equatable` deja pubspec) : `Filiere`, `Niveau`, `Serie`, `Subject`, `ExamTarget`, `DerivationRule`, `DerivedProfile`
- Repository : `lib/core/catalogue/catalogue_repository.dart` qui expose `Stream<CatalogueSnapshot>` (snapshots Firestore) + `Either<CatalogueFailure, DerivedProfile> derive(...)`
- Provider Riverpod : `catalogueProvider` lazy, expose un `AsyncValue<Catalogue>`
- Failure : `CatalogueFailure.empty()`, `.networkError(...)`, `.noMatchingRule(...)` etendant `Failure` (Story 0.4)

**Filtrage isActive** : toutes les queries Firestore appliquent `where('isActive', '==', true)`. Cache offline natif Firestore (Story 0.7) prend en charge la persistence.

**Ecran connexion bloquant** : route `/catalogue-waiting` affichee si `CatalogueRepository.firstLoad()` retourne `Left(CatalogueFailure.empty())` ET pas de cache offline. Affiche : icone, texte « Connecte-toi pour demarrer », bouton « Reessayer ». Pattern UX-DR-24 (loading/empty/error/offline) + EXPERIENCE.md ajout Flow 1 « Edge case 1er lancement offline ».

**Decision derivation** : helper `derive()` execute cote client (Dart) en lisant les `derivation_rules` Firestore. Pas de Cloud Function backend pour V1 (decision figee ici).

#### Acceptance Criteria

**AC1 — Modeles immutables** : `lib/core/catalogue/models.dart` (ou fichier separe par modele) avec 7 classes `equatable` listees ci-dessus. Each model has `fromFirestore(DocumentSnapshot)` factory + `toJson()` (utile pour debug). 0 dependance Flutter dans les modeles (juste `equatable`).

**AC2 — Repository Firestore** : `CatalogueRepository` expose :
- `Stream<List<Filiere>> watchFilieres()` (filter `isActive == true`, orderBy `sortOrder`)
- idem pour niveaux/series/subjects/examTargets/derivationRules
- `Future<Either<CatalogueFailure, DerivedProfile>> derive({...})` qui matche la 1ere rule des derivationRules
- Cache offline implicite (settings Story 0.7 deja active)

**AC3 — Provider Riverpod** : `catalogueProvider` Provider/StreamProvider lazy. `appStartupCatalogueCheckProvider` qui retourne `AsyncValue<bool>` (true si catalogue charge OK, false si offline+vide). Test integration.

**AC4 — Ecran connexion bloquant** : page `/catalogue-waiting` rendue si AsyncValue est offline+vide. Icone Lucide `wifi-off`, texte i18n FR/EN, bouton `AppButton.primary` « Reessayer » qui re-trigger le stream. Disparait des que le catalogue charge.

**AC5 — i18n FR/EN** : ajouter 3 cles ARB (`catalogueWaitingTitle`, `catalogueWaitingMessage`, `catalogueWaitingRetry`) en FR+EN. UX-DR-31 respecte (tutoiement FR).

**AC6 — Tests** :
- 4 tests unitaires modeles (1 par fromFirestore representative)
- 3 tests repository (mocks `FakeFirebaseFirestore` ou similaire) : stream filtres, derive() match, derive() noMatchingRule
- 2 tests widget pour ecran connexion bloquant (vide → affiche, charge → disparait)

**AC7 — `flutter analyze` 0 issue** + `flutter test` vert + PR ≤ 500 lignes diff (hors i18n generated).

#### Definition of Done

- [ ] `lib/core/catalogue/` cree avec models + repository + provider
- [ ] Ecran `/catalogue-waiting` integre dans `go_router`
- [ ] 3 cles ARB FR+EN ajoutees, AppLocalizations regenere
- [ ] 9+ tests verts
- [ ] `flutter analyze` 0 issue
- [ ] Validation device Android (optionnel iOS si Mac dispo)
- [ ] PR ≤ 500 lignes diff
- [ ] Commit `feat(catalogue): CatalogueRepository Firestore + ecran connexion bloquant (Story 1.1c)`

#### Notes pour Amelia

- **Reutiliser pattern Story 0.7** : firestore settings deja appliques au boot. Pas besoin de re-configurer.
- **AppLogger** : log `AppLogger.i('Catalogue loaded: X filieres, Y niveaux, ...')` au 1er succes. Log `AppLogger.w('Catalogue empty + offline')` si bloquant.
- **NE PAS** introduire de provider global qui parse toute la matrice au boot. Streams lazy.
- **NE PAS** ajouter `freezed` ou `json_serializable` (equatable + fromFirestore manuels suffisent).
- **Pattern Either** : `derive()` retourne `Either<CatalogueFailure, DerivedProfile>` per NFR-7.
- **iOS** : tester si Mac dispo. Sinon defer (cf. 0.4bis).

#### Acceptance Criteria

**AC1 — Audit matrice exécuté et tracé**
**Given** la matrice 🟡 squelette de `doc/partage/DONNEES-REFERENCE.md`
**When** un audit est mené (option A : par un enseignant camerounais consulté ; option B : par sources publiques MINESEC + Cameroon GCE Board)
**Then** le tableau de dérivation est complété pour les 4 séries francophones (A, C, D, E) × 3 niveaux (Seconde, Première, Terminale) + filière technique pour Terminale (F1-F5, G1-G3) + couverture anglophone (Form 1-5, Lower Sixth + Upper Sixth S1-S8 et A1-A5)
**And** la source consultée est citée (nom enseignant + école OU URLs MINESEC/GCE)
**And** le statut passe de 🟡 à 🟢 dans `doc/partage/DONNEES-REFERENCE.md` § historique

**AC2 — Seed JSON local créé**
**Given** la matrice validée
**When** on génère `mobile_app/assets/onboarding/catalogue_subjects.json`
**Then** le fichier contient un objet `{filieres: [...], niveaux: [...], series: [...], subjects: [...], examTargets: [...], derivationRules: [...]}` documenté
**And** chaque `subject` a `id` (slug snake_case), `name.fr`, `name.en`, `icon` (nom Lucide)
**And** chaque `examTarget` a `id` (`exam_bac_francophone_d` etc.), `name.fr`, `name.en`
**And** les `derivationRules` mappent `(subSystem, filiere, niveau, serie) → {subjects: [...], examTargets: [...]}`

**AC3 — Le seed est déclaré dans `pubspec.yaml` et chargeable au runtime**
**Given** `pubspec.yaml`
**When** on inspecte la section `flutter:` `assets:`
**Then** `assets/onboarding/catalogue_subjects.json` est listé
**And** un test unitaire `catalogue_loader_test.dart` charge le seed via `rootBundle.loadString` et vérifie la présence des 8 exemples figés (Tle D, Première C, etc.)

**AC4 — Cas tests cités dans le PRD vérifiables**
**Given** le seed chargé
**When** on simule `derive(subSystem='francophone', filiere='generale', niveau='Terminale', serie='D')`
**Then** la sortie est `subjects = [Maths, PCT, SVT, Français, Anglais, LV2, Philo, Hist-Géo, EPS]` (9 matières) et `examTargets = [exam_bac_francophone_d]`
**When** on simule `derive(subSystem='anglophone', filiere='generale', niveau='Upper Sixth', serie='S2')`
**Then** la sortie est `subjects = [Chemistry, Physics, Biology]` + optionnelles documentées et `examTargets = [exam_gce_a_level_anglophone_s2]`
**And** ces 2 cas sont des tests automatisés dans `catalogue_derivation_test.dart`

#### Definition of Done

- [ ] `doc/partage/DONNEES-REFERENCE.md` matrice complète et marquée 🟢 (au moins pour les séries listées dans le périmètre MVP § « Périmètre MVP suggéré »)
- [ ] `mobile_app/assets/onboarding/catalogue_subjects.json` créé et validé
- [ ] `pubspec.yaml` mis à jour pour déclarer l'asset
- [ ] 2 tests unitaires (loader + dérivation) verts
- [ ] `flutter analyze` 0 issue
- [ ] PR ≤ 400 lignes diff (le gros vient du JSON)
- [ ] Commit `docs(partage): valider matrice MINESEC/GCE R4 + seed catalogue local`

#### Notes pour Amelia

- **Source autoritaire** : si pas d'enseignant disponible, utiliser :
  - MINESEC : <https://www.minesec.cm/> (programmes officiels téléchargeables)
  - Cameroon GCE Board : <https://www.cameroongceboard.org/> (matières par série O/A Level)
- **Périmètre MVP** : couvrir au minimum les séries listées en `DONNEES-REFERENCE.md` § « Périmètre MVP suggéré » (Bepc, Probatoire/BAC séries D et C francophone général, A1-A3 et S1-S2 anglophone). Les séries techniques peuvent rester 🟡 partiel en V1 et être enrichies post-MVP.
- **Format icônes** : `name.fr = "Mathématiques"`, `icon = "function-square"` (Lucide). Vérifier la dispo dans le pack `lucide_icons`.
- **Bilinguisme** : `name.en` doit utiliser le nom officiel anglophone correspondant (ex. « Mathématiques » FR vs « Mathematics » EN, mais « Chimie » FR vs « Chemistry » EN — les sous-systèmes ont des matières disjointes, pas systématiquement des traductions 1:1).
- **Versionner le seed** : ajouter un champ `version: "1.0.0"` au seed pour pouvoir invalider le cache local quand on migrera vers Firestore.
- **NE PAS** coder la dérivation en Dart en mode "if filiere == 'generale' && niveau == 'Terminale'..." — utiliser une lookup table dans le JSON consommée par un seul helper `derive()`.

---

### Story 1.2 : Choix sous-système (FR-1) + bascule i18n runtime

**Statut** : Draft
**Sprint** : P1 (semaine 1)
**Dépendances** : Story 0.16 (i18n FR/EN setup), Story 0.13 (AppButton primaire), Story 0.12 (responsive helper)
**Estimation** : M (~4-5h)

**As a** élève camerounais qui lance Valide pour la 1ʳᵉ fois,
**I want** un écran clair me proposant 2 boutons « Francophone » et « Anglophone » qui basculent immédiatement toute l'interface dans la langue correspondante et fixent mon curriculum définitivement,
**so that** je puisse démarrer mon parcours dans ma langue sans confusion et que l'app respecte ADR-006 (sous-système immuable).

#### Contexte technique

FR-1 + ADR-006. Le choix de sous-système est **unique** au premier lancement et **immuable**. Il fixe :

- `users/{uid}.subSystem = "francophone"|"anglophone"` (champ immutable serveur, règle Firestore qui rejette toute mise à jour — déjà en place via Story 0.9 à étendre)
- `users/{uid}.language = "fr"|"en"` (dérivé, idem immutable)
- `MaterialApp.locale` (côté client, dérivé)

EXPERIENCE.md Flow 1 étape 2 : « deux boutons primaires plein largeur, aucun défaut suggéré. Tap "Francophone" → toute l'app passe en français immédiatement. »

Le choix est **persistant localement** (SharedPreferences) tant que l'auth n'est pas faite, puis migré dans `users/{uid}` lors de la création du doc Firestore (Story 1.3 ou 1.6). Avant auth, on est en **Anonymous Auth** (déjà activé via smoke test E0).

Un message d'avertissement clair (PRD FR-1 conséquence + ADR-006 négatif #2) : « Ce choix fixe la langue et le programme. Tu ne pourras pas changer après. » → confirmation par tap explicite (pas de retour arrière silencieux).

#### Acceptance Criteria

**AC1 — Splash 1.5s puis SubsystemChoicePage**
**Given** un device sans état `subSystem` enregistré localement
**When** l'app démarre
**Then** un splash s'affiche pendant 1.5s (logo Valide + pulse léger conforme DESIGN.md tokens motion)
**And** la route `/onboarding/subsystem` est ouverte automatiquement
**And** la page affiche le titre, un sous-titre court (« Choisis ta langue et ton programme — tu ne pourras pas changer après »), deux `AppButton.primary` plein largeur **« Francophone »** et **« Anglophone »** empilés
**And** aucun bouton par défaut n'est suggéré (pas d'auto-focus)

**AC2 — Bascule i18n instantanée + persistance locale**
**Given** la page de choix affichée en français par défaut (locale système FR)
**When** l'utilisateur tape « Anglophone »
**Then** une modale de confirmation s'affiche « This choice locks your language and curriculum. You won't be able to change it. » avec boutons `[Annuler]` `[Continuer]`
**And** au tap `[Continuer]`, `MaterialApp.locale` passe immédiatement à `en` (toute l'app reflète EN)
**And** `SharedPreferences` enregistre `subSystem = "anglophone"` et `language = "en"`
**And** la navigation route vers `/onboarding/profile/filiere` (Story 1.3)

**AC3 — Persistance après kill app**
**Given** le sous-système choisi (anglophone) et l'app fermée
**When** l'utilisateur relance l'app
**Then** le splash s'affiche
**And** la route `/onboarding/subsystem` **n'est jamais** ré-ouverte
**And** la locale `en` est restaurée avant le 1er `runApp`
**And** l'app reprend là où le flow était (cf. Story 1.8 persistance)

**AC4 — Garde « first launch only »**
**Given** un utilisateur avec `subSystem` posé
**When** il tente d'accéder à `/onboarding/subsystem` manuellement (deep link ou debug)
**Then** la route redirige vers `/` (home après onboarding) ou `/onboarding/profile/...` (si onboarding incomplet)
**And** le redirect est centralisé dans `go_router` (logique pour Story 1.5)

**AC5 — Anonymous Auth posée au choix**
**Given** la confirmation du sous-système
**When** le tap `[Continuer]` est validé
**Then** si `FirebaseAuth.instance.currentUser == null`, un `signInAnonymously()` est exécuté en arrière-plan (non bloquant)
**And** `AppLogger.i('Subsystem chosen: $subSystem, anonymous auth uid: $uid')` est émis
**And** en cas d'échec d'auth, le flow continue (offline-tolerant), le doc Firestore sera créé en Story 1.3 quand l'auth reviendra

**AC6 — Bilinguisme des messages**
**Given** les chaînes affichées sur la page de choix et la modale de confirmation
**When** on inspecte les fichiers `.arb`
**Then** toutes les chaînes existent en `app_fr.arb` ET `app_en.arb` (NFR-14, UX-DR-31)
**And** la microcopie respecte UX-DR-39 (tutoiement FR « Choisis ta langue », informal EN « Choose your language »)

#### Definition of Done

- [ ] 4 tests widget : (a) splash + choix affichés, (b) tap anglophone → modale, (c) tap continuer → locale change + nav, (d) garde first-launch
- [ ] 1 test integration : kill app + relance → subsystem restauré
- [ ] `flutter analyze` 0 issue
- [ ] Validation device : screenshots FR et EN avec basculement runtime
- [ ] PR ≤ 350 lignes diff
- [ ] Commit `feat(onboarding): choix sous-systeme immuable + bascule i18n runtime`

#### Notes pour Amelia

- **SharedPreferences vs Firestore** : avant auth = SharedPreferences (rapide, offline). Après doc users créé (Story 1.3), `subSystem` vit dans Firestore. La règle Firestore (étendue en Story 1.3) doit rejeter toute écriture qui modifie `subSystem` ou `language`.
- **MaterialApp.locale dynamique** : utiliser un `LocaleNotifier` (Riverpod) déjà en place via Story 0.16. Si pas en place, créer dans cette story.
- **Pas de retour arrière post-confirmation** : `Navigator.pushReplacement` ou équivalent `go_router` pour empêcher le back button d'Android de revenir au choix.
- **iOS spécifique** : le swipe-back iOS doit être désactivé sur cette route (`CupertinoPageRoute` non utilisé ici, ou `WillPopScope` explicite).
- **Modale de confirmation** : utiliser le composant `AppDialog` de Story 0.14. Texte clair, 2 boutons (annuler en `AppButton.secondary`, continuer en `AppButton.primary`).
- **NE PAS** logger le `uid` complet dans des logs réseau partagés — c'est OK ici car log debug local seulement, mais à surveiller en revue.

---

### Story 1.3 : Flow profil scolaire 3 étapes + écran récap (FR-2)

> **AMENDED 2026-06-05** (sprint change) : depend desormais de **Story 1.1c (CatalogueRepository)** au lieu de Story 1.1 cancelled. Lecture catalogue migre du seed JSON local vers Firestore via repository. AC enrichis (loading state + ecran connexion bloquant herite de 1.1c).

**Statut** : Draft
**Sprint** : P1 (semaine 1-2)
**Dépendances** : Story 1.1c (CatalogueRepository Firestore), Story 1.2 (sous-système choisi), Story 0.13 (AppButton, AppCard, PillTabs, ProgressBar), Story 0.14 (toasts pour validation)
**Estimation** : L (~6-8h, inchangee — la couche catalogue est encapsulee dans CatalogueRepository de 1.1c)

**As a** élève qui a choisi son sous-système,
**I want** remplir mon profil scolaire en 3 étapes guidées (filière → niveau → série) avec une progression visible, et voir mes matières dérivées + examen visé affichés clairement à la fin,
**so that** je sache immédiatement quels cours sont préparés pour moi sans avoir à cocher chaque matière individuellement (FR-2).

#### Contexte technique

> **MAJ 2026-06-05** : la lecture catalogue passe par `CatalogueRepository` (Story 1.1c) au lieu de `OnboardingCatalogue.load()` local. Les `subjects[]` et `examTargets[]` derives via `catalogueRepository.derive(...)` returning `Either<CatalogueFailure, DerivedProfile>`. Toutes les listes affichees (filieres, niveaux, series) sont des streams Firestore filtres `isActive == true`.

FR-2 + EXPERIENCE.md Flow 1 étapes 3-6. Le flow est une **state machine** linéaire avec navigation arrière autorisée entre étapes :

```
FiliereChoicePage (1/3) ──▶ NiveauChoicePage (2/3) ──▶ SerieChoicePage (3/3) ──▶ ProfileRecapPage
                       ◀────────────────────────◀────────────────────────◀────
```

À chaque étape, les choix dépendent des précédents (la liste de niveaux dépend de la filière, la liste de séries dépend du niveau). La dérivation matières + examens se fait via `derive()` du Story 1.1 sur le seed local.

À la confirmation finale (« C'est ma classe »), on **crée** le document `users/{uid}` Firestore avec :

```
{
  uid: <anonymous uid>,
  subSystem, language,
  filiere, niveau, serie,
  derivedSubjects: [...],   // calculé localement
  optedOutSubjects: [],     // vide à ce stade (Story 1.4)
  examTargets: [...],
  schoolId: null,           // Story 1.7
  displayName: null,        // Story 1.6
  photoUrl: null,
  createdAt, updatedAt
}
```

La règle Firestore `users/{uid}` self-only (Story 0.9) doit être **étendue** pour valider :
- `subSystem` ∈ `['francophone', 'anglophone']`
- `language = (subSystem == 'francophone' ? 'fr' : 'en')`
- `filiere` ∈ `['generale', 'technique']`
- `niveau, serie` non vides
- Pas de modification ultérieure de `subSystem`, `language`, `createdAt`

#### Acceptance Criteria

**AC1 — State machine OnboardingFlow**
**Given** un sous-système choisi (Story 1.2)
**When** l'utilisateur navigue dans le flow
**Then** un `onboardingFlowProvider` Riverpod tient l'état `OnboardingFlowState { subSystem, filiere?, niveau?, serie?, currentStep }`
**And** la navigation `Next/Back` met à jour `currentStep` et la route via go_router
**And** un test unitaire vérifie les 4 états et les transitions

**AC2 — Étape 1/3 filière (FiliereChoicePage)**
**Given** la route `/onboarding/profile/filiere`
**When** la page se charge
**Then** un header montre « Étape 1/3 » + ProgressBar à 33%
**And** 2 `AppCard` cliquables affichent « Général » et « Technique » avec icône
**And** au tap, `onboardingFlowProvider.filiere` est posé et nav vers `/onboarding/profile/niveau`
**And** un bouton retour Android/iOS ramène au splash (subsystem déjà choisi)

**AC3 — Étape 2/3 niveau (NiveauChoicePage)**
**Given** une filière choisie
**When** la page se charge
**Then** ProgressBar à 66%
**And** une liste scrollable de niveaux est affichée — filtrée selon (subSystem, filiere) depuis le seed catalogue
**And** francophone général : `[6e, 5e, 4e, 3e, 2nde, 1ere, Terminale]`
**And** anglophone général : `[Form 1, Form 2, Form 3, Form 4, Form 5, Lower Sixth, Upper Sixth]`
**And** au tap, `niveau` posé + nav vers `/onboarding/profile/serie`
**And** bouton retour ramène à filière

**AC4 — Étape 3/3 série (SerieChoicePage)**
**Given** un niveau choisi
**When** la page se charge
**Then** ProgressBar à 100%
**And** un widget `PillTabs` ou grille montre les séries valides pour `(subSystem, filiere, niveau)` — exemple Tle générale francophone : `[A, C, D, E]`, Upper Sixth générale anglophone : `[A1, A2, A3, A4, A5, S1, S2, S3, S4, S5, S6, S7, S8]`
**And** au tap, `serie` posé + nav vers `/onboarding/profile/recap`
**And** si pas de série applicable (ex. 3e francophone), skip cette étape avec `serie = '-'`

**AC5 — Écran récap matières + examen visé**
**Given** un profil complet `(subSystem, filiere, niveau, serie)`
**When** ProfileRecapPage se charge
**Then** un bandeau en haut affiche « Tu prépares le BAC D » (ou exam_target correspondant traduit via name.fr/name.en)
**And** une grille `GridView` montre les matières dérivées sous forme d'AppCard avec icône Lucide + nom
**And** un compteur « 9 matières » est affiché
**And** un `AppButton.primary` « C'est ma classe » est en bas
**And** un bouton secondaire « Retour » revient à la série
**And** si l'utilisateur a une option de retrait (Story 1.4), un lien discret « Retirer une matière » est visible (sinon pas)

**AC6 — Création doc Firestore + nav suite**
**Given** récap validé et `FirebaseAuth.currentUser` (anonymous OK)
**When** l'utilisateur tape « C'est ma classe »
**Then** un loading inline s'affiche (spinner + texte « Création de ton profil… »)
**And** un `users/{uid}` est créé avec tous les champs (`subSystem`, `language`, `filiere`, `niveau`, `serie`, `derivedSubjects[]`, `examTargets[]`, `optedOutSubjects: []`, `schoolId: null`, `createdAt`, `updatedAt`)
**And** un `AppLogger.i('Profile created: subSystem=$subSystem niveau=$niveau serie=$serie subjects=${derivedSubjects.length}')` est émis
**And** la navigation va vers `/onboarding/school` (Story 1.7) — ou `/onboarding/account` si school skippée
**And** en cas d'erreur Firestore (offline, règles refusent), un `Either<Failure, _>` remonte et un toast non bloquant « Profil sauvegardé localement, retentera en ligne » apparaît
**And** la création est idempotente (retry safe — utiliser `set` avec merge, pas `add`)

**AC7 — Règles Firestore étendues**
**Given** le fichier `firestore.rules` racine
**When** on inspecte la règle `match /users/{uid}`
**Then** la création valide la présence des champs requis et leurs types
**And** une mise à jour ultérieure rejette toute modif de `subSystem`, `language`, `createdAt`
**And** un test ajouté à `test/rules/users.test.mjs` vérifie 2 cas : (a) création valide OK, (b) update de `subSystem` KO

#### Definition of Done

- [ ] State machine `OnboardingFlowState` + tests (4+ cas)
- [ ] 4 pages widget : FiliereChoice, NiveauChoice, SerieChoice, ProfileRecap
- [ ] Helper `derive()` du Story 1.1 utilisé sans duplication
- [ ] Règles Firestore étendues + 2 tests passent
- [ ] 6 tests widget (1 par page + 2 transitions + 1 erreur Firestore)
- [ ] `flutter analyze` 0 issue
- [ ] Validation device : flow complet Fatou (Tle D) en < 60s
- [ ] PR ≤ 500 lignes diff
- [ ] Commit `feat(onboarding): flow profil scolaire 3 etapes + recap matieres derivees`

#### Notes pour Amelia

- **Pattern Riverpod** : `OnboardingFlowState` est un sealed class (ou freezed union) — `OnboardingFlowState.subsystem`, `.filiere(subSystem, filiere)`, `.niveau(...)`, `.serie(...)`. Riverpod `Notifier` qui expose les transitions.
- **Routes go_router** : `/onboarding/profile/filiere`, `/niveau`, `/serie`, `/recap` — chaque route a un guard qui vérifie l'état (si on tape `/serie` sans niveau choisi, redirect vers `/niveau`).
- **Retrait matières conditionnel** : la visibilité du lien « Retirer une matière » sur l'écran récap dépend des règles FR-3 — anglophone >= Form 3 ou Lower/Upper Sixth toutes filières. Garder le lien caché si pas autorisé. La logique sera implémentée en Story 1.4.
- **Préservation profil après merge auth** : la création anonymous + Firestore doc doit garantir que Story 1.6 (linkWithCredential) ne perde rien (`linkWithCredential` conserve l'uid).
- **Pas de catalogue Firestore** : Story 1.1 a livré un seed local. Lecture exclusivement via `rootBundle.loadString('assets/onboarding/catalogue_subjects.json')`.
- **i18n des noms matières** : utiliser `name.fr` ou `name.en` selon `subSystem` (cf. DONNEES-REFERENCE.md § « Mobile »).
- **Bilinguisme microcopie** : « Étape 1 sur 3 » FR vs « Step 1 of 3 » EN. Toutes les chaînes dans `.arb`.

---

### Story 1.4 : Retrait conditionnel matières (FR-3)

> **AMENDED 2026-06-05** (sprint change) : `_canOptOut(subSystem, niveau)` lit `series/{id}.canOptOut` depuis Firestore via `CatalogueRepository` au lieu de helper Dart hardcoded. Logique decisionnelle inchangee — seule la source change. Tests adaptes.

**Statut** : Draft
**Sprint** : P1 (semaine 1-2)
**Dépendances** : Story 1.3 (profil créé), Story 1.1c (CatalogueRepository pour lire `series/{id}.canOptOut`)
**Estimation** : S (~3h)

**As a** élève dont le profil autorise le retrait (anglophone Form 3+ ou Lower/Upper Sixth toutes filières),
**I want** pouvoir retirer certaines matières dérivées de ma liste (celles que je ne présenterai pas à mon examen),
**so that** mon dashboard et mes classements ne soient pas pollués par des matières que je ne pratique pas (FR-3).

#### Contexte technique

FR-3 : « Un élève francophone en Première C **ne voit pas** l'option ; un élève anglophone en Form 3 voit l'option et peut retirer toute matière non présentée à son O Level. »

Règle métier (cf. PRD + DONNEES-REFERENCE.md § Règles dérivation #3) :
- **Anglophones, dès Form 3** → autorisé (préparation O Level avec choix de matières)
- **Lower Sixth + Upper Sixth toutes filières** → autorisé (le stream S/A conditionne déjà la combinaison, mais retrait fin granulé)
- **Sinon** → option pas affichée

Le retrait écrit `users/{uid}.optedOutSubjects[]` — sous-ensemble strict de `derivedSubjects[]`. Si l'élève change d'avis, il peut re-cocher la matière (l'enlever de `optedOutSubjects`). C'est l'**unique** champ profil éditable post-création (à part `schoolId` Story 1.7 et `displayName/photoUrl` Story 1.6).

#### Acceptance Criteria

**AC1 — Visibilité conditionnelle**
**Given** un profil créé
**When** on inspecte l'écran récap (Story 1.3)
**Then** un lien « Retirer une matière » est affiché **si et seulement si** `_canOptOut(subSystem, niveau)` est vrai
**And** `_canOptOut('anglophone', 'Form 3')` → true ; `_canOptOut('anglophone', 'Form 2')` → false
**And** `_canOptOut('anglophone', 'Lower Sixth')` → true ; `_canOptOut('anglophone', 'Upper Sixth')` → true
**And** `_canOptOut('francophone', 'Première')` → false ; `_canOptOut('francophone', 'Lower Sixth')` → true
**And** un test unitaire vérifie les 6 cas ci-dessus

**AC2 — Page SubjectsOptOutPage**
**Given** le lien visible et tappé
**When** la route `/onboarding/profile/opt-out` se charge
**Then** une liste des matières dérivées est affichée avec checkbox (cochée = retirée)
**And** un bouton primaire « Valider » sauvegarde la sélection dans `users/{uid}.optedOutSubjects[]` via Firestore update
**And** un compteur « Tu présentes 5 matières sur 7 » est affiché en bas

**AC3 — Persistance Firestore**
**Given** une sélection de matières retirées
**When** l'utilisateur tape « Valider »
**Then** `optedOutSubjects` est mis à jour dans Firestore
**And** `AppLogger.i('Subjects opted out: ${optedOut.join(",")}')` est émis
**And** la garde de validation côté serveur : `optedOutSubjects ⊂ derivedSubjects` (règle Firestore)

**AC4 — Comportement post-validation**
**Given** la validation OK
**When** la navigation reprend
**Then** retour à l'écran récap (Story 1.3) qui re-affiche la grille filtrée (`derivedSubjects \ optedOutSubjects`)
**And** le compteur passe de « 7 matières » à « 5 matières »
**And** le lien « Retirer une matière » reste visible (peut être modifié) avec libellé « Modifier mes matières »

**AC5 — Cas francophone Première C : pas d'option**
**Given** un profil francophone, Première, série C
**When** l'écran récap se charge
**Then** aucun lien « Retirer une matière » n'est affiché
**And** un test widget vérifie l'absence du lien

#### Definition of Done

- [ ] Helper `_canOptOut(subSystem, niveau, filiere)` + 6 tests unitaires
- [ ] Page `SubjectsOptOutPage` + 2 tests widget (liste affichée, save)
- [ ] Règle Firestore `optedOutSubjects ⊂ derivedSubjects` + 1 test
- [ ] `flutter analyze` 0 issue
- [ ] PR ≤ 250 lignes diff
- [ ] Commit `feat(onboarding): retrait conditionnel matieres FR-3`

#### Notes pour Amelia

- La logique `_canOptOut` doit être **un pur helper** dans `core/profile/opt_out_rules.dart` — facilement testable.
- **NE PAS** permettre de retirer **toutes** les matières (vide = invalide). Le bouton « Valider » doit être disabled si `derivedSubjects \ optedOutSubjects` est vide. Message d'erreur clair.
- Si plus tard on veut autoriser le retrait à d'autres conditions (politique évoluée), on touchera uniquement ce helper — pas la page.
- Pour les classements (E5), `optedOutSubjects` doit aussi filtrer — à anticiper dans la structure de doc, déjà OK ici.

---

### Story 1.5 : Garde de navigation profil-incomplet (FR-4)

**Statut** : Draft
**Sprint** : P1 (semaine 1)
**Dépendances** : Story 1.3 (profil créé) — peut être développée en parallèle dès 1.3 mergée
**Estimation** : S (~3h)

**As a** tech lead Flutter,
**I want** une garde centralisée dans `go_router` qui redirige toute navigation vers une route métier (cours, exercice, classement) lorsque le profil utilisateur est incomplet, vers l'étape d'onboarding en cours,
**so that** FR-4 soit appliqué sans logique dispersée dans chaque feature.

#### Contexte technique

FR-4 + EXPERIENCE.md ligne 70. « La logique est centralisée (un seul `redirect` dans le routing), pas dispersée écran par écran. »

États possibles du profil utilisateur :
1. **Pas de subSystem** → `/onboarding/subsystem`
2. **subSystem mais pas de filière** → `/onboarding/profile/filiere`
3. **filière mais pas de niveau** → `/onboarding/profile/niveau`
4. **niveau mais pas de série (si applicable)** → `/onboarding/profile/serie`
5. **profil complet mais visiteur (pas auth)** → flow continue mais permet visit (Stories 1.7, 1.6 pour finir)
6. **profil complet ET authentifié** → toutes routes autorisées

Routes protégées (toutes les routes hors `/onboarding/*`, `/_crash`, `/_ai_smoke`, `/_test_courses`). Routes debug (`/_crash`, etc.) restent accessibles en dev.

#### Acceptance Criteria

**AC1 — Provider `profileCompletionProvider`**
**Given** un état utilisateur
**When** on lit `ref.read(profileCompletionProvider)`
**Then** il retourne `ProfileCompletionState.subsystemMissing`, `.filiereMissing`, `.niveauMissing`, `.serieMissing`, `.complete`
**And** la dérivation lit Firebase Auth + Firestore users/{uid} (en cache offline OK)

**AC2 — Garde centralisée dans go_router**
**Given** la configuration `GoRouter` du Story 0.2 (étendue ici)
**When** une route est requested
**Then** le `redirect` callback :
  - laisse passer les routes `/onboarding/*` et `/_*` (debug) inconditionnellement
  - laisse passer les routes home/matières/etc. **uniquement** si profil complet
  - redirige sinon vers la 1ère étape manquante (cf. états ci-dessus)
**And** un test integration vérifie 4 cas de redirect

**AC3 — Deep link vers `/lessons/maths_derivees` profil incomplet**
**Given** un utilisateur avec subSystem mais pas de niveau choisi
**When** un deep link `/lessons/maths_derivees` est ouvert
**Then** le router redirige vers `/onboarding/profile/niveau` (état en cours)
**And** un toast non bloquant peut informer « Termine ton profil pour continuer »

**AC4 — Pas de redirection une fois profil complet**
**Given** un profil complet (Story 1.3 finie)
**When** l'utilisateur navigue vers `/` ou `/matieres` ou un deep link `/lessons/X`
**Then** la route est servie normalement (pas de redirect)

**AC5 — Routes onboarding accessibles tant que pas finies**
**Given** un utilisateur visiteur avec profil complet mais pas de compte (FR-5 / Story 1.6 pas faite)
**When** l'utilisateur accède à `/onboarding/account`
**Then** la route est servie (pas redirect)
**And** l'utilisateur peut continuer son flow sans contrainte

#### Definition of Done

- [ ] `profileCompletionProvider` + tests unitaires (5 états)
- [ ] `GoRouter.redirect` centralisé + 4 tests integration
- [ ] `flutter analyze` 0 issue
- [ ] PR ≤ 200 lignes diff
- [ ] Commit `feat(onboarding): garde navigation profil-incomplet centralisee`

#### Notes pour Amelia

- La garde doit être **fast** (pas de network call à chaque redirect). Lire en cache Firestore (offline OK).
- En cas d'erreur de lecture, considérer le profil comme incomplet (fail-safe : redirige vers onboarding) — `AppLogger.w` émis.
- La logique `_nextOnboardingStep(state)` est un pur helper séparé.
- **NE PAS** mettre la logique de garde dans chaque page (« anti-pattern »).
- iOS swipe-back : le swipe arrière depuis une page protégée respecte le redirect (testé sur simulateur iOS si Mac dispo).

---

### Story 1.6 : Création compte Google/Apple + merge visiteur (FR-5)

**Statut** : Draft
**Sprint** : P1 (semaine 1-2)
**Dépendances** : Story 1.3 (profil créé en Anonymous Auth), Story 0.6 (Firebase Auth configuré)
**Estimation** : M (~5h)

**As a** visiteur qui a rempli son profil scolaire,
**I want** créer un compte Google ou Apple sans perdre mes choix de profil,
**so that** je puisse me reconnecter depuis un autre device et conserver mon historique (FR-5).

#### Contexte technique

FR-5 + EXPERIENCE.md Flow 1 étape 8. « Visiteur → profil rempli → création compte Google → tous les champs du profil sont préservés côté serveur. »

Mécanisme Firebase Auth : `linkWithCredential` permet de **promouvoir** un compte Anonymous en compte permanent **sans perdre l'uid**. Donc le doc `users/{uid}` créé en Story 1.3 reste intact, juste le compte est upgrade.

```dart
final googleCred = await GoogleSignIn().signIn();
final cred = GoogleAuthProvider.credential(idToken: googleCred.idToken, accessToken: googleCred.accessToken);
final result = await FirebaseAuth.instance.currentUser!.linkWithCredential(cred);
// uid inchangé, account.providerData mis à jour, profil Firestore préservé
```

Cas d'échec :
- Pas de réseau → message clair, retry
- Compte Google déjà lié à un autre Firebase uid → conflit, demander à l'utilisateur d'utiliser ce compte (signOut anonymous + signIn Google) **et accepter la perte du profil visiteur** (avec confirmation explicite)
- Utilisateur annule (close sheet Google) → pas d'erreur, retour à la page

Le bouton « Continuer en visiteur » est explicite : permet de finir l'onboarding sans compte (le visiteur ne pourra pas lancer un mode ni composer, cf. EXPERIENCE.md ligne 71).

#### Acceptance Criteria

**AC1 — Page AccountCreationPage**
**Given** un profil complet (post Story 1.3 ou post 1.7)
**When** la route `/onboarding/account` se charge
**Then** la page affiche :
  - Titre + sous-titre (« Crée ton compte pour sauvegarder ta progression »)
  - `AppButton.primary` plein largeur « Continuer avec Google » (avec icône Google)
  - `AppButton.primary` plein largeur « Continuer avec Apple » (avec icône Apple — visible Android et iOS, recommandation Apple)
  - Lien discret en bas « Continuer en visiteur »

**AC2 — Sign-in Google + linkWithCredential**
**Given** l'utilisateur est en Anonymous Auth avec profil créé
**When** il tape « Continuer avec Google »
**Then** la sheet système Google s'ouvre
**And** au choix d'un compte, `linkWithCredential` est appelé
**And** l'uid reste inchangé (vérifié par `currentUser.uid == previousUid`)
**And** `users/{uid}` est mis à jour avec `displayName` et `photoUrl` issus de Google
**And** `AppLogger.i('Account linked: provider=google uid=$uid')` émis
**And** la nav va vers `/` (home avec dashboard Story 1.9)

**AC3 — Sign-in Apple + linkWithCredential**
**Given** un device iOS (ou Android où Apple Sign-In est dispo)
**When** l'utilisateur tape « Continuer avec Apple »
**Then** la sheet Apple s'ouvre
**And** `linkWithCredential` lie le compte
**And** comportement identique à AC2 (uid préservé, profil intact)
**And** sur Android, Apple Sign-In via web (firebase_auth `signInWithProvider`) — fallback documenté

**AC4 — Échec réseau gracieux**
**Given** l'utilisateur tape « Continuer avec Google »
**When** le réseau est coupé
**Then** un toast « Connecte-toi à internet pour créer ton compte. Tu peux continuer en visiteur pour le moment. » s'affiche
**And** aucune modification n'est faite au compte ou au profil
**And** `AppLogger.w('Account linking failed: networkError')` émis

**AC5 — Conflit compte déjà lié**
**Given** un compte Google déjà associé à un autre uid Firebase
**When** `linkWithCredential` échoue avec `credential-already-in-use`
**Then** une modale s'affiche : « Ce compte est déjà utilisé. Si tu te connectes avec, tu perdras ton profil actuel. Veux-tu continuer ? »
**And** [Annuler] → retour à la page
**And** [Continuer] → signOut anonymous + signInWithCredential Google + supprime l'ancien doc users/{anonUid} → crée un nouveau flow ou redirige vers le compte existant
**And** un test integration mock le cas

**AC6 — Mode visiteur explicite**
**Given** la page AccountCreationPage affichée
**When** l'utilisateur tape « Continuer en visiteur »
**Then** la nav va vers `/` (home)
**And** le badge « Visiteur » est affiché en discret sur le dashboard (Story 1.9 anticipe)
**And** l'utilisateur peut revenir à `/onboarding/account` plus tard via lien « Créer mon compte »

#### Definition of Done

- [ ] Plugin `google_sign_in` + `sign_in_with_apple` ajoutés au `pubspec.yaml`
- [ ] iOS : capability Apple Sign-In activée dans Xcode (TODO en attendant Mac — documenté)
- [ ] Android : SHA-1 du keystore debug ajouté à Firebase Console (porteur)
- [ ] 4 tests widget : (a) page affichée, (b) tap Google → mock linkWith, (c) tap visiteur → nav, (d) erreur réseau
- [ ] 1 test integration : flow complet anonymous → Google → uid préservé
- [ ] `flutter analyze` 0 issue
- [ ] Validation device : flow Google sur Android (Apple seulement sur iOS en session Mac)
- [ ] PR ≤ 400 lignes diff
- [ ] Commit `feat(onboarding): creation compte Google et Apple avec merge profil visiteur`

#### Notes pour Amelia

- **Anonymous Auth obligatoire** : doit être activée dans Firebase Console (action porteur pendantE0 toujours en attente — verrouille les acceptance criteria).
- **Google Sign-In configuration** : nécessite OAuth client_id Android + iOS dans Firebase Console. Le `google-services.json` régénéré inclut ces refs.
- **Apple Sign-In sur Android** : faisable via `sign_in_with_apple` package (web flow). Documenter dans `doc/tools/CONTRIBUTING.md`.
- **NE PAS** stocker l'idToken Google dans le code ou les logs.
- **Bilinguisme** : « Continuer avec Google » FR vs « Continue with Google » EN (suivre la convention Google brand guidelines).
- **Edge case kill app mid-flow** : si l'utilisateur ferme l'app pendant le Google Sign-In, au retour il revient sur la page AccountCreationPage (auth state inchangé).
- **Test conflit** : utiliser `FirebaseAuth.instance.signInWithCredential` + `linkWithCredential` mocks pour simuler `credential-already-in-use`.

---

### Story 1.7 : Liaison école optionnelle (FR-6)

**Statut** : Draft
**Sprint** : P1 (semaine 2)
**Dépendances** : Story 1.6 (compte créé)
**Estimation** : M (~4-5h)

**As a** élève authentifié,
**I want** rechercher mon école dans le catalogue ou demander son ajout, ou skip cette étape,
**so that** je puisse participer aux classements de classe / école (Epic 5) plus tard sans bloquer mon onboarding (FR-6).

#### Contexte technique

FR-6 + EXPERIENCE.md Flow 1 étape 7.

Catalogue `schools` (cf. BASE-DE-DONNEES.md) :
```
schools/{schoolId}: {
  schoolId, name, region, ville, isValidated, type, createdAt
}
schools/{schoolId}/requests/{requestId}: {
  requestId, requestedBy: uid, requestedAt, status: 'pending'
}
```

Lecture autocomplete : query `schools` where `isValidated == true` + `name` startsWith `query` (limit 10). Cache Firestore offline natif (NFR-5).

Demande d'ajout d'école : écriture dans `schools/{schoolId}/requests/`. Modération admin hors scope mobile. Stub l'écriture si la règle Firestore n'est pas encore en place (déférer la règle à une chore backend).

Skip → `users/{uid}.schoolId = null`. Re-accessible plus tard via Profil settings (post-MVP).

#### Acceptance Criteria

**AC1 — Page SchoolLinkPage**
**Given** la route `/onboarding/school`
**When** la page se charge
**Then** elle affiche :
  - Titre « Lie ton école (optionnel) »
  - `AppInput` de recherche avec debounce 300ms
  - Liste de suggestions (au moins 5 visibles)
  - Bouton secondaire « Passer cette étape » en bas

**AC2 — Autocomplete depuis Firestore**
**Given** l'utilisateur tape « Lycée Bilingue »
**When** la requête est lancée
**Then** un loading state affiché 200ms+
**And** la liste affiche les écoles `isValidated == true` matchant le préfixe (max 10)
**And** chaque entrée a nom + région/ville + badge « Validée »
**And** au tap d'une école, `users/{uid}.schoolId = chosenId` est posé via Firestore update
**And** la nav va vers `/onboarding/done` (ou home)

**AC3 — Aucun résultat**
**Given** une recherche sans match
**When** la liste est vide
**Then** un état vide (UX-DR-12) « Aucune école trouvée » + bouton secondaire « Ajouter mon école »
**And** au tap, une modale demande nom + ville/région, validation soumet la demande dans `schools/{tempId}/requests/`
**And** un toast « Demande envoyée, on revient vers toi » s'affiche
**And** le `users/{uid}.schoolId` reste `null` (l'école sera liée par admin plus tard)

**AC4 — Skip explicite**
**Given** la page affichée
**When** l'utilisateur tape « Passer cette étape »
**Then** `users/{uid}.schoolId = null` (déjà la valeur par défaut, juste confirmation)
**And** la nav va vers home (Story 1.9)
**And** un toast non bloquant « Tu peux lier ton école plus tard dans Profil » est affiché

**AC5 — Cache offline**
**Given** un utilisateur offline ayant déjà consulté les écoles validées
**When** il revient sur la page
**Then** les suggestions cached sont affichées (Firestore cache offline NFR-5)
**And** la demande d'ajout est bufferisée et synchronisée à la reconnexion

#### Definition of Done

- [ ] `SchoolRepository` impl avec recherche autocomplete (debounce 300ms)
- [ ] 4 tests widget : (a) page affichée, (b) search + résultats, (c) tap école → save, (d) skip
- [ ] 1 test integration : demande ajout école
- [ ] `flutter analyze` 0 issue
- [ ] PR ≤ 350 lignes diff
- [ ] Commit `feat(onboarding): liaison ecole optionnelle avec autocomplete et demande ajout`

#### Notes pour Amelia

- **Indexes Firestore** : ajouter `schools.isValidated` + composite `(isValidated, name)` pour les requêtes startsWith. Mise à jour `firestore.indexes.json` racine.
- **Règles Firestore** : étendre `match /schools/{id}` pour permettre `read` à tout user authentifié (les écoles sont publiques). Écriture `requests/` autorisée à utilisateur authentifié seulement.
- **Debounce 300ms** : utiliser `Stream.debounce` ou `Timer.cancel()` pour éviter spam.
- **Bilinguisme** : noms d'écoles restent dans la langue locale du Cameroun (« Lycée », « Government High School » — pas de traduction des proper nouns).
- **Pas de géolocalisation V1** : seulement search textuelle. Géo en V2.
- **Pas de feedback admin** : la demande d'ajout n'a pas de retour mobile-side V1 (l'élève ne sera pas notifié si l'école est validée). À documenter post-MVP.

---

### Story 1.8 : Persistance session + reprise flow interrompu (FR-8)

**Statut** : Draft
**Sprint** : P1 (semaine 1)
**Dépendances** : Story 1.3 (state machine onboarding)
**Estimation** : S (~3h)

**As a** élève qui ferme l'app pendant l'onboarding (interruption batterie, sms parent, etc.),
**I want** que l'app reprenne automatiquement à l'étape où j'en étais lors de ma prochaine ouverture,
**so that** je n'aie pas à recommencer (FR-8) et que l'expérience d'onboarding soit fluide même sur Android entrée de gamme avec coupures fréquentes.

#### Contexte technique

FR-8 + EXPERIENCE.md ligne 450. « Edge case : profil interrompu → réouverture relance directement l'étape en cours. »

Mécanismes existants à enrichir :
1. **Auth state** : `FirebaseAuth.instance.authStateChanges()` survit naturellement (Firebase SDK persiste le token). Pas de travail à faire.
2. **subSystem** : déjà persisté en `SharedPreferences` (Story 1.2).
3. **OnboardingFlowState** : actuellement en mémoire Riverpod, perdu au kill. À persister.

Solution : ajouter un champ `users/{uid}.onboardingStep` qui prend `'subsystem'|'filiere'|'niveau'|'serie'|'recap'|'school'|'account'|'done'`. Mise à jour à chaque transition de step. Le `redirect` go_router lit ce champ pour reprendre à la bonne route.

Si l'utilisateur n'est pas encore en Anonymous Auth (avant Story 1.3), `onboardingStep` est stocké en SharedPreferences.

#### Acceptance Criteria

**AC1 — Champ `onboardingStep` posé à chaque transition**
**Given** un utilisateur dans le flow profil
**When** il passe de filière à niveau
**Then** `users/{uid}.onboardingStep = 'niveau'` est updated dans Firestore
**And** la valeur est lue à chaque démarrage de l'app

**AC2 — Reprise auto au démarrage**
**Given** un utilisateur avec `onboardingStep = 'serie'` posé
**When** l'app démarre
**Then** après le splash, la route `/onboarding/profile/serie` est ouverte automatiquement
**And** les choix précédents (filière, niveau) sont restaurés depuis Firestore dans le `OnboardingFlowProvider`

**AC3 — Reprise en mode visiteur (post-1.3 pré-1.6)**
**Given** un utilisateur avec profil créé mais pas de compte Google
**When** il kille l'app et la relance
**Then** la route `/onboarding/account` est ouverte (`onboardingStep = 'account'`)
**And** il peut continuer en visiteur ou créer son compte

**AC4 — Session post-onboarding préservée**
**Given** un utilisateur avec `onboardingStep = 'done'`
**When** il kille l'app et la relance après 1 semaine
**Then** la route `/` (home/dashboard) est ouverte sans redirection vers onboarding
**And** son `displayName`, son profil et toutes ses données sont disponibles
**And** Firebase Auth restore son token sans prompt de re-auth

**AC5 — Avant Anonymous Auth (cas rare)**
**Given** un utilisateur qui a choisi son sous-système mais n'a pas encore signInAnonymously (offline au moment du choix)
**When** il kille l'app et la relance en ligne
**Then** la valeur `subSystem` (SharedPreferences) est lue
**And** `signInAnonymously` est tenté
**And** le flow reprend à `/onboarding/profile/filiere` (1ère étape post-subsystem)

#### Definition of Done

- [ ] Champ `onboardingStep` ajouté au schéma `users` + doc/partage/BASE-DE-DONNEES.md mise à jour
- [ ] Mise à jour automatique du champ à chaque transition (intégrée dans `OnboardingFlowNotifier`)
- [ ] `appStartupProvider` ajusté pour lire le champ et router en conséquence
- [ ] 3 tests widget/integration : (a) kill app étape niveau → reprend à niveau, (b) kill après profil → reprend à account, (c) kill après onboarding → home
- [ ] `flutter analyze` 0 issue
- [ ] PR ≤ 250 lignes diff
- [ ] Commit `feat(onboarding): persistance session et reprise flow interrompu`

#### Notes pour Amelia

- **Cohérence avec garde Story 1.5** : le `redirect` go_router doit **prioriser** `onboardingStep` Firestore par rapport à l'inférence visuelle (ex. si `onboardingStep = 'recap'` mais filière manque, c'est anormal — log error + fail-safe vers `subsystem`).
- **Race condition** : si l'utilisateur tape rapidement filière → niveau, deux updates Firestore sont en flight. Utiliser `set` avec merge OK (idempotent).
- **Champ `subSystem` immuable** : pas posé ici, il reste posé en Story 1.2. Cette story ne touche qu'à `onboardingStep`.
- **Mise à jour `doc/partage/BASE-DE-DONNEES.md`** : ajouter le champ `onboardingStep: string` au schéma `UserDoc` avec note « cleanup post-MVP : retirer après stabilisation flow ».
- **Test edge case offline** : si Firestore est offline mais SharedPreferences a `subSystem`, le flow reprend après le subsystem. Comportement déjà couvert par AC5.

---

### Story 1.9 : Dashboard skeleton + filtrage matières par profil (FR-10 partiel)

> **AMENDED 2026-06-05** (sprint change) : la grille matieres filtre les `derivedSubjects \ optedOutSubjects` par `subject.isActive == true` lu depuis Firestore via `CatalogueRepository`. Une matiere desactivee admin runtime disparait automatiquement de la grille au prochain stream tick.

**Statut** : Draft
**Sprint** : P1 (semaine 2)
**Dépendances** : Story 1.3 (profil créé), Story 1.1c (CatalogueRepository pour `subject.isActive` filter)
**Estimation** : M (~5h)

**As a** élève qui vient de finir son onboarding,
**I want** atterrir sur un dashboard qui me souhaite la bienvenue par mon prénom et qui affiche en grille mes matières dérivées (filtrées selon mon profil),
**so that** je voie immédiatement que l'app est faite pour moi et que je sache quoi explorer ensuite (FR-10).

#### Contexte technique

FR-10 (partiel) + EXPERIENCE.md Flow 1 climax (étape 10). « Écran d'accueil s'affiche, hero bleu avec "Bienvenue Fatou !" + mini-carte de rang vide + 3 recommandations starter. »

**Périmètre Epic 1** : uniquement le squelette dashboard avec Hero + grille matières. Les blocs suivants viennent en E5 :
- ❌ Mini-carte de rang
- ❌ Recommandations équilibrées
- ❌ Notifications widget
- ❌ Score / points / badges

Filtrage : matières dérivées (`users/{uid}.derivedSubjects[] - optedOutSubjects[]`). Lecture du seed catalogue pour récupérer nom + icône de chaque matière.

Pour visiteurs (pas de compte Google) : badge discret « Visiteur » + lien « Créer mon compte » dans le coin. Le visiteur peut explorer la grille mais ne peut pas lancer un mode (cf. EXPERIENCE.md ligne 71).

#### Acceptance Criteria

**AC1 — Page HomePage avec hero**
**Given** un utilisateur post-onboarding (route `/`)
**When** la page se charge
**Then** un hero en haut affiche :
  - « Bienvenue {prénom} ! » si auth Google/Apple (prénom issu de `displayName`)
  - « Bienvenue ! » si visiteur (pas de prénom)
  - Sous-titre court contextualisé (« Voici tes matières — tu prépares le BAC D » par exemple)
**And** un bandeau d'examen visé affiche le nom de l'`examTargets[0]` (« BAC D », « GCE A Level Sciences », etc.)

**AC2 — Grille matières filtrée**
**Given** un profil avec `derivedSubjects = [maths, pct, svt, ...]` et `optedOutSubjects = []`
**When** la HomePage se charge
**Then** un `GridView` 2-3 colonnes (responsive selon UX-DR-32 breakpoints) affiche les matières
**And** chaque matière a `AppCard` avec icône Lucide + `name.fr` ou `name.en` selon `subSystem`
**And** un compteur « 9 matières » est visible en haut de la grille
**And** au tap sur une matière, navigation vers `/matieres/{subjectId}` (route stub pour E2, peut afficher un "Bientôt disponible" pour P1)

**AC3 — Visiteur — badge + invitation compte**
**Given** un utilisateur en Anonymous Auth (pas de provider Google/Apple)
**When** la HomePage se charge
**Then** un badge « Visiteur » s'affiche en haut à droite
**And** un encadré discret en bas de la grille : « Crée ton compte pour sauvegarder ta progression » avec `AppButton.secondary` « Créer mon compte »
**And** le bouton route vers `/onboarding/account`

**AC4 — Cas `optedOut`**
**Given** un profil avec `optedOutSubjects = ['biology']`
**When** la grille s'affiche
**Then** Biology n'apparaît pas
**And** le compteur passe de 6 à 5 matières

**AC5 — Loading + empty state**
**Given** un user dont le profil charge depuis Firestore
**When** la HomePage attend les données
**Then** un skeleton (UX-DR-13) s'affiche (gradient shimmer 1.4s)
**And** si la grille est vide (cas erreur dérivation), un état vide « Termine ton profil » avec bouton vers `/onboarding/profile/...`

**AC6 — Bottom tab bar visible**
**Given** la HomePage chargée
**When** on regarde le bas de l'écran
**Then** le bottom tab bar 4 onglets (UX-DR-23) est visible : Accueil (actif) / Matières / Activités / Profil
**And** la HomePage est sur l'onglet « Accueil »
**And** les autres onglets affichent un placeholder « Bientôt disponible » pour P1 (Stories E2-E6 viendront les remplir)

#### Definition of Done

- [ ] `HomePage` + Hero + grille matières + bottom tab bar
- [ ] `HomeViewModel` qui lit le profil + dérive `displayedSubjects = derivedSubjects \ optedOutSubjects`
- [ ] 4 tests widget : (a) profil complet → grille, (b) visiteur → badge + invite, (c) optedOut → filtré, (d) loading skeleton
- [ ] Responsive testé phone + tablet (Android au minimum, iOS en Mac session)
- [ ] `flutter analyze` 0 issue
- [ ] PR ≤ 400 lignes diff
- [ ] Commit `feat(home): dashboard skeleton avec grille matieres filtrees par profil`

#### Notes pour Amelia

- **Pas de recommandations** : le bloc « 3 recommandations » est out of scope Epic 1. Vide pour l'instant — un placeholder peut être ajouté pour E5.
- **Réutilisation seed catalogue** : utiliser le helper de Story 1.1 pour récupérer `subject.name.fr` etc. — pas de re-fetch Firestore.
- **Pattern bottom tabs** : utiliser `NavigationBar` Material 3 ou implémentation custom alignée DESIGN.md. Onglets Matières/Activités/Profil affichent une page placeholder « Disponible bientôt » pour P1.
- **Greeting prénom** : `displayName.split(' ').first` pour extraire le prénom. Si vide ou null → fallback « Bienvenue ! ».
- **iOS / Android safe area** : utiliser `SafeArea` correctement (notch iOS, status bar Android).
- **NE PAS** introduire de pull-to-refresh ici (UX-DR-38 mentionne pull-refresh mais c'est pour E2+).

---

### Story 1.10 : Suppression compte avec délai grâce 7 jours (FR-7)

**Statut** : Draft
**Sprint** : P1 (semaine 2)
**Dépendances** : Story 1.6 (compte créé), backend Cloud Function `requestAccountDeletion` (hors scope mobile — peut être stubbée)
**Estimation** : S (~3h)

**As a** élève qui veut quitter Valide,
**I want** demander la suppression de mon compte avec un délai de grâce de 7 jours pour pouvoir changer d'avis,
**so that** FR-7 soit respecté (RGPD-like) et que je ne perde pas définitivement mes données par erreur.

#### Contexte technique

FR-7 + ADR-005 (doc/partage maintenance). Le cycle de vie :
1. L'élève demande la suppression depuis Profil settings (UI mobile)
2. Cloud Function `requestAccountDeletion` (backend, hors scope mobile) pose `users/{uid}.deletionRequestedAt = now`
3. UI affiche un message clair « Ton compte sera supprimé dans 7 jours. Reconnecte-toi avant pour annuler. »
4. À chaque sign-in dans la fenêtre 7j, Cloud Function `cancelAccountDeletion` annule (pose `deletionRequestedAt = null`)
5. Un cron quotidien Cloud Function supprime effectivement après J+7 (mobile n'est pas concerné — la prochaine connexion donne `auth/user-not-found`)

**Côté mobile** : story livre UI + appel function (peut être stubbée si la function n'est pas encore en place). Détection du `deletionRequestedAt != null` au stream pour afficher un encadré d'avertissement permanent.

#### Acceptance Criteria

**AC1 — Page ProfileSettingsPage minimale**
**Given** un utilisateur authentifié (Story 1.6)
**When** il navigue vers `/profile/settings`
**Then** une page simple s'affiche avec section « Supprimer mon compte » en bas (style « zone de danger »)
**And** un `AppButton.danger` (UX-DR-1 variante danger) « Supprimer mon compte » est visible

**AC2 — Modale de confirmation explicite**
**Given** l'utilisateur tape sur le bouton de suppression
**When** la modale s'ouvre
**Then** elle affiche :
  - Titre « Es-tu sûr ? »
  - Texte clair « Ton compte sera supprimé dans 7 jours. Tu peux annuler à tout moment en te reconnectant pendant cette période. »
  - `AppButton.secondary` « Annuler » 
  - `AppButton.danger` « Confirmer la suppression »

**AC3 — Appel Cloud Function `requestAccountDeletion`**
**Given** la confirmation explicite
**When** l'utilisateur tape « Confirmer »
**Then** un spinner inline s'affiche
**And** un appel `cloud_functions.httpsCallable('requestAccountDeletion')()` est fait
**And** en succès : `AppLogger.i('Account deletion requested: uid=$uid')` + toast « Demande enregistrée. Reconnecte-toi avant {date+7j} pour annuler. »
**And** en échec : message d'erreur clair, pas de pénalité (l'utilisateur peut réessayer)
**And** si la Cloud Function n'existe pas (backend non déployé), l'erreur est gérée gracefully avec message « Fonctionnalité bientôt disponible »

**AC4 — Affichage encadré permanent post-demande**
**Given** un utilisateur avec `users/{uid}.deletionRequestedAt != null`
**When** il ouvre la HomePage (Story 1.9)
**Then** un encadré warning (UX-DR-8) en haut affiche « Ton compte sera supprimé le {date}. Cliquer pour annuler. »
**And** au tap, appel Cloud Function `cancelAccountDeletion` qui pose `deletionRequestedAt = null`
**And** un toast confirme « Suppression annulée. »

**AC5 — Annulation automatique par reconnexion**
**Given** un utilisateur avec `deletionRequestedAt` posé
**When** il revient sur l'app après avoir été déconnecté
**Then** au premier auth state restauré, l'app appelle Cloud Function `cancelAccountDeletion` automatiquement (FR-7 ligne 179 PRD)
**And** un toast informe « Ton compte est de nouveau actif. »

#### Definition of Done

- [ ] `ProfileSettingsPage` route + UI section danger zone
- [ ] Modale confirmation + 3 tests widget (affichage, annulation, confirmation)
- [ ] `AccountDeletionRepository` impl avec call Cloud Function + 1 test mock
- [ ] Détection `deletionRequestedAt` au stream + encadré home
- [ ] `flutter analyze` 0 issue
- [ ] Documentation : noter dans `doc/partage/CONTRATS-API.md` les 2 functions (`requestAccountDeletion`, `cancelAccountDeletion`) avec leur contrat
- [ ] PR ≤ 300 lignes diff
- [ ] Commit `feat(profile): suppression compte avec delai grace 7 jours (FR-7)`

#### Notes pour Amelia

- **Cloud Functions backend** : les 2 functions doivent être créées par l'équipe backend. Si pas en place au moment de la story, **stubber** côté mobile avec un AppLogger.i + fallback message. Documenter l'attente backend dans la PR.
- **Mise à jour `doc/partage/CONTRATS-API.md`** : nécessite accord backend (cf. CLAUDE.md règle). Soumettre la PR avec un commentaire à @backend-team.
- **NE PAS** logger le `uid` complet dans les logs partagés (PII-like).
- **Cas edge `auth/user-not-found`** : si l'utilisateur revient au-delà des 7 jours, le sign-in échoue. Catcher et rediriger vers `/onboarding/subsystem` avec message « Ton compte n'existe plus, recommence un nouveau profil. »
- **iOS / Android dispatch** : le bouton danger doit utiliser la couleur `AppColors.danger` (rouge sémantique). Tap rapide deux fois interdit (debounce 1s).
- **Pas de re-suppression** : si `deletionRequestedAt` est déjà posé, l'option « Supprimer » est cachée et remplacée par « Annuler la suppression ».

---

## Couverture des exigences

| FR | Story | Notes |
|---|---|---|
| FR-1 | 1.2 | Choix sous-système + bascule i18n + immuabilité |
| FR-2 | 1.3 | Flow 3 étapes + récap (lecture catalogue Firestore via 1.1c) |
| FR-3 | 1.4 | Retrait conditionnel (canOptOut depuis Firestore via 1.1c) |
| FR-4 | 1.5 | Garde nav centralisée |
| FR-5 | 1.6 | Compte Google/Apple + linkWithCredential |
| FR-6 | 1.7 | École optionnelle + autocomplete |
| FR-7 | 1.10 | Suppression 7j grace |
| FR-8 | 1.8 | Persistance + reprise |
| FR-10 | 1.9 | Dashboard filtré (partiel — recos en E5, isActive filter via 1.1c) |
| R4 | 1.1a | Audit matrice exhaustive + Firestore schema (replaced 1.1 cancelled) |
| Infrastructure seed | 1.1b | Script Python `scripts/firebase_seed/` (sprint change) |
| Infrastructure mobile | 1.1c | CatalogueRepository + ecran connexion bloquant (sprint change) |

| UX-DR | Story | Notes |
|---|---|---|
| UX-DR-1, 2 (boutons) | 1.2, 1.6, 1.10 | Réutilisation composants Story 0.13 |
| UX-DR-3 (input) | 1.7 | Search école |
| UX-DR-6 (pill tabs) | 1.3 | Série |
| UX-DR-7 (progress bar) | 1.3 | Étapes 1/3, 2/3, 3/3 |
| UX-DR-10 (modale) | 1.2, 1.10 | Confirmation immuabilité + suppression |
| UX-DR-12 (empty state) | 1.7 | Pas d'école trouvée |
| UX-DR-13 (skeleton) | 1.9 | Loading grille |
| UX-DR-23 (bottom tab bar) | 1.9 | 4 onglets |
| UX-DR-24 (loading/empty/error/offline) | 1.9 | 4 états |
| UX-DR-31 (i18n) | 1.2, transversal | Bascule + tutoiement FR |
| UX-DR-32 (responsive) | 1.9 | Grille phone/tablet |
| UX-DR-39 (microcopie) | toutes | Tutoiement FR |

## Estimation totale

| Story | Taille | Heures estimées |
|---|---|---|
| ~~1.1 Audit R4 + seed local~~ | ~~S~~ | ~~3-4h~~ **CANCELLED** |
| **1.1a Audit matrice + Firestore schema + ADR-015 + BASE-DE-DONNEES update** | **S** | **3-4h** |
| **1.1b Script Python seed_catalogue.py** | **M** | **4-5h** |
| **1.1c CatalogueRepository mobile + ecran connexion bloquant** | **M** | **4-5h** |
| 1.2 Sous-système | M | 4-5h |
| 1.3 Profil 3 étapes (lecture Firestore via 1.1c) | L | 6-8h |
| 1.4 Retrait matières (canOptOut Firestore) | S | 3h |
| 1.5 Garde nav | S | 3h |
| 1.6 Compte Google/Apple | M | 5h |
| 1.7 École | M | 4-5h |
| 1.8 Persistance | S | 3h |
| 1.9 Dashboard skeleton (isActive filter) | M | 5h |
| 1.10 Suppression compte | S | 3h |
| **Total post sprint change** | | **51-63h** |

Cible P1 = 1 semaine (5j × ~8h = 40h). Sprint change 2026-06-05 ajoute **+12-15h** (split 1.1 → 3 stories). **Options absorption** :

- Elargir P1 a 6-7j calendaires (recommande)
- OU deferer 1.7 (Liaison ecole) et 1.10 (Suppression compte) en debut P2 sans perte de user-value Epic 1 critique (Fatou et James peuvent valider l'onboarding sans ecole liee et sans option suppression compte)

Decision a prendre en mid-sprint si pression timeline.

## Notes transversales

- **Anonymous Auth activée en Firebase Console** : action porteur toujours en attente depuis Story 0.21 (sentinelle E0). Story 1.2 verrouille cet requirement. À traiter J1 P1.
- **Règles Firestore étendues** : Stories 1.3 (validation users/{uid}), 1.7 (catalog schools read + requests write), 1.10 (deletion field), **1.1c (6 nouvelles collections catalogue read-only)** — toutes nécessitent des updates `firestore.rules` + redéploiement. À coordonner avec backend si parallèle.
- **Backend Cloud Functions** : Story 1.10 dépend de `requestAccountDeletion` + `cancelAccountDeletion`. Si backend pas prêt, stub mobile-side.
- **Sprint change 2026-06-05** : pivot Firestore-driven catalogue (cf. [sprint-change-proposal-2026-06-05.md](../../sprint-change-proposal-2026-06-05.md)). Stories 1.1a/1.1b/1.1c remplacent 1.1 cancelled. Stories 1.3/1.4/1.9 amendees. Action porteur post-1.1b mergee : run `python scripts/firebase_seed/seed_catalogue.py --project valide-edu` pour peupler Firestore.
- **Accord backend BASE-DE-DONNEES.md** : Story 1.1a ajoute 6 collections (filieres, niveaux, series, subjects, exam_targets, derivation_rules) au schema partage. Per CLAUDE.md regle § doc/partage, necessite commentaire approval backend lead sur la PR 1.1a.
- **Nouveau dossier `scripts/firebase_seed/`** : exception au principe « ce depot = mobile only » de CLAUDE.md, documentee dans Story 1.1b. Justification : pas de backend deploye V1, le script Python d'init est l'unique mecanisme de seed.
- **CI/CD (0.17 deferred)** : pas de pipeline GitHub Actions. Tests à lancer manuellement (`flutter test` + `pytest scripts/firebase_seed/tests/`) avant chaque PR.
- **iOS validation** : Stories 1.6 (Apple Sign-In) et 1.9 (responsive tablet) gagnent à être validées sur iOS — session Mac à planifier.
- **Performance NFR-2 (démarrage < 3s)** : à surveiller — splash 1.5s + lecture catalogue Firestore (1er cold start) + check onboardingStep. Cache offline Firestore (Story 0.7) couvre les lancements suivants. Profiling Story 1.1c et 1.2.
