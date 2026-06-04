// =====================================================================
// Tests des regles Firestore — collection users/{uid} (Story 0.9 AC5)
// =====================================================================
//
// Prerequis :
//   1. `npm install` dans test/rules/
//   2. `firebase emulators:start --only firestore,auth` (depuis racine)
//   3. `npm test`
//
// Couvre 4 scenarios :
//   (a) user auth lit son doc → OK
//   (b) user auth lit doc autre → KO
//   (c) user non auth (anonyme) → KO
//   (d) ecriture avec subSystem invalide → KO
// =====================================================================

import { describe, before, after, beforeEach, test } from 'node:test';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc } from 'firebase/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const rulesPath = resolve(__dirname, '..', '..', 'firestore.rules');

let testEnv;

const validUserDoc = {
  uid: 'alice',
  subSystem: 'francophone',
  language: 'fr',
  filiere: 'generale',
  niveau: 'Tle',
  serie: 'D',
  derivedSubjects: [],
  optedOutSubjects: [],
  examTargets: [],
  schoolId: null,
  displayName: 'Alice Mbeki',
  photoUrl: null,
  createdAt: new Date(),
  updatedAt: new Date(),
  deletionRequestedAt: null,
};

describe('Firestore rules — users/{uid}', () => {
  before(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: 'valide-edu-rules-test',
      firestore: {
        rules: readFileSync(rulesPath, 'utf8'),
        host: '127.0.0.1',
        port: 8080,
      },
    });
  });

  after(async () => {
    await testEnv.cleanup();
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
    // Seed: doc alice prealable pour tests de lecture
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/alice'), validUserDoc);
    });
  });

  test('(a) user auth lit son propre doc → OK', async () => {
    const alice = testEnv.authenticatedContext('alice').firestore();
    await assertSucceeds(getDoc(doc(alice, 'users/alice')));
  });

  test('(b) user auth lit doc d\'un autre → KO', async () => {
    const bob = testEnv.authenticatedContext('bob').firestore();
    await assertFails(getDoc(doc(bob, 'users/alice')));
  });

  test('(c) user non authentifie lit users/* → KO', async () => {
    const anonymous = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(anonymous, 'users/alice')));
  });

  test('(d) creation avec subSystem invalide → KO', async () => {
    const charlie = testEnv.authenticatedContext('charlie').firestore();
    await assertFails(
      setDoc(doc(charlie, 'users/charlie'), {
        ...validUserDoc,
        uid: 'charlie',
        subSystem: 'other',
      }),
    );
  });

  test('(e) creation valide → OK', async () => {
    const dave = testEnv.authenticatedContext('dave').firestore();
    await assertSucceeds(
      setDoc(doc(dave, 'users/dave'), {
        ...validUserDoc,
        uid: 'dave',
      }),
    );
  });

  test('(f) update subSystem rejete (champ fige a l\'inscription) → KO', async () => {
    const alice = testEnv.authenticatedContext('alice').firestore();
    await assertFails(
      setDoc(
        doc(alice, 'users/alice'),
        { ...validUserDoc, subSystem: 'anglophone' },
        { merge: true },
      ),
    );
  });
});
