# Computer security

The more our activities move to the digital world, the more vulnerable we become to attacks. Hackers, malicious software and fraudsters seek to exploit our weaknesses. Computer security is an essential skill for digital life.

:::definition
**Computer security** is the set of practices, tools and methods designed to protect computer systems, data and users against unauthorised access, attacks, failures and data loss. It rests on three pillars: **Confidentiality, Integrity, Availability** (the CIA triad).
:::

## Types of malicious software (malware)

:::propriete
| Type | Description | How it spreads |
|---|---|---|
| **Virus** | Attaches to a host file, reproduces when shared | Shared files (USB, email) |
| **Worm** | Spreads alone on the network without a host file | Network vulnerabilities, mass emails |
| **Trojan horse** | Disguises itself as legitimate software | Pirated downloads, fake updates |
| **Ransomware** | Encrypts data and demands a ransom | Email attachments, malicious websites |
| **Spyware** | Monitors activities and steals information | Dubious freeware, plugins |
| **Adware** | Displays intrusive advertisements | Freeware, browser extensions |
:::

## Most common attacks

:::propriete
| Attack | Description |
|---|---|
| **Phishing** | Fake emails/texts imitating official organisations to steal credentials |
| **Brute force** | Trying all possible password combinations |
| **Dictionary attack** | Testing common passwords (names, dates, «123456»…) |
| **Man-in-the-middle** | Intercepting communications between two parties |
| **Denial of service (DoS/DDoS)** | Flooding a server with requests to make it unavailable |
| **SQL injection** | Inserting malicious code into a database via a form |
:::

## Protection tools

:::propriete
| Tool | Role |
|---|---|
| **Antivirus** | Detects, blocks and removes malicious software |
| **Firewall** | Filters incoming and outgoing network traffic according to rules |
| **Updates** | Fix known security vulnerabilities (always update!) |
| **Encryption** | Makes data unreadable without the key (HTTPS, VPN) |
| **Two-factor authentication (2FA)** | Requires a second factor in addition to the password |
| **VPN** | Encrypts the connection and hides the IP address on a public network |
:::

## Passwords

:::propriete
A **strong password** must:

| Criterion | Recommendation |
|---|---|
| **Length** | Minimum 12 characters |
| **Diversity** | Mix uppercase, lowercase, digits and special characters (!@#$%) |
| **Uniqueness** | A different password for each service |
| **Not guessable** | Avoid: first name, date of birth, «123456», «qwerty» |

Examples:
- ❌ Weak: `amara2011`, `school123`, `password`
- ✅ Strong: `Bj*7kT#mX2qR!`, `C@meroon&Sec@2024`

A **password manager** (Bitwarden, KeePass) allows you to store strong, unique passwords without having to remember them all.
:::

## Data backup (3-2-1 rule)

:::definition
A **backup** is a security copy of data allowing it to be restored in case of loss, failure or attack. The **3-2-1 rule** recommends:

- **3** copies of data (including the original).
- **2** different storage media (e.g. internal hard drive + USB key or external drive).
- **1** offsite copy (on the cloud, at home, in another building).

This rule protects against: hardware failure, ransomware, theft, fire.
:::

## Recognising a phishing email

:::methode
To spot a fraudulent (phishing) email:

1. **Check the sender**: is the address official? `service@orange.cm` ≠ `service@0range-cmm.tk`
2. **Look for mistakes**: phishing emails often contain spelling or grammar errors.
3. **Beware of urgency**: «Your account will be blocked in 24h!» — reputable organisations do not act like this.
4. **Do not click links**: hover over the link (without clicking) to see the actual URL.
5. **Never enter** your credentials on a link received by email — go directly to the official website.
6. **Check for HTTPS**: a secure site starts with `https://` and displays a padlock.
:::

:::attention
A HTTPS padlock guarantees that the connection is encrypted, but **NOT** that the site is honest. A phishing site can also use HTTPS! Always check the exact domain address, not just the padlock.
:::

:::retenir
- **Computer security** protects systems and data against unauthorised access and attacks.
- Threats: **virus** (host file), **worm** (autonomous), **ransomware** (ransom), **phishing** (identity theft).
- Protection: **antivirus**, **firewall**, **regular updates**, **strong passwords**, **2FA**.
- **3-2-1 rule**: 3 copies, 2 different media, 1 offsite.
- A **strong password**: ≥ 12 characters, mixed, unique per service.
:::
