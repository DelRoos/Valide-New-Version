# ADR-003 — Backend tout-Firebase

**Date** : 2026-06-03
**Statut** : 🟢 Accepté

## Contexte

Le MVP doit livrer en 6 semaines avec une équipe restreinte : authentification, base temps réel, stockage de fichiers, fonctions serveur (IA, paiements), notifications push, analytics, suivi des crashs, attestation d'origine de l'app, gestion de secrets.

Trois grandes options :

- **Stack custom (PostgreSQL + NestJS + Auth0 + S3 + Pusher)** : flexibilité maximale, mais infrastructure à orchestrer, ops à assumer.
- **Supabase** : Postgres + Auth + Storage open-source, attractif, mais Cloud Functions / Messaging / App Check pas natifs.
- **Firebase complet** : couvre 100 % du besoin nativement, cache offline Firestore natif (énorme pour le marché cible avec sa connectivité instable).

## Décision

**Tout Firebase pour le MVP** :

| Module | Usage |
|---|---|
| `firebase_auth` | Authentification Google + Apple |
| `cloud_firestore` | BDD NoSQL temps réel + cache offline automatique |
| `firebase_storage` | Photos Mode 1 compressées WebP, médias de contenu |
| `cloud_functions` | Cloud Functions 2nd gen TypeScript (IA, paiements, transactions atomiques) |
| `firebase_messaging` | Push FCM |
| `firebase_analytics` | Funnels, événements clés |
| `firebase_crashlytics` | Crashs + erreurs non fatales |
| `firebase_remote_config` | Feature flags, pilotage paywall sans redéploiement |
| `firebase_app_check` | Attestation d'origine (Play Integrity Android, DeviceCheck iOS plus tard) |
| Secret Manager | Clé Claude API, secrets agrégateur |

## Conséquences

**Positives**

- **Cache offline Firestore natif** = solution gratuite au problème de connectivité instable du marché cible. Aucun cache custom à développer (cf. ADR-010).
- **Time-to-market** rapide : pas d'infra à monter.
- **App Check intégré** = protection des Cloud Functions IA contre l'abus, sans dev custom.
- **Webhook handler natif** côté Cloud Functions pour les agrégateurs Mobile Money.
- **Cohérence d'écosystème** : un seul provider, un seul facturé, un seul tableau de bord.

**Négatives**

- **Verrouillage Firebase** (lock-in modéré). Migration future = effort important.
- **Coût Firestore à surveiller** : chaque lecture est facturée. Cache atténue, n'élimine pas. Mitigation par `RemoteConfig` pilotant les profondeurs de lecture si nécessaire.
- **Performance Firestore < Postgres optimisé** sur les requêtes complexes. Mitigation : on n'a pas de requête complexe au MVP ; les classements sont calculés en triggers, pas en requête live.
- **Région `europe-west1`** par défaut — latence Cameroun à mesurer en P1 (AS-3 PRD).

**Impact sur les agents BMAD**

- Winston a un terrain stable, pas de décision d'infra à prendre pour chaque feature.
- Amelia consomme une API uniforme côté Dart (`firebase_*` packages).

## Note sur Supabase / Postgres

Une note dans la doc d'archi packages mobile mentionne un possible stack Next.js + NestJS + Supabase évoqué précédemment. **Cette piste est écartée pour le MVP mobile** — l'app mobile parle Firebase exclusivement. Si la console admin / landing utilise Supabase plus tard pour ses besoins propres, c'est leur décision (autre dépôt).

## Détail d'implémentation

Voir [`doc/tech/Valide Mobile Package Architecture.md`](../../../../doc/tech/Valide%20Mobile%20Package%20Architecture.md) — section 1 (Firebase complet, module par module).

## Décisions liées

- [ADR-010](ADR-010-no-custom-cache.md) — pas de cache custom, conséquence directe de la confiance dans Firestore.
- [ADR-008](ADR-008-idempotency-via-sessionid.md) — idempotence via transactions Firestore.
