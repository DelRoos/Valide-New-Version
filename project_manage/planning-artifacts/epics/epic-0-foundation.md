---
epic: 0
title: Foundation & Bootstrap
phase: P0
status: Stories drafted
generatedAt: 2026-06-03
sourceArtifacts:
  - project_manage/planning-artifacts/epics.md
  - project_manage/planning-artifacts/architecture/architecture.md
  - project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/DESIGN.md
  - project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/EXPERIENCE.md
  - doc/tech/Valide School App Architecture.md
  - doc/tech/Valide School Package Architecture.md
  - doc/partage/BASE-DE-DONNEES.md
  - ADRs/ADR-001 à ADR-010
storyCount: 22  # +Story 0.4bis ajoutee 2026-06-04 (ADR-011)
---

# Epic 0 — Foundation & Bootstrap

## Goal

Mettre en place la base technique sans laquelle aucun epic métier (E1-E6) ne peut démarrer : projet Flutter clean architecture initialisé, backend Firebase opérationnel, design system implémenté, patterns transverses (logging, idempotence, cache, i18n, sécurité, retry réseau) appliqués, et risques projet critiques (R1 agrégateur MoMo, R2 mainteneur `flutter_smooth_markdown`, R3 latence `europe-west1`) instruits dès la semaine 0.

**Critère de sortie d'epic** : Une page « Hello Valide » bilingue FR/EN qui rend un texte + une formule LaTeX (`$\int_0^1 x^2 dx$`) + un schéma Mermaid via `PedagogicalContent`, déployée sur Play Internal Track, avec Crashlytics actif, App Check enforcé, et règles Firestore initiales validant l'écriture/lecture d'un document `_smoketest/launch`.

## Out of scope (Epic 0)

- ❌ Onboarding scolaire complet (filière/niveau/série) → **E1**
- ❌ Catalogue de matières / chapitres / leçons / notions → **E2**
- ❌ Quiz, Mode 1, Mode 2 → **E3**
- ❌ Paywall, paiement, agrégateur MoMo en prod → **E4** (l'évaluation des agrégateurs est en E0 = Story 0.18)
- ❌ Santé scolaire, points, classements → **E5**
- ❌ Mode 3, Mode Examen, Chat IA, Partage → **E6**
- ~~❌ iOS build (V1 = Android-only)~~ → **MAJ 2026-06-04 (ADR-011)** : iOS phone + iPad inclus en V1. Bootstrap iOS = Story 0.4bis ; Firebase iOS = Story 0.6 ; build CI iOS = Story 0.17 ; release TestFlight = Story 0.21.
- ❌ Mode sombre (V1 = clair seulement)
- ❌ Migration Firestore depuis legacy (greenfield)
- ⚠️ **Layouts responsive tablette** : in scope V1 mais minimal en E0. Les composants atomiques (Story 0.13) et la sentinelle E0 (Story 0.21) doivent rendre correctement sur tablette ; les écrans métier riches (split-view, NavigationRail, etc.) sont implémentés au fur et à mesure dans E1-E6.

## Dependency graph

```text
                  ┌─── 0.1 Bootstrap projet Flutter (Android)
                  │       │
                  │       ▼
                  │  0.2 Setup architecture (Riverpod + go_router)
                  │       │
          ┌───────┼───────┼───────┬────────────┬────────┐
          ▼       ▼       ▼       ▼            ▼        ▼
     0.3 Logger  0.4 Either  0.5 Dio   0.6 Firebase  0.10 Theme  0.16 i18n
                  │           retry    Android+iOS    tokens
                  ▼                       │              │
              0.4bis Bootstrap iOS        ▼              ▼
              (requis pour 0.6)        0.7 Cache    0.11 Fonts
                                      offline           │
                                         │              ▼
                                         ▼          0.12 ScreenUtil + Responsive
                                      0.8 App Check    │
                                         │              ▼
                                         ▼          0.13 Composants atomiques
                                      0.9 Règles       │
                                      Firestore        ▼
                                         │          0.14 Composants feedback + audio/haptic
                                         │              │
                                         │              ▼
                                         │          0.15 PedagogicalContent
                                         │              │
                                         └─────┬────────┘
                                               ▼
                                         0.21 Smoke test sentinelle (Android + iOS)

  Parallèle CI/CD et risques (peut démarrer dès 0.1) :
    0.17 CI/CD GitHub Actions (Android + iOS, runner macOS)
    0.18 Risk R1 — Évaluation agrégateurs MoMo (J1 mandatory)
    0.19 Risk R2 — Tests précoces flutter_smooth_markdown
    0.20 Risk R3 — Benchmark latence europe-west1
```

## Stories

### Story 0.1 : Bootstrap projet Flutter

**Statut** : Draft
**Sprint** : P0 (semaine 0)
**Dépendances** : aucune
**Estimation** : S (~2-4h)

**As a** tech lead Flutter,
**I want** un projet Flutter initialisé avec la structure clean architecture et un `pubspec.yaml` minimal versionné,
**so that** toutes les stories suivantes peuvent démarrer sur une base reproductible.

#### Contexte technique

Le projet n'a aucun code Flutter au moment de la story (cf. `CLAUDE.md` § Contexte projet). La structure cible suit la règle d'or `presentation → domain ← data` (cf. ADR-001) avec un découpage `core/` (transversal neutre) + `features/<feature>/` (vertical par feature). Cette story ne crée que le squelette ; les sous-dossiers `core/` seront remplis par les stories 0.2-0.5, 0.10-0.15.

Versions à utiliser : **Flutter stable la plus récente disponible au moment de la story** (à figer dans `.tool-versions` ou équivalent). Dart est inclus par le SDK Flutter — pas de gestion séparée.

#### Acceptance Criteria

**AC1 — Projet créé dans `mobile_app/`**
**Given** un dépôt git existant à la racine du projet
**When** la commande `flutter create --org com.valideStartup --project-name valide_school --platforms android .` est exécutée et le projet placé dans `mobile_app/` (cf. CLAUDE.md § Structure du dépôt)
**Then** `mobile_app/lib/main.dart` existe et affiche `Valide School` au lancement
**And** `cd mobile_app && flutter run` lance l'app sur émulateur Android sans erreur
**And** `mobile_app/android/app/build.gradle.kts` a `applicationId = "com.valideStartup.valideSchool"` (camelCase, patché depuis le défaut snake_case)

**AC2 — Structure clean architecture créée**
**Given** le projet créé
**When** on liste `mobile_app/lib/`
**Then** les dossiers vides suivants existent : `mobile_app/lib/core/{di,error,logging,network,theme,widgets,utils}`, `mobile_app/lib/features/`, `mobile_app/lib/l10n/`, avec un `.gitkeep` dans chaque
**And** un `mobile_app/lib/main.dart` minimal initialise `runApp(const ValideApp())`

**AC3 — pubspec versionné et propre**
**Given** le `pubspec.yaml` initial
**When** on vérifie ses dépendances
**Then** seules `flutter`, `cupertino_icons` et `flutter_lints` sont déclarées (les autres viennent dans les stories suivantes)
**And** `flutter pub get` réussit sans warning

**AC4 — README initial**
**Given** la racine projet
**When** on ouvre `README.md`
**Then** il contient un titre, une description (1 paragraphe), un lien vers `CLAUDE.md` et vers `doc/tools/CONTRIBUTING.md`
**And** une commande d'install / run minimale

#### Definition of Done

- [ ] `flutter analyze` retourne 0 issue
- [ ] PR ≤ 200 lignes diff
- [ ] Commit `chore(core): bootstrap projet Flutter clean architecture`
- [ ] Pas de fichier `.dart` autre que `main.dart` et stubs `.gitkeep`

#### Notes pour Amelia

- N'ajoute aucun package au-delà du strict minimum — les autres stories les ajouteront en justifiant.
- Vérifie que `.gitignore` n'a pas été dégradé (le nôtre, en racine, doit rester intact ; celui de Flutter peut être adapté/fusionné).
- Préfixe d'application Android : `app.valide.mobile` (à confirmer si conflit).

---

### Story 0.2 : Setup architecture state + routing

**Statut** : Draft
**Sprint** : P0 (semaine 0)
**Dépendances** : Story 0.1
**Estimation** : M (~4-6h)

**As a** tech lead Flutter,
**I want** Riverpod et go_router intégrés avec un shell d'app vide mais navigable,
**so that** chaque feature suivante puisse déclarer ses providers et routes sans toucher au bootstrap.

#### Contexte technique

ADR-002 acte le choix `flutter_riverpod` (et non GetX) pour des raisons de durabilité, testabilité et dépendances explicites. Le routing utilise `go_router` (cf. `Valide School Package Architecture.md`). Cette story ne crée que le shell racine + 1 route stub `/hello` — les routes métier viendront avec leurs features.

Le `ProviderScope` enveloppe `ScreenUtilInit` (qui viendra en Story 0.12) qui enveloppe `MaterialApp.router`. Cette story prépare la place mais utilise un `MaterialApp.router` direct ; Story 0.12 wrappera avec ScreenUtil.

#### Acceptance Criteria

**AC1 — Packages ajoutés**
**Given** le `pubspec.yaml` minimal
**When** on ajoute `flutter_riverpod` et `go_router` aux versions stables
**Then** `flutter pub get` réussit
**And** aucune autre dépendance n'est introduite

**AC2 — `ProviderScope` racine en place**
**Given** `lib/main.dart`
**When** on lance l'app
**Then** `runApp(const ProviderScope(child: ValideApp()))` est exécuté
**And** un `final helloProvider = Provider<String>((ref) => 'Valide');` est consommable dans le widget racine

**AC3 — `go_router` configuré avec route stub `/hello`**
**Given** une `GoRouter` configurée dans `core/di/` ou `core/routing/`
**When** on lance l'app
**Then** la route `/` redirige vers `/hello` qui affiche `Text('Hello Valide')`
**And** un test widget vérifie que `/hello` rend ce texte

**AC4 — Router accessible via provider**
**Given** un `routerProvider` Riverpod
**When** `MaterialApp.router(routerConfig: ref.watch(routerProvider))` est utilisé
**Then** la navigation marche au `go('/hello')` depuis n'importe quel widget

#### Definition of Done

- [ ] 1 test widget (`/hello` rend le texte)
- [ ] `flutter analyze` 0 issue
- [ ] PR ≤ 150 lignes diff
- [ ] Commit `feat(core): setup Riverpod et go_router avec shell minimal`

#### Notes pour Amelia

- N'utilise PAS `flutter_riverpod_lint` / `custom_lint` ici (overhead pour P0) — à introduire après si nécessaire.
- Le `routerProvider` peut être simple `Provider`, pas besoin de `AsyncNotifier` à ce stade.
- Garde la route `/hello` même après la story 0.21 (sera utilisée comme sentinelle régression).

---

### Story 0.3 : Setup `AppLogger`

**Statut** : Draft
**Sprint** : P0 (semaine 0)
**Dépendances** : Story 0.2
**Estimation** : M (~4h)

**As a** tech lead Flutter,
**I want** un wrapper `AppLogger` (single point of import) au-dessus de `package:logger` avec redaction des données sensibles,
**so that** toute l'app utilise un logging cohérent et qu'on respecte la règle non-négociable « pas de log de donnée sensible ».

#### Contexte technique

Règle CLAUDE.md § Architecture mobile 3 : `package:logger` n'est importé que dans `core/logging/app_logger.dart`. CLAUDE.md § Architecture mobile 4 : **ne jamais logger** mots de passe, jetons, codes PIN, numéros de téléphone complets, données personnelles sensibles. Cette story crée le wrapper, ses tests, et le lint custom qui force l'import unique.

Niveau de log par défaut en debug = `verbose`, en release = `warning`.

#### Acceptance Criteria

**AC1 — Wrapper créé**
**Given** un nouveau fichier `lib/core/logging/app_logger.dart`
**When** on importe `AppLogger`
**Then** il expose `v(String message, {Object? error})`, `d`, `i`, `w`, `e(String message, {Object? error, StackTrace? stackTrace})`
**And** il instancie un `Logger` de `package:logger` en interne (jamais exposé)

**AC2 — Redaction des données sensibles**
**Given** un `AppLogger.i('Login attempt for user +237698765432 with token=abc.def.ghi')`
**When** on log via `AppLogger`
**Then** la sortie contient `+237***5432` (masquage milieu) et `token=***`
**And** un test unitaire vérifie 3 patterns : téléphone, token JWT, mot `pin=` ou `password=`

**AC3 — Niveau par environnement**
**Given** `kReleaseMode == true`
**When** un `AppLogger.v('detail')` est appelé
**Then** rien n'est émis (filtré au niveau `warning`)

**AC4 — Lint interdit `import 'package:logger/logger.dart'` ailleurs**
**Given** un fichier `lib/features/foo/foo.dart` qui importerait directement `package:logger`
**When** `dart analyze --fatal-warnings` est exécuté avec la règle custom (ou un grep CI)
**Then** un échec est produit pointant la ligne d'import
**And** un commentaire dans `analysis_options.yaml` documente la règle

#### Definition of Done

- [ ] Tests unitaires : 3 cas redaction + 1 cas niveau par env (4 tests)
- [ ] Documentation 1 paragraphe dans `doc/tech/Valide School App Architecture.md` § Logging si pas déjà décrit
- [ ] PR ≤ 200 lignes diff
- [ ] Commit `feat(core): AppLogger avec redaction donnees sensibles`

#### Notes pour Amelia

- Si tu n'arrives pas à créer une règle `custom_lint`, fallback : ajouter un check au `analysis_options.yaml` via `errors:` + un grep dans le workflow GitHub Actions de la Story 0.17.
- La redaction téléphone doit gérer formats `+237`, `237`, et locaux à 9 chiffres camerounais.
- Ne jamais logger un payload JSON entier — toujours extraire et logger des champs identifiés.

---

### Story 0.4 : Setup `Failure` types + pattern `Either<Failure, T>`

**Statut** : Draft
**Sprint** : P0 (semaine 0)
**Dépendances** : Story 0.2
**Estimation** : S (~3h)

**As a** dev Flutter,
**I want** une hiérarchie `Failure` sealed + utilisation de `Either<Failure, T>` (fpdart) en sortie de repository,
**so that** la règle NFR-7 (aucune exception ne remonte à l'écran) soit appliquée mécaniquement.

#### Contexte technique

NFR-7 : aucune exception ne remonte à l'UI. Tout passe par `Either<Failure, T>`. ADR-001 § Règle d'or : la traduction `Exception → Failure` se fait **uniquement** dans `data/repositories/*_repository_impl.dart`. Cette story crée les types `Failure` et fournit un helper de traduction.

Hiérarchie minimale : `Failure` (sealed) → `NetworkFailure`, `AuthFailure`, `ServerFailure(code, message)`, `CacheFailure`, `ValidationFailure(field, reason)`, `UnknownFailure`.

#### Acceptance Criteria

**AC1 — Hiérarchie sealed**
**Given** un fichier `lib/core/error/failures.dart`
**When** on déclare les classes
**Then** `Failure` est `sealed`, étendue par 6 sous-classes nommées ci-dessus
**And** chaque sous-classe expose un `String message` lisible utilisateur

**AC2 — `fpdart` intégré**
**Given** `pubspec.yaml`
**When** on ajoute `fpdart` à la dernière stable
**Then** `flutter pub get` réussit
**And** `Either<NetworkFailure, String> result = Right('ok');` compile sans warning

**AC3 — Helper de traduction Exception→Failure**
**Given** un helper `Failure.from(Object exception)`
**When** on lui passe un `DioException` (timeout), une `FirebaseAuthException('wrong-password')`, ou un `Exception('boom')`
**Then** il retourne respectivement `NetworkFailure`, `AuthFailure`, `UnknownFailure`
**And** chaque cas est testé unitairement

**AC4 — Convention documentaire**
**Given** la story marquée done
**When** on relit `doc/tech/Valide School App Architecture.md` § Gestion erreurs
**Then** un paragraphe court documente la convention `Either<Failure, T>` et indique que ce helper centralise la traduction
**And** un exemple de repository impl est donné

#### Definition of Done

- [ ] Tests unitaires : 1 par sous-classe Failure + 3 par helper (9 tests)
- [ ] PR ≤ 250 lignes diff
- [ ] Commit `feat(core): Failure types et pattern Either<Failure,T>`

#### Notes pour Amelia

- Ne PAS exposer les `Exception` source dans les `Failure` (pas de `originalException` field) — sinon ils risquent de remonter à l'UI par accident.
- Les messages utilisateur sont en français et passent par `AppLocalizations` quand la Story 0.16 sera faite — pour cette story, mets des messages hardcodés FR temporaires avec un `// TODO(0.16): localiser`.

---

### Story 0.4bis : Bootstrap iOS + squelette responsive

> **AJOUTÉE 2026-06-04 (ADR-011)** suite au scope cross-platform.

**Statut** : Draft
**Sprint** : P0 (semaine 0-1)
**Dépendances** : Story 0.4 (failure types prêts, code de base stable)
**Estimation** : M (~4-5h, dont 1-2h de signing Apple + 1h Xcode)
**Risque** : Demande Mac local ou cloud + compte Apple Developer actif.

**As a** tech lead Flutter,
**I want** le squelette iOS généré pour le projet existant (`flutter create -t app --platforms=ios .`), un Bundle ID stable, un build iOS debug qui démarre, et une vérification que le code Stories 0.1-0.3 fonctionne sur iOS sans modification,
**so that** les Stories 0.5+ puissent dépendre d'une cible iOS opérationnelle et que Story 0.6 (Firebase Android + iOS) puisse démarrer.

#### Contexte technique

Story 0.1 a été faite avec `flutter create --platforms=android` — il n'y a pas de dossier `mobile_app/ios/`. Cette story le génère, vérifie que le code Dart existant (`main.dart`, `app.dart`, `core/logging/`, `core/error/`, `core/di/`, `core/routing/`, `features/hello/`) fonctionne sur simulateur iOS, et fige les conventions (Bundle ID, min iOS, capabilities, Podfile platform).

**Bundle ID** : `com.valideStartup.valideSchool` (aligné avec applicationId Android).
**Min iOS** : 13.0 (couvre 95 %+ du parc, supporté par Firebase iOS SDK).

#### Acceptance Criteria

**AC1 — Squelette iOS généré**
**Given** `mobile_app/` actuel (sans dossier `ios/`)
**When** on exécute `flutter create -t app --platforms=ios --org com.valideStartup --project-name valide_school .` à la racine de `mobile_app/`
**Then** un dossier `mobile_app/ios/` est créé avec `Runner.xcodeproj`, `Runner/`, `Podfile`, `Flutter/`
**And** aucun fichier existant n'est écrasé (vérifier `lib/`, `test/`, `pubspec.yaml`, `android/` intacts)

**AC2 — Bundle ID et min iOS figés**
**Given** `ios/Runner.xcodeproj/project.pbxproj`
**When** on l'ouvre
**Then** `PRODUCT_BUNDLE_IDENTIFIER = com.valideStartup.valideSchool` pour les configurations Debug, Release, Profile
**And** `ios/Podfile` contient `platform :ios, '13.0'`
**And** `ios/Runner/Info.plist` : `CFBundleDisplayName = Valide School`

**AC3 — Pods installés**
**Given** `mobile_app/ios/`
**When** on exécute `pod install` (Mac requis)
**Then** la commande réussit sans erreur
**And** `Podfile.lock` est généré
**And** `ios/Pods/` est créé (ignoré par `.gitignore` — ne pas committer le dossier mais committer `Podfile.lock`)

**AC4 — Build iOS debug réussit**
**Given** un simulateur iOS lancé (iPhone SE 2020 minimum)
**When** on exécute `flutter build ios --debug --no-codesign` puis `flutter run -d <ios-sim>`
**Then** l'app se lance et affiche la page `/hello` avec « Hello Valide » (cf. comportement Story 0.2)
**And** aucun crash au démarrage
**And** les tests existants `flutter test` restent verts (les widget tests n'utilisent pas la plateforme native, donc ils doivent rester verts)

**AC5 — Audit code existant cross-platform**
**Given** les fichiers Dart livrés Stories 0.1-0.4
**When** on grep `dart:io`, `Platform.is`, `import 'package:flutter/cupertino.dart'`
**Then** **aucun usage** n'est trouvé hors du futur `lib/core/platform/` (qui n'existe pas encore — donc 0 résultat attendu)
**And** AppLogger, Failure, Either fonctionnent identiquement sur iOS (logs visibles dans Xcode console)

**AC6 — `.gitignore` iOS**
**Given** `.gitignore` racine ou `mobile_app/.gitignore`
**When** on inspecte les patterns
**Then** sont ignorés : `mobile_app/ios/Pods/`, `mobile_app/ios/.symlinks/`, `mobile_app/ios/Flutter/Flutter.framework/`, `mobile_app/ios/Flutter/Flutter.podspec`, `mobile_app/ios/Runner/GoogleService-Info.plist` (anticipation Story 0.6), `**/*.xcuserdata/`
**And** sont committés : `Podfile`, `Podfile.lock`, `Runner.xcodeproj/`, `Runner.xcworkspace/`, `Info.plist`

#### Definition of Done

- [ ] `flutter build ios --debug --no-codesign` réussit
- [ ] `flutter run -d <ios-sim>` lance l'app avec la page Hello
- [ ] Tests `flutter test` restent verts (5+ tests)
- [ ] `Podfile.lock` committé
- [ ] `.gitignore` mis à jour
- [ ] CLAUDE.md § Points ouverts : confirme Bundle ID + min iOS (ou mets à jour)
- [ ] PR ≤ 300 lignes diff (le gros vient du squelette `ios/` généré automatiquement, qui peut représenter 200-300 lignes mais c'est du boilerplate Xcode)
- [ ] Commit `feat(core): bootstrap squelette iOS et verification cross-platform`

#### Notes pour Amelia

- **Mac requis**. Si pas de Mac local, utiliser un service de cloud Mac (MacInCloud, MacStadium) pour cette story.
- Le `flutter create -t app --platforms=ios .` peut écraser certains fichiers du dossier racine `mobile_app/` (ex. README) — utiliser un répertoire temporaire si nécessaire et copier seulement `ios/` à la fin.
- **Pas de Firebase ici** — Story 0.6 s'en occupe. Cette story livre juste un squelette iOS propre.
- **Pas de signing release** — `--no-codesign` est OK pour debug. Le signing release sera traité en Story 0.17 (CI macOS).
- **Capabilities Xcode** : ne pas activer Push Notifications / Background Modes ici — sera fait en Story 0.6.
- **Tester rapide** : ouvrir `ios/Runner.xcworkspace` dans Xcode pour vérifier que le projet est lisible (pas obligatoire si la CLI build passe).
- Cette story ne livre **aucun changement Dart** — uniquement du squelette iOS + audit.

---

### Story 0.5 : Setup Dio + retry + connectivity_plus

**Statut** : Draft
**Sprint** : P0 (semaine 0)
**Dépendances** : Story 0.3, Story 0.4
**Estimation** : M (~4-5h)

**As a** dev Flutter,
**I want** un `DioClient` central avec interceptors retry/logging et un `NetworkInfo` qui expose la connectivité,
**so that** NFR-15 (couverture connectivité instable) soit appliquée systématiquement et que tout appel HTTP soit tracé.

#### Contexte technique

Marché cible = connectivité fluctuante (cf. SPEC). Pattern retry Dio : 3 tentatives backoff exponentiel (500ms, 1s, 2s) sur 5xx + timeouts ; PAS de retry sur 4xx (sauf 429). `connectivity_plus` expose un stream consommé par un provider Riverpod. `dio_smart_retry` ou implémentation interceptor manuel — au choix dev, mais privilégier le custom pour ne pas ajouter de dépendance fragile.

À noter : Dio n'est utilisé que pour appels HTTP **non Firebase** (Cloud Functions custom appelées directement, certaines APIs externes). Les appels Firebase passent par les SDK Firebase (Story 0.6).

#### Acceptance Criteria

**AC1 — Packages ajoutés**
**Given** `pubspec.yaml`
**When** on ajoute `dio` et `connectivity_plus` aux dernières stables
**Then** `flutter pub get` réussit

**AC2 — `DioClient` créé**
**Given** `lib/core/network/dio_client.dart`
**When** on instancie `DioClient`
**Then** il expose une `Dio` avec base URL configurable (env), timeout 30s
**And** un interceptor de log qui appelle `AppLogger.d/i/w/e` (pas de log du body si > 1 KB)

**AC3 — Retry interceptor implémenté**
**Given** un endpoint qui renvoie 503 deux fois puis 200
**When** on `dioClient.get('/test')`
**Then** la requête réussit en 3 tentatives au total (backoff 500ms, 1s)
**And** un log `AppLogger.w` indique chaque retry avec le délai
**And** un test unitaire avec mock `Dio` valide ce comportement

**AC4 — `NetworkInfo` provider exposé**
**Given** `lib/core/network/network_info.dart`
**When** on `ref.watch(networkInfoProvider).status`
**Then** on reçoit `online | offline | unknown` (basé sur `Connectivity().checkConnectivity()`)
**And** le stream émet à chaque changement

#### Definition of Done

- [ ] Tests unitaires : retry (3 cas : 503→503→200, 503×4, 200 direct) + NetworkInfo (2 cas mock)
- [ ] PR ≤ 350 lignes diff
- [ ] Commit `feat(core): DioClient avec retry et NetworkInfo`

#### Notes pour Amelia

- Ne pas mettre la base URL en dur — utilise `--dart-define=API_BASE_URL=...` et lis via `String.fromEnvironment` dans `core/utils/env.dart` (à créer dans cette story).
- Le retry interceptor doit propager `DioException` après épuisement (l'app la traduira en `NetworkFailure` via Story 0.4).
- N'ajoute PAS `pretty_dio_logger` ou autre — `AppLogger` suffit.

---

### Story 0.6 : Setup Firebase Android + iOS (Auth, Firestore, Storage, Functions, FCM, Crashlytics, Analytics, Remote Config, App Check)

**Statut** : Draft
**Sprint** : P0 (semaine 0-1)
**Dépendances** : Story 0.2, Story 0.4bis (bootstrap iOS)
**Estimation** : L+ (~10-12h, dont 5h admin Firebase Console pour 2 plateformes + signing iOS)
**Risque** : Demande accès Firebase Console + compte Apple Developer (certificats, Bundle ID provisionning).

**As a** tech lead,
**I want** Firebase intégré sur Android **et iOS** avec tous les modules nécessaires initialisés en lazy-load au plus près de leur usage,
**so that** les epics suivants puissent consommer Auth/Firestore/Functions/FCM sur les deux plateformes sans setup supplémentaire et que NFR-3 (lazy-load) + NFR-16 (cross-platform) soient respectées.

#### Contexte technique

ADR-003 acte Firebase comme backend complet. ADR-011 (2026-06-04) acte le scope cross-platform V1. Cette story configure **Android ET iOS** dans le même projet Firebase. FlutterFire CLI est utilisé pour générer `firebase_options.dart` avec les deux plateformes. La région cible Cloud Functions est `europe-west1` (à confirmer après Story 0.20 R3). L'initialisation Crashlytics est faite au `main()` ; les autres modules sont init lazy (Auth quand l'écran login s'ouvre, Firestore quand premier provider Firestore est lu, etc.).

App Check est ajouté ici mais activé en mode debug provider seulement (Story 0.8 activera `enforceAppCheck: true`). Côté iOS, App Check utilise **DeviceCheck** (debug : `AppCheck.debugProvider`).

#### Acceptance Criteria

**AC1 — Projet Firebase créé avec les 2 plateformes**
**Given** la Firebase Console
**When** un projet `valide-school-mvp` est créé en plan Blaze (pay-as-you-go)
**Then** Auth (Email + Google + Apple), Firestore (Native mode, `europe-west1`), Storage (`europe-west1`), Cloud Functions (`europe-west1`), FCM, Crashlytics, Analytics (consentement à gérer plus tard), Remote Config, App Check (DeviceCheck iOS + Play Integrity Android) sont activés
**And** une **app Android** est ajoutée avec package `com.valideStartup.valideSchool` → `google-services.json` téléchargé et placé dans `mobile_app/android/app/`
**And** une **app iOS** est ajoutée avec Bundle ID `com.valideStartup.valideSchool` → `GoogleService-Info.plist` téléchargé et placé dans `mobile_app/ios/Runner/`

**AC2 — FlutterFire CLI configuré pour les 2 plateformes**
**Given** `flutterfire configure --project=valide-school-mvp --platforms=android,ios` est exécuté
**When** la commande termine
**Then** `lib/firebase_options.dart` est généré avec `DefaultFirebaseOptions.android` ET `DefaultFirebaseOptions.ios`
**And** `android/app/build.gradle.kts` est patché avec `google-services` plugin
**And** `ios/Runner.xcworkspace` ouvre dans Xcode sans erreur et `pod install` réussit (CocoaPods configuré dans `ios/Podfile`)

**AC3 — Initialisation au démarrage (les 2 plateformes)**
**Given** `main.dart`
**When** l'app démarre
**Then** `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` est appelé avant `runApp` — `currentPlatform` sélectionne automatiquement Android ou iOS
**And** `FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode)` est appelé
**And** `FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError`
**And** l'app build et lance sans erreur sur un émulateur Android **ET** un simulateur iOS

**AC4 — Lazy-load des autres modules**
**Given** la règle NFR-3
**When** on inspecte le code de bootstrap
**Then** Auth, Firestore, Storage, Functions, FCM, Remote Config NE sont PAS importés dans `main.dart`
**And** chacun est consommé via un provider Riverpod lazy (créé à la 1ère lecture)

**AC5 — Crashlytics testé sur les 2 plateformes**
**Given** une route debug `/_crash` (à supprimer après test)
**When** on tape sur un bouton qui fait `throw Exception('crash test')`
**Then** un crash apparaît dans Crashlytics Console dans les 5 minutes **pour les builds Android et iOS** (vérifier le filtre par plateforme dans la Console)
**And** le crash est marqué `non-fatal: false`

#### Definition of Done

- [ ] `google-services.json` ET `GoogleService-Info.plist` placés (en CI : restitués depuis secrets GitHub Actions encodés base64)
- [ ] Aucun secret dans le commit ; les deux fichiers sont dans `.gitignore`
- [ ] `lib/firebase_options.dart` généré et committé (les valeurs sont des identifiants publics, OK)
- [ ] Build Android `flutter build apk --debug` réussit
- [ ] Build iOS `flutter build ios --debug --no-codesign` réussit
- [ ] App lance sur émulateur Android ET simulateur iOS (cf. AC3)
- [ ] Crashlytics console montre un crash test sur les 2 plateformes (cf. AC5)
- [ ] Commit `feat(core): integration Firebase Android et iOS avec lazy-load des modules`
- [ ] `flutter pub get` réussit avec FlutterFire packages aux versions du `firebase_options.dart`

#### Notes pour Amelia

- **CRITIQUE** : `google-services.json` ET `GoogleService-Info.plist` sont dans `.gitignore`. Utiliser des secrets GitHub Actions `GOOGLE_SERVICES_JSON_BASE64` et `GOOGLE_SERVICE_INFO_PLIST_BASE64` pour les restituer en CI. Documenter la procédure dans `doc/tools/CONTRIBUTING.md` (Story 0.17 CI/CD).
- Si `kDebugMode == true`, Crashlytics doit être OFF (sinon spam de crashes de dev).
- Ne fais PAS `await` sur les autres init Firebase au `main()` — vraiment lazy.
- **iOS spécifiques** :
  - Min iOS 13.0 dans `ios/Podfile` (`platform :ios, '13.0'`).
  - Bundle ID `com.valideStartup.valideSchool` à figer dans `ios/Runner.xcodeproj/project.pbxproj`.
  - Capabilities Xcode à activer : Push Notifications (pour FCM), Background Modes (background fetch + remote notification).
  - `Info.plist` : `NSCameraUsageDescription` (pour Mode 1 photo, même si la story Mode 1 vient plus tard — anticiper le wording FR/EN), `NSUserTrackingUsageDescription` si Analytics IDFA utilisé (à vérifier).
  - Provisioning : utiliser un certificat développeur Apple pour le build debug ; le release sera couvert par Story 0.17 (CI macOS).
- **Hook AppLogger.e() → Crashlytics** : ajouter dans `app_logger.dart` un forward optionnel vers `FirebaseCrashlytics.instance.recordError()` quand le service est disponible (initialisé). Cette story est le moment où on branche ce forward (TODO laissé en Story 0.3 mentionnant cette story).

---

### Story 0.7 : Setup cache offline Firestore

**Statut** : Draft
**Sprint** : P0 (semaine 0-1)
**Dépendances** : Story 0.6
**Estimation** : XS (~1h)

**As a** dev Flutter,
**I want** le cache offline Firestore activé avec `persistenceEnabled: true` et `cacheSizeBytes: 40 MB`,
**so that** NFR-5 (pas de cache custom, uniquement le cache Firestore natif) et l'usage hors-ligne (FR-14) soient garantis dès la première lecture.

#### Contexte technique

ADR-010 acte « zéro cache custom ». Le cache offline Firestore est activé par défaut sur mobile mais avec une taille de cache de 100 MB. On la borne à 40 MB pour les téléphones modestes du marché cible (NFR-1, NFR-2). Sur Android, le cache utilise SQLite interne ; sur web (non concerné V1), c'est IndexedDB.

#### Acceptance Criteria

**AC1 — Settings appliqués au boot Firestore**
**Given** le provider Firestore Riverpod
**When** il est lu pour la première fois
**Then** `FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true, cacheSizeBytes: 40 * 1024 * 1024)` est appliqué avant tout `get`/`snapshots`
**And** un `AppLogger.i('Firestore cache: 40MB, persistence on')` confirme

**AC2 — Lecture cached vérifiée**
**Given** une lecture initiale de `_smoketest/launch` en ligne
**When** on coupe le réseau puis on relit
**Then** le document est servi depuis le cache (vérifiable via `metadata.isFromCache == true`)
**And** un test d'intégration simulant la coupure valide

**AC3 — Pas de cache custom dans le code**
**Given** une recherche dans `lib/`
**When** on grep `hive`, `drift`, `isar`, `sqflite`, `Map<String,` (utilisé pour cache)
**Then** aucun résultat de cache custom n'est trouvé
**And** documenté dans `doc/tech/Valide School App Architecture.md` § 12

#### Definition of Done

- [ ] 1 test d'intégration (peut être skippé en CI si flaky, mais à coder)
- [ ] PR ≤ 80 lignes diff
- [ ] Commit `feat(core): cache offline Firestore 40MB persistence on`

#### Notes pour Amelia

- L'ordre est critique : configurer `settings` **avant** tout `collection().get()` sinon Firestore lock les settings.
- Si tu lis une mauvaise valeur de `cacheSizeBytes` dans un crash report, c'est probablement Story 0.6 qui a une init désynchronisée.

---

### Story 0.8 : Setup App Check (Play Integrity provider)

**Statut** : Draft
**Sprint** : P0 (semaine 1)
**Dépendances** : Story 0.6
**Estimation** : S (~3h)

**As a** tech lead sécurité,
**I want** App Check activé avec Play Integrity en prod et debug provider en dev,
**so that** NFR-10 (App Check enforced sur Cloud Functions) soit appliquée et que les Cloud Functions sensibles rejettent les requêtes hors app officielle.

#### Contexte technique

NFR-10 + ADR-003. App Check protège Firestore et Cloud Functions contre les clients non-officiels (bots, scripts). En dev, le provider doit être `AppCheckProvider.debug` (avec un token debug enregistré dans Firebase Console). En release, c'est `AndroidProvider.playIntegrity`.

L'activation `enforceAppCheck: true` côté Cloud Functions sera faite story par story dans E4/E6 quand les Functions sensibles seront déployées — cette story ne fait que côté client.

#### Acceptance Criteria

**AC1 — Activation conditionnelle**
**Given** `main.dart` après `Firebase.initializeApp`
**When** l'app boot
**Then** `await FirebaseAppCheck.instance.activate(androidProvider: kReleaseMode ? AndroidProvider.playIntegrity : AndroidProvider.debug)` est exécuté
**And** un `AppLogger.i('AppCheck: ${kReleaseMode ? 'playIntegrity' : 'debug'}')` est émis

**AC2 — Token debug enregistré**
**Given** un build debug
**When** on lance l'app
**Then** un token debug est imprimé dans les logs Android (`adb logcat`)
**And** ce token est ajouté manuellement dans Firebase Console > App Check > Debug tokens
**And** la procédure est documentée dans `doc/tools/CONTRIBUTING.md`

**AC3 — Lecture Firestore protégée OK**
**Given** App Check actif en debug
**When** on lit `_smoketest/launch`
**Then** la lecture réussit (token validé)
**And** sans token (autre app), la lecture échoue avec `permission-denied` (à vérifier via app de test séparée, optionnel)

#### Definition of Done

- [ ] Procédure documentée dans `doc/tools/CONTRIBUTING.md` (récupération token debug)
- [ ] PR ≤ 150 lignes diff
- [ ] Commit `feat(core): App Check avec Play Integrity et debug provider`

#### Notes pour Amelia

- Sans token debug enregistré, **les requêtes Firestore échoueront silencieusement en dev** — c'est un piège connu, documente bien.
- iOS = `DeviceCheckProvider` ou `AppAttestProvider` selon version iOS. Pas dans cette story (V1 Android only).
- L'enforcement `enforceAppCheck: true` côté Functions ne se fait QUE pour les Functions critiques (paiement, IA, débit crédits) — story par story plus tard.

---

### Story 0.9 : Setup règles Firestore initiales

**Statut** : Draft
**Sprint** : P0 (semaine 1)
**Dépendances** : Story 0.6
**Estimation** : M (~4-5h)

**As a** tech lead sécurité,
**I want** des règles Firestore initiales qui valident le schéma `users/{uid}` et bloquent tout accès non authentifié,
**so that** NFR-9 (vrai verrou côté serveur) commence à être appliquée dès P0 et que la sentinelle E0 puisse valider l'écriture.

#### Contexte technique

NFR-9 : « le vrai verrou est dans les règles Firestore » (cf. CLAUDE.md). Cette story pose le squelette des règles : default deny + match `users/{uid}` self-only + match `_smoketest/{doc}` pour la story sentinelle (à retirer plus tard). Le schéma `users/{uid}` doit valider les champs cités dans `doc/partage/BASE-DE-DONNEES.md` § 1 (uid, displayName, profile.subsystem, profile.curriculum, createdAt, updatedAt).

Le déploiement des règles passe par `firebase deploy --only firestore:rules` documenté.

#### Acceptance Criteria

**AC1 — Fichier `firestore.rules` créé**
**Given** racine projet
**When** on crée `firestore.rules` à la racine
**Then** il commence par `rules_version = '2'; service cloud.firestore { match /databases/{database}/documents { ... default deny ... } }`
**And** un commentaire en-tête liste les ADRs et docs de référence

**AC2 — Match `users/{uid}` self-only**
**Given** un user authentifié `uid = 'abc'`
**When** il lit `users/abc`
**Then** la lecture réussit
**When** il lit `users/xyz` (autre user)
**Then** la lecture est refusée
**And** la création doit valider la présence des champs requis (`profile.subsystem` ∈ `['francophone', 'anglophone']`)

**AC3 — Match `_smoketest/{doc}` autorisé authentifié**
**Given** un user authentifié
**When** il écrit et lit `_smoketest/launch`
**Then** les deux opérations réussissent
**And** un commentaire `// TODO: remove after E0 sentinel validated` est présent

**AC4 — Déploiement testé**
**Given** Firebase CLI installé
**When** `firebase deploy --only firestore:rules --project=valide-school-mvp` est exécuté
**Then** le déploiement réussit
**And** les règles sont visibles dans Firebase Console > Firestore > Rules
**And** la commande de déploiement est documentée dans `doc/tools/CONTRIBUTING.md`

**AC5 — Tests des règles (firebase emulator)**
**Given** `firebase emulators:start --only firestore`
**When** on lance les tests `firebase_rules_test`
**Then** 4 tests passent : (a) user auth lit son doc OK, (b) user auth lit doc autre KO, (c) user non auth tout KO, (d) écriture user avec subsystem invalide KO

#### Definition of Done

- [ ] Tests `firebase emulator` exécutables localement
- [ ] PR ≤ 250 lignes diff
- [ ] Commit `feat(core): regles Firestore initiales avec users self-only et smoketest`
- [ ] `doc/partage/BASE-DE-DONNEES.md` § règles mis à jour (lien vers `firestore.rules`)

#### Notes pour Amelia

- Le test des règles passe par `@firebase/rules-unit-testing` côté Node — coder une petite suite TS dans `firebase/test/rules/` du dépôt mobile, ou alors documenter le test manuel via Firebase Console > Rules Playground si pas le temps.
- **Toute modification de ces règles plus tard doit passer par une story dédiée** + accord backend (cf. CLAUDE.md règle `doc/partage`).
- Le matching `_smoketest/{doc}` doit être supprimé dans une story de fin E0 ou début E1 (`// TODO`).

---

### Story 0.10 : Setup design tokens (`core/theme/tokens.dart`)

**Statut** : Draft
**Sprint** : P0 (semaine 0-1)
**Dépendances** : Story 0.2
**Estimation** : M (~4-5h)

**As a** dev Flutter,
**I want** les design tokens (couleurs, typo, spacing, radii, élévations) cristallisés dans `core/theme/tokens.dart` et appliqués via `ThemeData`,
**so that** les composants UX (Stories 0.13, 0.14) utilisent directement les tokens et que la règle « pas de magic numbers » soit appliquée.

#### Contexte technique

Source = DESIGN.md (notre artefact UX) qui contient les tokens lifted depuis `doc/tech/Valide - Design System.html`. Cette story ne lit QUE `DESIGN.md` (la source canonique) — pas le HTML directement. ThemeData clair seulement V1 (pas de dark mode P0). Pas de `flutter_screenutil` ici (Story 0.12 le wrappera).

Couleurs clés : primaire `#2563EB`, ink `#0F172A`, succès vert, warning ambre, erreur rouge, info ciel — chacune avec ses teintes `-soft`, `-soft-border`, `-ink`.

#### Acceptance Criteria

**AC1 — Tokens structurés**
**Given** `lib/core/theme/tokens.dart`
**When** on inspecte le fichier
**Then** il expose des classes/namespaces `AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppElevation`
**And** chaque token a un nom mappant 1:1 sur DESIGN.md (`AppColors.primary`, `AppColors.primarySoft`, `AppSpacing.s4` = 16 etc.)

**AC2 — Palette complète**
**Given** `AppColors`
**When** on liste les valeurs
**Then** sont définies : `primary`, `primaryDark`, `primaryLight`, `primarySoft`, `primarySoftBorder`, `ink`, `inkSoft`, `muted`, `mute2`, `border`, `bg`, `card`, `success`, `successSoft`, `successInk`, `warning`, `warningSoft`, `warningInk`, `danger`, `dangerSoft`, `dangerInk`, `sky`, `skySoft`, `skyInk` (22 couleurs)
**And** chaque hex match DESIGN.md à la majuscule près

**AC3 — Typographie complète**
**Given** `AppTypography`
**When** on liste les styles
**Then** sont définis : `display`, `h1`, `h2`, `h3`, `body`, `bodyStrong`, `meta`, `caption`, `eyebrow` (9 styles)
**And** chaque style a `fontFamily: 'Nunito Sans'`, `fontWeight`, `fontSize`, `height` correspondant à DESIGN.md

**AC4 — Spacing, Radius, Elevation**
**Given** les autres tokens
**When** on liste
**Then** `AppSpacing.s1..s10..s16` (valeurs 4/8/12/16/20/24/32/40/48/64), `AppRadius.xs..pill` (6/9/11/14/16/18/999), `AppElevation.soft/mid/brand`
**And** chaque valeur match DESIGN.md

**AC5 — Motion tokens**
**Given** une classe `AppMotion` dans `tokens.dart`
**When** on liste les tokens
**Then** sont définis : `AppMotion.instant` (0 ms), `AppMotion.fast` (120 ms), `AppMotion.standard` (200 ms), `AppMotion.emphasis` (300 ms), `AppMotion.celebration` (600 ms)
**And** les easings `AppMotion.standardOut` (`Curves.easeOut`), `standardIn` (`Curves.easeIn`), `emphasized` (`Curves.easeOutCubic`)
**And** `AppMotion.stagger` (50 ms)
**And** chaque valeur correspond au tableau « Motion tokens » de DESIGN.md § Animations & motion

**AC6 — ThemeData consommable**
**Given** un `appTheme = buildLightTheme()` dans `lib/core/theme/app_theme.dart`
**When** appliqué à `MaterialApp.router(theme: appTheme)`
**Then** un `Text('test', style: AppTypography.body)` rend en Nunito Sans (placeholder font si Story 0.11 pas faite — accepter Material default temporairement)
**And** `Container(color: AppColors.primary)` rend en bleu `#2563EB`

#### Definition of Done

- [ ] Tests widget : 1 test qui rend `MaterialApp(theme: appTheme)` et lit la couleur primaire effective
- [ ] Tests unitaires : 1 test qui vérifie les durations motion (au moins `fast`, `standard`, `emphasis`)
- [ ] PR ≤ 400 lignes diff (tokens nombreux mais structurés)
- [ ] Commit `feat(theme): design tokens alignes sur DESIGN.md`

#### Notes pour Amelia

- N'ajoute PAS de tokens absents de DESIGN.md même s'ils semblent utiles — toute extension passe par mise à jour DESIGN.md d'abord.
- Les tokens spacing utilisent `double` (pas `int`) — compatible `flutter_screenutil` `.w` plus tard.
- N'utilise PAS `Color.fromARGB` — utilise `Color(0xFF2563EB)` (`0xFF` + hex sans `#`).
- Les motion tokens sont exposés en `Duration` (pas en `int`) : `static const fast = Duration(milliseconds: 120);`.

---

### Story 0.11 : Setup fonts Nunito Sans + JetBrains Mono

**Statut** : Draft
**Sprint** : P0 (semaine 0-1)
**Dépendances** : Story 0.10
**Estimation** : S (~2h)

**As a** dev Flutter,
**I want** les fonts Nunito Sans (variable weights 400/600/700/800/900) et JetBrains Mono (400/700) embarquées dans l'app et configurées dans `pubspec.yaml`,
**so that** la typographie rendue corresponde au design (DESIGN.md) sans appel réseau Google Fonts en runtime.

#### Contexte technique

DESIGN.md spécifie Nunito Sans (texte général) et JetBrains Mono (blocs de code). Le pack `google_fonts` est explicitement déconseillé en V1 pour Valide à cause de :
- Latence sur première charge dans environnement à connexion fluctuante (R3)
- Taille APK non maîtrisée (NFR-1)

Solution : télécharger les TTF/OTF depuis Google Fonts (CC0 ou OFL), les placer dans `assets/fonts/`, déclarer dans `pubspec.yaml`.

#### Acceptance Criteria

**AC1 — Fonts téléchargées et placées**
**Given** Google Fonts pour Nunito Sans (variable) et JetBrains Mono (regular + bold)
**When** les fichiers sont placés
**Then** `assets/fonts/NunitoSans-VariableFont_wght.ttf`, `assets/fonts/JetBrainsMono-Regular.ttf`, `assets/fonts/JetBrainsMono-Bold.ttf` existent
**And** chaque fichier ≤ 500 KB

**AC2 — Déclaration `pubspec.yaml`**
**Given** la section `flutter:` de `pubspec.yaml`
**When** on inspecte
**Then** les fonts sont déclarées avec weights mappés (400/600/700/800/900 pour Nunito, 400/700 pour Mono)
**And** `flutter pub get && flutter run` démarre sans warning de font

**AC3 — Application via tokens**
**Given** `AppTypography` (Story 0.10)
**When** on rend `Text('Bonjour', style: AppTypography.h1)`
**Then** Nunito Sans 800 28px est utilisé (vérifiable par golden test ou debug paint)

**AC4 — Vérification taille APK**
**Given** `flutter build apk --release`
**When** la build termine
**Then** la taille n'augmente pas de plus de 1.5 MB par rapport à l'avant-story
**And** documenté dans `project_manage/planning-artifacts/architecture/.decision-log.md`

#### Definition of Done

- [ ] License Google Fonts respectée (OFL — pas besoin d'attribution dans l'app mais doc dans `doc/tech/` § Polices)
- [ ] PR ≤ 50 lignes diff (hors binaires fonts)
- [ ] Commit `feat(theme): polices Nunito Sans et JetBrains Mono integrees`

#### Notes pour Amelia

- Pour la variable font Nunito Sans, Flutter ≥ 3.7 gère les axes de variation — sinon fallback : télécharge chaque poids séparément.
- Vérifie le licensing OFL des fonts avant de les commit — Google Fonts diffuse en OFL la plupart du temps mais à vérifier.
- Ne PAS utiliser `google_fonts` package — c'est explicitement écarté.

---

### Story 0.12 : Setup `flutter_screenutil` + helper responsive 3 form factors

**Statut** : Draft
**Sprint** : P0 (semaine 1)
**Dépendances** : Story 0.2, Story 0.10
**Estimation** : M (~4h — +helper breakpoints et tests responsive vs S initial)

**As a** dev Flutter,
**I want** `flutter_screenutil` wrappé autour de `MaterialApp.router` avec design size 375×812, **plus un helper `Responsive` qui expose les 3 form factors (phone/phone-landscape/tablet)**,
**so that** l'UX rende correctement sur phone, phone-landscape et tablette (Android et iOS) sans rework futur.

#### Contexte technique

Règle CLAUDE.md § Architecture mobile 7 : pas de pixels en dur, utiliser `.w`/`.h`/`.sp`/`.r`. Design size de référence : 375×812 (cf. Mobile Package Architecture § 9 — c'est la taille d'iPhone 14, valide aussi pour Android entry phone).

**Breakpoints responsive** (cf. EXPERIENCE.md § Responsive & Platform) :

- `phone` : largeur < 600 dp
- `phoneLandscape` : 600-840 dp (couvre aussi small tablet portrait)
- `tablet` : ≥ 840 dp

Le wrapping doit être : `ProviderScope > ScreenUtilInit > MaterialApp.router`. `flutter_screenutil` gère l'échelle relative à 375×812 — **pour les layouts multi-colonnes**, on s'appuie sur `LayoutBuilder` ou `MediaQuery.sizeOf(context).width` (`Responsive` helper l'encapsule).

#### Acceptance Criteria

**AC1 — Package ajouté et wrapping**
**Given** `pubspec.yaml`
**When** on ajoute `flutter_screenutil` à la dernière stable
**Then** `flutter pub get` réussit
**And** `main.dart` enveloppe `MaterialApp.router` dans `ScreenUtilInit(designSize: const Size(375, 812), child: ...)`

**AC2 — Usage dans un composant test**
**Given** la page `/hello`
**When** on remplace `padding: 16` par `padding: 16.w`
**Then** le rendu visuel est identique sur 375dp et s'adapte sur 412dp
**And** un test widget vérifie le calcul

**AC3 — Lint custom contre pixels en dur**
**Given** un fichier `lib/foo.dart` qui contient `padding: EdgeInsets.all(16)`
**When** `dart analyze` ou un script CI grep est exécuté
**Then** un warning/erreur est produit
**And** la règle est documentée dans `analysis_options.yaml`
**And** des exceptions sont autorisées dans `lib/core/theme/` (les tokens sources)

**AC4 — Tokens compatibles**
**Given** `AppSpacing.s4` (Story 0.10) = `16.0`
**When** on utilise `AppSpacing.s4.w` dans un widget
**Then** cela compile et rend la bonne valeur sur 375dp

**AC5 — Helper `Responsive` 3 form factors**
**Given** `lib/core/responsive/responsive.dart`
**When** on appelle `Responsive.of(context).formFactor`
**Then** il retourne `FormFactor.phone` (< 600 dp), `FormFactor.phoneLandscape` (600-840 dp) ou `FormFactor.tablet` (≥ 840 dp)
**And** un widget `Responsive.builder(builder: (context, formFactor) => ...)` est exposé pour les cas de layout adaptatifs
**And** un test widget vérifie le bon classement sur 3 tailles d'écran simulées (375×812, 768×1024, 1024×1366)

**AC6 — Page Hello adaptée aux 3 form factors**
**Given** la page `/hello` actuelle
**When** on la rend sur phone et sur tablet
**Then** le texte « Hello Valide » reste centré, taille `AppTypography.h1.sp` adaptée, max-width 600 dp sur tablet (pas étalé)
**And** ce comportement est testé avec un golden test simple sur 2 tailles

#### Definition of Done

- [ ] PR ≤ 300 lignes diff (légèrement plus grosse à cause du helper Responsive + tests)
- [ ] Tests : AC2 widget + AC5 unitaires + AC6 golden basique
- [ ] Commit `feat(theme): flutter_screenutil et helper Responsive 3 form factors`

#### Notes pour Amelia

- Si lint custom trop complexe : fallback grep CI Story 0.17.
- `.sp` pour fontSize avec floor pour éviter rendu blurry sur petits écrans.
- N'utilise PAS `MediaQuery` directement (sauf cas particulier safe area) — passe par `ScreenUtil` pour l'échelle, par `Responsive` pour le form factor.
- Le helper `Responsive` n'est PAS un `InheritedWidget` lourd — il utilise simplement `MediaQuery.sizeOf(context)` en interne. Pas de provider Riverpod ici.
- Pour le golden test : utiliser `goldenFileTester` avec `flutter test --update-goldens` la première fois. Si les goldens deviennent un blocker en revue (différences CI vs local), accepter de les mettre derrière un tag `@Tags(['golden'])` et de les exécuter optionnellement.

---

### Story 0.13 : Composants UX globaux atomiques (Button, Input, Card, Badge, PillTabs, Progress, IconButton)

**Statut** : Draft
**Sprint** : P0 (semaine 1)
**Dépendances** : Story 0.10, Story 0.11, Story 0.12
**Estimation** : L (~8h, 7 composants × ~1h chacun + tests)

**As a** dev Flutter,
**I want** les composants atomiques (boutons, input, carte, badge, pill tabs, progression bar, icon button) implémentés dans `lib/core/widgets/` avec leurs tests widget,
**so that** les epics métier (E1-E6) puissent les consommer directement sans réinventer la roue et que UX-DR-1 à UX-DR-7 soient couvertes.

#### Contexte technique

EXPERIENCE.md § Patterns + DESIGN.md § Composants. Chaque composant doit :
- Accepter ses paramètres essentiels (label, onPressed, état loading/disabled, icône optionnelle)
- Utiliser exclusivement `AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`
- Touch target ≥ 48dp (UX-DR-29)
- Focus indicator visible (UX-DR-30)
- Être testé widget (golden test optionnel + comportement)

Icônes : `lucide_icons` (line, stroke-width 2, cf. DESIGN.md).

#### Acceptance Criteria

**AC1 — `AppButton.primary` et `AppButton.secondary`**
**Given** `lib/core/widgets/app_button.dart`
**When** on construit `AppButton.primary(label: 'Continuer', onPressed: () {})`
**Then** rend un bouton 52.h, `AppRadius.lg`, `AppColors.primary` bg, label weight 700
**And** state `loading: true` affiche spinner inline + label « Envoi… »
**And** state `disabled: true` réduit opacité 50% et `onPressed` ignoré
**And** touch target effectif ≥ 48dp (vérifié par test)
**And** au tap : anim `tap feedback` (scale 0.96→1.0 + opacity 0.7→1.0, durée `AppMotion.fast`) + `HapticFeedback.lightImpact()` sur `primary` / `HapticFeedback.selectionClick()` sur `secondary` (cf. EXPERIENCE.md § Multisensoriel)
**And** si `Profil.vibrationsEnabled == false`, le haptic est skip (Story 0.14 expose le `HapticService`)

**AC2 — `AppInput`**
**Given** `lib/core/widgets/app_input.dart`
**When** on construit `AppInput(label: 'Email', controller: ctrl)`
**Then** rend un champ 52.h, label obligatoire au-dessus, focus bordure 2px `AppColors.primary`
**And** un `errorText: 'Email invalide'` affiche en rouge sous le champ

**AC3 — `AppCard`**
**Given** `lib/core/widgets/app_card.dart`
**When** on construit `AppCard(child: Text('...'))`
**Then** rend un container 24.w padding, `AppRadius.xl2`, bordure 1px `AppColors.border`, shadow `AppElevation.soft`
**And** un `onTap` optionnel rend la card tappable avec ripple

**AC4 — `AppBadge`**
**Given** `lib/core/widgets/app_badge.dart`
**When** on construit `AppBadge(label: 'À renforcer', tone: BadgeTone.warning)`
**Then** rend un pill 4×10px padding, `AppColors.warningSoft` bg, texte `AppColors.warningInk` caption 12sp weight 700
**And** UX-DR-5 : le badge n'est JAMAIS rendu sans label (couleur jamais signal seul) — assert en debug

**AC5 — `AppPillTabs`**
**Given** `lib/core/widgets/app_pill_tabs.dart`
**When** on construit avec 3 tabs `['Tout', 'En cours', 'Fini']`
**Then** rend un container `AppRadius.lg`, item actif fond blanc + texte primary, items inactifs texte ink-soft
**And** un `onTabSelected` callback est appelé au tap
**And** l'indicateur actif glisse avec une `AnimatedAlign` de durée `AppMotion.fast` (120 ms) entre les pills + `HapticFeedback.selectionClick()` au switch

**AC6 — `AppProgressBar`**
**Given** `lib/core/widgets/app_progress_bar.dart`
**When** on construit `AppProgressBar(value: 0.4, label: '4/10')`
**Then** rend une barre 8.h, `AppRadius.xs`, fill `AppColors.primary` à 40%
**And** un label caption optionnel en-dessous
**And** transition de `value` animée avec `AnimatedContainer` durée `AppMotion.emphasis` (300 ms), easing `AppMotion.emphasized`

**AC7 — `AppIconButton`**
**Given** `lib/core/widgets/app_icon_button.dart`
**When** on construit avec une icône `LucideIcons.arrowLeft`
**Then** rend un bouton 48.w×48.h touch target, icône 20.sp stroke 2
**And** ripple visible au tap

#### Definition of Done

- [ ] 7 tests widget (1 par composant) + au moins 1 golden test par composant pour le rendu visuel
- [ ] Démo gallery dans `lib/dev/widget_gallery.dart` accessible via route debug `/_gallery` (à retirer post-MVP)
- [ ] PR ≤ 400 lignes diff (composants ramassés)
- [ ] Commit `feat(widgets): composants UX atomiques (button, input, card, badge, tabs, progress, iconbutton)`

#### Notes pour Amelia

- N'externalise PAS les composants en package séparé — `lib/core/widgets/` est OK pour V1.
- Lucide : utilise `lucide_icons` ou `lucide_icons_flutter` (au choix, vérifier maintenance).
- Pour les golden tests, garde-les minimaux (1 par composant) sinon trop coûteux à maintenir.

---

### Story 0.14 : Composants UX feedback + services Haptic & Audio (Toast, Modale, BottomSheet, EmptyState, Skeleton, Spinner, Encadré, célébrations)

**Statut** : Draft
**Sprint** : P0 (semaine 1)
**Dépendances** : Story 0.13
**Estimation** : L+ (~10-12h — +haptic/audio services et célébrations animées)

**As a** dev Flutter,
**I want** les composants de feedback (toast, modale, bottom sheet, empty state, skeleton, spinner, encadré info/warning/error) **plus** les services `HapticService` et `AudioService` **plus** les overlays célébration (success checkmark, error shake, level-up bloom) dans `lib/core/widgets/` et `lib/core/feedback/`,
**so that** les patterns UX (UX-DR-8 à UX-DR-14) et la couche multisensorielle (EXPERIENCE.md § Multisensoriel, DESIGN.md § Audio + Haptics) soient implémentés une seule fois et réutilisables.

#### Contexte technique

- EXPERIENCE.md § Patterns état + Multisensoriel + Emotional Posture.
- DESIGN.md § Animations & motion + Audio + Haptics (catalogue complet).
- Services audio + haptic exposés via providers Riverpod, settings Profil (sons/vibrations ON par défaut, persistés en `SharedPreferences`) — le slot setting est créé ici, l'écran Profil le consomme en E1.
- **Coupures globales** appliquées par les services (mode silencieux, batterie < 15 %, Mode Examen, prefs utilisateur) — cf. table « Coupures globales » EXPERIENCE.md.
- Assets audio : ≤ 12 sons, total ≤ 500 KB, en `assets/audio/*.ogg`, déclarés dans `pubspec.yaml`.

#### Acceptance Criteria

**AC1 — `AppToast.show(context, message, tone)`**
**Given** un `AppToast.show(context, 'Lien copié', tone: ToastTone.success)`
**When** appelé
**Then** un toast slide-in top en 200ms, reste 4s, bg `AppColors.ink` texte `AppColors.card`, icône `LucideIcons.checkCircle` à gauche
**And** un second appel pendant un toast affiche le suivant en file (pas d'overlap)

**AC2 — `AppModal.show(context, child, actions)`**
**Given** un `AppModal.show(context, child: Text('Confirmer ?'), primary: ('Oui', onYes), secondary: ('Non', onNo))`
**When** appelé
**Then** modale plein écran (max-width 420.w), overlay 50% noir, padding 24.w, `AppRadius.xl2`
**And** UX-DR-10 : pas de close X seul — au moins un bouton explicite

**AC3 — `AppBottomSheet.show(context, child, primaryAction)`**
**Given** appel
**When** slide-up
**Then** handle 36×4.h top, `AppRadius.xl2` top seul, safe area respectée, bouton primaire en bas accessible au pouce
**And** swipe-down ou tap hors zone ferme

**AC4 — `AppEmptyState`**
**Given** `AppEmptyState(icon: LucideIcons.inbox, title: 'Aucune notification', subtitle: 'Tu seras notifié dès qu\'il y aura du nouveau', cta: ('Explorer', onTap))`
**When** rendu
**Then** icône 64.sp centrée, titre h3, body texte muted, CTA `AppButton.primary` optionnel
**And** test widget vérifie absence de CTA si `cta == null`

**AC5 — `AppSkeleton`**
**Given** `AppSkeleton(width: 200.w, height: 16.h)`
**When** rendu
**Then** affiche un container animé shimmer (1.4s loop) avec `AppRadius.sm` ou hérité
**And** si `MediaQuery.disableAnimations == true`, rend un container statique (pas d'animation)

**AC6 — `AppSpinner`**
**Given** `AppSpinner(size: 18)`
**When** rendu
**Then** affiche un cercle border 3px, rotation 0.7s, color primary
**And** vise les actions < 3s (above-fold)

**AC7 — `AppInlineAlert`**
**Given** `AppInlineAlert(tone: AlertTone.warning, message: 'Tu n\'as pas de connexion')`
**When** rendu
**Then** padding 16.w, bordure gauche 4px `AppColors.warning`, bg `AppColors.warningSoft`, texte ink-warning
**And** un slot `actions` optionnel pour bouton

**AC8 — `HapticService` (`lib/core/feedback/haptic_service.dart`)**
**Given** un service exposé via `hapticServiceProvider` (Riverpod)
**When** on appelle `ref.read(hapticServiceProvider).light()` (ou `selection`, `medium`, `heavy`, `success`, `error`)
**Then** la méthode invoque le preset `HapticFeedback.*` correspondant (cf. DESIGN.md § Haptics catalogue)
**And** elle no-op si l'une des conditions suivantes est vraie : pref utilisateur `vibrationsEnabled == false`, Mode Examen actif, batterie < 15 %
**And** les séquences `success` et `error` enchainent les presets avec les delays documentés (100 ms / 80 ms)
**And** tests unitaires : 6 cas (un par méthode) + 4 cas coupure (pref off, examen, batterie low, batterie normale = appel passe)

**AC9 — `AudioService` (`lib/core/feedback/audio_service.dart`)**
**Given** un service exposé via `audioServiceProvider` (Riverpod)
**When** on appelle `ref.read(audioServiceProvider).play(AppSfx.successSoft)` (enum des 12 sons du catalogue)
**Then** le son OGG correspondant est joué via `audioplayers` ou `soundpool` (à arbitrer)
**And** il no-op si l'une des conditions suivantes est vraie : pref utilisateur `soundsEnabled == false`, Mode Examen actif, mode silencieux Android détecté
**And** un son qui se joue déjà n'empêche pas le suivant (`stop` + `play` immédiat sur le même slot)
**And** tests unitaires : 1 par condition de coupure + 1 happy path (le service délègue bien au player)

**AC10 — Overlays célébration animés**
**Given** trois widgets dans `lib/core/widgets/feedback/` : `SuccessCheckmarkOverlay`, `ErrorShakeWrapper`, `LevelUpBloomOverlay`
**When** on appelle `SuccessCheckmarkOverlay.show(context)` (ou équivalent)
**Then** l'animation correspondante joue (cf. DESIGN.md § Catalogue d'animations) avec `flutter_animate` + tokens `AppMotion`
**And** le widget orchestre l'appel au `HapticService` et `AudioService` en parallèle de l'anim (un seul point d'appel pour l'orchestration)
**And** si `MediaQuery.disableAnimations == true`, fallback sur affichage statique (icône + texte, pas d'anim)

#### Definition of Done

- [ ] 10 tests widget/unitaires (7 composants + 3 services/overlays)
- [ ] Démo gallery enrichie (`/_gallery`) avec section « Multisensoriel » qui permet de déclencher chaque preset
- [ ] Assets audio placeholders en place (silence OGG si on n'a pas encore les vrais sons — Story P0 séparée optionnelle pour la production des sons)
- [ ] `pubspec.yaml` déclare les 12 assets `assets/audio/*.ogg`
- [ ] Setting Profil `(soundsEnabled, vibrationsEnabled)` exposé en `SharedPreferences` via un `feedbackPrefsProvider` (consommé en E1 par l'écran Profil)
- [ ] PR ≤ 500 lignes diff (taille augmentée vs autres stories à cause des 3 ajouts services/overlays)
- [ ] Commit `feat(widgets): composants feedback + services haptic/audio + overlays celebration`

#### Notes pour Amelia

- Toast : utilise `OverlayEntry` ou `ScaffoldMessenger.of(context).showSnackBar()` adapté (préférer Overlay pour respecter le style ink).
- Skeleton shimmer : `shimmer` package ou implémentation maison `AnimationController` — au choix.
- Modale et BottomSheet : `showDialog` et `showModalBottomSheet` Material avec wrappers stylés.
- **Détection mode silencieux Android** : pas d'API Flutter native simple — utiliser `vibration` package (qui expose la détection) ou implémenter via `MethodChannel` ciblé. Si trop complexe pour P0 : fallback = on respecte uniquement le setting utilisateur, on ne détecte pas le ringer mode.
- **Détection batterie** : package `battery_plus`. À ajouter ici ou wrapper dans un `DeviceStateService` à part — au choix.
- **Production des sons** : hors scope dev. Si les vrais sons ne sont pas disponibles, livre des placeholders `silence.ogg` (8 KB chacun) avec un TODO Story future pour la production audio.
- **Tests audio** : ne pas tester le rendu sonore réel — mocker le `AudioPlayer` et vérifier les appels.
- **Performance Mode Examen** : le check « est-on en mode examen » se fait via un `examModeProvider` (créé dans E6 → en attendant, stub à `false` avec TODO).

---

### Story 0.15 : Setup `PedagogicalContent` wrapper

**Statut** : Draft
**Sprint** : P0 (semaine 1)
**Dépendances** : Story 0.13
**Estimation** : M (~5h)

**As a** dev Flutter,
**I want** un widget `PedagogicalContent` qui wrap `flutter_smooth_markdown` comme seul point d'import autorisé,
**so that** ADR-009 soit appliquée (mitigation risque mainteneur unique) et que tout rendu pédagogique (cours, énoncés, chat IA streaming) passe par ce widget unique.

#### Contexte technique

ADR-009 : `flutter_smooth_markdown` est en 0.7.x avec un mainteneur unique. Pour mitiger le risque, on l'enveloppe dans `lib/core/widgets/pedagogical_content.dart` — l'unique fichier autorisé à l'importer. Si demain le package est abandonné, on remplace l'implémentation interne sans toucher aux 50+ écrans consommateurs.

L'API expose :
- `PedagogicalContent(data: String)` — rendu statique d'un Markdown + LaTeX + Mermaid
- `PedagogicalContent.streaming(stream: Stream<String>)` — rendu progressif (utilisé Mode 3 et chat IA)

#### Acceptance Criteria

**AC1 — Package ajouté**
**Given** `pubspec.yaml`
**When** on ajoute `flutter_smooth_markdown` à la version 0.7.x la plus récente
**Then** `flutter pub get` réussit
**And** les packages embarqués (`flutter_math_fork`, `flutter_svg`, `flutter_highlight`, `cached_network_image`, `url_launcher`) ne sont PAS redéclarés (cf. ADR-009 § Dépendances embarquées) sauf `cached_network_image` et `url_launcher` qui sont utilisés hors widget pédagogique.

**AC2 — Widget statique**
**Given** `PedagogicalContent(data: '# Titre\n\nTexte avec \$x^2\$ inline.')`
**When** rendu
**Then** affiche un H1 stylé selon `AppTypography.h1`, paragraphe stylé `AppTypography.body`, formule LaTeX `x²` rendue
**And** un test widget vérifie le rendu sur 3 cas : Markdown pur, Markdown + LaTeX inline, Markdown + Mermaid flowchart

**AC3 — Widget streaming**
**Given** un `Stream<String>` qui émet `'#'`, `' Ti'`, `'tre'`
**When** `PedagogicalContent.streaming(stream: stream)` est rendu
**Then** le rendu se met à jour à chaque chunk
**And** le texte final équivaut à `PedagogicalContent(data: '# Titre')`

**AC4 — Lint enforce import unique**
**Given** un fichier `lib/foo/bar.dart` qui importerait `package:flutter_smooth_markdown/flutter_smooth_markdown.dart`
**When** `dart analyze` (avec règle custom) ou grep CI est exécuté
**Then** un échec est produit
**And** seul `lib/core/widgets/pedagogical_content.dart` est autorisé (documenté dans `analysis_options.yaml`)

**AC5 — Lazy-load**
**Given** un build release
**When** on profile le démarrage
**Then** le code de `flutter_smooth_markdown` n'est PAS chargé tant que `PedagogicalContent` n'est pas instancié (déferred import si possible)
**And** documenté dans ADR-009 § Lazy-load

#### Definition of Done

- [ ] 3 tests widget (static MD, static LaTeX, streaming)
- [ ] PR ≤ 250 lignes diff
- [ ] Commit `feat(widgets): PedagogicalContent wrapper isole flutter_smooth_markdown`

#### Notes pour Amelia

- Tu peux trouver `flutter_smooth_markdown` 0.7.x pas si découplable du `MaterialApp` parent — adapte si besoin via `Theme.of(context)`.
- Pour le deferred import : `import '...' deferred as smooth;` puis `await smooth.loadLibrary();` à la 1ère utilisation. Si trop complexe, accepte le coût initial (documente).
- **Test précoce Story 0.19** valide le comportement sur 3 cours réels — ne consacre PAS plus de 5h ici à des cas exotiques.

---

### Story 0.16 : Setup i18n FR/EN

**Statut** : Draft
**Sprint** : P0 (semaine 1)
**Dépendances** : Story 0.2
**Estimation** : M (~4h)

**As a** dev Flutter,
**I want** les Flutter Localizations configurées avec ARB FR/EN, gen-l10n, et une vingtaine de chaînes de base traduites,
**so that** NFR-14 (bilinguisme intégral) commence à s'appliquer et qu'aucun PR ne puisse glisser des chaînes hardcodées.

#### Contexte technique

NFR-14 + UX-DR-31. Le projet est strictement bilingue FR/EN. Locale par défaut = FR. Tutoiement FR / informal EN. Tous les `Text(...)` doivent passer par `AppLocalizations.of(context).<key>`.

#### Acceptance Criteria

**AC1 — `l10n.yaml` + ARB**
**Given** la racine projet
**When** on crée `l10n.yaml` + `lib/l10n/app_fr.arb` + `lib/l10n/app_en.arb`
**Then** `flutter gen-l10n` génère `lib/l10n/app_localizations.dart` sans warning
**And** `MaterialApp.router(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, locale: const Locale('fr'))` est configuré

**AC2 — ~20 chaînes de base**
**Given** les fichiers ARB
**When** on liste
**Then** au minimum les chaînes suivantes existent (`@key` description incluse) : `helloValide`, `continueLabel`, `cancelLabel`, `loadingLabel`, `errorGeneric`, `errorNoConnection`, `successCopied`, `confirmYes`, `confirmNo`, `closeLabel`, `retryLabel`, `loadingMore`, `emptyStateGeneric`, `appTitle`, `pageNotFound`, `tryAgain`, `sendingLabel`, `okLabel`, `back`, `next`
**And** chaque clé a sa traduction FR (tutoiement) et EN (informal)

**AC3 — Linting hardcoded strings**
**Given** un widget `Text('Hello')`
**When** `dart analyze` avec règle `prefer-translated-strings` ou un script CI grep est exécuté
**Then** un warning/erreur est produit (exception pour debug routes / dev gallery)
**And** documenté dans `analysis_options.yaml`

**AC4 — Page Hello bilingue**
**Given** la route `/hello`
**When** on change `MaterialApp.locale: const Locale('en')` et reload
**Then** le texte passe de « Bonjour Valide » à « Hello Valide »

#### Definition of Done

- [ ] 2 tests widget (FR et EN)
- [ ] PR ≤ 250 lignes diff
- [ ] Commit `feat(l10n): setup AppLocalizations FR EN`

#### Notes pour Amelia

- Le tutoiement FR est non négociable (cf. CLAUDE.md). Si tu utilises de l'IA pour traduire en FR, garde tutoiement.
- N'utilise PAS `easy_localization` — `flutter_localizations` (Material standard) suffit.
- La règle `prefer-translated-strings` du `dart_code_metrics` est OK si licence permise ; sinon fallback grep CI.

---

### Story 0.17 : Setup CI/CD GitHub Actions (Android + iOS)

**Statut** : Draft
**Sprint** : P0 (semaine 1-2)
**Dépendances** : Story 0.1 (PR build Android peut démarrer dès 0.1 ; iOS et release après 0.6)
**Estimation** : L (~8h — +runner macOS, signing iOS, TestFlight upload vs M initial)

**As a** tech lead,
**I want** un workflow GitHub Actions qui build APK + AAB (Android) + IPA (iOS), exécute `flutter analyze` et `flutter test`, upload symbols Crashlytics et release sur Play Internal + TestFlight,
**so that** chaque PR ait un feedback automatisé sur les 2 plateformes et que les release builds soient reproductibles.

#### Contexte technique

CLAUDE.md § Workflow Git : PR ≤ 400 lignes, conventional commits, pas de `--no-verify`. Le workflow doit refléter ces règles : check format, analyze, test, build sur les 2 plateformes.

**Secrets nécessaires** (à provisionner dans GitHub repo settings) :

- **Android**
  - `GOOGLE_SERVICES_JSON_BASE64` — pour restituer `mobile_app/android/app/google-services.json`
  - `ANDROID_KEYSTORE_BASE64` + `ANDROID_KEYSTORE_PASSWORD` + `ANDROID_KEY_ALIAS` + `ANDROID_KEY_PASSWORD` (release seulement)
  - `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` (upload Play Internal)
- **iOS**
  - `GOOGLE_SERVICE_INFO_PLIST_BASE64` — pour restituer `mobile_app/ios/Runner/GoogleService-Info.plist`
  - `APPLE_DEVELOPER_CERTIFICATE_P12_BASE64` + `APPLE_DEVELOPER_CERTIFICATE_PASSWORD`
  - `APPLE_PROVISIONING_PROFILE_BASE64`
  - `APPLE_API_KEY_ID` + `APPLE_API_ISSUER_ID` + `APPLE_API_PRIVATE_KEY` (App Store Connect API pour upload TestFlight)
- **Cross**
  - `FIREBASE_TOKEN` (pour Crashlytics symbols upload Android + iOS)

#### Acceptance Criteria

**AC1 — Workflow PR build Android**
**Given** `.github/workflows/pr-android.yml`
**When** un PR est ouvert
**Then** un job sur runner `ubuntu-latest` exécute (dans cet ordre) : checkout, setup Flutter, `flutter pub get`, `dart format --output=none --set-exit-if-changed .`, `flutter analyze`, `flutter test`, `flutter build apk --debug`
**And** le run échoue si une étape échoue

**AC2 — Workflow PR build iOS**
**Given** `.github/workflows/pr-ios.yml`
**When** un PR est ouvert
**Then** un job sur runner `macos-latest` exécute : checkout, setup Flutter, `flutter pub get`, `cd mobile_app/ios && pod install`, `flutter build ios --debug --no-codesign`
**And** le run échoue si une étape échoue
**And** le workflow utilise des conditions pour skip ce job si seuls des fichiers `android/` ou `doc/` ont changé (économie temps runner macOS qui est facturé 10× plus cher qu'Ubuntu)

**AC3 — Workflow release tag Android**
**Given** un push tag `v0.1.0-internal`
**When** le workflow `release-android.yml` se déclenche
**Then** il build `flutter build appbundle --release` + signe avec keystore stocké en secret, puis upload au Play Internal Track via Fastlane ou Google Play API
**And** upload Crashlytics symbols Android via `firebase crashlytics:symbols:upload --android-app-id=...`

**AC4 — Workflow release tag iOS**
**Given** le même push tag `v0.1.0-internal`
**When** le workflow `release-ios.yml` se déclenche (runner macOS)
**Then** il build `flutter build ipa --release --export-options-plist=...`, signe avec le certificat + provisioning profile en secret, puis upload à TestFlight via `xcrun altool` ou `fastlane pilot`
**And** upload Crashlytics dSYM iOS via `firebase crashlytics:symbols:upload --ios-app-id=...`

**AC5 — Lint custom imports interdits**
**Given** le workflow PR
**When** un fichier importe `package:logger/logger.dart` hors `lib/core/logging/` OU `package:flutter_smooth_markdown` hors `lib/core/widgets/pedagogical_content.dart`
**Then** un step de grep CI échoue avec un message explicite

**AC6 — Caching Flutter SDK + pub cache + Pods**
**Given** runs successifs
**When** on inspecte les durées
**Then** le 2ème PR build Android prend < 3 min (cache SDK + pub cache hit), le 2ème PR build iOS prend < 8 min (cache SDK + pub cache + Pods hit — iOS builds restent plus lents)
**And** le badge dans le README montre le statut des 2 workflows

#### Definition of Done

- [ ] Procédure secrets documentée dans `doc/tools/CONTRIBUTING.md`
- [ ] Badges Android + iOS ajoutés au `README.md` racine
- [ ] Premier run réussi sur les 2 plateformes
- [ ] Budget temps runner macOS surveillé (GitHub donne 2000 min/mois gratuit pour repo privé ; macOS coûte 10× plus) — alerte à 80 % d'usage configurée si possible
- [ ] PR ≤ 500 lignes diff (workflows iOS plus longs)
- [ ] Commit `chore(ci): GitHub Actions PR build Android et iOS + release tag`

#### Notes pour Amelia

- Utilise `subosito/flutter-action@v2` pour setup Flutter en CI.
- Le release au Play Internal Track peut être manuel en P0 si Fastlane prend trop de temps — documente le fallback manuel.
- Si Crashlytics symbols upload échoue, ne casse pas le build (warning seulement).

---

### Story 0.18 : Risk R1 — Évaluation parallèle agrégateurs MoMo (Tranzak / Campay / MyCoolPay)

**Statut** : Draft
**Sprint** : P0 (semaine 0, **J1 mandatory**)
**Dépendances** : aucune (peut démarrer J1)
**Estimation** : L (~3-5 jours étalés sur 2 semaines pour ouverture comptes)
**Risque** : R1 — bloquant pour E4 (P4)

**As a** product owner,
**I want** une évaluation comparée des 3 agrégateurs MoMo candidats avec un test end-to-end signed webhook sur chaque sandbox,
**so that** le choix d'agrégateur soit figé **avant le démarrage de P4** (semaine 4) et que l'ouverture du compte marchand ait commencé.

#### Contexte technique

ADR-007. Cf. CLAUDE.md § Points ouverts à connaître : « Stack admin / landing » + open question OQ-10 PRD = choix agrégateur. C'est le **risque R1** identifié dans `architecture.md` § 13.1 : l'ouverture compte marchand prend 2-4 semaines, **doit démarrer J1**.

Cette story produit un document de comparaison + une recommandation. Elle ne touche pas au code de l'app — c'est un livrable de research.

#### Acceptance Criteria

**AC1 — 3 comptes sandbox créés**
**Given** les 3 agrégateurs Tranzak, Campay, MyCoolPay
**When** la story commence
**Then** un compte sandbox est ouvert chez chaque (email projet partagé)
**And** documentation API obtenue pour les 3

**AC2 — Test webhook signé end-to-end**
**Given** un script de test simulé (Node, Python, peu importe)
**When** on exécute une transaction sandbox pour chaque agrégateur
**Then** le webhook arrive sur un endpoint local (ngrok ou équivalent), signature vérifiable côté serveur
**And** un screenshot ou log capture le succès

**AC3 — Document de comparaison**
**Given** les 3 tests faits
**When** on rédige `project_manage/planning-artifacts/research/aggregateurs-momo-comparaison.md`
**Then** le document compare sur 5 critères (cf. ADR-007) : webhook signé, couverture MoMo+OM, frais, support, délai compte marchand
**And** un tableau récap est fourni
**And** une recommandation argumentée pointe 1 agrégateur (+ fallback si refus)

**AC4 — Ouverture compte marchand lancée**
**Given** la recommandation
**When** la story termine
**Then** le dossier compte marchand est en cours auprès de l'agrégateur recommandé
**And** la timeline d'ouverture (~2-4 semaines) est notée dans le `.decision-log.md` projet

**AC5 — ADR mise à jour**
**Given** le choix arrêté
**When** la story est marquée done
**Then** ADR-007 est mise à jour : section « Décision » fixe l'agrégateur, statut passe à 🟢 Accepté (déjà l'est)
**And** OQ-10 du PRD est résolue (mise à jour du PRD)

#### Definition of Done

- [ ] Document de comparaison livré
- [ ] ADR-007 et PRD mis à jour
- [ ] Ouverture compte marchand engagée
- [ ] PR docs ≤ 400 lignes

#### Notes pour Amelia

- Cette story est probablement **non-dev** — peut être conduite par le PM (John) ou tech lead. Documente le delivery.
- Si l'un des agrégateurs n'a pas de sandbox ouvert au public, contacter le support — délai à intégrer.
- Ne perds pas plus de 3 jours sur cette story — il faut un choix « bon » pas « parfait ».

---

### Story 0.19 : Risk R2 — Tests précoces `flutter_smooth_markdown` sur 3 cours réels

**Statut** : Draft
**Sprint** : P0 (semaine 1, après Story 0.15)
**Dépendances** : Story 0.15
**Estimation** : M (~4-6h)
**Risque** : R2 — go/no-go avant E2

**As a** tech lead,
**I want** 3 cours réels BAC/Probatoire/GCE rendus via `PedagogicalContent` et un test de performance sur Android entrée de gamme,
**so that** ADR-009 § Tests précoces obligatoires soit accompli avant que E2 (Navigation contenu) ne démarre.

#### Contexte technique

ADR-009 § Tests précoces obligatoires énonce le test : 3 cours (maths, PCT, info ou SVT) doivent rendre correctement, avec performance < 2 s ouverture en cache sur Tecno Spark 8 class.

#### Acceptance Criteria

**AC1 — 3 cours préparés**
**Given** Markdown source à fournir par PO ou enseignant (ou rédaction maquette par l'équipe)
**When** la story commence
**Then** 3 fichiers `.md` existent dans `assets/dev/test_courses/`:
- `maths_derivees.md` (intégrales, sommes, vecteurs, ≥ 5 formules LaTeX)
- `pct_acide_base.md` (équations chimiques avec indices et exposants)
- `info_algo_recherche.md` (flowchart Mermaid + bloc de code)

**AC2 — Rendu visuel validé**
**Given** une route debug `/_test_courses` qui rend chaque cours via `PedagogicalContent`
**When** un dev/PO ouvre les 3 cours
**Then** chaque rendu est validé visuellement (screenshot annoté avec « OK / KO »)
**And** les KO sont signalés à l'éditeur du package (issue GitHub `flutter_smooth_markdown`)

**AC3 — Performance benchmark**
**Given** un build release installé sur Tecno Spark 8 ou équivalent
**When** on ouvre le cours `maths_derivees.md` (~3000 mots, 10 formules, 1 diagramme — adapter si besoin)
**Then** l'ouverture est < 2 s mesurée (Stopwatch dans le code de la route debug)
**And** le résultat est noté dans `project_manage/planning-artifacts/architecture/.decision-log.md`

**AC4 — Décision go/no-go**
**Given** les résultats
**When** la story termine
**Then** une décision « continuer » ou « basculer sur assemblage classique » est notée (cf. ADR-009)
**And** si « basculer », une story de fallback est créée pour la sprint E2

#### Definition of Done

- [ ] Screenshots des 3 cours rendus
- [ ] Benchmark documenté
- [ ] Décision dans `.decision-log.md`
- [ ] Commit `test(widgets): tests precoces PedagogicalContent sur 3 cours reels`

#### Notes pour Amelia

- Cherche les cours sur des sites éducatifs camerounais ou inventer des cours plausibles — peu importe la véracité pédagogique, ce qui compte c'est le mix Markdown + LaTeX + Mermaid.
- Si Mermaid casse, ne te bloque pas — note le KO et documente. C'est une donnée d'entrée pour la décision go/no-go.

---

### Story 0.20 : Risk R3 — Benchmark latence Firebase `europe-west1` depuis Cameroun

**Statut** : Draft
**Sprint** : P0 (semaine 1)
**Dépendances** : Story 0.6
**Estimation** : S (~2-3h)
**Risque** : R3 — décide la région backend finale

**As a** tech lead,
**I want** mesurer la latence Cold start + lecture Firestore + appel Cloud Function depuis Cameroun (Yaoundé ou Douala) sur Android entrée de gamme,
**so that** la région backend optimale soit arrêtée avant que E3+ ne déploie ses Cloud Functions.

#### Contexte technique

`architecture.md` § 13.1 R3. Hypothèse actuelle : `europe-west1` (Belgique) — proche du Cameroun en routing Internet sortant via les câbles ACE/WACS. À mesurer. Régions alternatives : `us-east1` (Virginia), `europe-west3` (Frankfurt).

#### Acceptance Criteria

**AC1 — Cloud Function `ping` déployée**
**Given** une simple Cloud Function `ping` qui retourne `{ now: timestamp, region: 'europe-west1' }`
**When** déployée
**Then** l'URL est accessible et appelable depuis l'app debug

**AC2 — Script de benchmark Flutter**
**Given** une route debug `/_benchmark`
**When** on tape sur un bouton « Run 10 calls »
**Then** 10 appels Function + 10 lectures Firestore sont exécutés en série
**And** les latences moyennes et 95p sont affichées

**AC3 — Run depuis Cameroun**
**Given** au moins 2 spots WiFi/4G distincts (Yaoundé centre-ville + un quartier connue connectivité moyenne)
**When** le benchmark tourne
**Then** les chiffres sont notés dans `project_manage/planning-artifacts/architecture/.decision-log.md` § Performance

**AC4 — Décision région**
**Given** les chiffres
**When** comparés à la cible NFR (raisonnable < 500ms cold, < 200ms warm)
**Then** une décision « rester europe-west1 » ou « migrer vers X » est notée
**And** si migration, une story de migration est créée pour P1

#### Definition of Done

- [ ] Benchmark documenté
- [ ] Décision dans `.decision-log.md`
- [ ] Commit `test(infra): benchmark latence europe-west1 depuis Cameroun`

#### Notes pour Amelia

- Le benchmark doit être conduit par quelqu'un physiquement au Cameroun — sinon VPN proxy (résultats moins fiables).
- Ne consacre pas plus d'une demi-journée à cette story — décision rapide.

---

### Story 0.21 : Page « Hello Valide » bilingue + smoke test E0 (sentinelle de sortie d'epic)

**Statut** : Draft
**Sprint** : P0 (semaine 1, en clôture E0)
**Dépendances** : Stories 0.3, 0.6, 0.7, 0.9, 0.10, 0.13, 0.14, 0.15, 0.16
**Estimation** : M (~4-5h)

**As a** tech lead,
**I want** une page « Hello Valide » qui rend en FR/EN un texte + une formule LaTeX + un schéma Mermaid via `PedagogicalContent`, écrit/lit dans `_smoketest/launch` Firestore et émet un log AppLogger,
**so that** la sortie de l'Epic 0 soit validée bout-en-bout (tous les composants foundation travaillent ensemble).

#### Contexte technique

C'est la **sentinelle E0** — le test d'intégration vivant qui valide que tout le bootstrap Epic 0 est fonctionnel ensemble. Si cette story passe, on entre confiant en E1.

#### Acceptance Criteria

**AC1 — Page bilingue rendue**
**Given** la route `/hello` (existante depuis Story 0.2, remplacée ici)
**When** l'utilisateur ouvre l'app
**Then** la page affiche :
- Titre `helloValide` (FR : « Bonjour Valide », EN : « Hello Valide »)
- Sélecteur langue FR/EN qui change la locale en runtime
- Un `PedagogicalContent` qui rend `# Bonjour\n\nVoici une intégrale : $\int_0^1 x^2 dx = \frac{1}{3}$\n\n` + un flowchart Mermaid simple
- Un bouton primaire « Continuer » (sans action V1)
- Un bouton secondaire « Annuler » (sans action V1)

**AC2 — Smoke test Firestore**
**Given** l'utilisateur lance l'app
**When** le `main()` boot termine
**Then** un `_smoketest/launch` document est écrit avec `{ ts: serverTimestamp(), buildVersion: kBuildVersion }`
**And** lu en retour pour vérification
**And** un `AppLogger.i('E0 smoke test: write+read OK in ${duration}ms')` confirme

**AC3 — Crashlytics actif et test crash**
**Given** une route debug `/_crash` (à retirer après validation)
**When** on tape un bouton
**Then** `throw Exception('E0 sentinel crash')` est levée
**And** une exception apparaît dans Crashlytics Console < 5 min

**AC4 — Déploiement Play Internal ET TestFlight**
**Given** un push tag `v0.1.0-internal`
**When** les workflows Story 0.17 release-android.yml + release-ios.yml tournent
**Then** un AAB est uploadé au **Play Internal Track** (Android) ET un IPA est uploadé à **TestFlight** (iOS)
**And** au moins un testeur autorisé peut installer et lancer l'app sans crash sur Android ET iOS

**AC5 — Sentinelle régression dans CI**
**Given** le workflow PR Story 0.17
**When** un PR modifie un fichier critique (theme, router, AppLogger, PedagogicalContent, Responsive)
**Then** un test widget de la page `/hello` est exécuté sur 3 tailles d'écran simulées (phone 375×812, tablet 1024×1366, +1 supplémentaire)
**And** ce test doit rester vert

**AC6 — Rendu responsive vérifié manuellement**
**Given** l'app lancée sur 4 cibles
**When** on inspecte le rendu de `/hello`
**Then** elle rend correctement sur :

- Android phone (Pixel 4a émulateur)
- Android tablet (Pixel Tablet émulateur ou device)
- iOS phone (iPhone SE 2020 simulateur)
- iOS tablet (iPad mini simulateur)

**And** sur tablette, le contenu reste centré max 600 dp (pas étalé) — cf. Story 0.12 AC5/AC6.

#### Definition of Done

- [ ] Page rendue manuellement vérifiée sur 4 cibles (screenshots dans PR)
- [ ] Tag `v0.1.0-internal` créé
- [ ] AAB uploadé Play Internal + IPA uploadé TestFlight
- [ ] Crash test validé sur Android ET iOS (cf. AC3)
- [ ] PR ≤ 250 lignes diff
- [ ] Commit `feat(app): page Hello Valide bilingue responsive sentinelle E0`

#### Notes pour Amelia

- C'est la story de clôture E0 — si quelque chose ne marche pas ici, c'est une story amont à reprendre.
- Garde `/hello` dans le code post-MVP, c'est une page de smoke test régression utile.
- La route `/_crash` doit être supprimée dès Story 0.21 mergée + test Crashlytics OK sur les 2 plateformes.
- Pour les screenshots, utilise `flutter_screenshots` ou les outils Xcode/Android Studio. Ne checke PAS les screenshots dans le repo — uploade-les dans la PR.

---

## Critère de sortie d'epic

L'Epic 0 est **fermé** quand :

1. Toutes les 21 stories ci-dessus sont marquées Done.
2. La sentinelle Story 0.21 est verte sur Play Internal Track.
3. Les 3 risques R1/R2/R3 ont une décision documentée dans le `.decision-log.md`.
4. Le `CONTRIBUTING.md` est à jour avec les procédures secrets / Firebase / déploiement.
5. Un compte rendu de fin de sprint E0 (`bmad-retrospective`) a été écrit.

## Risques et mitigations

| Risque | Story mitigation | Statut |
|---|---|---|
| **R1** Choix agrégateur MoMo bloque P4 | Story 0.18 — évaluation J1 + ouverture compte | Démarre J1 |
| **R2** Mainteneur unique `flutter_smooth_markdown` | Story 0.15 (isolation widget) + Story 0.19 (tests précoces) | Story 0.19 fin semaine 1 |
| **R3** Latence `europe-west1` depuis Cameroun | Story 0.20 — benchmark depuis Cameroun | Story 0.20 semaine 1 |
| **R4** Validation curriculum par enseignant camerounais | Pas en E0 — story dédiée en début E1 | Reporté E1 |

## Notes globales pour l'équipe

- **Toutes les stories E0 vont en parallèle dès que leurs dépendances sont vertes** — il n'y a pas de raison de séquentialiser plus que le graphe ne l'impose.
- **Story 0.18 (R1) est la plus risquée sur la timeline** car l'ouverture de compte marchand a un délai externe non maîtrisable.
- **La retrospective Epic 0** (`/bmad-retrospective`) est obligatoire avant de démarrer E1 — extraire les leçons et ajuster les estimations.
- Les stories pour E1-E6 seront générées **au début de chaque phase** via `/bmad-create-story`, en intégrant les apprentissages E0.
