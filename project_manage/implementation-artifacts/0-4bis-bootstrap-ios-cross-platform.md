---
story_id: 0.4bis
title: Bootstrap iOS + squelette responsive
epic: 0
phase: P0
status: in-progress
created: 2026-06-04
branch: feature/create_ios_platform
estimation: M (~4-5h)
dependencies:
  - 0.4
sourceArtifacts:
  - project_manage/planning-artifacts/epics/epic-0-foundation.md § Story 0.4bis
  - project_manage/planning-artifacts/architecture/adrs/ADR-011-cross-platform-v1-android-ios-tablet.md
  - CLAUDE.md § Cross-platform & responsive
---

# Story 0.4bis — Bootstrap iOS + squelette responsive

## Objectif

Générer le squelette iOS du projet existant (`flutter create -t app --platforms=ios .`), figer Bundle ID et min iOS, et vérifier que le code Stories 0.1-0.3 fonctionne sur iOS sans modification — pour débloquer Story 0.6 (Firebase Android + iOS).

## Contexte

Story 0.1 a été faite avec `flutter create --platforms=android`. Il n'y avait pas de dossier `mobile_app/ios/`. Cette story le génère sur Mac (`feature/create_ios_platform`).

**Décisions figées (ADR-011)** :

- **Bundle ID** : `com.valideStartup.valideSchool` (aligné applicationId Android)
- **Min iOS** : 13.0 (couvre 95 %+ du parc)
- **CFBundleDisplayName** : `Valide School`

## Acceptance Criteria

### AC1 — Squelette iOS généré
- **Status** : ✅ Done
- **Given** `mobile_app/` actuel (sans dossier `ios/`)
- **When** on exécute `flutter create -t app --platforms=ios --org com.valideStartup --project-name valide_school .`
- **Then** un dossier `mobile_app/ios/` est créé avec `Runner.xcodeproj`, `Runner/`, `Podfile`, `Flutter/`
- **And** aucun fichier existant n'est écrasé
- **Vérifié dans le commit** : 42 fichiers / ~1210 lignes ajoutées (squelette Xcode standard).

### AC2 — Bundle ID et min iOS figés
- **Status** : ✅ Done
- **Given** `ios/Runner.xcodeproj/project.pbxproj`
- **When** on l'inspecte
- **Then** `PRODUCT_BUNDLE_IDENTIFIER = com.valideStartup.valideSchool` ✅
- **And** `IPHONEOS_DEPLOYMENT_TARGET = 13.0` ✅
- **And** `Info.plist` : `CFBundleDisplayName = Valide School` ✅

### AC3 — Pods installés
- **Status** : ⏳ À vérifier sur Mac
- **Given** `mobile_app/ios/`
- **When** on exécute `pod install`
- **Then** la commande réussit sans erreur
- **And** `Podfile.lock` est généré et committé
- **And** `ios/Pods/` est créé (ignoré par `.gitignore`)

### AC4 — Build iOS debug réussit
- **Status** : ⏳ À vérifier sur Mac
- **Given** un simulateur iOS lancé (iPhone SE 2020 minimum)
- **When** on exécute `flutter build ios --debug --no-codesign` puis `flutter run -d <ios-sim>`
- **Then** l'app se lance et affiche la page `/hello` avec « Hello Valide »
- **And** aucun crash au démarrage
- **And** `flutter test` reste vert

### AC5 — Audit code existant cross-platform
- **Status** : ⏳ À vérifier
- **Given** les fichiers Dart livrés Stories 0.1-0.4
- **When** on grep `dart:io`, `Platform.is`, `import 'package:flutter/cupertino.dart'`
- **Then** **aucun usage** n'est trouvé hors du futur `lib/core/platform/`
- **And** AppLogger, Failure, Either fonctionnent identiquement sur iOS

### AC6 — `.gitignore` iOS
- **Status** : ✅ Done
- **Given** `mobile_app/.gitignore` et `mobile_app/ios/.gitignore`
- **When** on inspecte les patterns
- **Then** sont ignorés : `ios/Pods/`, `ios/.symlinks/`, `ios/Flutter/Flutter.framework/`, `**/*.xcuserdata/`, futur `ios/Runner/GoogleService-Info.plist` (anticipation Story 0.6)
- **And** sont committés : `Podfile` (et `Podfile.lock` après AC3), `Runner.xcodeproj/`, `Runner.xcworkspace/`, `Info.plist`

## Vérifications à faire sur Mac

```bash
cd ~/projets/Valide/mobile_app/ios

# AC3 : pod install + commit Podfile.lock
pod install
cd ..
git add ios/Podfile.lock
git commit -m "chore(ios): committer Podfile.lock"

# AC4 : build + run iOS sim
flutter build ios --debug --no-codesign
# (lancer un simulateur depuis Xcode Window → Devices and Simulators)
flutter run -d <ios-sim-id>  # ou flutter run et choisir l'iOS

# AC5 : audit cross-platform (devrait retourner 0 résultat hors squelette)
grep -rn --include='*.dart' "dart:io" lib/
grep -rn --include='*.dart' "Platform\.is" lib/
grep -rn --include='*.dart' "package:flutter/cupertino" lib/

# Tests (doivent rester verts)
flutter analyze
flutter test
```

## Definition of Done

- [x] AC1 — Squelette généré (vérifié commit `802bbd9`)
- [x] AC2 — Bundle ID + min iOS figés (vérifié)
- [ ] AC3 — `pod install` + `Podfile.lock` committé
- [ ] AC4 — Build iOS debug + run simulateur réussissent
- [ ] AC5 — Grep `dart:io` / `Platform.is` retourne 0 hors `core/platform/`
- [x] AC6 — `.gitignore` iOS en place
- [ ] PR ≤ 300 lignes diff (déjà ~1210 lignes du squelette ; exception assumée car boilerplate Xcode)
- [ ] PR titre conventionnel : `feat(core): bootstrap squelette iOS et verification cross-platform`
- [ ] `sprint-status.yaml` : `0-4bis-bootstrap-ios-cross-platform: done` après merge

## Notes

- Cette story dépend du **merge prealable** des deux PRs en cours :
  - PR Story 0.4 (`feature/0.4-failure-either`)
  - PR scope cross-platform (`chore/scope-cross-platform-tablet-v1`)
- La branche `feature/create_ios_platform` part de `c2a3594` (commit scope cross-platform). Donc l'ordre de merge final : 0.4 → scope → iOS.
- **Pas de Firebase ici** — Story 0.6 s'en occupe.
- **Pas de signing release** — `--no-codesign` est OK pour debug. Story 0.17 traite signing CI.
- **Capabilities Xcode** (Push Notifications, Background Modes) : à ne PAS activer ici — Story 0.6.
- **Squelette = boilerplate Xcode** : la taille de PR > 400 lignes est inévitable et acceptée pour cette story spécifique. À noter dans le titre de PR.
