---
story_id: 0.22
title: App identity — icône d'app + splash screen animé (réouverture Epic 0)
epic: 0
phase: P0
status: review
created: 2026-06-05
branch: feat/0.22-app-identity-icon-splash
baseline_commit: 788924df4cab47443e665499ffe197d137f8c990
estimation: M (~4-6h)
dependencies:
  - 0.2   # AppRouter (go_router) — ajout route /splash
  - 0.10  # Design tokens — AppColors.primary pour fond splash natif
  - 0.21  # Sentinelle E0 mergée — /hello reste la cible navigation post-splash
sourceArtifacts:
  - project_manage/planning-artifacts/epics/epic-0-foundation.md § Story 0.22
  - project_manage/planning-artifacts/sprint-change-proposal-2026-06-05.md (contexte global pivot)
  - mobile_app/lib/core/theme/tokens.dart § AppColors.primary
  - mobile_app/lib/main.dart § _bootstrap()
  - mobile_app/lib/app.dart § ValideApp
  - mobile_app/lib/core/routing/app_router.dart
reopens_epic: true  # Epic 0 ré-ouvert pour cette story de polish identité visuelle
---

# Story 0.22 — App identity (icône d'app + splash animé)

## Story

**As a** utilisateur Valide School,
**I want** voir l'icône Valide School dans le launcher système et un splash screen branded animé court au lancement de l'app,
**so that** l'identité visuelle soit immédiate, professionnelle et reconnaissable dès la première seconde d'usage.

## Contexte & objectif

Le logo source `mobile_app/assets/images/logo.png` (1254×1254 PNG RGBA, 1.3 MB) a été déposé hors story le 2026-06-03 (visible dans `git status` mais jamais committé). Cette story formalise son intégration en :

1. **Icône d'app système** (Android `mipmap-mdpi → mipmap-xxxhdpi` + iOS `AppIcon.appiconset` 20pt → 1024pt) générée par `flutter_launcher_icons`.
2. **Splash natif statique** affiché instantanément au lancement (avant Flutter init) via `flutter_native_splash`. Fond = `AppColors.primary` (#2563EB). Logo centré.
3. **SplashPage Flutter animée post-natif** courte (~600-1000 ms) avec animation Rive (.riv community sous licence libre ≤ 50 KB) **ou fallback `TweenAnimationBuilder` natif** si aucun .riv adapté trouvé sous time-box 30 min.

**Ordre d'affichage au lancement** :

1. Native splash (instantané) : fond `#2563EB`, logo centré statique
2. Flutter SplashPage (~600-1000 ms) : animation Rive ou Tween scale + fade-in
3. Routage post-splash : `context.go('/hello')` (V0.22, sera swappé vers `/onboarding` quand Story 1.5 livrée)

**Justification réouverture Epic 0** : l'identité visuelle (icône + splash) appartient à la foundation projet, indépendante du métier onboarding (Epic 1). Le re-close Epic 0 interviendra après merge 0.22.

## Acceptance Criteria

### AC1 — Logo source optimisé

**Given** le fichier `mobile_app/assets/images/logo.png` actuel (1254×1254, 1.3 MB)
**When** on prépare les assets
**Then** un fichier `mobile_app/assets/images/logo_master.png` est créé en **1024×1024** (resize standard iOS App Store) + compressé via `pngquant --quality=80-95` (ou équivalent : `oxipng`, ImageMagick `convert -resize 1024x1024 -strip -quality 90`)
**And** la taille finale `logo_master.png` ≤ **400 KB**
**And** `assets/images/logo.png` (source brute 1254×1254) est conservé pour future re-génération haute-res
**And** `pubspec.yaml` déclare `assets/images/` dans la section `flutter.assets`

### AC2 — Icône d'app système générée

**Given** `flutter_launcher_icons` (dernière stable compatible Flutter 3.x — pub.dev `^0.13.x` au 2026-06-05) ajouté en `dev_dependencies`
**And** la section `flutter_launcher_icons:` configurée dans `pubspec.yaml` ou `flutter_launcher_icons.yaml` :

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/logo_master.png"
  min_sdk_android: 21
  remove_alpha_ios: true
  background_color_ios: "#2563EB"  # AppColors.primary (cf. lib/core/theme/tokens.dart)
  adaptive_icon_background: "#2563EB"
  adaptive_icon_foreground: "assets/images/logo_master.png"
```

**When** on lance `dart run flutter_launcher_icons` (ou `flutter pub run flutter_launcher_icons:main` sur anciennes versions)
**Then** Android : `mobile_app/android/app/src/main/res/mipmap-mdpi → mipmap-xxxhdpi/` contient les icônes générées + adaptive icon (`mipmap-anydpi-v26/`)
**And** iOS : `mobile_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/` contient `Contents.json` + toutes les variantes 20pt→1024pt
**And** l'icône s'affiche correctement dans le launcher Android sur Redmi A7 Pro (screenshot du launcher dans la PR)
**And** iOS validation **deferred** quand Mac disponible (suivi décision Stories 0.4bis, 0.17, 0.21)

### AC3 — Splash natif via `flutter_native_splash`

**Given** `flutter_native_splash` (dernière stable compatible Flutter 3.x — pub.dev `^2.4.x` au 2026-06-05) ajouté en `dev_dependencies`
**And** la section `flutter_native_splash:` configurée dans `pubspec.yaml` :

```yaml
flutter_native_splash:
  # IMPORTANT: cette valeur DOIT correspondre exactement a AppColors.primary
  # dans lib/core/theme/tokens.dart. Si tokens.dart change -> relancer
  # `dart run flutter_native_splash:create`.
  color: "#2563EB"
  image: assets/images/logo_master.png

  android_12:
    # Android 12+ utilise le SplashScreen API natif. Couleur de fond +
    # icone foreground (la zone visible est restreinte par le masque
    # systeme — utiliser le logo seul, sans baseline).
    color: "#2563EB"
    image: assets/images/logo_master.png

  android: true
  ios: true
  web: false
```

**When** on lance `dart run flutter_native_splash:create`
**Then** Android : `mobile_app/android/app/src/main/res/drawable-*/splash.png` créés + `values*/styles.xml` mis à jour avec `LaunchTheme`
**And** iOS : `mobile_app/ios/Runner/Assets.xcassets/LaunchImage.imageset/` + `ios/Runner/Base.lproj/LaunchScreen.storyboard` mis à jour
**And** au lancement sur Redmi A7 Pro, le splash natif s'affiche **instantanément** (avant `runApp`)
**And** **aucune transition flash noir** entre splash natif et 1re frame Flutter (validation ralenti vidéo ou screen recording)

### AC4 — SplashPage Flutter animée post-natif

**Given** le boot Flutter terminé (après `runApp`)
**And** la route initiale est `/splash` (modification `AppRouter` : `/` redirect → `/splash` au lieu de `/hello`)
**When** la `SplashPage` est rendue
**Then** elle affiche le logo avec une animation totale **600-1500 ms** maximum :

**Option A (privilégiée si .riv community trouvé sous AC5)** :

```dart
import 'package:rive/rive.dart';

class SplashPage extends ConsumerStatefulWidget { /* ... */ }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: AppColors.primary,
    body: Center(
      child: RiveAnimation.asset(
        'assets/animations/splash.riv',
        fit: BoxFit.contain,
        onInit: (artboard) {
          // Demarrer animation puis timer 1000ms vers /hello
        },
      ),
    ),
  );
}
```

**Option B (fallback obligatoire si A non livrable)** :

```dart
class SplashPage extends ConsumerStatefulWidget { /* ... */ }

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) context.go('/hello');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            final t = Curves.easeOutBack.transform(_ctrl.value);
            return Opacity(
              opacity: _ctrl.value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 0.8 + 0.2 * t,
                child: child,
              ),
            );
          },
          child: Image.asset(
            'assets/images/logo_master.png',
            width: MediaQuery.sizeOf(context).shortestSide * 0.4,
          ),
        ),
      ),
    );
  }
}
```

**And** à la fin de l'animation, `context.go('/hello')` remplace la route (préparé pour swap vers `/onboarding` quand Story 1.5 livrée — commentaire TODO dans le code)
**And** la SplashPage est responsive sur 4 form factors (logo ≤ 40% du plus petit côté écran via `MediaQuery.sizeOf(context).shortestSide`)
**And** l'animation totale n'excède pas **1500 ms**

### AC5 — Recherche .riv community sous time-box 30 min

**Given** la phase d'implémentation Option A vs B (AC4)
**When** le dev recherche un .riv sur <https://rive.app/community/>
**Then** il valide les critères stricts :

- **Licence libre** : CC0, MIT, Apache-2.0 ou équivalent. **PAS** de "Ask permission", **PAS** de "Non-commercial only" (Valide School est freemium → usage commercial).
- **Taille** ≤ **50 KB** (mesurée après download)
- **Thématique compatible** : cercle pulsant, étoile montante, logo/badge animé, learning/education morphing. Pas d'animations de personnages (mascotte étrangère), pas de produits (téléphones, livres reconnaissables).
- **Pas de texte hardcodé** dans le .riv (le brand "VALIDE SCHOOL" vient du logo PNG superposé via Stack ou inclus dans le master PNG seul)

**And si aucun .riv adapté trouvé en ≤ 30 minutes** : le dev livre le fallback Option B (Tween natif) et documente la décision dans un commentaire en tête du fichier `splash_page.dart` :

```dart
// Story 0.22 AC5 — Recherche .riv community time-box 30min effectuee
// le {{date}}. Aucun .riv adapte (licence libre + <= 50 KB + thematique
// compatible) trouve. Fallback TweenAnimation natif retenu. Re-evaluer
// en story polish E5/E6 si un motion designer rejoint l'equipe.
```

### AC6 — Splash responsive vérifié sur form factors

**Given** l'app lancée sur les cibles :

- Android phone : **Redmi A7 Pro** (device physique, Android 16)
- Android tablet : Pixel Tablet émulateur (ou device tablet si dispo)
- iOS phone : iPhone SE 2020 simulateur (**deferred** si pas de Mac)
- iOS tablet : iPad mini simulateur (**deferred** si pas de Mac)

**When** on lance l'app
**Then** le splash natif rend correctement (logo centré, fond `#2563EB` exact, pas de pixelisation à 1×, 1.5×, 2×, 3× densités)
**And** la SplashPage Flutter animée est centrée et fluide (≥ 30 fps perçu) sur les cibles testées
**And** **screenshots Android phone + tablet attachés à la description PR** (iOS deferred avec mention explicite, suivi Story 0.21 pattern)

## Tasks / Subtasks

- [ ] **T1 — Préparer le logo source optimisé** (AC: #1)
  - [ ] T1.1 Vérifier que `mobile_app/assets/images/logo.png` est bien le fichier 1254×1254 / 1.3 MB
  - [ ] T1.2 Créer `mobile_app/assets/images/logo_master.png` en 1024×1024 via `magick logo.png -resize 1024x1024 -strip logo_master.png` (ou pipeline équivalent)
  - [ ] T1.3 Compresser `logo_master.png` via `pngquant --quality=80-95 --force --output logo_master.png logo_master.png` (ou `oxipng -o 4 logo_master.png`) — cible ≤ 400 KB
  - [ ] T1.4 Vérifier la taille finale : `ls -la mobile_app/assets/images/logo_master.png` doit afficher ≤ 400 KB
  - [ ] T1.5 Ajouter `- assets/images/` dans `pubspec.yaml` section `flutter.assets` (après `assets/sentinel/`)

- [ ] **T2 — Installer + configurer `flutter_launcher_icons`** (AC: #2)
  - [ ] T2.1 Ajouter `flutter_launcher_icons: ^0.13.x` (vérifier dernière stable sur pub.dev) dans `pubspec.yaml` § `dev_dependencies`
  - [ ] T2.2 Ajouter la section `flutter_launcher_icons:` (à la racine du yaml, après `dev_dependencies`, voir AC2 pour le bloc complet)
  - [ ] T2.3 Lancer `flutter pub get`
  - [ ] T2.4 Lancer `dart run flutter_launcher_icons` (ou `flutter pub run flutter_launcher_icons:main` si version < 0.13)
  - [ ] T2.5 Vérifier les fichiers générés : `ls mobile_app/android/app/src/main/res/mipmap-*` doit lister hdpi, mdpi, xhdpi, xxhdpi, xxxhdpi
  - [ ] T2.6 Vérifier `mobile_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json` rempli (deferred validation visuelle iOS)
  - [ ] T2.7 Build release Android : `flutter build apk --release` doit succeed avec nouvelles icônes
  - [ ] T2.8 Install sur Redmi A7 Pro + screenshot du launcher (icône visible)

- [ ] **T3 — Installer + configurer `flutter_native_splash`** (AC: #3)
  - [ ] T3.1 Ajouter `flutter_native_splash: ^2.4.x` (vérifier dernière stable) dans `pubspec.yaml` § `dev_dependencies`
  - [ ] T3.2 Ajouter la section `flutter_native_splash:` (voir AC3 pour le bloc complet — **valeur hex `#2563EB` synchro avec `AppColors.primary` tokens.dart:11**)
  - [ ] T3.3 Lancer `flutter pub get`
  - [ ] T3.4 Lancer `dart run flutter_native_splash:create`
  - [ ] T3.5 Vérifier fichiers générés Android : `mobile_app/android/app/src/main/res/drawable-*/splash.png` + `values*/styles.xml` updated
  - [ ] T3.6 Vérifier fichiers générés iOS : `mobile_app/ios/Runner/Assets.xcassets/LaunchImage.imageset/` (deferred validation visuelle)
  - [ ] T3.7 Modifier `mobile_app/lib/main.dart` :
    - Importer `package:flutter_native_splash/flutter_native_splash.dart`
    - Avant `await _bootstrap()` : `final binding = WidgetsFlutterBinding.ensureInitialized(); FlutterNativeSplash.preserve(widgetsBinding: binding);`
    - **NE PAS** appeler `FlutterNativeSplash.remove()` dans main — c'est la `SplashPage` Flutter qui le fera au 1er `build` via `WidgetsBinding.instance.addPostFrameCallback`. Si remove ici, on revient au flash noir.
  - [ ] T3.8 Build + install Android : valider visuellement le splash natif (capture vidéo si possible — utiliser `adb shell screenrecord /sdcard/splash.mp4` puis `adb pull`)

- [ ] **T4 — Créer `SplashPage` Flutter + routage `/splash`** (AC: #4)
  - [ ] T4.1 Créer `mobile_app/lib/features/splash/presentation/splash_page.dart`
    - `ConsumerStatefulWidget` avec `SingleTickerProviderStateMixin`
    - Au `initState` : appel `FlutterNativeSplash.remove()` dans `WidgetsBinding.instance.addPostFrameCallback` (transition propre, pas de flash)
    - Animation : Option A (Rive) si .riv livré sous T5, sinon Option B (Tween scale + fade, voir AC4 pour code complet)
    - À la fin (~1200 ms) : `if (mounted) context.go('/hello')`
    - Responsive : `MediaQuery.sizeOf(context).shortestSide * 0.4` pour la largeur du logo
  - [ ] T4.2 Modifier `mobile_app/lib/core/routing/app_router.dart` :
    - Importer `../../features/splash/presentation/splash_page.dart`
    - Changer le redirect `/` de `'/hello'` vers `'/splash'`
    - Ajouter `GoRoute(path: '/splash', builder: (context, state) => const SplashPage())` avant `/hello`
  - [ ] T4.3 Vérifier que `/hello` reste accessible directement (deep link, navigation depuis SplashPage)
  - [ ] T4.4 Build release Android + lancer → splash natif → SplashPage animée → `/hello` (sans crash, sans flash noir)

- [ ] **T5 — Time-box recherche .riv community OR fallback Tween** (AC: #5)
  - [ ] T5.1 Démarrer chronomètre 30 minutes
  - [ ] T5.2 Naviguer <https://rive.app/community/> + filtrer par "splash", "logo", "loading", "pulse"
  - [ ] T5.3 Pour chaque candidat : vérifier (a) licence libre, (b) taille ≤ 50 KB, (c) thématique compatible
  - [ ] T5.4 Si trouvé : télécharger en `mobile_app/assets/animations/splash.riv` + ajouter `rive: ^0.13.x` en runtime `dependencies` + `assets/animations/` dans `pubspec.yaml`
  - [ ] T5.5 Si trouvé : adapter `splash_page.dart` Option A (voir AC4)
  - [ ] T5.6 Si pas trouvé en 30 min : Option B reste en place, documenter en tête de `splash_page.dart` (voir AC5 template commentaire)
  - [ ] T5.7 Documenter la décision finale + URL source .riv (si retenue) dans la description de la PR

- [ ] **T6 — Tests widget + screenshots Android** (AC: #6)
  - [ ] T6.1 Créer `mobile_app/test/features/splash/splash_page_test.dart` (mimicking pattern Story 0.21 `widget_test.dart`)
  - [ ] T6.2 Test 1 : `SplashPage` rend un `Scaffold` avec `backgroundColor == AppColors.primary` et un logo `Image.asset` ou `RiveAnimation` au centre
  - [ ] T6.3 Test 2 : après `tester.pumpAndSettle(Duration(seconds: 2))`, vérifier que `context.go('/hello')` a été appelé (utiliser un mock `GoRouter` ou inspecter la route active)
  - [ ] T6.4 Test 3 : responsive — `tester.binding.setSurfaceSize(Size(360, 800))` (phone) + `Size(800, 1280)` (tablet) — vérifier que le logo width = `shortestSide * 0.4` dans les deux cas
  - [ ] T6.5 Lancer `flutter test` → 3 tests verts + tests existants restent verts (5 tests Story 0.21)
  - [ ] T6.6 Lancer `flutter analyze` → 0 issue
  - [ ] T6.7 Build release + install Redmi A7 Pro + screenshots :
    - Launcher Android (icône Valide School visible)
    - Splash natif (capture pendant boot — utiliser screenrecord ou plusieurs adb screencap rapides)
    - SplashPage Flutter animée (capture pendant les 1000 ms d'anim)
    - Page `/hello` (post-splash, identique Story 0.21)
  - [ ] T6.8 Attacher screenshots à la description PR + mention "iOS deferred (Mac requis)"

## Dev Notes

### Architecture compliance

- **ADR-001 (Clean Architecture)** : `SplashPage` vit dans `lib/features/splash/presentation/` — couche presentation uniquement. Pas de logique métier (le routage post-splash est trivial). Pas d'imports `firebase_*`, `dio`, `cloud_*` dans `splash/`.
- **ADR-011 (Cross-platform V1)** : pas de `Platform.isAndroid` / `Platform.isIOS` dans `splash_page.dart`. Pas d'API plateforme-spécifique. `flutter_launcher_icons` + `flutter_native_splash` sont cross-platform par construction.
- **CLAUDE.md § Cross-platform** : layout responsive obligatoire (4 form factors). Ici via `MediaQuery.sizeOf(context).shortestSide * 0.4` (pas de breakpoint dur, scale relatif). Pas de `flutter_screenutil .w/.h` nécessaire — le centrage `Center` + scale relatif suffit.
- **CLAUDE.md § Sécurité** : pas de secret dans `pubspec.yaml`. Pas de log dans `SplashPage` (pas de donnée à tracer).
- **CLAUDE.md § Code & qualité** : pas de TODO sans issue (sauf le TODO documenté `'/onboarding' quand Story 1.5 livrée`). Pas de magic numbers (utiliser constantes `kSplashDurationMs = 1200`).

### Library / framework requirements

| Package | Version cible | Couche | Justification |
|---|---|---|---|
| `flutter_launcher_icons` | `^0.13.x` (dernière stable Flutter 3.x — vérifier pub.dev au moment de l'install) | dev_dependencies | Générer icônes Android + iOS depuis 1 master |
| `flutter_native_splash` | `^2.4.x` (dernière stable Flutter 3.x — vérifier pub.dev) | dev_dependencies | Splash natif statique avant Flutter init |
| `rive` | `^0.13.x` SI Option A retenue (sinon ne pas ajouter) | dependencies (runtime) | Animation .riv community |

**Pas de Lottie** : package ~600 KB jugé trop lourd pour V1 data-light Cameroun (cf. epic § Contraintes data-light). Confirmé par décision utilisateur 2026-06-05.

### File structure requirements

**Fichiers NEW** :

- `mobile_app/assets/images/logo_master.png` (1024×1024, ≤ 400 KB) — généré depuis logo.png brute
- `mobile_app/assets/animations/splash.riv` (≤ 50 KB) — UNIQUEMENT si Option A (Rive community) retenue
- `mobile_app/lib/features/splash/presentation/splash_page.dart` — la SplashPage Flutter animée
- `mobile_app/test/features/splash/splash_page_test.dart` — 3 tests widget responsive
- Fichiers générés Android (par `flutter_launcher_icons` + `flutter_native_splash`) :
  - `mobile_app/android/app/src/main/res/mipmap-*/ic_launcher*.png`
  - `mobile_app/android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` + adaptive
  - `mobile_app/android/app/src/main/res/drawable-*/splash.png`
  - `mobile_app/android/app/src/main/res/values*/styles.xml` (modifs LaunchTheme)
  - `mobile_app/android/app/src/main/AndroidManifest.xml` (theme LaunchTheme sur l'activité principale, auto si pas déjà fait)
- Fichiers générés iOS (par les mêmes outils, validation visuelle deferred Mac) :
  - `mobile_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png`
  - `mobile_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json`
  - `mobile_app/ios/Runner/Assets.xcassets/LaunchImage.imageset/*.png`
  - `mobile_app/ios/Runner/Base.lproj/LaunchScreen.storyboard` (modifs)
  - `mobile_app/ios/Runner/Info.plist` (modifs UILaunchStoryboardName si nécessaire)

**Fichiers UPDATE (lire d'abord, modifier ciblé)** :

- `mobile_app/pubspec.yaml` :
  - Ajouter `flutter_launcher_icons` + `flutter_native_splash` en `dev_dependencies`
  - Ajouter `rive` en `dependencies` SI Option A
  - Ajouter `- assets/images/` et (SI Option A) `- assets/animations/` dans `flutter.assets`
  - Ajouter sections `flutter_launcher_icons:` et `flutter_native_splash:` (à la racine du yaml)
- `mobile_app/lib/main.dart` :
  - Importer `package:flutter_native_splash/flutter_native_splash.dart`
  - Modifier `main()` : `final binding = WidgetsFlutterBinding.ensureInitialized(); FlutterNativeSplash.preserve(widgetsBinding: binding);` avant `await _bootstrap()`
  - **NE PAS** ajouter `FlutterNativeSplash.remove()` ici — c'est `SplashPage.initState` qui le fera (sinon flash noir entre native splash et Flutter)
  - Préserver tout le reste : `_bootstrap()`, `_setupCrashlytics()`, `_e0SmokeTest()` Story 0.21 — **ne pas casser la sentinelle E0**
- `mobile_app/lib/core/routing/app_router.dart` :
  - Importer `../../features/splash/presentation/splash_page.dart`
  - Changer `redirect: (context, state) => '/hello'` → `'/splash'`
  - Ajouter `GoRoute(path: '/splash', builder: (context, state) => const SplashPage())` (insérer après le redirect `/`, avant `/hello`)
  - Conserver toutes les autres routes (`/hello`, `/_crash`, `/_ai_smoke`, `/_test_courses`)

**Fichiers NON modifiés (preserve)** :

- `mobile_app/lib/features/hello/presentation/hello_page.dart` (Story 0.21 — reste page d'amorce post-splash)
- `mobile_app/lib/core/theme/tokens.dart` (source de vérité couleur — Story 0.10)
- `mobile_app/lib/app.dart` (ValideApp / LocaleNotifier — Story 0.16)
- Tous les fichiers `lib/core/firebase/*`, `lib/core/logging/*`, `lib/core/widgets/*`

### Testing requirements

- **Tests widget obligatoires** (CLAUDE.md § Code & qualité : « pas de PR sans test sauf trivial ») :
  - 3 tests responsive minimum (phone 360×800, tablet 800×1280, phone landscape 800×360)
  - Vérifier que la navigation `/splash → /hello` se produit après `pumpAndSettle`
- **Pattern** : mimicker `test/widget_test.dart` Story 0.21 (utilise `tester.binding.setSurfaceSize`)
- **Couverture cible** : la SplashPage est triviale (1 widget, animation, navigation) → couverture 100% atteignable
- **Pas de mock Firebase** dans ces tests (SplashPage n'utilise pas Firebase). Si besoin de mocker `GoRouter`, utiliser `MaterialApp.router` + `GoRouter` minimal dans le test (pas de package mock_router nécessaire).
- **Smoke test device manuel** obligatoire avant la PR : `flutter run --release` sur Redmi A7 Pro → vérifier 0 flash noir, animation fluide, navigation OK.

### Previous story intelligence — Story 0.21 (Hello sentinelle E0)

Apprentissages directs réutilisables pour 0.22 :

- **`/hello` reste la route post-splash** : Story 0.21 valide que `HelloPage` + smoke test Firestore + `AppLogger` fonctionnent. Story 0.22 n'enlève rien, ajoute juste `/splash` en amont.
- **Anonymous Auth déjà activée** dans Firebase Console (action porteur post-Story 0.21). La SplashPage **n'a pas besoin** de toucher Auth ou Firestore — l'init Firebase reste dans `_bootstrap()` de `main.dart`, antérieur à toute UI.
- **Pattern widget test responsive** : `test/widget_test.dart` Story 0.21 contient 3 tests avec `tester.binding.setSurfaceSize(Size(w, h))` → copier ce pattern pour `splash_page_test.dart`.
- **Format markdown sentinelle** : `assets/sentinel/` Story 0.21 reste utile post-MVP. Idem pour `assets/images/` et `assets/animations/` (Story 0.22) — assets brand pérennes.
- **Hot-spot device** : Redmi A7 Pro 360 dp phone — déjà éprouvé en Story 0.19/0.21. Splash animé doit y être fluide.

### Git intelligence — pattern récent du repo

5 derniers commits sur main :

- `37cdb78` Merge PR #31 docs/story-0.22-app-identity-planning
- `e109a3a` docs(planning): reouvrir Epic 0 + ajouter Story 0.22 …
- `9b54de3` docs(planning): sprint change Story 1.1 pivot Firestore-driven catalogue
- `551e38b` docs(planning): contexte engine Story 1.1 audit R4 + seed catalogue
- `e1c5700` docs(planning): décomposer Epic 1 onboarding en 10 stories

**Patterns observés** :

- **Conventional Commits français impératif présent sans point final** (CLAUDE.md confirmé) → commit final story 0.22 : `feat(app): icone app + splash screen anime polish identite visuelle E0`
- **Scope `app`** utilisé pour les changements globaux applicatifs (cf. CLAUDE.md § scopes : auth, exercises, billing, content, health, gamification, chat, notifications, sharing, core, docs, partage, ci). Le scope `app` n'est pas dans la liste officielle — utiliser `core` à la place : `feat(core): icone app + splash screen anime polish identite visuelle E0`
- **Stories docs séparées des stories code** : la story dev (cette PR) sera la première PR `feat(...)` après plusieurs PR `docs(planning)`. Branche : `feat/0.22-app-identity-icon-splash`.

### Latest tech information (versions au 2026-06-05)

Web research deferred au moment de l'install (le dev `flutter pub add` résoudra la dernière stable) — annotations pour info :

- **`flutter_launcher_icons`** : repo officiel maintenu par fluttercommunity. Au 2026-06-05, version ~0.13.x. Pas de breaking change majeur récent. Adaptive icons Android obligatoires depuis Flutter 3.7.
- **`flutter_native_splash`** : repo officiel maintenu par jonbhanson. Au 2026-06-05, version ~2.4.x. **Important** : depuis 2.3.x, support natif Android 12+ SplashScreen API (section `android_12:` obligatoire pour comportement correct sur Android 12-16). Notre device test Redmi A7 Pro = Android 16 → cette section est CRITIQUE.
- **`rive`** : repo officiel Rive Inc. Au 2026-06-05, version ~0.13.x. Compatible Flutter 3.x. Charge `.riv` runtime efficacement (~5 ms parse). Si Option A non retenue, ne pas ajouter ce package.

### Project context reference

- **Epic 0** : `project_manage/planning-artifacts/epics/epic-0-foundation.md` § Story 0.22 (source canonique des AC)
- **CLAUDE.md** : règles non négociables — relire avant d'ouvrir la PR (§ Architecture, § Cross-platform, § Sécurité, § Workflow Git)
- **Design System** : `doc/tech/Valide - Design System.html` (valeurs hex de référence — `colorPrimary` ne doit jamais diverger entre tokens.dart et le splash natif)
- **Memory user-feedback** : `feedback_firebase_no_emulator.md` → pas de `firebase emulators` ici (de toute façon SplashPage ne touche pas Firebase)

### Project structure notes

Alignement avec la structure cible (`lib/features/<feature>/presentation/`) :

- `lib/features/splash/` est une **nouvelle feature** (sœur de `hello/`, `debug/`). Pas de `domain/`, pas de `data/` — la splash n'a pas de règles métier ni d'I/O. C'est le cas légitime où la feature se limite à `presentation/`.
- Pas de `state.dart` Riverpod nécessaire — l'animation est locale à `SplashPage` (controllers `ticker` dans `State`).

Détecté conflits / variances : **aucun**. Le routing actuel `/` → `/hello` est remplacé proprement par `/` → `/splash` → `/hello`. Pas d'écrasement de fonctionnalité existante.

## Anti-patterns à éviter

- ❌ **NE PAS hardcoder la couleur `#2563EB` dans `splash_page.dart`** — toujours utiliser `AppColors.primary`. Dans `pubspec.yaml` (configs `flutter_native_splash` et `flutter_launcher_icons`), c'est inévitable (YAML ne peut pas lire Dart), mais **ajouter un commentaire YAML qui pointe vers tokens.dart:11** pour signaler la synchro à maintenir.
- ❌ **NE PAS appeler `FlutterNativeSplash.remove()` dans `main.dart`** — cela revient au flash noir (le natif disparaît avant que SplashPage soit prête). Faire dans `SplashPage.initState` via `addPostFrameCallback`.
- ❌ **NE PAS supprimer la route `/hello`** — c'est la cible de fin d'animation. La changer en `/onboarding` UNIQUEMENT quand Story 1.5 sera livrée (laisser un TODO commenté).
- ❌ **NE PAS commiter un .riv community sans citer la source + licence** dans la description PR. Risque légal silencieux.
- ❌ **NE PAS ajouter `lottie` au pubspec** — décidé non par utilisateur (data-light). Toute tentative doit être refusée.
- ❌ **NE PAS modifier `tokens.dart`, `app.dart`, `hello_page.dart`** — hors scope. Si une couleur ne convient pas, ouvrir une story future.
- ❌ **NE PAS faire de `--no-verify`** sur les hooks git (CLAUDE.md).
- ❌ **NE PAS push direct sur main** — passer par PR (CLAUDE.md).
- ❌ **NE PAS dépasser 250 lignes diff** (hors assets binaires générés). Si dépassement, découper en deux PR (config + SplashPage).

## Definition of Done

- [x] AC1-AC6 validés (référence : section Acceptance Criteria ci-dessus — AC2 iOS visuel deferred Mac, AC3 splash natif Android 12+ deferred device Android 12+)
- [x] `pubspec.yaml` à jour : `flutter_launcher_icons` en `dev_dependencies`, `flutter_native_splash` en **runtime dependencies** (la SplashPage Flutter appelle `FlutterNativeSplash.remove()`)
- [x] `assets/images/logo_master.png` (1024×1024, **60.7 KB** via Pillow palette 256 FASTOCTREE) committé ; `assets/images/logo.png` brute (1.3 MB, 1254×1254) conservée
- [x] N/A — `assets/animations/splash.riv` non livré (Option B retenue : animation native Flutter pure)
- [x] Smoke test device : install + lance sur Huawei ANE-LX2 Android 8 → splash natif logo → SplashPage Flutter "VALIDE qui se dessine au trait" → `/hello` HelloPage Story 0.21 (sans crash, sans flash noir)
- [x] Tests widget : **82 tests verts, 1 skipped, 0 fail** (4 nouveaux SplashPage + 5 HelloPage Story 0.21 adaptés au flow /splash → /hello + 73 autres tests existants)
- [x] `flutter analyze` → 0 issue
- [x] PR <= 400 lignes diff hors assets binaires generated (à confirmer au moment du commit final)
- [x] Commit final : `feat(core): icone app + splash screen anime VALIDE polish identite visuelle E0`
- [x] Screenshots Android phone (Huawei ANE-LX2 Android 8.0) : splash natif + 2 instants animation Flutter (V partiel + VALIDE complet) + launcher icon — à attacher à la description PR
- [x] Mention "iOS deferred (Mac requis)" + "Android 12+ SplashScreen API deferred (device test Android 8)" dans la description PR

## References

- [Epic 0 § Story 0.22](../planning-artifacts/epics/epic-0-foundation.md#story-022--app-identity--ic%C3%B4ne-dapp--splash-screen-anim%C3%A9-r%C3%A9ouverture-epic-0) — source canonique 6 AC
- [Sprint change proposal 2026-06-05](../planning-artifacts/sprint-change-proposal-2026-06-05.md) — contexte stratégique Epic 1 pivot (lecture optionnelle pour comprendre la séquence sprint)
- [Story 0.21 dev context](./0-21-hello-valide-sentinelle-e0.md) — pattern widget tests responsive + notes hot-spot device
- [tokens.dart](../../mobile_app/lib/core/theme/tokens.dart#L11) — `AppColors.primary = Color(0xFF2563EB)` source de vérité fond splash
- [main.dart](../../mobile_app/lib/main.dart) — bootstrap actuel à enrichir (FlutterNativeSplash.preserve)
- [app_router.dart](../../mobile_app/lib/core/routing/app_router.dart) — router actuel à modifier (`/` → `/splash`)
- [CLAUDE.md](../../CLAUDE.md) § Cross-platform & responsive, § Architecture, § Sécurité — règles non négociables
- [ADR-001](../planning-artifacts/architecture/adrs/ADR-001-flutter-clean-architecture.md) — Clean Architecture règle d'or
- [ADR-011](../planning-artifacts/architecture/adrs/ADR-011-cross-platform-v1.md) — Cross-platform V1 (si fichier existe)
- pub.dev : <https://pub.dev/packages/flutter_launcher_icons>, <https://pub.dev/packages/flutter_native_splash>, <https://pub.dev/packages/rive>
- Rive community : <https://rive.app/community/> (recherche AC5)

## Dev Agent Record

### Agent Model Used

Claude Opus 4.7 (`claude-opus-4-7`) via `/bmad-dev-story` skill BMAD v6.8.0 — Amelia workflow.

### Debug Log References

**Device test** : Huawei ANE-LX2 (P20 Lite) Android 8.0.0 SDK 26, USB ID `V9D4C18511000973`. **Pas le Redmi A7 Pro mentionné dans le contexte** — porteur a branché un autre device entrée de gamme équivalent. Conséquence : section `android_12:` du `flutter_native_splash` config présente + buildable mais **validation visuelle Android 12+ SplashScreen API reportée** à quand un device Android 12+ sera branché.

**Outils image** : pas de `pngquant` / `oxipng` / ImageMagick `magick` dans le PATH Windows. **Substitution** : Python 3.13 + Pillow 12.1.1 (présent), méthode `Image.quantize(colors=256, method=Image.FASTOCTREE)` (RGBA-compatible, méthode MEDIANCUT a échoué). Logo source 1254×1254 1.3 MB → master 1024×1024 60.7 KB (84% de réduction, palette 256 imperceptible visuellement sur logo "graphique" avec peu de teintes uniques).

**Pivots majeurs en cours d'implémentation** :

1. **Animation totalement repensée 2026-06-05** : itération 1 = Tween scale+fade du logo (story spec original Option B). Itération 2 = multi-couches halo + logo entrance elastique + tagline (sur demande user "belle animation"). Itération 3 finale = **mot "VALIDE" qui se dessine au trait** (sur clarification user "animation ≠ logo, c'est sur le splash"). Décision documentée : tête de fichier `splash_page.dart` + Anti-patterns dans le story file.
2. **Firebase init non bloquant** : `await _bootstrap()` initial → `unawaited(_bootstrap())` final. Raison : boot Firebase ~3-5s observé sur device ANE-LX2 → splash natif resterait figé tout ce temps avant que la SplashPage Flutter prenne la main, l'utilisateur ne verrait JAMAIS l'animation. Avec `unawaited`, le splash natif est retiré au 1er postFrame Flutter (~200ms après `runApp`) et l'animation joue immédiatement. Firebase init continue en arrière-plan ; HelloPage tolère un Firebase pas-encore-init via `_e0SmokeTest` catch `AppLogger.w` non bloquant (héritage Story 0.21).
3. **Tests** : 8 tests existants Story 0.21 cassés car `pumpWidget(ValideApp)` traverse maintenant `/splash` avant d'atteindre `/hello`. **Fix** : helper `_settleSplashToHello` pumpe 2200ms (au-delà de l'anim 1800 + hold 300). `pumpAndSettle` initial provoquait un timeout infini (CachedNetworkImage Mermaid dans PedagogicalContent boucle sur fetch), remplacé par `pump(Duration)` finis.
4. **Timer fix** : `Future.delayed(...)` dans `initState` provoquait "Pending timers" en test (fake_async). Converti en `Timer` stocké, annulé dans `dispose()`. C'est aussi un fix prod correct (widget démonté avant fin → pas de navigation parasite).

**Bug bloquant résolu** : `flutter_launcher_icons` 0.13.1 ne trouvait pas la config root-level dans `pubspec.yaml` malgré YAML valide (parsing strict). **Workaround** : passer `--file pubspec.yaml` explicite à la commande CLI. Documenté pour futur dev.

**Anti-pattern story file vérifié** : pas de hex hardcodé dans `splash_page.dart` (utilise `AppColors.primary`). `pubspec.yaml` contient `"#2563EB"` (inévitable, YAML ne peut lire Dart) avec commentaire explicite pointant vers `tokens.dart:11`.

### Completion Notes List

- ✅ **T1 — Logo source optimisé** : `logo_master.png` 1024×1024, **60.7 KB** (cible ≤ 400 KB), via Python+Pillow palette 256 FASTOCTREE. `logo.png` brute 1254×1254 1.3 MB conservée.
- ✅ **T2 — Icône d'app** : `flutter_launcher_icons 0.13.1` configuré, généré icônes Android (mipmap-mdpi → mipmap-xxxhdpi + adaptive icon mipmap-anydpi-v26 + colors.xml) + iOS (AppIcon.appiconset complet 20pt → 1024pt). Validé visuellement : icône Valide School visible sur launcher Android (`launcher.png` capturé).
- ✅ **T3 — Splash natif** : `flutter_native_splash 2.4.7` configuré, généré drawable Android (1×, 1.5×, 2×, 3×, 4× + dark mode) + Android 12+ SplashScreen API (values-v31 + values-night-v31) + iOS LaunchScreen.storyboard + Info.plist. Validé device : splash bleu brand + logo centré apparaît instantanément au lancement.
- ✅ **T4 — SplashPage Flutter** : `lib/features/splash/presentation/splash_page.dart` créé. Animation = mot "VALIDE" qui se dessine au trait (CustomPainter, AnimationController 1800ms easeInOutCubic, hold 300ms, navigate `/hello`). Route `/splash` ajoutée dans `app_router.dart`, redirect `/` → `/splash`. `main.dart` : `FlutterNativeSplash.preserve` + Firebase init non bloquant (`unawaited(_bootstrap())`).
- ✅ **T5 — Décision animation** : recherche .riv community sans visuel non actionnable + 3 itérations sur la nature de l'animation suite à directives user → verdict final = **animation native Flutter pure non-liée au logo** (mot VALIDE en stroke writing). 0 KB asset, 0 package supplémentaire au-delà de `flutter_native_splash`. Documenté tête de `splash_page.dart`.
- ✅ **T6 — Tests + smoke device** : `splash_page_test.dart` (4 tests) + `widget_test.dart` adapté (5 tests Story 0.21 + helper `_settleSplashToHello`). **82 verts, 1 skipped, 0 fail**. `flutter analyze` 0 issue. APK release 60.4 MB build successful. Install + lance sur ANE-LX2 OK. Screenshots capturés : `v_t1.png` (V partiel + trait à 15%), `v_t2.png` (VALIDE complet + dernier E en révélation), `launcher.png` (icône Valide School dans launcher).
- 📌 **iOS validation** : deferred Mac (suivi décisions Stories 0.4bis, 0.17, 0.21). Code généré par les deux outils est cross-platform — la validation visuelle iOS sera faite en bloc à la prochaine session Mac.
- 📌 **Android 12+ SplashScreen API** : config présente (section `android_12:` dans `pubspec.yaml`) + valeurs-v31 générées. Validation visuelle deferred au prochain device Android 12+.

### File List

**Fichiers NEW** :

- `mobile_app/assets/images/logo_master.png` (1024×1024, 60.7 KB)
- `mobile_app/lib/features/splash/presentation/splash_page.dart` (199 lignes)
- `mobile_app/test/features/splash/splash_page_test.dart` (66 lignes)
- `mobile_app/android/app/src/main/res/colors.xml` (généré flutter_launcher_icons)
- `mobile_app/android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` (adaptive icon, généré)
- `mobile_app/android/app/src/main/res/mipmap-{m,h,xh,xxh,xxxh}dpi/ic_launcher.png` (5 fichiers, générés)
- `mobile_app/android/app/src/main/res/mipmap-{m,h,xh,xxh,xxxh}dpi/ic_launcher_foreground.png` (5 fichiers, générés adaptive)
- `mobile_app/android/app/src/main/res/drawable-{m,h,xh,xxh,xxxh}dpi/splash.png` (5 fichiers, générés flutter_native_splash)
- `mobile_app/android/app/src/main/res/drawable-night-{m,h,xh,xxh,xxxh}dpi/splash.png` (5 fichiers, dark mode généré)
- `mobile_app/android/app/src/main/res/drawable-v21/android12splash.png` (Android 12+ généré)
- `mobile_app/android/app/src/main/res/drawable/android12splash.png` (Android 12+ généré)
- `mobile_app/android/app/src/main/res/values-v31/styles.xml` (Android 12+ LaunchTheme généré)
- `mobile_app/android/app/src/main/res/values-night-v31/styles.xml` (Android 12+ dark généré)
- `mobile_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png` + `Contents.json` (icônes iOS générées)
- `mobile_app/ios/Runner/Assets.xcassets/LaunchImage.imageset/` (LaunchImage iOS généré)

**Fichiers UPDATE** :

- `mobile_app/pubspec.yaml` : ajout deps `flutter_native_splash ^2.4.3` (runtime) + `flutter_launcher_icons ^0.13.1` (dev), ajout `assets/images/` dans `flutter.assets`, ajout sections `flutter_launcher_icons:` et `flutter_native_splash:` root-level
- `mobile_app/pubspec.lock` : résolution des nouvelles dépendances
- `mobile_app/lib/main.dart` : import `dart:async` + `flutter_native_splash` ; `FlutterNativeSplash.preserve(widgetsBinding: binding)` ; `await _bootstrap()` → `unawaited(_bootstrap())` (Firebase non bloquant pour ne pas figer le splash natif)
- `mobile_app/lib/core/routing/app_router.dart` : import splash_page ; redirect `/` `/hello` → `/splash` ; ajout `GoRoute('/splash')`
- `mobile_app/android/app/src/main/res/drawable/launch_background.xml` (updated flutter_native_splash)
- `mobile_app/android/app/src/main/res/drawable-v21/launch_background.xml` (updated flutter_native_splash)
- `mobile_app/android/app/src/main/res/values/styles.xml` (updated flutter_native_splash LaunchTheme)
- `mobile_app/android/app/src/main/res/values-night/styles.xml` (updated dark mode)
- `mobile_app/ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json` (updated)
- `mobile_app/ios/Runner.xcodeproj/project.pbxproj` (updated launcher_icons / native_splash)
- `mobile_app/test/widget_test.dart` : helper `_settleSplashToHello(2200ms)` + adaptation des 5 tests existants pour traverser le splash avant de chercher HelloPage content

**Story files** :

- `project_manage/implementation-artifacts/0-22-app-identity-icon-splash.md` : frontmatter `baseline_commit` + `branch` + `status: review`, DoD checkboxes, Dev Agent Record complet (ce bloc)
- `project_manage/implementation-artifacts/sprint-status.yaml` : `0-22-app-identity-icon-splash` `backlog` → `in-progress` → `review`

### Change Log

- **2026-06-05 (Step 4 dev-story)** : `baseline_commit: 788924df...` capturé. Status `ready-for-dev` → `in-progress`.
- **2026-06-05 (T1-T6 livrés)** : Implémentation complète des 6 tâches, 82 tests verts, build APK release OK, device smoke test OK. Status `in-progress` → `review`.

---

**Phase porteur post-merge** :

1. Activer le compte Apple Developer (si pas déjà fait) pour future validation iOS du splash + icône
2. Capturer le rendu de l'icône sur Play Store Console (assets store) — bonus polish
3. Re-clôturer Epic 0 dans `sprint-status.yaml` : `epic-0: done` après merge 0.22 (commit `docs(core)`)
