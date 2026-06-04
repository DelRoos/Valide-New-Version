# Schéma de base de données — Firestore

> **Lead de maintenance** : équipe backend. **Co-mainteneur** : équipe mobile.
> **Statut global** : 🟡 **En cours** — squelette posé d'après les docs d'architecture, à figer pendant la Phase 1 du MVP.

---

## Comment lire ce document

Pour chaque collection :

1. **Chemin** : la position dans l'arbre Firestore.
2. **Identifiant** : la nature de l'ID du document (uid Firebase, slug, auto-généré…).
3. **Schéma TypeScript** : la forme du document, avec annotations `// `.
4. **Indexes** : les index composés à créer dans Firebase (au-delà des index automatiques sur champ unique).
5. **Règles d'accès** : qui peut lire / écrire, en résumé. Détail dans `firestore.rules` (dépôt backend).
6. **Mutable / Immutable côté mobile** : décide si le mobile fait un `.snapshots()` (stream) ou un `.get()` (lecture standard). Cf. archi mobile § 12.

---

## Vue d'ensemble des collections

| Collection | Rôle | Statut | Mutable côté mobile |
|---|---|---|---|
| `users` | Profil élève (sous-système, filière, niveau, série, école, langue) | 🟡 | Mutable (profil peut être modifié) |
| `subscriptions` | Statut d'abonnement par utilisateur | 🟡 | **Stream** (le statut change après webhook paiement) |
| `credits` | Solde de crédits par utilisateur | 🟡 | **Stream** |
| `subjects` | Catalogue des matières (référentiel) | 🟡 | Statique |
| `chapters` | Chapitres par matière | 🟡 | Statique |
| `lessons` | Leçons par chapitre | 🟡 | Statique |
| `notions` | Notions par leçon (unité atomique d'évaluation) | 🟡 | Statique |
| `exercises` | Exercices rattachés à une leçon | 🟡 | Statique |
| `quizzes` | Quiz générés par IA (peuvent être cachés pour réutilisation) | 🔴 | Statique / Mutable selon stratégie |
| `exam_subjects` | Sujets d'examen complets (Mode examen) | 🟡 | Statique |
| `users/{uid}/completions` | Marqueurs d'idempotence des exercices/quiz/sujets complétés | 🟡 | Privé à l'utilisateur |
| `users/{uid}/health/{notionId}` | Niveau de santé scolaire par notion | 🟡 | **Stream** |
| `users/{uid}/stats` | Points cumulés, streak, autres stats | 🟡 | **Stream** |
| `users/{uid}/sessions` | Sessions actives (Mode 1/2/3, examen) | 🔴 | Mutable |
| `users/{uid}/recommendations` | Recommandations actives sur le dashboard | 🟡 | **Stream** |
| `users/{uid}/conversations` | Conversations chat IA | 🟡 | Mutable |
| `users/{uid}/notifications` | Notifications in-app | 🟡 | **Stream** |
| `users/{uid}/sharing_links` | Liens de partage générés | 🟡 | Mutable |
| `rankings/{board}/entries/{uid}` | Classements (5 boards) | 🟡 | **Stream** (board courant uniquement) |
| `schools` | Catalogue des écoles | 🟡 | Statique |
| `payment_intents` | Intentions de paiement (créées par Cloud Function) | 🟡 | Privé (suivi côté serveur) |
| `webhook_events` | Trace des webhooks d'agrégateur (idempotence) | 🟡 | Inaccessible au mobile |

---

## Détail des collections

### `users/{uid}` 🟡

Profil de l'élève. L'`uid` est l'identifiant Firebase Auth.

```typescript
interface UserDoc {
  uid: string;                          // = doc ID, redondant mais pratique pour les requêtes inter-collection
  subSystem: "francophone" | "anglophone";  // fixé à l'inscription, jamais modifiable
  language: "fr" | "en";                // dérivé du sous-système, jamais modifiable
  filiere: "generale" | "technique";    // M1 — profil scolaire
  niveau: string;                       // ex. "Tle", "Form 5", "Lower Sixth" — cf. DONNEES-REFERENCE.md
  serie: string;                        // ex. "D", "Sciences", "Arts" — cf. DONNEES-REFERENCE.md
  derivedSubjects: string[];            // matières déduites du profil (refs vers subjects/{id})
  optedOutSubjects: string[];           // matières retirées par l'élève (anglophones Form 3+, Lower/Upper Sixth) — un sous-ensemble de derivedSubjects
  examTargets: string[];                // examens visés (refs vers une collection exams ou ids constants)
  schoolId: string | null;              // ref vers schools/{id} si lié
  displayName: string;
  photoUrl: string | null;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  // Délai de grâce de suppression (Phase 1)
  deletionRequestedAt: Timestamp | null;
}
```

**Indexes** :
- `subSystem` + `niveau` + `serie` (utile pour ranking par classe et stats par profil)
- `schoolId` + `niveau` + `serie` (utile pour ranking par école)

**Règles d'accès** :
- Lecture : uniquement par `uid` (l'élève lui-même), ou par un compte admin
- Écriture : uniquement par `uid`, sauf `derivedSubjects` qui est écrit par une Cloud Function lors de la création du profil
- `deletionRequestedAt` géré par Cloud Function (`requestAccountDeletion`)

### `subscriptions/{uid}` 🟡

État d'abonnement. **Mutable, le mobile l'écoute en stream.**

```typescript
interface SubscriptionDoc {
  uid: string;
  status: "none" | "active" | "gracePeriod" | "expired";
  plan: "monthly" | "yearly" | null;
  startedAt: Timestamp | null;
  expiresAt: Timestamp | null;          // fin de la période payée
  gracePeriodEndsAt: Timestamp | null;  // si paiement de renouvellement échoue
  cancelledAt: Timestamp | null;        // si l'élève a annulé (mais reste actif jusqu'à expiresAt)
  lastWebhookEventId: string | null;    // dernier event traité (idempotence webhook)
  updatedAt: Timestamp;
}
```

**Règles d'accès** :
- Lecture : uniquement par `uid` (l'élève lui-même)
- Écriture : **uniquement par Cloud Function** (jamais par le client). Le client ne décide jamais de son propre statut premium.

### `credits/{uid}` 🟡

Solde de crédits. **Mutable, stream.**

```typescript
interface CreditsDoc {
  uid: string;
  balance: number;                       // crédits actuellement disponibles
  totalPurchased: number;                // historique cumulé (jamais décrémenté)
  totalSpent: number;                    // historique cumulé
  updatedAt: Timestamp;
}
```

Sous-collection `credits/{uid}/transactions/{txnId}` 🟡 :

```typescript
interface CreditTransactionDoc {
  txnId: string;
  type: "purchase" | "debit" | "bonus" | "refund";
  delta: number;                         // négatif si debit, positif sinon
  reason: string;                        // ex. "mode1_correction:exerciseId=X"
  sessionId: string | null;              // pour les debits, clé d'idempotence
  paymentIntentId: string | null;        // pour les purchases, ref vers payment_intents
  createdAt: Timestamp;
}
```

**Règles d'accès** : Lecture par `uid`, écriture **uniquement par Cloud Function**.

### `subjects/{subjectId}` 🟡 (référentiel)

Catalogue des matières.

```typescript
interface SubjectDoc {
  subjectId: string;
  name: { fr: string; en: string };       // bilingue
  shortCode: string;                      // ex. "MATH", "PCT", "SVT"
  subSystem: "francophone" | "anglophone";
  applicableToFiliere: ("generale" | "technique")[];
  applicableToNiveau: string[];           // ex. ["Seconde", "Premiere", "Tle"]
  applicableToSerie: string[];            // ex. ["A", "C", "D"]
  // Indexes utiles pour le filtrage côté mobile
}
```

> **Indispensable** : ce catalogue alimente la **dérivation automatique** des matières à partir du profil élève (cf. ALGORITHMES.md § « Dérivation profil → matières »).

### `chapters/{chapterId}` 🟡

```typescript
interface ChapterDoc {
  chapterId: string;
  subjectId: string;
  order: number;
  title: { fr: string; en: string };
  description: { fr: string; en: string } | null;
}
```

Index : `subjectId` + `order`.

### `lessons/{lessonId}` 🟡

```typescript
interface LessonDoc {
  lessonId: string;
  chapterId: string;
  order: number;
  title: { fr: string; en: string };
  content: { fr: string; en: string };    // Markdown avec LaTeX, Mermaid, etc.
  // Rendu via PedagogicalContent (cf. archi mobile § 17.7)
}
```

Index : `chapterId` + `order`.

### `notions/{notionId}` 🟡

Plus petite unité d'évaluation.

```typescript
interface NotionDoc {
  notionId: string;
  lessonId: string;
  order: number;
  title: { fr: string; en: string };
  // Les questions de quiz sont rattachées à une notion (cf. archi mobile § 6.1)
}
```

Index : `lessonId` + `order`.

### `exercises/{exerciseId}` 🟡

Exercices rattachés à une leçon, utilisables en Mode 1/2/3.

```typescript
interface ExerciseDoc {
  exerciseId: string;
  lessonId: string;                      // l'exercice est rattaché à une leçon
  notionIds: string[];                   // notions évaluées (pour la santé scolaire)
  type: "qcm" | "shortAnswer" | "problem" | "openEnded";
  difficulty: "easy" | "medium" | "hard";
  prompt: { fr: string; en: string };
  steps: ExerciseStep[];                 // détaillé en Mode 2 (étapes ordonnées)
}

interface ExerciseStep {
  index: number;
  prompt: { fr: string; en: string };
  hints: ({ fr: string; en: string })[];  // jusqu'à 3 indices progressifs
  courseExcerpt: { fr: string; en: string };  // portion de cours associée
  expectedSolution: { fr: string; en: string };  // pour le corrigé final
}
```

Index : `lessonId`, `difficulty`, `type`.

### `users/{uid}/completions/{sessionId}` 🟡 (clé d'idempotence)

**Cœur de l'idempotence.** Chaque exercice / quiz / sujet d'examen complété crée un document avec son `sessionId` comme ID. Si la Cloud Function reçoit deux fois le même `sessionId`, elle ne recrédite pas.

```typescript
interface CompletionDoc {
  sessionId: string;                     // = doc ID
  uid: string;
  type: "exercise" | "quiz" | "exam";
  refId: string;                         // exerciseId / quizId / examSubjectId
  score: number;                         // sur 100
  impacts: NotionImpact[];               // delta de santé par notion
  pointsAwarded: number;
  completedAt: Timestamp;
}

interface NotionImpact {
  notionId: string;
  delta: number;                         // ex. +5 si correct, -3 si raté
}
```

**Règles d'accès** : Lecture par `uid`. Écriture **uniquement par Cloud Function** dans une **transaction** (cf. ALGORITHMES.md § « Idempotence »).

### `users/{uid}/health/{notionId}` 🟡

Niveau de santé scolaire par notion. **Mutable, stream pour l'affichage temps réel sur le dashboard de l'élève.**

```typescript
interface NotionHealthDoc {
  notionId: string;                      // = doc ID
  uid: string;
  level: number;                         // ex. 0-100
  label: "solide" | "à renforcer" | "priorité";  // dérivé du level, mais stocké pour requête rapide
  trend: "up" | "stable" | "down";
  lastUpdatedAt: Timestamp;
}
```

**Règles d'accès** : Lecture par `uid`. Écriture **uniquement par Cloud Function** (dans la transaction d'alimentation).

### `users/{uid}/stats` 🟡 (document unique, pas une sous-collection)

```typescript
interface UserStatsDoc {
  uid: string;
  totalPoints: number;
  weeklyPoints: number;                  // reset chaque lundi 00:00
  streakDays: number;                    // jours consécutifs d'activité
  lastActivityAt: Timestamp;
  lastWeeklyResetAt: Timestamp;
  // Mini-carte de rang sur le dashboard est dérivée des rankings
}
```

### `users/{uid}/sessions/{sessionId}` 🔴

État local d'une session en cours (Mode 2, mode examen) — permet de reprendre après fermeture de l'app.

```typescript
interface ActiveSessionDoc {
  sessionId: string;
  uid: string;
  type: "mode2" | "exam" | "mode3";
  refId: string;
  startedAt: Timestamp;
  // État spécifique au type
  stepStatuses?: Record<number, "solved" | "unsolved">;  // mode2
  hintsRevealed?: Record<number, number>;                // mode2 (étape → nb d'indices vus)
  currentPart?: number;                                  // exam
  partAnswers?: Record<number, unknown>;                 // exam
  lastSavedAt: Timestamp;
}
```

> **À figer en Phase 3** (Mode 2) et Phase 6 (Mode examen).

### `users/{uid}/recommendations/{recoId}` 🟡

Recommandations actives sur le dashboard (max 3 affichées en même temps).

```typescript
interface RecommendationDoc {
  recoId: string;
  uid: string;
  type: "weak_notion" | "consolidation_strong_notion" | "next_step";
  targetType: "exercise" | "lesson" | "notion" | "quiz";
  targetId: string;
  rationale: { fr: string; en: string };   // « tu as raté 3 questions sur cette notion »
  createdAt: Timestamp;
  expiresAt: Timestamp | null;
  status: "active" | "done" | "ignored";   // l'élève peut marquer fait ou ignorer
}
```

> Cf. ALGORITHMES.md § « Moteur de recommandations » — règle d'équilibre 1/5 sur notion déjà solide.

### `users/{uid}/conversations/{conversationId}` 🟡

```typescript
interface ConversationDoc {
  conversationId: string;
  uid: string;
  context: "free" | "course" | "notion" | "exercise";
  contextRef: string | null;             // ex. exerciseId si context=exercise
  pinnedRefs: { type: string; id: string }[];  // épinglés pour garder le contexte
  createdAt: Timestamp;
  lastMessageAt: Timestamp;
}
```

Sous-collection `messages/{msgId}` :

```typescript
interface MessageDoc {
  msgId: string;
  role: "user" | "assistant";
  content: string;                       // Markdown (peut contenir Mermaid pour diagrammes)
  createdAt: Timestamp;
}
```

### `users/{uid}/notifications/{notificationId}` 🟡

```typescript
interface NotificationDoc {
  notificationId: string;
  uid: string;
  type: "quiz_recap" | "exam_recap" | "inactivity_reminder" | "subject_unfinished"
       | "weekly_ranking" | "payment_confirmation" | "low_credits"
       | "new_recommendation" | "shared_link_opened";
  title: { fr: string; en: string };
  body: { fr: string; en: string };
  actionUrl: string;                     // deep link interne
  isRead: boolean;
  createdAt: Timestamp;
  // Le push FCM est envoyé en parallèle (pas stocké ici)
}
```

### `users/{uid}/sharing_links/{linkId}` 🟡

```typescript
interface SharingLinkDoc {
  linkId: string;
  uid: string;
  targetType: "exercise" | "exam" | "lesson" | "result";
  targetId: string;
  publicUrl: string;                     // valide?id=linkId
  openCount: number;
  isActive: boolean;
  createdAt: Timestamp;
}
```

### `rankings/{board}/entries/{uid}` 🟡

5 boards possibles :

- `general` — classement permanent global
- `weekly` — reset chaque lundi 00:00
- `subject_{subjectId}` — par matière
- `class_{niveau}_{serie}_{schoolId}` — par classe (si école renseignée)
- `school_{schoolId}` — par école

```typescript
interface RankingEntryDoc {
  uid: string;
  displayName: string;
  photoUrl: string | null;
  score: number;                         // points dans le contexte du board
  rank: number;                          // calculé périodiquement
  previousRank: number | null;           // pour afficher l'évolution
  updatedAt: Timestamp;
}
```

> Recalcul déclenché par un Firestore trigger sur `users/{uid}/stats` (cf. archi backend § 4.2). Attention au piège des triggers en boucle (cf. archi backend § 9.4) : le trigger écrit dans `rankings/`, pas dans `stats/`.

### `schools/{schoolId}` 🟡

Catalogue d'écoles.

```typescript
interface SchoolDoc {
  schoolId: string;
  name: string;
  city: string;
  region: string;
  subSystem: "francophone" | "anglophone" | "both";
  isValidated: boolean;                  // ajoutée par admin (les élèves peuvent demander un ajout)
  createdAt: Timestamp;
}
```

Sous-collection `schools/{schoolId}/requests` 🔴 : demandes d'ajout par les élèves en attente de validation admin.

### `payment_intents/{intentId}` 🟡

Tracé d'une intention de paiement créée auprès d'un agrégateur.

```typescript
interface PaymentIntentDoc {
  intentId: string;
  uid: string;
  type: "subscription" | "credits";
  plan: "monthly" | "yearly" | null;     // si type=subscription
  packId: string | null;                 // si type=credits
  amountXaf: number;                     // en F CFA
  aggregator: "tranzak" | "campay" | "mycoolpay";
  aggregatorIntentId: string;            // ID chez le partenaire
  status: "pending" | "succeeded" | "failed" | "cancelled";
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

### `webhook_events/{eventId}` 🟡 (interne backend)

Trace de chaque webhook reçu d'un agrégateur, pour idempotence du webhook. **Le mobile ne lit jamais cette collection.**

```typescript
interface WebhookEventDoc {
  eventId: string;                       // = aggregator's event_id (clé d'idempotence)
  aggregator: string;
  intentId: string;
  payload: Record<string, unknown>;
  signature: string;
  receivedAt: Timestamp;
  processedAt: Timestamp | null;
  result: "applied" | "duplicate" | "rejected_signature";
}
```

---

## Indexes composés à créer

À documenter ici dès qu'un index composé est ajouté à `firestore.indexes.json` (côté backend). Liste à compléter :

🔴 **À compléter pendant la mise en place** :

- `users` : `(subSystem, niveau, serie)` — pour les stats par profil
- `users` : `(schoolId, niveau, serie)` — pour les rankings classe
- `chapters` : `(subjectId, order)` — affichage trié
- `lessons` : `(chapterId, order)`
- `notions` : `(lessonId, order)`
- `exercises` : `(lessonId, difficulty)` — pour filtrage
- `rankings/{board}/entries` : `(score desc)` — top X

---

## Règles de sécurité — résumé

Le détail vit dans [`firestore.rules`](../../firestore.rules) à la racine de ce dépôt (les configs Firebase racine sont partagées avec le backend, cf. CLAUDE.md). Tests unitaires des règles dans [`test/rules/`](../../test/rules/). En résumé :

| Collection | Lecture | Écriture |
|---|---|---|
| `users/{uid}` | `uid` | `uid` (sauf champs dérivés écrits par CF) |
| `subscriptions/{uid}` | `uid` | **Cloud Function uniquement** |
| `credits/{uid}` | `uid` | **Cloud Function uniquement** |
| `credits/{uid}/transactions/*` | `uid` | **Cloud Function uniquement** |
| `subjects`, `chapters`, `lessons`, `notions`, `exercises`, `quizzes`, `exam_subjects` | Authentifié, profil complet (filtré par règle) | Admin (via backoffice) |
| `users/{uid}/completions/*` | `uid` | **Cloud Function uniquement** (dans transaction) |
| `users/{uid}/health/*` | `uid` | **Cloud Function uniquement** |
| `users/{uid}/stats` | `uid` | **Cloud Function uniquement** |
| `users/{uid}/recommendations/*` | `uid` | **Cloud Function uniquement** (sauf marquer fait/ignoré : `uid`) |
| `users/{uid}/conversations/*` | `uid` | **Cloud Function** (création) + `uid` (lecture) |
| `users/{uid}/notifications/*` | `uid` | **Cloud Function** (création) + `uid` (marquer lu) |
| `users/{uid}/sharing_links/*` | `uid` | `uid` (création) + Cloud Function (incrément openCount) |
| `rankings/*` | Authentifié | **Cloud Function uniquement** (via trigger) |
| `schools` | Authentifié | Admin uniquement (sauf demande d'ajout) |
| `payment_intents/*` | `uid` (propriétaire) | **Cloud Function uniquement** |
| `webhook_events/*` | **Personne** côté client | **Cloud Function uniquement** |

> **Vrai verrou d'accès au Mode 2 et autres features premium** : dans les règles Firestore, la création d'une session Mode 2 (`users/{uid}/sessions/{sessionId}`) est conditionnée à `get(subscriptions/{uid}).data.status == "active"`. Cf. archi backend § 12.4.

---

## Historique

| Date | Auteur | Modification |
|---|---|---|
| 2026-06-03 | Setup initial | Création du squelette à partir des docs d'architecture mobile et backend |
| 2026-06-04 | DelRoos / Claude | Story 0.9 — lien vers `firestore.rules` racine + `test/rules/` (règles initiales P0 : default deny + users self-only + `_smoketest/*` temporaire) |
