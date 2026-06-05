---
date: 2026-06-05
sprint: P1
triggering_story: Story 1.1 — Audit R4 matrice MINESEC/GCE + seed catalogue local
scope_classification: Moderate
status: pending-approval
author: Delano Roosvelt (PO) + Claude (PM agent via /bmad-correct-course)
---

# Sprint Change Proposal — Story 1.1 pivot Firestore-driven catalogue

## 1. Issue Summary

### Problem statement

La **Story 1.1** (PR `docs/story-1.1-context` mergée 2026-06-05, statut `ready-for-dev`, pas encore implémentée) prévoyait un **seed JSON local statique** (`assets/onboarding/catalogue_subjects.json`) embarqué dans le binaire de l'app + un helper Dart pur `derive()`. Cette approche optimisait latence et offline-first mais **empêchait toute évolution du catalogue** (ajout d'une matière, activation progressive d'une série selon la production de contenu, retrait d'une filière obsolète) sans rebuild + redéploiement sur les stores.

Le PO demande un **pivot architectural** vers Firestore comme source de vérité dynamique, avec un flag `isActive: bool` sur chaque entité (filière, niveau, série, matière, examTarget) permettant à un admin pédagogique d'activer/désactiver runtime depuis Firebase Console **sans cycle de release mobile**.

### Categorisation

**Strategic pivot** — nouveau requirement émergeant après planning, motivé par flexibilité opérationnelle.

### Evidence (citations user verbatim)

> « On souhaite gerer toutes les classe meme celle qui ne sont pas des classe d'examen »
> « Les classes et autres doivent venir du firebase »
> « on doit pouvoir desactiver une classse ou une filiere ou une section bref on activeras fonction des donnees au fur a mesure »
> « On dois pouvoir changer tout depuis le firebase activer et desactiver »

### Décisions complémentaires capturées (AskUserQuestion)

| Aspect | Décision PO |
|---|---|
| **Seed initial Firestore** | Dossier `scripts/firebase_seed/` avec script **Python** (admin SDK) |
| **Boot offline 1er lancement** | Écran « En attente de connexion » bloquant — pas de fallback JSON local |
| **Périmètre classes** | **TOUTES** classes (1er cycle + 2nd cycle A/C/D/E + technique F1-F5 + G1-G3 + autres ESF/IH/MVT + anglophone Form 1-5 + Lower/Upper Sixth complet S1-S8 + A1-A5) |
| **Action management** | `/bmad-correct-course` (cette session) |

## 2. Impact Analysis

### Epic Impact

- **Epic 1 (Onboarding & Profil scolaire)** — ✅ goal inchangé, structure modifiée. 4 stories impactées (1.1 cancelled, 1.3/1.4/1.9 amendées, 3 nouvelles 1.1a/1.1b/1.1c)
- **Epic 0** — ✅ aucun impact (foundation done)
- **Epic 2 (Navigation contenu)** — ⚠️ léger impact à anticiper quand E2 sera décomposé : stories E2 doivent gérer `subject.isActive == false`
- **Epic 3 (Quiz)** — ✅ aucun impact direct
- **Epic 4 (Freemium)** — ✅ aucun impact
- **Epic 5 (Santé/Gamif)** — ⚠️ léger : classements par matière filtrer sur `isActive`
- **Epic 6** — ✅ aucun impact

### Story Impact (Epic 1)

| Story | Statut | Type changement |
|---|---|---|
| **1.1** Audit R4 + seed catalogue local | **CANCELLED** (superseded) | Remplacée par 1.1a + 1.1b + 1.1c |
| **1.1a** Audit matrice exhaustive + Firestore schema + ADR-015 + BASE-DE-DONNEES update | **NEW** (Backlog) | Research/docs, S ~3-4h, accord backend requis |
| **1.1b** Script Python `scripts/firebase_seed/seed_catalogue.py` + matrice source + tests | **NEW** (Backlog) | M ~4-5h, dépend 1.1a |
| **1.1c** `CatalogueRepository` mobile (lecture Firestore + cache offline + isActive filter) + écran connexion bloquant + tests | **NEW** (Backlog) | M ~4-5h, dépend 1.1a (parallèle 1.1b possible) |
| **1.2** Choix sous-système | ✅ inchangée | — |
| **1.3** Flow profil 3 étapes | **AMENDED** | AC enrichis : lecture catalogue via `CatalogueRepository` Firestore (au lieu de seed local), loading state inter-étape, dépend désormais 1.1c |
| **1.4** Retrait conditionnel matières | **AMENDED** | `canOptOut` lu depuis `series/{id}.canOptOut` Firestore au lieu de JSON |
| **1.5** Garde nav profil-incomplet | ✅ inchangée | — |
| **1.6** Compte Google/Apple | ✅ inchangée | — |
| **1.7** Liaison école | ✅ inchangée | — |
| **1.8** Persistance session | ✅ inchangée | — |
| **1.9** Dashboard skeleton | **AMENDED** | Lecture matières dérivées filtrées par `subject.isActive == true` Firestore |
| **1.10** Suppression compte | ✅ inchangée | — |

**Estimation Epic 1 totale** : 39-48h → **51-63h** (+12-15h). P1 1 semaine = 40h serré → extension à 6-7j OU déférer 1.7 + 1.10 en début P2.

### Artifact Conflicts

| Artefact | Type modification | Accord requis |
|---|---|---|
| `doc/partage/BASE-DE-DONNEES.md` | Ajout 6 collections (`filieres`, `niveaux`, `series`, `subjects`, `exam_targets`, `derivation_rules`) + champ `isActive` + indexes composites + règles d'accès | **Oui — équipe backend** (CLAUDE.md règle § doc/partage) |
| `doc/partage/DONNEES-REFERENCE.md` | Update : matrice complétée 🟢, destination = Firestore (pas seed JSON), mention du script Python init | Update interne |
| `doc/partage/ALGORITHMES.md § 1` | Update mineur : algo dérivation peut être Cloud Function backend OU helper Dart client | Update interne |
| `doc/partage/CONTRATS-API.md` | Aucun impact | — |
| `project_manage/planning-artifacts/architecture/architecture.md` § 14 | Ajout ADR-015 référence | Update interne |
| **NEW** `project_manage/planning-artifacts/architecture/adrs/ADR-015-catalogue-firestore-runtime-activation.md` | Création | Création par /bmad-create-architecture ou par dev en Story 1.1a |
| `project_manage/planning-artifacts/epics/epic-1-onboarding.md` | Remplacer § Story 1.1 par § Stories 1.1a/b/c + amender § 1.3/1.4/1.9 + update graphe dépendances + update coverage tables | **Cette PR** |
| `project_manage/planning-artifacts/ux-designs/.../EXPERIENCE.md` | Ajout dans Flow 1 : « Loading state inter-étape lecture catalogue » + « Edge case 1er lancement offline → écran bloquant » | Update en Story 1.1c (ou cette PR) |
| `project_manage/implementation-artifacts/sprint-status.yaml` | Marquer 1-1-audit-r4-matrice-seed-catalogue: cancelled + ajouter 1-1a, 1-1b, 1-1c en backlog | **Cette PR** |
| `project_manage/implementation-artifacts/1-1-audit-r4-matrice-seed-catalogue.md` | Banner SUPERSEDED + status cancelled + référence à ce proposal | **Cette PR** |
| `firestore.rules` (racine) | Ajout règles pour 6 nouvelles collections (read auth, write false) | Story 1.1c ou Story 1.1b |
| `firestore.indexes.json` (racine) | Ajout 3 indexes composites | Story 1.1c |
| **NEW** `scripts/firebase_seed/` | Création dossier complet (Python script + matrice source + requirements + README + .gitignore) | Story 1.1b |
| `mobile_app/pubspec.yaml` | **PAS** d'ajout `assets/onboarding/` (le seed local n'est plus livré) | Aucune action — différent du plan initial |
| `mobile_app/.gitignore` | Vérifier `service-account.json` couvert | Story 1.1b |
| **NEW** `mobile_app/lib/core/catalogue/catalogue_repository.dart` (et fichiers liés) | Création repository Firestore | Story 1.1c |

### Technical Impact

- **Performance** : ⚠️ lecture Firestore au 1er chargement profil ajoute 200-800ms en 3G. Cache offline natif (Story 0.7) résout dès le 2ᵉ chargement. Acceptable.
- **NFR-2 démarrage < 3s** : profilage à faire en Story 1.1c. Splash + Anonymous Auth + lecture catalogue → marge serrée mais tenable.
- **Sécurité** : write Firestore = false côté mobile (admin uniquement via Console ou script Python serveur). Catalogue = données publiques (pas de PII).
- **CI/CD (0.17 deferred)** : pas de nouvelle dépendance CI. Tests Python du script s'exécutent localement.
- **Dépendances pubspec** : aucune nouvelle (déjà `cloud_firestore` ^6.5.0 via Story 0.6).

## 3. Recommended Approach

### Approche sélectionnée

**Option 1 — Direct Adjustment** avec **split Story 1.1 en 3 sous-stories séquentielles** (1.1a → 1.1b/1.1c parallèles).

### Justification

1. **Single dev session** respectée — chaque sous-story reste 3-5h, conforme à la règle BMAD.
2. **Découplage contrats vs implémentation** — 1.1a livre les contrats (schéma Firestore + ADR-015 + BASE-DE-DONNEES update) validables par backend séparément avant tout code.
3. **Parallélisation Python/Dart** — 1.1b (Python) et 1.1c (Dart) peuvent être développées en parallèle après 1.1a, exploitant 2 stacks séparées.
4. **Continuité downstream** — 1.1c remplace 1.1 comme story bloquante pour 1.3 (graphe dépendances inchangé en topologie).
5. **Pas de rollback nécessaire** — Story 1.1 actuelle = document markdown, pas de code Dart à reverter.

### Alternatives considérées et rejetées

- **Option 2 (Rollback)** — ❌ Non applicable, rien à rollback.
- **Option 3 (MVP Review)** — ❌ MVP toujours atteignable, aucune feature à retirer. Au contraire, le pivot Firestore **renforce** AS-2 du PRD (catalogue produit en parallèle équipe pédagogique).
- **Variant Story 1.1 unique L (10-12h)** — ❌ Trop gros, débordement single dev session, perte de parallélisation Python/Dart.
- **Variant seed JSON local conservé + Firestore optionnel V2** — ❌ Refusé par PO, le besoin d'activation runtime est immédiat.

### Effort estimate

**+12-15h** sur Epic 1 (de 39-48h → 51-63h). Cible P1 ~40h serré. Options absorption :
- Élargir P1 à 6-7j calendaires
- OU déférer 1.7 (Liaison école) et 1.10 (Suppression compte) en début P2

### Risk assessment

- **Risque dépendance backend** : moyen-faible. BASE-DE-DONNEES.md updates nécessitent accord backend. Mitigation : 1.1a livre le diff documenté, PR peut être validée async par backend.
- **Risque latence 1er chargement** : faible. Cache offline Firestore (Story 0.7) déjà actif. Écran connexion bloquant (UX-DR-24) gère l'edge case.
- **Risque seed Firestore manquant** : faible. Script Python documenté + procédure d'init dans README + porteur exécute.

### Timeline impact

P1 étendue de 1 semaine à **6-7 jours calendaires**. Pas d'impact sur P2-P6.

## 4. Detailed Change Proposals

### Change 4.1 — Sprint-status.yaml : renommer/ajouter stories Epic 1

**Section** : `development_status` → Epic 1

**OLD** (extrait actuel) :
```yaml
  epic-1: in-progress
  1-1-audit-r4-matrice-seed-catalogue: ready-for-dev  # 2026-06-05 ...
  1-2-choix-sous-systeme-bascule-i18n: backlog
  1-3-flow-profil-scolaire-3-etapes: backlog
  1-4-retrait-conditionnel-matieres: backlog
  ...
```

**NEW** :
```yaml
  epic-1: in-progress  # 2026-06-05 ... + sprint change 2026-06-05 (pivot Firestore Story 1.1)
  1-1-audit-r4-matrice-seed-catalogue: cancelled  # 2026-06-05 SUPERSEDED par sprint-change-proposal-2026-06-05.md (pivot Firestore). Story file conservée en archive avec banner SUPERSEDED.
  1-1a-audit-matrice-firestore-schema: backlog  # 2026-06-05 NEW (sprint change). Audit matrice exhaustive + schéma Firestore + ADR-015 + BASE-DE-DONNEES.md update (accord backend requis). Estim S ~3-4h.
  1-1b-script-python-seed-catalogue: backlog  # 2026-06-05 NEW. scripts/firebase_seed/seed_catalogue.py + matrice JSON source + README + tests. Estim M ~4-5h. Depends 1.1a.
  1-1c-catalogue-repository-mobile: backlog  # 2026-06-05 NEW. CatalogueRepository Firestore + cache offline + isActive filter + écran connexion bloquant + tests. Estim M ~4-5h. Depends 1.1a (parallèle 1.1b possible).
  1-2-choix-sous-systeme-bascule-i18n: backlog
  1-3-flow-profil-scolaire-3-etapes: backlog  # AMENDED : dépend 1.1c (CatalogueRepository) au lieu de 1.1
  1-4-retrait-conditionnel-matieres: backlog  # AMENDED : canOptOut Firestore-driven
  ...
  1-9-dashboard-skeleton-filtrage-profil: backlog  # AMENDED : filter isActive Firestore
  ...
```

**Rationale** : tracker visible des 3 nouvelles stories + mention claire de l'amendement sur les downstream.

### Change 4.2 — Marquer Story 1.1 superseded

**Fichier** : `project_manage/implementation-artifacts/1-1-audit-r4-matrice-seed-catalogue.md`

**Action** : ajouter banner au début du fichier (sous frontmatter) et changer status frontmatter.

**OLD frontmatter** :
```yaml
status: ready-for-dev
```

**NEW frontmatter** :
```yaml
status: cancelled
superseded_by: sprint-change-proposal-2026-06-05.md
```

**NEW banner au début du body** :
```markdown
> ⚠️ **SUPERSEDED 2026-06-05** par [sprint-change-proposal-2026-06-05.md](../planning-artifacts/sprint-change-proposal-2026-06-05.md).
>
> Cette story a été annulée suite à un pivot architectural (Firestore-driven catalogue avec `isActive` runtime). Elle est remplacée par les Stories 1.1a, 1.1b, 1.1c décomposées dans `epic-1-onboarding.md`.
>
> Le contenu ci-dessous est conservé en archive pour traçabilité de la décision initiale.
```

**Rationale** : préserve la traçabilité historique sans casser de liens / référencement.

### Change 4.3 — Epic-1-onboarding.md : remplacer § Story 1.1 par 1.1a/b/c + amender 1.3/1.4/1.9

**Fichier** : `project_manage/planning-artifacts/epics/epic-1-onboarding.md`

**Modifications principales** :

1. **Frontmatter** : `storyCount: 10` → `storyCount: 12` (suppression 1.1, ajout 1.1a/b/c = +2 net)
2. **Goal et Out of scope** : inchangés
3. **Dependency graph** : remplacer `1.1 (audit R4 + seed)` par `1.1a (audit + schema) → {1.1b (script Python), 1.1c (CatalogueRepository)}`
4. **§ Story 1.1** lignes 70-141 : **remplacer entièrement** par 3 nouvelles sections § Story 1.1a, § Story 1.1b, § Story 1.1c
5. **§ Story 1.3** : ajouter mention dépendance 1.1c + AC supplémentaire pour loading state + écran connexion bloquant
6. **§ Story 1.4** : modifier note `canOptOut` lu depuis Firestore
7. **§ Story 1.9** : modifier AC pour `isActive == true` filter
8. **§ Couverture des exigences** : ligne 1.1 → 1.1a (R4 audit) + ligne notes Firestore
9. **§ Estimation totale** : table mise à jour avec 1.1a/b/c et nouveau total 51-63h
10. **§ Notes transversales** : ajouter mention pivot Firestore + nouvelles dépendances backend

**Détail § Story 1.1a (nouveau)** :
- Titre : « Audit matrice exhaustive MINESEC/GCE + schéma Firestore + ADR-015 + BASE-DE-DONNEES update »
- Estim : S (~3-4h)
- Goal : compléter matrice toutes classes + définir collections Firestore (`filieres`, `niveaux`, `series`, `subjects`, `exam_targets`, `derivation_rules`) avec `isActive` + indexes + règles d'accès + écrire ADR-015 + mettre à jour BASE-DE-DONNEES.md
- Output : docs uniquement (pas de code Dart ni Python)
- Dépend : aucune
- Bloque : 1.1b, 1.1c

**Détail § Story 1.1b (nouveau)** :
- Titre : « Script Python `seed_catalogue.py` + matrice source + procédure d'init »
- Estim : M (~4-5h)
- Goal : créer `scripts/firebase_seed/seed_catalogue.py` (firebase-admin SDK), `data/matrice.json` source de vérité versionnée, `requirements.txt`, `README.md`, `.gitignore` (service-account.json), tests Python basiques
- Output : dossier `scripts/firebase_seed/` complet
- Dépend : 1.1a
- Action porteur post-merge : run script pour peupler Firestore

**Détail § Story 1.1c (nouveau)** :
- Titre : « CatalogueRepository mobile + écran connexion bloquant + tests »
- Estim : M (~4-5h)
- Goal : `lib/core/catalogue/catalogue_repository.dart` (lecture Firestore avec cache offline, filtre `isActive == true`, helper `derive()` côté client OU appel Cloud Function backend selon décision 1.1a), provider Riverpod, écran « En attente de connexion » bloquant si Firestore vide au 1er lancement (UX-DR-24), tests
- Output : code Dart + tests
- Dépend : 1.1a (peut paralléliser 1.1b)
- Bloque : 1.3, 1.9

**Détail amendement § Story 1.3** :
- Dépendances : ajouter `1.1c (CatalogueRepository)`
- Nouvelle AC : « Loading state inter-étape lecture catalogue avec skeleton (UX-DR-13). Edge case : si Firestore offline + vide → écran connexion bloquant »
- Note technique : remplacer `OnboardingCatalogue.load()` par `ref.watch(catalogueProvider).derive(...)`

**Détail amendement § Story 1.4** :
- Note technique : `_canOptOut(subSystem, niveau)` lit `series/{id}.canOptOut` depuis Firestore (via CatalogueRepository) au lieu de hardcoded en Dart

**Détail amendement § Story 1.9** :
- AC2 modifiée : `derivedSubjects \ optedOutSubjects` filtré par `subject.isActive == true` depuis Firestore

### Change 4.4 — ADR-015 (création différée à Story 1.1a)

Pas créé dans cette PR. Sera créé par dev en Story 1.1a (avec /bmad-create-architecture ou directement).

**Contenu attendu** :
- Statut : Accepté
- Décision : « Catalogue scolaire stocké en Firestore avec flag `isActive` runtime, seed via script Python externe »
- Justification : besoin admin de modifier sans rebuild, alignement ADR-003 (Firebase full backend), AS-2 PRD
- Conséquences positives : flexibilité runtime, alignement archi, activation progressive
- Conséquences négatives : dépendance Firestore au 1er lancement (mitigée cache offline + écran bloquant), latence légère, dépendance soft backend
- Alternatives rejetées : seed local statique, Cloud Function intermédiaire

### Change 4.5 — Mises à jour doc/partage (différées Story 1.1a)

`doc/partage/BASE-DE-DONNEES.md` + `DONNEES-REFERENCE.md` + `ALGORITHMES.md` seront modifiés en Story 1.1a (avec accord backend pour BASE-DE-DONNEES).

## 5. Implementation Handoff

### Scope classification

**Moderate** — backlog reorganization significatif (3 nouvelles stories + 3 amendments) + nouveau dossier `scripts/firebase_seed/` + accord backend requis sur BASE-DE-DONNEES.md.

### Handoff plan

| Action | Owner | Skill BMAD | Timing |
|---|---|---|---|
| **Merge cette PR** (sprint-change-proposal + amendments epic-1 + sprint-status + banner Story 1.1) | User (review + merge) | — | J0 (immédiat) |
| **Notifier backend team** des updates BASE-DE-DONNEES.md à venir en 1.1a | User | — | J0 |
| **Créer Story 1.1a** (file dans implementation-artifacts/) | User | `/bmad-create-story` | J1 |
| **Implémenter 1.1a** (audit + schema + ADR-015 + BASE-DE-DONNEES + DONNEES-REFERENCE + ALGORITHMES updates) | Amelia | `/bmad-dev-story` | J1-J2 P1 |
| **Approbation backend BASE-DE-DONNEES.md updates** (commentaire PR 1.1a) | Backend team | — | J2 P1 async |
| **Créer Story 1.1b** | User | `/bmad-create-story` | J2 P1 |
| **Implémenter 1.1b** (script Python) | Amelia | `/bmad-dev-story` | J2-J3 P1 |
| **Créer Story 1.1c** | User | `/bmad-create-story` | J2 P1 (parallèle 1.1b) |
| **Implémenter 1.1c** (CatalogueRepository + écran bloquant) | Amelia | `/bmad-dev-story` | J2-J4 P1 |
| **Run script seed sur Firestore valide-edu** | User (porteur Firebase) | — | J4 P1 après 1.1b mergée |
| **Continuer Stories 1.2, 1.3** (Epic 1 onboarding flow) | Amelia | `/bmad-create-story` + `/bmad-dev-story` | J5+ P1 |
| **(Optionnel) Update PRD pour traçabilité du pivot** | User | `/bmad-prd` (intent: Update) | post-P1 |

### Success criteria

- [ ] Cette PR mergée sur main
- [ ] Backend team notifiée et a confirmé qu'elle reviewera BASE-DE-DONNEES.md updates en PR 1.1a
- [ ] Stories 1.1a, 1.1b, 1.1c créées dans implementation-artifacts/
- [ ] Story 1.1 fichier porte le banner SUPERSEDED et status cancelled
- [ ] sprint-status.yaml cohérent avec nouvelle structure Epic 1
- [ ] epic-1-onboarding.md mis à jour avec 12 stories (1.1 cancelled + 1.1a/b/c + 1.2-1.10)
- [ ] Aucune story aval mentionne encore `assets/onboarding/catalogue_subjects.json` (search & replace effectué)

### Risks à surveiller post-merge

1. **Backend slow review** : si BASE-DE-DONNEES.md updates traînent en review backend, 1.1a est bloquée et P1 dérape. Mitigation : escalade async + commit doc/partage avec note « pending backend approval ».
2. **Surcharge porteur** : Story 1.1b livre un script Python que le porteur doit exécuter. S'assurer que la procédure README est claire.
3. **Drift estimation P1** : si total dépasse 60h, déférer 1.7 et 1.10 en début P2 (à décider en mid-sprint).

## 6. Approval

### User approval

- [ ] PO Delano Roosvelt approuve ce sprint change proposal
- [ ] User confirme que P1 timeline peut être étendue à 6-7j (ou que 1.7/1.10 seront déférés)
- [ ] User notifie backend team async pour la PR 1.1a à venir

### Approval signature

| Role | Name | Date | Signature |
|---|---|---|---|
| PO | Delano Roosvelt | 2026-06-05 | _PR merge = approval_ |
| PM agent | Claude Opus 4.7 | 2026-06-05 | (auto) |
| Backend lead | TBD | TBD | _async via PR 1.1a comment_ |

---

**Sprint Change Proposal v1 — généré par `/bmad-correct-course` le 2026-06-05.**
