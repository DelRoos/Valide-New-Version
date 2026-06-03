# ADR-007 — Paiement Mobile Money via agrégateur tiers

**Date** : 2026-06-03
**Statut** : 🟢 Accepté

## Contexte

Valide vise un marché où **Mobile Money est le moyen de paiement dominant** chez les jeunes adultes : MTN MoMo et Orange Money cumulent ~80 % des transactions mobiles. La carte bancaire est marginale dans la cible (Tle / Form 5 / Sixth, parents commerçants, étudiants).

Trois options d'intégration ont été pesées :

- **Intégration directe MTN MoMo + Orange Money** : APIs séparées, contrats commerciaux séparés, KYC séparés, webhooks à des formats différents. Effort important × 2 partenaires.
- **Stripe / PayPal** : couverture Mobile Money limitée et coûts en devise étrangère.
- **Agrégateur tiers** spécialisé Afrique francophone : Tranzak, Campay, MyCoolPay. Une API unifiée pour MoMo + OM + (parfois) d'autres méthodes (bank transfer).

Trois agrégateurs candidats sont mentionnés dans les docs d'archi (Tranzak, Campay, MyCoolPay) sans choix arrêté à ce stade.

## Décision

**Passer par un agrégateur tiers** (à choisir parmi Tranzak / Campay / MyCoolPay — décision finale en P1 / début P4).

Critères de sélection à utiliser :

1. **Webhook signé exploitable** (HMAC ou équivalent) — indispensable pour la sécurité.
2. **Couverture MoMo + OM** stable et documentée.
3. **Frais transactionnels** raisonnables.
4. **Qualité du support** technique (anglophone et/ou francophone, réactivité).
5. **Process d'ouverture de compte marchand** réaliste sur 6 semaines.

L'app mobile ouvre une **WebView** sur la page de paiement hébergée par l'agrégateur. L'élève valide par **PIN MoMo ou OM** sur son téléphone. L'agrégateur confirme par **webhook signé** au backend.

## Conséquences

**Positives**

- **Une seule intégration** au lieu de deux (MTN + Orange).
- **Webhook signé** simplifie la vérification serveur (clé secrète stockée en Secret Manager).
- **WebView agrégateur** = l'app n'a pas à gérer le PIN ni la sécurité du wallet (responsabilité du partenaire).
- **Conformité PCI / réglementation BEAC** déléguée à l'agrégateur.

**Négatives**

- **Dépendance externe critique** : si l'agrégateur tombe, le paiement tombe.
- **Frais transactionnels** prélevés (généralement 1.5 à 3 % par transaction). À intégrer dans la stratégie de prix.
- **Délai d'ouverture compte marchand** : 2-4 semaines selon partenaire. **Doit être lancé dès J1 du projet** — c'est le **risque R1** (cf. architecture.md § 13.1).
- **Choix non encore arrêté** : 3 candidats, comparaison à mener en P1.

## Règles d'implémentation non négociables

1. **L'app ne décide jamais du statut premium / crédit ajouté.** Le webhook serveur est la **seule source de vérité**. L'app affiche un overlay « Confirming your payment… » pendant l'attente et **écoute le stream Firestore** `subscriptions/{uid}` ou `credits/{uid}` pour la confirmation.
2. **Webhook signature vérifiée AVANT toute action.** Cf. archi backend § 10.
3. **Idempotence webhook** : un même `aggregator_event_id` reçu deux fois ne crédite qu'une seule fois (collection `webhook_events/{eventId}` côté serveur).
4. **Mode WebView + URL agrégateur** uniquement. **Pas de saisie de PIN** dans l'app Valide.

## Open Question (PRD OQ-10)

Décision du partenaire agrégateur à prendre dès J1. Recommandation : test de bout en bout des 3 candidats sur leur sandbox en parallèle de la P1, choix figé en début P2.

## Détail d'implémentation

Voir :

- [`doc/tech/Valide Cloud Function Architecture.md`](../../../../doc/tech/Valide%20Cloud%20Function%20Architecture.md) — section 10 (paiements et webhooks)
- [`doc/partage/CONTRATS-API.md`](../../../../doc/partage/CONTRATS-API.md) — `createSubscription`, `purchaseCredits`, `paymentWebhook`
- EXPERIENCE.md Flow 4 (paywall + paiement OM)

## Décisions liées

- [ADR-008](ADR-008-idempotency-via-sessionid.md) — l'idempotence appliquée aussi aux webhooks.
- [ADR-003](ADR-003-firebase-full-backend.md) — Cloud Functions hébergent le `paymentWebhook` ; Secret Manager stocke la clé de signature.
