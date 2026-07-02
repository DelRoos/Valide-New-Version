# Internet : protocoles et services

Internet est le plus grand réseau informatique du monde : des milliards d'appareils interconnectés sur tous les continents. Comment fonctionnet-il ? Quels services offre-t-il ? Comment s'y connecter de façon efficace et sécurisée ?

:::definition
**Internet** (*Interconnected Networks*) est un réseau mondial d'ordinateurs et d'appareils interconnectés utilisant la suite de protocoles **TCP/IP**. Ce n'est pas un seul réseau centralisé, mais un ensemble de millions de réseaux locaux reliés entre eux.

Internet n'appartient à personne : il est géré par des organisations internationales (ICANN, IETF, W3C…) et repose sur des standards ouverts.
:::

## Les protocoles fondamentaux

:::definition
Un **protocole** est un ensemble de règles définissant comment les données sont échangées entre équipements informatiques. Les protocoles d'Internet forment une pile hiérarchique :

| Protocole | Rôle |
|---|---|
| **IP** (Internet Protocol) | Adressage et routage des paquets de données |
| **TCP** (Transmission Control Protocol) | Transport fiable des données, contrôle des erreurs |
| **HTTP** | Transfert de pages web (HyperText Transfer Protocol) |
| **HTTPS** | HTTP sécurisé (chiffrement TLS) |
| **FTP** | Transfert de fichiers (File Transfer Protocol) |
| **SMTP / IMAP / POP3** | Envoi et réception d'e-mails |
| **DNS** | Traduction nom de domaine → adresse IP |
| **DHCP** | Attribution automatique d'adresses IP |
:::

## L'adresse IP

:::definition
Chaque équipement connecté à Internet possède une **adresse IP** (Internet Protocol) qui l'identifie de façon unique sur le réseau.

- **IPv4** : format 4 groupes de chiffres séparés par des points. Exemple : `192.168.1.1`. Limité à ~4,3 milliards d'adresses.
- **IPv6** : format hexadécimal sur 128 bits. Exemple : `2001:0db8:85a3::8a2e:0370:7334`. 340 undécillions d'adresses.

L'adresse IP est comparable à une adresse postale : elle permet de localiser une machine sur Internet et de lui envoyer des données.
:::

## Le DNS et la résolution de noms

:::definition
Le **DNS** (*Domain Name System*) est le système qui traduit les noms de domaine lisibles par l'homme (comme `lycee.cm`) en adresses IP numériques utilisées par les machines.

Sans DNS, on devrait retenir l'adresse IP de chaque site visité. Le DNS agit comme l'«annuaire téléphonique» d'Internet.

Fonctionnement :
1. L'utilisateur tape `www.google.com` dans son navigateur.
2. Le navigateur interroge le serveur DNS configuré.
3. Le serveur DNS retourne l'adresse IP : `142.250.74.46`.
4. Le navigateur se connecte à cette adresse IP.
:::

## L'URL (adresse web)

:::definition
Une **URL** (*Uniform Resource Locator*) est l'adresse complète d'une ressource sur Internet. Sa structure est :

```
protocole://nom-de-domaine/chemin?paramètres
```

Exemple : `https://www.lycee.cm/cours/maths?chapitre=3`

| Partie | Valeur | Description |
|---|---|---|
| Protocole | `https` | Comment accéder à la ressource |
| Domaine | `www.lycee.cm` | Adresse du serveur |
| Chemin | `/cours/maths` | Page spécifique sur le serveur |
| Paramètres | `?chapitre=3` | Informations supplémentaires |
:::

## Les services Internet

:::propriete
Internet supporte de nombreux services :

| Service | Protocole | Description |
|---|---|---|
| **World Wide Web (Web)** | HTTP/HTTPS | Navigation sur des pages web via un navigateur |
| **Messagerie électronique (e-mail)** | SMTP/IMAP | Envoi et réception de courriers électroniques |
| **Messagerie instantanée** | XMPP, propriétaire | WhatsApp, Telegram, Signal… |
| **VoIP (téléphonie IP)** | SIP/RTP | Appels vocaux sur Internet (WhatsApp call, Zoom) |
| **Transfert de fichiers** | FTP/SFTP | Envoyer/recevoir des fichiers sur un serveur |
| **Streaming** | HTTP/DASH | YouTube, Netflix, Spotify |
| **Cloud computing** | HTTPS | Stockage en ligne (Google Drive, iCloud) |
:::

## Les navigateurs web

:::definition
Un **navigateur web** est un logiciel permettant d'accéder aux pages web (documents HTML) en téléchargeant leur contenu depuis des serveurs web via HTTP/HTTPS.

Principaux navigateurs :
- **Mozilla Firefox** : libre, respectueux de la vie privée.
- **Google Chrome** : très rapide, très répandu.
- **Microsoft Edge** : intégré à Windows 11.
- **Safari** : intégré à iOS et macOS.

Un **moteur de recherche** (Google, Bing, DuckDuckGo) est un service web permettant de trouver des pages web selon des mots-clés. Il est utilisé **à l'intérieur** du navigateur.
:::

:::methode
Pour effectuer une recherche efficace sur Internet :

1. Utiliser des **mots-clés précis** (pas des phrases complètes).
2. Utiliser des **guillemets** pour une expression exacte : `"photosynthèse définition"`.
3. Utiliser `site:` pour limiter à un domaine : `site:education.cm résultats BEPC`.
4. Utiliser `-mot` pour exclure un terme : `python -serpent` (chercher le langage, pas le reptile).
5. **Vérifier les sources** : préférer les sites officiels (.gov, .edu, organismes reconnus).
:::

:::retenir
- **Internet** est le réseau mondial utilisant la suite de protocoles TCP/IP.
- **IP** : adresse unique de chaque machine. **DNS** : traduit les noms de domaine en adresses IP.
- **URL** : adresse d'une ressource (protocole://domaine/chemin).
- **HTTP/HTTPS** : transfert de pages web. HTTPS est chiffré et sécurisé.
- Services Internet : Web, e-mail, messagerie instantanée, VoIP, streaming, cloud.
- **Navigateur** (Firefox, Chrome) ≠ **moteur de recherche** (Google, Bing) : le premier est le logiciel, le second est un service web.
:::
