# Plan de tests fonctionnels — Parcours pré-dashboard Valide School

> Version 1.0 · 2026-06-13 · Auteur : équipe Valide

## Sommaire

1. [Contexte et périmètre](#1-contexte-et-périmètre)
2. [Pré-requis testeurs](#2-pré-requis-testeurs)
3. [Cartographie du parcours](#3-cartographie-du-parcours)
4. [Parcours principaux (TF-1.x)](#4-parcours-principaux-golden-paths)
5. [Scénarios de robustesse (TF-2.x)](#5-scénarios-de-robustesse)
6. [Scénarios d'erreur et offline (TF-3.x)](#6-scénarios-derreur-et-offline)
7. [Tests par cursus scolaire (TF-4.x)](#7-tests-par-cursus-scolaire)
8. [Tests responsive (TF-5.x)](#8-tests-responsive)
9. [Tests internationalisation (TF-6.x)](#9-tests-internationalisation-frên)
10. [Tests UI/UX détaillés par étape (TF-7.x)](#10-tests-uiux-détaillés-par-étape)
11. [Tests d'accessibilité minimale (TF-8.x)](#11-tests-daccessibilité-minimale)
12. [Tests de performance (TF-9.x)](#12-tests-de-performance) — voir aussi `temps-de-chargement.md`
13. [Tests de sécurité / vie privée (TF-10.x)](#13-tests-de-sécurité--vie-privée)

---

## 1. Contexte et périmètre

### Ce qu'on teste

**Le parcours pré-dashboard de Valide School** : depuis le premier lancement de
l'app sur un téléphone neuf jusqu'à l'arrivée du user sur le Dashboard avec son
profil scolaire complet.

L'app cible les élèves du secondaire camerounais (12-19 ans), bilingue FR/EN,
sur **Android phone/tablet + iOS iPhone/iPad**.

### Le parcours en 10 étapes (canonique)

```
Splash native (instantané)
  ↓
Splash Flutter animé "VALIDE" (~2,1 s)
  ↓
[Catalogue waiting] (si Firestore vide ET cache vide)
  ↓
Étape 0 — Choix du sous-système (Francophone / Anglophone)
Étape 1 — Hero intro (3 features de l'app)
Étape 2 — Choix de la filière (Générale / Technique)
Étape 3 — Choix du niveau (selon sub-system + track)
Étape 4 — Choix de la série + matières (5 modes selon niveau) — peut être skippé
Étape 5 — Choix de l'authentification (Google / Apple iOS / Visiteur)
Étape 6 — Saisie du prénom (pré-rempli si OAuth)
Étape 7 — Saisie du téléphone +237 (skippable)
Étape 8 — Choix de l'école (autocomplete + skippable + add custom)
Étape 9 — Célébration de succès → Dashboard
```

**Mode visiteur** : raccourcis depuis l'étape 5 directement vers le Dashboard
(skip 6+7+8+9).

### Hors périmètre de ces tests

- Contenu du Dashboard lui-même (matières, hero, navigation tabs)
- Pages secondaires (`/matieres`, `/activites`, `/profil`) — placeholders pour le moment
- Système de paiement / abonnement
- Fonctionnalités IA / chat
- Notifications

---

## 2. Pré-requis testeurs

### Équipement minimum recommandé

| Plateforme | Device | OS minimum |
|---|---|---|
| Android phone | Tecno Spark / Samsung A03 / Pixel 4a | Android 8.0 (SDK 26) |
| Android tablet | Pixel Tablet / Samsung Tab A | Android 8.0 |
| iPhone | iPhone 8 ou plus récent | iOS 13.0 |
| iPad | iPad mini / iPad Air | iPadOS 13.0 |

Au minimum **un device par plateforme** ; idéalement les 4 form factors.

### Comptes de test à préparer (avant la session)

| Compte | Usage | Note |
|---|---|---|
| Google #1 — `test1.valide@gmail.com` | OAuth Google nominal | Mot de passe partagé dans coffre-fort QA |
| Google #2 — `test2.valide@gmail.com` | Conflit OAuth (déjà lié) | À utiliser après les TF-1.x |
| Apple #1 — `test.valide@icloud.com` | OAuth Apple nominal (iOS uniquement) | Pas utilisable sur Android |
| Pas de compte | Mode visiteur | Bouton `Continuer en visiteur` |

### Environnement réseau

Le testeur doit pouvoir basculer entre :
- **Wi-Fi rapide** (référence, débit > 10 Mb/s)
- **3G dégradé** (simulable via "Network Link Conditioner" sur iOS, "Mock Network" sur Android dev menu, ou simplement bracelet anti-onde + mode 3G)
- **Mode avion / offline complet**

### Build à installer

- **Android** : `mobile_app-release.apk` (build CI sur la branche `main` la plus récente)
- **iOS** : TestFlight (à venir) ou build local Xcode si testeur a un Mac
- **Version cible** : `1.0.0+1` ou supérieur (vérifier dans la SplashPage ou logs)

### Outils complémentaires

- App **Charles Proxy** ou **Proxyman** (pour observer les appels Firestore — optionnel mais utile sur les bugs réseau)
- App **Firebase console** en lecture (le QA doit pouvoir vérifier le doc `users/{uid}` créé)

---

## 3. Cartographie du parcours

### Diagramme des transitions de l'OnboardingNotifier

```
            +----------------+
            |   Splash       |
            +-------+--------+
                    | (~2,1 s)
                    ↓
            +----------------+
            | CatalogueCheck |
            +-------+--------+
                    |
       Firestore OK | catalogue vide + offline → CatalogueWaitingPage
                    ↓
            +----------------+
            | Étape 0        |
            | Sub-system     |
            +-------+--------+
                    | setSubSystem (persisté SharedPrefs)
                    ↓
            +----------------+
            | Étape 1 — Hero |
            +-------+--------+
                    | next()
                    ↓
            +----------------+
            | Étape 2 — Track|
            +-------+--------+
                    | setTrackId  (reset downstream)
                    ↓
            +----------------+
            | Étape 3 — Level|
            +-------+--------+
                    | setLevelId
       requiresPicker=true ↓       requiresPicker=false (skip 4)
            +----------------+              ↓
            | Étape 4 —      |              |
            | Stream+Subjects|              |
            +-------+--------+              |
                    |                       |
                    ↓ ←---------------------+
            +----------------+
            | Étape 5 — Auth |
            +--+----------+--+
               |          |
               | OAuth    | Visiteur
               ↓          ↓
        +----------+   signInAnonymously + flush
        | Étape 6  |   + nav direct /dashboard
        | Name     |
        +----+-----+
             ↓ setUserDisplayName
        +----------+
        | Étape 7  |
        | Phone    |
        +----+-----+
             ↓ setPhoneNumber / skipPhone
        +----------+
        | Étape 8  |
        | School   |
        +----+-----+
             ↓ setSchool / setPending / skipSchool
        +----------+
        | Étape 9  |
        | Success  | ← Flush Firestore + retry 0s/1s/3s
        +----+-----+
             ↓ nav /dashboard
        +----------+
        | Dashboard|
        +----------+
```

### Persistance par étape

| Étape | Quoi est persisté | Où |
|---|---|---|
| 0 | `subSystem` | SharedPreferences (clé `onboarding.subsystem`) |
| 2-8 | Draft profile complet (sauf `phoneNumber` — PII) | SharedPreferences (clé `onboarding.draft`) |
| 9 (visiteur) | Doc complet `users/{uid}` | Firestore + draft cleared |
| 9 (compte) | Doc complet `users/{uid}` | Firestore + draft cleared |

---

## 4. Parcours principaux (golden paths)

> Ces 8 parcours **doivent tous passer**. Si l'un échoue → bug bloquant S1 ou S2.

---

### TF-1.1 — Visiteur francophone Terminale D (parcours le plus court)

**Persona** : élève francophone du Cameroun, scolarisé en Terminale série D
(scientifique), veut juste tester l'app sans créer de compte.

**Pré-conditions** : fresh install (reset effectué).

**Étapes** :
1. Lancer l'app
2. Attendre la fin du splash animé
3. Sur l'étape 0, taper la carte **Francophone**
4. Sur l'étape 1 (hero intro), taper **Continuer**
5. Sur l'étape 2 (track), taper **Générale**
6. Sur l'étape 3 (level), scroller et taper **Terminale**
7. Sur l'étape 4 (stream picker), taper **Série D**
8. Sur l'écran qui affiche les matières dérivées, taper **Valider**
9. Sur l'étape 5 (auth choice), taper **Continuer en visiteur**
10. **Aucune modale ne doit apparaître** (l'utilisateur est anonyme par défaut au boot)
11. Attendre la fin du flush Firestore (loader bref)

**Résultat attendu** :
- ✅ Arrivée directe sur le **Dashboard**
- ✅ Pas de page de célébration confetti (réservée aux comptes permanents)
- ✅ Le Dashboard affiche le hero "Bonjour visiteur !"
- ✅ Le card "Sauvegarder ton compte" est visible
- ✅ Les matières de Série D apparaissent dans la grille (Math, Physique, Chimie, SVT, Philo, Français, Anglais, EPS)
- ✅ Dans Firebase Console > Firestore > `users/{uid}` : doc créé avec `isAnonymous: true`, `trackId: general`, `levelId: francophone_terminale`, `streamId: francophone_terminale_d`, `pickedSubjects: [...]`

**Pass-fail** : tous les checks ✅. Si un seul ❌ → bug S2 minimum.

**Durée estimée** : 1 min 30.

---

### TF-1.2 — Visiteur francophone 6e (mode dérivé, skip étape 4)

**Persona** : élève en début de collège, doit juste choisir 6e et l'app lui propose
automatiquement les matières du tronc commun.

**Pré-conditions** : fresh install.

**Étapes** :
1. Lancer l'app, passer le splash
2. Étape 0 : taper **Francophone**
3. Étape 1 : taper **Continuer**
4. Étape 2 : taper **Générale**
5. Étape 3 : taper **6e**
6. **L'app saute automatiquement l'étape 4** et arrive directement à l'étape 5 (auth)
   - ⚠️ **Vérifier le label "1/3" du compteur** : sur Mar 5 par exemple "2/3" ne doit pas s'afficher (le compteur signale 1/3 à 5/3 dans le parcours sans picker)
7. Taper **Continuer en visiteur**
8. Arrivée sur le Dashboard

**Résultat attendu** :
- ✅ Étape 4 ne s'affiche **jamais** visuellement
- ✅ Dashboard montre les matières tronc commun 6e francophone : Français, Anglais, Maths, SVT, Sciences Physiques, Histoire-Géo, ECV, LCN, Informatique, EPS, EA, TM (pas de LV2 en 6e/5e)
- ✅ `users/{uid}` : `pickedSubjects` contient les 12 matières du tronc commun
- ✅ `streamId` est null dans Firestore

---

### TF-1.3 — Visiteur anglophone Form 5 (panier libre GCE O-Level)

**Persona** : élève anglophone, doit composer son panier de 6 à 11 matières avec
3 obligatoires (English, French, Mathematics).

**Pré-conditions** : fresh install.

**Étapes** :
1. Étape 0 : taper **Anglophone** (interface bascule en anglais)
2. Étape 1 : taper **Continue**
3. Étape 2 : taper **General**
4. Étape 3 : taper **Form 5**
5. Étape 4 : la page affiche le mode `free_with_obligatory` :
   - 3 matières lockées (icône cadenas) : English, French, Mathematics
   - 17 matières optionnelles avec checkboxes
6. **Tenter de valider sans rien cocher** → CTA Validate doit être désactivé (3 < min 6)
7. Cocher 3 matières optionnelles (total = 6) → CTA s'active
8. Tenter d'en cocher 9 supplémentaires (total = 12) → la 12e doit être impossible à cocher OU un toast d'erreur "Maximum 11 matières" s'affiche
9. Décocher 1 → 11 matières → valider
10. Étape 5 : taper **Continue as guest**
11. Arrivée Dashboard

**Résultat attendu** :
- ✅ Comportement min/max respecté (6-11)
- ✅ Les 3 obligatoires sont VISIBLEMENT lockées (pas de checkbox interactive)
- ✅ `users/{uid}.pickedSubjects` contient exactement 11 matières dont les 3 obligatoires
- ✅ Interface entièrement en anglais

---

### TF-1.4 — Visiteur anglophone Lower Sixth (series picker)

**Persona** : élève Lower Sixth devant choisir entre les 13 séries A-Level.

**Étapes** :
1. Étape 0 : taper **Anglophone**
2. Étapes 1-2 : Continue + General
3. Étape 3 : taper **Lower Sixth**
4. Étape 4 : la page affiche **13 cards de séries** (S1, S2, …, S8, A1, A2, A3, A4, A5)
   - Chaque card a un sous-titre descriptif
   - Chaque card est tappable
5. Taper **S2 (Mathematics-Physics)**
6. La page bascule sur l'aperçu des matières dérivées (3-4 matières A-Level)
7. Valider

**Résultat attendu** :
- ✅ Les 13 cards sont scrollables sans coupure (en phone portrait)
- ✅ Pas de "Chargement impossible" (bug historique #114)
- ✅ Pas de matière en doublon
- ✅ Le titre "Choisis ta série" reste visible en haut pendant le scroll des cards

---

### TF-1.5 — Compte Google francophone Terminale C (parcours complet)

**Persona** : élève qui crée un vrai compte pour sauvegarder ses choix.

**Pré-conditions** : fresh install, compte Google #1 dispo sur le device.

**Étapes** :
1. Étapes 0-4 : Francophone / Générale / Terminale / Série C / valider matières
2. Étape 5 : taper **Continuer avec Google**
3. Le picker Google natif s'ouvre → choisir `test1.valide@gmail.com` → autoriser
4. **Étape 6** : le champ nom doit être **pré-rempli** avec le displayName Google (ex. "Test Valide")
5. **Modifier le nom** : effacer puis taper "Marie"
6. Taper Continuer
7. Étape 7 (téléphone) : taper **+237 6 12 34 56 78** → CTA Continuer s'active → taper
8. Étape 8 (école) : taper "Vogt" → suggestions apparaissent → choisir **Collège Vogt Yaoundé** → Continuer
9. Étape 9 : confetti + message succès + bouton **Découvrir mon dashboard**
10. Taper le bouton → Dashboard

**Résultat attendu** :
- ✅ Le picker Google s'ouvre sans crash
- ✅ Étape 6 affiche bien "Test Valide" pré-rempli (et non vide)
- ✅ Le nom peut être **édité** (pas de skip automatique)
- ✅ Pendant la frappe du téléphone, le préfixe `+237` est constant et non éditable
- ✅ La validation refuse `+33 6 …` (non-Cameroun)
- ✅ La recherche école renvoie des résultats en < 1,5 s
- ✅ La page confetti s'affiche **avant** d'aller au dashboard
- ✅ Sur le Dashboard, le hero affiche "Bonjour Marie !"
- ✅ `users/{uid}` : `displayName: "Marie"`, `isAnonymous: false`, `authProvider: "google"`, `phoneNumber: "+237612345678"`, `schoolId: "<id Vogt>"`

---

### TF-1.6 — Compte Apple anglophone Upper Sixth (iOS only)

**Pré-conditions** : iPhone ou iPad sous iOS 13+, fresh install, compte Apple #1 dispo.

**Étapes** :
1. Étapes 0-4 : Anglophone / General / Upper Sixth / A3 (Bio-Chem-Maths) / valider
2. Étape 5 : taper **Continue with Apple** (le bouton est noir, à côté de Google)
3. Le sheet Apple natif s'ouvre → choisir "Share My Email" puis identifier
4. Étape 6 : champ pré-rempli si Apple a fourni le nom (souvent vide au 2e sign-in)
5. Taper "Eyong" → Continuer
6. Étape 7 : skip (bouton "Passer pour l'instant") → modale de confirmation → confirmer
7. Étape 8 : taper le bouton "Skip school" → modale ?? **À vérifier** : si pas de modale, c'est un gap
8. Arrivée page confetti + bouton → Dashboard

**Résultat attendu** :
- ✅ Le bouton Apple n'apparaît PAS sur Android (cf. TF-5.x)
- ✅ Apple ne fournit le nom QU'AU PREMIER sign-in : si compte déjà utilisé sur cet appareil, le champ peut être vide → step 6 demande saisie
- ✅ Skip phone affiche une modale "Tu pourras le compléter plus tard" (micro-friction)
- ✅ `users/{uid}.authProvider: "apple"`

---

### TF-1.7 — Compte Google francophone 1ère Technique F2

**Persona** : élève filière technique (lycée technique).

**Étapes** :
1. Étape 0 : Francophone
2. Étape 1 : Continuer
3. Étape 2 : **Technique** (et non Générale)
4. Étape 3 : choisir **1ère**
5. Étape 4 : la liste des séries doit afficher F1 à F8 + AF1-AF3 (filières
   industrielles + agricoles)
6. Choisir **F2 (Électrotechnique)** ou tout autre F-suffixé
7. Valider matières
8. Étape 5 : Google
9. Étapes 6-7-8-9 : continuer normalement

**Résultat attendu** :
- ✅ Le track "Technique" change bien les niveaux proposés à l'étape 3 (souvent les mêmes que Générale + spécificités)
- ✅ Les séries F-techniques sont présentes
- ✅ Aucune série "D" ou "A" générale n'est présentée (filtre track)
- ✅ Les matières dérivées sont alignées avec doc officiel (Dessin industriel, Électrotechnique, Maths techniques, …)

---

### TF-1.8 — Anonyme reprenant l'app (relaunch sans kill, état mémoire intact)

**Pré-conditions** : exécuter TF-1.1 jusqu'à l'étape 4, **sans** taper Valider.

**Étapes** :
1. **Mettre l'app en arrière-plan** (bouton Home / swipe up + maintenir, ne PAS killer)
2. Attendre 30 s (test arrière-plan court)
3. Revenir à l'app

**Résultat attendu** :
- ✅ L'utilisateur revient pile à l'étape 4 avec son choix (Série D + matières cochées) intact
- ✅ Aucune perte d'état UI

**Variante** : mettre l'app en arrière-plan 10 min puis revenir → idem.

---

## 5. Scénarios de robustesse

> Ces scénarios testent la résilience aux interruptions, retours arrière et changements
> d'avis. **Aucun ne doit faire perdre la progression du user**.

---

### TF-2.1 — Kill app à chaque étape → reprise correcte

**Objectif** : valider que la persistance SharedPreferences restaure tout sauf le phone.

**Procédure** :

Pour chaque étape `N` de 0 à 8 :

1. Faire le parcours jusqu'à l'étape `N` (avancer normalement)
2. **Force kill l'app** (swipe up + dismiss / Settings > Force stop sur Android)
3. Relancer l'app
4. Observer où l'app reprend

**Résultats attendus par étape** :

| Étape `N` au kill | Reprise après relaunch | Notes |
|---|---|---|
| 0 (rien choisi) | Étape 0 fresh | OK |
| 1 (subSystem choisi) | Étape 1 directement | subSystem persisté |
| 2 (sur Hero) | Étape 1 | back symétrique attendu |
| 3 (track choisi) | Étape 3 avec track pré-sélectionné | Sur l'étape 3 le track est consommé pour filtrer les levels |
| 4 (level choisi) | Étape 4 (ou 5 si derived) avec level intact | |
| 5 (subjects validés) | Étape 5 — choix auth — avec contexte préservé | |
| 6 (auth visiteur en cours) | Étape 5 (auth pas fini, on revient au choix) | |
| 7 (nom saisi) | Étape 7 (phone) avec displayName intact | |
| 8 (phone saisi ou skippé) | Étape 8 (school) | ⚠️ **phoneNumber non persisté** : si l'user avait saisi son numéro, il doit le re-saisir au retour |

**Critère pass-fail** :
- ✅ La progression est restaurée comme indiqué
- ❌ Si l'app revient à l'étape 0 après avoir choisi level/stream/subjects → BUG S1 (régression de la PR #121)

---

### TF-2.2 — Back nav à chaque étape (sans perte de données amont)

**Procédure** :

Pour chaque étape `N` de 2 à 8 :

1. Avancer jusqu'à l'étape `N`
2. Appuyer sur la **flèche back** (en haut à gauche du header)
3. Observer si les données du step précédent sont préservées
4. Re-avancer → données toujours là

**Cas particuliers à valider** :

- **Étape 4 (picker) en mode dérivé skip** : back depuis étape 5 doit aller à
  étape 3 (et non à étape 4 vide)
- **Étape 4 → back vers étape 3** : changer de niveau → reset du stream/subjects
  (downstream est nettoyé)
- **Étape 7 → back vers étape 6** : le nom est toujours là
- **Étape 6 → back vers étape 5** : revient au choix auth, l'auth précédent est-il
  "défait" ou maintenu ? **À documenter** : actuellement maintenu (currentUser
  Google reste signed-in, le user peut re-changer)

**Résultat attendu** : aucun back ne perd les données amont sauf si l'utilisateur
re-modifie explicitement (ex. re-tap d'un track différent).

---

### TF-2.3 — Switch sub-system à mi-parcours

**Objectif** : un user francophone réalise qu'il est dans la mauvaise interface
et veut basculer en anglophone.

**Étapes** :
1. Faire le parcours jusqu'à l'étape 4 en Francophone, choisir Terminale D
2. Faire **back, back, back, back** jusqu'à l'étape 0
3. Taper **Anglophone**
4. Observer la suite

**Résultat attendu** :
- ✅ L'interface bascule en anglais (locale change live)
- ✅ Les niveaux/séries présentés sont anglophones (Form 5, Lower Sixth, etc.)
- ✅ Le track précédemment choisi est reset (Générale ≠ General — les catalogues diffèrent)
- ✅ Pas de crash, pas d'écran blanc

**À surveiller** : un éventuel bug où `trackId="general"` (anglais) reste depuis
le francophone — vérifier que le sub-system swap force un reset.

---

### TF-2.4 — Switch OAuth → Visiteur (avec modale destructive)

**Pré-conditions** : compte Google créé (TF-1.5), arrivé sur le Dashboard.

**Étapes** :
1. Depuis le Dashboard, tap sur le FAB de debug → `Delete account & clear` (reset)
2. Relancer, passer le parcours jusqu'à l'étape 5
3. Taper **Continuer avec Google** → s'authentifier
4. Sur l'étape 6, faire **back** jusqu'à l'étape 5
5. Taper **Continuer en visiteur**

**Résultat attendu** :
- ✅ Une **modale destructive** s'affiche : "Continuer en visiteur ? Tu es connecté avec un compte. Continuer en visiteur supprimera ton profil actuel et tu repartiras de zéro."
- ✅ Deux boutons : "Garder mon compte" (gris) et "Effacer et continuer" (rouge)
- ✅ Tap **Garder mon compte** → la modale se ferme, rien ne change, l'utilisateur reste signed-in
- ✅ Tap **Effacer et continuer** → le doc `users/{uid_google}` est supprimé, signOut + signInAnonymously, nav vers le Dashboard en mode visiteur

**Vérification Firestore** : après le tap "Effacer", le doc `users/{uid_google}`
doit avoir disparu (ou alors être à nouveau attribué au nouveau uid anonyme s'il
est créé immédiatement).

---

### TF-2.5 — Upgrade visiteur → compte permanent depuis le Dashboard

**Pré-conditions** : avoir terminé TF-1.1 (visiteur sur Dashboard).

**Étapes** :
1. Sur le Dashboard, vérifier la présence du **card "Sauvegarder ton compte"** en bas
2. Taper le bouton **Créer mon compte**
3. Le bottomsheet **AccountUpgradeSheet** s'ouvre
4. Vérifier le titre "Sauvegarder ton compte" + le body explicatif
5. Taper **Continuer avec Google** → picker Google → choisir un compte
6. Le sheet se ferme → snackbar verte "Compte sauvegardé ✨"
7. Le card "Sauvegarder ton compte" **disparaît** du dashboard
8. Le hero affiche maintenant le prénom Google (ex. "Bonjour Test !")

**Résultat attendu** :
- ✅ L'uid Firestore reste **IDENTIQUE** à avant l'upgrade (preserve via `linkWithCredential`)
- ✅ Le doc `users/{uid}` est conservé avec **mêmes** trackId/levelId/streamId/pickedSubjects, mais : `isAnonymous: false`, `authProvider: "google"`, `displayName: "Test Valide"`
- ✅ Les matières restent visibles sur le dashboard (pas de perte de progression)
- ✅ Cancel du picker Google → snackbar n'apparaît pas, le bottomsheet reste ouvert

**Cas tordu à tester** : retenter avec un compte Google déjà lié à un autre uid
de l'app → l'erreur `credential-already-in-use` doit afficher un message clair
(non opaque) dans le bottomsheet.

---

### TF-2.6 — Réinstallation de l'app (delete + reinstall)

**Procédure** :
1. Terminer TF-1.1 (visiteur Dashboard avec doc Firestore créé)
2. **Désinstaller** l'app (long press → Désinstaller)
3. **Réinstaller** depuis l'apk / store

**Résultat attendu** :
- ✅ Le SharedPreferences est wipé (subSystem perdu) → l'app reprend à l'étape 0 fresh
- ✅ Le doc Firestore `users/{old_uid}` reste vivant (orphelin — c'est attendu car Firestore et Auth survivent à la réinstall si Google Play Services était actif)
- ✅ Le user peut refaire un nouveau parcours qui crée un **nouveau uid anonyme**

**Note pour le QA** : tester aussi avec un compte Google : après réinstall, le user
re-signe Google → linkWithCredential donne une erreur car le compte est déjà
attaché à un autre uid → comportement attendu : signIn récupère l'uid précédent
(reuse de l'auth), le doc Firestore reste accessible.

---

### TF-2.7 — Navigation rapide (double-tap, swipe rapide)

**Objectif** : robustesse aux taps rapides involontaires.

**Procédure** :
1. Sur l'étape 0, **double-tap rapide** sur "Francophone"
2. Observer si on passe à l'étape 1 ou si l'app saute à l'étape 2

**Résultat attendu** :
- ✅ Un seul `setSubSystem` est exécuté (idempotent), l'app va à l'étape 1
- ✅ Aucune transition n'est sautée même si l'animation est plus rapide

**Variantes** :
- Double-tap sur Continuer à l'étape 1 → doit aller à l'étape 2 (et pas 3)
- Triple-tap sur Continuer → idem

---

## 6. Scénarios d'erreur et offline

---

### TF-3.1 — Démarrer offline (mode avion ON dès le premier lancement)

**Pré-conditions** : fresh install + mode avion activé **avant** de toucher à l'app.

**Étapes** :
1. Activer le mode avion
2. Lancer l'app
3. Observer

**Résultat attendu** :
- ✅ Splash s'affiche
- ✅ L'app arrive sur la **CatalogueWaitingPage** (icône wifi-off + message "En attente de connexion")
- ✅ Bouton "Réessayer" présent
- ✅ Aucun crash, aucun écran blanc figé

**Suite** :
4. Désactiver le mode avion
5. Taper **Réessayer**

**Résultat attendu** :
- ✅ Le catalogue se charge (< 5 s sur Wi-Fi)
- ✅ L'app transitionne automatiquement vers l'étape 0
- ✅ Pas besoin de tap supplémentaire

---

### TF-3.2 — Couper le réseau pendant le flush (étape 9, compte permanent)

**Pré-conditions** : être à l'étape 8 avec un compte Google.

**Étapes** :
1. À l'étape 8, choisir une école et taper Continuer
2. **Activer immédiatement le mode avion** avant la fin de l'animation slide
3. Étape 9 affiche le loader (CircularProgressIndicator)
4. Observer pendant 5 secondes

**Résultat attendu** :
- ✅ L'app tente **3 retries automatiques** avec backoff : 0s, +1s, +3s (durée totale ~4s)
- ✅ Après les 3 retries → affichage de **ErrorRetryView** avec :
  - Icône `wifi-off` (kind `offline`)
  - Message "Pas de connexion. Vérifie ton réseau et réessaie."
  - Bouton **Réessayer**
- ✅ Désactiver le mode avion + tap Réessayer → nouveau cycle de 3 retries → succès → confetti → Dashboard
- ✅ Le doc `users/{uid}` est bien créé une seule fois (pas de doubles writes)

---

### TF-3.3 — Cancellation OAuth Google (tap dans le vide)

**Étapes** :
1. À l'étape 5, taper **Continuer avec Google**
2. Le picker Google s'ouvre
3. **Tap en dehors du picker** ou tap "Annuler"
4. Observer

**Résultat attendu** :
- ✅ Le picker se ferme
- ✅ L'utilisateur reste sur l'étape 5
- ✅ Aucun message d'erreur intrusif (le cancel est silencieux)
- ✅ Possibilité de retenter (boutons Google/Apple/Visiteur toujours actifs)

---

### TF-3.4 — Cancellation OAuth Apple (iOS only)

**Étapes** :
1. À l'étape 5, taper **Continue with Apple**
2. Le sheet Apple s'ouvre → taper la croix de fermeture

**Résultat attendu** : idem TF-3.3, comportement silencieux et récupérable.

---

### TF-3.5 — Permission-denied Firestore (rule artificielle)

**Pré-conditions** : nécessite l'aide du dev pour désactiver temporairement la
rule `allow write` sur `users/{uid}` côté Firebase console.

**Étapes** :
1. Le dev modifie les rules pour bloquer les writes pendant 30s
2. Le testeur fait le parcours jusqu'à l'étape 9
3. Le flush échoue avec code `permission-denied`

**Résultat attendu** :
- ✅ 3 retries automatiques (tous échouent)
- ✅ ErrorRetryView affiche le message **errorPermissionDenied** : "Session expirée. Re-lance l'app pour rafraîchir."
- ✅ Le testeur kill + relance → arrive sur Dashboard si profil OK ou retombe à l'étape 5 si auth perdu

---

### TF-3.6 — Numéro téléphone invalide (étape 7)

**Étapes** :
1. À l'étape 7, taper successivement :
   - `+33 6 12 34 56 78` (France) → ❌ Refusé
   - `+237 7 12 34 56 78` (préfixe inconnu 7 — pas mobile camerounais) → ❌ Refusé
   - `+237 6 12 34 56` (trop court) → ❌ Refusé (pas d'erreur affichée tant que < 13 chars)
   - `+237 6 12 34 56 78` (valide MTN/Orange) → ✅ Accepté
   - `+237 2 22 23 45 67` (valide Camtel fixe) → ✅ Accepté

**Résultat attendu** :
- ✅ Message d'erreur "Numéro invalide. Format : +237 6XX XXX XXX" affiché sous le champ
- ✅ CTA Continuer reste désactivé tant qu'invalide
- ✅ Le préfixe `+237` est constant et non éditable

---

### TF-3.7 — Nom < 2 chars ou > 50 chars (étape 6)

**Étapes** :
1. Étape 6 : taper "A" (1 char) → message "Au moins 2 caractères"
2. Effacer + taper une chaîne de 51 caractères → message "Maximum 50 caractères"
3. Effacer + taper "Bo" (2 chars) → ✅ Accepté, CTA actif

**Résultat attendu** :
- ✅ Le champ refuse au-delà de 50 (maxLength côté input)
- ✅ Si < 2 chars → CTA désactivé
- ✅ Pas d'autocapitalisation incohérente (test : taper "marie" → reste "marie" ou autocaps "Marie" si TextCapitalization.words activé)

---

### TF-3.8 — École : aucun résultat + ajout custom

**Étapes** :
1. Étape 8 : taper "Zzz" dans la barre de recherche
2. Attendre 1 s (debounce 300 ms + Firestore)
3. **Aucune école ne devrait matcher** → l'UI doit proposer "+ Ajouter Zzz"
4. Taper le bouton "+ Ajouter Zzz" (ou variant)
5. L'app crée un doc `school_requests/{id}` côté Firestore
6. La sélection bascule sur "Zzz (en attente de validation)" — icône pending
7. Continuer

**Résultat attendu** :
- ✅ Lookup Firestore en < 1,5 s
- ✅ Card "Ajouter Zzz" cliquable
- ✅ Indication visuelle "pending" sur la sélection
- ✅ Au flush final, `users/{uid}.pendingSchoolRequestId` est posé (et non `schoolId`)

---

### TF-3.9 — École : skip avec micro-friction

**Étapes** :
1. Étape 8 : taper le bouton **Passer pour l'instant** (en bas, underline)
2. Une modale doit apparaître : "Tu pourras compléter ton école plus tard. Continuer ?"
3. Confirmer

**Résultat attendu** :
- ✅ La modale s'affiche **avant** le skip (anti-tap accidentel)
- ✅ `users/{uid}.schoolId` est null, `schoolSkipped: true`

---

### TF-3.10 — Pression du bouton back système (Android)

**Procédure** :

Pour chaque étape, appuyer sur le **bouton back natif Android** (ou geste swipe back iOS) :

| Étape | Comportement attendu |
|---|---|
| 0 (subSystem) | Quitte l'app |
| 1 (hero) | Revient à étape 0 (équivalent au back du header) |
| 2-8 | Équivalent au tap du back du header |
| 9 (success) | Devrait **bloquer** (le user a déjà flushé, il doit aller au dashboard) |
| Dashboard | Quitte l'app (avec confirmation idéalement) |

**Note** : le step 9 success n'a pas de header (`_configStepsActive` false) — donc
pas de bouton back visible. Le back système doit être no-op ou ouvrir une confirmation.

---

## 7. Tests par cursus scolaire

Voir le fichier compagnon **`matrice-cursus.csv`** qui liste les ~30 combinaisons
sub-system × track × level × stream à valider. Pour chaque ligne, dérouler le
parcours TF-1.1 / TF-1.5 et vérifier :

1. ✅ La liste des séries (étape 4) correspond au cursus officiel
2. ✅ Les matières dérivées sont alignées avec le programme MINESEC / GCE Board
3. ✅ Aucune série n'affiche "Chargement impossible"
4. ✅ Les descriptions et abréviations sont en bonne langue (FR pour francophone, EN pour anglophone)

---

## 8. Tests responsive

### TF-5.1 — Phone portrait (référence)

Tous les TF-1.x → 3.x doivent passer sur un **Pixel 4a ou équivalent (≈ 411×891 dp)**.

### TF-5.2 — Phone landscape

Mettre le téléphone en mode paysage à chaque étape de l'onboarding.

**Résultat attendu** :
- ✅ Aucun contenu coupé en bas (le scroll prend le relais)
- ✅ Les cards se réorganisent en grille 2-3 colonnes si pertinent
- ✅ Le clavier ne mange pas le champ d'input (autoscroll Flutter)

**Statut connu** : phone landscape peut être **verrouillé portrait** en V1 si
décision produit. À confirmer avec le dev avant le test.

### TF-5.3 — Tablet portrait (≥ 600 dp width)

Sur Pixel Tablet / iPad mini.

**Résultat attendu** :
- ✅ Les cards de sélection passent en grille 2 colonnes (et non 1 unique)
- ✅ Le hero (étape 1) est centré et n'occupe pas 100% de la largeur
- ✅ Tailles de texte raisonnables (pas de fonte géante)

### TF-5.4 — Tablet landscape

Idem mais en paysage. Mêmes critères + 3 colonnes possibles si l'espace le permet.

---

## 9. Tests internationalisation FR/EN

### TF-6.1 — Switch FR → EN via sub-system

1. Lancer l'app, étape 0 : taper **Anglophone**
2. Toute l'UI bascule en anglais (CTA "Continue", titres traduits, etc.)
3. Faire back → étape 0 → taper **Francophone**
4. Toute l'UI rebascule en français

**Résultat attendu** :
- ✅ Aucun string en dur en français reste affiché en mode Anglophone (et vice-versa)
- ✅ Les noms de niveaux/séries/matières viennent du sub-collection Firestore correspondant à la langue
- ✅ Les abréviations badge (ex. "MATHS" / "MATHS") sont dans la bonne langue

### TF-6.2 — Vérification exhaustive des écrans en EN

Refaire tout TF-1.3 ou TF-1.4 en mode Anglophone et photographier chaque étape.
Vérifier qu'aucune string n'est restée en français.

**Strings spécifiques à vérifier** :
- Titre étape 5 : "Choose how to continue" (et non "Comment veux-tu continuer ?")
- Titre étape 9 : "All set!" (et non "C'est parti !")
- Bouton flush retry : "Try again"
- Snackbar account upgrade : "Account saved ✨"

---

## 10. Tests UI/UX détaillés par étape

### TF-7.0 — Splash animation

- ✅ Le mot "VALIDE" se trace lettre par lettre en blanc sur fond bleu
- ✅ Durée totale ≈ 2,1 s (animation 1,8 s + hold 0,3 s)
- ✅ Au-delà, navigation auto vers l'écran suivant (étape 0 ou Dashboard ou CatalogueWaiting)

### TF-7.1 — Étape 0 (sub-system)

- ✅ 2 cards (Francophone / Anglophone) avec icône + titre + description courte
- ✅ Tap sur une card surligne la sélection ET passe à l'étape suivante automatiquement
- ✅ CTA "Continuer" en bas est désactivé tant qu'aucun sub-system n'est choisi

### TF-7.2 — Étape 1 (hero intro)

- ✅ Illustration centrale + 3 features listées (icône + texte)
- ✅ Un seul CTA "Commencer" / "Get started"
- ✅ Pas de bouton back (c'est le 2e screen, on peut quitter mais pas remonter)

### TF-7.3 — Étape 2 (track)

- ✅ 2 cards : Générale / Technique
- ✅ Header affiche progress 1/3 (1er des 3 steps de "config")
- ✅ Bouton back actif → retour étape 1

### TF-7.4 — Étape 3 (level)

- ✅ Liste scrollable des niveaux disponibles pour le sub-system + track choisis
- ✅ Header : 2/3
- ✅ Tap auto-avance + le CTA Continuer existe en fallback
- ✅ Cards avec icône (livre, mortier, etc.) + nom du niveau

### TF-7.5 — Étape 4 (stream + subjects)

Selon le mode `pickerMode` de la série :

| Mode | Comportement |
|---|---|
| `derived` | L'étape est skippée — l'app saute directement à l'étape 5. Si l'user back depuis 5 → 3 |
| `series_only` | Liste des séries, tap pour choisir. Aperçu read-only des matières dérivées + CTA Valider |
| `free_with_obligatory` | Pas de série à choisir, panier libre avec matières obligatoires lockées + optionnelles cochables (min/max imposés) |
| `series_plus_optional` | Choix série + matières optionnelles supplémentaires |
| `tve_picker` | Spécifique TVE anglophone (à valider quand activé) |

**Critères communs** :
- ✅ Header : 3/3
- ✅ Titre "Choisis ta série" / "Choose your stream" toujours visible en haut
- ✅ PickerCounterBadge en haut à droite affiche "8/11 matières" en temps réel
- ✅ CTA Valider en bas s'active dès que min atteint

### TF-7.6 — Étape 5 (auth choice)

- ✅ 3 boutons (ou 2 sur Android) : Google + Apple (iOS only) + Visiteur
- ✅ Apple invisible sur Android et Web
- ✅ Pas de header progress (c'est un step de transition, pas "config")
- ✅ Pas de bouton back visible (le shell skip le header sur step 5) — **à vérifier** : peut-être un design oversight, à signaler si le user veut revenir à l'étape 4

### TF-7.7 — Étape 6 (name)

- ✅ Champ TextField avec autofocus, clavier qui s'ouvre auto
- ✅ Pré-rempli si OAuth a fourni un nom
- ✅ Validation 2-50 chars avec message d'erreur affiché en rouge
- ✅ TextCapitalization.words (premier letter auto-majuscule)

### TF-7.8 — Étape 7 (phone)

- ✅ Drapeau Cameroun + préfixe "+237" en grisé non éditable
- ✅ Champ pour 9 chiffres, formatage live (espaces tous les 2 chiffres)
- ✅ Bouton "Passer pour l'instant" en sous-link
- ✅ Aucun log du numéro complet dans la console (vérifier via `adb logcat` ou Xcode console — devrait montrer "+237 X XX XX 78 90")

### TF-7.9 — Étape 8 (school)

- ✅ Champ de recherche avec placeholder
- ✅ Suggestions Firestore apparaissent après 2 caractères saisis (300 ms debounce)
- ✅ Card "+ Ajouter <saisie>" en bas de la liste si aucune correspondance exacte
- ✅ Avertissement offline si réseau coupé : "Recherche indisponible hors connexion"

### TF-7.10 — Étape 9 (success)

- ✅ Animation confetti (Lottie ou natif)
- ✅ Titre "C'est parti !" / "All set!"
- ✅ Sous-titre court
- ✅ Bouton "Découvrir mon dashboard"
- ✅ Auto-dispatch après N secondes si le user ne tape pas ? **À vérifier** : actuellement le user doit taper manuellement

---

## 11. Tests d'accessibilité minimale

### TF-8.1 — Taille de texte 200% (Réglages système)

1. Aller dans Réglages → Affichage → Taille de texte → 200%
2. Relancer l'app
3. Faire le parcours TF-1.1

**Résultat attendu** :
- ✅ Aucun texte coupé sur les CTA principaux
- ✅ Les cards s'agrandissent verticalement plutôt que de tronquer le texte
- ✅ Possibilité de scroller même si un écran dépasse en hauteur

### TF-8.2 — Contraste minimal

Activer le mode "Augmenter le contraste" (Réglages → Accessibilité).
Vérifier que les textes restent lisibles, en particulier :
- Texte gris (subtitle, helper) sur fond clair
- Texte blanc sur boutons primary

### TF-8.3 — Lecteur d'écran (TalkBack / VoiceOver)

Activer TalkBack ou VoiceOver. Naviguer par swipe sur l'étape 0.

**Résultat attendu** :
- ✅ Chaque card est annoncée avec son nom (Francophone / Anglophone)
- ✅ Le CTA Continuer est annoncé comme "Bouton, Continuer"
- ✅ Pas de zones non décrites

**Statut connu** : audit accessibilité prévu en E1bis-10. Si gaps détectés ici,
les signaler en S3 ou S4 selon impact.

---

## 12. Tests de performance

Voir détails dans **`temps-de-chargement.md`**.

Résumé des cibles :

| Étape | Cible 4G/WiFi | Cible 3G dégradé |
|---|---|---|
| Splash → Étape 0 (cold start) | < 4 s | < 8 s |
| Transition entre 2 steps onboarding | < 300 ms | < 300 ms |
| Recherche école Firestore | < 1,5 s | < 3 s |
| Flush success (étape 9) | < 2 s | < 5 s |
| Boot Firebase + signInAnonymously | < 2 s | < 5 s |

---

## 13. Tests de sécurité / vie privée

### TF-10.1 — Aucun secret dans les logs

**Procédure** :
1. Brancher le device en USB
2. Lancer `adb logcat | grep -i valide` (Android) ou Console.app filtré sur "valide" (iOS)
3. Faire le parcours TF-1.5 (compte Google avec phone + nom)
4. Vider le buffer logs
5. Faire TF-2.5 (upgrade)

**Critères de pass** :
- ✅ Aucun mot de passe / token JWT en clair
- ✅ Le téléphone est masqué (`+237 X XX XX 78 90`)
- ✅ Le nom est masqué (`Te…[12c]`)
- ✅ Le uid n'apparaît que sous forme courte (`abc123...`)

### TF-10.2 — Pas de fuite croisée entre comptes

**Procédure** :
1. Compte Google A : faire TF-1.5 jusqu'au Dashboard
2. Reset complet (Delete account & clear)
3. Compte Google B (autre Gmail) : refaire TF-1.5
4. Vérifier que le user voit **uniquement** ses propres matières (et non celles du compte A)

### TF-10.3 — Test "switch d'appareil" (uid stable via OAuth)

**Procédure** :
1. Compte Google sur device #1 → flush profil
2. Désinstaller l'app sur device #1
3. Installer l'app sur device #2
4. Login Google avec le **même** compte sur device #2

**Résultat attendu** :
- ✅ L'uid Firebase est le même
- ✅ Le doc `users/{uid}` est récupéré tel quel
- ✅ Le user arrive directement sur le Dashboard avec ses matières (pas de re-parcours)

---

## Notes pour les bugs déjà connus à NE PAS reporter

Les comportements suivants sont **identifiés comme dette** et ne doivent pas être
reportés comme bugs :

1. **Schema Firestore mixte filiere/trackId** sur certains anciens documents users
   créés avant le 2026-06-10 (dette Story 1.19, hors scope V1)
2. **Pas de header back visible sur step 5** : décision design (les boutons d'auth sont
   les CTAs, pas de progress bar)
3. **Pas d'auto-dispatch après confetti** : décision produit (le user doit taper
   manuellement "Découvrir mon dashboard" pour s'approprier l'arrivée)
4. **Format des numéros camerounais sans préfixe 7** : 7 n'est pas un préfixe
   mobile valide officiel — refusé volontairement
5. **Apple sign-in absent sur Android** : decision produit (politique Apple +
   pas d'API cross-platform officielle)

Si un testeur rencontre un de ces points et n'est pas sûr → demander
confirmation à l'équipe avant d'ouvrir un ticket bug.

---

## Annexe — Crédits & contact

- Plan rédigé par : équipe Valide School (audit du 2026-06-13)
- Pour questions : Slack `#valide-qa` ou email `qa@valide-school.cm`
- Pour bugs critiques : alerter directement le développeur sur Slack/WhatsApp
- Référentiel doc officielle : `doc/partage/BASE-DE-DONNEES.md`,
  `doc/partage/ALGORITHMES.md`, `doc/partage/DONNEES-REFERENCE.md`
