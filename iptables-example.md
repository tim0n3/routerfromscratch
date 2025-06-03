root@fw:~# `iptables -nvL --line-numbers`
```
Chain INPUT (policy DROP 0 packets, 0 bytes)
num   pkts bytes target     prot opt in     out     source               destination
1        5   400 ACCEPT     0    --  lo     *       0.0.0.0/0            0.0.0.0/0
2      970 74014 ACCEPT     0    --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
3        0     0 DROP       0    --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate INVALID
4        2   120 SYN_FLOOD  6    --  *      *       0.0.0.0/0            0.0.0.0/0            tcp flags:0x17/0x02
5        1    84 ACCEPT     1    --  *      *       0.0.0.0/0            0.0.0.0/0            icmptype 8 limit: avg 5/sec burst 15
6        2   684 ACCEPT     17   --  eth1   *       0.0.0.0/0            0.0.0.0/0            udp spt:68 dpt:67
7        2   120            6    --  *      *       0.0.0.0/0            0.0.0.0/0            tcp dpt:22 ctstate NEW recent: SET name: SSH side: source mask: 255.255.255.255
8        0     0 DROP       6    --  *      *       0.0.0.0/0            0.0.0.0/0            tcp dpt:22 ctstate NEW recent: UPDATE seconds: 30 hit_count: 3 TTL-Match name: SSH side: source mask: 255.255.255.255
9        2   120 ACCEPT     6    --  *      *       0.0.0.0/0            0.0.0.0/0            tcp dpt:22
10    1438  205K LOG_DROP   0    --  *      *       0.0.0.0/0            0.0.0.0/0

Chain FORWARD (policy DROP 0 packets, 0 bytes)
num   pkts bytes target     prot opt in     out     source               destination
1        0     0 ACCEPT     0    --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
2        0     0 DROP       0    --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate INVALID
3        0     0 ACCEPT     6    --  eth1   eth0    192.168.50.0/24      0.0.0.0/0            tcp dpt:53 ctstate NEW
4        0     0 ACCEPT     17   --  eth1   eth0    192.168.50.0/24      0.0.0.0/0            udp dpt:53
5        0     0 ACCEPT     6    --  eth1   eth0    192.168.50.0/24      0.0.0.0/0            tcp dpt:80 ctstate NEW
6        0     0 ACCEPT     17   --  eth1   eth0    192.168.50.0/24      0.0.0.0/0            udp dpt:80
7        0     0 ACCEPT     6    --  eth1   eth0    192.168.50.0/24      0.0.0.0/0            tcp dpt:443 ctstate NEW
8        0     0 ACCEPT     17   --  eth1   eth0    192.168.50.0/24      0.0.0.0/0            udp dpt:443
9        0     0 ACCEPT     6    --  eth1   eth0    192.168.50.0/24      0.0.0.0/0            tcp dpt:123 ctstate NEW
10       0     0 ACCEPT     17   --  eth1   eth0    192.168.50.0/24      0.0.0.0/0            udp dpt:123
11       0     0 ACCEPT     0    --  eth1   eth0    192.168.50.0/24      0.0.0.0/0            ctstate NEW
12       0     0 ACCEPT     6    --  eth0   eth1    0.0.0.0/0            192.168.50.254       tcp dpt:22 ctstate NEW
13       0     0 LOG_DROP   0    --  *      *       0.0.0.0/0            0.0.0.0/0

Chain OUTPUT (policy ACCEPT 766 packets, 327K bytes)
num   pkts bytes target     prot opt in     out     source               destination

Chain LOG_DROP (2 references)
num   pkts bytes target     prot opt in     out     source               destination
1       91 11077 LOG        0    --  *      *       0.0.0.0/0            0.0.0.0/0            limit: avg 5/min burst 10 LOG flags 0 level 4 prefix "FW DROP: "
2     1438  205K DROP       0    --  *      *       0.0.0.0/0            0.0.0.0/0

Chain SYN_FLOOD (1 references)
num   pkts bytes target     prot opt in     out     source               destination
1        2   120 RETURN     0    --  *      *       0.0.0.0/0            0.0.0.0/0            limit: avg 10/sec burst 20
2        0     0 DROP       0    --  *      *       0.0.0.0/0            0.0.0.0/0
```
