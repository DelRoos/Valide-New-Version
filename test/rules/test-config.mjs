// =====================================================================
// Helpers de test — Firebase direct (sans emulateur)
// =====================================================================
//
// Strategie : utiliser le Firebase Admin SDK (cote serveur) pour generer
// des custom tokens, puis se connecter avec le Firebase Web SDK comme un
// vrai client. Toutes les requetes Firestore passent par les regles
// reellement deployees sur le projet `valide-edu`.
//
// Pre-requis (cote dev) :
//   - Service account JSON tele charge depuis Console Firebase :
//     Project Settings > Service accounts > Generate new private key
//   - Place dans `test/rules/service-account.json` (gitignore) OU pointe
//     via la variable d'environnement GOOGLE_APPLICATION_CREDENTIALS
// =====================================================================

import { readFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

import { initializeApp as initAdminApp, cert } from 'firebase-admin/app';
import { getAuth as getAdminAuth } from 'firebase-admin/auth';
import { getFirestore as getAdminFirestore } from 'firebase-admin/firestore';

import { initializeApp as initWebApp, deleteApp } from 'firebase/app';
import {
  getAuth as getWebAuth,
  signInWithCustomToken,
  signOut,
} from 'firebase/auth';
import { getFirestore as getWebFirestore } from 'firebase/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));

/** Projet Firebase cible. Voir feedback "pas d'emulateur" — tests directs. */
export const PROJECT_ID = process.env.FIREBASE_PROJECT_ID ?? 'valide-edu';

/**
 * Web API Key publique pour valide-edu. Reprise de
 * mobile_app/lib/firebase_options.dart (Android) — les API keys Firebase
 * sont publiques par design (Firebase doc "API keys are NOT secrets").
 */
export const WEB_API_KEY =
  process.env.FIREBASE_WEB_API_KEY ?? 'AIzaSyBhemIc1aKYBBVIYMe5JIc9OEAp4f0ilxc';

/**
 * Run ID unique pour ce passage de tests. Tous les UIDs/docs crees
 * sont prefixes avec `tr-{RUN_ID}-` pour eviter collisions + faciliter
 * cleanup.
 */
export const RUN_ID = `${Date.now().toString(36)}-${Math.random()
  .toString(36)
  .slice(2, 6)}`;

const serviceAccountPath =
  process.env.GOOGLE_APPLICATION_CREDENTIALS ??
  resolve(__dirname, 'service-account.json');

if (!existsSync(serviceAccountPath)) {
  throw new Error(
    `Service account introuvable a "${serviceAccountPath}". ` +
      `Telecharge depuis Console Firebase > Project Settings > Service accounts. ` +
      `Place dans test/rules/service-account.json ou pointe GOOGLE_APPLICATION_CREDENTIALS.`,
  );
}

const serviceAccount = JSON.parse(readFileSync(serviceAccountPath, 'utf8'));

const adminApp = initAdminApp(
  { credential: cert(serviceAccount), projectId: PROJECT_ID },
  `valide-rules-test-admin-${RUN_ID}`,
);

export const adminAuth = getAdminAuth(adminApp);
export const adminDb = getAdminFirestore(adminApp);

/** Prefixe un UID de test pour isoler ce run. */
export function testUid(name) {
  return `tr-${RUN_ID}-${name}`;
}

/**
 * Cree un client Firestore authentifie comme `uid`.
 * Retourne `{ db, cleanup }`. Appelle `cleanup()` en fin de test.
 */
export async function createAuthedClient(uid) {
  const customToken = await adminAuth.createCustomToken(uid);
  const webApp = initWebApp(
    {
      apiKey: WEB_API_KEY,
      authDomain: `${PROJECT_ID}.firebaseapp.com`,
      projectId: PROJECT_ID,
    },
    `client-${uid}`,
  );
  const auth = getWebAuth(webApp);
  await signInWithCustomToken(auth, customToken);
  const db = getWebFirestore(webApp);
  return {
    db,
    cleanup: async () => {
      await signOut(auth);
      await deleteApp(webApp);
    },
  };
}

/**
 * Cree un client Firestore NON authentifie (anonyme = ni custom token ni
 * signInAnonymously). Utile pour tester les acces non auth.
 */
export function createUnauthedClient() {
  const webApp = initWebApp(
    {
      apiKey: WEB_API_KEY,
      authDomain: `${PROJECT_ID}.firebaseapp.com`,
      projectId: PROJECT_ID,
    },
    `client-anon-${Math.random().toString(36).slice(2, 8)}`,
  );
  const db = getWebFirestore(webApp);
  return {
    db,
    cleanup: async () => {
      await deleteApp(webApp);
    },
  };
}

/**
 * Nettoie tous les docs `users/tr-{RUN_ID}-*` et `_smoketest/tr-{RUN_ID}-*`
 * crees pendant ce run. A appeler en `after()` global.
 */
export async function cleanupRun() {
  const prefix = `tr-${RUN_ID}-`;
  const cols = ['users', '_smoketest'];
  for (const col of cols) {
    const snap = await adminDb
      .collection(col)
      .where('uid', '>=', prefix)
      .where('uid', '<', prefix + '')
      .get();
    for (const doc of snap.docs) {
      await doc.ref.delete();
    }
    // Cas docs sans champ uid (smoketest) : on liste par doc ID prefix.
    const all = await adminDb.collection(col).get();
    for (const doc of all.docs) {
      if (doc.id.startsWith(prefix)) {
        await doc.ref.delete();
      }
    }
  }
}

/**
 * Helper : assertion succes (l'op ne throw pas).
 */
export async function assertSucceeds(promise) {
  try {
    await promise;
  } catch (err) {
    throw new Error(`Attendu: succes, recu erreur: ${err.message ?? err}`);
  }
}

/**
 * Helper : assertion echec (l'op throw avec permission-denied ou unauth).
 */
export async function assertFails(promise) {
  try {
    await promise;
  } catch (err) {
    const code = err.code ?? err.message ?? '';
    if (
      String(code).includes('permission-denied') ||
      String(code).includes('PERMISSION_DENIED') ||
      String(code).includes('unauthenticated')
    ) {
      return;
    }
    throw new Error(
      `Attendu: permission-denied/unauthenticated, recu code "${code}"`,
    );
  }
  throw new Error('Attendu: echec permission-denied, mais l\'op a reussi');
}
