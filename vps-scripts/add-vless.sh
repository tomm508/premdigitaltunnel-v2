#!/bin/bash
# ==========================================
# Script Create VLESS (5 Network Protocol)
# ==========================================

# Pastikan Xray Core terinstall
if [ ! -f /usr/local/bin/xray ] || [ ! -s /etc/xray/config.json ]; then
    echo -e "\e[33m[INFO] Xray belum terkonfigurasi. Memulai inisialisasi Xray...\e[0m"
    if [ -f /usr/local/bin/setup-xray ]; then
        /usr/local/bin/setup-xray
    else
        wget -qO /tmp/setup-xray.sh https://raw.githubusercontent.com/premdigital/Scpremdigital-v1/main/setup-xray.sh
        bash /tmp/setup-xray.sh
        rm -f /tmp/setup-xray.sh
    fi
fi

CONFIG_XRAY="/etc/xray/config.json"
mkdir -p /etc/premdigital

# Ambil Domain dari file, jika tidak ada pakai IP
domain=$(cat /etc/vps-domain.txt 2>/dev/null | tr -d '\r\n')
if [[ -z "$domain" ]]; then
    domain=$(curl -s -m 3 ipv4.icanhazip.com 2>/dev/null || curl -s -m 3 ipinfo.io/ip 2>/dev/null || echo "127.0.0.1")
fi

clear
echo -e "\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
echo -e "\e[1;33m       MEMBUAT AKUN VLESS (5 JALUR)\e[0m"
echo -e "\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"

# Validasi Username
while true; do
    read -rp "Username : " -e user
    if [[ -z "$user" ]]; then
        echo -e "\e[1;31mUsername tidak boleh kosong!\e[0m"
        continue
    fi
    if grep -q "\"email\": \"${user}\"" "$CONFIG_XRAY" 2>/dev/null; then
        echo -e "\e[1;31mUsername '${user}' sudah ada di sistem Xray!\e[0m"
    else
        break
    fi
done

# Validasi Masa Aktif (Wajib Angka Positif)
while true; do
    read -rp "Masa Aktif (Hari, Default 30) : " -e masaaktif
    [ -z "$masaaktif" ] && masaaktif=30
    if [[ "$masaaktif" =~ ^[0-9]+$ ]] && [ "$masaaktif" -gt 0 ]; then
        break
    else
        echo -e "\e[1;31mInput salah! Masa aktif harus berupa angka (contoh: 30).\e[0m"
    fi
done

# Generate UUID & Tanggal Expired
uuid=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || python3 -c 'import uuid; print(uuid.uuid4())')
exp=$(date -d "+$masaaktif days" +"%Y-%m-%d" 2>/dev/null || date -d "$masaaktif days" +"%Y-%m-%d" 2>/dev/null || date -v+${masaaktif}d +"%Y-%m-%d" 2>/dev/null)
[ -z "$exp" ] && exp=$(date -d "+30 days" +"%Y-%m-%d" 2>/dev/null || date +"%Y-%m-%d")

# Injeksi ke Config Xray menggunakan Python 3
python3 - <<EOF
import json
try:
    with open("$CONFIG_XRAY", "r") as f:
        data = json.load(f)
    for ib in data.get("inbounds", []):
        if ib.get("protocol") == "vless":
            clients = ib.setdefault("settings", {}).setdefault("clients", [])
            clients.append({
                "id": "$uuid",
                "email": "$user"
            })
    with open("$CONFIG_XRAY", "w") as f:
        json.dump(data, f, indent=2)
except Exception as e:
    print("Gagal mengupdate config:", e)
EOF

systemctl restart xray > /dev/null 2>&1

# Simpan riwayat user
echo "$user | $uuid | $exp | vless" >> /etc/premdigital/xray-users.db

# ==========================================
# Generate 5 Link VLESS (Format URI)
# ==========================================

# 1. WS TLS
link_ws_tls="vless://${uuid}@${domain}:443?path=/vless&security=tls&encryption=none&host=${domain}&type=ws&sni=${domain}#${user}"

# 2. WS Non-TLS
link_ws_ntls="vless://${uuid}@${domain}:80?path=/vless&security=none&encryption=none&host=${domain}&type=ws#${user}"

# 3. gRPC
link_grpc="vless://${uuid}@${domain}:443?mode=multi&security=tls&encryption=none&type=grpc&serviceName=vless&sni=${domain}#${user}"

# 4. HTTP Upgrade TLS
link_up_tls="vless://${uuid}@${domain}:443?path=/upvless&security=tls&encryption=none&host=${domain}&type=httpupgrade&sni=${domain}#${user}"

# 5. HTTP Upgrade Non-TLS
link_up_ntls="vless://${uuid}@${domain}:80?path=/upvless&security=none&encryption=none&host=${domain}&type=httpupgrade#${user}"

# ==========================================
# Output Hasil di Terminal
# ==========================================
clear
echo -e "\e[1;32m✅ SUKSES CREATE AKUN VLESS\e[0m"
echo -e "\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
echo -e "👤 Username     : \e[1;33m${user}\e[0m"
echo -e "🆔 UUID         : \e[1;37m${uuid}\e[0m"
echo -e "🌍 Host / SNI   : \e[1;37m${domain}\e[0m"
echo -e "⏳ Masa Aktif   : \e[1;37m${masaaktif} Hari\e[0m"
echo -e "📅 Expired Pada : \e[1;31m${exp}\e[0m"
echo -e "\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
echo -e "🔒 \e[1;32m1. WS TLS (Port 443)\e[0m"
echo -e "${link_ws_tls}"
echo ""
echo -e "🔓 \e[1;32m2. WS Non-TLS (Port 80)\e[0m"
echo -e "${link_ws_ntls}"
echo ""
echo -e "⚡ \e[1;32m3. gRPC (Port 443)\e[0m"
echo -e "${link_grpc}"
echo ""
echo -e "🚀 \e[1;32m4. HTTPUpgrade TLS (Port 443)\e[0m"
echo -e "${link_up_tls}"
echo ""
echo -e "📡 \e[1;32m5. HTTPUpgrade Non-TLS (Port 80)\e[0m"
echo -e "${link_up_ntls}"
echo -e "\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
echo -e "💡 Simpan link di atas untuk dimasukkan ke V2rayNG, Clash, atau Sing-box."
echo ""
