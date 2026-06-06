---
story_id: 1.2
title: Choix sous-système (FR-1) + bascule i18n runtime + persistance SharedPreferences
epic: 1
phase: P1
status: ready-for-dev
created: 2026-06-06
branch: feat/1.2-choix-sous-systeme-bascule-i18n
baseline_commit: 693d9eed  # merge commit Story 1.1b (PR #40)
estimation: M (~4-5h)
dependencies:
  - 0.16  # i18n FR/EN setup (gen-l10n + intl 0.20.2 + flutter_localizations actifs au pubspec)
  - 0.13  # AppButton.primary + AppButton.secondary
  - 0.14  # AppModal + shared_preferences déjà au pubspec ^2.3.3
  - 0.22  # SplashPage existante (ne pas réécrire, juste rediriger la destination post-anim)
  - 1.1c  # Pattern redirect global go_router + refreshListenable (à étendre)
blocks:
  - 1.3   # Flow profil 3 étapes (a besoin de subSystem fixé pour démarrer)
  - 1.5   # Garde navigation profil-incomplet (étend le redirect global de 1.2)
  - 1.6   # Compte Google/Apple (linkWithCredential nécessite l'Anonymous Auth posée)
  - 1.9   # Dashboard (filtre par subSystem)
sourceArtifacts:
  - project_manage/planning-artifacts/epics/epic-1-onboarding.md § Story 1.2 (lignes 339-426)
  - project_manage/planning-artifacts/prds/prd-valide-mvp-2026-06-03/prd.md § FR-1 (ligne 111) + § NFR-14 (ligne 714 bilinguisme intégral)
  - project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/EXPERIENCE.md ligne 25 (langue figée à inscription) + ligne 438 (Flow 1 étape 2 : deux boutons primaires plein largeur)
  - project_manage/planning-artifacts/architecture/adrs/ADR-006-subsystem-fixed-at-signup.md (sous-système figé définitivement à l'inscription)
  - project_manage/planning-artifacts/architecture/adrs/ADR-001-flutter-clean-architecture.md (règle d'or domain pur, data isolée)
  - project_manage/planning-artifacts/architecture/adrs/ADR-011-cross-platform-v1-android-ios-tablet.md (NFR-16, NFR-17 — responsive)
  - mobile_app/lib/app.dart (LocaleNotifier + localeProvider DÉJÀ EN PLACE — Story 1.2 consomme, modifie pour dériver de subSystem)
  - mobile_app/lib/main.dart (boot Firebase non bloquant + _e0SmokeTest fait déjà signInAnonymously au boot — Anonymous Auth probablement déjà acquise quand utilisateur arrive sur choix)
  - mobile_app/lib/core/routing/app_router.dart (pattern redirect global + refreshListenable — à étendre)
  - mobile_app/lib/features/splash/presentation/splash_page.dart (_kRouteAfterSplash hardcodé '/hello' — à rendre conditionnel)
  - mobile_app/lib/core/widgets/app_modal.dart (signature AppModal.show + primary/secondary)
  - mobile_app/lib/core/widgets/app_button.dart (AppButton.primary + .secondary, hauteur 52.h)
  - mobile_app/lib/core/firebase/providers.dart (firebaseAuthProvider lazy)
  - mobile_app/lib/l10n/app_fr.arb + app_en.arb (clés existantes — réutiliser continueLabel + cancelLabel)
  - mobile_app/pubspec.yaml (shared_preferences ^2.3.3 et flutter_localizations DÉJÀ présents)
---

# Story 1.2 — Choix sous-système (FR-1) + bascule i18n runtime + persistance SharedPreferences

Status: **ready-for-dev**

## Objectif

Livrer le **premier écran de choix utilisateur** de Valide : sélection francophone/anglophone qui **fixe définitivement la langue + le curriculum** (ADR-006), avec :

1. Splash existant (Story 0.22, ne pas modifier) qui navigue vers `/onboarding/subsystem` au lieu de `/hello` au 1er lancement
2. Page de choix : 2 `AppButton.primary` plein largeur (« Francophone » / « Anglophone »), aucun défaut suggéré
3. Modale de confirmation explicite avant de valider (« Ce choix fixe la langue et le programme. Tu ne pourras pas changer après. ») — pas de retour arrière silencieux possible
4. Au tap « Continuer » : bascule immédiate `MaterialApp.locale` (FR ↔ EN) + persistance `SharedPreferences` (`subSystem`, `language`) + navigation vers `/hello` (route cible jusqu'à 1.3 qui livrera `/onboarding/profile/filiere`)
5. Persistance kill app : au relancement, le splash navigue **direct** vers `/hello` (la page choix n'est jamais re-ouverte), avec la locale restaurée AVANT le 1er rendu
6. Garde « first launch only » via redirect `go_router` : tentative d'accès à `/onboarding/subsystem` après choix → redirect vers `/`

**Pourquoi** : FR-1 + ADR-006 + EXPERIENCE.md Flow 1. C'est l'étape **bloquante pour tout le reste de l'onboarding** : Stories 1.3 (profil scolaire), 1.5 (garde nav), 1.6 (compte Google), 1.9 (dashboard) consomment `subSystem` figé.

**Critère de fin** : Fatou (francophone) et James (anglophone) peuvent chacun lancer l'app pour la 1ère fois, voir le splash, choisir leur sous-système avec confirmation, voir l'app basculer dans leur langue, puis arriver sur `/hello`. Kill app + relance = direct sur `/hello` sans repasser par le choix. Aucune chaîne en dur dans le code (NFR-14).

## Story

**As a** élève camerounais qui lance Valide pour la 1ʳᵉ fois,
**I want** un écran clair me proposant 2 boutons « Francophone » et « Anglophone » qui basculent immédiatement toute l'interface dans la langue correspondante et fixent mon curriculum définitivement,
**so that** je puisse démarrer mon parcours dans ma langue sans confusion et que l'app respecte ADR-006 (sous-système immuable).

## Acceptance Criteria

### AC1 — Splash navigue vers `/onboarding/subsystem` au 1er lancement (sans modifier l'animation existante)

**Given** un device sans `subSystem` enregistré dans SharedPreferences
**When** l'app démarre
**Then** le splash existant (Story 0.22 — animation `_kStrokeDuration` 1800 ms + `_kHoldAfterStroke` 300 ms = 2100 ms total) s'affiche **sans modification de durée ni d'animation**
**And** à la fin de l'animation, la `SplashPage` navigue vers `/onboarding/subsystem` (au lieu du `'/hello'` actuel hardcodé ligne 38 de [`splash_page.dart`](../../mobile_app/lib/features/splash/presentation/splash_page.dart))
**And** la décision est prise en lisant `SharedPreferences.getString('subsystem')` (synchrone via le provider préchargé — cf. AC3) :
- Si null → `/onboarding/subsystem`
- Si `'francophone'` ou `'anglophone'` → `/hello` (route sentinelle existante, sera remplacée par `/onboarding/profile/filiere` en Story 1.3 SANS toucher à 1.2)

**Important** : `_kRouteAfterSplash` const **disparaît**. La destination devient dynamique via `ref.read(subSystemNotifierProvider)` dans `_goNext()`.

### AC2 — Page `/onboarding/subsystem` : 2 boutons plein largeur + aucun défaut

**Given** la route `/onboarding/subsystem` ouverte
**When** la `SubsystemChoicePage` se rend
**Then** la page affiche :
- Un **titre** i18n (`subsystemChoiceTitle`) — ex. FR : « Choisis ta langue et ton programme » / EN : « Choose your language and program »
- Un **sous-titre** i18n court (`subsystemChoiceSubtitle`) — ex. FR : « Tu ne pourras pas changer après. » / EN : « You won't be able to change it later. »
- **Deux `AppButton.primary` plein largeur empilés verticalement** :
  - `AppButton.primary(label: "Francophone")` avec `onPressed: _onTapFrancophone`
  - `AppButton.primary(label: "Anglophone")` avec `onPressed: _onTapAnglophone`
- **Aucun bouton par défaut suggéré** (pas d'`autofocus: true`, pas de surbrillance préférentielle, pas d'ordre qui implique « celui du haut est recommandé » — équilibrage visuel strict)

**And** les 2 boutons sont **plein largeur** : enveloppés dans `SizedBox(width: double.infinity, child: AppButton.primary(...))` car `AppButton` n'a pas de prop `fullWidth` (cf. [`app_button.dart`](../../mobile_app/lib/core/widgets/app_button.dart) ligne 72 : Container avec width implicite = parent)

**And** la page respecte le responsive 3 form factors (NFR-17, ADR-011) :
- Phone portrait < 600 dp : padding latéral `AppSpacing.s5.w`, boutons sur toute la largeur
- Tablet ≥ 840 dp : padding latéral généreux (ex. centrer avec `ConstrainedBox(maxWidth: 480.w)`)
- Pas de pixel hardcodé pour layout, utiliser `LayoutBuilder` ou `MediaQuery.sizeOf(context).width`

**And** la page est rendue par un `ConsumerStatefulWidget` (consomme Riverpod) avec `Scaffold` + `backgroundColor: AppColors.background` (ou `AppColors.card` — voir tokens).

### AC3 — Modale de confirmation + bascule i18n instantanée + persistance SharedPreferences

**Given** la page de choix affichée
**When** l'utilisateur tape `Francophone` (ou `Anglophone`)
**Then** une modale de confirmation s'affiche via `AppModal.show()` (cf. [`app_modal.dart`](../../mobile_app/lib/core/widgets/app_modal.dart)) :
- **Titre** : `subsystemConfirmTitle` (ex. FR : « Confirmer ton choix »)
- **Corps** : `subsystemConfirmBody` (ex. FR : « Ce choix fixe la langue et le programme. Tu ne pourras pas changer après. »)
- **Bouton secondary** : `cancelLabel` (clé i18n existante, FR « Annuler ») → ferme la modale, retour à la page de choix
- **Bouton primary** : `continueLabel` (clé i18n existante, FR « Continuer ») → exécute la confirmation

**When** l'utilisateur tape `[Continuer]` :
**Then** ces actions s'exécutent **dans cet ordre** :
1. Persist en SharedPreferences : `prefs.setString('subsystem', 'francophone' | 'anglophone')` ET `prefs.setString('language', 'fr' | 'en')` — durabilité kill app garantie
2. Update state du `subSystemNotifierProvider` (interne in-memory) — déclenche les watchers
3. `MaterialApp.locale` bascule immédiatement (le `LocaleNotifier` dérive de `subSystemNotifierProvider`, cf. AC4)
4. Log via `AppLogger.i('Subsystem chosen: $subSystem')` — **PAS** le uid complet pour éviter PII en logs (CLAUDE.md § Sécurité)
5. `AppLogger.i('Anonymous auth uid present: ${auth.currentUser?.uid != null}')` (boolean, pas l'uid lui-même)
6. Navigation `context.go('/hello')` — `go` (pas `push`) pour empêcher le back button d'Android de revenir à la page de choix

**And** la modale s'affiche dans la **locale courante** de l'app (au moment du tap). Si l'utilisateur est en FR et tape "Anglophone", la modale est en FR ; après confirmation, l'app bascule en EN. Si on veut V2 afficher la modale dans la LANGUE CIBLE pour valider dans cette langue, c'est un futur enrichissement — V1 reste simple.

**And** si l'utilisateur tape `[Annuler]` ou ferme la modale (barrierDismissible: false donc seul le bouton ferme — cf. AppModal ligne 18) → rien n'est persisté, on reste sur la page de choix.

### AC4 — Persistance kill app + locale restaurée AVANT 1er rendu (pas de flash FR→EN)

**Given** un utilisateur anglophone (subSystem persisté précédemment)
**When** l'app est tuée puis relancée
**Then** **avant le 1er `runApp`**, `main.dart` exécute `final prefs = await SharedPreferences.getInstance();` (~10 ms en hot start)
**And** `prefs` est injecté dans le `ProviderScope` via `overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]`
**And** au build initial de `LocaleNotifier`, `build()` lit `subSystemNotifierProvider` (synchronisé via le prefs préchargé) et retourne `Locale('en')` directement — **pas de flash FR par défaut puis bascule EN**
**And** le splash s'affiche en EN dès la 1ère frame (pas applicable car splash n'a pas de texte — mais la suite oui)
**And** à la fin du splash, navigation **directe** vers `/hello` (puisque subSystem présent → AC1 décide ainsi)
**And** la route `/onboarding/subsystem` n'est jamais re-ouverte (sauf accès manuel via deep link → AC5 redirige)

**Implémentation `main.dart`** :

```dart
Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  // Story 1.2 — preload SharedPreferences AVANT runApp pour eviter le flash
  // de locale par defaut puis bascule au build initial.
  final prefs = await SharedPreferences.getInstance();

  unawaited(_bootstrap());
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const ValideApp(),
    ),
  );
}
```

### AC5 — Garde « first launch only » via redirect `go_router`

**Given** un utilisateur avec `subSystem` posé (state ou SharedPreferences)
**When** il tente d'accéder à `/onboarding/subsystem` manuellement (deep link, lien debug, ou navigation programmatique en test)
**Then** le `redirect` global de `routerProvider` (cf. [`app_router.dart`](../../mobile_app/lib/core/routing/app_router.dart) lignes 25-46 — pattern Story 1.1c à étendre) :
- Détecte que `subSystemNotifierProvider` retourne une valeur non-null
- Redirige vers `/` (qui re-redirige vers `/splash` via la GoRoute `/` existante ligne 53)
- Le splash navigue ensuite vers `/hello` (puisque subSystem présent — AC1)

**And** la garde est **centralisée** dans le `redirect` (pas dispersée dans chaque page) — cohérent avec Story 1.5 (garde navigation profil-incomplet) qui ÉTENDRA cette logique.

**And** la liste des routes **bypass** dans le redirect doit inclure `/onboarding/subsystem` quand le subSystem est ABSENT (sinon boucle infinie). Logique exacte :

```dart
redirect: (context, state) {
  final loc = state.matchedLocation;

  // Bypass inconditionnel
  if (loc == '/' || loc.startsWith('/splash') || loc.startsWith('/_')) {
    return null;
  }

  final subSystem = ref.read(subSystemNotifierProvider);

  // Cas 1 : subSystem absent
  if (subSystem == null) {
    if (loc == '/onboarding/subsystem') return null;  // déjà sur la bonne route
    if (loc == '/catalogue-waiting') return null;     // catalogue prioritaire ? voir note
    return '/onboarding/subsystem';
  }

  // Cas 2 : subSystem present
  if (loc == '/onboarding/subsystem') {
    return '/';  // first-launch-only : ne pas re-ouvrir
  }

  // Pour les autres routes : check catalogue (logique Story 1.1c préservée)
  final catalogueCheck = ref.read(appStartupCatalogueCheckProvider);
  if (loc == '/catalogue-waiting') return null;
  return catalogueCheck.when(
    data: (ok) => ok ? null : '/catalogue-waiting',
    loading: () => null,
    error: (_, _) => '/catalogue-waiting',
  );
},
```

**Note ordering subsystem vs catalogue** : on traite subsystem AVANT catalogue. Justification : sans subSystem, l'écran de catalogue-waiting (qui montre un texte) n'a pas de langue clairement choisie — le user doit choisir d'abord, puis on vérifie le catalogue. **Edge case** : si user offline+vide catalogue ET pas de subSystem, on l'envoie sur `/onboarding/subsystem`. Le tap "Continuer" tentera d'accéder à `/hello` qui se fera rediriger vers `/catalogue-waiting`. Acceptable — le user a au moins défini sa langue avant de voir l'écran connexion bloquant.

**And** le `refreshListenable` (ligne 16-19 de `app_router.dart`) doit ÉCOUTER en plus `subSystemNotifierProvider` :

```dart
ref.listen(appStartupCatalogueCheckProvider, (_, _) => notifier.value++);
ref.listen(subSystemNotifierProvider, (_, _) => notifier.value++);  // NEW
```

Sinon, le tap "Continuer" persiste mais le router ne re-évalue pas le redirect → l'utilisateur reste bloqué.

### AC6 — Anonymous Auth pas re-déclenchée (déjà acquise au boot par _e0SmokeTest)

**Given** l'app au boot — `main.dart` ligne 33 lance `_bootstrap()` non bloquant qui appelle `_e0SmokeTest()` ligne 91-124, lequel exécute `signInAnonymously()` si `auth.currentUser == null`
**When** l'utilisateur arrive sur la page de choix (généralement 2-5 s après le boot)
**Then** dans 99% des cas, `FirebaseAuth.instance.currentUser?.uid` est déjà non-null (Anonymous Auth acquise par le smoke test)
**And** au tap `[Continuer]`, le handler **ne re-déclenche PAS** `signInAnonymously()` — il lit juste `auth.currentUser` et log :

```dart
final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
AppLogger.i('Subsystem chosen: ${subSystem.id}, anonymous auth: ${uid != null ? "present" : "absent"}');
```

**And** si `uid == null` (cas rare : Firebase init a échoué ou réseau hors-ligne au boot), le flow continue sans bloquer :
- Persistance SharedPreferences fonctionne (locale)
- Navigation `/hello` fonctionne
- Le doc Firestore `users/{uid}` sera créé en Story 1.3 quand l'auth reviendra (linkWithCredential idempotent)

**Anti-pattern à éviter** : **NE PAS** ajouter `await ref.read(firebaseAuthProvider).signInAnonymously();` dans Story 1.2. C'est redondant avec le smoke test E0 et risque de créer un compte fantôme si le smoke test a déjà réussi (Firebase Auth garantit normalement l'unicité, mais inutile de tenter).

### AC7 — Bilinguisme intégral (NFR-14) — 6 nouvelles clés ARB

**Given** le setup gen-l10n (cf. `mobile_app/l10n.yaml` + `pubspec.yaml` ligne 116 `generate: true`)
**When** on ajoute les clés
**Then** `app_fr.arb` reçoit **6 nouvelles clés** (toutes les autres réutilisent l'existant — `cancelLabel`, `continueLabel`) :

```json
"subsystemChoiceTitle": "Choisis ta langue et ton programme",
"@subsystemChoiceTitle": { "description": "Titre H2 de la page /onboarding/subsystem (Story 1.2). Tutoiement UX-DR-39." },

"subsystemChoiceSubtitle": "Tu ne pourras pas changer après.",
"@subsystemChoiceSubtitle": { "description": "Sous-titre court qui avertit du caractère immuable du choix (ADR-006)." },

"subsystemFrancophone": "Francophone",
"@subsystemFrancophone": { "description": "Label du bouton qui sélectionne le sous-système francophone." },

"subsystemAnglophone": "Anglophone",
"@subsystemAnglophone": { "description": "Label du bouton qui sélectionne le sous-système anglophone." },

"subsystemConfirmTitle": "Confirmer ton choix",
"@subsystemConfirmTitle": { "description": "Titre de la modale de confirmation qui s'affiche après tap sur Francophone/Anglophone." },

"subsystemConfirmBody": "Ce choix fixe la langue et le programme. Tu ne pourras pas changer après.",
"@subsystemConfirmBody": { "description": "Corps de la modale de confirmation. Explicite l'irréversibilité (ADR-006 negatif #2)." }
```

**And** `app_en.arb` reçoit les mêmes clés en EN informal (UX-DR-39 : « you », pas « thou ») :

```json
"subsystemChoiceTitle": "Choose your language and program",
"subsystemChoiceSubtitle": "You won't be able to change this later.",
"subsystemFrancophone": "Francophone",
"subsystemAnglophone": "Anglophone",
"subsystemConfirmTitle": "Confirm your choice",
"subsystemConfirmBody": "This choice locks your language and program. You won't be able to change it later."
```

**And** `flutter gen-l10n` regénère `AppLocalizations` sans erreur (auto via `flutter:` `generate: true`).

### AC8 — Tests + DoD

**Given** la PR finalisée
**When** on exécute la validation
**Then** ≥ 5 tests passent :

**4 widget tests** (`mobile_app/test/features/onboarding/presentation/subsystem_choice_page_test.dart`) :
1. `Splash navigue vers /onboarding/subsystem quand subSystem absent` — pumpWidget avec `sharedPreferencesProvider` overridé `getString('subsystem') == null`, pump 2300ms, expect `find.byType(SubsystemChoicePage), findsOneWidget`
2. `Tap Anglophone → modale s'affiche` — pumpWidget direct sur SubsystemChoicePage, tap, expect `find.text(<subsystemConfirmTitle>), findsOneWidget`
3. `Tap Continuer → locale change + nav /hello + SharedPreferences mis à jour` — verify `MaterialApp.locale == Locale('en')` après tap, verify `mockPrefs.getString('subsystem') == 'anglophone'`, verify `find.text('Hello Valide')` (route /hello)
4. `Garde first-launch : subSystem présent + tentative /onboarding/subsystem → redirect /` — pumpWidget avec subSystem persisté EN, push `/onboarding/subsystem` programmatiquement, expect `find.byType(SplashPage), findsOneWidget` (redirect / → /splash → /hello)

**1 test unitaire `SubsystemPrefs`** (`mobile_app/test/features/onboarding/data/subsystem_prefs_test.dart`) :
5. `set + read aller-retour` — write 'anglophone', expect get returns SubSystem.anglophone, expect language 'en'

(Tests bonus optionnels si le dev a le temps : tests de tous les `SubSystemExt` getters, test du redirect router avec `MockGoRouter`, etc.)

**And** `flutter analyze` retourne 0 issue (existants 0 issue préservé).
**And** `flutter test` complet (tous tests projet) reste vert — pas de régression sur les 92+ tests existants (Story 1.1c base + smaller). **Important** : les tests existants qui pumpent `ValideApp` doivent désormais préchager SharedPreferences (cf. pattern `_bypassCatalogueCheck` de Story 1.1c) — ajouter `sharedPreferencesProvider.overrideWithValue(FakeSharedPreferences())` dans les overrides.
**And** PR ≤ 500 lignes diff (le scope est focalisé : 1 page + 1 modèle + 1 wrapper prefs + 1 modif router + 1 modif splash + 1 modif main + 6 clés i18n + tests).
**And** Commit : `feat(onboarding): choix sous-systeme immuable + bascule i18n runtime (Story 1.2)`.

## Tasks / Subtasks

- [ ] **T1 — Modèle domain + extension Locale** (AC2, AC3, AC4)
  - [ ] T1.1 — Créer `mobile_app/lib/features/onboarding/domain/sub_system.dart` :
    ```dart
    enum SubSystem { francophone, anglophone }

    extension SubSystemExt on SubSystem {
      String get id => name; // 'francophone' | 'anglophone'
      String get languageCode => this == SubSystem.francophone ? 'fr' : 'en';
      Locale get locale => Locale(languageCode);
      static SubSystem? fromString(String? raw) {
        if (raw == 'francophone') return SubSystem.francophone;
        if (raw == 'anglophone') return SubSystem.anglophone;
        return null;
      }
    }
    ```
  - [ ] T1.2 — Aucune dépendance Flutter dans ce fichier sauf `dart:ui Locale` (acceptable pour core/feature mais à valider) — alternative : isoler `locale` getter dans data/ pour respecter strict ADR-001. Décision : `Locale` est `dart:ui`, OK pour domain (équivalent stdlib).

- [ ] **T2 — Data layer SharedPreferences** (AC3, AC4)
  - [ ] T2.1 — Créer `mobile_app/lib/features/onboarding/data/subsystem_prefs.dart` :
    ```dart
    class SubsystemPrefs {
      SubsystemPrefs(this._prefs);
      final SharedPreferences _prefs;
      static const _kKey = 'subsystem';
      static const _kLangKey = 'language';

      SubSystem? read() => SubSystemExt.fromString(_prefs.getString(_kKey));

      Future<void> write(SubSystem subSystem) async {
        await _prefs.setString(_kKey, subSystem.id);
        await _prefs.setString(_kLangKey, subSystem.languageCode);
      }
    }
    ```
  - [ ] T2.2 — Pas de logger ici (couche data simple), pas de Either<Failure, T> (SharedPreferences n'échoue pas dans la pratique pour ces opérations triviales).

- [ ] **T3 — Providers Riverpod** (AC4, AC5)
  - [ ] T3.1 — Créer `mobile_app/lib/features/onboarding/providers.dart` avec 3 providers :
    ```dart
    /// Override OBLIGATOIRE en main.dart via ProviderScope.overrides
    /// (preload SharedPreferences.getInstance() avant runApp).
    final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
      throw UnimplementedError('Override in main.dart with preloaded instance');
    });

    /// Wrapper lazy autour de SharedPreferences pour le subSystem.
    final subsystemPrefsProvider = Provider<SubsystemPrefs>((ref) {
      return SubsystemPrefs(ref.watch(sharedPreferencesProvider));
    });

    /// State courant — initialisé synchrone depuis SharedPreferences.
    /// Notifie au changement pour declencher refresh router + locale.
    class SubSystemNotifier extends Notifier<SubSystem?> {
      @override
      SubSystem? build() => ref.read(subsystemPrefsProvider).read();

      Future<void> set(SubSystem subSystem) async {
        await ref.read(subsystemPrefsProvider).write(subSystem);
        state = subSystem;
      }
    }
    final subSystemNotifierProvider =
        NotifierProvider<SubSystemNotifier, SubSystem?>(SubSystemNotifier.new);
    ```
  - [ ] T3.2 — `subSystemNotifierProvider.build()` est synchrone — `ref.read(subsystemPrefsProvider).read()` retourne synchrone car le `sharedPreferencesProvider` est préchargé (override main.dart).

- [ ] **T4 — Modif `app.dart` LocaleNotifier dérive de subSystem** (AC4)
  - [ ] T4.1 — Modifier `mobile_app/lib/app.dart` `LocaleNotifier.build()` :
    ```dart
    class LocaleNotifier extends Notifier<Locale> {
      @override
      Locale build() {
        final subSystem = ref.watch(subSystemNotifierProvider);
        return subSystem?.locale ?? const Locale('fr');
      }
      // setLocale supprime — la bascule passe par subSystemNotifierProvider.set()
    }
    ```
  - [ ] T4.2 — Supprimer la méthode `setLocale` (plus utilisée). Si du code consommateur l'appelait, migrer vers `subSystemNotifierProvider.set(SubSystem.x)`.

- [ ] **T5 — Modif `main.dart` preload SharedPreferences** (AC4)
  - [ ] T5.1 — Ajouter `await SharedPreferences.getInstance()` AVANT `runApp`
  - [ ] T5.2 — Wrap `ValideApp()` avec `ProviderScope(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)])`
  - [ ] T5.3 — Vérifier que `_bootstrap()` reste non bloquant (`unawaited`)

- [ ] **T6 — Modif `app_router.dart` redirect + route /onboarding/subsystem** (AC1, AC5)
  - [ ] T6.1 — Ajouter import `subsystem_choice_page.dart`
  - [ ] T6.2 — Étendre `refreshListenable` pour écouter aussi `subSystemNotifierProvider`
  - [ ] T6.3 — Étendre `redirect` selon logique AC5 (subSystem avant catalogue)
  - [ ] T6.4 — Ajouter `GoRoute(path: '/onboarding/subsystem', builder: ... SubsystemChoicePage())`

- [ ] **T7 — Modif `splash_page.dart` destination conditionnelle** (AC1)
  - [ ] T7.1 — Supprimer `const _kRouteAfterSplash = '/hello';`
  - [ ] T7.2 — Convertir `_goNext()` en consommateur Riverpod (la classe est déjà `ConsumerStatefulWidget`) :
    ```dart
    void _goNext() {
      if (_navigated || !mounted) return;
      _navigated = true;
      final subSystem = ref.read(subSystemNotifierProvider);
      final dest = subSystem == null ? '/onboarding/subsystem' : '/hello';
      context.go(dest);
    }
    ```
  - [ ] T7.3 — Pas de modif visuelle ni temporelle de l'animation (Story 0.22 préservée à 100%)

- [ ] **T8 — Présentation : `SubsystemChoicePage`** (AC2, AC3, AC6)
  - [ ] T8.1 — Créer `mobile_app/lib/features/onboarding/presentation/subsystem_choice_page.dart` : `ConsumerStatefulWidget`
  - [ ] T8.2 — Scaffold + responsive : `LayoutBuilder` ou `MediaQuery.sizeOf(context).width` pour layout 3 form factors
  - [ ] T8.3 — Stack vertical : title (`AppTypography.h2` via tokens) + subtitle + spacing + 2 boutons plein largeur + safe area
  - [ ] T8.4 — `_onTapFrancophone()` et `_onTapAnglophone()` appellent un `_confirmChoice(SubSystem subSystem)` partagé :
    ```dart
    Future<void> _confirmChoice(SubSystem subSystem) async {
      final l10n = AppLocalizations.of(context);
      final confirmed = await AppModal.show<bool>(
        context,
        title: l10n.subsystemConfirmTitle,
        child: Text(l10n.subsystemConfirmBody, style: AppTypography.body),
        primary: (label: l10n.continueLabel, onTap: (ctx) => Navigator.pop(ctx, true)),
        secondary: (label: l10n.cancelLabel, onTap: (ctx) => Navigator.pop(ctx, false)),
      );
      if (confirmed != true) return;
      if (!mounted) return;

      // Persist + bascule locale via notifier
      await ref.read(subSystemNotifierProvider.notifier).set(subSystem);

      final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
      AppLogger.i(
        'Subsystem chosen: ${subSystem.id}, '
        'anonymous auth: ${uid != null ? "present" : "absent"}',
      );

      if (!mounted) return;
      context.go('/hello'); // sera remplace par /onboarding/profile/filiere en Story 1.3
    }
    ```
  - [ ] T8.5 — Vérifier qu'il n'y a pas de chaîne en dur (NFR-14) — tout via `AppLocalizations.of(context)`

- [ ] **T9 — i18n : 6 nouvelles clés ARB** (AC7)
  - [ ] T9.1 — Ajouter les 6 clés dans `mobile_app/lib/l10n/app_fr.arb` (avec descriptions)
  - [ ] T9.2 — Ajouter les 6 clés dans `mobile_app/lib/l10n/app_en.arb`
  - [ ] T9.3 — Vérifier que `flutter gen-l10n` regénère sans erreur (lancé auto au prochain build via `generate: true`)
  - [ ] T9.4 — Vérifier que `AppLocalizations` expose `subsystemChoiceTitle`, etc.

- [ ] **T10 — Tests** (AC8)
  - [ ] T10.1 — Créer `test/features/onboarding/data/subsystem_prefs_test.dart` (1 test aller-retour avec `SharedPreferences.setMockInitialValues({})`)
  - [ ] T10.2 — Créer `test/features/onboarding/presentation/subsystem_choice_page_test.dart` (4 widget tests)
  - [ ] T10.3 — Vérifier que les tests existants qui pumpent `ValideApp` overrident `sharedPreferencesProvider` (`SharedPreferences.setMockInitialValues({})` + `await SharedPreferences.getInstance()`) — sinon throw `UnimplementedError` du provider. Adapter `test/widget_test.dart` + `test/features/splash/splash_page_test.dart` + `test/features/catalogue/presentation/catalogue_waiting_page_test.dart` similaire au pattern `_bypassCatalogueCheck` de Story 1.1c.
  - [ ] T10.4 — `flutter test` complet → tous verts (sans régression).

- [ ] **T11 — Validation finale** (AC8 + DoD)
  - [ ] T11.1 — `cd mobile_app && flutter analyze` → 0 issue
  - [ ] T11.2 — `cd mobile_app && flutter test` → tous verts
  - [ ] T11.3 — (Si Android device dispo) `flutter run --release` → tester flow Fatou (tap Francophone → modale FR → Continuer → /hello en FR) + tester flow James (tap Anglophone → modale en FR (locale courante) → Continuer → app bascule EN → /hello en EN avec "Bonjour Valide" devenu "Hello Valide")
  - [ ] T11.4 — (Si possible) kill+restart : vérifier que l'app va direct sur /hello dans la bonne langue
  - [ ] T11.5 — Diff PR ≤ 500 lignes
  - [ ] T11.6 — Update story frontmatter + sprint-status (in-progress → review) + Dev Agent Record
  - [ ] T11.7 — Commit `feat(onboarding): choix sous-systeme immuable + bascule i18n runtime (Story 1.2)` + push

## Dev Notes

### Architecture compliance (ADR-001 clean arch + ADR-006 immuable)

- **`lib/features/onboarding/`** : nouveau feature folder. 3 couches : `domain/` (SubSystem enum + extensions), `data/` (SubsystemPrefs SharedPreferences wrapper), `presentation/` (SubsystemChoicePage). Plus `providers.dart` au niveau feature pour exposer les providers Riverpod (pattern utilisé par `lib/core/catalogue/providers.dart` Story 1.1c).
- **Pas de Firebase dans Story 1.2** côté écriture. Le `users/{uid}` Firestore est créé en **Story 1.3** (après le flow profil 3 étapes). Story 1.2 écrit UNIQUEMENT en SharedPreferences locale.
- **ADR-006 immuable** : le doc `users/{uid}.subSystem` (créé en Story 1.3) sera immuable côté serveur via règle Firestore (étendue en 1.3). En attendant, la garde first-launch côté client (AC5) suffit.
- **Pas de logger sensible** (CLAUDE.md § Sécurité interdit logger uid complet) — Story 1.2 log juste un boolean `anonymous auth: present|absent`.

### Pattern Riverpod 3.x — Notifier + AsyncValue selon les cas

- `SubSystemNotifier extends Notifier<SubSystem?>` — synchrone car le `sharedPreferencesProvider` est préchargé. Pas besoin d'`AsyncNotifier`.
- `LocaleNotifier` reste `Notifier<Locale>` mais dérive maintenant de `subSystemNotifierProvider` via `ref.watch`. Plus de `setLocale` exposé — la mutation passe par `subSystemNotifierProvider.notifier.set(...)`.

### SharedPreferences preload pattern (canonique Flutter+Riverpod)

C'est le pattern recommandé partout (Riverpod docs, Flutter community) :

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const MyApp(),
  ));
}

// providers.dart
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must override in main.dart');
});
```

L'`UnimplementedError` dans le `Provider` body est intentionnel — sert de **garde** : si quelqu'un oublie l'override (notamment dans les tests), la stacktrace pointe immédiatement vers la cause. Pattern moins fragile que `null` par défaut.

### Anonymous Auth — déjà acquise via _e0SmokeTest au boot

Le boot fait déjà :
1. `main.dart` ligne 33 : `unawaited(_bootstrap())`
2. `_bootstrap()` ligne 40 : `await Firebase.initializeApp(...)`
3. `_e0SmokeTest()` ligne 91 : `if (auth.currentUser == null) await auth.signInAnonymously();`

Donc au moment où l'utilisateur arrive sur la page de choix (généralement 2-5 s après le 1er tap sur l'icône, splash inclus), `FirebaseAuth.instance.currentUser?.uid` est non-null dans 99% des cas. Story 1.2 n'a PAS à re-déclencher `signInAnonymously()`.

**Edge case** : si Firebase init échoue (options stub, ou Firebase services indisponibles), `auth.currentUser` reste null. Story 1.2 doit fonctionner quand même :
- Persistance SharedPreferences OK (pas dépendant de Firebase)
- Navigation OK
- Le doc Firestore sera créé en Story 1.3 quand l'auth reviendra (linkWithCredential idempotent)

### Modale dans la langue courante (V1) — décision pragmatique

Story 1.2 affiche la modale de confirmation dans la LOCALE COURANTE (au moment du tap). Si l'utilisateur est en FR et tape "Anglophone", la modale est en FR. C'est suffisant pour V1 — le message est clair.

**V2 possible** (post-MVP) : afficher la modale dans la LANGUE CIBLE pour valider dans cette langue. Implique injection manuelle de `AppLocalizations` pour le subSystem cliqué (pas via `AppLocalizations.of(context)`). Pas la peine en V1.

### Responsive (NFR-17, ADR-011) — 3 form factors

- **Phone portrait < 600 dp** : padding latéral `AppSpacing.s5.w`, boutons sur toute la largeur disponible (avec `width: double.infinity` parent).
- **Phone landscape ou small tablet 600-840 dp** : idem phone portrait OK (peut être verrouillé portrait via `SystemChrome.setPreferredOrientations` si on veut être strict, mais hors scope 1.2).
- **Tablet ≥ 840 dp** : centrer le contenu avec `ConstrainedBox(maxWidth: 480.w)` ou `Center + SizedBox(width: ...)`. Pas de design splittée tablette en V1 (over-engineering — la page n'a que 2 boutons).

Exemple structure :

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final maxContentWidth = constraints.maxWidth >= 840
        ? 480.0
        : double.infinity;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.s5.w),
          child: Column(...),
        ),
      ),
    );
  },
)
```

### Previous Story Intelligence

**Story 1.1c (mergée 6913609)** — patterns réutilisés :

- `refreshListenable` `ValueNotifier<int>` + `ref.listen` qui incrémente — déjà en place dans `app_router.dart`. Étendre pour écouter `subSystemNotifierProvider` en plus.
- Bypass routes système dans le `redirect` (`/`, `/splash`, `/_*`) — préserver.
- `_bypassCatalogueCheck` override pattern en tests — Story 1.2 doit faire pareil pour `sharedPreferencesProvider` (override avec `SharedPreferences.setMockInitialValues({})` puis getInstance).

**Story 0.22 (mergée 0cd95e0)** — `SplashPage` à préserver :

- Animation 2100 ms (1800 stroke + 300 hold) — Story 1.2 ne touche PAS à la durée ni au visuel
- `FlutterNativeSplash.remove()` au postFrame — préserver
- `_kRouteAfterSplash` const → devient dynamique via ref.read

**Story 0.21 (mergée d67ccec)** — `_e0SmokeTest` acquiert Anonymous Auth au boot. Story 1.2 n'ajoute pas de signInAnonymously redondant.

**Story 0.16 (mergée 0bca01a)** — i18n FR/EN setup actif (`generate: true` + `intl 0.20.2` + `flutter_localizations`). Story 1.2 ajoute juste 6 clés.

**Story 0.13 (mergée c9605b1)** + **Story 0.14 (mergée 2adb38c)** — `AppButton` + `AppModal` disponibles. Story 1.2 les consomme, ne les modifie pas.

### Git intelligence (5 derniers commits)

```text
693d9ee Merge pull request #40 from DelRoos/feat/1.1b-script-python-seed-catalogue
bed762b feat(scripts): script Python seed Firestore catalogue (Story 1.1b)
0bec7d3 Merge pull request #39 from DelRoos/docs/cloture-1.1c-post-merge
9402abc Merge pull request #38 from DelRoos/docs/cloture-1.1c-post-merge
6913609 Merge pull request #37 from DelRoos/feat/1.1c-catalogue-repository-mobile
```

- Baseline : main à `693d9ee` (post merge 1.1b).
- Convention commit confirmée : `feat(scope): description FR à l'impératif (Story X.Y)`.
- Scope pour Story 1.2 : `onboarding` (premier usage — cohérent avec l'epic et CLAUDE.md liste autorisée).

### File List (estimation)

| Fichier | Type | LOC estimé |
|---|---|---|
| `mobile_app/lib/features/onboarding/domain/sub_system.dart` | NEW | ~30 |
| `mobile_app/lib/features/onboarding/data/subsystem_prefs.dart` | NEW | ~30 |
| `mobile_app/lib/features/onboarding/providers.dart` | NEW | ~40 |
| `mobile_app/lib/features/onboarding/presentation/subsystem_choice_page.dart` | NEW | ~140 |
| `mobile_app/lib/main.dart` | UPDATE | +5 (preload prefs + override) |
| `mobile_app/lib/app.dart` | UPDATE | ~10 (LocaleNotifier dérivé subSystem) |
| `mobile_app/lib/core/routing/app_router.dart` | UPDATE | +30 (route + redirect étendu + listen) |
| `mobile_app/lib/features/splash/presentation/splash_page.dart` | UPDATE | +5 (destination dynamique) |
| `mobile_app/lib/l10n/app_fr.arb` | UPDATE | +30 (6 clés + descriptions) |
| `mobile_app/lib/l10n/app_en.arb` | UPDATE | +12 (6 clés sans descriptions, vu pattern existant) |
| `mobile_app/test/features/onboarding/data/subsystem_prefs_test.dart` | NEW | ~30 |
| `mobile_app/test/features/onboarding/presentation/subsystem_choice_page_test.dart` | NEW | ~160 |
| `mobile_app/test/widget_test.dart` | UPDATE | +5 (override sharedPreferencesProvider) |
| `mobile_app/test/features/splash/splash_page_test.dart` | UPDATE | +5 |
| `mobile_app/test/features/catalogue/presentation/catalogue_waiting_page_test.dart` | UPDATE | +5 |

**Total estimé** : ~540 lignes diff total. Sous le seuil 500 (DoD) si on est strict — la marge est serrée. Possible légère dépassement justifié si tests bonus.

### References

- [Source: project_manage/planning-artifacts/epics/epic-1-onboarding.md § Story 1.2 lignes 339-426] — décomposition complète + AC + DoD original
- [Source: project_manage/planning-artifacts/prds/prd-valide-mvp-2026-06-03/prd.md § FR-1 ligne 111] — choix initial du sous-système au premier lancement
- [Source: project_manage/planning-artifacts/prds/prd-valide-mvp-2026-06-03/prd.md § NFR-14 ligne 714] — bilinguisme intégral
- [Source: project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/EXPERIENCE.md ligne 438] — Flow 1 étape 2 : « deux boutons primaires plein largeur, aucun défaut suggéré »
- [Source: project_manage/planning-artifacts/architecture/adrs/ADR-006-subsystem-fixed-at-signup.md] — sous-système figé définitivement à l'inscription
- [Source: project_manage/planning-artifacts/architecture/adrs/ADR-001-flutter-clean-architecture.md] — règle d'or des dépendances
- [Source: project_manage/planning-artifacts/architecture/adrs/ADR-011-cross-platform-v1-android-ios-tablet.md] — NFR-16 cross-platform + NFR-17 responsive
- [Source: mobile_app/lib/app.dart] — LocaleNotifier + localeProvider existants à modifier (T4)
- [Source: mobile_app/lib/main.dart] — boot Firebase + smoke test E0 (Anonymous Auth acquise) — T5 ajoute preload prefs
- [Source: mobile_app/lib/core/routing/app_router.dart] — pattern redirect global Story 1.1c — T6 étend
- [Source: mobile_app/lib/features/splash/presentation/splash_page.dart] — `_kRouteAfterSplash` hardcodé à rendre dynamique (T7)
- [Source: mobile_app/lib/core/widgets/app_modal.dart] — signature AppModal.show pour T8.4
- [Source: mobile_app/lib/core/widgets/app_button.dart] — AppButton.primary pour T8.3
- [Source: mobile_app/lib/core/firebase/providers.dart] — firebaseAuthProvider pour T8.4
- [Source: mobile_app/lib/l10n/app_fr.arb] — clés existantes `cancelLabel`, `continueLabel` à réutiliser
- [Source: mobile_app/pubspec.yaml] — `shared_preferences ^2.3.3` et `flutter_localizations` déjà installés

## Notes pour Amelia (dev agent)

### Anti-patterns à éviter (LLM disaster prevention)

- ❌ **NE PAS** créer une nouvelle classe `LocaleNotifier` — elle EXISTE déjà dans `lib/app.dart`. La modifier en place (T4).
- ❌ **NE PAS** créer un nouveau `localeProvider` — il EXISTE déjà.
- ❌ **NE PAS** créer un wrapper `Locale` séparé. `Locale` est `dart:ui`, utilisable directement.
- ❌ **NE PAS** modifier `splash_page.dart` au-delà de `_goNext()` et de la suppression de `_kRouteAfterSplash`. L'animation, le painter, les durées restent INTACTS (Story 0.22 préservée).
- ❌ **NE PAS** ajouter `signInAnonymously()` au tap « Continuer » — déjà fait au boot via `_e0SmokeTest`. Au mieux logger un boolean.
- ❌ **NE PAS** logger l'uid complet de l'utilisateur (CLAUDE.md § Sécurité interdit ce type de PII en logs locaux ou réseau).
- ❌ **NE PAS** chaîner en dur les strings dans le code Dart. **TOUT** passe par `AppLocalizations.of(context).keyName` (NFR-14). Si un test affiche une chaîne FR ou EN, c'est probablement un bug.
- ❌ **NE PAS** ajouter de nouvelle dépendance pubspec. `shared_preferences ^2.3.3` est déjà là (ligne 54). `flutter_localizations` + `intl 0.20.2` aussi. `firebase_auth` aussi.
- ❌ **NE PAS** modifier `firestore.rules` ni `firestore.indexes.json`. Story 1.2 ne touche PAS Firestore (le doc users/{uid} est créé en 1.3).
- ❌ **NE PAS** créer un fichier `lib/features/onboarding/index.dart` (barrel) inutile.
- ❌ **NE PAS** committer de fichier `.g.dart` ou `.freezed.dart` (pas utilisés dans ce projet — `freezed` absent du pubspec).
- ❌ **NE PAS** push direct sur main. Toujours par PR via la branche `feat/1.2-choix-sous-systeme-bascule-i18n`.
- ❌ **NE PAS** utiliser `--no-verify` même si un hook gît.
- ❌ **NE PAS** introduire de logique « langue dérive de la locale système » (Locale.system). Pas demandé par PRD/ADR. Le user choisit explicitement, point.
- ❌ **NE PAS** prévoir un toggle de langue ailleurs dans l'app (Profil settings, dashboard, etc.). ADR-006 INTERDIT.

### Patterns à suivre (best practice projet)

- ✅ **Identifiers en anglais, doc et commentaires en français** (CLAUDE.md § Workflow Git).
- ✅ **Conventional commits FR à l'impératif** : `feat(onboarding): choix sous-systeme immuable + bascule i18n runtime (Story 1.2)`. Co-Authored-By Claude Opus 4.7.
- ✅ **Responsive 3 form factors** : `LayoutBuilder` ou `MediaQuery.sizeOf(context).width`. Pas de pixel hardcodé.
- ✅ **`AppLocalizations.of(context)` PARTOUT** pour les strings utilisateur.
- ✅ **`AppButton.primary` enveloppé dans `SizedBox(width: double.infinity, ...)`** pour plein largeur (le composant n'a pas de prop fullWidth).
- ✅ **`AppModal.show()`** pour la modale de confirmation, pas `showDialog` brut.
- ✅ **`context.go()`** (pas `context.push()`) pour empêcher le back button de revenir au choix après confirmation.
- ✅ **Tests verts avant commit** : `flutter analyze` 0 issue + `flutter test` tous verts.

### Décisions techniques figées (ne pas re-discuter)

- **SharedPreferences preload** : oui, dans `main.dart` avant `runApp`, via `ProviderScope.overrides`. Justification : éviter le flash FR→EN au boot pour les anglophones.
- **`LocaleNotifier` dérive de `subSystemNotifierProvider`** : oui. Plus de `setLocale` exposé.
- **Route cible post-confirmation V1** : `/hello` (sentinelle existante). Sera remplacée par `/onboarding/profile/filiere` quand Story 1.3 sera livrée — Story 1.2 n'a pas à se préparer à ce changement (1.3 modifiera juste cette ligne).
- **Modale dans la locale courante** : oui (V1 pragmatique). V2 peut afficher dans la langue cible si demandé.
- **Pas de signInAnonymously redondant** : oui. Au mieux logger `auth.currentUser?.uid != null` comme boolean.
- **Tests existants adaptés** : oui. Pattern `_bypassCatalogueCheck` à étendre avec override `sharedPreferencesProvider`.
- **PR ≤ 500 lignes** : cible. Si dépassement justifié par scope + tests, documenter dans completion notes (précédent : Story 1.1c +1480 lignes justifié).

### Workflow git

1. Branche : `feat/1.2-choix-sous-systeme-bascule-i18n` depuis `main` à `693d9ee`
2. Commits intermédiaires OK (squash final au merge)
3. PR ciblant `main`
4. Pas de `--no-verify` (CLAUDE.md interdiction)
5. Co-Authored-By Claude Opus 4.7
6. PR ≤ 500 lignes diff

### Si Amelia a un doute

- **Sur la valeur `_kRouteAfterSplash` quand subSystem absent** : `/onboarding/subsystem`. C'est la seule destination logique au 1er lancement.
- **Sur le moment où Anonymous Auth est acquise** : au boot via `_e0SmokeTest()`. C'est asynchrone et peut ne pas être terminé quand l'utilisateur arrive sur la page de choix (rare, ~2-5 s après le boot). Si `auth.currentUser?.uid == null`, ne pas bloquer, juste logger.
- **Sur le format `Locale('fr')` vs `Locale('fr', 'FR')`** : utiliser `Locale('fr')` sans région (Flutter doc recommande). `supportedLocales` dans `AppLocalizations` actuellement définit fr et en (au lieu de fr_FR / en_US) — préserver.
- **Sur la structure responsive tablette** : option pragmatique = `Center + ConstrainedBox(maxWidth: 480.w)`. Option full : `LayoutBuilder` + breakpoint à 840 dp. Le choix dépend du style attendu — défaut : Center + ConstrainedBox suffit pour V1.
- **Sur les tests d'intégration kill+restart** : utiliser `SharedPreferences.setMockInitialValues({'subsystem': 'anglophone', 'language': 'en'})` et pumpWidget — ça simule un restart avec subSystem persisté.

### Si Amelia veut aller plus vite (optimisations autorisées)

- ✅ Utiliser le pattern `Notifier` (sync) plutôt que `AsyncNotifier` pour `SubSystemNotifier`. Plus simple, et le préchargement de SharedPreferences le permet.
- ✅ Mutualiser `_onTapFrancophone` et `_onTapAnglophone` en `_confirmChoice(SubSystem)` partagé.
- ✅ Tester `LocaleNotifier` indirectement via le widget test (vérifier que `MaterialApp.locale` change après le tap Continuer) plutôt qu'un test unitaire séparé.

### Questions ouvertes à signaler dans la PR (non bloquantes)

- 🟡 **Locale système initiale FR ou EN ?** : actuellement `LocaleNotifier.build()` défaut FR. Si user système EN tape sur Anglophone, OK pas de bascule. Si user système EN tape Francophone, l'app bascule en FR. Pas un bug, juste un comportement à valider en test device.
- 🟡 **`/catalogue-waiting` accessible sans subSystem** : la logique AC5 dit oui (subsystem prioritaire mais catalogue waiting bypass). Si l'edge case « user offline + vide catalogue + pas de subSystem » se présente, la modale et le texte de la page de choix doivent être disponibles offline (assets gen-l10n compilés dans l'app → OK natif).
- 🟡 **Performance preload SharedPreferences** : sur device entrée de gamme, `await SharedPreferences.getInstance()` peut prendre ~50-100 ms (vs ~10 ms sur device haut de gamme). C'est avant le 1er rendu — donc retarde l'apparition du splash de ~100 ms. Acceptable, mais à mesurer en validation device si > 200 ms (un native splash drawable XML est déjà affiché, donc l'utilisateur ne voit pas l'attente).

## Definition of Done

- [ ] `mobile_app/lib/features/onboarding/{domain,data,presentation,providers.dart}` créés (4 fichiers nouveaux)
- [ ] `mobile_app/lib/{main.dart,app.dart,core/routing/app_router.dart,features/splash/presentation/splash_page.dart}` modifiés (4 fichiers)
- [ ] `mobile_app/lib/l10n/app_fr.arb` + `app_en.arb` : 6 nouvelles clés
- [ ] 5+ tests verts (1 SubsystemPrefs unit + 4 SubsystemChoicePage widget)
- [ ] Tests existants adaptés avec override `sharedPreferencesProvider` (pattern Story 1.1c)
- [ ] `flutter analyze` 0 issue
- [ ] `flutter test` tous verts (no regression)
- [ ] (Si device dispo) Smoke device Fatou (Francophone) + James (Anglophone) — flow complet OK
- [ ] PR ≤ 500 lignes diff
- [ ] Commit `feat(onboarding): choix sous-systeme immuable + bascule i18n runtime (Story 1.2)` avec Co-Authored-By Claude Opus 4.7
- [ ] Branch `feat/1.2-choix-sous-systeme-bascule-i18n` poussée + PR créée
- [ ] `sprint-status.yaml` : `1-2-choix-sous-systeme-bascule-i18n: review` puis `done` après merge
- [ ] Story frontmatter mis à jour : `status: review` puis `done`, `merged: YYYY-MM-DD`, `merge_commit: <sha>`, `pr_number: <n>` après merge

## Dev Agent Record

### Agent Model Used

(à remplir lors de l'implémentation — ex. `Claude Opus 4.7 (claude-opus-4-7)`)

### Debug Log References

(à remplir si nécessaire — erreurs gen-l10n, conflits de tests, etc.)

### Completion Notes List

(à remplir : volumétrie finale, écarts vs spec, suggestions pour Story 1.2 v2)

### File List

(à remplir : liste des fichiers créés/modifiés)

### Change Log

(à remplir : | Date | Auteur | Modification |)

---

**Ultimate context engine analysis completed — comprehensive developer guide created.**

Cette story est `ready-for-dev`. Amelia (via `/bmad-dev-story`) a tout pour implémenter sans ambiguïté :
- Architecture clean 3 couches (domain enum + data SharedPreferences wrapper + presentation page + providers Riverpod)
- Pattern preload SharedPreferences avant runApp (canonique Flutter+Riverpod)
- Modification minimale du `LocaleNotifier` existant (dérive de subSystem)
- Conservation 100% du splash Story 0.22 (juste destination dynamique)
- Extension surgicale du redirect router (subsystem avant catalogue)
- 6 clés i18n FR+EN avec réutilisation `cancelLabel`/`continueLabel`
- 5 tests minimum + adaptation pattern `_bypassCatalogueCheck` Story 1.1c
- Anti-patterns LLM disaster prevention (pas de signInAnonymously redondant, pas de wrapper Locale, pas de toggle ailleurs)
- File List explicite par tâche
