---
story_id: 1bis.3bis.c
title: Seed alignement Phase 5+6 — BT Industriel/Agricole (17 spécialités) + BEP/BP introduction
epic: 1bis
phase: P1bis — Alignement matrice officielle OBC/GCE (deferred de la PR #140)
status: ready-for-dev
created: 2026-06-13
baseline_commit: TBD  # après merge PR #140 sur main
estimation: L (~6-8h seed + 2h validation enseignant + 1h déploiement) — story plus grosse à découper si besoin
dependencies:
  - PR #140 mergée
  - Story 1bis-3bis-a (BT Tertiaire) en route — partage des matières communes (Fr / En / Math / Atelier)
  - Validation enseignant camerounais OBC fortement recommandée pour les blocs pro spécifiques
blocks: []
sourceArtifacts:
  - scripts/firebase_seed/data/matrice.json (état post-PR #140)
  - Référence officielle OBC matrice ESG/ESTP Parties 6 + 7
  - mobile_app/lib/features/onboarding/presentation/pages/level_choice_step_body.dart (consommateur runtime — vérifier pas de regression)
action_porteur_post_merge:
  - "Exécuter `python seed_catalogue.py --project valide-edu` après merge"
  - "Smoke device : 5-6 spécialités BT industriel + 2-3 BEP/BP doivent être testables"
---

# Story 1bis-3bis-c — Seed Phase 5+6 BT Industriel/Agricole + BEP/BP

Status: **ready-for-dev**

## Objectif

Compléter le seed sur 2 zones niches mais importantes pour la couverture complète :
1. **BT Industriel & Agricole** (Partie 6 de la référence) : 17 spécialités (TAG/PM, TAG/PP, TAG/AQ, TAG/PMF, TAG/MEA, TAG/TCPA, TGF, BIJO, GT, IB-TMG, IH, IS/RH, CMA/MVPL, AMEB, MAGE, MEM, MHB, MISE)
2. **BEP / BP** (Partie 7) : nouveau type d'examen avec niveaux dédiés + ~15 spécialités

## Pourquoi cette story est plus grosse + sensible

Contrairement aux phases 1-4, ces séries demandent :
- **Beaucoup de matières professionnelles nouvelles** (Zootechnie, Aquaculture, Bijouterie, Cartographie, Maintenance hospitalière biomédicale, etc.) — ~40 subjects à créer
- **Nouveau type de niveau BEP/BP** : examens techniques professionnels avec structure différente (bloc général très allégé + bloc pro lourd + atelier)
- **Validation domaine** : la nomenclature exacte de chaque matière pro doit refléter les référentiels OBC. Sans validation enseignant, risque de seed approximatif.

## Découpage proposé (si la story devient trop grosse)

Option A — **monolithique** : tout dans une PR (~2500L seed)
Option B — **3 sous-stories** :
- `1bis-3bis-c1` BT Agricole (TAG/*) + TGF — 7 spécialités, ~1000L
- `1bis-3bis-c2` BT Industriel — 10 spécialités, ~1200L
- `1bis-3bis-c3` BEP/BP — nouveau niveau + 15 spécialités, ~1500L

Choisir Option B si la validation enseignant arrive par tranches.

## BT Industriel & Agricole — spécialités à ajouter

Existent déjà : `ih` (Industrie habillement), `mvt` (CMA/MVT), `mem` (Maintenance électromécanique). Tle uniquement, à enrichir Premiere.

À ajouter (Premiere + Tle) :
- **TAG/PM** Production animale monogastriques
- **TAG/PP** Production animale polygastriques
- **TAG/AQ** Production aquacole
- **TAG/PMF** Productions végétales (manioc-fruits)
- **TAG/MEA** Maintenance équipements agricoles
- **TAG/TCPA** Transformation/conservation produits agropastoraux
- **TGF** Technique et gestion financière
- **BIJO** Bijouterie-joaillerie
- **GT** Géomètre topographe
- **IB-TMG** Industrie du bois (transformation mécanique)
- **IS/RH** Installation sanitaire et réseau hydraulique
- **CMA/MVPL** Construction et maintenance auto (poids lourds)
- **AMEB** Ameublement ébénisterie
- **MAGE** Menuiserie agencement
- **MHB** Maintenance hospitalière/biomédicale
- **MISE** Maintenance et installation systèmes électroniques

## BEP/BP — nouveau niveau

Niveau nouveau à ajouter : `francophone_bep` et `francophone_bp` (filière `technique`).

**BEP commercial**
- Comptabilité, Secrétariat

**BP commercial**
- Comptable, Secrétaire, Employé de Banque

**BP industrials** (15 spécialités)
- MENU, ELAD, ELNI, INSA, MACO, ELET, MEUS, MEAU, ELDI, FRCL, ELAU, ELPR, ELIE, CHME, COUT

Chaque BEP/BP : tronc général allégé (Français + Math + Anglais) + tronc pro de la spécialité + atelier.

## Nouveaux subjects estimés

- Agricoles : zootechnie, agronomie, phytotechnie, aquaculture, biologie aquatique, mécanique agricole, transformation agroalimentaire, hygiène, technologie agroalimentaire — ~10 subjects
- Industriels : bijouterie, dessin d'art, topographie, cartographie, technologie bois (transformation), technologie sanitaire, plomberie, mécanique poids lourds, ébénisterie, menuiserie, électronique biomédicale, systèmes électroniques — ~12 subjects
- BEP/BP : techniques bancaires, droit bancaire, technologie bois (atelier), métallurgie, chaudronnerie, électricité auto, moteurs diesel — ~7 subjects
- Plus subjects partagés (atelier, technologie, communication pro) — ~5 subjects
- **Total estimé : ~34 nouveaux subjects**

## Critères d'acceptation

- [ ] JSON valid + 0 référence cassée
- [ ] Tous les nouveaux subjects avec icônes Lucide valides (cf. `subject_icon_resolver.dart`)
- [ ] 17 nouvelles séries BT industriel + 17 nouvelles séries BEP/BP = 34 nouvelles séries actives
- [ ] 2 nouveaux niveaux : `francophone_bep`, `francophone_bp` (filiereIds: ["technique"])
- [ ] derivation rules cohérentes (vérifier 1-2 cas runtime à la main)
- [ ] flutter test passe (341+ tests)

## Estimation lignes JSON (si monolithique)

- Nouveaux subjects (34) : ~700L
- Nouveaux niveaux (2 BEP/BP) : ~40L
- Nouvelles séries (34) : ~1020L
- Nouvelles derivation rules (34) : ~750L
- Nouveaux exam_targets : ~340L
- **Total estimé : ~2850L** (Option A monolithique)

## Risques élevés

1. **Validation enseignant manquante** : sans expertise OBC, risque de nomenclature approximative. Solution : envoyer le seed proposé à un enseignant Cameroun pour validation avant déploiement.
2. **BEP/BP UX dans l'app** : actuellement le flow assume `Premiere/Terminale` comme niveaux finaux. BEP/BP a une logique différente (cycle court). Vérifier que `LevelChoiceStepBody` rend correctement le nouveau niveau et ne casse rien runtime.
3. **PR géante** : monolithique = ~2850L seed = PR très risquée à reviewer. Recommandation : Option B (3 sous-stories).
