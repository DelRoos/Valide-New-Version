# Scénarios de test — Navigation et parcours utilisateur

> **Principe de rédaction** : chaque scénario décrit une situation utilisateur réelle.
> Aucune référence à l'implémentation interne (providers, guards, classes Dart).
> Un testeur QA sans accès au code doit pouvoir exécuter chaque scénario.
>
> **Format** :
> - **L'utilisateur est** — qui est cet utilisateur, dans quel état
> - **Ce qu'il fait** — action déclenchante
> - **Il doit voir** — résultat attendu côté UI
> - **Inacceptable** — ce qui constitue un bug critique (l'utilisateur bloqué, perdu, ou ses données disparues)
>
> **Priorité** : P0 = bloquant / P1 = majeur / P2 = mineur

---

## Catégorie A — Premier lancement

---

### A-01 — Toute première ouverture de l'app
**Priorité** : P0
**L'utilisateur est** : quelqu'un qui installe l'app pour la première fois, aucun compte, aucune donnée locale.
**Ce qu'il fait** : ouvre l'app.
**Il doit voir** : l'animation de démarrage, puis l'écran de choix de langue/sous-système.
**Inacceptable** : écran blanc · crash · tableau de bord affiché sans profil · boucle infinie sur le splash.

---

### A-02 — Réinstallation après désinstallation (compte Firebase existant)
**Priorité** : P0
**L'utilisateur est** : quelqu'un qui avait un compte permanent (Google/Apple) complet, a désinstallé l'app, la réinstalle.
**Ce qu'il fait** : ouvre l'app pour la première fois après réinstallation.
**Il doit voir** : l'animation de démarrage, puis directement le tableau de bord — son compte est reconnu automatiquement via sa session Google/Apple.
**Inacceptable** : l'onboarding depuis le début comme si c'était un nouvel utilisateur · perte de son profil.

---

### A-03 — Nouveau téléphone, même compte Google/Apple
**Priorité** : P0
**L'utilisateur est** : quelqu'un qui change de téléphone, installe l'app sur son nouveau device, se connecte avec le même compte Google/Apple.
**Ce qu'il fait** : ouvre l'app, passe par le flow d'authentification.
**Il doit voir** : son profil et son historique intacts, tableau de bord.
**Inacceptable** : profil perdu · obligé de refaire l'onboarding complet.

---

### A-04 — Premier lancement sans réseau
**Priorité** : P0
**L'utilisateur est** : quelqu'un qui installe l'app et l'ouvre sans connexion internet.
**Ce qu'il fait** : ouvre l'app hors ligne.
**Il doit voir** : un écran lui indiquant qu'une connexion est nécessaire pour démarrer, avec invitation à réessayer.
**Inacceptable** : crash · tableau de bord vide · onboarding vide sans données · boucle de chargement infinie.

---

### A-05 — Retour en ligne après A-04
**Priorité** : P0
**L'utilisateur est** : bloqué sur l'écran d'attente réseau (A-04).
**Ce qu'il fait** : réactive sa connexion (WiFi ou données mobiles).
**Il doit voir** : l'app reprend automatiquement et le redirige vers l'étape correcte (onboarding si nouveau, tableau de bord si compte existant) sans avoir à relancer l'app.
**Inacceptable** : reste bloqué sur l'écran d'attente malgré le réseau · doit fermer et rouvrir l'app.

---

## Catégorie B — Retour sur l'app (utilisateur existant)

---

### B-01 — Retour d'un visiteur avec profil complet
**Priorité** : P0
**L'utilisateur est** : un visiteur (sans compte) qui a terminé l'onboarding lors d'une session précédente.
**Ce qu'il fait** : ferme l'app normalement, la rouvre.
**Il doit voir** : directement le tableau de bord, sans repasser par l'onboarding.
**Inacceptable** : renvoyé à l'onboarding · flash de l'onboarding avant le tableau de bord.

---

### B-02 — Retour d'un utilisateur permanent avec profil complet
**Priorité** : P0
**L'utilisateur est** : connecté avec Google ou Apple, profil complet.
**Ce qu'il fait** : ferme l'app, la rouvre.
**Il doit voir** : directement le tableau de bord.
**Inacceptable** : demande de reconnexion · onboarding · écran blanc.

---

### B-03 — Retour d'un utilisateur en cours d'onboarding (step 2 sur 9)
**Priorité** : P0
**L'utilisateur est** : a ouvert l'app, choisi son sous-système, choisi sa filière, fermé l'app sans aller plus loin.
**Ce qu'il fait** : rouvre l'app.
**Il doit voir** : l'onboarding reprend exactement à l'étape du choix du niveau (étape 3), avec la filière déjà sélectionnée visible — il ne recommence pas depuis le début.
**Inacceptable** : retour à l'étape 0 · filière perdue · tableau de bord vide.

---

### B-04 — Retour d'un utilisateur en cours d'onboarding (step 6 sur 9 — identité)
**Priorité** : P0
**L'utilisateur est** : a choisi son cursus, s'est authentifié avec Google, est en train de saisir son nom, ferme l'app.
**Ce qu'il fait** : rouvre l'app.
**Il doit voir** : l'écran de saisie du nom, avec les informations déjà renseignées pré-remplies si possible.
**Inacceptable** : renvoyé au tableau de bord avec un profil incomplet · renvoyé au début de l'onboarding · crash.

---

### B-05 — Retour sans réseau avec cache disponible
**Priorité** : P1
**L'utilisateur est** : utilisateur régulier (profil complet), utilise l'app fréquemment.
**Ce qu'il fait** : ouvre l'app sans connexion internet.
**Il doit voir** : le tableau de bord avec son contenu disponible en cache. L'app fonctionne en mode hors ligne.
**Inacceptable** : renvoyé sur l'écran d'attente réseau alors qu'il a un cache valide.

---

### B-06 — Retour après très longue absence (session potentiellement expirée)
**Priorité** : P1
**L'utilisateur est** : n'a pas ouvert l'app depuis plusieurs semaines.
**Ce qu'il fait** : rouvre l'app.
**Il doit voir** : tableau de bord ou onboarding selon son profil — aucune demande de reconnexion surprenante si son compte était permanent.
**Inacceptable** : erreur technique incompréhensible · renvoi vers l'onboarding pour un compte permanent qui existait · perte de profil.

---

## Catégorie C — Parcours onboarding complets

---

### C-01 — Visiteur : onboarding complet (parcours rapide)
**Priorité** : P0
**L'utilisateur est** : nouveau, choisit de continuer sans créer de compte.
**Ce qu'il fait** : choisit son sous-système → filière → niveau → (série et matières si applicable) → « Continuer en visiteur » → valide l'écran de confirmation.
**Il doit voir** : le tableau de bord, personnalisé avec son profil scolaire.
**Inacceptable** : renvoyé sur l'onboarding après la validation · tableau de bord vide sans matières · crash.

---

### C-02 — Compte Google : onboarding complet
**Priorité** : P0
**L'utilisateur est** : nouveau, veut créer un compte Google.
**Ce qu'il fait** : choisit son cursus → se connecte avec Google → saisit son nom → (téléphone optionnel) → (école optionnelle) → valide.
**Il doit voir** : le tableau de bord avec son nom affiché, profil complet.
**Inacceptable** : renvoyé sur l'onboarding en boucle · nom absent du profil · tableau de bord vide.

---

### C-03 — Compte Apple : onboarding complet (iOS uniquement)
**Priorité** : P0
**L'utilisateur est** : nouveau sur iPhone/iPad, veut créer un compte Apple.
**Ce qu'il fait** : choisit son cursus → se connecte avec Apple ID → saisit son nom → (téléphone optionnel) → (école optionnelle) → valide.
**Il doit voir** : le tableau de bord.
**Inacceptable** : même que C-02.

---

### C-04 — Niveau sans série (dérivation automatique des matières)
**Priorité** : P0
**L'utilisateur est** : élève de 6ème francophone (ou tout niveau sans série spécifique).
**Ce qu'il fait** : choisit son cursus jusqu'au niveau → l'app passe directement à l'étape d'authentification sans lui demander de choisir une série ou des matières.
**Il doit voir** : l'étape d'authentification directement après le choix du niveau. Après validation, le tableau de bord avec ses matières correctement remplies (dérivées automatiquement par le système).
**Inacceptable** : tableau de bord sans aucune matière · renvoyé sur l'onboarding car "matières manquantes".

---

### C-05 — Niveau avec série (choix des matières requis)
**Priorité** : P0
**L'utilisateur est** : élève de Terminale D (ou tout niveau avec séries distinctes).
**Ce qu'il fait** : choisit son cursus → niveau → doit choisir sa série → les matières associées sont présentées → valide → continue.
**Il doit voir** : les étapes de choix de série et de matières, puis l'authentification, puis le tableau de bord avec ses matières.
**Inacceptable** : étape série absente · matières de la mauvaise série · tableau de bord vide.

---

### C-06 — Retour arrière pendant l'onboarding
**Priorité** : P1
**L'utilisateur est** : en train de faire l'onboarding, réalise qu'il s'est trompé de filière.
**Ce qu'il fait** : appuie sur le bouton retour depuis n'importe quelle étape.
**Il doit voir** : l'étape précédente avec les choix déjà effectués encore visibles (il peut modifier). Les choix du niveau, série, matières se réinitialisent si la filière change (cohérence des données).
**Inacceptable** : retour à l'étape 0 depuis n'importe quelle étape · perte des choix déjà valides · crash.

---

### C-07 — Skip du téléphone
**Priorité** : P1
**L'utilisateur est** : en train de remplir son identité, ne souhaite pas donner son numéro.
**Ce qu'il fait** : appuie sur « Passer » à l'étape téléphone.
**Il doit voir** : passage à l'étape école, puis validation possible. Profil considéré complet.
**Inacceptable** : bloqué sur l'étape téléphone · profil incomplèt sans numéro.

---

### C-08 — Skip de l'école
**Priorité** : P1
**L'utilisateur est** : ne connaît pas son école dans la liste ou ne veut pas la renseigner.
**Ce qu'il fait** : appuie sur « Passer » à l'étape école.
**Il doit voir** : passage à l'étape de confirmation, validation possible. Profil complet.
**Inacceptable** : bloqué · profil incomplet sans école.

---

### C-09 — Essai de navigation vers le tableau de bord pendant l'onboarding
**Priorité** : P0
**L'utilisateur est** : en cours d'onboarding (profil incomplet).
**Ce qu'il fait** : tente d'accéder directement au tableau de bord (deep link, manipulation d'URL, bouton système).
**Il doit voir** : renvoyé sur l'onboarding — impossible d'accéder au tableau de bord sans profil complet.
**Inacceptable** : tableau de bord accessible avec profil vide · contenu incohérent affiché.

---

### C-10 — Essai de retourner sur l'onboarding avec profil déjà complet
**Priorité** : P0
**L'utilisateur est** : profil complet, tableau de bord actif.
**Ce qu'il fait** : tente d'accéder directement à l'onboarding (deep link, manipulation).
**Il doit voir** : redirigé automatiquement vers le tableau de bord — l'onboarding est une route à sens unique.
**Inacceptable** : onboarding accessible · données du profil écrasées · boucle.

---

## Catégorie D — Interruptions pendant l'onboarding (kill app)

> Dans tous ces scénarios, "ferme l'app" signifie une fermeture forcée (kill process),
> pas une mise en arrière-plan.

---

### D-01 — Ferme l'app avant d'avoir choisi le sous-système
**Priorité** : P0
**L'utilisateur est** : vient d'ouvrir l'app pour la première fois, voit le choix de langue/système.
**Ce qu'il fait** : ferme l'app sans rien sélectionner.
**Il doit voir** : au prochain lancement, le même premier écran — l'app repart de zéro.
**Inacceptable** : crash · écran blanc · tableau de bord vide.

---

### D-02 — Ferme l'app après avoir choisi le sous-système
**Priorité** : P0
**L'utilisateur est** : a choisi « Francophone » ou « Anglophone », voit l'écran d'introduction.
**Ce qu'il fait** : ferme l'app.
**Il doit voir** : au prochain lancement, reprend à l'écran d'introduction (le sous-système est conservé, il ne le choisit pas à nouveau).
**Inacceptable** : retour au choix de sous-système · perte du choix.

---

### D-03 — Ferme l'app après avoir choisi la filière
**Priorité** : P0
**L'utilisateur est** : a choisi sa filière (ex. Générale), voit l'écran de choix du niveau.
**Ce qu'il fait** : ferme l'app.
**Il doit voir** : au prochain lancement, reprend à l'écran de choix du niveau avec la filière déjà sélectionnée visible.
**Inacceptable** : retour à l'étape 0 · filière perdue.

---

### D-04 — Ferme l'app après avoir choisi le niveau
**Priorité** : P0
**L'utilisateur est** : a choisi son niveau, attend le choix de série ou l'étape d'auth.
**Ce qu'il fait** : ferme l'app.
**Il doit voir** : au prochain lancement, reprend à la bonne étape suivante (série si applicable, auth sinon).
**Inacceptable** : perte du niveau · retour au début.

---

### D-05 — Ferme l'app pendant que la fenêtre Google/Apple est ouverte
**Priorité** : P0
**L'utilisateur est** : à l'étape d'authentification, a appuyé sur « Se connecter avec Google », la fenêtre OAuth est ouverte.
**Ce qu'il fait** : ferme l'app sans terminer la connexion.
**Il doit voir** : au prochain lancement, retour à l'étape d'authentification — comme si l'authentification n'avait pas eu lieu. Son cursus scolaire est toujours là.
**Inacceptable** : état auth corrompu · perte du cursus · crash au reboot.

---

### D-06 — Ferme l'app après authentification réussie mais avant la saisie du nom
**Priorité** : P0
**L'utilisateur est** : s'est connecté avec Google/Apple, voit l'écran de saisie du nom.
**Ce qu'il fait** : ferme l'app sans saisir son nom.
**Il doit voir** : au prochain lancement, directement l'écran de saisie du nom — pas le tableau de bord (l'identité est incomplète).
**Inacceptable** : tableau de bord accessible avec identité incomplète · retour à l'étape d'authentification · crash.

---

### D-07 — Ferme l'app après avoir saisi son nom mais avant de valider
**Priorité** : P1
**L'utilisateur est** : a tapé son nom dans le champ, n'a pas encore appuyé sur « Continuer ».
**Ce qu'il fait** : ferme l'app.
**Il doit voir** : au prochain lancement, l'écran de saisie du nom avec son nom pré-rempli si possible (ou le champ vide, auquel cas il ressaisit).
**Inacceptable** : tableau de bord avec nom vide · crash.

---

### D-08 — Ferme l'app pendant la saisie du numéro de téléphone
**Priorité** : P1
**L'utilisateur est** : à l'étape téléphone, a commencé à taper son numéro.
**Ce qu'il fait** : ferme l'app.
**Il doit voir** : au prochain lancement, l'écran de téléphone vierge — le numéro saisi n'est pas conservé (données personnelles sensibles).
**Inacceptable** : numéro de téléphone stocké localement et affiché au reboot.

---

### D-09 — Ferme l'app après avoir choisi son école
**Priorité** : P1
**L'utilisateur est** : a sélectionné son école dans la liste.
**Ce qu'il fait** : ferme l'app avant de valider l'étape finale.
**Il doit voir** : au prochain lancement, l'étape école avec son choix pré-sélectionné.
**Inacceptable** : choix perdu · retour avant l'école.

---

### D-10 — Ferme l'app pendant l'enregistrement final (réseau coupé)
**Priorité** : P0
**L'utilisateur est** : sur l'écran de confirmation/célébration, l'app enregistre son profil.
**Ce qu'il fait** : perd le réseau ou ferme l'app pendant l'enregistrement.
**Il doit voir** : au prochain lancement, l'écran de confirmation à nouveau avec possibilité de réessayer l'enregistrement — rien n'a été perdu, l'app peut réessayer.
**Inacceptable** : tableau de bord vide · renvoi au début de l'onboarding · profil partiellement enregistré avec matières manquantes.

---

### D-11 — Réseau coupé pendant l'enregistrement final, retry
**Priorité** : P0
**L'utilisateur est** : sur l'écran de confirmation, enregistrement échoue (pas de réseau).
**Ce qu'il fait** : voit un message d'erreur, attend que le réseau revienne, appuie sur « Réessayer ».
**Il doit voir** : l'enregistrement réussit, tableau de bord affiché.
**Inacceptable** : l'app n'offre pas de retry · données enregistrées en double · profil corrompu.

---

## Catégorie E — Upgrade : visiteur → compte permanent

---

### E-01 — Visiteur crée un compte Google (happy path)
**Priorité** : P0
**L'utilisateur est** : visiteur avec profil scolaire complet, utilise l'app depuis le tableau de bord.
**Ce qu'il fait** : choisit de créer un compte, sélectionne Google, s'authentifie avec son compte Google, complète son identité (nom, téléphone optionnel, école optionnelle), valide.
**Il doit voir** : son profil scolaire intact après l'upgrade (il n'a pas à recommencer l'onboarding scolaire), tableau de bord avec compte permanent.
**Inacceptable** : perte du profil scolaire · renvoi à l'onboarding scolaire · nouveau compte vide.

---

### E-02 — Visiteur crée un compte Apple (iOS, happy path)
**Priorité** : P0
**Même principe que E-01, avec Apple ID.**

---

### E-03 — Visiteur abandonne l'upgrade (ferme la modale)
**Priorité** : P1
**L'utilisateur est** : visiteur, a ouvert la modale de création de compte.
**Ce qu'il fait** : ferme la modale sans s'authentifier.
**Il doit voir** : retour au tableau de bord, profil visiteur intact, aucun changement.
**Inacceptable** : profil modifié · erreur affichée · déconnexion.

---

### E-04 — Erreur réseau pendant l'upgrade
**Priorité** : P1
**L'utilisateur est** : visiteur, a tapé « Se connecter avec Google » mais le réseau échoue.
**Ce qu'il fait** : subit une erreur de connexion.
**Il doit voir** : message d'erreur dans la modale, possibilité de réessayer. Profil visiteur intact.
**Inacceptable** : compte créé partiellement · profil visiteur perdu · état auth corrompu.

---

### E-05 — Ferme l'app pendant la fenêtre OAuth de l'upgrade
**Priorité** : P0
**L'utilisateur est** : visiteur avec profil complet, a appuyé sur « Google » dans la modale d'upgrade, la fenêtre OAuth est ouverte.
**Ce qu'il fait** : ferme l'app.
**Il doit voir** : au prochain lancement, retour au tableau de bord en tant que visiteur — exactement comme avant l'upgrade tenté. Profil intact.
**Inacceptable** : état intermédiaire · profil perdu · renvoi à l'onboarding.

---

### E-06 — Ferme l'app après la liaison OAuth réussie, avant de finir l'identité
**Priorité** : P0
**L'utilisateur est** : vient de se connecter avec Google dans le cadre de l'upgrade, est à l'écran de saisie du nom.
**Ce qu'il fait** : ferme l'app sans terminer la saisie.
**Il doit voir** : au prochain lancement, l'écran de saisie du nom. Son profil scolaire est intact. Il n'est pas renvoyé au tableau de bord avec un compte incomplet.
**Inacceptable** : tableau de bord accessible avec compte Google mais sans nom · renvoi à l'onboarding scolaire.

---

### E-07 — Ferme l'app pendant la saisie du numéro de téléphone (upgrade)
**Priorité** : P1
**Même principe que D-08** — le numéro n'est pas stocké, l'utilisateur ressaisit.
**Il doit voir** : l'étape téléphone vierge, profil scolaire et nom déjà validés intacts.

---

### E-08 — Ferme l'app pendant l'enregistrement final de l'upgrade
**Priorité** : P0
**L'utilisateur est** : a complété toute l'identité, l'app enregistre le profil complet.
**Ce qu'il fait** : ferme l'app ou perd le réseau.
**Il doit voir** : au prochain lancement, l'écran de confirmation à nouveau pour réessayer. Pas de données perdues.
**Inacceptable** : compte Google sans nom dans le profil · tableau de bord vide · renvoi à l'onboarding scolaire.

---

## Catégorie F — Déconnexion

---

### F-01 — Déconnexion depuis le profil (happy path)
**Priorité** : P0
**L'utilisateur est** : connecté avec Google ou Apple, sur l'onglet Profil du tableau de bord.
**Ce qu'il fait** : appuie sur « Déconnexion ».
**Il doit voir** : renvoyé immédiatement sur l'écran de début d'onboarding. Son compte cloud est intact (il pourra se reconnecter).
**Inacceptable** : reste sur le tableau de bord · crash · écran blanc.

---

### F-02 — Ferme l'app immédiatement après avoir appuyé sur « Déconnexion »
**Priorité** : P1
**L'utilisateur est** : vient d'appuyer sur Déconnexion, l'app commence à traiter.
**Ce qu'il fait** : ferme l'app.
**Il doit voir** : au prochain lancement, l'onboarding (la déconnexion est considérée comme complète ou l'app redetecte l'absence de session).
**Inacceptable** : retour au tableau de bord du compte déconnecté · état d'authentification incohérent.

---

### F-03 — Relance l'app après déconnexion
**Priorité** : P0
**L'utilisateur est** : s'est déconnecté (F-01), rouvre l'app.
**Ce qu'il fait** : ouvre l'app.
**Il doit voir** : l'onboarding depuis le début (ou depuis le choix de filière si le sous-système était déjà connu). Pas d'accès direct au tableau de bord.
**Inacceptable** : tableau de bord de l'ancien compte · données de l'ancien compte visibles.

---

### F-04 — Se reconnecte après déconnexion
**Priorité** : P1
**L'utilisateur est** : s'est déconnecté, est sur l'onboarding, décide de se reconnecter avec Google.
**Ce qu'il fait** : refait l'onboarding, arrive à l'étape d'authentification, choisit Google avec le même compte.
**Il doit voir** : son ancien profil récupéré, tableau de bord.
**Inacceptable** : nouveau profil vide créé à la place de l'existant · erreur "compte déjà utilisé".

---

## Catégorie G — Suppression de compte

---

### G-01 — Suppression complète (happy path)
**Priorité** : P0
**L'utilisateur est** : compte permanent, sur la page Paramètres du compte.
**Ce qu'il fait** : appuie sur « Supprimer mon compte », confirme dans la dialog.
**Il doit voir** : l'app le renvoie sur l'écran de démarrage (onboarding depuis le début). Son compte n'existe plus — s'il tente de se reconnecter avec le même Google, l'app le traite comme un nouvel utilisateur.
**Inacceptable** : reste sur le tableau de bord · données encore accessibles · erreur technique sans explication.

---

### G-02 — Annule la suppression
**Priorité** : P1
**L'utilisateur est** : sur la dialog de confirmation de suppression.
**Ce qu'il fait** : appuie sur « Annuler ».
**Il doit voir** : retour sur la page Paramètres, compte intact, aucune modification.
**Inacceptable** : suppression déclenchée quand même · données modifiées.

---

### G-03 — Réseau coupé pendant la suppression
**Priorité** : P0
**L'utilisateur est** : a confirmé la suppression, le réseau est indisponible.
**Ce qu'il fait** : attend.
**Il doit voir** : message d'erreur réseau clair. La suppression n'est pas effectuée, ou n'est que partiellement effectuée. L'app l'informe qu'il peut réessayer.
**Inacceptable** : compte supprimé à moitié sans message · boucle · crash.

---

### G-04 — Reconnexion nécessaire (session trop ancienne)
**Priorité** : P1
**L'utilisateur est** : n'a pas ouvert l'app depuis longtemps, sa session est expirée.
**Ce qu'il fait** : tente de supprimer son compte.
**Il doit voir** : message clair lui demandant de se reconnecter d'abord avant de pouvoir supprimer le compte.
**Inacceptable** : suppression partielle sans message · erreur technique opaque.

---

### G-05 — Ferme l'app pendant la suppression (entre suppression des données et suppression du compte)
**Priorité** : P0
**L'utilisateur est** : a confirmé la suppression, l'app est en train d'effacer ses données.
**Ce qu'il fait** : ferme l'app pendant le processus.
**Il doit voir** : au prochain lancement, l'app détecte l'état intermédiaire et le renvoie vers l'onboarding — il peut recommencer comme un nouvel utilisateur. Il ne se retrouve pas dans un état bloqué ou avec des données fantômes.
**Inacceptable** : boucle entre tableau de bord et onboarding · état bloqué · crash au reboot.

---

### G-06 — Rouvre l'app après G-05 (état intermédiaire)
**Priorité** : P0
**L'utilisateur est** : a eu une suppression interrompue (G-05).
**Ce qu'il fait** : rouvre l'app.
**Il doit voir** : l'onboarding. Il peut créer un nouveau profil normalement.
**Inacceptable** : tableau de bord avec données corrompues · erreur permanente · boucle.

---

### G-07 — Visiteur sur la page Paramètres : pas de suppression disponible
**Priorité** : P1
**L'utilisateur est** : visiteur anonyme, accède à la page Paramètres du compte.
**Ce qu'il fait** : consulte la page.
**Il doit voir** : message indiquant qu'il n'a pas de compte permanent, et une invitation à créer un compte pour accéder à cette fonctionnalité. Pas de bouton de suppression.
**Inacceptable** : bouton de suppression visible pour un visiteur · crash.

---

### G-08 — Compte avec suppression planifiée visible au retour
**Priorité** : P1
**L'utilisateur est** : a demandé la suppression différée de son compte, rouvre l'app dans les 7 jours.
**Ce qu'il fait** : navigue vers Paramètres du compte.
**Il doit voir** : un bandeau d'avertissement indiquant la date de suppression prévue, avec option d'annulation.
**Inacceptable** : suppression exécutée sans avertissement · bandeau absent.

---

### G-09 — Annule la suppression planifiée en revenant sur l'app
**Priorité** : P1
**L'utilisateur est** : a une suppression planifiée, rouvre l'app (dans les 7 jours) sans rien faire de particulier.
**Ce qu'il fait** : ouvre simplement l'app.
**Il doit voir** : l'app annule automatiquement la demande de suppression (elle interprète le retour comme un signal de changement d'avis). Le bandeau disparaît.
**Inacceptable** : compte supprimé alors que l'utilisateur est revenu · annulation non effectuée alors que l'utilisateur est actif.

---

## Catégorie H — Accès direct et navigation entre pages

---

### H-01 — Accès direct au tableau de bord sans profil (deep link)
**Priorité** : P0
**L'utilisateur est** : sans profil complet (onboarding non terminé).
**Ce qu'il fait** : tente d'accéder directement au tableau de bord.
**Il doit voir** : renvoyé sur l'onboarding.
**Inacceptable** : tableau de bord accessible sans profil.

---

### H-02 — Accès direct à l'onboarding avec profil complet
**Priorité** : P0
**L'utilisateur est** : profil complet, tableau de bord actif.
**Ce qu'il fait** : tente d'accéder directement à l'onboarding.
**Il doit voir** : renvoyé sur le tableau de bord automatiquement.
**Inacceptable** : onboarding affiché · risque d'écraser son profil.

---

### H-03 — Consulte le profil public d'un autre utilisateur
**Priorité** : P1
**L'utilisateur est** : profil complet, tableau de bord actif.
**Ce qu'il fait** : accède au profil public d'un pair.
**Il doit voir** : la page de profil public du pair, avec possibilité de revenir en arrière.
**Inacceptable** : crash · tableau de bord de l'autre utilisateur · erreur d'autorisation.

---

### H-04 — Tente d'accéder au profil public d'un autre sans être connecté
**Priorité** : P1
**L'utilisateur est** : profil incomplet.
**Ce qu'il fait** : tente d'accéder à `/user/:uid` d'un pair.
**Il doit voir** : renvoyé sur l'onboarding.
**Inacceptable** : profil public accessible sans session.

---

### H-05 — Navigation entre les onglets du tableau de bord
**Priorité** : P1
**L'utilisateur est** : sur le tableau de bord.
**Ce qu'il fait** : navigue entre Accueil, Cours, Examens, Profil.
**Il doit voir** : chaque onglet conserve son état (pas de rechargement à chaque changement d'onglet).
**Inacceptable** : scroll reseté à chaque changement d'onglet · crash · renvoi vers l'onboarding depuis un onglet.

---

### H-06 — Retour système Android depuis la page Paramètres
**Priorité** : P1
**L'utilisateur est** : sur la page Paramètres du compte.
**Ce qu'il fait** : appuie sur le bouton retour système Android.
**Il doit voir** : retour sur le tableau de bord, onglet Profil.
**Inacceptable** : crash · retour sur l'onboarding · pile de navigation incorrecte.

---

### H-07 — Swipe-back iOS depuis la page Paramètres
**Priorité** : P1
**L'utilisateur est** : sur la page Paramètres (iPhone).
**Ce qu'il fait** : glisse depuis le bord gauche pour revenir.
**Il doit voir** : retour sur le tableau de bord.
**Inacceptable** : crash · animation cassée · mauvaise page.

---

### H-08 — Double appui sur un bouton de validation
**Priorité** : P1
**L'utilisateur est** : sur n'importe quel écran avec un bouton de confirmation (onboarding, upgrade, suppression).
**Ce qu'il fait** : appuie deux fois rapidement sur le bouton.
**Il doit voir** : une seule action exécutée. Le bouton est désactivé pendant le traitement.
**Inacceptable** : double enregistrement · double suppression · double requête OAuth.

---

### H-09 — App mise en arrière-plan puis revenue au premier plan
**Priorité** : P1
**L'utilisateur est** : n'importe où dans l'app (onboarding, tableau de bord, profil).
**Ce qu'il fait** : passe sur une autre app, revient sur Valide School après quelques minutes.
**Il doit voir** : exactement le même écran qu'avant, dans le même état. Aucune perturbation.
**Inacceptable** : renvoyé sur l'onboarding · perte de la navigation en cours · crash au retour.

---

### H-10 — Rotation d'écran pendant l'onboarding (tablette)
**Priorité** : P1
**L'utilisateur est** : sur une tablette, en train de faire l'onboarding.
**Ce qu'il fait** : pivote la tablette.
**Il doit voir** : l'interface s'adapte, les données saisies sont conservées, même étape.
**Inacceptable** : retour à l'étape précédente · données perdues · crash.

---

## Matrice des risques — Parcours non gérés prioritaires

Les scénarios suivants représentent les chemins les plus à risque d'aboutir sur un état non géré. Ils doivent être couverts en priorité absolue.

| Scénario | Risque principal |
|---|---|
| A-01 | Utilisateur bloqué dès la première seconde |
| A-04 / A-05 | Boucle ou écran mort sans réseau |
| B-03 | Perte du draft = abandon de l'onboarding |
| C-04 | Tableau de bord vide (matières absentes) |
| C-09 / C-10 | Accès non autorisé ou boucle |
| D-06 | Compte permanent sans identité = état fantôme |
| D-10 | Profil non enregistré après onboarding = perte silencieuse |
| E-06 | Upgrade interrompu = état compte incohérent |
| F-01 | Déconnexion sans redirect = compte accessible sans session |
| G-05 / G-06 | Suppression interrompue = état bloqué permanent |
