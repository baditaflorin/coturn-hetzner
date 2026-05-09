#!/usr/bin/env bash
# Run once on the Hetzner server to open required ports via ufw.
set -e

ufw allow 22/tcp           # SSH — don't lock yourself out
ufw allow 3478/tcp         # STUN/TURN
ufw allow 3478/udp         # STUN/TURN
ufw allow 5349/tcp         # TURNS (TLS)
ufw allow 5349/udp         # TURNS (TLS)
ufw allow 49152:65535/udp  # TURN relay port range

ufw --force enable
ufw status verbose
