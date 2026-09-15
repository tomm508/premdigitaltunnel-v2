#!/bin/bash
# ==========================================
# PremDigital - Xray Core & Multiplexer Setup
# ==========================================

if [ "${EUID}" -ne 0 ]; then
    echo "Mohon jalankan sebagai root"
    exit 1
fi

echo -e "\e[33m[INFO] Menyiapkan Direktori & File Pendukung Xray...\e[0m"
mkdir -p /etc/xray /var/log/xray /usr/local/share/xray /etc/premdigital/xray
touch /var/log/xray/access.log /var/log/xray/error.log 2>/dev/null
chmod 644 /var/log/xray/*.log 2>/dev/null

# Deteksi Domain VPS
if [ -f /etc/vps-domain.txt ]; then
    domain=$(cat /etc/vps-domain.txt | tr -d '\r\n')
else
    domain=$(curl -s -m 3 ipv4.icanhazip.com 2>/dev/null || curl -s -m 3 ipinfo.io/ip 2>/dev/null || echo "127.0.0.1")
    echo "$domain" > /etc/vps-domain.txt
fi

# Bebaskan Port 4430 dari konflik Stunnel / proses lama
if [ -f /etc/stunnel/stunnel.conf ] && grep -q "4430" /etc/stunnel/stunnel.conf; then
    echo -e "\e[33m[INFO] Membersihkan port 4430 dari konfigurasi Stunnel lama...\e[0m"
    sed -i '/\[ws-tls\]/,+2d' /etc/stunnel/stunnel.conf 2>/dev/null
    sed -i '/4430/d' /etc/stunnel/stunnel.conf 2>/dev/null
    # Jika stunnel.conf menjadi kosong atau rusak, pulihkan openssh-tls port 8443
    if ! grep -q "openssh-tls" /etc/stunnel/stunnel.conf 2>/dev/null; then
        cat >> /etc/stunnel/stunnel.conf << 'EOF'

[openssh-tls]
accept = 0.0.0.0:8443
connect = 127.0.0.1:109
EOF
    fi
    systemctl restart stunnel4 2>/dev/null || systemctl restart stunnel 2>/dev/null || true
fi
fuser -k 4430/tcp >/dev/null 2>&1 || true

# Buat Sertifikat SSL untuk Xray jika belum ada atau kosong
if [ ! -s /etc/xray/xray.crt ] || [ ! -s /etc/xray/xray.key ]; then
    echo -e "\e[33m[INFO] Menghasilkan Sertifikat SSL baru untuk Xray...\e[0m"
    openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -sha256 \
    -subj "/C=ID/ST=DKI Jakarta/L=Jakarta/O=PremDigital/OU=PremDigital/CN=$domain" \
    -out /etc/xray/xray.crt -keyout /etc/xray/xray.key 2>/dev/null
    chmod 644 /etc/xray/xray.crt 2>/dev/null
    chmod 600 /etc/xray/xray.key 2>/dev/null
fi

# Download & Pasang Xray Core jika belum ada atau rusak
if ! /usr/local/bin/xray version >/dev/null 2>&1; then
    echo -e "\e[33m[INFO] Mengunduh Xray Core Official...\e[0m"
    arch=$(uname -m)
    xray_arch="64"
    if [ "$arch" == "aarch64" ] || [ "$arch" == "arm64" ]; then
        xray_arch="arm64-v8a"
    elif [ "$arch" == "armv7l" ]; then
        xray_arch="arm32-v7a"
    fi
    
    apt-get update -y >/dev/null 2>&1
    apt-get install -y unzip curl wget python3 psmisc >/dev/null 2>&1
    
    rm -f /tmp/xray.zip
    wget -qO /tmp/xray.zip "https://github.com/XTLS/Xray-core/releases/download/v1.8.24/Xray-linux-${xray_arch}.zip" || \
    curl -sL "https://github.com/XTLS/Xray-core/releases/download/v1.8.24/Xray-linux-${xray_arch}.zip" -o /tmp/xray.zip
    
    if [ -s /tmp/xray.zip ]; then
        mkdir -p /tmp/xray_extract
        unzip -o /tmp/xray.zip -d /tmp/xray_extract/ >/dev/null 2>&1
        cp -f /tmp/xray_extract/xray /usr/local/bin/xray 2>/dev/null
        cp -f /tmp/xray_extract/*.dat /usr/local/share/xray/ 2>/dev/null
        cp -f /tmp/xray_extract/*.dat /usr/local/bin/ 2>/dev/null
        chmod +x /usr/local/bin/xray
        rm -rf /tmp/xray.zip /tmp/xray_extract
    fi

    # Fallback ke installer resmi jika masih belum terpasang
    if ! /usr/local/bin/xray version >/dev/null 2>&1; then
        echo -e "\e[33m[INFO] Menggunakan fallback installer resmi XTLS...\e[0m"
        bash -c "$(curl -sL https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install >/dev/null 2>&1
    fi
fi

# Fungsi untuk membuat template /etc/xray/config.json
generate_default_config() {
    cat > /etc/xray/config.json << 'EOF'
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 10001,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/vmess"
        }
      }
    },
    {
      "port": 10002,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/vless"
        }
      }
    },
    {
      "port": 10003,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/trojan"
        }
      }
    },
    {
      "port": 10004,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "grpc",
        "grpcSettings": {
          "serviceName": "vmess"
        }
      }
    },
    {
      "port": 10005,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "grpc",
        "grpcSettings": {
          "serviceName": "vless"
        }
      }
    },
    {
      "port": 10006,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "grpc",
        "grpcSettings": {
          "serviceName": "trojan"
        }
      }
    },
    {
      "port": 10007,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "httpupgrade",
        "httpupgradeSettings": {
          "path": "/upvmess"
        }
      }
    },
    {
      "port": 10008,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "httpupgrade",
        "httpupgradeSettings": {
          "path": "/upvless"
        }
      }
    },
    {
      "port": 10009,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "httpupgrade",
        "httpupgradeSettings": {
          "path": "/uptrojan"
        }
      }
    },
    {
      "port": 443,
      "listen": "127.0.0.1",
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
          { "dest": 109 }
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
}

# Buat Base Config Xray jika belum ada atau kosong
if [ ! -s /etc/xray/config.json ]; then
    echo -e "\e[33m[INFO] Mengonfigurasi /etc/xray/config.json...\e[0m"
    generate_default_config
fi

# Cek validitas config.json dengan Xray test
if command -v /usr/local/bin/xray >/dev/null 2>&1; then
    if ! /usr/local/bin/xray -test -config /etc/xray/config.json >/dev/null 2>&1; then
        echo -e "\e[31m[PERINGATAN] Format config.json lama bermasalah, meregenerasi default...\e[0m"
        cp -f /etc/xray/config.json /etc/xray/config.json.corrupt 2>/dev/null
        generate_default_config
    fi
fi

# Buat Service Systemd untuk Xray
cat > /etc/systemd/system/xray.service << 'EOF'
[Unit]
Description=Xray Service PremDigital
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
systemctl restart xray
sleep 1.5

if systemctl is-active --quiet xray; then
    echo -e "\e[32m[INFO] Xray Core & Service BERHASIL berjalan (RUNNING)!\e[0m"
else
    echo -e "\e[31m[ERROR] Xray belum berjalan, memeriksa log error...\e[0m"
    journalctl -u xray -n 10 --no-pager
fi
