# ADR-002 — Riverpod retenu vs GetX

**Date** : 2026-06-03
**Statut** : 🟢 Accepté

## Contexte

Flutter expose plusieurs solutions de gestion d'état : `setState` brut, `Provider`, `BLoC`, `GetX`, `Riverpod`, `Mobx`, `Redux`. Pour un projet pluriannuel avec une équipe qui peut grandir, le choix engage la maintenabilité, la testabilité et l'onboarding des nouveaux dev.

Deux finalistes ont été comparés en profondeur : **Riverpod** et **GetX**.

**Arguments GetX**

- Rapide à prototyper en solo (très peu de boilerplate).
- API courte (`Get.to`, `Get.find`).
- Gestion d'état + navigation + DI dans un seul package.

**Arguments Riverpod**

- Dépendances **explicites** et vérifiées à la compilation (vs « magie » du service locator global de GetX).
- **Testabilité native** : override d'un provider trivial en test (`overrideWithValue`).
- **Gouvernance** plus solide et écosystème mieux maintenu (équipe rfc, sponsorisé par Flutter Foundation).
- Impose de **bonnes pratiques** au lieu de simplement permettre le raccourci.

## Décision

**Riverpod** (`flutter_riverpod` + `riverpod_annotation` + `riverpod_generator`).

L'**arbitrage assumé** : GetX est plus rapide à prototyper en solo, Riverpod vieillit mieux. Pour un projet destiné à durer (équipe, financement, maintenance pluriannuelle, expansion CEMAC potentielle), **robustesse > vitesse initiale**.

Riverpod sert aussi de **système d'injection de dépendances** — on n'ajoute donc pas `get_it`.

## Conséquences

**Positives**

- Tests de notifier triviaux (1 ligne d'override par provider).
- Dépendances explicites visibles dans le graphe — pas de mystère « d'où vient cet objet ? ».
- `custom_lint` + `riverpod_lint` détectent les erreurs courantes (provider mal utilisé, dépendance oubliée) **avant l'exécution**.
- Migration future facilitée : si Riverpod tombe en désuétude un jour, la séparation Clean Arch (ADR-001) limite l'impact à `presentation/`.

**Négatives**

- Plus de code que GetX pour la même action simple (un provider + un notifier au minimum).
- Courbe d'apprentissage notable pour qui débute (sealed states, AsyncNotifier, override en test).
- Génération de code requise (`@riverpod` annotation).

**Impact sur les agents BMAD**

- Amelia (dev) suit le pattern « provider exposé en type contrat, fourni en impl » (cf. archi mobile § 8.4).
- Les notifiers exposent un état modélisé en sealed class `freezed` — le compilateur force le `switch` exhaustif côté UI.

## Détail d'implémentation

Voir [`doc/tech/Valide Mobile App Architecture.md`](../../../../doc/tech/Valide%20Mobile%20App%20Architecture.md) — section 8 (presentation + Riverpod).

## Décisions liées

- [ADR-001](ADR-001-flutter-clean-architecture.md) — Clean Architecture, dont Riverpod est le système d'injection.
