# `doc/partage/` — surface partagée entre les 4 équipes Valide

> **Ce dossier est la seule frontière de connaissance entre l'app mobile, le backend, la console admin et la landing page.**
> Tout ce qui doit être compris par **plus d'une équipe** vit ici, et **uniquement** ici.

---

## À qui s'adresse ce dossier

- **Équipe mobile** (ce dépôt) — produit et consomme
- **Équipe backend** (autre dépôt Cloud Functions) — produit et consomme
- **Équipe admin** (autre dépôt) — **consomme** (l'admin visualise les données et déclenche des actions à travers les contrats documentés ici)
- **Équipe landing** (autre dépôt) — **consomme** (la landing peut déclencher des deep links et des inscriptions documentés ici)

L'équipe admin et l'équipe landing **n'ont pas à fouiller** dans le code mobile ou backend. Tout ce dont elles ont besoin pour construire leur app **doit être dans ce dossier**.

---

## Pourquoi ce dossier existe

Sans surface partagée, chaque équipe finit par :

- Lire le code des autres dépôts pour deviner le schéma
- Faire des hypothèses sur les algorithmes et les coder différemment
- Inventer des contrats d'API qui ne correspondent pas à ce que le serveur expose
- Documenter des données de référence (filières, séries, matières) qui divergent

Résultat classique : l'admin affiche un statut « gracePeriod » que le backend n'émet plus, le mobile débit 5 crédits alors que le serveur en débite 3, la landing propose un lien profond qui ne route pas.

Ce dossier prévient cela.

---

## Contenu du dossier

| Fichier | Sujet | Maintenu par (lead) | Consommé par |
|---|---|---|---|
| [`BASE-DE-DONNEES.md`](BASE-DE-DONNEES.md) | Schéma Firestore : collections, documents, champs, indexes, règles de sécurité (résumé) | Backend (lead) + Mobile (co) | Admin, Mobile, Backend |
| [`ALGORITHMES.md`](ALGORITHMES.md) | Algorithmes métier : score, santé scolaire, points, recommandations, idempotence, état d'abonnement | Backend (lead) + Mobile (co) | Admin (pour comprendre les chiffres affichés), Mobile, Backend |
| [`CONTRATS-API.md`](CONTRATS-API.md) | Contrats des Cloud Functions exposées : entrée, sortie, codes d'erreur | Backend (lead) | Mobile, Admin, Landing |
| [`DONNEES-REFERENCE.md`](DONNEES-REFERENCE.md) | Matrices de référence : sous-systèmes, filières, niveaux, séries → matières + examens visés | PM + Backend (lead) | Toutes les équipes |

---

## Règles de maintenance

### 1. Co-maintenance entre mobile et backend

Tout changement qui touche le schéma Firestore, un algorithme métier ou un contrat d'API doit être proposé en PR sur ce dossier, **avant ou en même temps** que la PR de code correspondante (dans le dépôt mobile et/ou backend).

Procédure :

1. L'auteur ouvre une PR dans **ce dépôt** (mobile) avec la modification de `doc/partage/`.
2. L'auteur lie la PR au ticket / story BMAD.
3. Si la modif vient de l'équipe backend : un mainteneur backend approuve la PR mobile (commentaire écrit).
4. Si la modif vient de l'équipe mobile : un mainteneur backend approuve la PR mobile (commentaire écrit).
5. **Pas de merge** sans cet accord croisé.

### 2. Lecture seule pour admin et landing

Les équipes admin et landing **consomment** cette documentation pour construire leur app, mais **ne la modifient pas** directement.

Si l'équipe admin découvre que :
- Un champ documenté ici n'existe pas dans Firestore
- Un algorithme décrit ne produit pas le résultat décrit
- Un contrat d'API ne ressemble pas à la réalité

→ **Ouvrir une issue dans ce dépôt** avec :
- Le fichier de partage concerné
- L'écart observé (capture, exemple)
- Le contexte (sur quelle action / écran)

L'équipe mobile ou backend (selon le sujet) traite l'issue, corrige la doc OU le code, et clôt.

### 3. Sync mensuelle de cohérence

Une fois par mois, un mainteneur fait un audit de cohérence entre `doc/partage/` et la réalité du code (mobile + backend). Le résultat est posté en `#partage` :

- Champs documentés non utilisés en code → à retirer du doc OU à implémenter
- Champs utilisés en code non documentés → à ajouter au doc
- Algorithmes documentés divergents du code → trancher et aligner
- Contrats divergents → trancher et aligner

### 4. Versionnement implicite

Ce dossier suit la même branche que le code (`main`). Pas de versionnement séparé. Si une feature majeure est en cours en branche, sa partie `doc/partage/` est dans la même branche.

Pour les contrats d'API qui doivent supporter plusieurs versions d'app simultanément (utilisateurs avec des versions différentes), voir la règle d'évolution dans [CONTRATS-API.md](CONTRATS-API.md) — on **ajoute des champs optionnels**, on **ne casse jamais** un contrat existant sans versionner explicitement (`V2`).

---

## Convention d'écriture

- **Langue** : français.
- **Identifiers** dans les exemples (noms de champs, fonctions) : anglais (cohérent avec le code).
- **Code en bloc** : syntaxe TypeScript pour les types et schémas (sera compris par mobile via mapping mental Dart, par admin/backend directement).
- **Tables Markdown** pour les listes exhaustives (champs, codes d'erreur).
- **Diagrammes** : Mermaid (rendus par GitHub, GitLab, VS Code).
- Chaque section déclare son **statut** :
  - 🟢 **Stable** : aligné avec le code, à respecter
  - 🟡 **En cours** : décrit ce qui est en cours de construction
  - 🔴 **À compléter** : connu en théorie mais pas encore défini en détail
  - ⚪ **Obsolète** : remplacé par autre chose, à supprimer (le diff explique par quoi)

---

## Comment l'équipe admin / landing utilise ce dossier

1. Cloner **ce dépôt** en lecture pour disposer de `doc/partage/`. Ne pas avoir besoin du reste du code mobile.
2. Lire dans l'ordre :
   - [`DONNEES-REFERENCE.md`](DONNEES-REFERENCE.md) — comprend le découpage filières / matières
   - [`BASE-DE-DONNEES.md`](BASE-DE-DONNEES.md) — comprend ce qui est stocké et comment
   - [`ALGORITHMES.md`](ALGORITHMES.md) — comprend comment les chiffres affichés sont calculés
   - [`CONTRATS-API.md`](CONTRATS-API.md) — comprend comment appeler le backend
3. Mettre en place un **watch / abonnement aux notifications** des PRs sur `doc/partage/` (côté GitHub : « Watch this folder »). Quand un fichier change, vérifier l'impact sur l'admin / landing.

---

## Si tu modifies un fichier de ce dossier

Checklist avant de pousser ta PR :

- [ ] J'ai mis à jour le **statut** des sections impactées (🟢 / 🟡 / 🔴 / ⚪)
- [ ] J'ai mis à jour la table « Historique » en bas du fichier (date, auteur, résumé)
- [ ] J'ai notifié `#partage` qu'une PR touche `doc/partage/`
- [ ] J'ai obtenu l'accord croisé (mobile ↔ backend) requis (cf. règle 1)
- [ ] J'ai vérifié que les autres fichiers du dossier sont cohérents (ex. un nouveau champ dans `BASE-DE-DONNEES.md` doit peut-être apparaître dans un contrat de `CONTRATS-API.md`)
- [ ] L'équipe admin / landing peut comprendre la modif sans consulter le code

---

*Document maintenu en commun. Toute modification du fonctionnement du dossier (règles, conventions) se discute en sync archi cross-équipes.*
