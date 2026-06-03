# Découpage opérationnel — 6 phases hebdomadaires

> Companion de [SPEC.md](SPEC.md). Décompose le MVP en 6 phases consommables par `bmad-create-epics-and-stories`. Chaque phase est livrable en une semaine et a un livrable utilisateur démontrable.
>
> **Source narrative complète** : [doc/metier/Valide Decoupage MVP.md](../../../doc/metier/Valide%20Decoupage%20MVP.md) (à lire pour les scénarios « À tester » détaillés).

---

## Tableau de bord du MVP

| Phase | Semaine | Cap. SPEC | Livrable utilisateur |
|---|---|---|---|
| 1 | S1 | CAP-1 | Entrer : langue dérivée du sous-système, profil scolaire, compte Google/Apple, école optionnelle, mode visiteur |
| 2 | S2 | CAP-2 | Naviguer la hiérarchie matière → chapitre → leçon → notion, lire les cours, lecture offline |
| 3 | S3 | CAP-3 | Quiz IA, Mode 1 (texte + photo), Mode 2 (étapes + 3 indices max) |
| 4 | S4 | CAP-4 | Paiement Mobile Money (premium + crédits), verrous premium réels, idempotence |
| 5 | S5 | CAP-5 | Santé scolaire par notion, gamification (5 classements), notifications push + in-app |
| 6 | S6 | CAP-6 | Mode 3 IA, mode examen chronométré, chat pédagogique, partage deep-links, stabilisation |

**Règle d'or des coupes en cas de retard** (cf. SPEC § Constraints) :

1. Reporter d'abord : Partage de liens (P6)
2. Puis : Mode 3 Assisté (P6)
3. Puis : Chat IA (P6)
4. Puis : 3 classements sur 5 — garder général + hebdo (P5)

**Jamais couper** : entrée P1, contenu P2, Mode 1 + Mode 2 P3, paiement P4.

---

## Phase 1 — Entrer dans l'application (S1)

**Cap. SPEC** : CAP-1
**Objectif** : Pose le socle technique et permet à un élève d'arriver dans l'app avec un profil complet.

### À développer

- **Socle** : initialiser Flutter + Cloud Functions, structure en couches, thème, navigation, Firebase (Auth, Firestore), logging dès le départ.
- **Choix sous-système (M2)** : premier lancement → choix francophone / anglophone. **Fige définitivement** la langue de l'app (interface, contenu, notifications). Pas d'écran de réglage de langue ailleurs.
- **Profil scolaire (M1)** : formulaire en étapes obligatoires (filière → niveau → série) → matières + examens **déduits et affichés automatiquement** depuis la matrice de référence (cf. `DONNEES-REFERENCE.md`). Stockage de cette correspondance dans un endroit modifiable.
- **Règle bloquante** : tant que le profil n'est pas complet, l'élève n'accède à rien d'autre (garde de navigation centralisée — `go_router redirect`, pas éparpillé).
- **Retrait de matières** autorisé uniquement : anglophones dès Form 3 (sélection O Level) ; Lower/Upper Sixth toutes filières (sélection de la série S1-S8 / A1-A5).
- **Liaison école** (optionnelle) : catalogue + demande d'ajout ; possible de ne pas lier d'école.
- **Compte & session** : Google + Apple (sans mot de passe). Un visiteur qui crée un compte ensuite **conserve** son profil. Modification de profil/école/nom/photo, déconnexion. État persistant après fermeture.
- **Suppression de compte** : délai de grâce de 7 jours, annulé par reconnexion.
- **Mode visiteur** : profil possible + consultation préparée pour P2 ; création de compte à tout moment sans perte.

### Critères d'acceptation (extraits — détail complet dans `doc/metier/Valide Decoupage MVP.md`)

- Premier lancement → écran de choix du sous-système
- Choisir francophone → toute l'app passe en français
- Profil rempli (filière + niveau + série) → matières et examens s'affichent **tout seuls**
- Profil incomplet → impossible de faire quoi que ce soit d'autre
- Anglophone dès Form 3 : retrait d'une matière non présentée → possible
- Visiteur qui crée un compte Google → profil **conservé**, rien à ressaisir
- Fermer/rouvrir l'app → reste connecté, profil retrouvé
- Suppression → délai de 7 jours, annulable par reconnexion
- Aucun mot dans la mauvaise langue sur les écrans parcourus

### Risque principal

L'agrégateur Mobile Money est une dépendance externe critique de la P4 — la démarche d'ouverture de compte marchand doit être **lancée dès le J1 de la P1**, en parallèle du dev.

---

## Phase 2 — Naviguer et lire le contenu (S2)

**Cap. SPEC** : CAP-2
**Objectif** : Permet à l'élève de consulter le contenu pédagogique en mode lecture.

### À développer

- **Navigation hiérarchique (M15)** : matière → chapitre → leçon → notion. Chaque niveau ouvre le suivant. Exercices rattachés à une leçon, questions de quiz à une notion (utile pour P3 et P5).
- **Filtrage par profil** : tout le contenu affiché est filtré automatiquement selon le profil scolaire. L'élève ne filtre jamais lui-même par profil.
- **Lecture des cours** : texte enrichi (titres, listes, images, schémas, **formules mathématiques LaTeX**). Rendu via **un seul composant réutilisable** `PedagogicalContent` (wrappant `flutter_smooth_markdown`). Soigner formules math/sciences et schémas.
- **Filtres et recherche** : filtrer exercices par matière/chapitre/leçon/type/difficulté ; recherche par mot-clé.
- **Affichage des énoncés** : exercice + sujet d'épreuve. **Visiteur** : énoncés visibles, mais impossible de lancer un mode → invitation à créer un compte.
- **Lecture hors-ligne** : cache Firestore natif (cf. archi mobile § 12). **Pas de cache custom.** Resync auto au retour réseau.
- **Performance** : cours déjà consulté → ouverture quasi instantanée ; gros cours → état de chargement, UI non figée.

### Critères d'acceptation (extraits)

- Ouvrir matière → chapitre → leçon → notion → navigation claire dans cet ordre
- Regarder mes matières → seulement celles du profil
- Ouvrir un cours → texte, images, schémas correctement affichés
- 3 cours avec formules (maths/sciences) → formules propres, pas de texte cassé
- Couper la connexion → cours déjà consulté reste lisible hors ligne
- Rallumer la connexion → resynchronisation automatique
- Visiteur : énoncé visible mais impossible de lancer un mode

---

## Phase 3 — Quiz et pratique : Mode 1 et Mode 2 (S3)

**Cap. SPEC** : CAP-3
**Objectif** : Construire le **cœur du produit**. Semaine la plus chargée. Le paiement réel arrive en P4 ; cette semaine construit les mécaniques sans verrou premium ni débit de crédits.

### À développer

- **Quiz IA** : génération automatique sur une notion ou un chapitre, formes variées (QCM, vrai/faux, texte à trous, appariement). Score affiché à la fin. Résultat enregistré dans un format **réutilisable** (score + notions concernées) pour P5.
- **Mode 1 « Je maîtrise »** : travail solo, soumission texte **ou photo** d'un brouillon papier. Pour la photo : capture + **compression avant envoi** (data chère, critique). Correction IA distinguant juste / faux / incomplet / à mieux rédiger, avec renvois cliquables vers le cours.
  - Appel IA **par le serveur uniquement** (Cloud Function) — la clé Claude ne doit jamais être dans l'app.
  - Échec réseau → message clair, possibilité de réessayer.
- **Mode 2 « Semi-assisté »** : exercice découpé en **étapes ordonnées**. Par étape : mini-énoncé, **jusqu'à 3 indices progressifs** (pas plus), portion de cours associée, marquage résolu / non-résolu. À la fin : corrigé complet.
  - Progression conservée si l'élève quitte/revient pendant la session.
- **À préparer pour P4** : construire les modes de façon à pouvoir ajouter facilement le contrôle premium et le débit de crédits ensuite, sans tout réécrire.

### Critères d'acceptation (extraits)

- Quiz : formes variées, score affiché à la fin
- Mode 1 texte : correction distingue juste/faux/incomplet/à améliorer
- Mode 1 photo : envoi de photo, correction reçue, renvois vers le cours fonctionnels
- Mode 1 sans connexion : message clair, réessai possible, pas de plantage
- Mode 2 : étapes affichées avec mini-énoncé
- Mode 2 indices : maximum 3, pas un 4ᵉ
- Mode 2 : marquage résolu/non-résolu conservé
- Mode 2 : quitter en plein milieu et revenir → progression retrouvée

---

## Phase 4 — Payer et débloquer le premium (S4)

**Cap. SPEC** : CAP-4
**Objectif** : Brancher le paiement Mobile Money et le verrouillage des features payantes. **Semaine la plus risquée techniquement** (dépendance externe à l'agrégateur).

### À développer

- **Affichage des plans** : gratuit vs premium (différence claire) ; mensuel vs annuel (annuel affiché comme moins cher au mois).
- **Paiement Mobile Money** : intégration agrégateur (Tranzak / Campay / MyCoolPay). Flux : Cloud Function crée une intention → ouverture page agrégateur en WebView → validation PIN MoMo/OM sur le téléphone.
  - **Règle critique** : confirmation **par webhook serveur** vérifié signature avant toute action. **Jamais** par la page de paiement affichée dans l'app. L'app attend que le serveur ait basculé le statut.
- **Logique premium (verrous)** : une fois premium → débloquer Mode 2, fiches, mode examen, chat ×20. **Verrou réel côté serveur** (règles Firestore). Le check Flutter est uniquement une optimisation UX.
- **Crédits** : packs (10 ; 25 + 5 bonus ; 60 + 20 bonus). Solde affiché en permanence. **Coût d'une action affiché AVANT confirmation**. Branchement sur Mode 1 (et préparation Mode 3).
  - **Règle critique : débit une seule fois** même si l'élève appuie deux fois ou si le réseau force un nouvel essai. Idem paiements : un webhook reçu deux fois ne crédite pas deux fois.
- **Historique** : journal détaillé des crédits et transactions.
- **Annulation** : reste actif jusqu'à fin de période payée, puis bascule gratuit.

### Critères d'acceptation (extraits)

- Ouvrir abonnements → différence gratuit / premium claire
- Option annuelle → présentée comme moins chère au mois
- Payer premium par MoMo/OM → validation PIN sur téléphone
- Après paiement → premium se débloque **tout seul** sans bouton « activer »
- Compte gratuit ouvre Mode 2 → écran d'abonnement, mode **non** lançable
- Acheter pack 25 (+5 bonus) → solde augmente de 30
- Avant action payante → coût affiché **avant** confirmation
- Double-tap rapide sur correction → crédits retirés **une seule fois**
- Annuler abonnement → actif jusqu'à fin de période, puis gratuit

---

## Phase 5 — Progression, points, notifications (S5)

**Cap. SPEC** : CAP-5
**Objectif** : Construire la santé scolaire, la gamification et les notifications. S'alimente des résultats P3.

### À développer

- **Santé scolaire (M8)** : à chaque quiz/examen terminé, faire évoluer le niveau **notion par notion**. IA capture les erreurs et oriente vers ce qu'il faut travailler. Mise à jour niveau + points **côté serveur en une seule opération groupée** (jamais d'état partiel).
  - Affichage : niveau par matière avec étiquette `solide` / `à renforcer` / `priorité`, descente dans le détail (chapitre → leçon → notion), tendance d'activité.
  - **Recommandations** : jusqu'à 3 sur le dashboard. **Règle d'équilibre : au moins 1 sur 5 vise une notion déjà solide** (entretien, pas seulement faiblesses). Marquer « faite » ou « ignorer » → disparaît. Ouvrir → mène à la ressource.
- **Gamification (M9)** : points à chaque action utile (quiz complété → selon score ; sujet d'examen → bonus si mention ; exercice consulté en mode).
  - **Règle critique : crédité une seule fois par action** (même protection que crédits en P4).
  - 5 classements : général (permanent), hebdomadaire (reset chaque lundi 00:00), par matière, ma classe (si école renseignée), mon école.
  - Mini-carte de rang sur dashboard avec évolution vs semaine précédente. Visiteur peut consulter en lecture seule sans y figurer.
- **Notifications (M16)** : chaque notification arrive **à la fois** en push (écran de verrouillage) et in-app (icône cloche).
  - Types : rappel d'inactivité, récap après quiz/examen, sujet non terminé, classement hebdo, confirmation paiement, solde crédits faible, nouvelle reco, ouverture lien partagé.
  - Chacun avec sa condition de déclenchement et son **plafond** (ex. 1 seul rappel par période d'absence).
  - Pas de réglages personnels en V1. Taper une notif ouvre l'écran cible. « Tout marquer comme lu » en un geste.

### Critères d'acceptation (extraits)

- Faire un quiz → santé scolaire de notions concernées évolue
- Niveau par matière → étiquette claire solide/à renforcer/priorité
- Descendre matière → chapitre → leçon → notion → niveau visible à chaque profondeur
- Recommandations dashboard : jusqu'à 3, dont au moins 1 sur notion déjà maîtrisée
- Refaire la même action terminée (ou 2 appuis) → pas de points en double
- Classement hebdo un lundi → remis à zéro
- Tableau de bord : mini-carte de rang avec évolution vs semaine précédente
- Terminer un quiz → notification récap en push ET dans l'app
- Plafonds : un seul rappel après absence, pas un par jour

---

## Phase 6 — Assisté, examen, chat, partage, finitions (S6)

**Cap. SPEC** : CAP-6
**Objectif** : Complète les fonctionnalités restantes et sert de **tampon** pour rattraper le retard.

### À développer

- **Mode 3 « Assisté »** : IA accompagne pas à pas comme un répétiteur. Par étape : envoi texte/photo, analyse détaillée + conseil ciblé, conversation pour comprendre.
  - **Crédits : débit une seule fois par session**, pas à chaque message. Tout passe par le serveur.
- **Mode examen** : composition d'un sujet complet en conditions officielles. Seulement les sujets du profil. Écran de confirmation (durée officielle, pas de pause/aide) puis chronomètre. Navigation libre entre parties.
  - **Sauvegarde automatique continue** — rien perdu si l'élève quitte ou perd la connexion. Soumission avant fin OU envoi auto à expiration. Corrigé partie par partie selon barème, score total, mention. Réessai illimité.
- **Chat pédagogique (M6)** : conversation libre ou contextuelle (depuis un cours, une notion, un exercice). Posture d'accompagnement : **l'IA ne donne pas la solution** — redirige vers une démarche.
  - Afficher diagrammes générés (Mermaid). Épinglage exercice/notion pour garder contexte.
  - **Quota quotidien visible** : 10 messages gratuit, 200 premium. Historique consultable et reprenable.
- **Partage de liens (M18)** : créer un lien sur exercice/sujet/fiche/résultat ; partager (WhatsApp/SMS/email/copie). Ouvrir un lien : app installée → directement la ressource ; sinon → page d'invitation, puis redirection après installation. Liste des liens partagés avec nombre d'ouvertures, désactivation possible.
- **Stabilisation et lancement** : correction des bugs accumulés, tests bout en bout sur vrais téléphones d'entrée/milieu de gamme, vérification FR + EN, vérification connexion lente/coupée.

### Critères d'acceptation (extraits)

- Mode 3 : envoyer texte/photo sur une étape → analyse + conseil ciblé
- Mode 3 : crédits retirés **une seule fois** pour la session, quel que soit le nombre de messages
- Mode examen : liste de sujets = seulement ceux du profil
- Mode examen : démarrer → écran d'avertissement (durée, pas de pause) puis chrono
- Mode examen : fermer l'app puis revenir → composition retrouvée, rien perdu
- Mode examen : laisser le chrono finir → soumission automatique
- Chat : demander la réponse d'un exercice → l'IA **ne la donne pas**, oriente vers une démarche
- Chat : quota visible et qui diminue (10/jour gratuit, 200/jour premium)
- Partage : créer un lien sur exercice, envoyer par WhatsApp, ouvrir avec app installée → ouvre directement la ressource
- Partage : ouvrir lien sans app → propose installation, puis amène à la ressource
- Parcours complet (entrer → cours → quiz → exercice → payer → progression) → aucun plantage ni blocage
- Refait sur **2 téléphones** différents → marche sur les deux
- Refait **en anglais** → tout traduit et fonctionnel
- Refait avec **connexion lente/coupée** → messages clairs, pas de plantage, reprise normale

---

## Pilotage transversal

- **Tester sur un vrai téléphone**, pas seulement sur l'ordi des dev.
- **Tester en FR ET EN** (un profil de chaque).
- **Tester avec une connexion lente ou coupée** — l'app ne doit jamais planter ni rester bloquée.
- **Si l'app plante** pendant un test → test échoué.
- Cocher chaque scénario : **✓ réussi** ou **✗ échoué**. Phase validée seulement si **tout est ✓**.
- **Rituel hebdo** : chaque fin de phase, une personne déroule tous les scénarios « À tester », coche ✓/✗. Les ✗ = corrections de la semaine suivante.
