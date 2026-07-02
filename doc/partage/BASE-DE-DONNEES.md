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
| `filieres` | Catalogue filières (générale, technique) — multilingue, activable runtime via `isActive` | 🟢 | **Stream** (admin peut désactiver à chaud) |
| `niveaux` | Catalogue niveaux par (subSystem, filière) (6ᵉ, Seconde, Form 1, Lower Sixth, …) | 🟢 | **Stream** |
| `series` | Catalogue séries par (subSystem, niveau, filière) (A, C, D, E, F1-F5, G1-G3, S1-S8, A1-A5, …) + flag `canOptOut` | 🟢 | **Stream** |
| `subjects` | Catalogue matières bilingue (référentiel) + flag `isActive` | 🟢 | **Stream** (admin peut désactiver à chaud) |
| `exam_targets` | Catalogue examens visés (BEPC, Probatoire/BAC × séries, O Level, A Level × séries) | 🟢 | **Stream** |
| `derivation_rules` | Règles dérivation (subSystem, filiere, niveau, serie) → (subjectIds, examTargetIds, canOptOut) | 🟢 | **Stream** |
| `chapters` | Chapitres par matière | 🟢 | Statique |
| `lessons` | Leçons par chapitre | 🟢 | Statique |
| `notions` | Notions par leçon (unité atomique d'évaluation) | 🟢 | Statique |
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
| `schools` | Catalogue des écoles (~198 MINESEC+GCE V1 — Story 1.5.a) | 🟢 | Statique |
| `school_requests` | Demandes d'ajout d'école par les élèves (Story 1.5.c — modération admin Console) | 🟢 | Privé (read self only) |
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
  optedOutSubjects: string[];           // matières retirées par l'élève (mode opt_out legacy Story 1.4) — un sous-ensemble de derivedSubjects
  // NEW Story 1.11a (v2 catalogue, ADR-016) — utilisé par modes panier (free_with_obligatory, series_plus_optional, tve_picker)
  // Optionnel : absent sur profils v1 (modes derived/opt_out). Présent sur profils créés en mode panier.
  // Doit satisfaire pickedSubjectsValid() Firestore rule (Story 1.15) :
  //   pickedSubjects ⊂ (derivedSubjects ∪ derivation_rules.optionalSubjectIds)
  //   ET derivation_rules.obligatorySubjectIds ⊂ pickedSubjects
  pickedSubjects?: string[];            // matières finalement sélectionnées (panier polymorphe)
  examTargets: string[];                // examens visés (refs vers une collection exams ou ids constants)
  schoolId: string | null;              // ref vers schools/{id} si lié
  // Story 1.5.d — Dénormalisation depuis schools/{schoolId} au moment où l'utilisateur lie son école
  // via updateLinkedSchool(School?). null si schoolId null (les 4 champs sont cohérents ensemble).
  // Préparation Epic 2+ dashboard "École : X", Epic 5 rankings régionaux, Epic 6 IA contextualisée.
  // Économise -1 read schools/{id} par chargement downstream (~-50k reads/jour @10k DAU).
  schoolCity: string | null;            // ville de l'école liée (dénorm Story 1.5.d)
  schoolRegion: string | null;          // région de l'école liée (dénorm Story 1.5.d)
  schoolName: string | null;            // nom de l'école liée (dénorm Story 1.5.d)
  displayName: string;
  photoUrl: string | null;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  // Délai de grâce de suppression (Phase 1)
  deletionRequestedAt: Timestamp | null;
  // Story 1.6 — identité de linking Google/Apple. null = visiteur anonyme (avant linking).
  authProvider: 'google' | 'apple' | null;
  // Story 1.6 — miroir de Firebase Auth. false après linkWithCredential, true avant.
  isAnonymous: boolean;
  // ProfileSetupSheet — optionnel, Cameroun +237 uniquement. null si non renseigné.
  phoneNumber: string | null;
}
```

**Indexes** :
- `subSystem` + `niveau` + `serie` (utile pour ranking par classe et stats par profil)
- `schoolId` + `niveau` + `serie` (utile pour ranking par école)

**Règles d'accès** :
- Lecture : uniquement par `uid` (l'élève lui-même), ou par un compte admin
- Écriture : uniquement par `uid`, sauf `derivedSubjects` qui est écrit par une Cloud Function lors de la création du profil
- `deletionRequestedAt` géré par Cloud Function (`requestAccountDeletion`)

> **Boot-sync `subSystem` (2026-06-17)** : à chaque lancement de l'app, si l'utilisateur est authentifié, `splash_page.dart` lit `users/{uid}` une seule fois via `fetchProfileOnce()` (`.get()` — 1 read, non-bloquant, dans la fenêtre d'animation splash ~2.1s) pour comparer `data['subSystem']` avec la valeur locale SharedPreferences. Si différent (cas nouveau téléphone, backup cloud Android/iOS stale), le notifier Riverpod est mis à jour → SharedPreferences corrigé → Firestore reste la source de vérité. Ce read s'exécute en parallèle du warm-up catalogue via `Future.wait`. Non-bloquant : toute erreur est loguée en warning, l'app continue. **Pas de nouvel index Firestore** (lecture par doc ID auto-indexée).

## Catalogue scolaire (6 collections — Story 1.1a)

> **Pivot ADR-015** : le catalogue scolaire (filières, niveaux, séries, matières, examens, règles de dérivation) vit en **Firestore** avec flag `isActive: bool` sur chaque document. L'admin pédagogique active/désactive runtime depuis Firebase Console sans cycle de release mobile. Seed initial via script Python externe `scripts/firebase_seed/seed_catalogue.py` (Story 1.1b). Lecture côté mobile via `CatalogueRepository` (Story 1.1c) avec filtre systématique `where('isActive', '==', true)` + cache offline Firestore natif (NFR-5, ADR-010).

**Conventions IDs cross-collection** : snake_case strict, préfixe `{subSystem}_` pour disambiguation francophone / anglophone. Détail dans [DONNEES-REFERENCE.md § Convention de nommage](DONNEES-REFERENCE.md#convention-de-nommage-des-ids).

### `filieres/{filiereId}` 🟢

```typescript
interface FiliereDoc {
  filiereId: string;                    // = doc ID. Convention: snake_case ("generale", "technique")
  name: { fr: string; en: string };     // ex. { fr: "Générale", en: "General" }
  isActive: boolean;                    // pivot — admin Console toggle pour activer/désactiver runtime
  sortOrder: number;                    // ordre d'affichage (10, 20, 30...)
}
```

### `niveaux/{niveauId}` 🟢

```typescript
interface NiveauDoc {
  niveauId: string;                     // = doc ID. Convention: {subSystem}_{slug}
                                         // ex. "francophone_6e", "francophone_terminale",
                                         //     "anglophone_form_1", "anglophone_lower_sixth"
  subSystem: "francophone" | "anglophone";
  name: { fr: string; en: string };
  filiereIds: string[];                  // refs vers filieres/{id} — un niveau peut être valide
                                         // pour générale + technique (ex. Terminale)
  isActive: boolean;
  sortOrder: number;
}
```

### `series/{serieId}` 🟢

```typescript
interface SerieDoc {
  serieId: string;                       // = doc ID. Convention: {subSystem}_{niveau_slug}_{serie_slug}
                                         // ex. "francophone_terminale_d", "francophone_terminale_a1",
                                         //     "anglophone_upper_sixth_s2", "anglophone_tve_il_elet"
  subSystem: "francophone" | "anglophone";
  niveauId: string;                      // ref vers niveaux/{id}
  filiereId: string;                     // ref vers filieres/{id}
  name: { fr: string; en: string };
  canOptOut: boolean;                    // Story 1.4 — retrait conditionnel matières (mode opt_out legacy).
                                         // Anglophone Form 3+ et Lower/Upper Sixth toutes filières => true.
                                         // Sinon false.
  isActive: boolean;
  sortOrder: number;

  // NEW Story 1.11a (v2 catalogue, ADR-016) — panier polymorphe
  pickerMode?: PickerMode;               // default 'derived' si absent (rétrocompat v1 — comportement Story 1.4 préservé).
  minSubjects?: number;                  // default null = pas de min.
  maxSubjects?: number;                  // default null = pas de max.

  // NEW Story 1.11a — spécifique TVEE (uniquement si pickerMode == 'tve_picker')
  // Présents pour les séries TVE IL/AL (anglophone_tve_il_*, anglophone_tve_al_*).
  // Optionnels = undefined sur séries non-TVEE.
  professionalSubjectIds?: string[];     // matières professionnelles obligatoires
  relatedProfessionalSubjectIds?: string[]; // matières related obligatoires
  otherSubjectIds?: string[];            // matières libres (Other Subjects) au choix
}

// NEW Story 1.11a — type enum panier (ADR-016 Décision 3)
type PickerMode =
  | 'derived'                // default : matières dérivées non modifiables (Tle franco A/C/D/E v1)
  | 'opt_out'                // legacy Story 1.4 : retrait simple (Lower/Upper Sixth A-Level avant 1.16)
  | 'free_with_obligatory'   // O-Level Form 3-5 (Story 1.15) : sélection libre 6-11 + obligatoires
  | 'series_plus_optional'   // A-Level Lower/Upper Sixth (Story 1.16) : Series fixe + transversales optionnelles
  | 'tve_picker';            // TVEE IL/AL (Story 1.17) : Professional + Related obligatoires + Other libres
```

### `subjects/{subjectId}` 🟢

```typescript
interface SubjectDoc {
  subjectId: string;                     // = doc ID. Convention: {subSystem}_{shortCode} en snake_case
                                         // ex. "francophone_math", "francophone_pct", "francophone_svt",
                                         //     "anglophone_pure_maths", "anglophone_further_maths",
                                         //     "anglophone_english_lit"
  subSystem: "francophone" | "anglophone";
  name: { fr: string; en: string };
  icon: string;                          // nom Lucide (ex. "function-square", "flask-conical")
                                         // pack lucide_icons_flutter ^3.1.14 (pubspec.yaml)
  isActive: boolean;
  sortOrder: number;
}
```

> **Migration de l'ancien schéma `SubjectDoc`** (ligne ~155 ci-dessous, statut 🟡) : le schéma legacy ne sera **plus utilisé**. Le seed Story 1.1b écrira directement la nouvelle structure ci-dessus. L'ancienne définition reste documentée plus bas en attendant sa dépréciation formelle en Story 1.1c.

### `exam_targets/{examTargetId}` 🟢

```typescript
interface ExamTargetDoc {
  examTargetId: string;                  // = doc ID. Convention: exam_{niveau}_{subSystem}[_{serie}]
                                         // ex. "exam_bepc_francophone", "exam_bac_francophone_d",
                                         //     "exam_bac_technique_f1", "exam_gce_o_level_anglophone",
                                         //     "exam_gce_a_level_anglophone_s2"
  subSystem: "francophone" | "anglophone";
  name: { fr: string; en: string };      // ex. { fr: "BAC D", en: "BAC D" }
  isActive: boolean;
  sortOrder: number;
}
```

### `derivation_rules/{ruleId}` 🟢

```typescript
interface DerivationRuleDoc {
  ruleId: string;                        // = doc ID. Convention: rule_{subSystem}_{filiere}_{niveau}_{serie|none}
                                         // ex. "rule_francophone_generale_terminale_d",
                                         //     "rule_anglophone_generale_form_1_none"
  matchSubSystem: "francophone" | "anglophone";
  matchFiliere: string;                  // ref filieres/{id} ou "*" pour wildcard
                                         // (ex. Forms 1-2 sans distinction filière)
  matchNiveau: string;                   // ref niveaux/{id}
  matchSerie: string | null;             // ref series/{id} ou null si le niveau n'a pas de série
                                         // (ex. 6ᵉ, Form 1)
  subjectIds: string[];                  // refs vers subjects/{id} — résultat de la dérivation
  examTargetIds: string[];               // refs vers exam_targets/{id}
  canOptOut: boolean;                    // doublon avec series.canOptOut pour requête directe
                                         // (figé à la création de la rule)
  isActive: boolean;

  // NEW Story 1.11a (v2 catalogue, ADR-016) — panier polymorphe
  // Présents uniquement pour rules dont la série a pickerMode != 'derived'.
  // Sinon undefined (rétrocompat v1).
  obligatorySubjectIds?: string[];       // matières non décochables (modes free_with_obligatory + tve_picker)
                                         // ex. O-Level Form 5 : ['anglophone_english_lang', 'anglophone_french', 'anglophone_math']
  optionalSubjectIds?: string[];         // matières ajoutables (mode series_plus_optional A-Level)
                                         // ex. ['anglophone_computer_science', 'anglophone_ict', 'anglophone_religious_studies', 'anglophone_commerce']
}
```

### Validation panier polymorphe (Story 1.11a, ADR-016 Décision 4)

Pour les modes `free_with_obligatory`, `series_plus_optional`, `tve_picker`, le champ `users/{uid}.pickedSubjects` est validé côté serveur via une règle Firestore commune `pickedSubjectsValid()` (à implémenter dans `firestore.rules` par Story 1.15) :

```javascript
// firestore.rules — extrait Story 1.15 (sur match /users/{uid})
function pickedSubjectsValid(data) {
  let picked = data.get('pickedSubjects', []).toSet();
  let derived = data.derivedSubjects.toSet();
  let obligatory = data.get('obligatorySubjectIds', []).toSet();
  let optional = data.get('optionalSubjectIds', []).toSet();
  // pickedSubjects ⊂ (derivedSubjects ∪ optionalSubjectIds)
  // ET obligatorySubjectIds ⊂ pickedSubjects
  return picked.difference(derived.union(optional)).size() == 0
      && obligatory.difference(picked).size() == 0;
}
```

Validation **client (UI) + serveur (Firestore rule)** dupliquée pour UX rapide + intégrité (cf. ADR-016 § Décision 4). Tests ajoutés à `test/rules/users.test.mjs` par Story 1.15 : (n) `pickedSubjects` valide OK, (o) obligatoire manquant KO, (p) extra hors `derivedSubjects` ∪ `optionalSubjectIds` KO.

### Indexes composés (les 6 collections catalogue)

À ajouter dans `firestore.indexes.json` racine en Story 1.1c :

- `series.(subSystem ASC, niveauId ASC, filiereId ASC, isActive ASC)` — sélection séries valides pour flow profil 3 étapes (Story 1.3)
- `subjects.(subSystem ASC, isActive ASC, sortOrder ASC)` — grille matières dashboard (Story 1.9)
- `derivation_rules.(matchSubSystem ASC, matchFiliere ASC, matchNiveau ASC, matchSerie ASC, isActive ASC)` — match dérivation côté client (Story 1.1c `CatalogueRepository.derive()`)

### Règles d'accès (les 6 collections catalogue)

- **Lecture** : `if request.auth != null` (utilisateur authentifié, anonyme ou complet)
- **Écriture** : `if false` (jamais depuis le mobile — seul le script Python `seed_catalogue.py` (Story 1.1b) avec service-account.json OU la Firebase Console admin peut écrire)

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

### `chapters/{chapterId}` 🟢

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

### `lessons/{lessonId}` 🟢

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

### `notions/{notionId}` 🟢

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

### `schools/{schoolId}` 🟢

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
  keywords: string[];                    // Story 1.5.b — tokens lower-case ASCII sans accents
                                         // pour query arrayContains case-insensitive + abreviations
                                         // (ghs, gbhs, pss, lb, chs, gths, gtbhs). Genere cote seed Python
                                         // via _generate_keywords(name + city + region).
}
```

**Seed (Story 1.5.a)** : ~198 établissements MINESEC + GCE Board (V1) seedés sur `valide-edu` via [`scripts/firebase_seed/seed_schools.py`](../../scripts/firebase_seed/seed_schools.py) à partir de [`scripts/firebase_seed/data/schools.json`](../../scripts/firebase_seed/data/schools.json). Couvre les 10 régions officielles (Centre, Littoral, Ouest, Sud-Ouest, Nord-Ouest, Nord, Sud, Extrême-Nord, Adamaoua, Est). Extensible via PR + re-seed.

**Convention `schoolId`** : slug reproductible `school_<slug_nom>_<slug_ville>` (ex. `school_lycee_general_leclerc_yaounde`, `school_ghs_buea_town_buea`). Pattern : `^school_[a-z0-9_]+$`.

**Sémantique `subSystem`** :

| Valeur | Signification |
|---|---|
| `francophone` | École avec **uniquement** une section francophone (Lycée FR, Collège FR pur) |
| `anglophone` | École avec **uniquement** une section anglophone (Government High School, PSS, Comprehensive) |
| `both` | École avec **sections multiples** : francophone ET anglophone coexistantes au sein du même établissement (Lycée Bilingue, GBHS Government Bilingual High School, écoles avec annexes bilingues actives) |

> **Note V1** : la valeur `both` couvre tous les cas multi-langues du système camerounais (uniquement francophone + anglophone à ce jour). Si un nouveau sous-système devait être ajouté (ex. arabophone via madrasas, biculturelle, etc.), une migration vers `subSystems: string[]` (array Firestore avec `arrayContains`) serait privilégiée. À tracer en sprint-change si le cas survient.

> **Note pratique** : beaucoup de grandes écoles francophones (Lycée Joss, Lycée Général Leclerc, etc.) ont en pratique une **section bilingue** opérationnelle, ce qui pourrait justifier `both`. Le seed Story 1.5.a a privilégié l'**identité dominante** (francophone si le nom contient « Lycée », anglophone si « Government High School ») par défaut. Une école peut être promue `francophone` → `both` ultérieurement via PR sur `data/schools.json` + re-seed, ou directement par toggle admin Firebase Console.

> **Story 1.5.c (2026-06-10)** : la sous-collection `schools/{schoolId}/requests` POC Story 1.7 est **supprimée**. Les demandes d'ajout vivent désormais dans la collection racine [`school_requests/{requestId}`](#school_requestsrequestid--story-15c) (cf. ci-dessous).

### `school_requests/{requestId}` 🟢 (Story 1.5.c)

Demandes d'ajout d'école soumises par les élèves dont l'école n'est pas dans le seed Story 1.5.a (198 écoles V1 — couverture ~80%, le reste passe par ce flow). L'admin modère via Firebase Console + workflow `scripts/firebase_seed/data/README.md`.

```typescript
interface SchoolRequestDoc {
  requestId: string;                     // = doc ID Firestore (autoId)
  requestedBy: string;                   // uid de l'utilisateur authentifié
  requestedAt: Timestamp;                // SERVER_TIMESTAMP au create
  status: "pending" | "approved" | "rejected";  // initial: "pending" (forcé par rules)
  name: string;                          // nom de l'école (3-200 chars)
  city: string;                          // ville (2-100 chars)
  region?: string;                       // région (optionnel, max 100 chars)
  subSystem?: "francophone" | "anglophone" | "both";  // optionnel (« je ne sais pas »)
  // Champs admin (jamais écrits côté client) :
  decidedBy?: string;                    // uid de l'admin qui a décidé
  decidedAt?: Timestamp;                 // SERVER_TIMESTAMP à la décision
  schoolIdCreated?: string;              // si approved : ref vers schools/{schoolIdCreated}
  rejectionReason?: string;              // si rejected : explication courte
}
```

**Path** : collection racine (vs sous-collection schools/{id}/requests POC). Justifications :
- Découple sémantiquement de `schools/` (pas de pollution Firebase Console avec faux docs `_pending_<ts>`)
- Permet query `where('requestedBy', '==', uid)` naturelle pour read self (rules + futur écran « Mes demandes »)
- Rules simples (1 path explicite vs wildcard dynamique)

**Sécurité (cf. `firestore.rules` § `school_requests/{requestId}`)** :
- Create : owner uniquement (`requestedBy == auth.uid`) + champs valides + `status` forcé à `'pending'` (anti-escalade : un client malveillant ne peut pas créer une demande déjà `approved`)
- Read : self uniquement (`resource.data.requestedBy == auth.uid`)
- Update/delete : interdits côté client (modération admin via Console ou Cloud Function future)

**Cost-benefit (CLAUDE.md règle 10m)** :
- 1 write par demande (taux moyen ~5% des onboardings → ~42 demandes/mois @10k users)
- 0 read V1 (toast feedback suffit), 1-3 reads V2 (futur écran « Mes demandes »)
- Storage : ~150 KB après 1 an à 10k users (négligeable)
- Index V1 : aucun (single-field `requestedBy` auto-indexé). Index composite à ajouter si V2 ajoute un écran « Mes demandes » avec query `where('requestedBy') + where('status') + orderBy('requestedAt')`.

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

🟢 **Validés Story 1.1a** (catalogue scolaire) :

- `series` : `(subSystem, niveauId, filiereId, isActive)` — sélection séries valides flow profil
- `subjects` : `(subSystem, isActive, sortOrder)` — grille matières dashboard
- `derivation_rules` : `(matchSubSystem, matchFiliere, matchNiveau, matchSerie, isActive)` — match dérivation

🟢 **Validés Story 1.7 + 1.5.b** (catalogue écoles) :

- `schools` : `(isValidated ASC, name ASC)` — Story 1.7 query prefix range (conservé pour audit + retro-compat)
- `schools` : `(isValidated ASC, keywords ARRAY-CONTAINS)` — **Story 1.5.b** recherche `arrayContains` case-insensitive sans accents (search principal V2)

🟢 **Validés Story 2.1** (contenu pédagogique) :

- `chapters` : `(subjectId ASC, order ASC)` — liste chapitres par matière triés
- `lessons` : `(chapterId ASC, order ASC)` — liste leçons par chapitre triés
- `notions` : `(lessonId ASC, order ASC)` — liste notions par leçon triées

🔴 **À compléter pendant la mise en place** :

- `users` : `(subSystem, niveau, serie)` — pour les stats par profil
- `users` : `(schoolId, niveau, serie)` — pour les rankings classe
- `exercises` : `(lessonId, difficulty)` — pour filtrage
- `rankings/{board}/entries` : `(score desc)` — top X

---

## Règles de sécurité — résumé

Le détail vit dans [`firestore.rules`](../../firestore.rules) à la racine de ce dépôt (les configs Firebase racine sont partagées avec le backend, cf. CLAUDE.md). Tests unitaires des règles dans [`test/rules/`](../../test/rules/). En résumé :

| Collection | Lecture | Écriture |
|---|---|---|
| `users/{uid}` | `uid` | `uid` (sauf champs dérivés écrits par CF) + **`pickedSubjects` validé par `pickedSubjectsValid()` Story 1.15** |
| `subscriptions/{uid}` | `uid` | **Cloud Function uniquement** |
| `credits/{uid}` | `uid` | **Cloud Function uniquement** |
| `credits/{uid}/transactions/*` | `uid` | **Cloud Function uniquement** |
| `filieres`, `niveaux`, `series`, `exam_targets`, `derivation_rules` (catalogue Story 1.1a) | Authentifié (`request.auth != null`) | **Script Python `seed_catalogue.py` / Console admin uniquement** (`write: if false` côté mobile) |
| `subjects` (Story 1.1a, schema migré) | Authentifié | **Script Python / Console admin uniquement** |
| `chapters`, `lessons`, `notions` | Authentifié (`request.auth != null`) — Story 2.1 | Script Python `seed_content.py` / Console admin (`write: false` côté mobile) |
| `exercises`, `quizzes`, `exam_subjects` | Authentifié, profil complet (filtré par règle — futur Epic 3+) | Admin (via backoffice) |
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

## Règles d'optimisation lecture / écriture (V1)

> **Cohérent avec [CLAUDE.md § Architecture mobile règle 10](../../CLAUDE.md)** (modélisation Firestore optimisée — lecture, latence, coût). Cette section est l'application concrète à chaque collection et champ.

### Principes fondamentaux (rappel)

1. **Firestore facture par document lu**, pas par octet. Tout `.get()` ou émission `.snapshots()` = 1 read facturable.
2. **Marché Cameroun = réseau dégradé** : chaque round-trip coûte en latence (≥ 500ms typique 3G) et en data utilisateur.
3. **Cache offline natif Firestore** (NFR-5, ADR-010) = lecture instantanée sur docs déjà chargés. Privilégier ce mode.
4. **Toute story qui ajoute une lecture/écriture DOIT documenter** : (i) reads/session moyenne, (ii) volumétrie estimée à 10 000 users, (iii) trade-off vs alternative.

### Read patterns recommandés par collection

| Collection | Pattern V1 | Recommandation cible | Justification |
|---|---|---|---|
| `users/{uid}` | `.snapshots()` self-read + `.get()` boot-sync | OK Stream conservé + 1 `.get()` au lancement | Doc mutable pendant la session (Story 1.4 opt-out, Story 1.7 schoolId, Story 1.10 deletionRequestedAt). Boot-sync : 1 `.get()` supplémentaire au démarrage si authentifié, pour corriger `subSystem` stale (nouveau téléphone). |
| `subscriptions/{uid}` | `.snapshots()` self-read | OK Stream conservé | Statut paiement webhook-driven, doit refléter en live. |
| `credits/{uid}` | `.snapshots()` self-read | OK Stream conservé | Solde décrémente côté Cloud Function, live nécessaire. |
| **`filieres`** | `.snapshots()` (Story 1.1c) | ⚠️ **Refactor → `.get()` + cache offline** | Catalogue statique (~2 docs). Update admin rare (1-2x/an). Anti-pattern règle 10.g. |
| **`niveaux`** | `.snapshots()` (Story 1.1c) | ⚠️ **Refactor → `.get()`** | Idem (~16 docs v2). |
| **`series`** | `.snapshots()` (Story 1.1c) | ⚠️ **Refactor → `.get()`** | Idem (~95 docs v2). |
| **`subjects`** | `.snapshots()` (Story 1.1c) | ⚠️ **Refactor → `.get()`** | Idem (~70 docs v2). |
| **`exam_targets`** | `.snapshots()` (Story 1.1c) | ⚠️ **Refactor → `.get()`** | Idem (~82 docs v2). |
| **`derivation_rules`** | `.snapshots()` (Story 1.1c) | ⚠️ **Refactor → `.get()`** | Idem (~104 docs v2). |
| `chapters`, `lessons`, `notions` | À spécifier Epic 2 | `.get()` + cache | Statique, lecture par chapter/lessonId. |
| `exercises`, `quizzes` | À spécifier Epic 3 | `.get()` par ID | Lecture déclenchée au lancement quiz. |
| `users/{uid}/health/{notionId}` | À spécifier Epic 5 | `.snapshots()` | Mise à jour live après chaque session. |
| `users/{uid}/sessions/{sid}` | À spécifier Epic 3 | `.snapshots()` sur session courante uniquement | Mutable durant la session. |
| `schools` (recherche) | `.get()` + `.where(isValidated)` + `.where(keywords, arrayContains)` + `.limit(10)` + tri client | OK Story 1.5.b | Story 1.7 query prefix range refactoree Story 1.5.b en `arrayContains keywords[]` (case-insensitive + sans accents + abreviations ghs/gbhs/pss/lb/chs). Tri alphabetique cote Dart sur 10 items (orderBy Firestore + arrayContains necessiterait un index complexe — sur-engineering V1). |

**Décision V1 sur catalogue** : le refactor `snapshots → get` est tracé comme dette technique (impact économique tolérable à 10k users : ~$0.36/mois). À prioriser **Story 1.13** (qui touche déjà le repository pour `DerivedProfile v2`) ou **dès qu'on dépasse 50k users**, selon priorité produit.

### Update patterns détaillés par champ

> **Règle absolue** : toujours `.update({champ: valeur, updatedAt: FieldValue.serverTimestamp()})` ou `.set(payload, SetOptions(merge: true))`. **Jamais** `.set(payload)` complet (réécrit le doc entier → race conditions + coût).

#### `users/{uid}` — champ par champ

| Champ | Mutabilité | Méthode d'update | Quand | Validation | Story |
|---|---|---|---|---|---|
| `uid` | **Immutable** | N/A (= doc ID) | À la création | rules : doc ID == auth.uid | 1.3 |
| `subSystem` | **Immutable (écriture)** | `.set(merge: true)` à la création | Étape 1 onboarding | rules : impossible de modifier post-création ; lu au boot par `fetchProfileOnce()` pour corriger SharedPreferences stale (nouveau téléphone — voir note boot-sync ci-dessus) | 1.2 / 1.3 |
| `language` | **Immutable** | `.set(merge: true)` à la création | Étape 1 onboarding | dérivé de subSystem | 1.2 / 1.3 |
| `filiere` | **Immutable post-création** | `.set(merge: true)` à la création | Étape 2 onboarding | rules : impossible de modifier post-création (`request.resource.data.filiere == resource.data.filiere`) | 1.3 |
| `niveau` | **Immutable post-création** | `.set(merge: true)` à la création | Étape 2 onboarding | rules : idem filiere | 1.3 |
| `serie` | **Immutable post-création** | `.set(merge: true)` à la création | Étape 3 onboarding | rules : idem filiere | 1.3 |
| `trackId` | **Mutable** (depuis Story A.3) | `.update({trackId, levelId, streamId, derivedSubjects, examTargets, pickedSubjects, optedOutSubjects, updatedAt})` via `updateSchoolProfile()` | Édition profil scolaire depuis onglet Accueil (SchoolProfileEditSheet) | rules : contrainte immuabilité retirée Story A.3 Approche B ; `subSystem`/`language`/`createdAt` restent immutables | 1.3 (création) + **A.3** (édition) |
| `levelId` | **Mutable** (depuis Story A.3) | idem `trackId` | idem | idem | 1.3 (création) + **A.3** (édition) |
| `streamId` | **Mutable** (depuis Story A.3) | idem `trackId` | idem | idem | 1.3 (création) + **A.3** (édition) |
| `derivedSubjects` | **Mutable** (depuis Story A.3) | idem `trackId` | Recalculé via `derive()` en mémoire (catalogueProvider) avant save | rules : aucune contrainte spécifique | 1.3 (création) + **A.3** (édition) |
| `optedOutSubjects` | **Mutable** | `.update({optedOutSubjects: [...], updatedAt: ...})` | Tap Save sur SubjectsOptOutPage | rules : `subset(derivedSubjects)` via `diff.affectedKeys` | 1.4 |
| `pickedSubjects` (v2) | **Mutable** | `.update({pickedSubjects: [...], updatedAt: ...})` | Tap Save sur SubjectsPickerPage | rules : `pickedSubjectsValid()` (cf. ci-dessus) | 1.15 |
| `examTargets` | **Mutable** (depuis Story A.3) | idem `trackId` | Recalculé via `derive()` en mémoire | rules : aucune contrainte spécifique | 1.3 (création) + **A.3** (édition) |
| `schoolId` + `schoolCity` + `schoolRegion` + `schoolName` | **Mutable** (4 champs cohérents ensemble) | `.update({schoolId, schoolCity, schoolRegion, schoolName, updatedAt})` via `updateLinkedSchool(School?)` | Tap card school OU Skip sur SchoolPickerPage | rules : tous nuls ensemble si unlink ; pas de validation stricte cohérence avec `schools/{id}` (trade-off V1) | 1.7 + **1.5.d** |
| `displayName` | **Mutable** | `.update({displayName: X, updatedAt: ...})` | Après linkWithCredential Google/Apple | rules : self-write | 1.6 |
| `photoUrl` | **Mutable** | `.update({photoUrl: X, updatedAt: ...})` | Après linkWithCredential Google/Apple | rules : self-write | 1.6 |
| `createdAt` | **Immutable** | `FieldValue.serverTimestamp()` à la création | Étape 3 onboarding | rules : `request.resource.data.createdAt == resource.data.createdAt` | 1.3 |
| `updatedAt` | **Auto-update** | `FieldValue.serverTimestamp()` sur chaque update | Toute écriture | rules : doit être présent à chaque update | toutes |
| `deletionRequestedAt` | **Mutable** (par Cloud Function) | Cloud Function `requestAccountDeletion` / `cancelAccountDeletion` | Tap "Supprimer mon compte" | rules : write côté serveur uniquement | 1.10 |
| `authProvider` | **Mutable** (une seule fois, linking) | `.update({authProvider: 'google'/'apple', updatedAt: ...})` via `_persistIdentity()` | Après `linkWithCredential` Google/Apple | rules : self-write ; null → non-null uniquement (jamais annulation) | 1.6 |
| `isAnonymous` | **Mutable** (une seule fois, linking) | `.update({isAnonymous: false, updatedAt: ...})` via `_persistIdentity()` | Après `linkWithCredential` réussi | rules : self-write ; `true → false` uniquement | 1.6 |
| `phoneNumber` | **Mutable** | `.update({phoneNumber: X, updatedAt: ...})` via `updatePhoneNumber()` | ProfileSetupSheet post-linking | rules : self-write ; format `+237[26][0-9]{8}` validé côté client | 1.6 (ProfileSetupSheet) |

**Pattern de référence (Story 1.4)** :
```dart
await _firestore.collection('users').doc(uid).update({
  'optedOutSubjects': ids,
  'updatedAt': FieldValue.serverTimestamp(),
});
```
- Update partiel (n'écrase pas `displayName`, `schoolId`, etc.)
- `updatedAt` = serveur (jamais `DateTime.now()` client — évite skew d'horloge)
- Sans `set(merge: true)` car le doc existe déjà (post-onboarding)

#### Catalogue scolaire (6 collections) — write côté mobile

| Collection | Mutabilité mobile | Méthode | Justification |
|---|---|---|---|
| `filieres` | **Read-only mobile** | Aucune (rules `write: false`) | Seul `seed_catalogue.py` (Story 1.1b / 1.12) écrit via service-account |
| `niveaux` | Read-only mobile | Aucune | idem |
| `series` | Read-only mobile | Aucune | idem |
| `subjects` | Read-only mobile | Aucune | idem |
| `exam_targets` | Read-only mobile | Aucune | idem |
| `derivation_rules` | Read-only mobile | Aucune | idem |

**Activation runtime** : l'admin pédagogique modifie `isActive: false → true` directement dans Firebase Console (ADR-015). Le mobile observe (post-refactor `get()` : au prochain refresh ; en `snapshots()` actuel : immédiat).

#### `schools` — recherche + création de demande

| Champ | Mutabilité | Méthode | Story |
|---|---|---|---|
| `schoolId` | Immutable | N/A (= doc ID) | 1.7 |
| `name`, `city`, `region`, `subSystem` | Immutable post-seed | Modifié uniquement par admin console | 1.7 |
| `isValidated` | Mutable (admin uniquement) | Console | 1.7 (admin) |
| `schools/_pending/requests/{auto}` | **Create-only mobile** | `.collection('requests').add({...})` | Pattern Story 1.7 — séparation pour modération admin |

#### `users/{uid}` sous-collections — patterns futurs

| Sous-collection | Pattern d'écriture cible | Story |
|---|---|---|
| `users/{uid}/completions/{sessionId}` | `.set(payload)` une fois (idempotent par sessionId) | Epic 3 |
| `users/{uid}/health/{notionId}` | `.update({...})` après chaque session | Epic 5 |
| `users/{uid}/stats` (doc unique) | `.update({...})` avec `FieldValue.increment()` pour les compteurs | Epic 5 |
| `users/{uid}/sessions/{sid}` | `.set(payload)` création + `.update(...)` durant la session + `.delete()` à la fin | Epic 3 |

**Pattern critique** : pour les compteurs (`stats.totalQuizzes`, `stats.streak`), utiliser `FieldValue.increment(N)` plutôt que `read + computeNewValue + write`. Évite race conditions + 1 read épargné par session.

### Dénormalisations recommandées

| Cas | Dénormalisation | Pourquoi | Story |
|---|---|---|---|
| Dashboard affiche "École : Lycée X" (Epic 2+) | Dupliquer `schoolName: string` dans `users/{uid}` | Évite 1 read `schools/{schoolId}` à chaque ouverture dashboard | 🟢 Story 1.5.d |
| Préparation Epic 5 rankings régionaux + Epic 6 IA contextualisée | Dupliquer `schoolCity: string` + `schoolRegion: string` dans `users/{uid}` | Évite N reads `schools` quand on filtre/agrège par région ou ville | 🟢 Story 1.5.d |
| Ranking par école (Epic 5) | Dupliquer `schoolName`, `schoolRegion` dans `rankings/{board}/entries/{uid}` | Évite N reads `schools` pour afficher la liste | Epic 5 |
| Chat IA conversation list (Epic 6) | Stocker `lastMessage: string` (1 ligne) + `lastMessageAt: Timestamp` dans `users/{uid}/conversations/{cid}` | Évite de lire toute la sous-collection messages pour afficher la liste | Epic 6 |

**Trade-off accepté** : écritures plus coûteuses (multi-doc updates via `WriteBatch` ou Cloud Function quand un `school` change de nom — rare). Lectures massivement moins chères. À documenter dans la story qui introduit la dénormalisation.

### Anti-patterns interdits (rappel CLAUDE.md règle 10)

1. ❌ `.collection(X).get()` sans `.limit()` → coût explosif
2. ❌ `.snapshots()` sur catalogue ou contenu statique (chapters, lessons) → idem
3. ❌ Filtrer en `.where((doc) => ...)` côté Dart ce qui peut être filtré côté serveur `.where(...)` Firestore
4. ❌ N+1 reads (boucler une liste de docs et faire `.get()` pour chaque détail) — utiliser `whereIn` (max 30 IDs) ou dénormaliser
5. ❌ `.set(payload)` complet pour modifier 1 champ → `update({})` ou `set(merge: true)`
6. ❌ `.offset(N)` pour paginer (Firestore facture les docs sautés) → `.startAfterDocument(lastDoc)`
7. ❌ Stocker des blobs > 10 KB dans un doc listé en grille → isoler en sous-doc
8. ❌ Re-fetcher un champ déjà disponible dans le doc déjà lu
9. ❌ `DateTime.now()` client pour les timestamps → `FieldValue.serverTimestamp()`
10. ❌ Compteur incrémenté via read + write → `FieldValue.increment(N)`

### Audit conformité 2026-06-09 (snapshot post Story 1.12)

| Aspect | Statut | Détail |
|---|---|---|
| `.update()` / `.set(merge: true)` partout | ✅ Conforme | user_profile / account_linking / main confirmés |
| `.limit()` sur listes | ✅ Conforme | school_picker `.limit(10)`, catalogue check `.limit(1)` |
| `.where()` préfiltre serveur | ✅ Conforme (à 95 %) | Sauf `derive()` cas `matchFiliere == '*'` (mineur, ≤ 100 rules) |
| `arrayContains` pour listes courtes | ✅ Conforme | `niveaux.filiereIds` (max 2 entrées) |
| Cache offline natif Firestore | ✅ Conforme | Aucun `Source.server`/`cache` explicite |
| `FieldValue.serverTimestamp()` | ✅ Conforme | partout pour `createdAt` / `updatedAt` |
| `.snapshots()` sur catalogue | ⚠️ **Non-conforme** | 6 streams actifs sur catalogue statique. À refactor Story 1.13 cible. |
| Dénormalisation `schoolName` | 🟡 Non-applicable V1 | Tracé pour Epic 2+. |
| Sous-document pour blobs | 🟡 Non-applicable V1 | Pas de contenu pédagogique chargé encore. |
| Cost-benefit documenté en story | 🟡 Partiel | Stories 1.3-1.12 ont Dev Notes mais sans estimation reads/session formelle. À systématiser. |

**Action de remédiation** : refactor `catalogue_repository_firestore_impl.dart` `watchXxx()` → `fetchXxx()` (Future au lieu de Stream) + `catalogueProvider` `StreamProvider` → `FutureProvider`. Estimation : **S ~2-3h** + adaptation 11 tests existants. Trigger : intégrer à **Story 1.13** (DerivedProfile v2 — touche déjà ce repository) ou **dès qu'on atteint 50k users**.

---

## Historique

| Date | Auteur | Modification |
|---|---|---|
| 2026-06-03 | Setup initial | Création du squelette à partir des docs d'architecture mobile et backend |
| 2026-06-04 | DelRoos / Claude | Story 0.9 — lien vers `firestore.rules` racine + `test/rules/` (règles initiales P0 : default deny + users self-only + `_smoketest/*` temporaire) |
| 2026-06-05 | DelRoos / Claude (Amelia agent) | Story 1.1a — pivot Firestore catalogue scolaire (ADR-015). Ajout 6 collections `filieres`, `niveaux`, `series`, `subjects` (schema migré), `exam_targets`, `derivation_rules` avec flag `isActive: bool` runtime + 3 indexes composites + règles d'accès `read: auth / write: false` (seed via script Python externe Story 1.1b). Updates : Vue d'ensemble (+5 lignes, `subjects` 🟡→🟢 Stream), nouvelle section « Catalogue scolaire » entre `users` et `subscriptions`, tables Indexes + Règles sécurité résumé étendues. Sprint-change-proposal-2026-06-05.md. |
| 2026-06-30 | DelRoos / Claude (Amelia agent) | `users/{uid}` UserDoc — ajout 3 champs écrits en production depuis PR #149 mais absents du schéma : `authProvider` ('google'/'apple'/null, posé par `_persistIdentity()` au linking Story 1.6), `isAnonymous` (bool, miroir Firebase Auth, false après linking), `phoneNumber` (string/null, optionnel +237, posé par `ProfileSetupSheet`). Ajout 3 lignes dans la table Update patterns par champ. |
| 2026-06-09 | DelRoos / Claude (Amelia agent) | Ajout section majeure « Règles d'optimisation lecture / écriture (V1) » avant Historique. Inclut : (a) principes fondamentaux Firestore tarification (read facturé par doc + marché Cameroun 3G), (b) table Read patterns recommandés par collection (alignement règle 10.g CLAUDE.md — catalogue snapshots() flag refactor cible vers get() + cache), (c) table Update patterns détaillés `users/{uid}` champ par champ (mutabilité + méthode + validation rules + story), (d) tables catalogue write-readonly + `schools` + `users/{uid}` sous-collections futures, (e) dénormalisations recommandées (schoolName Epic 2+, ranking, chat conversation list), (f) 10 anti-patterns interdits rappel, (g) audit conformité 2026-06-09 snapshot post Story 1.12 (1 non-conformité catalogue snapshots, reste OK). Cohérent CLAUDE.md règle 10. Aucune modification schema existant. |
| 2026-06-09 | DelRoos / Claude (Amelia agent) | Story 1.11a — catalogue v2 alignement nomenclature officielle (ADR-016). Schema v2 étendu non-breaking : **+3 champs `SerieDoc`** (`pickerMode` enum 5 valeurs + `minSubjects` + `maxSubjects`) + **3 champs `SerieDoc` TVEE-spécifiques** (`professionalSubjectIds` + `relatedProfessionalSubjectIds` + `otherSubjectIds`) + **2 champs `DerivationRuleDoc`** (`obligatorySubjectIds` + `optionalSubjectIds`) + **1 champ `UserDoc`** (`pickedSubjects` optionnel mode panier). Nouveau type `PickerMode` documenté. Nouvelle sous-section « Validation panier polymorphe » avec règle Firestore `pickedSubjectsValid()` (impl Story 1.15). Table Règles de sécurité — résumé : ligne `users/{uid}` annotée pour validation `pickedSubjects`. **AUCUN nouvel index Firestore** (CLAUDE.md règle 9 enforcement explicite : les nouveaux champs sont lus sur docs déjà filtrés par indexes Story 1.1a existants). Defaults safe (`pickerMode == 'derived'` si absent) → rétrocompat Story 1.4 préservée. Sprint-change-proposal-2026-06-09.md. |
| 2026-06-10 | DelRoos / Claude (Amelia agent) | Story 1.5.a — seed initial collection `schools` sur `valide-edu`. Statut `schools/{schoolId}` 🟡 → 🟢 (Vue d'ensemble + section dédiée). Ajout précisions sur seed : ~198 établissements MINESEC + GCE Board V1 couvrant 10 régions officielles (Centre 40, Littoral 38, Ouest 34, Sud-Ouest 20, Nord-Ouest 16, Nord 13, Sud 11, Extrême-Nord 10, Adamaoua 8, Est 8). Convention `schoolId` formalisée (slug `school_<slug_nom>_<slug_ville>` pattern `^school_[a-z0-9_]+$`). Mix subSystem : 136 francophone / 35 both / 27 anglophone. Script Python autonome [`scripts/firebase_seed/seed_schools.py`](../../scripts/firebase_seed/seed_schools.py) calqué sur pattern Story 1.1b (`set(merge=True)`, ADC ou service-account, dry-run, idempotent). Matrice versionnée [`scripts/firebase_seed/data/schools.json`](../../scripts/firebase_seed/data/schools.json). 9 tests pytest sans Firestore live valident la matrice statique. **Aucun nouvel index Firestore** (l'index composite `(isValidated ASC, name ASC)` déjà déployé Story 1.7 suffit pour `school_repository_firestore_impl.searchByPrefix`). Sous-collection `schools/{schoolId}/requests` 🔴 reste à formaliser Story 1.5.c. |
| 2026-06-10 | DelRoos / Claude (Amelia agent) | Story 1.5.b — refactor recherche écoles vers `keywords[] arrayContains` case-insensitive sans accents. Schema `SchoolDoc` étendu avec champ `keywords: string[]` (lower-case ASCII tokens, dépendance `unidecode>=1.3.0` côté seed Python + map accents manuel côté Dart). Script `seed_schools.py` étendu avec flag `--regen-keywords` qui régénère la matrice (pipeline déterministe : name + city + region tokenisés + 7 abréviations communes ghs/gbhs/pss/lb/chs/gths/gtbhs). 198 écoles regénérées avec keywords[] (min 3 / max 10 / avg 5.6 tokens par école, GHS 14, LB 25, GBHS 6, PSS 2). **Nouvel index Firestore composite** `(isValidated ASC, keywords ARRAY-CONTAINS)` déclaré dans `firestore.indexes.json` + déployé sur `valide-edu`. Ancien index `(isValidated, name)` conservé pour audit. Tests : pytest 24/24 verts (Story 1.1b 6 + 1.5.a 9 + 1.5.b 9 = +9 nets) + Dart `school_repository_test.dart` 11/11 verts (Story 1.7 5 adapté avec keywords + Story 1.5.b 6 nouveaux : case-insensitive, accents, GHS abréviation, court-circuit, tri client). Read patterns table mise à jour. Reseed `valide-edu` OK : 198 docs en 43.35 s via ADC. |
| 2026-06-10 | DelRoos / Claude (Amelia agent) | Story 1.5.d — dénormalisation 4 champs école dans `users/{uid}` au moment de la liaison (clôture micro-epic Epic 1.5 Schools completion, 4/4). Schema `UserDoc` étendu non-breaking avec **3 nouveaux champs nullable** : `schoolCity` + `schoolRegion` + `schoolName` (dénormalisés depuis `schools/{schoolId}` au moment du tap card via `updateLinkedSchool(School?)`). Refactor interface domain : `UserProfileRepository.updateSchoolId(String?)` → `updateLinkedSchool(School?)` (entité School complète passée par le caller — 0 read supplémentaire `schools/{id}` au write, CLAUDE.md règle 10.k). Impl Firestore écrit les 4 champs en 1 update partiel (CLAUDE.md règle 10.l). Si `school == null` : les 4 champs deviennent null cohérents (unlink, pas de mismatch). Pas de validation stricte rules de cohérence `schoolCity ↔ schools/{id}.city` V1 (trade-off accepté : un client malveillant ne falsifie que SON propre profil — pas d'escalade, pas d'impact ranking équipe). Commentaire Story 1.5.d ajouté dans `firestore.rules` § users update. Table Dénormalisations recommandées mise à jour : ligne `schoolName` Dashboard 🟡→🟢 + nouvelle ligne `schoolCity` + `schoolRegion` (préparation Epic 5 rankings régionaux + Epic 6 IA contextualisée). Table Update patterns mise à jour : ligne `schoolId` étendue aux 4 champs cohérents. Tests : flutter analyze 0 + flutter test 270 verts (baseline 269 + 3 nouveaux Story 1.5.d (d)(e)(f) - 2 anciens Story 1.7 obsolètes = +1 net) + npm test rules 33/33 (baseline 30 + 3 nouveaux (o)(p)(q) : update 4 champs OK, unlink OK, subSystem immuable même avec school* KO) + pytest 26/26 (baseline 24 + 2 nouveaux `test_migration_idempotent` + `test_migration_skip_user_with_missing_school`). Script Python admin one-shot `migrate_user_school_denorm.py` créé (lookup par ID auto-indexé + cache local schools + idempotent via détection `schoolCity` déjà renseigné + dry-run + warning skip user dont schoolId pointe vers school absente). Workflow migration documenté dans `scripts/firebase_seed/data/README.md`. Cost-benefit : -1 read `schools/{id}` par chargement dashboard downstream Epic 2+ × 10k DAU × 5 ouvertures/jour = -50k reads/jour économisés. Storage supplémentaire ~1.5 MB total négligeable. Aucun nouvel index Firestore V1. Action porteur post-merge : (1) smoke test mobile 4 champs écrits sur `users/<uid>` Firebase Console, (2) run script migration sur valide-edu pour migrer users legacy. Clôture micro-epic Epic 1.5 (1.5.a + 1.5.b + 1.5.c + 1.5.d) → débloque retro Epic 1 globale. |
| 2026-07-01 | DelRoos / Claude (Amelia agent) | Story A.3 — édition profil scolaire (niveau/série/matières) depuis l'onglet Accueil. **Approche B (client direct)** : modification `firestore.rules` UPDATE `users/{uid}` — retrait contraintes immuabilité sur `trackId`, `levelId`, `streamId` (conservés : `subSystem`, `language`, `createdAt`). Table Update patterns mise à jour : `trackId`/`levelId`/`streamId` passent de **Immutable post-création** à **Mutable** (via `updateSchoolProfile()` — 1 `.update()` partiel 8 champs + updatedAt). `derivedSubjects` et `examTargets` également **Mutable** depuis A.3. Nouveau composant `SchoolProfileEditSheet` (bottom sheet multi-étapes PageController : niveau grid → série list → matières chips). Dérivation sujets 100% en mémoire depuis `catalogueProvider` (0 read Firestore supplémentaire). ⚠️ Accord backend requis avant déploiement `firebase deploy --only firestore:rules`. |
| 2026-06-21 | DelRoos / Claude (Amelia agent) | Story 2.1 — schéma contenu pédagogique finalisé + seed Python démo. Statuts `chapters/{chapterId}`, `lessons/{lessonId}`, `notions/{notionId}` 🟡 → 🟢 (Vue d'ensemble + sections dédiées). **3 nouveaux index Firestore composites** déclarés dans `firestore.indexes.json` + déployés sur `valide-edu` : `chapters(subjectId ASC, order ASC)`, `lessons(chapterId ASC, order ASC)`, `notions(lessonId ASC, order ASC)`. **Règles Firestore** étendues : 3 blocs `match /chapters`, `match /lessons`, `match /notions` avec `read: if request.auth != null` + `write: if false` — tout user authentifié peut lire (profil complet géré côté Flutter router Story 1.5). Table Indexes — section 🟢 Story 2.1 ajoutée, entrées chapters/lessons/notions retirées de 🔴. Table Règles de sécurité résumé mise à jour : ligne chapters/lessons/notions séparée de exercises/quizzes. Script Python [`scripts/firebase_seed/seed_content.py`](../../scripts/firebase_seed/seed_content.py) créé (pattern `seed_catalogue.py` : argparse, `set(merge=True)`, validation cross-collection subjectId, dry-run, idempotent). Données démo versionnées [`scripts/firebase_seed/data/content_demo.json`](../../scripts/firebase_seed/data/content_demo.json) : 2 matières (Maths `francophone_math` Tle D + Physics `anglophone_physics` Upper Sixth) × 4 chapitres × 2 leçons × 2 notions = 8 chapters, 16 lessons, 32 notions. Contenu FR+EN avec LaTeX + Mermaid dans au moins 1 leçon par matière. Seed exécuté sur `valide-edu` + idempotence confirmée. 6 tests pytest verts. |
| 2026-06-17 | DelRoos / Claude | Boot-sync `subSystem` depuis Firestore — nouveau pattern de lecture au lancement : `splash_page.dart` lit `users/{uid}` via `fetchProfileOnce()` (1 `.get()` non-bloquant) pour corriger `subSystem` stale sur nouveau téléphone. Firestore reste source de vérité. Aucune modification schéma ni index. Notes ajoutées : section `users/{uid}` (note boot-sync), table Read patterns (colonne `users/{uid}` étendue), table Update patterns (annotation `subSystem` Immutable écriture). |
| 2026-06-10 | DelRoos / Claude (Amelia agent) | Story 1.5.c — flow demande ajout école production-ready. **Nouvelle collection racine `school_requests/{requestId}`** 🟢 avec schema `SchoolRequestDoc` complet (requestedBy + requestedAt + status + name + city + region? + subSystem? + decidedBy? + decidedAt? + schoolIdCreated? + rejectionReason?). Sous-collection POC `schools/{schoolId}/requests` Story 1.7 **supprimée** (refactor non-breaking : `requestSchool` → `createSchoolRequest({name, city, region?, subSystem?})` dans le repository Dart). Rules Firestore étendues : create par owner (uid match + champs valides + status forcé `'pending'` anti-escalade) + read self (`requestedBy == auth.uid` → futur écran « Mes demandes ») + update/delete refusés côté client (modération admin via Console). Aucun nouvel index Firestore V1 (single-field `requestedBy` auto-indexé). Tests : npm test rules 30/30 verts (baseline 23 + 7 Story 1.5.c : create owner valide, uid d'autrui refusé, name trop court refusé, status != pending refusé, subSystem invalide refusé, subSystem valide accepté, read self OK, read other refusé, update/delete refusés) + Dart `school_repository_test.dart` 15/15 verts (Story 1.7 4 adaptés + Story 1.5.b 6 + Story 1.5.c 4 nouveaux : subSystem renseigné/null, region renseigné/null) + widget `school_picker_page_test.dart` 7/7 verts (Story 1.7 5 + Story 1.5.c 2 : modale rendue avec 4 RadioListTile, submit avec subSystem). UI modale `_AddSchoolDialog` étendue avec `RadioGroup<_SubSystemChoice>` 4 options (Francophone, Anglophone, Bilingue, Je ne sais pas par défaut) + 5 clés ARB FR/EN ajoutées. Cost-benefit V1 : ~42 demandes/mois @10k users = négligeable. Workflow admin modération documenté dans `scripts/firebase_seed/data/README.md`. |
