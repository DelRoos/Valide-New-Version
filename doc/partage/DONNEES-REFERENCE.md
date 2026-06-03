# Données de référence

> **Lead de maintenance** : PM + équipe backend (le catalogue alimente la collection `subjects`).
> **Statut global** : 🟡 **En cours** — structure et séries officielles posées d'après les sources MINESEC, GCE Board et Office du Baccalauréat. Les listes exactes de matières par série restent à valider par un enseignant camerounais.

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

> 🔴 **Liste exacte par niveau à valider** avec un enseignant. Les matières principales sont stables ; les coefficients et la liste complète des LV2 disponibles varient.

#### Second cycle (lycée, 3 ans) — séries officielles

Les filières du second cycle général se distinguent en **littéraires** et **scientifiques**, avec passage obligatoire en série dès la Seconde. Le **Probatoire** sanctionne la Première, le **BAC** sanctionne la Terminale.

| Série | Type | Profil |
|---|---|---|
| **A** | Littéraire | Lettres, philosophie, langues |
| **C** | Scientifique | Maths-Physique dominantes (filière la plus sélective) |
| **D** | Scientifique | SVT-Chimie dominantes |
| **E** | Scientifique-technique | Maths-Techniques industrielles (présente dans certains lycées) |

> 🔴 **Confirmation requise** : la série E est présente dans certains lycées techniques mais pas dans tous les programmes. Le découpage exact A/C/D/E/E1/E2 doit être validé.

| Niveau | Série | Examen | Retrait ? |
|---|---|---|---|
| Seconde | A / C | aucun | non (le choix de série fixe la liste) |
| Première | A / C / D / E | **Probatoire** (A / C / D / E) | non |
| Terminale | A / C / D / E | **BAC** (A / C / D / E) | non |

##### Matières par série (proposition à valider)

🔴 **Listes à valider** par un enseignant — les matières au programme officiel évoluent par arrêté ministériel.

**Série A (littéraire)** :
Français, Anglais, LV2, Philosophie, Histoire-Géo, Mathématiques, Éducation Physique
+ option (selon lycée) : Littérature, Arts plastiques, etc.

**Série C (scientifique maths-physique)** :
Mathématiques, Physique-Chimie-Technologie (PCT), SVT, Français, Anglais, LV2, Philosophie, Histoire-Géo, EPS

**Série D (scientifique SVT)** :
SVT (dominante), Mathématiques, PCT, Français, Anglais, LV2, Philosophie, Histoire-Géo, EPS

**Série E (scientifique-technique)** :
Mathématiques, Sciences Industrielles, PCT, Français, Anglais, Histoire-Géo, EPS

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

#### Autres séries techniques mentionnées (à confirmer)

D'autres spécialités existent localement et peuvent ne pas être ouvertes partout :

- **ESF** (Économie Sociale et Familiale)
- **IH** (Industrie Hôtelière)
- **MVT** (Mécanique des Véhicules à Tracteur)
- **ACA / ACC** (Action Commerciale, Aide-Comptable)
- **MAVA, MEAC AUTO, MEM, MECA** (Maintenance industrielle, mécanique automobile)

> 🔴 **Catalogue exhaustif à figer** : la nomenclature officielle de l'Office du Baccalauréat liste plus de 20 séries techniques. Au MVP, on peut se concentrer sur les **plus représentées** (F1-F4, G1-G3) et étendre plus tard.

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

🟡 **Liste à compléter et valider** (cf. [Cameroon GCE O Level subjects](https://camgceb.org/examinations/gce-ordinary-level/)) :

English Language, English Literature, French, Mathematics, Additional Mathematics, Physics, Chemistry, Biology, Geography, History, Economics, Religious Studies, Computer Science, Citizenship Education, Information & Communication Technology, Food & Nutrition, Commerce, etc.

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

> 🟡 **Liste finale à fixer** au démarrage Phase 1 par l'équipe backend en collaboration avec le PM, sur base des séries effectivement supportées par le MVP. Décision proposée : **MVP couvre les séries les plus représentées** (A, C, D côté général ; F1-F4, G1-G3 côté technique ; toutes les séries S et A côté anglophone), les autres viendront en V2.

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

🟡 **Squelette à compléter** en Phase 1. Quelques exemples figés :

| sous-sys | filière | niveau | série | examens visés |
|---|---|---|---|---|
| francophone | générale | 3ᵉ | — | `exam_bepc_francophone` |
| francophone | générale | Première | C | `exam_probatoire_francophone_c` |
| francophone | générale | Terminale | D | `exam_bac_francophone_d` |
| francophone | technique | Terminale | F1 | `exam_bac_technique_f1` |
| francophone | technique | Terminale | G2 | `exam_bac_technique_g2` |
| anglophone | générale | Form 5 | — | `exam_gce_o_level_anglophone` |
| anglophone | générale | Upper Sixth | S2 | `exam_gce_a_level_anglophone_s2` |
| anglophone | générale | Upper Sixth | A3 | `exam_gce_a_level_anglophone_a3` |

---

## Implications pour les équipes

### Mobile
- Ne stocke **pas** la matrice en dur. Lit `subjects/*` filtré par profil au démarrage.
- Affiche `name.fr` ou `name.en` selon le sous-système de l'utilisateur (chaque document `subject` a un champ bilingue).
- L'écran de sélection de série affiche **seulement** les séries valides pour la filière et le niveau de l'élève.

### Backend
- Mainteneur principal du catalogue `subjects/*` dans Firestore.
- Implémente la dérivation côté Cloud Function lors de la création / modification du profil (cf. ALGORITHMES.md § 1).
- Les seeds initiaux du catalogue sont dans `functions/seed/subjects.json` (dépôt backend, à créer en Phase 1).
- Fait évoluer le catalogue après validation par le PM (matières ajoutées / renommées).

### Admin
- Permet à l'équipe pédagogique de **modifier** le catalogue (ajouter une matière, corriger un nom).
- Toute modification doit déclencher un **recalcul des `derivedSubjects`** des élèves concernés (Cloud Function admin, cf. ALGORITHMES.md § 11).
- L'admin **affiche** la matrice dérivée pour un élève donné (debug : « voici les matières que ce profil voit »).
- L'admin sait gérer **les écoles** qui n'offrent pas toutes les séries (filtrage géographique). Cf. collection `schools` dans BASE-DE-DONNEES.md.

### Landing
- Peut afficher publiquement « préparation à 8 séries A Level, 3 séries STT, BEPC, Probatoire et BAC », sans détail.

---

## Périmètre MVP suggéré

Plutôt que de couvrir toutes les séries dès la V1 (effort de contenu énorme), couvrir **les séries les plus représentées** :

**Francophone — général** :
- Premier cycle : 6ᵉ → 3ᵉ + BEPC ✅
- Second cycle : Seconde, Première, Terminale séries **A, C, D** + Probatoire + BAC ✅
- (Série E reportée si elle représente < X % des élèves)

**Francophone — technique** :
- Industriel : Première et Terminale séries **F1, F2, F3, F4** + Probatoire + BAC ✅
- Tertiaire : Première et Terminale séries **G1, G2, G3** + BAC ✅
- (F5, ESF, IH, MVT, etc. reportées en V2)

**Anglophone** :
- Form 1 → Form 5 + O Level ✅
- Lower Sixth + Upper Sixth : **toutes les séries S1-S8 et A1-A5** ✅

> Décision finale : à valider en Phase 1 (`/bmad-prd`) avec le PM en fonction du marché cible et de la capacité de production de contenu.

---

## Historique

| Date | Auteur | Modification |
|---|---|---|
| 2026-06-03 | Setup initial | Création du squelette à partir des docs d'architecture mobile/backend |
| 2026-06-03 | Recherche domaine | Ajout des séries officielles MINESEC (A/C/D/E, F1-F5, G1-G3) et combinaisons GCE Board (S1-S8, A1-A5) confirmées par sources autoritaires. Sections de matières par série restent 🔴/🟡 à valider par un enseignant |
