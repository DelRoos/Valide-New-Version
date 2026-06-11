---
stepsCompleted: ["step-01-validate-prerequisites", "step-02-design-epics", "step-03-create-stories-epic-1"]
inputDocuments:
  - "project_manage/planning-artifacts/prds/prd-valide-mvp-2026-06-03/prd.md"
  - "project_manage/planning-artifacts/architecture/architecture.md"
  - "project_manage/planning-artifacts/architecture/adrs/ADR-001-flutter-clean-architecture.md"
  - "project_manage/planning-artifacts/architecture/adrs/ADR-002-riverpod-vs-getx.md"
  - "project_manage/planning-artifacts/architecture/adrs/ADR-003-firebase-full-backend.md"
  - "project_manage/planning-artifacts/architecture/adrs/ADR-004-bmad-method.md"
  - "project_manage/planning-artifacts/architecture/adrs/ADR-005-shared-surface-doc-partage.md"
  - "project_manage/planning-artifacts/architecture/adrs/ADR-006-subsystem-fixed-at-signup.md"
  - "project_manage/planning-artifacts/architecture/adrs/ADR-007-mobile-money-via-aggregator.md"
  - "project_manage/planning-artifacts/architecture/adrs/ADR-008-idempotency-via-sessionid.md"
  - "project_manage/planning-artifacts/architecture/adrs/ADR-009-flutter-smooth-markdown-wrapped.md"
  - "project_manage/planning-artifacts/architecture/adrs/ADR-010-no-custom-cache.md"
  - "project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/DESIGN.md"
  - "project_manage/planning-artifacts/ux-designs/ux-valide-mvp-2026-06-03/EXPERIENCE.md"
  - "project_manage/specs/spec-valide-mvp/SPEC.md"
  - "doc/partage/BASE-DE-DONNEES.md"
  - "doc/partage/ALGORITHMES.md"
  - "doc/partage/CONTRATS-API.md"
  - "doc/partage/DONNEES-REFERENCE.md"
---

# Valide School MVP — Epic Breakdown

## Overview

Ce document décompose les exigences du **PRD**, de l'**Architecture** et de l'**UX Design** (DESIGN + EXPERIENCE) en epics et stories implémentables pour la phase 4 (développement) du pipeline BMAD.

**Projet** : Valide School — app Flutter EdTech bilingue FR/EN, marché Cameroun secondaire (BEPC, Probatoire, BAC, GCE O/A-Level).
**Pipeline** : BMAD v6.8.0, méthodologie en 6 phases sur 6 semaines.
**Statut** : Stories en cours de génération (phase 3 BMAD).

## Requirements Inventory

### Functional Requirements (44 FRs)

**Onboarding & Profil scolaire (FR-1 à FR-8)**
- **FR-1** — Choix initial du sous-système (francophone/anglophone) au premier lancement, immuable
- **FR-2** — Remplissage du profil scolaire en étapes (filière → niveau → série)
- **FR-3** — Retrait conditionnel de matières (anglophones ≥ Form 3, francophones niveaux supérieurs)
- **FR-4** — Garde de navigation profil-incomplet (redirige vers reprise du flow)
- **FR-5** — Création compte Google/Apple sans perte du profil visiteur (merge)
- **FR-6** — Liaison école optionnelle depuis catalogue
- **FR-7** — Suppression compte avec délai de grâce 7 jours
- **FR-8** — Persistance de la session après fermeture de l'app

**Navigation & Lecture contenu (FR-9 à FR-15)**
- **FR-9** — Navigation hiérarchique (matière → chapitre → leçon → notion)
- **FR-10** — Filtrage automatique du contenu par profil
- **FR-11** — Rendu texte enrichi, formules LaTeX, schémas Mermaid (via `PedagogicalContent`)
- **FR-12** — Filtres et recherche d'exercices
- **FR-13** — Affichage des énoncés (exercices et sujets d'examen)
- **FR-14** — Lecture hors-ligne automatique (cache Firestore)
- **FR-15** — Performance ouverture contenu (< 500 ms si cached, indicateur < 200 ms sinon)

**Quiz & Pratique active Mode 1/2 (FR-16 à FR-19)**
- **FR-16** — Génération de quiz par IA sur notion ou chapitre
- **FR-17** — Soumission Mode 1 texte ou photo avec correction IA
- **FR-18** — Mode 2 — étapes ordonnées, max 3 indices, accès cours, premium
- **FR-19** — Gestion d'erreur réseau côté Mode 1 et Mode 2 (état restituable)

**Freemium & Paiement (FR-20 à FR-28)**
- **FR-20** — Affichage des plans avec comparaison gratuit/premium
- **FR-21** — Paiement Mobile Money via agrégateur (MTN MoMo / Orange Money) en WebView
- **FR-22** — Déblocage automatique après confirmation serveur (stream Firestore)
- **FR-23** — Verrous premium réels côté serveur (règles Firestore + Cloud Functions)
- **FR-24** — Achat de packs de crédits avec bonus (Pack 10 / Pack 25+5 / Pack 60+20)
- **FR-25** — Affichage permanent du solde et coût avant action
- **FR-26** — Idempotence stricte du débit et crédit (sessionId en transaction)
- **FR-27** — Historique des transactions et journal des crédits
- **FR-28** — Annulation d'abonnement avec maintien jusqu'à fin de période

**Santé scolaire & Gamification (FR-29 à FR-36)**
- **FR-29** — Évolution de la santé scolaire notion par notion (solide / à renforcer / priorité)
- **FR-30** — Mise à jour atomique santé + niveau + points (transaction Firestore)
- **FR-31** — Recommandations équilibrées sur dashboard (3 recos, 1/5 sur notion solide)
- **FR-32** — Attribution de points sans double comptage
- **FR-33** — Cinq classements (général, hebdo, matière, classe, école)
- **FR-34** — Mini-carte de rang sur dashboard avec évolution hebdomadaire
- **FR-35** — Notifications push + in-app pour chaque événement avec plafonds quotidiens
- **FR-36** — Marquer toutes notifications comme lues en un geste

**Mode 3, Examen, Chat IA, Partage (FR-37 à FR-44)**
- **FR-37** — Mode 3 — tuteur IA pas à pas, 1 débit par session (10 crédits)
- **FR-38** — Mode examen — composition complète chronométrée (conditions officielles)
- **FR-39** — Sauvegarde continue du mode examen (autosave ≥ 5 s)
- **FR-40** — Corrigé partie par partie, score, mention, réessai illimité
- **FR-41** — Chat IA pédagogique avec posture d'accompagnement (refuse réponses directes)
- **FR-42** — Quota chat visible et appliqué (10 gratuit / 200 premium par jour)
- **FR-43** — Création et partage de liens deep-link (`valide.app/r/{linkId}`)
- **FR-44** — Liste des liens partagés et désactivation avec compteur d'ouvertures

### Non-Functional Requirements (15 NFRs)

- **NFR-1** — Taille app installée < 30 MB (Android App Bundle + split per ABI)
- **NFR-2** — Démarrage app < 3 s sur Android Go-class
- **NFR-3** — Modules Firebase chargés au plus près de leur usage (lazy-load)
- **NFR-4** — Compression photos Mode 1 < 200 KB moyenne (WebP)
- **NFR-5** — Pas de cache custom maison — uniquement cache Firestore offline natif (ADR-010)
- **NFR-6** — Toute opération réseau / décision d'accès / paiement / IA produit un log via `AppLogger`
- **NFR-7** — Aucune exception ne remonte à l'écran (tout passe par `Either<Failure, T>`)
- **NFR-8** — Idempotence garantie côté serveur pour actions rejouables (sessionId en transaction, ADR-008)
- **NFR-9** — Vrai verrou d'accès premium dans règles Firestore (check Flutter = optim UX)
- **NFR-10** — App Check actif sur Cloud Functions sensibles (`enforceAppCheck: true`)
- **NFR-11** — Webhook agrégateur vérifié signature avant action (ADR-007)
- **NFR-12** — Aucun secret dans l'app (clé Claude, secrets webhook en Secret Manager)
- **NFR-13** — Cohérence écritures liées garantie par transaction atomique unique côté serveur
- **NFR-14** — Bilinguisme intégral (ARB FR/EN, pas de chaîne en dur)
- **NFR-15** — Couverture connectivité : retry Dio + messages clairs + état restituable

### Additional Requirements (Architecture — SYS-001 à SYS-013)

Exigences techniques transverses nécessitant des stories d'initialisation.

- **SYS-001** — Setup Flutter projet clean architecture 3 couches × features (Riverpod, go_router) — *ADR-001, ADR-002*
- **SYS-002** — Setup Firebase complet (Auth/Firestore/Storage/Cloud Functions/FCM/Crashlytics/Analytics/Remote Config/App Check) — *ADR-003*
- **SYS-003** — Setup CI/CD (build APK/AAB, tests, lint, Crashlytics upload symbols)
- **SYS-004** — Setup `AppLogger` (single import file `core/logging/app_logger.dart` qui wrap `package:logger`)
- **SYS-005** — Setup theme & design tokens (`core/theme/tokens.dart` alignés sur DESIGN.md, fonts Nunito Sans + JetBrains Mono)
- **SYS-006** — Setup `PedagogicalContent` widget (seul import autorisé de `flutter_smooth_markdown`) — *ADR-009*
- **SYS-007** — Règles Firestore initiales (verrous accès par profil/statut/permission)
- **SYS-008** — Indexes Firestore initiaux (cf. `doc/partage/BASE-DE-DONNEES.md` — 22 collections)
- **SYS-009** — Pattern idempotence sessionId en transaction (template Cloud Function) — *ADR-008*
- **SYS-010** — Cache offline Firestore activé (persistence + sizeBytes 40 MB) — *ADR-010*
- **SYS-011** — App Localizations FR/EN (ARB + gen-l10n, tutoiement FR / informal EN)
- **SYS-012** — `flutter_screenutil` setup (design size 375×812, breakpoints 360/393/412/480)
- **SYS-013** — Monitoring (Crashlytics + sentinelles métier : logs réseau/paiement/IA avec sessionId + uid)

### UX Design Requirements (40 UX-DRs)

**Composants visuels (UX-DR-1 à UX-DR-16)**
- **UX-DR-1** — Bouton primaire (52px height, `rounded.lg`, weight 700, touch ≥ 48 dp)
- **UX-DR-2** — Bouton secondaire (bg soft, bordure primary-soft-border)
- **UX-DR-3** — Champ input (52px, focus bordure 2px primary, label obligatoire)
- **UX-DR-4** — Carte (24px padding, `rounded.2xl`, shadow-soft)
- **UX-DR-5** — Badge (4px×10px, `rounded.pill`, caption 12px weight 700, jamais couleur seule)
- **UX-DR-6** — Pill tabs (max 3 onglets, sélection immédiate)
- **UX-DR-7** — Progression bar (8px height, `rounded.xs`)
- **UX-DR-8** — Encadré info/warning/error (left bordure 4px sémantique)
- **UX-DR-9** — Toast (top 4s, slide 200ms, bg ink texte card)
- **UX-DR-10** — Modale plein écran (24px padding, max-width 420px, bouton explicite)
- **UX-DR-11** — Bottom sheet (handle top, `rounded.2xl` top, safe area)
- **UX-DR-12** — État vide (illustration 64px, titre h3, body, CTA optionnel)
- **UX-DR-13** — Skeleton (gradient shimmer 1.4s, désactivé si réduction animations)
- **UX-DR-14** — Spinner (18px ou 24px, border 3px, 0.7s)
- **UX-DR-15** — Grille matières (grid auto-fill minmax 96px, icônes Lucide stroke 2)
- **UX-DR-16** — Mini-carte de rang (rang + flèche + delta hebdo, tap → classements)

**Design tokens (UX-DR-17 à UX-DR-22)**
- **UX-DR-17** — Système couleurs (primaire `#2563EB`, neutres, sémantiques, contraste WCAG AA)
- **UX-DR-18** — Échelle typographique (display / h1 / h2 / h3 / body / caption / eyebrow)
- **UX-DR-19** — Grille espacements (4px base, 1-16)
- **UX-DR-20** — Arrondis (xs 6 → pill 999, max 2 rayons par écran)
- **UX-DR-21** — Élévations (soft / mid / brand, réservées modales/sheets)
- **UX-DR-22** — Fonts Nunito Sans + JetBrains Mono

**UX patterns & comportements (UX-DR-23 à UX-DR-40)**
- **UX-DR-23** — Bottom tab bar 4 onglets (Accueil/Matières/Activités/Profil)
- **UX-DR-24** — Pattern loading/empty/error/offline (4 états minimum par écran)
- **UX-DR-25** — Pattern toasts (confirmation non-bloquante)
- **UX-DR-26** — Pattern modales (paywall, onboarding, célébration)
- **UX-DR-27** — Pattern bottom sheets (choix contextuel, partage)
- **UX-DR-28** — Accessibilité WCAG AA (contraste 4.5:1 corps, 3:1 ≥ 18px)
- **UX-DR-29** — Touch targets ≥ 48 dp
- **UX-DR-30** — Focus indicators (outline 2px primary)
- **UX-DR-31** — Internationalisation FR/EN (tutoiement FR / informal EN)
- **UX-DR-32** — Responsive 4 breakpoints (360 / 393 / 412 / 480 dp)
- **UX-DR-33** — Mode 1 UX (texte ou photo, correction IA étapes)
- **UX-DR-34** — Mode 2 UX (étapes + indices max 3 + accès cours + premium)
- **UX-DR-35** — Mode 3 UX (chat tuteur, 1 débit par session, streaming)
- **UX-DR-36** — Mode examen UX (chrono + composition + corrigé par barème + autosave)
- **UX-DR-37** — Chat IA UX (contexte auto, quota visible, posture pédagogique)
- **UX-DR-38** — Patterns d'interaction (tap/long-press/swipe/pull-refresh/back Android)
- **UX-DR-39** — Microcopie (tutoiement FR, messages non-techniques, étiquettes positives)
- **UX-DR-40** — Animations (120ms rapide / 200ms standard / 400-700ms célébrations, ease-out entrée)

### FR Coverage Map

| FR / NFR / SYS / UX-DR | Epic | Phase |
|---|---|---|
| FR-1 à FR-8 | E1 | P1 |
| FR-9, FR-11, FR-12, FR-13, FR-14, FR-15 | E2 | P2 |
| FR-10 | E1 (filtrage par profil au login) + E2 (filtres listes contenu) | P1/P2 |
| FR-16 à FR-19 | E3 | P3 |
| FR-20 à FR-28 | E4 | P4 |
| FR-29 à FR-36 | E5 | P5 |
| FR-37, FR-38, FR-39, FR-40 | E6 (Examen + Mode 3) | P6 |
| FR-41, FR-42 | E6 (Chat IA) | P6 |
| FR-43, FR-44 | E6 (Partage) | P6 |
| NFR-1, NFR-2, NFR-3 | E0 (build/lazy-load) | P0 |
| NFR-4 | E3 (compression photos Mode 1) | P3 |
| NFR-5 | E0 (cache Firestore offline) | P0 |
| NFR-6 | E0 (`AppLogger` setup) → utilisé partout | P0 |
| NFR-7 | E0 (`Failure` types + `Either<Failure,T>`) → utilisé partout | P0 |
| NFR-8 | E0 (template idempotence) + E3/E4/E5 (applications) | P0+ |
| NFR-9, NFR-10, NFR-11, NFR-12, NFR-13 | E0 (règles + App Check + secrets) + E4 (webhook) | P0/P4 |
| NFR-14 | E0 (i18n setup) → utilisé partout | P0 |
| NFR-15 | E0 (retry Dio) + chaque epic métier (états restituables) | P0+ |
| SYS-001 à SYS-013 | E0 | P0 |
| UX-DR-1 à UX-DR-22 (composants + tokens) | E0 | P0 |
| UX-DR-23, UX-DR-24, UX-DR-25, UX-DR-26, UX-DR-27 | E0 (patterns globaux) | P0 |
| UX-DR-28, UX-DR-29, UX-DR-30 (accessibilité) | E0 + check par story chaque epic | P0+ |
| UX-DR-31 | E0 (i18n) + chaque epic (chaînes traduites) | P0+ |
| UX-DR-32 (responsive) | E0 + check par story | P0+ |
| UX-DR-33 (Mode 1 UX) | E3 | P3 |
| UX-DR-34 (Mode 2 UX) | E3 | P3 |
| UX-DR-35 (Mode 3 UX) | E6 | P6 |
| UX-DR-36 (Examen UX) | E6 | P6 |
| UX-DR-37 (Chat IA UX) | E6 | P6 |
| UX-DR-38, UX-DR-39, UX-DR-40 (interactions, microcopie, animations) | E0 (système) + chaque epic | P0+ |

## Epic List

- **E0** — Foundation & Bootstrap (P0, semaine 0-1)
- **E1** — Onboarding & Profil scolaire (P1, semaine 1) — *livré 2026-06-10*
- **E1bis** — Refonte intégrale du flow pré-dashboard (P1bis, intercalé semaine 1-2) — *ajouté 2026-06-11*
- **E2** — Navigation & Lecture contenu (P2, semaine 2)
- **E3** — Quiz & Pratique active Mode 1/2 (P3, semaine 3)
- **E4** — Freemium & Paiement Mobile Money (P4, semaine 4)
- **E5** — Santé scolaire & Gamification (P5, semaine 5)
- **E6** — Mode 3, Examen, Chat IA, Partage (P6, semaine 6)

## Epic 0 : Foundation & Bootstrap

**Phase MVP** : P0 (semaine 0 → début semaine 1)
**Objectif business** : Mettre en place la base technique sans laquelle aucun epic métier ne peut démarrer — projet Flutter clean architecture configuré, backend Firebase opérationnel, design system implémenté, patterns transverses (logging, idempotence, cache, i18n, sécurité) appliqués.
**Couverture** : SYS-001 à SYS-013 + NFR-1/2/3/6/7/12/14 + UX-DR-1 à UX-DR-22 + UX-DR-23 à UX-DR-32 (patterns globaux)
**Critère de sortie d'epic** : Une page « Hello Valide » bilingue FR/EN qui rend un texte + une formule LaTeX + un schéma Mermaid via `PedagogicalContent`, déployée en TestFlight/Play Internal avec logs Crashlytics actifs, App Check enforcé, et règles Firestore initiales validant un user document.

*Stories détaillées dans `epic-0-foundation/` (générées maintenant).*

## Epic 1 : Onboarding & Profil scolaire

**Phase MVP** : P1 (semaine 1)
**Objectif business** : L'élève camerounais arrive sur l'app et peut, en < 2 minutes, choisir son sous-système (francophone / anglophone), renseigner son profil scolaire (filière, niveau, série), optionnellement créer un compte ou rester visiteur, et atterrir sur un dashboard contextualisé avec ses matières filtrées.
**Couverture** : FR-1 à FR-8 + FR-10 + UX-DR-31 (i18n appliqué)
**Risque clé** : R4 (validation matrice MINESEC/GCE par un enseignant) — story dédiée d'audit.
**Critère de sortie d'epic** : Personas Fatou Mballa (Tle D francophone) et James Tanyi (Upper Sixth S2 anglophone) peuvent compléter le flow d'onboarding en < 2 minutes chacun et voir leur dashboard personnalisé avec leurs matières correctes.

*Stories détaillées dans `epics/epic-1-onboarding.md` (générées 2026-06-05, 10 stories de FR-1 à FR-8 + FR-10 + audit R4).*

## Epic 1bis : Refonte intégrale du flow pré-dashboard

**Phase MVP** : P1bis (intercalé semaine 1-2, après Epic 1 livré et avant démarrage Epic 2)
**Objectif business** : Reconstruire le parcours pré-dashboard (10 étapes consolidées : sub-system → hero → track → level → stream/subjects → auth → name → phone → school → success) pour aligner l'expérience sur les templates `doc/templates/`, améliorer le ratio texte / hiérarchie / espacement, inverser l'ordre Auth ↔ Onboarding (auth déclenchée seulement après le picker), réintroduire la capture du numéro de téléphone Cameroun, et homogénéiser les identifiers code en anglais (track / level / stream).
**Couverture** : FR-1 à FR-8 (refondus) + FR-NEW phoneNumber + UX-DR-31, UX-DR-32, UX-DR-39 (microcopie améliorée FR/EN)
**Risque clé** : R-E1bis-1 — divergence entre PRD existant et templates (FR-5 mode visiteur, FR-6 école optionnelle confirmée, ordre Auth/Onboarding inversé). À mitiger par `/bmad-prd Update` parallèle ou en amont de E1bis-2.
**Critère de sortie d'epic** : les 5 personas Epic 1 (Fatou, James, Aïssatou, Mariam, Eyong) peuvent compléter le nouveau flow 10 étapes en < 90 s sur Android entrée de gamme + iPhone SE + Pixel Tablet, avec tests goldens passant sur les 4 form factors (phone < 600 dp, phone landscape 600-840, tablet portrait + paysage ≥ 840). Identifiers code 100% anglais (zéro `filiereId` / `niveauId` / `serieId` dans le code de E1bis). Le step 9 success se déclenche avec confetti + audio `complete.m4a` + haptic `success` + auto-dispatch 3.5 s vers `/dashboard`.

*Stories détaillées dans `epics/epic-1bis-refonte-onboarding.md` (générées 2026-06-11, 10 stories E1bis-0 à E1bis-9 — cf. fichier dédié).*

## Epic 2 : Navigation & Lecture contenu

**Phase MVP** : P2 (semaine 2)
**Objectif business** : L'élève peut explorer ses matières en navigation hiérarchique (matière → chapitre → leçon → notion), filtrer/rechercher dans le contenu, lire un cours riche (Markdown + LaTeX + Mermaid) avec ouverture < 500 ms en cache, et accéder à ce contenu hors-ligne automatiquement.
**Couverture** : FR-9, FR-11, FR-12, FR-13, FR-14, FR-15 + NFR-15
**Risque clé** : R2 (mainteneur `flutter_smooth_markdown`) — la story de tests précoces sur 3 cours réels BAC/Probatoire/GCE est en E0.
**Critère de sortie d'epic** : Un cours de ~3000 mots avec 10 formules et 2 diagrammes Mermaid s'ouvre en < 2 s sur Android entrée de gamme (Tecno Spark 8 class) en cache, et reste lisible hors-ligne après première lecture.

*Stories à générer en début de P2 via `/bmad-create-story`.*

## Epic 3 : Quiz & Pratique active Mode 1/2

**Phase MVP** : P3 (semaine 3)
**Objectif business** : L'élève peut s'entraîner activement via des quiz IA générés sur une notion ou un chapitre, soumettre une réponse texte ou photo en Mode 1 (gratuit, débite 5 crédits) avec correction IA structurée par étapes, ou résoudre un exercice en Mode 2 (premium, étapes ordonnées + max 3 indices + accès cours associé), avec gestion robuste des coupures réseau.
**Couverture** : FR-16 à FR-19 + NFR-4 (compression photo) + NFR-8 (idempotence appliquée)
**Critère de sortie d'epic** : Fatou peut, en 3G fluctuante, faire un quiz de 5 questions sur « Dérivées » puis soumettre un Mode 1 photo d'un exercice ; la correction IA arrive en < 8 s, le solde de crédits est débité une seule fois même en cas de retry réseau.

*Stories à générer en début de P3 via `/bmad-create-story`.*

## Epic 4 : Freemium & Paiement Mobile Money

**Phase MVP** : P4 (semaine 4)
**Objectif business** : L'élève voit la comparaison gratuit/premium quand un verrou s'active, choisit un plan, paie en Mobile Money (MTN MoMo ou Orange Money) via WebView de l'agrégateur, et voit son accès premium s'activer automatiquement à la confirmation serveur. Il peut également acheter des packs de crédits avec bonus, consulter son historique de transactions, et annuler son abonnement avec maintien jusqu'à fin de période.
**Couverture** : FR-20 à FR-28 + NFR-8/9/10/11/13
**Risque clé** : R1 (choix agrégateur Tranzak / Campay / MyCoolPay) — bloquant pour P4, story dédiée d'évaluation à lancer dès J1 (en E0 ou parallèle).
**Critère de sortie d'epic** : Un parent à Yaoundé peut souscrire l'abonnement mensuel 2000 FCFA pour sa fille en < 60 s via Orange Money, et le verrou Mode 2 s'enlève en < 3 s après confirmation du webhook serveur.

*Stories à générer en début de P4 via `/bmad-create-story`.*

## Epic 5 : Santé scolaire & Gamification

**Phase MVP** : P5 (semaine 5)
**Objectif business** : Chaque exercice/quiz complété met à jour atomiquement la santé scolaire de la notion correspondante (étiquettes solide / à renforcer / priorité), le niveau et les points de l'élève. Le dashboard propose 3 recommandations équilibrées (règle 1/5 sur notion solide), affiche une mini-carte de rang avec évolution hebdomadaire, et l'élève peut consulter 5 classements (général, hebdo, matière, classe, école). Les notifications push + in-app informent des progrès avec plafonds anti-fatigue.
**Couverture** : FR-29 à FR-36
**Critère de sortie d'epic** : Après une semaine d'usage, Fatou voit sa santé évoluer notion par notion, reçoit ses 3 recos quotidiennes équilibrées sur son dashboard, peut grimper dans le classement hebdo de sa classe, et reçoit ≤ 3 notifications push/jour pertinentes.

*Stories à générer en début de P5 via `/bmad-create-story`.*

## Epic 6 : Mode 3, Examen, Chat IA, Partage

**Phase MVP** : P6 (semaine 6)
**Objectif business** : L'élève premium accède à 4 features avancées : Mode 3 (tuteur IA pas à pas avec 1 débit de 10 crédits par session), Mode Examen (composition complète chronométrée en conditions officielles avec corrigé par barème), Chat IA pédagogique (posture d'accompagnement, refuse de donner les réponses directes, quota 10 gratuit / 200 premium par jour), et création de liens de partage `valide.app/r/{linkId}` avec compteur d'ouvertures et désactivation.
**Couverture** : FR-37 à FR-44
**Critère de sortie d'epic** : Un élève peut composer un sujet de BAC blanc complet de 4h en mode examen avec autosave, recevoir un corrigé partie par partie avec mention, partager un cours avec un camarade via WhatsApp, et avoir une conversation Chat IA de 20 messages qui le guide sans jamais donner la réponse finale.

*Stories à générer en début de P6 via `/bmad-create-story`.*

---

## Stratégie « stories au fur à mesure »

Décision du 2026-06-03 : seul **Epic 0 (Foundation)** voit ses stories générées maintenant, car P0 démarre immédiatement. Les stories des Epics 1 à 6 seront générées **au début de leur phase respective** via la skill `/bmad-create-story` (qui prend une demande de story unique et la rédige avec contexte plein), ce qui permet :

- D'intégrer les apprentissages de la phase précédente (retro courte)
- D'ajuster aux décisions ouvertes résolues entre-temps (ex : choix agrégateur MoMo résolu avant P4)
- D'éviter de fixer trop tôt des stories qui pourraient être obsolètes au moment de leur implémentation

Les **goals d'epic ci-dessus sont stables** et serviront de contrat pour la génération de stories de la phase concernée.
