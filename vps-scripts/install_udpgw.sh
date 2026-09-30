#!/bin/bash
# ==============================================================================
# PremDigital - Auto Installer BadVPN UDPGW (Multi-Port 7100, 7200, 7300)
# Mendukung Native Compile dari source resmi & Binary Fallback
# ==============================================================================

export DEBIAN_FRONTEND=noninteractive

echo -e "\e[33m=====================================================\e[0m"
echo -e "\e[32m   PremDigital - Auto Installer UDPGW (BadVPN)       \e[0m"
echo -e "\e[33m=====================================================\e[0m"

# 0. Bersihkan service lama jika ada agar port tidak bentrok
systemctl stop badvpn-7100 badvpn-7200 badvpn-7300 udpgw 2>/dev/null
systemctl disable badvpn-7100 badvpn-7200 badvpn-7300 udpgw 2>/dev/null

mkdir -p /usr/local/bin /usr/bin
mkdir -p /etc/systemd/system

echo "[1/4] Menyiapkan binary badvpn-udpgw..."
# Download binary valid siap pakai
wget -qO /usr/local/bin/badvpn-udpgw "https://raw.githubusercontent.com/daybreakersx/premscript/master/badvpn-udpgw64" || wget -qO /usr/local/bin/badvpn-udpgw "https://raw.githubusercontent.com/tomm508/premdigitaltunnel-v2/main/vps-scripts/badvpn-udpgw" || curl -sSL "https://raw.githubusercontent.com/daybreakersx/premscript/master/badvpn-udpgw64" -o /usr/local/bin/badvpn-udpgw

# Jika binary belum terpasang atau tidak cocok dengan arsitektur CPU, lakukan native compile
if [ ! -s /usr/local/bin/badvpn-udpgw ] || ! /usr/local/bin/badvpn-udpgw --version >/dev/null 2>&1; then
    echo "[!] Memulai kompilasi native dari source resmi badvpn..."
    apt-get update -y >/dev/null 2>&1
    apt-get install -y build-essential cmake libssl-dev unzip wget -y >/dev/null 2>&1
    cd /root || exit
    rm -rf master.zip badvpn-master
    wget -q https://github.com/ambrop72/badvpn/archive/master.zip
    if [ -f master.zip ]; then
        unzip -q master.zip
        cd badvpn-master && mkdir -p build && cd build || exit
        cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 >/dev/null 2>&1
        make install >/dev/null 2>&1
        cd /root || exit
        rm -rf badvpn-master master.zip
    fi
fi

chmod +x /usr/local/bin/badvpn-udpgw 2>/dev/null || true
cp -f /usr/local/bin/badvpn-udpgw /usr/bin/badvpn-udpgw 2>/dev/null || true
chmod +x /usr/bin/badvpn-udpgw 2>/dev/null || true

if [ ! -s /usr/local/bin/badvpn-udpgw ]; then
    echo -e "\e[31m[ERROR] Gagal memasang BadVPN UDPGW!\e[0m"
    exit 1
fi

echo "[2/4] Mengonfigurasi Service Systemd UDPGW (Port 7100, 7200, 7300)..."

cat > /etc/systemd/system/badvpn-7100.service << 'EOF'
[Unit]
Description=BadVPN UDP Gateway Port 7100
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:7100 --max-clients 1000 --max-connections-for-client 500
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
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 1000 --max-connections-for-client 500
Restart=always
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/badvpn-7300.service << 'EOF'
[Unit]
Description=BadVPN UDP Gateway Port 7300
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000 --max-connections-for-client 500
Restart=always
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOF

# Symlink udpgw.service ke badvpn-7300.service agar kompatibel dua arah
ln -sf /etc/systemd/system/badvpn-7300.service /etc/systemd/system/udpgw.service

echo "[3/4] Mengaktifkan dan menjalankan service..."
systemctl daemon-reload
systemctl enable badvpn-7100 badvpn-7200 badvpn-7300 >/dev/null 2>&1
systemctl restart badvpn-7100 badvpn-7200 badvpn-7300

echo "[4/4] Memeriksa status proses..."
sleep 1
ps aux | grep badvpn-udpgw | grep -v grep

echo -e "\e[32m=====================================================\e[0m"
echo -e "\e[32m[SUCCESS] BadVPN UDPGW Berhasil Terpasang & Aktif!\e[0m"
echo -e "Port Aktif : 7100, 7200, 7300 (127.0.0.1)"
echo -e "Kapasitas  : Max 500 Koneksi / Client (Stabil untuk Game)"
echo -e "====================================================="
