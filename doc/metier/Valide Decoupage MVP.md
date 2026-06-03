# Plan de développement du MVP — 6 phases

**Durée :** 6 semaines · **Portée :** développement de l'app uniquement (contenu produit en parallèle).

Deux niveaux dans ce document :
- **À développer** — le détail pour les développeurs : ce qu'il faut construire, écran par écran, règle par règle.
- **À tester** — les cases à cocher pour valider, utilisables par tous (sans connaissance technique).

---

## Avant de tester (vrai pour toutes les phases)

- Tester sur un **vrai téléphone**, pas seulement sur l'ordinateur des développeurs.
- Tester **en français ET en anglais** (un profil de chaque).
- Tester avec une **connexion lente ou coupée** : l'app ne doit jamais planter ni rester bloquée.
- **Si l'app plante** pendant un test → test échoué.
- Cocher chaque scénario : **✓ réussi** ou **✗ échoué**. Phase validée seulement si **tout est ✓**.

---

## Vue d'ensemble

| Phase | Semaine | À la fin, on peut… |
|---|---|---|
| 1 | S1 | Entrer : langue, profil, compte |
| 2 | S2 | Naviguer et lire les cours |
| 3 | S3 | Faire des quiz, pratiquer (Mode 1 et 2) |
| 4 | S4 | Payer et débloquer le premium |
| 5 | S5 | Voir sa progression, points, notifications |
| 6 | S6 | Mode Assisté, examen, chat, partage, finitions |

---

## Phase 1 — Entrer dans l'application (S1)

### À développer

**Mise en place du socle**
Initialiser le projet Flutter et le projet Cloud Functions, la structure en couches (présentation / domaine / données), le thème de base, la navigation, et le branchement de Firebase (Auth, Firestore). Mettre en place le logging dès le départ pour pouvoir diagnostiquer les phases suivantes.

**Choix du sous-système et langue (M2)**
Au tout premier lancement, afficher l'interface dans la langue du téléphone, puis demander le sous-système (francophone / anglophone). Ce choix fixe **définitivement** la langue de toute l'app (interface, contenu, notifications) ; il n'y a aucun réglage de langue séparé. Une fois choisi, l'app bascule dans la bonne langue et la conserve.

**Profil scolaire (M1)**
Construire le formulaire de profil en étapes obligatoires : filière (générale / technique), niveau, série. À partir de ces choix, **déduire et afficher automatiquement** la liste des matières suivies et des examens visés — sans que l'élève les coche un par un. Cette correspondance (filière + niveau + série → matières + examens) doit être définie quelque part de modifiable.

Permettre de **retirer** des matières non présentées à l'examen, mais seulement dans les cas prévus : anglophones dès la Form 3, et Lower Sixth / Upper Sixth où le stream (Sciences / Arts) détermine la combinaison.

**Règle bloquante :** tant que le profil n'est pas complet, l'élève ne peut accéder à **rien** d'autre dans l'app. À mettre en place comme une redirection systématique (un « garde » de navigation), pas un contrôle éparpillé écran par écran.

**Liaison d'école (optionnelle)**
Proposer de lier une école depuis un catalogue, ou de demander à en ajouter une si elle n'y figure pas. L'élève doit aussi pouvoir **ne pas** lier d'école et continuer.

**Compte et session**
Création de compte via Google et Apple (connexion en deux taps, sans mot de passe). Point important : un visiteur qui a déjà rempli son profil et crée ensuite un compte doit **conserver** son profil — rien à ressaisir. Permettre ensuite de modifier profil, école, nom affiché, photo, et de se déconnecter. L'état (connecté + profil) doit survivre à la fermeture/réouverture de l'app.

**Suppression de compte**
Suppression avec un délai de grâce de 7 jours : pendant ce délai, une reconnexion annule la suppression.

**Mode visiteur**
Un visiteur sans compte peut remplir un profil et accéder à la consultation (préparée en phase 2). À tout moment, il peut créer un compte sans perdre son profil.

### À tester

- [ ] Premier lancement → écran de choix du sous-système.
- [ ] Choisir « francophone » → toute l'app passe en français.
- [ ] Choisir « anglophone » → toute l'app passe en anglais.
- [ ] Remplir filière + niveau + série → les matières et examens s'affichent **tout seuls**.
- [ ] Profil incomplet → impossible de faire quoi que ce soit d'autre.
- [ ] (Anglophone, dès la Form 3) retirer une matière non présentée → possible.
- [ ] Lier une école depuis la liste → elle apparaît sur le profil.
- [ ] Ne pas lier d'école → on peut continuer quand même.
- [ ] Créer un compte Google après avoir rempli le profil en visiteur → profil **conservé**, rien à ressaisir.
- [ ] Modifier nom, photo, école → changements enregistrés.
- [ ] Fermer et rouvrir l'app → on reste connecté, profil retrouvé.
- [ ] Supprimer le compte → délai de 7 jours annoncé ; se reconnecter avant annule la suppression.
- [ ] Parcourir tous les écrans → aucun mot dans la mauvaise langue.

---

## Phase 2 — Naviguer et lire le contenu (S2)

### À développer

**Navigation dans la hiérarchie (M15)**
Construire la navigation qui suit la structure du contenu : matière → chapitre → leçon → notion. Chaque niveau ouvre le niveau suivant. Les exercices sont rattachés à une leçon ; les questions de quiz à une notion (utile pour les phases suivantes).

**Filtrage par profil**
Tout le contenu affiché doit être **filtré automatiquement** selon le profil scolaire : l'élève ne voit que ses matières, ses examens et ses sujets. Il ne filtre jamais lui-même par profil — c'est automatique.

**Lecture des cours**
Afficher les cours en texte enrichi : titres, listes, images, schémas, et **formules mathématiques**. Le rendu doit passer par **un seul composant d'affichage** réutilisable (pas d'appel dispersé à la librairie de rendu), pour pouvoir le remplacer facilement si besoin. Soigner particulièrement le rendu des formules (maths, sciences) et des schémas.

**Filtres et recherche**
Permettre de filtrer les exercices par matière, chapitre, leçon, type et difficulté, et de rechercher un exercice par mot-clé.

**Affichage des énoncés**
Afficher l'énoncé d'un exercice et d'un sujet d'épreuve. Pour un **visiteur** : énoncés visibles, mais impossible de démarrer un mode ou une composition → l'inviter à créer un compte.

**Lecture hors-ligne**
S'appuyer sur le cache de Firebase : un contenu déjà consulté reste lisible sans connexion, et se resynchronise automatiquement au retour du réseau. Ne pas développer de système de cache maison.

**Performance**
Un cours déjà consulté doit s'ouvrir quasi instantanément. Un gros cours chargé pour la première fois affiche un état de chargement et ne fige pas l'interface.

### À tester

- [ ] Ouvrir matière → chapitre → leçon → notion → navigation claire dans cet ordre.
- [ ] Regarder les matières → seulement celles de mon profil.
- [ ] Ouvrir un cours → texte, images, schémas s'affichent bien.
- [ ] Ouvrir 3 cours avec formules (maths/sciences) → formules affichées proprement, pas de texte bizarre.
- [ ] Utiliser les filtres (matière, chapitre, leçon, type, difficulté) → la liste se réduit.
- [ ] Chercher un exercice par mot-clé → résultats corrects.
- [ ] Ouvrir un énoncé d'exercice puis de sujet → énoncé complet affiché.
- [ ] En visiteur, ouvrir un énoncé → visible, mais impossible de lancer un mode (on demande un compte).
- [ ] Ouvrir un cours, le fermer, **couper la connexion**, le rouvrir → reste lisible hors ligne.
- [ ] Rallumer la connexion → resynchronisation automatique, sans action.
- [ ] Rouvrir un cours déjà consulté → s'affiche quasi instantanément.
- [ ] Ouvrir un gros cours pour la 1ʳᵉ fois → indication de chargement, app non figée.

---

## Phase 3 — Quiz et pratique : Mode 1 et Mode 2 (S3)

### À développer

C'est le cœur du produit, et la semaine la plus chargée. Le paiement réel arrive en phase 4 ; cette semaine, on construit les mécaniques de pratique (sans le verrou premium ni le débit de crédits, qu'on branchera ensuite).

**Quiz**
Générer automatiquement (par l'IA) des questions sur une notion ou un chapitre entier, dans plusieurs formes : QCM, vrai/faux, texte à trous, appariement. À la fin, calculer et afficher le score. Le résultat doit être enregistré dans un format **réutilisable** (score + notions concernées), car la santé scolaire et la gamification (phase 5) s'en serviront.

**Mode 1 « Je maîtrise »**
L'élève travaille seul, puis soumet sa réponse en **texte ou en photo** d'un brouillon papier. Pour la photo : capture + **compression avant envoi** (la data est chère, c'est important). La correction est faite par l'IA et distingue ce qui est juste, faux, incomplet, et à mieux rédiger, avec des **renvois cliquables vers le cours**.
Règle technique importante : l'appel à l'IA passe **par le serveur** (Cloud Function), jamais directement depuis l'app — la clé de l'IA ne doit jamais se trouver dans l'app. En cas d'échec réseau, afficher un message clair et permettre de réessayer.

**Mode 2 « Semi-assisté »**
Afficher l'exercice découpé en **étapes ordonnées**. Pour chaque étape : un mini-énoncé, la possibilité de demander **jusqu'à 3 indices progressifs** (pas plus), la consultation de la **portion de cours associée**, et le marquage de l'étape « résolue » ou « non résolue ». À la fin, afficher le **corrigé complet**.
La progression dans l'exercice (étapes marquées, indices déjà vus) doit être conservée si l'élève quitte l'écran et revient pendant la session.

**À préparer pour la suite**
Le Mode 2 sera réservé au premium et le Mode 1 coûtera des crédits — mais ces verrous se branchent en phase 4. Cette semaine, construire les modes de façon à pouvoir **ajouter** facilement le contrôle premium et le débit de crédits ensuite, sans tout réécrire.

### À tester

**Quiz**
- [ ] Lancer un quiz → questions de formes variées (choix multiple, vrai/faux, texte à trous, à relier).
- [ ] Terminer le quiz → score affiché à la fin.

**Mode 1 « Je maîtrise »**
- [ ] Répondre en texte et soumettre → correction : juste / faux / incomplet / à améliorer.
- [ ] Soumettre une **photo** d'un brouillon → photo envoyée, correction reçue.
- [ ] Cliquer un renvoi vers le cours dans la correction → amène au bon passage.
- [ ] Couper la connexion pendant l'envoi → message clair (pas de plantage), réessai possible.

**Mode 2 « Semi-assisté »**
- [ ] Ouvrir le mode → exercice découpé en étapes, un mini-énoncé par étape.
- [ ] Demander des indices plusieurs fois → jusqu'à **3 maximum**, pas un 4ᵉ.
- [ ] Ouvrir le cours associé à une étape → bon extrait affiché.
- [ ] Marquer une étape résolue / non résolue → marquage conservé.
- [ ] Aller au bout → corrigé complet affiché.
- [ ] Quitter en plein milieu puis revenir → progression retrouvée, pas de remise à zéro.

---

## Phase 4 — Payer et débloquer le premium (S4)

### À développer

C'est la semaine la plus risquée techniquement, car elle dépend d'un partenaire externe (l'agrégateur Mobile Money). La démarche d'ouverture de compte marchand doit avoir été lancée dès le début du projet.

**Affichage des plans**
Écran qui présente le plan gratuit et le plan premium, avec clairement ce que le premium ajoute. Souscription en mensuel ou annuel, l'annuel affiché comme moins cher au mois.

**Paiement Mobile Money**
Intégrer l'agrégateur (Tranzak / Campay / MyCoolPay) : l'app demande au serveur de créer une intention de paiement, ouvre la page de paiement de l'agrégateur, et l'élève valide par **code PIN** MoMo / Orange Money sur son téléphone.
Règle critique : **la confirmation du paiement vient du serveur** (l'agrégateur prévient le serveur par un message automatique vérifié), **jamais** de la page de paiement affichée dans l'app. L'app ne se déclare jamais premium toute seule : elle attend que le serveur ait basculé le statut, et le premium se débloque automatiquement.

**Logique premium (branchement des verrous)**
Une fois premium : débloquer le Mode 2, les fiches de lecture, le mode examen, et le chat ×20. Brancher ces verrous sur les fonctionnalités construites avant.
Règle critique : le verrou doit être **réel côté serveur** — un compte gratuit ne doit pas pouvoir lancer le Mode 2 même si l'app était modifiée. La vérification dans l'app n'est qu'un confort pour éviter d'afficher un écran inutile.

**Crédits**
Achat de packs (10 ; 25 + 5 bonus ; 60 + 20 bonus) payés par Mobile Money. Afficher le **solde en permanence** et le **coût d'une action avant de la confirmer**. Brancher le débit de crédits sur la correction Mode 1 (et préparer pour le Mode 3).
Règle critique : une action payante ne doit débiter qu'**une seule fois**, même si l'élève appuie deux fois ou si le réseau force un nouvel essai. Pareil pour les paiements : un même message de l'agrégateur reçu deux fois ne doit pas créditer deux fois.

**Historique et annulation**
Journal détaillé des crédits et historique des transactions. Annulation d'abonnement : reste actif jusqu'à la fin de la période payée, puis bascule en gratuit.

### À tester

**Voir et payer**
- [ ] Ouvrir les abonnements → différence gratuit / premium claire.
- [ ] Option annuelle → présentée comme moins chère au mois.
- [ ] Payer le premium par MoMo/OM → validation par code PIN sur le téléphone.
- [ ] Après paiement → premium se débloque **tout seul**, sans bouton « activer ».
- [ ] Une fois premium, ouvrir le Mode 2 → s'ouvre normalement.

**Blocage sans premium**
- [ ] Compte gratuit, ouvrir le Mode 2 → écran d'abonnement, mode **non** lançable.
- [ ] Compte gratuit → fiches et mode examen **non** accessibles.

**Crédits**
- [ ] Acheter le pack 25 (+5 bonus) → solde augmente de 30.
- [ ] Avant une action payante → coût en crédits affiché **avant** de confirmer.
- [ ] Lancer une correction payante → bon nombre de crédits retiré.
- [ ] Confirmer en **appuyant 2 fois vite** (ou couper/réessayer) → crédits retirés **une seule fois**.
- [ ] Ouvrir l'historique → achats et dépenses détaillés.

**Annulation**
- [ ] Annuler l'abonnement → reste actif jusqu'à la fin de la période payée, puis repasse en gratuit.

---

## Phase 5 — Progression, points, notifications (S5)

### À développer

Ces trois modules s'alimentent des résultats produits en phase 3 (quiz, exercices). C'est pourquoi ils viennent après.

**Santé scolaire (M8)**
À chaque quiz et chaque examen terminé, faire évoluer le niveau de l'élève **notion par notion**. L'IA capture les erreurs et oriente vers ce qu'il faut travailler. La mise à jour du niveau (et des points en même temps) doit se faire **côté serveur, en une seule opération groupée** : tout se met à jour ensemble, ou rien — pour ne jamais avoir un niveau modifié mais des points oubliés.
Affichage : niveau par matière avec une étiquette (solide / à renforcer / priorité), descente dans le détail (chapitre → leçon → notion), tendance d'activité (en progression / stable / en baisse).
Recommandations : jusqu'à 3 sur le tableau de bord. **Règle d'équilibre** : au moins une sur cinq vise une notion déjà solide (pour l'entretenir), pas seulement les points faibles. L'élève peut marquer une reco « faite » ou l'ignorer (elle disparaît), et l'ouvrir mène directement à la ressource.

**Gamification (M9)**
Gagner des points à chaque action utile : quiz complété (selon le score), sujet d'examen achevé (bonus si mention), exercice consulté en mode. Les points ne doivent être crédités qu'**une seule fois** par action (même protection que pour les crédits en phase 4).
Cinq classements : général (permanent), hebdomadaire (remis à zéro chaque lundi à 00h00), par matière, ma classe (si école renseignée), mon école. Mini-carte de rang sur le tableau de bord avec l'évolution vs semaine précédente. Un visiteur peut consulter les classements en lecture seule sans y figurer.

**Notifications (M16)**
Chaque notification arrive **à la fois** en push (écran de verrouillage) et en in-app (écran « notifications », icône cloche). Implémenter les types décrits (rappel d'inactivité, récap après quiz/examen, sujet non terminé, classement hebdo, confirmation de paiement, solde de crédits faible, nouvelle recommandation, ouverture d'un lien partagé), chacun avec sa **condition de déclenchement et son plafond** (par ex. un seul rappel par période d'absence). Pas de réglages personnels dans cette version. Taper une notification ouvre directement le bon écran. Possibilité de tout marquer comme lu d'un geste.

### À tester

**Santé scolaire**
- [ ] Faire un quiz puis regarder la santé scolaire → niveau des notions concernées a évolué.
- [ ] Niveau par matière → étiquette claire : solide / à renforcer / priorité.
- [ ] Descendre matière → chapitre → leçon → notion → niveau visible à chaque détail.
- [ ] Recommandations du tableau de bord → jusqu'à 3, dont au moins une notion déjà maîtrisée.
- [ ] Marquer une reco « faite » / l'ignorer → disparaît.
- [ ] Appuyer sur une reco → amène directement à la ressource conseillée.

**Points et classements**
- [ ] Faire quiz / exercice / sujet → points gagnés (bonus si mention sur un sujet).
- [ ] Refaire la même action terminée (ou 2 appuis) → pas de points en double.
- [ ] Ouvrir les classements → 5 présents : général, hebdo, par matière, ma classe, mon école.
- [ ] Classement hebdo un lundi → remis à zéro.
- [ ] Tableau de bord → mini-carte de rang avec évolution vs semaine précédente.
- [ ] Visiteur sans compte → peut consulter les classements, sans y figurer.

**Notifications**
- [ ] Terminer un quiz → notification récap (score + points) en push ET dans l'app.
- [ ] Ouvrir l'écran notifications (cloche) → classées par date, non-lues en avant.
- [ ] Appuyer sur une notification → amène au bon écran.
- [ ] Plafonds respectés → un seul rappel après une absence, pas un par jour.
- [ ] « Tout marquer comme lu » → toutes passent en lues.

---

## Phase 6 — Assisté, examen, chat, partage, finitions (S6)

### À développer

Cette semaine complète les fonctionnalités restantes et sert aussi de **tampon** pour rattraper ce qui a glissé.

**Mode 3 « Assisté »**
L'IA accompagne pas à pas comme un répétiteur. Pour chaque étape, l'élève envoie texte ou photo, reçoit une analyse détaillée et un conseil ciblé, et peut converser pour comprendre. Chaque session est facturée en crédits — débit **une seule fois par session**, pas à chaque message. Comme pour les autres modes IA, tout passe par le serveur.

**Mode examen**
Composition d'un sujet complet en conditions officielles. Afficher seulement les sujets du profil. Écran de confirmation annonçant la durée officielle et l'absence de pause/aide, puis déclenchement du chronomètre. Navigation libre entre les parties. **Sauvegarde automatique en continu** : rien ne doit être perdu si l'élève quitte l'app ou perd la connexion. Soumission avant la fin, ou envoi automatique à l'expiration. Corrigé partie par partie selon le barème, score total, mention. Réessai possible autant de fois que voulu.

**Chat pédagogique (M6)**
Conversation libre ou contextuelle (depuis un cours, une notion, un exercice). Posture d'accompagnement : l'IA aide à comprendre et **ne donne pas la solution** — si on lui demande la réponse d'un exercice, elle redirige vers une démarche d'apprentissage. Afficher les **diagrammes** générés quand un schéma aide. Épinglage d'un exercice/notion pour garder le contexte. Quota quotidien visible (10 messages en gratuit, 200 en premium). Historique consultable et reprenable.

**Partage de liens (M18)**
Créer un lien de partage sur un exercice, un sujet, une fiche ou un résultat, et le partager (WhatsApp, SMS, email, copie). Ouvrir un lien : si l'app est installée → directement la ressource ; sinon → page d'invitation à installer, puis redirection vers la ressource après installation. Liste des liens partagés avec le nombre d'ouvertures, et désactivation possible d'un lien.

**Stabilisation et lancement**
Corriger les bugs accumulés, tester les parcours principaux de bout en bout sur de vrais téléphones d'entrée/milieu de gamme, vérifier le français et l'anglais, et le comportement en connexion lente/coupée.

### À tester

**Mode 3 « Assisté »**
- [ ] Envoyer texte/photo sur une étape → analyse + conseil ciblé, conversation possible.
- [ ] Lancer une session → crédits retirés **une seule fois** pour la session.

**Mode examen**
- [ ] Liste des sujets → seulement ceux de mon profil.
- [ ] Démarrer → écran d'avertissement (durée, pas de pause/aide) puis chrono démarre.
- [ ] Naviguer librement entre les parties → possible.
- [ ] Fermer l'app (ou couper la connexion) puis revenir → composition retrouvée, rien perdu.
- [ ] Laisser le chrono finir → composition envoyée automatiquement.
- [ ] Après soumission → corrigé partie par partie, score, mention.
- [ ] Refaire le même sujet → possible autant de fois qu'on veut.

**Chat**
- [ ] Poser une question → l'IA aide à comprendre, dans la bonne langue.
- [ ] Demander la réponse d'un exercice → l'IA ne la donne **pas**, oriente vers une démarche.
- [ ] Question nécessitant un schéma → diagramme affiché dans la conversation.
- [ ] Quota de messages → visible et diminue (10/jour gratuit, 200/jour premium).
- [ ] Fermer/rouvrir → historique des conversations retrouvé, reprise possible.

**Partage**
- [ ] Créer un lien sur un exercice, l'envoyer par WhatsApp → lien part.
- [ ] Ouvrir le lien avec l'app installée → ouvre directement la ressource.
- [ ] Ouvrir le lien sans l'app → propose l'installation, puis amène à la ressource.
- [ ] Liste des liens partagés → nombre d'ouvertures visible, désactivation possible.

**Finitions**
- [ ] Parcours complet (entrer → cours → quiz → exercice → payer → progression) → aucun plantage ni blocage.
- [ ] Refaire sur **2 téléphones** différents → marche sur les deux.
- [ ] Refaire **en anglais** → tout traduit et fonctionnel.
- [ ] Refaire avec **connexion lente/coupée** → messages clairs, pas de plantage, reprise normale.

---

## Pilotage

**Si retard à la fin de la phase 4 — reporter dans cet ordre :**

1. Partage de liens.
2. Mode « Assisté ».
3. Chat.
4. 3 classements sur 5 (garder général + hebdo).

**À ne jamais couper :** entrée (P1), contenu (P2), Mode 1 + Mode 2 (P3), paiement (P4).

**Points d'attention :**

- 6 semaines = très court ; la dernière semaine servira sûrement à rattraper du retard.
- Le paiement dépend d'un partenaire externe → lancer la démarche **dès maintenant**.
- La qualité de l'IA demande des ajustements → prévoir du temps.

**Rituel hebdo :** chaque fin de phase, une personne déroule tous les scénarios « À tester », coche ✓/✗. Les ✗ = corrections de la semaine suivante.
