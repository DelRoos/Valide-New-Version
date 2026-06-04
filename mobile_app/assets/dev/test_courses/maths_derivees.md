# Dérivées et primitives — Tle D / C

> Cours de prise en main pour Story 0.19 (R2). Source pédagogique inventée
> — but unique : tester le rendu Markdown + LaTeX dans `PedagogicalContent`.

## 1. Rappel de la définition

Soit $f$ une fonction définie sur un intervalle $I$ et $a \in I$. On dit que
$f$ est **dérivable en $a$** s'il existe une limite finie

$$
f'(a) = \lim_{h \to 0} \frac{f(a+h) - f(a)}{h}
$$

Le nombre $f'(a)$ s'appelle alors le **nombre dérivé** de $f$ en $a$.

### 1.1 Interprétation géométrique

La droite d'équation $y = f'(a)(x - a) + f(a)$ est la **tangente** à la
courbe représentative de $f$ au point d'abscisse $a$. Le coefficient
directeur de cette tangente est précisément $f'(a)$.

## 2. Dérivées usuelles

| Fonction $f$ | Dérivée $f'$ | Domaine |
| --- | --- | --- |
| $f(x) = x^n$, $n \in \mathbb{Z}$ | $f'(x) = n \cdot x^{n-1}$ | $\mathbb{R}$ ou $\mathbb{R}^*$ |
| $f(x) = \sqrt{x}$ | $f'(x) = \dfrac{1}{2\sqrt{x}}$ | $]0, +\infty[$ |
| $f(x) = \sin(x)$ | $f'(x) = \cos(x)$ | $\mathbb{R}$ |
| $f(x) = \cos(x)$ | $f'(x) = -\sin(x)$ | $\mathbb{R}$ |
| $f(x) = e^x$ | $f'(x) = e^x$ | $\mathbb{R}$ |
| $f(x) = \ln(x)$ | $f'(x) = \dfrac{1}{x}$ | $]0, +\infty[$ |

## 3. Règles de calcul

Soient $u$ et $v$ deux fonctions dérivables sur $I$. Alors :

$$
(u + v)' = u' + v' \qquad (u \cdot v)' = u'v + uv' \qquad \left(\frac{u}{v}\right)' = \frac{u'v - uv'}{v^2}
$$

La **dérivée d'une fonction composée** vérifie

$$
(g \circ u)'(x) = u'(x) \cdot g'(u(x))
$$

### 3.1 Exemple type — racine d'une fonction

Si $f(x) = \sqrt{u(x)}$ avec $u(x) > 0$, alors

$$
f'(x) = \frac{u'(x)}{2\sqrt{u(x)}}
$$

## 4. Exercice résolu

**Énoncé.** Soit $f(x) = (3x^2 + 5)^4$. Calculer $f'(x)$.

**Solution.** On pose $u(x) = 3x^2 + 5$ donc $u'(x) = 6x$. La fonction $f$
s'écrit $f(x) = u(x)^4$ donc

$$
f'(x) = 4 \cdot u'(x) \cdot u(x)^3 = 4 \cdot 6x \cdot (3x^2 + 5)^3 = 24x (3x^2 + 5)^3
$$

## 5. Primitives — vue d'ensemble

Une fonction $F$ est une **primitive** de $f$ sur $I$ si $F'(x) = f(x)$ pour
tout $x \in I$. Toutes les primitives de $f$ diffèrent d'une constante :

$$
F(x) = F_0(x) + C \quad \text{avec } C \in \mathbb{R}
$$

| Fonction $f$ | Primitive $F$ | Conditions |
| --- | --- | --- |
| $f(x) = x^n$, $n \neq -1$ | $F(x) = \dfrac{x^{n+1}}{n+1}$ | $n \in \mathbb{Z}$ |
| $f(x) = \dfrac{1}{x}$ | $F(x) = \ln\lvert x \rvert$ | $x \neq 0$ |
| $f(x) = e^x$ | $F(x) = e^x$ | $x \in \mathbb{R}$ |
| $f(x) = \cos(x)$ | $F(x) = \sin(x)$ | $x \in \mathbb{R}$ |

## 6. Intégrale et aire

Pour $f$ continue sur $[a, b]$, l'intégrale $\int_a^b f(x) \, dx$ représente
l'aire algébrique sous la courbe. Si $F$ est une primitive de $f$ :

$$
\int_a^b f(x) \, dx = F(b) - F(a)
$$

### 6.1 Propriétés

- **Linéarité** : $\int_a^b (\alpha f + \beta g)(x) \, dx = \alpha \int_a^b f(x) \, dx + \beta \int_a^b g(x) \, dx$
- **Relation de Chasles** : $\int_a^c f(x) \, dx = \int_a^b f(x) \, dx + \int_b^c f(x) \, dx$
- **Positivité** : si $f \geq 0$ sur $[a, b]$, alors $\int_a^b f(x) \, dx \geq 0$

## 7. À retenir

1. Une fonction polynôme se dérive **terme à terme** en appliquant
   $(x^n)' = n x^{n-1}$.
2. La dérivée d'un quotient demande la formule $\dfrac{u'v - uv'}{v^2}$ —
   **toujours** dans cet ordre.
3. Une primitive est définie **à une constante près**. Il faut une condition
   initiale ($F(x_0) = y_0$) pour la fixer.
4. L'intégrale $\int_a^b f$ se calcule via $F(b) - F(a)$ — c'est le théorème
   fondamental de l'analyse.

> **Sommes de Riemann** : Pour $f$ continue sur $[a, b]$, en posant
> $x_k = a + k \cdot \frac{b-a}{n}$ on a $\sum_{k=0}^{n-1} f(x_k) \cdot \frac{b-a}{n} \xrightarrow[n \to +\infty]{} \int_a^b f(x) \, dx$.
