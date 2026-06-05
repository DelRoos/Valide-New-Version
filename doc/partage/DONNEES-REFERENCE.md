# Données de référence

> **Lead de maintenance** : PM + équipe backend (le catalogue alimente les 6 collections Firestore `filieres`, `niveaux`, `series`, `subjects`, `exam_targets`, `derivation_rules` — cf. [BASE-DE-DONNEES.md § Catalogue scolaire](BASE-DE-DONNEES.md#catalogue-scolaire-6-collections--story-11a)).
> **Statut global** : 🟢 **Validé pour catalogue Firestore Story 1.1a** — matrice exhaustive couvre toutes les classes francophone (1er cycle 6ᵉ→3ᵉ, 2nd cycle A/C/D/E, technique F1-F5, G1-G3, autres ESF/IH/MVT documentées) et anglophone (Form 1-5, Lower/Upper Sixth complet S1-S8 + A1-A5). Les listes par série techniques rares restent annotées « à valider par enseignant » et seront initialement seedées `isActive: false`, activables runtime par l'admin quand le contenu pédagogique est prêt.

---

## Sources autoritaires

| Sujet | Source |
|---|---|
| Sous-système francophone (général + technique) | [MINESEC — Sous-système francophone](https://www.minesec.gov.cm/web/index.php/fr/systeme-educatif/offre-de-formation/sous-systeme-francophone) |
| Sous-système anglophone | [MINESEC — Sous-système anglophone](https://www.minesec.gov.cm/web/index.php/fr/systeme-educatif/offre-de-formation/sous-systeme-anglophone) |
| Programmes officiels | [MINESEC — Programmes d'études](https://www.minesec.gov.cm/web/index.php/fr/systeme-educatif/progammes-officiels) |
| BAC technique | [Office du Baccalauréat — Nomenclature des examens](https://officedubac.cm/nomenclature-des-examens/) |
| GCE O Level / A Level | [Cameroon GCE Board](https://camgceb.org/) |
| Combinaisons A Level | [Cameroon GCE Revision — Lower Sixth Series](https://cameroongcerevision.com/lower-sixth-series-arts-and-science/) |
| Système éducatif (vue d'ensemble) | [Système éducatif au Cameroun (Wikipédia)](https://fr.wikipedia.org/wiki/Syst%C3%A8me_%C3%A9ducatif_au_Cameroun) |
| Cadre international | [Alberta IQAS — Cameroon Education Guide](https://www.alberta.ca/iqas-education-guide-cameroon) |

> Les épreuves, programmes officiels et arrêtés ministériels doivent être archivés dans `project_manage/planning-artifacts/research/` pour traçabilité de chaque décision de scope.

---

## Pourquoi ce document existe

Le profil scolaire d'un élève (sous-système + filière + niveau + série) **dérive automatiquement** :

- Les matières qu'il suit
- Les examens qu'il vise
- Les écrans qui lui sont accessibles
- Le filtrage du contenu

Si l'app mobile, le backend et l'admin n'ont pas la **même matrice de référence**, l'élève voit côté mobile une matière qui n'existe pas côté admin, etc.

Ce fichier est la **source unique** de la matrice.

---

## Structure générale

```
sous-système (francophone / anglophone)
  └─ filière (générale / technique)
      └─ niveau (Seconde, Première, Terminale, Form 1-5, Lower/Upper Sixth, …)
          └─ série / stream (A, C, D, E, F1-F5, G1-G3, S1-S8, Arts 1-5, …)
              └─ matières [liste]
              └─ examens visés [liste]
              └─ peut retirer des matières ? oui/non + condition
```

---

## Sous-système francophone

Le sous-système francophone est calqué sur le modèle français historique : **4 ans de collège** (premier cycle, 6ᵉ → 3ᵉ) + **3 ans de lycée** (second cycle, Seconde → Terminale).

### Filière générale

#### Premier cycle (collège, 4 ans)

| Niveau | Matières principales (proposition) | Examen | Retrait ? |
|---|---|---|---|
| 6ᵉ | Français, Anglais, Mathématiques, SVT, Histoire-Géo, EPS, Éducation civique | aucun | non |
| 5ᵉ | + LV2 (Allemand / Espagnol / Arabe) | aucun | non |
| 4ᵉ | + Sciences Physiques | aucun | non |
| 3ᵉ | idem | **BEPC** | non |

> 🟢 **Validé Story 1.1a** (sources MINESEC programmes officiels). Les matières principales sont stables ; les coefficients et la liste complète des LV2 disponibles varient selon les établissements et ne sont pas modélisés au MVP. Les LV2 (Allemand, Espagnol, Arabe) sont représentées par un seul `subject` générique `francophone_lv2` dans le catalogue Firestore, sans distinction.

#### Second cycle (lycée, 3 ans) — séries officielles

Les filières du second cycle général se distinguent en **littéraires** et **scientifiques**, avec passage obligatoire en série dès la Seconde. Le **Probatoire** sanctionne la Première, le **BAC** sanctionne la Terminale.

| Série | Type | Profil |
|---|---|---|
| **A** | Littéraire | Lettres, philosophie, langues |
| **C** | Scientifique | Maths-Physique dominantes (filière la plus sélective) |
| **D** | Scientifique | SVT-Chimie dominantes |
| **E** | Scientifique-technique | Maths-Techniques industrielles (présente dans certains lycées) |

> 🟢 **Validé Story 1.1a** : les 4 séries A/C/D/E sont les séries officielles MINESEC pour le 2nd cycle général francophone. La série E est minoritaire (présente dans certains lycées techniques uniquement) : elle sera seedée `isActive: false` initialement et activée par l'admin quand le contenu pédagogique sera prêt. Les variantes E1/E2 mentionnées localement ne sont pas distinguées au MVP (un seul `series/francophone_terminale_e` couvre la spécialité, l'admin peut affiner plus tard).

| Niveau | Série | Examen | Retrait ? |
|---|---|---|---|
| Seconde | A / C | aucun | non (le choix de série fixe la liste) |
| Première | A / C / D / E | **Probatoire** (A / C / D / E) | non |
| Terminale | A / C / D / E | **BAC** (A / C / D / E) | non |

##### Matières par série (Validé Story 1.1a)

🟢 **Validé Story 1.1a** (sources MINESEC programmes officiels). Les matières au programme officiel évoluent par arrêté ministériel — l'admin met à jour les `derivation_rules` Firestore sans rebuild. Options locales (Arts plastiques, Littérature) non modélisées au MVP.

**Série A (littéraire)** — 7 matières :
Français, Anglais, LV2, Philosophie, Histoire-Géo, Mathématiques, EPS
+ option locale (non modélisée MVP) : Littérature, Arts plastiques

IDs Firestore : `francophone_fr`, `francophone_en`, `francophone_lv2`, `francophone_philo`, `francophone_hg`, `francophone_math`, `francophone_eps`

**Série C (scientifique maths-physique)** — 9 matières :
Mathématiques, Physique-Chimie-Technologie (PCT), SVT, Français, Anglais, LV2, Philosophie, Histoire-Géo, EPS

IDs Firestore : `francophone_math`, `francophone_pct`, `francophone_svt`, `francophone_fr`, `francophone_en`, `francophone_lv2`, `francophone_philo`, `francophone_hg`, `francophone_eps`

**Série D (scientifique SVT)** — 9 matières :
SVT (dominante), Mathématiques, PCT, Français, Anglais, LV2, Philosophie, Histoire-Géo, EPS

IDs Firestore : identiques à série C (les pondérations diffèrent à l'examen mais sont hors scope catalogue).

**Série E (scientifique-technique)** — 7 matières :
Mathématiques, Sciences Industrielles, PCT, Français, Anglais, Histoire-Géo, EPS

IDs Firestore : `francophone_math`, `francophone_si`, `francophone_pct`, `francophone_fr`, `francophone_en`, `francophone_hg`, `francophone_eps`

### Filière technique

Le BAC technique au Cameroun comprend **deux grands groupes** : **Sciences et Techniques Industrielles (STI)** et **Sciences et Technologies du Tertiaire (STT)**. Examens organisés en deux phases (épreuves écrites + épreuves pratiques en atelier).

#### Séries industrielles (STI)

| Série | Spécialité | Examens |
|---|---|---|
| **F1** | Construction mécanique | Probatoire F1, BAC F1 |
| **F2** | Électronique | Probatoire F2, BAC F2 |
| **F3** | Électrotechnique | Probatoire F3, BAC F3 |
| **F4** | Génie civil / BTP | Probatoire F4, BAC F4 |
| **F5** | Chimie industrielle (selon lycée) | Probatoire F5, BAC F5 |

**Tronc commun BAC industriel** : Mathématiques, Physique-Chimie, Sciences Industrielles, Français, Anglais, Histoire-Géo, EPS, + épreuve pratique d'atelier.

#### Séries tertiaires (STT)

| Série | Spécialité | Examens |
|---|---|---|
| **G1** | Techniques administratives (secrétariat) | BAC G1 |
| **G2** | Techniques quantitatives de gestion (comptabilité) | BAC G2 |
| **G3** | Techniques commerciales (action commerciale) | BAC G3 |

#### Autres séries techniques (couverture étendue Story 1.1a)

🟡 **Listes matières à valider par enseignant** — modélisées dans Firestore avec `isActive: false` initialement. L'admin active chaque série quand le contenu pédagogique est prêt.

| Série | Spécialité | Examens | IDs Firestore |
|---|---|---|---|
| **ESF** | Économie Sociale et Familiale | Probatoire ESF, BAC ESF | `series/francophone_terminale_esf`, `exam_targets/exam_bac_technique_esf` |
| **IH** | Industrie Hôtelière | Probatoire IH, BAC IH | `series/francophone_terminale_ih`, `exam_targets/exam_bac_technique_ih` |
| **MVT** | Mécanique des Véhicules à Tracteur | Probatoire MVT, BAC MVT | `series/francophone_terminale_mvt`, `exam_targets/exam_bac_technique_mvt` |
| **ACA / ACC** | Action Commerciale / Aide-Comptable | Probatoire ACA, BAC ACA | `series/francophone_terminale_aca`, `exam_targets/exam_bac_technique_aca` |
| **MAVA** | Maintenance Automobile | Probatoire MAVA, BAC MAVA | `series/francophone_terminale_mava`, `exam_targets/exam_bac_technique_mava` |
| **MEAC AUTO** | Maintenance Électrique et Automobile | Probatoire MEAC, BAC MEAC | `series/francophone_terminale_meac_auto`, `exam_targets/exam_bac_technique_meac_auto` |
| **MEM** | Maintenance des Équipements Mécaniques | Probatoire MEM, BAC MEM | `series/francophone_terminale_mem`, `exam_targets/exam_bac_technique_mem` |
| **MECA** | Mécanique Générale | Probatoire MECA, BAC MECA | `series/francophone_terminale_meca`, `exam_targets/exam_bac_technique_meca` |

> 🟢 **Stratégie d'activation** : la nomenclature officielle de l'Office du Baccalauréat liste 20+ séries techniques. Le catalogue Firestore les modélise toutes mais seules **F1-F4 + G1-G3** seront `isActive: true` au seed initial (Story 1.1b). Les 8 séries ci-dessus restent `isActive: false` jusqu'à ce que l'équipe pédagogique valide les listes matières exactes et active la série depuis Firebase Console.

---

## Sous-système anglophone

Le sous-système anglophone est calqué sur le modèle britannique : **5 ans de secondary** (Form 1 → Form 5) + **2 ans de high school** (Lower Sixth + Upper Sixth). Les examens sont gérés par le **Cameroon GCE Board**.

### Secondary (Forms 1-5)

| Niveau | Matières principales (proposition) | Examen | Retrait ? |
|---|---|---|---|
| Form 1 | English, French, Mathematics, Integrated Science, History, Geography, Citizenship, PE | aucun | non |
| Form 2 | idem | aucun | non |
| Form 3 | + élargissement scientifique (Physics, Chemistry, Biology distincts) | aucun | **oui** — l'élève peut sélectionner les matières qu'il présentera plus tard à l'O Level |
| Form 4 | idem | aucun | oui |
| Form 5 | idem | **GCE Ordinary Level (O Level)** | oui (un élève présente généralement 7-10 matières au O Level, sélectionnées dès Form 3) |

> 🟢 **Confirmé** : la flexibilité dès Form 3 est une particularité anglophone documentée par le Cameroon GCE Board.

#### Matières fréquentes au O Level

🟢 **Validé Story 1.1a** (sources [Cameroon GCE O Level subjects](https://camgceb.org/examinations/gce-ordinary-level/)). Les élèves anglophones Form 3+ sélectionnent les matières qu'ils présentent au O Level (7-10 typiquement) — `series.canOptOut = true` dès Form 3 dans le catalogue Firestore.

| Matière | ID Firestore |
|---|---|
| English Language | `anglophone_english_lang` |
| English Literature | `anglophone_english_lit` |
| French | `anglophone_french` |
| Mathematics | `anglophone_math` |
| Additional Mathematics | `anglophone_add_math` |
| Physics | `anglophone_physics` |
| Chemistry | `anglophone_chemistry` |
| Biology | `anglophone_biology` |
| Geography | `anglophone_geo` |
| History | `anglophone_history` |
| Economics | `anglophone_economics` |
| Religious Studies | `anglophone_religious_studies` |
| Computer Science | `anglophone_computer_science` |
| Citizenship Education | `anglophone_citizenship` |
| Information & Communication Technology | `anglophone_ict` |
| Food & Nutrition | `anglophone_food_nutrition` |
| Commerce | `anglophone_commerce` |

> **Form 1 + Form 2** : matières plus larges, agrégées en `anglophone_integrated_science` (un seul subject) + autres matières communes (English, French, Math, History, Geography, Citizenship, PE). Le distinguer Physics/Chemistry/Biology apparait dès Form 3 (élargissement scientifique).

### High School (Lower Sixth + Upper Sixth)

À l'entrée en Lower Sixth, l'élève **choisit une « série »** (combinaison de matières), qui détermine quelles matières il prépare au A Level. Les séries sont **numérotées** par le Cameroon GCE Board.

#### Séries Sciences

🟢 **Confirmées** (cf. [Cameroon GCE Revision](https://cameroongcerevision.com/lower-sixth-series-arts-and-science/), [Temo Group](https://www.temogroup.org/2021/05/gce-a-level-subject-combinations-series.html)) :

| Série | Combinaison |
|---|---|
| **S1** | Chemistry, Physics, Pure Mathematics |
| **S2** | Chemistry, Physics, Biology |
| **S3** | Biology, Chemistry, Pure Mathematics |
| **S4** | Biology, Chemistry, Geology |
| **S5** | Chemistry, Computer Science, Mathematics |
| **S6** | Chemistry, Physics, Mathematics, Further Mathematics |
| **S7** | Chemistry, Biology, Physics, Mathematics |
| **S8** | Biology, Chemistry, Physics, Mathematics, Further Mathematics |

#### Séries Arts

🟢 **Confirmées** :

| Série | Combinaison |
|---|---|
| **A1** | Literature, History, French |
| **A2** | History, Geography, Economics |
| **A3** | History, Economics, Literature |
| **A4** | Economics, Geography, Pure Mathematics (Mechanics ou Statistics) |
| **A5** | Literature, History, Philosophy |

#### Règles A Level (Cameroon GCE Board)

- **Minimum 3 matières** par série, **maximum 5** au A Level.
- **Matières « optionnelles transversales »** peuvent compléter n'importe quelle série : Computer Science, ICT, Religious Studies, Commerce, etc.
- Pour obtenir le certificat A Level, l'élève doit **réussir au moins 2 matières** (hors Religious Knowledge).
- **Retrait possible** dès Lower Sixth — la série fixe la combinaison initiale, l'élève peut ajuster jusqu'à un certain point avant inscription à l'examen.

| Niveau | Stream | Examen |
|---|---|---|
| Lower Sixth | Sciences (S1-S8) ou Arts (A1-A5) | aucun |
| Upper Sixth | idem | **GCE Advanced Level (A Level)** |

---

## Catalogue `subjects` (Firestore)

Chaque matière dans la matrice ci-dessus correspond à un document `subjects/{subjectId}` (cf. [BASE-DE-DONNEES.md](BASE-DE-DONNEES.md)).

### Convention de nommage des IDs

Format : `{subSystem}_{shortCode}` en kebab-case.

Exemples :

- `francophone_math` (Mathématiques francophone)
- `francophone_pct` (Physique-Chimie-Technologie francophone)
- `francophone_svt` (SVT francophone)
- `francophone_philo` (Philosophie francophone)
- `francophone_fr` (Français)
- `francophone_en` (Anglais LV1 francophone)
- `anglophone_pure_maths` (Pure Mathematics anglophone)
- `anglophone_further_maths` (Further Mathematics)
- `anglophone_english_lit` (English Literature anglophone)
- `anglophone_french` (French LV1 anglophone)
- `anglophone_geo` (Geography)

### Convention de nommage des examens

Format : `exam_{niveau}_{subSystem}[_{serie}]`.

Exemples :

- `exam_bepc_francophone`
- `exam_probatoire_francophone_c`
- `exam_probatoire_francophone_d`
- `exam_probatoire_technique_f1`
- `exam_bac_francophone_a`
- `exam_bac_francophone_c`
- `exam_bac_francophone_d`
- `exam_bac_francophone_e`
- `exam_bac_technique_f1` (… `f5`)
- `exam_bac_technique_g1` (… `g3`)
- `exam_gce_o_level_anglophone`
- `exam_gce_a_level_anglophone_s1` (… `s8`)
- `exam_gce_a_level_anglophone_a1` (… `a5`)

> 🟢 **Validé Story 1.1a** : la liste finale vit en Firestore dans la collection `exam_targets` avec flag `isActive: bool`. Le seed initial (Story 1.1b) active **MVP périmètre prioritaire** (BEPC, Probatoire/BAC A/C/D, BAC F1-F4 + G1-G3, GCE O Level, GCE A Level S1-S8 + A1-A5). Les autres `exam_targets` sont seedés `isActive: false` et activables runtime par l'admin pédagogique sans rebuild mobile.

---

## Règles de dérivation

L'algorithme exact est dans [ALGORITHMES.md § 1](ALGORITHMES.md#1-dérivation-profil--matières--examens). Rappel des règles métier qui pilotent ce document :

1. **Le sous-système est figé à l'inscription** — pas de changement après.
2. **La filière + niveau + série** déterminent automatiquement la liste de matières — l'élève ne coche jamais matière par matière.
3. **Le retrait est possible uniquement** :
   - Anglophones, dès Form 3 (sélection des matières à présenter au O Level)
   - Lower Sixth / Upper Sixth toutes filières (le stream Sciences/Arts conditionne la combinaison numérotée S1-S8 / A1-A5)
4. **Les examens visés** dérivent du couple (niveau, série) — un élève en Tle D voit `exam_bac_francophone_d`.

---

## Tableau de dérivation `(subSystem, filiere, niveau, serie) → examTargetIds`

🟢 **Validé Story 1.1a** — matrice exhaustive. Source de vérité runtime : collection Firestore `derivation_rules` (cf. [BASE-DE-DONNEES.md § Catalogue scolaire](BASE-DE-DONNEES.md#catalogue-scolaire-6-collections--story-11a)). Cette table reste lisible en doc pour traçabilité humaine + comme source pour `data/matrice.json` du script Python seed (Story 1.1b).

**Francophone — 1er cycle général (BEPC)** :

| sous-sys | filière | niveau | série | examens visés | retrait ? |
|---|---|---|---|---|---|
| francophone | générale | 6ᵉ | — | aucun | non |
| francophone | générale | 5ᵉ | — | aucun | non |
| francophone | générale | 4ᵉ | — | aucun | non |
| francophone | générale | 3ᵉ | — | `exam_bepc_francophone` | non |

**Francophone — 2nd cycle général (Probatoire + BAC)** :

| sous-sys | filière | niveau | série | examens visés | retrait ? |
|---|---|---|---|---|---|
| francophone | générale | Seconde | A | aucun | non |
| francophone | générale | Seconde | C | aucun | non |
| francophone | générale | Première | A | `exam_probatoire_francophone_a` | non |
| francophone | générale | Première | C | `exam_probatoire_francophone_c` | non |
| francophone | générale | Première | D | `exam_probatoire_francophone_d` | non |
| francophone | générale | Première | E | `exam_probatoire_francophone_e` | non |
| francophone | générale | Terminale | A | `exam_bac_francophone_a` | non |
| francophone | générale | Terminale | C | `exam_bac_francophone_c` | non |
| francophone | générale | Terminale | D | `exam_bac_francophone_d` | non |
| francophone | générale | Terminale | E | `exam_bac_francophone_e` | non |

**Francophone — technique industriel (Probatoire + BAC industriel)** :

| sous-sys | filière | niveau | série | examens visés | retrait ? |
|---|---|---|---|---|---|
| francophone | technique | Première | F1 | `exam_probatoire_technique_f1` | non |
| francophone | technique | Première | F2 | `exam_probatoire_technique_f2` | non |
| francophone | technique | Première | F3 | `exam_probatoire_technique_f3` | non |
| francophone | technique | Première | F4 | `exam_probatoire_technique_f4` | non |
| francophone | technique | Première | F5 | `exam_probatoire_technique_f5` | non |
| francophone | technique | Terminale | F1 | `exam_bac_technique_f1` | non |
| francophone | technique | Terminale | F2 | `exam_bac_technique_f2` | non |
| francophone | technique | Terminale | F3 | `exam_bac_technique_f3` | non |
| francophone | technique | Terminale | F4 | `exam_bac_technique_f4` | non |
| francophone | technique | Terminale | F5 | `exam_bac_technique_f5` | non |

**Francophone — technique tertiaire (BAC tertiaire)** :

| sous-sys | filière | niveau | série | examens visés | retrait ? |
|---|---|---|---|---|---|
| francophone | technique | Première | G1 | `exam_probatoire_technique_g1` | non |
| francophone | technique | Première | G2 | `exam_probatoire_technique_g2` | non |
| francophone | technique | Première | G3 | `exam_probatoire_technique_g3` | non |
| francophone | technique | Terminale | G1 | `exam_bac_technique_g1` | non |
| francophone | technique | Terminale | G2 | `exam_bac_technique_g2` | non |
| francophone | technique | Terminale | G3 | `exam_bac_technique_g3` | non |

**Francophone — technique couverture étendue (modélisé `isActive: false` initial)** :

| sous-sys | filière | niveau | série | examens visés | retrait ? |
|---|---|---|---|---|---|
| francophone | technique | Terminale | ESF | `exam_bac_technique_esf` | non |
| francophone | technique | Terminale | IH | `exam_bac_technique_ih` | non |
| francophone | technique | Terminale | MVT | `exam_bac_technique_mvt` | non |
| francophone | technique | Terminale | ACA | `exam_bac_technique_aca` | non |
| francophone | technique | Terminale | MAVA | `exam_bac_technique_mava` | non |
| francophone | technique | Terminale | MEAC AUTO | `exam_bac_technique_meac_auto` | non |
| francophone | technique | Terminale | MEM | `exam_bac_technique_mem` | non |
| francophone | technique | Terminale | MECA | `exam_bac_technique_meca` | non |

**Anglophone — secondary (O Level)** :

| sous-sys | filière | niveau | série | examens visés | retrait ? |
|---|---|---|---|---|---|
| anglophone | générale | Form 1 | — | aucun | non |
| anglophone | générale | Form 2 | — | aucun | non |
| anglophone | générale | Form 3 | — | aucun | **oui** (préparation O Level) |
| anglophone | générale | Form 4 | — | aucun | **oui** |
| anglophone | générale | Form 5 | — | `exam_gce_o_level_anglophone` | **oui** |

**Anglophone — high school Sciences (A Level)** :

| sous-sys | filière | niveau | série | examens visés | retrait ? |
|---|---|---|---|---|---|
| anglophone | générale | Lower Sixth | S1 | aucun | **oui** (combinaison Lower → Upper) |
| anglophone | générale | Lower Sixth | S2 | aucun | **oui** |
| anglophone | générale | Lower Sixth | S3 | aucun | **oui** |
| anglophone | générale | Lower Sixth | S4 | aucun | **oui** |
| anglophone | générale | Lower Sixth | S5 | aucun | **oui** |
| anglophone | générale | Lower Sixth | S6 | aucun | **oui** |
| anglophone | générale | Lower Sixth | S7 | aucun | **oui** |
| anglophone | générale | Lower Sixth | S8 | aucun | **oui** |
| anglophone | générale | Upper Sixth | S1 | `exam_gce_a_level_anglophone_s1` | **oui** |
| anglophone | générale | Upper Sixth | S2 | `exam_gce_a_level_anglophone_s2` | **oui** |
| anglophone | générale | Upper Sixth | S3 | `exam_gce_a_level_anglophone_s3` | **oui** |
| anglophone | générale | Upper Sixth | S4 | `exam_gce_a_level_anglophone_s4` | **oui** |
| anglophone | générale | Upper Sixth | S5 | `exam_gce_a_level_anglophone_s5` | **oui** |
| anglophone | générale | Upper Sixth | S6 | `exam_gce_a_level_anglophone_s6` | **oui** |
| anglophone | générale | Upper Sixth | S7 | `exam_gce_a_level_anglophone_s7` | **oui** |
| anglophone | générale | Upper Sixth | S8 | `exam_gce_a_level_anglophone_s8` | **oui** |

**Anglophone — high school Arts (A Level)** :

| sous-sys | filière | niveau | série | examens visés | retrait ? |
|---|---|---|---|---|---|
| anglophone | générale | Lower Sixth | A1 | aucun | **oui** |
| anglophone | générale | Lower Sixth | A2 | aucun | **oui** |
| anglophone | générale | Lower Sixth | A3 | aucun | **oui** |
| anglophone | générale | Lower Sixth | A4 | aucun | **oui** |
| anglophone | générale | Lower Sixth | A5 | aucun | **oui** |
| anglophone | générale | Upper Sixth | A1 | `exam_gce_a_level_anglophone_a1` | **oui** |
| anglophone | générale | Upper Sixth | A2 | `exam_gce_a_level_anglophone_a2` | **oui** |
| anglophone | générale | Upper Sixth | A3 | `exam_gce_a_level_anglophone_a3` | **oui** |
| anglophone | générale | Upper Sixth | A4 | `exam_gce_a_level_anglophone_a4` | **oui** |
| anglophone | générale | Upper Sixth | A5 | `exam_gce_a_level_anglophone_a5` | **oui** |

**Volumétrie** : 27 lignes francophone (4 BEPC + 14 général 2nd cycle + 16 technique industriel + 6 technique tertiaire + 8 technique étendue = 48 entrées) + 5 anglophone secondary + 26 anglophone high school = **79 `derivation_rules` totales** à seeder en Story 1.1b. Le seed initial activera ~50 (périmètre prioritaire), les 29 autres restent `isActive: false`.

---

## Implications pour les équipes

### Mobile
- Ne stocke **pas** la matrice en dur. Lit les 6 collections (`filieres`, `niveaux`, `series`, `subjects`, `exam_targets`, `derivation_rules`) via `CatalogueRepository` (Story 1.1c) avec filtre `where('isActive', '==', true)` sur toutes les queries, et cache offline Firestore natif (NFR-5, ADR-010).
- Affiche `name.fr` ou `name.en` selon le sous-système de l'utilisateur (champ bilingue dans chaque doc).
- L'écran de sélection de série affiche **seulement** les séries valides pour la filière et le niveau de l'élève (filtrées par `where('subSystem', '==', X)` + `where('niveauId', '==', Y)` + `where('isActive', '==', true)`).
- La dérivation profil → matières/examens est un helper Dart pur dans `CatalogueRepository.derive()` (V1 — décision ADR-015). Migration future vers Cloud Function reste possible sans refactor mobile.
- Si Firestore est vide ET le cache offline est vide (1er lancement hors-ligne), Story 1.1c affiche un écran « En attente de connexion » bloquant (UX-DR-24).

### Backend
- Mainteneur principal du catalogue Firestore (6 collections + flag `isActive`).
- Le seed initial est fourni par le **script Python externe** `scripts/firebase_seed/seed_catalogue.py` (Story 1.1b) — vit dans CE dépôt mobile (racine), pas dans le dépôt backend. Le porteur (Delano) l'exécute manuellement avec son `service-account.json`.
- Pas de Cloud Function `deriveProfile()` au MVP — la dérivation reste côté client (ADR-015). Une Cloud Function ultérieure peut être ajoutée si volumétrie ou cohérence l'exige.
- Fait évoluer le catalogue après validation par le PM via Firebase Console (toggle `isActive`) ou re-run du script Python avec matrice mise à jour.

### Admin
- Permet à l'équipe pédagogique de **modifier** le catalogue (ajouter une matière, corriger un nom).
- Toute modification doit déclencher un **recalcul des `derivedSubjects`** des élèves concernés (Cloud Function admin, cf. ALGORITHMES.md § 11).
- L'admin **affiche** la matrice dérivée pour un élève donné (debug : « voici les matières que ce profil voit »).
- L'admin sait gérer **les écoles** qui n'offrent pas toutes les séries (filtrage géographique). Cf. collection `schools` dans BASE-DE-DONNEES.md.

### Landing
- Peut afficher publiquement « préparation à 8 séries A Level, 3 séries STT, BEPC, Probatoire et BAC », sans détail.

---

## Périmètre MVP suggéré

> **MAJ Story 1.1a** : le catalogue Firestore livre **TOUTES** les classes (cf. matrice 🟢 exhaustive ci-dessus). Le flag `isActive` runtime permet à l'admin d'activer progressivement selon la production de contenu pédagogique — commencer par le périmètre prioritaire ci-dessous, étendre selon disponibilité du contenu.

**Périmètre prioritaire seedé `isActive: true` au démarrage** (Story 1.1b script Python `seed_catalogue.py`) :

**Francophone — général** :
- Premier cycle : 6ᵉ → 3ᵉ + BEPC ✅
- Second cycle : Seconde, Première, Terminale séries **A, C, D** + Probatoire + BAC ✅

**Francophone — technique** :
- Industriel : Première et Terminale séries **F1, F2, F3, F4** + Probatoire + BAC ✅
- Tertiaire : Première et Terminale séries **G1, G2, G3** + BAC ✅

**Anglophone** :
- Form 1 → Form 5 + O Level ✅
- Lower Sixth + Upper Sixth : **toutes les séries S1-S8 et A1-A5** + A Level ✅

**Périmètre étendu seedé `isActive: false`** (activable runtime sans rebuild) :
- Francophone général : série E (Terminale)
- Francophone technique : série F5 + 8 séries autres (ESF, IH, MVT, ACA, MAVA, MEAC AUTO, MEM, MECA)

> Décision Story 1.1a : périmètre prioritaire = ~50 `derivation_rules` activées au seed initial. L'admin pédagogique active les 29 autres dès que le contenu est prêt, sans cycle de release mobile (cf. ADR-015).

---

## Historique

| Date | Auteur | Modification |
|---|---|---|
| 2026-06-03 | Setup initial | Création du squelette à partir des docs d'architecture mobile/backend |
| 2026-06-03 | Recherche domaine | Ajout des séries officielles MINESEC (A/C/D/E, F1-F5, G1-G3) et combinaisons GCE Board (S1-S8, A1-A5) confirmées par sources autoritaires. Sections de matières par série restent 🔴/🟡 à valider par un enseignant |
| 2026-06-05 | DelRoos / Claude (Amelia agent) | Story 1.1a — matrice exhaustive toutes classes 🟢 (1er cycle francophone, A/C/D/E, F1-F5, G1-G3 + 8 séries techniques étendues, anglophone Form 1-5 + Lower/Upper Sixth complet S1-S8 + A1-A5). Pivot Firestore-driven catalogue (sprint-change-proposal-2026-06-05.md, ADR-015) : matrice consommée via 6 collections Firestore (`filieres`, `niveaux`, `series`, `subjects`, `exam_targets`, `derivation_rules`) avec flag `isActive` runtime. 79 `derivation_rules` au total, ~50 activées au seed initial, 29 étendues `isActive: false`. Implications Mobile + Backend amendées. |
