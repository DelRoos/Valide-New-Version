# Sous-programmes : fonctions et procédures

Quand un même calcul doit être répété à plusieurs endroits d'un programme, le réécrire à chaque fois est fastidieux et source d'erreurs. Les **sous-programmes** (fonctions et procédures) permettent d'écrire le code une seule fois et de le réutiliser autant de fois que nécessaire.

:::definition
Un **sous-programme** est un bloc d'instructions nommé, indépendant, que l'on peut **appeler** (invoquer) depuis le programme principal ou depuis d'autres sous-programmes. On distingue :

- **Procédure** : effectue des actions (affichages, modifications de variables) sans retourner de valeur.
- **Fonction** : effectue des calculs et **retourne une valeur** au programme appelant.
:::

## La procédure

:::definition
Une **procédure** est un sous-programme qui exécute des actions sans retourner de résultat.

**Déclaration :**
```
PROCEDURE NomProcedure(param1 : TYPE1, param2 : TYPE2)
VARIABLES
  variables_locales : TYPE
DEBUT
  // Corps de la procédure
  instructions
FIN
```

**Appel :**
```
NomProcedure(valeur1, valeur2)
```
:::

:::exemple
Procédure affichant un message de bienvenue :

```
PROCEDURE Bienvenue(prenom : CHAINE)
DEBUT
  ECRIRE("Bonjour, ", prenom, " !")
  ECRIRE("Bienvenue dans le programme.")
FIN

// Programme principal
ALGORITHME Programme_Principal
VARIABLES
  nom : CHAINE
DEBUT
  LIRE(nom)
  Bienvenue(nom)    // Appel de la procédure
FIN
```

Si l'utilisateur saisit «Amara», la procédure affiche :
```
Bonjour, Amara !
Bienvenue dans le programme.
```
:::

## La fonction

:::definition
Une **fonction** est un sous-programme qui effectue un calcul et **retourne une valeur** grâce à l'instruction `RETOURNER`.

**Déclaration :**
```
FONCTION NomFonction(param1 : TYPE1, param2 : TYPE2) : TYPE_RETOUR
VARIABLES
  variables_locales : TYPE
DEBUT
  // Corps de la fonction
  instructions
  RETOURNER valeur
FIN
```

**Appel :**
```
resultat ← NomFonction(valeur1, valeur2)
```
La valeur retournée est stockée dans `resultat`.
:::

:::exemple
Fonction calculant l'aire d'un rectangle :

```
FONCTION Aire_Rectangle(longueur, largeur : REEL) : REEL
DEBUT
  RETOURNER longueur * largeur
FIN

// Programme principal
ALGORITHME Calcul_Aire
VARIABLES
  L, l, aire : REEL
DEBUT
  ECRIRE("Longueur : ")
  LIRE(L)
  ECRIRE("Largeur : ")
  LIRE(l)
  aire ← Aire_Rectangle(L, l)   // Appel de la fonction
  ECRIRE("Aire = ", aire)
FIN
```

Si L = 5 et l = 3, alors `Aire_Rectangle(5, 3)` retourne 15, et on affiche «Aire = 15».
:::

## Paramètres et variables locales

:::propriete
- **Paramètres** : valeurs passées à un sous-programme lors de son appel. Ils sont déclarés entre parenthèses dans l'en-tête du sous-programme.
- **Variables locales** : variables déclarées à l'intérieur d'un sous-programme. Elles n'existent que pendant l'exécution du sous-programme et sont inaccessibles depuis l'extérieur.
- **Variables globales** : variables déclarées dans le programme principal, accessibles partout. À utiliser avec précaution.

| Caractéristique | Variable locale | Variable globale |
|---|---|---|
| Déclarée dans | Le sous-programme | Le programme principal |
| Durée de vie | Le temps d'exécution du sous-programme | Toute l'exécution du programme |
| Accessibilité | Uniquement dans le sous-programme | Partout |
:::

## Avantages des sous-programmes

:::propriete
| Avantage | Description |
|---|---|
| **Réutilisabilité** | Écrire une fois, appeler plusieurs fois |
| **Modularité** | Diviser un problème complexe en sous-problèmes |
| **Lisibilité** | Un programme bien découpé est plus facile à comprendre |
| **Maintenabilité** | Corriger un bug dans la fonction le corrige partout |
| **Testabilité** | Tester chaque sous-programme indépendamment |
:::

:::methode
Pour concevoir un sous-programme :

1. **Identifier** la tâche répétée ou le calcul à isoler.
2. **Choisir** : retourne-t-il une valeur ? → Fonction ; sinon → Procédure.
3. **Définir les paramètres** : quelles informations la tâche a-t-elle besoin ?
4. **Écrire le corps** : implémenter la tâche.
5. **Appeler** le sous-programme depuis le programme principal.
:::

:::retenir
- Un **sous-programme** est un bloc d'instructions nommé et réutilisable.
- **Procédure** : effectue des actions, ne retourne pas de valeur.
- **Fonction** : effectue un calcul, **retourne une valeur** avec `RETOURNER`.
- **Paramètres** : valeurs passées lors de l'appel pour personnaliser le comportement.
- **Variables locales** : n'existent que pendant l'exécution du sous-programme.
- Avantages : réutilisabilité, modularité, lisibilité, maintenabilité.
:::
