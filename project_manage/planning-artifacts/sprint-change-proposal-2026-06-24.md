# Sprint Change Proposal — 2026-06-24
## Recentrage MVP : Compte complet → Contenu intégré → Exercice

**Date** : 2026-06-24  
**Déclencheur** : Réunion de pilotage équipe Valide School  
**Auteur** : Delano Roosvelt (porteur produit) + Amelia (dev)  
**Scope** : Major — replan fondamental du périmètre E2–E6  

---

## 1. Résumé du changement

### Problème identifié

Après mûre réflexion post-Epic 1bis, l'équipe a tranché : il faut un MVP démontrable **de bout en bout** sur 3 piliers avant d'investir dans la gamification, le paiement et le tracking détaillé.

Deux événements déclencheurs concomitants :
1. **Revert Story 2.4** (session 2026-06-24) — l'intégration Firestore du contenu cassait `SubjectDetailPage` ; les pages de contenu sont revenues à fake data.
2. **Décision réunion 2026-06-24** — réorientation complète des priorités post-E1bis.

### Décision actée

> **"Terminer le flow compte, puis lire un cours + fiche de lecture + faire les quiz liés, puis faire un exercice. Tout le reste après."**

| Pilier | Scope | Statut avant | Statut cible |
|--------|-------|-------------|-------------|
| **A — Compte complet** | Vérification E1bis end-to-end + smoke test 5 personas | done (E1bis) | done-verified |
| **B — Contenu intégré** | Chapitres + leçons Firestore + fiches de lecture + quiz liés | fake data (2.4 revertée) | Firebase réel |
| **C — Exercice de base** | Afficher + soumettre un exercice (sans correction IA V1) | backlog E3 | delivered |
| **D — Reste** | Progression, paiement, gamification, Mode 3, Examen, Chat IA | backlog | **explicitement déféré** |

---

## 2. Analyse d'impact

### 2.1 Epic 1bis — Compte complet (impact : vérification uniquement)

E1bis est **done** (PR #107–#143). Le flow 10 étapes (sub-system → hero → track → level → stream → auth → name → phone → school → success) est livré et fusionné.

**Gaps potentiels à vérifier avant démo** :
- Passage mode anonyme → compte réel (Firebase Auth linking) lors de l'upgrade mid-session
- Completion de profil si interrompue (guard de reprise)
- Suppression compte immédiate (bouton livré en session 2026-06-24 dans `profile_tab_page.dart`)

**Action** : Story de smoke test `A.1-account-e2e-verification` (≤ 1 jour, pas de code, QA uniquement).

### 2.2 Epic 2 — Navigation & Lecture contenu (impact : majeur)

| Story | Statut sprint-status | Statut réel (code) | Action |
|-------|---------------------|-------------------|--------|
| 2.1 schema+seed | done | ✓ mergée | — |
| 2.2 navigation UI | in-progress / review | ✓ mergée (commit 3769b6a) | Mettre à jour statut → done |
| 2.3 dashboard home | review | ✓ code livré | Valider UI porteur → done |
| 2.4 intégration Firestore | review | ⚠️ **revertée** (fake data) | → **in-progress** (à re-faire) |
| **2.5 fiches de lecture** | **inexistante** | n/a | → **à créer** |
| **2.6 quiz liés chapitres/leçons** | **inexistante** | n/a | → **à créer** |

**Nouveau périmètre E2 étendu :**
- **Story 2.4 (réouverte)** : intégration Firestore propre — subjects depuis `userSubjectsProvider`, chapitres et leçons depuis Firestore, shimmer states, error states localisés, cache offline. Correction du bug qui cassait `SubjectDetailPage` dans la précédente impl.
- **Story 2.5 (nouvelle)** : Fiches de lecture — nouveau type de contenu (`type: 'fiche'` en Firestore) rendu via `PedagogicalContent`. Navigation : leçon → fiche de lecture associée. Seed Python à étendre (Story 2.1 base).
- **Story 2.6 (nouvelle)** : Quiz liés aux chapitres/leçons — affichage de questions QCM/court liées à un chapitre ou une leçon (type `quiz` en Firestore), soumission locale, affichage score. Pas de correction IA en V1 (déféré E3).

### 2.3 Epic 3 — Quiz & Pratique active (impact : scope réduit, pull forward partiel)

| Ce qui est pull-forward | Ce qui est déféré |
|------------------------|------------------|
| Module exercice minimal (afficher énoncé + soumettre) | Correction IA (Mode 1 / Mode 2) |
| Affichage résultat basique | Compression photo (NFR-4) |
| — | Idempotence sessionId (si pas de serveur) |

**Nouvelle story** :
- **Story 3.1-mini (nouvelle)** : Module exercice — afficher un énoncé d'exercice classé (épreuve séquence / examen officiel / examen blanc / épreuve zéro), permettre de le parcourir et marquer comme "fait". Pas de correction IA.

### 2.4 Epics 4, 5, 6 — Déféré explicite

| Epic | Contenu | Nouveau statut |
|------|---------|---------------|
| E4 Freemium & Paiement | Mobile Money, plans, webhooks | **deferred** — après les 3 piliers |
| E5 Santé & Gamification | Progression, classements, recommandations | **deferred** — après les 3 piliers |
| E6 Mode 3, Examen, Chat, Partage | IA avancée, composition exam | **deferred** — après les 3 piliers |

> **Note porteur** : "on ne s'intéresse pas encore aux petits éléments de progression du user" — aucune story de tracking (streak, score historique, santé scolaire) n'est créée avant validation complète des 3 piliers.

---

## 3. Schéma Firestore — extensions requises (Pilier B)

Les stories 2.5 et 2.6 introduisent deux nouveaux types de documents. À valider avec l'équipe backend avant implémentation.

### 3.1 Fiche de lecture (`type: 'fiche'` dans `lessons`)

```
lessons/{lessonId}
  type: 'lesson' | 'fiche'   // champ discriminant (NOUVEAU)
  title: string
  content: string             // Markdown Firestore (existant)
  chapterId: string
  subjectId: string
  order: number
```

**Coût** : 1 read par fiche (même pattern que leçon). Pas de sous-collection supplémentaire.

### 3.2 Quiz (`quizzes/{quizId}`)

```
quizzes/{quizId}
  chapterId: string | null    // rattaché à un chapitre...
  lessonId: string | null     // ...ou à une leçon
  subjectId: string
  questions: [                // array ≤ 10 items (CLAUDE.md règle 10e)
    {
      text: string,
      type: 'mcq' | 'short',
      options: string[],      // null si type=short
      answer: string
    }
  ]
  order: number
```

**Coût** : 1 read par quiz. Pas de snapshot (statique). Index composite : `chapterId + order` et `lessonId + order`.

### 3.3 Exercice (`exercises/{exerciceId}`)

```
exercises/{exerciceId}
  subjectId: string
  type: 'sequence' | 'official' | 'blanc' | 'zero'
  year: number | null
  title: string
  content: string             // Markdown Firestore
  order: number
```

**Coût** : 1 read par exercice. Filtrage par `subjectId + type` (index composite requis).

> **⚠️ Avant Story 2.5/2.6** : ces schémas doivent être validés par l'équipe backend et ajoutés à `doc/partage/BASE-DE-DONNEES.md` (CLAUDE.md règle — toute modification du schéma Firestore passe par doc/partage/).

---

## 4. Nouveau plan de stories (ordre séquentiel)

```
Pilier A — Compte (vérification)
└── A.1 smoke-test-account-e2e     ← QA, pas de code

Pilier B — Contenu intégré
├── 2.4 content-integration        ← réouverture + fix bug revert
├── 2.5 fiches-de-lecture          ← nouveau type de contenu
└── 2.6 quiz-content-integration   ← QCM liés chapitres/leçons

Pilier C — Exercice
└── 3.1-mini exercise-module-basic ← énoncé + soumettre, sans IA

DÉFÉRÉ
├── E4 Paiement
├── E5 Gamification
└── E6 Mode 3 / Examen / Chat / Partage
```

**Timeline estimée** :
| Story | Effort estimé | Bloqué par |
|-------|--------------|-----------|
| A.1 smoke test | 0.5j (QA) | — |
| 2.4 réouverte | 1.5j | A.1 passé |
| 2.5 fiches de lecture | 2j | 2.4 done + schéma validé |
| 2.6 quiz liés | 2j | 2.5 done |
| 3.1-mini exercice | 2j | 2.6 done + schéma exercices validé |

**Total estimé Pilier B+C : ~8 jours développement**

---

## 5. Changements dans sprint-status.yaml

### Corrections d'état immédiates

```yaml
# Corrections statut (décalage code ↔ sprint-status)
2-2-subject-navigation-ui: done        # était in-progress, mergée commit 3769b6a
2-3-dashboard-home-ui: done            # valider UI porteur → done après approbation
2-4-content-integration: in-progress   # revert session 2026-06-24 → réouvrir

# Epics déférés explicitement
epic-3: deferred-partial               # seule 3.1-mini est pull forward
epic-4: deferred                       # décision réunion 2026-06-24
epic-5: deferred                       # décision réunion 2026-06-24
epic-6: deferred                       # décision réunion 2026-06-24

# Nouvelles stories à créer
A-1-smoke-test-account-e2e: backlog
2-5-fiches-de-lecture: backlog
2-6-quiz-content-integration: backlog
3-1-mini-exercise-module: backlog
```

---

## 6. Artefacts à mettre à jour

| Artefact | Modification requise | Responsable |
|----------|---------------------|-------------|
| `doc/partage/BASE-DE-DONNEES.md` | Ajouter collections `quizzes` + `exercises` + champ `type` sur `lessons` | Porteur + accord backend |
| `project_manage/planning-artifacts/epics.md` | Étendre Epic 2 + noter E4/E5/E6 déférés | Porteur |
| `firestore.indexes.json` | Indexes `quizzes` (chapterId+order, lessonId+order) + `exercises` (subjectId+type) | Dev (avant Story 2.6) |
| `sprint-status.yaml` | Corrections statuts ci-dessus | Dev (immédiat) |

---

## 7. Critères de succès (Definition of Done — Piliers A+B+C)

Un testeur peut, sur un device Android (compte neuf après suppression) :

1. **Pilier A** — Créer un compte (Google ou Apple), compléter le profil (filière → niveau → série → école optionnelle), atterrir sur le dashboard. Supprimer le compte depuis l'onglet Profil → revenir à l'onboarding proprement.

2. **Pilier B** — Naviguer vers une matière → voir les chapitres depuis Firestore → ouvrir un chapitre → lire une leçon (Markdown + LaTeX rendu par PedagogicalContent) → lire une fiche de lecture associée → faire un quiz lié au chapitre (QCM, voir le score).

3. **Pilier C** — Depuis l'onglet "S'entraîner", voir la liste des exercices classés par type, ouvrir un énoncé, le parcourir, le marquer comme fait.

---

## 8. Handoff

**Scope** : Major  
**Destinataires** :
- **Porteur (Delano)** : valider le schéma Firestore des nouvelles collections avec l'équipe backend ; valider l'UI Story 2.3 (HALT T13 actif) pour passer en `done`
- **Amelia (dev)** : mettre à jour sprint-status.yaml, créer les stories A.1 / 2.5 / 2.6 / 3.1-mini via `/bmad-create-story`, ré-implémenter Story 2.4 en corriger le bug revert
- **Paige (tech writer)** : mettre à jour `doc/partage/BASE-DE-DONNEES.md` avec les nouveaux schémas (après accord backend)

---

*Sprint Change Proposal approuvé le : ____________________*  
*Signature porteur : ____________________*
