# Temps de chargement — Cibles & protocole de mesure

> Document compagnon de `plan-tests-fonctionnels.md`. Définit les **cibles de
> performance** attendues sur le parcours pré-dashboard et le protocole pour les
> mesurer côté testeur.

## 1. Cibles synthétiques

### Sur Wi-Fi (référence) — appareil Android phone récent (Pixel 4a, iPhone 12+)

| Étape | Cible (médiane) | Limite acceptable | Au-delà = bug |
|---|---|---|---|
| Splash natif → première frame Flutter | < 1,5 s | 2,5 s | > 4 s |
| Splash Flutter animation complète | 2,1 s (fixe) | 2,4 s | > 3 s (animation trop lente) |
| signInAnonymously (boot) | < 1 s | 2 s | > 5 s |
| Catalogue check (Firestore vide check) | < 1 s | 2 s | > 5 s |
| Transition entre 2 étapes onboarding (animation slide) | 300 ms (fixe) | 400 ms | > 500 ms |
| Login Google (du tap au resultat) | < 3 s | 5 s | > 10 s |
| Login Apple | < 3 s | 5 s | > 10 s |
| Recherche école (par caractère après debounce) | < 1,5 s | 3 s | > 5 s |
| Création school_request (tap "+ Ajouter") | < 1 s | 2 s | > 4 s |
| Flush Firestore (étape 9 succès) | < 2 s | 4 s | > 8 s |
| Retry exponentiel cycle complet (3 tentatives) | 4 s (0+1+3) | 5 s | — |
| Nav Dashboard depuis "Découvrir mon dashboard" | < 500 ms | 1 s | > 2 s |

### Sur 3G dégradé — toutes cibles × 2 ou ×3 selon l'opération réseau

Le testeur doit considérer un facteur d'environ **×2 à ×3** sur les opérations
réseau (signIn, Firestore reads/writes, OAuth tokens) sur une connexion 3G de
qualité moyenne.

**À ne PAS multiplier** : les animations (splash, slide), elles sont CPU-bound
et restent constantes.

### Sur appareil bas de gamme (RAM < 2 Go, CPU lent)

- Le splash peut être ralenti de ~500 ms
- Les transitions slide peuvent passer à ~400 ms (acceptable)
- Le démarrage à froid (cold start) peut atteindre **6-8 s** sur Tecno
  Spark / Samsung A03 — encore acceptable mais à signaler si > 10 s

## 2. Protocole de mesure

### Méthode 1 — Chronomètre manuel (facile, imprécis ~ ±300 ms)

Le testeur utilise le chronomètre de son téléphone (ou une montre) :

1. Lancer le chronomètre au moment précis de l'action (tap)
2. Stopper à l'apparition complète de l'écran/état cible
3. Reporter le temps

**Utile pour** : splash, OAuth, recherche école, flush. Pas pour les transitions
< 500 ms.

### Méthode 2 — Vidéo + analyse frame-par-frame (précis ~ ±50 ms)

1. Filmer l'écran avec un autre téléphone à 60 fps (ou la fonction screenrecord
   Android `adb shell screenrecord` à 30 fps)
2. Importer dans VLC / éditeur vidéo, naviguer image par image
3. Mesurer entre 2 frames clés

**Utile pour** : transitions slide, animations.

### Méthode 3 — Logs `perfLogger` côté dev (très précis, nécessite USB)

L'app émet des logs structurés via `perfLogger.dart`. Activer via :

**Android** :
```
adb logcat | grep -E "PERF|nav.push|nav.replace"
```

**iOS** : ouvrir Console.app, filtrer sur "PERF".

Chaque entrée a la forme :
```
[PERF] event:onboarding.flush.users tEpochMs=1781333721127 durationMs=1240
```

**Événements à surveiller** :
- `boot.main.start` → début main()
- `boot.sharedPreferences.load` → fin du load des prefs
- `nav.push./splash` → arrivée splash
- `nav.push./dashboard` ou `nav.push./onboarding/v2` → première vraie page après splash
- `auth.google.signIn` → durée du picker Google
- `auth.google.linkCredential` → durée linkWithCredential
- `school.search.byPrefix` → durée recherche école
- `onboarding.flush.users` → durée flush étape 9
- `dev.auth.signInAnonymously` → reset visiteur

## 3. Cas dégradés à signaler systématiquement

Si l'un de ces seuils est franchi → reporter un bug **S2 (perf)** :

| Symptôme | Seuil bloquant |
|---|---|
| Cold start (du tap icône à étape 0 affichée) | > 10 s sur device de référence |
| Login Google qui prend > 15 s | Quelle que soit la connexion |
| Recherche école qui prend > 5 s | Sur Wi-Fi |
| Flush qui timeout sans 3 retries visibles | Quel que soit le contexte |
| Animation slide qui saccade (< 30 fps perçus) | Sur device de référence |
| Splash bloqué > 4 s sans transition | Quel que soit le contexte |
| Écran blanc / noir entre 2 transitions | Toujours signaler |

## 4. Comment savoir si la durée est conforme

| Symbole de pass | Critère |
|---|---|
| ✅ | Durée ≤ cible médiane sur le device de référence |
| ⚠️ | Durée entre la cible et la limite acceptable — signaler en S3 perf |
| ❌ | Durée au-delà de la limite acceptable — signaler en S2 perf |
| ❌❌ | Au-delà de la borne "bug" — signaler en S1 si l'utilisateur est bloqué |

## 5. Reporter une mesure

Dans le rapport de bug ou la checklist, format recommandé :

```
TF-9.3 — Login Google sur Pixel 4a, Wi-Fi rapide
- Mesure 1 : 2,4 s
- Mesure 2 : 3,1 s
- Mesure 3 : 2,2 s
- Médiane : 2,4 s — ✅ conforme (cible < 3 s)
```

Pour les mesures de transitions courtes, **3 essais minimum**, garder la médiane.

## 6. Variations attendues normales

- **Premier launch après install** : toujours plus lent que les launches suivants (Firebase init, App Check token, etc.)
- **Premier signInAnonymously** : peut prendre 3-5 s vs 1 s les fois suivantes
- **Cold start après reboot** : ajouter ~2 s pour le chargement Dart VM
- **Mode debug vs release** : tester **uniquement** sur build release
  (le mode debug est 5-10× plus lent et n'est pas représentatif)

## 7. Outils additionnels (optionnel)

- **Firebase Performance Monitoring** : déjà configuré côté Firebase, le QA peut
  consulter le dashboard pour les médianes globales par device
- **Flutter DevTools** : si le testeur a un dev sous le coude, peut être ouvert
  via Chrome `chrome://devtools` après `flutter run --profile`
