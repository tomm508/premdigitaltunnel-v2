#!/bin/bash
# ========================================================
# PremDigital Turbo Network & Speed Optimizer
# Solusi Anti-Lelet, Anti-DC & Speedtest/Upload Lancar
# ========================================================

echo -e "\e[32m[INFO] Mengaktifkan Turbo BBR & TCP Buffer Optimization...\e[0m"

# 1. Sysctl Network Optimization
cat > /etc/sysctl.d/99-premdigital-turbo.conf << 'EOF'
# TCP BBR Congestion Control
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

# TCP Buffer & Window Scaling (Speedtest & Upload Lancar)
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.rmem_default = 1048576
net.core.wmem_default = 1048576
net.ipv4.tcp_rmem = 4096 1048576 67108864
net.ipv4.tcp_wmem = 4096 1048576 67108864

# Anti MTU Black Hole (Mencegah upload video/speedtest macet)
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_base_mss = 1024

# Fast Open & TCP Tweaks
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_notsent_lowat = 16384
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1

# Connection Backlog & Limit
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_max_tw_buckets = 2000000
net.ipv4.tcp_fin_timeout = 15

# Anti-DC KeepAlive (Mencegah koneksi diputus oleh Provider Seluler)
net.ipv4.tcp_keepalive_time = 30
net.ipv4.tcp_keepalive_intvl = 5
net.ipv4.tcp_keepalive_probes = 5
EOF

sysctl --system > /dev/null 2>&1

# 2. Clamping TCP MSS pada Firewall (Mencegah packet drop saat upload video)
iptables -t mangle -C FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu 2>/dev/null || \
iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
iptables -t mangle -C OUTPUT -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu 2>/dev/null || \
iptables -t mangle -A OUTPUT -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

# 3. File Descriptors & Limits
cat > /etc/security/limits.d/99-premdigital.conf << 'EOF'
* soft nofile 1048576
* hard nofile 1048576
root soft nofile 1048576
root hard nofile 1048576
EOF


# 4. Anti-DC Tuning untuk Dropbear, Stunnel & OpenSSH
if [ -f /etc/default/dropbear ]; then
    sed -i "s/-I 60/-I 0/g" /etc/default/dropbear 2>/dev/null || true
    sed -i "s/-K [0-9]*/-K 15/g" /etc/default/dropbear 2>/dev/null || true
    systemctl restart dropbear 2>/dev/null || true
fi

if [ -f /etc/stunnel/stunnel.conf ]; then
    if ! grep -q "TIMEOUTidle" /etc/stunnel/stunnel.conf 2>/dev/null; then
        sed -i "/client = no/a TIMEOUTidle = 86400\nTIMEOUTclose = 0\nTIMEOUTbusy = 300" /etc/stunnel/stunnel.conf 2>/dev/null || true
        systemctl restart stunnel4 2>/dev/null || systemctl restart stunnel 2>/dev/null || true
    fi
fi

if [ -f /etc/ssh/sshd_config ]; then
    sed -i "/ClientAliveInterval/d" /etc/ssh/sshd_config 2>/dev/null || true
    sed -i "/ClientAliveCountMax/d" /etc/ssh/sshd_config 2>/dev/null || true
    sed -i "/TCPKeepAlive/d" /etc/ssh/sshd_config 2>/dev/null || true
    echo "ClientAliveInterval 15" >> /etc/ssh/sshd_config
    echo "ClientAliveCountMax 10" >> /etc/ssh/sshd_config
    echo "TCPKeepAlive yes" >> /etc/ssh/sshd_config
    systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || true
fi

echo -e "\e[32m[SUCCESS] Kernel BBR & Network Buffer Optimizer Aktif!\e[0m"
