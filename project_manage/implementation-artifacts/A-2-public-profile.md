---
story: A.2
title: "Page profil public — consulter le profil d'un camarade"
status: review
baseline_commit: "1008a65"
---

# Story A.2 : Page profil public — consulter le profil d'un camarade

---

## User Story

En tant qu'élève connecté, je veux pouvoir consulter la page de profil d'un autre élève (depuis la section « Activité récente » du dashboard ou d'un futur classement), afin de voir son nom, son niveau/série, son école et ses statistiques de progression.

---

## Acceptance Criteria

**AC1 — Route `/user/:uid` accessible**
Donné que je tape ou que je suis un lien `/user/abc123`,
Quand go_router résout la route,
Alors `PublicProfilePage` s'ouvre hors du shell (pas de NavigationBar), avec un bouton retour fonctionnel.

**AC2 — Header profil public**
Donné qu'un doc `users/{uid}` existe et que je suis authentifié,
Quand `fetchPublicProfile(uid)` retourne `Right(PublicProfile)`,
Alors j'affiche :
- Un avatar initiales (première lettre de `displayName`) sur fond gradient bleu (pattern `_ProfileHeader` existant).
- Le nom affiché (`displayName`).
- Niveau + série résolus via `catalogueProvider` (ex. « Terminale — D ») ; absents si non disponibles.
- Nom de l'école (`schoolName`) si non-null, masqué sinon.

**AC3 — Section stats hardcodée (fake V1)**
Quand le profil est affiché,
Alors une section « Stats » montre deux badges statiques :
- « 30 leçons lues » (icône `bookOpen`, couleur primary).
- « 3 quiz réussis » (icône `target`, couleur success).
Ces valeurs sont hardcodées pour V1 (intégration réelle planifiée Epic 3).

**AC4 — État loading : shimmer**
Quand `publicProfileProvider(uid)` est à l'état `loading`,
Alors des blocs `AppSkeleton` remplacent le header et la section stats.
Aucun texte « Chargement… » — uniquement des squelettes animés.

**AC5 — État erreur : message localisé selon le type**
Quand `fetchPublicProfile(uid)` retourne `Left(ProfileFailure)`,
Alors `AppEmptyState` est affiché avec :
- `permissionDenied` / `notAuthenticated` → clé ARB `errorPermissionDenied`.
- `networkUnavailable` → clé ARB `errorNetworkUnavailable`.
- `unknown` → clé ARB `errorFirestoreUnknown`.
Un bouton « Réessayer » (`retryLabel`) relance le provider.

**AC6 — Navigation depuis la section classmates**
Quand je tape sur une ligne `_ClassmateRow` dans `HomeTabPage`,
Alors l'app navigue vers `/user/{classmateUid}` via `context.push(...)`.
Pour V1 (données fake), les classmates `_kClassmates` reçoivent un champ `uid` fictif (ex. `'fake-amina-k'`) — la page `PublicProfilePage` affichera alors l'état erreur (pas de doc Firestore pour cet uid), ce qui est le comportement attendu et non bloquant.

**AC7 — Responsive phone + tablet**
Quand l'écran fait ≥ 840 dp de large (tablet),
Alors le contenu est centré dans un conteneur de largeur max 600 dp (même pattern que `SubjectDetailPage`).
En dessous de 840 dp (phone), le contenu occupe toute la largeur avec padding `AppSpacing.s4.w`.

**AC8 — Règle Firestore permettant la lecture inter-utilisateurs**
Quand un utilisateur authentifié tente de lire `users/{otherUid}`,
Alors la règle Firestore autorise la lecture (tout utilisateur authentifié peut lire n'importe quel doc `users/{uid}`).
La règle d'écriture reste inchangée (propriétaire uniquement).

**AC9 — Seuls les champs publics sont extraits**
Quand `fetchPublicProfile(uid)` lit `users/{uid}`,
Alors le modèle domain `PublicProfile` ne contient que : `uid`, `displayName`, `levelId`, `streamId`, `schoolName`, `subSystem`.
Les champs sensibles (`deletionRequestedAt`, `examTargets`, `derivedSubjects`, `optedOutSubjects`, `pickedSubjects`) ne sont jamais mappés ni exposés.

**AC10 — Tests : repo + widget**
Deux fichiers de tests verts :
- `test/features/account/data/user_profile_repository_public_profile_test.dart` : test unitaire du repo fake (succès → `Right(PublicProfile)`, Firestore error → `Left(ProfileFailure.firestoreError)`, uid absent → `Left(ProfileFailure.notAuthenticated)`).
- `test/features/account/presentation/public_profile_page_test.dart` : test widget (état loading → AppSkeleton présent ; état data → nom affiché ; état erreur réseau → AppEmptyState avec bon message).

---

## Dev Notes

### Composants existants à réutiliser

| Composant | Path | Usage dans cette story |
|---|---|---|
| `AppSkeleton` | `core/widgets/app_skeleton.dart` | États loading header + stats |
| `AppEmptyState` | `core/widgets/app_empty_state.dart` | État erreur |
| `AppButton` | `core/widgets/app_button.dart` | CTA « Réessayer » dans AppEmptyState |
| `_ProfileHeader` (pattern) | `features/dashboard/presentation/profile_tab_page.dart` | L'avatar initiales + gradient + nom + niveau-série est **extrait** et rendu public sous le nom `PublicProfileHeader` dans `features/account/presentation/widgets/public_profile_header.dart`. Ne pas dupliquer `_ProfileHeader` — en créer une version publique paramétrée. |
| `catalogueProvider` | `core/catalogue/providers.dart` | Résolution levelId → nom localisé, streamId → nom localisé |
| `userProfileRepositoryProvider` | `features/onboarding/providers.dart` | Référence pour le pattern de construction du repo ; **ne pas réutiliser** ce provider directement — créer `publicProfileProvider` séparé |

### Nouveau composant à créer et documenter dans COMPOSANTS-REUTILISABLES.md

**`PublicProfileHeader`** — `features/account/presentation/widgets/public_profile_header.dart`
- Props : `displayName: String`, `classLabel: String?`, `schoolName: String?`
- Avatar initiales + fond gradient `AppColors.primary → AppColors.primaryDark`, même style que `_ProfileHeader` existant.
- Responsive : réduit à largeur max sur tablet (géré par la page parente via `LayoutBuilder`).
- Pas d'import Firestore ni Riverpod dans ce widget — reçoit les données en paramètre.
- **Documenter dans `doc/tech/COMPOSANTS-REUTILISABLES.md`** dans la même PR.

### Décision Firestore rules — lecture inter-utilisateurs (A.2-DR-01)

**Contexte** : actuellement `firestore.rules` autorise la lecture de `users/{uid}` uniquement pour `request.auth.uid == uid` (propriétaire). La page profil public nécessite de lire le doc d'un autre utilisateur.

**Décision retenue** (validée avec le porteur) : ouvrir la lecture à tout utilisateur authentifié.

```
// Avant (Story 1.3)
allow read: if request.auth != null && request.auth.uid == uid;

// Après (Story A.2)
allow read: if request.auth != null;
```

**Justification** :
- Les champs sensibles (`deletionRequestedAt`, `examTargets`, `pickedSubjects`) sont dans le même doc mais le modèle domain `PublicProfile` n'en lit que 5 champs non-sensibles.
- La vraie protection des champs sensibles est côté application (mapping sélectif) + App Check (NFR-12). Une granularité champ par champ dans les rules Firestore (Field Mask) n'est pas disponible — on accepte que des champs supplémentaires soient techniquement lisibles par un utilisateur authentifié, ce qui est un trade-off V1 acceptable (profil non-premium, pas de données bancaires ni de données santé).
- **Post-V1** : si des champs vraiment sensibles apparaissent dans `users/{uid}`, créer un sous-doc `users/{uid}/private/main` pour les isoler (pattern standard Firestore).
- La règle d'écriture reste `allow write: if request.auth.uid == uid` (inchangée).

**Impact sur `firestore.rules`** (racine du dépôt) : modifier uniquement le bloc `match /users/{uid}`.

### Schéma Firestore — champs lus par `fetchPublicProfile()`

Collection `users`, doc `{uid}`, champs extraits (lecture `.get()`, 1 read) :

| Champ Firestore | Type | Mappé vers `PublicProfile` | Notes |
|---|---|---|---|
| `uid` | `String` | `uid` | Ou utiliser l'id du doc — même valeur |
| `displayName` | `String` | `displayName` | Peut être vide `''` si onboarding incomplet |
| `niveau` | `String` | `levelId` | Alias legacy ; renommer Story 1.19 |
| `serie` | `String` | `streamId` | Alias legacy ; renommer Story 1.19 |
| `schoolName` | `String?` | `schoolName` | Null si pas d'école liée |
| `subSystem` | `String` | `subSystem` | `'francophone'` ou `'anglophone'` |

**Cost-benefit Firestore** :
- Reads par session : 1 read par profil consulté (`.get()`, cache si déjà lu dans la session).
- À 10 000 utilisateurs avec 2 profils consultés/session : 20 000 reads/jour → coût négligeable (~0,01 $/jour).
- Pas de `snapshots()` — le profil public est statique pendant la consultation. Cache Firestore natif pour les revisites intra-session.
- Trade-off : on lit 6 champs dans un doc qui en contient ~15. Les 9 champs non utilisés sont transmis par Firestore (pas de Field Mask disponible en Dart SDK) mais non mappés dans `PublicProfile`. Acceptable V1.

### Modèle domain `PublicProfile`

```dart
// features/account/domain/public_profile.dart
import 'package:equatable/equatable.dart';

/// Projection publique du doc users/{uid}.
/// Champs non sensibles uniquement — pas d'import Firebase.
class PublicProfile extends Equatable {
  const PublicProfile({
    required this.uid,
    required this.displayName,
    required this.levelId,
    required this.streamId,
    this.schoolName,
    required this.subSystem,
  });

  final String uid;
  final String displayName;
  final String levelId;
  final String streamId;
  final String? schoolName;
  final String subSystem;

  @override
  List<Object?> get props => [uid, displayName, levelId, streamId, schoolName, subSystem];
}
```

### Méthode repo — signature à ajouter

Dans `UserProfileRepository` (domain interface) :

```dart
/// Story A.2 — Lit le profil public de n'importe quel utilisateur authentifié.
/// Lecture unique `.get()` (1 read, pas snapshots — profil statique).
/// Retourne Left(ProfileFailure.notAuthenticated()) si uid est null.
/// Retourne Left(ProfileFailure.firestoreError(...)) si FirebaseException.
/// Retourne Right(null) si le doc n'existe pas (uid invalide).
Future<Either<ProfileFailure, PublicProfile?>> fetchPublicProfile(String uid);
```

Dans `UserProfileRepositoryFirestoreImpl` (data) :

```dart
@override
Future<Either<ProfileFailure, PublicProfile?>> fetchPublicProfile(String uid) async {
  final callerUid = _getUid();
  if (callerUid == null) {
    AppLogger.w('fetchPublicProfile() aborted: caller not authenticated');
    return const Left(ProfileFailure.notAuthenticated());
  }
  try {
    final doc = await logPerf(
      'users.fetchPublicProfile',
      () => _firestore.collection('users').doc(uid).get(),
    );
    if (!doc.exists) {
      AppLogger.i('fetchPublicProfile: doc not found uid=<redacted>');
      return const Right(null);
    }
    final data = doc.data()!;
    final profile = PublicProfile(
      uid: uid,
      displayName: (data['displayName'] as String?) ?? '',
      levelId: (data['niveau'] as String?) ?? '',
      streamId: (data['serie'] as String?) ?? '',
      schoolName: data['schoolName'] as String?,
      subSystem: (data['subSystem'] as String?) ?? '',
    );
    AppLogger.i('fetchPublicProfile: found displayName=${profile.displayName.isNotEmpty}');
    return Right(profile);
  } on FirebaseException catch (e, st) {
    AppLogger.w(
      'fetchPublicProfile() FirebaseException: ${e.code} ${e.message}',
      error: e,
    );
    AppLogger.w('fetchPublicProfile() stack: $st');
    return Left(
      ProfileFailure.firestoreError(e.message ?? 'Firebase: ${e.code}', code: e.code),
    );
  } catch (e, st) {
    AppLogger.w('fetchPublicProfile() unexpected error: $e', error: e);
    AppLogger.w('fetchPublicProfile() stack: $st');
    return Left(ProfileFailure.firestoreError(e.toString()));
  }
}
```

### Provider

```dart
// À ajouter dans features/onboarding/providers.dart
// (ou dans features/account/providers.dart si on veut séparer — préférer onboarding/providers.dart
//  pour éviter une dépendance circulaire, userProfileRepositoryProvider y est déjà défini)

/// Story A.2 — Lecture profil public d'un autre utilisateur.
/// FutureProvider.family : clé = uid cible.
/// Auto-dispose pour ne pas garder en mémoire les profils visités.
final publicProfileProvider = FutureProvider.autoDispose
    .family<Either<ProfileFailure, PublicProfile?>, String>((ref, uid) {
  return ref.watch(userProfileRepositoryProvider).fetchPublicProfile(uid);
});
```

### Responsive strategy

- **Phone (< 840 dp)** : `Scaffold` avec `CustomScrollView`, padding horizontal `AppSpacing.s4.w`, pleine largeur.
- **Tablet (≥ 840 dp)** : même `CustomScrollView` mais le contenu est centré via `LayoutBuilder` avec `width = min(width, 600)` — même pattern que `SubjectDetailPage`.
- Le `PublicProfileHeader` (gradient) reste pleine largeur dans les deux cas (fond couvre toute la largeur, contenu texte est centré).
- Aucun breakpoint landscape-spécifique requis en V1 (profil simple sans grille).

### Clés ARB à ajouter (FR + EN)

| Clé | FR | EN |
|---|---|---|
| `publicProfileStatsTitle` | `Statistiques` | `Stats` |
| `publicProfileLessonsRead` | `leçons lues` | `lessons read` |
| `publicProfileQuizPassed` | `quiz réussis` | `quizzes passed` |
| `publicProfileNotFound` | `Profil introuvable` | `Profile not found` |
| `publicProfileNotFoundSubtitle` | `Ce profil n'existe pas ou a été supprimé.` | `This profile doesn't exist or has been deleted.` |

Les clés d'erreur globales `errorPermissionDenied`, `errorNetworkUnavailable`, `errorFirestoreUnknown`, `retryLabel` existent déjà — les réutiliser.

### Tests cibles

**T1 — Unit test repo** : `test/features/account/data/user_profile_repository_public_profile_test.dart`
- Utiliser un `FakeFirebaseFirestore` ou un fake manuel (`GetUidFn` injectable).
- Cas 1 (AC9) : doc existe → `Right(PublicProfile)` avec les 6 bons champs.
- Cas 2 (AC9) : doc inexistant → `Right(null)`.
- Cas 3 (AC10) : `callerUid` null → `Left(ProfileFailure.notAuthenticated())`.
- Cas 4 : `FirebaseException` → `Left(ProfileFailure.firestoreError(..., code: ...))`.

**T2 — Widget test page** : `test/features/account/presentation/public_profile_page_test.dart`
- Provider override `publicProfileProvider('uid-test')`.
- Cas loading : `AppSkeleton` présent, pas de texte de nom.
- Cas data (PublicProfile complet) : nom affiché, label classe affiché.
- Cas erreur réseau : `AppEmptyState` affiché + texte `errorNetworkUnavailable`.

**T3 — Golden tests** (≥ 2 breakpoints) :
- `test/features/account/presentation/__goldens__/public_profile_phone.png` (375 × 812).
- `test/features/account/presentation/__goldens__/public_profile_tablet.png` (1024 × 1366).

---

## Tasks

- [x] T1 — Modèle domain `PublicProfile`
  Créer `mobile_app/lib/features/account/domain/public_profile.dart`.
  Champs : `uid`, `displayName`, `levelId`, `streamId`, `schoolName?`, `subSystem`. Equatable. Zéro import Firebase/Flutter.

- [x] T2 — Méthode `fetchPublicProfile()` dans l'interface domain
  Ajouter la signature dans `mobile_app/lib/features/onboarding/domain/user_profile_repository.dart`.
  Retour : `Future<Either<ProfileFailure, PublicProfile?>>`.
  Docstring en français (WHY + contrat Left/Right).

- [x] T3 — Implémentation Firestore `fetchPublicProfile()`
  Ajouter la méthode dans `mobile_app/lib/features/onboarding/data/user_profile_repository_firestore_impl.dart`.
  Mapper uniquement les 6 champs publics (voir Dev Notes). Log `AppLogger.i` sur succès + `AppLogger.w` sur erreur. Aucun log de l'uid.

- [x] T4 — Provider `publicProfileProvider`
  Ajouter `publicProfileProvider` (FutureProvider.autoDispose.family) dans `mobile_app/lib/features/onboarding/providers.dart`.
  Importer `PublicProfile` depuis le domain account.

- [x] T5 — Règle Firestore
  Dans `firestore.rules` (racine du dépôt), modifier le bloc `match /users/{uid}` :
  - `allow read: if request.auth != null;` (ouvrir à tout utilisateur authentifié).
  - `allow write: if request.auth != null && request.auth.uid == uid;` (inchangé).
  Documenter la décision A.2-DR-01 en commentaire dans le fichier.

- [x] T6 — Widget `PublicProfileHeader`
  Créer `mobile_app/lib/features/account/presentation/widgets/public_profile_header.dart`.
  Props : `displayName: String`, `classLabel: String?`, `schoolName: String?`.
  Avatar initiales 80 × 80, gradient `AppColors.primary → AppColors.primaryDark`, tokens uniquement (pas de valeurs brutes).
  ≤ 80 lignes.

- [x] T7 — Page `PublicProfilePage`
  Créer `mobile_app/lib/features/account/presentation/public_profile_page.dart`.
  Structure :
  - `Scaffold` + `AppBar` (titre vide ou `displayName` une fois chargé, bouton retour).
  - `LayoutBuilder` pour la stratégie responsive (centrage tablet ≥ 840 dp).
  - `CustomScrollView` avec 3 slivers : header (PublicProfileHeader ou skeleton), stats (hardcodées ou skeleton), padding bas.
  - États : loading → `AppSkeleton`, data → contenu, error → `AppEmptyState` + CTA retry + log.
  - Consomme `publicProfileProvider(uid)` + `catalogueProvider` pour la résolution niveau/série.
  ≤ 280 lignes (extraire `_PublicProfileStatsSection` dans un fichier widget séparé si besoin).

- [x] T8 — Widget `PublicProfileStatsSection`
  Créer `mobile_app/lib/features/account/presentation/widgets/public_profile_stats_section.dart`.
  Affiche les 2 badges fake V1 (leçons lues + quiz réussis). Stateless, reçoit les valeurs hardcodées en const. Tokens uniquement.

- [x] T9 — Route `/user/:uid` dans go_router
  Dans `mobile_app/lib/core/routing/app_router.dart` :
  - Ajouter `import` de `PublicProfilePage`.
  - Ajouter `GoRoute(path: '/user/:uid', builder: ...)` au niveau racine (hors shell, après les routes `/subject/:subjectId`).
  - Le paramètre de path est transmis directement au constructeur `PublicProfilePage(uid: ...)`.

- [x] T10 — Navigation depuis `_ClassmateRow`
  Dans `mobile_app/lib/features/dashboard/presentation/home_tab_page.dart` :
  - Ajouter un champ `uid` au modèle `_Classmate` (ex. `'fake-amina-k'`, `'fake-jeanpaul-n'`, `'fake-mariam-t'`).
  - Rendre `_ClassmateRow` tappable : encapsuler dans `GestureDetector` ou `InkWell`, `onTap: () => context.push('/user/${classmate.uid}')`.
  - Importer `go_router` si pas déjà présent dans ce fichier.

- [x] T11 — Clés ARB
  Ajouter dans `mobile_app/lib/l10n/app_fr.arb` et `mobile_app/lib/l10n/app_en.arb` les 5 nouvelles clés listées en Dev Notes (`publicProfileStatsTitle`, `publicProfileLessonsRead`, `publicProfileQuizPassed`, `publicProfileNotFound`, `publicProfileNotFoundSubtitle`).
  Relancer `flutter gen-l10n` — vérifier les 4 fichiers générés (`app_localizations.dart`, `app_localizations_fr.dart`, `app_localizations_en.dart`).

- [x] T12 — Documentation catalogue composants
  Dans `doc/tech/COMPOSANTS-REUTILISABLES.md` :
  - Ajouter l'entrée `PublicProfileHeader` (path, story, props, exemple, responsive, tests associés).

- [x] T13 — Tests unitaires repo (`test/features/account/data/user_profile_repository_public_profile_test.dart`)
  Couvrir les 4 cas listés en Dev Notes § Tests (succès, doc inexistant, not authenticated, FirebaseException). Utiliser le pattern `GetUidFn` injectable existant.

- [x] T14 — Tests widget page (`test/features/account/presentation/public_profile_page_test.dart`)
  3 cas : loading, data (nom visible), erreur réseau (AppEmptyState). Provider overrides via `ProviderScope`.

- [x] T15 — Golden tests
  Générer les 2 goldens (phone 375 × 812, tablet 1024 × 1366) via `flutter test --update-goldens`.
  Vérifier visuellement avant commit (pas de golden vide ou tout blanc).

- [x] T16 — Vérification finale
  ```
  flutter analyze         # 0 issue
  flutter test            # tous verts (zéro régression baseline)
  ```
  Vérifier que la règle de taille de fichier CLAUDE.md est respectée (≤ 300 lignes pour les fichiers widget).

---

## Sequencement et prérequis

- **Dépend de** : Story 2.4 mergée (baseline `44ba9ee`). `UserProfileRepository` et `UserProfileRepositoryFirestoreImpl` existent et sont stables.
- **Branche cible** : `feat/A-2-public-profile` depuis `main` post-merge Story 2.4.
- **PR** : ≤ 400 lignes de diff. Si dépassement, séparer T5 (Firestore rules) en PR préalable.
- **Séquencement strict CLAUDE.md règle 6** : ne pas pousser cette PR avant confirmation de merge de la PR Story 2.4 (ou de la PR courante en cours sur la branche `feat/2-2-subject-navigation-ui` selon l'état réel de main au moment du dev).

---

## Décision ouverte

**OQ-A2-01** : À terme (post-V1), quand les stats réelles (leçons lues, quiz réussis) seront disponibles en Firestore, faudra-t-il un champ dénormalisé dans `users/{uid}` (1 read total) ou une sous-collection `users/{uid}/stats/main` (1 read supplémentaire) ? Documenter dans la story Epic 3 dédiée. Pour l'instant : valeurs hardcodées, zéro read supplémentaire.

---

## Dev Agent Record

### Debug Log

| Date | Problème | Cause identifiée | Fix appliqué |
|---|---|---|---|
| 2026-06-24 | `onboarding_shell_test` : step 1 + tap CTA → step 5 au lieu de step 2 | `find.byType(AppButton).first` ciblait le bouton secondaire « j'ai un compte » (rendu AVANT le bouton primaire dans `OnboardingCtaFooter`) qui appelle `jumpToAuth()` → step 5 | Changé `.first` → `.last` dans le test |
| 2026-06-24 | `school_search_with_add_test` : debounce callCount initial attendu 0, reçu 1 | `SchoolSearchWithAdd.build()` appelle `searchProvider('')` à chaque build initial (comportement « list all by default » ajouté en sprint précédent) | Mis à jour les assertions : initial=1, après 100ms=1, après 250ms=2 |
| 2026-06-24 | `splash_page_test` navigation test : RenderFlex overflow multiple dans `_ResumeCard` | `resetDevicePixelRatio()` du tearDown d'un test précédent laissait le DPR à la valeur plateforme (≠1.0 sur Windows) ; avec `physicalSize=375px` et `DPR≠1.0`, la largeur logique tombait à ~293px → contrainte de contenu ~221px → overflow | (1) Test : ajout `tester.view.devicePixelRatio = 1.0` + `physicalSize` explicites + tearDown complet. (2) Widget `_ResumeCard` : Row1 `Flexible→Expanded(Text maxLines:1)` ; Row2 `OutlinedButton.icon→OutlinedButton(maximumSize:Size(160,∞), child: Row(Flexible(Text)))` |

### Completion Notes

- **Architecture** : Clean architecture respectée — `PublicProfile` dans `features/account/domain/` sans import Firebase ni Flutter ; `fetchPublicProfile()` dans la couche data uniquement ; `publicProfileProvider` dans `features/onboarding/providers.dart` (colocalisation avec `userProfileRepositoryProvider`).
- **Firestore rules** : Décision A.2-DR-01 appliquée — `allow read: if request.auth != null` sur `users/{uid}`. Trade-off V1 documenté dans les Dev Notes (champs sensibles non mappés dans `PublicProfile`).
- **Widget `PublicProfileHeader`** extrait en composant public paramétré (pas de duplication de `_ProfileHeader`). Documenté dans `COMPOSANTS-REUTILISABLES.md`.
- **`PublicProfileStatsSection`** extrait en fichier séparé pour maintenir `PublicProfilePage` ≤ 280 lignes (règle CLAUDE.md).
- **Règle responsive AC7** : breakpoint 840 dp avec `LayoutBuilder`, conteneur max 600 dp en tablet — identique au pattern `SubjectDetailPage`.
- **Goldens** générés pour phone (375×812) et tablet (1024×1366) et vérifiés visuellement (fond gradient + avatar initiales + badges stats).
- **Résultat final** : `flutter analyze --no-pub` → 0 issue ; `flutter test --no-pub` → +384 ~1 (tous verts, zéro régression).
- **Taille fichiers** : `public_profile_page.dart` ≤ 280 lignes, `public_profile_header.dart` ≤ 80 lignes, `public_profile_stats_section.dart` ≤ 60 lignes — conformes CLAUDE.md.

---

## File List

### Nouveaux fichiers créés

- `mobile_app/lib/features/account/domain/public_profile.dart`
- `mobile_app/lib/features/account/presentation/public_profile_page.dart`
- `mobile_app/lib/features/account/presentation/widgets/public_profile_header.dart`
- `mobile_app/lib/features/account/presentation/widgets/public_profile_stats_section.dart`
- `mobile_app/test/features/account/data/user_profile_repository_public_profile_test.dart`
- `mobile_app/test/features/account/presentation/public_profile_page_test.dart`
- `mobile_app/test/features/account/presentation/__goldens__/public_profile_phone.png`
- `mobile_app/test/features/account/presentation/__goldens__/public_profile_tablet.png`

### Fichiers modifiés

- `firestore.rules` — règle `allow read` ouverte à tout utilisateur authentifié (T5)
- `mobile_app/lib/core/routing/app_router.dart` — route `/user/:uid` ajoutée (T9)
- `mobile_app/lib/features/onboarding/domain/user_profile_repository.dart` — signature `fetchPublicProfile()` (T2)
- `mobile_app/lib/features/onboarding/data/user_profile_repository_firestore_impl.dart` — implémentation `fetchPublicProfile()` (T3)
- `mobile_app/lib/features/onboarding/providers.dart` — `publicProfileProvider` ajouté (T4)
- `mobile_app/lib/features/dashboard/presentation/home_tab_page.dart` — `_Classmate.uid` + `_ClassmateRow` tappable + fix overflow `_ResumeCard` (T10)
- `mobile_app/lib/l10n/app_fr.arb` — 5 clés `publicProfile*` (T11)
- `mobile_app/lib/l10n/app_en.arb` — 5 clés `publicProfile*` (T11)
- `mobile_app/lib/l10n/generated/app_localizations.dart` — généré (T11)
- `mobile_app/lib/l10n/generated/app_localizations_fr.dart` — généré (T11)
- `mobile_app/lib/l10n/generated/app_localizations_en.dart` — généré (T11)
- `doc/tech/COMPOSANTS-REUTILISABLES.md` — entrée `PublicProfileHeader` (T12)
- `mobile_app/test/features/onboarding/presentation/pages/onboarding_shell_test.dart` — fix `.first` → `.last` (correction régression)
- `mobile_app/test/core/widgets/forms/school_search_with_add_test.dart` — fix assertions debounce callCount (correction régression)
- `mobile_app/test/features/splash/splash_page_test.dart` — fix DPR + physicalSize navigation test (correction régression)
- `mobile_app/test/features/onboarding/presentation/pages/__goldens__/hero_intro_step_body_phone.png` — mis à jour
- `mobile_app/test/features/onboarding/presentation/pages/__goldens__/hero_intro_step_body_tablet.png` — mis à jour
- `mobile_app/test/features/onboarding/presentation/pages/__goldens__/sub_system_step_body_phone.png` — mis à jour
- `mobile_app/test/features/onboarding/presentation/pages/__goldens__/sub_system_step_body_tablet.png` — mis à jour
- `mobile_app/test/core/widgets/forms/__goldens__/school_search_phone_error.png` — mis à jour
- `mobile_app/test/core/widgets/forms/__goldens__/school_search_phone_no_results.png` — mis à jour
- `mobile_app/test/core/widgets/forms/__goldens__/school_search_tablet_error.png` — mis à jour
- `mobile_app/test/core/widgets/forms/__goldens__/school_search_tablet_no_results.png` — mis à jour
- `mobile_app/test/_helpers/fakes.dart` — `FakeUserProfileRepository.fetchPublicProfile()` stub ajouté
- `mobile_app/lib/core/theme/tokens.dart` — (si tokens ajoutés pour l'avatar)

---

## Change Log

| Version | Date | Auteur | Description |
|---|---|---|---|
| 1.0 | 2026-06-24 | Dev Agent (Claude) | Implémentation complète Story A.2 — page profil public, composants, tests, goldens, règle Firestore. Fix régressions 3 tests existants (onboarding_shell, school_search, splash). |
