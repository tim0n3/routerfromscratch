### `maintenance.md`

# Router Maintenance Guide

Keep the lab router secure, updated and reliable with the tasks below.  
All cron/automation suggestions assume local **root** privileges.

---

## 1 - Daily

| Task | Command / Check | Notes |
|------|-----------------|-------|
| **Package security updates** | _Automated by_ `unattended-upgrades` | Verify logs: `/var/log/unattended-upgrades/`. |
| **Log sanity** | `journalctl -p 3 -b` | Look for new errors (priority ≤ err). |
| **Conntrack utilisation** | `conntrack -C` | If > 80 % of `nf_conntrack_max` (≈13 k) raise the limit. |

---

## 2 - Weekly

I. **Manual `apt full-upgrade`**  
   ```
   sudo apt update && sudo apt full-upgrade
   sudo reboot   # kernel/libc bumps
   ```

II. **Backup configs**

   ```
   sudo tar czf /root/router-configs-"$(date +%F)".tgz \
        /etc /usr/local/sbin/fw.sh /etc/iptables/rules.v4
   # copy to NAS / remote
   ```

III. **Fail2ban review**

   ```
   sudo fail2ban-client status sshd
   sudo zcat /var/log/fail2ban.log.*.gz | grep Ban | wc -l
   ```

---

## 3 - Monthly

* **Firewall audit** – run `iptables -S` and confirm rules still match policy.
* **DHCP lease utilisation** – `grep "^lease" /var/lib/dhcp/dhcpd.leases | wc -l`; if consistently > 200, shrink exclusion range or enlarge subnet.
* **Logrotate health** – `sudo logrotate -d /etc/logrotate.conf` (dry-run).
* **Snapshot VM** – save a clean snapshot after updates & tests.

---

## 4 - When Changing Rules

1. Edit `/usr/local/sbin/fw.sh`.
2. Run it: `sudo /usr/local/sbin/fw.sh`.
3. Test connectivity **before** saving:

   ```bash
   sudo iptables-save > /etc/iptables/rules.v4
   sudo systemctl restart netfilter-persistent
   ```

---

## 5 - Resource Tuning

| Knob                  | When to Change                   | Example                         
| --------------------- | -------------------------------- | -------------------------------- |
| `nf_conntrack_max`    | > 80 % utilisation               | `cat 32768 >> /proc/sys/net/netfilter/nf_conntrack_max` |
| `SYN_FLOOD` limits    | Frequent false-positives in logs | Increase `--limit` or `--burst`. |
| DHCP `max-lease-time` | Need shorter leases              | Lower to e.g. `21600` (6 h).     |

Add permanent kernel tweaks in `/etc/sysctl.d/99-router.conf` and run `sudo sysctl --system`.

---

## 6 - Disaster Recovery

| Scenario                    | Recovery                                                                           |
| --------------------------- | ---------------------------------------------------------------------------------- |
| Corrupt iptables rules      | Boot single-user, move `/etc/iptables/rules.v4` aside, reboot.                     |
| Mis-edited interfaces file  | Attach to console, `nano /etc/network/interfaces`, `systemctl restart networking`. |
| VM won’t boot after upgrade | Roll back to last snapshot.                                                        |

---

Stay safe – automate the boring stuff, test after every change, and keep backups off-box!
