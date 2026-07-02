# Introduction aux algorithmes et au pseudocode

Avant d'écrire un programme, tout bon informaticien réfléchit d'abord à la **méthode** : quelles étapes faut-il suivre pour résoudre le problème ? C'est ce que formalisent les algorithmes.

:::definition
Un **algorithme** est une suite **finie**, **non ambiguë** et **ordonnée** d'instructions permettant de résoudre un problème ou d'accomplir une tâche. Un algorithme :

- Prend des **données en entrée** (Input).
- Effectue des **traitements** (calculs, tests, boucles).
- Produit des **résultats en sortie** (Output).

Le mot «algorithme» vient du nom du mathématicien arabe Al-Khwarizmi (IXe siècle).
:::

## Propriétés d'un algorithme valide

:::propriete
Un algorithme valide doit posséder ces quatre propriétés :

1. **Finitude** : il doit se terminer en un nombre fini d'étapes. Un algorithme qui boucle indéfiniment n'est pas valide.
2. **Non-ambiguïté** : chaque instruction doit être précise et ne pas prêter à interprétation.
3. **Généralité** : il doit fonctionner pour toutes les entrées valides, pas seulement un cas particulier.
4. **Effectivité** : chaque instruction doit être exécutable par la machine (ou une personne).
:::

## Le pseudocode

:::definition
Le **pseudocode** (ou langage algorithmique) est une notation intermédiaire entre le langage naturel et un langage de programmation. Il permet d'écrire un algorithme de façon lisible et précise, sans se soucier de la syntaxe exacte d'un langage particulier (Python, C, Java…).

En France et au Cameroun, on utilise un pseudocode en français avec la structure suivante :
:::

:::propriete
Structure générale d'un algorithme en pseudocode :

```
ALGORITHME NomDeLAlgorithme
CONSTANTES
  NOM_CONSTANTE = valeur
VARIABLES
  nom1, nom2 : TYPE
  nom3 : TYPE
DEBUT
  // Instructions
  LIRE(variable)
  variable ← expression
  ECRIRE(variable ou texte)
FIN
```

Les mots-clés en MAJUSCULES (ALGORITHME, VARIABLES, DEBUT, FIN, LIRE, ECRIRE) font partie de la structure obligatoire.
:::

## Instructions de base

:::propriete
| Instruction | Rôle | Exemple |
|---|---|---|
| `LIRE(x)` | Saisir une valeur depuis l'utilisateur et la stocker dans x | LIRE(age) |
| `ECRIRE(x)` | Afficher la valeur de x à l'écran | ECRIRE(age) |
| `ECRIRE("texte")` | Afficher un texte fixe | ECRIRE("Bonjour !") |
| `x ← expression` | Affecter le résultat de l'expression à x | somme ← a + b |
:::

## Premier exemple complet

:::exemple
**Problème** : calculer le périmètre d'un rectangle de longueur L et de largeur l.

**Analyse** :
- Entrée : longueur L, largeur l.
- Traitement : périmètre = 2 × (L + l).
- Sortie : afficher le périmètre.

**Algorithme en pseudocode** :

```
ALGORITHME Perimetre_Rectangle
VARIABLES
  L, l, P : REEL
DEBUT
  ECRIRE("Entrez la longueur : ")
  LIRE(L)
  ECRIRE("Entrez la largeur : ")
  LIRE(l)
  P ← 2 * (L + l)
  ECRIRE("Le périmètre est : ")
  ECRIRE(P)
FIN
```

**Test** : si l'utilisateur saisit L = 5 et l = 3, alors P = 2 × (5 + 3) = 2 × 8 = 16.
:::

## L'algorigramme (diagramme de flux)

:::definition
Un **algorigramme** (ou logigramme, organigramme de programmation) est une représentation graphique d'un algorithme. Les symboles utilisés sont :

| Symbole | Forme | Signification |
|---|---|---|
| Début/Fin | Ovale | Point de départ ou d'arrivée |
| Entrée/Sortie | Parallélogramme | LIRE ou ECRIRE |
| Traitement | Rectangle | Affectation, calcul |
| Décision | Losange | Test (SI…) |
| Connecteur | Cercle | Renvoi vers une autre partie |
:::

:::methode
Pour concevoir un algorithme, suivre ces étapes :

1. **Comprendre le problème** : lire attentivement l'énoncé.
2. **Identifier les entrées** : quelles données l'utilisateur fournit-il ?
3. **Identifier la sortie** : quel résultat faut-il produire ?
4. **Décrire les traitements** : quelles opérations effectuer entre les entrées et la sortie ?
5. **Écrire le pseudocode** : traduire les traitements en instructions.
6. **Tester l'algorithme** : vérifier avec des valeurs d'exemple.
:::

:::attention
Un algorithme s'écrit **avant** le code informatique, pas après. Négliger cette étape conduit souvent à écrire un programme incorrect qu'on doit réécrire entièrement. L'algorithme est le plan de construction ; le code, la construction elle-même.
:::

:::retenir
- Un **algorithme** est une suite finie, non ambiguë et ordonnée d'instructions pour résoudre un problème.
- Propriétés : **finitude**, **non-ambiguïté**, **généralité**, **effectivité**.
- Le **pseudocode** est la notation textuelle d'un algorithme, indépendante de tout langage de programmation.
- Instructions de base : **LIRE** (entrée), **ECRIRE** (sortie), **←** (affectation).
- Structure : ALGORITHME → VARIABLES → DEBUT … FIN.
:::
