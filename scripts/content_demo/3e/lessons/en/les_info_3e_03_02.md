# The Internet: protocols and services

The Internet is the world's largest computer network: billions of devices interconnected across all continents. How does it work? What services does it offer? How can we use it effectively and safely?

:::definition
The **Internet** (*Interconnected Networks*) is a worldwide network of computers and devices using the **TCP/IP** protocol suite. It is not a single centralised network, but a set of millions of local networks connected to each other.

The Internet belongs to no one: it is managed by international organisations (ICANN, IETF, W3C…) and relies on open standards.
:::

## Fundamental protocols

:::definition
A **protocol** is a set of rules defining how data is exchanged between computing devices. Internet protocols form a hierarchical stack:

| Protocol | Role |
|---|---|
| **IP** (Internet Protocol) | Addressing and routing of data packets |
| **TCP** (Transmission Control Protocol) | Reliable data transport, error control |
| **HTTP** | Web page transfer (HyperText Transfer Protocol) |
| **HTTPS** | Secure HTTP (TLS encryption) |
| **FTP** | File transfer (File Transfer Protocol) |
| **SMTP / IMAP / POP3** | Sending and receiving emails |
| **DNS** | Domain name → IP address translation |
| **DHCP** | Automatic IP address assignment |
:::

## The IP address

:::definition
Every device connected to the Internet has an **IP address** (Internet Protocol) that uniquely identifies it on the network.

- **IPv4**: format of 4 groups of digits separated by dots. Example: `192.168.1.1`. Limited to ~4.3 billion addresses.
- **IPv6**: hexadecimal format over 128 bits. Example: `2001:0db8:85a3::8a2e:0370:7334`. 340 undecillion addresses.

An IP address is like a postal address: it allows a machine to be located on the Internet and data to be sent to it.
:::

## DNS and name resolution

:::definition
The **DNS** (*Domain Name System*) is the system that translates human-readable domain names (such as `lycee.cm`) into numeric IP addresses used by machines.

Without DNS, you would have to remember the IP address of every site you visit. DNS acts as the Internet's «phone book».

How it works:
1. The user types `www.google.com` in their browser.
2. The browser queries the configured DNS server.
3. The DNS server returns the IP address: `142.250.74.46`.
4. The browser connects to this IP address.
:::

## The URL (web address)

:::definition
A **URL** (*Uniform Resource Locator*) is the complete address of a resource on the Internet. Its structure is:

```
protocol://domain-name/path?parameters
```

Example: `https://www.lycee.cm/courses/maths?chapter=3`

| Part | Value | Description |
|---|---|---|
| Protocol | `https` | How to access the resource |
| Domain | `www.lycee.cm` | Server address |
| Path | `/courses/maths` | Specific page on the server |
| Parameters | `?chapter=3` | Additional information |
:::

## Internet services

:::propriete
The Internet supports many services:

| Service | Protocol | Description |
|---|---|---|
| **World Wide Web** | HTTP/HTTPS | Browsing web pages via a browser |
| **Email** | SMTP/IMAP | Sending and receiving electronic mail |
| **Instant messaging** | XMPP, proprietary | WhatsApp, Telegram, Signal… |
| **VoIP (Internet telephony)** | SIP/RTP | Voice calls over Internet (WhatsApp call, Zoom) |
| **File transfer** | FTP/SFTP | Sending/receiving files on a server |
| **Streaming** | HTTP/DASH | YouTube, Netflix, Spotify |
| **Cloud computing** | HTTPS | Online storage (Google Drive, iCloud) |
:::

## Web browsers

:::definition
A **web browser** is software that accesses web pages (HTML documents) by downloading their content from web servers via HTTP/HTTPS.

Main browsers:
- **Mozilla Firefox**: open source, privacy-friendly.
- **Google Chrome**: very fast, very widespread.
- **Microsoft Edge**: built into Windows 11.
- **Safari**: built into iOS and macOS.

A **search engine** (Google, Bing, DuckDuckGo) is a web service for finding web pages by keyword. It is used **inside** the browser.
:::

:::methode
To search effectively on the Internet:

1. Use **precise keywords** (not complete sentences).
2. Use **quotation marks** for an exact phrase: `"photosynthesis definition"`.
3. Use `site:` to limit to a domain: `site:education.gov BEPC results`.
4. Use `-word` to exclude a term: `python -snake` (searching for the language, not the reptile).
5. **Check sources**: prefer official sites (.gov, .edu, recognised organisations).
:::

:::retenir
- The **Internet** is the worldwide network using the TCP/IP protocol suite.
- **IP**: unique address for each machine. **DNS**: translates domain names into IP addresses.
- **URL**: address of a resource (protocol://domain/path).
- **HTTP/HTTPS**: web page transfer. HTTPS is encrypted and secure.
- Internet services: Web, email, instant messaging, VoIP, streaming, cloud.
- **Browser** (Firefox, Chrome) ≠ **search engine** (Google, Bing): the first is the software, the second is a web service.
:::
