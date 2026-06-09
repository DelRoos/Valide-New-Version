# Données de référence

> **Lead de maintenance** : PM + équipe backend (le catalogue alimente les 6 collections Firestore `filieres`, `niveaux`, `series`, `subjects`, `exam_targets`, `derivation_rules` — cf. [BASE-DE-DONNEES.md § Catalogue scolaire](BASE-DE-DONNEES.md#catalogue-scolaire-6-collections--story-11a)).
> **Statut global** : 🟢 **Validé v2 alignement nomenclature officielle Story 1.11a** (Office du Baccalauréat camerounais + Cameroon GCE Board) — matrice exhaustive v2 couvre toutes les classes francophone (1er cycle 6ᵉ→3ᵉ avec +4 matières officielles MINESEC ajoutées, 2nd cycle Tle générale 12 séries A1-A5/ABI/SH/AC/C/D/E/TI avec corrections C/D/E + sous-séries officielles, technique F1-F5/G1-G3/autres) et anglophone (Form 1-5 + Lower/Upper Sixth complet S1-S8 + A1-A5 + matières manquantes ajoutées : 5 O-Level codes GCE 0505/0546/0555/0565/0590 + 6 A-Level codes 0746/0790/0796/0765/0770/0740) + **sous-système ESTP anglophone TVEE complet** (TVE IL + TVE AL × 13 spécialités industrielles/commerciales/Home Economics, modèle panier polymorphe via `series.pickerMode` enum ADR-016). **Périmètre prioritaire MVP activé** au seed initial (Story 1.12) : ~50 `derivation_rules` activées (Fatou Tle D, James Upper Sixth S2, Mariam Form 5 panier O-Level, Aïssatou Tle A1 Lettres+Latin+Grec). **Périmètre étendu** ~90 `derivation_rules` seedées `isActive: false`, activables runtime par l'admin pédagogique via Firebase Console quand contenu pédagogique prêt (TVEE après validation enseignant TVEE, séries ABI/SH/AC/AI/TI selon production progressive).

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

> 🟢 **Étendu Story 1.11a** (alignement nomenclature officielle MINESEC) — ajout de **4 matières officielles premier cycle** présentes au programme MINESEC mais absentes du catalogue v1 :
>
> | ID Firestore | Matière |
> |---|---|
> | `francophone_lcn` | Langues et Cultures Nationales |
> | `francophone_info_college` | Informatique (collège — distincte de `francophone_info` Tle scientifique) |
> | `francophone_ea` | Éducation Artistique |
> | `francophone_tm` | Travail Manuel |
>
> Toutes seedées `isActive: true` par Story 1.12 (matières officielles présentes 6ᵉ → 3ᵉ).

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

**Série A (littéraire) — DEPRECATED Story 1.11a** — 7 matières :
Français, Anglais, LV2, Philosophie, Histoire-Géo, Mathématiques, EPS

⚠️ **DEPRECATED Story 1.11a, `isActive: false` post-1.12** : la nomenclature officielle MINESEC distingue les sous-séries A1, A2, A3, A4, A5, ABI, SH, AC, TI documentées ci-dessous (Story 1.11a). Conservée en v1 pour **rétrocompat profils existants** (`users/{uid}.serieId == "francophone_terminale_a"` créés avant 2026-06-09). Les nouveaux élèves Tle A choisissent la sous-série exacte parmi A1-A5/ABI/SH/AC.

IDs Firestore : `francophone_fr`, `francophone_en`, `francophone_lv2`, `francophone_philo`, `francophone_hg`, `francophone_math`, `francophone_eps`

---

**🟢 Story 1.11a — Sous-séries littéraires Tle francophone officielles (Office du Baccalauréat)** :

**Série A1 — Lettres + Latin + Grec** — 9 matières (`isActive: true` post-1.12) :
Français, Anglais, Mathématiques, Philosophie, Histoire-Géo, EPS, **Latin**, **Grec**, **LV2**

IDs Firestore : `francophone_fr`, `francophone_en`, `francophone_math`, `francophone_philo`, `francophone_hg`, `francophone_eps`, `francophone_latin`, `francophone_grec`, `francophone_lv2`

**Série A2 — Lettres + Latin + LV2** — 8 matières (`isActive: true` post-1.12) :
Français, Anglais, Mathématiques, Philosophie, Histoire-Géo, EPS, **Latin**, LV2

IDs Firestore : `francophone_fr`, `francophone_en`, `francophone_math`, `francophone_philo`, `francophone_hg`, `francophone_eps`, `francophone_latin`, `francophone_lv2`

**Série A3 — Lettres + Latin** — 7 matières (`isActive: true` post-1.12) :
Français, Anglais, Mathématiques, Philosophie, Histoire-Géo, EPS, **Latin**

IDs Firestore : `francophone_fr`, `francophone_en`, `francophone_math`, `francophone_philo`, `francophone_hg`, `francophone_eps`, `francophone_latin`

**Série A4 — Lettres + LV2 + Philo** — 7 matières (`isActive: true` post-1.12) :
Français, Anglais, Mathématiques, Philosophie, Histoire-Géo, EPS, LV2

IDs Firestore : `francophone_fr`, `francophone_en`, `francophone_math`, `francophone_philo`, `francophone_hg`, `francophone_eps`, `francophone_lv2`

**Série A5 — LV2 + LV3 + Philo** — 8 matières (`isActive: false` initial, LV3 rare) :
Français, Anglais, Mathématiques, Philosophie, Histoire-Géo, EPS, LV2, **LV3**

IDs Firestore : `francophone_fr`, `francophone_en`, `francophone_math`, `francophone_philo`, `francophone_hg`, `francophone_eps`, `francophone_lv2`, `francophone_lv3`

**Série ABI — Lettres bilingues** — 9 matières (`isActive: false` initial, option locale) :
Français + Anglais (à parité), **Littérature**, Philosophie, Histoire-Géo, Mathématiques, **Intensive English**, **Oral Communication**, **Manual Labour**

IDs Firestore : `francophone_fr`, `francophone_en`, `francophone_litterature`, `francophone_philo`, `francophone_hg`, `francophone_math`, `francophone_intensive_english`, `francophone_oral_communication`, `francophone_manual_labour`

**Série SH — Sciences Humaines** — 6 matières (`isActive: false` initial) :
Français, Anglais, Mathématiques, Philosophie, Histoire-Géo, EPS

IDs Firestore : `francophone_fr`, `francophone_en`, `francophone_math`, `francophone_philo`, `francophone_hg`, `francophone_eps`

**Série AC — Art et Cinématographie** — 6 matières (`isActive: false` initial, option marginale) :
Français, Anglais, **Arts/Cinématographie**, Philosophie, Histoire-Géo, EPS

IDs Firestore : `francophone_fr`, `francophone_en`, `francophone_arts_cinema`, `francophone_philo`, `francophone_hg`, `francophone_eps`

---

**Série C (scientifique maths-physique) — corrigée Story 1.11a** — 10 matières :
Mathématiques, **Physique**, **Chimie** (séparées de l'ex-PCT), SVT, Français, Anglais, Philosophie, Histoire-Géo, **Informatique**, EPS

⚠️ **Corrections Story 1.11a vs v1** :
- ❌ Retrait `francophone_lv2` (erronée v1 — LV2 absente du programme officiel C selon doc utilisateur 2026-06-09 § 5.5)
- ❌ Retrait `francophone_pct` (regroupé Physique+Chimie incorrect — séparer)
- ✅ Ajout `francophone_physique` + `francophone_chimie` séparés
- ✅ Ajout `francophone_info` (Informatique au programme officiel C)

IDs Firestore : `francophone_math`, `francophone_physique`, `francophone_chimie`, `francophone_svt`, `francophone_fr`, `francophone_en`, `francophone_philo`, `francophone_hg`, `francophone_info`, `francophone_eps`

**Série D (scientifique SVT) — corrigée Story 1.11a** — 11 matières :
SVT (dominante), Mathématiques, **Physique**, **Chimie**, **Environnement/Hygiène/Biotechnologie**, Français, Anglais, Philosophie, Histoire-Géo, **Informatique**, EPS

⚠️ **Corrections Story 1.11a vs v1** :
- ❌ Retrait `francophone_lv2` (erronée v1)
- ❌ Retrait `francophone_pct` (séparer)
- ✅ Ajout `francophone_physique` + `francophone_chimie` séparés
- ✅ Ajout `francophone_environnement` (Éducation à l'environnement / Hygiène / Biotechnologie — au programme officiel D selon doc utilisateur 2026-06-09 § 5.5)
- ✅ Ajout `francophone_info`

IDs Firestore : `francophone_math`, `francophone_svt`, `francophone_physique`, `francophone_chimie`, `francophone_environnement`, `francophone_fr`, `francophone_en`, `francophone_philo`, `francophone_hg`, `francophone_info`, `francophone_eps`

**Série E (scientifique-technique) — corrigée Story 1.11a** — 8 matières :
Mathématiques, **Physique**, **Chimie**, **Techniques/Technologie**, Français, **Philosophie**, Anglais, EPS

⚠️ **Corrections Story 1.11a vs v1** :
- ✅ Ajout `francophone_philo` (manquait — au programme officiel E selon doc utilisateur 2026-06-09 § 5.5)
- ✅ Renommer `francophone_si` (Sciences Industrielles) → `francophone_techno` (Techniques/Technologie) pour cohérence terminologique officielle
- ✅ Séparer Physique + Chimie (cohérence avec C/D corrigées)

IDs Firestore : `francophone_math`, `francophone_physique`, `francophone_chimie`, `francophone_techno`, `francophone_fr`, `francophone_philo`, `francophone_en`, `francophone_eps`

**Série TI — Technologie de l'Information** — 7 matières (`isActive: false` initial, lycée technique uniquement) :
Mathématiques, **Physique**, **Informatique** (algorithmique, programmation, bases de données, réseaux), Français, **Philosophie**, Anglais, EPS

IDs Firestore : `francophone_math`, `francophone_physique`, `francophone_info`, `francophone_fr`, `francophone_philo`, `francophone_en`, `francophone_eps`

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

🟢 **Étendu Story 1.11a** (alignement nomenclature officielle GCE Board — codes officiels 0505-0595 documentés par doc utilisateur 2026-06-09 § 8.1) — 5 matières manquantes ajoutées :

| Matière | Code GCE | ID Firestore |
|---|---|---|
| Accounting | 0505 | `anglophone_accounting` |
| Special Bilingual Education French | 0546 | `anglophone_special_bilingual_french` |
| Geology | 0555 | `anglophone_geology` |
| Human Biology | 0565 | `anglophone_human_biology` |
| Logic | 0590 | `anglophone_logic` |

#### Règles panier O-Level (Story 1.11a, sources Cameroon GCE Board)

Règles officielles documentées par doc utilisateur 2026-06-09 § 8.1 :

- **Minimum 6 matières** présentées, **maximum 10** (ou **11 avec Religious Studies**).
- **English Language + French + Mathematics obligatoires** (non décochables).
- Un candidat possédant déjà un *pass* dans 4+ matières O-Level peut s'inscrire à des matières supplémentaires isolées.
- Aucune limite au nombre de sessions (repeaters autorisés).

**Modélisation Firestore (impl Stories 1.12 + 1.15)** :

- `series.pickerMode: 'free_with_obligatory'` sur `anglophone_form_5` (et Form 3, Form 4 pour préparation)
- `series.minSubjects: 6`
- `series.maxSubjects: 11` (avec Religious Studies) ou `10` sinon
- `derivation_rules.obligatorySubjectIds: ['anglophone_english_lang', 'anglophone_french', 'anglophone_math']`

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

🟢 **Étendu Story 1.11a** (alignement nomenclature officielle GCE Board — codes officiels 0705-0796 documentés par doc utilisateur 2026-06-09 § 8.2) — 6 matières manquantes ajoutées :

| Matière | Code GCE | ID Firestore |
|---|---|---|
| Special Bilingual Education French (A-Level) | 0746 | `anglophone_a_special_bilingual_french` |
| Philosophy | 0790 | `anglophone_philosophy` |
| Information & Communication Technology (A-Level) | 0796 | `anglophone_ict_a_level` |
| Pure Mathematics With Mechanics | 0765 | `anglophone_pure_maths_mechanics` |
| Pure Mathematics With Statistics | 0770 | `anglophone_pure_maths_stats` |
| Food Science and Nutrition | 0740 | `anglophone_food_science_nutrition` |

**Modélisation Firestore A-Level (impl Stories 1.12 + 1.16)** :

- `series.pickerMode: 'series_plus_optional'` sur Series S1-S8 + A1-A5 (Upper Sixth)
- `series.minSubjects: 3` (Series obligatoires)
- `series.maxSubjects: 5`
- `derivation_rules.obligatorySubjectIds`: matières de la Series (ex. S2 = `['anglophone_chemistry', 'anglophone_physics', 'anglophone_biology']`)
- `derivation_rules.optionalSubjectIds: ['anglophone_computer_science', 'anglophone_ict_a_level', 'anglophone_religious_studies', 'anglophone_commerce']`

> **Note** : la série S8 dans la matrice v1 (`Biology, Chemistry, Physics, Mathematics, Further Mathematics`) est une **variante régionale**. Les sources officielles GCE Board documentent S1-S7. S8 est conservée en v2 pour **rétrocompat profils existants v1**. Cf. ADR-016 § Out of scope.

---

## Sous-système anglophone — ESTP (TVEE)

🟢 **Story 1.11a** — Le sous-système anglophone technique est administré par le Cameroon GCE Board (TVEE — Technical and Vocational Education Examinations). Deux niveaux d'examen :

- **TVE Intermediate Level (TVE IL)** — équivalent O-Level technique, fin Form 5 technique
- **TVE Advanced Level (TVE AL)** — équivalent A-Level technique, fin Upper Sixth technique

### Modélisation Firestore TVEE (ADR-016 Décision 2)

- `subSystem`: `anglophone` (même découpage linguistique que général)
- `filière`: `technique` (nouvelle valeur côté anglophone, cohérente avec `francophone/technique` v1)
- `niveau`: `anglophone_tve_il` OU `anglophone_tve_al`
- `série`: spécialité parmi 13 (industrielles + commerciales + Home Economics)

### Spécialités TVEE (13)

| Code | ID série TVE IL | ID série TVE AL | Spécialité | Famille |
|---|---|---|---|---|
| ELEQ | `anglophone_tve_il_eleq` | `anglophone_tve_al_eleq` | Electrical Equipment | Industrial |
| ELNI | `anglophone_tve_il_elni` | `anglophone_tve_al_elni` | Electronics | Industrial |
| ELME | `anglophone_tve_il_elme` | `anglophone_tve_al_elme` | Electromechanical | Industrial |
| ELET | `anglophone_tve_il_elet` | `anglophone_tve_al_elet` | Electrotechnique | Industrial |
| AC | `anglophone_tve_il_ac` | `anglophone_tve_al_ac` | Air Conditioning & Refrigeration Technology | Industrial |
| ME | `anglophone_tve_il_me` | `anglophone_tve_al_me` | Mechanical Engineering | Industrial |
| CE | `anglophone_tve_il_ce` | `anglophone_tve_al_ce` | Civil Engineering / Building Construction | Industrial |
| WW | `anglophone_tve_il_woodwork` | `anglophone_tve_al_woodwork` | Woodwork / Carpentry | Industrial |
| ACC | `anglophone_tve_il_acc` | `anglophone_tve_al_acc` | Accounting (commercial) | Commercial |
| COM | `anglophone_tve_il_commerce` | `anglophone_tve_al_commerce` | Commerce | Commercial |
| OP | `anglophone_tve_il_op` | `anglophone_tve_al_op` | Office Practice | Commercial |
| FN | `anglophone_tve_il_food_nutrition` | `anglophone_tve_al_food_nutrition` | Food and Nutrition | Home Economics |
| CT | `anglophone_tve_il_clothing_textiles` | `anglophone_tve_al_clothing_textiles` | Clothing & Textiles | Home Economics |

### Règles panier TVEE (sources Cameroon GCE Board, doc utilisateur 2026-06-09 § 9)

**TVE Intermediate Level (TVE IL)** :

- Minimum **5 matières** réussies (sur 11 maximum présentées)
- Dont **≥ 2 Professional Subjects** + **≥ 1 Related Professional Subject**
- **English Language + French obligatoires** (au programme général)
- Les Professional + Related Professional sont tous obligatoires (présentation). Le module *Other Subjects* permet d'ajouter 2-3 matières au choix.

**TVE Advanced Level (TVE AL)** :

- Minimum **6**, maximum **8 matières** présentées
- Dont **≥ 3 Professional Subjects** + **≥ 3 Related Professional Subjects**
- **English Language + French obligatoires**
- Pas de module Other Subjects libre — choix limité aux Professional + Related selon spécialité

### Modélisation Firestore mode `tve_picker` (impl Stories 1.12 + 1.17)

```typescript
// series/{anglophone_tve_il_elet} ou similaire
{
  serieId: "anglophone_tve_il_elet",
  subSystem: "anglophone",
  filiereId: "technique",
  niveauId: "anglophone_tve_il",
  name: { fr: "Electrotechnique (TVE IL)", en: "Electrotechnique (TVE IL)" },
  canOptOut: false,
  isActive: false,                       // initial : activable post-validation enseignant TVEE
  sortOrder: 100,
  pickerMode: "tve_picker",
  minSubjects: 5,
  maxSubjects: 11,
  professionalSubjectIds: [              // tous obligatoires
    "anglophone_tve_electrotechnique_theory",
    "anglophone_tve_electrotechnique_practical"
  ],
  relatedProfessionalSubjectIds: [       // au moins 1 obligatoire en TVE IL
    "anglophone_tve_math_industrial",
    "anglophone_tve_physics",
    "anglophone_tve_drawing"
  ],
  otherSubjectIds: [                     // 2-3 libres au choix
    "anglophone_tve_history",
    "anglophone_tve_geography",
    "anglophone_tve_economics",
    "anglophone_tve_religious_studies"
  ]
}

// derivation_rules pour TVE IL Electrotechnique
{
  ruleId: "rule_anglophone_technique_anglophone_tve_il_anglophone_tve_il_elet",
  matchSubSystem: "anglophone",
  matchFiliere: "technique",
  matchNiveau: "anglophone_tve_il",
  matchSerie: "anglophone_tve_il_elet",
  subjectIds: [                          // toutes les matières disponibles
    /* Professional + Related + Other + English + French */
  ],
  examTargetIds: ["exam_tve_il_anglophone_elet"],
  canOptOut: false,
  isActive: false,
  obligatorySubjectIds: [                // EN + FR + Professional + Related obligatoires
    "anglophone_tve_english",
    "anglophone_tve_french",
    "anglophone_tve_electrotechnique_theory",
    "anglophone_tve_electrotechnique_practical",
    "anglophone_tve_math_industrial"     // ≥1 Related en TVE IL
  ]
}
```

### Statut activation initial Story 1.12

Toutes les **26 séries TVEE** (13 × 2 niveaux) sont seedées `isActive: false` initialement. Activation runtime par l'admin pédagogique via Firebase Console **après validation par enseignant TVEE camerophone** (Mr Eboa Joseph, Lycée Technique Bonabéri — action porteur post-merge Story 1.17). Les listes exactes de matières par spécialité sont préliminaires et seront ajustées en 1.17 selon validation enseignant.

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
| francophone | générale | Terminale | A1 | `exam_bac_francophone_a1` | non |
| francophone | générale | Terminale | A2 | `exam_bac_francophone_a2` | non |
| francophone | générale | Terminale | A3 | `exam_bac_francophone_a3` | non |
| francophone | générale | Terminale | A4 | `exam_bac_francophone_a4` | non |
| francophone | générale | Terminale | A5 | `exam_bac_francophone_a5` | non |
| francophone | générale | Terminale | ABI | `exam_bac_francophone_abi` | non |
| francophone | générale | Terminale | SH | `exam_bac_francophone_sh` | non |
| francophone | générale | Terminale | AC | `exam_bac_francophone_ac` | non |
| francophone | générale | Terminale | C | `exam_bac_francophone_c` | non |
| francophone | générale | Terminale | D | `exam_bac_francophone_d` | non |
| francophone | générale | Terminale | E | `exam_bac_francophone_e` | non |
| francophone | générale | Terminale | TI | `exam_bac_francophone_ti` | non |

> 🟢 **Story 1.11a — Notes sur les lignes Tle francophone ci-dessus** :
> - **A** : ⚠️ DEPRECATED Story 1.11a, `isActive: false` post-1.12 (rétrocompat profils existants v1)
> - **A1, A2, A3, A4** : NEW Story 1.11a, `isActive: true` post-1.12 (sous-séries littéraires officielles MINESEC priorité haute)
> - **A5, ABI, SH, AC** : NEW Story 1.11a, `isActive: false` initial (activables runtime selon production contenu)
> - **C** : ⚠️ Corrigée Story 1.11a (Physique + Chimie séparés ex-PCT, retrait LV2 erronée v1, ajout Informatique)
> - **D** : ⚠️ Corrigée Story 1.11a (Physique + Chimie séparés, retrait LV2, ajout Environnement + Informatique)
> - **E** : ⚠️ Corrigée Story 1.11a (ajout Philo manquante v1, renommage `francophone_si` → `francophone_techno`)
> - **TI** : NEW Story 1.11a, `isActive: false` initial (Technologie de l'Information, lycée technique uniquement)

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

**Anglophone — ESTP TVEE (Story 1.11a, sources Cameroon GCE Board, toutes `isActive: false` initial)** :

| sous-sys | filière | niveau | série | examens visés | retrait ? |
|---|---|---|---|---|---|
| anglophone | technique | TVE IL | ELEQ | `exam_tve_il_anglophone_eleq` | **oui** (panier `tve_picker`) |
| anglophone | technique | TVE IL | ELNI | `exam_tve_il_anglophone_elni` | **oui** |
| anglophone | technique | TVE IL | ELME | `exam_tve_il_anglophone_elme` | **oui** |
| anglophone | technique | TVE IL | ELET | `exam_tve_il_anglophone_elet` | **oui** |
| anglophone | technique | TVE IL | AC | `exam_tve_il_anglophone_ac` | **oui** |
| anglophone | technique | TVE IL | ME | `exam_tve_il_anglophone_me` | **oui** |
| anglophone | technique | TVE IL | CE | `exam_tve_il_anglophone_ce` | **oui** |
| anglophone | technique | TVE IL | WW | `exam_tve_il_anglophone_woodwork` | **oui** |
| anglophone | technique | TVE IL | ACC | `exam_tve_il_anglophone_acc` | **oui** |
| anglophone | technique | TVE IL | COM | `exam_tve_il_anglophone_commerce` | **oui** |
| anglophone | technique | TVE IL | OP | `exam_tve_il_anglophone_op` | **oui** |
| anglophone | technique | TVE IL | FN | `exam_tve_il_anglophone_food_nutrition` | **oui** |
| anglophone | technique | TVE IL | CT | `exam_tve_il_anglophone_clothing_textiles` | **oui** |
| anglophone | technique | TVE AL | ELEQ | `exam_tve_al_anglophone_eleq` | **oui** |
| anglophone | technique | TVE AL | ELNI | `exam_tve_al_anglophone_elni` | **oui** |
| anglophone | technique | TVE AL | ELME | `exam_tve_al_anglophone_elme` | **oui** |
| anglophone | technique | TVE AL | ELET | `exam_tve_al_anglophone_elet` | **oui** |
| anglophone | technique | TVE AL | AC | `exam_tve_al_anglophone_ac` | **oui** |
| anglophone | technique | TVE AL | ME | `exam_tve_al_anglophone_me` | **oui** |
| anglophone | technique | TVE AL | CE | `exam_tve_al_anglophone_ce` | **oui** |
| anglophone | technique | TVE AL | WW | `exam_tve_al_anglophone_woodwork` | **oui** |
| anglophone | technique | TVE AL | ACC | `exam_tve_al_anglophone_acc` | **oui** |
| anglophone | technique | TVE AL | COM | `exam_tve_al_anglophone_commerce` | **oui** |
| anglophone | technique | TVE AL | OP | `exam_tve_al_anglophone_op` | **oui** |
| anglophone | technique | TVE AL | FN | `exam_tve_al_anglophone_food_nutrition` | **oui** |
| anglophone | technique | TVE AL | CT | `exam_tve_al_anglophone_clothing_textiles` | **oui** |

**Volumétrie v1 (Story 1.1b)** : 27 lignes francophone (4 BEPC + 14 général 2nd cycle + 16 technique industriel + 6 technique tertiaire + 8 technique étendue = 48 entrées) + 5 anglophone secondary + 26 anglophone high school = **79 `derivation_rules` totales** seedées en Story 1.1b.

**Volumétrie v2 (Story 1.11a — pivot alignement nomenclature officielle)** : v1 + **+9 lignes Tle francophone** (A1, A2, A3, A4, A5, ABI, SH, AC, TI) + **+26 lignes anglophone TVEE** (13 spécialités × 2 niveaux TVE IL + TVE AL) + corrections C/D/E (lignes existantes amendées, pas de nouvelles entrées) = **~114 `derivation_rules` totales v2** (+44% vs v1). Story 1.12 re-seedera Firestore avec la matrice v2.

**Activation initiale v2 (Story 1.12)** :
- **~50 activées** au seed initial (`isActive: true`) — périmètre prioritaire MVP : v1 prioritaire conservé + **+4 nouvelles sous-séries Tle franco** (A1, A2, A3, A4 : sous-séries littéraires officielles haute priorité) + matières manquantes O-Level/A-Level
- **~64 étendues** (`isActive: false`) — TVEE complet (26) + sous-séries franco basses priorités (A5, ABI, SH, AC, TI = 5) + 8 séries techniques étendues v1 (ESF/IH/MVT/ACA/MAVA/MEAC/MEM/MECA toujours `isActive: false`) + autres matières optionnelles

Activation runtime progressive par l'admin pédagogique via Firebase Console — pas de cycle de release mobile (cf. ADR-015 + ADR-016).

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
| 2026-06-09 | DelRoos / Claude (Amelia agent) | Story 1.11a — matrice v2 alignement nomenclature officielle (Office du Baccalauréat + Cameroon GCE Board, doc utilisateur 2026-06-09). **+4 matières premier cycle franco** (LCN, Informatique collège, Éducation Artistique, Travail Manuel) + **9 sous-séries Tle franco** (A1, A2, A3, A4, A5, ABI, SH, AC, TI) + **corrections séries C/D/E** (séparer Physique+Chimie ex-PCT, retirer LV2 erronée, ajouter Informatique + Environnement sur D, ajouter Philo sur E) + **5 matières O-Level** (codes GCE 0505 Accounting / 0546 Special Bilingual French / 0555 Geology / 0565 Human Biology / 0590 Logic) + **6 matières A-Level** (0746 Bilingual French / 0790 Philosophy / 0796 ICT / 0765 Pure Maths Mechanics / 0770 Pure Maths Stats / 0740 Food Science Nutrition) + **sous-système ESTP anglophone TVEE complet** (TVE IL + TVE AL × 13 spécialités industrielles/commerciales/Home Economics). ~140 `derivation_rules` totales v2 (vs 79 v1), ~50 activées au seed initial (1.12), ~90 étendues `isActive: false` (TVEE + sous-séries ABI/SH/AC/AI/TI + matières optionnelles activables progressivement). **Pivot panier polymorphe** : `series.pickerMode` enum 5 valeurs (`derived` default / `opt_out` legacy / `free_with_obligatory` O-Level / `series_plus_optional` A-Level / `tve_picker` TVEE) — cf. ADR-016. Série A franco DEPRECATED + `isActive: false` post-1.12 (rétrocompat). Sprint-change-proposal-2026-06-09.md. |
