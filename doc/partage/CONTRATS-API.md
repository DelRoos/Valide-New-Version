# Contrats des Cloud Functions

> **Lead de maintenance** : équipe backend.
> **Co-mainteneur** : équipe mobile (vérifie la cohérence avec ses datasources).
> **Statut global** : 🟡 **En cours** — catalogue posé d'après l'archi backend § 5.2, à figer au démarrage du backend (Phase 1).

---

> ## ⚠️ Mise à jour majeure — 2026-06-04 ([ADR-012](../../project_manage/planning-artifacts/architecture/adrs/ADR-012-firebase-ai-logic-replace-claude.md))
>
> Suite à l'adoption de **Firebase AI Logic (Gemini)** côté client à la place de Claude côté serveur, **3 contrats IA sont retirés du catalogue** et **1 contrat nouveau est ajouté** :
>
> | Contrat | Statut | Remplacement |
> |---|---|---|
> | `askTutor` (Phase 6 Mode 3) | **Supprimé** | Appel client `firebase_ai.generateContentStream(...)` |
> | `chatMessage` (Phase 6 Chat IA) | **Supprimé** | Appel client `firebase_ai.generateContentStream(...)` |
> | `correctMode1` (Phase 3 Mode 1 photo) | **Supprimé** | Appel client `firebase_ai.generateContent([Content.image(...), Content.text(...)])` |
> | `consumeCredits` (nouveau, ADR-012) | **Ajouté** | Cf. spec ci-dessous (à compléter à Phase 3) |
>
> Les sections détaillées de `askTutor`, `chatMessage`, `correctMode1` sont conservées plus bas comme **référence historique** mais ne sont plus implémentées. Toute contradiction se résout en faveur de l'ADR-012.

---

> ## ⚠️ Mise à jour Phase 4 — 2026-06-04 ([ADR-013](../../project_manage/planning-artifacts/architecture/adrs/ADR-013-freemopay-as-momo-aggregator.md))
>
> L'agrégateur Mobile Money retenu pour la V1 est **Freemopay v2** (`https://api-v2.freemopay.com`). Les 3 contrats Phase 4 ci-dessous (`createSubscription`, `purchaseCredits`, `paymentWebhook`) restent **valides dans leur intention**, mais leurs **détails techniques sont à aligner** avec l'API Freemopay v2 :
>
> | Contrat | À ajuster avant Phase 4 |
> |---|---|
> | `createSubscription` | `paymentUrl` (URL WebView agrégateur) → **probablement supprimé** : Freemopay valide via notification native MoMo/OM, pas de WebView. Renommer en `freemopayReference: string` (UUID Freemopay) + supprimer `paymentUrl` |
> | `purchaseCredits` | Idem |
> | `paymentWebhook` | `x-aggregator-signature` → **n'existe pas dans Freemopay v2**. Vérification = path-token URL secret (`?token=<secret>`) + **re-fetch obligatoire** `GET /api/v2/payment/:reference` avant tout crédit. Détails dans ADR-013 § Sécurité |
>
> Ces ajustements **nécessitent un accord backend** (cf. CLAUDE.md § Surface partagée) — à formaliser au démarrage de Phase 4 dans une PR dédiée. La doc API source : [`doc/tools/Freemopay API v2 — Documentation.md`](../tools/Freemopay%20API%20v2%20—%20Documentation.md).

---

## Pourquoi ce document existe

L'app mobile, la console admin et la landing appellent toutes les **mêmes Cloud Functions**. Si le contrat (nom, forme de l'entrée, forme de la sortie, codes d'erreur) diverge d'un côté à l'autre, **les clients cassent en silence**.

Ce fichier est la **source unique de vérité** pour chaque contrat. Côté backend, les types sont implémentés dans `functions/src/shared/types.ts`. Côté mobile, les models Dart correspondants vivent dans `lib/features/*/data/models/`. Côté admin, ils sont mappés en TypeScript depuis ce fichier.

> **Règle d'évolution** : on **ajoute** des champs optionnels, on **ne casse jamais** un contrat existant sans en faire une **V2** (`completeExerciseV2`). Cf. archi backend § 5.3.

---

## Comment lire un contrat

Chaque contrat est documenté avec :

1. **Type** : `onCall` (l'app appelle), `onRequest` (webhook externe), `onDocumentX` (trigger Firestore).
2. **Streaming** : oui / non (pour les contrats qui renvoient un flux).
3. **Authentification** : exigée ou non, claims requis.
4. **App Check** : exigé ou non.
5. **Entrée** : type TypeScript de `request.data`.
6. **Sortie** : type TypeScript de la réponse.
7. **Codes d'erreur possibles** : codes `HttpsError` que l'appelant peut recevoir.
8. **Implications mobile** : où le contrat est consommé, quel datasource, quel use case.
9. **Implications admin / landing** : si appelable depuis ces clients.

---

## Catalogue MVP

| Function | Type | Phase MVP | Statut |
|---|---|---|---|
| `completeExercise` | onCall | Phase 3 (Mode 2) | 🟡 |
| `submitQuiz` | onCall | Phase 3 | 🟡 |
| ~~`askTutor`~~ | ~~onCall streaming~~ | ~~Phase 6 (Mode 3)~~ | ❌ Supprimé ADR-012 |
| ~~`chatMessage`~~ | ~~onCall streaming~~ | ~~Phase 6~~ | ❌ Supprimé ADR-012 |
| ~~`correctMode1`~~ | ~~onCall~~ | ~~Phase 3~~ | ❌ Supprimé ADR-012 |
| `consumeCredits` (nouveau, ADR-012) | onCall | Phase 3 (Mode 1) | 🟡 — à figer |
| `createSubscription` | onCall | Phase 4 | 🟡 |
| `purchaseCredits` | onCall | Phase 4 | 🟡 |
| `paymentWebhook` | onRequest | Phase 4 | 🟡 |
| `checkPremiumAccess` | onCall | Phase 4 | 🟡 |
| `requestAccountDeletion` | onCall | Phase 1 | 🟡 |
| `createSharingLink` | onCall | Phase 6 | 🟡 |
| `submitExam` | onCall | Phase 6 | 🟡 |

---

## Contrats — Phase 3 (cœur pratique)

### `completeExercise` 🟡

**Type** : `onCall`
**Streaming** : non
**Auth requise** : oui (`request.auth.uid`)
**App Check** : oui (`enforceAppCheck: true`)

**Entrée** :

```typescript
interface CompleteExerciseRequest {
  exerciseId: string;
  sessionId: string;                     // UUID v4 généré côté mobile, MÊME pour tous les retries
  stepStatuses: Record<string, "solved" | "unsolved">;  // par index d'étape
}
```

**Sortie** :

```typescript
interface CompleteExerciseResponse {
  exerciseId: string;
  score: number;                         // 0-100
  impacts: { notionId: string; delta: number }[];
  pointsAwarded: number;
}
```

**Codes d'erreur** :

| Code `HttpsError` | Cas |
|---|---|
| `unauthenticated` | Pas de `request.auth` |
| `permission-denied` | Accès interdit (ex. compte non premium tentant Mode 2 sans gate locale qui aurait dû bloquer) |
| `invalid-argument` | Payload mal formé (validation `zod`) |
| `not-found` | `exerciseId` inexistant |
| `internal` | Erreur serveur inattendue |

**Implications mobile** :
- Datasource : `lib/features/exercises/data/datasources/exercise_remote_datasource.dart`
- Use case : `CompleteExercise`
- Le retry est automatique côté Dio (config dans `core/network/api_client.dart`). Le `sessionId` ne change pas entre retries.

**Implications admin** :
- L'admin ne déclenche pas elle-même `completeExercise`. Elle **lit** le résultat dans `users/{uid}/completions/*`.

---

### `submitQuiz` 🟡

**Type** : `onCall`
**Streaming** : non
**Auth requise** : oui
**App Check** : oui

**Entrée** :

```typescript
interface SubmitQuizRequest {
  quizId: string;
  sessionId: string;
  answers: Record<string, QuizAnswer>;
}

type QuizAnswer =
  | { type: "qcm"; selected: string[] }
  | { type: "trueFalse"; value: boolean }
  | { type: "fillBlank"; text: string }
  | { type: "matching"; pairs: { left: string; right: string }[] };
```

**Sortie** : même forme que `CompleteExerciseResponse`.

**Codes d'erreur** : idem `completeExercise`.

---

### `consumeCredits` 🟡 (nouveau ADR-012)

**Type** : `onCall`
**Streaming** : non
**Auth requise** : oui (`request.auth.uid`)
**App Check** : oui

**Rôle** : appelée par le client **AVANT** un appel `firebase_ai` qui coûte des crédits (Mode 1 photo, génération coûteuse). Vérifie le solde, débite atomiquement, applique l'idempotence par `sessionId`. Sans succès retourné par cette fonction, le client ne doit PAS lancer l'appel Gemini.

**Entrée** :

```typescript
interface ConsumeCreditsRequest {
  action: "mode1_correction" | "mode3_tutor" | "chat_message" | "exam_correction";
  sessionId: string;                       // idempotence (même session = pas de double débit)
  cost: number;                            // coût en crédits, vérifié serveur-side (le client ne décide pas)
  metadata?: Record<string, string>;       // optionnel : payload léger pour traçabilité (exerciseId, etc.)
}
```

**Sortie** :

```typescript
interface ConsumeCreditsResponse {
  allowed: boolean;                        // true = client peut appeler firebase_ai
  remaining: number;                       // solde crédits après débit
  reason?: "insufficient_credits" | "quota_exceeded" | "feature_premium_only" | "exam_mode_locked";
  paywallCta?: { plan: "premium_monthly" | "credits_pack_25"; price: string };  // si !allowed et raison commerciale
}
```

**Codes d'erreur** : `failed-precondition` (idempotence détectée, retourne l'état précédent), `unauthenticated`, `unavailable`.

**Implications mobile** : appel synchrone bloquant **avant** chaque `firebase_ai.generateContent(...)`. Si `allowed: false`, afficher le paywall ou l'erreur ; ne **jamais** appeler `firebase_ai` sans `allowed: true`.

**Implications backend** : transaction Firestore atomique sur `users/{uid}/credits` + écriture trace dans `users/{uid}/iaUsage/{sessionId}` (idempotence). Pas d'appel IA depuis cette function — elle ne fait QUE débiter.

> Spec posée par ADR-012 mais à figer en Story P3 (Mode 1) qui sera la première à la consommer.

---

### ~~`correctMode1`~~ 🟡 ❌ Supprimé ADR-012 (référence historique)

> Cette section est conservée pour mémoire mais le contrat n'est plus implémenté. Mode 1 utilise désormais `consumeCredits` (ci-dessus) + appel client `firebase_ai.generateContent([Content.image(storageUri ou bytes), Content.text(énoncé + system prompt)])`. Voir [ADR-012](../../project_manage/planning-artifacts/architecture/adrs/ADR-012-firebase-ai-logic-replace-claude.md).

**Type** : `onCall`
**Streaming** : non (la correction IA est synchrone côté Function — Claude répond en quelques secondes)
**Auth requise** : oui
**App Check** : oui

**Entrée** :

```typescript
interface CorrectMode1Request {
  exerciseId: string;
  sessionId: string;
  submission: {
    type: "text";
    text: string;
  } | {
    type: "photo";
    photoStorageUri: string;             // chemin Firebase Storage où la photo compressée a été uploadée
  };
}
```

**Sortie** :

```typescript
interface CorrectMode1Response {
  correction: {
    steps: Mode1StepResult[];
    summary: string;                     // Markdown, peut contenir LaTeX/Mermaid
  };
  score: number;                         // 0-100
  impacts: { notionId: string; delta: number }[];
  pointsAwarded: number;
  creditsSpent: number;
}

interface Mode1StepResult {
  index: number;
  status: "correct" | "incorrect" | "incomplete" | "rephrasing_needed";
  feedback: string;                      // Markdown
  courseRefs: { lessonId: string; excerpt: string }[];  // renvois cliquables
}
```

**Codes d'erreur** :

| Code | Cas |
|---|---|
| `failed-precondition` | Crédits insuffisants |
| `invalid-argument` | Texte vide, photo invalide |
| `internal` | Erreur IA |
| autres | idem `completeExercise` |

**Note sur la photo** : le mobile **compresse côté client** (cf. archi mobile § 5) puis upload vers Firebase Storage avant d'appeler la Function. L'URI Storage est passée dans le payload.

---

## Contrats — Phase 4 (paiement & premium)

### `createSubscription` 🟡

**Type** : `onCall`
**Auth requise** : oui
**App Check** : oui

**Entrée** :

```typescript
interface CreateSubscriptionRequest {
  plan: "monthly" | "yearly";
}
```

**Sortie** :

```typescript
interface CreateSubscriptionResponse {
  paymentUrl: string;                    // URL hébergée par l'agrégateur, à ouvrir en WebView
  intentId: string;                      // ID interne pour suivre l'intention
  expiresAt: string;                     // ISO 8601, durée de validité de l'URL
}
```

**Codes d'erreur** :

| Code | Cas |
|---|---|
| `already-exists` | L'utilisateur a déjà un abonnement actif |
| `failed-precondition` | Profil incomplet |
| `unavailable` | Agrégateur indisponible (réessayer plus tard) |
| `internal` | Erreur serveur |

---

### `purchaseCredits` 🟡

**Type** : `onCall`
**Auth requise** : oui
**App Check** : oui

**Entrée** :

```typescript
interface PurchaseCreditsRequest {
  packId: "pack_10" | "pack_25" | "pack_60";
}
```

**Sortie** : même structure que `CreateSubscriptionResponse` (URL agrégateur).

---

### `paymentWebhook` 🟡

**Type** : `onRequest` (HTTP POST)
**Auth requise** : non (l'agrégateur n'a pas de token Firebase)
**App Check** : non applicable
**Vérification** : **signature de l'agrégateur** (header `x-aggregator-signature`) obligatoire avant toute action

**Entrée** : payload de l'agrégateur (Tranzak / Campay / MyCoolPay — format dépend du partenaire, à figer en Phase 4).

**Sortie** : `200 OK` ou `401 Unauthorized` (signature invalide) ou `400 Bad Request` (payload invalide).

**Effets** :
1. Vérifier la signature
2. Vérifier l'idempotence par `event_id`
3. Si paiement confirmé :
   - Soit basculer `subscriptions/{uid}.status = "active"` + écrire `payment_intents/{intentId}.status = "succeeded"`
   - Soit créditer `credits/{uid}.balance += amount`
4. Écrire `webhook_events/{eventId}` (trace)

**Implications mobile et admin** : **aucun appel direct** vers cette Function. Le mobile **écoute** `subscriptions/{uid}` et `credits/{uid}` en stream pour réagir à la confirmation.

---

### `checkPremiumAccess` 🟡

**Type** : `onCall`
**Auth requise** : oui
**App Check** : oui

**Entrée** :

```typescript
interface CheckPremiumAccessRequest {
  feature: "mode2" | "exam" | "fiches" | "chat_premium";
}
```

**Sortie** :

```typescript
interface CheckPremiumAccessResponse {
  granted: boolean;
  reason: "active" | "gracePeriod" | "not_premium" | "expired";
}
```

> Rappel : cette Function est une **optimisation UX**. Le vrai verrou est dans les règles Firestore. Le mobile peut faire un check local sur `subscriptions/{uid}` plutôt que d'appeler cette Function — la Function est utile depuis l'admin pour vérifier sans charger l'abonnement complet.

---

## Contrats — Phase 6 (IA & partage)

### ~~`askTutor`~~ 🟡 ❌ Supprimé ADR-012 (référence historique)

> Cette section est conservée pour mémoire. Mode 3 utilise désormais `consumeCredits` + appel client `firebase_ai.generateContentStream(...)`. Voir [ADR-012](../../project_manage/planning-artifacts/architecture/adrs/ADR-012-firebase-ai-logic-replace-claude.md).

**Type** : `onCall` streaming
**Auth requise** : oui
**App Check** : oui

**Entrée** :

```typescript
interface AskTutorRequest {
  exerciseId: string;
  sessionId: string;                     // une session Mode 3 = 1 débit de crédits, pas 1 par message
  stepIndex: number;
  studentWork: {
    type: "text" | "photo";
    content: string;                     // texte ou URI Storage
  };
  conversationHistory?: { role: "user" | "assistant"; content: string }[];
}
```

**Sortie** : **flux** de chunks textuels (`AsyncIterable<string>` côté serveur, `Stream<String>` côté mobile via `cloud_functions`).

Le flux émet des deltas de texte au fur et à mesure que Claude génère. Le mobile les concatène et les affiche via `SmoothMarkdown` (streaming) — cf. archi mobile § 4.

**Crédits** : débité **une seule fois** par session (cf. ALGORITHMES.md § 8). Plusieurs messages dans une session ne re-débitent pas.

---

### ~~`chatMessage`~~ 🟡 ❌ Supprimé ADR-012 (référence historique)

> Cette section est conservée pour mémoire. Chat IA utilise désormais `consumeCredits` (ou vérification quota) + appel client `firebase_ai.generateContentStream(...)` avec historique de conversation injecté côté client. Voir [ADR-012](../../project_manage/planning-artifacts/architecture/adrs/ADR-012-firebase-ai-logic-replace-claude.md).

**Type** : `onCall` streaming
**Auth requise** : oui
**App Check** : oui

**Entrée** :

```typescript
interface ChatMessageRequest {
  conversationId: string;
  message: string;
  context: {
    type: "free" | "course" | "notion" | "exercise";
    refId: string | null;
  };
  pinnedRefs?: { type: string; id: string }[];
}
```

**Sortie** : flux texte, peut contenir des blocs Mermaid pour les diagrammes générés.

**Quota** :
- Gratuit : 10 messages / jour
- Premium : 200 messages / jour
- Vérifié **avant** l'appel à Claude (cf. archi backend § 11.4).

**Erreurs** :

| Code | Cas |
|---|---|
| `resource-exhausted` | Quota journalier dépassé |
| autres | idem |

**Posture pédagogique** : l'IA aide à comprendre, **ne donne pas la solution directement** sur les exercices (cf. PRD Phase 6). Si l'utilisateur demande la réponse, elle redirige vers une démarche. Cette posture est encodée dans le prompt système côté serveur.

---

### `submitExam` 🟡

**Type** : `onCall`
**Auth requise** : oui
**App Check** : oui

**Entrée** :

```typescript
interface SubmitExamRequest {
  examSubjectId: string;
  sessionId: string;
  parts: ExamPartSubmission[];
  durationSeconds: number;               // temps effectif passé
  submittedReason: "manual" | "auto_timeout";
}

interface ExamPartSubmission {
  partIndex: number;
  answers: unknown;                      // format dépend du type de question
}
```

**Sortie** :

```typescript
interface SubmitExamResponse {
  score: number;                         // sur 20
  mention: string;
  parts: ExamPartResult[];
  pointsAwarded: number;
  impacts: { notionId: string; delta: number }[];
}

interface ExamPartResult {
  partIndex: number;
  obtainedPoints: number;
  maxPoints: number;
  feedback: string;                      // Markdown
}
```

---

### `createSharingLink` 🟡

**Type** : `onCall`
**Auth requise** : oui

**Entrée** :

```typescript
interface CreateSharingLinkRequest {
  targetType: "exercise" | "exam" | "lesson" | "result";
  targetId: string;
}
```

**Sortie** :

```typescript
interface CreateSharingLinkResponse {
  linkId: string;
  publicUrl: string;                     // valide?id=linkId
}
```

---

## Contrats — Phase 1 (compte)

### `requestAccountDeletion` 🟡

**Type** : `onCall`
**Auth requise** : oui

**Entrée** : `{}`

**Sortie** :

```typescript
interface RequestAccountDeletionResponse {
  deletionScheduledFor: string;          // ISO 8601 — now + 7 jours
}
```

**Effet** : `users/{uid}.deletionRequestedAt = now`. Un cron quotidien supprime effectivement après 7 jours sauf si l'élève s'est reconnecté.

---

### `cancelAccountDeletion` 🟡 (Story 1.10, accord backend requis)

**Type** : `onCall`
**Auth requise** : oui

**Entrée** : `{}`

**Sortie** :

```typescript
interface CancelAccountDeletionResponse {
  cancelled: boolean;  // true si deletionRequestedAt etait pose, false si deja annule ou jamais demande
}
```

**Effet** : `users/{uid}.deletionRequestedAt = FieldValue.delete()`. Idempotent (pas d'erreur si deja null). Annule la programmation du cron de purge.

**Implications mobile** (Story 1.10 FR-7) :

- Appelee depuis `ProfileSettingsPage` modale "Annuler la suppression" (banner DashboardPage)
- Appelee automatiquement au boot via `autoAccountDeletionCancellerProvider` si l'utilisateur revient apres avoir kill l'app + `deletionRequestedAt` < sessionStart (heuristique anti-boucle)
- Si la function n'est pas encore deployee cote backend, mobile gere gracefully : log warn + toast "Fonctionnalite bientot disponible" + app reste utilisable. La banner deletion reste affichee, l'utilisateur re-essaie plus tard.

**Codes d'erreur** :

- `unauthenticated` — pas d'utilisateur loggue
- `not-found` — non standard cote backend, mappee cote mobile si la function n'est pas encore deployee
- `unavailable` — Firestore / network down

---

## Codes d'erreur communs

Tableau de correspondance `HttpsError` → `Failure` mobile (cf. archi mobile § 10) :

| `HttpsError.code` | `Failure` mobile | Message utilisateur |
|---|---|---|
| `unauthenticated` | `AuthFailure` | « Connexion requise » |
| `permission-denied` | `AccessDeniedFailure` | « Abonnement premium requis » (selon contexte) |
| `not-found` | `NotFoundFailure` | « Ressource introuvable » |
| `invalid-argument` | `ServerFailure` | « Données invalides » |
| `failed-precondition` | `ServerFailure` (avec message custom selon le cas) | « Crédits insuffisants » / « Profil incomplet » |
| `resource-exhausted` | `ServerFailure` (message custom) | « Quota journalier atteint » |
| `unavailable` | `NetworkFailure` | « Service temporairement indisponible » |
| `internal` | `UnknownFailure` | « Une erreur inattendue est survenue » |
| (timeout / hors réseau) | `NetworkFailure` | « Pas de connexion internet » |

---

## Implications pour l'admin

L'admin **n'appelle pas** la plupart des Functions listées ici — elles sont conçues pour le mobile.

Les Functions appelables depuis l'admin sont **uniquement** les Functions admin dédiées (cf. ALGORITHMES.md § 11), qui ne sont **pas** dans ce catalogue (à venir, statut 🔴).

L'admin **lit** plutôt les **résultats** des Functions dans Firestore :
- `users/{uid}/completions/*` pour voir les scores
- `subscriptions/{uid}` pour le statut premium
- `credits/{uid}` et `credits/{uid}/transactions/*` pour les crédits
- `payment_intents/*` pour suivre les paiements

---

## Implications pour la landing

La landing peut appeler **uniquement** des Functions publiques (pas de `request.auth`) qui sont **à définir** quand l'équipe landing existe. Aucune Function publique n'est encore prévue dans le catalogue MVP. Statut : 🔴 À compléter.

Cas d'usage prévisibles :
- Statistiques publiques (X élèves, X exercices) — peut se faire en Firestore lecture publique sur un document agrégé maintenu par cron
- Inscription depuis un lien profond — l'app mobile prend le relais après installation

---

## Synchronisation des types

Les types TypeScript de ce fichier doivent être synchronisés avec :

- `functions/src/shared/types.ts` (dépôt backend) — source de vérité côté serveur
- `lib/features/*/data/models/*_model.dart` (dépôt mobile) — duplication Dart
- `apps/admin/src/types/api.ts` (dépôt admin, à venir) — duplication TS côté admin

> Stratégie de synchronisation (cf. archi backend § 8.2) : maintenance manuelle (le catalogue est petit, ~12 contrats au MVP) + **tests de contrat** côté backend et mobile qui valident la forme JSON contre des fixtures partagées. Un changement de type ici impose de vérifier les trois autres emplacements **dans la même PR ou une PR liée**.

---

## Historique

| Date | Auteur | Modification |
|---|---|---|
| 2026-06-03 | Setup initial | Création du catalogue à partir de l'archi backend § 5.2 |
| 2026-06-04 | ADR-012 | Retrait des 3 contrats IA (`askTutor`, `chatMessage`, `correctMode1`) — remplacés par appels client `firebase_ai`. Ajout `consumeCredits` (à figer Phase 3) |
| 2026-06-04 | ADR-013 | Bannière Phase 4 : agrégateur Freemopay v2 retenu, ajustements à prévoir sur `createSubscription`/`purchaseCredits` (suppression `paymentUrl` WebView) et `paymentWebhook` (path-token + re-fetch GET au lieu de signature HMAC) |
