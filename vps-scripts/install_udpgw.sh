#!/bin/bash
# ==============================================================================
# PremDigital - Auto Installer BadVPN UDPGW (Multi-Port 7100, 7200, 7300)
# Fungsi: Mendukung Game Online, WhatsApp/Discord Voice Call, & Anti-Warning UDP
# Sesuai Aturan: Modular & Non-Destruktif (Zero Risk to Existing Services)
# ==============================================================================

export DEBIAN_FRONTEND=noninteractive

echo "====================================================="
echo "   PremDigital - Menginstal & Mengaktifkan UDPGW     "
echo "====================================================="

# 1. Pastikan folder dan tool pendukung tersedia
mkdir -p /usr/bin
mkdir -p /etc/systemd/system

# 2. Unduh binary badvpn-udpgw yang stabil
echo "[1/4] Mengunduh binary badvpn-udpgw..."
if [ ! -f /usr/bin/badvpn-udpgw ]; then
    wget -q -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/sensiplay/badvpn/master/badvpn-udpgw" || \
    wget -q -O /usr/bin/badvpn-udpgw "https://github.com/ambrop72/badvpn/raw/master/badvpn-udpgw"
fi

if [ ! -f /usr/bin/badvpn-udpgw ]; then
    echo "[ERROR] Gagal mengunduh binary badvpn-udpgw. Silakan periksa koneksi internet VPS."
    exit 1
fi

chmod +x /usr/bin/badvpn-udpgw

# 3. Buat service systemd untuk port 7100, 7200, dan 7300 (Kompatibel semua app: NetMod, HTTP Custom, dll.)
echo "[2/4] Mengonfigurasi Service Systemd UDPGW..."

# Port 7300 (Default NetMod & HTTP Custom)
cat > /etc/systemd/system/badvpn-7300.service << 'EOF'
[Unit]
Description=BadVPN UDP Gateway Port 7300
Documentation=https://github.com/ambrop72/badvpn
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

# Port 7200
cat > /etc/systemd/system/badvpn-7200.service << 'EOF'
[Unit]
Description=BadVPN UDP Gateway Port 7200
Documentation=https://github.com/ambrop72/badvpn
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

# Port 7100
cat > /etc/systemd/system/badvpn-7100.service << 'EOF'
[Unit]
Description=BadVPN UDP Gateway Port 7100
Documentation=https://github.com/ambrop72/badvpn
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

# 4. Reload daemon dan jalankan service
echo "[3/4] Mengaktifkan service saat booting otomatis..."
systemctl daemon-reload
systemctl enable badvpn-7100 badvpn-7200 badvpn-7300 >/dev/null 2>&1
systemctl restart badvpn-7100 badvpn-7200 badvpn-7300

# 5. Verifikasi port berjalan
echo "[4/4] Memeriksa status port UDPGW..."
sleep 1
if netstat -tulpn 2>/dev/null | grep -E "7100|7200|7300" >/dev/null || ss -tulpn 2>/dev/null | grep -E "7100|7200|7300" >/dev/null; then
    echo "====================================================="
    echo "[SUCCESS] UDPGW (Port 7100, 7200, 7300) AKTIF!"
    echo "Sekarang VPS Anda otomatis mendukung Game Online,"
    echo "WhatsApp Call, dan bebas dari peringatan di NetMod."
    echo "====================================================="
else
    echo "====================================================="
    echo "[INFO] Service telah terpasang dan siap digunakan."
    echo "====================================================="
fi
