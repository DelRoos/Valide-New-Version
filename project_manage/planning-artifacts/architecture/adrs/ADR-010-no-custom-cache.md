# ADR-010 — Pas de cache custom : uniquement le cache offline natif de Firestore

**Date** : 2026-06-03
**Statut** : 🟢 Accepté

## Contexte

La connectivité instable du marché cible (cf. SPEC Constraint § connectivité) impose que **l'app reste utilisable** quand le réseau lâche. Pour les contenus déjà consultés, l'élève s'attend à pouvoir les rouvrir hors-ligne.

Plusieurs stratégies existent :

- **Cache custom en mémoire (Map)** : simple mais perdu à la fermeture de l'app.
- **Cache custom persistant (Hive / drift / isar / SharedPreferences)** : robuste mais code à maintenir, gestion de versions de schéma, invalidation, sync avec le backend.
- **Cache offline natif Firestore** : intégré au SDK Firestore, activé par défaut sur mobile, zéro code à écrire.

Le cache Firestore offline garantit :

- Les documents déjà lus sont disponibles hors-ligne automatiquement.
- Les écritures pendant la coupure sont mises en queue et appliquées au retour réseau.
- Les streams (`.snapshots()`) émettent immédiatement depuis le cache, puis se mettent à jour quand le serveur répond.

## Décision

**Aucun système de cache custom n'est développé.** L'app s'appuie **exclusivement** sur :

- Le **cache offline natif de Firestore** pour les documents (cours, énoncés, profil, stats, etc.)
- Le package **`cached_network_image`** pour les médias provenant de Firebase Storage (images d'exercices, schémas) — le cache Firestore ne couvre pas Storage, donc canal séparé indispensable.

Aucun import de `hive`, `drift`, `isar`, `sqflite`, ni de gestion de cache manuel en Map.

## Conséquences

**Positives**

- **Zéro code de cache à maintenir.** Pas de bug d'invalidation, pas de gestion de version de schéma.
- **Comportement éprouvé** : le cache Firestore est utilisé en production par des millions d'apps.
- **Streams en lecture immédiate** : `users/{uid}/stats.snapshots()` émet en moins de 50 ms depuis le cache au retour focus, puis update dès que le serveur répond.
- **Synchronisation gérée nativement** au retour réseau.
- **Simplicité d'onboarding** : un nouveau dev n'a pas à apprendre une stratégie de cache.

**Négatives**

- **Coût des lectures Firestore à surveiller.** Firestore facture chaque **lecture côté serveur**. Le cache atténue mais n'élimine pas — un cold open après plusieurs jours fait des lectures fraîches.
- **Pas de contrôle fin** sur ce qui est mis en cache. Pas de capacité à dire « garde **tout** ce chapitre pour offline, pré-télécharge ». Si le besoin se confirme post-MVP, on ajoutera un mécanisme.
- **Volume cache limité** : Firestore impose 40 MB par défaut sur mobile (configurable). Sur les téléphones modestes avec stockage saturé, le cache peut être évincé.

## Règle de lecture

| Type de donnée | Pattern d'accès |
|---|---|
| Statique (cours, énoncé, leçon, notion, corrigé) | **Lecture standard `.get()`** — le cache Firestore décide automatiquement (serveur ou cache local) |
| Mutable (abonnement, crédits, santé, points, notifs, conversations) | **Stream `.snapshots()`** — le cache émet la valeur connue immédiatement, puis serveur |
| Médias (images, schémas Storage) | **`CachedNetworkImage`** — cache dédié, indépendant de Firestore |

## Anti-patterns à interdire

- ❌ Mettre `await ref.read(coursProvider).getCours(id)` dans une boucle ou dans `build()` — relit le document à chaque rebuild si le cache n'est pas à jour.
- ❌ Stocker manuellement un document Firestore dans une `Map<String, Cours>` côté Riverpod — duplique le cache Firestore et risque la divergence.
- ❌ Importer Hive / drift / isar « au cas où » — gel du périmètre à respecter.

## Cas où le pattern peut être remis en cause

À **réévaluer post-MVP** si l'un des signaux suivants apparaît :

- **Coût Firestore** > budget cible — basculer le contenu lourd et statique vers une base locale (`drift`).
- **Demande utilisateur forte** pour pré-télécharger un chapitre entier pour révision en avion / brousse — nécessite contrôle fin du cache (Hive ou drift).
- **Requêtes locales complexes** (par ex. recherche full-text dans tous les cours déjà lus) — Firestore ne le permet pas, base locale requise.

Si l'une de ces conditions se réalise, ouvrir un nouvel ADR pour réviser cette décision.

## Détail d'implémentation

Voir :

- [`doc/tech/Valide School App Architecture.md`](../../../../doc/tech/Valide%20School%20App%20Architecture.md) — section 12 (la stratégie de cache complète)
- [`doc/tech/Valide School Package Architecture.md`](../../../../doc/tech/Valide%20School%20Package%20Architecture.md) — section 10 (stratégie de cache)

## Décisions liées

- [ADR-003](ADR-003-firebase-full-backend.md) — Firebase pour le backend, dont Firestore avec cache natif.
