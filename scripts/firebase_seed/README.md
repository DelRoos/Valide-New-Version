# scripts/firebase_seed — Seed Firestore catalogue scolaire

Script Python autonome et idempotent qui populate les 6 collections Firestore du catalogue scolaire Valide School à partir d'une matrice JSON versionnée.

**Livré par** : Story 1.1b (BMAD).
**Décision archi** : [ADR-015 — Catalogue Firestore + activation runtime via isActive](../../project_manage/planning-artifacts/architecture/adrs/ADR-015-catalogue-firestore-runtime-activation.md).
**Schéma Firestore autoritatif** : [doc/partage/BASE-DE-DONNEES.md § Catalogue scolaire](../../doc/partage/BASE-DE-DONNEES.md#catalogue-scolaire-6-collections--story-11a).
**Matrice source** : [doc/partage/DONNEES-REFERENCE.md § Tableau de dérivation](../../doc/partage/DONNEES-REFERENCE.md#tableau-de-dérivation-subsystem-filiere-niveau-serie--examtargetids).

## Objectif

- Initialiser le catalogue (6 collections : `filieres`, `niveaux`, `series`, `subjects`, `exam_targets`, `derivation_rules`) sur un projet Firebase vide.
- Propager une évolution de la matrice (ajout d'une matière, correction d'un nom, activation d'une nouvelle série) par simple édition de `data/matrice.json` + re-run du script.
- Idempotent : un re-run avec la même matrice produit le même état Firestore (utilise `set(merge=True)` partout, jamais `add()`).

L'admin pédagogique peut aussi modifier directement les documents depuis Firebase Console (toggle `isActive`, correction de typo) sans passer par le script. Le script reste la source canonique pour les évolutions structurelles.

## Prérequis

- **Python ≥ 3.10** (testé OK avec 3.13)
- **`gcloud` CLI installé** (pour l'auth ADC recommandée) **OU** un `service-account.json` exporté depuis Firebase Console
- **Accès au projet Firebase cible** avec le rôle `Cloud Datastore User` minimum

## Setup initial (à faire une fois)

```bash
cd scripts/firebase_seed

# Créer un environnement virtuel (recommandé)
python -m venv .venv

# Windows PowerShell
.venv\Scripts\Activate.ps1
# Windows cmd
.venv\Scripts\activate.bat
# macOS/Linux
source .venv/bin/activate

# Installer les dépendances
pip install -r requirements.txt
```

## Authentification — option A : Application Default Credentials (recommandée)

```bash
gcloud auth application-default login
```

Une page web s'ouvre, tu choisis ton compte Google avec accès au projet Firebase. Pas de fichier à télécharger, valable pour tous les projets de ton compte.

**Avantages** : pas de secret à gérer, pas de risque de leak, partagé avec d'autres outils gcloud/firebase.

## Authentification — option B : service-account JSON

À utiliser pour CI/CD ou si tu n'as pas `gcloud` installé.

1. Firebase Console → Project Settings → Service accounts → Generate new private key
2. Télécharger le JSON dans `scripts/firebase_seed/service-account.json`
3. Passer `--credentials ./service-account.json` au script

> [!CAUTION]
> **Ne jamais commit `service-account.json`.** Le `.gitignore` racine du dépôt et le `.gitignore` local couvrent `service-account*.json`, mais double-check avec `git status` avant tout `git add`. Si tu le commit par erreur, **révoque immédiatement la clé** depuis Firebase Console.

## Exécution

```bash
# Dry-run (recommandé avant tout seed sur un projet partagé)
python seed_catalogue.py --project valide-edu --dry-run

# Seed réel (auth ADC)
python seed_catalogue.py --project valide-edu

# Seed réel (auth service-account)
python seed_catalogue.py --project valide-edu --credentials ./service-account.json
```

Sortie attendue :

```text
[OK] Matrice chargée : version=1.0.0, generatedAt=2026-06-06
[OK] Auth: Application Default Credentials, projectId=valide-edu
[OK] filieres         :   2 docs   (2 active, 0 inactive)
[OK] niveaux          :  14 docs   (14 active, 0 inactive)
[OK] series           :  60 docs   (48 active, 12 inactive)
[OK] subjects         :  38 docs   (37 active, 1 inactive)
[OK] exam_targets     :  47 docs   (35 active, 12 inactive)
[OK] derivation_rules :  69 docs   (57 active, 12 inactive)

[OK] Total: 230 documents en X.XX s.
```

## Modifier la matrice

1. Éditer [`data/matrice.json`](./data/matrice.json) (suivre la structure documentée dans [data/README.md](./data/README.md))
2. Re-run `python seed_catalogue.py --project valide-edu --dry-run` pour valider (validation référentielle automatique)
3. Re-run sans `--dry-run` pour propager dans Firestore
4. Firestore est mis à jour idempotent : les champs modifiés sont écrasés, les champs absents préservés (`set(merge=True)`)

**Pour supprimer un document** : utiliser Firebase Console directement. Le script n'efface jamais (choix défensif).

## Activer/désactiver une classe à chaud (sans re-run script)

C'est l'intérêt principal du pivot Firestore (ADR-015) :

1. Firebase Console → Firestore Database → collection (`series`, `derivation_rules`, `subjects`...) → ouvrir le doc
2. Toggle le champ `isActive` (true/false)
3. Effet immédiat côté mobile (le cache offline détectera l'invalidation au prochain sync — typiquement < 1 minute en réseau normal)

Utile pour :
- Activer une nouvelle série quand le contenu pédagogique est prêt
- Désactiver temporairement une série en attendant une correction
- Corriger un nom de matière sans cycle de release mobile

## Tests

```bash
pytest tests/ -v
```

6 tests valident la matrice JSON statique (validité, conventions IDs, unicité, cohérence référentielle, `canOptOut` cohérent entre `series` et `derivation_rules`, noms bilingues non vides). Aucun de ces tests ne requiert de connexion Firestore live.

## Troubleshooting

| Erreur | Cause probable | Fix |
|---|---|---|
| `Permission denied` au seed | Le compte n'a pas le rôle Cloud Datastore User sur le projet | Firebase Console → IAM → ajouter le rôle |
| `Project not found` | Typo dans `--project` ou projet supprimé | Vérifier le project ID exact dans Firebase Console |
| `Validation matrice échouée: champs manquants` | matrice.json corrompu / champ requis absent | Voir le message exact + corriger `data/matrice.json` |
| `Références invalides dans derivation_rules` | Un `subjectId` / `examTargetId` cité dans une rule n'existe pas | Voir le message + ajouter le doc manquant ou retirer la référence |
| `firebase_admin.exceptions.AlreadyExistsError: The default Firebase app already exists` | Lancer le script 2x dans le même process | Relancer le shell (rare) |

## Structure du dossier

```text
scripts/firebase_seed/
├── seed_catalogue.py          # script principal
├── data/
│   ├── matrice.json           # source de vérité versionnée (230 docs)
│   └── README.md              # documentation de la structure JSON
├── tests/
│   ├── __init__.py
│   └── test_seed.py           # 6 tests pytest (sans Firestore live)
├── requirements.txt           # firebase-admin>=7.2.0, pytest>=8.0
├── README.md                  # ce fichier
└── .gitignore                 # service-account*.json, .venv/, __pycache__/...
```

## Pourquoi `scripts/` dans un dépôt mobile ?

Cf. [CLAUDE.md § Structure du dépôt](../../CLAUDE.md) et ADR-015 § Décision #2. C'est une exception explicite : le script vit dans le dépôt mobile pour réduire le nombre de dépôts à maintenir tant qu'aucun dépôt backend n'est créé. Si un dépôt backend dédié émerge plus tard, ce dossier pourra être migré.

---

## Seed schools (Story 1.5.a)

Script complémentaire `seed_schools.py` qui seed la collection Firestore `schools` à partir de `data/schools.json` (~198 établissements MINESEC + GCE Board V1).

**Livré par** : Story 1.5.a (Epic 1.5 Schools completion).
**Schéma Firestore autoritatif** : [doc/partage/BASE-DE-DONNEES.md § `schools/{schoolId}`](../../doc/partage/BASE-DE-DONNEES.md#schoolsschoolid-).
**Story d'origine** : [1-5-a-seed-minesec-schools.md](../../project_manage/implementation-artifacts/1-5-a-seed-minesec-schools.md).

### Objectif

- Initialiser la collection `schools` sur un projet Firebase vide ou compléter un seed existant.
- Propager l'ajout d'une école (validée par admin via PR) par simple édition de `data/schools.json` + re-run du script.
- Idempotent : un re-run avec la même matrice produit le même état Firestore (`set(merge=True)` partout, jamais `add()`). Le `createdAt` est préservé via `SERVER_TIMESTAMP` au first-write.

L'admin peut aussi modifier directement les documents depuis Firebase Console (toggle `isValidated`, correction de typo) sans passer par le script. Le script reste la source canonique pour les ajouts massifs.

### Prérequis

Mêmes que `seed_catalogue.py` (Python ≥ 3.10, `gcloud` CLI OU service-account, rôle `Cloud Datastore User`).

### Exécution

```bash
# Dry-run (recommandé avant tout seed sur un projet partagé)
python seed_schools.py --project valide-edu --dry-run

# Seed réel (auth ADC)
python seed_schools.py --project valide-edu

# Seed réel (auth service-account)
python seed_schools.py --project valide-edu --credentials ./service-account.json
```

Sortie attendue :

```text
[OK] Matrice schools chargée : version=1.0.0, generatedAt=2026-06-10, count=198
[OK] Auth: Application Default Credentials, projectId=valide-edu
[OK] schools          : 198 docs   (198 validated, 0 unvalidated)

[OK] Total: 198 documents en X.XX s.
```

### Modifier la matrice schools

1. Éditer [`data/schools.json`](./data/schools.json) (suivre la structure documentée dans [data/README.md § schools.json](./data/README.md#schoolsjson--source-de-vérité-catalogue-des-écoles-minesec))
2. Re-run `python seed_schools.py --project valide-edu --dry-run` pour valider
3. Re-run sans `--dry-run` pour propager dans Firestore

### Tests

```bash
pytest tests/test_seed_schools.py -v
```

9 tests valident la matrice JSON statique (JSON loads, champs requis, unicité schoolId, subSystem valide, name/city/region non-vides, slug pattern, validator du script, couverture 10 régions, mix subSystem cohérent). Aucun de ces tests ne requiert de connexion Firestore live.

### Sources composites du seed V1

- **MINESEC** — lycées et collèges publics francophones (Yaoundé, Douala, Bafoussam, Dschang, Bertoua, Garoua, Maroua, Ngaoundéré, Ebolowa, etc.)
- **GCE Board (camgceb.org)** — Government High Schools, Government Bilingual High Schools, Presbyterian Secondary Schools (Buea, Limbe, Kumba, Bamenda, Mamfe, Tiko, etc.)
- **Wikipédia FR / techno-science.net** — cross-référence + complétion par ville

Dataset V1 ~198 écoles couvrant les 10 régions du Cameroun. Extensible via :

- PR sur `data/schools.json` + re-seed
- Flow utilisateur « Mon école n'est pas dans la liste » (Story 1.7 temporaire jusqu'à Story 1.5.c qui formalisera la modération admin)
