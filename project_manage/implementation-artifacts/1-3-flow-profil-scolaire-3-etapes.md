---
story_id: 1.3
title: Flow profil scolaire 3 étapes (Filière → Niveau → Série) + écran récap + création doc users
epic: 1
phase: P1
status: ready-for-dev
created: 2026-06-06
branch: feat/1.3-flow-profil-scolaire-3-etapes
baseline_commit: 3ccfd28  # merge commit Story 1.2 (PR #42)
estimation: L (~6-8h — la plus grosse story d'Epic 1)
dependencies:
  - 1.1c  # CatalogueRepository Firestore (watchX streams + derive() Either<CatalogueFailure, DerivedProfile>)
  - 1.2   # SubSystem fixé en SharedPreferences + subSystemNotifierProvider (synchrone, déjà au boot)
  - 0.6   # Firebase Auth + Firestore providers (firebaseAuthProvider + firestoreProvider)
  - 0.7   # Cache offline Firestore 40MB activé
  - 0.9   # Règles Firestore users/{uid} (Story 1.3 les ÉTEND : immutabilité subSystem/language/createdAt)
  - 0.13  # AppButton + AppCard + AppPillTabs + AppProgressBar
  - 0.14  # AppToast (toast non bloquant erreur Firestore)
blocks:
  - 1.4   # Retrait conditionnel matières (consomme `users/{uid}.derivedSubjects` + écran récap où le lien apparaît)
  - 1.5   # Garde navigation profil-incomplet (étend le redirect global avec ProfileCompletionState)
  - 1.6   # Compte Google/Apple (linkWithCredential nécessite users/{uid} créé en 1.3)
  - 1.7   # Liaison école (édite users/{uid}.schoolId)
  - 1.9   # Dashboard skeleton (lit users/{uid}.derivedSubjects + users/{uid}.examTargets)
sourceArtifacts:
  - project_manage/planning-artifacts/epics/epic-1-onboarding.md § Story 1.3 (lignes 429-562)
  - project_manage/planning-artifacts/prds/prd-valide-mvp-2026-06-03/prd.md § FR-2 (ligne 122) + § FR-4 (ligne 143)
  - project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/EXPERIENCE.md ligne 437-450 (Flow 1 étapes 3-6)
  - project_manage/planning-artifacts/architecture/adrs/ADR-006-subsystem-fixed-at-signup.md (subSystem + language immutables serveur)
  - project_manage/planning-artifacts/architecture/adrs/ADR-015-catalogue-firestore-runtime-activation.md (dérivation côté client V1)
  - doc/partage/BASE-DE-DONNEES.md § users/{uid} (lignes 57-90 — schéma TypeScript autoritatif)
  - doc/partage/ALGORITHMES.md § 1 (lignes 39-90 — dérivation profil + cas pas de match + retrait conditionnel)
  - doc/partage/DONNEES-REFERENCE.md § Tableau de dérivation (69 derivation_rules seedées sur valide-edu via Story 1.1b)
  - mobile_app/lib/core/catalogue/domain/catalogue_repository.dart (interface watchX + derive + hasNonEmptyCatalogue)
  - mobile_app/lib/core/catalogue/data/catalogue_repository_firestore_impl.dart (implémentation avec filtres isActive + orderBy sortOrder)
  - mobile_app/lib/core/catalogue/providers.dart (catalogueRepositoryProvider + catalogueProvider)
  - mobile_app/lib/core/catalogue/domain/models.dart (Filiere/Niveau/Serie/Subject/ExamTarget/DerivationRule/DerivedProfile)
  - mobile_app/lib/features/onboarding/providers.dart (subSystemNotifierProvider DÉJÀ EN PLACE — Story 1.2 — synchrone)
  - mobile_app/lib/features/onboarding/domain/sub_system.dart (enum SubSystem.francophone/anglophone)
  - mobile_app/lib/features/onboarding/presentation/subsystem_choice_page.dart (pattern Story 1.2 — ConsumerStatefulWidget + AppModal + context.go)
  - mobile_app/lib/core/routing/app_router.dart (router + redirect — Story 1.3 ajoute 4 routes onboarding/profile/*)
  - mobile_app/lib/core/firebase/providers.dart (firebaseAuthProvider + firestoreProvider + firebaseAvailableProvider)
  - mobile_app/lib/core/error/failures.dart (Failure abstract — CatalogueFailure héritage déjà OK Story 1.1c)
  - mobile_app/lib/core/widgets/app_card.dart (signature AppCard(child, onTap, padding))
  - mobile_app/lib/core/widgets/app_pill_tabs.dart (AppPillTabs(labels, selectedIndex, onTabSelected))
  - mobile_app/lib/core/widgets/app_progress_bar.dart (AppProgressBar(value, label))
  - mobile_app/lib/core/widgets/app_button.dart (AppButton.primary + .secondary avec loading prop)
  - firestore.rules (racine — bloc users/{uid} actuel Story 0.9 à étendre)
  - test/rules/users.test.mjs (6 tests rules Story 0.9 existants — Story 1.3 ajoute 2-3 cas)
---

# Story 1.3 — Flow profil scolaire 3 étapes + écran récap + création doc users

Status: **ready-for-dev**

## Objectif

Livrer **le cœur de l'onboarding** : guider l'élève à travers les 3 étapes du profil scolaire (Filière → Niveau → Série) avec progression visible, puis afficher un récap des matières dérivées + examen visé, et créer son document `users/{uid}` Firestore à la confirmation.

C'est la story qui transforme une session anonyme + sous-système en un **profil pédagogique complet** consommable par toute la suite (dashboard 1.9, retrait matières 1.4, compte Google 1.6, liaison école 1.7).

**5 pages livrées** : `FiliereChoicePage`, `NiveauChoicePage`, `SerieChoicePage`, `ProfileRecapPage` + state machine `OnboardingFlowState`.

**Pourquoi** : FR-2 + EXPERIENCE.md Flow 1 étapes 3-6. Sans Story 1.3, l'app reste sur `/hello` (sentinelle E0) post-1.2 — aucune valeur métier. Story 1.3 est **le seuil de viabilité** d'Epic 1.

**Critère de fin** : Fatou (francophone) peut compléter le flow en < 60 s sur Android Pixel 4a et obtenir un doc `users/{uid}` Firestore avec `derivedSubjects = [francophone_math, francophone_pct, francophone_svt, francophone_fr, francophone_en, francophone_lv2, francophone_philo, francophone_hg, francophone_eps]` + `examTargets = [exam_bac_francophone_d]`. James (anglophone Upper Sixth S2) obtient `[anglophone_chemistry, anglophone_physics, anglophone_biology]` + `[exam_gce_a_level_anglophone_s2]`. La règle Firestore rejette toute modif ultérieure de `subSystem`, `language`, `createdAt`.

## Story

**As a** élève qui a choisi son sous-système (Story 1.2),
**I want** remplir mon profil scolaire en 3 étapes guidées (filière → niveau → série) avec une progression visible, et voir mes matières dérivées + examen visé affichés clairement à la fin,
**so that** je sache immédiatement quels cours sont préparés pour moi sans avoir à cocher chaque matière individuellement (FR-2).

## Acceptance Criteria

### AC1 — State machine `OnboardingFlowState` + `Notifier`

**Given** un sous-système choisi en Story 1.2 (`subSystemNotifierProvider` non-null)
**When** l'utilisateur entre dans le flow profil
**Then** un `onboardingFlowProvider` Riverpod tient l'état :

```dart
@immutable
class OnboardingFlowState {
  const OnboardingFlowState({this.filiereId, this.niveauId, this.serieId});
  final String? filiereId;   // ref filieres/{id}
  final String? niveauId;    // ref niveaux/{id}
  final String? serieId;     // ref series/{id} OU null si niveau sans série (6ᵉ, Form 1)

  OnboardingFlowStep get currentStep {
    if (filiereId == null) return OnboardingFlowStep.filiere;
    if (niveauId == null) return OnboardingFlowStep.niveau;
    if (serieId == null) return OnboardingFlowStep.serie;
    return OnboardingFlowStep.recap;
  }

  /// Profil complet (sérialisable vers Firestore).
  bool get isComplete => filiereId != null && niveauId != null;
  // Note : serieId peut être null pour les niveaux sans série (6ᵉ francophone, Form 1-4 anglophone)

  OnboardingFlowState copyWith({String? filiereId, String? niveauId, String? serieId}) { ... }
  OnboardingFlowState resetFrom(OnboardingFlowStep step) { ... }
}

enum OnboardingFlowStep { filiere, niveau, serie, recap }
```

**And** un `Notifier<OnboardingFlowState>` expose :
- `selectFiliere(String id)` — pose filiereId, reset niveau + serie
- `selectNiveau(String id)` — pose niveauId, reset serie
- `selectSerie(String? id)` — pose serieId (null possible si niveau sans série)
- `backTo(OnboardingFlowStep step)` — reset les champs après `step`

**And** un test unitaire vérifie :
- État initial : tous null
- Après `selectFiliere('generale')` → currentStep == niveau
- Après `selectNiveau('francophone_terminale')` → currentStep == serie
- Après `selectSerie('francophone_terminale_d')` → currentStep == recap
- `backTo(filiere)` reset niveau + serie
- `selectFiliere` après avoir choisi niveau → niveau + serie sont reset (évite incohérence)

### AC2 — Étape 1/3 : `FiliereChoicePage` (`/onboarding/profile/filiere`)

**Given** route `/onboarding/profile/filiere`
**When** la page se rend
**Then** :
- Header : `AppProgressBar(value: 1/3)` + label « Étape 1 sur 3 » (i18n FR/EN)
- Titre H2 : « Choisis ta filière » (i18n)
- **2 `AppCard` cliquables** côte à côte (responsive : empilées en phone portrait, côte à côte en tablet) :
  - « Générale » avec icône `LucideIcons.graduationCap`
  - « Technique » avec icône `LucideIcons.wrench`
- Les 2 filières sont lues via `catalogueRepository.watchFilieres()` (Story 1.1c) — filtrées `isActive == true` automatiquement
- **Loading state** : skeleton/spinner pendant le premier load (~200-800 ms en 3G, cache offline après)
- **Empty state** : si stream retourne `[]` (catalogue vide), redirect vers `/catalogue-waiting` (logique existante Story 1.1c — déjà gérée par le router redirect global)

**And** au tap d'une carte, `onboardingFlowProvider.notifier.selectFiliere(filiereId)` est appelé puis `context.go('/onboarding/profile/niveau')`.

**And** un bouton retour Android/iOS navigue vers `/hello` (l'utilisateur peut quitter le flow temporairement — Story 1.5 gérera la garde de re-navigation). Pour V1 : `context.go('/hello')` au `WillPopScope` ou route racine du flow.

### AC3 — Étape 2/3 : `NiveauChoicePage` (`/onboarding/profile/niveau`)

**Given** filière choisie (state contient `filiereId`)
**When** route `/onboarding/profile/niveau` ouverte
**Then** :
- Header : `AppProgressBar(value: 2/3)` + label « Étape 2 sur 3 »
- Titre H2 : « Choisis ton niveau » (i18n)
- **Liste verticale scrollable** (`ListView.separated` ou `Column` selon hauteur) des niveaux filtrés via `catalogueRepository.watchNiveaux(subSystem, filiereId)` (Story 1.1c) :
  - Francophone général : `[francophone_6e, francophone_5e, francophone_4e, francophone_3e, francophone_seconde, francophone_premiere, francophone_terminale]`
  - Francophone technique : `[francophone_premiere, francophone_terminale]` (Seconde technique pas modélisée — décision Story 1.1b)
  - Anglophone général : `[anglophone_form_1, …, anglophone_form_5, anglophone_lower_sixth, anglophone_upper_sixth]`
- Chaque niveau est un `AppCard` cliquable avec `name.fr` ou `name.en` selon `subSystem` (cf. CatalogueRepository `Niveau` model)
- Loading + empty states identiques AC2

**And** au tap, `selectNiveau(niveauId)` puis :
- Si le niveau a au moins une série (cf. liste séries vide ou non) : `context.go('/onboarding/profile/serie')`
- Si **pas de série applicable** (6ᵉ→3ᵉ francophone, Form 1-4 anglophone) : skip cette étape avec `selectSerie(null)` puis `context.go('/onboarding/profile/recap')`

**Détection « pas de série »** : lire `catalogueRepository.watchSeries(subSystem, niveauId, filiereId)` et vérifier si vide. Implémentation : `.first` du stream avec timeout 2 s, fallback skip si vide. Pattern simple, pas de pré-fetch dans state machine.

**And** bouton retour : `backTo(filiere)` + `context.go('/onboarding/profile/filiere')`.

### AC4 — Étape 3/3 : `SerieChoicePage` (`/onboarding/profile/serie`)

**Given** niveau choisi (state contient `niveauId`) ET le niveau a des séries (sinon AC3 a déjà skip)
**When** route `/onboarding/profile/serie` ouverte
**Then** :
- Header : `AppProgressBar(value: 3/3)` + label « Étape 3 sur 3 »
- Titre H2 : « Choisis ta série » (i18n)
- Subtitle adaptée selon nombre de séries (ex. Tle générale FR : « A, C ou D ? » ; Upper Sixth EN : « Choisis ta combinaison Sciences ou Arts »)
- **Choix séries** :
  - Si ≤ 5 séries : `AppPillTabs(labels, selectedIndex, onTabSelected)` (cf. composant existant Story 0.13)
  - Si > 5 séries (Upper Sixth EN : 13 séries S1-S8 + A1-A5) : `GridView.count` 3-4 colonnes avec des `AppCard` carrés cliquables
- Séries lues via `catalogueRepository.watchSeries(subSystem, niveauId, filiereId)`
- Loading + empty states identiques AC2

**And** au tap, `selectSerie(serieId)` puis `context.go('/onboarding/profile/recap')`.

**And** bouton retour : `backTo(niveau)` + `context.go('/onboarding/profile/niveau')`.

### AC5 — Écran récap matières + examen visé (`/onboarding/profile/recap`)

**Given** profil complet `(subSystem, filiereId, niveauId, serieId?)`
**When** `ProfileRecapPage` se charge
**Then** :
- Appel `catalogueRepository.derive(subSystem, filiereId, niveauId, serieId?)` qui retourne `Future<Either<CatalogueFailure, DerivedProfile>>`
- État loading : skeleton GridView 3x3 + spinner inline
- État succès `Right(DerivedProfile)` :
  - **Bandeau en haut** : « Tu prépares le {examTargets[0].name.fr} » (FR) ou « You're preparing {examTargets[0].name.en} » (EN). Si plusieurs exam_targets, lister séparés par virgule (rare cas). Si liste vide (ex. 6ᵉ francophone sans examen), afficher « Pas d'examen visé à ce niveau »
  - **Grille `GridView.count` 3 colonnes** de `AppCard` avec icône Lucide (depuis `subject.icon`) + `name.fr/name.en`
  - **Compteur** : « {N} matières » (FR) / « {N} subjects » (EN)
  - **Bouton primaire** : `AppButton.primary(« C'est ma classe »)` (FR) / « That's my class » (EN) — déclenche AC6
  - **Bouton secondaire** : `AppButton.secondary(« Retour »)` → `backTo(serie)` + `context.go(...)` selon contexte
  - **Lien retrait matières** (Story 1.4) : si `DerivedProfile.canOptOut == true`, afficher un `TextButton` discret « Retirer une matière » — **désactivé en Story 1.3** (clic = navigation no-op + log « Story 1.4 not implemented yet »). Visibilité conditionnelle préparée pour 1.4.
- État échec `Left(CatalogueFailure)` :
  - `CatalogueFailure.empty()` ou `.networkError(...)` : afficher l'écran connexion bloquant (`/catalogue-waiting` — redirect géré par router)
  - `CatalogueFailure.noMatchingRule(...)` : afficher un message d'erreur clair « Aucune classe trouvée pour ce profil. Reviens en arrière et corrige tes choix. » + bouton « Retour » qui `backTo(filiere)`. Log `AppLogger.w('derive() noMatchingRule: $profile')`.

**And** la page est **responsive 3 form factors** (NFR-17) :
- Phone : 2 colonnes (avec icônes grandes) ou 3 si écran assez large
- Tablet : 3-4 colonnes + max-width 720dp centré
- Pas de pixel hardcodé pour layout

### AC6 — Création doc Firestore + nav post-recap

**Given** récap affiché ET `FirebaseAuth.instance.currentUser != null` (anonymous OK — déjà acquis au boot par `_e0SmokeTest` Story 0.21)
**When** l'utilisateur tape « C'est ma classe »
**Then** :
1. Bouton passe en `AppButton.primary(loading: true, label: « Création de ton profil… »)` (i18n)
2. Construire le payload `users/{uid}` exactement selon BASE-DE-DONNEES.md § users/{uid} :
   ```dart
   {
     'uid': uid,
     'subSystem': subSystem.id,                        // 'francophone' | 'anglophone'
     'language': subSystem.languageCode,               // 'fr' | 'en'
     'filiere': flowState.filiereId,                   // 'generale' | 'technique'
     'niveau': flowState.niveauId,                     // 'francophone_terminale' etc.
     'serie': flowState.serieId ?? '-',                // 'francophone_terminale_d' ou '-' si niveau sans série
     'derivedSubjects': derivedProfile.subjects.map((s) => s.subjectId).toList(),
     'optedOutSubjects': <String>[],                   // vide à création (Story 1.4 modifiera)
     'examTargets': derivedProfile.examTargets.map((e) => e.examTargetId).toList(),
     'schoolId': null,                                 // Story 1.7
     'displayName': '',                                // Story 1.6 (linkWithCredential posera le name Google/Apple)
     'photoUrl': null,                                 // Story 1.6
     'createdAt': FieldValue.serverTimestamp(),
     'updatedAt': FieldValue.serverTimestamp(),
     'deletionRequestedAt': null,                      // Story 1.10
   }
   ```
3. Appel `firestore.collection('users').doc(uid).set(payload, SetOptions(merge: true))` — `merge: true` garantit idempotence (re-tap = re-écrit les mêmes valeurs sans duplication)
4. Log `AppLogger.i('Profile created: subSystem=${subSystem.id} niveau=${niveauId} serie=${serieId ?? "-"} subjects=${subjects.length}')`
5. Navigation : `context.go('/onboarding/account')` — route Story 1.6 (compte Google/Apple). **Mais Story 1.6 n'est pas encore livrée** → Story 1.3 V1 navigue vers `/hello` en attendant. Quand 1.6 mergera, remplace cette ligne par `/onboarding/account` ou `/onboarding/school` (selon ordre flow EXPERIENCE.md).

**And** en cas d'erreur Firestore (`FirebaseException` ex. `permission-denied`, `unavailable`) :
- Le `set()` est wrappé dans try/catch
- Retour `Left(Failure)` (créer une nouvelle classe `ProfileFailure` extends `Failure` : `.firestoreError(message)`, `.notAuthenticated()`)
- Toast non bloquant `AppToast.show(« Profil sauvegardé localement, on retentera en ligne »)` (i18n)
- Le state local reste cohérent — l'utilisateur peut re-taper « C'est ma classe » après reconnexion (idempotent grâce à merge: true)

**And** la création est **idempotente** : un re-tap après échec ne crée pas de doublon, met juste à jour `updatedAt`.

### AC7 — Règles Firestore `users/{uid}` étendues + tests rules

**Given** le fichier `firestore.rules` racine (Story 0.9 actuelle ligne 38-62)
**When** on inspecte la règle `match /users/{uid}`
**Then** la règle existante reste fonctionnelle + **étend** :
- **Création** (`allow create`) :
  - `request.resource.data.uid == uid`
  - `request.resource.data.subSystem in ['francophone', 'anglophone']`
  - `request.resource.data.language in ['fr', 'en']`
  - `request.resource.data.filiere in ['generale', 'technique']` ← NEW
  - `request.resource.data.niveau is string && request.resource.data.niveau.size() > 0` ← NEW
  - `request.resource.data.serie is string` ← NEW (peut être '-' donc autorise tout string non null)
  - `request.resource.data.derivedSubjects is list` ← NEW
  - `request.resource.data.examTargets is list` ← NEW
  - `request.resource.data.displayName is string` (existant)
- **Update** (`allow update`) :
  - `request.resource.data.subSystem == resource.data.subSystem` (existant)
  - `request.resource.data.language == resource.data.language` (existant)
  - `request.resource.data.createdAt == resource.data.createdAt` ← NEW (immutable)
  - `request.resource.data.filiere == resource.data.filiere` ← NEW (Story 1.3 fige aussi filière)
  - `request.resource.data.niveau == resource.data.niveau` ← NEW (idem)
  - `request.resource.data.serie == resource.data.serie` ← NEW (idem)
  - Pas de restriction sur `derivedSubjects`, `optedOutSubjects`, `examTargets`, `displayName`, `photoUrl`, `schoolId`, `updatedAt` (Stories 1.4, 1.6, 1.7 les modifieront)

**Note serveur strict** : ADR-006 dit que `subSystem`, `language`, `filiere`, `niveau`, `serie` sont tous figés à l'inscription. Cohérence : `createdAt` aussi. `updatedAt` doit pouvoir évoluer (chaque update qui passe la règle).

**And** `test/rules/users.test.mjs` enrichi avec **3 nouveaux tests** :
- `(g) update language KO` (rejette modif language)
- `(h) update createdAt KO` (rejette modif createdAt)
- `(i) update filiere KO` (rejette modif filiere — Story 1.3)
- Préserve les 6 tests existants Story 0.9 (a-f) qui restent verts

**And** le helper `validUserDoc(uid)` dans `users.test.mjs` est mis à jour pour utiliser les IDs catalogue cohérents avec la matrice Story 1.1a/1.1b : `niveau: 'francophone_terminale'`, `serie: 'francophone_terminale_d'`, `derivedSubjects: ['francophone_math', 'francophone_pct', ...]`, `examTargets: ['exam_bac_francophone_d']`.

**And** `cd test/rules && npm test` (commande validée Story 0.9) → 9 tests verts (6 existants + 3 nouveaux). Les tests tournent **directement sur valide-edu** (sans émulateur, mémorisé feedback `feedback_firebase_no_emulator.md`).

### AC8 — i18n + tests Flutter + qualité

**Given** la PR finalisée
**When** on exécute la validation
**Then** :
- **i18n** : toutes les chaînes utilisateur sont via `AppLocalizations.of(context)`. Au moins ~15 nouvelles clés ARB (titre/sous-titre des 4 pages + boutons + bandeau exam + compteur matières + messages erreur + libellé étapes « Étape X sur Y »). FR + EN cohérents (UX-DR-39 tutoiement FR / informal EN).
- **Tests widget** : ≥ 6 nouveaux tests (1 par page + 2 transitions + 1 erreur derive) dans `test/features/onboarding/presentation/`
- **Test unitaire state machine** : ≥ 5 cas dans `test/features/onboarding/domain/onboarding_flow_state_test.dart`
- **Test ProfileRepository** : ≥ 2 cas (créa OK + erreur firebase) dans `test/features/onboarding/data/user_profile_repository_test.dart` (via `fake_cloud_firestore`)
- `flutter analyze` 0 issue préservé
- `flutter test` complet vert (no régression sur les 100 tests existants Story 1.2)
- **PR ≤ 700 lignes diff** hors l10n générée + tests rules .mjs (cette story est `L (~6-8h)` — diff legitimement étoffé)
- Commit : `feat(onboarding): flow profil scolaire 3 etapes + recap matieres derivees + creation users doc (Story 1.3)`

## Tasks / Subtasks

- [ ] **T1 — Domain : `OnboardingFlowState` + `OnboardingFlowStep` enum** (AC1)
  - [ ] T1.1 — Créer `mobile_app/lib/features/onboarding/domain/onboarding_flow_state.dart` avec class @immutable + enum + getters + copyWith + resetFrom
  - [ ] T1.2 — Pas de dépendance Flutter (domain pur) — juste `package:flutter/foundation.dart` pour `@immutable` si voulu, ou simple class

- [ ] **T2 — Data : `UserProfileRepository`** (AC6)
  - [ ] T2.1 — Créer `mobile_app/lib/features/onboarding/data/user_profile_repository.dart` qui wrappe Firestore + Auth
  - [ ] T2.2 — Interface `UserProfileRepository` abstract dans `domain/` (clean arch ADR-001) — méthode `Future<Either<ProfileFailure, void>> createProfile({...})`
  - [ ] T2.3 — Impl `UserProfileRepositoryFirestoreImpl` dans `data/` — try/catch FirebaseException → `Left(ProfileFailure.firestoreError(...))`
  - [ ] T2.4 — Construire payload exactement selon AC6 (timestamps via `FieldValue.serverTimestamp()`)
  - [ ] T2.5 — `set(payload, SetOptions(merge: true))` partout (jamais `add()`)

- [ ] **T3 — Domain : `ProfileFailure` sealed/abstract class** (AC6)
  - [ ] T3.1 — Créer `mobile_app/lib/features/onboarding/domain/profile_failure.dart`
  - [ ] T3.2 — Étendre `Failure` (existant `lib/core/error/failures.dart` abstract — depuis Story 1.1c)
  - [ ] T3.3 — 2 variantes : `.firestoreError(String message)`, `.notAuthenticated()`

- [ ] **T4 — Providers Riverpod** (AC1, AC2, AC5, AC6)
  - [ ] T4.1 — Étendre `mobile_app/lib/features/onboarding/providers.dart` (existant Story 1.2)
  - [ ] T4.2 — Ajouter `onboardingFlowProvider` : `NotifierProvider<OnboardingFlowNotifier, OnboardingFlowState>`
  - [ ] T4.3 — Ajouter `userProfileRepositoryProvider` : `Provider<UserProfileRepository>` (instancie l'impl Firestore)
  - [ ] T4.4 — Ajouter `derivedProfileProvider` : `FutureProvider<Either<CatalogueFailure, DerivedProfile>>` qui appelle `catalogueRepository.derive(...)` avec les valeurs du flow state — invalidé au changement

- [ ] **T5 — Routes go_router : 4 routes onboarding/profile/*** (AC2, AC3, AC4, AC5)
  - [ ] T5.1 — Étendre `mobile_app/lib/core/routing/app_router.dart` (existant Stories 1.1c + 1.2)
  - [ ] T5.2 — Ajouter 4 `GoRoute` :
    - `/onboarding/profile/filiere` → `FiliereChoicePage`
    - `/onboarding/profile/niveau` → `NiveauChoicePage`
    - `/onboarding/profile/serie` → `SerieChoicePage`
    - `/onboarding/profile/recap` → `ProfileRecapPage`
  - [ ] T5.3 — Étendre le redirect global : si subSystem présent + utilisateur sur `/onboarding/profile/*` sans état flow cohérent, redirect vers la 1ère étape manquante. **MAIS** cette garde fine est le scope de **Story 1.5 (garde nav profil-incomplet)** — Story 1.3 fait le MVP : si sur `/onboarding/profile/niveau` sans filière, redirect vers `/onboarding/profile/filiere`. Pas plus. Story 1.5 généralisera.
  - [ ] T5.4 — Étendre `refreshListenable` pour écouter aussi `onboardingFlowProvider` (sinon le router ne re-évalue pas après transitions internes — pas critique car les pages appellent `context.go` explicite, mais cohérent avec pattern Story 1.2)

- [ ] **T6 — Présentation : `FiliereChoicePage`** (AC2)
  - [ ] T6.1 — `lib/features/onboarding/presentation/filiere_choice_page.dart` : `ConsumerStatefulWidget`
  - [ ] T6.2 — Scaffold + `AppProgressBar(value: 1/3, label: 'Étape 1 sur 3')`
  - [ ] T6.3 — Title H2 i18n + `LayoutBuilder` responsive
  - [ ] T6.4 — `ref.watch(catalogueRepositoryProvider).watchFilieres()` → `StreamBuilder` ou `ref.watch(stream)` via `AsyncValue.when(loading, data, error)`
  - [ ] T6.5 — Pour chaque filière active : `AppCard(onTap: → selectFiliere + context.go(niveau))`
  - [ ] T6.6 — Icônes Lucide selon `filiereId` (`generale` → `graduationCap`, `technique` → `wrench`)
  - [ ] T6.7 — Empty state : si stream `.isEmpty`, redirect vers `/catalogue-waiting`

- [ ] **T7 — Présentation : `NiveauChoicePage`** (AC3)
  - [ ] T7.1 — `lib/features/onboarding/presentation/niveau_choice_page.dart` : `ConsumerStatefulWidget`
  - [ ] T7.2 — Lecture state : `subSystem = ref.watch(subSystemNotifierProvider)`, `flow = ref.watch(onboardingFlowProvider)`. Si `flow.filiereId == null` → redirect `/onboarding/profile/filiere`
  - [ ] T7.3 — Header `AppProgressBar(value: 2/3, label: 'Étape 2 sur 3')` + Title H2 i18n
  - [ ] T7.4 — `watchNiveaux(subSystem, filiereId)` → `ListView.separated` de `AppCard` cliquables avec `name.fr/en`
  - [ ] T7.5 — Au tap : `selectNiveau` puis logique « pré-check séries » :
    ```dart
    final series = await catalogueRepository.watchSeries(...).first.timeout(Duration(seconds: 2), onTimeout: () => []);
    if (series.isEmpty) {
      flow.selectSerie(null);  // explicit null
      context.go('/onboarding/profile/recap');
    } else {
      context.go('/onboarding/profile/serie');
    }
    ```
  - [ ] T7.6 — Bouton retour : `backTo(filiere)` + nav

- [ ] **T8 — Présentation : `SerieChoicePage`** (AC4)
  - [ ] T8.1 — `lib/features/onboarding/presentation/serie_choice_page.dart` : `ConsumerStatefulWidget`
  - [ ] T8.2 — Guard : si flow.niveauId == null → redirect `/onboarding/profile/niveau`
  - [ ] T8.3 — Header progress 3/3 + title
  - [ ] T8.4 — `watchSeries(subSystem, niveauId, filiereId)` → conditional layout :
    - Si `series.length <= 5` : `AppPillTabs(labels: series.map((s) => s.name.fr/en).toList(), selectedIndex: -1, onTabSelected: (i) => selectSerie(series[i].serieId))`
    - Si `> 5` : `GridView.count(crossAxisCount: 3, children: series.map((s) => AppCard(onTap: ...))).toList()`
  - [ ] T8.5 — Au tap : `selectSerie(serieId)` + `context.go('/onboarding/profile/recap')`
  - [ ] T8.6 — Bouton retour : `backTo(niveau)` + nav

- [ ] **T9 — Présentation : `ProfileRecapPage`** (AC5, AC6)
  - [ ] T9.1 — `lib/features/onboarding/presentation/profile_recap_page.dart` : `ConsumerStatefulWidget`
  - [ ] T9.2 — Guard : si `!flow.isComplete` → redirect `/onboarding/profile/filiere`
  - [ ] T9.3 — `ref.watch(derivedProfileProvider)` → `AsyncValue.when(loading, data, error)`
  - [ ] T9.4 — Loading state : skeleton GridView 3x3 + spinner
  - [ ] T9.5 — Data state : Bandeau exam target + GridView matières + compteur + 2 boutons (primary « C'est ma classe » + secondary « Retour »)
  - [ ] T9.6 — Error state : différencier `CatalogueFailure.empty/networkError` (redirect /catalogue-waiting) vs `.noMatchingRule` (message d'erreur + retour)
  - [ ] T9.7 — Tap « C'est ma classe » : isLoading state local true → appel `userProfileRepository.createProfile(...)` → succès navigation `/hello` (V1, sera remplacé par `/onboarding/account` Story 1.6) ; échec `AppToast.show(...)` + isLoading false
  - [ ] T9.8 — Si `DerivedProfile.canOptOut == true`, afficher TextButton « Retirer une matière » désactivé avec log

- [ ] **T10 — i18n : nouvelles clés ARB FR + EN** (AC8)
  - [ ] T10.1 — Ajouter ~15 clés dans `mobile_app/lib/l10n/app_fr.arb` :
    - `onboardingStepLabel` ("Étape {step} sur {total}") avec placeholders
    - `onboardingFiliereTitle` / `onboardingFiliereGenerale` / `onboardingFiliereTechnique`
    - `onboardingNiveauTitle`
    - `onboardingSerieTitle` / `onboardingSerieSubtitle`
    - `onboardingRecapPrepareLabel` ("Tu prépares {examName}") avec placeholder
    - `onboardingRecapNoExamLabel` ("Pas d'examen visé à ce niveau")
    - `onboardingRecapSubjectsCount` ("{count, plural, =1{1 matière} other{{count} matières}}")
    - `onboardingRecapValidateCta` ("C'est ma classe")
    - `onboardingRecapOptOutLink` ("Retirer une matière")
    - `onboardingRecapCreatingLabel` ("Création de ton profil…")
    - `onboardingRecapFirestoreErrorToast` ("Profil sauvegardé localement, on retentera en ligne")
    - `onboardingRecapNoMatchingRule` (message erreur derive())
    - `onboardingBackButton` (réutilisable, ou réutiliser `back` existant)
  - [ ] T10.2 — Versions EN équivalentes UX-DR-39 informal ("Step {step} of {total}", "You're preparing {examName}", "That's my class", "Remove a subject", "Setting up your profile…", etc.)
  - [ ] T10.3 — `flutter gen-l10n` régénère AppLocalizations sans erreur

- [ ] **T11 — Tests Flutter** (AC8)
  - [ ] T11.1 — `test/features/onboarding/domain/onboarding_flow_state_test.dart` : 5 cas (état initial + selectFiliere → step niveau + selectNiveau → step serie + selectSerie → step recap + backTo reset)
  - [ ] T11.2 — `test/features/onboarding/data/user_profile_repository_test.dart` : 2 cas (createProfile succès avec `FakeFirebaseFirestore` + erreur FirebaseException simulée)
  - [ ] T11.3 — `test/features/onboarding/presentation/filiere_choice_page_test.dart` : 1 widget test (page render + tap → nav)
  - [ ] T11.4 — `test/features/onboarding/presentation/niveau_choice_page_test.dart` : 1 widget test (avec flow.filiereId pré-populé)
  - [ ] T11.5 — `test/features/onboarding/presentation/serie_choice_page_test.dart` : 1 widget test (PillTabs path)
  - [ ] T11.6 — `test/features/onboarding/presentation/profile_recap_page_test.dart` : 2 widget tests (data state grille matières affichée + error state noMatchingRule)
  - [ ] T11.7 — Adapter `widget_test.dart` si pertinent (HelloPage déjà testé avec subSystem fixé, normalement pas d'impact)

- [ ] **T12 — firestore.rules + tests rules** (AC7)
  - [ ] T12.1 — Modifier `firestore.rules` racine pour étendre la règle `match /users/{uid}` (cf. AC7 détails)
  - [ ] T12.2 — Modifier `test/rules/users.test.mjs` :
    - Mettre à jour `validUserDoc(uid)` avec IDs catalogue cohérents (`francophone_terminale`, `francophone_terminale_d`, derivedSubjects/examTargets remplis)
    - Ajouter 3 tests : (g) update language KO, (h) update createdAt KO, (i) update filiere KO
  - [ ] T12.3 — `cd test/rules && npm test` → 9 tests verts (6 existants + 3 nouveaux)
  - [ ] T12.4 — Déployer les nouvelles règles sur valide-edu : `firebase deploy --only firestore:rules --project valide-edu` (porteur ou Claude avec ADC déjà configurée)

- [ ] **T13 — Validation finale**
  - [ ] T13.1 — `cd mobile_app && flutter analyze` → 0 issue
  - [ ] T13.2 — `cd mobile_app && flutter test` → tous verts (100 existants + ~10 nouveaux)
  - [ ] T13.3 — `cd test/rules && npm test` → 9/9 verts
  - [ ] T13.4 — Smoke device (si APK release dispo) : flow complet Fatou Tle D < 60s + James Upper Sixth S2 < 60s + observer doc `users/{uid}` créé dans Firebase Console
  - [ ] T13.5 — Vérifier diff PR ≤ 700 lignes (hors l10n générée + .mjs tests)
  - [ ] T13.6 — Update story file + sprint-status review + commit + push

## Dev Notes

### Architecture compliance (ADR-001 + ADR-006 + ADR-015)

- **Clean arch 3 couches** : `lib/features/onboarding/{domain,data,presentation,providers.dart}`. Pas de Firebase dans domain (sauf `Locale` dart:ui qui est OK depuis Story 1.2).
- **ADR-006** : `subSystem`, `language` immutables serveur. Story 1.3 **étend** ce verrou à `filiere`, `niveau`, `serie`, `createdAt` côté règles Firestore. Cohérent avec « profil scolaire fixé à l'inscription » (FR-2).
- **ADR-015 dérivation côté client V1** : `CatalogueRepository.derive()` est appelé dans `derivedProfileProvider` (T4.4) au moment de l'écran récap. La dérivation est ré-exécutée à chaque entrée sur l'écran (rapide, cache offline). Pas de cache local custom.
- **Pas de Cloud Function** dans Story 1.3 — création directe `users/{uid}` Firestore. Cohérent ADR-003 (Firebase full backend) + dépôt mobile-only.

### Pattern Riverpod 3.x — Notifier simple + FutureProvider

- `OnboardingFlowNotifier extends Notifier<OnboardingFlowState>` — synchrone, pas d'AsyncNotifier nécessaire (état pur en mémoire).
- `derivedProfileProvider = FutureProvider<...>` qui dépend de `subSystemNotifierProvider` + `onboardingFlowProvider` + `catalogueRepositoryProvider`. Quand l'utilisateur change un choix en amont, le provider est invalidé automatiquement (ref.watch).
- Pas besoin de `AsyncNotifier` pour `derivedProfileProvider` — `FutureProvider` suffit car `derive()` est ponctuel (1 fois sur le récap, pas un stream).

### Modèle data `users/{uid}` Firestore — schéma autoritatif

Cf. BASE-DE-DONNEES.md § users/{uid} lignes 61-79. Récap des champs Story 1.3 doit poser :

| Champ | Type | Source en 1.3 |
|---|---|---|
| `uid` | string | `auth.currentUser.uid` |
| `subSystem` | enum string | `subSystemNotifierProvider` (Story 1.2) |
| `language` | enum string | dérivé : `subSystem.languageCode` |
| `filiere` | enum string | `flowState.filiereId` |
| `niveau` | string | `flowState.niveauId` (ex. `francophone_terminale`) |
| `serie` | string | `flowState.serieId ?? '-'` |
| `derivedSubjects` | string[] | `DerivedProfile.subjects.map((s) => s.subjectId)` |
| `optedOutSubjects` | string[] | `[]` vide à création (Story 1.4) |
| `examTargets` | string[] | `DerivedProfile.examTargets.map((e) => e.examTargetId)` |
| `schoolId` | string \| null | `null` (Story 1.7) |
| `displayName` | string | `''` (Story 1.6 posera Google/Apple name) |
| `photoUrl` | string \| null | `null` (Story 1.6) |
| `createdAt` | Timestamp | `FieldValue.serverTimestamp()` |
| `updatedAt` | Timestamp | `FieldValue.serverTimestamp()` |
| `deletionRequestedAt` | Timestamp \| null | `null` (Story 1.10) |

**Important** : utiliser `FieldValue.serverTimestamp()` pour `createdAt` + `updatedAt`. Sinon les timestamps sont calculés côté client (horloge potentiellement décalée) — incohérent avec règles serveur.

### Previous Story Intelligence (Stories 1.1c + 1.2)

**Story 1.1c (mergée 6913609)** — `CatalogueRepository` :
- Interface stable : `watchFilieres()`, `watchNiveaux({subSystem, filiereId})`, `watchSeries({subSystem, niveauId, filiereId})`, `watchSubjects({subSystem})`, `watchExamTargets({subSystem})`, `derive({subSystem, filiere, niveau, serie})` → `Future<Either<CatalogueFailure, DerivedProfile>>`, `hasNonEmptyCatalogue()`
- Tous les streams filtrent `isActive == true` automatiquement
- `name` est `Map<String, String>` (`{fr, en}`) — lire `name['fr']!` ou `name['en']!` selon subSystem
- `DerivedProfile.canOptOut` propagé depuis la `derivation_rule` matchée — Story 1.3 lit ce flag pour afficher/masquer le lien retrait
- Tests utilisent `FakeFirebaseFirestore` (dev_dependency `fake_cloud_firestore: ^4.0.0` au pubspec)

**Story 1.2 (mergée 3ccfd28)** — patterns à réutiliser :
- `subSystemNotifierProvider` synchrone (state non-null garanti car la route `/onboarding/profile/filiere` n'est accessible que si Story 1.2 a posé un subSystem — garde redirect global)
- Pattern preload SharedPreferences : déjà acquis, Story 1.3 n'a pas à toucher main.dart
- Pattern test `_preparePrefs` + override providers (à réutiliser dans T11)
- Pattern `firebaseAvailableProvider` guard dans presentation (cf. `subsystem_choice_page.dart`)
- Pattern `AppModal.show` pour confirmation : pas réutilisé en Story 1.3 (les choix filière/niveau/série n'ont pas de confirm modale — irréversible mais pas figé serveur, peut revenir en arrière)

### Code existant à NE PAS toucher (sauf via points d'extension explicites)

- **`SplashPage` Story 0.22** : préservée. Story 1.3 ne touche pas le splash.
- **`SubsystemChoicePage` Story 1.2** : préservée. Story 1.3 enchaîne après, ne modifie pas la page.
- **`HelloPage` Story 0.21** : sera la destination temporaire post-recap V1 (avant que Story 1.6 livre `/onboarding/account`). Pas de modif.
- **`CatalogueRepository` Story 1.1c** : interface stable, consommée en lecture seule.
- **`subSystemNotifierProvider` Story 1.2** : lecture seule (jamais `.notifier.set()` en Story 1.3 — le subSystem est fixé).

### Git intelligence (5 derniers commits)

```text
3ccfd28 Merge pull request #42 from DelRoos/feat/1.2-choix-sous-systeme-bascule-i18n
ad391fa feat(onboarding): choix sous-systeme immuable + bascule i18n runtime (Story 1.2)
ae8ea84 Merge pull request #41 from DelRoos/docs/cloture-1.1b-post-merge
9a279c2 docs(planning): contexte engine Story 1.2 choix sous-systeme + bascule i18n
3e837d2 docs(planning): cloture Story 1.1b post merge PR #40
```

- Baseline : main à `3ccfd28` (post merge 1.2). Branche `feat/1.3-flow-profil-scolaire-3-etapes` depuis là.
- Convention commit : `feat(onboarding): description FR à l'impératif (Story X.Y)`. Scope `onboarding` déjà ouvert par 1.2.

### File List (estimation)

| Fichier | Type | LOC estimé |
|---|---|---|
| `mobile_app/lib/features/onboarding/domain/onboarding_flow_state.dart` | NEW | ~60 |
| `mobile_app/lib/features/onboarding/domain/profile_failure.dart` | NEW | ~30 |
| `mobile_app/lib/features/onboarding/domain/user_profile_repository.dart` | NEW | ~30 (interface) |
| `mobile_app/lib/features/onboarding/data/user_profile_repository_firestore_impl.dart` | NEW | ~90 |
| `mobile_app/lib/features/onboarding/providers.dart` | UPDATE | +60 (3 providers ajoutés) |
| `mobile_app/lib/features/onboarding/presentation/filiere_choice_page.dart` | NEW | ~120 |
| `mobile_app/lib/features/onboarding/presentation/niveau_choice_page.dart` | NEW | ~140 |
| `mobile_app/lib/features/onboarding/presentation/serie_choice_page.dart` | NEW | ~150 |
| `mobile_app/lib/features/onboarding/presentation/profile_recap_page.dart` | NEW | ~200 |
| `mobile_app/lib/core/routing/app_router.dart` | UPDATE | +20 (4 routes + refreshListenable) |
| `mobile_app/lib/l10n/app_fr.arb` | UPDATE | +60 (15 clés + descriptions) |
| `mobile_app/lib/l10n/app_en.arb` | UPDATE | +30 (15 clés) |
| `mobile_app/lib/l10n/generated/app_localizations*.dart` | UPDATE | +120 (auto gen-l10n) |
| `mobile_app/test/features/onboarding/domain/onboarding_flow_state_test.dart` | NEW | ~80 |
| `mobile_app/test/features/onboarding/data/user_profile_repository_test.dart` | NEW | ~100 |
| `mobile_app/test/features/onboarding/presentation/*_test.dart` (4 fichiers) | NEW | ~250 cumul |
| `firestore.rules` | UPDATE | +15 (validation create + immutabilité update) |
| `test/rules/users.test.mjs` | UPDATE | +50 (3 tests + helper update) |

**Total estimé** : ~1525 lignes diff total. **Au-dessus du seuil 700** de DoD — pattern récurrent (Story 1.1c +1480, 1.2 +810). Justifié par scope intégral L (~6-8h) — 4 pages complètes + state machine + repo Firestore + règles + tests croisés.

### References

- [Source: project_manage/planning-artifacts/epics/epic-1-onboarding.md § Story 1.3 lignes 429-562]
- [Source: project_manage/planning-artifacts/prds/prd-valide-mvp-2026-06-03/prd.md § FR-2 ligne 122] — Remplissage du profil scolaire en étapes
- [Source: project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/EXPERIENCE.md lignes 437-450] — Flow 1 étapes 3-6
- [Source: project_manage/planning-artifacts/architecture/adrs/ADR-006-subsystem-fixed-at-signup.md] — subSystem + language immutables
- [Source: project_manage/planning-artifacts/architecture/adrs/ADR-015-catalogue-firestore-runtime-activation.md] — dérivation client V1
- [Source: doc/partage/BASE-DE-DONNEES.md § users/{uid} lignes 57-90] — schéma TypeScript autoritatif
- [Source: doc/partage/ALGORITHMES.md § 1 lignes 39-90] — algorithme dérivation + cas pas de match
- [Source: doc/partage/DONNEES-REFERENCE.md § Tableau de dérivation] — 69 derivation_rules seedées (Story 1.1b)
- [Source: mobile_app/lib/core/catalogue/domain/catalogue_repository.dart] — interface watchX + derive (Story 1.1c)
- [Source: mobile_app/lib/core/catalogue/domain/models.dart] — Filiere/Niveau/Serie/Subject/ExamTarget/DerivedProfile
- [Source: mobile_app/lib/features/onboarding/providers.dart] — subSystemNotifierProvider (Story 1.2) à étendre
- [Source: mobile_app/lib/features/onboarding/presentation/subsystem_choice_page.dart] — pattern Story 1.2 (ConsumerStatefulWidget + Riverpod + AppModal)
- [Source: mobile_app/lib/core/routing/app_router.dart] — pattern redirect global Story 1.1c + 1.2 à étendre
- [Source: mobile_app/lib/core/firebase/providers.dart] — firebaseAuthProvider + firestoreProvider + firebaseAvailableProvider
- [Source: mobile_app/lib/core/widgets/{app_card,app_pill_tabs,app_progress_bar,app_button}.dart] — composants UI existants
- [Source: firestore.rules racine ligne 38-62] — règle `users/{uid}` Story 0.9 à étendre
- [Source: test/rules/users.test.mjs] — 6 tests existants (a-f) Story 0.9 + helper validUserDoc

## Notes pour Amelia (dev agent)

### Anti-patterns à éviter (LLM disaster prevention)

- ❌ **NE PAS** dupliquer la dérivation `derive()` — utiliser EXCLUSIVEMENT `catalogueRepository.derive()` (Story 1.1c). Pas de logique de matching côté Story 1.3.
- ❌ **NE PAS** créer un nouveau `LocaleNotifier` ni nouveau `subSystemNotifierProvider` — ils EXISTENT (Story 1.2).
- ❌ **NE PAS** utiliser `Timestamp.now()` ou `DateTime.now()` pour `createdAt`/`updatedAt` — TOUJOURS `FieldValue.serverTimestamp()` (timestamps serveur cohérents).
- ❌ **NE PAS** utiliser `.add()` sur la collection `users` — TOUJOURS `.doc(uid).set(payload, SetOptions(merge: true))` pour idempotence + ID explicite = uid.
- ❌ **NE PAS** logger l'uid complet (CLAUDE.md § Sécurité). Logger juste le subSystem + niveau + nombre de subjects.
- ❌ **NE PAS** stocker `derivedSubjects` en cache client custom — relire depuis Firestore quand besoin (cache offline Firestore natif fait le job, ADR-010).
- ❌ **NE PAS** modifier `subSystemNotifierProvider.set()` en Story 1.3 — le subSystem est fixé en 1.2.
- ❌ **NE PAS** introduire `ProfileFailure` qui n'hérite pas de `Failure` (existant `lib/core/error/failures.dart`). Cohérence pattern Either<Failure, T>.
- ❌ **NE PAS** chaîner string en dur dans le code utilisateur — TOUT via `AppLocalizations.of(context)` (NFR-14).
- ❌ **NE PAS** ajouter `WillPopScope` partout sans nécessité — Android/iOS gèrent par défaut. Sauf sur ProfileRecapPage si on veut empêcher de revenir au flow après création doc Firestore (à débattre — V1 acceptable de laisser).
- ❌ **NE PAS** modifier `firestore.indexes.json` (Story 1.3 ne nécessite pas de nouveau composite index — les requêtes `users/{uid}` sont par doc ID).
- ❌ **NE PAS** push direct sur main. Toujours par PR.
- ❌ **NE PAS** déployer les règles Firestore depuis un autre projet que valide-edu (vérifier `firebase use valide-edu` avant `firebase deploy`).

### Patterns à suivre (best practice projet)

- ✅ **Either<Failure, T>** partout en data layer — `UserProfileRepository.createProfile()` retourne `Either<ProfileFailure, void>` (pas de void crochet, le void est expressif).
- ✅ **`FieldValue.serverTimestamp()`** pour TOUS les timestamps Firestore (pas de DateTime.now() client).
- ✅ **`set(payload, SetOptions(merge: true))`** EXCLUSIF pour `users/{uid}`. Jamais `add()` ni `set()` sans merge.
- ✅ **`ref.read(firebaseAuthProvider).currentUser?.uid`** avec guard firebaseAvailableProvider (pattern Story 1.2).
- ✅ **`AppLocalizations.of(context).*`** pour TOUTES les strings utilisateur. Pas une seule chaîne en dur.
- ✅ **`context.go()`** (pas `context.push()`) pour empêcher Android back button de polluer la stack onboarding.
- ✅ **Tests pattern Story 1.1c/1.2** : `SharedPreferences.setMockInitialValues({...subSystem})` + `appStartupCatalogueCheckProvider.overrideWith((ref) async => true)` + nouveau `userProfileRepositoryProvider.overrideWithValue(FakeUserProfileRepository())` pour widget tests.
- ✅ **Convention commit FR à l'impératif** + Co-Authored-By Claude Opus 4.7.

### Décisions techniques figées (ne pas re-discuter)

- **State machine via simple class @immutable** (pas sealed class) avec champs nullables + `currentStep` getter. Plus simple à serialiser, plus simple à tester.
- **`derivedProfileProvider` = `FutureProvider`** (pas AsyncNotifier) car `derive()` est ponctuel.
- **`UserProfileRepository`** dans `domain/` (interface) + `data/` (impl Firestore) — clean arch stricte.
- **`ProfileFailure` étend `Failure`** abstract existant.
- **Route post-recap V1 = `/hello`** (sera remplacée par `/onboarding/account` Story 1.6 sans toucher 1.3).
- **Règles Firestore étendues côté `users/{uid}`** : Story 1.3 ajoute la validation des champs créa + immutabilité update sur subSystem/language/filiere/niveau/serie/createdAt. Pas plus.
- **Tests rules en direct sur valide-edu** (pas d'émulateur — feedback `feedback_firebase_no_emulator.md`).
- **Lien « Retirer une matière » désactivé V1** — Story 1.4 l'activera. Préparer la visibilité conditionnelle `if (derivedProfile.canOptOut)`.

### Workflow git

1. Branche : `feat/1.3-flow-profil-scolaire-3-etapes` depuis main à `3ccfd28`
2. Commits intermédiaires OK (squash final au merge)
3. PR ciblant `main`
4. PR ≤ 700 lignes diff hors l10n générée + .mjs tests rules
5. Co-Authored-By Claude Opus 4.7

### Si Amelia a un doute

- **Sur l'ordre flow post-recap V1** : EXPERIENCE.md ligne 446 dit recap → liaison école (Story 1.7) → compte (Story 1.6). Mais 1.6 et 1.7 ne sont pas livrées. Story 1.3 V1 navigue vers `/hello` (sentinelle). Le commentaire dans le code doit dire « Sera remplacé par /onboarding/school (Story 1.7) ou /onboarding/account (Story 1.6) ».
- **Sur le label étape 3/3 quand serie skip** : si niveau sans série, on saute directement à recap. La progress bar passe de 2/3 à 100% sans afficher 3/3 ? Décision : passer de 66% à 100% directement, c'est acceptable visuellement (animation `AppProgressBar` smooth).
- **Sur le tri des niveaux** : `CatalogueRepository.watchNiveaux` applique déjà `orderBy('sortOrder')` (Story 1.1c). Les niveaux apparaissent dans l'ordre 6ᵉ → Tle naturellement.
- **Sur la garde niveau-sans-filière** : si quelqu'un tape `/onboarding/profile/niveau` sans filière (deep link, debug), la garde T7.2 le redirige vers `/filiere`. Test widget validera ce cas.
- **Sur `serie: '-'` vs `null` en Firestore** : décision = string `'-'` (cohérent avec règle Firestore qui valide `is string`). null serait acceptable mais le helper de test serait à adapter. Choix : `'-'` pour rester simple côté règles.
- **Sur le déploiement firestore.rules** : déjà testé Story 1.1c (ADC OK). Commande : `firebase deploy --only firestore:rules --project valide-edu`. Avant deploy, lancer `cd test/rules && npm test` pour validation locale.

### Si Amelia veut aller plus vite (optimisations autorisées)

- ✅ Utiliser un helper privé `_OnboardingProgressHeader` réutilisable pour les 3 pages (DRY).
- ✅ Mutualiser l'AsyncValue.when patterns via une extension ou un widget générique (mais ne pas sur-engineer).
- ✅ Tester les 4 widget pages avec un pattern partagé `_pumpOnboardingPage(tester, flowState)`.

### Questions ouvertes à signaler dans la PR (non bloquantes)

- 🟡 **Comportement post-création si Story 1.6 pas mergée** : V1 navigue `/hello`. Si user tape « C'est ma classe » sans Story 1.6 → arrive sur HelloPage. Acceptable pour V1 mais à documenter.
- 🟡 **Affichage compteur matières « N matières »** : pluralisation Dart via `intl` package (`Intl.plural(...)` ou ARB plural placeholder). Choisir une approche cohérente avec le projet existant.
- 🟡 **Cas niveau avec 1 seule série** : ex. si une série unique existe pour un niveau, faut-il auto-skip cette étape ? V1 décision : non, afficher la série + tap explicite (cohérence UX, l'utilisateur voit son choix).

## Definition of Done

- [ ] `lib/features/onboarding/{domain,data,presentation}/` étendu : 9 nouveaux fichiers + providers.dart UPDATE
- [ ] `lib/l10n/app_{fr,en}.arb` : 15+ nouvelles clés + AppLocalizations régénéré
- [ ] `lib/core/routing/app_router.dart` : 4 nouvelles routes
- [ ] `firestore.rules` racine : règle `users/{uid}` étendue + déployée sur valide-edu
- [ ] `test/rules/users.test.mjs` : 9 tests verts (6 existants + 3 nouveaux) + helper validUserDoc mis à jour
- [ ] ≥ 10 nouveaux tests Flutter verts (5 domain state machine + 2 data repo + 4 widget pages)
- [ ] `flutter analyze` 0 issue préservé
- [ ] `flutter test` tous verts (no régression sur 100 existants)
- [ ] (Si device dispo) Smoke device : flow complet Fatou Tle D < 60s + doc users/{uid} créé dans Firestore Console valide-edu
- [ ] PR ≤ 700 lignes diff hors l10n générée + .mjs
- [ ] Commit `feat(onboarding): flow profil scolaire 3 etapes + recap matieres derivees + creation users doc (Story 1.3)` avec Co-Authored-By Claude Opus 4.7
- [ ] Branch `feat/1.3-flow-profil-scolaire-3-etapes` poussée + PR créée
- [ ] `sprint-status.yaml` : `1-3` review puis done après merge
- [ ] Story frontmatter `status: review` puis `done`, `merged: YYYY-MM-DD`, `merge_commit: <sha>`, `pr_number: <n>`

## Dev Agent Record

### Agent Model Used

(à remplir lors de l'implémentation)

### Debug Log References

(à remplir si nécessaire)

### Completion Notes List

(à remplir : volumétrie finale, écarts vs spec, suggestions pour Story 1.3 v2)

### File List

(à remplir : liste des fichiers créés/modifiés)

### Change Log

(à remplir : | Date | Auteur | Modification |)

---

**Ultimate context engine analysis completed — comprehensive developer guide created.**

Cette story est `ready-for-dev`. Amelia (via `/bmad-dev-story`) a tout pour implémenter sans ambiguïté :
- Architecture clean (domain + data + presentation + providers)
- 5 pages (Filière/Niveau/Série/Récap + state machine OnboardingFlowState)
- Pattern Riverpod 3.x (Notifier sync + FutureProvider pour derive)
- Pattern Firestore set(merge:true) + serverTimestamp + Either<ProfileFailure, void>
- Garde routing par étape (filière requise pour niveau, etc.)
- Règles Firestore étendues + 3 tests rules ajoutés
- 10+ tests Flutter couvrant state + data + widget
- Anti-patterns LLM disaster prevention (pas de derive duplication, pas de Timestamp.now(), pas de .add(), pas de log uid complet)
- Intelligence Stories 1.1c + 1.2 (patterns réutilisés + composants existants)
- File List explicite par tâche
