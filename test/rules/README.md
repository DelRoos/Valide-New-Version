# Tests des regles Firestore (Story 0.9)

Tests unitaires des regles Firestore via `@firebase/rules-unit-testing` + emulateur Firebase local.

## Prerequis

- Node.js ≥ 20
- Firebase CLI (`npm install -g firebase-tools`)
- Java JRE 11+ (l'emulateur Firestore tourne sur JVM)

## Installation

```bash
cd test/rules
npm install
```

## Lancer les tests

Depuis la **racine du depot**, dans deux terminaux :

```bash
# Terminal 1 — demarrer l'emulateur Firestore + Auth
firebase emulators:start --only firestore,auth

# Terminal 2 — lancer les tests
cd test/rules
npm test
```

Ou en une commande avec `firebase emulators:exec` :

```bash
# Depuis la racine
firebase emulators:exec --only firestore,auth "cd test/rules && npm test"
```

## Couverture

- [users.test.mjs](users.test.mjs) — 6 tests sur `users/{uid}` (AC2 + AC5 a-d)
- [smoketest.test.mjs](smoketest.test.mjs) — 2 tests sur `_smoketest/{doc}` (AC3)

## Deploy des regles en prod

```bash
firebase deploy --only firestore:rules --project=valide-edu
```
