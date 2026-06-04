# Guide de contribution — Valide School

> **Périmètre** : ce dépôt contient **uniquement l'application mobile Flutter** de Valide.
> **Public** : développeur mobile, designer/UX, PM, QA travaillant sur l'app mobile.
> **Statut** : document vivant. Toute évolution passe par une PR sur ce fichier, validée en revue.

---

## ⚠️ Important — Ce repo ne contient pas tout

Le projet Valide est composé de **quatre applications**, **chacune dans son propre dépôt**. Ce dépôt-ci contient **seulement** l'app mobile.

| Application | Dépôt | Stack |
|---|---|---|
| **App mobile** | **ce dépôt** | Flutter + Riverpod + Firebase |
| Backend (Cloud Functions) | autre dépôt | TypeScript + Cloud Functions 2nd gen + Node 22 |
| Console admin | autre dépôt | à définir |
| Site landing / vitrine | autre dépôt | à définir |

**La surface de partage entre ces 4 dépôts vit dans [`doc/partage/`](../partage/)** (cf. § 13). C'est le seul endroit où les équipes mobile / backend / admin / landing se croisent. Ce dossier est **co-maintenu** : toute modification de la base de données, d'un algorithme métier ou d'un contrat d'API doit être reflétée dans `doc/partage/` **dans la même PR** que le code qui la cause.

---

## Table des matières

1. [Bienvenue & vue d'ensemble](#1-bienvenue--vue-densemble)
2. [Avant de commencer — onboarding](#2-avant-de-commencer--onboarding)
3. [Structure du dépôt mobile](#3-structure-du-dépôt-mobile)
4. [Méthode de travail — BMAD](#4-méthode-de-travail--bmad)
5. [Workflow Git](#5-workflow-git)
6. [Conventions de code](#6-conventions-de-code)
7. [Revue de code](#7-revue-de-code)
8. [Tests](#8-tests)
9. [Definition of Done](#9-definition-of-done)
10. [Communication & rituels](#10-communication--rituels)
11. [Sécurité & gestion des secrets](#11-sécurité--gestion-des-secrets)
12. [Documentation](#12-documentation)
13. [Le dossier `doc/partage/` — surface partagée](#13-le-dossier-docpartage--surface-partagée)
14. [Anti-patterns à éviter](#14-anti-patterns-à-éviter)
15. [Outils requis & premier setup](#15-outils-requis--premier-setup)
16. [Que faire en cas de blocage](#16-que-faire-en-cas-de-blocage)
17. [Décisions ouvertes à trancher](#17-décisions-ouvertes-à-trancher)

---

## 1. Bienvenue & vue d'ensemble

**Valide School** est l'application mobile bilingue FR/EN pour les élèves du secondaire camerounais (BEPC, Probatoire, BAC, GCE O/A-Level).

**MVP** : 6 semaines, découpé en 6 phases hebdomadaires (cf. [Valide Decoupage MVP.md](../metier/Valide%20Decoupage%20MVP.md)).

**Trois contraintes marché qui guident toute décision** (ne sont pas négociables) :

- Téléphones modestes — perf et taille de l'app comptent
- Data limitée et coûteuse — compresser, ne rien recharger inutilement
- Connectivité instable — retry, cache, robustesse réseau

**Où trouver quoi**

| Tu cherches… | Va voir |
|---|---|
| Le périmètre et le découpage du MVP | [doc/metier/Valide Decoupage MVP.md](../metier/Valide%20Decoupage%20MVP.md) |
| L'architecture de l'app mobile | [doc/tech/Valide School App Architecture.md](../tech/Valide%20School%20App%20Architecture.md) |
| Les packages Flutter (et pourquoi) | [doc/tech/Valide School Package Architecture.md](../tech/Valide%20School%20Package%20Architecture.md) |
| Le Design System | [doc/tech/Valide - Design System.html](../tech/Valide%20-%20Design%20System.html) |
| Les maquettes d'écrans par module | [doc/tech/Valide - Design.html](../tech/Valide%20-%20Design.html) |
| L'architecture backend (référence) | [doc/tech/Valide Cloud Function Architecture.md](../tech/Valide%20Cloud%20Function%20Architecture.md) |
| **Schéma BDD, algorithmes, contrats API** | **[doc/partage/](../partage/)** |
| La méthode de pilotage (BMAD) | [doc/tools/BMAD_METHOD_GUIDE.md](BMAD_METHOD_GUIDE.md) |
| Ce guide | tu y es |

---

## 2. Avant de commencer — onboarding

Checklist à dérouler **dans cet ordre** lors de ton premier jour.

### 2.1 Lecture obligatoire (~2 h)

| Étape | Document |
|---|---|
| 1 | [Valide Decoupage MVP.md](../metier/Valide%20Decoupage%20MVP.md) — les 6 phases du MVP |
| 2 | [BMAD_METHOD_GUIDE.md](BMAD_METHOD_GUIDE.md) — sections 1 à 5 (philosophie, phases, agents) |
| 3 | [Mobile App Architecture.md](../tech/Valide%20School%20App%20Architecture.md) — entier, particulièrement sections 4 (règle d'or), 6-8 (couches), 19 (checklist de revue) |
| 4 | [Mobile Package Architecture.md](../tech/Valide%20School%20Package%20Architecture.md) — entier |
| 5 | [doc/partage/README.md](../partage/README.md) — comprendre la surface partagée |
| 6 | Ce guide en entier |

### 2.2 Setup local (cf. § 15)

Installer Flutter, Firebase CLI, BMAD. Cloner le repo. Lancer l'app en local. **Ne pas commencer à coder avant que le projet tourne sur ta machine.**

### 2.3 Première contribution (icebreaker)

Choisir un ticket étiqueté `good-first-issue` (typo dans la doc, petit refacto, ajout d'un test). Objectif : valider le workflow, pas livrer une feature.

### 2.4 Présentation à l'équipe

Lors du prochain rituel d'équipe (cf. § 10), te présenter en 2 min : qui tu es, sur quoi tu vas travailler, ce sur quoi tu veux qu'on t'aide en priorité.

---

## 3. Structure du dépôt mobile

```
Valide/
├── lib/                           # Code Flutter (cf. archi mobile § 14 pour le détail interne)
│   ├── main.dart
│   ├── core/                      # transversal (logging, error, theme, router, l10n, widgets génériques)
│   └── features/                  # features métier — chacune avec ses 3 couches
│       ├── auth/
│       ├── content/
│       ├── exercises/
│       ├── billing/
│       ├── academic_health/
│       ├── gamification/
│       ├── chat/
│       ├── notifications/
│       └── sharing/
├── test/                          # Tests (mirroir de lib/)
├── integration_test/              # Tests E2E (si applicable)
├── android/                       # Config Android
├── ios/                           # Config iOS
├── assets/                        # Images, fonts, lottie, l10n ARB
├── pubspec.yaml
│
├── doc/
│   ├── metier/                    # Specs produit
│   ├── tech/                      # Specs techniques mobile + référence backend
│   ├── tools/                     # Méthode, ce guide
│   └── partage/                   # ⚠ surface partagée avec admin / backend / landing
│
├── _bmad/                         # Installation BMAD (cf. BMAD guide)
├── project_manage/                  # Artefacts BMAD générés (PRD, archi, stories…)
│
├── .github/                       # Templates PR, issues, CI/CD
│   ├── PULL_REQUEST_TEMPLATE.md
│   ├── ISSUE_TEMPLATE/
│   └── workflows/
│
├── .gitignore
├── analysis_options.yaml
├── README.md
└── doc/tools/CONTRIBUTING.md      # ce fichier
```

Le détail de la structure interne de `lib/` (couches `domain` / `data` / `presentation`, contenu de `core/`, gabarit par feature) est dans la section 14 du [Mobile App Architecture](../tech/Valide%20School%20App%20Architecture.md). **Ne pas dupliquer ici.**

---

## 4. Méthode de travail — BMAD

Le projet est piloté avec la **méthode BMAD v6.8.0**. Toute story passe par le pipeline :

```
SPEC (bmad-spec)
   ↓
PRD (bmad-prd) + UX (bmad-ux → DESIGN.md + EXPERIENCE.md)
   ↓
Architecture (bmad-create-architecture)
   ↓
Epics + Stories (bmad-create-epics-and-stories)
   ↓
Sprint Planning (bmad-sprint-planning) → sprint-status.yaml
   ↓
Pour chaque story :
   bmad-create-story → story-{slug}.md
   bmad-dev-story → code + tests
   bmad-code-review → revue adversariale
```

### Règles d'or

1. **Le fichier story est la seule source de vérité pour le dev.** Tu n'implémentes que ce qui est dans la story, dans l'ordre des tâches. Pas de bonus, pas de refacto autour. Si tu vois une amélioration : tu crées un ticket pour une story future, **tu ne la fais pas maintenant**.
2. **Une décision se trace.** Décisions techniques → ADR dans `project_manage/planning-artifacts/adrs/`. Décisions produit / UX → `.decision-log.md` à côté du livrable de la skill.
3. **Pas de Quick Flow sur une feature à plusieurs composants.** `/bmad-quick-dev` = bugfix, petit refacto, micro-feature qui tient dans la tête d'une personne. Une feature qui implique aussi le backend → pipeline complet.
4. **Investigation forensique avant patch.** Bug mystérieux ? Lance `/bmad-investigate` (preuves graduées Confirmed / Deduced / Hypothesized). Patche seulement les `Confirmed`.
5. **Conventions dans `project-context.md`.** Avant d'écrire du code, vérifie que `project_manage/project-context.md` existe et est à jour. Sinon : `/bmad-generate-project-context`.

> Détails : [BMAD_METHOD_GUIDE.md](BMAD_METHOD_GUIDE.md).

---

## 5. Workflow Git

### 5.1 Branche principale

- `main` est la branche **stable**, protégée : aucun push direct, uniquement via PR mergée.
- `main` est toujours déployable. Si une PR casse `main`, revert d'abord, fix ensuite.

### 5.2 Stratégie : GitHub Flow

```
main ←─── PR ←─── feature/auth-google-login
main ←─── PR ←─── fix/quiz-score-rounding
main ←─── PR ←─── chore/upgrade-flutter-3.27
```

### 5.3 Nommage des branches

Format : `<type>/<slug-court-en-anglais>`

| Type | Quand |
|---|---|
| `feature/` | Nouvelle fonctionnalité utilisateur (story BMAD) |
| `fix/` | Correction de bug |
| `chore/` | Tâche technique sans impact utilisateur (upgrade dep, refacto, CI) |
| `docs/` | Modifications de documentation uniquement |
| `test/` | Ajout ou correction de tests sans changement de code de prod |
| `experiment/` | Spike / preuve de concept |

Exemples : `feature/exercise-mode-semi-assisted`, `fix/firestore-cache-stale`, `chore/upgrade-firebase-12`.

Règles : kebab-case, anglais, ≤ 50 caractères.

### 5.4 Commits — Conventional Commits

Format :

```
<type>(<scope>): <description courte en français, impératif présent>

<corps optionnel — pourquoi, pas quoi>

<footer optionnel — refs>
```

| Type | Description |
|---|---|
| `feat` | Nouvelle fonctionnalité |
| `fix` | Correction de bug |
| `refactor` | Refacto sans changement de comportement |
| `perf` | Amélioration de performance |
| `test` | Ajout / modification de tests |
| `docs` | Documentation uniquement |
| `chore` | Tâche technique (deps, CI, outillage) |
| `style` | Formatage, lint (pas de changement de logique) |

**Scope** : `auth`, `exercises`, `billing`, `content`, `health`, `gamification`, `chat`, `notifications`, `sharing`, `core`, `docs`, `partage`, `ci`.

Exemple :

```
feat(exercises): ajouter le Mode 2 « Semi-assisté » avec étapes et indices

Implémente le découpage en étapes, la révélation progressive
d'indices (max 3) et la consultation du cours associé.
Le verrou premium et le débit de crédits seront branchés en Phase 4.

Refs: story-3-2-mode-2-semi-assisted
```

Règles :
- Description en **français**, à l'**impératif présent**, **sans point final**.
- Un commit = une intention atomique.
- Les commits de bruit (« wip », « fix typo », « oups ») sont squashés avant la PR.

### 5.5 Pull Requests

**Taille cible** : ≤ 400 lignes de diff (hors fichiers générés et lock).

**Template** (`.github/PULL_REQUEST_TEMPLATE.md`, à créer) :

```markdown
## Quoi
<résumé en 2-3 phrases — pas un copier-coller du commit>

## Pourquoi
<lien vers la story BMAD / l'issue / l'ADR>

## Impact sur doc/partage/
- [ ] Aucun
- [ ] Oui — j'ai mis à jour le(s) fichier(s) concerné(s) dans la même PR :
  - [ ] doc/partage/BASE-DE-DONNEES.md
  - [ ] doc/partage/ALGORITHMES.md
  - [ ] doc/partage/CONTRATS-API.md
  - [ ] doc/partage/DONNEES-REFERENCE.md

## Comment tester
- [ ] Étape 1
- [ ] Étape 2

## Captures (si UI)
<screenshots ou GIF>

## Checklist auteur
- [ ] Tests ajoutés ou mis à jour (cf. § 8)
- [ ] Documentation à jour si l'API publique a changé
- [ ] Logs ajoutés sur les opérations sensibles (cf. archi mobile § 11)
- [ ] Pas de secret commit (clé, token, PIN)
- [ ] Pas de print() oublié
- [ ] Story / issue référencée
```

**Cycle de vie** :

1. **Draft** — tu pousses, ouvres la PR en draft, la CI tourne.
2. **Ready for review** — tu sors du draft, ajoutes les reviewers (au moins 1).
3. **Review** — itération sur les commentaires. Tu corriges, le reviewer marque `Resolved`.
4. **Approved** — 1 ou 2 approbations selon la zone (cf. § 7).
5. **Merge** — squash & merge par défaut. Le titre de la PR devient le message du commit final (Conventional Commits).

### 5.6 Avant d'ouvrir une PR

```powershell
flutter analyze
flutter test
dart format --set-exit-if-changed lib/ test/

git log --oneline origin/main..HEAD     # vérifier la liste de commits
git rebase -i origin/main               # squash si nécessaire
```

Si ta branche a plus d'une journée : **rebase** sur `main` à jour (pas de merge dans la branche, préférer le rebase).

---

## 6. Conventions de code

**Source unique de vérité** : [Mobile App Architecture.md](../tech/Valide%20School%20App%20Architecture.md), particulièrement les sections 4 (règle d'or des dépendances), 6-8 (couches), 19 (checklist de revue).

### 6.1 Règles non négociables (rappel)

- Le `domain` n'importe **jamais** Flutter, Firebase, Dio, Riverpod, ni `logger`. Dart pur.
- La traduction `Exception → Failure` se fait uniquement dans les repository impls.
- `package:logger` n'est importé que dans `core/logging/app_logger.dart`.
- `flutter_smooth_markdown` n'est importé que dans `core/widgets/pedagogical_content.dart`.
- Le mutable (abonnement / crédits / santé / points) s'obtient par **stream** ; le statique par lecture standard.
- Toute opération réseau, décision d'accès, paiement, appel IA, et erreur attrapée **produit un log**.
- Les models ne sortent jamais de `data/` (`toEntity()` à la frontière).
- Pas de pixels en dur dans les widgets : utiliser `flutter_screenutil` (`.w` / `.h` / `.sp` / `.r`).
- Toute consommation d'une Cloud Function passe par un datasource, **avec le contrat documenté dans [doc/partage/CONTRATS-API.md](../partage/CONTRATS-API.md)**. Si tu inventes ou modifies un contrat côté mobile sans synchroniser cette doc et l'équipe backend, c'est un bug de revue.

### 6.2 Linter & formatage

- **Linter** : `analysis_options.yaml` à la racine, avec `flutter_lints` + `riverpod_lint` + `custom_lint`. Tout warning = corriger avant merge.
- **Formatage** : `dart format`.

### 6.3 Conventions transverses

- **Langue du code** : identifiers (variables, fonctions, classes, types, fichiers) **en anglais**.
- **Langue de la doc / commentaires** : **français**.
- **Pas de commentaires WHAT** — uniquement WHY non évident.
- **Pas de TODO / FIXME** sans lien vers une issue.
- **Pas de code mort** — Git garde l'historique.
- **Pas de magic numbers** — constantes nommées dans `core/theme/tokens.dart` ou config de feature.
- **Pas d'accès Firestore direct** depuis la couche `presentation/` — toujours via un datasource.

---

## 7. Revue de code

### 7.1 Principe : revue adversariale

Issu de BMAD (cf. [BMAD § 11](BMAD_METHOD_GUIDE.md#11-revue-adversariale)). **Le reviewer doit trouver des problèmes.** « Ça a l'air bien » est interdit.

Pour chaque PR, le reviewer cherche au minimum :
- 1 problème de correction (bug, oubli, mauvaise gestion d'erreur)
- 1 problème de robustesse (cas limite, race condition, état réseau)
- 1 amélioration possible (clarté, perf, simplification)

Si rien trouvé après une lecture sérieuse, le reviewer le dit explicitement.

### 7.2 Qui review quoi

| Zone du code | Reviewers requis |
|---|---|
| Feature standard (touche 1 feature) | 1 dev mobile |
| Touche `core/`, `domain/` cross-feature, ou archi | 2 reviewers dont 1 senior mobile |
| Touche un contrat Cloud Function (datasource appelant une Function) | 1 dev mobile + 1 dev backend (cross-repo, par sync écrite) |
| Touche `doc/partage/` | 1 dev mobile + relecture de l'équipe consommatrice (admin, backend, ou landing selon le fichier) |
| `doc/` (hors partage) | 1 reviewer |
| `.github/workflows/` (CI/CD) | 1 reviewer + accord d'un mainteneur |

### 7.3 Checklist de revue (à reprendre dans le PR template)

**Couches & dépendances**
- [ ] Le `domain` n'importe ni Flutter, ni Firebase, ni Dio, ni Riverpod, ni `logger`
- [ ] `Exception → Failure` uniquement dans un repository impl
- [ ] Les models ne sortent pas de `data/` (`toEntity()` à la frontière)
- [ ] Le provider du repository expose le **contrat**, fournit l'**impl**

**Logging**
- [ ] `package:logger` n'apparaît que dans `app_logger.dart`
- [ ] Toute opération réseau / décision d'accès / paiement / appel IA est loggée
- [ ] Toute erreur attrapée est loggée avec error + stackTrace
- [ ] Aucune donnée sensible (PIN, jeton, mot de passe, n° complet) n'est loggée

**Cache & données**
- [ ] Le mutable est un Stream, pas une lecture figée
- [ ] Aucun système de cache custom n'a été ajouté

**UI**
- [ ] Pas de couleur ou taille en dur (tokens via Design System / `flutter_screenutil`)
- [ ] États gérés (loading / error / empty / success)
- [ ] Testé sur au moins 2 gabarits d'écran (petit + standard)
- [ ] Testé en français ET en anglais si la feature touche du texte localisé

**Surface partagée**
- [ ] Si la PR touche un contrat backend ou une donnée Firestore : `doc/partage/` mis à jour dans la même PR
- [ ] Si la PR introduit un nouvel algorithme métier : ajouté à `doc/partage/ALGORITHMES.md`
- [ ] Aucune divergence introduite entre le code mobile et `doc/partage/`

**Tests**
- [ ] Les nouveaux use cases ont des tests de domaine (cas succès + cas échec)
- [ ] Repository impls : test de traduction `Exception → Failure`
- [ ] Si la PR corrige un bug : test de non-régression

### 7.4 Délais

- Première revue sous **24 h ouvrées**. Sinon, l'auteur peut taguer un autre reviewer.
- Réponse de l'auteur aux modifs demandées sous **48 h ouvrées**. Sinon la PR est marquée stale.
- **Pas d'auto-merge.** Le merge est manuel après approbations.

---

## 8. Tests

Voir [Mobile App Architecture.md § 18](../tech/Valide%20School%20App%20Architecture.md).

| Type | Quand | Outils |
|---|---|---|
| **Tests de domaine** | Pour chaque use case et entité non triviale | `flutter_test` + `mocktail` |
| **Tests de data** | Pour chaque repository impl (vérifier `Exception → Failure`) | `flutter_test` + `mocktail` |
| **Tests de presentation** | Pour les notifiers complexes (transitions d'état) | `flutter_test` + override Riverpod |
| **Tests de widgets** | Pour les widgets vraiment complexes uniquement | `flutter_test` |
| **Tests E2E** | À la fin de chaque phase MVP, parcours critiques | À décider (`integration_test` ou Patrol — cf. § 17) |

### Règles

- **Toute logique métier nouvelle** doit avoir des tests (cas succès + au moins un cas d'échec).
- **Tout bug corrigé** doit être accompagné d'un test de non-régression (échoue sans le fix, passe avec).
- **Pas de PR sans test** sauf cas trivial (rename, doc, dep bump).
- Pas de seuil chiffré de couverture (métrique gamable). En revanche, les use cases sans test passent en revue défavorable.

### Ce qu'on ne teste pas

Code généré (`*.g.dart`, `*.freezed.dart`), SDK tiers, widgets de pur affichage.

---

## 9. Definition of Done

Une story / PR est **terminée** quand **toutes** ces cases sont cochées :

- [ ] Le code implémente toutes les tâches de la story (et **rien de plus**)
- [ ] Tous les critères d'acceptation (Given/When/Then) sont validés manuellement
- [ ] Tests unitaires écrits et passants
- [ ] Tests d'intégration / E2E passants (si applicables)
- [ ] Pas de warning lint
- [ ] Pas de TODO / FIXME sans issue liée
- [ ] Logs ajoutés sur les opérations sensibles
- [ ] Pas de secret committé
- [ ] PR passée en revue et approuvée selon § 7.2
- [ ] CI verte
- [ ] **`doc/partage/` à jour si la PR a un impact croisé**
- [ ] Documentation à jour si le setup a changé
- [ ] Testé sur un **vrai téléphone**
- [ ] Testé en **français ET anglais** (pour toute UI bilingue)
- [ ] Testé en **connexion lente / coupée** (pour tout flux réseau)
- [ ] Mergé sur `main` et story marquée terminée dans `sprint-status.yaml`

---

## 10. Communication & rituels

### 10.1 Canal d'équipe

À décider — cf. § 17. Sous-canaux suggérés :

- `#general` — discussions générales, annonces
- `#mobile` — questions et discussions app mobile (ce dépôt)
- `#partage` — coordination avec backend / admin / landing autour de `doc/partage/`
- `#design` — design, UX, Design System
- `#produit` — discussions PM / scope / priorisation
- `#review-requests` — pinger les PRs en attente
- `#incidents` — production / bugs critiques

### 10.2 Rituels

| Rituel | Fréquence | Durée | Objectif |
|---|---|---|---|
| **Daily standup** | Quotidien (matin) | 10 min | Bloqueurs, qui fait quoi aujourd'hui |
| **Sprint planning** | Début de phase | 1 h | `/bmad-sprint-planning` |
| **Demo + Retro** | Fin de phase | 1 h | Tester ensemble + retrospective |
| **Sync archi cross-équipes** | Hebdomadaire | 30 min | Décisions impactant `doc/partage/` (backend, admin, landing présents) |
| **Office hours** | 2 × par semaine | 1 h | Aide ouverte, mob programming, design review |

### 10.3 Décisions

- **Décision technique impactant plusieurs équipes** → ADR rédigé, revue en sync archi cross-équipes, mergé après accord écrit.
- **Décision produit / scope** → tracée dans `.decision-log.md` du livrable concerné, validée par le PM.
- **Décision urgente** → l'auteur décide, documente immédiatement, présente à la prochaine sync.

### 10.4 Ce qui n'est PAS un canal de décision

DM privés, vocal sans CR écrit, conversation en présentiel non notée. Une décision qui n'est pas par écrit dans un ADR ou `.decision-log.md` n'existe pas.

---

## 11. Sécurité & gestion des secrets

### 11.1 Règles absolues

1. **Aucun secret dans le code source.** Clés API, ID Firebase, secrets de signature — jamais.
2. **Aucun secret dans les commits, même supprimés ensuite.** Un secret committé = compromis, à rotater.
3. **Aucun secret dans les logs.**
4. **Aucun secret dans les screenshots partagés.**

### 11.2 Où vivent les secrets

| Secret | Stockage | Comment y accéder |
|---|---|---|
| `google-services.json` (Android) | gitignored, partagé via canal sécurisé d'équipe | placé manuellement dans `android/app/` |
| `GoogleService-Info.plist` (iOS) | gitignored, partagé via canal sécurisé d'équipe | placé manuellement dans `ios/Runner/` |
| Identifiants signature Android (keystore) | gitignored, partagé via canal sécurisé | `android/key.properties` |
| Variables d'environnement de build | `.env.local` (gitignored), exemple dans `.env.example` | via tool de build |

**Important** : la clé Claude API et les secrets de signature des agrégateurs Mobile Money vivent **uniquement** côté backend (Cloud Functions). L'app mobile **ne doit jamais** les manipuler.

### 11.3 `.gitignore` impératif

```
# Secrets
.env
.env.*
!.env.example
**/google-services.json
**/GoogleService-Info.plist
**/key.properties
**/*.keystore
**/*.jks
**/*.pem
**/*.key

# Builds
build/
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
ios/Pods/

# IDE
.idea/
.vscode/
*.iml

# OS
.DS_Store
Thumbs.db

# BMAD
_bmad/_config/   # config locale spécifique utilisateur
```

### 11.4 Si un secret a fuité

1. **Rotater immédiatement** le secret (Firebase, Anthropic, agrégateur, signature Android).
2. **Révoquer** l'ancien.
3. **Alerter** l'équipe sur `#incidents`.
4. Nettoyer l'historique Git uniquement si pertinent (la rotation est prioritaire).

### 11.5 Règles Firestore — deploy et tests locaux (Story 0.9)

Les règles Firestore vivent à la **racine du dépôt** (`firestore.rules`, `firestore.indexes.json`, `firebase.json`, `.firebaserc`) car elles sont déployées via `firebase deploy` indépendamment du build Flutter.

**Déployer les règles** sur le projet Firebase :

```bash
firebase deploy --only firestore:rules --project=valide-edu
```

**Tester les règles en local** (avant push) :

```bash
# Terminal 1 — émulateur Firestore + Auth
firebase emulators:start --only firestore,auth

# Terminal 2 — tests unitaires des règles
cd test/rules
npm install   # première fois seulement
npm test
```

Ou en une seule commande depuis la racine :

```bash
firebase emulators:exec --only firestore,auth "cd test/rules && npm test"
```

**Quand ajouter / modifier une règle** :

1. Modifier `firestore.rules` à la racine.
2. Ajouter ou modifier les tests dans `test/rules/*.test.mjs`.
3. Lancer `npm test` en local — tout doit passer.
4. Mettre à jour `doc/partage/BASE-DE-DONNEES.md` § règles d'accès si le contrat change (et obtenir l'accord backend, cf. § 13).
5. Commit + PR.
6. Après merge, déployer manuellement avec `firebase deploy --only firestore:rules`.

---

## 12. Documentation

### Principes

- **Une seule source de vérité par sujet.** Si une info est dupliquée entre deux docs, c'est un bug à corriger.
- **La doc est du code.** Elle vit dans le repo, suit le workflow PR / review, est versionnée avec la fonctionnalité.
- **Pas de doc générée à part.** Pas de wiki externe désynchronisé.

### Quand mettre à jour quoi

| Tu changes… | Mettre à jour |
|---|---|
| Le schéma de données Firestore | `doc/partage/BASE-DE-DONNEES.md` |
| Un algorithme métier (score, santé, points, idempotence…) | `doc/partage/ALGORITHMES.md` |
| Une consommation de Cloud Function | `doc/partage/CONTRATS-API.md` (en accord avec l'équipe backend) |
| Une donnée de référence (filière, série, matières) | `doc/partage/DONNEES-REFERENCE.md` |
| Le pattern d'une couche mobile | Section concernée de [Mobile App Architecture](../tech/Valide%20School%20App%20Architecture.md) |
| Une dépendance Flutter | [Mobile Package Architecture](../tech/Valide%20School%20Package%20Architecture.md) |
| Une convention transversale | Ce guide |
| Une décision technique non triviale | Un ADR dans `project_manage/planning-artifacts/adrs/` |
| Une décision produit / scope | Le `.decision-log.md` du livrable concerné |
| Le périmètre du MVP | `doc/metier/Valide Decoupage MVP.md` (avec validation PM) |

---

## 13. Le dossier `doc/partage/` — surface partagée

**C'est la seule surface où l'app mobile, le backend, l'admin et la landing se croisent.**

Le dossier vit dans **ce dépôt** mais ses fichiers sont **co-maintenus** par les équipes mobile et backend, et **consommés** par les équipes admin et landing.

```
doc/partage/
├── README.md                  # mode d'emploi, règles de mise à jour
├── BASE-DE-DONNEES.md         # schéma Firestore (collections, champs, indexes)
├── ALGORITHMES.md             # algorithmes métier (score, santé, points, idempotence…)
├── CONTRATS-API.md            # contrats des Cloud Functions (in/out, codes d'erreur)
└── DONNEES-REFERENCE.md       # matrices de référence (filière, série, matières, examens)
```

### Règles de maintenance

1. **Toute PR qui touche le schéma Firestore, un algorithme ou un contrat MUST mettre à jour `doc/partage/` dans la même PR.** Pas de PR « code maintenant, doc plus tard ». La doc est dans le diff.
2. **Toute modification d'un contrat backend doit être validée par l'équipe backend** avant merge (les contrats sont à deux sens). La validation est écrite dans la PR (commentaire d'un mainteneur backend).
3. **Toute modification du schéma Firestore doit être validée par l'équipe backend** (qui gère les règles de sécurité).
4. **Toute modification d'un algorithme central (idempotence, transaction, premium gate) doit être validée par l'équipe backend** (la logique vit côté serveur, mais le mobile en dépend).
5. **L'équipe admin et l'équipe landing consomment, ne modifient pas.** Si elles découvrent un écart entre la doc et la réalité, elles ouvrent une issue dans ce dépôt.
6. **Lecture obligatoire** : chaque membre de l'équipe mobile lit `doc/partage/` lors de l'onboarding.

### Comment proposer une modification

- Si tu travailles côté mobile et tu introduis une nouvelle donnée Firestore → PR qui modifie le code mobile + `BASE-DE-DONNEES.md` + validation backend.
- Si tu travailles côté backend (autre dépôt) et tu changes un contrat → PR dans **ce dépôt** sur `CONTRATS-API.md` (avant la PR backend), pour aligner l'équipe mobile.
- Si tu travailles côté admin / landing (autre dépôt) et tu remarques une divergence → issue dans **ce dépôt** avec le détail.

> Détail du contenu attendu de chaque fichier : voir [doc/partage/README.md](../partage/README.md).

---

## 14. Anti-patterns à éviter

### 14.1 Transverses

- **Vibe coding sans BMAD.** Sauter le pipeline crée des décisions contradictoires entre composants.
- **Refactorer une zone non liée à la story.** Hors scope. Crée un ticket, fais-le dans une PR dédiée.
- **Réinventer ce qui existe déjà dans `core/`.** Avant de créer un utilitaire, chercher.
- **Ignorer un test rouge en disant « ça marche en local ».** CI rouge = bloqué.
- **PR géante en fin de sprint.** Mieux vaut une PR partielle mergée que 2000 lignes en attente.
- **Bypasser un hook pre-commit / pre-push avec `--no-verify`.** Le hook a une raison. Si le hook est faux, on fixe le hook.

### 14.2 Mobile

- Importer `cloud_firestore` dans `domain/` ou `presentation/`. **Toujours via un datasource.**
- Cacher manuellement des données mutables. Le cache Firestore suffit (cf. archi § 12).
- Pixels en dur dans un widget. Utiliser `flutter_screenutil` et les tokens du Design System.
- Laisser une exception remonter à l'écran. Tout passe par `Either<Failure, T>`.
- Logger une donnée sensible.
- Appeler une Cloud Function sans documenter le contrat dans `doc/partage/CONTRATS-API.md`.
- Inventer un format de document Firestore sans le déclarer dans `doc/partage/BASE-DE-DONNEES.md`.

### 14.3 Git

- Force-push sur `main`. **Jamais.**
- Merge commits dans une feature branch. Préférer le rebase.
- Commits non significatifs dans `main` (« wip », « fix »). Squash avant la PR.
- PR sans description ou avec description « update stuff ».

---

## 15. Outils requis & premier setup

### 15.1 Outils

| Outil | Version min | Pour quoi |
|---|---|---|
| Git | 2.40+ | Versioning |
| Flutter | **À aligner** (proposition : 3.27+) | Dev mobile |
| Dart | livré avec Flutter | — |
| Node.js | 22.x (LTS) | Outillage (BMAD, scripts) |
| Firebase CLI | 13+ | Émulateurs, déploiement |
| Java JDK | 17+ | Émulateur Firestore (Java requis) |
| Android Studio | dernière stable | SDK Android, émulateur |
| Xcode (macOS) | dernière stable | Build iOS, simulateur |
| BMAD | v6.8.x | Méthode de pilotage |
| IDE compatible BMAD | — | Claude Code (recommandé), Cursor, Windsurf, Kiro, GitHub Copilot |
| Un vrai téléphone Android entrée de gamme | — | Tester en conditions réelles |

### 15.2 Setup pas à pas

```powershell
# 1. Cloner
git clone <repo-url> Valide
cd Valide

# 2. Installer BMAD (à la racine du repo)
npx bmad-method install
# → module bmm, IDE claude-code, langue French

# 3. Récupérer les fichiers de config Firebase (canal sécurisé d'équipe)
# Placer manuellement :
# - android/app/google-services.json
# - ios/Runner/GoogleService-Info.plist
# - android/key.properties (si signature)

# 4. Installer les dépendances Flutter
flutter pub get

# 5. Vérifier que tout est OK
flutter doctor
flutter analyze
flutter test

# 6. Lancer l'app sur un émulateur ou device
flutter run

# 7. Première story BMAD (dans l'IDE Claude Code)
/bmad-create-story
```

Si une étape échoue : voir § 16.

---

## 16. Que faire en cas de blocage

### 16.1 Tu ne comprends pas une story

1. Relis le fichier story complet (Contexte, Tâches, Critères d'acceptation, Références).
2. Lis le PRD section référencée et `.decision-log.md` correspondant.
3. Si flou : pose la question en standup ou dans `#mobile`.
4. **Ne commence pas à coder « à peu près ».**

### 16.2 Un bug que tu ne comprends pas

1. **Ne pars pas en hypothèses.** Lance `/bmad-investigate`.
2. Patche seulement les `Confirmed`. Pour les `Hypothesized` : sous-ticket et continue l'investigation.
3. Bloqué > 2 h : escalade en pair programming.

### 16.3 Ton setup ne marche pas

1. Relire le README et ce guide § 15.
2. Vérifier les versions (`flutter --version`, `node --version`, `java -version`).
3. Vérifier les fichiers de config Firebase et la signature.
4. Si toujours bloqué : `#mobile` avec le message d'erreur complet.

### 16.4 CI casse sans raison apparente

1. Relire les logs CI complets (pas juste la ligne rouge — le contexte autour).
2. `git pull origin main && git rebase main` pour t'assurer d'être à jour.
3. Reproduire localement.
4. Si opaque : `#mobile` avec lien vers le run CI.

### 16.5 Désaccord avec une revue

C'est normal. La revue est une **discussion**, pas un jugement.

1. Réponds au commentaire avec ton argument.
2. Si le désaccord persiste : demande un 3ᵉ avis.
3. Si toujours pas tranché : escalade au lead mobile.
4. **Ne merge pas une PR avec désaccord ouvert.**

### 16.6 Tu vois un écart entre la réalité (code) et `doc/partage/`

1. **N'écris pas de code par-dessus la doc** sans avoir clarifié. La doc est le contrat.
2. Ouvre une issue avec : le fichier de partage concerné, la réalité observée, l'écart.
3. Trancher en sync archi cross-équipes (cf. § 10.2).
4. Mettre à jour la doc OU le code (selon ce qui est correct) dans une PR dédiée.

---

## 17. Décisions ouvertes à trancher

Ces points ne sont pas encore tranchés. À régler au kickoff. Mettre à jour ce guide après tranchage.

| # | Décision | Options | Pourquoi c'est important |
|---|---|---|---|
| 1 | **Hébergement repo** | GitHub (cohérent avec BMAD/Claude Code) ; GitLab ; Bitbucket | Affecte CI/CD et terminologie PR/MR |
| 2 | **Canal d'équipe** | Discord ; Slack ; Teams | Productivité quotidienne |
| 3 | **Outil de gestion projet** | GitHub Issues/Projects ; Linear ; Jira ; Notion | Tracking sprint + intégration BMAD |
| 4 | **Version exacte Flutter / Dart** | À aligner sur LTS au démarrage | Évite la divergence entre machines |
| 5 | **Outil de monitoring prod** | Firebase Crashlytics + Cloud Logging ; Sentry ; Datadog | Diagnostic d'incidents |
| 6 | **CI/CD mobile** | GitHub Actions ; CircleCI ; Codemagic ; Bitrise | Coût, délais de build, signature |
| 7 | **Région Firebase** | `europe-west1` (proposition archi backend) ; à confirmer après mesure latence Cameroun | Latence utilisateur |
| 8 | **Framework E2E** | `integration_test` Flutter ; Patrol | Robustesse des tests E2E |
| 9 | ~~Présence agents Bob / Barry après install BMAD v6.8~~ | ✅ **Tranchée le 2026-06-03** : Bob, Barry et Quinn ne sont **pas** des agents distincts en v6.8.0. Roster officiel = Mary, John, Winston, Amelia, Sally, Paige (6 agents). Leurs skills (`bmad-sprint-planning`, `bmad-create-story`, `bmad-quick-dev`, `bmad-qa-generate-e2e-tests`, etc.) sont invocables directement sans agent. | — |
| 10 | **Protocole de sync `doc/partage/` avec les autres dépôts** | Pull request croisée + lien dans le commentaire ; calendrier de revue mensuel | Évite que `doc/partage/` dérive de la réalité |

---

## Annexe — Glossaire spécifique au projet

| Terme | Définition |
|---|---|
| **Mode 1 « Je maîtrise »** | L'élève travaille seul puis soumet pour correction IA (texte ou photo) — coûte des crédits |
| **Mode 2 « Semi-assisté »** | Exercice découpé en étapes avec 3 indices max — réservé premium |
| **Mode 3 « Assisté »** | Tuteur IA pas à pas — coûte des crédits par session |
| **Santé scolaire** | Niveau de l'élève par notion, mis à jour à chaque activité |
| **Sous-système** | « Francophone » ou « Anglophone », fixe la langue pour toute l'app |
| **Filière** | Générale ou Technique |
| **Notion** | Plus petite unité de contenu — un exercice évalue 1+ notions |
| **Crédits** | Monnaie interne pour les actions IA payantes |
| **Premium** | Abonnement débloquant Mode 2, mode examen, fiches, chat ×20 |
| **MoMo / OM** | MTN Mobile Money / Orange Money |
| **Agrégateur** | Tranzak / Campay / MyCoolPay (passerelle paiement Mobile Money) |
| **Webhook** | Notification serveur entrante de l'agrégateur après paiement (côté backend uniquement) |
| **App Check** | Mécanisme Firebase qui atteste qu'une requête vient de l'app authentique |
| **`.decision-log.md`** | Journal des décisions produit/UX par skill BMAD (cf. BMAD § 12.4) |
| **ADR** | Architecture Decision Record — décision technique structurée |
| **Surface partagée** | Le contenu de `doc/partage/` — la frontière de connaissance entre les 4 équipes |

---

*Document maintenu par l'équipe mobile. Toute modification se fait par PR sur ce fichier.*
