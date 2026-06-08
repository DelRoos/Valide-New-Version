// =====================================================================
// Tests d'integration des regles Firestore — schools/{schoolId} (Story 1.7)
// Firebase direct (sans emulateur). Cf. test/rules/test-config.mjs.
// =====================================================================

import { describe, before, after, test } from 'node:test';
import {
  doc,
  getDoc,
  setDoc,
  addDoc,
  collection,
} from 'firebase/firestore';

import {
  adminDb,
  testUid,
  createAuthedClient,
  createUnauthedClient,
  cleanupRun,
  assertSucceeds,
  assertFails,
} from './test-config.mjs';

const aliceUid = testUid('alice-schools');
const bobUid = testUid('bob-schools');

// Helper : seeded school id stable pour ce run.
const seededSchoolId = testUid('school-seed');

describe('Firestore rules — schools/{schoolId}', () => {
  const cleanups = [];

  before(async () => {
    // Seed une ecole validee via Admin SDK (bypass rules).
    await adminDb.collection('schools').doc(seededSchoolId).set({
      name: 'Lycee de Test',
      city: 'Douala',
      region: 'Littoral',
      subSystem: 'both',
      isValidated: true,
      createdAt: new Date(),
    });
  });

  after(async () => {
    for (const c of cleanups) {
      try {
        await c();
      } catch (_) {
        /* ignore cleanup errors */
      }
    }
    await cleanupRun();
  });

  test('(a) user auth lit une ecole validee -> OK', async () => {
    const { db, cleanup } = await createAuthedClient(aliceUid);
    cleanups.push(cleanup);
    await assertSucceeds(getDoc(doc(db, 'schools', seededSchoolId)));
  });

  test('(b) user non auth lit schools/* -> KO', async () => {
    const { db, cleanup } = createUnauthedClient();
    cleanups.push(cleanup);
    await assertFails(getDoc(doc(db, 'schools', seededSchoolId)));
  });

  test('(c) user auth ecrit schools/* -> KO (catalogue read-only)', async () => {
    const { db, cleanup } = await createAuthedClient(aliceUid);
    cleanups.push(cleanup);
    await assertFails(
      setDoc(doc(db, 'schools', `${aliceUid}-fake-write`), {
        name: 'Fake',
        city: 'Fake',
      }),
    );
  });

  test('(d) user auth cree request avec son uid -> OK', async () => {
    const { db, cleanup } = await createAuthedClient(aliceUid);
    cleanups.push(cleanup);
    const requestsCol = collection(
      db,
      'schools',
      `_pending_${Date.now()}`,
      'requests',
    );
    await assertSucceeds(
      addDoc(requestsCol, {
        requestedBy: aliceUid,
        requestedAt: new Date(),
        status: 'pending',
        name: 'Lycee Inconnu',
        city: 'Buea',
        region: 'Sud-Ouest',
      }),
    );
  });

  test('(e) user auth cree request avec uid d\'autrui -> KO', async () => {
    const { db, cleanup } = await createAuthedClient(aliceUid);
    cleanups.push(cleanup);
    const requestsCol = collection(
      db,
      'schools',
      `_pending_${Date.now()}_other`,
      'requests',
    );
    await assertFails(
      addDoc(requestsCol, {
        requestedBy: bobUid, // pas son uid
        requestedAt: new Date(),
        status: 'pending',
        name: 'X',
        city: 'Y',
      }),
    );
  });

  test('(f) user auth cree request sans nom -> KO', async () => {
    const { db, cleanup } = await createAuthedClient(aliceUid);
    cleanups.push(cleanup);
    const requestsCol = collection(
      db,
      'schools',
      `_pending_${Date.now()}_noname`,
      'requests',
    );
    await assertFails(
      addDoc(requestsCol, {
        requestedBy: aliceUid,
        requestedAt: new Date(),
        status: 'pending',
        name: '', // vide
        city: 'Buea',
      }),
    );
  });
});
