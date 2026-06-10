// =====================================================================
// Tests d'integration des regles Firestore — schools/{schoolId} (Story 1.7)
// + school_requests/{requestId} (Story 1.5.c)
// Firebase direct (sans emulateur). Cf. test/rules/test-config.mjs.
// =====================================================================

import { describe, before, after, test } from 'node:test';
import {
  doc,
  getDoc,
  setDoc,
  addDoc,
  updateDoc,
  deleteDoc,
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

describe('Firestore rules — schools/{schoolId} + school_requests (Story 1.5.c)', () => {
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

  // ======================================================================
  // Story 1.5.c — school_requests/{requestId} (collection racine)
  // ======================================================================

  test('(d) Story 1.5.c — user auth cree school_request avec son uid + champs valides -> OK', async () => {
    const { db, cleanup } = await createAuthedClient(aliceUid);
    cleanups.push(cleanup);
    await assertSucceeds(
      addDoc(collection(db, 'school_requests'), {
        requestedBy: aliceUid,
        requestedAt: new Date(),
        status: 'pending',
        name: 'Lycee Inconnu',
        city: 'Buea',
        region: 'Sud-Ouest',
      }),
    );
  });

  test('(e) Story 1.5.c — user auth cree school_request avec uid d\'autrui -> KO', async () => {
    const { db, cleanup } = await createAuthedClient(aliceUid);
    cleanups.push(cleanup);
    await assertFails(
      addDoc(collection(db, 'school_requests'), {
        requestedBy: bobUid, // pas son uid
        requestedAt: new Date(),
        status: 'pending',
        name: 'Lycee Anonyme',
        city: 'Buea',
      }),
    );
  });

  test('(f) Story 1.5.c — user auth cree school_request avec name trop court -> KO', async () => {
    const { db, cleanup } = await createAuthedClient(aliceUid);
    cleanups.push(cleanup);
    await assertFails(
      addDoc(collection(db, 'school_requests'), {
        requestedBy: aliceUid,
        requestedAt: new Date(),
        status: 'pending',
        name: 'XY', // < 3 chars
        city: 'Buea',
      }),
    );
  });

  test('(g) Story 1.5.c — user auth cree school_request avec status != pending -> KO', async () => {
    const { db, cleanup } = await createAuthedClient(aliceUid);
    cleanups.push(cleanup);
    await assertFails(
      addDoc(collection(db, 'school_requests'), {
        requestedBy: aliceUid,
        requestedAt: new Date(),
        status: 'approved', // tentative d'escalade
        name: 'Lycee Malveillant',
        city: 'Buea',
      }),
    );
  });

  test('(h) Story 1.5.c — user auth cree school_request avec subSystem invalide -> KO', async () => {
    const { db, cleanup } = await createAuthedClient(aliceUid);
    cleanups.push(cleanup);
    await assertFails(
      addDoc(collection(db, 'school_requests'), {
        requestedBy: aliceUid,
        requestedAt: new Date(),
        status: 'pending',
        name: 'Lycee SubSystem Invalide',
        city: 'Buea',
        subSystem: 'invalid', // pas dans francophone/anglophone/both
      }),
    );
  });

  test('(i) Story 1.5.c — user auth cree school_request avec subSystem valide -> OK', async () => {
    const { db, cleanup } = await createAuthedClient(aliceUid);
    cleanups.push(cleanup);
    await assertSucceeds(
      addDoc(collection(db, 'school_requests'), {
        requestedBy: aliceUid,
        requestedAt: new Date(),
        status: 'pending',
        name: 'Lycee Bilingue Test',
        city: 'Buea',
        subSystem: 'both',
      }),
    );
  });

  test('(j) Story 1.5.c — user auth lit sa propre school_request -> OK', async () => {
    // Seed via Admin SDK une demande appartenant a Alice.
    const aliceReqId = testUid('school-req-alice');
    await adminDb.collection('school_requests').doc(aliceReqId).set({
      requestedBy: aliceUid,
      requestedAt: new Date(),
      status: 'pending',
      name: 'Lycee Alice Test',
      city: 'Buea',
    });
    const { db, cleanup } = await createAuthedClient(aliceUid);
    cleanups.push(cleanup);
    cleanups.push(async () => {
      await adminDb.collection('school_requests').doc(aliceReqId).delete();
    });
    await assertSucceeds(getDoc(doc(db, 'school_requests', aliceReqId)));
  });

  test('(k) Story 1.5.c — user auth lit la school_request d\'un autre user -> KO', async () => {
    const bobReqId = testUid('school-req-bob');
    await adminDb.collection('school_requests').doc(bobReqId).set({
      requestedBy: bobUid,
      requestedAt: new Date(),
      status: 'pending',
      name: 'Lycee Bob Test',
      city: 'Bamenda',
    });
    const { db, cleanup } = await createAuthedClient(aliceUid);
    cleanups.push(cleanup);
    cleanups.push(async () => {
      await adminDb.collection('school_requests').doc(bobReqId).delete();
    });
    await assertFails(getDoc(doc(db, 'school_requests', bobReqId)));
  });

  test('(l) Story 1.5.c — user auth update sa propre school_request -> KO (moderation admin only)', async () => {
    const aliceReqId = testUid('school-req-alice-update');
    await adminDb.collection('school_requests').doc(aliceReqId).set({
      requestedBy: aliceUid,
      requestedAt: new Date(),
      status: 'pending',
      name: 'Lycee Alice Update Test',
      city: 'Buea',
    });
    const { db, cleanup } = await createAuthedClient(aliceUid);
    cleanups.push(cleanup);
    cleanups.push(async () => {
      await adminDb.collection('school_requests').doc(aliceReqId).delete();
    });
    await assertFails(
      updateDoc(doc(db, 'school_requests', aliceReqId), {
        status: 'approved', // tentative d'auto-moderation
      }),
    );
  });

  test('(m) Story 1.5.c — user auth delete sa propre school_request -> KO', async () => {
    const aliceReqId = testUid('school-req-alice-delete');
    await adminDb.collection('school_requests').doc(aliceReqId).set({
      requestedBy: aliceUid,
      requestedAt: new Date(),
      status: 'pending',
      name: 'Lycee Alice Delete Test',
      city: 'Buea',
    });
    const { db, cleanup } = await createAuthedClient(aliceUid);
    cleanups.push(cleanup);
    cleanups.push(async () => {
      await adminDb.collection('school_requests').doc(aliceReqId).delete();
    });
    await assertFails(deleteDoc(doc(db, 'school_requests', aliceReqId)));
  });
});
