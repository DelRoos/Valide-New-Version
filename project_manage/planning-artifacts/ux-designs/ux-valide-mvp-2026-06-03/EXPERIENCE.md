---
name: Valide
status: draft
created: 2026-06-03
updated: 2026-06-03
sources:
  - ../../../specs/spec-valide-mvp/SPEC.md
  - ../../prds/prd-valide-mvp-2026-06-03/prd.md
  - DESIGN.md
  - ../../../../doc/tech/Valide - Design.html
---

# Valide — Experience Spine

> **Comportement, flux, états, accessibilité.** Source de vérité pour tout ce qui est `comment ça marche`. L'identité visuelle (tokens, composants visuels) vit dans [`DESIGN.md`](DESIGN.md), que ce fichier référence par syntaxe `{path.to.token}`. En cas de conflit avec un mock importé, **les spines (DESIGN + EXPERIENCE) priment**.

---

## Foundation

**Form-factor :** mobile natif Android-first (Flutter). Versions cibles Android 8.0 → 14+. iOS reporté V2 (cf. PRD § 14). Pas de support tablette / iPad / web en V1.

**Inheritance :** pas de UI system tiers (shadcn, MUI, etc.) — l'app étend les conventions Material 3 d'Android mais ne s'y soumet pas littéralement. Les tokens `DESIGN.md` priment. Les gestes système (back, swipe-to-dismiss sur sheets, system text selection) sont préservés.

**Bilinguisme :** la langue (FR ou EN) est **figée à l'inscription** par le choix de sous-système. Aucun toggle de langue dans l'app. Toute chaîne affichée à l'élève doit exister dans les deux langues (catalogue ARB).

**Thème :** light only en V1. Pas de dark mode — `[ASSUMPTION]` que la consultation se fait majoritairement en journée. Dark mode candidat V2 si demande remonte.

**Connectivité :** l'app fonctionne **systématiquement en mode dégradé acceptable** quand la connexion lâche. Aucun écran ne bloque sur un loader infini ; aucune fonctionnalité critique n'exige le réseau **après** avoir été initialement chargée.

---

## Information Architecture

Navigation top-level via **bottom tab bar à 4 onglets** (cf. maquettes M2 du Design HTML). Pas de drawer hamburger.

### Top-level surfaces

| Tab | Surface | Atteint depuis | Rôle |
|---|---|---|---|
| 🏠 | **Accueil** | App open par défaut | Carte de bienvenue contextuelle, mini-carte de rang, 3 recommandations, raccourci modes en cours |
| 📚 | **Matières** | Tab | Grille des matières du profil → chapitres → leçons → notions → exercices |
| 📝 | **Activités** | Tab | Quiz récents, examens, modes en cours, historique |
| 👤 | **Profil** | Tab | Identité, abonnement + crédits, école, paramètres minimaux, notifications, déconnexion, suppression |

### Surfaces secondaires

| Surface | Atteint depuis | Rôle |
|---|---|---|
| **Onboarding** (1ère ouverture) | Cold start sans session | Choix sous-système → profil scolaire → objectif → démo IA → compte |
| **Lecture cours** | Matières → ... → leçon | `PedagogicalContent` : texte enrichi, LaTeX, Mermaid |
| **Énoncé exercice** | Leçon → exercice OU Activités | Énoncé + choix de mode (1/2/3) |
| **Mode 1 — Je maîtrise** | Énoncé → tap « Mode 1 » | Soumission texte/photo, correction IA |
| **Mode 2 — Semi-assisté** (premium) | Énoncé → tap « Mode 2 » → si gratuit, paywall | Étapes + indices + cours associé |
| **Mode 3 — Assisté** (crédits) | Énoncé → tap « Mode 3 » | Chat tuteur IA pas à pas |
| **Mode examen** (premium) | Activités → Sujets blancs | Chrono + composition + corrigé |
| **Santé scolaire** | Accueil → mini-carte OU Profil → progression | Niveau par matière / chapitre / leçon / notion |
| **Classements** | Accueil → mini-carte de rang → « voir tous » | 5 boards (général, hebdo, matière, classe, école) |
| **Chat IA** | Accueil → FAB OU contextuel depuis cours/notion/exercice | Conversation libre ou contextuelle |
| **Notifications** | Icône cloche persistante (header) | Liste chronologique, marquer comme lu |
| **Paywall** | Tentative d'action premium par compte gratuit | Plans + souscription |
| **Achat crédits** | Solde crédits OU tentative action payante avec solde insuffisant | Packs + paiement |
| **Liens partagés** | Profil → activité → liens | Liste avec compteur d'ouvertures, désactivation |

### Règles de navigation

- **Bottom tab bar** : visible sur toutes les top-level surfaces et les vues de drill-down liste. Cachée sur les écrans modaux (onboarding, paywall, mode examen, Mode 1/2/3 en cours).
- **Bouton retour Android** : navigue dans l'historique de la pile, sans surprise.
- **Deep links internes** : tap sur notification ou tap sur recommandation → navigation directe vers la surface cible avec contexte préservé.
- **Garde profil-incomplet (FR-4)** : tant que le profil n'est pas complet, tout deep link redirige vers l'écran d'inscription en cours.
- **Garde auth visiteur** : un visiteur peut consulter (Matières, Profil partiel) mais ne peut lancer aucun mode ni composition — invitation à créer un compte sur tap d'action.

---

## Voice and Tone

**Microcopie.** La voix de marque visuelle (chaleureuse, claire, confiante) vit dans `DESIGN.md.Brand & Style`. Ici, les règles de rédaction des chaînes affichées.

### Principes

- **Français : tutoiement par défaut** (élève, cible ado/jeune adulte). « Tu peux », « tu vas voir », « ton niveau ».
- **Anglais : ton équivalent informel direct.** Pas de « please » excessif, pas de capitalisation Title Case dans le corps.
- **Court et complet.** Phrases entières, mais courtes. Pas de jargon technique.
- **Pas d'émoji** dans l'interface (gardés pour les notifications de réussite et la célébration, mesurés).
- **Pas de point d'exclamation** sauf célébration explicite.
- **Pas de jargon religieux ou culturel polarisant.**

### Microcopie d'état

| Situation | Faire (FR) | Faire (EN) | Ne pas faire |
|---|---|---|---|
| Chargement | « Chargement… » ou skeleton silencieux | "Loading…" or silent skeleton | "Veuillez patienter pendant le chargement..." |
| Pas de connexion | « Pas de connexion. Tu peux continuer ce que tu as ouvert. » | "No connection. You can continue with what you've opened." | "Network error 503" |
| Erreur serveur | « Une erreur est survenue. Réessaie ? » | "Something went wrong. Try again?" | "HTTP 500 internal server error" |
| Action réussie | « C'est enregistré. » | "Saved." | "Vos modifications ont été enregistrées avec succès !" |
| Profil incomplet | « Termine ton profil pour accéder à tes matières. » | "Complete your profile to access your subjects." | "Profile required" |
| Crédits insuffisants | « Il te manque 3 crédits pour cette action. » | "You need 3 more credits for this action." | "Insufficient balance" |
| Paywall Mode 2 | « Mode 2 — Semi-assisté. Inclus dans le premium. » | "Mode 2 — Step-by-step. Included with premium." | "Subscription required" |
| Quota chat atteint | « Tu as utilisé tes 10 messages aujourd'hui. Reviens demain ou passe en premium pour 200/jour. » | "You've used your 10 messages today. Come back tomorrow or upgrade to premium for 200/day." | "Quota exceeded" |
| IA refuse de donner la réponse | « Je peux te guider — qu'as-tu déjà essayé ? » | "I can guide you — what have you tried so far?" | "I cannot provide the answer" |
| Mention obtenue | « Très bien ! Mention obtenue : Bien. +100 points. » | "Well done! Distinction earned: Good. +100 points." | "Congratulations! You won!!!!" |
| Niveau monté | « Ton niveau en Photosynthèse passe à Solide. » | "Your level in Photosynthesis moves up to Solid." | "Achievement unlocked: Photosynthesis Master 🎉🎉🎉" |

### Étiquettes de santé scolaire

Stratégique : **`priorité`** plutôt que **« faible »** ou **« mauvais »**. Une notion `priorité` est une invitation à agir, pas un verdict.

| FR | EN | Niveau |
|---|---|---|
| Solide | Solid | ≥ 70 |
| À renforcer | To strengthen | 40-69 |
| Priorité | Priority | < 40 |

### Boutons d'action

- Verbes d'action concrets : « Démarrer », « Soumettre », « Partager », « Voir le corrigé ».
- Pas de boutons-questions (« Voulez-vous… »).
- Pas de boutons-évidence (« Cliquer ici »).

---

## Component Patterns

**Behavioral.** Specs visuelles dans `DESIGN.md.Components`.

| Composant | Quand l'utiliser | Règles comportementales |
|---|---|---|
| **Bouton primaire** (`{components.button}`) | Action principale unique de l'écran | Un seul par écran. Disabled state : `{colors.mute2}` background, opacité 0.6. Loading state : remplacer texte par spinner `{components.icon}` + label « Envoi… ». Tap area = la zone visuelle, pas plus pour éviter les claps fantômes. |
| **Bouton secondaire** | Action secondaire ou annulation | À côté du primaire en barre d'action de modale. Jamais utilisé seul comme action principale. |
| **Carte de cours / leçon** | Grille Matières, liste chapitres | Tap → ouvre. Long-press réservé au système. Skeleton pendant le chargement. |
| **Pill tabs** | Filtrer une liste, basculer entre vues équivalentes | Max 3 onglets. Au-delà → utiliser un sélecteur dropdown. Sélection visible immédiate, contenu chargé en transition de 200 ms. |
| **Bottom sheet** | Choix contextuel, confirmations courtes, partage | Hauteur auto-content. Tap hors zone OU swipe-down ferme. Bouton de validation primaire en bas, callable au pouce. |
| **Modale plein écran** | Onboarding step, paywall, mode examen, célébration | Pas de close discret en X seul ; bouton clair « Continuer » ou « Plus tard ». |
| **Toast** | Confirmation d'action courte non-bloquante (« Lien copié », « Notif marquée lue ») | Top de l'écran, 4 s, slide-in/slide-out 200 ms. **Jamais** pour un état d'erreur critique — pour ça, utiliser un encadré inline. |
| **Encadré inline** (info/warning/error) | Information persistante sur un écran (pas de connexion, abonnement bientôt expiré, paywall justification) | Pas auto-dismiss. Bouton d'action si possible. |
| **Badge** | Métadonnée non-cliquable (étiquette santé, type d'exercice, mention) | Couleur sémantique selon contexte. Toujours doublé d'un texte (cf. `DESIGN.md.Colors` règle stricte). |
| **Champ texte** | Saisie utilisateur | Label au-dessus (jamais placeholder seul). Erreur de validation : encadré rouge sous le champ avec texte explicatif. Auto-focus uniquement sur le premier champ d'un formulaire. |
| **Photo Mode 1** | Bouton « Photo » dans Mode 1 | Demande permission caméra ou galerie. Capture → compression locale → preview → confirmation avant envoi. Indicateur de progression d'upload visible. |
| **PedagogicalContent** | Rendu cours, énoncé, correction IA, message chat | Wrappant `flutter_smooth_markdown` (cf. archi mobile § 4 et 17.7). Lazy-load (pas chargé au démarrage de l'app). Streaming pour Mode 3 et chat (effet caractère par caractère). |
| **Spinner** | Action courte < 3 s perçues | Au-delà → basculer en skeleton ou en barre de progression chiffrée. |
| **Skeleton** | Chargement de liste, de cours, de quiz | Respecte la forme finale du contenu. Animation `shimmer` désactivée si « réduire animations » système actif. |
| **Mini-carte de rang** | Dashboard | Affiche rang actuel + flèche d'évolution (↑↓→) + delta. Tap → écran classement détaillé. Si élève sans école → variante message « Renseigne ton lycée pour voir ton classement de classe » `[OPEN — cf. PRD OQ-6]` |

---

## State Patterns

Chaque écran possède au minimum 4 états gérés : **loading**, **error**, **empty**, **success**. Aucun écran ne peut être en état indéterminé.

| État | Surface | Traitement |
|---|---|---|
| Cold open (jamais ouvert) | Accueil | Skeleton hero + skeleton 3 recommandations, puis hydratation Firestore (cache si dispo). |
| Cold open (déjà ouvert) | Accueil | Affichage immédiat depuis cache, refresh silencieux Firestore au retour focus. |
| Offline open | Accueil + Matières + cours déjà consultés | Affichage normal depuis cache. Encadré inline `info` discret en haut : « Hors ligne — ce que tu as déjà ouvert reste disponible. » Disparaît dès que la connexion revient. |
| Empty matières (profil incomplet) | Matières | Bloc « Termine ton profil » + bouton « Compléter mon profil » qui ouvre l'inscription en cours. |
| Empty activités (jamais d'activité) | Activités | État vide + invitation « Lance ton premier quiz ». |
| Empty classement classe (sans école) | Classements > Ma classe | « Renseigne ton lycée pour rejoindre ce classement » + bouton « Lier mon école ». |
| Empty notifications | Notifications (cloche) | « Tu seras notifié ici quand quelque chose arrive. » |
| Loading cours (gros contenu) | Lecture cours | Skeleton structural (titres, paragraphes) avant rendu du contenu. Indicateur visible dans les 200 ms. |
| Loading correction IA | Mode 1 après soumission | Encadré inline avec spinner + texte « Correction en cours… » + bouton « Annuler ». L'utilisateur reste sur l'écran ; pas de modal bloquant. |
| Streaming chat / Mode 3 | Chat & Mode 3 | Texte qui s'écrit caractère par caractère, indicateur « ... » en bas tant que le stream est ouvert. |
| Sync en cours | Discrete badge dans header (icône cloud + animation) | Apparaît si écriture en file d'attente côté Firestore offline (paiement, soumission). Disparaît dès sync OK. |
| Error réseau (action) | Inline sur le bouton d'action | Le bouton revient à son état initial après l'erreur. Encadré rouge sous le bouton : « Pas de connexion. Réessayer ? ». |
| Error serveur | Encadré rouge dans la surface concernée + log Crashlytics côté app | Message d'erreur clair non technique. Bouton « Réessayer ». |
| Error idempotence (jamais visible utilisateur) | — | Si retry réseau aboutit à une opération déjà traitée, l'app reçoit le même résultat — pas d'erreur ni message. |
| Success quiz / exercice | Écran de résultat plein largeur | Score + impacts santé + points gagnés. Animation `pulse` brève sur le score (désactivée si réduction animations). Bouton primaire « Voir le corrigé », secondaire « Retour ». |
| Success paiement | Écran de célébration plein écran | Texte « Bienvenue dans Premium » + mention de ce qui est débloqué + bouton « Découvrir le Mode 2 » qui navigue vers un Mode 2 d'exemple. Apparaît seulement quand le stream Firestore confirme `subscriptions.status = "active"`. |
| Premium expiré | Bandeau persistant en haut de l'accueil | « Ton abonnement a expiré. Tu peux le renouveler à tout moment. » + bouton « Voir les plans ». |
| Solde crédits faible | Bandeau discret dans header crédits | À 10 / 5 / 0, bandeau orange (`amber`) avec « Plus que X crédits — achète un pack ». Plafond : un seul bandeau par seuil franchi. |
| Quota chat atteint | Inline dans le composer chat | Champ disabled + message « Tu as utilisé tes X messages aujourd'hui. » + lien « Voir mes plans » si gratuit. |
| Suppression de compte (7 jours grace) | Profil | Bandeau rouge persistant : « Ton compte sera supprimé le 2026-06-10. Reconnecte-toi avant pour annuler. » Disparaît dès la reconnexion (annulation). |
| Examen — sauvegarde continue | Pendant mode examen | Badge discret « Enregistré » qui clignote à chaque autosave (≥ 5 s). |
| Examen — connexion coupée | Pendant mode examen | Indicateur « Hors ligne — composition sauvegardée localement » dans le header. Aucune action utilisateur requise. |
| Examen — temps écoulé | À l'expiration du chrono | Auto-submission immédiate. Modal full screen : « Temps écoulé — composition envoyée. » + bouton « Voir le corrigé ». |

---

## Emotional Posture

**Pourquoi cette section** : sur un marché de l'éducation où l'élève vient souvent avec de l'anxiété (examen, parents, peur de l'échec), l'app doit dégager une émotion **encourageante, lucide, calme**. L'émotion n'est pas un vernis : elle change la rétention, la persévérance, l'usage.

### Les 4 émotions cibles, par moment

| Moment | Émotion visée | Levier principal | Anti-pattern |
|---|---|---|---|
| **Onboarding (premier soir)** | Soulagement, accueil | Copy chaleureux, illustration douce, progression visible | Pas de wall of text, pas d'avalanche d'options |
| **Lecture cours / révision** | Concentration sereine | Typographie généreuse, blancs respiratoires, micro-feedback discret | Pas de notifications, pas de pop-up promo, pas de bandeaux premium intrusifs |
| **Bonne réponse / progression** | Fierté tranquille | Checkmark animé doux + haptic light + son success_soft + copy concis (« C'est ça. ») | Pas de confettis débridés, pas de « 🎉🎉🎉 » |
| **Mauvaise réponse / échec** | Bienveillance, redirection | Shake léger + haptic medium + son error_soft + copy non culpabilisant (« Pas tout à fait. On reprend ? ») | Pas de couleur rouge agressive seule, pas de « Faux ! », pas de score qui descend en gros |
| **Paywall / paiement** | Confiance, contrôle | Transparence prix, copy direct (« 1 500 F CFA pour 1 mois »), feedback paiement haptic+son+anim claire | Pas de dark pattern, pas de countdown anxiogène, pas de comparaisons honteuses |
| **Mode Examen** | Concentration neutre | **Tout son et haptic coupés**, motion réduit, copy minimaliste, chrono visible mais discret | Pas de célébration, pas d'animations décoratives, pas de couleurs vives |
| **Santé scolaire faible** | Espoir, plan d'action | Étiquette « Priorité » (jamais « faible »), suggestion concrète immédiate, micro-anim d'invitation | Pas de jugement, pas de classement humiliant |

### Règles d'écriture émotionnelle

- **Tutoiement présent mais non envahissant.** « Tu peux », « tu vas voir », pas « Tu DOIS ».
- **Préférer le futur à l'impératif** : « Tu vas voir tes matières » plutôt que « Vois tes matières ».
- **Nommer le sentiment de l'élève uniquement quand on est sûr** : « Pas tout à fait, on reprend ? » plutôt que « Ne sois pas découragé ! ».
- **Verbes au présent pour décrire l'état** : « Ton niveau monte » au lieu de « Ton niveau a augmenté ».
- **Une émotion par écran**, pas un cocktail. Un écran de quiz est concentration ; un écran de résultat est fierté ou redirection ; pas les deux.

### Couleur et émotion (rappels — specs dans DESIGN.md)

- **Primary `{colors.primary}`** : confiance, engagement (boutons d'action principaux).
- **Success `{colors.success}`** : validation, plein de sens (jamais utilisé en succès gratuit pour ne pas dévaloriser).
- **Warning `{colors.warning}`** : attention sans peur (utilisé pour rappels positifs, pas pour menaces).
- **Error `{colors.error}`** : présent mais doublé d'un texte explicite (jamais signal seul).
- **Soft palettes (`{colors.primary-soft}`, etc.)** : pour les fonds de surface émotionnellement neutres mais chaleureux.

---

## Multisensoriel — Motion, Audio, Haptic

**Posture globale** : Tout est animé (micro-interactions partout, transitions sobres), les sons accompagnent les **moments significatifs uniquement** (≤ 12 sons clés), les haptics renforcent **chaque confirmation positive ou négative significative**. **Toutes ces couches respectent les préférences système et les contraintes marché** (téléphones modestes, batterie, mode silencieux).

> Les **tokens, catalogues, durées et packages** vivent dans `DESIGN.md` § Animations & motion / Audio / Haptics. Ici on couvre **quand** déclencher quoi, pas **comment** l'implémenter.

### Choreography par moment clé

| Moment | Anim | Son | Haptic | Copy |
|---|---|---|---|---|
| Tap bouton primaire | `tap feedback` 120 ms | `tap` (si activé + bouton primaire) | `light` | — |
| Tap bouton secondaire | `tap feedback` 120 ms | aucun | `selection` | — |
| Bonne réponse Mode 1 | `success checkmark` 300 ms | `success_soft` | `medium` | « C'est ça. » |
| Bonne réponse Mode 2 (semi-assisté) | `success checkmark` 300 ms + barre progression | `success_strong` | `medium` | « Étape validée. » |
| Mauvaise réponse Mode 1 | `error shake` 360 ms | `error_soft` | `heavy` | « Pas tout à fait. On reprend ? » |
| Quiz terminé | `progress bar fill` 300 ms + slide écran résultat | `complete` | `success` (séquence) | « Quiz terminé. » + mention obtenue |
| Niveau monté (santé scolaire) | `level-up bloom` 600 ms | `levelup` | `heavy` | « Ton niveau en {notion} passe à {Solide}. » |
| Badge gagné | `level-up bloom` 600 ms | `badge` | `heavy` | « Badge gagné : {nom}. » |
| Paiement Mobile Money OK | `success checkmark` plein écran 700 ms | `payment_ok` | `success` (séquence) | « Paiement reçu. Premium activé. » |
| Paywall hit (essayer Mode 2 sans premium) | `error shake` 200 ms (sur bouton bloqué) | `error_strong` | `heavy` | « Mode 2 — inclus dans le premium. » + CTA |
| Notification in-app | `slide-up snackbar` 200 ms | `notification` | aucun | court (≤ 60 caractères) |
| Streak maintenu | `pulse` discret sur badge profil | `streak` (très discret) | `light` | optionnel |
| Message Chat IA envoyé | `slide-up bulle` 200 ms | `chat_send` | `selection` | — |
| Pull-to-refresh | spinner natif | aucun | `selection` (au release du pull) | — |
| Switch tab principal | `pill tabs switch` 120 ms | aucun | `selection` | — |
| Page transition standard | `slide page` 200 ms | aucun | aucun | — |
| Skeleton chargement | `skeleton shimmer` (continu) | aucun | aucun | — |
| Hello première ouverture (sentinelle E0) | fade-in 300 ms du texte + formule LaTeX | aucun | aucun | « Hello Valide » |

### Coupures globales (override toutes les couches)

| Contexte | Motion | Audio | Haptic |
|---|---|---|---|
| **Mode Examen actif** | Motion réduit (seules transitions fonctionnelles) | Aucun son | Aucun haptic |
| **Mode silencieux Android** | Motion normal | Aucun son | Haptic normal (volume silencieux n'affecte pas la vibration) |
| **Mode économie batterie Android** | Anims continues coupées (shimmer ok), motion fonctionnel ok | Sons toujours OK | Haptic OK |
| **Batterie < 15 %** | Anims continues coupées | Sons OK | Aucun haptic (économie) |
| **Préférence système « réduire animations »** (MediaQuery.disableAnimations) | Anims décoratives → statique, fonctionnelles 120 ms max | Sons OK | Haptic OK |
| **Setting Profil « Sons activés » = off** | Motion normal | Aucun son | Haptic normal |
| **Setting Profil « Vibrations activées » = off** | Motion normal | Sons normaux | Aucun haptic |

### Anti-patterns multisensoriels

- **Jamais cumuler animation lourde + son fort + haptic heavy** pour la même action banale. Réservé aux 3-4 moments forts par session.
- **Pas d'animations qui retardent l'action** : si un tap bouton déclenche une anim 400 ms avant l'effet, l'utilisateur perçoit l'app comme lente. Le `tap feedback` 120 ms est **simultané** à l'action, pas avant.
- **Pas de son sans haptic associé** sur les confirmations (en mode silencieux, l'utilisateur n'a aucun feedback).
- **Pas de haptic seul** sans feedback visuel (les sourds-malentendants ne sont pas le cas critique, mais l'utilisateur regarde son écran : le visuel reste maître).
- **Pas de boucle audio** (musique d'ambiance, jingles répétés).
- **Pas de pop-up à la première utilisation** « Veux-tu activer les sons ? » — settings vivent dans Profil, on n'interrompt pas l'onboarding.

### Implémentation amont (rappel Stories Epic 0)

- **Tokens motion** (durations, easings) : Story 0.10 — Setup design tokens
- **Atoms animés** (boutons avec tap feedback, switch toggle haptic, pill tabs) : Story 0.13 — Composants atomiques
- **Services audio + haptic + overlays célébration** : Story 0.14 — Composants feedback
- **Setting « Sons / Vibrations »** dans Profil : E1 ou première story Profil

---

## Interaction Primitives

- **Tap to act.** Tout élément cliquable réagit visuellement au tap (état pressed : opacité 0.7 sur le bouton, ou highlight `{colors.primary-soft}` sur les cards).
- **Long-press réservé au système** (sélection de texte, copier-coller). Pas de menu contextuel custom long-press en V1.
- **Swipe horizontal** : autorisé sur les pill-tabs (basculer entre vues équivalentes). Pas de carrousel d'écrans pleins.
- **Swipe-down** : ferme les bottom sheets.
- **Pull-to-refresh** : sur les écrans listes uniquement (Matières grille, Activités, Notifications, Classements). Pas sur les écrans de contenu (cours, énoncé, chat).
- **Bouton retour Android** : navigation hiérarchique. Sur modales/sheets : ferme la modale/sheet.
- **Tap hors zone d'une modale** : ferme la modale, sauf si elle contient des saisies non sauvegardées (alors confirmation).
- **Caméra/galerie** : déclenchement par bouton explicite uniquement, jamais par geste implicite.

**Bannis :**

- **Pas de carrousel** d'écrans principaux (le swipe horizontal est contre-intuitif pour les bottom tabs).
- **Pas d'animation hero au cold open** au-delà de 400 ms (ralentit le perçu).
- **Pas de badge count rouge** sur les onglets (le « notifications » s'affiche dans l'icône cloche, pas en chiffre sur le tab).
- **Pas de push notifications de re-engagement excessif** — respecter les plafonds (FR-35).
- **Pas de streaks** comme métrique gamification principale. Les streaks sont visibles sur le profil mais ne génèrent pas de notifications culpabilisantes en cas de rupture.
- **Pas de modales empilées** (max 1 niveau d'overlay).

---

## Accessibility Floor

**Behavioral.** Le contraste visuel est dans `DESIGN.md`.

### TalkBack / system reader

- Chaque élément interactif a un **label sémantique** explicite + son **rôle** + son **état** (« Bouton, soumettre l'exercice, désactivé »).
- Les éléments de progression annoncent la valeur (« Progression : 3 sur 5 étapes »).
- Les états de santé scolaire annoncent l'étiquette (« Photosynthèse, niveau solide, en hausse cette semaine »).
- L'icône cloche annonce le nombre de notifications non lues.

### Dynamic type (taille de police système)

- Les tokens de typo (`{typography.scale}`) doivent **respecter le `textScaleFactor`** d'Android. Aucun texte ne doit truncate à la plus grande accessibilité — l'écran scrolle si nécessaire.
- Tester chaque écran à `textScaleFactor: 1.3` (grande taille système) — c'est la barre minimum.

### Réduction des animations

- Désactiver `pulse`, `shimmer` et autres anims décoratives. Garder uniquement les transitions fonctionnelles courtes (200 ms).
- Les célébrations passent en affichage statique (texte + couleur).

### Tap targets

- Minimum **48 dp** Android (cf. principe accessibilité du Design System HTML). Le défaut bouton de `52 px` dépasse confortablement.
- Sur les listes denses (matières), maintenir un padding suffisant pour éviter les claps fantômes.

### Ordre de focus

- Suit l'ordre de lecture (haut → bas, gauche → droite en mode LTR).
- Le focus visible passe en `outline 2px {colors.primary}` sur l'élément ciblé.

### Couleur seule jamais un signal

- Toute information critique (étiquette de santé, état d'erreur, statut premium) est doublée d'un **texte explicite** et d'une **icône** si pertinent. Cf. règle stricte dans `DESIGN.md.Colors`.

### Internationalisation et lisibilité

- Pas de chaîne en dur dans le code (toutes via ARB FR/EN).
- Les chaînes longues (paragraphes d'explication) sont vérifiées en FR et EN pour éviter les débordements (anglais ~10 % plus court, français ~15 % plus long que la moyenne).
- Les chiffres et dates utilisent le format local (`intl` package).

### Connectivité comme accessibilité

L'app doit être utilisable en connexion 3G dégradée, ce qui est une forme d'accessibilité pour la cible. Cela implique :

- Aucun loader infini : timeout systématique avec proposition d'action.
- Messages d'erreur réseau **explicites** mentionnant la connectivité, jamais un code technique.
- Skeleton plutôt que spinner pour les chargements > 500 ms perçus.

---

## Responsive & Platform

**Form-factors supportés :** Android téléphone uniquement en V1.

### Breakpoints téléphone

| Catégorie | Largeur logique | Comportement |
|---|---|---|
| Petit (entrée de gamme) | 360 dp (~5") | Marges horizontales 16 px. Grille de matières en 3 colonnes. |
| Standard (milieu) | 393 dp | Marges horizontales 16 px. Grille en 3 colonnes. |
| Tall | 412 dp | Marges horizontales 20 px. Grille en 3 colonnes. |
| Large | 480 dp+ | Marges horizontales 20 px. Grille en 4 colonnes. |

**Pas de support tablette.** Si l'app est lancée sur tablette Android (par accident), l'expérience reste mono-colonne avec marges horizontales centrées et largeur max 480 px. Pas de mise en page split-view en V1.

### Densités d'écran

- Tester sur ldpi/mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi (cibler particulièrement xhdpi et xxhdpi qui dominent le segment entrée et milieu de gamme camerounais).
- Toutes les icônes sont vectorielles (SVG via `flutter_smooth_markdown` ou widgets natifs) — pas de PNG multirésolution.

### Plateforme Android

- Respecter les **system gestures** (back, home, recents).
- L'app **n'utilise pas** la barre de notification système pour des notifications inline (uniquement les pushes FCM légitimes).
- **Pas d'overlay screen** au-dessus d'autres apps.
- **Pas de demande de permissions abusive** : caméra demandée uniquement quand l'élève tape « Photo » dans Mode 1, géolocalisation jamais.

### Adaptation aux téléphones modestes

- Cible : Android 8.0 (API 26), 2 GB RAM, 32 GB stockage.
- L'app installée doit faire **< 30 MB** (cf. NFR-1 du PRD).
- Pas de splash screen plus long que 2 s.
- Lazy-load `flutter_smooth_markdown` au premier écran qui le nécessite (lecture cours, correction IA, chat).
- Compression photo Mode 1 : qualité WebP 80, max 200 KB avant upload.

---

## Inspiration & Anti-patterns

Quelques références explicites pour cadrer la posture.

### Inspirations

- **Duolingo** — le sentiment de progression visible (mini-carte de rang + recommandations sur le dashboard). On reprend l'idée de **rendre le progrès visible quotidiennement**.
- **Khan Academy** — la hiérarchie matière → leçon → exercice et le mélange contenu/pratique sur le même écran. On reprend la **clarté de la structure pédagogique**.
- **Notion / Linear** — la palette restrained (un seul accent) et la mono-colonne disciplinée. On reprend le **bleu unique guidant l'action**, pas de palette arc-en-ciel.

### Anti-patterns rejetés

- **Streaks comme métrique principale** (Duolingo, Snapchat, BeReal). On rejette la culpabilisation des jours manqués qui est démotivante. Les streaks restent visibles sur le profil mais ne génèrent ni notification de rupture, ni perte de privilège.
- **Notifications push de re-engagement** (« Tu nous manques »). On limite les notifications aux **plafonds documentés** (1 rappel par période d'absence, pas un par jour).
- **Carrousel de matières en haut du dashboard** (Babbel, certains EdTech occidentaux). Le carrousel masque les options. On préfère la grille complète sur l'onglet Matières.
- **Couleur de santé scolaire vif (vert vif solide, rouge vif faible)**. On préfère les variantes `soft` plus douces, doublées d'un texte. La cible ado/jeune adulte camerounais a un rapport sensible à la couleur du « rouge » (échec).
- **Voix encouragement excessive** (« Tu es génial ! », « Quel champion ! »). On préfère le factuel encourageant (« +28 points », « Niveau passé à Solide »).

---

## Key Flows

Les flux suivants reprennent et étendent les UJ-1 à UJ-7 du PRD. Chaque flux a un **climax** : le moment où la valeur est délivrée et où l'élève le sait.

### Flow 1 — Onboarding (Fatou, premier soir)

*Réalise UJ-1 du PRD. Personas : Fatou Mballa, Tle D francophone, Yaoundé, Tecno Spark 8.*

1. Fatou lance l'app pour la 1ʳᵉ fois. Splash 1.5 s (logo bleu pulsé léger).
2. Écran sous-système : deux boutons primaires plein largeur **« Francophone »** et **« Anglophone »**. Aucun défaut suggéré. Tap « Francophone » → toute l'app passe en français immédiatement.
3. Écran profil étape 1/3 : filière. Deux cartes : **Général** et **Technique**. Tap « Général ».
4. Étape 2/3 : niveau. Liste scrollable (6ᵉ à Terminale). Tap « Terminale ».
5. Étape 3/3 : série. Pill tabs : A, C, D, E (selon disponibilité). Tap « D ».
6. Écran récap : matières dérivées affichées en grille (Maths, PCT, SVT, Français, Anglais, LV2, Philo, Histoire-Géo, EPS) + examen visé en bandeau (« Tu prépares le BAC D »). Bouton primaire « C'est ma classe ».
7. Écran liaison école (optionnel) : champ recherche + suggestions + bouton secondaire « Passer ». Fatou tape « Lycée Bilingue d'Application », sélectionne dans la liste.
8. Écran compte : deux boutons « Continuer avec Google » et « Continuer avec Apple ». Fatou tape Google.
9. Sheet système Google Sign-In → confirmation.
10. **Climax :** écran d'accueil s'affiche, hero bleu avec « Bienvenue Fatou ! Voici tes matières. ». Mini-carte de rang vide (« Pas encore classée — fais ton premier quiz ! »). 3 recommandations starter (« Commence par les fonctions polynomiales — programme officiel BAC D »). Fatou est dans l'app, prête.

**Failure : panne Google Sign-In** → écran d'erreur explicite, bouton « Réessayer » + lien « Continuer en visiteur (tu pourras créer un compte plus tard) ». Pas de blocage dur.

**Edge case : profil interrompu** → réouverture relance directement l'étape en cours (FR-8 persistance).

### Flow 2 — Lecture cours en taxi-brousse (James, trajet Buea-Limbé)

*Réalise UJ-2. Personas : James Tanyi, Upper Sixth S2 anglophone, Buea.*

1. James ouvre l'app. Accueil affiché instantanément depuis cache.
2. Tap onglet Matières.
3. Grille des 3 matières + optionnelles. Tap **Chemistry** (carte avec icône bécher Lucide).
4. Liste des chapitres avec étiquettes santé. Tap **Organic Chemistry**.
5. Liste des leçons. Tap **Functional Groups**.
6. Liste des notions de cette leçon. Tap **Alcohols and Ethers**.
7. Lecture cours : titre + texte + formule `R-OH` rendue + schéma Mermaid d'estérification. Cache offline déjà actif (cours consulté la semaine dernière).
8. **Climax** : James fait défiler tranquillement, lecture fluide, formule lisible, diagramme correct.
9. Taxi entre dans un tunnel — connexion coupe. Aucun changement visible. Encadré discret « Hors ligne — ce que tu as déjà ouvert reste disponible. » apparaît en haut.
10. Sortie de tunnel — encadré disparaît silencieusement.

**Edge case : exercice rattaché à la leçon** → James tape sur la carte « Exercices » en bas de la leçon. Énoncés affichés (déjà cache). Tap « Mode 1 » → message inline « Cette action a besoin d'une connexion. Réessaye dans un moment. » + bouton « Notifie-moi quand la connexion revient » `[ASSUMPTION — V1 ou V2 selon backlog]`.

### Flow 3 — Mode 1 photo (Fatou, soir de révision maths)

*Réalise UJ-3.*

1. Fatou ouvre l'app, navigue vers l'exercice de probabilités (déjà identifié).
2. Énoncé affiché + 3 boutons modes : Mode 1, Mode 2 (avec badge premium), Mode 3 (coût visible « 10 crédits »).
3. Tap « Mode 1 — Je maîtrise ». Bottom sheet : « Soumets ta réponse — texte ou photo ». Coût affiché : « 5 crédits — Solde actuel : 30 ».
4. Tap « Photo ». Demande permission caméra (si jamais accordée).
5. Caméra système ouvre. Fatou capture son brouillon.
6. Preview avec recadrage automatique. Bouton « Envoyer ma réponse (5 crédits) ».
7. Tap. Compression locale (icône + barre 1 s) → upload Storage (barre de progression) → appel Cloud Function (spinner inline + texte « Correction en cours… »). Total perçu : 8 s.
8. **Climax :** correction affichée. Étape 1 ✓ Juste. Étape 2 ⚠ Incomplet (« Il te manque la condition d'indépendance »). Étape 3 ✻ À mieux rédiger. Chaque étape porte un bouton « Revoir cette partie du cours ».
9. Fatou tape « Revoir » sur étape 2 → ouverture leçon à la bonne section.
10. Retour à la correction. Badge solde mis à jour : « 25 crédits ».

**Edge case : double-tap** → Fatou tape deux fois rapidement sur « Envoyer ». Un seul débit (idempotence par sessionId).

**Failure : timeout IA** → spinner remplacé par encadré « La correction prend plus de temps que prévu. » + bouton « Continuer d'attendre » et bouton « Réessayer plus tard ». Solde **non débité** tant que la correction n'est pas reçue ou explicitement abandonnée.

### Flow 4 — Paywall + paiement premium (James, fin de journée)

*Réalise UJ-4.*

1. James veut faire un exercice de stoechiométrie en Mode 2. Tap sur exercice → tap « Mode 2 ».
2. **Paywall plein écran** affiché immédiatement, **sans charger l'exercice** (économie data + sécurité). Header : « Mode 2 — Semi-assisté ». Sous-titre : « Inclus dans le premium. »
3. Deux plans en pill-tab : « Monthly » sélectionné par défaut, « Yearly » à droite. Sélection Yearly → affichage « 1 500 FCFA/month — Save 25% ». Tap « Subscribe via Orange Money ».
4. Champ téléphone (autofill si dispo). Tap « Continue ».
5. Cloud Function `createSubscription` appelée. Toast d'attente bref. URL agrégateur retournée.
6. WebView agrégateur s'ouvre, page hébergée par Tranzak/Campay/MyCoolPay.
7. James saisit son PIN OM sur son téléphone (via OTP ou push de son operator).
8. Page agrégateur : « Payment in progress ». WebView se ferme automatiquement après 5 s.
9. James revient sur le paywall avec un overlay « Confirming your payment… » (spinner + texte). L'app **n'a rien activé**.
10. Webhook serveur arrive (3-15 s). Stream Firestore émet `status: "active"`. Overlay disparaît, paywall disparaît.
11. **Climax :** écran de célébration plein écran. « Welcome to Premium! ». Mention de ce qui est débloqué (« Mode 2, Mode examen, Fiches, Chat 200/day »). Bouton primaire « Discover Mode 2 ». Tap → exercice se charge enfin.
12. Mode 2 démarre.

**Edge case : webhook tardif (> 30 s)** → overlay propose « Try again » qui re-vérifie le statut via Cloud Function `checkPremiumAccess` puis revérifie le stream. Pas de re-débit.

**Failure : paiement refusé (solde OM insuffisant)** → webhook arrive avec status `failed`. Overlay disparaît, encadré rouge sur le paywall : « Payment could not be completed. Please try with another method. ». Pas de pénalité.

### Flow 5 — Mode 2 semi-assisté avec coupure batterie (James, suite)

*Réalise UJ-4 suite.*

1. James suit les 5 étapes du Mode 2 sur la stoechiométrie. Étape 3 : il révèle 2 indices sur 3 max.
2. Étape 5 : marque « Non résolue ». Tap « Voir le corrigé complet ».
3. Batterie tombe à 5 % → coupure brutale.
4. Recharge. James rouvre l'app.
5. **Climax :** notification accueil « Tu as un Mode 2 en cours sur Stoechiométrie — reprendre ? ». Tap → exercice ouvert, étape 5 active, marquages préservés, indices déjà révélés conservés.

### Flow 6 — Santé scolaire + reco équilibrée (Fatou, le lendemain)

*Réalise UJ-5.*

1. Fatou ouvre l'app. Notification push avait été reçue : « Récap quiz — score 14/20, +28 points ».
2. Accueil : mini-carte « #3 cette semaine sur 14 dans ta classe (+2 places) ». 3 recommandations affichées : (a) « Révise tes points faibles en cinétique chimique » (PCT, priorité), (b) « Maintiens ton niveau en photosynthèse » (SVT, solide — règle d'équilibre), (c) « Termine le sujet BAC D 2024 PCT entamé hier ».
3. Tap mini-carte → écran classements détaillé, 5 boards en pill-tabs (Général, Hebdo, Par matière, Ma classe, Mon école).
4. Retour. Tap « Santé scolaire » dans le profil.
5. Vue d'ensemble : 6 matières affichées avec étiquettes (Maths solide, PCT à renforcer, SVT solide, Philo priorité, etc.).
6. Tap SVT → drill down chapitres avec étiquettes. Tap « Génétique » → leçons. Tap « Lois de Mendel » → notions. Niveau visible à chaque profondeur.
7. **Climax :** Fatou voit que la notion « Photosynthèse » est passée de 65 à 72 — étiquette `solide`. Petite tendance ↑ à droite. Elle revient sur le dashboard, marque la reco (a) « Faite » (elle décide de la traiter plus tard) → la reco disparaît, une nouvelle s'affiche le lendemain.

**Empty state si élève sans école** : la mini-carte de rang affiche « Renseigne ton lycée pour rejoindre ton classement de classe » + bouton « Lier mon école ». `[OPEN — cf. PRD OQ-6 : invitation explicite ou variation silencieuse ?]`

### Flow 7 — Mode examen avec interruption (Fatou, samedi après-midi)

*Réalise UJ-7.*

1. Fatou ouvre Activités → Sujets blancs → BAC D 2024 PCT.
2. Écran d'avertissement plein écran : « Tu démarres un examen blanc. Durée 4 h, pas de pause, pas d'aide externe. ». Boutons : « Pas maintenant » (retour) / « Démarrer ».
3. Tap Démarrer. Chronomètre 4 h démarre dans le header.
4. Sujet affiché : Partie A (Chimie) sur 12 pts, Partie B (Physique) sur 8 pts. Navigation libre via pill-tabs « A / B ».
5. Fatou compose pendant 1 h. Toutes les 5 s, badge discret « Enregistré » clignote.
6. Frère interrompt. Fatou ferme brusquement l'app.
7. 2 h plus tard, elle revient. Notification accueil : « Tu as un examen blanc en cours — reprendre ? ». Tap → chrono repris à où il en était (les 2 h sont décomptées mais la composition est préservée).
8. Fatou termine. Tap « Soumettre ».
9. **Climax :** corrigé partie par partie. Score : 14/20, mention « Bien ». +50 points + 50 bonus mention.
10. Bouton « Partager mon résultat » → bottom sheet WhatsApp/SMS/copier. Tap WhatsApp.
11. Système WhatsApp s'ouvre avec lien `valide.app/r/abc123` + texte pré-rempli.
12. Cousine de Fatou ouvre le lien sur son téléphone (sans app). Page d'invitation Valide → bouton « Installer ». Après installation et inscription, redirection automatique vers le résultat.

**Edge case : timeout du chrono** → soumission automatique sans intervention utilisateur. Modal full screen « Temps écoulé — composition envoyée » + bouton « Voir le corrigé ».

### Flow 8 — Chat IA avec posture pédagogique (James, soir)

*Réalise UJ-6.*

1. James est sur la leçon de radioactivité. Icône chat épinglée en bas → tap.
2. Chat s'ouvre avec contexte automatique (« Discussion sur Radioactivité — half-life »). Quota visible : « 7/200 messages used today ».
3. James : « Why does half-life stay constant even when the amount of substance changes? »
4. Réponse IA en streaming caractère par caractère. Explication progressive. Génère un diagramme Mermaid d'une exponentielle décroissante affiché dans la bulle.
5. James insiste : « Just give me the formula and the answer for a sample problem. »
6. **Climax :** réponse IA en streaming : « I can guide you — what have you tried so far? Let's break the problem into the variables you know. » Le chat **n'a pas** donné de réponse directe. James est obligé de réfléchir.
7. Conversation continue. Quota : 9/200.
8. Quitte. À la prochaine ouverture du chat, conversation reprenable depuis l'historique.

**Edge case : quota approche** → à 195/200, encadré warning « Tu approches de ta limite quotidienne (5 messages restants) ». À 200/200, champ disabled + message « Reviens demain pour 200 nouveaux messages. ».

---

> **Pour les tokens visuels, les composants visuels et les règles d'usage de la couleur**, voir [`DESIGN.md`](DESIGN.md).
>
> **Pour les FRs détaillées et les NFRs cross-cutting**, voir le PRD parent ([prd.md](../../prds/prd-valide-mvp-2026-06-03/prd.md)).
>
> En cas de conflit avec un mock dans `imports/` ou `mockups/`, **les deux spines priment**.
