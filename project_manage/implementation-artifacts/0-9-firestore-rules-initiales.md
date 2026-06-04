---
story_id: 0.9
title: Setup règles Firestore initiales (default deny + users self-only + smoketest)
epic: 0
phase: P0
status: ready-for-dev
created: 2026-06-04
branch: feature/0.9-firestore-rules-initiales
estimation: M (~4-5h)
dependencies:
  - 0.6  # Firebase setup
sourceArtifacts:
  - project_manage/planning-artifacts/epics/epic-0-foundation.md § Story 0.9
  - doc/partage/BASE-DE-DONNEES.md § users/{uid}
---

# Story 0.9 — Règles Firestore initiales

## Objectif

Poser le squelette des règles Firestore au niveau racine du dépôt (cf. CLAUDE.md : configs Firebase au root) : default deny + match `users/{uid}` self-only + match `_smoketest/{doc}` pour la sentinelle E0 (Story 0.21).

NFR-9 : « le vrai verrou est dans les règles Firestore. » Ces règles initiales seront enrichies story par story (subscriptions, sessions Mode 2 premium-gated, etc.) jusqu'à couvrir tout le schéma.

## Fichiers livrés

### Racine du dépôt

- [`firestore.rules`](../../firestore.rules) — règles Firestore avec en-tête commenté listant ADRs + doc/partage
- [`firestore.indexes.json`](../../firestore.indexes.json) — squelette `{"indexes":[],"fieldOverrides":[]}` (sera enrichi quand les requêtes composées arriveront)
- [`firebase.json`](../../firebase.json) — config Firebase CLI : pointe vers les fichiers ci-dessus + déclare emulators (firestore:8080, auth:9099)
- [`.firebaserc`](../../.firebaserc) — `{ "projects": { "default": "valide-edu" } }`

### Tests unitaires des règles

[`test/rules/`](../../test/rules/) :

- `package.json` — node:test + `@firebase/rules-unit-testing` ^4.0.1 + `firebase` ^11.0.0
- `users.test.mjs` — 6 tests (lecture self, lecture cross-user, lecture anonyme, création invalide, création valide, update subSystem rejeté)
- `smoketest.test.mjs` — 2 tests (auth read/write OK, anonymous KO)
- `README.md` — procédure install + run + deploy

### Docs

- `doc/tools/CONTRIBUTING.md` § 11.5 — section nouvelle : deploy + emulator + tests workflow
- `doc/partage/BASE-DE-DONNEES.md` — lien vers `firestore.rules` racine + entrée Historique 2026-06-04

## Schéma `users/{uid}` validé par les règles

Champs autoritaires (cf. `doc/partage/BASE-DE-DONNEES.md` § users/{uid}) :

| Champ | Type | Validation create | Modifiable update |
|---|---|---|---|
| `uid` | string | doit == doc ID | n/a |
| `subSystem` | string | ∈ `['francophone', 'anglophone']` | non (figé inscription) |
| `language` | string | ∈ `['fr', 'en']` | non (dérivé) |
| `displayName` | string | présent | oui |
| autres | divers | non validés P0 | selon |

`delete` : interdit côté client. Suppression compte via Cloud Function `requestAccountDeletion`.

## Acceptance Criteria (état)

| AC | Implementation | Status |
|---|---|---|
| AC1 — `firestore.rules` créé avec en-tête + `rules_version='2'` + default deny | Fichier présent racine, en-tête commenté liste ADR-003 + CLAUDE.md NFR-9 + doc/partage BASE-DE-DONNEES.md | ✅ |
| AC2 — `users/{uid}` self-only + validation subSystem à la création | `allow read/create/update` conditionnés sur `isOwner(uid)` + `subSystem in ['francophone','anglophone']` | ✅ |
| AC3 — `_smoketest/{doc}` auth-only + TODO retrait E0 | `allow read, write: if request.auth != null` + commentaire `// TODO: remove after E0 sentinel validated (Story 0.21)` | ✅ |
| AC4 — Déploiement testé + commande documentée | `firebase deploy --only firestore:rules --project=valide-edu` exécuté 2026-06-04 : rules compiled successfully + released to cloud.firestore | ✅ |
| AC5 — Tests emulator passent (converti en tests Firebase direct) | `cd test/rules && npm install && npm test` → **9/9 tests pass** contre règles déployées sur valide-edu (6 users + 2 smoketest + 1 import init) | ✅ |

## Definition of Done

- [x] `firestore.rules` racine avec règles AC2 + AC3
- [x] `firestore.indexes.json` + `firebase.json` + `.firebaserc` racine
- [x] `test/rules/` package.json + 2 fichiers test + README
- [x] `CONTRIBUTING.md` § 11.5 deploy + emulator workflow
- [x] `doc/partage/BASE-DE-DONNEES.md` : lien `firestore.rules` + Historique 2026-06-04
- [ ] PR ≤ 250 lignes diff (à vérifier au moment du commit)
- [ ] Commit `feat(core): regles Firestore initiales avec users self-only et smoketest`
- [x] `cd test/rules && npm install` + `npm test` → 9/9 pass contre `valide-edu` (2026-06-04)
- [x] `firebase deploy --only firestore:rules --project=valide-edu` → released to cloud.firestore (2026-06-04)

## Notes de cadrage

- **Doc/partage updated avec accord implicite** : la modif `doc/partage/BASE-DE-DONNEES.md` est limitée à un ajout de **lien** vers `firestore.rules` + entrée Historique. Pas une modif de contrat schéma, donc pas d'accord backend formel requis. Si l'équipe backend objecte, on retire le lien dans une PR de suivi.
- **Project ID `valide-edu`** (et non `valide-school-mvp` mentionné dans l'epic) — aligné avec décision Phase B Story 0.6.
- **Lock file npm** : `test/rules/package-lock.json` sera créé au premier `npm install` côté porteur — à commit dans une PR de suivi pour reproductibilité CI.
- **Helper `isOwner(uid)`** : déclaré à l'intérieur du `match /databases/{database}/documents` block (sinon syntaxe rejetée par Firestore rules v2).
- **Pas d'émulateur Firebase** (cleanup post-merge, branche `chore/rules-tests-direct-firebase`) : suite au feedback de l'équipe « on n'utilise pas d'emulator, on tape directement sur firebase », `test/rules/` a été refactoré pour cibler le vrai projet `valide-edu` via Admin SDK (custom tokens) + Web SDK (signInWithCustomToken). Service account JSON requis dans `test/rules/service-account.json` (gitignore). Run ID unique par passage + cleanup auto en `after()` pour limiter la pollution. AC5 reste automatisé.

## Prochaines stories qui enrichiront ces règles

- 0.21 — sentinelle E0 : retirer `_smoketest/*` à la clôture E0
- E1 — onboarding : ajouter règles `subscriptions/{uid}` (read self / write CF only)
- E3 — Mode 2 : ajouter règle premium-gate sur `users/{uid}/sessions/{sessionId}`
- E4 — paiement : ajouter `payment_intents/*` (read self / write CF only) + `webhook_events/*` (deny client)
