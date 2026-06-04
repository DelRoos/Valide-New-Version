# ADR-013 — Agrégateur Mobile Money = Freemopay (v2)

**Date** : 2026-06-04
**Statut** : 🟢 Accepté (V1)
**Décide** : la question ouverte d'[ADR-007](ADR-007-mobile-money-via-aggregator.md) (« choisir parmi Tranzak / Campay / MyCoolPay ») et clôt le **Risque R1** (Story 0.18, sprint Epic 0).

## Contexte

[ADR-007](ADR-007-mobile-money-via-aggregator.md) avait acté le principe d'un **agrégateur tiers** pour MoMo + Orange Money, sans figer le partenaire. Trois candidats étaient mentionnés (Tranzak, Campay, MyCoolPay) avec des critères de sélection (webhook signé, couverture, frais, support, délai d'ouverture compte). La Story 0.18 R1 (Epic 0 Foundation) était dédiée à comparer les 3 sandbox.

Le porteur produit a tranché en cours de Foundation :

> *« Pour l'aggregateur dans un premier temps on utiliseras freemopay decrit ici [`doc/tools/Freemopay API v2 — Documentation.md`](../../../../doc/tools/Freemopay%20API%20v2%20—%20Documentation.md) »* (2026-06-04)

Freemopay n'était pas dans la liste initiale d'ADR-007 mais entre dans la catégorie « agrégateur tiers Cameroun MoMo + OM » et dispose d'une documentation v2 publique exploitable.

## Décision

**Adopter Freemopay v2 comme unique agrégateur Mobile Money pour la V1 de Valide School.**

### Surface API utilisée

| Endpoint | Méthode | Usage Valide |
|---|---|---|
| `POST /api/v2/payment/token` | aucune (appKey/secretKey JSON) | Génère un JWT 1 h utilisable par les autres endpoints |
| `POST /api/v2/payment` | Bearer ou Basic | **Init paiement abonnement / crédits** — appelée par `createSubscription` et `purchaseCredits` |
| `GET /api/v2/payment/:reference` | Bearer ou Basic | **Re-vérification du statut côté serveur** avant tout crédit utilisateur (mitigation absence de signature webhook) |
| (webhook entrant) | POST (côté backend) | Reçoit le callback final de Freemopay → déclenche la mise à jour Firestore |
| `POST /api/v2/payment/direct-withdraw` | Basic | **Non utilisé en V1** — réservé pour cashback ultérieur (ne pas exposer dans le code V1) |

### Conventions techniques V1

- **Base URL** : `https://api-v2.freemopay.com` — figée comme constante backend.
- **Authentification** : **Basic Auth** (`base64(appKey:secretKey)`). Choix : pas besoin de cycle de renouvellement du JWT, code backend plus simple. Les secrets vivent dans **Secret Manager Google Cloud** côté backend (ADR-007 § règle 1).
- **Format `externalId`** : `valide_{type}_{uid}_{sessionId}` où `type ∈ {subscription, credits}` et `sessionId` = clé d'idempotence du ADR-008. Permet la réconciliation côté backend.
- **`callback` URL** : `https://<region>-<project>.cloudfunctions.net/freemopayWebhook?token=<URL_SECRET>` où `URL_SECRET` est un secret long stocké en Secret Manager (mitigation absence de signature, cf. § Sécurité ci-dessous).
- **`description`** : courte, en français, type « Abonnement Premium Valide — 1 mois » (apparaît sur le téléphone du payeur).
- **`amount`** : entier en FCFA (XAF), envoyé en string conformément à la spec.
- **`payer`** : format `237XXXXXXXXX` (sans `+`).

### Flux paiement V1 (révision ADR-007 § 30)

```
┌──────────────────────────────────────────────────────────────────┐
│ 1. Mobile (Riverpod → Cloud Function `createSubscription`)       │
│                          │                                       │
│ 2. Backend valide user (Auth + App Check) → POST /api/v2/payment │
│    avec externalId = valide_subscription_{uid}_{sessionId}       │
│                          │                                       │
│ 3. Freemopay répond `{reference: <UUID>, status: SUCCESS}`       │
│    (init OK, payeur va recevoir notif)                           │
│                          │                                       │
│ 4. Backend stocke `payments/{sessionId}` Firestore               │
│    { freemopayReference, status: PENDING, ... }                  │
│                          │                                       │
│ 5. Mobile écoute snapshot `payments/{sessionId}` → overlay       │
│    « Confirme le paiement sur ton téléphone »                    │
│                          │                                       │
│ 6. Payeur valide PIN MoMo/OM (notification SIM Toolkit native)   │
│    [PAS de WebView — révise ADR-007 § 30]                        │
│                          │                                       │
│ 7. Freemopay POST callback → /freemopayWebhook?token=<secret>    │
│    { status: SUCCESS|FAILED, reference, amount, externalId, ... }│
│                          │                                       │
│ 8. Backend webhook :                                             │
│    a. vérifie token URL == Secret Manager                        │
│    b. RE-FETCH `GET /api/v2/payment/:reference` (source vérité)  │
│    c. update `payments/{sessionId}` + `subscriptions/{uid}`      │
│    d. répond `200 OK` (sinon Freemopay retentera)                │
│                          │                                       │
│ 9. Mobile reçoit snapshot Firestore → ferme overlay              │
└──────────────────────────────────────────────────────────────────┘
```

## Sécurité — divergence critique vs ADR-007 et mitigation

**ADR-007 § Critères de sélection** exigeait : *« Webhook signé exploitable (HMAC ou équivalent) — indispensable pour la sécurité. »*

**Freemopay v2 ne signe pas son webhook** (la doc v2 ne mentionne ni HMAC, ni clé partagée, ni signature dans l'en-tête). Le payload reçu est donc **non authentifié au niveau cryptographique**.

**Mitigation V1 (acceptée par le porteur 2026-06-04)** :

1. **Path token secret long** dans l'URL du webhook (`?token=<32+ caractères aléatoires>`, stocké Secret Manager, non versionné). Tout webhook reçu sans le token correct → `403`.
2. **Re-fetch obligatoire** du statut via `GET /api/v2/payment/:reference` **avant** tout crédit utilisateur. Le payload webhook est traité comme un **trigger**, pas comme une source de vérité.
3. **Idempotence webhook** : `payments/{sessionId}` + `webhook_events/{reference}` (cf. ADR-008). Un même `reference` reçu deux fois ne crédite qu'une seule fois.
4. **Filtrage IP** (best-effort) : whitelist d'IPs Freemopay si la liste est disponible auprès du support. Sinon, dépend uniquement des mitigations 1+2.

Ce compromis est acceptable en V1 (Foundation) parce que :

- Le re-fetch via `GET` rend la signature webhook redondante pour la sécurité financière (le backend ne croit jamais ce que le webhook lui dit, il le vérifie).
- Le path token rend la fabrication de faux webhooks impossible sans avoir accès aux secrets Google Cloud (= compromis backend, scénario hors scope V1).
- Le coût d'un appel GET supplémentaire par paiement est marginal (< 50 ms, et seulement à la réception du webhook).

**Si Freemopay v3 ajoute un HMAC signé**, l'ADR sera mis à jour pour s'appuyer dessus en priorité.

## Conséquences

### Positives

- **Recherche R1 close** : une décision plutôt qu'un benchmark de 3 sandbox, gain de ~3-5 jours d'investigation.
- **Doc API existante et fournie** : pas besoin de demander un PDF privé à un commercial.
- **API simple** : 4 endpoints utiles, schémas JSON clairs, statuts énumérés.
- **Pas de WebView** : le payeur valide via la notification native MoMo/OM (SIM Toolkit). Meilleure UX mobile, pas de page tiers à afficher, pas de problèmes de cookies/popups. L'overlay « Confirme sur ton téléphone » suffit.
- **Cashout natif** disponible (`direct-withdraw`) pour usages futurs (cashback, parrainage rémunéré).
- **Rate limit raisonnable** (100 req/min/marchand) : suffit pour Valide V1 (estimation < 10 paiements/min en peak).

### Négatives

- **Pas de signature webhook** : contredit le critère initial d'ADR-007. Mitigation acceptable (cf. ci-dessus) mais reste une dette de sécurité à monitorer.
- **Dépendance unique** : si Freemopay tombe ou augmente brutalement ses frais, le seul plan B est de **réintégrer un autre agrégateur** (effort de quelques semaines). Mitigation : abstraction backend `MomoAggregator` interface, l'implémentation Freemopay derrière, pour faciliter un swap futur.
- **Pas de retour d'expérience publique abondant** (vs Stripe / PayPal). Risque opérationnel : downtimes, support inégal, à éprouver en sandbox avant production.
- **Format `amount` en string** : friable côté backend (validation explicite obligatoire pour éviter les bugs de parsing).
- **Pas de PCI-DSS / certification listée publiquement** : à clarifier auprès du commercial Freemopay (conformité BEAC pour les flux financiers Cameroun).

### Coûts évités

- Comparaison sandbox Tranzak + Campay + MyCoolPay (Story 0.18 R1 dans sa forme initiale).
- Onboarding marchand parallèle sur 3 plateformes.

## Alternatives écartées

### A1 — Continuer le benchmark des 3 candidats (Tranzak / Campay / MyCoolPay)

**Pourquoi écarté** : décision prise par le porteur produit pour avancer. Coût d'opportunité (3-5 jours) jugé non rentable vs. choix pragmatique d'une API déjà documentée et accessible.

### A2 — Intégration directe MTN MoMo + Orange Money (sans agrégateur)

**Pourquoi écarté** : déjà tranché en ADR-007 (effort double, KYC séparés). Reste valide.

### A3 — Bypass agrégateur pour la V1 (gratuit only)

**Pourquoi écarté** : le freemium est central au modèle économique (Epic 4, P4 du MVP). Sans paiement, pas de revenu.

## Impact sur les artefacts

| Artefact | Action |
|---|---|
| [ADR-007](ADR-007-mobile-money-via-aggregator.md) | Ajouter note de tête : « Partenaire choisi : Freemopay (ADR-013) ». § « Open Question » → marquée RÉSOLUE |
| [`doc/partage/CONTRATS-API.md`](../../../../doc/partage/CONTRATS-API.md) | Ajouter note dans `createSubscription` / `purchaseCredits` / `paymentWebhook` : « Implémenté côté backend via Freemopay v2. Détails : `doc/tools/Freemopay API v2 — Documentation.md` + ADR-013 » |
| [`doc/tech/Valide Cloud Function Architecture.md`](../../../../doc/tech/Valide%20Cloud%20Function%20Architecture.md) | § 10 (paiements) : remplacer mention « agrégateur à choisir » par référence Freemopay. Ajouter flux complet du § « Flux paiement V1 » de cet ADR |
| [`CLAUDE.md` § Points ouverts](../../../../CLAUDE.md) | Le point « **Liste exacte de matières par série** » reste. Ajouter ligne « R1 MoMo aggregator : tranché ADR-013 » si pertinent ou retirer cette OQ |
| `project_manage/implementation-artifacts/sprint-status.yaml` | `0-18-risk-r1-agregateurs-momo: done  # ADR-013 (Freemopay)` |
| Story 0.18 (file) | **Non créée en `implementation-artifacts/`** — la décision a court-circuité l'exécution de la story. La trace est cet ADR + entrée sprint-status |
| Epic 0 file | Marquer Story 0.18 R1 « DONE (court-circuit via ADR-013) » |
| Story 4.x (à venir Epic 4) | Implémentation Cloud Functions `createSubscription` / `purchaseCredits` / `freemopayWebhook` basée sur cette spec |
| `doc/partage/.decision-log.md` (si existant, sinon noter dans l'epic-0) | Trace de la décision |

## Open Questions résolues

- [x] **OQ-10 (PRD)** — Choix agrégateur MoMo → **Freemopay v2**.
- [x] **Risque R1 (architecture § 13.1)** — Étude sandbox 3 candidats → **plus nécessaire** (décision directe).

## Open Questions nouvelles

- **OQ-Freemopay-1** — Quelle politique de retry côté Cloud Function si `POST /api/v2/payment` renvoie une erreur réseau (timeout, 5xx) ? Proposition : retry exponentiel max 2 tentatives + journalisation erreur. À détailler en Epic 4.
- **OQ-Freemopay-2** — Que fait-on si le webhook n'arrive **jamais** (60 s après init) ? Proposition : Cloud Function planifiée `reconcilePendingPayments` qui poll `GET /api/v2/payment/:reference` toutes les minutes pour les `payments/{sessionId}` en `PENDING`. À spécifier en Epic 4.
- **OQ-Freemopay-3** — Comment monitorer le taux d'échec et déclencher une alerte si > 5 % ? Mise en place dashboard Cloud Monitoring + alerte email à confirmer en Epic 4.
- **OQ-Freemopay-4** — Sandbox Freemopay : URL distincte ou même URL avec compte de test ? À confirmer auprès du support Freemopay dès l'ouverture de compte.
- **OQ-Freemopay-5** — Conformité BEAC / PCI : statut exact à clarifier (mail au commercial). Affecte le statut juridique de Valide vis-à-vis des flux financiers.

## Suivi et conditions de réexamen

Cet ADR sera **revu** si :

- Freemopay tombe ou pratique des frais inacceptables → re-évaluer Tranzak / Campay / MyCoolPay.
- Freemopay v3 ajoute un webhook signé HMAC → resserrer le ADR (retirer la mitigation path-token, s'appuyer sur la signature).
- L'usage révèle que les 100 req/min sont insuffisants → demander un upgrade commercial ou multi-marchand.
- Une exigence légale impose la signature des webhooks (jamais entendu de précédent BEAC mais à monitorer).

## Décisions liées

- [ADR-003](ADR-003-firebase-full-backend.md) — Cloud Functions hébergent `freemopayWebhook`. Secret Manager stocke `freemopayAppKey`, `freemopaySecretKey`, `freemopayWebhookUrlToken`.
- [ADR-007](ADR-007-mobile-money-via-aggregator.md) — Principe agrégateur tiers (cet ADR le concrétise).
- [ADR-008](ADR-008-idempotency-via-sessionid.md) — `sessionId` côté client devient `externalId` côté Freemopay (lien d'idempotence end-to-end).

## Sources

- Documentation officielle V2 fournie par le porteur : [`doc/tools/Freemopay API v2 — Documentation.md`](../../../../doc/tools/Freemopay%20API%20v2%20—%20Documentation.md)
- Base URL et endpoints : `https://api-v2.freemopay.com`
