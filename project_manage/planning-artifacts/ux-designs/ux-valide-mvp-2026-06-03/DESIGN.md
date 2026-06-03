---
name: Valide
status: draft
created: 2026-06-03
updated: 2026-06-03
sources:
  - ../../../specs/spec-valide-mvp/SPEC.md
  - ../../prds/prd-valide-mvp-2026-06-03/prd.md
  - ../../../../doc/tech/Valide - Design System.html
  - ../../../../doc/tech/Valide - Design.html
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

Layout **mono-colonne** systématique. Pas de grilles 2 colonnes sauf cas explicites : icon grid (matières) et grid-3 (graisses, badges principaux).

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

### Animations & motion

- **Durées** : 120 ms (changements d'état rapide, hover), 200 ms (transitions standard, sheet slide), 400-700 ms (célébrations).
- **Easing** : standard `ease-out` pour les entrées, `ease-in` pour les sorties. Pas de `ease-in-out` sauf cas particulier.
- **Anims réservées** : `spin` pour spinners, `shimmer` pour skeletons, `blink` pour curseur, `pulse` pour célébrations (montée de niveau, badge gagné).
- **Respect du système d'accessibilité** : si « réduire les animations » est actif, désactiver `pulse` et `shimmer` (remplacer par état statique).

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
