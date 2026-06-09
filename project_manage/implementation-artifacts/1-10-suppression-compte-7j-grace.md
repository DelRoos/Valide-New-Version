---
story_id: 1.10
title: Suppression compte avec delai grace 7 jours (FR-7)
epic: 1
phase: P1
status: ready-for-dev
created: 2026-06-09
branch: feat/1.10-suppression-compte-7j-grace
baseline_commit: 2511cd5  # merge PR #57 (Story 1.8 done)
estimation: M (~5h)
dependencies:
  - 1.5   # profileCompletionProvider + evaluateRedirect (garde + auto-cancel au boot)
  - 1.6   # AccountLinkingRepository + compte permanent (suppression == compte permanent essentiellement)
  - 1.9   # /dashboard + bottom nav + onglet /profil placeholder
sourceArtifacts:
  - project_manage/planning-artifacts/epics/epic-1-onboarding.md § Story 1.10 (lignes 1091-1170)
  - project_manage/planning-artifacts/prds/prd-valide-mvp-2026-06-03/prd.md § FR-7
  - doc/partage/CONTRATS-API.md § requestAccountDeletion (lignes 513-528, deja documente)
  - doc/partage/BASE-DE-DONNEES.md § users/{uid} (deletionRequestedAt deja au schema)
  - mobile_app/lib/core/widgets/app_button.dart (Story 0.13 — ajout variant danger)
  - mobile_app/lib/features/dashboard/presentation/dashboard_page.dart (Story 1.9 — banner deletion)
  - mobile_app/lib/features/dashboard/presentation/placeholder_tab_page.dart (Story 1.9 — onglet profil cible)
  - mobile_app/lib/core/firebase/providers.dart (cloudFunctionsProvider Story 0.6 — region europe-west1)
---

# Story 1.10 — Suppression compte avec delai grace 7 jours (FR-7)

Status: **ready-for-dev**

## Objectif

Livrer **FR-7 (RGPD-like)** : un utilisateur peut demander la suppression de son compte avec une periode de grace de 7 jours pour pouvoir changer d'avis. La purge effective est faite par un cron quotidien backend (hors scope mobile).

**Pourquoi maintenant** : derniere story Epic 1, livre une fonctionnalite compliance attendue par les stores (Apple/Google exigent une option de suppression de compte in-app pour valider l'app). Permet aussi de cloturer Epic 1 proprement.

**Pourquoi 7 jours** : protection contre les regrets impulsifs (PRD ligne 179) + temps suffisant pour un reset password / reconnexion / annulation. Aligne avec RGPD article 17 (droit a l'oubli) + jurisprudence app stores.

**Hors scope** :

- Implementation Cloud Function `requestAccountDeletion` + `cancelAccountDeletion` (HORS SCOPE — equipe backend, autre depot)
- Cron quotidien de purge (HORS SCOPE — equipe backend)
- Affichage historique des donnees / export RGPD (V2 si besoin reglementaire)
- Suppression de compte visiteur Anonymous Auth (V2 — un visiteur sans compte permanent ne peut pas "supprimer" car rien n'est lie a son identite verifiable)

**Critere de fin** :

- Fatou (compte Google permanent) navigue `/profil` -> tap "Parametres" -> arrive sur `/profil/settings`
- Voit en bas une section "Zone de danger" avec bouton rouge "Supprimer mon compte"
- Tap dessus -> modale "Es-tu sure ?" + texte explicite "Ton compte sera supprime dans 7 jours"
- Tap "Confirmer la suppression" -> spinner + appel Cloud Function `requestAccountDeletion` -> succes toast "Demande enregistree. Reconnecte-toi avant le DD/MM/YYYY pour annuler"
- Au prochain ouverture (ou retour sur /dashboard) : banner warning en haut "Ton compte sera supprime le DD/MM/YYYY. Cliquer pour annuler"
- Tap banner -> modale "Annuler la suppression ?" -> appel `cancelAccountDeletion` -> toast "Suppression annulee, ton compte est de nouveau actif"

Cas Edge :

- Cloud Function non deployee (backend pas pret) : erreur gracieuse, message "Fonctionnalite bientot disponible" + log warning
- Reseau coupe : erreur reseau standard, retry possible
- Tap rapide double sur "Confirmer" : debounce 1s + bouton disabled pendant l'appel
- Auto-cancel au boot apres relance : si user revient apres avoir demande suppression et `deletionRequestedAt` non null, l'app appelle `cancelAccountDeletion` automatiquement (cf. AC5)
- Compte deja supprime (J+7 depasse + cron passe) : sign-in echoue avec `auth/user-not-found` -> redirect `/onboarding/subsystem` + toast "Ton compte n'existe plus, recommence un nouveau profil"
- Visiteur Anonymous Auth qui clique sur "Supprimer" : section masquee OU desactivee + message "Cree d'abord un compte permanent pour pouvoir le supprimer"

## Story

**As an** eleve qui veut quitter Valide,
**I want** demander la suppression de mon compte avec un delai de grace de 7 jours pour pouvoir changer d'avis,
**so that** FR-7 (RGPD-like) soit respecte et que je ne perde pas definitivement mes donnees par erreur.

## Decision technique : `cancelAccountDeletion` est un NOUVEAU contrat backend a ajouter

`doc/partage/CONTRATS-API.md` documente deja `requestAccountDeletion` (Phase 1, lignes 513-528) mais PAS `cancelAccountDeletion`. Story 1.10 ajoute ce contrat avec :

```typescript
interface CancelAccountDeletionResponse {
  cancelled: boolean;  // true si deletionRequestedAt etait pose, false si deja annule ou jamais demande
}
```

**Effet** : `users/{uid}.deletionRequestedAt = null` (FieldValue.delete). Pas d'erreur si deja null (idempotent).

**Action porteur** : commenter @backend-team sur la PR pour formaliser l'accord (CLAUDE.md regle surface partagee).

**Mobile-side fallback** : si la fonction n'est pas encore deployee, l'appel echoue avec `not-found` -> gere gracefully via `AppLogger.w` + toast "Fonctionnalite bientot disponible". L'app reste utilisable.

## Acceptance Criteria

### AC1 — AppButton.danger variant (Story 0.13 extension)

**Given** la palette de tokens (`AppColors.danger` = rouge semantique #DC2626) deja livree Story 0.10
**When** une feature a besoin d'un bouton "action destructrice"
**Then** `AppButton.danger(label: ..., onPressed: ...)` est disponible (3eme variant apres primary + secondary)
**And** son apparence est : fond rouge `AppColors.danger`, texte blanc `AppColors.card`, meme hauteur 52.h, meme padding s5.w
**And** son haptic preset = `HapticPreset.heavy` (intention destructive, feedback plus fort)

### AC2 — ProfileSettingsPage minimale

**Given** un utilisateur authentifie compte permanent (`isAnonymous == false`)
**When** il navigue vers `/profil/settings`
**Then** une `Scaffold` simple s'affiche avec :

- AppBar titre "Parametres" + bouton retour (-> /profil)
- Section "Mon compte" (informative) : email du compte Google/Apple + provider icon
- Section "Zone de danger" en bas (couleur subtile bordure danger, fond `AppColors.dangerSoft`)
  - Titre "Supprimer mon compte"
  - Texte explicatif "Cette action est irreversible apres 7 jours."
  - `AppButton.danger` "Supprimer mon compte"

**And** si l'utilisateur est visiteur (`isAnonymous == true`), la section "Zone de danger" est REMPLACEE par un message info "Cree d'abord un compte permanent pour pouvoir le supprimer" + bouton secondary "Creer mon compte" -> `/onboarding/account` (Story 1.6).

### AC3 — Acces depuis l'onglet Profil placeholder Story 1.9

**Given** un utilisateur sur l'onglet "Profil" du bottom nav Story 1.9 (`/profil` placeholder "Bientot disponible")
**When** il regarde la page
**Then** un bouton secondaire "Parametres" est ajoute en bas (au-dessus du bottom nav)
**And** au tap -> `context.go('/profil/settings')`

**Implementation** : modification mineure de `PlaceholderTabPage` Story 1.9 — quand `tabIndex == 3` (Profil), ajouter un bouton "Parametres" sous le texte "Bientot disponible". Ne pas changer le comportement pour les autres onglets.

### AC4 — Modale de confirmation + appel Cloud Function

**Given** l'utilisateur sur `/profil/settings` tape sur "Supprimer mon compte"
**When** la modale `showDialog` s'ouvre
**Then** elle affiche :

- Titre "Es-tu sure ?"
- Texte "Ton compte sera supprime dans 7 jours. Tu peux annuler a tout moment en te reconnectant pendant cette periode."
- `AppButton.secondary` "Annuler" (ferme la modale)
- `AppButton.danger` "Confirmer la suppression"

**And** au tap "Confirmer la suppression" :

1. Bouton danger passe en `loading: true` (spinner inline)
2. Appel `cloudFunctionsProvider.httpsCallable('requestAccountDeletion').call({})`
3. **Succes** : modale se ferme + `AppToast.info("Demande enregistree. Reconnecte-toi avant le {date+7j} pour annuler.")` + `AppLogger.i('Account deletion requested')` (PAS d'uid en clair — CLAUDE.md securite 4)
4. **Echec reseau** : `AppToast.warning("Pas de connexion. Reessaie plus tard.")` + bouton revient a l'etat normal (retry possible)
5. **Echec function-not-found** : `AppToast.warning("Fonctionnalite bientot disponible")` + `AppLogger.w('requestAccountDeletion not deployed')` + bouton revient a l'etat normal
6. **Autre echec** : `AppToast.warning("Erreur, reessaie plus tard")` + log warn

**And** tap rapide double sur "Confirmer" est ignore (debounce via `loading` state).

### AC5 — Banner warning sur DashboardPage (Story 1.9)

**Given** un utilisateur avec `users/{uid}.deletionRequestedAt != null` (timestamp Firestore)
**When** il ouvre `/dashboard`
**Then** un banner en haut (au-dessus du Hero Story 1.9) s'affiche :

- Background `AppColors.warningSoft`
- Texte "Ton compte sera supprime le {date+7j format DD/MM/YYYY}. Toucher pour annuler."
- Icone `LucideIcons.triangleAlert` a gauche
- Tap n'importe ou sur le banner -> AppToast info + appel `cancelAccountDeletion`

**And** quand `deletionRequestedAt` redevient null (apres cancel succes), le banner disparait au prochain tick du stream.

**Implementation** : modification mineure de `DashboardPage` Story 1.9 — `StreamBuilder<Map<String, dynamic>?>` lit `data['deletionRequestedAt']` ; si non null, render banner avant le Hero. Reutilise `userProfileRepositoryProvider.watchProfile()` deja consomme.

### AC6 — Auto-cancel au boot (annulation automatique par reconnexion)

**Given** un utilisateur avec `deletionRequestedAt` pose qui revient sur l'app apres avoir ete deconnecte ou kill app
**When** au boot l'auth state est restaure (Firebase Auth SDK natif) + `profileCompletionProvider` se charge
**Then** l'app detecte `deletionRequestedAt != null` au stream + appelle automatiquement `cancelAccountDeletion`
**And** un toast info confirme "Ton compte est de nouveau actif" (apres succes)
**And** si l'appel echoue (reseau), pas de toast (eviter spam), juste un `AppLogger.w` + retry au prochain boot

**Implementation** : un nouveau provider `autoAccountDeletionCancellerProvider` watch le profile stream + declenche le call quand `deletionRequestedAt` apparait au boot. Mecanisme une-fois-par-session via `bool` interne.

**Note conservative** : ne pas faire le call SUR LE BOOT si le user vient juste de demander la suppression (timestamp recent). Heuristique : ne declencher l'auto-cancel que si le timestamp `deletionRequestedAt` est anterieur a la session courante (i.e. l'app vient d'etre relance). Eviter de cancel immediatement apres un request.

### AC7 — Modale "Annuler la suppression" depuis banner dashboard

**Given** un utilisateur sur `/dashboard` avec banner deletion visible
**When** il tape sur le banner
**Then** une modale `showDialog` s'ouvre :

- Titre "Annuler la suppression ?"
- Texte "Ton compte ne sera plus supprime. Tu peux toujours en demander la suppression plus tard."
- `AppButton.secondary` "Non, garder la suppression"
- `AppButton.primary` "Oui, annuler la suppression"

**And** au tap "Oui, annuler" :

1. Bouton primary loading
2. Appel `cloudFunctionsProvider.httpsCallable('cancelAccountDeletion').call({})`
3. Succes : modale ferme + `AppToast.info("Suppression annulee.")` + banner disparait (prochain stream tick)
4. Echec : `AppToast.warning("Erreur, reessaie plus tard.")` + bouton revient normal

### AC8 — Mise a jour doc/partage/CONTRATS-API.md (accord backend requis)

**Given** la PR finalisee
**Then** :

- `doc/partage/CONTRATS-API.md` § Phase 1 ajoute `cancelAccountDeletion` apres `requestAccountDeletion` :

```typescript
### cancelAccountDeletion (NEW Story 1.10)

**Type** : onCall
**Auth requise** : oui

**Entree** : {}

**Sortie** :
{
  cancelled: boolean;  // true si deletionRequestedAt etait pose, false si deja annule
}

**Effet** : users/{uid}.deletionRequestedAt = FieldValue.delete. Idempotent.
```

- Action porteur : ajouter commentaire `@backend-team approval requested` sur la PR ouvrant Story 1.10. Pas bloquant pour le merge (le contrat est consomme cote mobile + stubbe gracefully si non deploye).

### AC9 — i18n + tests + qualite

**Given** la PR finalisee
**Then** :

- **i18n** : ~12 nouvelles cles ARB FR + EN :
  - `profileSettingsTitle` ("Parametres" / "Settings")
  - `profileSettingsAccountSection` ("Mon compte" / "My account")
  - `profileSettingsDangerSection` ("Zone de danger" / "Danger zone")
  - `profileSettingsDeleteCta` ("Supprimer mon compte" / "Delete my account")
  - `profileSettingsDeleteSubtitle` ("Cette action est irreversible apres 7 jours." / "This action is irreversible after 7 days.")
  - `profileSettingsVisitorMessage` ("Cree d'abord un compte permanent pour pouvoir le supprimer" / "Create a permanent account first to delete it")
  - `accountDeletionConfirmTitle` ("Es-tu sure ?" / "Are you sure?")
  - `accountDeletionConfirmBody` ("Ton compte sera supprime dans 7 jours. Tu peux annuler a tout moment en te reconnectant pendant cette periode." / equivalent EN)
  - `accountDeletionConfirmCta` ("Confirmer la suppression" / "Confirm deletion")
  - `accountDeletionRequestedToast` ("Demande enregistree. Reconnecte-toi avant le {date} pour annuler." parametree ICU)
  - `accountDeletionScheduledBanner` ("Ton compte sera supprime le {date}. Toucher pour annuler." parametree ICU)
  - `accountDeletionCancelConfirmTitle` ("Annuler la suppression ?" / "Cancel deletion?")
  - `accountDeletionCancelConfirmCta` ("Oui, annuler la suppression" / "Yes, cancel deletion")
  - `accountDeletionCancelledToast` ("Suppression annulee." / "Deletion cancelled.")
  - `accountDeletionAutoCancelledToast` ("Ton compte est de nouveau actif." / "Your account is active again.")
  - `accountDeletionNotAvailableToast` ("Fonctionnalite bientot disponible." / "Feature coming soon.")
  - `dashboardTabSettingsCta` ("Parametres" / "Settings")
- **Tests Flutter** :
  - `test/features/account/data/account_deletion_repository_test.dart` NEW (~3 cas : request succes + cancel succes + function-not-found gracefull)
  - `test/features/account/presentation/profile_settings_page_test.dart` NEW (~3 cas : danger zone visible compte permanent, message visiteur si Anonymous, tap delete -> modale)
  - `test/core/widgets/app_button_danger_test.dart` NEW (~2 cas : variant danger render + couleur danger correcte)
  - `test/features/dashboard/presentation/dashboard_page_test.dart` UPDATE (+1 cas : banner deletion visible si deletionRequestedAt set)
- **Tests rules** : aucune modification de regles Firestore (`users/{uid}.deletionRequestedAt` est ecrit UNIQUEMENT par Cloud Function — pas de regle client a ajouter, le client ne peut deja pas ecrire ce champ via les regles Story 1.3 immutability)
- **Firestore indexes (CLAUDE.md regle 9)** : aucun nouvel index (pas de nouvelle query, lecture via `userProfileRepository.watchProfile()` deja en place)
- `flutter analyze` 0 issue
- `flutter test` vert (196 baseline Story 1.8 -> ~205 cible, +9)
- **PR ≤ 350 lignes diff** (story M, plus complexe que 1.8)
- Commit : `feat(profile): suppression compte avec delai grace 7 jours (Story 1.10)`

## Tasks / Subtasks

- [ ] **T1 — Variant AppButton.danger (Story 0.13 extension)** (AC1)
  - [ ] T1.1 — Etendre `mobile_app/lib/core/widgets/app_button.dart` enum `_ButtonVariant` avec `danger`
  - [ ] T1.2 — Ajouter factory `AppButton.danger(...)` + branches dans `build()` (couleur fond `AppColors.danger`, fg `AppColors.card`)
  - [ ] T1.3 — Mettre haptic preset `HapticPreset.heavy` ou `.medium` pour action destructive
  - [ ] T1.4 — 2 tests : variant danger render + couleur danger applique

- [ ] **T2 — Domain AccountDeletion (NEW feature folder)** (AC4, AC7)
  - [ ] T2.1 — Creer `mobile_app/lib/features/account/domain/account_deletion_repository.dart` (abstract + sealed `AccountDeletionFailure` : networkFailure, functionNotFound, unknown)
  - [ ] T2.2 — Pas de model specifique : on retourne `Either<AccountDeletionFailure, void>` pour request + cancel

- [ ] **T3 — Data AccountDeletionRepositoryImpl (NEW)** (AC4, AC7)
  - [ ] T3.1 — Creer `mobile_app/lib/features/account/data/account_deletion_repository_impl.dart`
  - [ ] T3.2 — Injecter `FirebaseFunctions` (via `cloudFunctionsProvider` Story 0.6, region europe-west1)
  - [ ] T3.3 — `requestAccountDeletion()` : `httpsCallable('requestAccountDeletion').call({})` + map FirebaseFunctionsException -> Left
    - `not-found` (function pas deployee) -> `AccountDeletionFailure.functionNotFound`
    - `unavailable` / `deadline-exceeded` -> `networkFailure`
    - autres -> `unknown`
  - [ ] T3.4 — `cancelAccountDeletion()` : meme pattern
  - [ ] T3.5 — `AppLogger.i('Account deletion requested')` SANS uid en clair (CLAUDE.md securite 4)

- [ ] **T4 — Providers AccountDeletion (NEW)** (AC4, AC5, AC6, AC7)
  - [ ] T4.1 — Creer `mobile_app/lib/features/account/providers.dart` avec :
    - `accountDeletionRepositoryProvider` (Provider, lazy)
    - `AccountDeletionStatusNotifier` (Notifier idle/requesting/requested/cancelling/cancelled/error) + provider
    - `autoAccountDeletionCancellerProvider` (Provider qui watch profile stream + declenche cancel auto au boot UNE FOIS)
  - [ ] T4.2 — `autoAccountDeletionCancellerProvider` : flag `bool _alreadyCancelled` interne, ref.listen sur `userProfileRepository.watchProfile()`, condition `deletionRequestedAt != null && timestamp < sessionStart`

- [ ] **T5 — Presentation ProfileSettingsPage (NEW)** (AC2)
  - [ ] T5.1 — Creer `mobile_app/lib/features/account/presentation/profile_settings_page.dart` (ConsumerWidget)
  - [ ] T5.2 — Read `firebaseAuthProvider.currentUser` -> `isAnonymous` + `email` + `providerData[0].providerId` (google.com / apple.com)
  - [ ] T5.3 — Section "Mon compte" : email + icone provider (LucideIcons.globe pour google, LucideIcons.apple pour apple)
  - [ ] T5.4 — Section "Zone de danger" si `!isAnonymous` :
    - AppCard background `AppColors.dangerSoft` border `AppColors.danger`
    - Texte explicatif
    - `AppButton.danger` "Supprimer mon compte" -> tap = open modale (T6)
  - [ ] T5.5 — Section "Pas de compte permanent" si `isAnonymous` :
    - AppCard info `AppColors.skySoft`
    - Texte "Cree d'abord un compte permanent"
    - `AppButton.secondary` "Creer mon compte" -> `/onboarding/account`

- [ ] **T6 — Modale confirmation suppression (NEW)** (AC4)
  - [ ] T6.1 — Helper `_showDeleteConfirmDialog(BuildContext context, WidgetRef ref)` dans `profile_settings_page.dart`
  - [ ] T6.2 — `showDialog<bool>` avec AlertDialog : titre, body, 2 boutons (cancel / danger)
  - [ ] T6.3 — Si confirmation = true : appel `ref.read(accountDeletionStatusNotifierProvider.notifier).requestDeletion()`
  - [ ] T6.4 — Bouton "Confirmer la suppression" passe en `loading: true` via le notifier
  - [ ] T6.5 — Pattern `ref.listen` sur le notifier pour fermer la modale + afficher toast au resultat

- [ ] **T7 — Banner deletion sur DashboardPage (UPDATE Story 1.9)** (AC5)
  - [ ] T7.1 — Modifier `mobile_app/lib/features/dashboard/presentation/dashboard_page.dart`
  - [ ] T7.2 — Dans le `StreamBuilder<Map<String, dynamic>?>`, lire aussi `data['deletionRequestedAt']` (Timestamp Firestore)
  - [ ] T7.3 — Si non null, calculer `scheduledDate = deletionRequestedAt + 7 jours` (formate DD/MM/YYYY via `intl.DateFormat`)
  - [ ] T7.4 — Render `_DeletionBanner` widget au-dessus du Hero : Container `AppColors.warningSoft` + icone triangleAlert + texte + tap = open `_showCancelDeletionDialog`
  - [ ] T7.5 — Modale "Annuler la suppression ?" + 2 boutons + appel `cancelDeletion()`

- [ ] **T8 — Cta "Parametres" sur onglet Profil placeholder (UPDATE Story 1.9)** (AC3)
  - [ ] T8.1 — Modifier `mobile_app/lib/features/dashboard/presentation/placeholder_tab_page.dart`
  - [ ] T8.2 — Si `tabIndex == 3` (Profil), ajouter sous le texte "Bientot disponible" un `AppButton.secondary("Parametres", onPressed: () => context.go('/profil/settings'))`
  - [ ] T8.3 — Conserve le comportement Story 1.9 pour les autres onglets (Matieres, Activites)

- [ ] **T9 — Route /profil/settings (UPDATE app_router)** (AC2, AC3)
  - [ ] T9.1 — Ajouter `GoRoute(path: '/profil/settings', builder: ... => const ProfileSettingsPage())` dans `app_router.dart`
  - [ ] T9.2 — Verifier que la route passe le redirect Story 1.5 (profile complete) + Story 1.8 smart resume — `/profil/settings` est une route metier, garde Story 1.5 s'applique

- [ ] **T10 — Auto-cancel au boot (UPDATE main.dart ou app.dart)** (AC6)
  - [ ] T10.1 — Au startup app, ref.read le `autoAccountDeletionCancellerProvider` pour qu'il se mette en route
  - [ ] T10.2 — Heuristique session : capturer `sessionStartTime = DateTime.now()` au boot ; auto-cancel uniquement si `deletionRequestedAt.toDate() < sessionStartTime` (timestamp anterieur)
  - [ ] T10.3 — `AppToast.info` "Ton compte est de nouveau actif" via `BuildContext` (besoin du `navigatorKey` ou observer router) — alternative simple : show toast au prochain build de `/dashboard` apres detection auto-cancel reussi

- [ ] **T11 — doc/partage/CONTRATS-API.md (UPDATE accord backend)** (AC8)
  - [ ] T11.1 — Ajouter `cancelAccountDeletion` apres `requestAccountDeletion` (lignes ~530)
  - [ ] T11.2 — Format identique au pattern existant (Type onCall, Auth requise, Entree {}, Sortie typed, Effet)
  - [ ] T11.3 — Ajouter @backend-team approval requested dans le PR description

- [ ] **T12 — i18n** (AC9)
  - [ ] T12.1 — Ajouter ~17 cles dans `mobile_app/lib/l10n/app_fr.arb` (descriptions + ICU pour les dates)
  - [ ] T12.2 — Versions EN equivalentes
  - [ ] T12.3 — `flutter gen-l10n` regenere AppLocalizations
  - [ ] T12.4 — Format dates : utiliser `DateFormat('dd/MM/yyyy', l10n.localeName)` cote presentation pour eviter d'integrer la date dans le template ARB (plus simple)

- [ ] **T13 — Tests Flutter** (AC9)
  - [ ] T13.1 — `test/features/account/data/account_deletion_repository_test.dart` NEW (~3 cas) :
    - (a) requestAccountDeletion succes -> Right(null) + log appele
    - (b) cancelAccountDeletion succes -> Right(null)
    - (c) FirebaseFunctionsException not-found -> Left(functionNotFound) + log warn
  - [ ] T13.2 — `test/features/account/presentation/profile_settings_page_test.dart` NEW (~3 cas) :
    - (a) compte permanent rendered : section "Zone de danger" + bouton danger visible
    - (b) visiteur Anonymous rendered : message info + bouton "Creer mon compte"
    - (c) tap "Supprimer mon compte" -> modale ouverte avec 2 boutons (assertion AlertDialog visible)
  - [ ] T13.3 — `test/core/widgets/app_button_danger_test.dart` NEW (~2 cas) :
    - (a) AppButton.danger rendered : couleur background == AppColors.danger
    - (b) AppButton.danger.onPressed null -> bouton disabled (parite avec primary/secondary)
  - [ ] T13.4 — `test/features/dashboard/presentation/dashboard_page_test.dart` UPDATE (+1 cas) :
    - (f) deletionRequestedAt set sur watchProfile data -> banner warning visible avec texte "Ton compte sera supprime"

- [ ] **T14 — Validation finale**
  - [ ] T14.1 — `flutter analyze` -> 0 issue
  - [ ] T14.2 — `flutter test` -> ~205 verts (196 baseline + ~9 nouveaux)
  - [ ] T14.3 — Aucun test rules a ajouter (`deletionRequestedAt` ecrit uniquement par Cloud Function)
  - [ ] T14.4 — Aucun deploiement Firestore indexes (CLAUDE.md regle 9 verifie)
  - [ ] T14.5 — Diff PR ≤ 350 lignes
  - [ ] T14.6 — Update story frontmatter `status: review` + sprint-status `review` + commit + push
  - [ ] T14.7 — PR description : mentionner @backend-team approval requested pour `cancelAccountDeletion`

## Dev Notes

### Architecture compliance (ADR-001 + ADR-006 + ADR-011)

- **Clean architecture** : `account/` nouveau feature folder avec `domain/` + `data/` + `presentation/` standards. `domain/` n'importe ni Firebase ni Flutter.
- **Pattern Either** : `AccountDeletionRepository` retourne `Future<Either<AccountDeletionFailure, void>>` pour les 2 methodes.
- **Cross-platform** : Cloud Functions callable est identique Android + iOS. AppButton.danger est rendu par Flutter (pas de divergence plateforme).
- **CLAUDE.md regle 9 (indexes Firestore)** : **AUCUN nouvel index requis**. Toutes les lectures passent par `userProfileRepository.watchProfile()` (par doc ID, auto-indexed) deja en place.

### Pattern : autoAccountDeletionCancellerProvider

```dart
final autoAccountDeletionCancellerProvider = Provider<void>((ref) {
  // Capture le moment du boot pour comparer aux deletionRequestedAt anciens.
  final sessionStart = DateTime.now();
  bool alreadyHandled = false;

  ref.listen(userProfileRepositoryProvider.watchProfile(), (prev, next) {
    if (alreadyHandled) return;
    next.whenData((data) async {
      if (data == null) return;
      final ts = data['deletionRequestedAt'];
      if (ts is! Timestamp) return;
      // Ne cancel que si le timestamp est ANTERIEUR au boot
      // (eviter d'annuler immediatement apres un request user).
      if (ts.toDate().isBefore(sessionStart)) {
        alreadyHandled = true;
        await ref.read(accountDeletionRepositoryProvider).cancelAccountDeletion();
      }
    });
  });
});
```

**Note** : ce provider doit etre "amorce" au boot. On le fait via un `ref.read` dans `main.dart` ou un `Consumer` racine de `ValideApp`.

### Pattern : modale confirmation avec ref.listen

```dart
// Dans ProfileSettingsPage build()
ref.listen(accountDeletionStatusNotifierProvider, (prev, next) {
  next.maybeWhen(
    requested: () {
      Navigator.of(context).pop(); // Ferme la modale confirmation
      AppToast.show(context, message: l10n.accountDeletionRequestedToast(...), tone: ToastTone.info);
    },
    error: (failure) {
      // Garde la modale ouverte mais reset le loading state
      final message = switch (failure) {
        AccountDeletionFailureFunctionNotFound() => l10n.accountDeletionNotAvailableToast,
        AccountDeletionFailureNetwork() => l10n.errorNoConnection,
        _ => l10n.errorGeneric,
      };
      AppToast.show(context, message: message, tone: ToastTone.warning);
    },
    orElse: () {},
  );
});
```

### Pattern : variant AppButton.danger

```dart
// app_button.dart — etendre l'enum
enum _ButtonVariant { primary, secondary, danger }

factory AppButton.danger({
  Key? key,
  required String label,
  required VoidCallback? onPressed,
  bool loading = false,
  IconData? icon,
}) => AppButton._(
  key: key,
  label: label,
  onPressed: onPressed,
  variant: _ButtonVariant.danger,
  loading: loading,
  icon: icon,
);

// build() — branche danger
final bg = switch (_variant) {
  _ButtonVariant.primary => AppColors.primary,
  _ButtonVariant.secondary => AppColors.card,
  _ButtonVariant.danger => AppColors.danger,
};
final fg = switch (_variant) {
  _ButtonVariant.primary => AppColors.card,
  _ButtonVariant.secondary => AppColors.primary,
  _ButtonVariant.danger => AppColors.card,
};
final border = switch (_variant) {
  _ButtonVariant.primary => null,
  _ButtonVariant.secondary => Border.all(color: AppColors.primarySoftBorder),
  _ButtonVariant.danger => null,
};
```

### Anti-pattern : NE PAS logger l'uid en clair

```dart
// MAUVAIS — fuite identite dans les logs
AppLogger.i('Account deletion requested: uid=${user.uid}');

// BON — pas d'uid, juste le fait
AppLogger.i('Account deletion requested');
```

CLAUDE.md securite 4 : "JAMAIS logger : mots de passe, jetons, codes PIN, numeros de telephone complets, donnees personnelles sensibles". L'uid Firebase est un identifiant persistant -> a traiter comme PII.

### Anti-pattern : NE PAS auto-cancel immediatement apres un request

Si l'utilisateur tape "Confirmer la suppression" -> `deletionRequestedAt` pose -> stream emit -> `autoAccountDeletionCanceller` voit le timestamp et... annule immediatement la demande qu'il vient de faire. Boucle absurde.

Solution : comparer le timestamp au `sessionStartTime`. Si `deletionRequestedAt > sessionStart` -> c'est une demande FAITE PENDANT CETTE SESSION, ne pas auto-cancel. Si `deletionRequestedAt < sessionStart` -> c'est une demande d'une session anterieure, l'utilisateur revient -> auto-cancel approprie.

### Anti-pattern : NE PAS bloquer le user en cas de Cloud Function non deployee

Le backend pourrait ne pas avoir deploye `cancelAccountDeletion` au moment du merge. Au lieu de planter l'app, on log warn + on affiche un toast "Fonctionnalite bientot disponible" + on garde l'app utilisable. Le banner deletion reste affiche, le user re-essaie plus tard, ca passe quand le backend deploie.

### Anti-pattern : NE PAS exposer le bouton "Supprimer" aux visiteurs

Un visiteur Anonymous n'a rien a "supprimer" (pas de compte permanent). Afficher le bouton serait confus et l'appel Cloud Function echouerait avec `unauthenticated`. UI guard : `if (!isAnonymous) show danger zone else show "create account" message`.

### Cas edge : email + provider info dans ProfileSettingsPage

```dart
final user = ref.watch(firebaseAuthProvider).currentUser!;
final email = user.email; // Google/Apple posent ca dans linkWithCredential
final providerData = user.providerData;
final hasGoogle = providerData.any((p) => p.providerId == 'google.com');
final hasApple = providerData.any((p) => p.providerId == 'apple.com');
```

**Note securite** : `user.email` peut etre null si l'utilisateur a refuse de partager son email avec Apple Sign In (cas frequent iOS). Gerer le null gracefully : afficher "Compte lie" sans email plutot que "null".

### Securite CLAUDE.md § 4 (rappel)

- **JAMAIS** logger : `user.uid`, `user.email`, `user.displayName`, `idToken`, `accessToken`
- **OK** logger : "Account deletion requested" / "Account deletion cancelled" (booleens metier, pas d'identite)
- **JAMAIS** stocker la requete de suppression cote client : c'est la Cloud Function qui pose `deletionRequestedAt` cote serveur. Le client ne fait QUE le call + reagit au stream `watchProfile()`.

### File List (anticipee — Amelia complete)

**Nouveaux** :

- `mobile_app/lib/features/account/domain/account_deletion_repository.dart` (~30 lignes — abstract + sealed AccountDeletionFailure)
- `mobile_app/lib/features/account/data/account_deletion_repository_impl.dart` (~60 lignes — Cloud Functions impl + mapping FirebaseFunctionsException)
- `mobile_app/lib/features/account/providers.dart` (~70 lignes — repo + notifier + auto-canceller)
- `mobile_app/lib/features/account/presentation/profile_settings_page.dart` (~200 lignes — ConsumerWidget + sections + modale)
- `mobile_app/test/features/account/data/account_deletion_repository_test.dart` (~80 lignes — 3 cas)
- `mobile_app/test/features/account/presentation/profile_settings_page_test.dart` (~120 lignes — 3 cas)
- `mobile_app/test/core/widgets/app_button_danger_test.dart` (~50 lignes — 2 cas)

**Modifies** :

- `mobile_app/lib/core/widgets/app_button.dart` (+~20 lignes — variant danger)
- `mobile_app/lib/core/routing/app_router.dart` (+2 lignes — route /profil/settings)
- `mobile_app/lib/features/dashboard/presentation/dashboard_page.dart` (+~50 lignes — _DeletionBanner + modale cancel + StreamBuilder lit deletionRequestedAt)
- `mobile_app/lib/features/dashboard/presentation/placeholder_tab_page.dart` (+~10 lignes — bouton "Parametres" si tabIndex == 3)
- `mobile_app/lib/main.dart` ou `app.dart` (+1 ligne — ref.read autoAccountDeletionCancellerProvider au boot)
- `mobile_app/lib/l10n/app_fr.arb` (+~50 lignes — 17 cles avec descriptions)
- `mobile_app/lib/l10n/app_en.arb` (+~17 lignes — 17 cles)
- `mobile_app/lib/l10n/generated/app_localizations*.dart` (auto gen-l10n)
- `mobile_app/test/features/dashboard/presentation/dashboard_page_test.dart` (+~30 lignes — 1 nouveau cas banner deletion)
- `doc/partage/CONTRATS-API.md` (+~25 lignes — contrat cancelAccountDeletion + accord backend)
- `project_manage/implementation-artifacts/1-10-suppression-compte-7j-grace.md`
- `project_manage/implementation-artifacts/sprint-status.yaml`

### Change Log

| Date       | Auteur            | Modification                                                                |
| ---------- | ----------------- | --------------------------------------------------------------------------- |
| 2026-06-09 | Claude Opus 4.7   | Story 1.10 contexte engine cree — pattern fallback Cloud Function non deployee + autoAccountDeletionCanceller + AppButton.danger variant |

---

**Ultimate context engine analysis completed — comprehensive developer guide created.**

Cette story est `ready-for-dev`. Amelia (via `/bmad-dev-story`) a tout pour implementer :

- Architecture : feature folder `account/` standalone, AppButton.danger variant atomique, banner reutilise watchProfile stream existant
- 9 AC + 14 Tasks + Dev Notes avec 4 anti-patterns documentes
- Pattern critique : autoAccountDeletionCanceller compare timestamp au sessionStart (evite annulation immediate du request user)
- Fallback Cloud Function non deployee : pas de blocage, message clair "Fonctionnalite bientot disponible"
- doc/partage/CONTRATS-API.md : nouveau contrat `cancelAccountDeletion` documente, @backend-team approval requested dans la PR
- CLAUDE.md securite 4 : aucun log d'uid/email/displayName, juste les booleens metier
- AUCUN changement Firestore rules/indexes (deletionRequestedAt ecrit cote Cloud Function uniquement)
- Critere de sortie Epic 1 : FR-7 livre, Epic 1 cloture (1.1a/1.1b/1.1c + 1.2 + 1.3 + 1.4 + 1.5 + 1.6 + 1.7 + 1.8 + 1.9 + 1.10 done)
- PR ≤ 350 lignes diff (story M)
