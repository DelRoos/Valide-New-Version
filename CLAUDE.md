# Instructions pour Claude — Projet Valide School

> Ce fichier est chargé automatiquement dans ton contexte au début de chaque session. Il définit le comportement non négociable attendu de toi sur ce projet.

---

## Contexte projet (en 5 lignes)

- **Valide School** : app Flutter bilingue FR/EN pour élèves du secondaire camerounais (BEPC, Probatoire, BAC, GCE O/A-Level).
- **Ce dépôt = app mobile uniquement.** Le backend Cloud Functions, la console admin et la landing page vivent dans des dépôts séparés.
- **Statut** : phase de documentation. Aucun code Flutter encore. MVP planifié sur 6 semaines (6 phases).
- **Méthode de pilotage** : BMAD v6.8.0 — voir [doc/tools/BMAD_METHOD_GUIDE.md](doc/tools/BMAD_METHOD_GUIDE.md).
- **Contraintes marché non négociables** : téléphones modestes, data limitée et coûteuse, connectivité instable.

---

## Structure du dépôt

```text
.
├── mobile_app/             # ← Projet Flutter (toutes commandes flutter à lancer ici)
│   ├── lib/                # code Dart (clean architecture : core/ + features/)
│   ├── android/            # configuration Android (Gradle, manifests)
│   ├── test/               # tests Flutter
│   ├── pubspec.yaml        # dépendances Flutter
│   └── analysis_options.yaml
├── doc/                    # documentation projet (tech, métier, partage, tools)
├── project_manage/         # planification BMAD (SPEC, PRD, UX, architecture, epics, stories)
├── _bmad/                  # installation BMAD v6.8.0
├── .claude/                # skills BMAD chargées dans Claude Code
├── .github/                # templates PR + issues
├── CLAUDE.md               # ce fichier — règles non négociables
├── README.md
└── (futur : firebase.json, .firebaserc, firestore.rules, firestore.indexes.json, storage.rules)
                            # ↑ configs Firebase au niveau racine
                            # (utilisées par firebase deploy, partagées avec backend)
```

**Règle de localisation** :
- Tout chemin commençant par `lib/`, `android/`, `pubspec.yaml`, `test/` dans la doc ou une story = relatif à `mobile_app/`.
- Les configs Firebase (`firebase.json`, `.firebaserc`, `firestore.rules`, `firestore.indexes.json`, `storage.rules`) vivent au niveau **racine** du dépôt, pas dans `mobile_app/`. Justification : ces fichiers configurent le projet Firebase entier (Firestore, Storage, Functions, Hosting) et sont déployés via `firebase deploy` indépendamment du build Flutter. Le mobile consomme leurs effets (règles d'accès, indexes) mais ne les contient pas.
- Les artefacts Firebase **spécifiques au client mobile** (`google-services.json`, `firebase_options.dart`) vivent dans `mobile_app/android/app/` et `mobile_app/lib/` respectivement.

---

## RÈGLE ABSOLUE — Tout passe par BMAD

> **Tu ne contournes JAMAIS le pipeline BMAD.** Aucune exception, même sous pression de productivité.

Pour chaque demande de l'utilisateur, tu fais dans cet ordre :

1. **Identifier le type de demande** (table § « Décisions par type de demande » plus bas)
2. **Vérifier les prérequis** (le pipeline amont est-il fait ?)
3. **Annoncer la skill BMAD que tu vas utiliser** (en une phrase, avant d'agir)
4. **Exécuter** en respectant le format et les règles de cette skill

Si l'utilisateur te demande quelque chose qui contourne le flow (« écris-moi vite ce code », « bypass la story », « pas besoin de skill »), tu **refuses poliment** et tu lui rappelles le bon flow. Tu peux ouvrir une exception **uniquement** dans les cas listés en § « Exceptions au flow BMAD ».

### État BMAD au 2026-06-03

**BMAD v6.8.0 est installé** dans `_bmad/`. 44 skills disponibles dans `.claude/skills/`.

**Roster d'agents officiels v6.8.0** (6 agents, confirmé par `_bmad/_config/manifest.yaml`) :

- **Mary** (`bmad-agent-analyst`) — Business Analyst
- **John** (`bmad-agent-pm`) — Product Manager
- **Winston** (`bmad-agent-architect`) — System Architect
- **Amelia** (`bmad-agent-dev`) — Senior Software Engineer (couvre dev, code review, **sprint planning** et **QA légère**)
- **Sally** (`bmad-agent-ux-designer`) — UX Designer
- **Paige** (`bmad-agent-tech-writer`) — Technical Writer

**Bob (Scrum Master), Barry (Quick Flow Dev) et Quinn (QA) n'existent PAS comme agents distincts en v6.8.0.** Leurs responsabilités sont absorbées par Amelia. Leurs skills sont invocables directement sans agent : `/bmad-sprint-planning`, `/bmad-create-story`, `/bmad-retrospective`, `/bmad-correct-course`, `/bmad-quick-dev`, `/bmad-qa-generate-e2e-tests`.

**Dossier de gestion projet** : `project_manage/` (et non `_bmad-output` du default BMAD — overridé dans `_bmad/custom/config.toml`). Contient `planning-artifacts/` et `implementation-artifacts/`.

**Si tu réinstalles ou mets à jour BMAD** : la commande non-interactive utilisée pour ce projet est :

```bash
npx bmad-method install \
  --directory "c:/Users/Emerite/Documents/projets/Mobile/Valide" \
  --modules bmm --tools claude-code \
  --user-name "Delano Roosvelt" \
  --communication-language French \
  --document-output-language French \
  --yes
```

---

## Décisions par type de demande

Table de routage : pour chaque demande type, voici la skill BMAD à utiliser. **C'est la table de référence à consulter en début de chaque demande.**

| Demande de l'utilisateur ressemble à… | Skill / action à lancer | Prérequis |
|---|---|---|
| « Aide-moi à clarifier mon idée », « j'ai un brain dump », « voici un brief » | `/bmad-spec` (distillation en SPEC.md à 5 champs) | aucun |
| « Donne-moi une vision produit », « écris un product brief » | `/bmad-product-brief` (intent `Create`) | aucun |
| « Fais une PR-FAQ », « test du communiqué de presse » | `/bmad-prfaq` | aucun |
| « Recherche marché / concurrence » | `/bmad-market-research` | aucun |
| « Recherche réglementation / domaine / système éducatif camerounais » | `/bmad-domain-research` | aucun |
| « Recherche faisabilité technique / stack / packages » | `/bmad-technical-research` | aucun |
| « Écris le PRD » | `/bmad-prd` (intent `Create`, mode `Coaching` si premier PRD, `Fast` si SPEC déjà fait) | SPEC.md ou Product Brief recommandé |
| « Modifie le PRD » | `/bmad-prd` (intent `Update`) | PRD.md existe |
| « Vérifie la cohérence du PRD » | `/bmad-prd` (intent `Validate`) | PRD.md existe |
| « Conçois l'UX / les écrans / le design » | `/bmad-ux` → `DESIGN.md` + `EXPERIENCE.md` | PRD.md, et idéalement le Design System HTML existant |
| « Conçois l'architecture » | `/bmad-create-architecture` | PRD + UX |
| « Découpe en epics et stories » | `/bmad-create-epics-and-stories` | Architecture |
| « Est-ce qu'on peut commencer à coder ? » | `/bmad-check-implementation-readiness` | Architecture + Stories |
| « Planifie le sprint » | `/bmad-sprint-planning` | Stories prêtes |
| « Prépare la prochaine story pour le dev » | `/bmad-create-story` | Sprint planifié |
| « Implémente la story X » | `/bmad-dev-story` | Fichier story-X.md prêt |
| « Code review », « revue le diff » | `/bmad-code-review` | Code à reviewer |
| « Fais un petit fix », « ajoute juste un bouton », « renomme cette variable » | `/bmad-quick-dev` (uniquement si ≤ 1 composant, ≤ 5 fichiers, pas de décision archi) | aucun |
| « J'ai un bug bizarre », « ça crashe je ne comprends pas », « investigue ce module » | `/bmad-investigate` (forensique avec preuves graduées) | aucun |
| « Retrospective fin de phase » | `/bmad-retrospective` | Fin d'epic |
| « Le scope change en cours de sprint » | `/bmad-correct-course` | Sprint en cours |
| « Où en sommes-nous ? » | `/bmad-workflow-status` | aucun |
| « Génère le project context » | `/bmad-generate-project-context` | aucun |
| « Documente ce projet existant » | `/bmad-document-project` | aucun |
| « Tous les agents dans une salle pour discuter de X » | `/bmad-party-mode` | aucun |
| Question floue, exploratoire, sans intention claire | Demander clarification puis proposer la skill appropriée — **ne pas agir** avant clarification |

### Routage des skills par intent (v6.7+)

Pour les skills qui ont 3 intents (`Create` / `Update` / `Validate`) :

| Situation | Intent |
|---|---|
| Aucun livrable n'existe encore | `Create` |
| Le livrable existe et on modifie un point précis | `Update` |
| On vérifie sans modifier | `Validate` |

Et pour les modes (`Fast` / `Coaching`) :

| Situation | Mode |
|---|---|
| Premier livrable, l'utilisateur veut apprendre, sujet sensible | `Coaching` |
| Le contexte est solide en amont (SPEC distillé), l'utilisateur est expérimenté, on veut aller vite | `Fast` |

---

## Règles non négociables (héritées des docs)

### Architecture mobile (cf. [Mobile App Architecture](doc/tech/Valide%20School%20App%20Architecture.md))

1. **Règle d'or des dépendances** : `presentation → domain ← data`. Le `domain` n'importe **JAMAIS** Flutter, Firebase, Dio, Riverpod, ni `logger`.
2. **Traduction `Exception → Failure`** : uniquement dans les repository impls (`data/repositories/*_repository_impl.dart`).
3. **Logging** : `package:logger` n'est importé que dans `core/logging/app_logger.dart`. Toute opération réseau / décision d'accès / paiement / appel IA / erreur attrapée **doit** produire un log.
4. **Ne jamais logger** : mots de passe, jetons, codes PIN, numéros de téléphone complets, données personnelles sensibles.
5. **Cache** : on utilise **uniquement** le cache offline natif de Firestore. Pas de cache custom. Mutable = stream `snapshots()` ; statique = `.get()`.
6. **flutter_smooth_markdown** : n'est importé que dans `core/widgets/pedagogical_content.dart`.
7. **flutter_screenutil** : pas de pixels en dur dans les widgets, utiliser `.w` / `.h` / `.sp` / `.r`.
8. **Models** : ne sortent jamais de `data/` — `toEntity()` à la frontière.

### Sécurité

1. **Aucun secret dans le code**, aucun secret dans les commits (même supprimés ensuite), aucun secret dans les logs, aucun secret dans les screenshots.
2. **La clé Claude API et les secrets agrégateurs vivent côté backend uniquement.** Ne propose JAMAIS de les mettre dans l'app mobile.
3. **Le vrai verrou d'accès est côté serveur** (règles Firestore + Cloud Function). Le check Flutter sur le statut premium est une **optimisation UX**, pas un verrou.

### Surface partagée [`doc/partage/`](doc/partage/)

1. **Toute PR qui touche le schéma Firestore, un algorithme métier ou un contrat Cloud Function DOIT mettre à jour `doc/partage/` dans la même PR.** Pas de « code maintenant, doc plus tard ».
2. **Toute modification de contrat backend doit avoir l'accord écrit de l'équipe backend** (commentaire de mainteneur dans la PR).
3. **L'équipe admin et la landing consomment, ne modifient pas.**

### Workflow Git

1. Branches : `feature/`, `fix/`, `chore/`, `docs/`, `test/`, `experiment/` (kebab-case, anglais, ≤ 50 caractères).
2. Commits : **Conventional Commits** en français à l'impératif présent, sans point final. Scope obligatoire (auth, exercises, billing, content, health, gamification, chat, notifications, sharing, core, docs, partage, ci).
3. PR ≤ 400 lignes de diff. Squash & merge.
4. Pas de force-push sur `main`. Pas de merge commit dans une feature branch. Pas de `--no-verify`.
5. Identifiers code en **anglais**, commentaires et doc en **français**.

### Code & qualité

1. **Pas de commentaires WHAT** — uniquement WHY non évident.
2. **Pas de TODO / FIXME** sans lien vers une issue.
3. **Pas de magic numbers** — constantes nommées dans `core/theme/tokens.dart` ou config feature.
4. **Tests obligatoires** : toute logique métier nouvelle (cas succès + ≥ 1 cas d'échec). Tout bug corrigé = test de non-régression.
5. **Pas de PR sans test** sauf cas trivial (rename, doc, dep bump).

---

## Documents à consulter selon la demande

| Sujet | Document |
|---|---|
| Méthode BMAD (skills, intents, agents) | [doc/tools/BMAD_METHOD_GUIDE.md](doc/tools/BMAD_METHOD_GUIDE.md) |
| Comment contribuer (workflow, conventions, revue) | [doc/tools/CONTRIBUTING.md](doc/tools/CONTRIBUTING.md) |
| Périmètre du MVP en 6 phases | [doc/metier/Valide Decoupage MVP.md](doc/metier/Valide%20Decoupage%20MVP.md) |
| Architecture mobile détaillée | [doc/tech/Valide School App Architecture.md](doc/tech/Valide%20School%20App%20Architecture.md) |
| Packages Flutter (et pourquoi) | [doc/tech/Valide School Package Architecture.md](doc/tech/Valide%20School%20Package%20Architecture.md) |
| Architecture backend (référence) | [doc/tech/Valide Cloud Function Architecture.md](doc/tech/Valide%20Cloud%20Function%20Architecture.md) |
| Schéma Firestore | [doc/partage/BASE-DE-DONNEES.md](doc/partage/BASE-DE-DONNEES.md) |
| Algorithmes métier | [doc/partage/ALGORITHMES.md](doc/partage/ALGORITHMES.md) |
| Contrats Cloud Functions | [doc/partage/CONTRATS-API.md](doc/partage/CONTRATS-API.md) |
| Matrice profil → matières/examens | [doc/partage/DONNEES-REFERENCE.md](doc/partage/DONNEES-REFERENCE.md) |
| Design System (tokens, composants) | [doc/tech/Valide - Design System.html](doc/tech/Valide%20-%20Design%20System.html) |
| Maquettes par module | [doc/tech/Valide - Design.html](doc/tech/Valide%20-%20Design.html) |

**Avant d'utiliser un terme métier ou technique du projet**, vérifie qu'il existe dans le glossaire de [CONTRIBUTING.md](doc/tools/CONTRIBUTING.md) ou de [BMAD_METHOD_GUIDE.md](doc/tools/BMAD_METHOD_GUIDE.md). Si tu inventes un terme, signale-le explicitement à l'utilisateur.

---

## Exceptions au flow BMAD

Tu peux agir **sans skill BMAD** uniquement dans ces cas :

1. **Discussion / exploration** : l'utilisateur veut comprendre quelque chose, pas produire un artefact. Pas de fichier modifié.
2. **Lecture de doc** : il te demande où trouver quoi, ou de résumer un document existant.
3. **Petite correction de doc** (typo, lien cassé, formatage) : tu peux corriger directement, en commit `docs(scope): <description>`.
4. **Setup outillage** : installer un outil, configurer un linter, créer un `.gitignore`, un PR template. Pas de logique métier.
5. **Réponse à une question méthodologique** : « comment fonctionne X dans BMAD », « explique cette règle ».
6. **L'utilisateur demande explicitement** un mode hors-BMAD (par ex. « juste pour discuter », « brouillon rapide ») — tu confirmes que ce sera hors-pipeline et tu n'en produis pas d'artefact officiel.

Dans tous les autres cas : **passe par BMAD**.

---

## Comportements interdits

- ❌ **Coder Flutter sans story BMAD.** Tu ne crées pas de fichier `.dart` de feature sans qu'une `story-{slug}.md` ait été générée en amont.
- ❌ **Modifier `doc/partage/` sans accord croisé.** Si tu changes BASE-DE-DONNEES / ALGORITHMES / CONTRATS-API, tu signales **immédiatement** à l'utilisateur que l'équipe backend doit valider, et tu attends son OK avant de finaliser.
- ❌ **Quick Flow sur une feature multi-composants.** Si la demande touche mobile + backend + admin, c'est pipeline complet (`/bmad-create-story` → `/bmad-dev-story`), pas `/bmad-quick-dev`.
- ❌ **Patcher un bug mystérieux sans `/bmad-investigate`.** Si tu ne sais pas pourquoi un bug se produit, tu lances l'investigation forensique. Tu ne pars pas en hypothèse libre.
- ❌ **Refactoriser une zone non liée à la story en cours.** Hors scope. Tu proposes une issue pour une story future.
- ❌ **Mettre un secret dans le code, même temporairement.** Même pas en `// TODO: remove`.
- ❌ **Logger une donnée sensible** (PIN, jeton, mot de passe, n° de téléphone complet, contenu personnel).
- ❌ **Importer Firebase, Dio ou Flutter dans la couche `domain/`.**
- ❌ **Push direct sur `main`.** Toujours par PR.
- ❌ **`--no-verify` sur un hook git.** Si le hook est faux, tu fixes le hook.
- ❌ **Inventer un contrat Cloud Function** ou un format Firestore qui n'est pas documenté dans `doc/partage/`. Si tu en as besoin, tu mets à jour `doc/partage/` d'abord (avec accord backend).
- ❌ **Mélanger deux intentions dans un seul commit** (ex. `feat` + `refactor`). Tu sépares.
- ❌ **Proposer une PR > 400 lignes.** Tu découpes.
- ❌ **Affirmer une conclusion d'investigation sans la grader** (`Confirmed` / `Deduced` / `Hypothesized`).

---

## Comportements attendus (rappel court)

- ✅ Avant chaque action sur un fichier, **annoncer en une phrase** ce que tu vas faire et la skill BMAD utilisée.
- ✅ Avant chaque décision technique non triviale, **proposer un ADR** ou **consulter `.decision-log.md`** existant.
- ✅ **Tracer les décisions produit / UX / scope** dans le `.decision-log.md` du livrable concerné.
- ✅ Pour une revue, **trouver des problèmes** (revue adversariale). Si vraiment rien, le dire explicitement.
- ✅ Quand tu modifies `doc/partage/`, **mettre à jour la table « Historique »** en bas du fichier.
- ✅ Pour les ambiguïtés : **demander à l'utilisateur** plutôt qu'inventer.
- ✅ Pour les langues : **identifiers en anglais, doc et commentaires en français**.
- ✅ **Conventional Commits** systématiques.
- ✅ Avant de prétendre qu'une feature est finie, dérouler la **Definition of Done** de [CONTRIBUTING.md § 9](doc/tools/CONTRIBUTING.md#9-definition-of-done).

---

## Sanity check au début de chaque session

À ta première interaction avec l'utilisateur dans une nouvelle session :

1. **Confirmer le contexte** en une phrase : « Je suis sur Valide School, pipeline BMAD v6.8.0, on est en phase doc. »
2. **Lancer mentalement `bmad-workflow-status`** : vérifier `project_manage/` pour comprendre où en est le projet (existe-t-il un SPEC, un PRD, une archi, des stories ?).
3. **Demander à l'utilisateur ce qu'il veut faire** plutôt que de présumer.
4. **Identifier la skill BMAD à utiliser** dans la table § « Décisions par type de demande » et l'annoncer.

Si tu détectes un écart entre ton contexte chargé et la réalité du dépôt (ex. tu te souviens d'une décision qui n'est plus dans les docs), **fais confiance au dépôt et signale l'écart à l'utilisateur**.

---

## Points ouverts à connaître

Liste minimale à garder en tête tant que ces décisions ne sont pas prises (cf. [CONTRIBUTING.md § 17](doc/tools/CONTRIBUTING.md#17-décisions-ouvertes-à-trancher)) :

- **Stack admin / landing** : pas décidé, autres dépôts.
- **Statut agents Bob / Barry en v6.8.0** : à vérifier avec `/bmad-help` après install.
- **Liste exacte de matières par série** dans `DONNEES-REFERENCE.md` : 🟡 / 🔴, à valider par un enseignant camerounais.
- **Version exacte Flutter / Dart** : non figée, à aligner au démarrage.

Quand l'utilisateur prend une décision sur l'un de ces points, **mets-la à jour dans le bon document** dans la même conversation (CONTRIBUTING.md, ou doc/partage/, ou ADR).

---

*Ce fichier est lu à chaque session. Si tu en changes les règles, la modification se fait par PR comme le reste de la doc — pas en conversation.*
