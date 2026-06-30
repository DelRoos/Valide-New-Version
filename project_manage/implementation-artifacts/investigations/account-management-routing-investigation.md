# Investigation: Module gestion de compte — parcours et routes

## Hand-off Brief

1. **Ce qui s'est passé.** Le module gestion de compte (`features/account`) contient 4 anomalies **Confirmed** : deux routes inexistantes utilisées dans `profile_settings_page.dart`, une logique de suppression de compte dupliquée et incohérente dans `profile_tab_page.dart`, et un fichier `_main_bottom_nav.dart` zombi référençant des routes fantômes.
2. **Où en est le cas.** Conclu — toutes les causes racines sont **Confirmed** par lecture directe du code. Aucune hypothèse ouverte.
3. **Ce qu'il faut faire.** Lancer `/bmad-quick-dev` pour BUG-1 et BUG-2 (corrections de route simples < 5 lignes), puis un `bmad-create-story` pour BUG-3 (unification de la logique de suppression) et une chore PR séparée pour supprimer le dead code.

---

## Case Info

| Field            | Value                                                                         |
| ---------------- | ----------------------------------------------------------------------------- |
| Ticket           | N/A — investigation préventive                                                |
| Date opened      | 2026-06-29                                                                    |
| Status           | **Concluded**                                                                 |
| System           | Flutter / go_router / Riverpod — branche `feat/A-2-public-profile`           |
| Evidence sources | `lib/core/routing/app_router.dart`, `lib/features/account/`, `lib/features/dashboard/presentation/` |

---

## Problem Statement

L'utilisateur signale que le module gestion de compte ne fonctionne pas bien. Investigation du parcours complet et de l'intégration des routes dans le pipeline GoRouter.

---

## Evidence Inventory

| Source                                                  | Status    | Notes                                              |
| ------------------------------------------------------- | --------- | -------------------------------------------------- |
| `lib/core/routing/app_router.dart`                      | Available | Table de vérité des routes — lu intégralement      |
| `lib/features/account/presentation/profile_settings_page.dart` | Available | 2 routes invalides identifiées                |
| `lib/features/dashboard/presentation/profile_tab_page.dart` | Available | Logique de suppression dupliquée               |
| `lib/features/dashboard/presentation/_main_bottom_nav.dart` | Available | Fichier orphelin, routes fantômes              |
| `lib/features/account/providers.dart`                   | Available | Providers suppression compte                       |
| `lib/features/onboarding/providers.dart`                | Available | `publicProfileProvider` (Story A.2)               |
| `lib/features/onboarding/data/user_profile_repository_firestore_impl.dart` | Available | `fetchPublicProfile` implémenté |

---

## Confirmed Findings

### Finding 1 — BUG : Bouton retour de `ProfileSettingsPage` navigue vers `/profil` (route inexistante)

**Evidence :** `mobile_app/lib/features/account/presentation/profile_settings_page.dart:90`

```dart
onPressed: () => GoRouter.of(context).go('/profil'),
```

**Detail :** `/profil` n'est pas déclaré dans `app_router.dart`. La branche Shell du profil est à `/profile` (ligne 103 du router — `StatefulShellBranch` branche 3). GoRouter ne peut pas résoudre `/profil` et lancera une `Exception: No routes for location: /profil` (comportement go_router en mode debug) ou redirigera silencieusement vers la route initiale. Le back button de la page Paramètres est **cassé**.

---

### Finding 2 — BUG : CTA visiteur de `ProfileSettingsPage._VisitorMessage` navigue vers `/onboarding/account` (route inexistante)

**Evidence :** `mobile_app/lib/features/account/presentation/profile_settings_page.dart:308`

```dart
onPressed: () => GoRouter.of(context).go('/onboarding/account'),
```

**Detail :** `/onboarding/account` n'est pas déclaré dans `app_router.dart`. La seule route onboarding existante est `/onboarding/v2` (ligne 142). La string `/onboarding/account` provient d'une décision antérieure au refactor E1bis (mentionnée dans les ARB keys `l10n.generated/app_localizations.dart:719` et `:1535`). L'encadré visiteur « Créer un compte » depuis la page Paramètres ne navigue **nulle part**.

---

### Finding 3 — BUG : Logique de suppression de compte dupliquée et incohérente dans `ProfileTabPage`

**Evidence :** `mobile_app/lib/features/dashboard/presentation/profile_tab_page.dart:50-88`

```dart
void _onDeleteAccount(BuildContext context, WidgetRef ref) {
  showDialog<bool>(...).then((confirmed) async {
    // 1. Supprimer le document Firestore en ligne
    await firestore.collection('users').doc(user.uid).delete();
    // 2. Terminer les listeners puis vider le cache offline
    await firestore.terminate();
    await firestore.clearPersistence();
    // 3. Supprimer le compte Auth
    await user.delete();
  });
}
```

**Detail :** Cette implémentation :
- **Supprime immédiatement** (pas de délai 7 jours) en contredisant directement la Story 1.10 (workflow `requestAccountDeletion` via Cloud Function)
- Bypass `AccountDeletionRepository` et `accountDeletionStatusNotifierProvider` — aucun feedback toast, aucune machine à états, aucune annulation possible
- Catch silencieux (`catch (_) {}`) sur le delete Firestore — violation CLAUDE.md règle 13 (anti-pattern catch silencieux)
- Strings UI hardcodées (`'Supprimer le compte'`, `'Toutes tes données...'`) — pas de clé ARB, pas de i18n

La bonne implémentation est dans `ProfileSettingsPage` (route `/profil/settings`) via `accountDeletionStatusNotifierProvider.requestDeletion()`. Les deux coexistent dans l'app : l'onglet Profil (`/profile`) expose le chemin cassé, et la page Paramètres expose le chemin correct.

---

### Finding 4 — DEAD CODE : `MainBottomNav` orphelin référençant des routes fantômes

**Evidence :** `mobile_app/lib/features/dashboard/presentation/_main_bottom_nav.dart:17`

```dart
static const _routes = ['/dashboard', '/matieres', '/activites', '/profil'];
```

**Detail :** `MainBottomNav` n'est importé nulle part (grep confirmé). Le `_main_shell.dart` gère sa propre nav bar `_StyledNavBar` avec `goBranch()` — c'est l'implémentation active depuis la refactorisation `StatefulShellRoute`. Les routes `/matieres`, `/activites`, `/profil` n'existent pas dans le router. Pas d'impact runtime car le fichier est inutilisé, mais crée de la confusion lors de la maintenance.

---

## Deduced Conclusions

### Déduction 1 — Origine : refactorisation `StatefulShellRoute` incomplète

**Basé sur :** Findings 1, 4

**Raisonnement :** Avant la refactorisation vers `StatefulShellRoute` (implémentée dans `_main_shell.dart`), le shell utilisait probablement un `GoRoute` avec `NavigationBar` externe (`MainBottomNav`). Les routes `/matieres`, `/activites`, `/profil` étaient des destinations directes. Après le refactor, les branches du shell utilisent `/courses`, `/exams`, `/profile`. La page `ProfileSettingsPage` conserve un `go('/profil')` hérité de l'ancienne structure, et `_main_bottom_nav.dart` n'a pas été supprimé.

**Conclusion :** Le bouton back de `ProfileSettingsPage` doit pointer vers `/profile` (onglet shell) ou simplement faire `context.pop()` / `Navigator.of(context).maybePop()`.

---

### Déduction 2 — `ProfileTabPage._onDeleteAccount` est une implémentation préliminaire non retirée

**Basé sur :** Finding 3

**Raisonnement :** `profile_tab_page.dart` commente `// 3. Supprimer le compte Auth → déclenche le redirect vers onboarding`, ce qui correspond au schéma MVP "rapide" antérieur à Story 1.10. Story 1.10 a ajouté `ProfileSettingsPage` avec le workflow 7 jours, mais l'ancienne implémentation dans l'onglet Profil n'a pas été retirée.

**Conclusion :** Le menu "Supprimer le compte" dans `ProfileTabPage` doit soit (a) disparaître et renvoyer vers `/profil/settings`, soit (b) être remplacé par l'appel à `accountDeletionStatusNotifierProvider`.

---

## Source Code Trace

| Element       | Detail                                                                                           |
| ------------- | ------------------------------------------------------------------------------------------------ |
| BUG-1 origin  | `profile_settings_page.dart:90` — `GoRouter.of(context).go('/profil')`                         |
| BUG-1 trigger | Tap sur le bouton back (AppBar leading) de `ProfileSettingsPage`                                |
| BUG-1 condition | Toujours (la route `/profil` n'existe jamais)                                                 |
| BUG-2 origin  | `profile_settings_page.dart:308` — `GoRouter.of(context).go('/onboarding/account')`            |
| BUG-2 trigger | Tap sur le CTA "Créer un compte" dans `_VisitorMessage` (user anonyme)                         |
| BUG-2 condition | Toujours (la route `/onboarding/account` n'existe jamais)                                     |
| BUG-3 origin  | `profile_tab_page.dart:50-88` — `_onDeleteAccount()`                                           |
| BUG-3 trigger | Tap sur "Supprimer le compte" dans la section "Compte" du menu profil                          |
| BUG-3 condition | User authentifié (non-anonyme)                                                                |
| Dead code     | `_main_bottom_nav.dart` — `MainBottomNav` classe non importée nulle part                       |

---

## Conclusion

**Confidence : High** — toutes les causes racines sont directement observables dans le code.

Le module gestion de compte présente **3 bugs actifs** :

1. **BUG-1** (sévérité : moyenne) — Bouton back cassé sur `ProfileSettingsPage` : `go('/profil')` → route inconnue.
2. **BUG-2** (sévérité : haute) — CTA "Créer un compte" visiteur cassé : `go('/onboarding/account')` → route inconnue. L'utilisateur anonyme ne peut pas initier la création de compte depuis les paramètres.
3. **BUG-3** (sévérité : critique) — Double implémentation de la suppression de compte : `ProfileTabPage._onDeleteAccount()` supprime immédiatement et silencieusement, contredisant le workflow 7 jours de Story 1.10.

Et **1 dette** :
- DEAD-1 — `_main_bottom_nav.dart` orphelin à supprimer (chore).

---

## Recommended Next Steps

### Fix direction

**BUG-1 + BUG-2 — Corrections de routes (`/bmad-quick-dev`, 1 fichier, < 10 lignes)**
- `profile_settings_page.dart:90` : remplacer `go('/profil')` par `Navigator.of(context).maybePop()` (le back depuis un `push` dépile correctement).
- `profile_settings_page.dart:308` : remplacer `go('/onboarding/account')` par `go('/onboarding/v2')`.

**BUG-3 — Unification logique suppression compte (story dédiée recommandée)**
- Option A (conservatrice) : supprimer `_onDeleteAccount` de `ProfileTabPage` et remplacer le menu item "Supprimer le compte" par un item qui fait `context.push('/profil/settings')`. Délègue tout à `ProfileSettingsPage`.
- Option B (UX fluide) : remplacer `_onDeleteAccount` par un appel à `accountDeletionStatusNotifierProvider.notifier.requestDeletion()` avec les toasts localisés (copier le pattern de `ProfileSettingsPage`). Évite le push vers `/profil/settings`.
- **Recommandation : Option A** — une seule source de vérité, moins de surface à maintenir.

**DEAD-1 — Supprimer le fichier zombi (chore PR séparée, 1 fichier)**
- Supprimer `lib/features/dashboard/presentation/_main_bottom_nav.dart`.

### Diagnostic

Aucun diagnostic supplémentaire requis — root cause entièrement confirmée par lecture statique.

---

## Reproduction Plan

**BUG-2** (le plus impactant à tester) :
1. Lancer l'app avec un compte anonyme (pas de compte lié Google/Apple).
2. Onglet Profil → item "Compte" → "Paramètres du compte".
3. Observer la section visiteur (encadré info bleu).
4. Tapper "Créer un compte" → **attendu** : navigation vers `/onboarding/v2` ; **actuel** : erreur GoRouter ou freeze.

**BUG-3** :
1. Se connecter avec un compte réel (Google/Apple).
2. Onglet Profil → section "Compte" → "Supprimer le compte".
3. Confirmer → **attendu** : Cloud Function planifiée à J+7, toast "Suppression prévue le XX/XX" ; **actuel** : suppression Firestore + auth immédiate, app redirigée vers onboarding sans toast.
