# coturn-hetzner

Self-hosted TURN relay server on a Hetzner VPS using Docker. Fixes WebRTC connections stuck at "connecting" when peers are on different networks or mobile carriers.

**Cost: ~4 €/month** (Hetzner CX22 — 2 vCPU, 4 GB RAM)

---

## What this solves

WebRTC needs a relay (TURN server) when two peers can't connect directly — which happens constantly with mobile networks, corporate firewalls, or different ISPs. Without it, the mesh stays at `connecting` permanently and no data syncs.

STUN alone (e.g. Google's `stun.l.google.com`) only helps peers discover their public IPs. It doesn't relay traffic. TURN does.

---

## Prerequisites

- A Hetzner account — [hetzner.com](https://hetzner.com)
- Server running Ubuntu 22.04 or Debian 12
- Docker + Docker Compose installed on the server
- (Optional) A domain pointing at the server IP for TLS

---

## Setup

### 1. Create the server

In the Hetzner console → **Create server**:
- Image: Ubuntu 22.04
- Type: CX22 (~4 €/month) or CX11 (~3 €/month) for lighter load
- Add your SSH key

Note the public IPv4 shown after creation.

### 2. Install Docker on the server

```sh
ssh root@YOUR_SERVER_IP
curl -fsSL https://get.docker.com | sh
```

### 3. Clone this repo on the server

```sh
git clone https://github.com/baditaflorin/coturn-hetzner.git
cd coturn-hetzner
```

### 4. Configure

```sh
cp .env.example .env
nano .env
```

```env
SERVER_IP=1.2.3.4               # your Hetzner server's public IPv4
TURN_DOMAIN=turn.yourdomain.com # or just the IP if skipping TLS
TURN_USER=myuser
TURN_PASS=a-strong-random-password
```

### 5. Open firewall ports

```sh
chmod +x hetzner-firewall.sh
./hetzner-firewall.sh
```

> If you use Hetzner's cloud firewall instead of ufw, allow the same ports there.

### 6. Start

```sh
make up
make logs   # watch startup — ready when you see "Total: listening on port"
```

---

## Test it works

Go to **[webrtc.github.io/samples/src/content/peerconnection/trickle-ice](https://webrtc.github.io/samples/src/content/peerconnection/trickle-ice/)** and add your server:

```
URI:       turn:YOUR_SERVER_IP:3478
Username:  myuser
Password:  your-password
```

Click **Gather candidates**. You must see `relay` type candidates. If you only see `host` or `srflx`, the relay ports are blocked — check the firewall.

---

## TLS (recommended for mobile)

Some mobile carriers block plain UDP entirely. TLS on port 5349 (`turns:`) gets through almost everything.

Requires a domain name pointing at your server.

```sh
make certs TURN_DOMAIN=turn.yourdomain.com
make down && make up
```

Test with `turns:turn.yourdomain.com:5349` in the ICE tester above.

---

## Use with anon-conf-poll

In the **Connection** panel → **Add server**:

```
URL:        turn:YOUR_SERVER_IP:3478
Username:   myuser
Credential: your-password
```

With TLS:
```
URL:        turns:turn.yourdomain.com:5349
Username:   myuser
Credential: your-password
```

Click **Add server**, reload the page. The mesh should reach `connected` instead of staying at `connecting`.

---

## Commands

| Command | What it does |
|---|---|
| `make up` | Start coturn in the background |
| `make down` | Stop |
| `make logs` | Tail logs |
| `make test` | Quick connectivity check |
| `make certs` | Get a Let's Encrypt TLS cert |

---

## Ports

| Port | Protocol | Purpose |
|---|---|---|
| 3478 | TCP + UDP | STUN / TURN |
| 5349 | TCP + UDP | TURNS (TLS) |
| 49152–65535 | UDP | TURN relay traffic |

The relay range (49152–65535 UDP) is the one most commonly forgotten. Without it, coturn starts but can't actually relay.

---

## Troubleshooting

**Still stuck at "connecting":** the UDP relay range is almost certainly blocked. Double-check ufw and the Hetzner cloud firewall.

**No relay candidates:** `SERVER_IP` in `.env` must match the server's exact public IP.

**TLS cert errors:** make sure the domain resolves to the server before running `make certs`.
