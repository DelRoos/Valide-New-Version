# Variables, types de données et opérations

Tout algorithme manipule des informations : des nombres, du texte, des valeurs logiques. Ces informations sont stockées dans des **variables**, chacune ayant un **type** qui définit ce qu'elle peut contenir.

:::definition
Une **variable** est un espace mémoire nommé dans lequel on stocke une valeur. Cette valeur peut être lue et modifiée au cours de l'exécution de l'algorithme. Une variable est caractérisée par :

- Un **nom** (identifiant) : ex. age, note, nomEleve.
- Un **type** : la nature des valeurs qu'elle peut stocker.
- Une **valeur** : le contenu actuel de l'espace mémoire.

En pseudocode, on déclare les variables dans la section VARIABLES avant le DEBUT.
:::

## Les types de données

:::definition
Le **type** d'une variable détermine la nature des valeurs qu'elle peut stocker et les opérations que l'on peut effectuer dessus.

| Type | Description | Exemples de valeurs |
|---|---|---|
| **ENTIER** | Nombre entier (sans virgule) | −10, 0, 5, 1000 |
| **REEL** | Nombre décimal (avec virgule) | 3,14 ; −2,5 ; 0,001 |
| **CHAINE** | Texte (chaîne de caractères) | "Bonjour", "Amara", "3eA" |
| **BOOLEEN** | Valeur logique | VRAI, FAUX |
| **CARACTERE** | Un seul caractère | 'A', 'z', '5', '?' |
:::

## Déclaration des variables en pseudocode

:::propriete
Les variables se déclarent dans la section VARIABLES avec la syntaxe :

```
VARIABLES
  nomVariable : TYPE
  nom1, nom2 : TYPE   (plusieurs variables du même type)
```

Exemples :

```
VARIABLES
  age : ENTIER
  note, moyenne : REEL
  nomEleve : CHAINE
  estMajeur : BOOLEEN
```
:::

## L'affectation

:::definition
L'**affectation** permet de stocker une valeur dans une variable. En pseudocode, elle s'écrit avec la flèche **←** :

```
variable ← expression
```

L'expression à droite de **←** est **d'abord calculée**, puis le résultat est stocké dans la variable à gauche.

Exemple :
```
a ← 5        // a vaut 5
b ← 3        // b vaut 3
c ← a + b    // c vaut 8 (5 + 3)
a ← a + 1   // a vaut maintenant 6 (l'ancienne valeur + 1)
```
:::

:::attention
L'affectation `a ← a + 1` est valide en algorithmique (et en programmation) : on lit l'ancienne valeur de `a` (5), on y ajoute 1 (résultat : 6), puis on stocke ce résultat dans `a`. Après l'affectation, `a` vaut 6.

En mathématiques, l'équation a = a + 1 est impossible. En algorithmique, c'est une opération courante (incrémenter un compteur).
:::

## Les opérateurs

:::propriete
**Opérateurs arithmétiques :**

| Opérateur | Signification | Exemple | Résultat |
|---|---|---|---|
| + | Addition | 7 + 3 | 10 |
| − | Soustraction | 7 − 3 | 4 |
| * | Multiplication | 7 * 3 | 21 |
| / | Division réelle | 7 / 2 | 3,5 |
| DIV | Division entière | 7 DIV 2 | 3 |
| MOD | Reste de la division | 7 MOD 2 | 1 |

**Opérateurs de comparaison :**

| Opérateur | Signification |
|---|---|
| = | Égal à |
| ≠ | Différent de |
| < | Inférieur à |
| > | Supérieur à |
| ≤ | Inférieur ou égal à |
| ≥ | Supérieur ou égal à |

**Opérateurs logiques :**

| Opérateur | Signification | Exemple |
|---|---|---|
| ET | Les deux conditions vraies | (a > 0) ET (a < 10) |
| OU | Au moins une condition vraie | (note = 20) OU (mention = "TB") |
| NON | Inverse la condition | NON (estConnecte) |
:::

## Exemple complet

:::exemple
**Problème** : demander à l'utilisateur son âge et afficher s'il est majeur ou non.

```
ALGORITHME Majorite
VARIABLES
  age : ENTIER
DEBUT
  ECRIRE("Quel est votre âge ? ")
  LIRE(age)
  SI age >= 18 ALORS
    ECRIRE("Vous êtes majeur.")
  SINON
    ECRIRE("Vous êtes mineur.")
  FINSI
FIN
```

**Test 1** : age = 20 → âge ≥ 18 est VRAI → affiche «Vous êtes majeur.»
**Test 2** : age = 15 → âge ≥ 18 est FAUX → affiche «Vous êtes mineur.»
:::

:::methode
Règles de nommage des variables :

1. Le nom commence par une **lettre** (pas un chiffre).
2. Le nom ne contient que des **lettres, chiffres et underscores** (pas d'espace, pas d'accent, pas de tiret).
3. Le nom est **descriptif** et significatif : `noteMaths` plutôt que `n`.
4. Respecter la **casse** : `age` et `Age` sont deux variables différentes.
:::

:::retenir
- Une **variable** est un espace mémoire nommé pour stocker une valeur modifiable.
- Types : **ENTIER** (entier), **REEL** (décimal), **CHAINE** (texte), **BOOLEEN** (VRAI/FAUX).
- **Affectation** : `variable ← expression` (calculer d'abord, puis stocker).
- **Opérateurs arithmétiques** : +, −, *, /, DIV (division entière), MOD (reste).
- **Opérateurs logiques** : ET, OU, NON — permettent de combiner des conditions.
:::
