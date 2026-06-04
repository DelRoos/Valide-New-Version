---
story_id: 0.6
title: Setup Firebase Android + iOS + Firebase AI Logic (Gemini)
epic: 0
phase: P0
status: in-progress
created: 2026-06-04
branch: feature/0.6-firebase-setup-phase-a
estimation: L++ (~12-14h total)
dependencies:
  - 0.2  # routing + DI
  - 0.3  # AppLogger (forward Crashlytics)
  - 0.4bis  # bootstrap iOS
sourceArtifacts:
  - project_manage/planning-artifacts/epics/epic-0-foundation.md § Story 0.6
  - project_manage/planning-artifacts/architecture/adrs/ADR-003-firebase-full-backend.md
  - project_manage/planning-artifacts/architecture/adrs/ADR-012-firebase-ai-logic-replace-claude.md
---

# Story 0.6 — Firebase Android + iOS + Firebase AI Logic

## Approche en 2 phases

Story 0.6 est trop lourde pour être livrée dans une seule passe agent — elle
demande des actions humaines sur la **Firebase Console** + **Xcode signing**
que personne ne peut déléguer à un agent. On livre en 2 phases :

### Phase A — Code & configs natives (cette PR)

**Acteur** : agent (Claude). **Estimation** : ~6h. **Branche** :
`feature/0.6-firebase-setup-phase-a`. **Mergeable seule** : oui, sans
casser l'app actuelle (l'init Firebase échoue proprement avec un
message d'erreur clair tant que Phase B n'est pas faite).

Contenu :

- Packages Firebase + `firebase_ai` ajoutés au `pubspec.yaml`
- `.gitignore` durci pour `google-services.json` + `GoogleService-Info.plist`
- Stub `lib/firebase_options.dart` qui lève `UnsupportedError` avec
  instructions claires pour Phase B
- `main.dart` : try/catch sur `Firebase.initializeApp` + Crashlytics
  conditionnel (skip si init échoue, log d'erreur clair)
- Providers Riverpod lazy pour : Auth, Firestore, Storage, Functions,
  Messaging, Remote Config, App Check, **Firebase AI Logic**
- Forward `AppLogger.e()` → `FirebaseCrashlytics.instance.recordError()`
  (conditionnel sur init OK)
- Routes debug `/_crash` (force exception) + `/_ai_smoke` (sync + streaming)
- `android/app/build.gradle.kts` : plugin `google-services` ajouté
- `ios/Podfile` : min iOS 13.0
- `ios/Runner/Info.plist` : permissions caméra + tracking (FR/EN)
- Tests unitaires des providers (mockables, n'init pas Firebase)

### Phase B — Setup Firebase Console + Xcode (PR future)

**Acteur** : porteur (Delano). **Estimation** : ~6h. **Branche** : à
définir, probablement `chore/0.6-firebase-config-files` ou directement sur
`main` puisque les configs ne touchent pas le code.

Contenu :

1. Créer projet Firebase `valide-school-mvp` (plan Blaze)
2. Activer modules : Auth (Email + Google + Apple), Firestore (Native,
   `europe-west1`), Storage (`europe-west1`), Cloud Functions
   (`europe-west1`), FCM, Crashlytics, Analytics, Remote Config, App
   Check (DeviceCheck iOS + Play Integrity Android), **AI Logic avec
   Gemini Developer API**.
3. Ajouter app Android (`com.valideStartup.valideSchool`) → télécharger
   `google-services.json` dans `mobile_app/android/app/`
4. Ajouter app iOS → télécharger `GoogleService-Info.plist` dans
   `mobile_app/ios/Runner/`
5. `cd mobile_app && flutterfire configure --project=valide-school-mvp
   --platforms=android,ios` (régénère `lib/firebase_options.dart` réel)
6. Xcode signing iOS : certificat développeur Apple, provisioning
   profile pour Bundle ID `com.valideStartup.valideSchool`
7. Smoke tests AC5 (`/_crash`) + AC6 (`/_ai_smoke`) sur émulateur
   Android + simulateur iOS + 1 device réel
8. **Commit `firebase_options.dart` réel** (les valeurs sont des
   identifiants publics OK) + secrets GitHub Actions pour les fichiers
   `.json` / `.plist` (CI Story 0.17).

## Acceptance Criteria (Phase A seule — voir Story 0.6 epic pour le tout)

| AC | Phase | Implémentation Phase A |
|---|---|---|
| AC1 — Projet Firebase + 2 apps | B | Stub + doc Phase B |
| AC2 — FlutterFire CLI | B | Stub `firebase_options.dart` avec instructions |
| AC3 — Init au démarrage | A partiel | try/catch + log si échec init ; vrai test = Phase B |
| AC4 — Lazy-load | A | Tous les modules en providers Riverpod, jamais importés dans `main.dart` |
| AC5 — Crashlytics testé | B | Route `/_crash` créée Phase A, smoke = Phase B |
| AC6 — Firebase AI Logic smoke | B | Route `/_ai_smoke` créée Phase A, smoke = Phase B |

## Definition of Done (Phase A)

- [x] Story file
- [ ] Packages Firebase + firebase_ai dans pubspec.yaml + pubspec.lock
- [ ] `.gitignore` : `google-services.json`, `GoogleService-Info.plist`, autres secrets
- [ ] Stub `firebase_options.dart` clair (lève `UnsupportedError` avec instructions)
- [ ] `main.dart` : try/catch Firebase init + setup Crashlytics conditionnel
- [ ] `lib/core/firebase/providers.dart` : providers lazy pour 8 modules
- [ ] `app_logger.dart` : forward `e()` vers Crashlytics si init OK
- [ ] Routes debug `/_crash` + `/_ai_smoke` (sync + streaming) ajoutées au router
- [ ] `android/app/build.gradle.kts` : plugin google-services
- [ ] `ios/Podfile` : `platform :ios, '13.0'`
- [ ] `ios/Runner/Info.plist` : permissions (`NSCameraUsageDescription` FR+EN)
- [ ] Tests : providers + Crashlytics forward (mockable)
- [ ] `flutter analyze` = 0 issue, `flutter test` = vert
- [ ] PR mergée — l'app continue de build mais affiche un toast d'erreur clair sur la sentinelle E0 jusqu'à Phase B

## Décisions de cadrage Phase A

| Sujet | Décision | Justification |
|---|---|---|
| `firebase_options.dart` réel | **Reporté Phase B** | Demande `flutterfire configure` (interactif, auth Google) — incompatible mode agent |
| Build APK debug fonctionnel | **Reporté Phase B** | Sans `google-services.json` valide, build échoue. Tant que pas merge Phase B, on désactive ce check en CI (Story 0.17) |
| Smoke tests AC5 / AC6 | **Reporté Phase B** | Sans Firebase initialisé, les smoke tests ne peuvent pas tourner |
| Init Firebase conditionnelle | **OUI** | L'app ne doit pas crasher si stub `firebase_options.dart` est utilisé — try/catch silencieux + log |
