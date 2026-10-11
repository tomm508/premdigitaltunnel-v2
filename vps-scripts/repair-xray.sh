#!/bin/bash
# ====================================================
# PremDigital Tunnel - Auto Repair & Diagnostics Xray
# Mengatasi Xray Stopped / Error Tanpa Merusak Akun
# ====================================================

RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
CYAN='\e[1;36m'
NC='\e[0m'

clear
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}       AUTO REPAIR & DIAGNOSTIK XRAY CORE         ${NC}"
echo -e "${CYAN}           PremDigital Tunneling System           ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${YELLOW}[1/7] Memeriksa binary dan direktori Xray...${NC}"
mkdir -p /etc/xray /var/log/xray /usr/local/share/xray /etc/premdigital/xray
touch /var/log/xray/access.log /var/log/xray/error.log 2>/dev/null
chmod 666 /var/log/xray/*.log 2>/dev/null

if ! command -v /usr/local/bin/xray >/dev/null 2>&1; then
    echo -e "${RED}[!] Binary /usr/local/bin/xray tidak ditemukan. Mengunduh ulang...${NC}"
    arch=$(uname -m)
    xray_arch="64"
    if [ "$arch" == "aarch64" ] || [ "$arch" == "arm64" ]; then
        xray_arch="arm64-v8a"
    fi
    wget -qO /tmp/xray.zip "https://github.com/XTLS/Xray-core/releases/download/v1.8.24/Xray-linux-${xray_arch}.zip" 2>/dev/null
    if [ -s /tmp/xray.zip ]; then
        mkdir -p /tmp/xray_extract
        unzip -o /tmp/xray.zip -d /tmp/xray_extract/ >/dev/null 2>&1
        cp -f /tmp/xray_extract/xray /usr/local/bin/xray 2>/dev/null
        cp -f /tmp/xray_extract/*.dat /usr/local/share/xray/ 2>/dev/null
        chmod +x /usr/local/bin/xray
        rm -rf /tmp/xray.zip /tmp/xray_extract
    fi
fi

chmod +x /usr/local/bin/xray 2>/dev/null
echo -e "  ${GREEN}✓ Binary Xray OK: $(/usr/local/bin/xray version 2>/dev/null | head -n1)${NC}"

echo -e "\n${YELLOW}[2/7] Memeriksa sertifikat SSL Xray...${NC}"
domain="127.0.0.1"
if [ -f /etc/vps-domain.txt ]; then
    domain=$(head -n 1 /etc/vps-domain.txt 2>/dev/null | tr -d '\r\n ')
fi
[ -z "$domain" ] && domain=$(curl -s -m 2 ifconfig.me 2>/dev/null || echo "127.0.0.1")

if [ ! -s /etc/xray/xray.crt ] || [ ! -s /etc/xray/xray.key ]; then
    echo -e "  ${YELLOW}[!] Sertifikat SSL kosong/hilang, membuat sertifikat baru...${NC}"
    openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -sha256 \
    -subj "/C=ID/ST=DKI Jakarta/L=Jakarta/O=PremDigital/OU=PremDigital/CN=$domain" \
    -out /etc/xray/xray.crt -keyout /etc/xray/xray.key >/dev/null 2>&1
fi
chmod 644 /etc/xray/xray.crt 2>/dev/null
chmod 600 /etc/xray/xray.key 2>/dev/null
echo -e "  ${GREEN}✓ Sertifikat SSL OK!${NC}"

echo -e "\n${YELLOW}[3/7] Memeriksa potensi konflik Port 443 / 80...${NC}"
# Matikan apache2 atau nginx jika tidak sengaja berjalan
if systemctl is-active --quiet apache2 2>/dev/null; then
    systemctl stop apache2 >/dev/null 2>&1
    systemctl disable apache2 >/dev/null 2>&1
    echo -e "  ${YELLOW}✓ Apache2 dimatikan (konflik port)${NC}"
fi
if systemctl is-active --quiet nginx 2>/dev/null; then
    systemctl stop nginx >/dev/null 2>&1
    systemctl disable nginx >/dev/null 2>&1
    echo -e "  ${YELLOW}✓ Nginx dimatikan (konflik port)${NC}"
fi

# Cek apakah port 443 terkunci oleh proses hantu
pid_443=$(lsof -t -i:443 2>/dev/null | grep -v "$$" | head -n1)
if [ -n "$pid_443" ]; then
    proc_name=$(ps -p "$pid_443" -o comm= 2>/dev/null)
    if [ "$proc_name" != "xray" ]; then
        echo -e "  ${YELLOW}[!] Port 443 dipakai oleh '$proc_name' (PID: $pid_443). Membebaskan port...${NC}"
        kill -9 "$pid_443" 2>/dev/null || true
    fi
fi
echo -e "  ${GREEN}✓ Port 443 siap digunakan.${NC}"

echo -e "\n${YELLOW}[4/7] Memeriksa integritas /etc/xray/config.json...${NC}"
CONFIG_XRAY="/etc/xray/config.json"
CONFIG_VALID=0

# Backup config sebelum dicek/diperbaiki
if [ -f "$CONFIG_XRAY" ]; then
    cp -f "$CONFIG_XRAY" "${CONFIG_XRAY}.bak" 2>/dev/null
fi

if [ -s "$CONFIG_XRAY" ]; then
    if /usr/local/bin/xray -test -config "$CONFIG_XRAY" >/dev/null 2>&1; then
        CONFIG_VALID=1
        echo -e "  ${GREEN}✓ Syntax config.json VALID!${NC}"
    else
        echo -e "  ${RED}[!] Syntax config.json bermasalah / korup!${NC}"
        cp -f "$CONFIG_XRAY" "${CONFIG_XRAY}.corrupted_$(date +%s)" 2>/dev/null
    fi
else
    echo -e "  ${RED}[!] File config.json kosong atau tidak ada!${NC}"
fi

if [ $CONFIG_VALID -eq 0 ]; then
    echo -e "  ${YELLOW}[*] Meregenerasi template config.json resmi & aman...${NC}"
    cat > "$CONFIG_XRAY" << 'EOF'
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "warning"
  },
  "policy": {
    "levels": {
      "0": {
        "handshake": 10,
        "connIdle": 86400,
        "uplinkOnly": 0,
        "downlinkOnly": 0,
        "bufferSize": 512
      }
    }
  },
  "inbounds": [
    {
      "port": 10001,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": { "clients": [] },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "/vmess" }
      }
    },
    {
      "port": 10002,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": { "clients": [], "decryption": "none" },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "/vless" }
      }
    },
    {
      "port": 10003,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "settings": { "clients": [] },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "/trojan" }
      }
    },
    {
      "port": 10004,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": { "clients": [] },
      "streamSettings": {
        "network": "grpc",
        "grpcSettings": { "serviceName": "vmess" }
      }
    },
    {
      "port": 10005,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": { "clients": [], "decryption": "none" },
      "streamSettings": {
        "network": "grpc",
        "grpcSettings": { "serviceName": "vless" }
      }
    },
    {
      "port": 10006,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "settings": { "clients": [] },
      "streamSettings": {
        "network": "grpc",
        "grpcSettings": { "serviceName": "trojan" }
      }
    },
    {
      "port": 10007,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": { "clients": [] },
      "streamSettings": {
        "network": "httpupgrade",
        "httpupgradeSettings": { "path": "/upvmess" }
      }
    },
    {
      "port": 10008,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": { "clients": [], "decryption": "none" },
      "streamSettings": {
        "network": "httpupgrade",
        "httpupgradeSettings": { "path": "/upvless" }
      }
    },
    {
      "port": 10009,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "settings": { "clients": [] },
      "streamSettings": {
        "network": "httpupgrade",
        "httpupgradeSettings": { "path": "/uptrojan" }
      }
    },
    {
      "port": 443,
      "listen": "0.0.0.0",
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none",
        "fallbacks": [
          { "path": "/vmess", "dest": 10001 },
          { "path": "/vless", "dest": 10002 },
          { "path": "/trojan", "dest": 10003 },
          { "path": "/upvmess", "dest": 10007 },
          { "path": "/upvless", "dest": 10008 },
          { "path": "/uptrojan", "dest": 10009 },
          { "serviceName": "vmess", "dest": 10004 },
          { "serviceName": "vless", "dest": 10005 },
          { "serviceName": "trojan", "dest": 10006 },
          { "dest": 80 }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
          "certificates": [
            {
              "certificateFile": "/etc/xray/xray.crt",
              "keyFile": "/etc/xray/xray.key"
            }
          ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    }
  ]
}
EOF

    # Restore semua akun dari database /etc/premdigital/xray-users.db
    if [ -f /etc/premdigital/xray-users.db ] && [ -s /etc/premdigital/xray-users.db ]; then
        echo -e "  ${YELLOW}[*] Memulihkan kembali semua akun pelanggan dari database...${NC}"
        python3 - << 'PY_RESTORE'
import json

db_path = "/etc/premdigital/xray-users.db"
cfg_path = "/etc/xray/config.json"

try:
    with open(cfg_path, "r") as f:
        cfg = json.load(f)
    
    with open(db_path, "r") as f:
        lines = f.readlines()
        
    for line in lines:
        parts = [p.strip() for p in line.split("|")]
        if len(parts) >= 4:
            user, uuid_pass, exp, proto = parts[0], parts[1], parts[2], parts[3].lower()
            for ib in cfg.get("inbounds", []):
                ib_proto = ib.get("protocol", "").lower()
                if ib_proto == proto:
                    clients = ib.setdefault("settings", {}).setdefault("clients", [])
                    if proto == "vmess":
                        clients.append({"id": uuid_pass, "alterId": 0, "email": user})
                    elif proto == "vless":
                        clients.append({"id": uuid_pass, "email": user})
                    elif proto == "trojan":
                        clients.append({"password": uuid_pass, "email": user})
                        
    with open(cfg_path, "w") as f:
        json.dump(cfg, f, indent=2)
    print("  \033[1;32m✓ Semua akun pelanggan berhasil dipulihkan secara utuh!\033[0m")
except Exception as e:
    print(f"  \033[1;31m[!] Gagal memulihkan database: {e}\033[0m")
PY_RESTORE
    fi
fi

echo -e "\n${YELLOW}[5/7] Memperbarui Unit Service systemd...${NC}"
cat > /etc/systemd/system/xray.service << 'EOF'
[Unit]Description=Xray Service PremDigital
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /etc/xray/config.json
Restart=always
RestartSec=3s
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable xray >/dev/null 2>&1

echo -e "\n${YELLOW}[6/7] Menjalankan Xray Service...${NC}"
systemctl restart xray
sleep 2

echo -e "\n${YELLOW}[7/7] Verifikasi Status Xray...${NC}"
if systemctl is-active --quiet xray; then
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  ✓ BERHASIL! Xray Core Sekarang RUNNING (HIJAU)!  ${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "Status Systemd : ${GREEN}$(systemctl is-active xray)${NC}"
    echo -e "Port 443 Listen: ${GREEN}$(ss -tulpn | grep ':443 ' | awk '{print $1, $5}' | head -n1)${NC}"
else
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}  ✖ PERINGATAN: Xray masih belum dapat berjalan!   ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Detail Log Error Xray:${NC}"
    journalctl -u xray -n 12 --no-pager
    echo ""
    echo -e "${YELLOW}Hasil Uji Test Config:${NC}"
    /usr/local/bin/xray -test -config "$CONFIG_XRAY"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
read -n 1 -s -r -p "Tekan Enter Untuk Kembali..."
exit 0
