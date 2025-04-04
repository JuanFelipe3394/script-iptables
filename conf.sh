#!/bin/bash

# Limpar regras existentes
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X

# Configuração de interfaces
LAN_IFACE="enp0s8"    # Rede interna (172.16.0.0/24)
WAN_IFACE="enp0s3"    # Placa NAT (internet)

# Habilitar roteamento
echo 1 > /proc/sys/net/ipv4/ip_forward

# Regras da cadeia NAT
iptables -t nat -A POSTROUTING -o $WAN_IFACE -j MASQUERADE

# Permitir tráfego de encaminhamento entre LAN e WAN
iptables -A FORWARD -i $LAN_IFACE -o $WAN_IFACE -j ACCEPT
iptables -A FORWARD -i $WAN_IFACE -o $LAN_IFACE -m state --state ESTABLISHED,RELATED -j ACCEPT

# Liberar tráfego SSH
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A OUTPUT -p tcp --sport 22 -j ACCEPT

# Liberar portas do Samba4
iptables -A INPUT -p tcp -m multiport --dports 137,138,139,445 -j ACCEPT
iptables -A INPUT -p udp -m multiport --dports 137,138,139,445 -j ACCEPT

# Permitir tráfego na rede interna (172.16.0.0/24)
iptables -A INPUT -i $LAN_IFACE -s 172.16.0.0/24 -j ACCEPT
iptables -A OUTPUT -o $LAN_IFACE -d 172.16.0.0/24 -j ACCEPT

# Permitir conexões internas (loopback)
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Política padrão de bloqueio (opcional, para maior segurança)
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Permitir tráfego essencial (conexões já estabelecidas)
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
