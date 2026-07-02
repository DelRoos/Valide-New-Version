# Computer network architecture

Sending a message, sharing a file, accessing a remote printer: all of this is made possible by computer networks. Understanding their architecture means understanding how computers communicate.

:::definition
A **computer network** is a set of computing devices (computers, printers, servers, smartphones…) interconnected to **share resources** (files, printers, Internet connection) and **communicate** with each other.
:::

## Types of networks by size

:::propriete
| Type | Full name | Range | Examples |
|---|---|---|---|
| **PAN** | Personal Area Network | A few metres | Bluetooth, infrared |
| **LAN** | Local Area Network | Building, campus | School or company network |
| **MAN** | Metropolitan Area Network | City | City cable network |
| **WAN** | Wide Area Network | Country, continent, world | The Internet |

The **LAN** (local area network) is the most common type of network in schools and businesses in Cameroon.
:::

## Network topologies

:::definition
The **topology** of a network describes how devices are connected to each other. The most common topologies are:

- **Star topology**: all devices are connected to a central point (switch/hub). If one cable fails, only the affected device is disconnected. **This is the most widely used topology today.**
- **Bus topology**: all devices are connected to a common cable. A cable failure cuts the entire network.
- **Ring topology**: devices are connected in a closed loop. Data flows in one direction.
:::

:::figure
```
Star topology:

   [PC1]   [PC2]
     \       /
      [Switch]
     /       \
   [PC3]   [Printer]

Bus topology:

[PC1]--[PC2]--[PC3]--[PC4]--[PC5]
       (common cable)

Ring topology:

[PC1] → [PC2] → [PC3]
  ↑                ↓
[PC5] ← [PC4] ←←←←
```
:::

## Network equipment

:::propriete
| Equipment | Role |
|---|---|
| **Network card (NIC)** | Interface between computer and network (Ethernet or Wi-Fi) |
| **Ethernet cable** | Physical data transmission medium (category 5e, 6) |
| **Hub** | Simple concentrator: broadcasts data to all ports (obsolete) |
| **Switch** | Intelligent concentrator: sends data only to the destination port |
| **Router** | Connects different networks and chooses the best path for data |
| **Modem** | Converts digital signal to analogue signal (phone line, fibre) |
| **Wi-Fi access point** | Enables wireless connections (Wi-Fi 5 GHz, 2.4 GHz) |
:::

## Client-server and peer-to-peer architecture

:::definition
There are two fundamental network architectures:

**Client-server architecture:**
- One or more **servers** centralise resources (files, databases, applications).
- **Clients** make requests to the server and receive responses.
- Advantages: centralised management, security, reliability. Used in businesses, schools, the Internet.

**Peer-to-peer (P2P) architecture:**
- Each device is both client and server.
- Resources are distributed among all devices.
- Advantages: no central server, less expensive. Disadvantages: less secure, harder to manage.
:::

## Networks in Cameroon

:::exemple
In Cameroon, computer networks are present in many contexts:

- **Schools and universities**: computer laboratories on a local area network (LAN) to share an Internet connection.
- **Businesses**: local networks with file servers and shared printers.
- **Mobile Money (MTN, Orange)**: WAN connecting branches across the country.
- **Government**: government network (SIGIPES for civil servants).
- **Cybercafés**: shared Internet access via a router and multiple client workstations.
:::

:::methode
To configure a simple local area network (star LAN) in a computer room:

1. Install a **switch** at the centre of the room.
2. Connect each computer to the switch with an **Ethernet cable**.
3. Configure the **IP addresses** of each machine (192.168.1.1, 192.168.1.2, etc.).
4. Connect the switch to a **router/modem** if Internet sharing is required.
5. Test the connection: `ping 192.168.1.1` from each workstation.
:::

:::retenir
- A **computer network** interconnects devices to share resources and communicate.
- Types: **PAN** (personal), **LAN** (local), **MAN** (metropolitan), **WAN** (wide).
- Topologies: **star** (most widely used), **bus**, **ring**.
- Key equipment: switch (intelligent concentrator), router (connects networks), modem (signal conversion).
- Architectures: **client-server** (centralised) and **peer-to-peer P2P** (distributed).
:::
