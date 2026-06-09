---
date: 2026-06-09
sprint: P1 (extension)
triggering_story: Story 1.10 — Suppression compte (en review) + audit alignement nomenclature officielle
scope_classification: Major
status: pending-approval
author: Delano Roosvelt (PO) + Claude (PM agent via /bmad-correct-course)
sources:
  - Office du Baccalauréat camerounais (officedubac.cm) — Nomenclature ESG + ESTP francophone
  - Cameroon GCE Board (camgceb.org) — Syllabus O-Level + A-Level + TVEE
  - Cameroon GCE Revision — Lower Sixth Series Arts & Science
  - Doc utilisateur 2026-06-09 « Orientation et matières au secondaire camerounais »
---

# Sprint Change Proposal — Alignement catalogue avec nomenclature officielle camerounaise

## 1. Issue Summary

### Problem statement

Suite à l'implémentation de l'Epic 1 (Stories 1.1a → 1.10), un **audit comparatif** entre le catalogue Firestore actuel (`derivation_rules` v1 livré par Story 1.1b) et la **nomenclature officielle** publiée par l'Office du Baccalauréat et le Cameroon GCE Board révèle 4 catégories de gaps critiques :

1. **Matières manquantes** : 4 matières premier cycle francophone (Langues et Cultures Nationales, Informatique, Éducation Artistique, Travail Manuel), 4 matières O-Level anglophone (0546 Special Bilingual French, 0555 Geology, 0565 Human Biology, 0590 Logic), 3 matières A-Level (0746 Bilingual French, 0790 Philosophy, 0796 ICT), plus erreurs de composition dans séries C/D francophones (présence incorrecte de LV2, absence d'Informatique, Physique-Chimie fusionnée à tort).
2. **Sous-séries Tle francophone absentes** : la nomenclature officielle distingue **A1, A2, A3, A4, A5, ABI, SH, AC, TI** (en plus de C, D, E). Le catalogue actuel ne modélise que A (générique), C, D, E.
3. **Règles de choix anglophone non implémentées** :
   - **O-Level** : règle officielle = « min 6 matières, max 11, avec English Language + French + Mathematics obligatoires » — actuellement l'app présente toutes les matières dérivées sans validation panier.
   - **A-Level** : règle officielle = « max 5 matières, Series = combinaison de 3-4 fixes, matières transversales optionnelles (Computer Science, ICT, Religious Studies, Commerce) ajoutables » — actuellement Series fige la combinaison sans flexibilité.
4. **Sous-système ESTP anglophone (TVEE) totalement absent** : la nomenclature officielle GCE Board liste **TVE Intermediate Level** (équivalent O-Level technique, fin Form 5) + **TVE Advanced Level** (équivalent A-Level technique, fin Upper Sixth) avec 10+ spécialités (ELEQ, ELNI, ELME, ELET, Air Conditioning, Mechanical Engineering, Civil Engineering, Carpentry, Accounting, Commerce, Office Practice, Food & Nutrition, Clothing & Textiles). Le catalogue mobile ne couvre actuellement aucun parcours technique anglophone.

### Categorisation

**Strategic alignment** — convergence avec la nomenclature officielle pour livrer un MVP crédible auprès des établissements et enseignants camerophones.

### Evidence (sources citables)

- **Office du Baccalauréat** publie A1-A5 + ABI + SH + AC + TI comme séries officielles francophones (Probatoire + BAC).
- **Cameroon GCE Board** publie 21 codes officiels O-Level (0505-0595) avec règle obligatoire EN+FR+Math + min 6 max 11.
- **Cameroon GCE Board** publie 20 codes officiels A-Level (0705-0796) avec règle max 5 + Series + transversales.
- **Cameroon GCE Board TVEE** : TVE IL et TVE AL formalisés avec règles min 5 (TVE IL, dont 2 Professional + 1 Related) et 6-8 (TVE AL, dont 3 Professional + ≥3 Related).
- **Réalité marché** : les bassins Nord-Ouest et Sud-Ouest (anglophones) ont une forte filière technique TVEE — ne pas la couvrir = -15 à -20% du marché cible adressable selon SPEC.

### Décisions complémentaires (AskUserQuestion 2026-06-09)

| Aspect | Décision PO |
|---|---|
| **Périmètre correction** | **Tous les 4 axes** : matières manquantes + sous-séries franco + panier Anglo (O + A Level) + ESTP TVEE |
| **Modélisation sous-séries franco** | **Flat** — 12 séries en Tle générale (A1, A2, A3, A4, A5, ABI, SH, AC, C, D, E, TI). Pas d'étape supplémentaire dans le flow profil, juste plus de cards au choix série. |
| **Modélisation TVEE** | **Filière `technique` en `anglophone`** (à confirmer ADR-016 v1) — cohérent avec `francophone/technique` déjà modélisé |
| **Panier O-Level** | **Refactor `SubjectsOptOutPage` → `SubjectsPickerPage`** avec mode multi (`derived`/`opt_out`/`free_with_obligatory`/`series_plus_optional`) piloté par flag Firestore |
| **Mode skill** | Incremental |
| **Action management** | `/bmad-correct-course` (cette session) |

## 2. Impact Analysis

### Epic Impact

- **Epic 0** — ✅ aucun impact (foundation done, infrastructure stable)
- **Epic 1 (Onboarding & Profil scolaire)** — ⚠️ **+8 stories extension** + **2 amendments stories existantes** (1.4 + 1.3 amendés). Goal inchangé. Critère de sortie élargi pour couvrir aussi Mariam Tanyi (Form 5 anglophone avec panier) et Eyong Eboa (TVE AL anglophone spécialité Electrotechnique).
- **Epic 2 (Navigation contenu)** — ⚠️ léger : grille matières dashboard (1.9) doit gérer la nouvelle matrice mais sans refactor (consommation transparente via `effectiveDerivedSubjectsProvider`)
- **Epic 3 (Quiz)** — ⚠️ léger : contenu pédagogique pour nouvelles matières (Latin, Grec, LV3, Geology, Logic, Human Biology, etc.) reste à produire par l'équipe pédagogique — pas d'impact code, juste data. Activable runtime via `isActive` toggle Firestore.
- **Epic 4-6** — ✅ aucun impact

### Story Impact (Epic 1 extension)

| Story | Statut | Type changement |
|---|---|---|
| **1.1a** Audit matrice v1 | done | Inchangée. Extension v2 livrée par 1.11a. |
| **1.1b** Script Python seed v1 | done | Inchangée. matrice.json v2 livrée par 1.12. |
| **1.1c** CatalogueRepository mobile | done | ⚠️ **AMENDED** : DerivedProfile model étendu en 1.13 (champs `obligatorySubjects`, `optionalSubjects`, `pickerMode`, `minSubjects`, `maxSubjects`). Non-breaking pour profils existants (defaults safe). |
| **1.2** Choix sous-système | done | ✅ inchangée |
| **1.3** Flow profil 3 étapes | done | ⚠️ **AMENDED léger** par 1.14 : la step série affiche désormais jusqu'à 12 cards (Tle franco) au lieu de 4, et conditionnellement le picker O-Level/A-Level/TVEE en cas anglophone. Cosmétique uniquement, pas de step supplémentaire. |
| **1.4** Retrait conditionnel matières | done | ⚠️ **AMENDED majeur** par 1.15 : `SubjectsOptOutPage` refactorisée en `SubjectsPickerPage` polymorphe (mode `opt_out` legacy + mode `free_with_obligatory` O-Level + mode `series_plus_optional` A-Level). Tests existants conservés en mode legacy. |
| **1.5** Garde nav profil-incomplet | done | ✅ inchangée |
| **1.6** Compte Google/Apple | done | ✅ inchangée |
| **1.7** Liaison école | done | ✅ inchangée |
| **1.8** Persistance session | done | ✅ inchangée |
| **1.9** Dashboard skeleton | done | ✅ inchangée (consomme effectiveDerivedSubjectsProvider sans connaître la mécanique panier) |
| **1.10** Suppression compte | review (PR 1.10 ouverte) | ✅ inchangée |
| **1.11a** Audit matrice exhaustive v2 + ADR-016 modélisation | **NEW** | Docs only, S ~3h |
| **1.11b** Update PRD FR-2/FR-3 + EXPERIENCE.md flow variable | **NEW** | Docs only, S ~2h |
| **1.12** Update matrice.json + re-seed Firestore | **NEW** | Backend script, M ~4h |
| **1.13** Catalogue mobile : enrichir DerivedProfile + pickerMode | **NEW** | Mobile data layer, S ~3h |
| **1.14** Flow profil : sous-séries Tle franco + adaptation 12 cards | **NEW** | Mobile UI, M ~5h |
| **1.15** Refactor 1.4 → SubjectsPickerPage : panier Anglo O-Level | **NEW** | Mobile UI, M ~5h |
| **1.16** Extension A-Level : matières transversales optionnelles | **NEW** | Mobile UI, S ~3h |
| **1.17** ESTP anglophone TVEE : filière technique + niveaux + 10+ spécialités | **NEW** | Mobile + data, L ~6-8h |

**Estimation Epic 1 extension** : 31-36h. Timeline impact : **+7-8 jours calendaires après merge Story 1.10**. Cible : sortie Epic 1 v2 vers 2026-06-17.

### Artifact Conflicts

| Artefact | Type modification | Accord requis | Story |
|---|---|---|---|
| `doc/partage/DONNEES-REFERENCE.md` | Matrice v2 : ajout 4 matières premier cycle + 4 matières O-Level + 3 matières A-Level + 9 nouvelles séries franco + sous-système TVEE complet. Update historique. | Update interne (mainteneur PM) | 1.11a |
| `doc/partage/BASE-DE-DONNEES.md` | Ajout 3 champs `series` (`pickerMode`, `minSubjects`, `maxSubjects`) + 2 champs `derivation_rules` (`obligatorySubjectIds[]`, `optionalSubjectIds[]`). Update indexes composites si besoin (probablement non — les nouveaux champs ne sont pas indexés directement). | **Accord backend** | 1.11a |
| `doc/partage/ALGORITHMES.md § 1` | Update algo dérivation : retourne `DerivedProfile` enrichi (`obligatorySubjects`, `optionalSubjects`, `pickerMode`). Pseudo-code étendu. | Update interne | 1.11a |
| `project_manage/planning-artifacts/architecture/architecture.md` § 14 | Ajout ADR-016 référence | Update interne | 1.11a |
| **NEW** `project_manage/planning-artifacts/architecture/adrs/ADR-016-catalogue-v2-sous-series-panier-tvee.md` | Création | Création par 1.11a | 1.11a |
| `project_manage/planning-artifacts/prds/.../prd.md` § FR-2 | "3 étapes obligatoires" → "3 étapes obligatoires, avec liste de séries variable selon profil (jusqu'à 12 cards en Tle franco, picker O-Level/A-Level/TVEE en anglophone)" | Update interne | 1.11b |
| `project_manage/planning-artifacts/prds/.../prd.md` § FR-3 | "Retrait conditionnel" → "Sélection panier conditionnelle (panier libre O-Level avec validation, retrait simple sinon, extension transversale A-Level)" | Update interne | 1.11b |
| `project_manage/planning-artifacts/ux-designs/.../EXPERIENCE.md` Flow 1 | Ajout variant : (a) cards série étendues, (b) picker panier O-Level avec validation min/max + obligatoires, (c) extension Series A-Level avec checkboxes optionnelles, (d) parcours TVEE anglophone | Update interne | 1.11b |
| `project_manage/planning-artifacts/epics/epic-1-onboarding.md` | Ajout sections § Story 1.11a, 1.11b, 1.12, 1.13, 1.14, 1.15, 1.16, 1.17. Update graphe dépendances. Update estimation totale (51-63h → 82-99h). | **Cette PR** | — |
| `project_manage/implementation-artifacts/sprint-status.yaml` | Ajout 8 nouvelles stories (backlog) + amendments tracés sur 1.3/1.4/1.1c | **Cette PR** | — |
| `scripts/firebase_seed/data/matrice.json` | Extension : ~50 nouveaux documents (subjects + series + derivation_rules + exam_targets) | Story 1.12 livraison | 1.12 |
| `scripts/firebase_seed/seed_catalogue.py` | Probablement aucune modif (idempotent + accepts nouveaux champs sans validation rigide). À confirmer 1.12. | Story 1.12 vérification | 1.12 |
| `mobile_app/lib/core/catalogue/models.dart` | Ajout champs `DerivedProfile.{obligatorySubjects, optionalSubjects, pickerMode, minSubjects, maxSubjects}` avec defaults safe (Story 1.13) | Story 1.13 | 1.13 |
| `mobile_app/lib/features/onboarding/presentation/subjects_opt_out_page.dart` | Refactor en `SubjectsPickerPage` polymorphe (3 modes) | Story 1.15 | 1.15 |
| **NEW** `mobile_app/lib/features/onboarding/presentation/serie_choice_page.dart` | Adaptation : afficher jusqu'à 12 cards + groupement visuel (Tle franco) + variant filière technique anglo (TVEE) | Story 1.14 + 1.17 | 1.14, 1.17 |
| `firestore.rules` (racine) | Update validation `users/{uid}` : la règle `optedOutSubjects ⊂ derivedSubjects` reste, ajout règle `pickedSubjects` symétrique pour mode `free_with_obligatory` (subset de subjects autorisés Series + obligatoires obligatoires) | Story 1.15 | 1.15 |
| `firestore.indexes.json` (racine) | Aucun nouvel index nécessaire (les nouveaux champs sont des arrays ou scalaires sur docs lus par ID) — à confirmer 1.13 (CLAUDE.md règle 9 enforcement) | Story 1.13 | 1.13 |
| `firestore.indexes.json` deploy | `firebase deploy --only firestore:indexes --project valide-edu` si index ajouté (CLAUDE.md règle 9 enforcement) | Story 1.13 | 1.13 |
| `mobile_app/lib/l10n/*.arb` | ~30 nouvelles clés i18n (cards série, picker labels, validation toast, TVEE specificities) | Stories 1.14/1.15/1.16/1.17 | 1.14+ |

### Technical Impact

- **Performance** : ⚠️ matrice étendue à ~130 derivation_rules au seed (vs 79 v1). Lecture initiale streams Firestore augmente légèrement mais reste linéaire. Cache offline absorbe. Acceptable.
- **NFR-2 démarrage < 3s** : marge stable. Le seed v2 ne change rien au boot path.
- **Sécurité** : write Firestore reste interdit côté mobile. Catalogue v2 = données publiques étendues, pas de PII.
- **CI/CD (0.17 deferred)** : impact nul.
- **Dépendances pubspec** : aucune nouvelle.
- **Tests** : +30-40 nouveaux tests cumulés sur 8 stories (validation panier, parsing nouvelles règles, widgets pickers, TVEE flow). Baseline actuelle 205 → cible post-Epic 1 v2 ~245-250 tests.
- **Backwards compat** : critique. Les profils déjà créés (`users/{uid}.derivedSubjects` existant) continuent à fonctionner. Les nouveaux champs `obligatorySubjects`, `optionalSubjects` sont **optionnels** dans `DerivedProfile` avec defaults vides → ancien comportement préservé.
- **Action porteur (Delano) post-merge 1.12** : re-run du script Python seed sur valide-edu pour pousser matrice v2 — idempotent, peut écraser sans casser.

## 3. Recommended Approach

### Approche sélectionnée

**Option 1 — Direct Adjustment** avec **extension Epic 1 par 8 nouvelles stories séquentielles + amendments**.

### Justification

1. **Pattern éprouvé** : le sprint change du 2026-06-05 a réussi avec la même mécanique (split + amendments). Pas de pivot architectural cette fois (Firestore-driven déjà acté), juste enrichissement matrice + UX.
2. **Single dev session** respectée : chaque story reste 3-5h sauf 1.17 (L ~6-8h pour TVEE, justifié car nouveau domaine entier).
3. **Découplage contrats vs impl** : 1.11a/1.11b livrent les contrats (ADR-016 + DONNEES-REFERENCE v2 + PRD + UX) validables séparément avant tout code.
4. **Parallélisation possible** :
   - 1.12 (script Python re-seed) et 1.13 (model Dart enrichi) peuvent partir en parallèle après 1.11a
   - 1.14 (sous-séries franco) et 1.15 (panier O-Level) parallélisables après 1.13
   - 1.17 (TVEE) parallélisable après 1.13 (touche surtout data + flow)
5. **Pas de rollback nécessaire** : code Epic 1 v1 reste fonctionnel pendant le rollout. Le mode `pickerMode: 'derived'` (default) reproduit le comportement actuel.
6. **MVP maintenu** : aucune fonctionnalité retirée. Au contraire, +20-25% du marché cible adressable (parcours TVEE + tous parcours littéraires francophones).

### Alternatives considérées et rejetées

- **Option 2 (Rollback)** — ❌ Non applicable, Epic 1 v1 fonctionne, on étend.
- **Option 3 (MVP Review)** — ❌ Refusé par PO (toutes les 4 cases cochées en AskUserQuestion). Le MVP doit livrer un catalogue aligné officiel.
- **Variante Major refactor catalogue v3** (deep redesign avec hiérarchies type sous-séries comme tree) — ❌ Trop complexe pour bénéfice marginal. Flat suffit pour MVP.
- **Variante reporter TVEE en post-MVP** — ❌ Refusé par PO. Le porteur a explicitement coché TVEE. Justification marché : 15-20% du marché anglophone passe par TVEE selon SPEC.
- **Variante créer un Epic 1bis dédié** — ❌ Plus lourd administrativement. Pattern Epic 1 extension par stories suffit (cf. epic-1 status `in-progress` qui absorbe l'extension naturellement).

### Effort estimate

**+31-36h** sur Epic 1 (de 51-63h → 82-99h cumul). Timeline P1 : étendre de ~7-8 jours calendaires. Total Epic 1 : ~17-19 jours calendaires (au lieu de 10).

### Risk assessment

- **Risque casse rétrocompat catalogue** : faible. Backwards compat assurée par defaults safe dans `DerivedProfile`. Test régression manuel Fatou (Tle D) + James (Upper Sixth S2) doit passer post-1.13.
- **Risque dépendance backend** : faible. Aucune Cloud Function nouvelle. Juste 2 champs ajoutés `series.pickerMode` etc. Update BASE-DE-DONNEES.md → backend approve async (commentaire PR 1.11a).
- **Risque ergonomique 12 cards série** : moyen. Tle Franco générale = 12 cards = scroll obligatoire sur Pixel 4a. Mitigation : groupement visuel par famille (Lettres / Sciences / Techniques) en 1.14. Tests UX Fatou doit pouvoir trouver "D" en < 10s.
- **Risque charge mentale panier O-Level** : moyen. Compromis : pre-cocher EN+FR+Math + 3 matières populaires (Physics, Chemistry, Biology pour sciences ; History, Geography, Literature pour arts) selon stream Form 3+ — UX-DR à raffiner en 1.11b/1.15.
- **Risque sous-estimation TVEE (1.17)** : moyen-fort. C'est un nouveau domaine — l'enseignant TVEE camerophone pourrait remonter nuances en review. Mitigation : seedé `isActive: false` initial, activable progressivement après validation enseignant.
- **Risque non-couverture exhaustive** : la doc utilisateur 2026-06-09 mentionne aussi BT (BAC Technicien), BP (Brevet Professionnel), BEP, CAP, AF (artistiques F1-F3), F6/F7/F8 industriels, Hôtellerie HO-HE/HO-RB/HO-CU, Tourisme TO-AAT/TO-AV, ESF, et 30+ autres spécialités BT/BP. **Décision PO** : V2 ne couvre pas ces spécialités (out of scope MVP). Documentées dans ADR-016 § Out of scope.

### Timeline impact

P1 étendue de ~10 j à **~17-19 j calendaires**. Pas d'impact P2-P6. Critère de sortie Epic 1 v2 acquis vers 2026-06-17 (sous réserve velocity).

## 4. Detailed Change Proposals

### Change 4.1 — Sprint-status.yaml : ajout 8 nouvelles stories Epic 1

**Section** : `development_status` → Epic 1

**Ajout après ligne `1-10-suppression-compte-7j-grace`** :

```yaml
  # === Epic 1 extension v2 (sprint-change 2026-06-09 alignement nomenclature officielle) ===
  1-11a-audit-matrice-v2-adr016: backlog  # 2026-06-09 NEW. Audit matrice exhaustive v2 + ADR-016 modelisation sous-series flat + TVEE filiere + panier multi-mode + BASE-DE-DONNEES updates (accord backend requis). S ~3h.
  1-11b-update-prd-ux-flow-variable: backlog  # 2026-06-09 NEW. Amendement PRD FR-2/FR-3 + EXPERIENCE.md Flow 1 variants. S ~2h. Depends 1.11a.
  1-12-update-matrice-reseed-firestore: backlog  # 2026-06-09 NEW. Update scripts/firebase_seed/data/matrice.json (+50 documents) + run seed sur valide-edu. M ~4h. Depends 1.11a.
  1-13-derivedprofile-pickermode-extension: backlog  # 2026-06-09 NEW. Enrichir DerivedProfile (obligatorySubjects, optionalSubjects, pickerMode, minSubjects, maxSubjects) + CatalogueRepository.derive() update + non-breaking. S ~3h. Depends 1.11a (paralleliser 1.12 possible).
  1-14-sous-series-tle-franco-flat: backlog  # 2026-06-09 NEW. Flow profil : SerieChoicePage affiche 12 cards Tle franco (A1-A5/ABI/SH/AC/C/D/E/TI) avec groupement visuel famille. M ~5h. Depends 1.13.
  1-15-refactor-opt-out-en-picker-anglo-olevel: backlog  # 2026-06-09 NEW. SubjectsOptOutPage -> SubjectsPickerPage polymorphe (modes derived/opt_out/free_with_obligatory). Validation min 6 max 11 + EN+FR+Math obligatoires O-Level. Refactor non breaking. M ~5h. Depends 1.13.
  1-16-extension-a-level-transversales: backlog  # 2026-06-09 NEW. Mode series_plus_optional A-Level : checkboxes transversales (Computer Science, ICT, Religious Studies, Commerce). S ~3h. Depends 1.15.
  1-17-estp-anglophone-tvee: backlog  # 2026-06-09 NEW. Sous-systeme ESTP TVEE complet : filiere technique en anglophone, niveaux TVE IL + TVE AL, 10+ specialites (ELEQ/ELNI/ELME/ELET/AC/ME/CE/Carpentry/Acc/Commerce/OP/Food/Clothing), regles min 5 (IL) / 6-8 (AL). isActive false initial. L ~6-8h. Depends 1.13.
```

**Update commentaire epic-1** :

**OLD** :
```yaml
  epic-1: in-progress  # 2026-06-05 Epic 1 actif. Sprint change 2026-06-05 ...
```

**NEW** :
```yaml
  epic-1: in-progress  # 2026-06-09 Epic 1 etendu par sprint-change-proposal-2026-06-09.md (alignement nomenclature officielle). +8 stories 1.11a-1.17. Critere de sortie elargi : Mariam Tanyi (Form 5 anglophone panier O-Level) et Eyong Eboa (TVE AL anglophone Electrotechnique) doivent egalement reussir l'onboarding. Sprint change 2026-06-05 toujours actif (pivot Firestore). Timeline P1 +7-8j calendaires.
```

**Rationale** : tracker visible des 8 nouvelles stories + amendments tracés sur 1.3/1.4/1.1c via leur commentaire existant. Pas de cancelled cette fois (pas de pivot architectural).

### Change 4.2 — Epic-1-onboarding.md : ajout 8 sections stories + amendments 1.3/1.4/1.1c

**Fichier** : `project_manage/planning-artifacts/epics/epic-1-onboarding.md`

**Modifications** :

1. **Frontmatter** :
   - `storyCount: 12` → `storyCount: 20` (12 + 8 nouvelles)
   - `amendments`: ajouter ligne `"2026-06-09 — sprint-change-proposal-2026-06-09.md : alignement nomenclature officielle. +8 stories 1.11a/b, 1.12, 1.13, 1.14, 1.15, 1.16, 1.17. Stories 1.3/1.4/1.1c amendees (DerivedProfile enrichi, SerieChoicePage 12 cards, SubjectsOptOutPage -> SubjectsPickerPage polymorphe). Critere de sortie elargi pour Mariam Tanyi (Form 5 panier) et Eyong Eboa (TVE AL)."`
2. **Goal** : inchangé (le critère de sortie est élargi dans le critère de sortie textuel).
3. **Critère de sortie d'epic** :
   - **OLD** : "Fatou Mballa (Tle D francophone) et James Tanyi (Upper Sixth S2 anglophone) peuvent chacun compléter le flow d'onboarding..."
   - **NEW** : "Fatou Mballa (Tle D francophone), James Tanyi (Upper Sixth S2 anglophone), Aïssatou Diop (Tle A1 francophone Lettres+Latin+Grec), Mariam Bakari (Form 5 anglophone, panier 8 matières dont EN+FR+Math obligatoires) et Eyong Eboa (TVE AL anglophone Electrotechnique) peuvent chacun compléter le flow d'onboarding en moins de 2 minutes..."
4. **Dependency graph** : ajout branche extension v2 après node 1.10 :

```text
... (graphe existant 1.1a → 1.1c → 1.2 → 1.3 → {1.4 ... 1.10}) ...

                                    │
                       (sprint change 2026-06-09)
                                    │
                                    ▼
                  1.11a Audit matrice v2 + ADR-016
                                    │
                                    ▼
                  1.11b Update PRD FR-2/FR-3 + UX
                                    │
                          ┌────────┴─────────┐
                          ▼                  ▼
                  1.12 Update matrice  1.13 DerivedProfile
                  + reseed Firestore   pickerMode extension
                          │                  │
                          └────────┬─────────┘
                                   ▼
              ┌──────────────┬─────────┬──────────────┐
              ▼              ▼         ▼              ▼
      1.14 Sous-series  1.15 Picker  1.17 ESTP   (1.16 A-Level
      Tle franco flat   Anglo O-Lvl  TVEE        transversales
                                     anglophone   depend 1.15)
                                                       │
                                                       ▼
                                              1.16 A-Level transversales
```

5. **§ Story 1.11a (nouveau)** :
   - Titre : « Audit matrice exhaustive v2 (nomenclature officielle) + ADR-016 modélisation sous-séries flat + TVEE filière + panier multi-mode + BASE-DE-DONNEES updates »
   - Estim : S (~3h)
   - Goal : compléter matrice (~50 nouveaux documents) + écrire ADR-016 + amender BASE-DE-DONNEES.md (3 champs `series` + 2 champs `derivation_rules`) + amender ALGORITHMES.md § 1
   - Output : docs uniquement
   - Dépend : aucune
   - Bloque : 1.11b, 1.12, 1.13
   - Sources : Office du Baccalauréat (officedubac.cm), Cameroon GCE Board (camgceb.org), doc utilisateur 2026-06-09

6. **§ Story 1.11b (nouveau)** :
   - Titre : « Update PRD FR-2/FR-3 + EXPERIENCE.md Flow 1 variants »
   - Estim : S (~2h)
   - Goal : amender PRD § FR-2 (3 étapes mais avec liste série variable) + § FR-3 (panier conditionnelle vs retrait simple) + EXPERIENCE.md Flow 1 (4 variants UX : cards étendues, picker O-Level, extension A-Level, parcours TVEE)
   - Output : docs uniquement
   - Dépend : 1.11a
   - Bloque : 1.14, 1.15

7. **§ Story 1.12 (nouveau)** :
   - Titre : « Update scripts/firebase_seed/data/matrice.json + re-seed Firestore »
   - Estim : M (~4h)
   - Goal : étendre `data/matrice.json` selon matrice v2 (1.11a), valider tests Python existants passent, re-run seed sur valide-edu (porteur), vérifier Firebase Console
   - Output : matrice.json étendu + run seed
   - Dépend : 1.11a
   - Action porteur post-merge : `python seed_catalogue.py --project valide-edu`

8. **§ Story 1.13 (nouveau)** :
   - Titre : « Enrichir DerivedProfile : pickerMode + obligatorySubjects + optionalSubjects + min/max »
   - Estim : S (~3h)
   - Goal : ajout champs au model `DerivedProfile` (defaults safe), update mapping Firestore → DerivedProfile dans `CatalogueRepository.derive()`, tests régression Fatou/James (pickerMode = `derived` par défaut → ancien comportement), tests nouveaux cas (pickerMode = `free_with_obligatory` etc.)
   - Output : code Dart + tests
   - Dépend : 1.11a (paralléliser 1.12 possible)
   - Bloque : 1.14, 1.15, 1.17
   - Non-breaking : 1.4 actuel continue à fonctionner via mode `derived`

9. **§ Story 1.14 (nouveau)** :
   - Titre : « Sous-séries Tle francophone flat : SerieChoicePage 12 cards avec groupement visuel famille »
   - Estim : M (~5h)
   - Goal : adapter `SerieChoicePage` pour afficher jusqu'à 12 cards en Tle franco (A1, A2, A3, A4, A5, ABI, SH, AC, C, D, E, TI) avec groupement visuel par famille (Lettres / Sciences / Techniques / Autres) — pas de step supplémentaire dans le flow
   - Output : code Dart + tests widget Aïssatou (Tle A1)
   - Dépend : 1.13
   - Tests cibles : Aïssatou trouve "A1" en < 10s sur Pixel 4a

10. **§ Story 1.15 (nouveau)** :
    - Titre : « Refactor SubjectsOptOutPage → SubjectsPickerPage polymorphe : panier Anglo O-Level free_with_obligatory »
    - Estim : M (~5h)
    - Goal : refactor non-breaking `SubjectsOptOutPage` en `SubjectsPickerPage` avec 3 modes (legacy `opt_out` conservé + nouveau `free_with_obligatory` O-Level + placeholder `series_plus_optional` A-Level pour 1.16). Validation min 6 max 11 + EN+FR+Math non décochables. Toast erreur sur tentative invalide.
    - Output : code Dart refactorisé + tests Mariam (Form 5, 8 matières)
    - Dépend : 1.13
    - Bloque : 1.16
    - **firestore.rules** : nouvelle règle `pickedSubjects ⊂ derivedSubjects ∪ optionalSubjectIds ∧ obligatorySubjectIds ⊂ pickedSubjects` (à valider 1.15)

11. **§ Story 1.16 (nouveau)** :
    - Titre : « Extension A-Level : matières transversales optionnelles (Computer Science, ICT, Religious Studies, Commerce) »
    - Estim : S (~3h)
    - Goal : compléter `SubjectsPickerPage` mode `series_plus_optional` : Series fige 3-4 matières + checkboxes optionnelles transversales avec validation max 5 (incl. Series)
    - Output : code Dart + tests James (Upper Sixth S2 + ICT optionnel)
    - Dépend : 1.15

12. **§ Story 1.17 (nouveau)** :
    - Titre : « ESTP anglophone TVEE : filière technique + niveaux TVE IL/AL + 10+ spécialités »
    - Estim : L (~6-8h)
    - Goal : ajouter filière `technique` en `anglophone` (niveaux `tve_il` + `tve_al`) + 10-13 spécialités (ELEQ, ELNI, ELME, ELET, AC, ME, CE, Carpentry, Acc, Commerce, OP, Food, Clothing). Règles : min 5 (TVE IL) avec ≥2 Professional + ≥1 Related ; min 6 max 8 (TVE AL) avec ≥3 Professional + ≥3 Related. isActive: false initial (activable post-validation enseignant TVEE).
    - Output : matrice.json étendu (~30 nouveaux documents) + adaptation SerieChoicePage flow filière technique anglo + adaptation SubjectsPickerPage mode `tve_picker` (nouveau)
    - Dépend : 1.13
    - Activation : `isActive: false` au seed initial pour 1.17. Toggle runtime via Firebase Console quand contenu pédagogique TVEE est prêt.

13. **§ Couverture des exigences** : table mise à jour avec 1.11a → 1.17 lignes
14. **§ Estimation totale** : table mise à jour avec nouveau total 82-99h
15. **§ Notes transversales** : ajout mention sprint change 2026-06-09 + Mariam + Eyong + Aïssatou personas

### Change 4.3 — Création ADR-016 (livré par Story 1.11a)

**Fichier** : `project_manage/planning-artifacts/architecture/adrs/ADR-016-catalogue-v2-sous-series-panier-tvee.md`

**Contenu attendu** (sera détaillé en 1.11a) :
- **Statut** : Accepté (post-merge cette PR)
- **Décisions** :
  1. Sous-séries Tle francophone modélisées **flat** comme séries de plein droit (`francophone_terminale_a1`, etc.) — pas de hiérarchie. Décision PO 2026-06-09.
  2. TVEE modélisé en **filière `technique` en `anglophone`** avec niveaux `tve_il` et `tve_al`. Pas de nouveau subSystem. Cohérent avec pattern `francophone/technique`.
  3. Panier polymorphe via champ `series.pickerMode: enum('derived' | 'opt_out' | 'free_with_obligatory' | 'series_plus_optional' | 'tve_picker')`. Defaults safe = `derived` (comportement actuel).
  4. Validations panier (min/max + obligatoires) **côté client** (UI) + **côté Firestore rules** (`pickedSubjects ⊂ derivedSubjects ∪ optionalSubjectIds ∧ obligatorySubjectIds ⊂ pickedSubjects`).
- **Justification** : alignement nomenclature officielle (Office du Bac + GCE Board), élargissement marché cible adressable (+15-20% anglo TVEE + couverture exhaustive séries franco littéraires).
- **Conséquences positives** : MVP crédible auprès enseignants, scaling progressif via flag `isActive`, pattern Firestore-driven préservé (ADR-015).
- **Conséquences négatives** : SerieChoicePage charge mentale +200% Tle franco (12 cards vs 4) → mitigation groupement visuel famille. matrice.json +60% volumétrie. Tests +30-40 nouveaux cas.
- **Alternatives rejetées** :
  - Hiérarchique (groupe + sous-série) → rejeté par PO (overhead UX, gain pédagogique marginal).
  - Nouveau subSystem `anglophone_technique` → rejeté (incohérent avec `francophone/technique`).
  - Panier mono-mode → rejeté (impossible de couvrir O-Level + A-Level + opt-out simple + TVEE).
  - Validation panier serveur uniquement → rejeté (UX dégradée, latence).

### Change 4.4 — Updates doc/partage (livrées par Story 1.11a)

#### 4.4.1 — DONNEES-REFERENCE.md (extension matrice)

**Sections nouvelles/amendées** :

**Premier cycle francophone (matières ajoutées)** :

| ID Firestore | Matière |
|---|---|
| `francophone_lcn` | Langues et Cultures Nationales |
| `francophone_info` | Informatique (déjà partiel — formaliser) |
| `francophone_ea` | Éducation Artistique |
| `francophone_tm` | Travail Manuel |

**Tle francophone — séries v2 (nouvelles)** :

| ID série | Nom | Matières (avec IDs Firestore) |
|---|---|---|
| `francophone_terminale_a1` | A1 Lettres + Latin + Grec | FR, EN, Math, Philo, HG, EPS, **Latin**, **Grec**, **LV2** |
| `francophone_terminale_a2` | A2 Lettres + Latin + LV2 | FR, EN, Math, Philo, HG, EPS, **Latin**, LV2 |
| `francophone_terminale_a3` | A3 Lettres + Latin | FR, EN, Math, Philo, HG, EPS, **Latin** |
| `francophone_terminale_a4` | A4 Lettres + LV2 + Philo | FR, EN, Math, Philo, HG, EPS, LV2 |
| `francophone_terminale_a5` | A5 LV2 + LV3 + Philo | FR, EN, Math, Philo, HG, EPS, LV2, **LV3** |
| `francophone_terminale_abi` | ABI Lettres bilingues | FR + EN (parité), **Littérature**, Philo, HG, Math, **Intensive English**, **Oral Communication**, **Manual Labour** |
| `francophone_terminale_sh` | SH Sciences Humaines | FR, EN, Math, Philo, HG, EPS |
| `francophone_terminale_ac` | AC Art + Cinématographie | FR, EN, **Arts/Cinéma**, Philo, HG, EPS |
| `francophone_terminale_ti` | TI Technologie de l'Information | Math, **Physique**, **Informatique (algo+prog+BD+réseaux)**, FR, **Philo**, EN, EPS |

**Tle francophone — séries v1 (corrections)** :

| ID série | Correction |
|---|---|
| `francophone_terminale_c` | **Séparer** PCT → Physique + Chimie. **Retirer** LV2. **Ajouter** Informatique. Liste finale : Math, **Physique**, **Chimie**, SVT, FR, EN, Philo, HG, **Informatique**, EPS |
| `francophone_terminale_d` | **Séparer** PCT → Physique + Chimie. **Retirer** LV2. **Ajouter** Environnement/Hygiène/Biotechnologie, Informatique. Liste finale : Math, SVT, **Physique**, **Chimie**, **Environnement**, FR, EN, Philo, HG, **Informatique**, EPS |
| `francophone_terminale_e` | **Ajouter** Philo. Liste finale : Math, **Physique**, **Chimie**, **Techniques/Technologie**, FR, **Philo**, EN, EPS |
| `francophone_terminale_a` | **DÉPRÉCATION**. `isActive: false`. Conservée pour rétrocompat données existantes. Les nouveaux élèves Tle A choisissent A1-A5/ABI/SH/AC. |

**O-Level anglophone — matières ajoutées (4)** :

| ID Firestore | Code GCE | Matière |
|---|---|---|
| `anglophone_special_bilingual_french` | 0546 | Special Bilingual Education French |
| `anglophone_geology` | 0555 | Geology |
| `anglophone_human_biology` | 0565 | Human Biology |
| `anglophone_logic` | 0590 | Logic |
| `anglophone_accounting` | 0505 | Accounting (si manquant) |

**O-Level anglophone — règle panier** :

Sur `series/anglophone_form_5` (et Form 3, Form 4 pour préparation) :
- `pickerMode: 'free_with_obligatory'`
- `minSubjects: 6`
- `maxSubjects: 11` (avec Religious Studies) ou `10` sinon — à figer en 1.11a
- `obligatorySubjectIds: ['anglophone_english_lang', 'anglophone_french', 'anglophone_math']`

**A-Level anglophone — matières ajoutées (3)** :

| ID Firestore | Code GCE | Matière |
|---|---|---|
| `anglophone_a_special_bilingual_french` | 0746 | Special Bilingual Education French |
| `anglophone_philosophy` | 0790 | Philosophy |
| `anglophone_ict` | 0796 | Information and Communication Technology |
| `anglophone_pure_maths_mechanics` | 0765 | Pure Mathematics With Mechanics |
| `anglophone_pure_maths_stats` | 0770 | Pure Mathematics With Statistics |
| `anglophone_food_science_nutrition` | 0740 | Food Science and Nutrition |

**A-Level — règle panier sur Series (S1-S8, A1-A5)** :

- `pickerMode: 'series_plus_optional'`
- `minSubjects: 3` (Series obligatoires)
- `maxSubjects: 5`
- `obligatorySubjectIds: [Series subjects]`
- `optionalSubjectIds: ['anglophone_computer_science', 'anglophone_ict', 'anglophone_religious_studies', 'anglophone_commerce']`

**ESTP anglophone TVEE** :

Nouveau niveau (anglophone, filière technique) :
- `anglophone_tve_il` — TVE Intermediate Level (fin Form 5 technique)
- `anglophone_tve_al` — TVE Advanced Level (fin Upper Sixth technique)

Spécialités initiales (1.17, all `isActive: false` au seed initial) :

| Code | ID Firestore | Spécialité |
|---|---|---|
| ELEQ | `anglophone_tve_il_eleq` / `anglophone_tve_al_eleq` | Electrical Equipment |
| ELNI | `anglophone_tve_il_elni` / `anglophone_tve_al_elni` | Electronics |
| ELME | `anglophone_tve_il_elme` / `anglophone_tve_al_elme` | Electromechanical |
| ELET | `anglophone_tve_il_elet` / `anglophone_tve_al_elet` | Electrotechnique |
| AC | `anglophone_tve_il_ac` / `anglophone_tve_al_ac` | Air Conditioning & Refrigeration Technology |
| ME | `anglophone_tve_il_me` / `anglophone_tve_al_me` | Mechanical Engineering |
| CE | `anglophone_tve_il_ce` / `anglophone_tve_al_ce` | Civil Engineering / Building Construction |
| WW | `anglophone_tve_il_woodwork` / `anglophone_tve_al_woodwork` | Woodwork / Carpentry |
| ACC | `anglophone_tve_il_acc` / `anglophone_tve_al_acc` | Accounting (commercial) |
| COM | `anglophone_tve_il_commerce` / `anglophone_tve_al_commerce` | Commerce |
| OP | `anglophone_tve_il_op` / `anglophone_tve_al_op` | Office Practice |
| FN | `anglophone_tve_il_food_nutrition` / `anglophone_tve_al_food_nutrition` | Food and Nutrition |
| CT | `anglophone_tve_il_clothing_textiles` / `anglophone_tve_al_clothing_textiles` | Clothing & Textiles |

Règle TVEE (mode `tve_picker`) :
- `pickerMode: 'tve_picker'`
- TVE IL : `minSubjects: 5` avec ≥2 Professional + ≥1 Related + EN + FR obligatoires
- TVE AL : `minSubjects: 6` `maxSubjects: 8` avec ≥3 Professional + ≥3 Related
- Champs nouveaux sur `series` TVEE : `professionalSubjectIds[]`, `relatedProfessionalSubjectIds[]`, `otherSubjectIds[]` (optionnels libres)

**Update historique DONNEES-REFERENCE.md** : ligne ajoutée 2026-06-09.

#### 4.4.2 — BASE-DE-DONNEES.md (extension schema)

**Section `series`** : ajout 3 champs

```typescript
interface SeriesV2 {
  // ... champs existants v1 ...
  pickerMode?: 'derived' | 'opt_out' | 'free_with_obligatory' | 'series_plus_optional' | 'tve_picker';  // default 'derived' si absent
  minSubjects?: number;  // default null (pas de min)
  maxSubjects?: number;  // default null (pas de max)
}
```

**Section `derivation_rules`** : ajout 2 champs

```typescript
interface DerivationRuleV2 {
  // ... champs existants v1 ...
  obligatorySubjectIds?: string[];  // matières non décochables (pour mode free_with_obligatory ou tve_picker)
  optionalSubjectIds?: string[];     // matières optionnelles ajoutables (pour mode series_plus_optional)
}
```

**Section `series` TVEE supplémentaire** :

```typescript
interface SeriesTVE extends SeriesV2 {
  pickerMode: 'tve_picker';
  professionalSubjectIds: string[];        // matières professionnelles obligatoires
  relatedProfessionalSubjectIds: string[]; // matières related professional
  otherSubjectIds: string[];               // matières libres
}
```

**Section `users/{uid}` extension** : ajout champ optionnel `pickedSubjects[]` (utilisé si profil créé avec un mode panier — sinon vide, derivedSubjects + optedOutSubjects suffisent).

**Indexes composites** : aucun nouvel index nécessaire. Les nouveaux champs sont lus sur docs déjà filtrés par index existants.

**Règles d'accès** : inchangées (catalogue read auth, write false, `users/{uid}` self-only).

**Update accord backend** : commenter `@backend-team` dans la PR 1.11a pour approbation des 5 nouveaux champs catalogue + 1 champ `users/{uid}`.

#### 4.4.3 — ALGORITHMES.md § 1 update

L'algo `derive()` retourne désormais `DerivedProfile` enrichi :

```typescript
interface DerivedProfile {
  subjects: Subject[];           // toutes matières (existant)
  examTargets: ExamTarget[];     // (existant)
  canOptOut: boolean;            // (existant)
  // NOUVEAUX (1.13)
  pickerMode: PickerMode;        // 'derived' (default) | 'opt_out' | 'free_with_obligatory' | 'series_plus_optional' | 'tve_picker'
  obligatorySubjects: Subject[]; // sous-ensemble de subjects, non décochable
  optionalSubjects: Subject[];   // matières ajoutables (transversales A-Level)
  minSubjects: number | null;    // null = pas de min
  maxSubjects: number | null;
}
```

Pseudo-code étendu :

```typescript
function derive(profile: Profile): DerivedProfile {
  const rule = matchFirstActive(profile);  // existant
  const subjects = mapSubjects(rule.subjectIds);
  
  // Nouveau v2
  const series = getSeries(profile.serieId);
  const pickerMode = series.pickerMode ?? 'derived';
  const obligatorySubjects = mapSubjects(rule.obligatorySubjectIds ?? []);
  const optionalSubjects = mapSubjects(rule.optionalSubjectIds ?? []);
  
  return {
    subjects, examTargets, canOptOut: series.canOptOut ?? false,
    pickerMode, obligatorySubjects, optionalSubjects,
    minSubjects: series.minSubjects, maxSubjects: series.maxSubjects,
  };
}
```

### Change 4.5 — Update PRD (livré par Story 1.11b)

#### 4.5.1 — § FR-2 : Remplissage profil scolaire en étapes

**OLD** : "Un utilisateur peut remplir son profil scolaire en **trois étapes obligatoires** (filière → niveau → série), et voit les matières + examens dérivés automatiquement."

**NEW** : "Un utilisateur peut remplir son profil scolaire en **3 étapes** (filière → niveau → série), avec une liste de séries variable selon profil. La step série affiche jusqu'à 12 cards pour Tle francophone générale (A1-A5 + ABI + SH + AC + C/D/E/TI) avec groupement visuel par famille, ou un picker panier pour anglophone O-Level et A-Level, ou un parcours dédié pour ESTP anglophone TVEE."

**Consequences testable amendments** :
- Ajout : "Un profil francophone Tle A1 montre `[FR, EN, Math, Philo, HG, EPS, Latin, Grec, LV2]` (9 matières)."
- Ajout : "Un profil anglophone Form 5 avec panier voit 6-11 matières sélectionnées avec EN+FR+Math obligatoires."
- Ajout : "Un profil anglophone TVE AL Electrotechnique voit 6-8 matières avec ≥3 Professional + ≥3 Related."

#### 4.5.2 — § FR-3 : Retrait/sélection conditionnel(le) de matières

**OLD** : "Un utilisateur dans les cas autorisés (anglophones ≥ Form 3, ou Lower/Upper Sixth toutes filières) peut **retirer** des matières de sa liste dérivée."

**NEW** : "Un utilisateur dans les cas autorisés peut **sélectionner ou retirer** des matières selon le mode défini par sa série :
- **Mode `derived`** (default — Tle franco) : pas de modification possible
- **Mode `opt_out`** (anglo Lower/Upper Sixth — legacy 1.4) : retrait simple
- **Mode `free_with_obligatory`** (Form 3-5 O-Level) : sélection libre 6-11 matières, EN+FR+Math obligatoires
- **Mode `series_plus_optional`** (Lower/Upper Sixth A-Level — extension) : Series fixe + transversales optionnelles, max 5
- **Mode `tve_picker`** (TVE IL/AL anglo) : Professional + Related obligatoires, Other Subjects libres avec quotas"

### Change 4.6 — Update EXPERIENCE.md Flow 1 (livré par Story 1.11b)

**Section** : Flow 1 § Step série (étape 5)

**Ajout 4 variants UX** :

1. **Variant Tle franco générale** : 12 cards (au lieu de 4) groupées visuellement par famille (Lettres : A1, A2, A3, A4, A5, ABI ; Sciences humaines : SH, AC ; Sciences : C, D ; Sciences techniques : E, TI). Scroll vertical attendu sur Pixel 4a.
2. **Variant anglophone Form 3-5 (panier O-Level)** : après step niveau, page picker dédiée. Pre-coche EN+FR+Math (verrouillées) + 6 suggestions populaires (peuvent décocher). Compteur "Tu présentes X/11 matières" en bas. Validation : disable bouton si X < 6 ou X > 11.
3. **Variant anglophone Lower/Upper Sixth (panier A-Level)** : choix Series (existant) puis page d'extension transversale. Series fige 3-4 matières (verrouillées). 4 checkboxes optionnelles (Computer Science, ICT, Religious Studies, Commerce). Compteur "X/5 matières".
4. **Variant anglophone TVEE** : après choix filière "Technique", liste filière technique → niveau (TVE IL ou TVE AL) → spécialité (10+ cards groupées Industrial / Commercial / Home Economics). Picker avec Professional verrouillées + Related obligatoires + Other Subjects libres avec quota selon TVE IL/AL.

### Change 4.7 — Mises à jour mobile (livrées par Stories 1.13-1.17)

Détails techniques par story :

- **1.13** : `lib/core/catalogue/models.dart` ajout champs `DerivedProfile` (defaults safe). `CatalogueRepository.derive()` mapping étendu. Tests régression Fatou/James (mode `derived` par défaut → comportement identique).
- **1.14** : `lib/features/onboarding/presentation/serie_choice_page.dart` adaptation `LayoutBuilder` + `ListView.builder` avec sections (familles) + tags Lucide par famille (BookOpen pour Lettres, Atom pour Sciences, etc.). i18n FR/EN 12 nouvelles clés noms série.
- **1.15** : `subjects_opt_out_page.dart` → `subjects_picker_page.dart`. `switch (derivedProfile.pickerMode)` rendant 3 widgets : `_OptOutBody` (legacy), `_FreeWithObligatoryBody` (O-Level), placeholder `_SeriesPlusOptionalBody` (1.16). Validation min/max + obligatoires inline. Tests Mariam (Form 5, 8 matières dont EN+FR+Math).
- **1.16** : `_SeriesPlusOptionalBody` impl complète. Tests James Upper Sixth S2 + ICT optionnel.
- **1.17** : nouveau widget `_TvePickerBody` + route `/onboarding/profile/tve-spec` (niveau TVE IL/AL → spécialité). Updates pubspec si besoin (peu probable). Tests Eyong Eboa (TVE AL Electrotechnique 7 matières).

### Change 4.8 — firestore.rules update (livré par Story 1.15)

**Section** : `match /users/{uid}` règle update

**Ajout règle validation `pickedSubjects`** :

```javascript
// Validation pickedSubjects pour modes panier
function pickedSubjectsValid(data) {
  let picked = data.get('pickedSubjects', []);
  let derived = data.derivedSubjects;
  let obligatory = data.get('obligatorySubjectIds', []);
  let optional = data.get('optionalSubjectIds', []);
  
  // pickedSubjects ⊂ (derivedSubjects ∪ optionalSubjectIds)
  return picked.toSet().difference(derived.toSet().union(optional.toSet())).size() == 0
      // obligatorySubjectIds ⊂ pickedSubjects
      && obligatory.toSet().difference(picked.toSet()).size() == 0;
}
```

Test ajouté dans `test/rules/users.test.mjs` : (n) pickedSubjects valide OK, (o) obligatoire manquant KO, (p) extra hors derived/optional KO.

## 5. Implementation Handoff

### Scope classification

**Major** — pas de pivot architectural (Firestore-driven préservé) mais :
- +8 nouvelles stories (~31-36h)
- Touche PRD (FR-2, FR-3) et UX (Flow 1)
- Touche surface partagée `doc/partage/*` (accord backend requis)
- Touche modélisation Firestore (5 nouveaux champs catalogue + 1 champ users/{uid})
- Élargit le critère de sortie Epic 1

### Handoff plan

| Action | Owner | Skill BMAD | Timing |
|---|---|---|---|
| **Merge cette PR** (sprint-change-proposal + amendments epic-1 + sprint-status) | User (review + merge) | — | J0 |
| **Notifier backend team** (via PR 1.11a) des updates BASE-DE-DONNEES.md (5 nouveaux champs) | User | — | J0 |
| **Créer Story 1.11a** | User | `/bmad-create-story` | J1 |
| **Implémenter 1.11a** (audit matrice v2 + ADR-016 + BASE-DE-DONNEES + ALGORITHMES updates) | Amelia | `/bmad-dev-story` | J1 |
| **Approbation backend BASE-DE-DONNEES.md** (commentaire PR 1.11a) | Backend team | — | J1-J2 async |
| **Créer + Implémenter 1.11b** (PRD + UX updates) | User + Amelia | `/bmad-create-story` + `/bmad-dev-story` | J2 |
| **Créer + Implémenter 1.12** (matrice.json + re-seed) | User + Amelia + porteur Firebase | `/bmad-create-story` + `/bmad-dev-story` | J2-J3 |
| **Créer + Implémenter 1.13** (DerivedProfile extension) | User + Amelia | `/bmad-create-story` + `/bmad-dev-story` | J2-J3 parallèle 1.12 |
| **Créer + Implémenter 1.14** (sous-séries flat) | User + Amelia | `/bmad-create-story` + `/bmad-dev-story` | J4 |
| **Créer + Implémenter 1.15** (refactor picker O-Level) | User + Amelia | `/bmad-create-story` + `/bmad-dev-story` | J4-J5 |
| **Créer + Implémenter 1.16** (A-Level transversales) | User + Amelia | `/bmad-create-story` + `/bmad-dev-story` | J5 |
| **Créer + Implémenter 1.17** (ESTP TVEE) | User + Amelia | `/bmad-create-story` + `/bmad-dev-story` | J5-J7 parallèle 1.14/1.15 possible |
| **Re-run seed Firestore valide-edu post-1.12 merge** | User (porteur Firebase) | — | J3 P1+ |
| **Smoke device Mariam (Form 5 picker) + Eyong (TVE AL) post-Epic 1 v2** | User | — | J8 |
| **Epic 1 retrospective v2** | User | `/bmad-retrospective` | J8 |

### Success criteria

- [ ] Cette PR mergée sur main
- [ ] Backend team notifiée et confirmera review BASE-DE-DONNEES.md en PR 1.11a
- [ ] Stories 1.11a, 1.11b, 1.12, 1.13, 1.14, 1.15, 1.16, 1.17 créées dans `implementation-artifacts/`
- [ ] `sprint-status.yaml` cohérent avec nouvelle structure Epic 1 v2 (20 stories au total)
- [ ] `epic-1-onboarding.md` mis à jour avec 8 sections nouvelles + amendments 1.3/1.4/1.1c
- [ ] Post-merge Story 1.17 : Mariam (Form 5 panier 8 matières) + Eyong (TVE AL Electrotechnique 7 matières) + Aïssatou (Tle A1 Lettres+Latin+Grec) peuvent compléter l'onboarding en < 2min
- [ ] Cumul `flutter test` post-Epic 1 v2 : ≥ 240 tests verts (+30-35 vs baseline 205)

### Risks à surveiller post-merge

1. **Surcharge porteur post-1.12** : porteur doit re-seeder matrice v2 sur valide-edu. Idempotent mais critique. Mitigation : README.md `scripts/firebase_seed/` mis à jour avec procédure.
2. **Backend slow review** : si `BASE-DE-DONNEES.md` updates traînent, 1.11a est bloquée et P1 dérape. Mitigation : escalade async + commit doc/partage avec note "pending backend approval".
3. **Régression test panier** : refactor 1.15 (`SubjectsOptOutPage` → `SubjectsPickerPage`) doit préserver tests existants Story 1.4 (mode legacy `opt_out`). Mitigation : test régression Fatou (mode `derived` → aucun picker) + James (mode `opt_out` → picker simple) avant 1.15 merge.
4. **TVEE complexité** : Story 1.17 = L (6-8h), nouveau domaine. Mitigation : seedé `isActive: false` initial, activable progressivement. Si 1.17 déborde → split 1.17a (data + matrice TVEE) + 1.17b (flow UI TVEE).
5. **Estimation timeline** : 7-8j cumulés post-1.10. Si déborde, déférer 1.17 (TVEE) en début Epic 2.

## 6. Approval

### User approval

- [ ] PO Delano Roosvelt approuve ce sprint change proposal v2
- [ ] User confirme que P1 timeline peut être étendue de 7-8 jours
- [ ] User notifie backend team async pour la PR 1.11a à venir (commentaire `@backend-team` sur la PR)
- [ ] User valide les décisions ADR-016 (flat sous-séries + filière technique anglo TVEE + panier polymorphe)

### Approval signature

| Role | Name | Date | Signature |
|---|---|---|---|
| PO | Delano Roosvelt | 2026-06-09 | _PR merge = approval_ |
| PM agent | Claude Opus 4.7 | 2026-06-09 | (auto) |
| Backend lead | TBD | TBD | _async via PR 1.11a comment_ |

---

**Sprint Change Proposal v1 — généré par `/bmad-correct-course` le 2026-06-09. Source d'audit : doc utilisateur "Orientation et matières au secondaire camerounais" (2026-06-09) + Office du Baccalauréat (officedubac.cm) + Cameroon GCE Board (camgceb.org).**
