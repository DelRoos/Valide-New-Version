# data/ — Sources de vérité versionnées

Ce dossier contient les matrices JSON versionnées seedées dans Firestore par les scripts Python du dossier parent.

| Fichier | Collection Firestore | Script | Story |
| --- | --- | --- | --- |
| `matrice.json` | `filieres`, `niveaux`, `series`, `subjects`, `exam_targets`, `derivation_rules` | `seed_catalogue.py` | 1.1b |
| `schools.json` | `schools` | `seed_schools.py` | 1.5.a |
| `content_demo.json` | `chapters`, `lessons`, `notions` | `seed_content.py` | 2.1 |

---

## matrice.json — Source de vérité catalogue scolaire

Fichier JSON versionné qui contient la matrice exhaustive du catalogue scolaire Valide School (6 collections Firestore). Lu par `seed_catalogue.py` (Story 1.1b) au seed et après chaque évolution.

## Source autoritaire

- **Tableau de dérivation** (les 69 entrées de `derivation_rules`) : [`doc/partage/DONNEES-REFERENCE.md § Tableau de dérivation`](../../../doc/partage/DONNEES-REFERENCE.md#tableau-de-dérivation-subsystem-filiere-niveau-serie--examtargetids)
- **Schéma TypeScript** des 6 collections : [`doc/partage/BASE-DE-DONNEES.md § Catalogue scolaire`](../../../doc/partage/BASE-DE-DONNEES.md#catalogue-scolaire-6-collections--story-11a)
- **Conventions IDs** : [`doc/partage/DONNEES-REFERENCE.md § Convention de nommage des IDs`](../../../doc/partage/DONNEES-REFERENCE.md)

## Structure racine

```jsonc
{
  "version": "1.0.0",
  "generatedAt": "YYYY-MM-DD",
  "comment": "Note humaine sur le contenu",
  "filieres":         [ /* 2 docs */ ],
  "niveaux":          [ /* 14 docs */ ],
  "series":           [ /* 60 docs */ ],
  "subjects":         [ /* 38 docs */ ],
  "exam_targets":     [ /* 47 docs */ ],
  "derivation_rules": [ /* 69 docs */ ]
}
```

## Conventions IDs (résumé)

| Collection | Convention | Exemple |
|---|---|---|
| `filieres` | snake_case sans préfixe | `generale`, `technique` |
| `niveaux` | `{subSystem}_{slug}` | `francophone_6e`, `anglophone_lower_sixth` |
| `series` | `{subSystem}_{niveau_slug}_{serie_slug}` | `francophone_terminale_d`, `anglophone_upper_sixth_s2` |
| `subjects` | `{subSystem}_{shortCode}` | `francophone_math`, `anglophone_chemistry` |
| `exam_targets` | `exam_{slug}_{subSystem}[_{serie}]` | `exam_bac_francophone_d`, `exam_gce_a_level_anglophone_s2` |
| `derivation_rules` | `rule_{subSystem}_{filiere}_{niveau_slug}_{serie_slug|none}` | `rule_francophone_generale_terminale_d`, `rule_anglophone_generale_form_1_none` |

Détails complets dans [BASE-DE-DONNEES.md § Catalogue scolaire](../../../doc/partage/BASE-DE-DONNEES.md#catalogue-scolaire-6-collections--story-11a).

## Champ par champ

### `filieres[i]`

```jsonc
{
  "filiereId": "generale",                       // = doc ID Firestore
  "name": { "fr": "Générale", "en": "General" },
  "isActive": true,
  "sortOrder": 10
}
```

### `niveaux[i]`

```jsonc
{
  "niveauId": "francophone_terminale",
  "subSystem": "francophone",                    // "francophone" | "anglophone"
  "name": { "fr": "Terminale", "en": "Terminale" },
  "filiereIds": ["generale", "technique"],       // liste de filieres applicables
  "isActive": true,
  "sortOrder": 170
}
```

### `series[i]`

```jsonc
{
  "serieId": "francophone_terminale_d",
  "subSystem": "francophone",
  "niveauId": "francophone_terminale",           // ref → niveaux/{id}
  "filiereId": "generale",                       // ref → filieres/{id}
  "name": { "fr": "D", "en": "D" },
  "canOptOut": false,                            // Story 1.4 — true si l'élève peut retirer des matières
  "isActive": true,
  "sortOrder": 90
}
```

### `subjects[i]`

```jsonc
{
  "subjectId": "francophone_math",
  "subSystem": "francophone",
  "name": { "fr": "Mathématiques", "en": "Mathematics" },
  "icon": "function-square",                     // nom Lucide (cf. https://lucide.dev/icons/)
  "isActive": true,
  "sortOrder": 10
}
```

### `exam_targets[i]`

```jsonc
{
  "examTargetId": "exam_bac_francophone_d",
  "subSystem": "francophone",
  "name": { "fr": "BAC D", "en": "BAC D" },
  "isActive": true,
  "sortOrder": 80
}
```

### `derivation_rules[i]`

```jsonc
{
  "ruleId": "rule_francophone_generale_terminale_d",
  "matchSubSystem": "francophone",
  "matchFiliere": "generale",                    // ref → filieres/{id} OU "*" wildcard
  "matchNiveau": "francophone_terminale",        // ref → niveaux/{id}
  "matchSerie": "francophone_terminale_d",       // ref → series/{id} OU null (si niveau sans série)
  "subjectIds": [                                // liste de refs → subjects/{id}
    "francophone_math", "francophone_pct", "francophone_svt",
    "francophone_fr", "francophone_en", "francophone_lv2",
    "francophone_philo", "francophone_hg", "francophone_eps"
  ],
  "examTargetIds": ["exam_bac_francophone_d"],   // liste de refs → exam_targets/{id}
  "canOptOut": false,                            // doublon avec series.canOptOut, pour requête directe
  "isActive": true
}
```

Note : `derivation_rules` n'a **pas** de `sortOrder` (contrairement aux 5 autres collections).

## Périmètre d'activation (`isActive`)

Le périmètre activé au seed initial reflète [DONNEES-REFERENCE.md § Périmètre MVP suggéré](../../../doc/partage/DONNEES-REFERENCE.md#périmètre-mvp-suggéré) :

- **Périmètre prioritaire** (`isActive: true`, ~57/69 rules actives) :
  - Francophone général : 6ᵉ→3ᵉ + BEPC, Seconde/Première/Terminale séries **A, C, D** + Probatoire/BAC
  - Francophone technique : Première/Terminale **F1-F4** + **G1-G3**
  - Anglophone : Form 1→Form 5 + O Level, Lower/Upper Sixth **S1-S8 et A1-A5** + A Level

- **Périmètre étendu** (`isActive: false`, ~12/69 rules inactives) :
  - Francophone général : série **E** (Première + Terminale)
  - Francophone technique : série **F5** (Première + Terminale) + 8 séries étendues Terminale (ESF, IH, MVT, ACA, MAVA, MEAC AUTO, MEM, MECA)
  - L'admin pédagogique active runtime via Console toggle `isActive` quand le contenu pédagogique est prêt — pas besoin de re-run script ni de release mobile

## Volumétrie finale

| Collection | Total | Active | Inactive |
|---|---|---|---|
| `filieres` | 2 | 2 | 0 |
| `niveaux` | 14 | 14 | 0 |
| `series` | 60 | 48 | 12 |
| `subjects` | 38 | 37 | 1 (placeholder technique étendu) |
| `exam_targets` | 47 | 35 | 12 |
| `derivation_rules` | 69 | 57 | 12 |
| **Total** | **230** | **193** | **37** |

## Notes d'écart vs DONNEES-REFERENCE.md

- **69 derivation_rules** (vs **79** indiqués dans DONNEES-REFERENCE.md § volumétrie ligne 417) : le tableau réel des sections § Tableau de dérivation ne contient que 69 entrées. Le 79 de la ligne 417 inclut probablement des doubles-comptages (2nd cycle général : 10 réelles vs 14 estimées ; technique industriel : 10 réelles vs 16 estimées). La matrice livrée est cohérente avec **les tableaux DONNEES-REFERENCE.md** (source vérité).
- **Séries techniques étendues** (8 séries Terminale) : les listes de matières exactes ne sont pas encore validées par enseignant camerounais (cf. DONNEES-REFERENCE.md ligne 141 🟡). Modélisées avec un subject placeholder `francophone_tech_general_etendu` + matières communes (fr, en, eps) — à enrichir post-MVP quand l'équipe pédagogique aura validé les listes exactes.
- **Form 1-2 anglophone** : `integrated_science` agrégé en un seul subject, à éclater en physics/chemistry/biology dès Form 3 (élargissement scientifique documenté DONNEES-REFERENCE.md ligne 198).

## Workflow d'évolution

1. Repérer le changement à apporter (nouvelle série activable, correction matière, nouveau niveau...)
2. Éditer ce JSON (respecter la structure documentée ci-dessus)
3. `python ../seed_catalogue.py --project valide-edu --dry-run` pour validation + comptage
4. Si OK : `python ../seed_catalogue.py --project valide-edu`
5. Commit `data/matrice.json` (et éventuellement DONNEES-REFERENCE.md si la matrice doc a évolué — accord backend requis pour `doc/partage/`)

Pour les **micro-corrections** (typo dans un nom, toggle `isActive`), passer directement par Firebase Console est plus rapide et acceptable — pas besoin de re-run le script.

---

## schools.json — Source de vérité catalogue des écoles MINESEC

Fichier JSON versionné qui contient la matrice des établissements scolaires camerounais (collection Firestore `schools`). Lu par `seed_schools.py` (Story 1.5.a) au seed initial et après chaque évolution.

### Source autoritaire

- **Schéma TypeScript** : [`doc/partage/BASE-DE-DONNEES.md § schools/{schoolId}`](../../../doc/partage/BASE-DE-DONNEES.md#schoolsschoolid-)
- **Story d'origine** : [Story 1.5.a — Seed MINESEC](../../../project_manage/implementation-artifacts/1-5-a-seed-minesec-schools.md)
- **Sources composites** : MINESEC (lycées/collèges publics francophones) + GCE Board (GHS/GBHS/PSS anglophones) + Wikipédia FR + techno-science.net

### Structure racine

```jsonc
{
  "version": "1.0.0",
  "generatedAt": "YYYY-MM-DD",
  "source": "Composite : MINESEC + GCE Board + Wikipedia + techno-science.net",
  "comment": "Dataset Story 1.5.a (Epic 1.5)",
  "schools": [ /* ~200 docs V1 — extensible via PR + flow demande ajout Story 1.5.c */ ]
}
```

### Conventions schoolId

Slug reproductible `school_<slug_nom>_<slug_ville>` :

- Lower-case
- Accents normalisés (é → e)
- Espaces → underscore
- Caractères spéciaux supprimés
- Pattern : `^school_[a-z0-9_]+$`

Exemples :

- `school_lycee_general_leclerc_yaounde`
- `school_lycee_bilingue_bonaberi_douala`
- `school_ghs_buea_town_buea`
- `school_pss_mankon_bamenda`

### Champ par champ — `schools[i]`

```jsonc
{
  "schoolId": "school_lycee_bilingue_bonaberi_douala",  // = doc ID Firestore
  "name": "Lycee Bilingue de Bonaberi",                 // casse officielle préservée
  "city": "Douala",                                     // ville
  "region": "Littoral",                                 // une des 10 régions officielles MINESEC
  "subSystem": "both",                                  // "francophone" | "anglophone" | "both"
  "isValidated": true,                                  // true pour toutes les écoles MINESEC officielles
  "keywords": [                                         // Story 1.5.b — tokens lower-case ASCII pour query arrayContains
    "bilingue", "bonaberi", "de",                       // tokens du name + city + region (sans accents)
    "douala", "lb", "littoral", "lycee"                 // + abréviations communes (lb=Lycée Bilingue)
  ]
}
```

> **Note `createdAt`** : posé automatiquement par le script de seed (`firestore.SERVER_TIMESTAMP`), pas dans le JSON.

> **Note `keywords[]`** (Story 1.5.b) : régénéré déterministiquement par `_generate_keywords()` à partir de `name + city + region + abréviations communes`. **Ne pas éditer manuellement** — utiliser `python seed_schools.py --regen-keywords` pour propager toute modification de `name/city/region`. Cf. [README.md § Régénérer le champ keywords[]](../README.md#régénérer-le-champ-keywords-story-15b).

### Régions MINESEC officielles (10)

`Adamaoua`, `Centre`, `Est`, `Extreme-Nord`, `Littoral`, `Nord`, `Nord-Ouest`, `Ouest`, `Sud`, `Sud-Ouest`.

### Heuristique `subSystem`

| Nom contient... | subSystem | Sémantique |
|---|---|---|
| « Lycée » / « Collège » / « CES » (FR pur) | `francophone` | Section uniquement francophone |
| « Government High School » / « GHS » / « PSS » / « Comprehensive » | `anglophone` | Section uniquement anglophone |
| « Lycée Bilingue » / « Government Bilingual High School » / « GBHS » | `both` | **Sections multiples francophone + anglophone** coexistantes |

**Note importante** : la valeur `both` couvre toutes les écoles avec **plusieurs langues coexistantes** dans le même établissement — pas seulement les écoles « bilingues » dans le nom officiel. Beaucoup de grands lycées francophones (Lycée Joss, Lycée Général Leclerc, etc.) ont en pratique une section bilingue opérationnelle et peuvent être promus `francophone` → `both` ultérieurement.

Si ambigu (école bilingue privée, nom mixte) : choisir `both` par défaut. Corrections possibles via Firebase Console toggle ultérieur OU PR sur `schools.json` + re-seed.

> **Évolution future** : si un nouveau sous-système devait être ajouté (ex. arabophone via madrasas), une migration vers `subSystems: string[]` (array Firestore avec `arrayContains`) serait privilégiée. À tracer en sprint-change si le cas survient. Cf. note dans [BASE-DE-DONNEES.md § schools/{schoolId}](../../../doc/partage/BASE-DE-DONNEES.md#schoolsschoolid-).

### Volumétrie V1 (post-seed Story 1.5.a)

| Région | Écoles |
|---|---|
| Centre | 40 |
| Littoral | 38 |
| Ouest | 34 |
| Sud-Ouest | 20 |
| Nord-Ouest | 16 |
| Nord | 13 |
| Sud | 11 |
| Extreme-Nord | 10 |
| Adamaoua | 8 |
| Est | 8 |
| **Total** | **198** |

| subSystem | Écoles |
|---|---|
| francophone | 136 |
| both | 35 |
| anglophone | 27 |
| **Total** | **198** |

### Workflow d'évolution

1. Identifier l'école à ajouter (nom, ville, région, subSystem)
2. Générer le `schoolId` selon la convention (`school_<slug>`)
3. Ajouter l'entrée dans `schools[]` (respecter l'ordre alphabétique par région si possible)
4. `python ../seed_schools.py --project valide-edu --dry-run` pour validation + comptage
5. Si OK : `python ../seed_schools.py --project valide-edu`
6. Commit `data/schools.json` (Conventional Commits scope `core` ou `partage`)

Pour les **micro-corrections** (typo dans un nom, toggle `isValidated`), passer directement par Firebase Console est plus rapide et acceptable — pas besoin de re-run le script.

### Source complémentaire — flow demande ajout Story 1.5.c

Les écoles absentes de `schools.json` peuvent être ajoutées par les utilisateurs via le flow « Mon école n'est pas dans la liste » dans `school_picker_page` (Stories 1.7 + 1.5.c).

Le flow écrit dans la **collection racine** `school_requests/{requestId}` (cf. [`BASE-DE-DONNEES.md § school_requests/{requestId}`](../../../doc/partage/BASE-DE-DONNEES.md)). Schéma du doc :

```text
school_requests/{requestId}:
  requestedBy: <uid>
  requestedAt: <serverTimestamp>
  status: "pending" | "approved" | "rejected"
  name: <string 3-200>
  city: <string 2-100>
  region?: <string max 100>
  subSystem?: "francophone" | "anglophone" | "both"
  decidedBy?: <admin uid>
  decidedAt?: <serverTimestamp>
  schoolIdCreated?: <ref vers schools/{id}>
  rejectionReason?: <string>
```

---

## Workflow admin modération des demandes d'ajout (Story 1.5.c)

Cette section décrit le workflow opérationnel pour traiter les demandes d'ajout d'école soumises par les utilisateurs. Pas de Cloud Function de modération V1 (over-engineering pour 1-3 admins et ~42 demandes/mois @10k users) — l'admin modère manuellement via Firebase Console + ce script.

### Étape 1 — Lister les demandes pending

1. Ouvrir [Firebase Console > Firestore Database > school_requests](https://console.firebase.google.com/project/valide-edu/firestore/data/~2Fschool_requests)
2. Filtrer : ajouter un filtre `status == 'pending'`
3. Inspecter les champs `name` + `city` + `region` + `subSystem` (optionnel) de chaque demande

### Étape 2 — Valider une demande (créer le doc `schools/<newId>`)

**Option A — Rapide / ad-hoc (à éviter pour la traçabilité Git)** : ajouter manuellement l'école dans Firebase Console > `schools/<newId>` avec le schéma `SchoolDoc` complet (cf. BASE-DE-DONNEES.md § schools/{schoolId}), puis run `python seed_schools.py --project valide-edu --regen-keywords` depuis `scripts/firebase_seed/` pour générer les `keywords[]`.

**Option B — Canonique / recommandée** :

1. Slugifier le nom + ville pour obtenir un `schoolId` stable : `school_<slug_nom>_<slug_ville>` (pattern `^school_[a-z0-9_]+$`)
2. Ajouter une entrée dans `scripts/firebase_seed/data/schools.json` avec `schoolId` + `name` + `city` + `region` + `subSystem`
3. Commit + PR (Conventional Commits scope `core`) — assure la traçabilité Git
4. Après merge : run `python seed_schools.py --project valide-edu` (génère `keywords[]` automatiquement via `_generate_keywords()`)
5. Vérifier dans Firebase Console que `schools/<newId>` est créé avec `isValidated: true` + `keywords` non-vide

> **Pourquoi Option B est canonique** : `schools.json` est la source de vérité versionnée. Si l'option A est utilisée sans suivi dans `schools.json`, un re-seed depuis un poste neuf (nouveau dev, CI, autre projet) effacera l'ajout fait directement en Console. Option B garantit que toute promotion est rejouable depuis Git.

### Étape 3 — Marquer la demande modérée

Une fois la décision prise (approved ou rejected), mettre à jour le doc `school_requests/{requestId}` via Firebase Console :

**Si approved** :

```text
status: "approved"
decidedBy: <ton uid admin>
decidedAt: <serverTimestamp ou date courante>
schoolIdCreated: <newId du doc schools/ créé en étape 2>
```

**Si rejected** :

```text
status: "rejected"
decidedBy: <ton uid admin>
decidedAt: <serverTimestamp ou date courante>
rejectionReason: "<explication courte, ex. 'École déjà présente sous nom X' ou 'Données incohérentes'>"
```

> Les champs `update/delete` sont **interdits côté client** par les rules Firestore — seul l'admin via Console (ou une future Cloud Function de modération) peut écrire `decidedBy/decidedAt/status/schoolIdCreated/rejectionReason`. Cela garantit qu'un utilisateur ne peut pas s'auto-modérer.

### Notes opérationnelles

- **Fréquence de check** : poll Firebase Console ~1×/semaine au lancement, ajuster selon volume. À 10k users, ~42 demandes/mois → 1×/2-3 jours.
- **Doublons** : si la même école est demandée plusieurs fois, garder 1 doc approved + marquer les autres rejected avec `rejectionReason: "Doublon de school_requests/<idRetenu>"`.
- **subSystem absent** : si l'utilisateur a coché « Je ne sais pas », l'admin doit déterminer le sous-système (recherche Wikipedia / MINESEC / site école) avant de créer le doc `schools/`.
- **Pas d'API de notification utilisateur V1** : si l'utilisateur veut connaître le statut, il devra contacter le support hors-app. Un écran « Mes demandes » mobile est différé V2.

---

## Migration users legacy (Story 1.5.d) — `migrate_user_school_denorm.py`

À lancer **1 seule fois** après le merge de Story 1.5.d, pour dénormaliser les 3 champs `schoolCity`, `schoolRegion`, `schoolName` dans `users/{uid}` pour les users legacy (créés avant Story 1.5.d via Stories 1.6/1.7) qui ont `schoolId != null` mais pas ces 3 champs cosmétiques.

### Commande

```bash
cd scripts/firebase_seed

# Dry-run d'abord (recommandé) : liste les users à migrer sans écrire.
python migrate_user_school_denorm.py --project valide-edu --dry-run

# Migration réelle.
python migrate_user_school_denorm.py --project valide-edu
```

### Comportement

Pour chaque user avec `schoolId != null` :
1. Si `schoolCity` déjà renseigné → **skip** (idempotence : la migration a déjà été faite ou Story 1.5.d a écrit les 4 champs directement à la liaison).
2. Sinon : fetch `schools/{schoolId}` (lookup par ID auto-indexé), puis `set(merge=True)` sur `{schoolCity, schoolRegion, schoolName, updatedAt}`.
3. Si le `schoolId` du user pointe vers une école **absente** (cas rare : doc `schools/` supprimé manuellement par admin) → log `[WARN]` + skip (l'admin doit traiter manuellement le user via Firebase Console).

### Idempotence + rejouabilité

Le script est **idempotent** : re-run sur un projet déjà migré → 0 nouvelle écriture (tous les users sont détectés `already_done`). Safe à re-lancer si interruption réseau ou besoin de vérifier l'état.

### Edge case — école supprimée manuellement

Si un user a `schoolId: "school_x"` mais `schools/school_x` n'existe plus, le script affiche :

```text
[WARN] user uid_xx... references schoolId='school_x' which does not exist in schools/ -> skip
```

Action manuelle admin pour ces users : ouvrir Firebase Console > `users/<uid>` et soit (a) repositionner `schoolId` sur une école valide, soit (b) le passer à `null` (les 4 champs deviennent null cohérents lors de la prochaine `updateLinkedSchool(null)` depuis l'app).

### Sortie attendue

```text
[OK] Auth: Application Default Credentials, projectId=valide-edu

[OK] Migration terminee en 1.23 s.
  scanned                 : 152
  migrated                : 47
  already_done (idempot.) : 95
  no_school_id            : 8
  skipped_missing_school  : 2
```

> **Important** : ne **PAS** lancer ce script avant le merge de Story 1.5.d. Les users actifs entre-temps écrivent déjà les 4 champs cohérents via l'app (`updateLinkedSchool` depuis `school_picker_page`) ; le script ne migre que les users legacy antérieurs au refactor.

---

## content_demo.json — Données démo contenu pédagogique (Story 2.1)

Fichier JSON versionné qui contient les données démo du contenu pédagogique Valide School (3 collections Firestore). Lu par `seed_content.py` (Story 2.1) au seed initial et après chaque évolution du contenu démo.

**Schéma Firestore** : [`doc/partage/BASE-DE-DONNEES.md § chapters/lessons/notions`](../../../doc/partage/BASE-DE-DONNEES.md)
**Story d'origine** : [2-1-schema-seed-content.md](../../../project_manage/implementation-artifacts/2-1-schema-seed-content.md)

### Structure JSON — content_demo.json

```jsonc
{
  "version": "1.0.0",
  "generatedAt": "YYYY-MM-DD",
  "comment": "Note humaine sur le contenu",
  "subjects": [
    {
      "subjectId": "francophone_math",   // ref → subjects/{id} (collection catalogue)
      "chapters": [ /* N ChapterEntry */ ]
    }
  ]
}
```

### Conventions IDs — content_demo.json

| Niveau | Pattern | Exemple |
| --- | --- | --- |
| Chapter | `{subSystem_short}_{subject_short}_ch{nn}` | `franco_math_ch01` |
| Lesson | `{chapter_id}_l{nn}` | `franco_math_ch01_l01` |
| Notion | `{lesson_id}_n{nn}` | `franco_math_ch01_l01_n01` |

### Schéma des entrées JSON

#### `subjects[i].chapters[j]` — ChapterEntry

```jsonc
{
  "chapterId": "franco_math_ch01",          // = doc ID Firestore
  "order": 1,                               // int >= 1, strictement croissant dans la matière
  "title": { "fr": "...", "en": "..." },    // bilingue obligatoire
  "description": { "fr": "...", "en": "..." } | null,
  "lessons": [ /* LessonEntry[] */ ]
}
```

#### `subjects[i].chapters[j].lessons[k]` — LessonEntry

```jsonc
{
  "lessonId": "franco_math_ch01_l01",
  "order": 1,
  "title": { "fr": "...", "en": "..." },
  "content": { "fr": "Markdown FR...", "en": "Markdown EN..." },  // bilingue, LaTeX ($...$) OK
  "notions": [ /* NotionEntry[] */ ]
}
```

#### `subjects[i].chapters[j].lessons[k].notions[l]` — NotionEntry

```jsonc
{
  "notionId": "franco_math_ch01_l01_n01",
  "order": 1,
  "title": { "fr": "...", "en": "..." }
}
```

### Volumétrie V1 (données démo Story 2.1)

| subjectId | Matière | Chapitres | Leçons | Notions |
| --- | --- | --- | --- | --- |
| `francophone_math` | Mathématiques Tle D (francophone) | 4 | 8 | 16 |
| `anglophone_physics` | Physics Upper Sixth (anglophone) | 4 | 8 | 16 |
| **Total** | | **8** | **16** | **32** |

### Évolution du contenu démo

1. Éditer `data/content_demo.json` (ajouter chapter/lesson/notion, corriger contenu)
2. `python ../seed_content.py --project valide-edu --dry-run` pour validation + comptage
3. Si OK : `python ../seed_content.py --project valide-edu`
4. Commit `data/content_demo.json` (Conventional Commits scope `content`)

> **Note** : le script valide automatiquement que tous les `subjectId` référencés existent dans la collection Firestore `subjects`. Si vous ajoutez un nouveau `subjectId`, exécuter `seed_catalogue.py` en premier.
