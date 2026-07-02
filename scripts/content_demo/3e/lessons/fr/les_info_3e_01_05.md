# Bases de données : organisation de l'information

Un hôpital gère des milliers de dossiers patients, une école des centaines d'élèves, une bibliothèque des milliers d'ouvrages. Sans base de données, gérer de telles quantités d'informations serait impossible. Les bases de données sont au cœur des systèmes informatiques modernes.

:::definition
Une **base de données** est une collection organisée d'informations structurées, stockées de façon à faciliter leur accès, leur gestion et leur mise à jour. Elle est gérée par un **Système de Gestion de Base de Données** (SGBD).
:::

## Structure d'une base de données

:::definition
Une base de données relationnelle est organisée en **tables** (ou relations). Chaque table est composée de :

- **Champs** (ou attributs) : les colonnes, définissant le type d'information stocké.
- **Enregistrements** (ou tuples) : les lignes, représentant chaque objet ou personne.
- **Clé primaire** : champ unique identifiant sans ambiguïté chaque enregistrement (ex : Matricule, NumeroEleve).
:::

:::exemple
Table ELEVES d'une base de données scolaire :

| Matricule | Nom | Prénom | DateNaissance | Classe |
|---|---|---|---|---|
| E001 | MVOGO | Amara | 12/03/2011 | 3eA |
| E002 | BELLO | Fadimatou | 25/07/2010 | 3eA |
| E003 | NGUYEN | Paul | 08/11/2011 | 3eB |

- **Champs** : Matricule, Nom, Prénom, DateNaissance, Classe.
- **Enregistrements** : chaque ligne (E001 Mvogo, E002 Bello, E003 Nguyen).
- **Clé primaire** : Matricule (unique pour chaque élève).
:::

## Le SGBD (Système de Gestion de Base de Données)

:::definition
Un **SGBD** est le logiciel qui permet de créer, organiser, interroger et maintenir une base de données. Il assure :

- La **saisie** et la modification des données.
- La **recherche** et l'extraction d'informations via des **requêtes**.
- La **sécurité** et la confidentialité des données.
- La **cohérence** des données (pas de doublons, respect des contraintes).

Exemples de SGBD : **MySQL** (libre, très répandu sur Internet), **PostgreSQL** (libre), **Microsoft Access** (payant, bureautique), **LibreOffice Base** (gratuit).
:::

## Les requêtes

:::definition
Une **requête** est une question posée à la base de données pour extraire des informations précises. En SQL (Structured Query Language), la requête de base est :

```
SELECT champ1, champ2
FROM NomTable
WHERE condition;
```
:::

:::exemple
Pour trouver tous les élèves de la classe 3eA :

```sql
SELECT Nom, Prénom
FROM ELEVES
WHERE Classe = '3eA';
```

Résultat :
| Nom | Prénom |
|---|---|
| MVOGO | Amara |
| BELLO | Fadimatou |

Le SGBD filtre et retourne uniquement les enregistrements correspondant à la condition.
:::

## Avantages des bases de données

:::propriete
Par rapport à un classeur papier ou un simple tableur, une base de données offre :

| Avantage | Description |
|---|---|
| **Capacité** | Gère des millions d'enregistrements |
| **Rapidité** | Recherche instantanée même dans de grands volumes |
| **Intégrité** | Évite les doublons et incohérences grâce aux contraintes |
| **Sécurité** | Gestion des droits d'accès par utilisateur |
| **Partage** | Plusieurs utilisateurs simultanés |
| **Cohérence** | Mise à jour centralisée : un seul endroit à modifier |
:::

## Applications au Cameroun

:::exemple
Au Cameroun, les bases de données sont utilisées dans de nombreux domaines :

- **MINESEC** : registres des élèves, résultats du BEPC et du BAC.
- **Hôpitaux** : dossiers médicaux des patients.
- **MTN / Orange** : gestion des abonnés Mobile Money.
- **Mairies** : état civil (naissances, mariages, décès).
- **Bibliothèques nationales** : catalogues de livres et d'archives.
:::

:::methode
Pour concevoir une table de base de données :

1. **Identifier l'objet** à décrire (élève, livre, patient, produit…).
2. **Lister les informations** nécessaires (nom, prénom, date, quantité…).
3. **Définir les types** de chaque champ (texte, nombre, date, booléen…).
4. **Choisir la clé primaire** : champ unique et immuable (matricule, ISBN, numéro de sécurité sociale…).
5. **Éviter la redondance** : ne stocker chaque information qu'une seule fois.
:::

:::retenir
- Une **base de données** est une collection organisée d'informations gérée par un **SGBD**.
- Structure : **tables** → **champs** (colonnes) + **enregistrements** (lignes) + **clé primaire** (identifiant unique).
- Un **SGBD** (MySQL, LibreOffice Base, Access) permet de créer, modifier, interroger et sécuriser les données.
- Les **requêtes** (en SQL) permettent d'extraire des informations selon des critères précis.
- Applications : registres scolaires (BEPC), dossiers médicaux, gestion Mobile Money au Cameroun.
:::
