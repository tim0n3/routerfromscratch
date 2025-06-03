#!/bin/sh
# Two-NIC router & firewall for Debian 12
# WAN = eth0 (DHCP) | LAN = eth1 (192.168.50.0/24)
set -e

WAN_IF="eth0"
LAN_IF="eth1"
LAN_NET="192.168.50.0/24"
LAN_GW="192.168.50.254"

# Port-forward: WAN :2222 → 192.168.50.254:22
DNAT_WAN_PORT=2222
DNAT_LAN_IP="192.168.50.254"
DNAT_LAN_PORT=22

# ---------- flush & baseline policies ----------
iptables -t filter -F
iptables -t filter -X
iptables -t nat    -F
iptables -t nat    -X
iptables -t mangle -F
iptables -t mangle -X

iptables -P INPUT   DROP
iptables -P FORWARD DROP
iptables -P OUTPUT  ACCEPT     # outbound kept open

# ---------- trusted basics ----------
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT   -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT   -m conntrack --ctstate INVALID -j DROP
iptables -A FORWARD -m conntrack --ctstate INVALID -j DROP

# ---------- anti-SYN-flood ----------
iptables -N SYN_FLOOD
iptables -A INPUT -p tcp --syn -j SYN_FLOOD
iptables -A SYN_FLOOD -m limit --limit 10/s --limit-burst 20 -j RETURN
iptables -A SYN_FLOOD -j DROP

# ---------- ICMP (ping) – rate-limited ----------
iptables -A INPUT -p icmp --icmp-type echo-request \
         -m limit --limit 5/s --limit-burst 15 -j ACCEPT

# ---------- DHCP server on LAN ----------
iptables -A INPUT -i ${LAN_IF} -p udp --sport 68 --dport 67 -j ACCEPT

# ---------- SSH exposed (LAN & WAN) ----------
iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW \
         -m recent --name SSH --set
iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW \
         -m recent --name SSH --update --seconds 30 --hitcount 3 --rttl -j DROP
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# ---------- LAN → WAN essentials ----------
for P in 53 80 443 123 ; do
  iptables -A FORWARD -i ${LAN_IF} -o ${WAN_IF} -s ${LAN_NET} \
           -p tcp --dport $P -m conntrack --ctstate NEW -j ACCEPT
  iptables -A FORWARD -i ${LAN_IF} -o ${WAN_IF} -s ${LAN_NET} \
           -p udp --dport $P -j ACCEPT
done
# Catch-all forward for other traffic
iptables -A FORWARD -i ${LAN_IF} -o ${WAN_IF} -s ${LAN_NET} \
         -m conntrack --ctstate NEW -j ACCEPT

# ---------- WAN → LAN port-forward ----------
iptables -t nat -A PREROUTING -i ${WAN_IF} -p tcp --dport ${DNAT_WAN_PORT} \
         -j DNAT --to-destination ${DNAT_LAN_IP}:${DNAT_LAN_PORT}

iptables -A FORWARD -p tcp -i ${WAN_IF} -o ${LAN_IF} \
         -d ${DNAT_LAN_IP} --dport ${DNAT_LAN_PORT} \
         -m conntrack --ctstate NEW -j ACCEPT

# ---------- NAT masquerade ----------
iptables -t nat -A POSTROUTING -o ${WAN_IF} -s ${LAN_NET} -j MASQUERADE

# ---------- minimal drop logging ----------
iptables -N LOG_DROP
iptables -A LOG_DROP -m limit --limit 5/min --limit-burst 10 \
         -j LOG --log-prefix "FW DROP: " --log-level 4
iptables -A LOG_DROP -j DROP

iptables -A INPUT   -j LOG_DROP
iptables -A FORWARD -j LOG_DROP
