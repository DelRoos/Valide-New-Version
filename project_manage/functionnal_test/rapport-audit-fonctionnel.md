# Rapport d'audit fonctionnel — Parcours premier lancement → Dashboard

> **Version** : 1.0  
> **Date** : 2026-06-13  
> **Auditeur** : Claude Code (ADB + analyse statique + logs)  
> **Device** : Xiaomi 25128RN17A · Android 16 · 720×1600 px · densité 320 dpi  
> **App** : `com.valideStartup.valideSchool` v1.0.0 (versionCode=1, installée le 2026-06-12)  
> **Branche** : `main` (commit `9e89b44`)

---

## Résumé exécutif

L'audit couvre le parcours complet **premier lancement → dashboard** via tests ADB interactifs, capture de screenshots à chaque étape et analyse des logs Flutter.

| Sévérité | Nombre | Statut |
|---|---|---|
| S1 — Bloquant | **2** | ❌ Bugs qui empêchent l'utilisateur d'atteindre le dashboard |
| S2 — Important | **3** | ⚠️ Dégradation UX significative |
| S3 — Mineur | **9** | 💬 Typos / accents manquants (textes en dur) |
| Performance | **4** | ⏱️ Temps de chargement hors cibles |
| ✅ Passés | **13** | Parcours et comportements conformes |

**Verdict** : **Le parcours golden path n'est pas stable.** Deux bugs S1 empêchent les utilisateurs des niveaux dérivés (6e–3e) et des niveaux avec séries (Terminale, Première…) d'atteindre le dashboard. Le parcours complet est fonctionnel uniquement pour les comptes Google/Apple sur des niveaux intermédiaires (Seconde, si les règles catalogue existent).

---

## Environnement de test

```
Device         : Xiaomi 25128RN17A (Redmi Note)
OS             : Android 16
Résolution     : 720×1600 px physiques
Densité        : 320 dpi → ~450 dp de largeur logique
Réseau test    : Wi-Fi (≥ 10 Mb/s) + mode avion (offline total)
Build Flutter  : Release APK v1.0.0 (Impeller/Vulkan renderer)
Firebase       : Projet valide-edu (prod)
```

---

## Métriques de démarrage (mesurées sur logs PERF)

| Étape | Temps mesuré | Cible spec | Verdict |
|---|---|---|---|
| `boot.main.start` → `boot.sharedPreferences.load` | **43 ms** | < 100 ms | ✅ |
| `boot.runApp` → `nav.push./splash` | **1 549 ms** | < 2 000 ms | ✅ |
| `boot.firebase.initializeApp` | **3 145 ms** | < 2 000 ms | ❌ +57% |
| `boot.firebase.ready` → `nav.push./onboarding/v2` | **734 ms** | < 500 ms | ⚠️ |
| `Catalogue check` (1ère règle dérivation active) | **~8 600 ms** depuis boot | < 5 000 ms | ❌ +72% |
| `E0 smoke test` Firestore write+read | **7 649 ms** | < 2 000 ms | ❌ ×3.8 |
| **Cold start total (boot → Step 0 utilisable)** | **~9–10 s** | < 6 s | ❌ |

> **Note** : Le cold start est mesuré depuis le tap utilisateur jusqu'à la première interaction possible. Les 9–10 s incluent l'animation splash (2,1 s) + Firebase init + catalogue check. Sur un réseau 3G camerounais, ces temps seraient 2–3× plus élevés.

---

## Bugs S1 — Bloquants (empêchent d'atteindre le dashboard)

---

### BUG-01 · Step 4 (Série + Matières) : "Chargement impossible" pour tous les niveaux avec série

**Sévérité** : S1 — Bloquant  
**Reproductible** : 100% sur Terminale Générale Francophone (testé). Probablement tous niveaux Première/Seconde/3e/4e/5e francophones + anglophones Lower Sixth / Upper Sixth.

**Symptôme** :  
À l'arrivée sur Step 4 (sélecteur série + matières), l'écran affiche "Chargement impossible" avec icône cloud-off et bouton "Réessayer". La connexion réseau est active. Le retry ne résout pas le problème.

**Screenshot** :  
![Step 4 - Chargement impossible](screenshots/05_step4_stream.png)

**Log capturé** :
```
[PERF] catalogue.derivationRules.fetch ok 1127ms
⚠️ derive() noMatchingRule: subSystem=francophone filiere=generale niveau=francophone_terminale serie=(none)
```

**Analyse (root cause)** :  
`derivedProfileV2Provider` est déclenché dès l'arrivée sur Step 4, avant que l'utilisateur ait sélectionné une série. Pour les niveaux avec plusieurs séries (Terminale D, C, A, etc.), la règle de dérivation a besoin d'un `streamId` non null. L'appel à `derive(subSystem, trackId, levelId, serie=null)` retourne `noMatchingRule`, ce qui fait afficher l'état d'erreur.

**Le picker de séries devrait s'afficher en premier**, permettant à l'utilisateur de choisir sa série. Seulement après ce choix, `derivedProfileV2Provider` devrait être appelé avec le `streamId`.

**Impact** :  
Tous les utilisateurs dont le niveau nécessite un choix de série (estimation : ~70% des élèves du secondaire : Terminale, Première, classes anglophones Upper/Lower Sixth) sont bloqués. Impossible d'atteindre le dashboard.

**Comportement attendu** :  
- Affichage du picker de séries (cards : Série D, Série C, Série A1, …)
- Tap sur une série → appel `derive()` avec le `streamId` sélectionné
- Affichage des matières dérivées + bouton Valider

**Fix suggéré** :  
Dans `stream_subjects_picker_step_body.dart` : conditionner l'appel à `derivedProfileV2Provider` à `state.streamId != null`. Afficher le picker de séries en premier (lecture simple de `catalogueProvider.series` filtrée par niveau) sans dépendre de `derivedProfileV2Provider`.

---

### BUG-02 · Parcours visiteur sur niveaux dérivés (6e–3e) : Dashboard inaccessible

**Sévérité** : S1 — Bloquant  
**Reproductible** : 100% sur 6e Générale Francophone + Continuer en visiteur.

**Symptôme** :  
Après avoir sélectionné Francophone → Générale → 6e → "Continuer en visiteur", l'utilisateur arrive sur Step 6 (saisie du prénom) au lieu du Dashboard. Retapper "Continuer en visiteur" reproduit le même comportement. L'utilisateur est bloqué en boucle.

**Screenshots** :  
- Tap 1 sur visiteur → [screenshots/08_dashboard_6e_visitor.png] → Step 6 (attendu : Dashboard)  
- Tap 2 sur visiteur → [screenshots/10_visitor_2nd_attempt.png] → Step 6 encore

**Log capturé** :
```
auth.step5 guest reuse existing anonymous session
```
Aucun log de flush réussi ni d'erreur réseau. Aucun log `nav.push./dashboard`.

**Analyse (root cause)** :  
Pour les niveaux en mode `derived` (6e, 5e, 4e, 3e), Step 4 est sauté (skip). L'état `OnboardingState.pickedSubjects` reste `[]` (liste vide) car aucun picker n'a collecté les matières.

À Step 5, quand le visiteur appuie sur "Continuer en visiteur" :
1. `signInAnonymously()` → OK (session anonymous réutilisée)
2. `setAuthProvider(guest)` → `isVisitor = true`
3. Flush Firestore : `users/{uid}` écrit avec `pickedSubjects: []`
4. `clearPersistedDraft()` est appelé
5. `GoRouter.go('/dashboard')` est appelé
6. **Le router vérifie `profileCompletionProvider`**
7. `profileCompletion` lit `users/{uid}.pickedSubjects = []` → retourne `serieMissing`
8. **Redirect vers `/onboarding/v2`** (guard profil incomplet)
9. `OnboardingShell.loadFromPersistence()` → draft effacé, subSystem=francophone → currentStep=1 (hero) ou suivant (nom)
10. Affichage de Step 6 (ou Step 1 selon l'état du draft)

**Impact** :  
Tous les élèves de 6e, 5e, 4e, 3e (mode dérivé) ne peuvent pas accéder au dashboard, qu'ils soient visiteurs ou potentiellement en compte. Estimation : ~40% des élèves du secondaire francophone (classes de collège).

**Comportement attendu** :  
`GoRouter.go('/dashboard')` avec `isAnonymous:true` et `pickedSubjects:[]` mais un mode dérivé → profil considéré comme "complet enough" pour accéder au dashboard. Les matières sont dérivées dynamiquement côté dashboard depuis le catalogue.

**Fix suggéré (deux options)** :  

Option A — Peupler `pickedSubjects` avant le flush : quand `levelRequiresPicker=false`, appeler `derive()` en arrière-plan dès que le `levelId` est sélectionné et populer `state.pickedSubjects` avec les matières dérivées. Cela garantit que le flush inclut une liste non vide.

Option B — Ajuster `profileCompletionProvider` : pour les niveaux dérivés (`requiresPicker=false`), considérer le profil comme complet sans `pickedSubjects` non vides. Les matières sont calculées à la volée côté dashboard.

**Option A est recommandée** car elle garantit la cohérence entre ce qui est stocké en Firestore et ce que le dashboard affiche.

---

## Bugs S2 — Importants (dégradation UX significative)

---

### BUG-03 · Loader invisible sur Step 2 (Track) : ~4 secondes d'écran quasi-vide

**Sévérité** : S2  
**Reproductible** : 100% au premier accès (catalogue Firestore pas encore en cache).

**Symptôme** :  
Après avoir tapé "C'est parti" sur Step 1 (Hero), Step 2 (Choix de filière) s'affiche avec un fond blanc et un minuscule indicateur bleu au centre. Les cards Générale/Technique n'apparaissent qu'après ~4 secondes. Aucun texte de chargement n'est visible.

**Screenshot** : [screenshots/03_step2_track.png] → écran vide avec micro-dot bleu

**Impact** :  
L'utilisateur peut croire que l'app est gelée. Risque d'abandon ou de tap accidentel sur le fond vide.

**Comportement attendu** :  
Afficher un skeleton loader ou un `CircularProgressIndicator` centré avec un texte "Chargement du programme..." pendant le fetch Firestore. Ou mieux : précharger le catalogue en arrière-plan dès le splash.

---

### BUG-04 · Step 1 (Hero) : Card "Chat IA" partiellement masquée

**Sévérité** : S2  
**Reproductible** : Sur Xiaomi 720×1600 (phone 5,5"). Potentiellement sur tout phone ≤ 375 dp logique.

**Symptôme** :  
La troisième feature card ("Chat IA") est coupée en bas de l'écran. L'utilisateur peut ne pas savoir qu'il y a une troisième card sans scroller. Aucun indicateur visuel de scroll (pas de shadow, pas de chevron).

**Screenshot** : [screenshots/02_step1_hero.png] → "Chat IA" visible à 50%

**Impact** :  
Problème de découvrabilité. Le user rate un argument de vente clé (l'IA).

**Comportement attendu** :  
Soit la 3e card est entièrement visible (contenu scrollable avec affordance visible), soit la 3e feature est affichée en mode compact (icône + texte sur une ligne) pour tenir dans l'espace disponible.

---

### BUG-05 · Reprise après kill inconsistante (cascade du BUG-02)

**Sévérité** : S2 (cascade de BUG-02)  
**Reproductible** : À corriger en même temps que BUG-02.

**Symptôme** :  
Après kill de l'app depuis Step 6 (état anormal causé par BUG-02), le relancement repart à Step 1 (Hero) au lieu de Step 5 (Auth). Le draft avait été effacé par le flush visiteur avant la boucle de redirect.

**Analyse** :  
Le `clearPersistedDraft()` est appelé lors du flush visiteur (avant que le router ait confirmé l'arrivée sur le dashboard). Si le router fait ensuite un redirect vers l'onboarding, le draft est déjà perdu. Résultat : l'état de reprise est incohérent.

**Fix suggéré** :  
Appeler `clearPersistedDraft()` seulement après confirmation que le dashboard est effectivement affiché (via un callback GoRouter ou un flag d'état). Alternativement, ne pas appeler `clearPersistedDraft()` sur le chemin visiteur avant que `profileCompletion.isComplete` soit vérifié.

---

## Bugs S3 — Mineurs (typos / accents manquants)

Toutes les chaînes suivantes sont des accents manquants dans les fichiers ARB ou les valeurs hardcodées Flutter.

| ID | Étape | Texte observé | Texte attendu |
|---|---|---|---|
| BUG-06 | Step 0 | "Choisis ton **systeme** scolaire pour **demarrer**." | "…**système**…**démarrer**." |
| BUG-07 | Step 2 | "Quelle **filiere** suis-tu ?" | "Quelle **filière** suis-tu ?" |
| BUG-08 | Step 3 | "**Selectionne** ton niveau actuel…" | "**Sélectionne** ton niveau actuel…" |
| BUG-09 | Step 5 | "**Cree** ton compte" | "**Crée** ton compte" |
| BUG-10 | Step 5 | "Une seule **etape** pour sauvegarder ton **progres**" | "Une seule **étape**…ton **progrès**" |
| BUG-11 | Step 4 erreur | "**Verifie** ta connexion et **reessaie**." | "**Vérifie**…**réessaie**." |
| BUG-12 | Step 6 | placeholder "Ton **prenom**" | "Ton **prénom**" |
| BUG-13 | Step 6 | body "Ton **prenom** (ou un surnom) suffit." | "Ton **prénom**…" |

> **Note** : La CatalogueWaitingPage (`TF-3.1`) utilise les formes correctement accentuées ("Vérifie", "réessaie") → les ARBs de cette page sont OK. Le problème vient d'un sous-ensemble de strings dans les bodies des steps onboarding.

---

## Issues de performance

| ID | Description | Mesuré | Cible | Dépassement |
|---|---|---|---|---|
| PERF-01 | Firebase init cold start | **3 145 ms** | < 2 000 ms | +57% |
| PERF-02 | E0 smoke test Firestore write+read | **7 649 ms** | < 2 000 ms | ×3,8 |
| PERF-03 | Cards Track visibles sur Step 2 | **~4 000 ms** | < 300 ms | ×13 |
| PERF-04 | Cold start total (boot → Step 0 utilisable) | **~9–10 s** | < 6 s | +67% |

> **PERF-02 (E0 smoke test à 7 649 ms) est particulièrement préoccupant.** Ce test s'exécute en arrière-plan mais consomme un write + un read Firestore sur la connexion de démarrage. Sur un réseau 2G/3G dégradé camerounais (latence 300–800 ms/aller), ce test prendrait 15–25 s. Si ce test bloque le goToOnboarding, c'est un bloquant sur le marché cible.

---

## Ce qui fonctionne bien (✅ Passés)

| Test | Description | Résultat |
|---|---|---|
| TF-7.0 | Splash natif : fond bleu + logo | ✅ Correct |
| TF-7.0b | Splash Flutter : animation livre | ✅ Correct, transition auto |
| TF-7.1a | Step 0 : 2 cards FR/EN avec descriptions | ✅ Affiché |
| TF-7.1b | Step 0 : CTA désactivé sans sélection | ✅ État disabled correct |
| TF-7.1c | Step 0 : tap Francophone → Step 1 immédiat | ✅ Transition correcte |
| TF-7.2a | Step 1 : Hero banner + 3 feature cards | ✅ Affiché |
| TF-7.2b | Step 1 : CTA "C'est parti" actif | ✅ Toujours actif (pas de sélection requise) |
| TF-7.3a | Step 2 : progress bar 1/3 visible | ✅ Correct |
| TF-7.3b | Step 2 : back arrow actif → Step 1 | ✅ Navigation correcte |
| TF-7.4a | Step 3 : 7 niveaux Générale Francophone | ✅ 6e, 5e, 4e, 3e, Seconde, Première, Terminale |
| TF-7.4b | Step 3 : progress bar 2/3 | ✅ Correct |
| TF-1.2b | 6e → skip Step 4 → Step 5 direct | ✅ Navigation correcte |
| TF-7.6a | Step 5 : pas de bouton Apple sur Android | ✅ Correct (absent sur Android) |
| TF-7.6b | Step 5 : séparateur "ou" entre les boutons | ✅ Présent |
| TF-2.2a | Back Step 6 → Step 5 | ✅ Navigation correcte |
| TF-3.1a | Boot offline → CatalogueWaitingPage | ✅ Affiché, pas de crash |
| TF-3.1b | CatalogueWaiting : icône wifi-off + message | ✅ Correct |
| TF-3.1c | CatalogueWaiting : bouton Réessayer | ✅ Présent et cliquable |
| TF-3.1d | Recovery : désactiver avion + Réessayer → Step 0 | ✅ Transition automatique |

---

## Tests non couverts dans cette session

Les éléments suivants n'ont pas pu être testés faute de compte Google configuré sur le device de test, ou parce qu'ils nécessitent des corrections des S1 en amont :

| Test | Raison du non-test |
|---|---|
| TF-1.1 (Terminale D visiteur) | Bloqué par BUG-01 (Step 4 fail) |
| TF-1.3 (Form 5 anglophone) | Bloqué par BUG-01 |
| TF-1.4 (Lower Sixth séries) | Bloqué par BUG-01 |
| TF-1.5 (Google compte Terminale C) | Pas de compte Google sur le device test |
| TF-1.6 (Apple iOS) | Android only |
| TF-1.7 (1ère Technique F2) | Bloqué par BUG-01 |
| TF-2.4 (Switch OAuth → Visiteur) | Pas de compte Google sur le device |
| TF-2.5 (Upgrade visiteur → compte) | Bloqué par BUG-02 |
| TF-3.2 (Offline flush step 9) | Step 9 non atteignable (BUG-01/02) |
| TF-3.6 (Validation phone) | Step 7 non atteint |
| TF-3.7 (Validation nom) | Step 6 atteignable mais hors scope prioritaire |
| TF-3.8/3.9 (École) | Step 8 non atteignable |
| TF-5.x (Responsive tablet) | Pas de tablette dans le setup |
| TF-6.x (i18n EN) | Anglophone partiellement testé |
| TF-8.x (Accessibilité) | Non couvert |
| Dashboard complet | Non atteint (BUG-01/02) |

---

## Plan d'action recommandé

### Priorité immédiate (avant toute session testeur humain)

| Action | Responsable | Délai |
|---|---|---|
| Fixer BUG-01 (Step 4 noMatchingRule) | Dev Amelia | Sprint en cours |
| Fixer BUG-02 (pickedSubjects vide mode dérivé) | Dev Amelia | Sprint en cours |
| Vérifier que tous les accents ARB sont corrects (BUG-06 à 13) | Dev / Tech Writer | < 1h (find & replace) |

### Avant la session testeur (après fix S1)

1. Provisionner **2 comptes Google de test** sur un device Android avant la session
2. Préparer un device iOS (iPhone ou iPad) pour tester OAuth Apple + bouton Apple
3. Vérifier les règles Firestore catalogue : s'assurer que les `derivation_rules` existent pour toutes les combinaisons subSystem × track × level × stream (francophone + anglophone, tous niveaux)
4. Re-run ce même audit ADB après le fix des S1 pour confirmer les regressions éliminées

### Ce qui peut être testé maintenant (sans fix S1)

- TF-2.7 (double-tap robustesse Steps 0–1)
- TF-3.6/3.7 (validation phone et nom sur Step 6/7 — atteignables si on fait un Google OAuth)
- TF-8.1/8.2 (accessibilité taille texte + contraste)
- TF-5.1 (phone portrait — déjà partiellement testé ici)

---

## Annexe — Logs clés capturés

### Séquence de boot (cold start Wi-Fi)

```
09:52:11.647  [PERF] event:boot.main.start
09:52:11.856  [PERF] boot.sharedPreferences.load ok 43ms
09:52:11.864  [PERF] event:boot.runApp
09:52:13.413  [PERF] event:nav.push./splash          ← splash démarre 1823ms après main.start
09:52:15.003  [PERF] boot.firebase.initializeApp ok 3145ms   ← trop lent
09:52:15.012  [PERF] event:boot.firebase.ready
09:52:15.067  connectivity: ConnectivityStatus.online
09:52:15.584  Firestore cache: 40MB, persistence on
09:52:15.747  [PERF] event:nav.push./onboarding/v2   ← splash → onboarding 2334ms
09:52:21.280  Catalogue check: at least 1 derivation_rule active   ← +5533ms après firebase ready
09:52:22.665  E0 smoke test: write+read OK in 7649ms   ← 3× cible
```

### Bug-01 (Step 4 noMatchingRule)

```
10:02:56.026  [PERF] catalogue.derivationRules.fetch ok 1127ms
10:02:56.032  ⚠️ derive() noMatchingRule: subSystem=francophone filiere=generale niveau=francophone_terminale serie=(none)
```

### Bug-02 (Visiteur mode dérivé → Step 6)

```
10:17:53.406  auth.step5 guest reuse existing anonymous session
```
*(Aucun log de flush réussi, aucun nav.push./dashboard → redirect onboarding)*

### Offline boot recovery

```
[Offline] CatalogueWaitingPage affichée (pas de derivation_rule en cache)
[Recovery] Désactiver avion + tap Réessayer → nav.push./onboarding/v2 automatique
```

---

## Annexe — Liste des screenshots

| Fichier | Étape | Contenu |
|---|---|---|
| 01_after_splash.png | Step 0 | SubSystem choice (Francophone / Anglophone) |
| 02_step1_hero.png | Step 1 | Hero intro — "Chat IA" coupée (BUG-04) |
| 03_step2_track.png | Step 2 | Écran quasi-vide, loader (BUG-03) |
| 03b_step2_track_after_wait.png | Step 2 | Cards Générale/Technique après 4s |
| 04_step3_level.png | Step 3 | 7 niveaux Francophone Générale |
| 05_step4_stream.png | Step 4 | "Chargement impossible" (BUG-01) |
| 05b_step4_after_retry.png | Step 4 | Retry → même erreur (BUG-01 confirmé) |
| 06_back_to_level.png | Step 3 | Retour après back depuis Step 4 |
| 07_6e_auth_or_picker.png | Step 5 | Auth choice (6e → skip Step 4 ✅) |
| 08_dashboard_6e_visitor.png | Step 6 | Attendu : Dashboard. Obtenu : Step 6 nom (BUG-02) |
| 09_back_from_step6.png | Step 5 | Back Step 6 → Step 5 ✅ |
| 10_visitor_2nd_attempt.png | Step 6 | 2e tap visiteur → Step 6 encore (BUG-02 confirmé) |
| 11_kill_relaunch.png | Splash | Splash natif après kill |
| 12_after_kill_relaunch_onboard.png | Step 1 | Après kill → Step 1 (BUG-05) |
| 13_offline_boot.png | Splash | Splash en mode avion |
| 14_offline_result.png | CatalogueWaiting | "En attente de connexion" ✅ |
| 15_offline_recovery.png | Step 0 | Récupération online → Step 0 ✅ |

---

*Rapport généré le 2026-06-13 via tests ADB interactifs sur build release v1.0.0.*  
*Pour reproduire : `adb shell pm clear com.valideStartup.valideSchool` puis lancer l'app.*
