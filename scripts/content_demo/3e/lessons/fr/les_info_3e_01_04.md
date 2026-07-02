# Tableurs et calculs automatiques

Un tableur transforme l'ordinateur en calculateur puissant, capable de traiter des centaines de données en quelques secondes. C'est un outil indispensable en comptabilité, en statistiques, en sciences et dans la vie quotidienne.

:::definition
Un **tableur** est un logiciel organisant les données en **feuilles de calcul** composées de **cellules**, chacune identifiée par une **colonne** (lettre) et une **ligne** (numéro). Les tableurs les plus utilisés sont **LibreOffice Calc** (gratuit), **Microsoft Excel** (payant) et **Google Sheets** (en ligne).
:::

## Structure d'une feuille de calcul

:::propriete
Une feuille de calcul est organisée ainsi :

- **Colonnes** : identifiées par des lettres (A, B, C, …, Z, AA, AB…).
- **Lignes** : identifiées par des numéros (1, 2, 3, …).
- **Cellule** : intersection d'une colonne et d'une ligne, identifiée par sa **référence** (ex : C3 = colonne C, ligne 3).
- **Plage de cellules** : groupe de cellules contigues, noté avec deux-points (A1:A10 = de A1 à A10).

Exemple :

| | A | B | C |
|---|---|---|---|
| **1** | Élève | Note 1 | Note 2 |
| **2** | Amara | 14 | 16 |
| **3** | Boukar | 12 | 18 |
:::

## Types de données dans une cellule

:::propriete
Une cellule peut contenir :

| Type | Exemple | Alignement par défaut |
|---|---|---|
| **Texte** | «Nom», «Élève» | Gauche |
| **Nombre** | 14, 3,5, −2 | Droite |
| **Date** | 30/06/2026 | Droite |
| **Formule** | =B2+C2 | Droite (affiche le résultat) |

Une formule commence toujours par le signe **=**.
:::

## Formules et fonctions essentielles

:::definition
Une **formule** est une expression commençant par **=** qui effectue des calculs automatiques. Elle peut utiliser :

- Des opérateurs arithmétiques : **+**, **−**, **\***, **/**
- Des références de cellules : A1, B3, C5:C10
- Des **fonctions** prédéfinies : SOMME, MOYENNE, MAX, MIN, SI…
:::

:::propriete
Fonctions les plus utilisées en 3ème :

| Fonction | Syntaxe | Description |
|---|---|---|
| Somme | =SOMME(A1:A10) | Additionne les valeurs de A1 à A10 |
| Moyenne | =MOYENNE(B1:B10) | Calcule la moyenne de B1 à B10 |
| Maximum | =MAX(C1:C10) | Trouve la plus grande valeur |
| Minimum | =MIN(C1:C10) | Trouve la plus petite valeur |
| Nombre | =NB(A1:A10) | Compte les cellules contenant un nombre |
| Condition | =SI(B2>=10;"Admis";"Refusé") | Renvoie «Admis» si B2 ≥ 10, sinon «Refusé» |
:::

:::exemple
Calcul de la moyenne d'un élève :

| | A | B | C | D |
|---|---|---|---|---|
| **1** | Matière | Note | Coeff | Note × Coeff |
| **2** | Maths | 14 | 4 | =B2*C2 |
| **3** | Français | 12 | 3 | =B3*C3 |
| **4** | SVT | 16 | 2 | =B4*C4 |
| **5** | **Total** | | =SOMME(C2:C4) | =SOMME(D2:D4) |
| **6** | **Moyenne** | | | =D5/C5 |

La formule =D5/C5 calcule la moyenne pondérée : somme des (notes × coefficients) divisée par la somme des coefficients.
:::

## Références relatives et absolues

:::definition
Lors de la **recopie** d'une formule, les références de cellules changent automatiquement. On distingue :

- **Référence relative** (ex : A1) : s'adapte lors de la copie (A1 devient B1 si on copie vers la droite).
- **Référence absolue** (ex : $A$1) : ne change pas lors de la copie. Le symbole **$** fixe la colonne, la ligne, ou les deux.
- **Référence mixte** : $A1 (colonne fixe) ou A$1 (ligne fixe).
:::

:::exemple
Si la cellule E2 contient =D2/$D$5 et qu'on la copie vers E3 :
- D2 devient D3 (référence relative → s'adapte à la ligne).
- $D$5 reste $D$5 (référence absolue → ne change pas).

Ceci permet de diviser chaque note par le total (en D5) sans changer la référence au total.
:::

## Graphiques

:::methode
Pour créer un graphique à partir d'un tableau :

1. **Sélectionner** les données (cellules avec titres et valeurs).
2. **Insérer** → **Graphique** (ou icône graphique dans la barre d'outils).
3. **Choisir le type** : histogramme (comparaison), courbe (évolution), camembert (proportions).
4. **Personnaliser** : titre, légende, couleurs.
5. **Valider** : le graphique est inséré dans la feuille.
:::

:::attention
Ne pas utiliser un graphique en camembert (secteurs) si la somme des données ne représente pas 100 % d'un tout. Par exemple, les notes sur 20 de plusieurs matières ne se prêtent pas à un camembert — utiliser un histogramme.
:::

:::retenir
- Un **tableur** organise les données en cellules identifiées par colonne (lettre) et ligne (numéro), ex : B3.
- Une **formule** commence par **=** et effectue des calculs automatiques.
- Fonctions clés : **=SOMME()**, **=MOYENNE()**, **=MAX()**, **=MIN()**, **=SI()**.
- **Référence absolue** ($A$1) : ne change pas lors de la recopie. **Référence relative** (A1) : s'adapte.
- On peut créer des **graphiques** (histogramme, courbe, camembert) à partir des données d'un tableau.
:::
