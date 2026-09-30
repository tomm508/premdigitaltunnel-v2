#!/bin/bash
# ==============================================================================
# PremDigital - Auto Installer BadVPN UDPGW (Multi-Port 7100, 7200, 7300)
# ==============================================================================

export DEBIAN_FRONTEND=noninteractive

echo "====================================================="
echo "   PremDigital - Menginstal & Mengaktifkan UDPGW     "
echo "====================================================="

mkdir -p /usr/bin /usr/local/bin
mkdir -p /etc/systemd/system

echo "[1/4] Mengunduh binary badvpn-udpgw..."
# Coba ambil dari repo sendiri, jika belum ada ambil dari mirror terpercaya
wget -qO /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/tomm508/premdigitaltunnel-v2/main/vps-scripts/badvpn-udpgw" || wget -qO /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/daybreakersx/premscript/master/badvpn-udpgw64" || curl -sSL "https://raw.githubusercontent.com/daybreakersx/premscript/master/badvpn-udpgw64" -o /usr/bin/badvpn-udpgw

chmod +x /usr/bin/badvpn-udpgw
cp -f /usr/bin/badvpn-udpgw /usr/local/bin/badvpn-udpgw 2>/dev/null || true
chmod +x /usr/local/bin/badvpn-udpgw 2>/dev/null || true

if [ ! -s /usr/bin/badvpn-udpgw ]; then
    echo "[ERROR] Gagal mengunduh binary badvpn-udpgw!"
    exit 1
fi

echo "[2/4] Mengonfigurasi Service Systemd UDPGW..."

cat > /etc/systemd/system/badvpn-7300.service << 'EOF'
[Unit]
Description=BadVPN UDP Gateway Port 7300
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000 --max-connections-for-client 20
Restart=always
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/badvpn-7200.service << 'EOF'
[Unit]
Description=BadVPN UDP Gateway Port 7200
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 1000 --max-connections-for-client 20
Restart=always
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/badvpn-7100.service << 'EOF'
[Unit]
Description=BadVPN UDP Gateway Port 7100
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/badvpn-udpgw --listen-addr 127.0.0.1:7100 --max-clients 1000 --max-connections-for-client 20
Restart=always
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOF

echo "[3/4] Mengaktifkan service..."
systemctl daemon-reload
systemctl enable badvpn-7100 badvpn-7200 badvpn-7300 >/dev/null 2>&1
systemctl restart badvpn-7100 badvpn-7200 badvpn-7300

echo "[4/4] Memeriksa status port..."
sleep 1
ps aux | grep badvpn-udpgw | grep -v grep

echo "====================================================="
echo "[SUCCESS] BadVPN UDPGW Berhasil Terpasang & Aktif!"
echo "Port: 7100, 7200, 7300 (127.0.0.1)"
echo "====================================================="
