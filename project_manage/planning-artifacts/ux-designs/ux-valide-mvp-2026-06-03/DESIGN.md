---
name: Valide
status: final
created: 2026-06-03
updated: 2026-06-11
sources:
  - ../../../specs/spec-valide-mvp/SPEC.md
  - ../../prds/prd-valide-mvp-2026-06-03/prd.md
  - ../../../../doc/tech/Valide - Design System.html
  - ../../../../doc/tech/Valide - Design.html
  - ../../../../doc/templates/src/components/OnboardingFlow.tsx
  - ../../../../doc/templates/src/data/educationData.ts
  - ../../../../doc/templates/src/types.ts
  - ../../../../doc/tech/COMPOSANTS-REUTILISABLES.md
colors:
  primary: '#2563EB'
  primary-dark: '#1E3A8A'
  primary-light: '#DBEAFE'
  primary-soft: '#EFF6FF'
  primary-soft-border: '#BFDBFE'
  ink: '#0F172A'
  ink-soft: '#334155'
  muted: '#64748B'
  mute2: '#94A3B8'
  border: '#E2E8F0'
  bg: '#F8FAFC'
  card: '#FFFFFF'
  green: '#16A34A'
  green-soft: '#DCFCE7'
  green-ink: '#166534'
  amber: '#F59E0B'
  amber-soft: '#FEF3C7'
  amber-ink: '#92400E'
  red: '#DC2626'
  red-soft: '#FEE2E2'
  red-ink: '#991B1B'
  sky: '#0284C7'
  sky-soft: '#E0F2FE'
typography:
  font:
    family: 'Nunito Sans'
    fallback: 'Nunito, -apple-system, system-ui, sans-serif'
    weights: [400, 600, 700, 800, 900]
  mono:
    family: 'JetBrains Mono'
    fallback: 'ui-monospace, monospace'
  scale:
    display: { size: 46, weight: 900, line-height: 1.05, letter-spacing: '-0.04em' }
    h1: { size: 30, weight: 900, line-height: 1.15, letter-spacing: '-0.03em' }
    h2: { size: 22, weight: 800, line-height: 1.25, letter-spacing: '-0.02em' }
    h3: { size: 18, weight: 800, line-height: 1.3 }
    body: { size: 16, weight: 500, line-height: 1.5 }
    body-strong: { size: 16, weight: 700, line-height: 1.5 }
    meta: { size: 13, weight: 600, line-height: 1.4 }
    caption: { size: 12, weight: 700, line-height: 1.3 }
    eyebrow: { size: 11, weight: 800, line-height: 1.3, letter-spacing: '0.06em', case: 'uppercase' }
rounded:
  xs: 6px
  sm: 9px
  md: 11px
  lg: 14px
  xl: 16px
  '2xl': 18px
  pill: 999px
spacing:
  '1': 4px
  '2': 8px
  '3': 12px
  '4': 16px
  '5': 20px
  '6': 24px
  '8': 32px
  '10': 40px
  '12': 48px
  '16': 64px
elevation:
  shadow-soft: '0 4px 12px rgba(15,23,42,0.06)'
  shadow-mid: '0 8px 24px rgba(15,23,42,0.08)'
  shadow-brand: '0 6px 18px rgba(37,99,235,0.35)'
components:
  button:
    height: 52px
    padding-x: 20px
    radius: lg
    font-size: 16px
    font-weight: 700
    icon-gap: 8px
  button-compact:
    height: 40px
    padding-x: 14px
    radius: md
    font-size: 14px
    font-weight: 700
  input:
    height: 52px
    padding-x: 16px
    radius: lg
    font-size: 16px
    border: '1px solid {border}'
  card:
    padding: 24px
    radius: '2xl'
    shadow: shadow-soft
    border: '1px solid {border}'
  badge:
    padding-y: 4px
    padding-x: 10px
    radius: pill
    font-size: 12px
    font-weight: 700
  pill-tab-container:
    bg: '#F1F5F9'
    radius: lg
    padding: 4px
  pill-tab-item:
    height: 36px
    padding-x: 16px
    radius: md
    font-size: 13px
    font-weight: 700
  icon-cell:
    padding: '16px 8px'
    radius: lg
  inline-code:
    radius: xs
    padding: '2px 7px'
    font-size: 12.5px
    font-weight: 600
icons:
  set: 'Lucide (line icons, stroke-width 2)'
  default-size: 20px
  stroke-width: 2
breakpoints:
  mobile-min: 360px
  mobile-default: 393px
  mobile-tall: 412px
  mobile-large: 480px
---

> **Identité visuelle de Valide.** Source de vérité pour tout ce qui est `comment ça regarde`. Le comportement, les flux, les états et l'accessibilité vivent dans `EXPERIENCE.md` qui référence ces tokens par nom (syntaxe `{path.to.token}`). En cas de conflit avec un mock ou une maquette importée, **c'est ce fichier qui gagne**.

## Brand & Style

Valide est l'application mobile bilingue des élèves du secondaire camerounais. Le design est **moderne, clair, motivant** sans tomber dans le ludique infantilisant ni dans le froid corporate. **Mobile-first sans concession** : tout est pensé pour un Android d'entrée de gamme tenu à une main, dans un taxi-brousse, à la lumière du jour ou sous une ampoule à LED.

Quatre principes guident chaque décision visuelle :

1. **Simplicité.** Un écran = une intention principale. Pas de surcharge.
2. **Motivation.** Valoriser la progression et les efforts, encourager sans culpabiliser. Les étiquettes de santé scolaire (`solide`, `à renforcer`, `priorité`) sont conçues pour ne pas accabler — y compris `priorité` est une invitation à agir, pas un verdict.
3. **Clarté pédagogique.** L'élève sait toujours **où il est**, **quoi faire**, et **quelle est la prochaine action**.
4. **Accessibilité.** Lisible sur petits écrans Android. Texte ≥ 14 px, cibles tactiles ≥ 48 dp, contraste minimum WCAG AA. Aucun signal de couleur n'est utilisé seul (toujours doublé d'un texte ou d'une icône).

**Voix de marque visuelle :** chaleureuse (Nunito Sans), claire (palette bleu-blanc), confiante (graisses fortes pour les titres). On ne décore pas pour décorer.

## Colors

L'identité repose sur **le bleu et le blanc**. Le bleu (`{colors.primary}`) **guide l'action** — il signale ce qui est cliquable, ce qui se déclenche, ce qui valide. Il **ne remplit jamais** un écran entier (anti-pattern « océan de bleu » qui sature et démobilise).

### Palette marque

| Token | Hex | Usage |
|---|---|---|
| `{colors.primary}` | `#2563EB` | Action principale, liens, focus, surbrillance |
| `{colors.primary-dark}` | `#1E3A8A` | Hover/active de l'action principale, accents sur fond bleu clair |
| `{colors.primary-light}` | `#DBEAFE` | Fonds de progress bar, badges info |
| `{colors.primary-soft}` | `#EFF6FF` | Fonds de chip discrète, pill-tab active container |
| `{colors.primary-soft-border}` | `#BFDBFE` | Bordure de chip et bouton secondaire |

### Neutres

| Token | Hex | Usage |
|---|---|---|
| `{colors.ink}` | `#0F172A` | Texte principal, titres |
| `{colors.ink-soft}` | `#334155` | Texte de corps secondaire |
| `{colors.muted}` | `#64748B` | Légendes, métadonnées |
| `{colors.mute2}` | `#94A3B8` | Texte tertiaire, placeholders |
| `{colors.border}` | `#E2E8F0` | Bordures de cartes, séparateurs |
| `{colors.bg}` | `#F8FAFC` | Fond d'écran |
| `{colors.card}` | `#FFFFFF` | Fond de carte |

### États (palette sémantique)

Chaque état utilise un trio `couleur / soft / ink` pour les fonds clairs et les variantes texte.

| État | `couleur` | `soft` | `ink` | Usage |
|---|---|---|---|---|
| Succès | `#16A34A` | `#DCFCE7` | `#166534` | Réussite quiz, paiement validé, étiquette `solide` |
| Attention | `#F59E0B` | `#FEF3C7` | `#92400E` | Étiquette `à renforcer`, solde crédits faible |
| Erreur | `#DC2626` | `#FEE2E2` | `#991B1B` | Étiquette `priorité`, échec réseau, suppression |
| Information | `#0284C7` | `#E0F2FE` | — | Notifications neutres, conseils |

**Règle stricte :** la couleur seule **n'est jamais** un signal. Tout état est doublé d'un **texte explicite** (« Solide », « À renforcer », « Priorité ») et d'une **icône optionnelle**. Un élève daltonien doit pouvoir distinguer les états sans nuancer les bleus-rouges.

### Contraste

Tous les pairings texte / fond satisfont **WCAG AA** (4.5:1 pour le corps, 3:1 pour le texte ≥ 18 px). Le pairing `{colors.muted}` sur `{colors.bg}` est validé pour des tailles ≥ 14 px uniquement.

## Typography

**Famille principale** : Nunito Sans (Google Fonts) — sans-serif chaude, ronde, très lisible sur petits écrans. Plus humaine qu'Inter, mieux adaptée à un produit éducatif pour adolescents. **Famille code/data** : JetBrains Mono pour le code inline et les valeurs numériques alignées.

### Graisses utilisées

- **400 Regular** — corps long (très rare en mobile)
- **600 SemiBold** — corps standard, métadonnées
- **700 Bold** — boutons, labels d'action, badges
- **800 ExtraBold** — sous-titres, sections, eyebrow
- **900 Black** — display, h1 hero

### Échelle

| Style | Taille | Graisse | Usage |
|---|---|---|---|
| `{typography.scale.display}` | 46 px | 900 | Hero d'onboarding, écrans de célébration (mention obtenue, montée de niveau) |
| `{typography.scale.h1}` | 30 px | 900 | Titre principal d'écran (« Mes matières », « Santé scolaire ») |
| `{typography.scale.h2}` | 22 px | 800 | Titre de section dans un écran |
| `{typography.scale.h3}` | 18 px | 800 | Titre de carte, titre de chapitre |
| `{typography.scale.body-strong}` | 16 px | 700 | Corps mis en avant, étiquette de progression |
| `{typography.scale.body}` | 16 px | 500 | Corps standard, énoncé d'exercice |
| `{typography.scale.meta}` | 13 px | 600 | Métadonnées, durées, contextes |
| `{typography.scale.caption}` | 12 px | 700 | Badges, légendes de tableaux |
| `{typography.scale.eyebrow}` | 11 px | 800 (uppercase, letter-spacing) | Sur-titres de section (« CHAPITRE 02 ») |

### Règles

- Texte principal : `{colors.ink}` sur `{colors.bg}` ou `{colors.card}`.
- Hauteur de ligne respectée à 1.5 pour le corps, 1.05-1.25 pour les titres.
- **Pas de all-caps** au-delà de l'eyebrow (fatigue de lecture).
- Le rendu des formules **LaTeX** et des schémas **Mermaid** se fait via le composant `PedagogicalContent` (rendu typographique géré par `flutter_smooth_markdown`, hors scope de ce DS).

## Layout & Spacing

**Grille de base : 4 px.** L'échelle progresse en 4 / 8 / 12 / 16 / 20 / 24 / 32 / 40 / 48 / 64.

Tokens : voir `{spacing}` en frontmatter.

### Marges d'écran

- **Horizontal** : `{spacing.4}` (16 px) — la marge standard mobile. Augmenté à `{spacing.5}` (20 px) sur écrans ≥ 412 px de large.
- **Vertical** : `{spacing.4}` à `{spacing.6}` (16-24 px) entre blocs majeurs ; `{spacing.3}` (12 px) entre éléments connexes ; `{spacing.2}` (8 px) à l'intérieur d'un même groupe (icône + texte).

### Rythme vertical

- Hero d'écran → premier bloc : `{spacing.6}` (24 px)
- Entre cartes consécutives : `{spacing.3}` (12 px)
- Entre items d'une liste : pas d'écart visible (les cartes ou les séparateurs hairline portent la séparation)
- Bottom safe area : `{spacing.6}` minimum + safe area système

### Grille de contenu

Layout **mono-colonne** systématique sur phone portrait (< 600 dp). Pas de grilles 2 colonnes sauf cas explicites : icon grid (matières) et grid-3 (graisses, badges principaux).

### Layout tablette (≥ 840 dp) — MAJ 2026-06-04 (ADR-011)

> Comportements responsives détaillés dans EXPERIENCE.md § Responsive & Platform.

- **Largeur de lecture** : tout contenu textuel (cours, énoncé, chat) reste dans une **colonne max 600 dp** centrée — au-delà, la lisibilité tombe.
- **Grilles** : matières en **5-6 colonnes** sur tablette (contre 3 sur phone), notifications/classements/historique **2-colonnes (master-detail)** si la largeur le permet.
- **Marges** : `{spacing.6}` (24 px) à `{spacing.7}` (32 px) sur tablette au lieu de `{spacing.4}` (16 px) phone.
- **Bottom tabs vs NavigationRail** : portrait tablette = bottom tabs ; paysage tablette = NavigationRail à gauche.
- **Split-view** : autorisé sur écran cours+sommaire (paysage tablette uniquement). Largeur sommaire fixe 300 dp, contenu prend le reste (max 600 dp utiles + marges).
- **Pas de hero qui prend toute la largeur** : sur tablette, les héros (mini-carte rang, paywall hero) gardent une largeur max 600 dp centrée.

### Surfaces

- `{colors.bg}` (gris très clair) pour le fond d'écran
- `{colors.card}` (blanc) pour les surfaces remontées (cartes, modales)
- La hiérarchie passe par **layout et typographie**, **jamais** par contraste de fond agressif

## Elevation & Depth

Trois niveaux d'élévation, utilisés avec parcimonie :

- `{elevation.shadow-soft}` — cartes standard sur fond `{colors.bg}`. Effet « papier posé ».
- `{elevation.shadow-mid}` — modales, sheets remontées, cards de paywall. Effet « surface mise en avant ».
- `{elevation.shadow-brand}` — exclusivement sur le logo et les éléments de célébration (mention obtenue, montée de niveau). Couleur bleue (`rgba(37,99,235,0.35)`) qui signe la marque.

**Pas d'élévation pour la hiérarchie courante** — la hiérarchie vient du layout (espacement, alignement) et de la typo (graisse, taille). L'élévation est un effet réservé.

## Shapes

Arrondis généreux, modernes, jamais carrés. Tokens : voir `{rounded}` en frontmatter.

| Token | Valeur | Usage |
|---|---|---|
| `{rounded.xs}` | 6 px | Code inline, séparateurs de progression |
| `{rounded.sm}` | 9 px | Nav items, petits éléments |
| `{rounded.md}` | 11 px | Pill-tab actif, pic d'icône principe |
| `{rounded.lg}` | 14 px | Boutons, inputs, icon cells, pill-tab container |
| `{rounded.xl}` | 16 px | Petites cartes, shadow boxes |
| `{rounded.2xl}` | 18 px | Cartes standard |
| `{rounded.pill}` | 999 px | Chips, badges, FAB |

**Règle :** ne pas mélanger 4 rayons différents sur le même écran. Privilégier `{rounded.lg}` (14 px) pour les actions et `{rounded.2xl}` (18 px) pour les containers — cette paire couvre 80 % des cas.

Les images suivent le rayon de leur container — aucune image carrée à coin vif.

## Components

Spec **visuelle** des composants. La spec **comportementale** (interactions, états dynamiques, accessibilité) vit dans `EXPERIENCE.md.Component Patterns`.

### Boutons

#### Bouton primaire — `btn-primary`

- Hauteur : `52 px` (cible tactile confortable, dépasse les 48 dp Android requis)
- Padding horizontal : `{spacing.5}` (20 px)
- Background : `{colors.primary}`, texte `{colors.card}`
- Radius : `{rounded.lg}` (14 px)
- Font : `{typography.scale.body-strong}` (16 px, weight 700)
- Icône optionnelle à gauche du texte, espacée de 8 px

#### Bouton secondaire — `btn-secondary`

- Mêmes dimensions
- Background : `{colors.primary-soft}`, texte `{colors.primary}`, bordure 1 px `{colors.primary-soft-border}`

#### Bouton outline — `btn-outline`

- Mêmes dimensions
- Background : `transparent`, texte `{colors.ink}`, bordure 1 px `#CBD5E1`

#### Bouton danger — `btn-danger`

- Mêmes dimensions
- Background : `{colors.red-soft}`, texte `{colors.red}`. Utilisé sur les confirmations destructrices uniquement.

#### Bouton compact

- Hauteur : `40 px`, radius `{rounded.md}` (11 px), font 14 px / weight 700. Pour les actions secondaires en barre d'outils ou bouton « voir plus ».

### Badges

- Padding : `4 px 10 px`
- Radius : `{rounded.pill}` (999 px)
- Font : `{typography.scale.caption}` (12 px weight 700)
- Avec un dot coloré 6 px optionnel à gauche
- Couleurs : utiliser un trio sémantique (background `{state}-soft`, texte `{state}-ink`, dot `{state}`)

### Cartes

- Background : `{colors.card}`
- Padding : `{spacing.6}` (24 px)
- Radius : `{rounded.2xl}` (18 px)
- Bordure : 1 px `{colors.border}`
- Ombre : `{elevation.shadow-soft}`

### Champs de saisie

- Hauteur : `52 px`
- Padding horizontal : `{spacing.4}` (16 px)
- Radius : `{rounded.lg}` (14 px)
- Bordure : 1 px `{colors.border}` (focus : 2 px `{colors.primary}`)
- Font : `{typography.scale.body}` (16 px). Placeholder en `{colors.mute2}`.

### Pill tabs (sélecteur segmenté)

- Container : background `#F1F5F9`, radius `{rounded.lg}` (14 px), padding 4 px
- Item actif : background `{colors.card}`, texte `{colors.primary}`, ombre légère
- Item inactif : background transparent, texte `{colors.muted}`
- Item : hauteur 36 px, padding horizontal `{spacing.4}` (16 px), radius `{rounded.md}` (11 px), font 13 px weight 700

### Icônes (grille de matières)

- Cell : background `{colors.card}`, bordure 1 px `{colors.border}`, radius `{rounded.lg}` (14 px), padding `16px 8px`
- Layout : grid auto-fill, minmax `96px 1fr`, gap `{spacing.3}` (10 px)
- Label : `{typography.scale.caption}` (11 px), couleur `{colors.muted}`
- Bibliothèque d'icônes : **Lucide** (line icons, stroke-width 2, taille par défaut 20 px)

### Progression

- Barre horizontale 8 px de haut, radius `{rounded.xs}` (6 px sur conteneur, fill arrondi)
- Fond : `{colors.primary-light}`, fill : `{colors.primary}` (ou `{state}-couleur` selon contexte santé scolaire)
- Texte associé : `{typography.scale.caption}` (12 px), à droite ou en-dessous

### Encadrés (info / warning / error)

- Background : `{state}-soft`
- Bordure gauche : 4 px solide `{state}-couleur`
- Padding : `{spacing.4}` (16 px)
- Radius : `{rounded.lg}` (14 px)
- Texte : `{state}-ink`, taille body

### Toasts

- Position : top, slide-in depuis le haut, 4 secondes d'affichage
- Dimensions : pleine largeur moins marges écran, hauteur auto
- Background : `{colors.ink}` (sombre, pour contraste sur tout fond), texte `{colors.card}`
- Radius : `{rounded.lg}` (14 px), padding `12px 16px`
- Icône d'état à gauche (succès / erreur / info), bouton fermer optionnel à droite

### Modales

- Background : `{colors.card}`, radius `{rounded.2xl}` (18 px)
- Padding : `{spacing.6}` (24 px)
- Ombre : `{elevation.shadow-mid}`
- Overlay : `rgba(15,23,42,0.5)`
- Largeur : `min(420px, calc(100vw - 32px))`
- Boutons d'action : alignés horizontalement en bas, primaire à droite, secondaire/cancel à gauche

### Bottom sheets

- Background : `{colors.card}`, radius haut `{rounded.2xl}` (18 px), bas 0
- Handle : barre 36 × 4 px, `{colors.mute2}`, centrée en haut
- Slide-up animation depuis le bas
- Padding : `{spacing.6}` (24 px), avec safe area bottom

### États vides

- Illustration ou icône Lucide 64 px en `{colors.mute2}` au centre
- Titre `{typography.scale.h3}` (18 px / 800), couleur `{colors.ink-soft}`
- Corps `{typography.scale.body}` (16 px / 500), couleur `{colors.muted}`
- CTA optionnel en bouton secondaire en-dessous

### Chargement (skeleton)

- Background : gradient animé `linear-gradient(90deg, #EEF1F5 25%, #E2E8F0 37%, #EEF1F5 63%)` à 400 % de largeur
- Animation `shimmer` 1.4 s ease infinite
- Radius : suit le composant qu'il représente

### Spinner

- 18 × 18 px (ou 24 px pour overlay)
- Border 3 px, top-color `{colors.card}` sur fond `{colors.primary}` (rotation 0.7 s linéaire)
- Réservé aux actions brèves (< 3 s perçues). Au-delà, basculer en skeleton.

### Composants Onboarding (refonte 2026-06-11 — templates `doc/templates/`)

> Composants spécifiques au flow d'onboarding 10 étapes. Spec comportementale dans `EXPERIENCE.md.Component Patterns` + `EXPERIENCE.md.Flow 1`. Cf. `.decision-log.md` D-UX-Update-20.

#### CTA footer gradient

- Position : `position: absolute`, `bottom: 0`, `inset-x: 0`
- Padding : `{spacing.5}` (20 px) avec safe area bottom
- Background : `linear-gradient(to top, {colors.bg} 0%, {colors.bg} 70%, transparent 100%)` sur ≈ 80 px de hauteur visible
- Bouton intérieur : `btn-primary` plein largeur (cf. `{components.button}`), `max-width: 600 dp` centré
- Step 9 success : `btn-primary` mais background = `{colors.success}` + ombre `0 8px 20px rgba(22,163,74,0.25)`
- Pointer-events : conteneur `none`, bouton `auto` (laisse passer les taps sur contenu derrière le gradient)
- Z-index : 40

#### SubSystem hero card (sélecteur sub-system)

- Carte plein largeur (≤ `max-width: 600 dp` tablette)
- Padding : `{spacing.4}` à `{spacing.5}` (16-20 px)
- Background : `{colors.card}` ; selected → `{colors.primary-soft}`
- Bordure : 1 px `{colors.border}/0.5` ; selected → ring 2 px `{colors.primary}` + bordure transparente
- Radius : `{rounded.2xl}` (18 px)
- Ombre : `{elevation.shadow-soft}` ; selected → `0 10px 30px rgba(37,99,235,0.15)` + `scale(1.01)`
- Icône optionnelle 48×48 dans un cercle `{rounded.2xl}` à gauche (background `{colors.bg}` text `{colors.ink-soft}` ; selected → `{colors.primary}` text `{colors.card}` + ombre `{elevation.brand}`)
- Titre : `{typography.scale.body-strong}` (17 px / 900) → `{colors.ink}` ; selected → `{colors.primary}`
- Desc optionnel : `{typography.scale.caption}` (12 px / 600) → `{colors.ink-soft}`
- Indicateur radio 24×24 à droite (cercle bordé 2 px `{colors.border}/0.5` ; selected → background `{colors.primary}` + checkmark 14×14 blanc strokeWidth 3)
- Tap : haptic `selection` + bg transition 200 ms standardOut

#### Phone input with country flag

- Hauteur : 56 px (un peu plus haut que `{components.input}` standard pour accommoder le drapeau)
- Padding gauche : 95 px (réservé drapeau + indicatif fixe)
- Drapeau SVG Cameroun 20×14 px (3 bandes verticales vert/rouge/jaune + étoile jaune centrée bande rouge), positionné absolute left 16 px top 17 px, radius 2 px overflow hidden
- Indicatif `+237` à droite du drapeau : `{typography.scale.body-strong}` (16 px / 700) `{colors.ink}` + bordure droite 1 px `{colors.border}/0.8` + padding right 8 px
- Champ input : type `tel`, mask `6 XX XX XX XX`, `{typography.scale.body-strong}` (17 px / 700), placeholder `{colors.mute2}` « 6 -- -- -- -- »
- Background : `{colors.card}`, radius `{rounded.2xl}` (16-18 px), ombre `0 4px 20px rgba(15,23,42,0.04)`
- Focus : ring 2 px `{colors.primary}`
- État disabled : opacity 0.5

#### School search with add

- Champ recherche : hauteur 60 px, padding left 56 px (icône Search 22 px), padding right 48 px (bouton clear XCircle 22 px)
- Background : `{colors.card}`, radius `{rounded.2xl}`, ombre `0 8px 30px rgba(15,23,42,0.06)`, focus ring 2 px `{colors.primary}`
- Suggestions liste : cartes `SelectionCard` (cf. composant ci-dessous), gap `{spacing.4}` (16 px)
- Carte « + Ajouter "<saisie>" » : padding `{spacing.5}` (20 px), radius `{rounded.2xl}` (20 px), border-dashed 2 px `{colors.primary}/0.5`, bg `{colors.primary-soft}`, texte `{colors.primary}` `{typography.scale.body-strong}` (17 px / 700), icône `Plus` 20 px à droite. Hover/tap → bg `{colors.primary-light}`

#### Selection card (générique — pickers, séries, écoles, sous-système, track)

- Standard : padding `{spacing.4}` ou `{spacing.5}` (16-20 px), radius `{rounded.2xl}` (16-18 px)
- Compact : padding `{spacing.3}` (12 px), radius `{rounded.xl}` (14-16 px)
- Background : `{colors.card}`, bordure 1 px `{colors.border}/0.5`
- Ombre : `{elevation.shadow-soft}`
- Selected : bg `{colors.primary-soft}`, ring 2 px `{colors.primary}`, scale 1.01, ombre `0 10px 30px rgba(37,99,235,0.15)`
- Icône optionnelle gauche 48×48 (compact 40×40) cercle radius `{rounded.2xl}` ; bg `{colors.bg}` text `{colors.ink-soft}` ; selected → bg `{colors.primary}` text `{colors.card}` + ombre `{elevation.brand}`
- Titre : `{typography.scale.body-strong}` 17 px / 900 ink ; selected → primary
- Desc optionnelle : 12 px / 600 ink-soft ; selected → primary-dark/0.8
- Radio indicateur droit : 24×24 (compact 20×20) cercle bordé 2 px `{colors.border}/0.5` ; selected → bg primary + checkmark blanc 14×14 strokeWidth 3
- Tap area : la totalité de la carte. Tap → haptic `selection` 30 ms.

#### Picker counter badge (sticky)

- Position : sticky top dans le scroll body, gap 16 px sous le header
- Padding : `{spacing.3}` à `{spacing.4}` (12-16 px)
- Background : `{colors.warning-soft}` (compteur sous min) OU `{colors.success-soft}` (compteur valide)
- Bordure : 1 px transparente
- Radius : `{rounded.lg}` (14 px)
- Ombre : `{elevation.shadow-soft}`
- Layout flex justify-between :
  - Label gauche : `{typography.scale.caption}` (13 px / 800 uppercase tracking-wider) — couleur `{colors.warning-ink}` ou `{colors.success-ink}`
  - Badge droit : padding `8x4 px`, radius `{rounded.md}`, bg `{colors.card}/0.5`, font `{typography.scale.caption}` (12 px / 900) « 8 / Min 6 » ou « 8 / Max 11 ✓ »

#### Celebration confetti success

- Plein écran (h-full + w-full + overflow-hidden)
- Background : `{colors.bg}`
- Canvas confetti absolute inset-0 z-0 pointer-events-none, particules 4 par frame ×2 origines (left/right), couleurs `#2563EB / #16A34A / #D97706 / #0EA5E9`, durée 2.5 s
- Cercle central success 128×128 :
  - background `{colors.success-soft}`
  - radius full (50%)
  - ombre `0 0 60px rgba(22,163,74,0.3)` (halo glow)
  - Checkmark central 64×64 `{colors.success}` strokeWidth 3
  - Animation entrée : spring damping 15 stiffness 200 delay 100 ms (scale 0→1, opacity 0→1)
- 3 micro-icônes orbitantes (24-28 px) :
  - PartyPopper top-left-2 -top-4 : `{colors.warning-ink}`, anim y[0,-20,0] opacity[1,0,1] loop 2 s
  - Sparkles -bottom-2 -right-4 : `{colors.primary}`, anim y[0,20,0] opacity[1,0,1] loop 2.2 s
  - CheckCircle2 top-8 -right-6 : `{colors.sky}`, anim x[0,20,0] loop 1.8 s
- Titre H2 : delay 300 ms anim y[20→0] opacity[0→1] duration 400 ms
- Sous-titre body : delay 400 ms idem
- Coupures globales : si `MediaQuery.disableAnimations` → pas de confetti + pas de spring → fade-in 200 ms statique + checkmark sans animation. Si silencieux → pas de son `complete.m4a`.

#### Progress header bar (onboarding)

- Position : sticky top, z-40, padding `{spacing.4}` (16 px) + padding top 24 px safe area
- Background : `{colors.bg}`, bordure basse 1 px `{colors.border}/0.5`, ombre légère `0 1px 2px rgba(0,0,0,0.04)`
- Layout flex gap 16 px max-width 600 dp centré
- Back button : 44×44 cercle `{colors.card}/0.5` hover `{colors.card}`, icône ArrowLeft 20 px `{colors.ink}`, ombre `{elevation.shadow-soft}`
- Barre progression : flex-1 hauteur 12 px, bg `{colors.card}` ombre intérieure, radius full, fill `{colors.primary}` transition all 500 ms ease-out
- Compteur droite : `{typography.scale.caption}` (14 px / 700) `{colors.ink-soft}` « 2/3 »

### Animations & motion

**Posture motion** : *Micro-interactions partout, transitions sobres*. Tout élément interactif réagit visuellement au tap ; chaque changement d'état est animé ; les transitions inter-écrans restent standard pour ne pas alourdir le perçu sur téléphones modestes.

**Cible perf** : 60 fps sur Android Go (entrée de gamme). Si on ne peut pas tenir 60 fps sur un animation, on simplifie ou on bascule en statique.

#### Motion tokens (à implémenter en Story 0.10)

| Token | Valeur | Usage |
|---|---|---|
| `motion.duration.instant` | 0 ms | Désactivation animations (système ou flag premium dégradé) |
| `motion.duration.fast` | 120 ms | Changements d'état atomiques (pressed → released, focus, switch toggle) |
| `motion.duration.standard` | 200 ms | Transitions composants (sheet slide, fade-in modale, page transition standard) |
| `motion.duration.emphasis` | 300 ms | Entrée d'un écran clé, ouverture overlay important |
| `motion.duration.celebration` | 400-700 ms | Célébrations (badge gagné, level up, paiement réussi, bonne réponse Mode 1) |
| `motion.easing.standardOut` | `Curves.easeOut` | Entrées d'éléments |
| `motion.easing.standardIn` | `Curves.easeIn` | Sorties d'éléments |
| `motion.easing.emphasized` | `Curves.easeOutCubic` | Célébrations, hero |
| `motion.stagger` | 50 ms | Délai inter-élément dans une liste qui fade-in |

#### Catalogue d'animations Valide School

| Pattern | Quand | Durée | Note |
|---|---|---|---|
| **Tap feedback** | Tap sur n'importe quel élément interactif | `fast` (120 ms) | Scale 0.96 → 1.0 + opacity 0.7 → 1.0. Implémenté au niveau atom (Story 0.13) |
| **Fade-in stagger** | Apparition d'une liste (matières, notifications, classements) | `standard` + `stagger` | Max 8 premiers items animés, le reste apparaît instantanément (perf) |
| **Slide page** | Navigation `go_router` standard | `standard` | Slide horizontal (push) ou bottom-up (modal route) |
| **Sheet bottom slide** | Ouverture bottom sheet | `standard` | Avec backdrop fade-in en parallèle |
| **Snackbar / Toast slide-up** | Feedback léger | `standard` | Disparaît après 3 s |
| **Skeleton shimmer** | Chargement contenu | continu | Cycle 1.5 s. Désactivé si `MediaQuery.disableAnimations` |
| **Spinner rotation** | Action brève < 3 s | continu | 0.7 s/tour linéaire |
| **Success checkmark** | Bonne réponse Mode 1/2/3, paiement OK, soumission OK | `emphasis` | Draw du checkmark + bounce léger. Couplé à `haptic.success` + son `success` |
| **Error shake** | Mauvaise réponse, validation form échouée | `fast` ×3 | Shake horizontal léger. Couplé à `haptic.error` + son `error` |
| **Level-up bloom** | Montée de niveau santé scolaire, badge gagné | `celebration` | Burst de cercles + scale + fade. Couplé à `haptic.heavy` + son `levelup` |
| **Progress bar fill** | Avancement quiz, progression chapitre | `emphasis` | Anim de 0 → valeur cible. Texte synchronisé |
| **Pill tabs switch** | Changement de section | `fast` | Indicator slide entre les pills |
| **Cursor blink** | Champ saisie focus | continu | Standard plateforme |

#### Respect du système

- **`MediaQuery.disableAnimations`** (Android « Désactiver les animations » dans dev options ou prefer-reduced-motion) : on fallback sur des transitions instantanées pour shimmer, level-up bloom, fade-in stagger ; on garde tap feedback et page transition courte (120 ms).
- **Mode économie batterie Android** : on désactive automatiquement les animations continues décoratives (shimmer reste, mais on accepte qu'il soit moins prioritaire CPU).
- **Cold start** : pas de hero animation > 400 ms au démarrage (perçu lent).

#### Package retenu

- **`flutter_animate`** pour les patterns custom (success checkmark, error shake, level-up bloom, stagger). Évite de réécrire les `AnimationController`.
- **Implicit widgets natifs** (`AnimatedContainer`, `AnimatedOpacity`, `AnimatedSwitcher`, `AnimatedAlign`) pour les micro-interactions atomiques.
- Pas de **Lottie** en V1 (perf + taille APK).

---

### Audio (sons d'interaction)

> **MAJ 2026-06-04 (ADR-011)** : V1 cross-platform Android + iOS. Format audio passé OGG → **AAC/M4A** (OGG non supporté nativement iOS).

**Posture audio** : *Standard — 8 à 12 sons clés, total ≤ 500 KB embarqués dans le bundle*. Aucun son streamé (data + latence). Chaque son est court (0.2-1 s), en **AAC/M4A basse qualité (mono, 22 kHz, ~32-64 kbps)** — supporté nativement Android et iOS sans transcoding runtime.

**Respect utilisateur** :
- Sons soumis au volume **média** du système (pas notification, pas alarme).
- Setting global « Sons activés » dans Profil (par défaut ON), persisté en `SharedPreferences`.
- **Sons coupés automatiquement** si le téléphone est en mode silencieux (`SystemSoundType` détecté via `package:vibration` ou via le ringer mode Android).
- **Sons coupés en Mode Examen** (FR-24+) : ambiance neutre obligatoire.

#### Catalogue Valide School (à implémenter en Story 0.14)

| Son | Quand | Durée | Asset cible |
|---|---|---|---|
| `tap` | Tap sur bouton primaire uniquement (pas tous les éléments — fatigue) | 80 ms | `assets/audio/tap.m4a` ≤ 8 KB |
| `success_soft` | Bonne réponse Mode 1 standard | 350 ms | ≤ 30 KB |
| `success_strong` | Bonne réponse Mode 2 (semi-assisté, plus rare) | 500 ms | ≤ 50 KB |
| `error_soft` | Mauvaise réponse Mode 1 | 250 ms | ≤ 25 KB |
| `error_strong` | Form validation échouée, action bloquée (paywall hit) | 350 ms | ≤ 35 KB |
| `complete` | Quiz terminé, leçon finie | 700 ms | ≤ 60 KB |
| `levelup` | Montée de niveau santé scolaire, palier franchi | 900 ms | ≤ 80 KB |
| `badge` | Badge gagné | 800 ms | ≤ 70 KB |
| `payment_ok` | Paiement Mobile Money réussi | 700 ms | ≤ 60 KB |
| `notification` | Notification in-app reçue (différent du son push système) | 500 ms | ≤ 45 KB |
| `streak` | Streak maintenu (discret, non culpabilisant) | 400 ms | ≤ 35 KB |
| `chat_send` | Message envoyé au Chat IA | 150 ms | ≤ 15 KB |

**Budget total cible** : ≤ 500 KB. Si dépassement, on supprime `tap`, `streak`, `chat_send` (les moins essentiels) avant les autres.

#### Package audio retenu

- **`audioplayers`** (cross-platform Android + iOS). `soundpool` est **éliminé** car Android-only (cf. NFR-16 / ADR-011).
- Recommandation : utiliser un pool de `AudioPlayer` réutilisables (1 par catégorie : `tap`, `success`, `error`, `notification`, …) plutôt qu'un `AudioPlayer` par appel — évite les fuites de ressources et l'overhead de création.

---

### Haptics (vibrations)

> **MAJ 2026-06-04 (ADR-011)** : cross-platform. API Flutter `HapticFeedback.*` couvre Android (via `vibrator`) ET iOS (via Taptic Engine). Mapping ci-dessous garantit une expérience cohérente sur les deux plateformes (intensité ressentie peut varier légèrement — c'est attendu).

**Posture haptic** : *Discret mais présent*. Chaque confirmation positive ou négative significative déclenche un haptic. Les micro-interactions de navigation n'en ont pas (fatigue).

**Respect utilisateur** :
- Setting global « Vibrations activées » dans Profil (par défaut ON), persisté en `SharedPreferences`.
- **Pas de haptic en Mode Examen**.
- **Pas de haptic si batterie < 15 %** (mode économie).
- Utilise l'API Flutter native `HapticFeedback.*` (gratuit en perms Android, pas besoin de `<uses-permission android:name="android.permission.VIBRATE"/>` au-delà de ce que Flutter déclare déjà).

#### Catalogue Valide School (à implémenter en Story 0.14)

| Haptic | Quand | API Flutter | Mapping iOS (Taptic) | Mapping Android (vibrator) |
|---|---|---|---|---|
| `selection` | Switch toggle, pill tab change, sélection radio | `HapticFeedback.selectionClick()` | `UISelectionFeedbackGenerator` | vibration ~10 ms |
| `light` | Tap sur bouton primaire, validation Mode 1/2/3 | `HapticFeedback.lightImpact()` | `UIImpactFeedbackGenerator(.light)` | vibration ~20 ms |
| `medium` | Bonne réponse, action confirmée (soumission quiz, envoi message) | `HapticFeedback.mediumImpact()` | `UIImpactFeedbackGenerator(.medium)` | vibration ~40 ms |
| `heavy` | Mauvaise réponse, validation form échouée, paywall hit, level up | `HapticFeedback.heavyImpact()` | `UIImpactFeedbackGenerator(.heavy)` | vibration ~80 ms |
| `success` (séquence) | Paiement réussi, badge gagné | `medium` + delay 100 ms + `light` | enchaînement Taptic | enchaînement vibrator |
| `error` (séquence) | Erreur réseau bloquante | `heavy` + delay 80 ms + `heavy` | enchaînement Taptic | enchaînement vibrator |

> L'intensité **ressentie** peut varier entre Android (vibrator linéaire) et iOS (Taptic Engine plus précis et tactile). C'est attendu — on accepte cette variation de qualité haptique, l'important est la **présence** et la **sémantique** (positive/négative).

**Bannis** :

- Pas de vibration continue > 500 ms (épuise batterie, mauvaise UX perçue).
- Pas de pattern complexe custom (utiliser uniquement les presets Flutter).

#### Package haptic retenu

- **API Flutter native uniquement** (`flutter/services` → `HapticFeedback`). Pas de dépendance externe.

---

## Do's and Don'ts

| Do | Don't |
|---|---|
| Mono-colonne systématique | Grilles 2 colonnes pour densifier |
| Bouton primaire = action principale unique par écran | Plusieurs boutons primaires concurrents |
| Couleur d'état toujours doublée d'un texte explicite | Couleur seule comme signal (vert = ok, rouge = ko) |
| Icônes Lucide line stroke 2 px | Mélange d'icônes filled et line, plusieurs stroke widths |
| Radius `{rounded.lg}` pour actions, `{rounded.2xl}` pour cartes | Multiplier 4 rayons différents par écran |
| Élévation réservée aux modales/sheets/célébrations | Élévation pour hiérarchier les cartes courantes |
| Marges respiratoires généreuses (16/24 px) | Compresser pour faire tenir plus à l'écran |
| Tutoiement direct en français, équivalent EN | Vouvoiement froid, ton corporate |
| Étiquettes positives : « priorité » plutôt que « faible » | Lexique culpabilisant (« mauvais », « insuffisant ») |
| Boutons ≥ 48 dp (52 px par défaut) | Cibles tactiles < 44 pt iOS / 48 dp Android |
| Texte ≥ 14 px en utile, ≥ 16 px en corps | Texte < 12 px hors caption isolée |
| Indicateurs de progression visibles pour toute opération > 200 ms | Délais sans feedback |

---

> Pour le comportement des composants, les flux utilisateur, les états et les règles d'accessibilité, voir [`EXPERIENCE.md`](EXPERIENCE.md). En cas de conflit entre ce DESIGN.md et un mock importé dans `imports/`, **DESIGN.md prime**.
