# ADR-004 — Méthode BMAD v6.8.0 pour le pilotage du projet

**Date** : 2026-06-03
**Statut** : 🟢 Accepté

## Contexte

Le projet est piloté en collaboration avec des agents IA (Claude Code, Cursor, etc.). Trois approches existent pour cette collaboration :

- **Vibe coding** : on tape une demande, l'IA produit du code, on copie-colle. Marche pour un script isolé, désastre pour un MVP multi-composants — décisions contradictoires entre agents, pas de source de vérité commune, code spaghetti.
- **Méthode interne ad-hoc** : on écrit ses propres prompts, ses templates. Effort non négligeable, résultat dépend de la discipline individuelle.
- **Framework structuré (BMAD)** : pipeline `SPEC → PRD → UX → Architecture → Stories → Code`, agents persona spécialisés, décisions tracées.

## Décision

**BMAD v6.8.0** (release 2026-05-25) comme méthode unique de pilotage du projet sur ce dépôt et sur les autres (backend, admin, landing).

Pipeline appliqué :

```
/bmad-spec            → SPEC.md (5 champs : Why, Capabilities, Constraints, Non-goals, Success signal)
/bmad-prd             → prd.md (44 FRs + 15 NFRs + 7 UJs)
/bmad-ux              → DESIGN.md + EXPERIENCE.md (two-spine contract)
/bmad-create-architecture  → architecture.md + ADRs
/bmad-create-epics-and-stories  → fichiers Epic avec stories
/bmad-dev-story       → code + tests
/bmad-code-review     → revue adversariale
/bmad-investigate     → forensique pour bugs mystérieux
```

Configuration : module `bmm`, IDE `claude-code`, langue de communication FR, langue d'output FR, user `Delano Roosvelt`. Output dans `project_manage/` (overrides dans `_bmad/custom/config.toml`).

## Conséquences

**Positives**

- **Source de vérité unique par phase** : chaque skill produit un livrable nommé que la suivante consomme par nom. Pas de divergence.
- **Décisions tracées** : `.decision-log.md` à côté de chaque livrable (PRD, UX, architecture).
- **Cohérence inter-agents** : Winston et Amelia ne peuvent pas inventer des choix contradictoires — le PRD et l'architecture les bornent.
- **Onboarding nouveau dev / agent** : `project-context.md` + ce pipeline donnent un onboarding express.
- **Revue adversariale** : `bmad-code-review` force la recherche de problèmes plutôt que la confirmation.
- **6 agents disponibles en v6.8.0** : Mary, John, Winston, Amelia, Sally, Paige. Bob (Scrum Master) et Barry (Quick Flow) absents — leurs skills sont invocables directement.

**Négatives**

- **Effort initial de discipline** : suivre le pipeline est plus lent que sauter directement au code.
- **Verbosité documentaire** : chaque skill produit plusieurs fichiers (kernel + companions + decision-log). À assumer comme dette de doc.
- **Verrouillage outil** : si BMAD est abandonné, les artefacts restent (Markdown) mais le tooling n'est plus maintenu.
- **Compétence requise** sur la méthode (cf. guide [`doc/tools/BMAD_METHOD_GUIDE.md`](../../../../doc/tools/BMAD_METHOD_GUIDE.md)).

**Impact sur les comportements attendus de Claude**

Documentés dans [`CLAUDE.md`](../../../../CLAUDE.md) à la racine du dépôt — chargé automatiquement à chaque session :

- Toute demande passe par une skill BMAD (sauf 6 exceptions documentées).
- Quick Flow uniquement pour les actions mono-composant simples.
- Investigation forensique avant patch d'un bug mystérieux.
- Modification de `doc/partage/` requiert accord cross-équipe.

## Détail d'implémentation

Voir [`doc/tools/BMAD_METHOD_GUIDE.md`](../../../../doc/tools/BMAD_METHOD_GUIDE.md) (à jour v6.8.0).

## Décisions liées

- [ADR-005](ADR-005-shared-surface-doc-partage.md) — `doc/partage/`, surface co-maintenue entre les 4 dépôts BMAD du projet.
