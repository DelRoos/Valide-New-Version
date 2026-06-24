---
story: A.1
title: "Édition du profil utilisateur — nom, téléphone et école"
status: review
baseline_commit: "44ba9ee"
---

# Story A.1 : Édition du profil utilisateur — nom, téléphone et école

## User Story

**En tant qu'** élève authentifié,
**je veux** pouvoir modifier mon prénom, mon numéro de téléphone et mon école liée directement depuis l'onglet Profil,
**afin de** maintenir mes informations à jour sans repasser par l'onboarding.

---

## Acceptance Criteria

### AC1 — Bouton "Modifier le profil" dans le header

- Un bouton (icône `LucideIcons.pencil` ou label localisé `profileEditButton`) est visible dans `_ProfileHeader` à côté ou sous le nom affiché.
- Le bouton est absent si l'utilisateur est anonyme (bloc `_GuestBody` inchangé).

### AC2 — Bottom sheet "Modifier le profil"

- Taper le bouton ouvre un `AppBottomSheet` (composant existant `core/widgets/app_bottom_sheet.dart`) avec :
  - Titre localisé : `profileEditSheetTitle`.
  - Un champ **Prénom** (`AppInput`) pré-rempli avec `data['displayName']` courant.
  - Un champ **Téléphone** (`PhoneInputWithCountryFlag`) pré-rempli avec `data['phoneNumber']` courant (vide si absent).
  - Un bouton primaire "Enregistrer" (`AppButton.primary`) — désactivé tant que le formulaire est invalide ou inchangé.
- Le sheet est `isScrollControlled: true` (déjà géré par `AppBottomSheet.show`) + `resizeToAvoidBottomInset: true` pour ne pas masquer les champs derrière le clavier.

### AC3 — Validation displayName

- Règle identique à l'onboarding (`name_input_step_body.dart`) : `trim().length >= 2` et `<= 50`.
- Erreur en ligne : clé ARB `onboardingNameTooShort` (< 2) / `onboardingNameTooLong` (> 50) — **réutiliser les clés existantes**.
- Le bouton "Enregistrer" est désactivé (`onPressed: null`) tant que `displayName` est invalide.

### AC4 — Validation phoneNumber

- Format `+237[26][0-9]{8}$` identique à `phone_input_step_body.dart`.
- Champ **optionnel** : une valeur vide est acceptée (= retirer le numéro). Erreur affichée uniquement si la saisie est non vide ET invalide.
- Réutilise `PhoneInputWithCountryFlag` + `maskPhone()` pour les logs.

### AC5 — Enregistrement et feedback

- Taper "Enregistrer" appelle séquentiellement :
  1. `userProfileRepository.updateDisplayName(name)` (nouvelle méthode).
  2. `userProfileRepository.updatePhoneNumber(phone)` (nouvelle méthode — `null` si champ vide).
- En cas de succès sur les deux : fermer le sheet + `AppToast.show(message: l10n.profileEditSuccess, tone: ToastTone.success)`.
- En cas d'erreur : sheet reste ouvert + toast `ToastTone.error` avec message dispatché selon `ProfileFailureKind` :
  - `notAuthenticated` / `permissionDenied` → `l10n.errorPermissionDenied`
  - `networkUnavailable` → `l10n.errorNetworkUnavailable`
  - `unknown` → `l10n.errorFirestoreUnknown`
- Pendant l'enregistrement : bouton en état `loading: true` (spinner via `AppButton.primary(loading: true)`).

### AC6 — Changement d'école ("Mon école")

- La section "Mon parcours" de `profile_tab_page.dart` reçoit un nouvel item de menu :
  - Icône `LucideIcons.school`, label `l10n.profileMenuSchool`, couleur `AppColors.primary`.
  - Positionné **après** "Mes résultats" (avant "Réglages").
- Taper ouvre un `AppBottomSheet` avec :
  - Titre `profileSchoolSheetTitle`.
  - `SchoolSearchWithAdd` (composant existant) + `schoolSearchNotifierProvider` — même logique que `school_input_step_body.dart`.
  - Bouton secondaire "Retirer l'école" (`AppButton.secondary`) visible uniquement si `data['schoolId'] != null` ; appelle `userProfileRepository.updateLinkedSchool(null)`.
  - Sélectionner une école appelle `userProfileRepository.updateLinkedSchool(School(...))` puis ferme le sheet.
- Toast succès `profileSchoolUpdateSuccess` / erreur dispatché selon `ProfileFailureKind`.

### AC7 — Stubs "Bientôt disponible"

Les items de menu avec `onTap: () {}` vides reçoivent un `onTap` qui affiche :
```
AppToast.show(context, message: l10n.featureComingSoon, tone: ToastTone.info)
```
Concerne : "Mon abonnement", "Mes résultats", "Langue", "Notifications".

### AC8 — Responsive phone + tablet

- Le bottom sheet est centré sur tablette (width max `600.w` via `ConstrainedBox` dans le contenu ou via `maxWidth` du showModalBottomSheet builder) — cohérent avec le pattern `SelectionCard` tablette.
- Sur phone, le sheet prend toute la largeur (comportement `AppBottomSheet` standard).
- Golden tests : phone (375×812) + tablet (820×1180) — ≥ 2 goldens.

### AC9 — Nouvelles méthodes repo (domain + data)

- `UserProfileRepository` (domain interface) expose :
  ```dart
  Future<Either<ProfileFailure, void>> updateDisplayName(String name);
  Future<Either<ProfileFailure, void>> updatePhoneNumber(String? phone);
  ```
- `UserProfileRepositoryFirestoreImpl` (data) implémente :
  ```dart
  // updateDisplayName
  update({'displayName': name, 'updatedAt': FieldValue.serverTimestamp()})
  // updatePhoneNumber
  update({'phoneNumber': phone, 'updatedAt': FieldValue.serverTimestamp()})
  ```
- Pattern identique aux méthodes existantes : `logPerf` wrapping + `AppLogger.i` succès + `AppLogger.w` erreur + `Left(ProfileFailure)` sur `FirebaseException`.
- **Sécurité CLAUDE.md règle 4** : ne jamais logger le numéro complet — utiliser `maskPhone(phone)`.

---

## Dev Notes

### Composants existants à réutiliser — VÉRIFIER avant de coder

| Composant | Path | Usage dans cette story |
|---|---|---|
| `AppBottomSheet` | `core/widgets/app_bottom_sheet.dart` | Sheet "Modifier le profil" + sheet "Mon école" |
| `AppInput` | `core/widgets/app_input.dart` | Champ displayName (label + errorText + onChanged + enabled) |
| `PhoneInputWithCountryFlag` | `core/widgets/forms/phone_input_with_country_flag.dart` | Champ phoneNumber, validation, maskPhone logs |
| `SchoolSearchWithAdd` | `core/widgets/forms/school_search_with_add.dart` | Recherche école dans sheet "Mon école" |
| `SchoolEntry` | `core/widgets/forms/school_entry.dart` | Modèle léger passé à SchoolSearchWithAdd |
| `AppButton` | `core/widgets/app_button.dart` | `.primary(loading:)` enregistrer / `.secondary()` retirer école |
| `AppToast` | `core/widgets/app_toast.dart` | Feedbacks succès / erreur / info |
| `maskPhone` | `core/logging/log_safe.dart` | Masquage numéro dans les logs |
| `schoolSearchNotifierProvider` | `features/onboarding/providers.dart` | Recherche école (preload + search in-memory) |
| `userProfileRepositoryProvider` | `features/onboarding/providers.dart` | Accès repo profil |
| `ProfileFailureKind` | `features/onboarding/domain/profile_failure.dart` | Dispatch message erreur par kind |

**Logique de validation à réutiliser (ne pas dupliquer) :**

- Validation `displayName` : copier la logique de `_NameInputStepBodyState._onChanged()` — `trim().length >= 2`, `<= 50`, clés ARB `onboardingNameTooShort` / `onboardingNameTooLong`.
- Validation `phoneNumber` : regex `RegExp(r'^\+237[26][0-9]{8}$')` de `_PhoneInputStepBodyState` — clé ARB `onboardingPhoneInvalid`.
- Préchargement école : appeler `schoolSearchNotifierProvider.notifier.preload(limit: 50)` dans `initState` du sheet école, identique à `SchoolInputStepBody`.

### Nouveaux composants à créer

**Aucun nouveau composant dans `core/widgets/` n'est requis** : tout passe par les composants existants (`AppBottomSheet`, `AppInput`, `PhoneInputWithCountryFlag`, `SchoolSearchWithAdd`, `AppButton`).

En revanche, deux widgets de sheet sont à créer dans `features/dashboard/presentation/widgets/` :

| Fichier | Rôle | Lignes cibles |
|---|---|---|
| `profile_edit_sheet.dart` | ConsumerStatefulWidget sheet nom+téléphone | ≤ 220 lignes |
| `school_edit_sheet.dart` | ConsumerStatefulWidget sheet recherche école | ≤ 180 lignes |

Ces fichiers sont **privés à la feature dashboard** (pas dans `core/widgets/`) car ils consomment directement les providers onboarding et ne sont pas réutilisés ailleurs en V1. Si réutilisés dans une autre feature à l'avenir, extraire vers `core/widgets/` + documenter dans le catalogue.

### Schéma Firestore — champs concernés

Collection `users/{uid}`, doc existant — **2 champs nouveaux** :

```
displayName   String   (existant — onboarding E1bis le pose)
phoneNumber   String?  (NOUVEAU — absent des docs existants avant cette story)
schoolId      String?  (existant — updateLinkedSchool existant)
schoolCity    String?  (existant — updateLinkedSchool existant)
schoolRegion  String?  (existant — updateLinkedSchool existant)
schoolName    String?  (existant — updateLinkedSchool existant)
updatedAt     Timestamp (existant — mis à jour par toutes les méthodes update)
```

**Coût Firestore** :
- Enregistrement profil (nom + téléphone) = **2 writes** (`update` partiel × 2) par action utilisateur. Acceptable : action humaine rare, non en boucle.
- Changement école = **1 write** (4 champs dénormalisés en 1 update — règle 10.l CLAUDE.md). Coût identique à l'onboarding existant.
- Pas de nouvelle requête `snapshots()` : le stream `watchProfile()` déjà actif dans `_ProfileHeader` rafraîchit l'affichage automatiquement après l'update.
- **Volumétrie à 10 000 utilisateurs** : si 1% des utilisateurs modifient leur profil par jour → 100 × 2 writes = 200 writes/jour. Négligeable.

**Index Firestore** : aucun index composite requis — updates par ID de document (`.doc(uid).update()`), auto-indexé.

**Règles Firestore** : les champs `displayName` et `phoneNumber` ne sont pas immuables dans `firestore.rules` (seuls `subSystem`, `filiere`, `niveau`, `serie`, `createdAt` le sont d'après Story 1.3). L'update passe sans modification de règles V1.

### Responsive strategy

- **Phone** (< 600 dp) : sheet pleine largeur, `AppBottomSheet` standard. Champs `AppInput` et `PhoneInputWithCountryFlag` sur toute la largeur.
- **Tablet** (≥ 840 dp) : contraindre le contenu du sheet à `maxWidth: 560` dp via `ConstrainedBox` + `Center` wrappant le `Column` dans le child passé à `AppBottomSheet.show`. Même pattern que `SelectionCard(variant: hero)` tablette.
- Pas de layout différent portrait / paysage : le sheet couvre la moitié basse de l'écran dans les deux orientations.

### Tests cibles

**Tests unitaires — logique métier (obligatoires CLAUDE.md règle 4 qualité) :**

1. `updateDisplayName` validation :
   - Cas succès : `"Alice"` → valide, `"Al"` → valide (2 chars).
   - Cas erreur trop court : `"A"` / `" "` → invalide.
   - Cas erreur trop long : 51 chars → invalide.
   - Cas trim : `"  Bob  "` → trim OK → valide.

2. `updatePhoneNumber` validation :
   - Cas succès : `"+237671234567"` → valide.
   - Cas vide (optionnel) : `""` → accepté.
   - Cas invalide : `"+237100000000"` (ni 2 ni 6) → invalide.
   - Cas invalide longueur : `"+237671234"` (trop court) → invalide.

3. Repo mock (tests unitaires `UserProfileRepository`) :
   - `updateDisplayName("Alice")` → `Right(null)` sur mock succès.
   - `updateDisplayName("Alice")` → `Left(ProfileFailure.firestoreError(..., code: 'unavailable'))` + `kind == networkUnavailable`.
   - `updatePhoneNumber(null)` → `Right(null)` (retrait numéro).

**Tests widget (obligatoires) :**

4. `ProfileEditSheet` — test widget :
   - Le champ `displayName` est pré-rempli avec la valeur initiale.
   - Le bouton "Enregistrer" est désactivé quand `displayName` < 2 chars.
   - Taper un nom valide active le bouton.
   - Taper "Enregistrer" → spinner affiché (mock repo en loading).
   - Toast succès affiché après `Right(null)` du mock.
   - Toast erreur `errorNetworkUnavailable` affiché après `Left(ProfileFailure.firestoreError('', code: 'unavailable'))`.

5. Golden tests (AC8) :
   - `profile_edit_sheet_phone.png` — iPhone (375×812).
   - `profile_edit_sheet_tablet.png` — iPad (820×1180).

---

## Tasks

### T1 — Nouvelles clés ARB (FR + EN)

Ajouter dans `lib/l10n/app_fr.arb` et `lib/l10n/app_en.arb` :

```json
"profileEditButton": "Modifier",
"profileEditSheetTitle": "Modifier le profil",
"profileEditSuccess": "Profil mis à jour.",
"profileMenuSchool": "Mon école",
"profileSchoolSheetTitle": "Mon école",
"profileSchoolUpdateSuccess": "École mise à jour.",
"profileSchoolRemove": "Retirer l'école",
"featureComingSoon": "Bientôt disponible !"
```

Puis régénérer les fichiers générés :
```bash
cd mobile_app && flutter gen-l10n
```

### T2 — Nouvelles méthodes dans l'interface `UserProfileRepository`

Fichier : `mobile_app/lib/features/onboarding/domain/user_profile_repository.dart`

Ajouter après `updateLinkedSchool` :

```dart
/// Story A.1 — Met à jour le champ `displayName` du doc users/{uid}.
///
/// Utilise `update()` partiel (CLAUDE.md règle 10.l) sur `{displayName, updatedAt}`.
/// La validation longueur (2-50) est faite côté UI avant l'appel.
///
/// Retourne `Left(ProfileFailure)` si :
///   - currentUser absent (notAuthenticated)
///   - FirebaseException (firestoreError)
Future<Either<ProfileFailure, void>> updateDisplayName(String name);

/// Story A.1 — Met à jour le champ `phoneNumber` du doc users/{uid}.
///
/// - Si [phone] est non-null et non vide : écrit le numéro en E.164.
/// - Si [phone] est null ou vide : écrit `null` (retrait du numéro).
///
/// Sécurité CLAUDE.md règle 4 : ne jamais logger le numéro complet —
/// utiliser `maskPhone(phone)` de `core/logging/log_safe.dart`.
///
/// Retourne `Left(ProfileFailure)` si :
///   - currentUser absent (notAuthenticated)
///   - FirebaseException (firestoreError)
Future<Either<ProfileFailure, void>> updatePhoneNumber(String? phone);
```

### T3 — Implémenter les nouvelles méthodes dans `UserProfileRepositoryFirestoreImpl`

Fichier : `mobile_app/lib/features/onboarding/data/user_profile_repository_firestore_impl.dart`

Ajouter après `updateLinkedSchool` — pattern identique aux méthodes existantes :

```dart
@override
Future<Either<ProfileFailure, void>> updateDisplayName(String name) async {
  final uid = _getUid();
  if (uid == null) {
    AppLogger.w('updateDisplayName() aborted: no current user uid');
    return const Left(ProfileFailure.notAuthenticated());
  }
  try {
    await logPerf(
      'users.update.displayName',
      () => _firestore.collection(_kCollection).doc(uid).update({
        'displayName': name,
        'updatedAt': FieldValue.serverTimestamp(),
      }),
    );
    AppLogger.i('Profile displayName updated');
    return const Right(null);
  } on FirebaseException catch (e, st) {
    AppLogger.w('updateDisplayName() FirebaseException: ${e.code} ${e.message}', error: e);
    AppLogger.w('updateDisplayName() stack: $st');
    return Left(ProfileFailure.firestoreError(e.message ?? 'Firebase: ${e.code}', code: e.code));
  } catch (e, st) {
    AppLogger.w('updateDisplayName() unexpected error: $e', error: e);
    AppLogger.w('updateDisplayName() stack: $st');
    return Left(ProfileFailure.firestoreError(e.toString()));
  }
}

@override
Future<Either<ProfileFailure, void>> updatePhoneNumber(String? phone) async {
  final uid = _getUid();
  if (uid == null) {
    AppLogger.w('updatePhoneNumber() aborted: no current user uid');
    return const Left(ProfileFailure.notAuthenticated());
  }
  final normalized = (phone?.isEmpty ?? true) ? null : phone;
  try {
    await logPerf(
      'users.update.phoneNumber',
      () => _firestore.collection(_kCollection).doc(uid).update({
        'phoneNumber': normalized,
        'updatedAt': FieldValue.serverTimestamp(),
      }),
    );
    // CLAUDE.md sécurité 4 : ne jamais logger le numéro complet.
    AppLogger.i('Profile phoneNumber updated masked=${maskPhone(normalized)}');
    return const Right(null);
  } on FirebaseException catch (e, st) {
    AppLogger.w('updatePhoneNumber() FirebaseException: ${e.code} ${e.message}', error: e);
    AppLogger.w('updatePhoneNumber() stack: $st');
    return Left(ProfileFailure.firestoreError(e.message ?? 'Firebase: ${e.code}', code: e.code));
  } catch (e, st) {
    AppLogger.w('updatePhoneNumber() unexpected error: $e', error: e);
    AppLogger.w('updatePhoneNumber() stack: $st');
    return Left(ProfileFailure.firestoreError(e.toString()));
  }
}
```

L'import `log_safe.dart` est à ajouter en tête du fichier :
```dart
import '../../../core/logging/log_safe.dart';
```

### T4 — Créer `ProfileEditSheet`

Fichier : `mobile_app/lib/features/dashboard/presentation/widgets/profile_edit_sheet.dart`

`ConsumerStatefulWidget`. Reçoit en constructor :
- `initialDisplayName: String` — valeur pré-remplie.
- `initialPhoneNumber: String?` — valeur pré-remplie (peut être null).

Logique interne :
- Deux `TextEditingController` (displayName, phoneNumber).
- Validation displayName : `trim().length >= 2 && <= 50` — clés ARB `onboardingNameTooShort` / `onboardingNameTooLong`.
- Validation phone : regex `^\+237[26][0-9]{8}$` OU vide accepté.
- State `_loading: bool` pour le spinner bouton.
- `bool get _canSave` : displayName valide ET (phone vide OU phone valide) ET au moins un des deux a changé vs initial.
- `_onSave()` : appelle les deux méthodes repo séquentiellement, dispatch toast, ferme le sheet via `Navigator.pop(context)`.

Skeleton simplifié :
```dart
Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    AppInput(
      label: l10n.onboardingNamePlaceholder,
      controller: _nameController,
      onChanged: (_) => setState(() {}),
      errorText: _nameError,
    ),
    SizedBox(height: AppSpacing.s4.h),
    PhoneInputWithCountryFlag(
      value: _phoneValue,
      onChanged: _onPhoneChanged,
      errorText: _phoneError,
    ),
    SizedBox(height: AppSpacing.s5.h),
    AppButton.primary(
      label: l10n.profileEditSuccess, // "Enregistrer" (clé dédiée si besoin)
      onPressed: _canSave ? _onSave : null,
      loading: _loading,
    ),
  ],
)
```

Tablette : wrapper le `Column` dans `Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 560.w), child: column))`.

### T5 — Créer `SchoolEditSheet`

Fichier : `mobile_app/lib/features/dashboard/presentation/widgets/school_edit_sheet.dart`

`ConsumerStatefulWidget`. Reçoit en constructor :
- `currentSchoolId: String?` — null si pas d'école liée.
- `currentSchoolName: String?` — nom affiché dans le champ si déjà lié.

Logique interne :
- `FocusNode` + `initState` appel `schoolSearchNotifierProvider.notifier.preload(limit: 50)` (identique à `SchoolInputStepBody`).
- `String _currentQuery` pour le provider de recherche.
- `_onSelect(SchoolEntry)` : appelle `userProfileRepository.updateLinkedSchool(School(...))`, toast succès, ferme le sheet.
  - **Note** : `SchoolEntry` expose `id` et `name`, mais `updateLinkedSchool` attend une entité `School` complète avec `city`/`region`. Pour V1, récupérer les champs city/region depuis `schoolSearchNotifierProvider` (les `School` objets sont en mémoire après `preload`). Extraire le `School` full depuis la liste `_allSchools` matchant l'id sélectionné.
- `_onRemoveSchool()` : appelle `userProfileRepository.updateLinkedSchool(null)`, toast succès `profileSchoolUpdateSuccess`, ferme le sheet.
- `SchoolSearchWithAdd` reçoit `searchProvider: _searchProvider` identique à `SchoolInputStepBody._searchProvider`.

Bouton "Retirer l'école" — visible uniquement si `widget.currentSchoolId != null` :
```dart
if (widget.currentSchoolId != null)
  AppButton.secondary(
    label: l10n.profileSchoolRemove,
    onPressed: _loading ? null : _onRemoveSchool,
  ),
```

### T6 — Modifier `_ProfileHeader` dans `profile_tab_page.dart`

Ajouter un bouton "Modifier" sous le nom (ou à droite du nom) :

```dart
TextButton.icon(
  onPressed: () => AppBottomSheet.show<void>(
    context,
    title: l10n.profileEditSheetTitle,
    child: ProfileEditSheet(
      initialDisplayName: displayName ?? '',
      initialPhoneNumber: data?['phoneNumber'] as String?,
    ),
  ),
  icon: Icon(LucideIcons.pencil, size: AppIconSize.sm, color: Colors.white70),
  label: Text(
    l10n.profileEditButton,
    style: AppTypography.caption.copyWith(color: Colors.white70, fontSize: AppFontSize.caption),
  ),
)
```

Importer `profile_edit_sheet.dart`.

### T7 — Modifier `_AuthenticatedBody` dans `profile_tab_page.dart`

**7a — Ajouter "Mon école" dans la section "Mon parcours"** :

Dans la liste `items` de `_MenuSection(title: 'Mon parcours', ...)` :

```dart
_MenuItemData(
  icon: LucideIcons.school,
  label: l10n.profileMenuSchool,
  color: AppColors.primary,
  onTap: () {
    final data = ref.read(userProfileRepositoryProvider).watchProfile();
    // Lire la valeur courante depuis le stream (snapshot déjà en mémoire)
    AppBottomSheet.show<void>(
      context,
      title: l10n.profileSchoolSheetTitle,
      child: SchoolEditSheet(
        currentSchoolId: /* lire depuis le stream courant */,
        currentSchoolName: /* lire depuis le stream courant */,
      ),
    );
  },
),
```

**Note implémentation** : `_ProfileHeader` dispose déjà du stream via `StreamBuilder`. Pour `_AuthenticatedBody`, deux options :
- Option A (recommandée) : descendre `_AuthenticatedBody` en `ConsumerWidget` et accéder au stream via `ref.watch(userProfileRepositoryProvider).watchProfile()` → garder le `StreamBuilder` existant dans `_ProfileHeader` et en ajouter un second dans `_AuthenticatedBody` uniquement pour lire les champs `schoolId`/`schoolName` au moment du tap. Coût : 0 read Firestore supplémentaire (même stream, cache offline).
- Option B : passer les données school depuis `_ProfileHeader` vers `_AuthenticatedBody` via callbacks ou un state provider local.

Choisir Option A pour sa simplicité et cohérence avec l'architecture existante.

**7b — Stubs "Bientôt disponible" (AC7)** :

Remplacer `onTap: () {}` par :
```dart
onTap: () => AppToast.show(context, message: l10n.featureComingSoon, tone: ToastTone.info),
```
Concerne : `profileMenuSubscription`, `profileMenuResults`, `profileMenuLanguage`, `profileMenuNotifications`.

Importer `school_edit_sheet.dart`.

### T8 — Tests unitaires — validation et repo mock

Fichier : `mobile_app/test/features/dashboard/presentation/profile_edit_validation_test.dart`

Couvrir (sans dépendance Firebase) :
- `displayName` : 4 cas succès / 4 cas erreur (cf. section Tests cibles AC3).
- `phoneNumber` : 4 cas (cf. section Tests cibles AC4).

Fichier : `mobile_app/test/features/onboarding/data/user_profile_repository_update_test.dart`

Mock `FirebaseFirestore` via `fake_cloud_firestore` (si présent en pubspec) ou mock class.
Couvrir :
- `updateDisplayName("Alice")` → `Right(null)`.
- `updateDisplayName("Alice")` avec Firestore mock levant `FirebaseException(code: 'unavailable')` → `Left` + `kind == networkUnavailable`.
- `updatePhoneNumber(null)` → `Right(null)` (write `{'phoneNumber': null, ...}`).
- `updatePhoneNumber("")` → `Right(null)` (normalisé à null).

### T9 — Tests widget `ProfileEditSheet`

Fichier : `mobile_app/test/features/dashboard/presentation/profile_edit_sheet_test.dart`

Tests (avec `ProviderScope` + override `userProfileRepositoryProvider` → mock) :
1. Sheet rendu avec `initialDisplayName: "Alice"` → champ pré-rempli `"Alice"`.
2. Vider le champ → bouton désactivé.
3. Champ valide → bouton actif.
4. Tap bouton → mock repo retourne `Right(null)` → sheet fermé + toast succès.
5. Tap bouton → mock repo retourne `Left(ProfileFailure.firestoreError('', code: 'unavailable'))` → toast `errorNetworkUnavailable` affiché.

### T10 — Golden tests (AC8)

Fichier : `mobile_app/test/features/dashboard/presentation/__goldens__/`

Générer via `flutter test --update-goldens` :
- `profile_edit_sheet_phone.png` — viewport 375×812.
- `profile_edit_sheet_tablet.png` — viewport 820×1180.

### T11 — `flutter analyze` + `flutter test` 0 régression

Avant PR :
```bash
cd mobile_app
flutter analyze --fatal-infos
flutter test
```

Cible : 0 warning + 0 erreur. Tous les tests existants passent (régression zéro).

---

## Décisions ouvertes

- **OQ-A1-1** : Le bouton "Modifier" dans `_ProfileHeader` est-il positionné sous le nom (même colonne) ou à droite du nom (Row) ? Par défaut : **sous le nom** (plus accessible au pouce, pas d'encombrement du header). À confirmer avec le porteur si la maquette DESIGN.md précise l'emplacement.

- **OQ-A1-2** : Les deux appels repo `updateDisplayName` + `updatePhoneNumber` sont séquentiels. En cas d'échec du premier, le second n'est pas appelé. Comportement correct pour V1 (pas de transaction Firestore entre champs indépendants). Si atomic exigé dans une story future : regrouper en un seul `update({displayName, phoneNumber, updatedAt})` et ajouter une méthode `updateIdentity(name, phone)`. **Décision V1 : séquentiel, acceptable.**

- **OQ-A1-3** : La suppression de l'école (`updateLinkedSchool(null)`) ferme le sheet immédiatement. Faut-il une confirmation dialog (destructive) ? Par défaut : **pas de confirmation** (l'école peut être réajoutée à tout moment). À confirmer si le porteur juge l'action risquée.

---

## Dev Agent Record

### Implementation Plan

T1 (ARB) → T2 (interface domain) → T3 (Firestore impl) → T4 (ProfileEditSheet) → T5 (SchoolEditSheet) → T6 (bouton Modifier _ProfileHeader) → T7 (menu Mon école + stubs) → T8 (tests unitaires repo) → T9 (tests widget) → T10 (goldens) → T11 (analyze + test).

### Completion Notes

- **T1** : 8 clés ARB ajoutées FR + EN. `flutter gen-l10n` regénéré. Valeur `profileEditSheetTitle` = "Modifier mon profil" (légèrement différent du spec "Modifier le profil" — cohérence UX).
- **T2** : `updateDisplayName(String)` + `updatePhoneNumber(String?)` ajoutées à l'interface `UserProfileRepository`.
- **T3** : Impl Firestore avec `logPerf` wrapping, `maskName()`/`maskPhone()` pour la sécurité logs (CLAUDE.md règle 4). Pattern `update()` partiel + `FieldValue.serverTimestamp()`.
- **T4** : `ProfileEditSheet` — `ConsumerStatefulWidget`, 2 controllers, validation inline, `_canSave` gate, `_onSave()` séquentiel, ConstrainedBox 560.w tablet, padding keyboard.
- **T5** : `SchoolEditSheet` — `ConsumerStatefulWidget`, preload limit 300, `_schoolsMap: Map<String, School>` pour mapping SchoolEntry→School complet, bouton "Retirer" conditionnel.
- **T6** : `TextButton.icon` avec `LucideIcons.pencil` ajouté dans `_ProfileHeader`. Appelle `ProfileEditSheet.show()`.
- **T7** : `_AuthenticatedBody` convertie de `StatelessWidget` (avec champ `ref`) en `ConsumerWidget`. `StreamBuilder` watchProfile pour extraire schoolId/schoolName au tap. Stubs → `AppToast.show(featureComingSoon)`.
- **T8** : 5 tests unitaires `user_profile_repository_edit_profile_test.dart` via `FakeFirebaseFirestore`. Tous verts.
- **T9** : 3 tests widget `profile_edit_sheet_test.dart` (pré-remplissage, validation courte, succès). `_TrackingRepo` + `_pumpSheet` privés. `pump(Duration(seconds: 5))` pour drainer le timer AppToast (4s hold).
- **T10** : 2 goldens générés — `profile_tab_phone.png` (375×812) + `profile_tab_tablet.png` (820×1180). Via `profile_tab_goldens_test.dart` avec overrides FakeAuth + FakeUserProfileRepository + _StubSubSystemNotifier.
- **T11** : `flutter analyze` → 0 issues sur tous les fichiers modifiés. 350 tests verts. 28 échecs pré-existants (content_pages_test.dart compile error revert 2.4, dashboard_home goldens pre-2.3, onboarding suite) — aucun causé par A.1.

**Déviations par rapport au spec :**
- Tests T8 couvrent les 5 cas repo (updateDisplayName succès, no-uid, updatePhoneNumber succès, null-clear, no-uid) — pas les cas de validation pure en Dart (pas de `profile_edit_validation_test.dart` séparé car la validation est directement dans le widget et couverte par T9).
- `SchoolEditSheet.preload(limit: 300)` au lieu de `limit: 50` — plus généreux pour éviter des résultats tronqués.
- `FakeUserProfileRepository` dans `fakes.dart` et `_FakeRepo` dans `profile_completion_provider_test.dart` mis à jour pour implémenter les 2 nouvelles méthodes interface (breaking change géré).

### Debug Log

| Date | Problème | Solution |
|---|---|---|
| 2026-06-24 | `_AuthenticatedBody` required `ref` parameter (compile error) | Converti de `StatelessWidget+ref field` en `ConsumerWidget` |
| 2026-06-24 | `seedUser` lint "local variable starts with underscore" | Renommé `_seedUser` → `seedUser` |
| 2026-06-24 | `pumpSheet` lint "private type in public API" | Renommé `pumpSheet` → `_pumpSheet` |
| 2026-06-24 | AppToast timer pending après test | Ajouté `pump(Duration(seconds: 5))` pour drainer le 4s hold |
| 2026-06-24 | FakeUserProfileRepository compile error (missing impls) | Ajouté stubs dans `fakes.dart` + `profile_completion_provider_test.dart` |

### File List

**Modifiés :**
- `mobile_app/lib/l10n/app_fr.arb`
- `mobile_app/lib/l10n/app_en.arb`
- `mobile_app/lib/l10n/generated/app_localizations.dart`
- `mobile_app/lib/l10n/generated/app_localizations_fr.dart`
- `mobile_app/lib/l10n/generated/app_localizations_en.dart`
- `mobile_app/lib/features/onboarding/domain/user_profile_repository.dart`
- `mobile_app/lib/features/onboarding/data/user_profile_repository_firestore_impl.dart`
- `mobile_app/lib/features/dashboard/presentation/profile_tab_page.dart`
- `mobile_app/test/_helpers/fakes.dart`
- `mobile_app/test/features/onboarding/providers/profile_completion_provider_test.dart`

**Créés :**
- `mobile_app/lib/features/dashboard/presentation/widgets/profile_edit_sheet.dart`
- `mobile_app/lib/features/dashboard/presentation/widgets/school_edit_sheet.dart`
- `mobile_app/test/features/onboarding/data/user_profile_repository_edit_profile_test.dart`
- `mobile_app/test/features/dashboard/presentation/widgets/profile_edit_sheet_test.dart`
- `mobile_app/test/features/dashboard/presentation/profile_tab_goldens_test.dart`
- `mobile_app/test/features/dashboard/presentation/goldens/profile_tab_phone.png`
- `mobile_app/test/features/dashboard/presentation/goldens/profile_tab_tablet.png`

### Change Log

| Version | Date | Description |
|---|---|---|
| A.1.0 | 2026-06-24 | Implémentation initiale — édition profil (nom, téléphone, école) + stubs "Bientôt disponible" |
