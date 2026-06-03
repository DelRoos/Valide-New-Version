# Guide Complet de la Méthode BMAD

> **Version de référence — BMAD v6.8.0 (25 mai 2026)** | Documentation officielle : https://docs.bmad-method.org/
>
> ⚠️ **Évolutions majeures depuis v6.0 à connaître** (détaillées dans le doc) :
> - **Skills Architecture** : « workflows » est remplacé par « skills ». Préfixe des commandes simplifié `/bmad-bmm-X` → `/bmad-X` (le namespace `bmm` disparaît des commandes utilisateur). Les commandes des agents passent de `/bmad-agent-bmm-X` à `/bmad-agent-X`.
> - **Skills installées dans `.claude/skills/`** (et non plus `.claude/commands/`).
> - **`bmad-ux`** remplace `bmad-create-ux-design` et produit **deux fichiers** : `DESIGN.md` (tokens visuels) + `EXPERIENCE.md` (comportement, flux, IA, états, a11y) — modèle « two-spine contract ».
> - **`bmad-spec`** (nouveau) remplace `bmad-distillator` : distille un brain-dump / transcript / brief en `SPEC.md` avec un noyau à 5 champs (Problem, Capabilities, Constraints, Non-goals, Success signal).
> - **`bmad-investigate`** (nouveau) : skill forensique pour debug / RCA / exploration de code inconnu, avec preuves graduées `Confirmed / Deduced / Hypothesized`.
> - **`bmad-prd` et `bmad-product-brief`** : trois intents `Create` / `Update` / `Validate` + deux modes `Fast` / `Coaching`.
> - **`.decision-log.md`** : nouveau pattern de journal de décisions produit par plusieurs skills, qui complète (et souvent supplante) les ADR éparpillés.
> - **Recherche éclatée** : `bmad-domain-research`, `bmad-market-research`, `bmad-technical-research`.
> - **Nouvelle skill `bmad-prfaq`** (Working Backwards façon Amazon) en Phase 1.
> - **Quick Flow unifié** : la skill `bmad-quick-dev` couvre maintenant clarification + plan + implémentation + revue + présentation en une commande (l'ancien `bmad-quick-spec` séparé n'existe plus comme commande utilisateur).
> - **19 techniques d'élicitation** (au lieu de 8) regroupées en catégories.
> - **Manifests** : colonnes / clés JSON `after`/`before` renommées `preceded-by`/`followed-by`.
> - **Web Bundles v1.0** : exécution hors-IDE (Gemini Gems, ChatGPT) avec parité de schéma.

---

## Table des Matières

1. [Introduction et Philosophie](#1-introduction-et-philosophie)
2. [Concepts Fondamentaux](#2-concepts-fondamentaux)
3. [Installation](#3-installation)
4. [Architecture du Système](#4-architecture-du-système)
5. [Les Quatre Phases du Développement](#5-les-quatre-phases-du-développement)
6. [Quick Flow — La Piste Rapide](#6-quick-flow--la-piste-rapide)
7. [Les Agents — Vos Collaborateurs IA](#7-les-agents--vos-collaborateurs-ia)
8. [Les Workflows Détaillés](#8-les-workflows-détaillés)
9. [Les Commandes Slash](#9-les-commandes-slash)
10. [Party Mode — L'Équipe Complète dans une Salle](#10-party-mode--léquipe-complète-dans-une-salle)
11. [Revue Adversariale](#11-revue-adversariale)
12. [Élicitation Avancée](#12-élicitation-avancée)
13. [Prévention des Conflits d'Agents](#13-prévention-des-conflits-dagents)
14. [Le Fichier project-context.md](#14-le-fichier-project-contextmd)
15. [Personnalisation des Agents](#15-personnalisation-des-agents)
16. [Testing — Quinn vs TEA](#16-testing--quinn-vs-tea)
17. [Les Modules Officiels](#17-les-modules-officiels)
18. [Migration de V4 vers V6](#18-migration-de-v4-vers-v6)
19. [Projets Existants (Brownfield)](#19-projets-existants-brownfield)
20. [Bonnes Pratiques et Anti-Patterns](#20-bonnes-pratiques-et-anti-patterns)
21. [Exemples Complets Pas-à-Pas](#21-exemples-complets-pas-à-pas)
22. [Ressources et Communauté](#22-ressources-et-communauté)

---

## 1. Introduction et Philosophie

### 1.1 Qu'est-ce que BMAD ?

**BMAD-METHOD** signifie **"Breakthrough Method for Agile AI-Driven Development"** (Méthode Révolutionnaire pour le Développement Agile Piloté par IA). On voit aussi le backronyme affectueux : *"Build More Architect Dreams"*.

C'est un **framework open source, 100% gratuit** (licence MIT) pour structurer le développement logiciel en collaboration avec des agents IA spécialisés. Créé en avril 2025, il a rapidement atteint **38 900+ étoiles GitHub** avec plus de 4 800 forks et 119 contributeurs — ce qui témoigne d'une adoption massive et rapide dans la communauté.

### 1.2 Le Problème que BMAD Résout

La plupart des développeurs utilisent l'IA de manière improvisée : ils tapent une requête, l'IA produit du code, on copie-colle, on répare les bugs, on recommence. Cette approche — parfois appelée **"vibe coding"** — produit des résultats médiocres parce que :

- L'IA manque de **contexte persistant** sur l'architecture du projet
- Différents agents IA prennent des **décisions contradictoires** (REST vs GraphQL, Redux vs Context, etc.)
- Il n'y a pas de **source de vérité documentaire** partagée
- Le code devient vite un **spaghetti incohérent** impossible à maintenir

> *"Au lieu de faire réfléchir l'IA à votre place et produire des résultats moyens, BMAD fait fonctionner le système comme un guide expert qui vous aide à mieux penser en partenariat avec l'intelligence artificielle."*

### 1.3 La Philosophie Centrale

BMAD repose sur **trois piliers philosophiques** :

**Pilier 1 : Docs-as-Code (La documentation est la source de vérité)**

Contrairement à l'approche traditionnelle où le code est la référence finale, BMAD place la **documentation structurée** au centre :
- Le PRD (Product Requirements Document) définit CE QU'ON CONSTRUIT
- L'Architecture définit COMMENT ON LE CONSTRUIT
- Les User Stories définissent chaque unité de travail
- Le code est un **dérivé en aval** de ces documents

**Pilier 2 : Human-Amplification (L'humain amplifié, pas remplacé)**

BMAD ne demande pas à l'IA de faire les décisions à votre place. Elle vous aide à :
- Clarifier vos exigences via des questions guidées
- Prendre des décisions informées avec les compromis bien présentés
- Documenter le raisonnement pour référence future
- Valider les hypothèses avant d'implémenter

**Pilier 3 : Scale-Adaptive Intelligence (Intelligence adaptative à l'échelle)**

BMAD ajuste la profondeur de planification selon la complexité :

| Piste | Cas d'usage | Complexité |
|-------|-------------|------------|
| **Quick Flow** | Bugs, petites features, scripts | 1–15 stories |
| **BMad Method** | Produits, plateformes | 10–50+ stories |
| **Enterprise** | Systèmes complexes, domaines réglementés | 30+ stories |

---

## 2. Concepts Fondamentaux

### 2.1 La Chaîne de Contexte (Context Chain)

C'est l'idée centrale de BMAD : **chaque phase produit des artefacts qui alimentent les phases suivantes**.

```
Idée du Produit
      ↓
Product Brief (vision stratégique)
      ↓
PRD - "Quoi construire" (exigences fonctionnelles et non-fonctionnelles)
      ↓
Architecture - "Comment construire" (décisions techniques)
      ↓
Epics & Stories - "Qui fait quoi" (unités de travail)
      ↓
Code (implémentation coherente)
```

> *"Le PRD dit à l'architecte quelles contraintes sont importantes. L'architecture dit à l'agent dev quels patterns suivre."*

**Exemple concret :**

Sans chaîne de contexte :
- L'agent implémente l'authentification avec JWT
- Un autre agent implémente l'upload de fichiers et suppose des sessions côté serveur
- Résultat : conflit de design d'authentification impossible à résoudre proprement

Avec chaîne de contexte :
- Le PRD dit : "les utilisateurs doivent rester connectés 30 jours"
- L'architecture dit : "JWT avec refresh tokens, stockage dans httpOnly cookies"
- Tous les agents suivent cette décision : cohérence parfaite

### 2.2 Context Engineering (Ingénierie de Contexte)

Le concept d'**ingénierie de contexte** reconnaît que les agents IA travaillent mieux avec un contexte clair et structuré. BMAD construit ce contexte progressivement.

Trois stratégies pour optimiser l'utilisation des tokens (budget de contexte IA) :

| Stratégie | Description | Économie de tokens |
|-----------|-------------|-------------------|
| **FULL_LOAD** | Charge tout le contexte en mémoire | 0% |
| **SELECTIVE_LOAD** | Récupère des fichiers spécifiques | ~90% d'économies |
| **INDEX_GUIDED** | Analyse l'index d'abord, puis les détails | ~95% d'économies |

Pour les grands projets, BMAD utilise automatiquement INDEX_GUIDED : l'agent regarde l'index de la documentation, identifie les sections pertinentes, et ne charge que ce dont il a besoin.

### 2.3 Les ADR (Architecture Decision Records)

Les ADR sont des **mini-documents** qui capturent une décision technique importante :
- **Contexte** : Pourquoi cette décision était nécessaire
- **Décision** : Ce qui a été choisi
- **Conséquences** : Les implications de ce choix

**Exemple d'ADR :**

```markdown
# ADR-001 : Style d'API

## Contexte
Notre application a besoin de communiquer avec le backend.
Plusieurs options existent : REST, GraphQL, gRPC.

## Décision
Utiliser GraphQL pour toutes les communications client-serveur.

## Conséquences
- Positif : Requêtes flexibles, réduction de l'over-fetching
- Négatif : Courbe d'apprentissage pour les nouveaux développeurs
- Impact : Tous les agents doivent utiliser Apollo Client
```

Pourquoi c'est important ? **Si cet ADR n'existe pas**, un agent crée un endpoint REST, un autre crée un resolver GraphQL — deux systèmes incompatibles dans la même app.

### 2.4 Les Artefacts de Planification vs d'Implémentation

BMAD organise ses sorties en deux catégories :

**Artefacts de Planification** (`project_manage/planning-artifacts/`) :
- `SPEC.md` *(v6.8+)* — Noyau distillé (Problem/Capabilities/Constraints/Non-goals/Success signal)
- `product-brief.md` — Vision stratégique
- `prfaq-{slug}.md` *(v6.8+)* — PR-FAQ Working Backwards (optionnel)
- `prd.md` — Exigences produit
- `DESIGN.md` + `EXPERIENCE.md` *(v6.8+ remplacent l'ancien `ux-spec.md`)*
- `architecture.md` — Architecture technique
- Fichiers Epic (`epic-1-user-auth.md`, etc.)
- `.decision-log.md` *(v6.7+)* — Journal des décisions par skill

**Artefacts d'Implémentation** (`project_manage/implementation-artifacts/`) :
- `sprint-status.yaml` — Suivi des sprints
- `story-*.md` — Stories individuelles prêtes à coder
- `project-context.md` — Constitution du projet pour les agents

### 2.5 La Distinction Planning vs Solutioning

Une confusion courante : confondre **planning** et **solutioning**. Ce sont deux phases distinctes.

| Dimension | Planning (Phase 2) | Solutioning (Phase 3) |
|-----------|-------------------|----------------------|
| **Question** | Quoi construire ? Et pourquoi ? | Comment construire ? Et en quelles unités ? |
| **Agent principal** | John (PM) | Winston (Architect) + John (PM) |
| **Sortie** | PRD avec FRs et NFRs | Architecture + Fichiers Epic avec Stories |
| **Audience** | Parties prenantes, équipe produit | Développeurs |
| **Niveau** | Logique métier | Design technique + Décomposition |

**Exemple :**

*Planning dit :* "Les utilisateurs doivent pouvoir s'inscrire et se connecter."

*Solutioning dit :* "On utilise Firebase Auth avec Google + Email/Password. La collection Firestore `users/{uid}` stocke le profil. L'agent dev doit utiliser `FirebaseAuth.instance.signInWithGoogle()`. Epic 1 = Auth, Story 1.1 = Login page, Story 1.2 = Registration flow..."

---

## 3. Installation

### 3.1 Prérequis

- **Node.js v20 ou supérieur** (requis)
- **Git** (recommandé)
- Un **IDE avec support IA** : Claude Code, Cursor, Windsurf, Kiro, GitHub Copilot

Vérifier votre version Node.js :
```bash
node --version
# Doit afficher v20.x.x ou supérieur
```

### 3.2 Installation Standard

```bash
# Dans le répertoire de votre projet
npx bmad-method install
```

L'installateur est interactif et vous guide à travers 4 étapes :

**Étape 1 : Répertoire d'installation**
```
? Install directory: (current directory)
```
Appuyez sur Entrée pour utiliser le répertoire courant.

**Étape 2 : Outil IA**
```
? Select your AI tool:
  ❯ Claude Code
    Cursor
    Windsurf
    Kiro
    GitHub Copilot
```

**Étape 3 : Modules**
```
? Select modules to install:
  ❯ ✓ BMad Method (BMM) — Suite agile complète [Recommandé]
    BMad Builder (BMB) — Création d'agents personnalisés
    Creative Intelligence Suite (CIS)
    Test Architect Enterprise (TEA)
    Game Dev Studio (GDS)
```

**Étape 4 : Personnalisation**
```
? Your name: Roosvelt
? Communication language: French
? Document output language: French
? User skill level: intermediate
```

### 3.3 Installation Non-Interactive (CI/CD)

Pour les environnements automatisés, utilisez les flags :

```bash
npx bmad-method install \
  --directory /path/to/project \
  --modules bmm \
  --tools claude-code \
  --user-name "Roosvelt" \
  --communication-language "French" \
  --document-output-language "French" \
  --yes
```

Flags disponibles :

| Flag | Description | Exemple |
|------|-------------|---------|
| `--directory <path>` | Répertoire cible | `--directory ./mon-projet` |
| `--modules <list>` | Modules séparés par virgules | `--modules bmm,tea` |
| `--tools <list>` | IDEs cibles (**requis** pour install fresh depuis v6.6) | `--tools claude-code,cursor` |
| `--list-tools` *(v6.6+)* | Lister les IDs d'outils supportés | `--list-tools` |
| `--user-name <name>` | Nom de l'utilisateur | `--user-name "Alice"` |
| `--communication-language` | Langue des agents | `--communication-language French` |
| `--document-output-language` | Langue des docs générés | `--document-output-language French` |
| `--output-folder <path>` | Où stocker les artefacts | `--output-folder ./_output` |
| `--action <type>` | install, update, compile-agents | `--action update` |
| `--set <module>.<key>=<value>` *(v6.6+)* | Forcer une valeur de config sans prompt (répétable) | `--set bmm.user_skill_level=advanced` |
| `--list-options [module]` *(v6.6+)* | Lister les options de config disponibles | `--list-options bmm` |
| `--custom-source <url>` *(v6.6+)* | Installer un module externe (URL git, marketplace) | `--custom-source https://...` |
| `-y / --yes` | Accepter tous les défauts | `-y` |

### 3.4 Structure des Répertoires Créés

Après installation, voici ce que BMAD crée dans votre projet :

```
mon-projet/
├── _bmad/                          # Installation BMAD
│   ├── _config/                    # Configuration système
│   │   ├── manifest.yaml           # Métadonnées d'installation
│   │   └── agents/                 # Personnalisation des agents
│   ├── core/                       # Framework universel
│   │   ├── agents/
│   │   │   └── bmad-master.md      # Agent orchestrateur
│   │   └── tasks/
│   └── bmm/                        # Module BMad Method
│       ├── agents/                 # Agents spécialisés
│       │   ├── analyst.md          # Mary — Business Analyst
│       │   ├── pm.md               # John — Product Manager
│       │   ├── architect.md        # Winston — Architecte
│       │   ├── sm.md               # Bob — Scrum Master
│       │   ├── dev.md              # Amelia — Développeuse
│       │   ├── ux-designer.md      # Sally — UX Designer
│       │   └── quick-flow-solo-dev.md  # Barry — Quick Dev
│       ├── workflows/              # Workflows par phase
│       │   ├── 1-analysis/
│       │   ├── 2-plan-workflows/
│       │   ├── 3-solutioning/
│       │   ├── 4-implementation/
│       │   └── bmad-quick-flow/
│       └── config.yaml             # Configuration du module
├── project_manage/                   # Sorties générées
│   ├── planning-artifacts/         # PRD, architecture, etc.
│   └── implementation-artifacts/  # Stories, sprint status, etc.
├── .claude/
│   └── commands/                   # Commandes Claude Code
└── docs/                           # Votre documentation projet
```

### 3.5 Vérification Post-Installation

Après installation, testez immédiatement :

```
/bmad-help
```

Vous devriez voir une réponse de l'agent BMad Master vous guidant vers les prochaines étapes.

### 3.6 Configuration (config.yaml)

Le fichier `_bmad/bmm/config.yaml` contient votre configuration :

```yaml
project_name: mon-projet-saas
user_skill_level: intermediate       # beginner | intermediate | advanced
planning_artifacts: "{project-root}/project_manage/planning-artifacts"
implementation_artifacts: "{project-root}/project_manage/implementation-artifacts"
project_knowledge: "{project-root}/docs"   # Où est votre doc
user_name: Roosvelt
communication_language: French       # Langue de communication avec les agents
document_output_language: French     # Langue des documents générés
output_folder: "{project-root}/project_manage"
```

---

## 4. Architecture du Système

### 4.1 Les 7 Couches du Système

BMAD est architecturé en 7 couches distinctes :

```
┌─────────────────────────────────────────────────┐
│  Couche 1 : Entrée                              │
│  (Commandes CLI et IDEs AI)                     │
├─────────────────────────────────────────────────┤
│  Couche 2 : Framework Core                      │
│  (Installateur, ConfigCollector, UI)            │
├─────────────────────────────────────────────────┤
│  Couche 3 : Gestion de Modules                  │
│  (ModuleManager, ExternalModuleManager)         │
├─────────────────────────────────────────────────┤
│  Couche 4 : Agents & Workflow                   │
│  (Compilateur, Moteur Workflow, Système Mémoire)│
├─────────────────────────────────────────────────┤
│  Couche 5 : Intégration IDE                     │
│  (IdeManager, Générateurs de commandes)         │
├─────────────────────────────────────────────────┤
│  Couche 6 : Manifest & Persistance              │
│  (manifest.yaml, CSV manifests, Cache)          │
├─────────────────────────────────────────────────┤
│  Couche 7 : Système de Fichiers                 │
│  (Structure de répertoire, configs)             │
└─────────────────────────────────────────────────┘
```

### 4.2 Le Compilateur d'Agents

Les agents ne sont pas de simples fichiers Markdown. Ils sont d'abord définis en YAML déclaratif :

```yaml
# analyst.agent.yaml (source)
agent:
  metadata:
    name: "Mary"
    icon: "📊"
    title: "Business Analyst"
  persona:
    role: "Strategic Business Analyst & Requirements Expert"
    identity: "Senior analyst with expertise in market research..."
    communication_style: "Treats analysis like a treasure hunt..."
    principles: "Every business challenge has root causes..."
  menu:
    - id: BP
      label: "Guided Brainstorming Session"
      workflow: brainstorming
```

Le **Compilateur d'Agents** transforme ce YAML en fichiers Markdown avec des blocs XML embarqués que les LLMs comprennent mieux. Quand vous personnalisez un agent, vous modifiez le YAML et re-compilez :

```bash
npx bmad-method install
# Puis choisir "Recompile Agents"
```

### 4.3 Skills Architecture (v6.8.0) — ce qui remplace les anciens « Workflows »

À partir de v6.8.0, BMAD parle de **skills** plus que de workflows. La différence est plus que cosmétique :

| Aspect | Ancien « Workflow » (v6.0) | Nouvelle « Skill » (v6.8.0) |
|---|---|---|
| Forme du livrable | Un seul document monolithique (`ux-spec.md`) | **Plusieurs fichiers companions avec un contrat scellé** (ex. `DESIGN.md` + `EXPERIENCE.md` + `.decision-log.md`) |
| Handoff vers la skill suivante | Implicite (l'agent suivant relit) | **Explicite** : chaque skill déclare ses sorties nommées, les suivantes les consomment par nom |
| Mode d'exécution | Conversation IDE | Conversation IDE **ou** mode headless (JSON in/out) **ou** Web Bundle (Gemini Gems, ChatGPT) |
| Intent | 1 (Create implicite) | 3 (Create / Update / Validate) sur les skills clés (PRD, Product Brief, UX, etc.) |
| Personnalisation utilisateur | Globale par agent | Par skill + par mode (Fast / Coaching) |
| Source de l'agent | Un Markdown + XML | YAML déclaratif compilé, plus l'arbre `step-*.md` |
| Localisation install IDE | `.claude/commands/` | **`.claude/skills/`** |

**Conséquence pratique** : quand tu lis « workflow » dans la suite de ce document, mentalement remplace par « skill ». Le terme « workflow » subsiste dans certains noms historiques (ex. `bmad-workflow-status`) mais le modèle conceptuel courant est celui des skills.

**Le modèle « two-spine contract »** : plusieurs skills v6.8.0 (notamment `bmad-ux` et `bmad-spec`) suivent ce modèle : le livrable est éclaté en deux fichiers de natures différentes qui se référencent, plutôt qu'un seul document hybride. Avantage : chaque axe (visuel vs comportement, intent vs détail) peut évoluer indépendamment et être validé par la bonne personne.

### 4.4 Architecture de Workflow (Step-File Architecture)

Chaque workflow suit une **architecture en fichiers d'étapes** :

```
workflow-create-prd/
├── README.md          # Point d'entrée avec instructions et metadata
├── step-1-discovery.md
├── step-2-requirements.md
├── step-3-validation.md
└── step-4-finalize.md
```

Mécanismes clés :
- **Chargement just-in-time** : Les fichiers d'étapes se chargent à la demande
- **Commandes HALT** : Empêchent la lecture anticipée (l'agent attend votre validation)
- **Frontmatter de statut** : Chaque étape track son état de completion
- **Sorties vers dossiers désignés** : Les artefacts vont dans les bons répertoires automatiquement

### 4.4 Le Système de Manifest

BMAD maintient plusieurs fichiers CSV de manifest pour la découverte dynamique :

| Fichier | Contenu |
|---------|---------|
| `manifest.yaml` | Métadonnées d'installation, versions, IDEs |
| `workflows-manifest.csv` | Tous les workflows avec descriptions |
| `agents-manifest.csv` | Tous les agents avec métadonnées |
| `tasks-manifest.csv` | Toutes les tâches disponibles |
| `files-manifest.csv` | Suivi de fichiers avec hashes SHA-256 |

Ces fichiers permettent à `bmad-help` de connaître dynamiquement ce qui est installé et disponible.

---

## 5. Les Quatre Phases du Développement

### Vue d'Ensemble

```
┌──────────────────────────────────────────┐
│  Phase 1 : ANALYSE (Optionnel)           │
│  Explorer, valider le concept            │
│  → Product Brief                        │
└──────────────────┬───────────────────────┘
                   ↓
┌──────────────────────────────────────────┐
│  Phase 2 : PLANNING (Requis)             │
│  Définir les exigences                  │
│  → PRD + UX Design                      │
└──────────────────┬───────────────────────┘
                   ↓
┌──────────────────────────────────────────┐
│  Phase 3 : SOLUTIONING (Méthode BMad)    │
│  Décider comment construire             │
│  → Architecture + Epics + Stories       │
└──────────────────┬───────────────────────┘
                   ↓
┌──────────────────────────────────────────┐
│  Phase 4 : IMPLÉMENTATION (Execution)    │
│  Coder, reviewer, livrer                │
│  → Code fonctionnel testé               │
└──────────────────────────────────────────┘
```

---

### Phase 1 : Analyse (Optionnel)

**Objectif** : Explorer le problème et valider le concept avant de s'engager dans le développement.

**Quand l'utiliser** : Avant de commencer un nouveau produit dont vous n'êtes pas sûr, ou pour explorer un marché.

**Quand la sauter** : Vous avez déjà une vision claire, ou vous travaillez sur une feature spécifique d'un produit existant.

#### Workflow 1.1 : Brainstorming
**Commande** : `/bmad-brainstorming` *(ex-`/bmad-bmm-brainstorming`)* ou option `[BP]` de Mary
**Agent** : Mary (Analyste)
**Sortie** : `brainstorming-report.md`

Mary vous guide à travers une session structurée d'idéation. Elle utilise des techniques comme :
- **SCAMPER** (Substitute, Combine, Adapt, Modify, Put to other uses, Eliminate, Reverse)
- **Reverse Brainstorming** (Comment pourrait-on FAIRE ÉCHOUER le produit ?)
- **How Might We** (Comment pourrait-on... ?)

**Exemple de session :**
```
Vous : Je veux créer une app de suivi des ventes pour les vendeurs africains

Mary : Intéressant ! Commençons par explorer le problème.
       Question 1 : Quel problème spécifique vivent ces vendeurs aujourd'hui ?
       Ont-ils actuellement un moyen de suivre leurs ventes ?

Vous : Non, la plupart utilisent des cahiers ou rien du tout

Mary : Parfait. Explorons les dimensions du problème...
       [Session guidée de 30-45 minutes]

→ Sortie : brainstorming-report.md avec insights structurés
```

#### Workflow 1.2 : Research (scindée en 3 skills depuis v6.8.0)
**Agent** : Mary (Analyste)

L'ancienne skill générique `/bmad-bmm-research` a été éclatée en trois skills spécialisées, chacune avec son protocole d'enquête propre :

- **`/bmad-market-research`** : Taille de marché, concurrents, tendances, segments. Sortie : `market-research-{slug}.md`.
- **`/bmad-domain-research`** : Réglementation, contraintes métier, vocabulaire du domaine, processus existants. Sortie : `domain-research-{slug}.md`.
- **`/bmad-technical-research`** : Faisabilité, stack technologique, contraintes plateforme, comparaisons d'outils. Sortie : `technical-research-{slug}.md`.

> Pourquoi cette scission : un PM cherche autre chose qu'un dev, qui cherche autre chose qu'un juriste. Auparavant, la skill unique mélangeait les angles ; les trois skills dédiées produisent des livrables plus exploitables par les phases en aval (PRD, Architecture).

#### Workflow 1.3 : Product Brief
**Commande** : `/bmad-product-brief` *(ex-`/bmad-bmm-create-product-brief`)*
**Agent** : Mary (Analyste)
**Sortie** : `product-brief.md` + `.decision-log.md`

Depuis v6.7+, suit le même pattern que le PRD :
- **3 intents** : Create / Update / Validate
- **2 modes** : Fast / Coaching

#### Workflow 1.4 : PR-FAQ « Working Backwards » (nouveau v6.8.0)
**Commande** : `/bmad-prfaq`
**Agent** : Mary (Analyste) ou John (PM)
**Sortie** : `prfaq-{slug}.md`

Inspiré de la pratique Amazon « Working Backwards » : avant d'écrire le PRD, on rédige le **communiqué de presse fictif du lancement** (PR) + la **FAQ** (questions internes + externes). Si le PR n'est pas convaincant à lire, le produit n'est pas convaincant à construire — on revoit la vision avant d'investir.

**Quand l'utiliser** : avant un PRD majeur, surtout si la vision produit est encore floue ou contestée en interne. Court-circuite la tentation de « foncer dans la spec » avant d'aligner les parties prenantes.

#### Workflow 1.5 : Spec Distillation (nouveau v6.8.0)
**Commande** : `/bmad-spec` *(remplace l'ancien `bmad-distillator`)*
**Agent** : agent neutre (chargé selon le contexte)
**Sortie** : `SPEC.md` + companions (catalogues, diagrammes) + `.decision-log.md`

Distille n'importe quel input désordonné — **brain dump, vieux PRD, transcript de réunion, brief client, ticket d'idée** — en un `SPEC.md` au **noyau à 5 champs** :

| Champ | Question à laquelle il répond |
|---|---|
| **Problem** | Quel problème résout-on, pour qui ? |
| **Capabilities** | Que doit savoir faire la solution (haut niveau) ? |
| **Constraints** | Quelles limites (budget, temps, plateforme, réglementaire) ? |
| **Non-goals** | Qu'est-ce qu'on **ne** fait **pas** explicitement ? |
| **Success signal** | Comment saura-t-on que c'est réussi (signal mesurable) ? |

Le contenu accessoire (listes de fonctionnalités candidates, captures, schémas) va dans des **fichiers companions** nommés ; les sources d'entrée sont cataloguées pour ne pas être relues plusieurs fois en aval.

**Modes** : conversationnel (avec questions de clarification) ou **headless JSON** (entrée structurée → sortie structurée, idéal pour pipelines).

**Pourquoi cette skill existe** : le PRD est trop long pour servir d'entrée à un Quick Flow ou à une nouvelle phase d'exploration. `SPEC.md` est l'entrée minimale partageable entre skills — un PRD distillé en moins de 2 pages. **Pour Valide**, ce serait l'entrée idéale à donner à John pour le `bmad-prd` : on lui passe le SPEC du Decoupage MVP plutôt que le PDF entier.

Le Product Brief capture la vision stratégique en ~2 pages :
- Vision du produit en une phrase
- Problème résolu et pour qui
- Proposition de valeur unique
- Métriques de succès
- Contraintes et risques

**Structure type du product-brief.md :**
```markdown
# Product Brief : Next Sales

## Vision
Permettre aux vendeurs africains de gérer leur commerce depuis leur téléphone.

## Problème
80% des vendeurs en Afrique subsaharienne n'ont pas d'outil de suivi commercial.
Ils perdent des clients faute de relances, et ne savent pas quels produits marchent.

## Public Cible
Vendeurs indépendants et PME (1-10 employés) en Afrique francophone.

## Proposition de Valeur Unique
Premier outil de vente conçu spécifiquement pour les contraintes africaines
(connexion intermittente, paiement mobile money, interface en français).

## Métriques de Succès
- 500 utilisateurs actifs en 3 mois
- Taux de rétention à 30 jours > 40%

## Contraintes
- Budget : Bootstrap
- Délai : 6 mois pour le MVP
- Technologie : Flutter pour iOS et Android simultanés
```

---

### Phase 2 : Planning (Requis)

**Objectif** : Définir précisément ce qu'on va construire et pour qui.

#### Workflow 2.1 : PRD (Product Requirements Document) — v6.7+ avec 3 intents et 2 modes
**Commande** : `/bmad-prd` *(ex-`/bmad-bmm-create-prd`)*
**Agent** : John (Product Manager)
**Sorties** : `prd.md` + `addendum.md` (le cas échéant) + `.decision-log.md`
**Durée typique** : 30 min (Fast) à 2 h (Coaching)

**3 intents** :
- **Create** : nouveau PRD depuis zéro (ou depuis un `SPEC.md` produit par `bmad-spec`).
- **Update** : amender un PRD existant — John ne refait pas tout, il vise les sections à toucher et laisse une trace dans `.decision-log.md`.
- **Validate** : audit de cohérence (FRs vs NFRs, personas vs scope, etc.) sans modification — sort un rapport.

**2 modes** :
- **Fast** : John tire le maximum de ton input et te pose le minimum de questions. Bon quand le contexte est déjà clair (un `product-brief.md` solide, un `SPEC.md` distillé).
- **Coaching** : John interroge plus profondément, t'apprend les concepts PM (Jobs-to-be-Done, NFRs, MVP scoping) au fur et à mesure. Bon si tu n'es pas PM de formation.

**Le `.decision-log.md` (pattern v6.7+)** : à chaque décision PRD significative (« on garde le scope X, on coupe Y, le NFR Z passe en P1 »), John consigne `quand / quoi / pourquoi / qui l'a tranché`. Ce fichier voyage avec le PRD à travers les phases suivantes — Winston, John en mode Epics, et Bob/Amelia s'y réfèrent pour comprendre la justification d'une exigence sans devoir te rappeler la conversation initiale. **Il remplace en grande partie le besoin d'ADR pour les décisions produit** (les ADR restent pour les décisions techniques en Phase 3).

John vous interview comme un PM expérimenté. Il pose des questions jusqu'à ce qu'il comprenne parfaitement le produit :

```
John : Pour qui construisons-nous en premier ?

Vous : Pour les vendeurs individuels, pas les grandes entreprises

John : Quel est leur plus grand pain point aujourd'hui ?

Vous : Ils oublient de relancer les clients qui n'ont pas encore payé

John : Combien de clients gèrent-ils en moyenne ?

Vous : Entre 20 et 200 clients

John : POURQUOI utilisent-ils actuellement des cahiers plutôt que
       des apps comme Excel ou WhatsApp ?

Vous : Ils ne sont pas très à l'aise avec les outils compliqués

John : Parfait. Voici ce que j'entends : [Synthèse...]
```

**Structure type du PRD.md :**
```markdown
# PRD : Next Sales

## Objectifs Produit
### Exigences Fonctionnelles (FRs)
- FR1 : L'utilisateur peut créer un profil vendeur
- FR2 : L'utilisateur peut ajouter des clients avec nom + téléphone
- FR3 : L'utilisateur peut enregistrer une vente avec montant et produit
- FR4 : Le système envoie des rappels automatiques pour les paiements impayés
- FR5 : L'utilisateur peut voir un tableau de bord de ses ventes du mois

### Exigences Non-Fonctionnelles (NFRs)
- NFR1 : L'app doit fonctionner avec une connexion 3G (< 2MB de données/jour)
- NFR2 : Temps de chargement < 3 secondes
- NFR3 : Support iOS et Android
- NFR4 : Interface uniquement en français

## Personas Utilisateurs
### Persona 1 : "Fatou la Vendeuse"
- 35 ans, vend du tissu au marché
- Smartphone Android entrée de gamme
- 50 clients réguliers, 200 contacts

## User Stories de Haut Niveau
- En tant que Fatou, je veux voir mes clients qui n'ont pas payé
  afin de les relancer au bon moment
- En tant que Fatou, je veux voir mon chiffre d'affaires du mois
  afin de savoir si mon business est rentable

## Hors Scope
- Comptabilité avancée
- Multi-utilisateurs (V1)
- Interface en anglais (V1)
```

#### Workflow 2.2 : UX Design — le « Two-Spine Contract » (v6.8.0)
**Commande** : `/bmad-ux` *(ex-`/bmad-bmm-create-ux-design`, retiré)*
**Agent** : Sally (UX Designer)
**Sortie** : **deux fichiers scellés** + un journal :
- `DESIGN.md` — tokens visuels (Google Labs spec) : couleurs, typographie, espacements, arrondis, ombres, iconographie
- `EXPERIENCE.md` — comportement, flux, IA (architecture d'information), états, accessibilité ; référence les tokens de `DESIGN.md` via la syntaxe `{path.to.token}`
- `.decision-log.md` — journal des décisions UX prises pendant la skill

**Pourquoi deux fichiers (et non l'ancien `ux-spec.md`)** : c'est un **contrat scellé entre design et engineering**, pas une couche de traduction. L'identité visuelle (`DESIGN.md`) et le comportement (`EXPERIENCE.md`) évoluent à des rythmes différents — les séparer permet de modifier l'un sans casser l'autre, et de faire valider chacun par la bonne personne (graphiste vs PM/UX).

Sally produit, dans `EXPERIENCE.md` :
- Flux de navigation (user flows)
- Wireframes décrits textuellement avec références aux tokens
- Hiérarchie d'information
- Patterns d'interaction
- États (loading, error, empty, success)
- Accessibilité (contrastes, tailles cibles tactiles, navigation au clavier)

Et dans `DESIGN.md` : la palette canonique, l'échelle typographique, l'échelle d'espacement, les rayons, les ombres, les icônes — toutes nommées et adressables.

**Modes** (héritage du pattern v6.7+ que `bmad-prd` a aussi) :
- **Fast** : Sally pose le strict minimum de questions et propose un premier jet.
- **Coaching** : Sally enseigne au passage et challenge tes hypothèses (utile si l'UX n'est pas ton métier).

**Intents** :
- **Create** : nouveau design.
- **Update** : modifier un design existant en respectant les tokens déjà figés.
- **Validate** : vérifier la cohérence entre `DESIGN.md`, `EXPERIENCE.md`, et le PRD.

**Quand l'utiliser** : si votre produit a une UI significative.
**Quand le sauter** : APIs, CLIs, scripts sans interface.

**Cas pratique Valide** : vous avez déjà un Design System HTML très complet ([Valide - Design System.html](../tech/Valide%20-%20Design%20System.html)) et un Design HTML (`Valide - Design.html`). Plutôt que de laisser Sally repartir de zéro, **alimentez-la avec ces deux fichiers en entrée** et demandez l'intent `Create` : elle produira `DESIGN.md` (les tokens déjà figés — couleurs `#2563EB`, Nunito Sans, etc.) et `EXPERIENCE.md` (les flux par module M1-M16). Les deux fichiers deviennent alors la **source unique** que `bmad-create-architecture`, `bmad-create-epics-and-stories` et `bmad-dev-story` consulteront — fini la divergence HTML ↔ code.

---

### Phase 3 : Solutioning (Pour la Méthode BMad Complète)

**C'est la phase la plus critique et la plus incomprise de BMAD.**

#### Pourquoi le Solutioning est-il Indispensable ?

Imaginez ce scénario sans solutioning :

```
Epic 1 (Agent IA 1) : Implemente l'authentification
→ Utilise des sessions JWT côté client

Epic 2 (Agent IA 2) : Implemente le tableau de bord
→ Suppose des sessions côté serveur pour la sécurité

Epic 3 (Agent IA 3) : Implemente les notifications
→ Utilise les métadonnées de session serveur pour identifier l'utilisateur

Résultat : CATASTROPHE. Trois systèmes d'auth incompatibles.
Coût de correction : 3x le temps d'implémentation.
```

Avec solutioning :

```
Architecture dit : "JWT avec httpOnly cookies, refresh tokens,
                   durée 30 jours, révocation via Firestore"

Epic 1, 2, 3 lisent l'architecture → tous suivent les mêmes règles
Résultat : Cohérence parfaite, zéro conflit.
```

> *"Détecter les problèmes d'alignement en solutioning est 10x plus rapide que les découvrir pendant l'implémentation."*

#### Workflow 3.1 : Architecture
**Commande** : `/bmad-create-architecture` *(ex-`/bmad-bmm-create-architecture`)*
**Agent** : Winston (Architecte)
**Sortie** : `architecture.md` + fichiers ADR

Winston engage une conversation pour comprendre vos préférences et contraintes, puis propose une architecture adaptée — non pas à partir d'un template, mais des vraies décisions de votre produit.

**Sections typiques de architecture.md :**

```markdown
# Architecture : Next Sales

## Vue d'Ensemble du Système
[Diagramme ASCII du système]

## Stack Technologique
| Couche | Technologie | Justification |
|--------|------------|---------------|
| Mobile | Flutter | iOS + Android simultanés |
| Backend | Firebase | Hébergement géré, temps réel |
| Auth | Firebase Auth | Intégration native Flutter |
| DB | Firestore | NoSQL flexible, temps réel |
| Storage | Firebase Storage | Images produits |

## Modèle de Données
```
businesses/{businessId}
  clients/{clientId}
  products/{productId}
  sales/{saleId}
  reminders/{reminderId}
```

## ADR-001 : Architecture Monorepo
### Contexte : Gérer app Flutter + backend Cloud Functions
### Décision : Monorepo avec lib/ (Flutter) et functions/ (Node.js)
### Conséquences : Déploiements coordonnés, CI unifié

## ADR-002 : Gestion d'État
### Contexte : État complexe avec données temps réel
### Décision : GetX pour gestion d'état et navigation
### Conséquences : Tous les controllers étendent GetxController
```

#### Workflow 3.2 : Epics & Stories
**Commande** : `/bmad-create-epics-and-stories` *(ex-`/bmad-bmm-create-epics-and-stories`)*
**Agent** : John (PM)
**Prérequis** : PRD + Architecture complétés (et `DESIGN.md` + `EXPERIENCE.md` si l'UX a été faite)
**Sortie** : Fichiers Epic avec Stories détaillées
**Bonus v6.6+** : **brownfield epic scoping** — détecte les chevauchements de fichiers entre epics et applique des principes de design pour réduire les modifications inutiles ; inclut une « design completeness gate ».

John décompose le PRD en epics et stories en respectant l'architecture :

**Structure d'un fichier Epic :**
```markdown
# Epic 1 : Authentification et Onboarding

## Résumé
Permettre aux vendeurs de créer un compte et s'authentifier.

## Stories

### Story 1.1 : Écran de Login
**En tant que** vendeur non-connecté
**Je veux** pouvoir me connecter avec mon numéro de téléphone
**Afin de** accéder à mon espace de vente

**Critères d'acceptation :**
- Given : L'utilisateur est sur l'écran de login
- When : Il saisit son téléphone et son code reçu par SMS
- Then : Il est redirigé vers le tableau de bord

**Tâches techniques :**
- [ ] Créer `AuthController` avec méthode `signInWithPhone()`
- [ ] Créer `LoginView` avec champ téléphone + code OTP
- [ ] Configurer Firebase Phone Auth
- [ ] Tester sur iOS et Android

**Dépendances :** Aucune
**Effort estimé :** 2 jours
```

#### Workflow 3.3 : Vérification de Readiness
**Commande** : `/bmad-check-implementation-readiness` *(ex-`/bmad-bmm-check-implementation-readiness`)*
**Agents** : Winston + John
**Sortie** : Rapport PASS / CONCERNS / FAIL

Avant de commencer à coder, cette revue adversariale vérifie :
- Les stories sont-elles assez précises pour être implémentées ?
- Y a-t-il des contradictions entre PRD et Architecture ?
- Les dépendances entre stories sont-elles clairement définies ?
- Les critères d'acceptation sont-ils testables ?

Si le résultat est **FAIL**, on revient corriger les documents avant de coder.

---

### Phase 4 : Implémentation

C'est là que le code est écrit. La Phase 4 se répète en cycles (sprint par sprint, story par story).

#### Le Cycle Typique d'une Story

```
1. Sprint Planning   → Bob initialise le sprint
2. Create Story      → Bob prépare la prochaine story pour Amelia
3. Dev Story         → Amelia implémente
4. Code Review       → Amelia ou un autre agent revoit
5. (Répéter pour chaque story)
6. Retrospective     → Bob fait la revue post-epic
```

#### Workflow 4.1 : Sprint Planning
**Commande** : `/bmad-sprint-planning` *(ex-`/bmad-bmm-sprint-planning`)*
**Agent** : Bob (Scrum Master) — voir note section 7 sur l'absorption potentielle de ce rôle par Amelia en v6.8.0
**Sortie** : `sprint-status.yaml`

Bob extrait toutes les epics et stories et crée un fichier de suivi YAML :

```yaml
# sprint-status.yaml
sprint:
  number: 1
  start_date: 2025-03-01
  end_date: 2025-03-15

epics:
  - id: epic-1
    name: "Authentification"
    status: in_progress
    stories:
      - id: story-1.1
        name: "Écran de Login"
        status: completed
        assigned_to: amelia
      - id: story-1.2
        name: "Onboarding"
        status: in_progress
        assigned_to: amelia
      - id: story-1.3
        name: "Profil Vendeur"
        status: pending
```

#### Workflow 4.1.b : Sprint Status (nouveau v6.8.0)
**Commande** : `/bmad-sprint-status`
**Agent** : Bob (ou agent neutre)
**Sortie** : mise à jour de `sprint-status.yaml` + rapport de progression

Skill légère pour faire un point d'avancement en cours de sprint sans déclencher une retrospective complète. Utile pour les standups quotidiens automatisés ou un check-in mid-sprint.

#### Workflow 4.2 : Create Story
**Commande** : `/bmad-create-story` *(ex-`/bmad-bmm-create-story`)*
**Agent** : Bob (Scrum Master)
**Sortie** : `story-{slug}.md`

Bob prépare une story complète et prête-à-développer pour Amelia :

```markdown
# Story 1.2 : Flow d'Onboarding

## Contexte
[Liens vers PRD section 3.2, Architecture section Auth]

## Tâches Ordonnées
1. [ ] Créer `OnboardingController` dans `lib/presentation/modules/onboarding/`
2. [ ] Créer 3 slides d'onboarding avec `OnboardingView`
3. [ ] Stocker le flag `hasSeenOnboarding` dans SharedPreferences
4. [ ] Rediriger vers `/home` si flag existant

## Critères d'Acceptation (Given/When/Then)
- Given : Nouvel utilisateur connecté pour la première fois
- When : Il lance l'app
- Then : Il voit les 3 slides d'onboarding
- And : Il peut les sauter ou les parcourir

- Given : Utilisateur ayant vu l'onboarding
- When : Il relance l'app
- Then : Il va directement au tableau de bord

## Références Techniques
- Pattern à suivre : `auth_controller.dart` (même structure)
- Route à ajouter : `AppRoutes.onboarding = '/onboarding'`
- SharedPreferences key : `'has_seen_onboarding'`
```

#### Workflow 4.3 : Dev Story
**Commande** : `/bmad-dev-story` *(ex-`/bmad-bmm-dev-story`)*
**Agent** : Amelia (Développeuse)

Amelia implémente en suivant **strictement** le fichier story :

1. Elle lit le fichier story complet
2. Elle exécute chaque tâche dans l'ordre
3. Elle écrit les tests AVANT le code (TDD red-green-refactor)
4. Elle coche les tâches au fur et à mesure
5. Elle ne sort JAMAIS du scope de la story

> *"Le Fichier Story est la seule source de vérité. Amelia n'implémente rien qui n'est pas mappé à une tâche spécifique."*

Discipline critique d'Amelia :
```
Tâche 1 : Créer OnboardingController
→ Amelia crée UNIQUEMENT le controller, rien de plus

Tâche 2 : Créer la vue
→ Amelia crée la vue qui utilise le controller

Elle NE CRÉE PAS un "bonus" service de tracking parce qu'elle pense
que ce serait bien d'avoir. Hors scope = pas fait.
```

#### Workflow 4.4 : Code Review
**Commande** : `/bmad-code-review` *(ex-`/bmad-bmm-code-review`)*
**Agent** : Amelia (ou un agent différent sur un LLM frais)

La revue de code dans BMAD est **adversariale** (voir Section 11). L'agent DOIT trouver des problèmes. Il ne peut pas dire "ça a l'air bien".

**Recommandation importante** : Utiliser un nouveau contexte et idéalement un LLM différent pour la revue. Un agent qui vient de coder est "aveugle" à ses propres erreurs.

#### Workflow 4.5 : Retrospective
**Commande** : `/bmad-retrospective` *(ex-`/bmad-bmm-retrospective`)*
**Agent** : Bob (Scrum Master)

Après la completion d'un epic, Bob facilite une retrospective :
- Qu'est-ce qui a bien marché ?
- Qu'est-ce qui aurait pu être mieux ?
- Les estimations d'effort étaient-elles justes ?
- Y a-t-il de nouvelles informations qui impactent la suite ?

#### Workflow 4.6 : Correct Course
**Commande** : `/bmad-correct-course` *(ex-`/bmad-bmm-correct-course`)*
**Agents** : Bob + John

Quand un changement significatif survient en cours de sprint (nouvelle exigence client, bug critique, décision de pivot), ce workflow analyse l'impact et propose un plan :

```
Situation : Le client veut ajouter les paiements Mobile Money en cours de Sprint 2

Correct Course analyse :
- Impact sur les stories en cours : Story 2.3 (paiements) doit être rééscrite
- Impact sur l'architecture : Nouveau service FreemoPay à documenter en ADR
- Impact planning : Sprint 2 allongé de 3 jours
- Recommandation : Créer Story 2.3b pour l'intégration, repousser Story 2.4 à Sprint 3
```

#### Workflow 4.7 : Investigate (nouveau v6.7.0) — la forensique de code
**Commande** : `/bmad-investigate`
**Agent** : Amelia ou Winston (selon le contexte)
**Sortie** : `{slug}-investigation.md`

Skill **forensique** pour les situations où on ne comprend pas encore ce qui se passe : bug récurrent, incident production, RCA (Root Cause Analysis), exploration d'un module hérité, ou audit d'une zone du code inconnue.

**Deux modes d'investigation** :
- **Defect-chasing** : on a un symptôme (« le quiz se fige après la question 5 »), on remonte vers la cause.
- **Area-exploration** : on hérite d'un code inconnu et on veut le cartographier avant de toucher quoi que ce soit.

**Le concept clé : preuves graduées.** Chaque conclusion du rapport d'investigation est étiquetée :

| Grade | Signification | Exemple |
|---|---|---|
| **Confirmed** | Preuve directe dans le code, les logs ou un test | « La transaction n'est pas atomique : ligne X du repository fait un set en dehors du runTransaction » |
| **Deduced** | Inférence logique à partir d'éléments confirmés | « Si la transaction n'est pas atomique ET que le retry réseau rejoue l'écriture, alors les points sont doublés » |
| **Hypothesized** | Hypothèse plausible non vérifiée — à tester | « Probablement aussi un problème sur les crédits ; non vérifié dans cette session » |

Cette gradation force l'IA à **ne pas inventer** de causes. Elle remplace les « LGTM » et les « probablement que ça vient de... » qui pourrissent les diagnostics IA classiques.

**Resume-on-collision** : sur de gros codebases, la skill peut être interrompue et reprise sans relire tout depuis le début — elle reprend là où elle s'était arrêtée.

**Pour Valide** : utile en Phase 4 dès qu'un bug récurrent émerge (transaction d'alimentation, condition de course sur l'idempotence, plantage de `flutter_smooth_markdown`...). Évite de partir en hypothèse libre et de modifier du code sans savoir pourquoi.

---

## 6. Quick Flow — La Piste Rapide (unifiée en v6.8.0)

### 6.1 Philosophie

Quick Flow est une **piste parallèle** pour les tâches qui ne méritent pas tout le processus BMad complet.

> *"Skip the ceremony. Quick Flow takes you from idea to working code in two commands."*

### 6.2 Quand Utiliser Quick Flow ?

**✅ Utilisez Quick Flow pour :**
- Corrections de bugs et patches
- Refactoring de code existant
- Petites fonctionnalités bien comprises (ajouter un bouton, changer un comportement)
- Scripts et outils internes
- Prototypage et spikes
- Travail qu'un seul développeur peut garder entièrement en tête

**❌ N'utilisez PAS Quick Flow pour :**
- Nouveaux produits ou plateformes nécessitant un alignement parties prenantes
- Fonctionnalités majeures couvrant plusieurs composants
- Travail nécessitant des décisions architecturales (schéma BDD, contrats API)
- Exigences floues ou contestées

### 6.3 La Commande Unifiée Quick Flow (v6.8.0)

> ⚠️ **Changement v6.0 → v6.8.0** : l'ancien duo `bmad-bmm-quick-spec` + `bmad-bmm-quick-dev` est **fusionné** en une seule skill `bmad-quick-dev` qui orchestre clarification + plan + implémentation + revue + présentation. Tu n'as plus besoin de passer le tech-spec d'une commande à l'autre — la skill gère tout le cycle. Le mode « tech-spec en entrée » reste possible (tu pointes un fichier spec existant).

#### `/bmad-quick-dev` — le cycle complet

Barry (ou l'agent dev en charge) orchestre 5 phases dans une seule conversation :

**Étape 1 — Comprendre**
```
Barry : Décris la fonctionnalité désirée.

Vous : Je veux ajouter un bouton "Partager" sur la page produit
       qui génère un lien vers le catalogue en ligne.
```

**Étape 2 — Investiguer**
```
Barry : [Scanne automatiquement le codebase]
Barry : J'ai trouvé ProductDetailView, ProductController,
        AppRoutes.catalogLink. Je lis aussi share_plus pub.
        Y a-t-il des contraintes spécifiques ?

Vous : Le lien doit inclure le businessId pour le catalogue.
```

**Étape 3 — Générer**

Barry produit un spec technique ordonné :

```markdown
# Tech Spec : Bouton Partager Produit

## Tâches
1. Ajouter méthode `shareProductLink()` dans `ProductController`
   - Construire l'URL : `https://catalog.nextsales.app/{businessId}/{productId}`
   - Utiliser `Share.share(url)` de share_plus

2. Ajouter `IconButton` share dans `ProductDetailView` AppBar
   - Icône : `Icons.share`
   - onTap : `controller.shareProductLink()`

3. Gérer l'état d'erreur si businessId null

## Critères d'Acceptation
- Given : Utilisateur sur la page d'un produit
- When : Il tape le bouton partager
- Then : La dialog de partage native s'ouvre avec le lien catalogue
- And : Le lien fonctionne sur un navigateur externe
```

**Étape 4 — Réviser**
```
Barry : Voici le spec complet. Validez pour que je commence l'implémentation.
```

Sortie intermédiaire : `spec-{slug}.md` (la skill continue ensuite sur l'implémentation).

**Étape 5 — Implémenter, revoir, présenter**

Dans la même invocation, Barry :
1. Implémente chaque tâche du spec en séquence
2. Auto-vérifie chaque critère d'acceptation
3. Lance une revue de code adversariale sur son propre diff
4. Présente un résumé final avec le diff et les points d'attention

**Modes d'entrée alternatifs** :
- **Mode spec existant** : tu pointes un `spec-X.md` déjà écrit (par un humain ou une session précédente). Barry saute la phase clarification et passe directement à l'implémentation.
- **Mode direct** (pour ultra-simple) : tu décris la tâche en une phrase, Barry implémente sans produire de spec formel.

### 6.4 Post-Implémentation Automatique

Après chaque quick-dev, Barry effectue automatiquement :
1. **Audit d'auto-vérification** : Vérifie chaque tâche et critère d'acceptation
2. **Revue de code adversariale** : Lance une revue du diff produit

### 6.5 Détection d'Escalade

Quick Flow inclut des protections : si Barry détecte que la tâche est trop complexe pour Quick Flow, il alerte :

```
Barry : ⚠️ Cette feature touche 8 fichiers, implique une nouvelle
        collection Firestore et nécessite une décision d'architecture.
        Je vous recommande de passer par le processus PRD + Architecture
        complet. Voulez-vous escalader ?
```

---

## 7. Les Agents — Vos Collaborateurs IA

### Vue d'Ensemble

Les agents BMAD sont des **personas IA persistants** avec des personnalités distinctes, des expertises spécialisées, et des styles de communication différents. Ils ne sont pas de simples chatbots génériques — chaque agent a un rôle précis et des limites claires.

> ⚠️ **Point ouvert v6.8.0** : la doc officielle des agents (https://docs.bmad-method.org/reference/agents/) liste explicitement Mary, John, Winston, **Amelia** (qui « handles development stories, code review, QA testing, and sprint planning » — ce qui couvre une bonne partie du rôle de Bob), Sally et Paige. Quinn (QA) est mentionné dans certaines sources. **Bob (Scrum Master) et Barry (Quick Flow Dev) ne sont pas confirmés comme agents dédiés dans v6.8.0** — leurs responsabilités semblent absorbées par Amelia + les skills unifiées (`bmad-sprint-planning`, `bmad-quick-dev`). Les descriptions de Bob et Barry ci-dessous (sections 7.4 et 7.6) **restent valides comme rôles fonctionnels**, mais après installation, vérifiez avec `/bmad-help` quels agents sont réellement présents dans votre installation. Si Bob n'est pas listé, ses skills (sprint planning, create story, retrospective, correct course) sont invoquées directement sans agent dédié — Amelia ou un agent neutre les exécute.

### 7.1 Mary — La Business Analyste 📊

**Commande** : `/bmad-agent-analyst` *(ex-`/bmad-agent-bmm-analyst`)*
**Option dans Party Mode** : `[MH]`

**Personnalité** : Mary traite l'analyse comme une chasse au trésor. Elle est enthousiasmée par chaque indice, pose des questions qui déclenchent des "aha !", et structure les insights avec une précision chirurgicale.

**Expertise** :
- Recherche de marché et analyse concurrentielle
- Élicitation d'exigences (faire parler les parties prenantes)
- Traduction des besoins flous en specs actionnables
- Brainstorming structuré

**Principes de Mary** :
- Tout défi métier a des causes profondes à découvrir
- Fonder les résultats sur des preuves vérifiables
- Articuler les exigences avec précision absolue

**Menu Disponible** :
```
[BP] Session de Brainstorming guidée
[RS] Recherche (marché, domaine, concurrentielle, technique)
[PB] Créer un Product Brief
[DP] Documenter un projet existant
[PM] Party Mode
```

**Exemple d'interaction avec Mary :**
```
Vous : J'ai une idée d'app de livraison pour l'Afrique

Mary : Fascinant ! Avant d'explorer les fonctionnalités,
       je veux comprendre le problème profond.

       Quelle est la plus grande frustration d'un livreur aujourd'hui ?
       Et d'un client qui commande une livraison ?

       [Commence à mapper les pain points avec précision]
```

### 7.2 John — Le Product Manager 📋

**Commande** : `/bmad-agent-pm` *(ex-`/bmad-agent-bmm-pm`)*
**Expérience** : 8+ ans de lancement de produits B2B et consumer

**Personnalité** : John pose "POURQUOI ?" sans relâche comme un détective. Il est direct et précis, coupe le superflu, et ne remplit pas de templates — il fait émerger le PRD d'interviews.

**Expertise** :
- Product management (Jobs-to-be-Done, design centré utilisateur)
- Priorisation et scoring d'opportunité
- Décomposition en Epics et Stories
- Analyse d'impact des changements

**Principes de John** :
- Les PRDs émergent d'interviews, pas de templates
- Livrer le minimum pour valider l'hypothèse
- Chaque feature doit être justifiée par un besoin utilisateur réel

**Menu Disponible** :
```
[PR] Créer PRD (Requis pour flux BMad Method)
[ES] Créer Epics et User Stories (Requis APRÈS Architecture)
[IR] Implementation Readiness Review
[CC] Course Correction Analysis
```

**Style caractéristique de John :**
```
Vous : On veut ajouter une fonctionnalité de rapports

John : POURQUOI les utilisateurs veulent des rapports ?
       Qu'est-ce qu'ils font avec ces données aujourd'hui ?
       Qui dans leur équipe regarde les rapports ?
       À quelle fréquence ?
       Qu'est-ce qu'ils décident grâce à ces rapports ?

       [Ne passe pas à la spec sans comprendre le besoin profond]
```

### 7.3 Winston — L'Architecte 🏗️

**Commande** : `/bmad-agent-architect` *(ex-`/bmad-agent-bmm-architect`)*

**Personnalité** : Winston parle avec des tons calmes et pragmatiques. Il équilibre "ce qui pourrait être" avec "ce qui devrait être". Champion des "boring technologies qui fonctionnent vraiment".

**Expertise** :
- Architecture de systèmes distribués
- Infrastructure cloud et design API
- Patterns scalables et sélection technologique
- ADR (Architecture Decision Records)

**Principes de Winston** :
- Les parcours utilisateurs guident les décisions techniques
- Embrasser la technologie ennuyeuse pour la stabilité
- Connecter chaque décision à la valeur métier
- Simple > Élégant si ça suffit

**Menu Disponible** :
```
[CA] Créer Document d'Architecture
[IR] Implementation Readiness Review
```

**Exemple d'interaction avec Winston :**
```
Vous : Quelle base de données pour mon app mobile ?

Winston : Ça dépend de vos contraintes. Quelques questions :
          - Vos données sont-elles relationnelles (jointures complexes) ?
          - Avez-vous besoin de temps réel ?
          - Votre équipe connaît-elle SQL ?

          Pour une app Flutter avec Firebase Auth,
          Firestore est le choix "ennuyeux" mais pragmatique.
          Il n'aura pas les performances d'un Postgres bien optimisé,
          mais vous serez en production en 2 semaines au lieu de 2 mois.

          Est-ce que ça vous va, ou y a-t-il une raison pour SQL ?
```

### 7.4 Bob — Le Scrum Master 🏃

**Commande** : `/bmad-agent-sm` *(ex-`/bmad-agent-bmm-sm`)* — voir note d'incertitude en tête de section 7

**Personnalité** : Concis et orienté checklist. Chaque mot a un but, chaque exigence cristal clair. Zéro tolérance pour l'ambiguïté.

**Expertise** :
- Cérémonies agiles (sprint planning, retrospectives)
- Préparation de stories pour le développement
- Suivi de sprint et détection de blocages
- Course correction

**Principes de Bob** :
- Frontières strictes entre prep de story et implémentation
- Les stories sont la source unique de vérité
- Alignement parfait entre PRD et exécution dev

**Menu Disponible** :
```
[SP] Sprint Planning (Requis après création Epics+Stories)
[CS] Créer Story (Requis pour préparer stories pour dev)
[ER] Rétrospective d'epic
[CC] Course Correction
```

### 7.5 Amelia — La Développeuse 💻

**Commande** : `/bmad-agent-dev` *(ex-`/bmad-agent-bmm-dev`)*

**Personnalité** : Ultra-succincte. Parle en chemins de fichiers et IDs de critères d'acceptation. Pas de rembourrage, tout précision.

**Expertise** :
- Implémentation stricte des stories approuvées
- TDD (Test-Driven Development)
- Adherence aux patterns du projet existant
- Revue de code adversariale

**Principes critiques d'Amelia** :
- Le Fichier Story est la **seule** source de vérité
- La séquence de tâches est autoritaire sur toute "bonne idée" du moment
- Cycle red-green-refactor : test échouant → le faire passer → améliorer
- **Jamais** implémenter quelque chose hors scope
- **Jamais** mentir sur les tests : ils doivent exister ET passer

**Menu Disponible** :
```
[DS] Executer Dev Story workflow (chemin BMM complet)
[CR] Code review (Hautement recommandé, contexte frais)
```

**Exemple de discipline d'Amelia :**
```
Bob a défini la Story 2.3 : "Ajouter le filtre par date sur la liste des ventes"

Amelia remarque que le code de filtrage pourrait être réutilisé
pour les clients ET les produits.

→ Amelia RÉSISTE à la tentation d'extraire un service générique
→ Elle implémente UNIQUEMENT le filtre pour les ventes
→ Elle documente dans la story : "Note : extraction possible en Story future"
→ Bob crée Story 2.7 : "Extraire FilterService générique"
```

### 7.6 Barry — Le Quick Flow Dev 🚀

**Commande** : `/bmad-agent-quick-flow-solo-dev` *(ex-`/bmad-agent-bmm-quick-flow-solo-dev` — voir note d'incertitude en tête de section 7)*

**Personnalité** : Direct, confiant, orienté implémentation. Utilise le jargon tech et va droit au but. Cérémonie minimale, efficacité implacable.

**Expertise** :
- Quick Flow de bout en bout (spec → implémentation)
- Analyse rapide de codebase
- Tech specs actionnables
- Auto-vérification post-implémentation

**Principes de Barry** :
- Planification et exécution sont les deux faces d'une même pièce
- Les specs servent à construire, pas à la bureaucratie
- Code qui livre est mieux que code parfait qui ne livre pas

### 7.7 Sally — L'UX Designer 🎨

**Commande** : `/bmad-agent-ux-designer` *(ex-`/bmad-agent-bmm-ux-designer`)*

Spécialisée dans la conception d'expérience utilisateur. **Depuis v6.8.0**, produit **deux fichiers** via la skill `bmad-ux` : `DESIGN.md` (tokens visuels) et `EXPERIENCE.md` (flux, états, accessibilité) — voir workflow 2.2.

### 7.8 Murat — Le Test Architect (TEA) 🧪

Disponible uniquement avec le module TEA installé.

Spécialisé dans la stratégie de test de niveau entreprise, la priorisation basée sur les risques (P0-P3), et les décisions de release gate.

### 7.9 Paige — La Technical Writer 📝

**Commande** : `/bmad-agent-tech-writer` *(ex-`/bmad-agent-bmm-tech-writer`)*

Gère la documentation technique : standards de documentation, explications de concepts, guides utilisateur, migrations.

### 7.10 BMad Master 🧙

**Commande** : `/bmad-help` ou chargé automatiquement

**Rôle** : Orchestrateur et expert BMad. Il connaît tous les agents, workflows, et ressources installés. C'est votre guide pour répondre aux questions "Que faire maintenant ?" et "Comment fonctionne telle chose ?".

---

## 8. Les Workflows Détaillés

### 8.1 Tableau de Toutes les Skills (v6.8.0)

| Phase | Skill | Commande | Agent | Sortie |
|-------|----------|---------|-------|--------|
| 1 | Brainstorming | `/bmad-brainstorming` | Mary | `brainstorming-report.md` |
| 1 | Market Research | `/bmad-market-research` | Mary | `market-research-{slug}.md` |
| 1 | Domain Research | `/bmad-domain-research` | Mary | `domain-research-{slug}.md` |
| 1 | Technical Research | `/bmad-technical-research` | Mary | `technical-research-{slug}.md` |
| 1 | Product Brief | `/bmad-product-brief` | Mary | `product-brief.md` + `.decision-log.md` |
| 1 | PR-FAQ *(nouveau)* | `/bmad-prfaq` | Mary/John | `prfaq-{slug}.md` |
| 1/Util | Spec Distillation *(nouveau)* | `/bmad-spec` | neutre | `SPEC.md` + companions + `.decision-log.md` |
| 2 | PRD | `/bmad-prd` | John | `prd.md` + `addendum.md` + `.decision-log.md` |
| 2 | UX *(refonte 2-spine)* | `/bmad-ux` | Sally | `DESIGN.md` + `EXPERIENCE.md` + `.decision-log.md` |
| 3 | Architecture | `/bmad-create-architecture` | Winston | `architecture.md` + ADRs |
| 3 | Epics & Stories | `/bmad-create-epics-and-stories` | John | Fichiers Epic |
| 3 | Readiness Check | `/bmad-check-implementation-readiness` | Winston+John | Rapport PASS/CONCERNS/FAIL |
| 4 | Sprint Planning | `/bmad-sprint-planning` | Bob/neutre | `sprint-status.yaml` |
| 4 | Sprint Status *(nouveau)* | `/bmad-sprint-status` | Bob/neutre | màj `sprint-status.yaml` |
| 4 | Create Story | `/bmad-create-story` | Bob | `story-{slug}.md` |
| 4 | Dev Story | `/bmad-dev-story` | Amelia | Code + tests |
| 4 | Code Review | `/bmad-code-review` | Amelia/agent frais | Approbation/Révisions |
| 4 | Retrospective | `/bmad-retrospective` | Bob | Leçons apprises |
| 4 | Correct Course | `/bmad-correct-course` | Bob+John | Plan mis à jour |
| 4 | Investigate *(nouveau)* | `/bmad-investigate` | Amelia/Winston | `{slug}-investigation.md` (preuves graduées) |
| QF | Quick Dev *(unifié)* | `/bmad-quick-dev` | Barry/Amelia | `spec-{slug}.md` + code |
| Util | Generate Context | `/bmad-generate-project-context` | Winston | `project-context.md` |
| Util | Document Project | `/bmad-document-project` | Paige | Documentation brownfield |
| Util | Workflow Status | `/bmad-workflow-status` | BMad Master | Statut actuel |
| Util | Party Mode | `/bmad-party-mode` | Tous | Conversation collaborative |

### 8.2 Workflow Status — Votre Boussole

**Commande** : `/bmad-workflow-status` *(ex-`/bmad-bmm-workflow-status`)*

Ce workflow répond à la question universelle : **"Où en suis-je et que dois-je faire maintenant ?"**

Il examine l'état de votre projet et recommande la prochaine action :

```
Exemple de sortie :

📍 Statut Actuel : Phase 3 - Solutioning

✅ Complété :
- prd.md (Phase 2)
- DESIGN.md + EXPERIENCE.md (Phase 2)

🔄 En cours :
- architecture.md (Sections 1-4 complétées, section 5 manquante)

📋 Prochaines étapes recommandées :
1. Compléter l'architecture (section Modèle de Données)
2. Exécuter /bmad-create-epics-and-stories
3. Exécuter /bmad-check-implementation-readiness

⚠️ Attention : Les stories ne peuvent pas être créées avant
   que l'architecture soit complète.
```

### 8.3 Generate Project Context

**Commande** : `/bmad-generate-project-context` *(ex-`/bmad-bmm-generate-project-context`)*

Winston scanne votre codebase et produit `project-context.md` — la constitution du projet pour tous les agents futurs (voir Section 14).

---

## 9. Les Commandes Slash

### 9.1 Convention de Nommage (v6.8.0)

> ⚠️ **Le namespace `bmm` a disparu des commandes utilisateur.** Les modules existent toujours en interne (organisation des skills), mais l'utilisateur n'écrit plus le code du module dans la commande.

| Pattern (v6.8.0) | Signification | Exemple |
|---------|--------------|---------|
| `bmad-agent-{nom}` | Lance un agent | `/bmad-agent-dev` |
| `bmad-{skill}` | Exécute une skill | `/bmad-prd`, `/bmad-ux` |
| `bmad-{nom}` | Outil ou tâche core | `/bmad-help`, `/bmad-spec` |

**Anciens patterns v6.0 (obsolètes mais utiles si tu vois une vieille doc)** :
| Pattern (v6.0) | Devient (v6.8.0) |
|---------|--------------|
| `bmad-agent-{module}-{nom}` (ex. `bmad-agent-bmm-dev`) | `bmad-agent-{nom}` (ex. `bmad-agent-dev`) |
| `bmad-{module}-{workflow}` (ex. `bmad-bmm-create-prd`) | `bmad-{skill}` (ex. `bmad-prd`) |

### 9.2 Codes de Modules

| Code | Module |
|------|--------|
| `bmm` | BMad Method (suite agile principale) |
| `bmb` | BMad Builder (création d'agents) |
| `tea` | Test Architect Enterprise |
| `cis` | Creative Intelligence Suite |
| `gds` | Game Dev Studio |

### 9.3 Localisation des Commandes

Selon votre IDE, les commandes sont dans des répertoires différents :

| IDE | Répertoire (v6.8.0) | Extension |
|-----|-----------|-----------|
| Claude Code | **`.claude/skills/`** *(était `.claude/commands/` en v6.0)* | `.md` |
| Cursor | `.cursor/skills/` *(était `.cursor/commands/`)* | `.md` |
| Windsurf | `.windsurf/workflows/` | `.md` |
| Web Bundles *(v6.8+)* | bundle Gemini Gems / ChatGPT | bundle exporté |

> ⚠️ Si vous migrez depuis v6.0, **supprimez manuellement** les anciens `.claude/commands/bmad-*.md` après install — sinon les anciennes commandes coexisteront avec les nouvelles skills et créeront de la confusion.

### 9.4 Utilisation de bmad-help

C'est votre commande principale :

```bash
/bmad-help
/bmad-help J'ai une idée SaaS, par où commencer ?
/bmad-help Quelles sont mes options pour le testing ?
/bmad-help Je suis bloqué sur le workflow PRD
/bmad-help Montre-moi ce qui a été fait jusqu'ici
/bmad-help Comment personnaliser l'agent dev ?
```

`bmad-help` répond à ~80% des questions directement dans l'IDE et recommande toujours la prochaine action concrète.

---

## 10. Party Mode — L'Équipe Complète dans une Salle

### 10.1 Concept

> *"Run party-mode and you've got your whole AI team in one room."*

Party Mode active simultanément tous vos agents BMAD dans une conversation groupée. Le BMad Master orchestre : pour chaque message, il sélectionne 2-3 agents les plus pertinents qui répondent avec leur perspective unique.

Les agents **interagissent authentiquement** — ils sont d'accord, en désaccord, et construisent sur les idées des autres.

### 10.2 Comment l'Activer

```bash
/bmad-party-mode
# Ou depuis n'importe quel agent
[PM]
```

### 10.3 Comment ça Fonctionne Techniquement

1. Le facilitateur charge le manifeste des agents
2. Construit le roster avec toutes les personnalités fusionnées
3. Pour chaque message utilisateur : analyse le domaine d'expertise requis
4. Sélectionne 2-3 agents les plus pertinents
5. Si un agent est directement adressé, il est prioritaire + 1-2 agents complémentaires

### 10.4 Cas d'Usage Optimaux

**Décisions majeures :**
```
Vous : Monolithe ou microservices pour mon MVP ?

Winston (Architect) : Pour un MVP, je recommande fortement le monolithe.
  Les microservices ajoutent une complexité opérationnelle significative
  qui ralentit la vitesse d'itération au stade MVP. Vous pouvez extraire
  des services plus tard si nécessaire.

John (PM) : Je suis d'accord avec Winston sur le timing. Du côté produit,
  la vitesse de mise sur le marché est critique. Chaque semaine perdue
  sur l'infrastructure est une semaine sans feedback utilisateur.

Mary (Analyst) : Un point à considérer : si votre feuille de route inclut
  des équipes indépendantes dans 6 mois, le design modulaire maintenant
  facilitera l'extraction. Quelle est votre vision d'équipe à 12 mois ?
```

**Brainstorming :**
```
Vous : Comment améliorer l'onboarding de notre app ?

Mary : Explorons les causes profondes d'abandon. Où les utilisateurs
  abandonnent-ils dans le flux actuel ? Avez-vous des données analytics ?

Sally : Du côté UX, plusieurs approches : progressive disclosure
  (révéler les features graduellement), onboarding narratif
  (raconter une histoire pendant l'onboarding), ou gamification.

John : Je veux m'assurer qu'on adresse le vrai problème. L'onboarding
  est-il trop long ? Trop compliqué ? Ou les utilisateurs ne comprennent
  pas la valeur dès le début ?
```

**Post-mortem :**
```
Vous : Notre Sprint 2 a pris 3 semaines au lieu de 2. Pourquoi ?

Bob : En regardant le sprint-status.yaml, je vois que Story 2.3
  a été sous-estimée à 2 jours mais a pris 5. Causes ?

Amelia : Story 2.3 avait une dépendance non documentée vers le service
  Firebase Auth qui n'était pas encore configuré en Phase 2.
  La story manquait cette dépendance dans ses prérequis.

John : Côté planning, le PRD n'était pas assez précis sur les
  exigences de sécurité de cette feature. À corriger dans le PRD.
```

### 10.5 Sortir du Party Mode

```
*exit
# ou
goodbye
# ou
end party
```

---

## 11. Revue Adversariale

### 11.1 Définition

Une revue adversariale est une technique où le revieweur **doit** trouver des problèmes. La phrase "ça a l'air bien" est **interdite**.

### 11.2 Pourquoi ça Fonctionne

Le biais de confirmation est réel. Dans une revue normale, on a tendance à chercher la confirmation que le code est correct. En obligeant le revieweur à trouver des problèmes, on force un examen approfondi.

### 11.3 Où BMAD l'Utilise

La revue adversariale apparaît dans **tous** les workflows :
- `code-review` : L'agent doit trouver 3-10 problèmes spécifiques
- `check-implementation-readiness` : Doit trouver les incohérences
- `quick-dev` : Auto-vérification post-implémentation

**Exemple de Code Review Adversarial :**

```
Amelia Review (version normale) :
"Le code est propre, les tests passent, LGTM ✅"

Amelia Review (version adversariale BMAD) :
"Problèmes trouvés :

1. ProductController.saveSheet() ne vérifie pas la connectivité réseau
   avant d'appeler Firestore — crash potential en mode hors ligne

2. L'upload des images se fait en séquentiel, pas en parallèle
   — performance 4x plus lente que nécessaire

3. La méthode analyzePhotos() charge TOUTES les photos en mémoire
   simultanément — OOM possible sur les devices low-end

4. Pas de test pour le cas d'erreur 'quota dépassé' Firebase
   — comportement indéfini en production

5. Le progress indicator ne montre pas de feedback pendant l'upload
   — l'UX semble bloquée pendant 10-30 secondes"
```

### 11.4 Limites à Connaître

**Attention** : Les LLMs peuvent **fabriquer des problèmes** quand on leur demande obligatoirement d'en trouver. Des faux positifs émergent sous forme de :
- Pinaillages stylistiques sans impact réel
- Mauvaises interprétations du code
- Préoccupations inventées

**Règle** : Le jugement humain final filtre les vrais problèmes du bruit.

**Pattern d'itération** : Les deuxièmes revues trouvent souvent des problèmes supplémentaires. Les troisièmes revues justifient rarement l'effort supplémentaire.

---

## 12. Élicitation Avancée

### 12.1 Définition

L'élicitation avancée est une **seconde passe structurée** sur du contenu généré. Au lieu de demander à l'IA de "réessayer" ou "l'améliorer" vaguement, vous sélectionnez une méthode de raisonnement spécifique.

> *"Au lieu de dire 'améliore ça', vous dites 'examine ça sous l'angle de l'analyse pre-mortem'"*

### 12.2 Processus

1. Vous avez un contenu généré (PRD, architecture, story, etc.)
2. Vous demandez à l'agent de proposer des méthodes d'élicitation
3. L'agent suggère 5 méthodes pertinentes pour ce contenu
4. Vous sélectionnez une méthode
5. L'agent ré-examine sa propre sortie à travers ce prisme
6. Vous acceptez, rejetez, répétez, ou continuez

### 12.3 Les 19 Méthodes Disponibles (v6.8.0)

> ⚠️ **v6.0 → v6.8.0** : le catalogue est passé de 8 à 19 techniques, regroupées en catégories. Les 8 originelles restent, 11 nouvelles ont été ajoutées en v6.8.0.

**Catégorie A — Stress-test et adversariale**
| Méthode | Description | Meilleur pour |
|---------|-------------|--------------|
| **Pre-mortem Analysis** | « Dans 6 mois, ce projet a échoué. Pourquoi ? » | Specs, plans, architectures |
| **Red Team vs Blue Team** | L'adversaire contre le défenseur | Sécurité, concurrence |
| **Steelmanning** *(nouveau)* | Reformuler la position adverse sous son meilleur jour avant de la critiquer | Décisions contestées, choix de stack |
| **Inversion Analysis** *(nouveau)* | « Comment garantir l'échec total ? » et inverser | Stratégie, processus |
| **Cascading Failure Simulation** *(nouveau)* | Tracer une panne unique à travers ses effets dominos | Systèmes distribués, paiements |
| **Boundary & Edge Case Sweep** *(nouveau)* | Balayer systématiquement les limites du domaine | Tests, validation de données |

**Catégorie B — Raisonnement structuré**
| Méthode | Description | Meilleur pour |
|---------|-------------|--------------|
| **First Principles** | Déconstruire jusqu'aux vérités fondamentales | Décisions techniques |
| **Chain-of-Thought Scaffolding** *(nouveau)* | Forcer l'IA à exposer son raisonnement étape par étape avant de conclure | Analyses complexes, math |
| **Abstraction Laddering** *(nouveau)* | Monter (pourquoi ?) et descendre (comment ?) l'échelle d'abstraction | Reformulation de problème |
| **Morphological Analysis** *(nouveau)* | Matrice de toutes les combinaisons possibles de dimensions | Design de solution, features |

**Catégorie C — Multi-perspectives**
| Méthode | Description | Meilleur pour |
|---------|-------------|--------------|
| **Six Thinking Hats** *(nouveau)* | Six chapeaux de De Bono (faits, émotions, risques, bénéfices, créativité, contrôle) | Décisions d'équipe, brainstorming |
| **Stakeholder Mapping** | Qui est impacté et comment ? | PRD, features |
| **Delphi Method** *(nouveau)* | Convergence par tours de votes anonymes + justifications | Estimations, priorisation |
| **Analogical Reasoning** | « Comment X résout-il ce problème ? » | Nouveaux domaines |

**Catégorie D — Exploration et innovation**
| Méthode | Description | Meilleur pour |
|---------|-------------|--------------|
| **Inversion** | « Comment ferait-on le contraire ? » | User journeys, UX |
| **Constraint Removal** | « Si on n'avait pas cette contrainte ? » | Innovation, refactoring |
| **Socratic Questioning** | Questionner chaque hypothèse | Exigences ambiguës |

> Trois autres techniques complètent la collection (catégories de validation et de synthèse). Quand tu lances l'élicitation avec un agent en v6.8.0, demande-lui simplement de **lister les 19 options** — il les présentera selon le contexte du contenu à examiner.

### 12.4 `.decision-log.md` — la mémoire des décisions (v6.7+)

Plusieurs skills v6.7+ (`bmad-prd`, `bmad-product-brief`, `bmad-ux`, `bmad-spec`) produisent maintenant un fichier `.decision-log.md` à côté de leur livrable principal. Ce fichier capture **chaque décision prise pendant la skill** au format :

```markdown
## 2026-06-03 — Décision : Cible iOS exclue du MVP
- **Quoi** : Le MVP est Android-first ; iOS reporté à V2.
- **Pourquoi** : 92 % du marché smartphone camerounais est Android (cf. domain-research-cm.md).
  Le coût de validation iOS (compte développeur Apple, app review) consomme 2 semaines pour
  un gain marginal en V1.
- **Qui** : Roosvelt (validé) ; John (PM) a proposé.
- **Impact aval** : architecture mobile ne déclare plus iOS dans ses plateformes cibles ;
  Cloud Functions région inchangée.
- **Réversibilité** : moyenne — réintroduire iOS demandera de retester chaque flux.
```

**Pourquoi c'est important** : sans ce journal, une décision prise en PRD est oubliée 3 mois plus tard et un agent ressuscite l'option écartée. Le `.decision-log.md` est lu automatiquement par les skills aval — Winston, Bob, Amelia voient les décisions PM et UX sans avoir besoin de relire toute la conversation.

**Différence avec un ADR** :
- **ADR** = décision **technique** (architecture, stack, pattern) figée dans `project_manage/planning-artifacts/adrs/`.
- **`.decision-log.md`** = décisions **produit / scope / UX** prises pendant une skill, vivant à côté du livrable de cette skill.

Les deux coexistent.

### 12.4 Exemple Concret — Pre-mortem sur un PRD

```
[Après génération du PRD pour une app de livraison]

Vous : Applique l'analyse pre-mortem à ce PRD

John : Je vais imaginer que le produit a échoué après 6 mois.

Scénario d'échec 1 : Les livreurs abandonnent l'app
→ Cause racine possible : L'app consomme trop de données mobiles.
→ Le PRD ne spécifie pas de contrainte sur la consommation données.
→ Correction recommandée : Ajouter NFR "< 50MB/jour d'utilisation active"

Scénario d'échec 2 : Les restaurants refusent d'intégrer l'API
→ Cause racine possible : L'onboarding restaurant est trop complexe.
→ Le PRD suppose que les restaurants ont une équipe IT.
  La majorité sont des PME sans IT.
→ Correction recommandée : Ajouter un mode "restaurant sans API" (QR codes)

Scénario d'échec 3 : Les paiements échouent en zone rurale
→ Le PRD ne mentionne que Mobile Money MTN.
  Orange Money est dominant dans certaines régions.
→ Correction : Ajouter Orange Money comme exigence P1

Recommandation : 3 modifications significatives au PRD avant de continuer.
```

### 12.5 Recommandation

> *"L'analyse Pre-mortem est un bon premier choix pour tout spec ou plan. Elle trouve constamment des lacunes qu'une revue standard manque."*

---

## 13. Prévention des Conflits d'Agents

### 13.1 Le Problème des Conflits

Quand plusieurs agents IA implémentent différentes parties d'un système **sans référence architecturale commune**, ils prennent des décisions techniques conflictuelles.

### 13.2 Types de Conflits Courants

**Conflit 1 : Style d'API**
```
Epic 1 → Agent A crée des endpoints REST
Epic 2 → Agent B crée des resolvers GraphQL
Epic 3 → Agent C crée des méthodes RPC

→ Résultat : 3 styles d'API différents dans la même app
→ Coût de correction : Réécriture complète du layer API
```

**Conflit 2 : Gestion d'État**
```
Feature Auth → Redux Toolkit
Feature Cart → React Context
Feature Orders → Zustand

→ Résultat : 3 systèmes de state management dans le même projet
→ Coût : Confusion développeur, bugs difficiles à déboguer
```

**Conflit 3 : Conventions Base de Données**
```
Agent 1 : `user_id`, `created_at` (snake_case)
Agent 2 : `userId`, `createdAt` (camelCase)
Agent 3 : `UserId`, `CreatedAt` (PascalCase)

→ Résultat : Inconsistance totale du schéma
→ Coût : Migrations + refactoring
```

### 13.3 La Solution : L'Architecture comme Contexte Partagé

```
PRD : "Quoi construire"
    ↓
Architecture : "Comment construire — règles pour TOUS les agents"
    ↓
Epic 1 (Agent 1) lit l'architecture → respecte les règles
Epic 2 (Agent 2) lit l'architecture → respecte les mêmes règles
Epic 3 (Agent 3) lit l'architecture → respecte les mêmes règles
    ↓
Résultat : Cohérence parfaite
```

### 13.4 Sujets ADR Critiques à Documenter

| Domaine | Décision à documenter |
|---------|----------------------|
| Style API | REST vs GraphQL vs gRPC |
| Base de données | Choix BDD + conventions de nommage |
| Authentification | JWT vs Sessions + durée + stockage |
| Gestion d'état | Un seul système (Redux OU Context OU Zustand) |
| Style CSS/UI | Un seul framework (Tailwind OU Styled-Components) |
| Testing | Jest + Playwright OU Vitest + Cypress |
| Logging | Format de logs + niveaux |
| Gestion d'erreurs | Pattern uniforme de gestion d'erreurs |

### 13.5 Anti-Patterns à Éviter

**Anti-pattern 1 : Décisions implicites**
```
❌ "On utilisera une BDD relationnelle" (documenté nulle part)
✅ ADR-003 : "PostgreSQL sur Railway. camelCase pour toutes les colonnes."
```

**Anti-pattern 2 : Sur-documentation**
```
❌ Documenter chaque nom de variable comme une décision d'architecture
✅ Documenter uniquement les décisions qui impactent plusieurs agents/epics
```

**Anti-pattern 3 : Architecture obsolète**
```
❌ Architecture mise à jour mais les agents ne le savent pas
✅ Toujours régénérer project-context.md après une mise à jour d'architecture
```

---

## 14. Le Fichier project-context.md

### 14.1 Définition

`project-context.md` est la **constitution de votre projet** pour les agents IA. C'est un fichier unique qui capture tout ce qu'un agent doit savoir pour générer du code cohérent avec le reste du projet.

**Emplacement** : `project_manage/project-context.md`

### 14.2 Ce qu'il Contient

Winston le génère en scannant votre codebase pour capturer :

```markdown
# Project Context : Next Sales

## Stack Technologique
- Flutter 3.27+ avec Dart 3.10+
- Firebase (Auth, Firestore, Storage, Functions)
- GetX pour gestion d'état et navigation
- flutter_screenutil pour le responsive (design size: 390x844)

## Structure de Fichiers
- lib/domain/ — Entités et interfaces (pur Dart, pas de dépendances)
- lib/data/ — Datasources et repositories impl
- lib/presentation/ — Modules, vues, controllers

## Conventions de Nommage
- Controllers : NomController extends GetxController
- Vues : NomView extends GetView<NomController>
- Modèles : NomModel (avec toJson/fromJson)
- Routes : AppRoutes.nomRoute = '/nom-route'

## Patterns Obligatoires
- JAMAIS utiliser print() → Toujours LogService.i/d/w/e()
- State réactif : nomVar.obs, Rxn<Type>() pour nullable
- UI feedback : UIFeedback.showSuccess/Error/Warning/Info()
- BusinessId : toujours depuis BusinessSessionService.activeBusinessId.value

## Gestion d'Erreurs
- try/catch dans tous les appels async
- LogService.e() pour les erreurs
- UIFeedback.showError() pour montrer à l'utilisateur

## Tests
- tests dans test/ mirroring lib/
- run: flutter test test/path/to/test.dart
```

### 14.3 Comment le Générer

```bash
/bmad-generate-project-context
```

Winston scanne automatiquement votre code existant et produit le fichier.

### 14.4 Quand le Régénérer

- Après une mise à jour majeure de l'architecture
- Quand de nouveaux patterns sont établis dans le projet
- Avant de commencer une nouvelle phase d'implémentation
- Si les agents commencent à générer du code inconsistant

### 14.5 Usage dans les Workflows

Chaque workflow d'implémentation charge automatiquement `project-context.md` s'il existe. Les agents ajustent leur génération de code en conséquence.

---

## 15. Personnalisation des Agents

### 15.1 Règle Fondamentale

**Ne jamais éditer directement les fichiers agents** dans `_bmad/bmm/agents/`. Ces fichiers sont **écrasés** lors des mises à jour. Utilisez les fichiers `.customize.yaml`.

```
❌ Éditer _bmad/bmm/agents/dev.md directement
✅ Créer _bmad/_config/agents/bmm-dev.customize.yaml
```

### 15.2 Emplacement des Fichiers de Personnalisation

```
_bmad/
└── _config/
    └── agents/
        ├── core-bmad-master.customize.yaml
        ├── bmm-dev.customize.yaml
        ├── bmm-pm.customize.yaml
        ├── bmm-architect.customize.yaml
        └── bmm-analyst.customize.yaml
```

### 15.3 Options de Personnalisation

| Section | Comportement | Ce que vous pouvez faire |
|---------|-------------|-------------------------|
| `agent.metadata` | Remplace | Changer nom d'affichage, icône |
| `persona` | Remplace | Définir rôle, identité, style, principes |
| `memories` | Ajoute | Contexte persistant que l'agent garde toujours en tête |
| `menu` | Ajoute | Nouveaux éléments de menu |
| `critical_actions` | Ajoute | Instructions exécutées au démarrage |
| `prompts` | Ajoute | Prompts réutilisables |

### 15.4 Exemple Complet de Personnalisation

Personnaliser Amelia pour qu'elle connaisse les spécificités de votre projet :

```yaml
# _bmad/_config/agents/bmm-dev.customize.yaml

memories:
  - "Ce projet utilise Flutter + Firebase + GetX. JAMAIS de print(),
     toujours LogService. Les controllers héritent de GetxController."
  - "Toutes les données sont scopées sous businesses/{businessId}/.
     Récupérer le businessId depuis BusinessSessionService.activeBusinessId.value"
  - "Pour les dates, toujours utiliser FieldValue.serverTimestamp() dans Firestore,
     jamais DateTime.now() directement."
  - "L'interface est en français. Tous les messages d'erreur en français."

critical_actions:
  - "Au démarrage, lire project-context.md si il existe"
  - "Avant de créer un nouveau fichier, vérifier si un pattern similaire existe"
```

### 15.5 Personnaliser la Persona

```yaml
# bmm-pm.customize.yaml

persona:
  role: "Product Manager spécialisé marché africain"
  identity: |
    Expert en product management avec focus sur l'Afrique subsaharienne.
    Connais les contraintes locales : connectivité limitée, paiement mobile money,
    multilinguisme (français + langues locales).
  communication_style: |
    Toujours contextualiser les décisions dans le cadre africain.
    Poser des questions sur les contraintes réseau, les habitudes de paiement.
  principles: |
    - La feature doit marcher sur un téléphone Android entrée de gamme
    - Mobile money (MTN, Orange) est le premier moyen de paiement
    - Le service doit fonctionner avec une connexion intermittente
```

### 15.6 Appliquer les Changements

Après toute modification de `.customize.yaml` :

```bash
npx bmad-method install
# Choisir "Recompile Agents" (option la plus rapide)
```

---

## 16. Testing — Quinn vs TEA

### 16.1 Vue d'Ensemble

BMAD offre deux approches de testing selon la complexité du projet.

### 16.2 Quinn — QA Intégré (Rapide et Simple)

**Disponible** : Inclus dans le module BMM (aucune installation supplémentaire)
**Cible** : Petits à moyens projets
**Commande** : `[QA]` depuis n'importe quel agent, ou `/bmad-qa-automate` *(ex-`/bmad-bmm-qa-automate`)*

**Workflow Quinn en 5 étapes :**

1. **Détection** : Scanne les frameworks de test (Jest, Vitest, Playwright, Cypress)
2. **Identification** : Trouve les features via votre input ou découverte automatique
3. **Tests API** : Génère des tests couvrant codes de statut, structure de réponse, happy path, 1-2 cas d'erreur
4. **Tests E2E** : Génère tests avec locateurs sémantiques et assertions de résultats visibles
5. **Exécution** : Lance les tests, corrige les échecs immédiatement

**Exemple avec Quinn :**
```
Quinn : J'ai détecté Flutter + flutter_test.
        Quelles features voulez-vous tester ?

Vous : La création d'une vente

Quinn : [Génère automatiquement :]
        - test_sale_creation_happy_path()
        - test_sale_creation_no_client_error()
        - test_sale_creation_offline_error()
        - test_sale_amount_validation()
```

### 16.3 TEA — Test Architect Enterprise (Complet)

**Installation** : `npx bmad-method install --modules tea`
**Cible** : Grands projets, domaines réglementés, équipes multi-agents
**Agent** : Murat (Master Test Architect)

**9 Workflows TEA :**

| Workflow | Commande | Objectif |
|----------|---------|---------|
| Test Design | `/bmad-tea-test-design` | Stratégie comprehensive liée aux exigences |
| ATDD | `/bmad-tea-atdd` | Tests d'acceptation AVANT le code |
| Automate | `/bmad-tea-automate` | Génération tests avec patterns avancés |
| Test Review | `/bmad-tea-test-review` | Valide qualité et couverture |
| Traceability | `/bmad-tea-trace` | Mappe tests aux exigences pour conformité |
| NFR Assessment | `/bmad-tea-nfr` | Évalue les exigences non-fonctionnelles |
| CI Setup | `/bmad-tea-ci` | Configure exécution tests dans pipelines |
| Framework | `/bmad-tea-framework` | Met en place l'infrastructure de test |
| Release Gate | `/bmad-tea-release-gate` | Décision go/no-go basée sur les données |

**Comparaison Quinn vs TEA :**

| Dimension | Quinn | TEA |
|-----------|-------|-----|
| Installation | Inclus | `npm install` |
| Workflows | 1 | 9 |
| Approche | Happy path + edge cases | Priorisation basée risque P0-P3 |
| Release gate | Non | Oui |
| Traceabilité | Non | Oui |
| Conformité réglementaire | Non | Oui |
| Recommandé pour | Startups, MVP, side projects | Entreprise, fintech, santé |

### 16.4 ATDD — Tests d'Acceptation Avant le Code

L'approche TEA ATDD suit le cycle TDD :

```
1. Écrire le test d'acceptation (Given/When/Then)
2. Le test ÉCHOUE (red) ✗
3. Écrire le minimum de code pour le faire passer
4. Le test PASSE (green) ✓
5. Refactoriser (refactor) ♻️
6. Répéter pour la tâche suivante
```

**Exemple ATDD :**
```dart
// ÉCRIT EN PREMIER, avant le code :
test('Création de vente — happy path', () async {
  // Given
  final controller = SaleController(...);
  final client = Client(id: 'c1', name: 'Fatou');
  final product = Product(id: 'p1', name: 'Tissu', salePrice: 5000);

  // When
  await controller.createSale(client: client, product: product, quantity: 2);

  // Then
  expect(controller.sales.length, equals(1));
  expect(controller.sales.first.total, equals(10000));
  verify(mockRepository.saveSale(any)).called(1);
});
```

---

## 17. Les Modules Officiels

### 17.1 BMad Method (BMM) — Le Core

**Code** : `bmm`
**Contenu** : 34+ workflows, 9 agents

C'est le module principal. Il contient tout ce dont vous avez besoin pour un développement agile complet : de l'idée jusqu'au code en production.

### 17.2 BMad Builder (BMB) — Créez Vos Propres Agents

**Code** : `bmb`

Le méta-module qui vous permet de créer vos propres agents, workflows et modules customisés :

- **Agent Builder** : Créer des agents IA spécialisés avec expertise personnalisée
- **Workflow Builder** : Concevoir des processus structurés avec étapes et points de décision
- **Module Builder** : Packager et publier des modules partageables

**Cas d'usage** :
```
Vous avez besoin d'un agent spécialisé "Expert Droit OHADA"
pour votre app de gestion juridique en Afrique.

BMB vous guide pour créer :
- La persona de l'agent
- Son menu de commandes
- Ses workflows spécifiques
- Le package publiable
```

### 17.3 Creative Intelligence Suite (CIS)

**Code** : `cis`

Outils pour la créativité structurée et l'idéation :

- Innovation Strategist
- Design Thinking Coach
- Brainstorming Coach
- Problem Solver / Creative Problem Solver
- Storyteller
- Presentation Master

Frameworks intégrés : SCAMPER, Reverse Brainstorming, reformulation de problèmes.

### 17.4 Test Architect Enterprise (TEA)

**Code** : `tea`

Stratégie de test de niveau entreprise (voir Section 16.3).

### 17.5 Game Dev Studio (GDS)

**Code** : `gds`

Workflows de développement de jeux supportant Unity, Unreal, Godot :

- Game Design Document automatique
- Mode Quick Dev pour jeux
- Design narratif assisté
- Support 21+ types de jeux

---

## 18. Migration de V4 vers V6 (et v6.0 → v6.8.0)

### 18.0 Migration intra-V6 : v6.0 → v6.8.0

Si tu as installé BMAD en v6.0 (mars 2026) et tu mets à jour vers v6.8.0 (mai-juin 2026), tu n'as pas une migration majeure, mais plusieurs changements à connaître :

| Changement | Action requise |
|---|---|
| Préfixe commandes `/bmad-bmm-X` → `/bmad-X` | Aucune édition manuelle ; après `npx bmad-method install`, mettre à jour tes raccourcis IDE / scripts |
| Skills installées dans `.claude/skills/` (vs `.claude/commands/`) | **Supprimer manuellement** `.claude/commands/bmad-*.md` après update, sinon coexistence ambiguë |
| `bmad-create-ux-design` retiré → `bmad-ux` | Si tu as un `ux-spec.md` existant : le redécouper manuellement en `DESIGN.md` + `EXPERIENCE.md`, ou lancer `/bmad-ux` en intent `Validate` pour migration assistée |
| `bmad-distillator` retiré → `bmad-spec` | Custom workflows qui appelaient `distillator` : remapper vers `bmad-spec` |
| `bmad-quick-spec` + `bmad-quick-dev` → `bmad-quick-dev` unifié | Mettre à jour les habitudes : une seule commande au lieu de deux |
| Manifests `after`/`before` → `preceded-by`/`followed-by` | Si tu as des manifests custom (BMB) : rename des clés JSON / colonnes CSV |
| 8 → 19 techniques d'élicitation | Profiter des nouvelles, aucune migration |
| Nouvelles skills (`prfaq`, `investigate`, `sprint-status`) | Aucune migration, à découvrir |

**Procédure recommandée** :
```bash
# 1. Backup
git add -A && git commit -m "pre-v6.8.0 backup"

# 2. Mettre à jour
npx bmad-method install --action update

# 3. Nettoyer les anciennes commandes IDE v6.0
rm -f .claude/commands/bmad-*.md
# (équivalent Windows : Remove-Item .claude/commands/bmad-*.md)

# 4. Vérifier que les nouvelles skills sont bien installées
ls .claude/skills/
/bmad-help
```

### 18.1 Changements Majeurs V4 → V6

| Aspect | BMAD V4 | BMAD V6 |
|--------|---------|---------|
| Répertoire core | `_bmad-core/` (était BMad Method) | `_bmad/core/` (framework universel) |
| Répertoire méthode | `_bmad-method/` | `_bmad/bmm/` |
| Configuration | Modifications directes | `config.yaml` par module |
| Gestion docs | Sharding pré-planifié | Scan automatique |
| Personnalisation agents | Édition directe | Fichiers `.customize.yaml` |
| Concept central | Workflows | Skills (depuis v6.8.0) |
| Préfixe commandes | `bmad-{module}-{nom}` | `bmad-{nom}` (depuis v6.8.0) |

### 18.2 Étapes de Migration

```bash
# 1. Lancer l'installateur (détecte V4 automatiquement)
npx bmad-method install

# 2. L'installateur propose :
# → Backup automatique de _bmad-core/ et _bmad-method/
# → Ou nettoyage manuel si vous préférez

# 3. Après installation V6, nettoyer les commandes IDE V4
# (ex: .claude/commands/BMad/agents/*.md — ancienne structure)

# 4. Migrer les artefacts de planification
cp project_manage-v4/*.md project_manage/planning-artifacts/

# 5. Régénérer project-context.md
# /bmad-generate-project-context
```

### 18.3 Migration du Développement en Cours

Si vous avez des stories en cours de développement :

1. Copier les fichiers story vers `project_manage/implementation-artifacts/`
2. Vérifier que le sprint-status.yaml est bien structuré (nouveau format V6)
3. Relancer `bmad-help` pour vérifier que tout est détecté correctement

---

## 19. Projets Existants (Brownfield)

### 19.1 Définition

Un projet **brownfield** est un projet déjà existant dans lequel vous intégrez BMAD. Différent du **greenfield** (nouveau projet de zéro).

### 19.2 Approche Recommandée

**Étape 1 : Documenter l'existant**
```bash
/bmad-document-project
# Paige scanne votre codebase et génère une documentation complète
```

**Étape 2 : Générer le project context**
```bash
/bmad-generate-project-context
# Winston analyse les patterns existants et crée project-context.md
```

**Étape 3 : Choisir votre piste selon la taille du changement**

| Type de changement | Piste recommandée |
|-------------------|------------------|
| Bug fix | Quick Flow |
| Petite feature (< 5 fichiers) | Quick Flow |
| Feature moyenne (5-15 fichiers) | Quick Flow avec quick-spec |
| Feature majeure (15+ fichiers) | BMad Method complet |
| Refactoring architectural | BMad Method complet |
| Nouveau module entier | BMad Method complet |

### 19.3 Points d'Attention pour Brownfield

**L'architecture existante prime** :

Winston scanne la documentation existante pour éviter de recommander des changements qui contredisent des décisions déjà prises. Si votre projet utilise déjà REST, Winston ne recommandera pas GraphQL dans un ADR.

**Les agents respectent les patterns existants** :

Grâce au `project-context.md` généré depuis le code existant, tous les agents respecteront les conventions déjà établies. Amelia ne créera pas un nouveau pattern d'état si GetX est déjà utilisé partout.

**Gestion progressive** :

Pour les grands projets brownfield, il est normal de commencer par Quick Flow pour les changements immédiats, puis d'intégrer progressivement la méthode complète pour les nouvelles features.

---

## 20. Bonnes Pratiques et Anti-Patterns

### 20.1 Bonnes Pratiques

**✅ DO : Commencer par bmad-help**
```
/bmad-help J'ai terminé le PRD, que faire maintenant ?
```
Ne cherchez pas à deviner. `bmad-help` sait exactement où vous en êtes.

**✅ DO : Documenter les décisions importantes**

Chaque fois que vous prenez une décision technique significative qui n'est pas dans l'architecture, ajoutez un ADR immédiatement. Ne laissez pas les décisions implicites.

**✅ DO : Valider avant chaque phase**

```
Phase 2 terminée → Relire le PRD entier avant de passer à l'Architecture
Phase 3 terminée → Exécuter check-implementation-readiness avant le dev
```

**✅ DO : Utiliser Party Mode pour les décisions difficiles**

Si vous ne savez pas quelle approche choisir entre deux options, invitez Winston, John et Mary en Party Mode. Leurs perspectives croisées éclaireront la décision.

**✅ DO : Régénérer project-context.md régulièrement**

Après chaque sprint, si de nouveaux patterns ont émergé, régénérez `project-context.md`.

**✅ DO : Contextualiser Quick Flow correctement**

Même en Quick Flow, donnez à Barry assez de contexte :
```
❌ "Ajouter un filtre"
✅ "Dans ProductListView (lib/presentation/modules/products/views/product_list_view.dart),
    ajouter un filtre par catégorie. Les catégories viennent de ProductController.categories.
    Utiliser le même pattern de filtre que ClientListView qui a un filtre par date."
```

**✅ DO : Un contexte frais pour les revues de code**

Ouvrez une nouvelle conversation pour la revue de code. Un agent qui vient de coder est biaisé.

### 20.2 Anti-Patterns

**❌ DON'T : Sauter le Solutioning pour une app multi-epics**

```
// Terrible idée :
PRD ✓ → Implémenter directement → CHAOS

// La bonne approche :
PRD ✓ → Architecture ✓ → Epics ✓ → Implémenter → Cohérence
```

**❌ DON'T : Demander à Amelia de "tout améliorer" pendant une story**

Amelia implémente la story. Elle ne refactorise pas le code autour, n'ajoute pas de features bonus, n'extrait pas de services génériques. Hors scope = hors scope.

**❌ DON'T : Éditer directement les fichiers agents**

```bash
# ❌ Ne jamais faire :
nano _bmad/bmm/agents/dev.md

# ✅ Toujours utiliser :
# Éditer _bmad/_config/agents/bmm-dev.customize.yaml
# puis : npx bmad-method install (Recompile Agents)
```

**❌ DON'T : Utiliser Quick Flow pour une feature architecturalement complexe**

Si la feature nécessite :
- Un nouveau modèle de données
- Une nouvelle décision d'API
- Une coordination entre plusieurs modules

→ Escaladez vers BMad Method complet.

**❌ DON'T : Ignorer les résultats du check-implementation-readiness**

Si le résultat est FAIL ou CONCERNS, ne pas commencer l'implémentation. Corriger d'abord.

**❌ DON'T : Laisser les conflits d'agents se résoudre d'eux-mêmes**

Si deux stories ont des approches contradictoires détectées pendant l'implémentation, STOP. Décider dans l'architecture, documenter en ADR, puis continuer.

---

## 21. Exemples Complets Pas-à-Pas

### 21.1 Exemple Greenfield : Créer une App de Gestion de Ventes

#### Contexte
Vous voulez créer "VenteApp", une application mobile pour que les vendeurs africains suivent leurs ventes.

#### Étape 1 : Installation
```bash
cd venteapp
npx bmad-method install
# → Module : BMM
# → IDE : claude-code
# → Langue : French
```

#### Étape 2 : Brainstorming (Phase 1)
```
/bmad-agent-analyst
[BP] Session de Brainstorming

Mary : Parlons de VenteApp. Quel problème spécifique résolvez-vous ?
Vous : Les vendeurs oublient de relancer les clients impayés
Mary : [Session de 45 min]
→ Sortie : brainstorming-report.md avec 12 insights structurés
```

#### Étape 2bis : Distiller en SPEC (recommandé v6.8+)
```
/bmad-spec
→ Sortie : SPEC.md (5 champs : Problem, Capabilities, Constraints, Non-goals, Success signal)
   + companions (catalogue de features candidates)
   + .decision-log.md
```
Le `SPEC.md` sert ensuite d'entrée concise au PRD plutôt que le brainstorming complet.

#### Étape 3 : PRD (Phase 2) — mode Coaching pour un premier PRD
```
/bmad-prd
Intent : Create
Mode : Coaching

John : [Interview de 60 min en mode coaching, explique chaque concept]
→ Sortie : prd.md (8 FRs, 4 NFRs, 2 personas) + .decision-log.md
```

#### Étape 3bis : UX (Phase 2) — deux fichiers scellés
```
/bmad-ux
Intent : Create
Mode : Coaching

Sally : [Session UX]
→ Sortie : DESIGN.md (tokens) + EXPERIENCE.md (flux, états, a11y) + .decision-log.md
```

#### Étape 4 : Architecture (Phase 3)
```
/bmad-agent-architect
[CA] Créer Architecture

Winston : [Session de 30 min, consulte prd.md + DESIGN.md + EXPERIENCE.md + .decision-log.md]
→ Sortie : architecture.md + 5 ADRs
```

#### Étape 5 : Vérification Readiness
```
/bmad-check-implementation-readiness
→ Résultat : CONCERNS (2 stories ambiguës)
→ Corriger les stories concernées
→ Re-run : PASS ✓
```

#### Étape 6 : Sprint Planning
```
/bmad-sprint-planning
→ Sortie : sprint-status.yaml (3 epics, 18 stories)
```

#### Étape 7 : Implémentation (Sprint 1)
```
# Story 1.1 — Login
/bmad-create-story  → story-1-1-login.md
/bmad-dev-story     → Implémente story-1-1
/bmad-code-review   → Revue adversariale → 3 issues trouvées → corrigées

# Story 1.2 — Onboarding
/bmad-create-story  → story-1-2-onboarding.md
/bmad-dev-story     → Implémente story-1-2
/bmad-code-review   → Revue → LGTM

# Bug récurrent en cours de sprint ? → Investigate
/bmad-investigate   → diagnostic forensique avec preuves graduées
                     (Confirmed / Deduced / Hypothesized)

# ... (repeat pour chaque story)
```

#### Étape 8 : Retrospective Sprint 1
```
/bmad-retrospective
→ Epic 1 complété en 10 jours (estimé 8 — OK)
→ Leçons : Firebase Auth setup + 2 jours → ajouter à project-context.md
```

### 21.2 Exemple Quick Flow : Ajouter un Bouton Partager

#### Contexte
Sur un projet existant, ajouter un bouton "Partager" sur la page produit.

#### Étape unique : Quick Dev unifié (v6.8.0)
```
/bmad-quick-dev

Barry : Décris la feature.
Vous : Ajouter un bouton share sur ProductDetailView qui génère
       un lien https://catalog.app/{businessId}/{productId}
       et utilise le système de partage natif iOS/Android

Barry : [Scanne ProductDetailView, ProductController, AppRoutes]
Barry : [Propose le spec — vous approuvez]
        → Spec intermédiaire : spec-share-product.md

Barry : [Implémente les 5 tâches en séquence]
Barry : [Auto-vérification : 3/3 critères d'acceptation validés]
Barry : [Revue de code adversariale : 1 issue trouvée — businessId null]
Barry : [Corrige l'issue]
Barry : [Présentation finale du diff]
→ Résultat : Feature complète en 15 minutes, une seule commande
```

### 21.3 Exemple Party Mode : Choisir le Bon Stack

#### Contexte
Vous avez un nouveau projet mais hésitez entre plusieurs technologies.

```
/bmad-party-mode

Vous : On doit choisir entre React Native et Flutter pour notre app.
       On a une équipe de 2 devs JS, on vise iOS et Android, MVP en 3 mois.

Winston : Techniquement, les deux sont viables pour votre timeline.
          Flutter offre des performances natives et une UI plus cohérente,
          mais votre équipe devra apprendre Dart.
          React Native réutilise vos connaissances JS,
          mais les bridges natifs peuvent causer des frictions.

          Ma question : Avez-vous des composants UI complexes (animations,
          listes longues, formulaires dynamiques) dans votre MVP ?

John : Du côté produit, 3 mois pour un MVP est serré.
       La courbe d'apprentissage Dart représente probablement 2-3 semaines.
       Si votre équipe est solide en React, RN permet de livrer plus vite
       en phase 1. On peut toujours réévaluer pour V2.

Mary : Une donnée importante : votre marché cible.
       Si vous visez aussi les marchés avec des appareils Android basse gamme,
       Flutter a un avantage significatif en termes de performance.
       Quelle est la distribution device de vos utilisateurs cibles ?

→ Discussion continue...
→ Décision documentée en ADR-001
```

---

## 22. Ressources et Communauté

### 22.1 Documentation Officielle

| Ressource | URL |
|-----------|-----|
| Documentation principale | https://docs.bmad-method.org/ |
| Getting Started | https://docs.bmad-method.org/tutorials/getting-started/ |
| Référence Agents | https://docs.bmad-method.org/reference/agents/ |
| Référence Workflows | https://docs.bmad-method.org/reference/workflow-map/ |
| Référence Commandes | https://docs.bmad-method.org/reference/commands/ |
| Guide Installation | https://docs.bmad-method.org/how-to/install-bmad/ |
| Fichier AI-optimisé | https://bmad-code-org.github.io/BMAD-METHOD/llms-full.txt |

### 22.2 GitHub

```
Repository : https://github.com/bmad-code-org/BMAD-METHOD
Issues : Bugs vérifiés
Discussions : Conversations générales
```

### 22.3 Communauté Discord

**Serveur** : discord.gg/gk8jAdXWmj

| Channel | Usage |
|---------|-------|
| `#bmad-method-help` | Questions en temps réel |
| `#help-requests` | Questions détaillées, recherchables |
| `#suggestions-feedback` | Propositions d'amélioration |
| `#report-bugs-and-issues` | Documentation de bugs |

### 22.4 Autres Ressources

- **YouTube** : @BMadCode (tutoriels vidéo)
- **Podcast** : The BMad Method Podcast (lancé mars 2026)
- **bmad-help dans l'IDE** : Votre première source pour toute question

### 22.5 Résumé des Informations Clés

| Info | Détail |
|------|--------|
| Nom complet | Breakthrough Method for Agile AI-Driven Development |
| Licence | MIT (100% gratuit, open source) |
| **Version actuelle** | **v6.8.0 (25 mai 2026)** |
| Releases récentes | v6.6.0 (29 avr.), v6.7.0 (17 mai), v6.7.1 (18 mai), v6.8.0 (25 mai) |
| GitHub stars | 38 900+ (en croissance) |
| Créé | Avril 2025 |
| Node.js requis | v20+ |
| IDEs supportés | Claude Code, Cursor, Windsurf, Kiro, GitHub Copilot |
| Exécution hors-IDE | **Web Bundles v1.0** (Gemini Gems, ChatGPT) — *nouveau v6.8.0* |

### 22.6 Web Bundles v1.0 (nouveau, v6.8.0)

Les **Web Bundles** permettent d'exécuter des skills BMAD **hors d'un IDE**, dans :
- **Gemini Gems** (Google) : un Gem personnalisé qui agit comme une skill BMAD
- **ChatGPT** (Custom GPTs) : import du bundle pour transformer un Custom GPT en agent BMAD

Le bundle est un fichier auto-contenu avec **parité de schéma** avec la skill IDE : mêmes entrées, mêmes sorties, mêmes intents. La planification (Phase 1-2) peut donc être faite depuis un téléphone ou un poste sans IDE, et les artefacts importés ensuite dans le projet IDE pour la Phase 3-4.

**Cas d'usage Valide** : un PM ou un stakeholder non-dev pourrait piloter la création du PRD ou du Product Brief via un Custom GPT BMAD, puis t'envoyer les `.md` produits pour intégration dans `project_manage/`.

---

## Annexe A — Glossaire

| Terme | Définition |
|-------|-----------|
| **ADR** | Architecture Decision Record — mini-document capturant une décision **technique** |
| **Agent** | Persona IA spécialisé avec rôle, expertise et style de communication définis |
| **Artefact** | Document produit par une skill (PRD, architecture, story, etc.) |
| **ATDD** | Acceptance Test-Driven Development — écrire les tests d'acceptation avant le code |
| **Brownfield** | Projet existant dans lequel on intègre BMAD |
| **Context Chain** | Chaîne de contexte — chaque artefact alimente les phases suivantes |
| **`.decision-log.md`** *(v6.7+)* | Journal des décisions **produit / scope / UX** prises pendant une skill ; complète les ADR |
| **DESIGN.md** *(v6.8+)* | Tokens visuels (couleurs, typo, espacements, ombres) — un des deux fichiers de `bmad-ux` |
| **Epic** | Regroupement de stories liées représentant une grande fonctionnalité |
| **EXPERIENCE.md** *(v6.8+)* | Comportement, flux, IA, états, accessibilité — second fichier de `bmad-ux` |
| **FR** | Functional Requirement — exigence fonctionnelle (« l'utilisateur peut… ») |
| **Greenfield** | Nouveau projet de zéro |
| **Headless mode** | Exécution d'une skill avec entrée/sortie JSON, sans conversation (pour pipelines) |
| **Investigate** *(v6.7+)* | Skill forensique avec preuves graduées Confirmed/Deduced/Hypothesized |
| **Intent** *(v6.7+)* | Mode d'exécution d'une skill (Create / Update / Validate) |
| **Mode (Fast/Coaching)** *(v6.7+)* | Profondeur d'interview de la skill (rapide minimaliste, ou pédagogique) |
| **NFR** | Non-Functional Requirement — exigence non-fonctionnelle (performance, sécurité, etc.) |
| **Party Mode** | Mode où tous les agents collaborent en discussion groupée |
| **PR-FAQ** *(v6.8+)* | « Working Backwards » façon Amazon : communiqué de presse fictif + FAQ avant le PRD |
| **PRD** | Product Requirements Document — document définissant ce qu'on construit |
| **Quick Flow** | Piste rapide unifiée (`bmad-quick-dev`) pour petites features |
| **Skill** *(v6.8+)* | Successeur des « workflows » : émet des fichiers companions avec handoff explicite |
| **Skills Architecture** *(v6.8+)* | Modèle d'organisation des skills (`.claude/skills/`, two-spine contract, intents, modes) |
| **Solutioning** | Phase 3 — définir comment construire (architecture + décomposition) |
| **SPEC.md** *(v6.8+)* | Noyau à 5 champs produit par `bmad-spec` (Problem, Capabilities, Constraints, Non-goals, Success signal) |
| **Story** | Unité de travail implémentable par un agent dev en 1-3 jours |
| **TDD** | Test-Driven Development — cycle red-green-refactor |
| **Two-Spine Contract** *(v6.8+)* | Modèle de livrable en deux fichiers couplés qui se référencent (ex. DESIGN+EXPERIENCE) |
| **Vibe Coding** | Développement improvisé sans plan structuré (l'anti-BMAD) |
| **Web Bundle** *(v6.8+)* | Bundle auto-contenu pour exécuter une skill BMAD dans Gemini Gems ou ChatGPT |

---

## Annexe B — Cheat Sheet Commandes (v6.8.0)

> ⚠️ **Changement de préfixe depuis v6.0** : les commandes utilisateur n'ont plus le namespace `bmm`. Si tu as une habitude v6.0, fais le mapping mental `/bmad-bmm-X` → `/bmad-X` et `/bmad-agent-bmm-X` → `/bmad-agent-X`.

```bash
# ─── AIDE & NAVIGATION ─────────────────────────────────────
/bmad-help                          # Guide intelligent (toujours commencer ici)
/bmad-workflow-status               # Où en suis-je ? (ex-/bmad-bmm-workflow-status)

# ─── AGENTS ────────────────────────────────────────────────
/bmad-agent-analyst                 # Mary — Analyste
/bmad-agent-pm                      # John — Product Manager
/bmad-agent-architect               # Winston — Architecte
/bmad-agent-dev                     # Amelia — Développeuse (englobe sprint planning, code review, QA légère)
/bmad-agent-ux-designer             # Sally — UX Designer
/bmad-agent-tech-writer             # Paige — Technical Writer
# Bob (SM) et Barry (Quick Flow) : leurs responsabilités sont absorbées par Amelia et par les skills
# unifiées (bmad-sprint-planning, bmad-quick-dev). Vérifier `/bmad-help` après install pour la
# présence éventuelle d'agents dédiés dans ta version installée.

# ─── PHASE 1 : ANALYSE ─────────────────────────────────────
/bmad-brainstorming                 # Session brainstorming guidée
/bmad-domain-research               # Recherche domaine (ex-/bmad-bmm-research scindée)
/bmad-market-research               # Recherche marché et concurrentielle
/bmad-technical-research            # Recherche technique / faisabilité stack
/bmad-product-brief                 # Product Brief (3 intents : Create/Update/Validate, modes Fast/Coaching)
/bmad-prfaq                         # PR-FAQ « Working Backwards » (nouveau)

# ─── DISTILLATION & SPEC (nouveau core skill) ──────────────
/bmad-spec                          # Distille brain-dump/PRD/transcript en SPEC.md
                                    # (noyau 5 champs : Problem, Capabilities, Constraints,
                                    # Non-goals, Success signal). Remplace bmad-distillator.

# ─── PHASE 2 : PLANNING ────────────────────────────────────
/bmad-prd                           # PRD (3 intents Create/Update/Validate, modes Fast/Coaching)
                                    # produit prd.md + addendum.md + .decision-log.md
/bmad-ux                            # UX (ex-bmad-create-ux-design) — produit DEUX fichiers :
                                    # DESIGN.md (tokens visuels) + EXPERIENCE.md (flux, états, a11y)
                                    # + .decision-log.md

# ─── PHASE 3 : SOLUTIONING ─────────────────────────────────
/bmad-create-architecture           # Architecture technique (+ ADRs)
/bmad-create-epics-and-stories      # Epics et Stories (avec brownfield epic scoping v6.6+)
/bmad-check-implementation-readiness  # Gate PASS/CONCERNS/FAIL avant dev

# ─── PHASE 4 : IMPLÉMENTATION ──────────────────────────────
/bmad-sprint-planning               # Planification sprint → sprint-status.yaml
/bmad-sprint-status                 # Suivi de l'avancement (nouveau)
/bmad-create-story                  # Préparer la prochaine story → story-{slug}.md
/bmad-dev-story                     # Implémenter une story (TDD)
/bmad-code-review                   # Revue de code adversariale
/bmad-correct-course                # Correction de course en cours de sprint
/bmad-retrospective                 # Retrospective epic
/bmad-investigate                   # Forensique : bug triage, RCA, exploration code inconnu.
                                    # Preuves graduées Confirmed/Deduced/Hypothesized. (nouveau)

# ─── QUICK FLOW (unifié) ───────────────────────────────────
/bmad-quick-dev                     # UNIFIÉ : clarification + plan + implémentation + revue
                                    # + présentation. Remplace l'ancien duo quick-spec + quick-dev.

# ─── COLLABORATIF ──────────────────────────────────────────
/bmad-party-mode                    # Tous les agents pertinents dans une seule conversation

# ─── UTILITAIRES ───────────────────────────────────────────
/bmad-generate-project-context      # Constitution du projet → project-context.md
/bmad-document-project              # Documenter un projet existant (brownfield)
/bmad-shard-doc                     # Diviser grands documents
/bmad-index-docs                    # Indexer documentation
```

### Mapping rapide v6.0 → v6.8.0

| Avant (v6.0) | Maintenant (v6.8.0) |
|---|---|
| `/bmad-bmm-X` | `/bmad-X` |
| `/bmad-agent-bmm-X` | `/bmad-agent-X` |
| `/bmad-bmm-create-prd` | `/bmad-prd` (3 intents, 2 modes) |
| `/bmad-bmm-create-product-brief` | `/bmad-product-brief` (3 intents, 2 modes) |
| `/bmad-bmm-create-ux-design` (→ `ux-spec.md`) | `/bmad-ux` (→ `DESIGN.md` + `EXPERIENCE.md`) |
| `/bmad-bmm-research` (générique) | `/bmad-domain-research`, `/bmad-market-research`, `/bmad-technical-research` |
| `/bmad-bmm-quick-spec` + `/bmad-bmm-quick-dev` | `/bmad-quick-dev` (unifié) |
| `bmad-distillator` | `/bmad-spec` |
| _(n'existait pas)_ | `/bmad-prfaq` |
| _(n'existait pas)_ | `/bmad-investigate` |
| _(n'existait pas)_ | `/bmad-sprint-status` |
| Installation : `.claude/commands/` | Installation : `.claude/skills/` |
| Manifest : colonnes `after` / `before` | Manifest : `preceded-by` / `followed-by` |

---

*Guide rédigé à partir de la documentation officielle BMAD v6.8.0 — https://docs.bmad-method.org/*
*Mis à jour : juin 2026 (release v6.8.0 du 25 mai 2026)*
