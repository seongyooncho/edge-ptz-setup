#!/bin/bash
set -euo pipefail

# Minimal, idempotent nmcli setup for eth1
CON_NAME="static-eth1"
IFACE="eth1"
IPV4_ADDR="192.168.1.10/24"

log() { printf "[*] %s\n" "$*"; }
ok()  { printf "[OK] %s\n" "$*"; }
err() { printf "[ERR] %s\n" "$*" >&2; }

need_cmd() { command -v "$1" >/dev/null 2>&1 || { err "Missing command: $1"; exit 1; }; }

need_cmd nmcli
need_cmd ip
need_cmd grep

# 1) Delete "Wired connection 2" if present
if nmcli -t -f NAME connection show | grep -Fxq "Wired connection 2"; then
  log "Deleting connection: Wired connection 2"
  nmcli connection delete "Wired connection 2"
  ok "Deleted: Wired connection 2"
else
  ok "Not present: Wired connection 2"
fi

# 2) Ensure static-eth1 exists
if nmcli -t -f NAME connection show | grep -Fxq "$CON_NAME"; then
  ok "Connection exists: $CON_NAME"
else
  log "Creating $CON_NAME on $IFACE with $IPV4_ADDR"
  nmcli connection add type ethernet ifname "$IFACE" con-name "$CON_NAME" \
    ip4 "$IPV4_ADDR"
  ok "Created: $CON_NAME"
fi

ok "Done."
