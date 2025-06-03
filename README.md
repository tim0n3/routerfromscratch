# Two-NIC Debian 12 Router & Firewall

A lightweight virtual router/firewall for small labs, built with **iptables** and **ISC-DHCP-Server** on Debian 12 “bookworm”.  
It routes between a DHCP-fed **WAN** (`eth0`) and a static-IP **LAN** (`eth1`, `192.168.50.0/24`).

---

## 1 - Features

* **IPv4 routing & NAT** (MASQUERADE)  
* **Stateful firewall** with sensible defaults  
* **Basic hardening** – SYN-cookies, rp-filter, …  
* **Rate-limited SSH exposure** on both WAN & LAN  
* **Port-forward:** `WAN:2222 → 192.168.50.254:22`  
* **DHCP server** (12 h leases, 192.168.50.1-243)  
* **Optional extras** – fail2ban, unattended-upgrades

---

## 2 - File Map

| File | Purpose |
|------|---------|
| `/etc/network/interfaces` | Interface definitions (WAN = DHCP, LAN = static) |
| `/etc/sysctl.d/99-router.conf` | Kernel routing & hardening tweaks |
| `/usr/local/sbin/fw.sh` | Complete iptables ruleset (run once, then persisted) |
| `/etc/iptables/rules.v4` | Saved rules loaded by `netfilter-persistent` |
| `/etc/dhcp/dhcpd.conf` | DHCP scope & options |
| `/etc/default/isc-dhcp-server` | Tells DHCP daemon to bind to `eth1` |
| `/etc/fail2ban/jail.local` | (Optional) local overrides |
| `maintenance.md` | Routine tasks & health checks |

---

## 3 - Quick Start


### I.  Install packages
```
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt install -y \
  iptables iptables-persistent isc-dhcp-server \
  rsyslog logrotate fail2ban unattended-upgrades \
  net-tools iproute2 dnsutils curl vim less
```
### II.  Copy the config files above into place
```
sudo cp interfaces /etc/network/interfaces
sudo cp 99-router.conf /etc/sysctl.d/
sudo cp fw.sh /usr/local/sbin/fw.sh && sudo chmod +x /usr/local/sbin/fw.sh
sudo cp dhcpd.conf /etc/dhcp/dhcpd.conf
sudo cp isc-dhcp-server /etc/default/isc-dhcp-server
```
### III.  Enable tweaks & firewall
```
sudo sysctl --system
sudo /usr/local/sbin/fw.sh
sudo sh -c 'iptables-save > /etc/iptables/rules.v4'
```
### IV.  Enable services
```
sudo systemctl enable --now netfilter-persistent isc-dhcp-server fail2ban
```
## 4 - Verification

1. **LAN host** should obtain `192.168.50.x` (1-243) with gateway/DNS `192.168.50.254`.
2. `ping 1.1.1.1` and `dig debian.org` from the LAN should succeed.
3. From outside, `ssh -p 2222 <WAN_IP>` should land on the router’s local SSH.
4. Check counters: `sudo iptables -nvL --line-numbers`.

---

## 5 - Troubleshooting

| Symptom                          | Fix                                                                      |
| -------------------------------- | ------------------------------------------------------------------------ |
| LAN client gets **no DHCP**      | `sudo journalctl -u isc-dhcp-server` – ensure `eth1` up & scope correct. |
| **No internet** on LAN           | `iptables -t nat -L POSTROUTING -nv` – is MASQUERADE rule present?       |
| **SSH brute-force spam** in logs | Verify fail2ban running: `sudo fail2ban-client status sshd`.             |
| Over-flowing **conntrack table** | Tune `nf_conntrack_max` in `99-router.conf` (see `maintenance.md`).      |

---

Happy routing!
