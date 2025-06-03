#!/usr/bin/env bash
#
# Idempotent, one-shot installer for the two-NIC Debian 12 router
# ───────────────────────────────────────────────────────────────
# • Sets execute bits on required shell files (step 0)
# • Runs dependency installer
# • Deploys kernel tweaks, firewall, DHCP, etc.
# • Safe to re-run: only overwrites files that actually changed
#
set -euo pipefail

### 0  Set permissions for each shell file ──────────────────────
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

for f in "$SCRIPT_DIR/install-deps.sh" \
         "$SCRIPT_DIR/fw.sh"            \
         "$SCRIPT_DIR/setup.sh"; do
  if [ -f "$f" ] && [ ! -x "$f" ]; then
    chmod +x "$f"
  fi
done

### 1  Sanity checks  ────────────────────────────────────────────
[ "$(id -u)" -eq 0 ] || { echo "Run as root (sudo)"; exit 1; }

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
stamp() { printf "[%s] %s\n" "$(date +'%F %T')" "$*"; }

backup_file() {
  # backup_file /etc/foo.conf
  local target="$1"
  [ -e "$target" ] || return 0        # nothing to back up
  local ts; ts="$(date +'%F_%H%M%S')"
  cp -a "$target" "${target}.${ts}.bak"
}

safe_install() {
  # safe_install src_file dest_file mode
  local src="$1" dst="$2" mode="${3:-}"
  if ! cmp -s "$src" "$dst" 2>/dev/null; then
    stamp "Updating $dst"
    backup_file "$dst"
    install -m "${mode:-644}" "$src" "$dst"
  else
    stamp "$dst already up-to-date"
  fi
}

enable_service() {
  systemctl enable --now "$1"
}

### 2  Run dependency installer (always safe to repeat) ────────────────
if [ -x "$SCRIPT_DIR/install-deps.sh" ]; then
  stamp "Running install-deps.sh"
  "$SCRIPT_DIR/install-deps.sh"
else
  echo "Missing or non-executable install-deps.sh"; exit 1
fi

### 3  Deploy configuration files ───────────────────────────────
safe_install "$SCRIPT_DIR/99-router.conf"  "/etc/sysctl.d/99-router.conf"
safe_install "$SCRIPT_DIR/dhcpd.conf"      "/etc/dhcp/dhcpd.conf"
safe_install "$SCRIPT_DIR/isc-dhcp-server" "/etc/default/isc-dhcp-server"
safe_install "$SCRIPT_DIR/interfaces"      "/etc/network/interfaces" 644
chmod 644 /etc/network/interfaces

### 4  Apply kernel tweaks ──────────────────────────────────────
stamp "Applying sysctl settings"
sysctl --system >/dev/null

### 5  Bring up networking (idempotent) ──────────────────────────
stamp "Restarting networking"
systemctl restart networking || true     # tolerate if already fine

### 6  Run / persist firewall ──────────────────────────────────
if [ -x "$SCRIPT_DIR/fw.sh" ]; then
  stamp "Executing firewall script"
  "$SCRIPT_DIR/fw.sh"
  iptables-save > /etc/iptables/rules.v4
else
  echo "Missing or non-executable fw.sh"; exit 1
fi

### 7  Enable / restart services ────────────────────────────────
enable_service netfilter-persistent
enable_service isc-dhcp-server
enable_service fail2ban || true          # optional package
enable_service unattended-upgrades || true

### 8  Done ─────────────────────────────────────────────────────
stamp "Router setup complete"
exit 0
