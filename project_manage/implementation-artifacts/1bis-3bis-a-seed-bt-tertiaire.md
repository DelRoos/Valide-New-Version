---
story_id: 1bis.3bis.a
title: Seed alignement Phase 2+3 — F4 splits (BA/BE/TP) + BT Tertiaire (HO-* / TO-*) + ESF Premiere
epic: 1bis
phase: P1bis — Alignement matrice officielle OBC/GCE (deferred de la PR #140)
status: ready-for-dev
created: 2026-06-13
baseline_commit: TBD  # après merge PR #140 sur main
estimation: M (~3-4h seed + 1h validation + 30min déploiement)
dependencies:
  - PR #140 mergée — Phase 1 (Premiere A1-A5) + Phase 7 (A-Level cleanup) en place
  - Subject.group field + mapper Firestore (PR #140)
blocks: []
sourceArtifacts:
  - scripts/firebase_seed/data/matrice.json (état post-PR #140)
  - Référence officielle OBC matrice ESG/ESTP fournie par porteur produit 2026-06-13 (Parties 4, 5)
  - scripts/firebase_seed/seed_catalogue.py (script de déploiement, inchangé)
  - mobile_app/lib/features/onboarding/presentation/pages/stream_subjects_picker_step_body.dart (consommateur runtime — vérifier pas de regression UI)
action_porteur_post_merge:
  - "Exécuter `python seed_catalogue.py --project valide-edu` après merge"
  - "Smoke device : Tle F4 sub-séries BA / BE / TP doivent apparaître + leurs matières dérivées"
  - "Smoke device : Tle HO-CU (Hôtellerie Cuisine) + Tle TO-AV (Tourisme Agence Voyage) doivent apparaître"
---

# Story 1bis-3bis-a — Seed Phase 2+3 — F4 splits + BT Tertiaire

Status: **ready-for-dev**

## Objectif

Compléter le seed `matrice.json` pour 2 zones manquantes vs la référence officielle OBC :
1. **F4 splitté en BA / BE / TP** (Bâtiment / Bureau d'études / Travaux publics) — actuellement F4 est une série monolithique générique
2. **BT Tertiaire** : ajouter HO-HE / HO-RB / HO-CU / TO-AAT / TO-AV + ESF en Premiere (seul ESF Tle existe)

## Contexte (ce qui existe vs ce qu'il faut ajouter)

### F4 — actuellement
- `francophone_premiere_f4` (générique "Génie civil")
- `francophone_terminale_f4` (générique "Génie civil")
- 1 derivation rule par niveau avec 8 matières génériques (math, sciences_phy, si, tech_atelier, fr, en, hg, eps)

### F4 — cible
- Désactiver F4 générique (`isActive: false`)
- Ajouter 6 nouvelles séries : `*_premiere_f4_ba`, `*_premiere_f4_be`, `*_premiere_f4_tp`, `*_terminale_f4_ba`, `*_terminale_f4_be`, `*_terminale_f4_tp`
- 6 nouvelles derivation rules avec matières spécifiques de chaque option

### BT Tertiaire — actuellement
- Seul `francophone_terminale_esf` existe (inactif aujourd'hui — réactiver)

### BT Tertiaire — cible
- Ajouter 5 spécialités × 2 niveaux = 10 séries : HO-HE, HO-RB, HO-CU, TO-AAT, TO-AV (Premiere + Tle)
- ESF Premiere à ajouter (Tle existe, à réactiver)
- 11 nouvelles derivation rules + 11 exam_targets correspondants

## Nouveaux subjects à créer (matières professionnelles spécifiques)

### Génie civil (F4 splits)
- `francophone_beton_arme` (Béton armé)
- `francophone_rdm` (Résistance des matériaux)
- `francophone_topographie` (Topographie)
- `francophone_construction_batiment` (Technologie du bâtiment / Étude des constructions)

### Hôtellerie (HO-*)
- `francophone_hebergement` ✓ existe déjà
- `francophone_restaurant_bar` ✓ existe déjà
- `francophone_cuisine` ✓ existe déjà
- `francophone_gestion_hoteliere` (à créer)
- `francophone_hygiene_securite` (à créer)
- `francophone_communication_pro` (à créer)
- `francophone_oenologie` (à créer)
- `francophone_nutrition_aliments` (à créer)
- `francophone_techniques_culinaires` (à créer)

### Tourisme (TO-*)
- `francophone_accueil_tourisme` ✓ existe déjà
- `francophone_agence_voyage` ✓ existe déjà
- `francophone_geographie_touristique` (à créer)
- `francophone_gestion_touristique` (à créer)
- `francophone_billetterie` (à créer)
- `francophone_economie_droit` (à créer — partagé avec ESF)

### ESF
- `francophone_esf` (Économie sociale et familiale — à créer)
- `francophone_sciences_consommation` (à créer)
- `francophone_gestion_foyer` (à créer)

## Critères d'acceptation

- [ ] JSON valid + 0 référence cassée (Python validator)
- [ ] Active series count ≥ 80 (passage de 66 actuels + 12 nouvelles séries actives)
- [ ] Nouvelles derivation rules avec subjectIds tous résolus
- [ ] Déploiement seed valide-edu vérifié en Firebase Console (~140 docs catalogue)
- [ ] Smoke device : Tle F4/BA visible dans le picker, matières correctes affichées en chips
- [ ] Smoke device : Tle HO-CU visible, matières culinaires correctes
- [ ] flutter test passe (341+ tests)

## Estimation lignes JSON

- Nouveaux subjects : ~280L (14 subjects × 20L)
- Nouvelles séries : ~480L (16 séries × 30L)
- Nouvelles derivation rules : ~330L (17 rules × ~20L)
- Nouveaux exam_targets : ~170L (17 × 10L)
- Désactivations F4 + flag ESF : ~10L
- **Total estimé : ~1270L**

## Risques

- Matières professionnelles : nomenclature exacte à valider avec enseignant Cameroun OBC. Le seed propose des noms cohérents avec la référence officielle, mais des variations existent (ex. "Mathématiques financières" vs "Maths financières"). Pour MVP, on tolère les variations légères.
- BT Tertiaire actuellement inactif (ESF). Si réactivation casse un user existant qui avait ESF inactif en profil, accepter le risque (dev only avant V1).
