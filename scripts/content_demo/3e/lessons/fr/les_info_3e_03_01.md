# Architecture des réseaux informatiques

Envoyer un message, partager un fichier, accéder à une imprimante distante : tout cela est rendu possible par les réseaux informatiques. Comprendre leur architecture, c'est comprendre comment les ordinateurs communiquent.

:::definition
Un **réseau informatique** est un ensemble d'équipements informatiques (ordinateurs, imprimantes, serveurs, smartphones…) interconnectés afin de **partager des ressources** (fichiers, imprimantes, connexion Internet) et de **communiquer** entre eux.
:::

## Types de réseaux selon la taille

:::propriete
| Type | Nom complet | Portée | Exemples |
|---|---|---|---|
| **PAN** | Personal Area Network | Quelques mètres | Bluetooth, infrarouge |
| **LAN** | Local Area Network | Bâtiment, campus | Réseau d'une école, d'une entreprise |
| **MAN** | Metropolitan Area Network | Ville | Réseau câblé d'une ville |
| **WAN** | Wide Area Network | Pays, continent, monde | Internet |

Le **LAN** (réseau local) est le type de réseau le plus courant dans les établissements scolaires et les entreprises au Cameroun.
:::

## Les topologies de réseau

:::definition
La **topologie** d'un réseau décrit la façon dont les équipements sont connectés entre eux. Les topologies les plus courantes sont :

- **Topologie en étoile** : tous les postes sont reliés à un point central (switch/hub). Si un câble tombe, seul le poste concerné est coupé. **C'est la topologie la plus utilisée aujourd'hui.**
- **Topologie en bus** : tous les postes sont reliés à un câble commun. Une panne du câble coupe tout le réseau.
- **Topologie en anneau** : les postes sont reliés en boucle fermée. Les données circulent dans un sens.
:::

:::figure
```
Topologie en étoile :

   [PC1]   [PC2]
     \       /
      [Switch]
     /       \
   [PC3]   [Imprimante]

Topologie en bus :

[PC1]--[PC2]--[PC3]--[PC4]--[PC5]
       (câble commun)

Topologie en anneau :

[PC1] → [PC2] → [PC3]
  ↑                ↓
[PC5] ← [PC4] ←←←←
```
:::

## Les équipements réseau

:::propriete
| Équipement | Rôle |
|---|---|
| **Carte réseau (NIC)** | Interface entre l'ordinateur et le réseau (Ethernet ou Wi-Fi) |
| **Câble Ethernet** | Support physique de transmission des données (catégorie 5e, 6) |
| **Hub** | Concentrateur simple : diffuse les données à tous les ports (obsolète) |
| **Switch (commutateur)** | Concentrateur intelligent : envoie les données uniquement au port destinataire |
| **Routeur** | Relie des réseaux différents et choisit le meilleur chemin pour les données |
| **Modem** | Convertit le signal numérique en signal analogique (ligne téléphonique, fibre) |
| **Point d'accès Wi-Fi** | Permet les connexions sans fil (Wi-Fi 5 GHz, 2,4 GHz) |
:::

## Modèle client-serveur et poste à poste

:::definition
Il existe deux architectures fondamentales de réseau :

**Architecture client-serveur :**
- Un ou plusieurs **serveurs** centralisent les ressources (fichiers, bases de données, applications).
- Les **clients** font des requêtes au serveur et reçoivent les réponses.
- Avantages : gestion centralisée, sécurité, fiabilité. Utilisé dans les entreprises, les écoles, Internet.

**Architecture poste à poste (peer-to-peer ou P2P) :**
- Chaque poste est à la fois client et serveur.
- Les ressources sont distribuées entre tous les postes.
- Avantages : pas de serveur central, moins coûteux. Inconvénients : moins sécurisé, plus difficile à gérer.
:::

## Le réseau au Cameroun

:::exemple
Au Cameroun, les réseaux informatiques sont présents dans de nombreux contextes :

- **Lycées et universités** : laboratoires informatiques en réseau local (LAN) pour partager une connexion Internet.
- **Entreprises** : réseaux locaux avec serveurs de fichiers et imprimantes partagées.
- **Mobile Money (MTN, Orange)** : réseau WAN reliant les agences à travers tout le pays.
- **Administration** : réseau gouvernemental (SIGIPES pour les fonctionnaires).
- **Cybercafés** : accès partagé à Internet via un routeur et plusieurs postes clients.
:::

:::methode
Pour configurer un réseau local simple (LAN en étoile) dans une salle informatique :

1. Installer un **switch** au centre de la salle.
2. Relier chaque ordinateur au switch avec un **câble Ethernet**.
3. Configurer les **adresses IP** de chaque machine (192.168.1.1, 192.168.1.2, etc.).
4. Connecter le switch à un **routeur/modem** si on veut partager Internet.
5. Tester la connexion : `ping 192.168.1.1` depuis chaque poste.
:::

:::retenir
- Un **réseau informatique** interconnecte des équipements pour partager des ressources et communiquer.
- Types : **PAN** (personnel), **LAN** (local), **MAN** (métropolitain), **WAN** (étendu).
- Topologies : **étoile** (la plus utilisée), **bus**, **anneau**.
- Équipements clés : switch (concentrateur intelligent), routeur (relie des réseaux), modem (conversion signal).
- Architectures : **client-serveur** (centralisé) et **poste à poste P2P** (distribué).
:::
