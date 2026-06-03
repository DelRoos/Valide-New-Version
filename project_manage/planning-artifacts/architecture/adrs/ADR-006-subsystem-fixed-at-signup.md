# ADR-006 — Sous-système figé définitivement à l'inscription

**Date** : 2026-06-03
**Statut** : 🟢 Accepté

## Contexte

Valide est bilingue FR / EN, ciblant à la fois le sous-système éducatif **francophone** (MINESEC, BEPC, Probatoire, BAC) et **anglophone** (Cameroon GCE Board, GCE O Level, GCE A Level). Ces deux sous-systèmes :

- Ont des **curricula différents** (matières et programmes officiels distincts)
- Sont **rédigés dans deux langues différentes** (français vs anglais)
- Utilisent des **nomenclatures de séries différentes** (`A`, `C`, `D`, `E`, `F1-F5`, `G1-G3` côté FR ; `S1-S8`, `A1-A5` côté EN)

Trois options de design ont été pesées :

- **Toggle de langue indépendant du curriculum** : l'utilisateur choisit sa langue d'interface (FR / EN) et son curriculum (FR / EN) séparément. Permet par ex. à un anglophone de lire en français.
- **Langue dérive du sous-système** : choisir « francophone » fixe l'interface en français et le curriculum côté MINESEC. Choisir « anglophone » fixe l'interface en anglais et le curriculum côté Cameroon GCE.
- **Détection auto par localisation système** : utiliser la langue du téléphone pour proposer un défaut.

## Décision

**La langue dérive du sous-système, et le sous-système est choisi UNE FOIS à l'inscription, sans possibilité de bascule ultérieure.**

Pas d'écran de réglage de langue ailleurs dans l'app. Pas de toggle.

Justifications documentées dans :

- SPEC § Constraints (« Bilingue FR/EN figé à l'inscription par sous-système »)
- PRD FR-1 (« Choix initial du sous-système au premier lancement »)
- EXPERIENCE.md.Foundation (« La langue (FR ou EN) est figée à l'inscription par le choix de sous-système »)

## Conséquences

**Positives**

- **Simplicité utilisateur** : un seul écran de choix au démarrage, pas de confusion langue vs curriculum.
- **Cohérence des données** : tous les contenus liés à un utilisateur sont dans une langue unique — pas de mélange en base.
- **Filtrage automatique du contenu** : le filtre par profil joue aussi le rôle de filtre par langue, sans logique séparée.
- **Notifications dans la bonne langue** garanties (pas de cas où la notif est en FR pour un élève EN ou vice-versa).
- **Catalogue de contenu simplifié** : chaque ressource (cours, leçon, notion, exercice, sujet) a une version FR et une version EN ; le bon est servi par `users/{uid}.subSystem`.

**Négatives**

- **Un anglophone qui voudrait lire en français** (cas hypothétique : étudiant anglophone qui veut s'entraîner aux examens francophones) n'est pas servi. Cas extrêmement rare au Cameroun ; non-goal V1.
- **Choix irréversible** : si l'utilisateur se trompe au premier lancement, il doit supprimer son compte et recréer. Mitigation : la suppression est facile (7 jours de grâce, FR-7), mais il faut un message clair au moment du choix (« Ce choix fixe la langue et le programme. Tu ne pourras pas changer après. »).
- **Pas d'A/B test bilingue intra-utilisateur** possible.

## Implémentation

- `users/{uid}.subSystem` est un champ **immutable** côté serveur (règle Firestore qui rejette toute mise à jour).
- `users/{uid}.language` (dérivé : `fr` si `francophone`, `en` si `anglophone`) idem immutable.
- L'écran de choix au premier lancement est **unique** — pas accessible depuis le Profil après inscription.
- La langue de l'app, des notifications, des emails (si jamais V2), du contenu et du chat IA est **toujours** dérivée de `subSystem`.

## Détail d'implémentation

Voir [`doc/partage/BASE-DE-DONNEES.md`](../../../../doc/partage/BASE-DE-DONNEES.md) (`UserDoc.subSystem` et `language` documentés comme immutables) et [`doc/partage/DONNEES-REFERENCE.md`](../../../../doc/partage/DONNEES-REFERENCE.md) (matrice par sous-système).

## Décisions liées

Aucune dépendance directe à un autre ADR.
