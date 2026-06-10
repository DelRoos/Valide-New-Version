# Instructions pour Claude — Projet Valide School

> Ce fichier est chargé automatiquement dans ton contexte au début de chaque session. Il définit le comportement non négociable attendu de toi sur ce projet.

---

## Contexte projet

- **Valide School** : app Flutter bilingue FR/EN pour élèves du secondaire camerounais (BEPC, Probatoire, BAC, GCE O/A-Level).
- **Ce dépôt = app mobile uniquement.** Le backend Cloud Functions, la console admin et la landing page vivent dans des dépôts séparés.
- **Statut** : Foundation en cours (P0). MVP initialement planifié sur 6 semaines, **timeline ajustée à ~8-10 semaines** suite au scope cross-platform (cf. ADR-011).
- **Méthode de pilotage** : BMAD v6.8.0 — voir [doc/tools/BMAD_METHOD_GUIDE.md](doc/tools/BMAD_METHOD_GUIDE.md).
- **Contraintes marché non négociables** : téléphones modestes, data limitée et coûteuse, connectivité instable.
- **Plateformes V1** : **Android (phone & tablet) + iOS (iPhone & iPad)**. Responsive natif Flutter, layouts adaptés à 3 form factors (phone portrait, phone landscape optionnel, tablet portrait/landscape). Pas de WebView wrapper.

---

## Structure du dépôt

```text
.
├── mobile_app/             # ← Projet Flutter (toutes commandes flutter à lancer ici)
│   ├── lib/                # code Dart (clean architecture : core/ + features/)
│   ├── android/            # configuration Android (Gradle, manifests)
│   ├── ios/                # configuration iOS (Xcode project, Info.plist, Podfile)
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

- Tout chemin commençant par `lib/`, `android/`, `ios/`, `pubspec.yaml`, `test/` dans la doc ou une story = relatif à `mobile_app/`.
- Les configs Firebase (`firebase.json`, `.firebaserc`, `firestore.rules`, `firestore.indexes.json`, `storage.rules`) vivent au niveau **racine** du dépôt, pas dans `mobile_app/`. Justification : ces fichiers configurent le projet Firebase entier (Firestore, Storage, Functions, Hosting) et sont déployés via `firebase deploy` indépendamment du build Flutter. Le mobile consomme leurs effets (règles d'accès, indexes) mais ne les contient pas.
- Les artefacts Firebase **spécifiques au client mobile** vivent côté client :
  - Android : `mobile_app/android/app/google-services.json`
  - iOS : `mobile_app/ios/Runner/GoogleService-Info.plist`
  - Dart : `mobile_app/lib/firebase_options.dart` (généré par FlutterFire CLI, contient les options des deux plateformes)

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
9. **Firestore indexes — source de vérité = `firestore.indexes.json`**. Toute PR qui ajoute ou modifie une requête Firestore avec **multi-`where`** ou **`where` + `orderBy`** sur champs différents DOIT déclarer le composite index correspondant dans `firestore.indexes.json` (racine du repo) **et** le déployer via `firebase deploy --only firestore:indexes --project valide-edu`. Critères qui imposent un index composite : (a) plus d'un `.where(...)` sur champs différents (incl. `arrayContains`), (b) `.where(...)` + `.orderBy(...)` sur des champs distincts, (c) requête `collectionGroup`. Les requêtes par ID de document (`.doc(id).get()`, `.snapshots()`) et les requêtes single-field sont auto-indexées par Firestore — pas besoin de déclaration. **Ne jamais créer un index uniquement via la console Firebase** : la déclaration locale est l'autorité (sinon staging/CI/nouveau projet repartent à zéro). Pour aligner après création console manuelle : `firebase firestore:indexes --project valide-edu > tmp.json` puis merger dans `firestore.indexes.json`.

10. **Modélisation Firestore optimisée pour lecture, latence et coût**. Firestore est facturé **par document lu** (pas par octet), et chaque écran chargé sur le réseau camerounais (2G/3G dégradé) coûte en latence ET en consommation data utilisateur. Toute nouvelle collection, sous-collection, requête ou champ DOIT être conçu en suivant les principes ci-dessous. Si une story propose une modélisation qui les viole sans justification écrite (ex. trade-off explicite vs simplicité MVP), **stop et signale à l'utilisateur** avant de coder.

    **a. Modéliser par requête, pas par entité.** Identifie les 1-3 lectures principales d'un écran AVANT de définir la structure. Un seul `.get()` ou `.snapshots()` par écran cible idéal. Si un écran nécessite >3 reads pour s'afficher, c'est un signal fort de remodélisation (dénormalisation, composition de champ, sous-collection).

    **b. Dénormalisation > jointures.** Firestore n'a pas de JOIN. Au lieu de stocker `userId` puis lire `users/{userId}` séparément, **dupliquer** les champs lus fréquemment (`userDisplayName`, `userPhotoUrl`) dans le document parent. Trade-off accepté : écritures plus coûteuses (multi-doc updates via `WriteBatch` ou Cloud Function), lectures massivement moins chères. Pour Valide School : dupliquer `schoolName` dans `users/{uid}` plutôt que re-fetch `schools/{schoolId}` à chaque ouverture dashboard.

    **c. Plafonner `limit()` et paginer.** Aucune requête `collection().get()` sans `.limit(N)` explicite. Les listes paginées utilisent `startAfterDocument(lastDoc)` (curseur), jamais `offset()` (Firestore facture les docs sautés). Cibles V1 : `limit(20)` pour les listes UI, `limit(10)` pour les autocomplete (recherche école Story 1.7), `limit(50)` max pour les flux temps réel.

    **d. Préfiltrer côté serveur — pas dans Flutter.** Toute logique de filtrage métier (`isActive: true`, `subSystem == 'francophone'`, etc.) doit passer par `.where(...)` dans la requête, jamais en `.where((doc) => ...)` côté Dart après réception. Filtrer côté client = lire et facturer des docs inutiles.

    **e. `arrayContains` plutôt que sous-collection pour les listes courtes (<10 éléments).** Pour les relations N-M de petite taille (matières d'une série, examens visés), un champ `subjectIds: string[]` indexé par `arrayContains` coûte 1 read vs N reads via sous-collection. Au-delà de 10-15 éléments, basculer en sous-collection avec pagination.

    **f. Sous-collection vs racine — règle de propagation.** Une sous-collection (`users/{uid}/sessions/{sid}`) coûte la même chose qu'une collection racine en lecture **mais** elle est invisible aux requêtes globales (sauf `collectionGroup` — exige un index composite explicite, cf. règle 9). Choisir sous-collection quand : (a) les docs n'ont de sens que dans le contexte du parent, (b) on veut une isolation des règles Firestore par parent. Choisir racine quand : on veut interroger globalement OU partager entre utilisateurs.

    **g. Streams `snapshots()` — uniquement sur data mutable.** Chaque snapshot listener actif facture **1 read par doc à chaque update** + 1 read initial. Réserver `snapshots()` aux écrans dont la donnée change pendant la session (chat, statut paiement). Pour la donnée statique (catalogue scolaire, contenu pédagogique, profil utilisateur immuable), **toujours** `.get()` (cache offline Firestore prend le relais, cf. règle 5). Anti-pattern explicite : `.snapshots()` sur la collection `subjects` ou `derivation_rules` (changent rarement → gaspillage).

    **h. Cache offline par défaut, source explicite si critique.** Sauf raison forte, accepter le cache Firestore natif (`Source.serverAndCache`). Forcer `Source.server` uniquement quand la fraîcheur est non négociable (paiement, suppression compte). Forcer `Source.cache` uniquement pour des UX explicites (mode offline, écran de chargement instantané avant refresh).

    **i. Aggrégations — `count()` server-side > scan côté client.** Pour les compteurs (nombre de stories vues, total quiz réussis), utiliser `query.count()` (1 read facturé pour le résultat, pas N docs). Ne JAMAIS faire `.get()` + `.length` côté Dart pour compter.

    **j. Champs lourds isolés en sous-doc.** Les blobs (Markdown long de cours, JSON de quiz complet) doivent vivre dans un sous-document ou Cloud Storage, **pas** dans le document parent listé en grille. Sinon chaque scroll d'une grille de 20 cours = 20 reads de 50 KB = data + latence. Pattern : `lessons/{lid}` (métadonnées listables : titre, icône, durée) + `lessons/{lid}/content/main` (Markdown lourd lu uniquement à l'ouverture).

    **k. Identifiants stables et déterministes en chemin de lecture critique.** Privilégier les lectures par ID (`.doc(id).get()` — auto-indexé, 1 read, 0 latence d'index) plutôt que par requête (`.where(...).limit(1).get()` — 1 read + temps d'index). Quand un objet est lu via un ID connu (uid utilisateur, examTargetId, subjectId), structurer le chemin pour le permettre.

    **l. Mises à jour partielles — `update()` ou `set(merge: true)`.** Ne jamais réécrire un doc entier pour modifier un champ : utiliser `update({champ: valeur})` ou `set(payload, SetOptions(merge: true))`. Préserve les champs absents du payload + évite les race conditions. Pattern obligatoire dans toutes les `*_repository_impl.dart` (cf. Stories 1.3, 1.4, 1.6, 1.7, 1.10, 1.12).

    **m. Cost-benefit documenté dans la story.** Toute story qui introduit une nouvelle collection, un nouvel index composite, un nouveau `snapshots()` ou une dénormalisation DOIT inclure dans ses Dev Notes une estimation : **(i) nombre de reads/écriture par session utilisateur moyenne**, **(ii) volumétrie estimée à 10 000 utilisateurs**, **(iii) trade-off accepté vs alternative**. Si non documenté, c'est un rouge en revue.

    **Anti-patterns interdits** :
    - ❌ Lire toute une collection sans `limit()`
    - ❌ `snapshots()` sur du catalogue (matières, séries, niveaux) ou contenu pédagogique statique
    - ❌ Filtrer en Dart ce qui peut être filtré en `.where(...)` Firestore
    - ❌ N+1 reads (boucler une liste et lire chaque détail séparément quand une dénormalisation l'aurait évité)
    - ❌ Écrire un doc entier pour modifier 1 champ
    - ❌ `offset()` pour paginer (utiliser `startAfterDocument`)
    - ❌ Stocker des blobs (>10 KB Markdown, JSON exam complet) dans un doc qui sera listé en grille
    - ❌ Re-fetcher des champs déjà disponibles dans le doc déjà lu

    **Réfs** : [Firestore data model](https://firebase.google.com/docs/firestore/data-model) + [Firestore pricing](https://firebase.google.com/docs/firestore/pricing) + [BASE-DE-DONNEES.md](doc/partage/BASE-DE-DONNEES.md) (schéma autoritaire).

11. **Composants réutilisables — catalogue obligatoire**. **AVANT** d'écrire le moindre `StatelessWidget` / `StatefulWidget` / fonction de build dans `lib/features/**/presentation/` ou `lib/core/widgets/`, **CONSULTER** [doc/tech/COMPOSANTS-REUTILISABLES.md](doc/tech/COMPOSANTS-REUTILISABLES.md) (catalogue source de vérité). Si un composant existant fait déjà le job (ou peut être adapté avec un paramètre optionnel supplémentaire), **le réutiliser** — pas de classe privée dupliquée d'un autre fichier (anti-pattern `_LegacyOptOutBody` / `_FreeWithObligatoryBody` / `_SeriesPlusOptionalBody` / `_TvePickerBody` dans `subjects_picker_page.dart`, identifié rétro Epic 1 v2 — à extraire Story 1.18).

    **Quand créer un nouveau composant** : si rien du catalogue ne convient, créer dans `lib/core/widgets/` (ou sous-dossier sémantique : `lib/core/widgets/picker/`, `lib/core/widgets/cards/`). **Documenter** simultanément dans `doc/tech/COMPOSANTS-REUTILISABLES.md` (nom, path, props, contexte d'usage, comportement responsive `phone-only` / `phone + tablet` / `tablet-adaptive`, exemple, story d'origine). Une PR qui ajoute un widget réutilisable sans entrée dans le catalogue **se renvoie**.

    **Périmètre actuel** : widgets UI uniquement (couche `presentation`). Ne s'étend pas aux usecases/repositories/models qui suivent l'architecture clean existante.

    **Workflow BMAD** :
    - `bmad-create-story` : étape obligatoire « Composants existants à réutiliser ? » — lister explicitement dans la story les composants du catalogue à consommer, et nommer les nouveaux composants à créer si besoin.
    - `bmad-dev-story` : checkpoint avant codage widget — relire le catalogue + déclarer la stratégie de réutilisation dans Dev Notes.
    - Quand un composant existe mais a besoin d'une adaptation mineure : ajouter un paramètre optionnel au composant existant **plutôt que** dupliquer. Si l'adaptation est majeure (logique différente), créer un composant frère distinct (pas une copie modifiée).

### Cross-platform & responsive (V1 = Android + iOS, phone + tablet)

1. **Pas de code plateforme-spécifique non isolé.** Tout `if (Platform.isAndroid)` ou `if (Platform.isIOS)` est confiné à `core/platform/*` (un wrapper par capability divergente : silent mode detection, haptic mapping, etc.). Les couches `domain` et `presentation` ne `import 'dart:io'` jamais.
2. **Pas de package Android-only sans wrapper.** Avant d'ajouter une dépendance, vérifier qu'elle supporte iOS. Sinon : choisir une alternative cross-platform, ou wrapper avec fallback iOS dans `core/platform/`.
3. **Pas de pixel hardcodé pour layouts responsives — règle enforced par BMAD.** Au-delà de `flutter_screenutil` (échelle phone-référence 375×812), tout écran doit utiliser un `LayoutBuilder` ou `MediaQuery.sizeOf(context).width` pour adapter à 3 form factors : phone (< 600 dp), phone landscape (600-840 dp), tablet (≥ 840 dp). **`bmad-create-story` exige** une section « Stratégie responsive » dans chaque story ajoutant/modifiant un écran (form factors cibles + breakpoints + layout strategy). **`bmad-dev-story` exige** une Acceptance Criteria explicite « le widget s'adapte en tablette ». Une story qui ajoute un écran sans déclaration responsive est **renvoyée**.
4. **Pas de design portrait-only sur tablette.** Tablette doit fonctionner en portrait ET paysage. Phone landscape est optionnel (peut être verrouillé portrait en V1 si stories le justifient).
5. **Tester chaque écran sur 4 form factors — règle enforced par BMAD** : Android phone (Pixel 4a), Android tablet (Pixel Tablet), iOS phone (iPhone 14), iOS tablet (iPad mini). Au minimum, un golden test par breakpoint (≥ 1 viewport ≥ 840 dp = tablet **obligatoire**). **`bmad-dev-story` exige** ce golden test breakpoint tablet comme checkpoint avant push de PR. Dette technique connue (à résorber Story 1.18 + A7) : `subjects_picker_page`, `school_picker_page`, `dashboard_placeholder` actuellement non couverts.
6. **Conventions iOS quand divergentes** : utiliser les widgets Material par défaut (l'app est Material visual sur les deux), mais respecter les comportements iOS attendus quand ils ne contredisent pas le design (swipe-back navigation iOS via `CupertinoPageRoute` autorisée si elle améliore l'UX).
7. **Assets audio en AAC/M4A** (pas OGG — non supporté nativement iOS).

### Sécurité

1. **Aucun secret dans le code**, aucun secret dans les commits (même supprimés ensuite), aucun secret dans les logs, aucun secret dans les screenshots.
2. **Les secrets serveur** (signature webhook agrégateur, éventuelles clés tierces backend) **vivent côté backend uniquement** (Secret Manager). Ne propose JAMAIS de les mettre dans l'app mobile.
3. **L'IA passe par Firebase AI Logic (Gemini)** — pas de clé API à protéger côté backend pour l'IA. La sécurité des appels IA repose sur **App Check + Firebase Auth** (cf. ADR-012 et NFR-12 du PRD).
4. **Le vrai verrou d'accès est côté serveur** (règles Firestore + Cloud Function). Le check Flutter sur le statut premium est une **optimisation UX**, pas un verrou.

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
6. **Séquencement strict : 1 PR à la fois — JAMAIS deux PR enchaînées sans attendre merge intermédiaire.** Quand une cascade implique plusieurs PR (contexte → dev → cloture par story, ou suite de stories), pousser et **attendre la confirmation de merge** avant de pousser la PR suivante. Justification : empêche les collisions main (cf. incident merge Story 1.13 PR #74/#75 mai 2026 — fix dans PR #77). Cette règle s'applique aux PR consécutives sur la même branche ou des branches dépendantes. Exceptions : (a) deux PR sur des branches **strictement indépendantes** sans dépendance code/doc commune, (b) chez le porteur (hotfix urgent isolé) avec accord explicite utilisateur. Pas d'exception « ça va se mélanger gentiment » — toujours séquentialiser.

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
| **Catalogue composants réutilisables Flutter** (règle 11) | [doc/tech/COMPOSANTS-REUTILISABLES.md](doc/tech/COMPOSANTS-REUTILISABLES.md) |
| **Templates Dev Notes condensés + cost-benefit Firestore** (règle 10m) | [doc/tech/STORY-TEMPLATES.md](doc/tech/STORY-TEMPLATES.md) |

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
- **Bundle ID iOS** : `com.valideStartup.valideSchool` (aligné avec applicationId Android) — à confirmer dans Story 0.4bis.
- **Min iOS version** : iOS 13.0 proposé (couvre 95%+ du marché). À figer en Story 0.4bis.
- **Min Android SDK** : actuellement 21 (Android 5.0, défaut Flutter). À confirmer.
- **Détection mode silencieux iOS** : pas d'API publique sur iOS (Apple ne l'expose pas) — fallback obligatoire sur setting Profil utilisateur. Documenté en Story 0.14.

Quand l'utilisateur prend une décision sur l'un de ces points, **mets-la à jour dans le bon document** dans la même conversation (CONTRIBUTING.md, ou doc/partage/, ou ADR).

---

*Ce fichier est lu à chaque session. Si tu en changes les règles, la modification se fait par PR comme le reste de la doc — pas en conversation.*
