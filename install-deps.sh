#!/bin/sh

sudo apt update && sudo DEBIAN_FRONTEND=noninteractive \
  apt install -y --no-install-recommends \
    iptables iptables-persistent \
    isc-dhcp-server \
    rsyslog logrotate fail2ban \
    unattended-upgrades \
    net-tools iproute2 dnsutils \
    curl vim less
