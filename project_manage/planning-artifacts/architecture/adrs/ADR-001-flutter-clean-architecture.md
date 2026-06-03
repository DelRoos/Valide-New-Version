# ADR-001 — Flutter + Clean Architecture en 3 couches × features

**Date** : 2026-06-03
**Statut** : 🟢 Accepté

## Contexte

Valide cible iOS + Android avec une équipe restreinte sur 6 semaines de MVP, sur des téléphones d'entrée et milieu de gamme. Le projet doit durer (~équipe pluriannuelle, expansion CEMAC potentielle). Trois options ont été pesées :

- **Native iOS + Android séparés** : performance maximale, mais double effort de dev (~2× le temps).
- **React Native** : équipe JS, mais bridges natifs source de friction sur les composants riches (formules math, schémas Mermaid).
- **Flutter** : base unique iOS + Android, performance native (Skia), écosystème mature (Firebase first-class).

Sur l'organisation interne du code, la tentation classique est de mettre toute la logique dans les `StatefulWidget`. Ça marche au début, devient ingérable à 5+ features avec une équipe qui grandit.

## Décision

- **Flutter** comme framework unique, en V1 Android-first (iOS reporté V2 — cf. PRD § 14).
- **Clean Architecture en 3 couches** (`presentation` / `domain` / `data`), avec règle d'or `presentation → domain ← data`.
- **Découpage horizontal par feature** : chaque dossier `features/X/` contient ses 3 couches. `core/` pour le transversal neutre.
- **`domain` en Dart pur** : interdit d'importer Flutter, Firebase, Dio, Riverpod, `logger`. Vérifié par lint.

## Conséquences

**Positives**

- Une seule base de code à maintenir pour iOS + Android.
- Logique métier (`domain`) testable en quelques millisecondes sans Firebase ni Flutter.
- Changement de techno (par ex. base de données) localisé à `data/` — `presentation` et `domain` intacts.
- Nouveau dev peut comprendre une feature en ouvrant un seul dossier.

**Négatives**

- Plus de fichiers / boilerplate que l'approche « tout dans les widgets ».
- Courbe d'apprentissage pour les devs qui découvrent Clean Architecture.
- Génération de code (`build_runner`) nécessaire pour `freezed`, `json_serializable`, `riverpod_generator`.

**Impact sur les agents BMAD**

- Amelia (dev) consomme une story BMAD et l'implémente en respectant les couches. Lint bloque les violations.
- Les tests de domaine sont écrits **avant** ou en même temps que le code (TDD), sans dépendance Firebase.

## Détail d'implémentation

Voir [`doc/tech/Valide Mobile App Architecture.md`](../../../../doc/tech/Valide%20Mobile%20App%20Architecture.md) — sections 3, 4, 5, 6, 7, 8 (les piliers) et section 14 (structure de dossiers).

## Décisions liées

- [ADR-002](ADR-002-riverpod-vs-getx.md) — choix de Riverpod, conséquence de l'engagement Clean Architecture.
- [ADR-005](ADR-005-shared-surface-doc-partage.md) — `doc/partage/` comme frontière inter-équipes (justifié par la séparation `domain` mobile vs services backend).
