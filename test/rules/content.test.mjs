// =====================================================================
// Tests Firestore rules — chapters/{chapterId} + lessons/{lessonId}
// + notions/{notionId} (Story 2.1, Epic 2)
//
// Regles testees :
//   - read  si auth     : OK   (tout user authentifie peut lire)
//   - read  si non-auth : KO   (pas de lecture publique contrairement au catalogue)
//   - write si auth     : KO   (seed via script Python uniquement)
// =====================================================================

import { describe, before, after, test } from 'node:test';
import {
  doc,
  getDoc,
  setDoc,
  deleteDoc,
} from 'firebase/firestore';

import {
  adminDb,
  testUid,
  createAuthedClient,
  createUnauthedClient,
  assertSucceeds,
  assertFails,
} from './test-config.mjs';

const aliceUid = testUid('alice-content');

// IDs stables pour ce run.
const seededChapterId = testUid('chapter-seed');
const seededLessonId  = testUid('lesson-seed');
const seededNotionId  = testUid('notion-seed');

describe('Firestore rules — chapters/lessons/notions (Story 2.1)', () => {
  before(async () => {
    // Seed via Admin SDK (bypass rules) — simule le seed Python.
    await adminDb.collection('chapters').doc(seededChapterId).set({
      subjectId: 'francophone_math',
      order: 1,
      title: { fr: 'Chapitre test', en: 'Test chapter' },
      description: null,
      createdAt: new Date(),
    });

    await adminDb.collection('lessons').doc(seededLessonId).set({
      chapterId: seededChapterId,
      order: 1,
      title: { fr: 'Lecon test', en: 'Test lesson' },
      content: { fr: 'Contenu FR', en: 'Content EN' },
      createdAt: new Date(),
    });

    await adminDb.collection('notions').doc(seededNotionId).set({
      lessonId: seededLessonId,
      order: 1,
      title: { fr: 'Notion test', en: 'Test notion' },
      createdAt: new Date(),
    });
  });

  after(async () => {
    await adminDb.collection('chapters').doc(seededChapterId).delete().catch(() => {});
    await adminDb.collection('lessons').doc(seededLessonId).delete().catch(() => {});
    await adminDb.collection('notions').doc(seededNotionId).delete().catch(() => {});
  });

  // -----------------------------------------------------------------------
  // (a) read chapter — user authentifie : OK
  // -----------------------------------------------------------------------
  test('(a) read chapter — user authentifie : succes', async () => {
    const { db, cleanup } = await createAuthedClient(aliceUid);
    try {
      await assertSucceeds(getDoc(doc(db, 'chapters', seededChapterId)));
    } finally {
      await cleanup();
    }
  });

  // -----------------------------------------------------------------------
  // (b) read chapter — user NON authentifie : KO
  // -----------------------------------------------------------------------
  test('(b) read chapter — user non authentifie : echec', async () => {
    const { db, cleanup } = createUnauthedClient();
    try {
      await assertFails(getDoc(doc(db, 'chapters', seededChapterId)));
    } finally {
      await cleanup();
    }
  });

  // -----------------------------------------------------------------------
  // (c) read lesson — user authentifie : OK
  // -----------------------------------------------------------------------
  test('(c) read lesson — user authentifie : succes', async () => {
    const { db, cleanup } = await createAuthedClient(aliceUid);
    try {
      await assertSucceeds(getDoc(doc(db, 'lessons', seededLessonId)));
    } finally {
      await cleanup();
    }
  });

  // -----------------------------------------------------------------------
  // (d) read notion — user authentifie : OK
  // -----------------------------------------------------------------------
  test('(d) read notion — user authentifie : succes', async () => {
    const { db, cleanup } = await createAuthedClient(aliceUid);
    try {
      await assertSucceeds(getDoc(doc(db, 'notions', seededNotionId)));
    } finally {
      await cleanup();
    }
  });

  // -----------------------------------------------------------------------
  // (e) write chapter — user authentifie : KO (write: if false)
  // -----------------------------------------------------------------------
  test('(e) write chapter — user authentifie : echec (write interdit)', async () => {
    const { db, cleanup } = await createAuthedClient(aliceUid);
    try {
      await assertFails(
        setDoc(doc(db, 'chapters', testUid('chapter-write-attempt')), {
          subjectId: 'francophone_math',
          order: 99,
          title: { fr: 'Hack', en: 'Hack' },
          description: null,
        }),
      );
    } finally {
      await cleanup();
    }
  });

  // -----------------------------------------------------------------------
  // (f) delete lesson — user authentifie : KO
  // -----------------------------------------------------------------------
  test('(f) delete lesson — user authentifie : echec (write interdit)', async () => {
    const { db, cleanup } = await createAuthedClient(aliceUid);
    try {
      await assertFails(deleteDoc(doc(db, 'lessons', seededLessonId)));
    } finally {
      await cleanup();
    }
  });
});
