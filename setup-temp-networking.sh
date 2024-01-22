#!/bin/bash

set -ueo pipefail

MAC=$(hexdump -vn3 -e '/3 "52:54:00"' -e '/1 ":%02x"' -e '"\n"' /dev/urandom)

ip link add name k8s-br0 type bridge
ip link set k8s-br0 type bridge stp_state 1
ip link add k8s-br0-nic type dummy

ip link set dev k8s-br0-nic address $MAC
ip link set k8s-br0-nic master k8s-br0

ip addr add 192.168.100.1/24 dev k8s-br0 broadcast 192.168.100.255

ip link set k8s-br0 up
ip link set k8s-br0-nic up

cat << EOF > ip-masquerade.txt
*mangle
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
# DHCP packets sent to VMs have no checksum (due to a longstanding bug).
-A POSTROUTING -o k8s-br0 -p udp -m udp --dport 68 -j CHECKSUM --checksum-fill
COMMIT

*nat
:PREROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
# Do not masquerade to these reserved address blocks.
-A POSTROUTING -s 192.168.100.0/24 -d 224.0.0.0/24 -j RETURN
-A POSTROUTING -s 192.168.100.0/24 -d 255.255.255.255/32 -j RETURN
# Masquerade all packets going from VMs to the LAN/Internet.
-A POSTROUTING -s 192.168.100.0/24 ! -d 192.168.100.0/24 -p tcp -j MASQUERADE --to-ports 1024-65535
-A POSTROUTING -s 192.168.100.0/24 ! -d 192.168.100.0/24 -p udp -j MASQUERADE --to-ports 1024-65535
-A POSTROUTING -s 192.168.100.0/24 ! -d 192.168.100.0/24 -j MASQUERADE
COMMIT

*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
# Allow basic INPUT traffic.
-A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -p icmp --icmp-type 8 -m conntrack --ctstate NEW -j ACCEPT
# Accept SSH connections.
-A INPUT -p tcp -m tcp --syn -m conntrack --ctstate NEW --dport 22 -j ACCEPT
# Accept DNS (port 53) and DHCP (port 67) packets from VMs.
-A INPUT -i k8s-br0 -p udp -m udp -m multiport --dports 53,67 -j ACCEPT
-A INPUT -i k8s-br0 -p tcp -m tcp -m multiport --dports 53,67 -j ACCEPT
# Reject everything else.
-A INPUT -m conntrack --ctstate INVALID -j DROP
-A INPUT -p tcp -m tcp -j REJECT --reject-with tcp-reset
-A INPUT -j REJECT --reject-with icmp-port-unreachable

# Allow established traffic to the private subnet.
-A FORWARD -d 192.168.100.0/24 -o k8s-br0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
# Allow outbound traffic from the private subnet.
-A FORWARD -s 192.168.100.0/24 -i k8s-br0 -j ACCEPT
# Allow traffic between virtual machines.
-A FORWARD -i k8s-br0 -o k8s-br0 -j ACCEPT
# Reject everything else.
-A FORWARD -i k8s-br0 -j REJECT --reject-with icmp-port-unreachable
-A FORWARD -o k8s-br0 -j REJECT --reject-with icmp-port-unreachable
COMMIT
EOF

iptables-restore -n -v < ip-masquerade.txt

dnsmasq \
    --conf-file=/var/lib/dnsmasq/k8s-br0/dnsmasq.conf \
    --pid-file=/var/run/dnsmasq/k8s-br0.pid

rm ip-masquerade.txt
