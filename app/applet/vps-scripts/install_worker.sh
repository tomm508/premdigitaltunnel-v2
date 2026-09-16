#!/bin/bash
# Script Installer untuk PremDigital Worker

echo "====================================================="
echo "   PremDigital - VPS Worker Auto Installer           "
echo "====================================================="

# 1. Baca konfigurasi yang tadi dibuat user
if [ ! -f /root/node_config.txt ]; then
    echo "[ERROR] File /root/node_config.txt tidak ditemukan!"
    echo "Pastikan Anda sudah menjalankan perintah konfigurasi pertama (cat > /root/node_config.txt ...)"
    exit 1
fi
source /root/node_config.txt

echo "[INFO] Menginstal Worker untuk Node: $NODE_ID..."

# 2. Download script auto-reporter yang asli dari github
echo "[INFO] Mengunduh script pelapor..."
curl -s -o /root/premdigital_reporter.sh https://raw.githubusercontent.com/tomm508/premdigitaltunnel-v2/main/vps-scripts/auto_reporter.sh
chmod +x /root/premdigital_reporter.sh

# 3. Pasang di Cronjob agar jalan tiap 1 menit
echo "[INFO] Memasang jadwal Cronjob..."
# Hapus cron lama (jika ada) dan pasang yang baru
(crontab -l 2>/dev/null | grep -v "premdigital_reporter.sh"; echo "*/1 * * * * /root/premdigital_reporter.sh >/dev/null 2>&1") | crontab -

echo "====================================================="
echo "[SUCCESS] Instalasi selesai!"
echo "[INFO] VPS ini ($NODE_ID) sekarang akan otomatis melapor"
echo "status RAM/CPU ke Web Admin setiap 1 menit."
echo "====================================================="
