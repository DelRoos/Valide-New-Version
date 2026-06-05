# ADR-015 — Catalogue scolaire Firestore + activation runtime via isActive

**Date** : 2026-06-05
**Statut** : 🟢 Accepté
**Lié à** : [sprint-change-proposal-2026-06-05.md](../../sprint-change-proposal-2026-06-05.md)

## Contexte

La Story 1.1 initiale (mergée comme docs `ready-for-dev` le 2026-06-05, puis cancelled) prévoyait un **seed JSON local statique** embarqué dans le binaire de l'app (`mobile_app/assets/onboarding/catalogue_subjects.json`) + un helper Dart pur `derive()` lisant ce seed via `rootBundle`. Approche cohérente avec l'invariant data-light et le démarrage offline (NFR-2, NFR-5), mais **empêchait toute évolution du catalogue scolaire** sans rebuild et redéploiement sur les stores : ajout d'une matière au programme, activation progressive d'une série selon la production de contenu pédagogique, retrait d'une filière obsolète, correction d'une faute de frappe sur un nom de matière — chaque modification requérait un cycle de release complet.

Le PO Delano Roosvelt a demandé un **pivot architectural** vers Firestore comme source de vérité dynamique, avec un flag `isActive: bool` sur chaque entité (filière, niveau, série, matière, exam_target, derivation_rule) permettant à l'admin pédagogique d'activer/désactiver runtime depuis Firebase Console **sans cycle de release mobile**.

**Citations evidence verbatim** (sprint-change-proposal-2026-06-05.md § 1) :

> « On souhaite gerer toutes les classe meme celle qui ne sont pas des classe d'examen »
> « Les classes et autres doivent venir du firebase »
> « on doit pouvoir desactiver une classse ou une filiere ou une section bref on activeras fonction des donnees au fur a mesure »
> « On dois pouvoir changer tout depuis le firebase activer et desactiver »

## Décision

1. **Catalogue scolaire stocké en Firestore** sur 6 collections (`filieres`, `niveaux`, `series`, `subjects`, `exam_targets`, `derivation_rules`) avec flag `isActive: bool` sur chaque document. Schéma documenté dans [BASE-DE-DONNEES.md § Catalogue scolaire](../../../../doc/partage/BASE-DE-DONNEES.md#catalogue-scolaire-6-collections--story-11a).

2. **Seed initial via script Python externe** `scripts/firebase_seed/seed_catalogue.py` (Story 1.1b) utilisant `firebase-admin` SDK. Source de vérité versionnée dans `scripts/firebase_seed/data/matrice.json`. Le script vit dans CE dépôt mobile (racine, hors `mobile_app/`) — exception explicite à la séparation backend/mobile, justifiée par le fait qu'il n'y a pas (encore) de dépôt backend déployé pour absorber cette responsabilité.

3. **Lecture côté mobile via `CatalogueRepository`** (Story 1.1c) qui applique systématiquement `where('isActive', '==', true)` sur toutes les queries Firestore. Cache offline natif (Story 0.7 + ADR-010) couvre le 2ᵉ+ load.

4. **Dérivation profil → matières + examens exécutée côté client en V1** : helper Dart pur dans `CatalogueRepository.derive()` qui matche la première `derivation_rule` Firestore compatible avec `(subSystem, filiere, niveau, serie)`. Cohérent avec le périmètre mobile-only de ce dépôt (pas de Cloud Function backend déployée à ce stade). Migration future vers Cloud Function `deriveProfile(uid)` triggered Firestore reste possible sans refactor mobile — le repository encapsule la dérivation derrière une interface stable.

5. **Pas de fallback JSON local**. Si Firestore est vide ET le cache offline est vide (1er lancement strictement hors-ligne), Story 1.1c affiche un écran « En attente de connexion » bloquant (UX-DR-24) avec retry. Décision PO assumée : le marché cible Cameroun a de la data limitée mais rarement zéro au tout 1er lancement (typiquement un proche partage du WiFi pour l'install).

## Conséquences

**Positives**

- **Activation progressive** : l'équipe pédagogique active une série (`isActive: true`) quand le contenu pédagogique correspondant est produit, sans cycle de release mobile. Critique pour le périmètre étendu (29 séries `isActive: false` au seed initial, activables au fil de l'eau).
- **Alignement [ADR-003](ADR-003-firebase-full-backend.md)** (Firebase full backend) + **[ADR-010](ADR-010-no-custom-cache.md)** (cache Firestore offline natif suffit, pas de cache custom à développer).
- **Renforce AS-2 PRD** (catalogue produit en parallèle équipe pédagogique).
- **Suppression du risque R4** : la matrice Firestore est l'unique source de vérité runtime — plus de risque de drift entre seed JSON embarqué et schéma backend (qui n'existait de toute façon pas encore).
- **Correction de production** : faute de frappe, renommage de matière, ajout d'une option locale → 1 toggle Console, déploiement en secondes vers tous les utilisateurs.

**Négatives**

- **Dépendance Firestore au 1er lancement** : un utilisateur strictement offline au tout premier démarrage ne peut pas finir l'onboarding. Mitigé par l'écran « En attente de connexion » + invariant marché Cameroun (data limitée mais rarement zéro à l'install) + cache offline Firestore qui prend le relais dès le 2ᵉ chargement.
- **Latence supplémentaire au 1er chargement** : 200-800 ms en 3G pour télécharger les ~50 documents catalogue activés. Cache offline natif couvre les loads suivants (0 ms réseau).
- **Coût Firestore reads** : chaque démarrage profil incomplet déclenche 6 stream subscriptions. Acceptable pour V1 (volumes faibles + free tier Firebase suffit), à surveiller en P5 (Santé scolaire) quand la volumétrie augmentera.
- **Dépendance soft à un script Python externe** (Story 1.1b) pour le seed initial et les évolutions structurelles (ajout d'une matière nécessite d'éditer `data/matrice.json` + re-run du script, OU édition directe depuis Console pour les cas simples). Le porteur (Delano) doit l'exécuter au démarrage du projet et après chaque évolution majeure du catalogue.
- **Pas de validation schéma server-side au-delà de `firestore.rules`** : si le script Python écrit un doc avec une typo de champ, Firestore l'accepte. Mitigation : tests Python en Story 1.1b + revue de la matrice JSON source.

## Alternatives rejetées

- **Seed JSON local statique embarqué** (Story 1.1 cancelled) : pas d'activation runtime, rebuild + redéploiement stores obligatoire pour ajouter une matière. Refusé par PO.
- **Cloud Function intermédiaire `getCatalogue()`** : ajoute une latence cold start (~1-2 s en Cameroun) + dépendance à un backend déployé qui n'existe pas encore + complexifie l'auth (App Check). Pas requis V1 puisque Firestore offre déjà la lecture authentifiée filtrée.
- **Hybride seed JSON local + Firestore optionnel V2** : refusé par PO. Le besoin d'activation runtime est immédiat (catalogue produit en parallèle équipe pédagogique, pas après stabilisation V1).
- **Cloud Function `deriveProfile()` pour la dérivation** : ajoute une latence + dépendance backend. Décision : helper Dart client V1, ré-évaluation si volumétrie ou cohérence l'exige plus tard. Migration sans refactor mobile possible (repository encapsule).

## Décisions liées

- [ADR-003](ADR-003-firebase-full-backend.md) — Firebase full backend. Cohérence : Firestore reste le datastore central, le catalogue n'introduit pas de nouvelle stack.
- [ADR-006](ADR-006-subsystem-fixed-at-signup.md) — Sous-système figé à l'inscription. Le catalogue Firestore rend cette immuabilité tangible : `users/{uid}.subSystem` est immuable + les `derivation_rules` matchent par `subSystem`, donc changer de sous-système signifierait recréer un compte (cohérent avec l'intention ADR-006).
- [ADR-010](ADR-010-no-custom-cache.md) — Pas de cache custom. Le cache offline Firestore natif suffit pour le 2ᵉ+ load du catalogue (NFR-5).
- [ADR-001](ADR-001-flutter-clean-architecture.md) — Clean Architecture 3 couches. `CatalogueRepository` (Story 1.1c) sera dans `lib/core/catalogue/` avec interface `CatalogueRepository` (domain) + impl `CatalogueRepositoryFirestoreImpl` (data) derrière `Either<Failure, T>` (NFR-7).
- [sprint-change-proposal-2026-06-05.md](../../sprint-change-proposal-2026-06-05.md) — décision PO motivante de cette ADR.

## Détail d'implémentation

Voir :
- [BASE-DE-DONNEES.md § Catalogue scolaire (6 collections — Story 1.1a)](../../../../doc/partage/BASE-DE-DONNEES.md#catalogue-scolaire-6-collections--story-11a) — schéma TypeScript des 6 collections + indexes + règles d'accès
- [DONNEES-REFERENCE.md § Tableau de dérivation](../../../../doc/partage/DONNEES-REFERENCE.md#tableau-de-d%C3%A9rivation-subsystem-filiere-niveau-serie--examtargetids) — matrice exhaustive 🟢 toutes classes (79 derivation_rules)
- [ALGORITHMES.md § 1 Dérivation profil → matières + examens](../../../../doc/partage/ALGORITHMES.md#1-d%C3%A9rivation-profil--mati%C3%A8res--examens) — lieu d'exécution V1 (helper Dart client) + pseudo-code
- Story 1.1b — script Python `scripts/firebase_seed/seed_catalogue.py`
- Story 1.1c — `CatalogueRepository` mobile + écran « En attente de connexion »
