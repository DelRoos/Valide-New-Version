# ADR-005 — `doc/partage/` comme surface partagée entre les 4 dépôts

**Date** : 2026-06-03
**Statut** : 🟢 Accepté

## Contexte

Valide est composé de **4 applications dans 4 dépôts séparés** :

1. App mobile Flutter (ce dépôt)
2. Backend Cloud Functions TypeScript (autre dépôt)
3. Console admin (autre dépôt)
4. Landing page (autre dépôt)

Sans surface partagée maintenue, chaque équipe finit par lire le code des autres pour deviner :

- Le schéma Firestore (quels champs existent, quels types)
- Les algorithmes métier (scoring, santé scolaire, idempotence)
- Les contrats des Cloud Functions (input / output / codes d'erreur)
- Les données de référence (matières dérivées d'un profil)

Résultat classique : l'admin affiche un statut `gracePeriod` que le backend n'émet plus, le mobile débit 5 crédits alors que le serveur en débite 3, la landing propose un deep link qui ne route pas.

## Décision

Créer un dossier **`doc/partage/`** **dans le dépôt mobile** (ce dépôt), **co-maintenu** par les équipes mobile et backend, et **consommé en lecture** par les équipes admin et landing.

Contenu :

| Fichier | Sujet | Lead | Consommé par |
|---|---|---|---|
| `BASE-DE-DONNEES.md` | Schéma Firestore (22 collections, indexes, règles d'accès résumées) | Backend + Mobile | Admin, Mobile, Backend |
| `ALGORITHMES.md` | 11 algorithmes métier (score, santé, points, recommandations, idempotence, état d'abonnement, débit crédits…) | Backend + Mobile | Admin (pour comprendre les chiffres affichés), Mobile, Backend |
| `CONTRATS-API.md` | 12 Cloud Functions (entrée, sortie, codes d'erreur, mapping vers `Failure` mobile) | Backend | Mobile, Admin, Landing |
| `DONNEES-REFERENCE.md` | Matrice profil → matières/examens (MINESEC + GCE) | PM + Backend | Toutes les équipes |

Règles de maintenance (cf. CONTRIBUTING.md § 13) :

1. Toute PR mobile qui touche le schéma Firestore, un algorithme métier ou un contrat d'API doit **mettre à jour `doc/partage/` dans la même PR**.
2. Modifications de contrats backend requièrent **accord écrit** d'un mainteneur backend (commentaire dans la PR).
3. L'équipe admin et landing **consomment**, ne modifient pas — elles ouvrent une issue si elles trouvent une divergence.
4. **Sync mensuelle** : audit de cohérence doc ↔ code.

## Conséquences

**Positives**

- Une **seule** source de vérité pour les contrats inter-équipes.
- L'équipe admin peut **commencer à construire** sa console sans attendre que le backend soit terminé (les contrats sont documentés).
- L'équipe landing peut configurer ses deep links sans lire le code Flutter.
- **Onboarding cross-équipe** facilité.

**Négatives**

- **Coût de maintenance** : la doc doit être tenue à jour à chaque PR impactante. Sans discipline, dérive garantie.
- **Localisation** : héberger dans le dépôt mobile plutôt que dans un dépôt dédié peut sembler arbitraire. Mais ça évite un 5ᵉ dépôt à maintenir, et les équipes admin / landing clonent ce dépôt en lecture (sans avoir besoin du code mobile pour autant).
- **Risque de retard** : si une PR backend est mergée avant que `doc/partage/` ne soit mis à jour, divergence introduite. Mitigation par la règle de PR cross-référencée.

## Alternatives écartées

- **Dépôt dédié pour la surface partagée** : 5ᵉ dépôt à maintenir, plus de friction pour les contributions.
- **Code généré (OpenAPI / JSON Schema)** : envisagé en stratégie 2 (cf. archi backend § 8.2). Reporté V2 si le périmètre dépasse les ~12 contrats actuels.
- **Communication informelle (Slack, Notion)** : convenu de pas tenir le rôle de contrat — pas indexable, pas reviewable, pas versionable.

## Impact sur les agents BMAD

- Winston (architecte) référence `doc/partage/` comme sources adoptées dans `architecture.md`.
- John (PM) référence `DONNEES-REFERENCE.md` pour les règles produit liées aux séries.
- Amelia (dev) consulte `BASE-DE-DONNEES.md` et `CONTRATS-API.md` avant d'écrire un datasource.

## Détail d'implémentation

Voir [`doc/partage/README.md`](../../../../doc/partage/README.md) (mode d'emploi du dossier) et CONTRIBUTING.md § 13.

## Décisions liées

- [ADR-004](ADR-004-bmad-method.md) — BMAD pilote chaque dépôt, surface partagée co-maintenue.
- [ADR-008](ADR-008-idempotency-via-sessionid.md) — l'idempotence est un algorithme documenté dans `doc/partage/ALGORITHMES.md`.
