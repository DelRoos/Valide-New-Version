// =====================================================================
// Tests d'integration des regles Firestore — _smoketest/{doc} (AC3)
// Firebase direct (sans emulateur). Cf. test/rules/test-config.mjs.
// =====================================================================

import { describe, after, test } from 'node:test';
import { doc, getDoc, setDoc } from 'firebase/firestore';

import {
  testUid,
  createAuthedClient,
  createUnauthedClient,
  cleanupRun,
  assertSucceeds,
  assertFails,
} from './test-config.mjs';

const eveUid = testUid('eve');
const docId = testUid('launch');

describe('Firestore rules — _smoketest/{doc}', () => {
  const cleanups = [];

  after(async () => {
    for (const c of cleanups) {
      try {
        await c();
      } catch (_) {
        /* ignore */
      }
    }
    await cleanupRun();
  });

  test('user auth ecrit puis lit _smoketest/launch -> OK', async () => {
    const { db, cleanup } = await createAuthedClient(eveUid);
    cleanups.push(cleanup);
    await assertSucceeds(
      setDoc(doc(db, '_smoketest', docId), {
        at: new Date(),
        source: 'rules-test',
      }),
    );
    await assertSucceeds(getDoc(doc(db, '_smoketest', docId)));
  });

  test('user non auth ecrit/lit _smoketest -> KO', async () => {
    const { db, cleanup } = createUnauthedClient();
    cleanups.push(cleanup);
    await assertFails(
      setDoc(doc(db, '_smoketest', docId), { at: new Date() }),
    );
    await assertFails(getDoc(doc(db, '_smoketest', docId)));
  });
});
