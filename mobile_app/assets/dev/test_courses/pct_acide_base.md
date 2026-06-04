# Réactions acide-base — Tle C / D

> Cours de prise en main pour Story 0.19 (R2). Source pédagogique inventée
> — but unique : tester le rendu Markdown + équations chimiques (indices
> et exposants en LaTeX) dans `PedagogicalContent`.

## 1. Couples acide-base au sens de Brønsted

Selon Brønsted, un **acide** est une espèce capable de céder un ion $H^+$
(proton) et une **base** est une espèce capable d'en capter un.

Un couple acide-base est noté $\text{Acide} / \text{Base}$ et reliés par la
demi-équation acide-base :

$$
\text{Acide} \rightleftharpoons \text{Base} + H^+
$$

### 1.1 Exemples de couples

| Acide | Base conjuguée | Type |
| --- | --- | --- |
| $H_3O^+$ | $H_2O$ | oxonium / eau |
| $H_2O$ | $OH^-$ | eau / hydroxyde |
| $CH_3COOH$ | $CH_3COO^-$ | acide acétique / acétate |
| $NH_4^+$ | $NH_3$ | ammonium / ammoniac |
| $HCO_3^-$ | $CO_3^{2-}$ | hydrogénocarbonate / carbonate |
| $HSO_4^-$ | $SO_4^{2-}$ | hydrogénosulfate / sulfate |

L'eau est **amphotère** : elle peut jouer le rôle d'acide ($H_2O / OH^-$) ou
de base ($H_3O^+ / H_2O$).

## 2. Réaction acide-base en solution aqueuse

Une réaction acide-base met en jeu **deux couples** :

$$
\text{Acide}_1 + \text{Base}_2 \rightarrow \text{Base}_1 + \text{Acide}_2
$$

### 2.1 Exemple — acide chlorhydrique dans l'eau

L'acide chlorhydrique est un acide fort. Il se dissocie totalement :

$$
HCl + H_2O \rightarrow H_3O^+ + Cl^-
$$

### 2.2 Exemple — acide acétique dans l'eau

L'acide acétique est un acide faible. La réaction est limitée :

$$
CH_3COOH + H_2O \rightleftharpoons H_3O^+ + CH_3COO^-
$$

## 3. Constante d'acidité $K_a$ et $pK_a$

Pour un couple $\text{AH} / \text{A}^-$ en solution aqueuse :

$$
K_a = \frac{[A^-] \cdot [H_3O^+]}{[AH]} \qquad pK_a = -\log_{10}(K_a)
$$

Plus le $pK_a$ est **petit**, plus l'acide est **fort** (il libère facilement
ses $H^+$).

### 3.1 Échelle de force

| Acide | $pK_a$ (à $25°C$) |
| --- | --- |
| $HCl$ | $\sim -7$ (très fort) |
| $H_2SO_4$ (première acidité) | $\sim -3$ |
| $CH_3COOH$ | $4{,}76$ |
| $NH_4^+$ | $9{,}25$ |
| $H_2O$ | $14$ |

## 4. pH d'une solution

Le pH mesure la concentration en ions $H_3O^+$ :

$$
pH = -\log_{10}([H_3O^+])
$$

avec $[H_3O^+]$ exprimée en $\text{mol} \cdot L^{-1}$.

### 4.1 Solution neutre, acide ou basique

- Solution **neutre** : $pH = 7$ à $25°C$
- Solution **acide** : $pH < 7$
- Solution **basique** : $pH > 7$

### 4.2 Produit ionique de l'eau

À toute température, $K_e = [H_3O^+] \cdot [OH^-]$. À $25°C$, $K_e = 10^{-14}$
donc $pK_e = 14$. On en déduit la relation utile :

$$
pH + pOH = pK_e = 14 \qquad \text{(à } 25°C\text{)}
$$

## 5. Réaction de neutralisation

Une **neutralisation** est la réaction entre un acide et une base de leurs
solutions aqueuses. Exemple :

$$
HCl_{(aq)} + NaOH_{(aq)} \rightarrow NaCl_{(aq)} + H_2O_{(\ell)}
$$

L'équation ionique se simplifie en :

$$
H_3O^+ + OH^- \rightarrow 2\,H_2O
$$

Cette réaction est **totale** (la constante d'équilibre vaut $10^{14}$ à $25°C$).

## 6. Titrage acide-base

On verse progressivement une solution titrante de concentration connue dans
une solution titrée jusqu'à atteindre l'**équivalence** (autant de moles
d'acide que de base réagi). À l'équivalence :

$$
n(\text{titrant}) = n(\text{titré}) \quad \Leftrightarrow \quad C_T \cdot V_{eq} = C_0 \cdot V_0
$$

L'équivalence se repère :

1. par changement de couleur d'un **indicateur coloré** adapté ;
2. par la variation rapide du pH (saut de titrage) — méthode pH-métrique.

## 7. À retenir

1. Un couple acide-base est lié par l'échange d'un seul ion $H^+$.
2. La force d'un acide se lit sur $pK_a$ : plus petit = plus fort.
3. À $25°C$, $pH + pOH = 14$ et $[H_3O^+] \cdot [OH^-] = 10^{-14}$.
4. Une neutralisation acide fort + base forte produit eau + sel.
5. À l'équivalence d'un titrage, $C_T \cdot V_{eq} = C_0 \cdot V_0$.

> **Domaine de prédominance** : pour un couple $\text{AH} / \text{A}^-$,
> $AH$ prédomine quand $pH < pK_a$ et $A^-$ prédomine quand $pH > pK_a$.
> À $pH = pK_a$, $[AH] = [A^-]$.
