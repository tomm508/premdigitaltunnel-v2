#!/bin/bash
# ==========================================
# PremDigital - Installer & Setup Limit IP 2 Login (AutoKill)
# ==========================================

RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
CYAN='\e[1;36m'
NC='\e[0m'

echo -e "${BLUE}====================================================${NC}"
echo -e "${GREEN}      INSTALLER LIMIT MULTI-LOGIN (AUTOKILL)        ${NC}"
echo -e "${BLUE}====================================================${NC}"

mkdir -p /etc/premdigital
mkdir -p /var/log/xray
touch /var/log/limit-ip.log
chmod 644 /var/log/limit-ip.log

# 1. Pasang Konfigurasi Default jika belum ada
if [ ! -f /etc/premdigital/limit-ip.conf ]; then
    cat > /etc/premdigital/limit-ip.conf << 'EOF'
# PremDigital AutoKill Limit IP Configuration
MAX_IP=2
AUTOKILL=1
NOTIF_LOG=1
EOF
fi

# 2. Pasang Skrip ke /usr/local/bin
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/limit-ip.py" ]; then
    cp -f "$SCRIPT_DIR/limit-ip.py" /usr/local/bin/limit-ip.py
    chmod +x /usr/local/bin/limit-ip.py
fi

if [ -f "$SCRIPT_DIR/limit-ip-menu.sh" ]; then
    cp -f "$SCRIPT_DIR/limit-ip-menu.sh" /usr/local/bin/limit-ip-menu
    chmod +x /usr/local/bin/limit-ip-menu
fi

if [ -f "$SCRIPT_DIR/limit-ip.sh" ]; then
    cp -f "$SCRIPT_DIR/limit-ip.sh" /usr/local/bin/limit-ip
    chmod +x /usr/local/bin/limit-ip
fi

# 3. Pastikan Xray mengaktifkan access log
if [ -f /etc/xray/config.json ]; then
    python3 -c "
import json, os
path = '/etc/xray/config.json'
try:
    with open(path, 'r') as f:
        cfg = json.load(f)
    log_cfg = cfg.setdefault('log', {})
    if 'access' not in log_cfg:
        log_cfg['access'] = '/var/log/xray/access.log'
        log_cfg['error'] = '/var/log/xray/error.log'
        with open(path, 'w') as f:
            json.dump(cfg, f, indent=2)
        print('[OK] Access log diaktifkan di Xray config.json')
except Exception as e:
    pass
"
    systemctl restart xray 2>/dev/null || true
fi

# 4. Pasang Cronjob Otomatis Tiap 1 Menit
(crontab -l 2>/dev/null | grep -v "limit-ip"; echo "*/1 * * * * /usr/bin/python3 /usr/local/bin/limit-ip.py --kill >/dev/null 2>&1") | crontab -

# 5. Pasang Systemd Daemon (Opsional background loop)
cat > /etc/systemd/system/limit-ip.service << 'EOF'
[Unit]
Description=PremDigital Multi-Login AutoKill Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /usr/local/bin/limit-ip.py --kill
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now limit-ip.service 2>/dev/null || true

echo -e "${GREEN}[SUKSES] Sistem Limit Multi-Login berhasil dipasang!${NC}"
echo -e "Perintah cepat yang tersedia di terminal:"
echo -e " - ${YELLOW}limit-ip${NC}        : Membuka Menu Pengaturan Limit IP"
echo -e " - ${YELLOW}limit-ip --check${NC}: Cek status user & IP aktif seketika"
echo -e " - ${YELLOW}limit-ip --kill${NC} : Jalankan autokill manual sekarang"
echo -e "${BLUE}====================================================${NC}"
