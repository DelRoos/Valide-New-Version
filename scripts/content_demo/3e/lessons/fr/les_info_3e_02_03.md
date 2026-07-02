# Structures conditionnelles

Un programme prend souvent des décisions différentes selon les circonstances : si la note est supérieure à 10, l'élève est admis ; sinon, il est refusé. Ces branchements conditionnels sont le cœur de la logique algorithmique.

:::definition
Une **condition** est une expression logique dont l'évaluation donne VRAI ou FAUX. Elle utilise des opérateurs de comparaison (=, ≠, <, >, ≤, ≥) et des opérateurs logiques (ET, OU, NON).

Une **structure conditionnelle** (ou alternative) permet d'exécuter des blocs d'instructions différents selon que la condition est VRAIE ou FAUSSE.
:::

## La structure SI…ALORS…SINON

:::propriete
**Forme complète (avec SINON) :**

```
SI condition ALORS
  // Bloc exécuté si la condition est VRAIE
  instructions_vrai
SINON
  // Bloc exécuté si la condition est FAUSSE
  instructions_faux
FINSI
```

**Forme réduite (sans SINON) :**

```
SI condition ALORS
  // Exécuté seulement si VRAIE
  instructions
FINSI
```

Si la condition est FAUSSE dans la forme réduite, on passe directement au FINSI.
:::

:::exemple
**Problème** : Déterminer si un nombre est positif, négatif ou nul.

```
ALGORITHME Signe_Nombre
VARIABLES
  n : REEL
DEBUT
  ECRIRE("Entrez un nombre : ")
  LIRE(n)
  SI n > 0 ALORS
    ECRIRE("Le nombre est positif.")
  SINON
    SI n < 0 ALORS
      ECRIRE("Le nombre est négatif.")
    SINON
      ECRIRE("Le nombre est nul.")
    FINSI
  FINSI
FIN
```

Ce code utilise une **structure imbriquée** : un SI à l'intérieur d'un autre SI.
:::

## La structure SELON…FAIRE

:::definition
La structure **SELON…FAIRE** (ou CASE/SWITCH) permet de traiter plusieurs valeurs possibles d'une variable sans écrire de nombreux SI imbriqués. Elle est plus lisible quand on teste une même variable contre plusieurs valeurs.

```
SELON variable FAIRE
  valeur1 : instructions_1
  valeur2 : instructions_2
  valeur3, valeur4 : instructions_3_4
  AUTREMENT : instructions_defaut
FINSELON
```
:::

:::exemple
**Problème** : Afficher la mention selon la note (sur 20) d'un élève.

```
ALGORITHME Mention
VARIABLES
  note : ENTIER
DEBUT
  LIRE(note)
  SI note < 0 OU note > 20 ALORS
    ECRIRE("Note invalide.")
  SINON
    SI note >= 16 ALORS
      ECRIRE("Très Bien")
    SINON
      SI note >= 14 ALORS
        ECRIRE("Bien")
      SINON
        SI note >= 12 ALORS
          ECRIRE("Assez Bien")
        SINON
          SI note >= 10 ALORS
            ECRIRE("Passable")
          SINON
            ECRIRE("Insuffisant")
          FINSI
        FINSI
      FINSI
    FINSI
  FINSI
FIN
```

**Trace d'exécution** (note = 15) :
1. 15 < 0 OU 15 > 20 → FAUX → on entre dans le SINON
2. 15 ≥ 16 → FAUX → on entre dans le SINON
3. 15 ≥ 14 → VRAI → on affiche «Bien»
:::

## Conditions composées

:::propriete
On peut combiner plusieurs conditions avec ET, OU, NON :

| Expression | Vraie si... |
|---|---|
| (a > 0) ET (a < 10) | a est strictement entre 0 et 10 |
| (note = 20) OU (mention = "TB") | l'une ou l'autre est vraie |
| NON (estConnecte) | l'utilisateur n'est pas connecté |

**Table de vérité du ET :**

| A | B | A ET B |
|---|---|---|
| VRAI | VRAI | VRAI |
| VRAI | FAUX | FAUX |
| FAUX | VRAI | FAUX |
| FAUX | FAUX | FAUX |

**Table de vérité du OU :**

| A | B | A OU B |
|---|---|---|
| VRAI | VRAI | VRAI |
| VRAI | FAUX | VRAI |
| FAUX | VRAI | VRAI |
| FAUX | FAUX | FAUX |
:::

:::methode
Pour écrire une structure conditionnelle :

1. **Formuler la condition** sous forme logique (Vrai/Faux).
2. **Écrire le bloc ALORS** : ce qui se passe si la condition est vraie.
3. **Écrire le bloc SINON** (si nécessaire) : ce qui se passe si la condition est fausse.
4. **Fermer avec FINSI**.
5. **Tester** avec au moins deux valeurs : une qui rend la condition vraie et une qui la rend fausse.
:::

:::attention
Ne pas confondre = (comparaison) et ← (affectation) :
- `SI note = 10 ALORS` → teste si note est égal à 10 (COMPARAISON).
- `note ← 10` → stocke la valeur 10 dans note (AFFECTATION).

En algorithmique, on utilise = pour la comparaison (contrairement à Python qui utilise ==).
:::

:::retenir
- Une **condition** est une expression VRAI/FAUX utilisant les opérateurs <, >, ≤, ≥, =, ≠.
- **SI…ALORS…SINON…FINSI** : bloc ALORS si VRAI, bloc SINON si FAUX. SINON est facultatif.
- **SELON…FAIRE** : teste plusieurs valeurs d'une même variable, plus lisible que de nombreux SI imbriqués.
- **Conditions composées** : ET (les deux vraies), OU (au moins une vraie), NON (inverse).
- Toujours tester l'algorithme avec des valeurs couvrant chaque branche du SI.
:::
