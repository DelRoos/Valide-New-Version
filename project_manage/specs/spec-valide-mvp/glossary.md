# Glossaire — Valide MVP

> Companion de [SPEC.md](SPEC.md). Définit les termes métier et techniques utilisés dans le SPEC et dans tous les artefacts en aval (PRD, architecture, stories). Tout downstream qui consomme ce SPEC doit aussi consommer ce glossaire pour éviter les ambiguïtés.

---

## Termes métier — Pédagogie

| Terme | Définition |
|---|---|
| **Sous-système** | Le « francophone » ou « anglophone », choisi à l'inscription, qui fixe **définitivement** la langue de l'app **et** le curriculum (MINESEC vs Cameroon GCE). Pas de bascule possible après. |
| **Filière** | Le « générale » ou « technique » dans le système secondaire. Détermine les séries disponibles. |
| **Série** | Désignation officielle de la combinaison de matières d'un élève. Francophone général : `A` (lettres), `C` (maths-physique), `D` (SVT-chimie), `E` (scientifique-technique, selon lycée). Francophone technique : `F1` (mécanique) à `F5` (chimie indus), `G1` (admin) à `G3` (commerce). Anglophone A Level Sciences : `S1` à `S8`. Anglophone A Level Arts : `A1` à `A5`. Détail : [DONNEES-REFERENCE.md](../../../doc/partage/DONNEES-REFERENCE.md). |
| **Niveau** | Année scolaire de l'élève. Francophone : 6ᵉ, 5ᵉ, 4ᵉ, 3ᵉ, Seconde, Première, Terminale. Anglophone : Form 1 à Form 5, Lower Sixth, Upper Sixth. |
| **Stream** (anglophone) | Pour les Lower/Upper Sixth, le grand choix `Sciences` ou `Arts` qui conditionne les séries S1-S8 ou A1-A5 disponibles. |
| **Matière** | Discipline enseignée (Maths, PCT, SVT, Pure Maths, etc.). Référentiel dans la collection Firestore `subjects`. |
| **Chapitre** | Subdivision d'une matière. |
| **Leçon** | Subdivision d'un chapitre. C'est à ce niveau que les exercices sont rattachés. |
| **Notion** | Plus petite unité d'évaluation, subdivision d'une leçon. Un exercice évalue 1+ notions. Les niveaux de **santé scolaire** sont calculés par notion. |
| **Profil scolaire** | Combinaison (sous-système, filière, niveau, série) qui dérive automatiquement les matières suivies et les examens visés. |
| **Examen visé** | Examen officiel qu'un profil prépare. Francophone : BEPC (3ᵉ), Probatoire (Première), BAC (Terminale). Anglophone : GCE O Level (Form 5), GCE A Level (Upper Sixth). |
| **Mention** | Niveau de réussite à un examen (Très Bien, Bien, Assez Bien, Passable, Insuffisant — barème à confirmer). |

## Termes métier — Pratique et accompagnement

| Terme | Définition |
|---|---|
| **Mode 1 « Je maîtrise »** | L'élève travaille seul, soumet sa réponse (texte ou photo d'un brouillon papier), reçoit une correction IA. Coûte des crédits par soumission. |
| **Mode 2 « Semi-assisté »** | L'exercice est découpé en étapes ordonnées. Par étape : mini-énoncé, jusqu'à 3 indices progressifs (max), portion de cours associée. **Réservé aux abonnés premium.** |
| **Mode 3 « Assisté »** | Un tuteur IA accompagne pas à pas comme un répétiteur. Conversation, analyses détaillées. Crédits débités **une seule fois par session**, pas par message. |
| **Mode examen** | Composition d'un sujet officiel complet en conditions chronométrées (durée officielle, pas de pause, pas d'aide). Sauvegarde continue. Corrigé partie par partie selon barème. **Réservé premium.** |
| **Quiz** | Questions générées par IA sur une notion ou un chapitre (QCM, vrai/faux, texte à trous, appariement). Plus court qu'un exercice ou qu'un sujet. |
| **Chat pédagogique** | Conversation libre avec l'IA. Posture d'accompagnement : **l'IA ne donne pas les solutions** des exercices, elle oriente vers une démarche. Quota : 10 messages/jour en gratuit, 200/jour en premium. |
| **Indice (Mode 2)** | Aide progressive révélée par l'élève. Maximum 3 par étape — un 4ᵉ tap ne révèle rien. |
| **Santé scolaire** | Niveau de l'élève par notion, sur une échelle (ex. 0-100), avec étiquette `solide` / `à renforcer` / `priorité`. Mis à jour à chaque activité pédagogique. |
| **Recommandation** | Suggestion sur le tableau de bord (max 3 affichées). Règle d'équilibre : au moins 1 sur 5 doit cibler une notion **déjà solide** (entretien), pas seulement les faiblesses. |

## Termes métier — Économie

| Terme | Définition |
|---|---|
| **Gratuit (free)** | Plan par défaut. Accès à la consultation de contenu, quiz, Mode 1 (avec crédits), chat ×10/jour. Pas de Mode 2, examen, fiches, chat ×20. |
| **Premium** | Abonnement payant (mensuel ou annuel). Débloque Mode 2, mode examen, fiches, chat 200/jour. Inclut un quota de crédits. |
| **Crédits** | Monnaie interne consommable pour les actions IA payantes (correction Mode 1, session Mode 3). Achetable en packs. |
| **Pack de crédits** | Lot vendu : Pack 10 (10 crédits), Pack 25 (25 + 5 bonus = 30), Pack 60 (60 + 20 bonus = 80). |
| **Plan mensuel / annuel** | Cadence de l'abonnement premium. L'annuel est affiché comme moins cher au mois (incitation au plan long). |
| **MoMo** | MTN Mobile Money — wallet mobile dominant chez les utilisateurs MTN au Cameroun. Paiement par PIN sur téléphone. |
| **OM** | Orange Money — wallet mobile dominant chez les utilisateurs Orange. |
| **Agrégateur** | Tiers (Tranzak, Campay, MyCoolPay) qui expose une API unifiée pour encaisser MoMo + OM. La démarche d'ouverture de compte marchand chez l'agrégateur est la dépendance externe critique du projet. |
| **Webhook** | Notification serveur entrante envoyée par l'agrégateur au backend Valide après une transaction. **Source unique de vérité** pour la confirmation de paiement (jamais le retour de la WebView). Signature vérifiée avant toute action. |
| **Délai de grâce (subscription)** | Fenêtre pendant laquelle l'élève garde l'accès premium même si le paiement de renouvellement échoue, pour rattraper sans interruption. |
| **Annulation** | L'élève désactive le renouvellement automatique. L'abonnement **reste actif jusqu'à la fin de la période payée**, puis bascule en gratuit. |

## Termes techniques

| Terme | Définition |
|---|---|
| **App Check** | Mécanisme Firebase qui atteste qu'une requête vient de l'app authentique (via Play Integrity / DeviceCheck). Protège les Cloud Functions sensibles (notamment l'IA coûteuse) contre l'abus. Activé via `enforceAppCheck: true`. |
| **Idempotence** | Propriété : une opération exécutée plusieurs fois produit le même résultat qu'une seule exécution. Garantie par une **clé `sessionId`** générée côté client et vérifiée **dans la même transaction Firestore** que les écritures de données côté serveur (sinon condition de course). Protège contre les double-tap rapides et les retries réseau. |
| **Transaction atomique (Firestore)** | Un `runTransaction` qui regroupe plusieurs lectures/écritures Firestore. Tout réussit, ou rien — jamais d'état partiel. Utilisé pour l'alimentation santé + niveau + points + marque d'idempotence en une seule opération. |
| **Stream Firestore** | Lecture via `.snapshots()` qui émet en continu les changements d'un document/collection. Utilisé pour les données **mutables** (abonnement, crédits, santé, points). Le cache Firestore alimente le stream instantanément, puis se met à jour dès que le serveur répond. |
| **Lecture standard Firestore** | Lecture via `.get()`. Utilisée pour les données **statiques** (cours, énoncés, corrigés). Le cache Firestore offline est automatique. |
| **Either (`fpdart`)** | Type qui contient **soit** un `Failure` (échec), **soit** une valeur attendue (succès). Convention : `Left` = échec, `Right` = succès. Remplace les exceptions qui remontent à l'écran — aucune exception ne traverse les frontières des couches. |
| **Failure** | Échec métier présentable à l'élève (« Pas de connexion », « Abonnement requis »). Convertit les `Exception` techniques aux frontières du repository impl. |
| **`AppLogger`** | Wrapper maison autour de `package:logger`, seul fichier autorisé à importer cette librairie. Centralise la config (niveaux, format, branchement Crashlytics). Toute opération réseau, décision d'accès, paiement, appel IA et erreur attrapée doit **produire un log**. |
| **`PedagogicalContent`** | Widget unique qui enveloppe `flutter_smooth_markdown`. **Seul fichier autorisé à importer ce package** (qui est jeune et à mainteneur unique — risque d'abandon). Si le package casse, on remplace l'implémentation de ce widget sans toucher au reste de l'app. |
| **Two-spine UX contract** | Modèle BMAD v6.8.0 : le livrable UX (skill `bmad-ux`) est en **deux fichiers couplés** — `DESIGN.md` (tokens visuels) et `EXPERIENCE.md` (flux, états, accessibilité) — qui se référencent par `{path.to.token}`. Évite la dérive entre design et engineering. |
| **`.decision-log.md`** | Pattern BMAD v6.7+ : journal des décisions produit / scope / UX prises pendant une skill. Vit à côté du livrable. Lu automatiquement par les skills aval. Coexiste avec les ADR (qui restent pour les décisions **techniques** d'architecture). |
| **`SPEC.md`** | Le noyau à 5 champs (Why, Capabilities, Constraints, Non-goals, Success signal) produit par la skill `bmad-spec`. C'est l'entrée minimale partageable entre skills et entre équipes. |

## Termes BMAD utilisés dans le projet

| Terme | Définition |
|---|---|
| **Skill** | Compétence atomique BMAD invoquée par une commande slash (`/bmad-spec`, `/bmad-prd`, etc.). Émet plusieurs fichiers nommés que la skill suivante consomme explicitement. |
| **Agent** | Persona BMAD avec rôle et style (Mary, John, Winston, Amelia, Sally, Paige). Invocable via `/bmad-agent-X`. |
| **Intent** | Mode d'exécution d'une skill v6.7+ : `Create` (créer), `Update` (modifier chirurgicalement), `Validate` (auditer sans modifier). |
| **Mode (Fast / Coaching)** | Profondeur d'interview de la skill. `Fast` = minimum de questions. `Coaching` = pédagogique, t'apprend les concepts au passage. |
| **Capability (CAP-N)** | Unité de capacité du SPEC. ID stable et unique (jamais réutilisé, jamais renuméroté). Chaque CAP a un `intent` (ce qu'on peut faire) et un `success` (critère testable). |
| **Companion** | Fichier `.md` accompagnant le SPEC qui contient du contenu load-bearing trop volumineux pour le noyau. Listé en `companions:` dans le frontmatter du SPEC. |
| **Adopted companion** | Companion qui appartient à une **autre** skill (ex. `DESIGN.md` de `bmad-ux`, ou les docs d'architecture maintenues à part). Référencé mais pas édité par cette skill. |
| **Surface partagée** | Le dossier [`doc/partage/`](../../../doc/partage/) — la seule frontière de connaissance entre les 4 dépôts du projet (mobile, backend, admin, landing). Co-maintenue par mobile et backend, consommée par admin et landing. |
