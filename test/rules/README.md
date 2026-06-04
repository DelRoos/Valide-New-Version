# Tests des regles Firestore (Story 0.9 + cleanup post-merge)

Tests d'integration des regles Firestore **directement sur le projet Firebase `valide-edu`**, sans emulateur.

> Pourquoi pas d'emulateur ? Choix d'equipe — workflow plus simple, regles testees dans leur environnement reel. Voir Story 0.9 retrospective.

## Prerequis

- Node.js ≥ 20
- Service account JSON pour `valide-edu` :

  1. Firebase Console > Project Settings > Service accounts > "Generate new private key"
  2. Enregistrer dans `test/rules/service-account.json` (gitignore) **OU** definir `GOOGLE_APPLICATION_CREDENTIALS=/chemin/vers/sa.json`

## Installation

```bash
cd test/rules
npm install
```

## Lancer les tests

Depuis `test/rules/` :

```bash
npm test
```

Ou depuis la racine :

```bash
npm test --prefix test/rules
```

## Couverture

- [users.test.mjs](users.test.mjs) — 6 tests sur `users/{uid}` (AC5 a-f)
- [smoketest.test.mjs](smoketest.test.mjs) — 2 tests sur `_smoketest/{doc}` (AC3)

Chaque run :
- Genere un `RUN_ID` unique (timestamp + random) — UIDs et docs prefixes `tr-{RUN_ID}-*`
- Cree les docs preconditions via Admin SDK (bypass rules)
- Authentifie les clients de test via custom tokens (Admin SDK) + signInWithCustomToken (Web SDK)
- Nettoie les docs `users/tr-{RUN_ID}-*` et `_smoketest/tr-{RUN_ID}-*` en fin de run

## Variables d'environnement

| Variable | Defaut | Role |
| --- | --- | --- |
| `FIREBASE_PROJECT_ID` | `valide-edu` | Projet Firebase cible |
| `FIREBASE_WEB_API_KEY` | (hardcode `AIzaSy...` valide-edu) | API key Web SDK |
| `GOOGLE_APPLICATION_CREDENTIALS` | `./service-account.json` | Chemin vers service account |

## Deploy des regles en prod

```bash
firebase deploy --only firestore:rules --project=valide-edu
```

Tester en local avant deploy : lance les tests ci-dessus contre la version COMMITEE des regles. Pour tester une modif non encore deployee, il faut d'abord deployer sur un projet de test (ex: `valide-test-env`) puis pointer `FIREBASE_PROJECT_ID=valide-test-env`.
