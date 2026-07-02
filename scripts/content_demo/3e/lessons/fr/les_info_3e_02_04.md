# Structures répétitives : les boucles

Répéter une même action dix fois, cent fois, ou jusqu'à ce qu'une condition soit remplie : c'est le rôle des boucles. Sans elles, on serait obligé d'écrire cent fois la même instruction — les boucles rendent les algorithmes puissants et concis.

:::definition
Une **boucle** (ou structure répétitive, ou itération) est une instruction qui répète un bloc d'instructions plusieurs fois. Le bloc répété s'appelle le **corps de la boucle**. Chaque exécution du corps est appelée une **itération**.

Il existe trois types de boucles en algorithmique :
1. **POUR** : répétition un nombre fixe et connu de fois.
2. **TANTQUE** : répétition conditionnelle, condition testée **avant** chaque itération.
3. **REPETER…JUSQU'À** : répétition conditionnelle, condition testée **après** chaque itération.
:::

## La boucle POUR

:::definition
La boucle **POUR** est utilisée quand le **nombre d'itérations est connu à l'avance**. Un compteur prend successivement toutes les valeurs d'un intervalle.

```
POUR compteur DE valeur_debut A valeur_fin [PAS DE pas] FAIRE
  // Corps de la boucle
  instructions
FINPOUR
```

- `compteur` est automatiquement incrémenté de 1 (ou du `pas` si précisé) à chaque itération.
- La boucle s'arrête quand `compteur > valeur_fin`.
:::

:::exemple
Afficher la table de multiplication de 7 :

```
ALGORITHME Table_7
VARIABLES
  i : ENTIER
DEBUT
  POUR i DE 1 A 10 FAIRE
    ECRIRE(7, " × ", i, " = ", 7 * i)
  FINPOUR
FIN
```

Résultat :
```
7 × 1 = 7
7 × 2 = 14
...
7 × 10 = 70
```

La boucle s'exécute 10 fois (i = 1, 2, 3, …, 10).
:::

## La boucle TANTQUE

:::definition
La boucle **TANTQUE** est utilisée quand le nombre d'itérations n'est pas connu à l'avance. La condition est testée **avant** chaque itération. Si elle est FAUSSE dès le début, le corps n'est jamais exécuté.

```
TANTQUE condition FAIRE
  // Corps de la boucle
  instructions
FINTANTQUE
```

La boucle continue tant que la condition est VRAIE. Elle s'arrête dès que la condition devient FAUSSE.
:::

:::exemple
Calculer la somme des entiers positifs jusqu'à ce que la somme dépasse 100 :

```
ALGORITHME Somme_Limite
VARIABLES
  somme, n : ENTIER
DEBUT
  somme ← 0
  n ← 1
  TANTQUE somme <= 100 FAIRE
    somme ← somme + n
    n ← n + 1
  FINTANTQUE
  ECRIRE("La somme dépasse 100 pour n = ", n - 1)
  ECRIRE("La somme obtenue est : ", somme)
FIN
```
:::

## La boucle REPETER…JUSQU'À

:::definition
La boucle **REPETER…JUSQU'À** est similaire à TANTQUE, mais la condition est testée **après** chaque itération. Le corps est donc toujours exécuté **au moins une fois**.

```
REPETER
  // Corps de la boucle
  instructions
JUSQU'A condition
```

La boucle continue tant que la condition est FAUSSE. Elle s'arrête dès que la condition devient VRAIE.
:::

:::exemple
Demander à l'utilisateur de saisir une note valide (entre 0 et 20) :

```
ALGORITHME Saisie_Note
VARIABLES
  note : ENTIER
DEBUT
  REPETER
    ECRIRE("Entrez une note entre 0 et 20 : ")
    LIRE(note)
    SI note < 0 OU note > 20 ALORS
      ECRIRE("Note invalide, réessayez.")
    FINSI
  JUSQU'A (note >= 0) ET (note <= 20)
  ECRIRE("Note valide saisie : ", note)
FIN
```

Le bloc se répète jusqu'à ce que l'utilisateur saisisse une note valide.
:::

## Comparaison des trois boucles

:::propriete
| Critère | POUR | TANTQUE | REPETER…JUSQU'À |
|---|---|---|---|
| Nombre d'itérations | Connu à l'avance | Inconnu | Inconnu |
| Test de la condition | — | Avant le corps | Après le corps |
| Exécution minimale | 0 si debut > fin | 0 si condition fausse dès le départ | **Toujours 1** |
| Usage typique | Tables, comptage, listes | Traitement jusqu'à condition | Saisie avec validation |
:::

:::methode
Pour choisir la bonne boucle :

- **Nombre d'itérations connu ?** → utiliser **POUR**.
- **Nombre d'itérations inconnu, corps peut ne pas s'exécuter ?** → utiliser **TANTQUE**.
- **Corps doit s'exécuter au moins une fois (ex : saisie utilisateur) ?** → utiliser **REPETER…JUSQU'À**.
:::

:::attention
Une **boucle infinie** se produit quand la condition d'une boucle TANTQUE reste toujours VRAIE, ou que la condition JUSQU'À d'une boucle REPETER reste toujours FAUSSE. Le programme tourne indéfiniment. Vérifier toujours que la condition de sortie peut être atteinte.

Contre-exemple d'une boucle infinie :
```
i ← 1
TANTQUE i > 0 FAIRE
  i ← i + 1   // i augmente toujours → condition toujours vraie → boucle infinie !
FINTANTQUE
```
:::

:::retenir
- **POUR** : nombre d'itérations connu. Syntaxe : POUR i DE a A b FAIRE … FINPOUR.
- **TANTQUE** : condition testée AVANT. Peut ne jamais s'exécuter. Syntaxe : TANTQUE cond FAIRE … FINTANTQUE.
- **REPETER…JUSQU'À** : condition testée APRÈS. S'exécute toujours au moins 1 fois.
- Une **boucle infinie** est une erreur : vérifier que la condition de sortie est atteignable.
- Choisir la boucle selon si le nombre d'itérations est connu (POUR) ou non (TANTQUE / REPETER).
:::
