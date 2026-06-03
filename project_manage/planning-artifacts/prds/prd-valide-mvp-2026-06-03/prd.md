---
title: Valide School MVP
status: draft
created: 2026-06-03
updated: 2026-06-03
spec_ref: ../../../specs/spec-valide-mvp/SPEC.md
---

# PRD — Valide School MVP

*Premier passage. Vise à fixer le QUOI (exigences fonctionnelles + non-fonctionnelles + scope) en s'appuyant sur le SPEC déjà distillé. Le COMMENT (architecture, choix techniques) est dans les docs d'archi cibles.*

---

## 0. Document Purpose

Ce PRD est destiné à John (PM Valide), Winston (architecte), Amelia (dev mobile et code review/sprint planning), Sally (UX) et les équipes consommatrices (admin, landing). Il **dérive du** [`SPEC-valide-mvp`](../../../specs/spec-valide-mvp/SPEC.md) sans le répéter — il l'enrichit en fixant : personas nommées, user journeys, FRs nominales avec consequences testables, NFRs cross-cutting, scope MVP, métriques de succès. Le vocabulaire est verrouillé par [`glossary.md`](../../../specs/spec-valide-mvp/glossary.md) — toute synonymie dans le présent doc est une violation. Les détails opérationnels par phase sont dans [`phases-mvp.md`](../../../specs/spec-valide-mvp/phases-mvp.md) ; les choix techniques sont dans les trois docs d'architecture mobile et backend.

---

## 1. Vision

**Valide** est une application mobile bilingue qui aide les élèves du secondaire camerounais à préparer concrètement leurs examens officiels — BEPC, Probatoire, BAC pour les francophones ; GCE O et A Level pour les anglophones. Elle remplace le cahier d'exercices, l'application étrangère mal adaptée, et le tutorat trop cher par un compagnon de poche qui tient sur un Android d'entrée de gamme et fonctionne quand la connexion lâche.

L'app propose trois modes de pratique progressifs : **Mode 1** (autonome avec correction IA texte ou photo d'un brouillon), **Mode 2** (semi-assisté par étapes avec indices progressifs, premium), **Mode 3** (tuteur IA conversationnel). Elle suit la progression notion par notion, propose des recommandations équilibrées, et accueille la composition de sujets d'examens en conditions officielles. Le paiement passe par **MTN Mobile Money** et **Orange Money** via un agrégateur tiers ; le premium et les crédits se débloquent automatiquement après confirmation serveur.

Le moment est propice : la pénétration smartphone au Cameroun atteint ~40 % et croît, les examens BEPC/Probatoire/BAC restent un goulot d'étranglement social majeur, et aucun outil existant ne combine curriculum local (MINESEC APC + Cameroon GCE Board), paiement Mobile Money, bilinguisme, et conception mobile-first pour téléphones modestes. Valide cible cette niche en 6 semaines de MVP, avec une équipe restreinte et un pipeline BMAD discipliné.

---

## 2. Target User

### 2.1 Jobs To Be Done

Du point de vue d'un élève camerophone en classe d'examen :

- **Réussir l'examen officiel** (BEPC, Probatoire, BAC, GCE) sans payer un tutorat hors de portée.
- **Comprendre les notions difficiles** au moment où je bloque, pas trois jours après en cours collectif.
- **Pratiquer activement** plutôt que relire passivement — quiz, exercices, sujets blancs.
- **Voir mes progrès** notion par notion pour savoir où concentrer mes révisions.
- **Travailler hors-ligne** quand le réseau lâche ou que je veux économiser ma data.
- **Payer avec ce que j'ai** — Mobile Money sur mon téléphone, pas carte bancaire.
- **Me sentir poussé** — voir mon rang, gagner des points, recevoir des recommandations qui ne soient pas que des constats d'échec.

Du point de vue d'un opérateur de la plateforme :

- **Maintenir l'intégrité économique** — pas de double comptage de points ou de crédits, pas de premium contourné par modification de l'app.
- **Diagnostiquer les incidents** sur des téléphones et réseaux variés — d'où le logging discipliné côté mobile et serveur.

### 2.2 Non-Users (V1)

- **Élèves du primaire** — programmes différents, pédagogie différente.
- **Étudiants du supérieur** — examens et contenu hors scope.
- **Élèves hors Cameroun** — la matrice de référence, les agrégateurs MoMo et le curriculum sont nationaux. Pas d'expansion CEMAC en V1.
- **Enseignants** — pas d'interface enseignant en V1 (pas de création de quiz, pas de suivi de classe).
- **Parents** — pas d'app parent en V1.
- **Utilisateurs hors du curriculum camerounais** — voir ci-dessus.

> **MAJ 2026-06-04 — Scope plateforme révisé** : Les utilisateurs iPhone et utilisateurs de tablette (Android et iPad) **sont désormais inclus dans la V1**, suite à décision produit. Cf. ADR-011 et `.decision-log.md` PRD. La timeline V1 glisse en conséquence à ~8-10 semaines au lieu de 6.

### 2.3 Key User Journeys

Sept journeys numérotés UJ-1 à UJ-7 portés par deux protagonistes nommées. Les FRs réfèrent à ces journeys par ID inline.

- **UJ-1. Fatou s'inscrit le soir, sur le balcon, avant de réviser.**
  Fatou Mballa, 18 ans, Terminale D à Yaoundé, vise le BAC D. Famille modeste (parents commerçants au marché Mokolo). Android Tecno Spark 8 (entrée de gamme, 32 GB stockage, 2 GB RAM). MTN MoMo. Première ouverture sur la 4G du quartier (instable le soir). Elle voit l'écran de choix de sous-système, tape **« Francophone »** — toute l'app passe en français. Elle remplit son profil en trois étapes : **filière « générale » → niveau « Terminale » → série « D »** ; les matières (Maths, PCT, SVT, Français, Anglais, LV2, Philo, Histoire-Géo, EPS) et l'examen visé (`exam_bac_francophone_d`) **s'affichent automatiquement** sans rien cocher. Elle se connecte avec son compte Google. On lui propose de lier son lycée — elle saisit « Lycée Bilingue d'Application », sélectionne dans la liste, valide. Elle voit son écran d'accueil, ses matières en haut. Total : moins de 2 minutes. **Edge case :** elle a coupé l'app pendant le remplissage du profil ; à la réouverture, elle reprend exactement où elle s'était arrêtée, profil non perdu.

- **UJ-2. James lit un cours de chimie sur le trajet en taxi-brousse.**
  James Tanyi, 17 ans, Upper Sixth S2 (Chemistry/Physics/Biology) à Buea, vise GCE A Level. Père enseignant de mathématiques, encourageant. Infinix Hot 11 (milieu de gamme, 64 GB, 4 GB RAM). Orange Money. Trajet Buea → Limbé en taxi-brousse, réseau qui passe et lâche. Il ouvre l'app, navigue **Chemistry → Organic Chemistry → Functional Groups → Alcohols and Ethers**. Le cours s'ouvre instantanément (déjà consulté la semaine dernière, donc en cache offline Firestore). Il lit le contenu, voit la formule générale `R-OH` rendue proprement, fait défiler vers le schéma de réaction d'estérification (diagramme Mermaid) qui s'affiche sans encombre. Le taxi entre dans un tunnel, le réseau coupe — la lecture continue sans interruption. À la sortie du tunnel, l'app resynchronise silencieusement. **Edge case :** s'il tape sur un exercice rattaché à la leçon, l'énoncé s'ouvre offline aussi (déjà cached) mais le bouton « Mode 1 » nécessite la connexion pour soumettre — message clair.

- **UJ-3. Fatou fait un exercice de maths en Mode 1 photo.**
  Fatou a fait l'exercice de probabilités sur son cahier. Elle ouvre l'app, retrouve l'énoncé dans **Mathématiques → Probabilités → Variables aléatoires**, tape « Mode 1 — Je maîtrise ». L'app annonce le coût : **5 crédits pour une correction photo** ; elle a 30 crédits (pack 25+5 acheté hier). Elle confirme, prend en photo son brouillon. L'app compresse l'image avant l'envoi (icône, indicateur de progression), uploade vers Firebase Storage, appelle la Cloud Function `correctMode1`. Quelques secondes plus tard, la correction arrive : **étape 1 juste**, **étape 2 incomplète** (il manquait la condition d'indépendance), **étape 3 à mieux rédiger** (calcul correct mais notation ambiguë). Chaque feedback porte un renvoi cliquable vers la portion de cours concernée. Elle tape sur « étape 2 → revoir », l'app ouvre la leçon à la bonne section. Crédits débités : 5. Solde : 25. **Edge case :** elle confirme deux fois rapidement par réflexe — un seul débit de 5 crédits est effectué (idempotence par sessionId).

- **UJ-4. James tente le Mode 2 sur un problème de stoechiométrie — paywall.**
  James veut comprendre une réaction qui le bloque depuis trois jours. Il ouvre l'exercice et tape « Mode 2 — Semi-assisté ». Comme il est compte gratuit, l'app ne charge **pas** l'exercice et affiche directement le **paywall** : « Mode 2 réservé aux abonnés premium ». L'app évite ainsi une lecture inutile (économie data). Il voit les plans : **mensuel 2 000 FCFA**, **annuel 18 000 FCFA** (« 1 500/mois — économisez 25 % »). Il choisit annuel (son père prendra le relais), tape « Payer par Orange Money », saisit son numéro. L'app ouvre la page hébergée par l'agrégateur dans une WebView. James valide avec son PIN OM sur son téléphone. La page renvoie un message « paiement en cours ». L'app **n'active rien** localement. Quelques secondes après, le webhook serveur arrive, vérifié signature, et bascule `subscriptions/{uid}.status = "active"`. Le stream Firestore que l'app écoute reçoit le nouvel état ; le paywall disparaît, le Mode 2 se charge tout seul. James entame les étapes 1 à 4, révèle 2 indices sur l'étape 3, marque l'étape 5 « non-résolue », arrive au corrigé complet. **Edge case :** à mi-parcours, sa batterie tombe à 5 % et le téléphone s'éteint ; à la recharge, il retrouve l'exercice étape 4, indices déjà révélés, marquages préservés.

- **UJ-5. Fatou consulte sa santé scolaire après son quiz.**
  Fatou a terminé son quiz hebdomadaire de SVT (note 14/20). Une notification push arrive : « Récap quiz — score 14/20, +28 points ». Elle ouvre l'app, va sur son dashboard. Sa **santé scolaire** affiche son niveau par matière : Maths `solide`, PCT `à renforcer`, SVT `solide`, Philo `priorité`. Elle descend dans SVT → Génétique → Lois de Mendel → niveau passé de 65 à 72 (étiquette `solide`). Sur le dashboard, elle voit **trois recommandations** : (1) « Révise tes points faibles en cinétique chimique » (PCT, notion priorité), (2) « Maintiens ton niveau en photosynthèse » (SVT, notion solide — c'est la règle d'équilibre 1 sur 5 qui s'applique), (3) « Termine le sujet blanc BAC D 2024 entamé hier ». Sur sa mini-carte de rang : **#3 cette semaine sur 14 dans sa classe** (+2 places vs semaine dernière). Elle tape sur la reco 1, l'app ouvre directement la leçon « Cinétique chimique » de PCT. **Edge case :** si elle marque la reco 3 « ignorer », elle disparaît du dashboard et un nouveau set s'affichera demain matin.

- **UJ-6. James pose une question au chat IA sur la radioactivité.**
  James bloque sur la décroissance radioactive. Il ouvre une leçon de physique, tape l'icône de chat épinglé à la leçon. Il pose : « Why does half-life stay constant even when the amount of substance changes? » Le chat (en anglais car compte anglophone) répond en streaming, avec une explication progressive et un diagramme Mermaid qui s'affiche dans la bulle de conversation. James insiste : « Just give me the formula and the answer for a sample problem. » Le chat **refuse poliment** et redirige : « Je peux te guider pour la démarche — qu'as-tu déjà essayé ? ». Quota visible en haut : 7/200 messages utilisés aujourd'hui (compte premium depuis hier). James reformule et avance pas à pas. **Edge case :** s'il atteint 195/200, l'app affiche un avertissement ; à 200/200, blocage avec proposition de revenir demain.

- **UJ-7. Fatou compose un sujet d'examen complet, puis le partage.**
  Fatou prend deux heures pour faire un BAC D blanc complet de PCT. Elle ouvre **Mode examen → BAC D 2024 PCT**. Écran d'avertissement : « Durée 4 h, pas de pause, pas d'aide. Continuer ? ». Elle confirme, chronomètre démarre. Elle navigue librement entre la partie A (chimie) et la partie B (physique). Au bout d'une heure, son frère l'interrompt — elle ferme l'app brusquement. Plus tard, elle revient : composition retrouvée à l'identique, chronomètre repris. Elle termine, soumet à 3 h 47. Le corrigé arrive partie par partie selon barème, score 14/20, mention « Bien ». Elle gagne 50 points + 50 bonus mention. Elle tape « Partager mon résultat » : un lien `valide.app/r/abc123` est généré, partagé sur WhatsApp à sa cousine. La cousine, qui n'a pas l'app, ouvre le lien — page d'invitation à installer puis redirection automatique vers le résultat après installation et inscription. **Edge case :** Fatou refait le même sujet une semaine plus tard — autorisé, le sujet est rejouable.

---

## 3. Glossary

> Le vocabulaire **principal** vit dans [`../../../specs/spec-valide-mvp/glossary.md`](../../../specs/spec-valide-mvp/glossary.md). Le présent glossaire complète **uniquement** avec les termes spécifiques à ce PRD.

- **Parcours canonique** — le flux bout en bout qui sert de Success signal (s'inscrire → consulter cours → quiz + Mode 1 + Mode 2 → payer MoMo/OM → voir santé + rang). Validé en fin de Phase 6.
- **Paywall** — écran qui bloque l'accès à une fonctionnalité premium et propose l'abonnement, sans charger la ressource sous-jacente (économie data + sécurité).
- **Mini-carte de rang** — widget du dashboard montrant le rang de l'élève et son évolution vs la semaine précédente sur un classement spécifique.
- **Sujet blanc** — sujet d'examen officiel des années passées, utilisé pour s'entraîner en conditions chronométrées (Mode examen).

Tout autre terme : voir le glossaire du SPEC.

---

## 4. Features

> Numérotation FR globale et stable. Les FRs référencent les UJs par ID. Les NFRs cross-cutting sont en §10 ; les NFRs spécifiques à une feature sont dans la sous-section concernée.

### 4.1 Onboarding et profil scolaire (réalise CAP-1)

**Description :** au premier lancement, l'utilisateur choisit son **sous-système** (francophone ou anglophone), ce qui **fixe définitivement** la langue de l'app et le curriculum. Il remplit ensuite son profil scolaire (filière → niveau → série) ; les matières et examens visés se déduisent automatiquement de la matrice de référence (cf. `DONNEES-REFERENCE.md`). Tant que le profil est incomplet, aucune autre fonctionnalité n'est accessible (garde de navigation centralisée). L'utilisateur peut, selon son contexte, retirer certaines matières (anglophones dès Form 3 ; toutes filières Lower/Upper Sixth). Liaison à une école optionnelle depuis un catalogue, avec demande d'ajout possible. Création de compte via Google ou Apple — un visiteur qui avait déjà rempli un profil le conserve. Suppression de compte avec délai de grâce de 7 jours, annulée par reconnexion. Mode visiteur permet la consultation préparée en Phase 2.

**Functional Requirements :**

#### FR-1 : Choix initial du sous-système

Un nouvel utilisateur peut choisir son sous-système (francophone / anglophone) au premier lancement avant tout autre écran. Réalise UJ-1.

**Consequences (testable) :**

- L'écran de choix s'affiche au premier lancement et **uniquement** au premier lancement.
- Choisir « francophone » bascule **toute l'interface, le contenu et les notifications** en français de manière permanente.
- Choisir « anglophone » bascule de la même façon en anglais.
- Aucun bouton de réglage de langue n'est accessible ailleurs dans l'app.

#### FR-2 : Remplissage du profil scolaire en étapes

Un utilisateur peut remplir son profil scolaire en trois étapes obligatoires (filière → niveau → série), et voit les matières + examens dérivés automatiquement. Réalise UJ-1.

**Consequences (testable) :**

- Les choix possibles à chaque étape ne dépendent **que** des choix précédents (la série dépend du niveau et de la filière).
- À la confirmation de la série, la liste des matières **et** la liste des examens visés s'affichent **sans cocher individuellement** ; aucun parcours d'inscription n'aboutit avec une liste vide.
- Un profil francophone Tle D montre `[Maths, PCT, SVT, Français, Anglais, LV2, Philo, Hist-Géo, EPS]` et `[exam_bac_francophone_d]`.
- Un profil anglophone Upper Sixth S2 montre `[Chemistry, Physics, Biology]` (+ optionnelles) et `[exam_gce_a_level_anglophone_s2]`.

#### FR-3 : Retrait conditionnel de matières

Un utilisateur dans les cas autorisés (anglophones ≥ Form 3, ou Lower/Upper Sixth toutes filières) peut retirer des matières de sa liste dérivée. Hors ces cas, le retrait n'est pas proposé.

**Consequences (testable) :**

- Un élève francophone en Première C **ne voit pas** l'option « retirer une matière ».
- Un élève anglophone en Form 3 voit l'option et peut retirer toute matière non présentée à son O Level.
- Une matière retirée n'apparaît plus dans la liste filtrée du contenu, ni dans les classements par matière.

#### FR-4 : Garde de navigation profil-incomplet

Un utilisateur dont le profil n'est pas complet **ne peut pas** accéder à un autre écran que ceux d'inscription/profil.

**Consequences (testable) :**

- Tenter d'ouvrir un deep link vers un cours, un exercice ou un classement avec un profil incomplet → redirige vers l'écran d'inscription en cours.
- La logique est centralisée (un seul `redirect` dans le routing), pas dispersée écran par écran.

#### FR-5 : Création de compte Google / Apple sans perte du profil visiteur

Un visiteur qui crée un compte Google ou Apple après avoir rempli un profil **conserve** son profil intégralement (zéro ressaisie).

**Consequences (testable) :**

- Visiteur → profil rempli → création compte Google → tous les champs du profil sont préservés côté serveur.
- Idem pour Apple.

#### FR-6 : Liaison école optionnelle

Un utilisateur peut lier une école depuis un catalogue, demander l'ajout d'une école absente, ou ne pas lier d'école.

**Consequences (testable) :**

- Recherche par nom dans le catalogue, avec autocomplétion sur les écoles validées (`schools/{id}.isValidated == true`).
- « Ajouter mon école » crée une demande dans `schools/{schoolId}/requests/` en attente de validation admin.
- Continuer sans école est explicitement autorisé.

#### FR-7 : Suppression de compte avec délai de grâce 7 jours

Un utilisateur peut demander la suppression de son compte ; la suppression effective intervient 7 jours plus tard sauf reconnexion entretemps.

**Consequences (testable) :**

- À la demande, `users/{uid}.deletionRequestedAt = now` est posé via Cloud Function.
- L'utilisateur reçoit un message clair annonçant les 7 jours.
- Une reconnexion dans la fenêtre annule la suppression (`deletionRequestedAt = null`).
- Un cron quotidien supprime effectivement les comptes au-delà des 7 jours.

#### FR-8 : Persistance de la session après fermeture de l'app

L'état (connecté + profil) survit à la fermeture et réouverture de l'app.

**Consequences (testable) :**

- Fermer l'app puis rouvrir → l'utilisateur reste connecté, son profil est retrouvé sans réauth.

**Feature-specific NFRs :**

- L'écran de choix de sous-système doit s'afficher en moins de 2 secondes au premier lancement, même hors-ligne (utilise des assets locaux).
- L'inscription complète (sous-système → profil → compte → école) doit pouvoir aboutir en moins de 3 minutes sur un Android entrée de gamme.

### 4.2 Navigation et lecture du contenu (réalise CAP-2)

**Description :** l'élève consulte le contenu par hiérarchie **matière → chapitre → leçon → notion**. Chaque niveau ouvre le niveau suivant. Les exercices sont rattachés à une leçon ; les questions de quiz à une notion (préparation Phase 3). Tout le contenu est filtré automatiquement selon le profil — l'élève ne filtre jamais lui-même par profil. Les cours s'affichent via le widget unique `PedagogicalContent` (cf. archi mobile § 17.7) qui rend Markdown + LaTeX + Mermaid + SVG. La lecture offline est gérée nativement par le cache Firestore. Les visiteurs voient les énoncés mais ne peuvent lancer ni mode ni composition.

**Functional Requirements :**

#### FR-9 : Navigation hiérarchique

Un utilisateur peut naviguer matière → chapitre → leçon → notion en tapant chaque niveau. Réalise UJ-2.

**Consequences (testable) :**

- Chaque niveau affiche les éléments du niveau inférieur, triés selon l'ordre pédagogique (`order` ascendant).
- Le breadcrumb ou le bouton retour mène au niveau parent.

#### FR-10 : Filtrage automatique du contenu par profil

Un utilisateur voit **uniquement** le contenu correspondant à son profil scolaire dérivé. Réalise UJ-2.

**Consequences (testable) :**

- Un élève Tle D voit seulement ses matières dérivées (Maths, PCT, SVT, etc.), pas Latin ni Géologie.
- Un élève Upper Sixth S2 voit seulement Chemistry/Physics/Biology, pas Pure Maths ni Geography.
- Aucune action utilisateur n'est requise pour appliquer le filtre.

#### FR-11 : Rendu texte enrichi, formules LaTeX, schémas Mermaid

Un cours s'affiche avec texte enrichi (titres, listes, images, tables, blocs de code), **formules LaTeX** (inline et bloc) et **schémas Mermaid**. Réalise UJ-2.

**Consequences (testable) :**

- 3 cours réels de maths/physique avec formules BAC/Probatoire s'affichent proprement (indices, exposants, fractions, intégrales, vecteurs).
- 3 cours avec schémas Mermaid (flowchart, séquence, mindmap) s'affichent proprement.
- Le rendu se fait via **un seul widget réutilisable** `PedagogicalContent` ; aucun écran feature n'importe `flutter_smooth_markdown` directement.

#### FR-12 : Filtres et recherche d'exercices

Un utilisateur peut filtrer les exercices par matière / chapitre / leçon / type / difficulté, et rechercher par mot-clé.

**Consequences (testable) :**

- Appliquer un filtre réduit la liste affichée à ceux qui matchent les critères.
- Une recherche par mot-clé renvoie des résultats pertinents (titre, énoncé).

#### FR-13 : Affichage des énoncés (exercices et sujets)

Un utilisateur peut consulter l'énoncé complet d'un exercice ou d'un sujet d'épreuve.

**Consequences (testable) :**

- L'énoncé s'affiche entièrement, avec formules et schémas si présents.
- Un visiteur voit l'énoncé mais ne peut pas lancer un Mode, ni démarrer une composition — bouton remplacé par une invitation à créer un compte.

#### FR-14 : Lecture hors-ligne automatique

Un utilisateur dont la connexion s'interrompt peut continuer à consulter le contenu déjà ouvert. Réalise UJ-2.

**Consequences (testable) :**

- Ouvrir un cours en ligne, le fermer, couper la connexion, le rouvrir → toujours lisible.
- Rallumer la connexion → resynchronisation automatique, sans action utilisateur.

#### FR-15 : Performance d'ouverture du contenu

Un contenu déjà consulté s'ouvre quasi-instantanément ; un gros contenu chargé pour la première fois affiche un état de chargement et ne fige pas l'UI.

**Consequences (testable) :**

- Rouvrir un cours déjà lu → < 500 ms perçus sur Android entrée de gamme.
- Charger un gros cours pour la première fois → indicateur visible dans les 200 ms.

**Feature-specific NFRs :**

- Le cache offline doit couvrir **tout** ce que l'élève a consulté, sans gestion manuelle de cache custom.

### 4.3 Pratique active : quiz, Mode 1, Mode 2 (réalise CAP-3)

**Description :** le cœur du produit. Phase la plus chargée du MVP (Phase 3). Les mécaniques sont construites cette semaine ; les verrous premium (Mode 2) et les débits de crédits (Mode 1) sont **branchés** en Phase 4. Le scoring est conçu réutilisable (santé scolaire + gamification en Phase 5 le consomment).

**Functional Requirements :**

#### FR-16 : Génération de quiz par IA sur notion ou chapitre

Un utilisateur peut lancer un quiz généré automatiquement par IA sur une notion ou un chapitre entier, dans plusieurs formes (QCM, vrai/faux, texte à trous, appariement). Score affiché à la fin.

**Consequences (testable) :**

- Lancer un quiz sur la notion X → produit ≥ 5 questions, mélange d'au moins 2 formes différentes.
- À la fin : score sur 100 affiché.
- Le résultat est enregistré dans un format réutilisable (score + notions concernées) pour la santé scolaire et la gamification.

#### FR-17 : Soumission Mode 1 texte ou photo avec correction IA

Un utilisateur peut soumettre sa réponse en **texte** ou en **photo** d'un brouillon papier, et recevoir une correction IA distinguant juste / faux / incomplet / à mieux rédiger. Réalise UJ-3.

**Consequences (testable) :**

- Soumettre une réponse texte → reçoit une correction avec les 4 catégories d'étiquettes.
- Soumettre une photo : l'image est **compressée côté client** (WebP) avant upload Storage.
- La correction comporte des renvois cliquables vers les portions de cours pertinentes.
- L'appel à l'IA passe par la Cloud Function `correctMode1` — la clé Claude n'est jamais dans l'app.

**Out of Scope :**

- Annotation graphique sur la photo (pas en V1).

#### FR-18 : Mode 2 — étapes ordonnées, indices max 3, cours associé

Un utilisateur premium peut faire un exercice en Mode 2 où l'exercice est découpé en étapes ordonnées avec mini-énoncé, jusqu'à 3 indices progressifs, portion de cours associée, et marquage résolu / non-résolu. À la fin, corrigé complet. Réalise UJ-4.

**Consequences (testable) :**

- Le 4ᵉ tap sur « Indice » d'une étape ne révèle rien (max 3 strict).
- Marquer une étape résolue puis quitter l'écran et revenir pendant la même session : le marquage est conservé.
- À la fin, le corrigé complet s'affiche.
- Un compte gratuit qui tape sur le bouton Mode 2 ne charge **pas** l'exercice (économie data) et voit le paywall.

#### FR-19 : Gestion de l'échec réseau côté Mode 1 et Mode 2

Un utilisateur dont la connexion lâche pendant un Mode 1 ou un upload de photo voit un message clair et peut réessayer sans plantage.

**Consequences (testable) :**

- Couper la connexion pendant l'envoi → l'app affiche un message non technique, pas une exception brute.
- Bouton « Réessayer » disponible. Le retry n'engendre pas de double débit (idempotence par sessionId).

**Feature-specific NFRs :**

- La photo Mode 1 doit être compressée à < 200 KB en moyenne avant upload.
- Le temps moyen entre soumission et correction IA reçue doit être < 15 secondes sur 4G.

### 4.4 Monétisation freemium par Mobile Money (réalise CAP-4)

**Description :** plans gratuit et premium, mensuel ou annuel, avec achat de packs de crédits. Paiement via **MTN MoMo** ou **Orange Money** par l'agrégateur tiers (à choisir parmi Tranzak / Campay / MyCoolPay). La confirmation passe **exclusivement** par le webhook serveur vérifié signature ; l'app n'active jamais le premium localement. Les verrous d'accès aux features premium sont **réels côté serveur** (règles Firestore) ; le check Flutter est uniquement une optimisation UX. L'idempotence est garantie par `sessionId` côté client et garde dans la transaction Firestore côté serveur.

**Functional Requirements :**

#### FR-20 : Affichage des plans avec comparaison gratuit / premium

Un utilisateur peut voir les plans gratuit et premium avec la différence clairement explicitée, et choisir mensuel ou annuel (annuel affiché comme moins cher au mois). Réalise UJ-4.

**Consequences (testable) :**

- L'écran affiche côte à côte les features gratuit vs premium.
- L'annuel est libellé « X FCFA / mois — économisez Y % » (et non un prix total seul).

#### FR-21 : Paiement Mobile Money via agrégateur

Un utilisateur peut souscrire premium ou acheter un pack de crédits en payant par **MTN MoMo** ou **Orange Money** via une WebView agrégateur. Réalise UJ-4.

**Consequences (testable) :**

- Choisir un plan → l'app demande au serveur de créer une intention de paiement (`createSubscription` ou `purchaseCredits`).
- L'app ouvre l'URL retournée dans une WebView.
- L'utilisateur valide par **PIN MoMo ou OM** sur son téléphone.

#### FR-22 : Déblocage automatique après confirmation serveur

Le premium se débloque **automatiquement** après confirmation par webhook serveur, sans aucun bouton « activer ». Réalise UJ-4.

**Consequences (testable) :**

- Après validation PIN, l'app **n'active rien** localement.
- Le webhook arrive côté Cloud Function, signature vérifiée → `subscriptions/{uid}.status = "active"`.
- Le stream Firestore que l'app écoute reçoit le nouvel état ; le paywall disparaît, la feature se débloque automatiquement.

#### FR-23 : Verrous premium réels côté serveur

Un compte gratuit ne peut pas créer de session Mode 2 (ou mode examen, fiches, chat premium) **même si l'app est modifiée**. Réalise UJ-4.

**Consequences (testable) :**

- Tentative manuelle de créer un doc `users/{uid}/sessions/{X}` avec `type: "mode2"` par un compte non premium → rejetée par les **règles Firestore**.
- Le check Flutter local est aligné mais n'est qu'une optimisation UX.

#### FR-24 : Achat de packs de crédits avec bonus

Un utilisateur peut acheter des packs de crédits : Pack 10 (10 crédits), Pack 25 (25 + 5 bonus = 30), Pack 60 (60 + 20 bonus = 80). Réalise UJ-3 (Fatou utilise un pack 25 acheté hier).

**Consequences (testable) :**

- Acheter le pack 25 → solde augmente de exactement 30.

#### FR-25 : Affichage permanent du solde et du coût avant action

Le solde de crédits est affiché en permanence ; le coût d'une action payante est affiché **avant** confirmation.

**Consequences (testable) :**

- Le solde est visible sur le dashboard et sur les écrans d'action payante.
- Tapant « Mode 1 » sur un exercice → un dialogue affiche « Coût : 5 crédits » avant la confirmation finale.

#### FR-26 : Idempotence stricte du débit et du crédit

Un utilisateur qui appuie deux fois rapidement sur « confirmer » ou qui subit un retry réseau ne se voit débiter qu'**une seule fois**. Un même webhook reçu deux fois ne crédite qu'**une seule fois**. Réalise UJ-3.

**Consequences (testable) :**

- Double-tap rapide sur Mode 1 → 5 crédits débités, pas 10.
- Couper le réseau pendant la soumission, retry → 5 crédits débités, pas 10.
- Un agrégateur qui rejoue son webhook → le pack 25 crédite 30 une seule fois.

#### FR-27 : Historique des transactions et journal des crédits

Un utilisateur peut consulter l'historique de ses achats et l'historique détaillé de ses dépenses en crédits.

**Consequences (testable) :**

- L'écran historique liste chaque transaction (date, type, montant, motif).
- Filtre par type (achat / débit / bonus / remboursement) possible.

#### FR-28 : Annulation d'abonnement avec maintien jusqu'à fin de période

Un utilisateur peut annuler son abonnement ; il reste actif jusqu'à la fin de la période payée, puis bascule gratuit.

**Consequences (testable) :**

- Annuler → `subscriptions/{uid}.cancelledAt = now`, mais `status` reste `active` jusqu'à `expiresAt`.
- À `expiresAt`, le cron quotidien bascule `status = "expired"`.

**Feature-specific NFRs :**

- Le délai moyen entre validation PIN et déblocage côté app doit être < 30 secondes en conditions normales.

### 4.5 Santé scolaire, gamification, notifications (réalise CAP-5)

**Description :** s'alimente des résultats produits en §4.3. Trois sous-modules cohérents : **santé scolaire par notion**, **gamification (points + 5 classements)**, **notifications**.

**Functional Requirements :**

#### FR-29 : Évolution de la santé scolaire notion par notion

Un utilisateur voit son niveau évoluer par notion à chaque quiz, exercice ou sujet d'examen terminé. Réalise UJ-5.

**Consequences (testable) :**

- Terminer un quiz → les notions évaluées voient leur niveau bouger (montée si réussi, baisse si raté).
- Le niveau est visible à 4 niveaux de profondeur : matière → chapitre → leçon → notion.
- Étiquette automatique selon le niveau : `solide` (≥ 70), `à renforcer` (40-69), `priorité` (< 40). Seuils à valider en Phase 5.

#### FR-30 : Mise à jour atomique santé + niveau + points

Les mises à jour de santé scolaire, niveau et points s'appliquent en **une seule transaction Firestore atomique** côté serveur ; jamais d'état partiel.

**Consequences (testable) :**

- Couper le réseau pendant la soumission au moment de l'alimentation → soit toutes les écritures sont visibles à la resync, soit aucune (pas de points crédités sans mise à jour santé).

#### FR-31 : Recommandations équilibrées sur le dashboard

Un utilisateur voit jusqu'à **3 recommandations** sur son dashboard. Au moins **1 sur 5 vise une notion déjà solide** (règle d'équilibre). Réalise UJ-5.

**Consequences (testable) :**

- Tirer 5 batches successifs de recommandations → au moins 1 batch contient une reco sur une notion `solide`.
- Marquer une reco « faite » ou « ignorer » → elle disparaît du dashboard.
- Taper sur une reco → ouvre directement la ressource cible (leçon ou exercice).

#### FR-32 : Attribution de points sans double comptage

Un utilisateur gagne des points à chaque action utile, mais une action ne crédite des points **qu'une seule fois**. Réalise UJ-5, UJ-7.

**Consequences (testable) :**

- Terminer un quiz (score 70/100) → +35 points (selon barème à confirmer).
- Refaire le même quiz terminé → pas de nouveaux points.
- Sujet d'examen avec mention « Bien » → +50 points + 50 bonus mention.
- 2 appuis rapides sur « soumettre » → points crédités une seule fois.

#### FR-33 : Cinq classements (général, hebdo, matière, classe, école)

Un utilisateur voit 5 classements : général (permanent), hebdomadaire (reset lundi 00:00 heure Cameroun), par matière, ma classe (si école renseignée), mon école.

**Consequences (testable) :**

- Le classement hebdo se remet à zéro chaque lundi à 00:00 UTC+1.
- Un élève sans école renseignée est exclu des classements « ma classe » et « mon école » (ou voit un état vide avec invitation à renseigner — cf. Open Question).
- Un visiteur peut consulter les classements en lecture seule sans y figurer.

#### FR-34 : Mini-carte de rang sur le dashboard

Un utilisateur voit sur son dashboard une mini-carte de rang sur le classement de sa classe (ou général à défaut) avec l'évolution vs la semaine précédente. Réalise UJ-5.

**Consequences (testable) :**

- La mini-carte affiche rang actuel + flèche d'évolution (↑↓→) + delta de rang.

#### FR-35 : Notifications push + in-app pour chaque événement

Chaque événement utilisateur déclenche **à la fois** une notification push (écran de verrouillage) et une notification in-app (icône cloche). Plafonds par type.

**Consequences (testable) :**

- Terminer un quiz → 1 notif récap (en push + dans l'app).
- Plafond inactivity : 1 seul rappel par période d'absence, pas un par jour.
- Plafond low_credits : 1 par seuil franchi (10, 5, 0), pas un par débit.
- Taper sur une notification → ouvre l'écran cible (deep link interne).

#### FR-36 : « Tout marquer comme lu »

Un utilisateur peut marquer toutes ses notifications in-app comme lues en un geste.

**Consequences (testable) :**

- Bouton disponible sur l'écran notifications ; toutes les notifs passent en `isRead: true`.

### 4.6 Mode 3, mode examen, chat IA, partage (réalise CAP-6)

**Description :** Phase 6, sert aussi de tampon pour rattraper le retard. **Mode 3** = tuteur IA pas à pas (1 débit de crédits par session, pas par message). **Mode examen** = composition complète chronométrée avec sauvegarde continue. **Chat IA** pédagogique qui **ne donne pas les solutions**. **Partage** de liens deep-link vers ressources.

**Functional Requirements :**

#### FR-37 : Mode 3 — tuteur IA pas à pas, 1 débit par session

Un utilisateur peut lancer une session Mode 3 où un tuteur IA accompagne pas à pas. Les crédits sont débités **une seule fois par session**, quel que soit le nombre de messages.

**Consequences (testable) :**

- Lancer une session Mode 3 → 10 crédits débités (montant à figer).
- Échanger 20 messages dans la session → toujours 10 crédits débités au total.
- Sortir et rentrer dans la même session → pas de nouveau débit.

#### FR-38 : Mode examen — composition complète chronométrée

Un utilisateur premium peut composer un sujet d'examen complet en conditions officielles (durée officielle, pas de pause, pas d'aide). Réalise UJ-7.

**Consequences (testable) :**

- L'écran d'avertissement précède le démarrage : « Durée X h, pas de pause, pas d'aide. Continuer ? ».
- Le chronomètre démarre à la confirmation.
- Navigation libre entre les parties du sujet.
- Soumission manuelle possible avant la fin ; à expiration, soumission automatique.

#### FR-39 : Sauvegarde continue du mode examen

L'état du mode examen (réponses, partie en cours, chrono) est sauvegardé en continu ; aucune donnée n'est perdue si l'utilisateur quitte l'app, perd la connexion, ou que la batterie tombe. Réalise UJ-7.

**Consequences (testable) :**

- Fermer l'app pendant la composition puis rouvrir → composition retrouvée à l'identique, chronomètre repris.
- Couper la connexion pendant la composition → poursuite locale + resync au retour.

#### FR-40 : Corrigé partie par partie, score, mention, réessai illimité

Après soumission d'un mode examen, l'utilisateur reçoit un corrigé partie par partie selon barème, un score total et une mention. Il peut refaire le même sujet autant de fois qu'il le souhaite. Réalise UJ-7.

**Consequences (testable) :**

- Le corrigé liste chaque partie avec points obtenus / barème.
- La mention dérive d'une grille (à valider — cf. Open Question sur le barème).
- Refaire le même sujet est autorisé.

#### FR-41 : Chat IA pédagogique avec posture d'accompagnement

Un utilisateur peut discuter avec une IA pédagogique en mode libre ou contextuel (depuis un cours, une notion, un exercice). L'IA **ne donne pas la solution directe** d'un exercice ; elle redirige vers une démarche d'apprentissage. Réalise UJ-6.

**Consequences (testable) :**

- Demander « Donne-moi la réponse à cet exercice » → l'IA refuse poliment et oriente vers une démarche.
- Pour les sujets qui appellent un schéma, l'IA peut générer un diagramme Mermaid affiché dans la conversation.
- Conversation reprenable depuis l'historique.

#### FR-42 : Quota chat visible et appliqué

Un utilisateur voit le quota journalier de messages chat (10 gratuit, 200 premium) et est bloqué une fois atteint. Réalise UJ-6.

**Consequences (testable) :**

- Quota visible en haut de l'écran chat.
- Atteindre le quota → bloque l'envoi avec message explicatif.
- Le quota se réinitialise à minuit UTC+1.

#### FR-43 : Création et partage de liens deep-link

Un utilisateur peut créer un lien partageable sur un exercice, un sujet, une fiche ou un résultat, et le partager (WhatsApp, SMS, email, copie). Réalise UJ-7.

**Consequences (testable) :**

- Le lien est de la forme `valide.app/r/{linkId}`.
- Ouvrir le lien avec l'app installée → directement la ressource.
- Ouvrir le lien sans l'app → page d'invitation à installer, puis redirection automatique vers la ressource après installation et inscription.

#### FR-44 : Liste des liens partagés et désactivation

Un utilisateur peut consulter la liste de ses liens partagés avec le nombre d'ouvertures par lien, et désactiver un lien.

**Consequences (testable) :**

- Liste affiche : ressource cible, date de création, nombre d'ouvertures, statut actif/désactivé.
- Désactiver un lien → ouvertures ultérieures rejetées.

**Feature-specific NFRs :**

- Le chat doit afficher la réponse de l'IA en streaming (premier caractère < 2 s, complet < 15 s en moyenne).
- Le mode examen ne doit pas perdre plus de 5 secondes de réponses en cas de coupure brutale (sauvegarde au moins toutes les 5 s).

---

## 5. Non-Goals (Explicit)

> Les 11 non-goals du SPEC sont **toutes maintenues** et tiennent ici également :

- Pas de génération de cours par IA — contenu rédigé humain.
- Pas de classe virtuelle synchrone — pas de cours en direct, visio, tableau blanc.
- Pas de réseau social entre élèves — pas de DM, fil d'actualité, profils publics.
- Pas de réglages de notifications personnalisés en V1.
- Pas d'expansion CEMAC immédiate.
- Pas de réglage manuel de langue — dérive du sous-système.
- Pas de gestion d'écoles ni de classes par enseignants côté mobile.
- Pas de cache custom maison — uniquement cache Firestore natif.
- Pas de tests E2E exhaustifs en V1 — parcours critiques seulement.
- ~~Pas de support iPad ni tablette spécifique en V1.~~ → **Tablette (Android et iPad) incluse en V1** (MAJ 2026-06-04, cf. ADR-011).
- Pas de marketplace de contenu tiers.

Et spécifiquement pour ce PRD :

- **Pas d'authentification par numéro de téléphone OTP en V1** — Google + Apple suffisent au démarrage (à reconsidérer en V2 si la couverture Google est insuffisante).
- **Pas de différenciation tarifaire par région** — un seul prix mensuel et un seul annuel pour tout le Cameroun en V1.
- **Pas de réduction étudiant ou bourse intégrée** — sera traité en V2.

---

## 6. MVP Scope

### 6.1 In Scope

- FR-1 à FR-44 (l'intégralité des features décrites en §4).
- **Cross-platform Android (phone & tablet) + iOS (iPhone & iPad)** — distribution Play Store (AAB) + App Store (IPA via TestFlight puis prod) (MAJ 2026-06-04, ADR-011).
- **Responsive natif** Flutter : 3 form factors cibles (phone < 600 dp, phone landscape 600-840 dp, tablet ≥ 840 dp).
- Bilingue FR + EN intégral (interface, contenu, notifications).
- Paiement MoMo + Orange Money via 1 agrégateur (à choisir parmi Tranzak / Campay / MyCoolPay).
- Au moins **1 matière pleinement populée** par sous-système au moment du lancement, pour démontrer le parcours canonique (cf. Assumption A2).
- Couverture curricula : francophone général séries **A, C, D** ; francophone technique séries **F1-F4, G1-G3** ; anglophone **toutes séries S1-S8 et A1-A5** (sous réserve Open Question OQ-1).

### 6.2 Out of Scope for MVP

- ~~**iOS** — reporté V2.~~ → **iOS inclus en V1** (MAJ 2026-06-04, ADR-011). La part de marché iPhone au Cameroun reste minoritaire (~8 %) mais la décision produit donne la priorité à la couverture plateforme (parité fonctionnelle Android/iOS) plutôt qu'au ROI court terme.
- **Série E francophone** — reportée V2 selon prévalence (cf. OQ-2).
- **Filières techniques étendues** (F5, ESF, IH, MVT, MAVA, MEM, etc.) — reportées V2 (cf. OQ-1).
- **Expansion CEMAC** (Gabon, Congo, RDC, Tchad, RCA) — V3 minimum.
- **Authentification par téléphone (OTP SMS)** — V2 si la couverture Google est insuffisante.
- **Application enseignant** — V3.
- **Application parent** — V3.
- **Marketplace de contenu tiers** — V3 minimum.
- **`[NOTE FOR PM]`** : si le retard P6 force la coupe selon l'ordre prévu (partage → Mode 3 → chat → 3 classements/5), le partage et le Mode 3 sont les plus susceptibles d'être déplacés en V1.1. À surveiller à mi-Phase 6.

---

## 7. Success Metrics

> Les métriques de **lancement** (acquisition, rétention, conversion) sont en aval du MVP — un sujet V2. Le MVP a des métriques de **validation** : « le produit fait ce qu'il prétend faire, sur de vrais devices, avec de vrais utilisateurs ».

**Primary**

- **SM-1 — Parcours canonique réussi.** Deux utilisateurs réels (Fatou Mballa profil — Tle D francophone, Yaoundé ; James Tanyi profil — Upper Sixth S2 anglophone, Buea), sur deux Android d'entrée et milieu de gamme, complètent **le parcours canonique** (inscription → cours avec formules → quiz + Mode 1 + Mode 2 → paiement MoMo ou OM → santé + rang) **sans plantage, sans perte de données, sans double comptage**, en connexion 3G fluctuante, en moins de **45 minutes** au total. Validates FR-1 à FR-44.
- **SM-2 — Latence de déblocage premium après paiement.** Le délai médian entre validation PIN MoMo/OM et activation du premium côté app est < **30 secondes** sur 4G stable. Validates FR-22.
- **SM-3 — Idempotence en conditions réelles.** Sur 50 soumissions Mode 1 simulant des retries réseau (10 % de coupures aléatoires), 0 cas de double débit de crédits ou de double comptage de points. Validates FR-26, FR-32.

**Secondary**

- **SM-4 — Temps d'inscription.** Le temps médian d'inscription complète (sous-système → profil → compte Google → liaison école optionnelle) est < **3 minutes** sur Android entrée de gamme avec 3G. Validates FR-1 à FR-6.
- **SM-5 — Cache offline.** Sur 10 cours déjà consultés, 10/10 restent ouvrables hors-ligne sans intervention manuelle. Validates FR-14.

**Counter-metrics (do not optimize)**

- **SM-C1 — Temps passé dans l'app par session.** **Ne pas optimiser** — Valide est un outil d'apprentissage, pas un produit d'attention. Un élève qui passe 30 minutes ciblées dans l'app puis ferme pour étudier sur son cahier est un succès, pas un échec. Contrebalance toute tentation d'instrumentaliser SM-1 vers du « temps passé ».
- **SM-C2 — Revenue Per User (ARPU).** **Ne pas optimiser** sur le MVP. Pousser le ARPU au détriment du free flow casserait l'accessibilité aux familles modestes — qui est le cœur du marché cible. Contrebalance toute tentation de durcir les crédits ou de réduire le quota gratuit pour booster la conversion premium.
- **SM-C3 — Nombre de notifications push envoyées par jour.** **Ne pas optimiser** au-delà des plafonds prévus (FR-35). Augmenter la fréquence pour stimuler le DAU est l'anti-pattern classique des apps EdTech occidentales et casse la confiance.

---

## 8. Open Questions

Numérotées OQ-1 à OQ-10. Les OQ-1 à OQ-7 viennent du SPEC ; les OQ-8 à OQ-10 sont apparues à la rédaction de ce PRD.

1. **OQ-1 — Périmètre des séries techniques en V1.** F1-F4 + G1-G3 suffisent-elles ? Inclure ESF, IH, MVT dès la V1 ou attendre V2 ? *Bloque la fin de la matrice DONNEES-REFERENCE.md.*
2. **OQ-2 — Série E francophone.** Présente dans certains lycées, pas dans tous. V1 ou V2 ? *Mineur si on documente clairement.*
3. ~~**OQ-3 — Stratégie iOS post-V1.** Quel seuil d'utilisateurs déclenche le port iOS ?~~ → **RÉSOLU (2026-06-04)** : iOS est inclus dès la V1 par décision produit, pas par signal. Cf. ADR-011.
4. **OQ-4 — Volume initial de contenu pédagogique pour le test « parcours canonique ».** Combien de leçons, exercices, sujets minimum par sous-système ? *À spécifier avec l'équipe pédagogique.*
5. **OQ-5 — Mention vs note sur 20 vs barème officiel.** BAC/Probatoire/GCE utilisent-ils la même échelle ? Afficher selon sous-système ou normaliser ?
6. **OQ-6 — Comportement pour élève sans école renseignée.** Invitation à renseigner sur le dashboard ou silencieux ? *Affecte FR-33, FR-34.*
7. **OQ-7 — Plafond chat premium 200/jour.** Strict (refus net) ou gradient (warning 180, blocage 200) ?
8. **OQ-8 — Délai de grâce subscription.** Combien de jours de grace après échec de renouvellement avant `expired` ? Proposition 7 jours, à valider.
9. **OQ-9 — Modèle de notation Mode 1 (pondérations correct / incomplet / rephrasing / incorrect).** À calibrer avec un panel d'enseignants en Phase 3.
10. **OQ-10 — Choix de l'agrégateur Mobile Money.** Tranzak vs Campay vs MyCoolPay : qui propose les meilleures conditions (frais, support, webhook signé exploitable) ? *Décision bloquante pour P4 — à lancer dès J1.*

---

## 9. Assumptions Index

Numérotées AS-1 à AS-7. Les AS-1 à AS-5 viennent du SPEC ; AS-6 et AS-7 sont apparues à la rédaction de ce PRD.

- **AS-1** — L'agrégateur Mobile Money choisi expose un webhook signé exploitable côté Cloud Function. *Validation requise avant P4.*
- **AS-2** — Le catalogue de contenu pédagogique sera produit en parallèle par l'équipe pédagogique avec un volume suffisant pour démontrer le parcours canonique au moment du lancement.
- **AS-3** — La région Firebase `europe-west1` offre une latence acceptable depuis le Cameroun. *À mesurer en P1.*
- **AS-4** — L'équipe pédagogique francophone et anglophone valide la matrice profil → matières → examens dans `DONNEES-REFERENCE.md` au plus tard fin de P1.
- **AS-5** — Les 6 agents BMAD v6.8.0 (Mary, John, Winston, Amelia, Sally, Paige) suffisent pour piloter le projet ; pas d'agent custom additionnel nécessaire. *Confirmée par l'installation BMAD du 2026-06-03.*
- **AS-6** — Google Sign-In et Apple Sign-In couvrent suffisamment la population cible. Si la couverture Google est insuffisante (élèves sans compte Google), une auth par téléphone OTP devra être ajoutée en V2.
- **AS-7** — Les seuils d'étiquetage de santé scolaire (`solide` ≥ 70, `à renforcer` 40-69, `priorité` < 40) sont pédagogiquement pertinents. *À valider en Phase 5 avec un enseignant.*

---

## 10. Cross-Cutting NFRs

Ces NFRs s'appliquent à toutes les features de §4. Elles dérivent **directement** des Constraints du SPEC mais sont exprimées ici comme exigences testables.

- **NFR-1 — Taille de l'app installée < 30 MB par device sur Android** (App Bundle + split per ABI) et **< 50 MB sur iOS** (l'IPA inclut tous les bitcodes, pas de split natif). Vérifier sur builds release.
- **NFR-2 — Démarrage de l'app < 3 secondes** sur Android Go-class (entrée de gamme) **et < 2 secondes sur iPhone milieu de gamme (iPhone SE 2020+) et iPad mini**.
- **NFR-3 — Modules Firebase chargés au plus près de leur usage**, pas au démarrage. `flutter_smooth_markdown` en lazy-load uniquement sur les écrans qui l'utilisent.
- **NFR-4 — Compression des photos Mode 1 avant upload.** Cible : < 200 KB en moyenne, format WebP.
- **NFR-5 — Pas de cache custom maison.** Uniquement le cache offline natif de Firestore. Aucun import de Hive, drift, isar, etc.
- **NFR-6 — Toute opération réseau, décision d'accès, paiement et appel IA produit un log via `AppLogger`.** Aucune donnée sensible loggée (PIN, jeton, n° de téléphone complet, mot de passe).
- **NFR-7 — Aucune exception ne remonte à l'écran utilisateur.** Tout passe par `Either<Failure, T>` (`fpdart`). Les erreurs s'affichent comme messages clairs en français ou en anglais selon le sous-système.
- **NFR-8 — Idempotence garantie côté serveur pour toute action rejouable.** Clé `sessionId` vérifiée dans la même transaction Firestore que les écritures de données.
- **NFR-9 — Vrai verrou d'accès aux features premium dans les règles Firestore.** Le check Flutter local est une optimisation UX, pas un verrou.
- **NFR-10 — App Check actif sur toutes les Cloud Functions sensibles** (`enforceAppCheck: true`).
- **NFR-11 — Webhook agrégateur vérifié signature avant toute action.**
- **NFR-12 — Aucun secret dans l'app mobile.** La clé Claude API et les secrets de signature webhook vivent **uniquement** côté backend (Secret Manager).
- **NFR-13 — Cohérence des écritures liées garantie par transaction atomique unique côté serveur** (santé + niveau + points + marque d'idempotence dans le même `runTransaction`).
- **NFR-14 — Application bilingue intégrale.** Tout texte affiché à l'élève doit être disponible dans les deux langues ; pas de chaîne en dur dans le code.
- **NFR-15 — Couverture des contraintes connectivité.** Toute action réseau doit avoir un retry avec backoff exponentiel (Dio), un message d'erreur clair en cas d'échec, et un état restituable si l'utilisateur revient plus tard.
- **NFR-16 — Cross-platform Android + iOS.** L'app doit fonctionner sur Android 8.0+ (API 26) ET iOS 13.0+. Parité fonctionnelle stricte sur les deux plateformes. Pas de feature Android-only sans équivalent iOS (et inversement). Code plateforme-spécifique confiné à `core/platform/*` derrière des wrappers.
- **NFR-17 — Responsive 3 form factors.** Chaque écran utilisateur doit être conçu et testé sur 3 layouts : phone portrait (< 600 dp), phone landscape ou small tablet (600-840 dp), tablet (≥ 840 dp). Le breakpoint phone-landscape peut être assimilé à phone-portrait en V1 si la story le justifie, mais tablet est obligatoire. Pas de pixel hardcodé pour la composition de layout : `LayoutBuilder` ou `MediaQuery.sizeOf(context).width`.
- **NFR-18 — Assets audio cross-platform.** Tous les fichiers audio embarqués sont en **AAC/M4A** (supportés nativement Android et iOS). Pas de OGG (iOS ne le supporte pas nativement).

---

## 11. Aesthetic and Tone

> Référence visuelle complète : [`doc/tech/Valide - Design System.html`](../../../doc/tech/Valide%20-%20Design%20System.html). Référence comportementale : la skill `bmad-ux` produira `DESIGN.md` + `EXPERIENCE.md` en aval, alimentée par les HTML existants.

- **Palette** : bleu primaire `#2563EB` (encre `#0F172A`, palette d'états vert / ambre / rouge / ciel). Cohérent avec une identité « éducative, fiable, lisible ».
- **Typographie** : Nunito Sans (sans-serif chaude, lisible sur petits écrans), JetBrains Mono pour le code ; échelles définies dans le Design System.
- **Voix de l'app** : amical mais pas familier, encourageant sans être condescendant, factuel sur les résultats. Pas d'émoji intempestif (gardé pour les notifications de réussite). En français : tutoiement par défaut (élève) ; en anglais : ton équivalent informel direct.
- **Ton des messages d'erreur** : clair, factuel, jamais technique. « Pas de connexion internet » plutôt que « Network error 503 ». Toujours proposer une action (« réessayer », « revenir plus tard »).
- **Posture de l'IA** : pédagogique, jamais autoritaire. Pas de réponse directe sur les exercices ; oriente vers la démarche.

---

## 12. Information Architecture

Top-level surfaces de l'app (mobile). Détail wireframes dans les maquettes existantes (`Valide - Design.html`) et dans le futur `EXPERIENCE.md`.

- **Onboarding** (premier lancement uniquement) : choix sous-système → profil scolaire → objectif → démo IA → création compte.
- **Accueil (Home)** : carte de bienvenue, mini-carte de rang, 3 recommandations, raccourci vers les modes en cours.
- **Matières** : liste des matières dérivées du profil → chapitres → leçons → notions.
- **Quiz** : entry point pour générer un quiz ; lister les quiz récents.
- **Examens** : sujets blancs par profil, mode examen, historique de compositions.
- **Santé scolaire** : niveau par matière → drill down par chapitre → leçon → notion.
- **Classements** : navigation entre les 5 boards.
- **Chat** : conversations en cours, historique, quota.
- **Profil** : informations perso (nom, photo, école), abonnement + crédits, paramètres minimaux, notifications, déconnexion, suppression.
- **Notifications** (icône cloche persistante) : liste chronologique, marquer comme lu.

---

## 13. Monetization

Modèle **freemium** :

- **Plan gratuit** : consultation contenu, quiz illimités, Mode 1 (avec crédits achetables), chat IA 10 messages/jour, accès classements en lecture.
- **Plan premium** : tout le gratuit + Mode 2 + Mode examen + fiches + chat IA 200/jour + quota mensuel de crédits inclus (à figer).
- **Pricing** : mensuel et annuel (annuel ~25 % moins cher au mois). Prix exacts à figer après une étude de prix locale rapide en P1 — proposition de départ : **2 000 FCFA/mois**, **18 000 FCFA/an**.
- **Crédits** : packs 10, 25 (+5 bonus), 60 (+20 bonus). Prix proposés : **500 / 1 000 / 2 500 FCFA**.
- **Paiement** : MTN MoMo + Orange Money uniquement, via agrégateur. Pas de carte en V1.

---

## 14. Platform

> **MAJ 2026-06-04 — section refondue suite à ADR-011 (scope cross-platform).**

### 14.1 Cibles V1

- **Android phone & tablet.** Min API 26 (Android 8.0), target API 34 (Android 14+). Tests primaires sur Android Go-class (Tecno Spark, Infinix Hot) + un device tablette Android (Lenovo Tab M10 ou équivalent). Distribution **Play Store** (AAB) avec split per ABI.
- **iOS iPhone & iPad.** Min iOS 13.0 (couvre 95 %+ du parc iPhone), target iOS 17+. Tests primaires sur iPhone SE 2020 (petite cible perf) + iPhone 14 (cible standard) + iPad mini (cible tablette). Distribution **App Store** via TestFlight d'abord, puis prod.
- **Responsive 3 form factors** (cf. NFR-17) : phone portrait (< 600 dp), phone landscape ou small tablet (600-840 dp), tablet (≥ 840 dp).
- **Pas de Web.** L'app est nativement mobile ; la version web Flutter n'est pas dans le scope MVP (pourrait être considérée pour la console admin, mais c'est un autre dépôt).

### 14.2 Conventions cross-platform

- **Design Material** sur les deux plateformes (cohérence de marque) avec adaptations comportement iOS quand pertinent (swipe-back navigation via `CupertinoPageRoute` autorisé).
- **Pas de feature Android-only** sans équivalent ou no-op gracieux iOS.
- **Détection mode silencieux** : disponible sur Android, **pas d'API publique iOS** → fallback obligatoire sur setting Profil utilisateur (cf. EXPERIENCE.md § Multisensoriel).
- **Haptic** : `HapticFeedback.*` Flutter (Taptic Engine côté iOS, vibrator côté Android — mapping documenté en DESIGN.md § Haptics).
- **Audio** : OGG **interdit** (iOS) → AAC/M4A obligatoire (cf. NFR-18).
- **Packages plateforme-spécifiques** (ex. `soundpool` Android-only) interdits sans wrapper cross-platform.

### 14.3 Impact timeline

L'inclusion d'iOS et de la tablette dès la V1 augmente l'effort Foundation (P0) d'environ **30-50 %** (setup Firebase iOS, signing, App Store, CI macOS, responsive widgets) et **20-30 %** sur les phases E1-E6 (chaque écran porte 2-3 breakpoints). Timeline V1 **ajustée à ~8-10 semaines** au lieu de 6.

---

## 15. Constraints and Guardrails

### 15.1 Safety

- **Modération du chat IA** : l'IA ne donne pas de réponses inappropriées (anti-tricherie sur les exercices, mais aussi pas de contenu sensible ou dangereux). Posture pédagogique encadrée par prompt système côté serveur.
- **Pas de signalement / pas de blocage entre élèves** en V1 car il n'y a pas d'interaction entre élèves au-delà des classements.

### 15.2 Privacy

- **Mineurs** : la cible (élèves du secondaire) inclut une part importante de mineurs. La collecte de données est **minimale** : nom affiché, photo (optionnelle), email (via Google/Apple), profil scolaire. **Pas de géolocalisation**, **pas de carnet d'adresses**, **pas de microphone**.
- **Conservation** : les données sont conservées tant que le compte est actif. Suppression de compte avec délai de grâce 7 jours (FR-7).
- **Export RGPD** : Cloud Function admin dédiée (cf. ALGORITHMES.md § 11).
- **Pas de partage avec des tiers** au-delà de Firebase (Google) et de l'agrégateur (uniquement les champs nécessaires à la transaction).

### 15.3 Cost

- **Coût IA** : chaque appel à Claude est facturé. Protection : App Check + crédits utilisateur + quota chat + limite tokens par requête.
- **Coût Firestore** : facturation à la lecture de document. Protection : cache offline, pas de relecture en boucle, modèles statiques (cours) versionnés peu fréquemment.
- **Coût Storage** : photos Mode 1 compressées en WebP avant upload.

---

## 16. Why Now

Trois forces convergent en 2026 qui rendent ce produit livrable et nécessaire maintenant :

1. **Pénétration smartphone croissante** : ~40 % des élèves du secondaire ont accès à un smartphone (souvent partagé en famille), contre ~25 % en 2022. Le segment milieu de gamme (Tecno, Infinix, Itel, Samsung Galaxy A) est devenu accessible (~50 000 — 100 000 FCFA).
2. **Mobile Money mature** : MTN MoMo et Orange Money sont les méthodes de paiement dominantes des jeunes adultes. Les agrégateurs (Tranzak, Campay, MyCoolPay) ont stabilisé leurs APIs et webhooks signés depuis 2024-2025.
3. **Stack IA accessible** : la disponibilité de Claude (Anthropic) avec des modèles 4.x qui gèrent natif maths/sciences/conversation pédagogique en deux langues. Coût/token suffisamment bas pour un freemium viable.

Inversement, attendre 6-12 mois supplémentaires laisse le terrain à des concurrents internationaux qui pourraient pivoter sur le Cameroun (apps EdTech panafricaines en levée). **Le MVP en 6 semaines vise précisément cette fenêtre.**

---

*Fin du PRD V1 (draft). À enchaîner avec `bmad-ux` (DESIGN.md + EXPERIENCE.md à partir des HTML existants) ou directement `bmad-create-architecture` (Winston, qui lit ce PRD + les archis mobile/backend déjà documentées).*
