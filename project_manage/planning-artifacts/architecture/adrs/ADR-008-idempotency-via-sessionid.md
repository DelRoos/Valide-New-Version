# ADR-008 — Idempotence via `sessionId` dans la même transaction Firestore

**Date** : 2026-06-03
**Statut** : 🟢 Accepté

## Contexte

Le marché cible présente une **connectivité instable** (3G fluctuante, coupures fréquentes). Cela implique que **toute opération réseau peut être rejouée** :

- L'app n'a pas reçu la réponse → elle retente.
- L'élève tape deux fois rapidement sur « Soumettre » par réflexe.
- L'OS Android tue l'app pendant un upload, l'app retente au retour.
- L'agrégateur Mobile Money rejoue son webhook (sa propre logique de retry).

Sans protection :

- Compléter un exercice 2× → **points doublés**, **santé scolaire faussée** (+ X * 2 sur la même notion).
- Soumission Mode 1 2× → **5 crédits débités 2 fois** (10 crédits perdus).
- Achat pack crédits 2× → **30 crédits crédités au lieu de 30**.

Ces incohérences minent la confiance dans les points, le solde et la gamification — qui sont des piliers d'engagement produit.

## Décision

**Idempotence stricte** sur toutes les opérations rejouables, via le mécanisme suivant :

1. **Le mobile génère un `sessionId` unique** (UUID v4) au début de chaque action. Toutes les retries de cette action utilisent **le même** `sessionId`.

2. **Le serveur (Cloud Function) fait DANS UNE SEULE transaction Firestore** :
   - Lecture de la garde : `tx.get(doc('users/{uid}/completions/{sessionId}'))`
   - Si la marque existe → renvoyer le résultat existant **sans rien écrire de nouveau**.
   - Sinon → effectuer toutes les écritures liées (santé + niveau + points + marque d'idempotence) dans la **même** transaction. Tout réussit, ou rien.

3. **La garde DOIT être DANS la transaction.** Pas hors. Sinon : condition de course garantie sur double-tap simultané (deux appels passent la garde avant que l'un n'ait écrit la marque).

```typescript
// Côté Cloud Function (illustratif)
await db.runTransaction(async (tx) => {
  const completionRef = doc(`users/${uid}/completions/${sessionId}`);
  const existing = await tx.get(completionRef);
  if (existing.exists) {
    return existing.data(); // déjà traité, idempotent
  }

  const score = computeScore(payload);
  const impacts = computeNotionImpacts(payload);
  const points = computePoints(score);

  // Toutes les écritures dans la MÊME transaction
  tx.set(completionRef, { sessionId, score, impacts, pointsAwarded: points });
  for (const impact of impacts) {
    tx.set(doc(`users/${uid}/health/${impact.notionId}`), { delta: impact.delta }, { merge: true });
  }
  tx.set(doc(`users/${uid}/stats`), {
    totalPoints: increment(points),
    weeklyPoints: increment(points)
  }, { merge: true });

  return { score, impacts, pointsAwarded: points };
});
```

## Conséquences

**Positives**

- **Zéro double comptage** garanti par Firestore (transactions ACID).
- **Robustesse aux retries Dio** côté mobile — pas de logique anti-double à inventer côté client.
- **Pattern uniforme** appliqué à toutes les opérations rejouables — pas de cas particulier par action.

**Négatives**

- **Coût** : chaque transaction Firestore est facturée en lectures + écritures. Mesure d'impact sur le budget Firebase à surveiller.
- **Latence légèrement supérieure** à un appel non-transactionnel (typiquement +100-300 ms).
- **Discipline forte requise côté dev** : oublier la garde dans la transaction = bug critique invisible en test simple. Doit être testé avec **simulation de double-tap + coupure réseau**.

## Application

| Action rejouable | Clé d'idempotence | Documents écrits ensemble dans la transaction |
|---|---|---|
| Compléter exercice (Mode 1, Mode 2, Mode 3) | `sessionId` mobile | `completions/{sessionId}` + `health/{notionId}` + `stats` |
| Compléter quiz | `sessionId` mobile | idem |
| Compléter sujet d'examen | `sessionId` mobile | idem + bonus mention si applicable |
| Débit crédits (Mode 1, Mode 3 session) | `sessionId` (le même que la complétion) | `credits` + `credits/transactions/{sessionId}` |
| Webhook paiement agrégateur | `aggregator_event_id` (clé fournie par l'agrégateur, pas un sessionId) | `webhook_events/{eventId}` + `subscriptions/{uid}` ou `credits/{uid}` + `payment_intents/{intentId}` |
| Attribution de points (FR-32 PRD) | `sessionId` de l'action source | inclus dans la transaction de l'action |

## Tests obligatoires

Cf. CONTRIBUTING.md § 8.2 — tests d'idempotence **obligatoires** sur chaque Function rejouable :

- Test « double-tap rapide » : 2 appels parallèles avec même `sessionId` → 1 seul résultat écrit.
- Test « retry réseau » : coupure simulée entre première écriture et réponse → second appel ne re-credit pas.
- Test webhook : même `event_id` reçu 2 fois → 1 seul crédit appliqué.

## Détail d'implémentation

Voir :

- [`doc/tech/Valide Cloud Function Architecture.md`](../../../../doc/tech/Valide%20Cloud%20Function%20Architecture.md) — section 9 (transactions et idempotence — pierre angulaire)
- [`doc/partage/ALGORITHMES.md § 9`](../../../../doc/partage/ALGORITHMES.md) — détail du pattern
- architecture.md § 8 (synthèse)

## Décisions liées

- [ADR-003](ADR-003-firebase-full-backend.md) — Firestore comme moteur transactionnel.
- [ADR-007](ADR-007-mobile-money-via-aggregator.md) — idempotence appliquée aussi aux webhooks d'agrégateur.
