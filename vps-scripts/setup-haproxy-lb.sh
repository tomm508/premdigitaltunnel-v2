#!/bin/bash
# ==========================================
# PremDigital - High Performance HAProxy Load Balancer
# Supports Multi-Core Worker Distribution (leastconn)
# ==========================================

RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
CYAN='\e[1;36m'
NC='\e[0m'

echo -e "${BLUE}====================================================${NC}"
echo -e "${GREEN}      INSTALLER HAPROXY HIGH-PERFORMANCE LB        ${NC}"
echo -e "${BLUE}====================================================${NC}"

# 1. Install HAProxy jika belum ada
if ! command -v haproxy &>/dev/null; then
    echo -e "${YELLOW}[1/4] Menginstall HAProxy...${NC}"
    apt-get update -y >/dev/null 2>&1
    apt-get install -y haproxy >/dev/null 2>&1
fi

# 2. Backup konfigurasi lama
mkdir -p /etc/haproxy
if [ -f /etc/haproxy/haproxy.cfg ]; then
    cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bak
fi

# Deteksi port yang aman agar tidak bentrok dengan service aktif (ws-openssh / xray)
PORT_HTTP=80
PORT_HTTPS=443
if ss -tlnp 2>/dev/null | grep -E -q ":80\s"; then
    PORT_HTTP=8880
fi
if ss -tlnp 2>/dev/null | grep -E -q ":443\s"; then
    PORT_HTTPS=8443
fi

# 3. Buat Konfigurasi HAProxy Multi-Worker Load Balancing
echo -e "${YELLOW}[2/4] Mengkonfigurasi Load Balancer (leastconn & health-check)...${NC}"
cat << EOF > /etc/haproxy/haproxy.cfg
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    user haproxy
    group haproxy
    daemon
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    maxconn 20000

defaults
    log     global
    mode    tcp
    option  tcplog
    option  dontlognull
    retries 3
    timeout connect 5000ms
    timeout client  50000ms
    timeout server  50000ms

# Statistik Web Dashboard HAProxy (Port 9000)
frontend stats_fe
    mode http
    bind *:9000
    stats enable
    stats uri /
    stats refresh 5s
    stats show-legends
    stats auth admin:premdigital

# Frontend HTTP / WS
frontend http_in
    mode tcp
    bind *:$PORT_HTTP
    default_backend ws_backend_pool

# Frontend HTTPS / TLS
frontend https_in
    mode tcp
    bind *:$PORT_HTTPS
    default_backend tls_backend_pool

# Backend WS Pools (Least Connection Balancing)
backend ws_backend_pool
    mode tcp
    balance leastconn
    server ws_openssh 127.0.0.1:80 check backup
    server ws_core1 127.0.0.1:10015 check
    server ws_core2 127.0.0.1:2082 check backup

# Backend TLS Pools (Xray VMess/VLess/Trojan)
backend tls_backend_pool
    mode tcp
    balance leastconn
    server xray_tls 127.0.0.1:443 check
    server stunnel_tls 127.0.0.1:8443 check backup
EOF

# 4. Aktifkan & Restart HAProxy
echo -e "${YELLOW}[3/4] Mengaktifkan service HAProxy...${NC}"
systemctl enable haproxy >/dev/null 2>&1
systemctl restart haproxy >/dev/null 2>&1

echo -e "${GREEN}[4/4] SUKSES! Load Balancer HAProxy berhasil dipasang.${NC}"
echo -e "Web Statistik Load Balancer : ${CYAN}http://$(curl -s -m 3 ipv4.icanhazip.com):9000${NC}"
echo -e "User Statistik              : ${YELLOW}admin${NC} | Password: ${YELLOW}premdigital${NC}"
echo -e "${BLUE}====================================================${NC}"
