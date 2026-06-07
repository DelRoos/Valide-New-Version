// =====================================================================
// Tests d'integration des regles Firestore — users/{uid} (Story 0.9 AC5)
// Firebase direct (sans emulateur). Cf. test/rules/test-config.mjs.
// =====================================================================

import { describe, before, after, test } from 'node:test';
import { doc, getDoc, setDoc, FieldValue } from 'firebase/firestore';

import {
  adminDb,
  testUid,
  createAuthedClient,
  createUnauthedClient,
  cleanupRun,
  assertSucceeds,
  assertFails,
} from './test-config.mjs';

const aliceUid = testUid('alice');
const bobUid = testUid('bob');
const charlieUid = testUid('charlie');
const daveUid = testUid('dave');

// Story 1.3 — helper aligne sur le schema users/{uid} actuel (IDs catalogue
// Firestore : `francophone_terminale`, `francophone_terminale_d`, etc.).
const validUserDoc = (uid) => ({
  uid,
  subSystem: 'francophone',
  language: 'fr',
  filiere: 'generale',
  niveau: 'francophone_terminale',
  serie: 'francophone_terminale_d',
  derivedSubjects: ['francophone_math', 'francophone_pct', 'francophone_svt'],
  optedOutSubjects: [],
  examTargets: ['exam_bac_francophone_d'],
  schoolId: null,
  displayName: `Test ${uid}`,
  photoUrl: null,
  createdAt: new Date(),
  updatedAt: new Date(),
  deletionRequestedAt: null,
});

describe('Firestore rules — users/{uid}', () => {
  const cleanups = [];

  before(async () => {
    // Seed : alice prealable via Admin SDK (bypass rules)
    await adminDb.collection('users').doc(aliceUid).set(validUserDoc(aliceUid));
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

  test('(a) user auth lit son propre doc -> OK', async () => {
    const { db, cleanup } = await createAuthedClient(aliceUid);
    cleanups.push(cleanup);
    await assertSucceeds(getDoc(doc(db, 'users', aliceUid)));
  });

  test('(b) user auth lit doc d un autre user -> KO', async () => {
    const { db, cleanup } = await createAuthedClient(bobUid);
    cleanups.push(cleanup);
    await assertFails(getDoc(doc(db, 'users', aliceUid)));
  });

  test('(c) user non authentifie lit users/* -> KO', async () => {
    const { db, cleanup } = createUnauthedClient();
    cleanups.push(cleanup);
    await assertFails(getDoc(doc(db, 'users', aliceUid)));
  });

  test('(d) creation avec subSystem invalide -> KO', async () => {
    const { db, cleanup } = await createAuthedClient(charlieUid);
    cleanups.push(cleanup);
    await assertFails(
      setDoc(doc(db, 'users', charlieUid), {
        ...validUserDoc(charlieUid),
        subSystem: 'other',
      }),
    );
  });

  test('(e) creation valide -> OK', async () => {
    const { db, cleanup } = await createAuthedClient(daveUid);
    cleanups.push(cleanup);
    await assertSucceeds(
      setDoc(doc(db, 'users', daveUid), validUserDoc(daveUid)),
    );
  });

  test('(f) update subSystem (fige inscription) -> KO', async () => {
    const { db, cleanup } = await createAuthedClient(aliceUid);
    cleanups.push(cleanup);
    await assertFails(
      setDoc(
        doc(db, 'users', aliceUid),
        { ...validUserDoc(aliceUid), subSystem: 'anglophone' },
      ),
    );
  });

  // Story 1.3 — 3 nouveaux cas : immutabilite etendue.

  test('(g) update language (derive subSystem) -> KO', async () => {
    const { db, cleanup } = await createAuthedClient(aliceUid);
    cleanups.push(cleanup);
    await assertFails(
      setDoc(
        doc(db, 'users', aliceUid),
        { ...validUserDoc(aliceUid), language: 'en' },
      ),
    );
  });

  test('(h) update filiere (fige Story 1.3) -> KO', async () => {
    const { db, cleanup } = await createAuthedClient(aliceUid);
    cleanups.push(cleanup);
    await assertFails(
      setDoc(
        doc(db, 'users', aliceUid),
        { ...validUserDoc(aliceUid), filiere: 'technique' },
      ),
    );
  });

  test('(i) update niveau (fige Story 1.3) -> KO', async () => {
    const { db, cleanup } = await createAuthedClient(aliceUid);
    cleanups.push(cleanup);
    await assertFails(
      setDoc(
        doc(db, 'users', aliceUid),
        { ...validUserDoc(aliceUid), niveau: 'francophone_premiere' },
      ),
    );
  });
});
