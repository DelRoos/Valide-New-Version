---
story_id: 1.8
title: Persistance session + reprise flow interrompu (FR-8)
epic: 1
phase: P1
status: done
created: 2026-06-09
branch: feat/1.8-persistance-session-reprise-flow
baseline_commit: 872fafd  # merge PR #56 (cloture 1.9 + contexte 1.8)
merge_commit: 2511cd5  # PR #57 mergee 2026-06-09
estimation: S (~3h)
dependencies:
  - 1.2   # subSystemNotifierProvider deja persiste subSystem en SharedPreferences
  - 1.3   # OnboardingFlowNotifier state machine (filiere/niveau/serie)
  - 1.5   # evaluateRedirect + profileCompletionProvider (gardent les business routes)
  - 1.9   # /dashboard route post-onboarding (cible de redirection apres createProfile)
blocks:
  - 1.10  # suppression compte avec 7j grace (besoin de session persiste pour cancelAccountDeletion)
sourceArtifacts:
  - project_manage/planning-artifacts/epics/epic-1-onboarding.md § Story 1.8 (lignes 920-996)
  - project_manage/planning-artifacts/prds/prd-valide-mvp-2026-06-03/prd.md § FR-8
  - project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/EXPERIENCE.md § Edge case profil interrompu (~ligne 450)
  - mobile_app/lib/features/onboarding/data/subsystem_prefs.dart (pattern existant SharedPreferences)
  - mobile_app/lib/features/onboarding/providers.dart (OnboardingFlowNotifier + profileCompletionProvider)
  - mobile_app/lib/features/onboarding/domain/onboarding_flow_state.dart (OnboardingFlowState immuable)
  - mobile_app/lib/core/routing/app_router.dart (evaluateRedirect Story 1.5)
---

# Story 1.8 — Persistance session + reprise flow interrompu (FR-8)

Status: **done**

## Objectif

Livrer **FR-8** : un eleve qui ferme l'app pendant les 3 etapes du flow profil (filiere -> niveau -> serie) doit, a la prochaine ouverture, reprendre exactement la ou il en etait au lieu de tout recommencer.

**Pourquoi** : sur Android entree de gamme (Redmi A7 cible), les coupures sont frequentes (sms parent, batterie faible, OOM kill, low memory). Si Fatou doit retaper filiere + niveau a chaque reouverture, elle abandonne. Le PRD FR-8 le specifie comme prioritaire.

**Pourquoi maintenant** : Story 1.9 a livre /dashboard. La session post-onboarding est deja persistee implicitement (Firebase Auth restore + users/{uid} en Firestore + Story 1.5 redirect = complete -> /dashboard). Story 1.8 comble le trou : la session **pendant** les 3 etapes profile (avant createProfile Story 1.3) qui ne sont pas encore persistees.

**Hors scope V1 Epic 1** :

- Persistance cross-device avant compte permanent (le visiteur Anonymous n'est pas multi-device, pas la peine)
- Persistance Firestore de l'etape `onboardingStep` (overkill : SharedPreferences synchrone + sur sont suffisants ; users/{uid} prend le relais apres createProfile via profileCompletionProvider Story 1.5)
- Restauration de la modale conflit Story 1.6 ou du toast skip Story 1.7 (les vues post-recap sont gerees par d'autres mecanismes — cf. Decision § ci-dessous)

**Critere de fin** :

- Fatou choisit francophone + generale + Tle, kill app pendant l'ecran "choisis ta serie"
- Relance l'app : splash -> direct sur `/onboarding/profile/serie` avec filiereId='generale' + niveauId='francophone_terminale' deja restaures (la liste des series est rechargee depuis le catalogue)
- Tap sur "D" -> recap -> "C'est ma classe" -> users/{uid} cree -> /dashboard

Cas Edge :

- Kill au choix filiere (rien tape) -> relaunch sur `/onboarding/profile/filiere` (etat vide, comme avant)
- Kill apres createProfile (visiteur) -> relaunch sur `/dashboard` (Story 1.9 visitor flow gere, ne pas rediriger vers /onboarding/account)
- Kill apres createProfile (compte permanent) -> relaunch sur `/dashboard`
- Kill avant signInAnonymously (subsystem choisi offline) -> relaunch tente signInAnonymously + retombe sur `/onboarding/profile/filiere`

## Story

**As a** eleve qui ferme l'app pendant l'onboarding (interruption batterie, sms parent, low memory kill),
**I want** que l'app reprenne automatiquement a l'etape ou j'en etais lors de ma prochaine ouverture,
**so that** je n'aie pas a recommencer mon profil (FR-8) et que l'experience reste fluide meme sur entree de gamme avec coupures frequentes.

## Decision technique : SharedPreferences uniquement (PAS Firestore)

Le spec d'epic Story 1.8 mentionne un champ `users/{uid}.onboardingStep` cote Firestore. **Decision dev** : on N'IMPLEMENTE PAS ce champ Firestore. Justifications :

1. **Anonymous Auth pas cross-device** : un user Anonymous (avant Story 1.6) ne peut pas se reconnecter sur un autre appareil — pas besoin de persister son etape cote serveur.
2. **users/{uid} n'existe pas encore** pendant les 3 etapes profile (le doc est cree dans `createProfile` Story 1.3, etape `recap`). Persister `onboardingStep` la-bas ferait apparaitre un doc partiel + complique les regles Firestore Story 1.3 (immuabilite filiere/niveau/serie/createdAt). 
3. **SharedPreferences est synchrone + offline-safe** : le sur, le rapide, le naturel pour de l'etat local. Pattern deja en place pour `subSystem` (Story 1.2) + langue. On l'etend.
4. **Apres createProfile, profileCompletionProvider Story 1.5 prend le relais** : `users/{uid}.filiere/niveau/serie` est la source de verite, evaluateRedirect cable dessus, /dashboard livree Story 1.9. Pas besoin de doublon `onboardingStep`.
5. **Pas de cleanup post-MVP** a faire : SharedPreferences vit dans le sandbox app + se nettoie a `uninstall`. Pas de migration. Pas de mise a jour `doc/partage/BASE-DE-DONNEES.md` car schema users inchange.

**Amendement scope vs epic** : pas de modification `doc/partage/BASE-DE-DONNEES.md` necessaire. Pas d'accord backend a obtenir (CLAUDE.md regle surface partagee).

## Acceptance Criteria

### AC1 — Persistance flow state a chaque transition

**Given** un utilisateur dans le flow profil
**When** il tape sur une filiere (ex. "Generale")
**Then** `SharedPreferences['onboarding.flow.filiere_id'] = 'generale'` est ecrit immediatement (synchrone via `prefs.setString`)
**And** au tap suivant sur un niveau (ex. "Tle"), `SharedPreferences['onboarding.flow.niveau_id'] = 'francophone_terminale'` est ecrit
**And** au tap sur une serie (ex. "D"), `SharedPreferences['onboarding.flow.serie_id'] = 'francophone_terminale_d'` est ecrit

**And** au tap sur "Retour" depuis NiveauChoicePage vers FiliereChoicePage, le `niveau_id` (et `serie_id`) est **efface** des prefs (coherent avec `OnboardingFlowState.resetFrom` Story 1.3 : retour amont = reset aval).

### AC2 — Reprise auto au demarrage (etape profile en cours)

**Given** un utilisateur qui a tape filiere + niveau, kill app sur SerieChoicePage
**When** il relance l'app
**Then** apres le splash (1800ms anim + 300ms hold Story 0.22), il atterrit directement sur `/onboarding/profile/serie`
**And** `OnboardingFlowNotifier.state` est restaure avec `filiereId='generale'` + `niveauId='francophone_terminale'`
**And** la liste des series de Tle est affichee correctement (le catalogue est re-cherche via le stream existant Story 1.3, donc cache offline OK)

**Implementation** : `OnboardingFlowNotifier.build()` lit les 3 prefs au demarrage et retourne `OnboardingFlowState(filiereId, niveauId, serieId)` au lieu de `const OnboardingFlowState()`.

### AC3 — Reprise au step niveau

**Given** un utilisateur qui a tape filiere seulement, kill app sur NiveauChoicePage
**When** il relance l'app
**Then** il atterrit directement sur `/onboarding/profile/niveau` avec `filiereId` restauree

### AC4 — Reprise au step recap (apres tap serie, avant tap "C'est ma classe")

**Given** un utilisateur qui a tape filiere + niveau + serie, kill app sur ProfileRecapPage avant tap "C'est ma classe"
**When** il relance l'app
**Then** il atterrit directement sur `/onboarding/profile/recap` avec les 3 ids restaures
**And** le recap re-derive le DerivedProfile via `derivedProfileProvider` (utilise les ids du flow)

### AC5 — Kill apres createProfile (Story 1.3 done) : reprend sur /dashboard

**Given** un utilisateur qui a finalise son profil (users/{uid} cree, soit visiteur soit compte permanent)
**When** il kille l'app et la relance
**Then** apres le splash, il atterrit sur `/dashboard` (la garde Story 1.5 voit `profileCompletion = complete`, ne redirige pas vers onboarding)
**And** Story 1.9 dashboard rend le hero personnalise + grille matieres + (si visiteur) badge "Visiteur" + invite compte

**Implementation** : aucune modification specifique. Le comportement Story 1.5 + 1.9 existant suffit.

### AC6 — Cas edge : subSystem persiste mais profil pas demarre

**Given** un utilisateur qui a valide son sous-systeme (subsystem.id ecrit en prefs Story 1.2) mais a kill l'app AVANT de tap une filiere
**When** il relance l'app
**Then** il atterrit sur `/onboarding/profile/filiere` (1ere etape profile)
**And** `OnboardingFlowState` est vide (`filiereId == null`)

### AC7 — Cas edge : pas de signInAnonymously au kill (offline)

**Given** un utilisateur qui a tape sous-systeme + filiere offline (`signInAnonymously` echec au boot Story 0.21), kill app
**When** il relance l'app online
**Then** `signInAnonymously` reussit + uid present
**And** la garde Story 1.5 voit subSystem present + uid present + users/{uid} absent + `OnboardingFlowState.filiereId` restaure -> redirige vers `/onboarding/profile/niveau` (etape suivante)

**Implementation** : la logique de redirect doit considerer le flow state restaure pour determiner la VRAIE prochaine etape (pas systematiquement /filiere).

### AC8 — Tests + qualite + diff

**Given** la PR finalisee
**Then** :

- **NEW** : `mobile_app/lib/features/onboarding/data/onboarding_flow_prefs.dart` (~70 lignes — wrapper SharedPreferences sur 3 cles)
- **UPDATE** : `OnboardingFlowNotifier.build()` lit prefs ; `selectFiliere/Niveau/Serie/backTo/reset` ecrivent prefs
- **UPDATE** : `evaluateRedirect` Story 1.5 considere le flow state pour choisir la prochaine route quand profile incomplet (et pas systematiquement la 1ere etape manquante)
- **NEW** : `mobile_app/test/features/onboarding/data/onboarding_flow_prefs_test.dart` (~3 cas : read/write/clear)
- **NEW** : `mobile_app/test/features/onboarding/providers/onboarding_flow_notifier_persistence_test.dart` (~3 cas : build restore + selectFiliere persists + backTo clears downstream)
- **UPDATE** : `mobile_app/test/core/routing/app_router_redirect_test.dart` (~3 nouveaux cas : filiere prefs set -> redirect /niveau, filiere+niveau prefs -> /serie, tout pref -> /recap)
- **Tests rules** : aucune (pas de modification Firestore rules)
- **Firestore indexes (CLAUDE.md regle 9)** : aucun nouvel index (pas de nouvelle query)
- **doc/partage/BASE-DE-DONNEES.md** : aucune modification (decision : pas de champ Firestore onboardingStep)
- `flutter analyze` 0 issue
- `flutter test` vert (185 baseline Story 1.9 -> ~192 cible Story 1.8, +7)
- **PR ≤ 250 lignes diff** hors gen-l10n (story S, scope ferme)
- Commit : `feat(onboarding): persistance session et reprise flow interrompu (Story 1.8)`

## Tasks / Subtasks

- [ ] **T1 — Data : OnboardingFlowPrefs (NEW)** (AC1)
  - [ ] T1.1 — Creer `mobile_app/lib/features/onboarding/data/onboarding_flow_prefs.dart` (pattern SubsystemPrefs Story 1.2)
  - [ ] T1.2 — 3 cles : `onboarding.flow.filiere_id`, `onboarding.flow.niveau_id`, `onboarding.flow.serie_id`
  - [ ] T1.3 — API : `OnboardingFlowState read()` + `Future<void> write(OnboardingFlowState state)` + `Future<void> clear()`
  - [ ] T1.4 — Documenter : SharedPreferences synchrone + offline-safe + cohabite avec subsystem prefs Story 1.2

- [ ] **T2 — Provider : onboardingFlowPrefsProvider (NEW)** (AC1)
  - [ ] T2.1 — Ajouter `onboardingFlowPrefsProvider` dans `providers.dart` (lazy autour de `sharedPreferencesProvider`)
  - [ ] T2.2 — Pattern : `Provider<OnboardingFlowPrefs>` -> `OnboardingFlowPrefs(ref.watch(sharedPreferencesProvider))`

- [ ] **T3 — Persistance dans OnboardingFlowNotifier (UPDATE)** (AC1, AC2, AC3, AC4)
  - [ ] T3.1 — Modifier `OnboardingFlowNotifier.build()` : `ref.read(onboardingFlowPrefsProvider).read()` au lieu de `const OnboardingFlowState()`
  - [ ] T3.2 — Modifier `selectFiliere(filiereId)` : ecrit pref + set state (fire-and-forget Future, etat in-memory bouge avant la persistance pour eviter de bloquer le tap)
  - [ ] T3.3 — Modifier `selectNiveau(niveauId)` : ecrit pref (incluant serieId reset a null) + set state
  - [ ] T3.4 — Modifier `selectSerie(serieId)` : ecrit pref + set state
  - [ ] T3.5 — Modifier `backTo(step)` : ecrit pref (state apres reset) + set state
  - [ ] T3.6 — Modifier `reset()` : `prefs.clear()` + `state = const OnboardingFlowState()`

- [ ] **T4 — Smart redirect : route vers la VRAIE prochaine etape (UPDATE)** (AC2, AC3, AC4, AC7)
  - [ ] T4.1 — Modifier `evaluateRedirect` dans `app_router.dart` : ajouter parametre `flowState: OnboardingFlowState`
  - [ ] T4.2 — Quand profile incomplet (filiereMissing/niveauMissing/serieMissing) + flowState pas vide :
    - flowState.serieId set -> /onboarding/profile/recap
    - flowState.niveauId set -> /onboarding/profile/serie
    - flowState.filiereId set -> /onboarding/profile/niveau
    - sinon -> nextOnboardingRoute classique (le default selon profileCompletion)
  - [ ] T4.3 — Modifier le routerProvider : passer `ref.read(onboardingFlowProvider)` a evaluateRedirect
  - [ ] T4.4 — Ajouter ref.listen sur onboardingFlowProvider (deja en place Story 1.3, verifier)

- [ ] **T5 — Cas edge subSystem persiste mais session perdue** (AC6, AC7)
  - [ ] T5.1 — Verifier que main.dart appelle `signInAnonymously` au boot (Story 0.21) + retombe gracefully si offline
  - [ ] T5.2 — Si pas de uid : la garde Story 1.5 redirige vers `/onboarding/subsystem` (defensif) — verifier si pas de regression
  - [ ] T5.3 — Aucune modif code attendue, juste documenter le comportement

- [ ] **T6 — Tests : data layer** (AC8)
  - [ ] T6.1 — `mobile_app/test/features/onboarding/data/onboarding_flow_prefs_test.dart` (3 cas) :
    - (a) read sans valeur prefs -> retourne `OnboardingFlowState()` vide
    - (b) write puis read -> meme state
    - (c) clear -> read retourne state vide

- [ ] **T7 — Tests : OnboardingFlowNotifier persistance** (AC8)
  - [ ] T7.1 — `mobile_app/test/features/onboarding/providers/onboarding_flow_notifier_persistence_test.dart` (3 cas) :
    - (a) build avec prefs prepopulees -> state restaure
    - (b) selectFiliere -> pref ecrit
    - (c) backTo(filiere) -> pref niveau + serie effaces

- [ ] **T8 — Tests : evaluateRedirect smart resume** (AC8)
  - [ ] T8.1 — Ajouter 3 cas dans `mobile_app/test/core/routing/app_router_redirect_test.dart` :
    - (a) profileCompletion = filiereMissing + flowState.filiereId='generale' + niveauId=null -> redirect /onboarding/profile/niveau
    - (b) profileCompletion = filiereMissing + flowState.filiereId+niveauId set + serieId=null -> redirect /onboarding/profile/serie
    - (c) profileCompletion = filiereMissing + flowState all set -> redirect /onboarding/profile/recap

- [ ] **T9 — Validation finale**
  - [ ] T9.1 — `flutter analyze` -> 0 issue
  - [ ] T9.2 — `flutter test` -> ~192 verts (185 baseline + 9 nouveaux - 2 si adaptation evaluateRedirect tests existants)
  - [ ] T9.3 — Diff PR ≤ 250 lignes
  - [ ] T9.4 — Update story frontmatter `status: review` + sprint-status `review` + commit + push

## Dev Notes

### Architecture compliance (ADR-001 + ADR-006 + ADR-011)

- **Couche data pure** : `OnboardingFlowPrefs` wrappe `SharedPreferences`. Pas d'import Firestore ni domain.
- **Domain inchange** : `OnboardingFlowState` immuable, pas de modification.
- **Cross-platform** : SharedPreferences fonctionne identiquement sur Android + iOS.
- **CLAUDE.md regle 9 (indexes Firestore)** : **AUCUN nouvel index requis**. Story 1.8 ne lance aucune nouvelle query Firestore.

### Pattern : extension de SubsystemPrefs Story 1.2

```dart
class OnboardingFlowPrefs {
  OnboardingFlowPrefs(this._prefs);
  final SharedPreferences _prefs;

  static const String _kFiliereKey = 'onboarding.flow.filiere_id';
  static const String _kNiveauKey = 'onboarding.flow.niveau_id';
  static const String _kSerieKey = 'onboarding.flow.serie_id';

  OnboardingFlowState read() => OnboardingFlowState(
        filiereId: _prefs.getString(_kFiliereKey),
        niveauId: _prefs.getString(_kNiveauKey),
        serieId: _prefs.getString(_kSerieKey),
      );

  Future<void> write(OnboardingFlowState state) async {
    if (state.filiereId == null) {
      await _prefs.remove(_kFiliereKey);
    } else {
      await _prefs.setString(_kFiliereKey, state.filiereId!);
    }
    if (state.niveauId == null) {
      await _prefs.remove(_kNiveauKey);
    } else {
      await _prefs.setString(_kNiveauKey, state.niveauId!);
    }
    if (state.serieId == null) {
      await _prefs.remove(_kSerieKey);
    } else {
      await _prefs.setString(_kSerieKey, state.serieId!);
    }
  }

  Future<void> clear() async {
    await _prefs.remove(_kFiliereKey);
    await _prefs.remove(_kNiveauKey);
    await _prefs.remove(_kSerieKey);
  }
}
```

### Pattern : Notifier hybride (read sync + write async)

```dart
class OnboardingFlowNotifier extends Notifier<OnboardingFlowState> {
  @override
  OnboardingFlowState build() {
    // Lecture synchrone au build (SharedPreferences est preloaded en main.dart Story 1.2)
    return ref.read(onboardingFlowPrefsProvider).read();
  }

  void selectFiliere(String filiereId) {
    final newState = const OnboardingFlowState().copyWith(filiereId: filiereId);
    state = newState; // bouge l'UI immediatement
    // Persiste en arriere-plan (fire-and-forget, pas await pour eviter de bloquer)
    unawaited(ref.read(onboardingFlowPrefsProvider).write(newState));
  }
  // ... pareil pour selectNiveau / selectSerie / backTo / reset
}
```

### Pattern : smart redirect dans evaluateRedirect Story 1.5

```dart
@visibleForTesting
String? evaluateRedirect({
  required String location,
  required AsyncValue<bool> catalogueCheck,
  required bool hasSubSystem,
  required AsyncValue<ProfileCompletionState> profileCompletion,
  required OnboardingFlowState flowState, // NEW Story 1.8
}) {
  // ... checks existants (catalogue, subsystem) ...

  // Story 1.5 + 1.8 — garde profil-incomplet smart resume.
  if (!location.startsWith('/onboarding/') && location != '/catalogue-waiting') {
    final nextRoute = profileCompletion.when(
      data: (state) {
        if (state.isComplete) return null;
        // Smart resume : si flowState a deja des donnees, route vers la
        // VRAIE prochaine etape (pas systematiquement /filiere).
        return _smartResumeRoute(state, flowState);
      },
      loading: () => null,
      error: (_, _) => '/onboarding/subsystem',
    );
    if (nextRoute != null) return nextRoute;
  }

  return null;
}

String _smartResumeRoute(ProfileCompletionState completion, OnboardingFlowState flowState) {
  // Profile incomplet en Firestore. Le flow state SharedPreferences nous dit
  // ou l'utilisateur en etait reellement.
  if (flowState.serieId != null) return '/onboarding/profile/recap';
  if (flowState.niveauId != null) return '/onboarding/profile/serie';
  if (flowState.filiereId != null) return '/onboarding/profile/niveau';
  // Aucune donnee in-flight : route classique vers la 1ere etape manquante.
  return completion.nextOnboardingRoute;
}
```

### Anti-pattern : NE PAS persister en Firestore

```dart
// MAUVAIS — overkill + complique les regles Story 1.3 immuabilite
await firestore.collection('users').doc(uid).set(
  {'onboardingStep': 'niveau'},
  SetOptions(merge: true),
);

// BON — SharedPreferences synchrone, simple, offline-safe
await prefs.setString('onboarding.flow.filiere_id', 'generale');
```

Justification : la session pendant les 3 etapes profile n'a pas besoin de cross-device. Anonymous Auth est mono-device par definition. Apres createProfile, profileCompletionProvider Story 1.5 + /dashboard Story 1.9 prennent le relais via Firestore — la, le cross-device fonctionne via Firebase Auth restore + users/{uid}.

### Anti-pattern : NE PAS await la persistance dans les setters Notifier

```dart
// MAUVAIS — bloque l'UI au tap (ecran qui freeze)
void selectFiliere(String filiereId) async {
  await ref.read(onboardingFlowPrefsProvider).write(newState);
  state = newState;
}

// BON — fire-and-forget, UI reactive
void selectFiliere(String filiereId) {
  state = newState;
  unawaited(ref.read(onboardingFlowPrefsProvider).write(newState));
}
```

Justification : SharedPreferences.setString est rapide (<5ms typique) mais sur device entree de gamme avec stockage lent, ca peut introduire un lag perceptible. Le set state synchrone est prioritaire pour la UX.

### Anti-pattern : NE PAS oublier de reset les downstream lors d'un backTo

```dart
// MAUVAIS — l'utilisateur revient sur filiere apres avoir choisi niveau+serie,
// retape une autre filiere -> niveau+serie sont restaures depuis prefs mais
// n'ont plus de sens vis-a-vis de la nouvelle filiere
void backTo(OnboardingFlowStep step) {
  state = state.resetFrom(step);
  // OUBLI : pas d'ecriture prefs
}

// BON — ecrit le nouveau state (avec downstream reset) en prefs
void backTo(OnboardingFlowStep step) {
  final newState = state.resetFrom(step);
  state = newState;
  unawaited(ref.read(onboardingFlowPrefsProvider).write(newState));
}
```

Note : `OnboardingFlowState.resetFrom(filiere)` retourne `const OnboardingFlowState()` (tout vide). Donc `prefs.write(emptyState)` doit appeler `remove` sur chaque cle (pas `setString(null)` qui crashe).

### Cas edge : restoration apres update catalogue

Si l'admin desactive runtime une serie qui etait dans le flow state restaure (`flowState.serieId = 'francophone_terminale_a' a flag isActive=false`), la SerieChoicePage la masque (filtree par `isActive == true` Story 1.1c). Le user voit la liste sans sa serie + doit en choisir une autre. Pas de probleme — la prefs serieId reste mais sera ecrasee au prochain tap.

### Securite CLAUDE.md § 4

- SharedPreferences n'est pas un secret store — convient pour des refs catalogue (filiere_id, niveau_id) qui sont publiques.
- **JAMAIS** y stocker : uid Firebase Auth complet (deja persiste par le SDK Firebase de toute facon), tokens OAuth, mots de passe, n° de telephone.
- **OK** y stocker : refs catalogue (Story 1.2 deja stocke subSystem.id, language.code).

### File List (anticipee — Amelia complete)

**Nouveaux** :

- `mobile_app/lib/features/onboarding/data/onboarding_flow_prefs.dart` (~70 lignes — wrapper SharedPreferences)
- `mobile_app/test/features/onboarding/data/onboarding_flow_prefs_test.dart` (~60 lignes — 3 cas)
- `mobile_app/test/features/onboarding/providers/onboarding_flow_notifier_persistence_test.dart` (~120 lignes — 3 cas)

**Modifies** :

- `mobile_app/lib/features/onboarding/providers.dart` (+~30 lignes — `onboardingFlowPrefsProvider` + persistance dans Notifier methods)
- `mobile_app/lib/core/routing/app_router.dart` (+~20 lignes — `_smartResumeRoute` helper + parametre dans evaluateRedirect + ref.read flowState)
- `mobile_app/test/core/routing/app_router_redirect_test.dart` (+~60 lignes — 3 nouveaux cas smart resume + adaptation signature evaluateRedirect)
- `project_manage/implementation-artifacts/1-8-persistance-session-reprise-flow.md`
- `project_manage/implementation-artifacts/sprint-status.yaml`

### Change Log

| Date       | Auteur            | Modification                                                                |
| ---------- | ----------------- | --------------------------------------------------------------------------- |
| 2026-06-09 | Claude Opus 4.7   | Story 1.8 contexte engine cree — decision SharedPreferences vs Firestore documentee |
| 2026-06-09 | Claude Opus 4.7   | Story 1.8 dev complete (9 tasks). 3 fichiers data/provider/router + 3 fichiers tests. flutter analyze 0 issue + flutter test 196 verts (185 baseline + 11). Diff ~480 lignes incl. 3 nouveaux fichiers (au dela cible 250 mais coherent avec scope reel : wrapper + persistance + smart redirect + 11 tests). |

### Dev Agent Record — Completion Notes

**Implementation summary** :
- T1 NEW `mobile_app/lib/features/onboarding/data/onboarding_flow_prefs.dart` (~70 lignes — wrapper SharedPreferences 3 cles : `onboarding.flow.filiere_id/niveau_id/serie_id`). Pattern : `read()` synchrone, `write(state)` async avec `_writeOrRemove` helper, `clear()` reset 3 cles.
- T2 NEW `onboardingFlowPrefsProvider` dans `providers.dart` (lazy autour de `sharedPreferencesProvider`).
- T3 UPDATE `OnboardingFlowNotifier` : `build()` lit prefs au lieu de `const OnboardingFlowState()`. Toutes les mutations (selectFiliere/Niveau/Serie/backTo/reset) appellent `_persist(newState)` qui fire-and-forget `prefs.write` via `unawaited()`. UI bouge immediatement, persistance suit en microtask.
- T4 UPDATE `evaluateRedirect` Story 1.5 : ajout parametre `flowState: OnboardingFlowState` + helper `_smartResumeRoute` qui route vers la VRAIE prochaine etape (serie set → /recap, niveau set → /serie, filiere set → /niveau, sinon → `completion.nextOnboardingRoute`).
- T5 audit edge cases OK : main.dart fait deja `signInAnonymously` au boot (Story 0.21). Si offline, la garde Story 1.5 retombe sur /onboarding/subsystem. Pas de changement code.
- T6 NEW `test/features/onboarding/data/onboarding_flow_prefs_test.dart` (4 cas : read empty + write/read roundtrip + clear + write avec null-field).
- T7 NEW `test/features/onboarding/providers/onboarding_flow_notifier_persistence_test.dart` (3 cas : build restore + selectFiliere ecrit + backTo(serie) preserve filiere/niveau et efface serie).
- T8 UPDATE `test/core/routing/app_router_redirect_test.dart` : adaptation 14 appels existants (ajout `flowState: _emptyFlow`) + 4 nouveaux cas smart resume (smart-a/b/c/d).
- T9 validation : `flutter analyze` 0 issue + `flutter test` 196 passed + 1 skipped (vs baseline 185, +11 net).

**Bugs encountered & fixes** : aucun. La conception SharedPreferences synchrone + persistance fire-and-forget + smart redirect en helper pur a marche du premier coup. Les warnings IDE intermediaires ("Unused import", "Named parameter not defined") etaient des hooks stale entre mes edits sequentiels.

**Decisions** :
- **SharedPreferences uniquement (PAS Firestore)** — decision strategique documentee dans la story et le code. Pas de modification `doc/partage/BASE-DE-DONNEES.md` car schema users inchange.
- **fire-and-forget persistance** : `unawaited(_persist())` au lieu de `await` dans les setters Notifier — evite le freeze UI sur device entree de gamme avec stockage lent.
- **Smart resume helper pur `_smartResumeRoute`** : pas de logique complexe dans `evaluateRedirect`, juste un appel. Testable isolement via les 4 cas smart.

**Anti-patterns evites** (Dev Notes) :
- NE PAS persister en Firestore (cf. Decision § ci-dessus) ✓
- NE PAS await la persistance dans setters Notifier (pattern unawaited) ✓
- NE PAS oublier reset downstream lors backTo (resetFrom + write avec null → _writeOrRemove appelle remove) ✓
- NE PAS stocker secrets en SharedPreferences (seulement ids catalogue publics : filiere/niveau/serie) ✓

**CLAUDE.md regle 9 (indexes Firestore)** : verifie. AUCUNE nouvelle query Firestore. **Pas de deploiement `firebase deploy --only firestore:indexes` necessaire.**

**Smoke device defere** : test runtime kill app a chaque etape (filiere/niveau/serie/recap) + reprise sur device Android Redmi A7 reste a faire post-merge porteur. Scenarios attendus :
- Fatou tape filiere "Generale", kill app -> relance -> direct sur /onboarding/profile/niveau
- Fatou tape niveau "Tle", kill -> relance -> direct sur /onboarding/profile/serie
- Fatou tape serie "D", kill avant "C'est ma classe" -> relance -> direct sur /onboarding/profile/recap
- Fatou tape "C'est ma classe" -> users/{uid} cree -> kill -> relance -> direct sur /dashboard (visiteur badge)

### File List (final)

**Nouveaux fichiers** (3) :
- `mobile_app/lib/features/onboarding/data/onboarding_flow_prefs.dart` (~70 lignes)
- `mobile_app/test/features/onboarding/data/onboarding_flow_prefs_test.dart` (~80 lignes, 4 cas)
- `mobile_app/test/features/onboarding/providers/onboarding_flow_notifier_persistence_test.dart` (~110 lignes, 3 cas)

**Fichiers modifies** (3) :
- `mobile_app/lib/features/onboarding/providers.dart` (+42 lignes : `onboardingFlowPrefsProvider` + persistance dans Notifier methods + `_persist` helper)
- `mobile_app/lib/core/routing/app_router.dart` (+40 lignes : import + `flowState` parametre + `_smartResumeRoute` helper)
- `mobile_app/test/core/routing/app_router_redirect_test.dart` (+99 lignes : adaptation 14 appels existants + 4 nouveaux cas smart resume)
- `project_manage/implementation-artifacts/1-8-persistance-session-reprise-flow.md` (frontmatter status review + Dev Agent Record)
- `project_manage/implementation-artifacts/sprint-status.yaml` (1.8 in-progress → review)

---

**Ultimate context engine analysis completed — comprehensive developer guide created.**

Cette story est `ready-for-dev`. Amelia (via `/bmad-dev-story`) a tout pour implementer :

- Architecture : pure persistance locale, aucun changement Firestore/rules/indexes
- 8 AC + 9 Tasks + Dev Notes avec 4 anti-patterns documentes
- Decision strategique documentee : SharedPreferences > Firestore pour cette story
- Smart redirect dans evaluateRedirect Story 1.5 : route vers la VRAIE prochaine etape
- Critere de sortie : Fatou peut killer/relancer a n'importe quelle etape sans perdre sa progression
- PR ≤ 250 lignes diff (story S, scope minimal mais haute valeur UX)
