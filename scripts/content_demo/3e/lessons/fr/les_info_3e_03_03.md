# Sécurité informatique

Plus nos activités migrent vers le numérique, plus nous devenons vulnérables aux attaques. Des pirates informatiques, des logiciels malveillants et des escrocs cherchent à exploiter nos failles. La sécurité informatique est une compétence essentielle de la vie numérique.

:::definition
La **sécurité informatique** est l'ensemble des pratiques, outils et méthodes visant à protéger les systèmes informatiques, les données et les utilisateurs contre les accès non autorisés, les attaques, les pannes et les pertes de données. Elle repose sur trois piliers : **Confidentialité, Intégrité, Disponibilité** (trilogie CIA).
:::

## Les types de logiciels malveillants (malware)

:::propriete
| Type | Description | Mode de propagation |
|---|---|---|
| **Virus** | Se fixe à un fichier hôte, se reproduit lors du partage | Fichiers partagés (USB, e-mail) |
| **Ver (worm)** | Se propage seul sur le réseau sans fichier hôte | Failles réseau, e-mails de masse |
| **Cheval de Troie** | Se déguise en programme légitime | Téléchargements pirates, fausses mises à jour |
| **Ransomware** | Chiffre les données et réclame une rançon | Pièces jointes d'e-mails, sites malveillants |
| **Spyware** | Surveille les activités et vole des informations | Logiciels gratuits douteux, plugins |
| **Adware** | Affiche des publicités intempestives | Logiciels freeware, extensions de navigateur |
:::

## Les attaques les plus courantes

:::propriete
| Attaque | Description |
|---|---|
| **Phishing** | Faux e-mails/SMS imitant des organismes officiels pour voler des identifiants |
| **Attaque par force brute** | Essayer toutes les combinaisons possibles de mot de passe |
| **Attaque par dictionnaire** | Tester les mots de passe courants (noms, dates, «123456»…) |
| **Attaque de l'homme du milieu** | Intercepter les communications entre deux parties |
| **Déni de service (DoS/DDoS)** | Saturer un serveur de requêtes pour le rendre inaccessible |
| **Injection SQL** | Insérer du code malveillant dans une base de données via un formulaire |
:::

## Les outils de protection

:::propriete
| Outil | Rôle |
|---|---|
| **Antivirus** | Détecte, bloque et supprime les logiciels malveillants |
| **Pare-feu (firewall)** | Filtre le trafic réseau entrant et sortant selon des règles |
| **Mises à jour** | Corrigent les failles de sécurité connues (toujours mettre à jour !) |
| **Chiffrement** | Rend les données illisibles sans la clé (HTTPS, VPN) |
| **Authentification à deux facteurs (2FA)** | Exige un second facteur en plus du mot de passe |
| **VPN** | Chiffre la connexion et masque l'adresse IP sur un réseau public |
:::

## Les mots de passe

:::propriete
Un **mot de passe fort** doit :

| Critère | Recommandation |
|---|---|
| **Longueur** | Minimum 12 caractères |
| **Diversité** | Mélanger majuscules, minuscules, chiffres et caractères spéciaux (!@#$%) |
| **Unicité** | Un mot de passe différent pour chaque service |
| **Non devinable** | Éviter : prénom, date de naissance, «123456», «azerty» |

Exemples :
- ❌ Faible : `amara2011`, `lycee123`, `motdepasse`
- ✅ Fort : `Bj*7kT#mX2qR!`, `C@meroun&Sec@2024`

Un **gestionnaire de mots de passe** (Bitwarden, KeePass) permet de stocker des mots de passe forts et uniques sans avoir à tous les mémoriser.
:::

## La sauvegarde des données (règle 3-2-1)

:::definition
La **sauvegarde** (backup) est une copie de sécurité des données permettant de les restaurer en cas de perte, de panne ou d'attaque. La **règle 3-2-1** recommande :

- **3** copies des données (dont l'original).
- **2** supports de stockage différents (ex : disque dur interne + clé USB ou disque externe).
- **1** copie hors site (sur le cloud, chez soi, dans un autre bâtiment).

Cette règle protège contre : la panne matérielle, le ransomware, le vol, l'incendie.
:::

## Reconnaître un e-mail de phishing

:::methode
Pour repérer un e-mail frauduleux (phishing) :

1. **Vérifier l'expéditeur** : l'adresse est-elle officielle ? `service@orange-cm.com` ≠ `service@0range-cmm.tk`
2. **Repérer les fautes** : les phishings contiennent souvent des fautes d'orthographe ou de grammaire.
3. **Méfier des urgences** : «Votre compte sera bloqué dans 24h !» — les organismes sérieux n'agissent pas ainsi.
4. **Ne pas cliquer sur les liens** : survoler le lien (sans cliquer) pour voir l'URL réelle.
5. **Ne jamais saisir** ses identifiants sur un lien reçu par e-mail — aller directement sur le site officiel.
6. **Vérifier le HTTPS** : un site sécurisé commence par `https://` et affiche un cadenas.
:::

:::attention
Un cadenas HTTPS garantit que la connexion est chiffrée, mais **PAS** que le site est honnête. Un site de phishing peut aussi utiliser HTTPS ! Vérifier toujours l'adresse exacte du domaine, pas seulement le cadenas.
:::

:::retenir
- La **sécurité informatique** protège systèmes et données contre les accès non autorisés et les attaques.
- Menaces : **virus** (hôte), **ver** (autonome), **ransomware** (rançon), **phishing** (vol d'identité).
- Protection : **antivirus**, **pare-feu**, **mises à jour régulières**, **mots de passe forts**, **2FA**.
- **Règle 3-2-1** : 3 copies, 2 supports différents, 1 hors site.
- Un **mot de passe fort** : ≥ 12 caractères, mixte, unique par service.
:::
