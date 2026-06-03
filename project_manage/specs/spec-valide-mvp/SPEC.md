---
id: SPEC-valide-mvp
companions:
  - phases-mvp.md
  - glossary.md
  - ../../../doc/tech/Valide School App Architecture.md
  - ../../../doc/tech/Valide School Package Architecture.md
  - ../../../doc/tech/Valide Cloud Function Architecture.md
  - ../../../doc/partage/BASE-DE-DONNEES.md
  - ../../../doc/partage/ALGORITHMES.md
  - ../../../doc/partage/CONTRATS-API.md
  - ../../../doc/partage/DONNEES-REFERENCE.md
sources:
  - ../../../doc/metier/Valide Decoupage MVP.md
  - ../../../doc/metier/MVP Valide School.pdf
---

> **Canonical contract.** Ce SPEC et les fichiers listés en `companions:` forment le contrat complet, préservation-validé, de ce qu'il faut construire, tester et valider. Les documents listés en `sources:` sont là pour traçabilité narrative — ne les consulter que si tu cherches une justification de fond que ce contrat omet intentionnellement.

# Valide MVP — application mobile EdTech bilingue pour le secondaire camerounais

## Why

Les élèves du secondaire camerounais — francophones (BEPC, Probatoire, BAC) et anglophones (GCE O/A Level) — n'ont pas d'outil de préparation aux examens adapté à leur contexte réel : téléphones d'entrée et milieu de gamme (~40 % de pénétration smartphone), data limitée et coûteuse, connectivité instable, paiement par Mobile Money (MTN MoMo, Orange Money). Les apps EdTech existantes sont conçues pour des contextes occidentaux qui ne matchent pas — interfaces lourdes, paiement par carte, contenu hors curriculum local, monolinguisme. **Le projet Valide ambitionne de livrer en 6 semaines un MVP qui combine pratique active (3 modes d'accompagnement), correction IA, paiement Mobile Money, gamification et chat pédagogique, en respectant ces trois contraintes marché non négociables.** Le résultat doit être démontrable à un élève réel sur un Android d'entrée de gamme, en français ou en anglais, avec une connexion 3G fluctuante.

## Capabilities

- id: CAP-1
  intent: Un nouvel élève entre dans l'app en choisissant son sous-système (francophone ou anglophone), renseigne filière + niveau + série, et voit automatiquement ses matières et examens visés se déduire sans cocher individuellement.
  success: Un profil francophone Tle D voit Maths/PCT/SVT/Français/Anglais/Philo/Histoire-Géo/EPS + l'examen `bac_francophone_d` ; un anglophone Upper Sixth S2 voit Chemistry/Physics/Biology + `gce_a_level_anglophone_s2` ; aucun parcours d'inscription n'aboutit avec une liste de matières vide.

- id: CAP-2
  intent: L'élève consulte le contenu par hiérarchie matière → chapitre → leçon → notion, avec rendu du texte enrichi, des formules LaTeX (math/physique) et des schémas (Mermaid/SVG).
  success: Un cours déjà lu s'ouvre quasi-instantanément hors-ligne (cache Firestore natif) ; 3 cours de maths/physique avec formules réelles BAC/Probatoire s'affichent proprement, sans texte cassé ni dégradation des indices/exposants ; le contenu visible est filtré automatiquement par profil sans intervention manuelle.

- id: CAP-3
  intent: L'élève fait des quiz IA et des exercices, soit en autonomie avec correction IA (Mode 1, texte ou photo d'un brouillon papier), soit en semi-assisté avec étapes ordonnées et indices progressifs (Mode 2).
  success: Une soumission Mode 1 (texte ou photo) revient avec une correction IA distinguant juste / faux / incomplet / à mieux rédiger, avec renvois cliquables vers le cours ; Mode 2 expose au maximum 3 indices par étape (un 4ᵉ tap ne révèle rien) ; quitter en plein milieu et revenir restore l'état (étapes marquées, indices déjà vus).

- id: CAP-4
  intent: L'élève souscrit le premium (mensuel ou annuel) ou achète des packs de crédits (10 ; 25 + 5 bonus ; 60 + 20 bonus) via MTN MoMo ou Orange Money, et obtient l'accès automatiquement après confirmation par webhook serveur.
  success: Après validation PIN MoMo/OM, le premium se débloque tout seul sans bouton « activer » (l'app écoute un stream Firestore) ; un double-tap rapide sur « confirmer » ou un retry réseau ne débite/crédite qu'une seule fois (idempotence garantie par sessionId dans la même transaction Firestore) ; un compte gratuit reçoit l'écran paywall avant le Mode 2 et ne peut pas créer de session Mode 2 même si l'app est modifiée (vrai verrou dans les règles Firestore).

- id: CAP-5
  intent: Après chaque activité, le niveau de l'élève évolue par notion (santé scolaire), il gagne des points alimentant 5 classements (général, hebdo, par matière, ma classe, mon école), et le tableau de bord propose jusqu'à 3 recommandations équilibrées.
  success: Le niveau est visible par matière → chapitre → leçon → notion avec étiquette `solide` / `à renforcer` / `priorité` ; le classement hebdo se remet à zéro chaque lundi 00:00 (heure Cameroun, UTC+1) ; au moins 1 recommandation sur 5 vise une notion **déjà solide** pour l'entretenir ; la mise à jour santé + niveau + points s'applique en une transaction Firestore atomique unique (jamais un état partiel).

- id: CAP-6
  intent: L'élève peut être accompagné pas à pas par un tuteur IA (Mode 3), composer un sujet d'examen complet chronométré, discuter avec une IA pédagogique qui n'aide pas à tricher, et partager des liens deep-links vers des ressources.
  success: Mode 3 débite les crédits **une seule fois par session** quel que soit le nombre de messages échangés ; la sauvegarde du mode examen est continue (couper l'app et rouvrir restore intégralement la composition) ; le chat IA refuse de donner la réponse d'un exercice et redirige vers une démarche de résolution ; ouvrir un lien partagé avec l'app installée mène **directement** à la ressource ; sans l'app, le lien propose l'installation puis la ressource.

## Constraints

- **Téléphones d'entrée et milieu de gamme cibles.** L'app doit livrer en moins de 30 MB téléchargés par device (Android App Bundle + split per ABI) et démarrer en moins de 3 secondes sur un Android Go-class ; les modules Firebase sont chargés au plus près de leur usage et `flutter_smooth_markdown` est en lazy-load (jamais au démarrage).
- **Data limitée et coûteuse.** Les photos Mode 1 sont compressées en WebP qualité raisonnable **avant** upload (poste le plus gros côté utilisateur) ; cache Firestore offline activé, aucune relecture en boucle du contenu statique ; pas de système de cache custom (Hive, drift) — uniquement le cache natif.
- **Connectivité instable.** Toute Cloud Function rejouable est idempotente, avec une clé `sessionId` lue **dans la même transaction** que les écritures de données (sinon condition de course garantie sur double-tap) ; Dio configuré avec retry/backoff ; aucune exception ne remonte à l'écran — tout passe par `Either<Failure, T>` (`fpdart`).
- **Bilingue FR/EN figé à l'inscription par sous-système.** Pas d'écran de réglage de langue ; tout le contenu pédagogique doit exister dans les deux langues ; le sous-système fixe non seulement l'interface mais aussi le **curriculum** (MINESEC APC vs Cameroon GCE Board) et donc les matières/examens dérivables.
- **Paiement uniquement par Mobile Money via agrégateur tiers** (Tranzak / Campay / MyCoolPay). La démarche d'ouverture de compte marchand est une dépendance externe critique à lancer dès J1 du projet. Pas de paiement carte en V1.
- **Sécurité côté serveur, pas côté client.** La clé Claude API et les secrets de signature webhook ne quittent jamais le serveur (Secret Manager). Aucune confirmation de premium ou crédit ne vient du client. Le vrai verrou d'accès aux features premium (Mode 2, mode examen, fiches, chat premium) est dans les **règles Firestore**, pas dans le check Flutter local — qui n'est qu'une optimisation UX.
- **Cohérence des écritures liées (santé/niveau/points) garantie par transaction atomique unique** côté Cloud Function, avec la garde d'idempotence à l'intérieur du `runTransaction`. Tout réussit, ou rien — jamais d'état partiel comme « points crédités sans mise à jour santé ».
- **Curriculum conforme aux référentiels officiels.** Côté MINESEC pour le francophone (séries A/C/D côté général ; F1-F4/G1-G3 côté technique). Côté Cameroon GCE Board pour l'anglophone (toutes séries S1-S8 et A1-A5 du A Level + sélection libre dès Form 3 pour le O Level). Détail : voir `DONNEES-REFERENCE.md`.
- **Budget temps strict : 6 semaines, équipe restreinte.** Ordre de coupe en cas de retard : (1) partage de liens, (2) Mode 3, (3) chat IA, (4) 3 classements sur 5 (garder général + hebdo). Jamais couper : entrée P1, contenu P2, Mode 1 + Mode 2 P3, paiement P4.
- **Android-first pour la V1.** ~92 % du marché smartphone camerounais est Android. iOS reporté à V2 (le coût de validation iOS — compte développeur Apple, app review — ne se justifie pas sur le MVP).

## Non-goals

- **Pas de génération de cours par IA.** Le contenu pédagogique est rédigé par des humains, conforme aux programmes officiels MINESEC et Cameroon GCE Board, et produit en parallèle de l'app.
- **Pas de classe virtuelle synchrone.** Pas de cours en direct, pas de visio, pas de tableau blanc partagé. L'IA accompagne en asynchrone.
- **Pas de réseau social entre élèves.** Pas de messages directs, pas de fils d'actualité, pas de profils publics. Les classements affichent seulement nom + photo + score (lecture seule), jamais un canal de communication.
- **Pas de réglages de notifications personnalisés en V1.** Les types et fréquences sont fixés par les règles produit ; l'utilisateur peut « tout marquer comme lu » mais ne désactive pas un type particulier.
- **Pas d'expansion CEMAC immédiate.** V1 cible le Cameroun uniquement — les agrégateurs Mobile Money, le curriculum, les écoles, les langues sont cadrés là-dessus.
- **Pas de réglage manuel de langue.** La langue dérive automatiquement et définitivement du sous-système choisi à l'inscription. Pas de bouton « passer en anglais ».
- **Pas de gestion d'écoles ni de classes par enseignants côté mobile.** C'est la responsabilité de la console admin (dépôt séparé). L'app mobile ne fait que lier optionnellement un élève à une école issue du catalogue.
- **Pas de cache custom maison.** On utilise exclusivement le cache offline natif de Firestore. Pas de Hive, pas de drift, pas de gestion de version de contenu côté client.
- **Pas de tests E2E exhaustifs en V1.** Les tests de domaine, data et présentation sont obligatoires sur les couches Clean Architecture. Les E2E se limitent aux **parcours critiques** de chaque phase, validés sur vrais devices.
- **Pas de support iPad ni tablette spécifique en V1.** Design optimisé téléphone uniquement (gabarit de référence 375×812 ou équivalent à figer avec Design).
- **Pas de marketplace de contenu tiers** (éditeurs externes, enseignants individuels publiant leurs propres exercices). Tout le catalogue est produit ou validé par l'équipe pédagogique Valide.

## Success signal

À la fin de la semaine 6, sur **deux vrais téléphones Android d'entrée et milieu de gamme**, **un élève francophone** (profil Tle D, basé à Yaoundé) et **un élève anglophone** (profil Upper Sixth S2, basé à Buea), chacun dans sa langue, doivent pouvoir compléter le **parcours canonique** suivant sans plantage ni blocage : s'inscrire avec Google → remplir leur profil scolaire → consulter un cours contenant des formules mathématiques → faire un quiz et un exercice en Mode 1 et un en Mode 2 → s'abonner au premium par MoMo (élève FR) ou acheter un pack de crédits par Orange Money (élève EN) → consulter leur santé scolaire et leur rang dans le classement de leur classe. Le test se déroule en **connexion 3G lente coupée et rétablie à plusieurs reprises**, **sans aucune perte de données**, **sans double comptage de points ou de crédits**, et **sans qu'aucun mot dans la mauvaise langue n'apparaisse** sur les écrans parcourus.

## Assumptions

- L'agrégateur Mobile Money choisi (Tranzak, Campay, ou MyCoolPay) expose un webhook de confirmation signé exploitable côté Cloud Function — à confirmer avec le partenaire avant la phase 4.
- Le catalogue de contenu pédagogique (cours, exercices, sujets d'examen) sera produit en parallèle par l'équipe pédagogique avec un volume suffisant pour le démarrage (au minimum 1 matière fully populée par sous-système au moment du lancement, pour démontrer le parcours canonique).
- La région Firebase `europe-west1` (proposition de l'archi backend) offre une latence acceptable vers le Cameroun — à mesurer en phase 1 avant de figer.
- L'équipe pédagogique francophone et anglophone valide la matrice profil → matières → examens dans `DONNEES-REFERENCE.md` au plus tard fin de la phase 1.
- Les agents BMAD Mary, John, Winston, Amelia, Sally et Paige (6 agents v6.8.0 — Bob/Barry/Quinn absents) suffisent pour piloter le projet sans agent custom additionnel.

## Open Questions

- **Catalogue technique du MVP** : quelles séries de l'enseignement technique (F1 à F5, G1 à G3, ESF, IH, MVT…) couvre-t-on dès la V1 ? Le scope proposé est F1-F4 + G1-G3, mais ce point doit être tranché par le PM avec un enseignant de l'enseignement technique avant la phase 2.
- **Séries de Terminale série E** : présente dans certains lycées francophones mais pas dans tous. Inclusion en V1 ou V2 ?
- **Stratégie iOS post-V1** : à quel volume d'utilisateurs déclenche-t-on le port iOS ? Définir un seuil pour piloter par signal et non par instinct.
- **Volume initial de contenu pour le test « parcours canonique »** : combien de leçons, exercices et sujets minimum par sous-système pour valider la Success signal ci-dessus ? À spécifier avec l'équipe pédagogique.
- **Mention vs note sur 20 vs barème officiel** : les BAC/Probatoire/GCE utilisent-ils la même échelle ? Faut-il afficher selon le sous-système ou normaliser ?
- **Comportement de l'app pour un élève sans école renseignée** : il est exclu du classement « ma classe » et « mon école » mais doit-il voir une invitation à renseigner son école sur le dashboard, ou est-ce silencieux ?
- **Plafond de chat premium** : 200 messages/jour est-il un quota strict (refus net après) ou avec dégradation gracieuse (avertissement à 180, blocage à 200) ?

