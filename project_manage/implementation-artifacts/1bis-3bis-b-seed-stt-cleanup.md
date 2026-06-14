---
story_id: 1bis.3bis.b
title: Seed alignement Phase 4 — STT cleanup (G1-G3 → ACA/CG/ACC/FIG/SES)
epic: 1bis
phase: P1bis — Alignement matrice officielle OBC/GCE (deferred de la PR #140)
status: ready-for-dev
created: 2026-06-13
baseline_commit: TBD  # après merge PR #140 sur main
estimation: M (~2-3h seed + risque migration utilisateurs existants)
dependencies:
  - PR #140 mergée — alignement de baseline
  - Story 1bis-3bis-a peut être faite en parallèle (indépendant)
blocks: []
sourceArtifacts:
  - scripts/firebase_seed/data/matrice.json (état post-PR #140)
  - Référence officielle OBC matrice ESG/ESTP Partie 3 STT
  - mobile_app/lib/features/onboarding/data/onboarding_flush_service.dart (cursus mismatch handling pour visiteurs)
action_porteur_post_merge:
  - "Exécuter `python seed_catalogue.py --project valide-edu` après merge"
  - "Smoke device : Tle ACA / CG / ACC / FIG / SES doivent apparaître + leurs matières dérivées"
  - "Vérifier : aucun utilisateur existant en base ne bloque (cursus mismatch handler doit gérer le rename G1→ACA en delete+recreate pour les visiteurs)"
---

# Story 1bis-3bis-b — Seed Phase 4 STT cleanup

Status: **ready-for-dev**

## Objectif

Aligner les séries Tertiaire (STT) sur la nomenclature officielle OBC :
- **G1 / G2 / G3** (génériques) → **ACA / CG / ACC** (renommage cohérent avec ref officielle)
- Ajout **FIG** et **SES** (manquants)
- Couvrir Premiere ET Terminale (actuellement seul Tle a des séries STT incomplètes)

## Contexte (ce qui existe vs ce qu'il faut faire)

### STT — actuellement
- Premiere : `francophone_premiere_g1`, `_g2`, `_g3` (génériques)
- Terminale : `francophone_terminale_g1`, `_g2`, `_g3` + `francophone_terminale_aca`, `_mava`, `_meac_auto` (mapping ambigu, plusieurs sont inactifs)

### STT — cible (Tle + Premiere)
- `francophone_premiere_aca` (Action et Communication Administratives) — remplace g1
- `francophone_premiere_cg` (Comptabilité et Gestion) — remplace g2
- `francophone_premiere_acc` (Action et Communication Commerciales) — remplace g3
- `francophone_premiere_fig` (Fiscalité et Informatique de Gestion) — NOUVEAU
- `francophone_premiere_ses` (Sciences Économiques et Sociales) — NOUVEAU
- Idem pour Terminale

## Stratégie de migration (sensible)

**NE PAS supprimer** les anciennes séries G1/G2/G3 — désactiver uniquement (`isActive: false`). Justification : un utilisateur visiteur en base peut avoir `streamId: "francophone_terminale_g1"` dans son profil. Le `onboarding_flush_service._hasCursusMismatch` détecte le mismatch + delete+recreate pour visiteurs.

Pour comptes permanents qui auraient G1/G2/G3 : les rules immutables Firestore refuseront le delete. À gérer dans une story de migration data future si besoin (rare cas en MVP).

## Nouveaux subjects à créer

- `francophone_economie_generale` (Économie générale)
- `francophone_droit` (Droit)
- `francophone_communication_administrative` (Communication administrative)
- `francophone_organisation_gestion` (Organisation et gestion administrative)
- `francophone_bureautique` (Bureautique)
- `francophone_informatique_gestion` (Informatique de gestion)
- `francophone_math_financiere` (Mathématiques financières)
- `francophone_fiscalite` (Fiscalité)
- `francophone_marketing` (Marketing / Mercatique)
- `francophone_vente_negociation` (Vente et négociation)
- `francophone_programmation_bd` (Programmation / Bases de données de gestion)
- `francophone_ses_subject` (Sciences Économiques et Sociales — homonyme du nom de série, suffixé `_subject` pour éviter collision)

## Critères d'acceptation

- [ ] JSON valid + 0 référence cassée
- [ ] 10 nouvelles séries actives (5 spécialités × 2 niveaux Premiere/Tle)
- [ ] G1/G2/G3 désactivés (isActive: false) — pas supprimés
- [ ] 10 nouvelles derivation rules avec ~13 matières chacune (blocs général + professionnel)
- [ ] 10 nouveaux exam_targets (Probatoire + BAC pour ACA/CG/ACC/FIG/SES)
- [ ] flutter test passe (341+ tests)
- [ ] Smoke device : Tle ACA visible, matières dérivées correctes (Compta, Droit, Économie...)

## Estimation lignes JSON

- Nouveaux subjects : ~240L
- Nouvelles séries : ~300L
- Nouvelles derivation rules : ~280L
- Nouveaux exam_targets : ~100L
- Désactivations : ~10L
- **Total estimé : ~930L**

## Risques

- **Cursus mismatch en runtime** : si un visiteur a déjà G1 en profil, le flush service refera le doc. OK pour visiteurs (déjà géré). Pour comptes permanents : rare en MVP, accepter.
- **Naming conflict** : `francophone_ses` est aussi le nom du serieId. Le nom du subject doit être différent — utiliser `francophone_ses_subject` ou repenser la convention.
