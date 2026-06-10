// =====================================================================
// Tests d'integration des regles Firestore — users/{uid} (Story 0.9 AC5)
// Firebase direct (sans emulateur). Cf. test/rules/test-config.mjs.
// =====================================================================

import { describe, before, after, test } from 'node:test';
import { doc, getDoc, setDoc, updateDoc, serverTimestamp } from 'firebase/firestore';

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

  // Story 1.4 — validation optedOutSubjects subset derivedSubjects.

  test('(j) update optedOutSubjects valide (sous-ensemble de derivedSubjects) -> OK', async () => {
    const { db, cleanup } = await createAuthedClient(aliceUid);
    cleanups.push(cleanup);
    // update partiel (cf. impl Story 1.4 updateOptedOutSubjects) : touche
    // uniquement optedOutSubjects + updatedAt, preserve les champs immuables.
    await assertSucceeds(
      updateDoc(
        doc(db, 'users', aliceUid),
        {
          optedOutSubjects: ['francophone_pct'],
          updatedAt: serverTimestamp(),
        },
      ),
    );
  });

  test('(k) update optedOutSubjects invalide (matiere hors derivedSubjects) -> KO', async () => {
    const { db, cleanup } = await createAuthedClient(aliceUid);
    cleanups.push(cleanup);
    await assertFails(
      updateDoc(
        doc(db, 'users', aliceUid),
        {
          // 'anglophone_biology' n'existe pas dans derivedSubjects d'alice.
          optedOutSubjects: ['anglophone_biology'],
          updatedAt: serverTimestamp(),
        },
      ),
    );
  });

  // Story 1.15 — validation pickedSubjects subset derivedSubjects
  // (Decision 3 pragmatique : pas de validation `obligatorySubjectIds`
  // cote serveur, garantie client uniquement).

  test('(l) update pickedSubjects valide (sous-ensemble derivedSubjects) -> OK', async () => {
    const { db, cleanup } = await createAuthedClient(aliceUid);
    cleanups.push(cleanup);
    await assertSucceeds(
      updateDoc(
        doc(db, 'users', aliceUid),
        {
          // alice = francophone Tle D, derivedSubjects = [math, pct, svt].
          // Subset valide (3 oblig pour ce profil v1).
          pickedSubjects: ['francophone_math', 'francophone_pct'],
          updatedAt: serverTimestamp(),
        },
      ),
    );
  });

  test('(m) update pickedSubjects invalide (matiere hors derivedSubjects) -> KO', async () => {
    const { db, cleanup } = await createAuthedClient(aliceUid);
    cleanups.push(cleanup);
    await assertFails(
      updateDoc(
        doc(db, 'users', aliceUid),
        {
          // 'anglophone_biology' n'existe pas dans derivedSubjects d'alice.
          pickedSubjects: ['francophone_math', 'anglophone_biology'],
          updatedAt: serverTimestamp(),
        },
      ),
    );
  });

  test('(n) update pickedSubjects vide (subset trivial) -> OK pragmatique', async () => {
    // Pragmatique MVP : pas de validation cardinalite cote serveur. Si client
    // bypass et POST une liste vide ou sans obligatoires, Firestore accepte
    // mais profil est UX-casse (re-evaluable Epic 2+).
    const { db, cleanup } = await createAuthedClient(aliceUid);
    cleanups.push(cleanup);
    await assertSucceeds(
      updateDoc(
        doc(db, 'users', aliceUid),
        {
          pickedSubjects: [],
          updatedAt: serverTimestamp(),
        },
      ),
    );
  });

  // Story 1.5.d — Denormalisation 4 champs school* en 1 update partiel.
  // Pas de validation stricte coherence schoolCity <-> schools/{id}.city V1
  // (un client malveillant ne ferait que falsifier SON propre profil — pas
  // d'escalade securite, pas d'impact ranking equipe).

  test('(o) update schoolId + schoolCity + schoolRegion + schoolName coherents -> OK', async () => {
    const { db, cleanup } = await createAuthedClient(aliceUid);
    cleanups.push(cleanup);
    await assertSucceeds(
      updateDoc(
        doc(db, 'users', aliceUid),
        {
          schoolId: 'school_test_lycee_x',
          schoolCity: 'Yaounde',
          schoolRegion: 'Centre',
          schoolName: 'Lycee Test X',
          updatedAt: serverTimestamp(),
        },
      ),
    );
  });

  test('(p) update unlink : 4 champs school* = null coherents -> OK', async () => {
    const { db, cleanup } = await createAuthedClient(aliceUid);
    cleanups.push(cleanup);
    await assertSucceeds(
      updateDoc(
        doc(db, 'users', aliceUid),
        {
          schoolId: null,
          schoolCity: null,
          schoolRegion: null,
          schoolName: null,
          updatedAt: serverTimestamp(),
        },
      ),
    );
  });

  test('(q) update subSystem reste refuse meme avec school* (immuable Story 1.3) -> KO', async () => {
    const { db, cleanup } = await createAuthedClient(aliceUid);
    cleanups.push(cleanup);
    // Tentative de bypass : payer le bypass schoolCity pour passer subSystem.
    // La rule immutable Story 1.3 reste preservee Story 1.5.d.
    await assertFails(
      updateDoc(
        doc(db, 'users', aliceUid),
        {
          subSystem: 'anglophone',
          schoolCity: 'Bamenda',
          updatedAt: serverTimestamp(),
        },
      ),
    );
  });
});
