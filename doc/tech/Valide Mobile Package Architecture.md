# Stack Flutter — Référence des packages

**Projet :** Application EdTech mobile-first (marché camerounais, curriculum MINESEC APC)
**Contraintes directrices :** mobile-first, ~40% de pénétration smartphone (gammes entrée/milieu), data limitée et coûteuse, sensibilité au prix.
**Principe transversal :** chaque dépendance doit se justifier par un gain réel ; on privilégie le léger, le rapide, et ce que l'on contrôle. Le poids et la lenteur viennent rarement de l'état ou du routing (négligeables) — ils viennent de Firebase empilé, du rendu de contenu chargé trop tôt, et des images non compressées.

---

## Sommaire des décisions

| Domaine | Choix |
|---|---|
| State management | `flutter_riverpod` |
| Navigation | `go_router` |
| Réseau | `dio` |
| **Logging** | **`logger` (wrappé dans `AppLogger`)** |
| Backend / données | Firebase (core, auth, firestore, storage, functions, messaging, analytics, crashlytics, remote_config, app_check) |
| Cache données | Cache natif Firestore |
| Cache médias | `cached_network_image` |
| Contenu pédagogique | `flutter_smooth_markdown` (lazy-load) |
| Capture réponses Mode 1 | `image_picker`, `flutter_image_compress` |
| Paiement mobile money | `webview_flutter`, `url_launcher` |
| Préférences / i18n | `shared_preferences`, `flutter_localizations` + `intl` |
| **Adaptation à l'écran** | **`flutter_screenutil` (tailles dynamiques)** |
| Graphiques / animations | `fl_chart`, `lottie` |
| Génération de code | `build_runner`, `json_serializable`, `riverpod_generator`, `freezed`, lints |

---

## 1. Firebase (FlutterFire)

Les modules Firebase pèsent **individuellement** sur la taille de l'app. Règle : configurer chaque module proprement et ne charger son SDK que là où il sert.

#### `firebase_core`
- **Pourquoi :** point d'entrée obligatoire ; initialise la connexion Firebase. Aucun autre module Firebase ne fonctionne sans lui.
- **Comment :** `Firebase.initializeApp()` dans le `main()` avant `runApp()`, avec les options générées par FlutterFire CLI (`flutterfire configure`).

#### `firebase_auth`
- **Pourquoi :** gère l'authentification des élèves/enseignants. Supporte email, numéro de téléphone (pertinent ici : beaucoup d'utilisateurs n'ont pas d'email mais ont un numéro), et fournisseurs sociaux.
- **Comment :** privilégier l'auth par téléphone (OTP SMS) comme méthode principale vu le contexte. `FirebaseAuth.instance.signInWith...`. Exposer l'état d'auth via un provider Riverpod (`StreamProvider` sur `authStateChanges()`).

#### `cloud_firestore`
- **Pourquoi :** base NoSQL temps réel pour cours, exercices, progression élève, sessions de tutorat. Synchro temps réel native, et **cache offline activé par défaut sur mobile**.
- **Comment :** structurer en collections claires (cours / exercices / progression / sessions). Activer la persistance (par défaut sur mobile). **Attention coût :** Firestore facture à la lecture de documents — éviter de relire en boucle du contenu statique ; s'appuyer sur le cache.

#### `firebase_storage`
- **Pourquoi :** stockage des médias lourds : PDF de cours, images d'exercices, schémas (SVT/PCT). Ces fichiers **ne passent pas** par le cache Firestore — canal séparé.
- **Comment :** uploader des images **compressées en WebP** depuis le backend. Servir via URL ; mettre en cache côté client avec `cached_network_image`.

#### `cloud_functions`
- **Pourquoi :** exécuter la logique sensible côté serveur — surtout l'appel à l'API Claude (le wrapper protège la clé API), la logique RAG, et toute opération qui ne doit pas vivre dans le client.
- **Comment :** le client appelle une Function (`httpsCallable`), la Function orchestre RAG + appel Claude + renvoie le résultat (idéalement en streaming pour le Mode 3). Ne JAMAIS mettre la clé API Claude dans l'app Flutter.

#### `firebase_messaging`
- **Pourquoi :** notifications push — rappels de révision, nouveaux exercices, relances d'engagement. Levier direct de rétention sur un marché où le réengagement compte.
- **Comment :** gérer l'enregistrement des tokens, les permissions (iOS/Android), et le routage des notifications vers le bon écran (deep link via `go_router`).

#### `firebase_analytics`
- **Pourquoi :** tracking comportemental et funnels (inscription → premier exercice → conversion payante). Indispensable pour piloter le produit par la donnée et mesurer l'usage réel des 3 modes.
- **Comment :** logger des événements nommés cohérents (`exercise_started`, `mode_selected`, `correction_viewed`, `payment_completed`). Brancher sur les écrans clés.

#### `firebase_crashlytics`
- **Pourquoi :** remontée automatique des crashs et erreurs non fatales en production. Permet de détecter et corriger vite ce qui casse sur la diversité réelle des téléphones du marché.
- **Comment :** capturer les erreurs Flutter (`FlutterError.onError`) et les erreurs asynchrones non gérées vers Crashlytics.

#### `firebase_remote_config`
- **Pourquoi :** feature flags, A/B testing, et surtout pilotage dynamique du **paywall freemium/abonnement** sans republier l'app. Permet d'ajuster prix, limites du gratuit, et activations de fonctionnalités à distance.
- **Comment :** définir des valeurs par défaut côté app, les surcharger depuis la console. Lire via un provider Riverpod pour réagir dans l'UI.

#### `firebase_app_check`
- **Pourquoi :** atteste que les requêtes proviennent bien de ton app authentique, et empêche l'abus de tes endpoints — en particulier l'appel à l'API Claude, **coûteux**. Protection directe de tes marges.
- **Comment :** activer App Check et l'exiger côté Cloud Functions / Firestore / Storage (enforcement). Utiliser Play Integrity (Android) et DeviceCheck/App Attest (iOS).

---

## 2. Gestion d'état & navigation

#### `flutter_riverpod`
- **Pourquoi :** gérer l'état des 3 modes d'exercices, des sessions de tutorat, de l'état RAG et de l'authentification. Choisi plutôt que **GetX** pour un projet destiné à durer (équipe, financement, maintenance pluriannuelle, expansion CEMAC) :
  - Dépendances **explicites** et vérifiées à la compilation (vs la « magie » du service locator global de GetX).
  - **Testabilité** native (override de providers trivial en test).
  - **Gouvernance** plus solide et écosystème mieux maintenu.
  - Impose de bonnes pratiques au lieu de simplement permettre le raccourci.
- **Arbitrage assumé :** GetX est plus rapide à prototyper en solo. Riverpod vieillit mieux. Pour ce projet, robustesse > vitesse initiale.
- **Poids :** négligeable. Aucun impact runtime notable.
- **Comment :** `ProviderScope` à la racine. Providers par domaine (auth, cours, session de tutorat). Utiliser `AsyncNotifier` pour les états asynchrones (chargement d'exercices, appels Claude). Voir la section Génération de code pour la syntaxe annotée `@riverpod`.

#### `go_router`
- **Pourquoi :** routing déclaratif officiel (équipe Flutter), gestion des **deep links** — essentiel pour le partage d'exercices via WhatsApp (canal de distribution clé) et le routage des notifications push. Permet aussi le **lazy loading** des écrans lourds.
- **Poids :** léger.
- **Comment :** définir les routes de façon centralisée ; protéger les routes selon l'état d'auth (redirect). Charger en lazy les écrans coûteux (correction, rendu Mermaid).

---

## 3. Réseau

#### `dio`
- **Pourquoi :** client HTTP robuste pour les appels vers les Cloud Functions / backend. Apporte **retries, intercepteurs, timeouts configurables** — précieux sur une connexion instable (zones à faible débit).
- **Arbitrage :** le package `http` natif est plus léger, mais sur ce marché à connectivité variable, la robustesse de `dio` (retry automatique, gestion fine des erreurs réseau) justifie le léger surcoût de poids.
- **Comment :** une instance `Dio` configurée avec intercepteurs (injection du token d'auth, retry sur échec réseau, logging en debug). Centraliser dans une couche `ApiClient`.

---

## 4. Logging

#### `logger`
- **Pourquoi :** sur un marché à téléphones et réseaux très variés, **les logs sont la première source de diagnostic**. La règle d'équipe est simple : toute opération réseau, décision d'accès (premium), paiement, appel IA, transition d'état clé, et toute erreur attrapée **doivent** produire un log. Une erreur sans log est un bug de revue.
- **Pourquoi `logger` plutôt que `print` ou `developer.log` :** sortie formatée et lisible en dev (niveaux, couleurs, stack traces propres), filtrage par niveau en release (on coupe les `debug`), et une API simple (`d/i/w/e`) qui se mappe naturellement sur les pratiques de logging structuré côté serveur.
- **Arbitrage vs `talker` :** `talker` apporte plus (UI in-app, intégration Dio/BLoC) mais pèse plus et impose un écosystème. `logger` reste minimal et suffit pour un MVP — on ajoute un dashboard d'observabilité côté serveur (Cloud Logging) plutôt qu'in-app.
- **Comment — règle non négociable :** on n'importe **jamais** `package:logger` directement dans le code métier. On passe par un wrapper maison `AppLogger` (`core/logging/app_logger.dart`), pour trois raisons :
  1. **Respecter la règle d'or de l'archi** : le `domain` ne doit importer aucun paquet externe (cf. guide *App Architecture*, section 4).
  2. **Centraliser la config** (niveaux, format, branchement vers Crashlytics en production) à un seul endroit.
  3. **Pouvoir changer de librairie** sans toucher au reste de l'app.
- **Exposition** : `AppLogger` est fourni via Riverpod (`loggerProvider`, `keepAlive: true`) et injecté dans les datasources, repositories impls et notifiers.
- **Ne jamais logger** : mots de passe, jetons d'authentification, codes PIN MoMo/OM, numéros de téléphone complets, contenu personnel sensible. En cas de doute, logger un identifiant (`uid`, `exerciseId`) plutôt que la donnée elle-même.

> Détail complet de l'API `AppLogger` et des niveaux (`d`/`i`/`w`/`e`) dans le guide *App Architecture*, section 11.

---

## 5. Contenu pédagogique (le cœur)

#### `flutter_smooth_markdown`
- **Pourquoi :** **un seul widget** couvre Markdown + LaTeX + Mermaid + SVG + **streaming temps réel**. Remplace à lui seul l'assemblage `flutter_markdown` + `flutter_math_fork` + WebView Mermaid + `flutter_svg`.
  - **Markdown complet :** titres, listes, tables, blocs de code, blockquotes, task lists, sections repliables.
  - **LaTeX natif** (inline `$...$` et bloc `$$...$$`) — utilise `flutter_math_fork` en interne. Essentiel pour math/PCT (BEPC, Probatoire, BAC).
  - **Mermaid natif, sans WebView** — flowcharts, séquence, Gantt, Kanban, timeline, radar, XY charts, pie. Résout directement la question « comment gérer Mermaid » : quand Claude génère un bloc Mermaid (arbre de décision en algo, schéma de processus SVT, diagramme de séquence IT), il est rendu nativement.
  - **Streaming (`StreamMarkdown`)** — point fort majeur pour le **Mode 3 (tutorat pas-à-pas)** : on branche le flux de l'API Claude directement sur le widget, l'élève voit la réponse s'afficher progressivement (UX « ChatGPT-like » que les élèves connaissent déjà).
- **Points de vigilance (dépendance centrale, à connaître) :**
  - Package **jeune et peu adopté** (version 0.7.x, pré-1.0, peu de téléchargements, publié récemment).
  - Éditeur **non vérifié** sur pub.dev ; plusieurs fonctions Mermaid en `-beta`.
  - **Breaking changes probables** avant la 1.0 ; mainteneur unique (risque de maintenance).
- **Mitigation obligatoire :** **isoler derrière un widget maison** (ex. `PedagogicalContent(data: ...)`) qui enveloppe `SmoothMarkdown`. Si le package casse ou est abandonné, on remplace l'implémentation à un seul endroit.
- **Optimisation poids :** **charger en lazy** — uniquement sur les écrans d'exercice/correction/tutorat, jamais au démarrage. Le poids est surtout du code Dart (tree-shaké), pas des assets, donc impact APK modéré.
- **Test précoce :** valider tôt le rendu LaTeX sur les formules réelles BAC/Probatoire (cas tordus math/PCT) et le rendu Mermaid sur les vrais diagrammes.
- **Dépendances embarquées (à NE PAS déclarer en double) :** `flutter_math_fork`, `flutter_svg`, `flutter_highlight`, `cached_network_image`, `url_launcher`.

#### `cached_network_image`
- **Pourquoi :** cache des médias venant de Firebase Storage (images d'exercices, schémas). Le cache Firestore **ne couvre pas** les médias — d'où un canal de cache dédié. Évite de re-télécharger (économie de data, gain de vitesse).
- **Note :** déjà embarqué par `flutter_smooth_markdown`, mais à déclarer explicitement si utilisé hors de ce widget.
- **Comment :** remplacer les `Image.network` par `CachedNetworkImage` avec placeholder et widget d'erreur.

---

## 6. Capture des réponses élèves — Mode 1 « Je maîtrise »

#### `image_picker`
- **Pourquoi :** permettre à l'élève de photographier son travail manuscrit (copie d'exercice) pour soumission et correction personnalisée.
- **Comment :** capture caméra ou sélection galerie ; renvoie un fichier à compresser puis uploader vers Storage.

#### `flutter_image_compress`
- **Pourquoi :** **compresser avant upload** — réduit drastiquement la consommation de data de l'élève et accélère l'envoi. Critique sur ce marché.
- **Comment :** compresser en JPEG/WebP à qualité raisonnable avant tout upload Storage. C'est souvent le plus gros poste de data côté utilisateur — à ne pas négliger.

---

## 7. Paiement (mobile money)

Firebase ne gère pas MTN MoMo / Orange Money. L'intégration passe par les agrégateurs (Tranzak / Campay / MyCoolPay).

#### `webview_flutter`
- **Pourquoi :** afficher les pages de paiement hébergées des agrégateurs dans l'app.
- **Comment :** ouvrir l'URL de paiement dans une WebView, écouter les redirections pour détecter succès/échec. (À ne pas confondre avec un usage Mermaid — ici c'est uniquement le paiement.)

#### `url_launcher`
- **Pourquoi :** redirections de paiement et liens externes (ouvrir une app de paiement, un lien de support).
- **Note :** déjà embarqué par `flutter_smooth_markdown` ; déclarer explicitement.

---

## 8. Préférences & internationalisation

#### `shared_preferences`
- **Pourquoi :** stockage clé-valeur léger pour préférences (langue choisie, dernier mode utilisé, onboarding vu).
- **Poids :** minuscule.

#### `flutter_localizations` + `intl`
- **Pourquoi :** application **bilingue FR/EN** — obligatoire vu le système anglophone (GCE O/A-Level) en plus du francophone. Gère traductions, formats de date/nombre.
- **Comment :** fichiers ARB par langue, génération des `AppLocalizations` via le generator `gen-l10n` intégré à Flutter. Basculer la locale selon le choix utilisateur (persisté via `shared_preferences`).

---

## 9. Adaptation à l'écran (tailles dynamiques)

Le marché cible va du petit smartphone d'entrée de gamme (écran ~5", densité modeste) au milieu de gamme plus généreux. Sans adaptation, une UI conçue sur un seul gabarit casse sur les autres : textes coupés, boutons trop petits pour le pouce, paddings disproportionnés. C'est un point de qualité visible immédiatement par l'élève.

#### `flutter_screenutil`
- **Pourquoi :** fournit des unités **proportionnelles à la taille de l'écran** (`.w` pour la largeur, `.h` pour la hauteur, `.sp` pour la typo, `.r` pour les rayons). On dessine une fois sur un gabarit de référence (ex. 375×812) et l'app s'adapte automatiquement aux autres résolutions, **sans `MediaQuery` éparpillé** dans le code.
- **Arbitrage vs alternatives :**
  - **`MediaQuery` brut** : marche, mais oblige à recalculer des ratios partout — code verbeux et incohérent d'un écran à l'autre.
  - **`responsive_framework`** : pensé pour le **web** et les très grands écarts (mobile/tablette/desktop). Surdimensionné pour un produit 100 % mobile-first ; coût en complexité non justifié.
  - **`sizer`** : plus minimaliste, mais l'écosystème et l'adoption de `flutter_screenutil` sont bien meilleurs (intégration LayoutBuilder, support des splits Android, communauté active).
- **Poids :** négligeable (utilitaires de calcul).
- **Comment :**
  - Initialisation **une seule fois** à la racine avec `ScreenUtilInit(designSize: Size(375, 812), ...)` autour du `MaterialApp` (gabarit de design de référence à figer avec l'équipe design — à aligner sur le Design System).
  - Dans les widgets : `SizedBox(height: 24.h)`, `Text("...", style: TextStyle(fontSize: 16.sp))`, `borderRadius: BorderRadius.circular(12.r)`.
  - **Règle d'équipe :** pas de pixels en dur dans les widgets de feature. Les valeurs absolues vivent dans `core/theme/tokens.dart` (où elles peuvent être lues avec `.sp` / `.w` / `.r` à l'usage).
- **Points de vigilance :**
  - `.sp` (font scaling) doit respecter le **réglage d'accessibilité système** : ne pas neutraliser le `textScaleFactor` de l'utilisateur (élèves malvoyants).
  - Plafonner certains paddings pour qu'ils ne « gonflent » pas sur de très grands écrans (`.w.clamp(min, max)`).
  - Tester systématiquement sur **au moins deux gabarits** : petit (ex. 360×640) et standard (ex. 393×873) — c'est dans la checklist de revue.

---

## 10. Visualisation & animation

#### `fl_chart`
- **Pourquoi :** graphiques de progression et KPIs élève (courbes de progression, scores par matière, radar de compétences APC).
- **Optimisation :** si certains graphiques restent très simples (une barre, une ligne), un `CustomPainter` natif fait le travail à zéro dépendance — `fl_chart` est réservé aux visualisations riches.
- **Comment :** alimenter les graphiques depuis les données de progression Firestore via des providers Riverpod.

#### `lottie`
- **Pourquoi :** animations vectorielles pour la gamification et le feedback positif (réussite d'exercice, montée de niveau).
- **À limiter :** chaque animation est un asset JSON qui pèse. Plafonner à quelques animations, et préférer les animations Flutter natives (`AnimatedContainer`, `Hero`, `AnimatedSwitcher`) quand elles suffisent.

---

## 11. Génération de code (generators)

Tout est en **`dev_dependencies`** : ces outils tournent à la compilation et **ne pèsent rien dans l'APK**. Seules les parties `*_annotation` (légères) restent dans l'app. Aucune contradiction avec l'objectif léger/rapide.

#### `build_runner`
- **Pourquoi :** le moteur de génération. Tous les autres generators tournent à travers lui ; sans lui, aucun fichier `.g.dart` / `.freezed.dart` n'est produit.
- **Comment :** `dart run build_runner watch --delete-conflicting-outputs` pendant le dev (régénération automatique), ou `build` en one-shot.

#### `json_serializable` + `json_annotation`
- **Pourquoi :** convertir les documents Firestore (cours, exercices, progression, sessions) et les réponses de l'API Claude entre JSON et objets Dart typés. Génère les `fromJson`/`toJson`, évitant un code répétitif et source d'erreurs.
- **Comment :** annoter `@JsonSerializable()`, déclarer `factory Model.fromJson(...)`, lancer build_runner. `json_annotation` reste dans l'app (léger) ; `json_serializable` est en dev.

#### `riverpod_generator` + `riverpod_annotation`
- **Pourquoi :** syntaxe moderne et officielle de Riverpod : une fonction annotée `@riverpod` génère automatiquement un provider typé. Beaucoup moins de boilerplate, typage plus sûr.
- **Comment :** `@riverpod` au-dessus d'une fonction/classe. `riverpod_annotation` reste dans l'app ; `riverpod_generator` est en dev.

#### `custom_lint` + `riverpod_lint`
- **Pourquoi :** règles de lint spécifiques à Riverpod qui détectent les erreurs courantes (provider mal utilisé, dépendance oubliée) **avant** l'exécution. Renforce la robustesse, cohérent avec le choix de Riverpod pour un projet durable.
- **Comment :** activer `custom_lint` dans `analysis_options.yaml`.

#### `freezed` + `freezed_annotation`
- **Pourquoi :** génère des classes de données immutables avec `copyWith`, égalité de valeur, et surtout des **unions / sealed classes** — idéal pour modéliser proprement les états (loading / data / error, les 3 modes d'exercice, les étapes d'une session de tutorat). Se combine nativement avec `json_serializable`.
- **Comment :** `@freezed` sur une classe avec ses constructeurs factory. `freezed_annotation` reste dans l'app ; `freezed` est en dev.

#### `gen-l10n` (intégré à Flutter)
- **Pourquoi :** génère les classes `AppLocalizations` à partir des fichiers ARB FR/EN. Generator **intégré** à Flutter — pas de package tiers nécessaire.
- **Comment :** configurer `l10n.yaml` ; la génération se déclenche au build.

---

## 12. Stratégie de cache

**Cache Firestore natif** comme socle : gratuit, activé par défaut sur mobile, zéro code. Il couvre les données déjà lues et la synchro hors-ligne des collections.

Deux limites à garder en tête :
1. **Médias non couverts** par le cache Firestore → `cached_network_image` est le canal de cache dédié pour les images/schémas venant de Storage (non optionnel).
2. **Pré-téléchargement volontaire** (« télécharger un chapitre pour réviser hors-ligne ») et **requêtes locales complexes** non pris en charge par le cache Firestore : si ce besoin se confirme, ajouter une base locale (`drift` pour des requêtes SQL riches, `hive` pour du clé-valeur rapide).

À surveiller : le **coût des lectures Firestore** sur le contenu statique relu fréquemment. Si la facture grimpe, basculer le contenu lourd et statique vers une base locale contrôlée.

---

## 13. Optimisation poids & rapidité (leviers de build)

La vraie légèreté vient de la config de build autant que des dépendances :

1. **Android App Bundle (.aab)** ou **split APK par ABI** (`--split-per-abi`) → ne livrer que le code natif du téléphone de l'élève. Gain majeur sur la taille téléchargée.
2. **Tree-shaking des icônes** (actif par défaut en release).
3. **Toujours mesurer en release** (`flutter build apk --release`), jamais en debug.
4. **Compression des images en WebP** côté backend avant Storage — souvent le plus gros poste de data.
5. **Lazy loading** des écrans lourds (correction, Mermaid) via `go_router`.
6. **Charger les SDK Firebase au plus près de leur usage**, pas tout au démarrage.

**Où se cache le poids / la lenteur (par ordre d'impact) :** Firebase empilé > `flutter_smooth_markdown` chargé trop tôt > images non compressées. Optimiser là, pas sur Riverpod/go_router.

---

## 14. Récapitulatif `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # Firebase
  firebase_core: ^latest
  firebase_auth: ^latest
  cloud_firestore: ^latest
  firebase_storage: ^latest
  cloud_functions: ^latest
  firebase_messaging: ^latest
  firebase_analytics: ^latest
  firebase_crashlytics: ^latest
  firebase_remote_config: ^latest
  firebase_app_check: ^latest

  # État & navigation
  flutter_riverpod: ^latest
  riverpod_annotation: ^latest
  go_router: ^latest

  # Réseau
  dio: ^latest

  # Logging (wrappé dans core/logging/app_logger.dart)
  logger: ^latest

  # Contenu pédagogique
  flutter_smooth_markdown: ^0.7.1
  cached_network_image: ^latest

  # Capture réponses (Mode 1)
  image_picker: ^latest
  flutter_image_compress: ^latest

  # Paiement
  webview_flutter: ^latest
  url_launcher: ^latest

  # Préférences & i18n
  shared_preferences: ^latest
  intl: ^latest

  # Adaptation à l'écran (tailles dynamiques)
  flutter_screenutil: ^latest

  # Visualisation & animation
  fl_chart: ^latest
  lottie: ^latest

  # Annotations (légères, restent dans l'app)
  json_annotation: ^latest
  freezed_annotation: ^latest

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Génération de code
  build_runner: ^latest
  json_serializable: ^latest
  riverpod_generator: ^latest
  freezed: ^latest
  custom_lint: ^latest
  riverpod_lint: ^latest
```

> **Note d'architecture :** ce stack suppose un backend **tout-Firebase**. Si le stack Next.js + NestJS + Supabase (PostgreSQL) précédemment évoqué reste d'actualité, l'articulation des deux est à clarifier (chevauchement Firestore/PostgreSQL et Firebase Auth/Supabase Auth).
