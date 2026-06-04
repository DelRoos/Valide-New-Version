// =====================================================================
// Tests des regles Firestore — collection _smoketest/{doc} (Story 0.9 AC3)
// =====================================================================
//
// Cette collection est temporaire (Story 0.21 sentinelle E0). Le matching
// `_smoketest/*` sera retire en fin E0 ou debut E1.
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

describe('Firestore rules — _smoketest/{doc}', () => {
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
  });

  test('user auth ecrit puis lit _smoketest/launch → OK', async () => {
    const eve = testEnv.authenticatedContext('eve').firestore();
    await assertSucceeds(
      setDoc(doc(eve, '_smoketest/launch'), { at: new Date(), source: 'rules-test' }),
    );
    await assertSucceeds(getDoc(doc(eve, '_smoketest/launch')));
  });

  test('user non auth → KO', async () => {
    const anonymous = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      setDoc(doc(anonymous, '_smoketest/launch'), { at: new Date() }),
    );
    await assertFails(getDoc(doc(anonymous, '_smoketest/launch')));
  });
});
