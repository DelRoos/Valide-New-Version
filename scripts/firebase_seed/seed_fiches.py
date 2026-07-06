"""
seed_fiches.py — Seed les sous-collections chapters/{chapterId}/fiche/main.

Seed minimal pour les chapitres de test (3e). Le contenu est en Markdown
pedagogique reel (FR + EN) avec formules LaTeX et blocs callout.

Usage :
    python seed_fiches.py --project valide-edu --credentials ./service-account.json
    python seed_fiches.py --project valide-edu --dry-run

Idempotence : set(merge=True) — safe a re-runner.
"""

from __future__ import annotations

import argparse
import sys
import time
from pathlib import Path
from typing import Optional

import firebase_admin
from firebase_admin import credentials, firestore
from google.cloud.firestore_v1 import SERVER_TIMESTAMP

# ---------------------------------------------------------------------------
# Contenu des fiches par chapitre (raw strings pour les backslashes LaTeX)
# ---------------------------------------------------------------------------

_MATH_01_FR = r"""# Fiche de revision — Calcul litteral et equations

:::retenir
**Ce qu'il faut savoir :**
- Developper et factoriser des expressions algebriques.
- Resoudre des equations du 1er degre a une inconnue.
- Appliquer les identites remarquables.
:::

## Identites remarquables

$$( a + b )^2 = a^2 + 2ab + b^2$$

$$( a - b )^2 = a^2 - 2ab + b^2$$

$$( a + b )( a - b ) = a^2 - b^2$$

## Resolution d'une equation du 1er degre

Pour resoudre $ax + b = c$ :

1. Isoler le terme en $x$ : $ax = c - b$
2. Diviser par $a$ (si $a \neq 0$) : $x = \dfrac{c - b}{a}$

:::exemple
**Exemple :** Resoudre $3x + 5 = 14$

$3x = 14 - 5 = 9 \Rightarrow x = 3$
:::

## Developpement

:::methode
Pour developper $a(b + c)$ :
$$a(b + c) = ab + ac$$
Appliquer a chaque terme de la parenthese.
:::

## Factorisation

:::methode
Factoriser = mettre en evidence le facteur commun.

**Exemple :** $6x^2 + 9x = 3x(2x + 3)$
:::
"""

_MATH_01_EN = r"""# Revision Sheet — Algebraic Expressions and Equations

:::retenir
**Key Points:**
- Expand and factorise algebraic expressions.
- Solve first-degree equations in one unknown.
- Apply remarkable identities.
:::

## Remarkable Identities

$$( a + b )^2 = a^2 + 2ab + b^2$$

$$( a - b )^2 = a^2 - 2ab + b^2$$

$$( a + b )( a - b ) = a^2 - b^2$$

## Solving a First-Degree Equation

To solve $ax + b = c$:

1. Isolate $x$: $ax = c - b$
2. Divide by $a$ (if $a \neq 0$): $x = \dfrac{c - b}{a}$

:::exemple
**Example:** Solve $3x + 5 = 14$

$3x = 14 - 5 = 9 \Rightarrow x = 3$
:::

## Expansion

:::methode
To expand $a(b + c)$:
$$a(b + c) = ab + ac$$
Apply to every term inside the brackets.
:::

## Factorisation

:::methode
Factorising = finding the common factor.

**Example:** $6x^2 + 9x = 3x(2x + 3)$
:::
"""

_MATH_02_FR = r"""# Fiche de revision — Geometrie et theoreme de Pythagore

:::retenir
**Ce qu'il faut savoir :**
- Enoncer et appliquer le theoreme de Pythagore.
- Calculer les longueurs dans un triangle rectangle.
- Reconnaitre un triangle rectangle via la reciproque.
:::

## Theoreme de Pythagore

Dans un triangle rectangle d'hypotenuse $c$ et de cotes $a$, $b$ :

$$a^2 + b^2 = c^2$$

:::attention
L'hypotenuse est toujours le cote **oppose** a l'angle droit — c'est le plus grand cote.
:::

## Reciproque

:::theoreme
Si $a^2 + b^2 = c^2$, alors le triangle est rectangle en $C$.
:::

## Calcul d'un cote

:::methode
**Trouver l'hypotenuse :** $c = \sqrt{a^2 + b^2}$

**Trouver un cote :** $a = \sqrt{c^2 - b^2}$
:::

:::exemple
**Exemple :** Triangle avec $a = 3$, $b = 4$.

$c = \sqrt{9 + 16} = \sqrt{25} = 5$

C'est un triangle 3-4-5.
:::
"""

_MATH_02_EN = r"""# Revision Sheet — Geometry and Pythagoras' Theorem

:::retenir
**Key Points:**
- State and apply Pythagoras' theorem.
- Calculate lengths in a right-angled triangle.
- Identify right-angled triangles using the converse.
:::

## Pythagoras' Theorem

In a right-angled triangle with hypotenuse $c$ and sides $a$, $b$:

$$a^2 + b^2 = c^2$$

:::attention
The hypotenuse is always the side **opposite** the right angle — it is the longest side.
:::

## Converse

:::theoreme
If $a^2 + b^2 = c^2$, then the triangle has a right angle at $C$.
:::

## Finding a Side

:::methode
**Find the hypotenuse:** $c = \sqrt{a^2 + b^2}$

**Find a leg:** $a = \sqrt{c^2 - b^2}$
:::

:::exemple
**Example:** Triangle with $a = 3$, $b = 4$.

$c = \sqrt{9 + 16} = \sqrt{25} = 5$

This is a 3-4-5 right triangle.
:::
"""

_MATH_03_FR = r"""# Fiche de revision — Statistiques et probabilites

:::retenir
**Ce qu'il faut savoir :**
- Calculer moyenne, mediane, mode et etendue.
- Comprendre la notion de probabilite.
- Lire et construire des tableaux de frequences.
:::

## Indicateurs statistiques

| Indicateur | Definition |
|---|---|
| Moyenne | Somme des valeurs / effectif total |
| Mediane | Valeur centrale une fois les donnees ordonnees |
| Mode | Valeur la plus frequente |
| Etendue | Valeur max - Valeur min |

## Moyenne d'une serie

$$\bar{x} = \dfrac{x_1 + x_2 + \cdots + x_n}{n}$$

:::exemple
**Exemple :** Notes : 8, 12, 15, 10, 12.

$\bar{x} = \dfrac{8+12+15+10+12}{5} = \dfrac{57}{5} = 11{,}4$

Mode = 12 (apparait 2 fois). Mediane = 12 (valeur centrale apres tri).
:::

## Probabilite

$$P(A) = \dfrac{\text{nombre de cas favorables}}{\text{nombre de cas possibles}}$$

:::attention
$0 \leq P(A) \leq 1$. Un evenement certain a $P = 1$, un evenement impossible $P = 0$.
:::
"""

_MATH_03_EN = r"""# Revision Sheet — Statistics and Probability

:::retenir
**Key Points:**
- Calculate mean, median, mode, and range.
- Understand the concept of probability.
- Read and build frequency tables.
:::

## Statistical Indicators

| Indicator | Definition |
|---|---|
| Mean | Sum of values / total count |
| Median | Middle value when data is ordered |
| Mode | Most frequent value |
| Range | Max value - Min value |

## Mean of a Series

$$\bar{x} = \dfrac{x_1 + x_2 + \cdots + x_n}{n}$$

:::exemple
**Example:** Scores: 8, 12, 15, 10, 12.

$\bar{x} = \dfrac{8+12+15+10+12}{5} = \dfrac{57}{5} = 11.4$

Mode = 12 (appears twice). Median = 12 (middle value after sorting).
:::

## Probability

$$P(A) = \dfrac{\text{number of favourable outcomes}}{\text{total number of outcomes}}$$

:::attention
$0 \leq P(A) \leq 1$. A certain event has $P = 1$, an impossible event $P = 0$.
:::
"""

_SVT_01_FR = r"""# Fiche de revision — Reproduction humaine

:::retenir
**Ce qu'il faut savoir :**
- Distinguer reproduction sexuee et asexuee.
- Decrire les appareils reproducteurs masculin et feminin.
- Expliquer la fecondation et le developpement embryonnaire.
:::

## Types de reproduction

| Type | Caracteristiques |
|---|---|
| Sexuee | Necessite deux gametes (ovule + spermatozoide) |
| Asexuee | Un seul parent — bouturage, bourgeonnement |

## La fecondation

:::definition
La **fecondation** est la fusion d'un spermatozoide et d'un ovule pour former un **oeuf (zygote)**.
:::

Elle se produit dans les trompes de Fallope.

## Developpement embryonnaire

1. **Zygote** → divisions cellulaires → **morula** → **blastula**
2. **Gastrulation** → formation des feuillets embryonnaires
3. **Organogenese** → formation des organes
4. **Naissance** → apres ~9 mois de gestation

:::attention
Ne pas confondre **gamete** (cellule reproductrice, $n$ chromosomes) et **zygote** (cellule-oeuf, $2n$ chromosomes).
:::
"""

_SVT_01_EN = r"""# Revision Sheet — Human Reproduction

:::retenir
**Key Points:**
- Distinguish between sexual and asexual reproduction.
- Describe male and female reproductive systems.
- Explain fertilisation and embryonic development.
:::

## Types of Reproduction

| Type | Characteristics |
|---|---|
| Sexual | Requires two gametes (egg + sperm) |
| Asexual | Single parent — cuttings, budding |

## Fertilisation

:::definition
**Fertilisation** is the fusion of a sperm cell and an egg to form a **zygote**.
:::

It occurs in the fallopian tubes.

## Embryonic Development

1. **Zygote** → cell divisions → **morula** → **blastula**
2. **Gastrulation** → formation of embryonic layers
3. **Organogenesis** → organ formation
4. **Birth** → after ~9 months of gestation

:::attention
Do not confuse a **gamete** (reproductive cell, $n$ chromosomes) with a **zygote** (fertilised egg, $2n$ chromosomes).
:::
"""

_PC_01_FR = r"""# Fiche de revision — Atomes et molecules

:::retenir
**Ce qu'il faut savoir :**
- Decrire la structure d'un atome.
- Distinguer atome, ion et molecule.
- Ecrire et lire une formule chimique.
:::

## Structure de l'atome

:::definition
Un **atome** est constitue d'un **noyau** (protons + neutrons) entoure d'**electrons**.
:::

| Particule | Charge | Localisation |
|---|---|---|
| Proton | $+$ | Noyau |
| Neutron | Neutre | Noyau |
| Electron | $-$ | Couche electronique |

Un atome neutre verifie : **nombre de protons = nombre d'electrons**.

## Ions

:::definition
Un **ion** est un atome (ou groupe d'atomes) qui a perdu ou gagne des electrons.
- Perte d'electrons → **cation** (charge positive, ex. $Na^+$)
- Gain d'electrons → **anion** (charge negative, ex. $Cl^-$)
:::

## Molecules et formules

:::exemple
- $H_2O$ : 2 atomes H + 1 atome O
- $CO_2$ : 1 atome C + 2 atomes O
- $NaCl$ : sel de cuisine (cristal ionique)
:::
"""

_PC_01_EN = r"""# Revision Sheet — Atoms and Molecules

:::retenir
**Key Points:**
- Describe the structure of an atom.
- Distinguish between atoms, ions, and molecules.
- Read and write chemical formulae.
:::

## Structure of the Atom

:::definition
An **atom** consists of a **nucleus** (protons + neutrons) surrounded by **electrons**.
:::

| Particle | Charge | Location |
|---|---|---|
| Proton | $+$ | Nucleus |
| Neutron | Neutral | Nucleus |
| Electron | $-$ | Electron shell |

A neutral atom satisfies: **number of protons = number of electrons**.

## Ions

:::definition
An **ion** is an atom (or group of atoms) that has lost or gained electrons.
- Loss of electrons → **cation** (positive charge, e.g. $Na^+$)
- Gain of electrons → **anion** (negative charge, e.g. $Cl^-$)
:::

## Molecules and Formulae

:::exemple
- $H_2O$: 2 H atoms + 1 O atom
- $CO_2$: 1 C atom + 2 O atoms
- $NaCl$: table salt (ionic crystal)
:::
"""

FICHES: list[dict] = [
    {"chapterId": "ch_math_3e_01", "fr": _MATH_01_FR, "en": _MATH_01_EN},
    {"chapterId": "ch_math_3e_02", "fr": _MATH_02_FR, "en": _MATH_02_EN},
    {"chapterId": "ch_math_3e_03", "fr": _MATH_03_FR, "en": _MATH_03_EN},
    {"chapterId": "ch_svt_3e_01",  "fr": _SVT_01_FR,  "en": _SVT_01_EN},
    {"chapterId": "ch_pc_3e_01",   "fr": _PC_01_FR,   "en": _PC_01_EN},
]


# ---------------------------------------------------------------------------
# Firebase
# ---------------------------------------------------------------------------

def init_firebase(project_id: str, credentials_path: Optional[Path]):
    if credentials_path:
        if not credentials_path.exists():
            raise FileNotFoundError(f"Credentials introuvable : {credentials_path}")
        cred = credentials.Certificate(str(credentials_path))
        mode = f"service-account ({credentials_path.name})"
    else:
        cred = credentials.ApplicationDefault()
        mode = "Application Default Credentials"
    firebase_admin.initialize_app(cred, {"projectId": project_id})
    print(f"[OK] Auth : {mode} | project={project_id}")
    return firestore.client()


# ---------------------------------------------------------------------------
# Seed
# ---------------------------------------------------------------------------

def seed_fiches(db, dry_run: bool) -> int:
    count = 0
    for fiche in FICHES:
        ch_id = fiche["chapterId"]
        payload = {
            "fr": fiche["fr"],
            "en": fiche.get("en") or fiche["fr"],
            "updatedAt": SERVER_TIMESTAMP,
        }
        path = f"chapters/{ch_id}/fiche/main"
        if dry_run:
            print(f"[DRY-RUN] Would write {path}  ({len(fiche['fr'])} chars FR)")
        else:
            (
                db.collection("chapters").document(ch_id)
                .collection("fiche").document("main")
                .set(payload, merge=True)
            )
            print(f"[OK] {path}")
        count += 1
    return count


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Seed chapters/{chapterId}/fiche/main dans Firestore",
    )
    parser.add_argument("--project", required=True)
    parser.add_argument("--credentials", type=Path, default=None)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    if args.dry_run:
        db = None
        print("[DRY-RUN] Init Firebase sautee.")
    else:
        try:
            db = init_firebase(args.project, args.credentials)
        except Exception as exc:
            print(f"[ERROR] Init Firebase : {exc}", file=sys.stderr)
            return 1

    start = time.perf_counter()
    count = seed_fiches(db, args.dry_run)
    elapsed = time.perf_counter() - start

    prefix = "[DRY-RUN]" if args.dry_run else "[OK]"
    print(f"\n{prefix} {count} fiche(s) en {elapsed:.2f}s")
    return 0


if __name__ == "__main__":
    sys.exit(main())
