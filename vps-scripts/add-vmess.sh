#!/bin/bash
# ==========================================
# Script Create VMESS (5 Network Protocol)
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
if [ -f /etc/vps-domain.txt ]; then
    domain_direct=$(head -n 1 /etc/vps-domain.txt 2>/dev/null | tr -d '\r\n ')
else
    domain_direct=$(curl -s -m 2 ipv4.icanhazip.com 2>/dev/null || echo "127.0.0.1")
fi
[ -z "$domain_direct" ] && domain_direct="127.0.0.1"

if [ -f /etc/vps-cloudfront.txt ]; then
    domain_cf=$(head -n 1 /etc/vps-cloudfront.txt 2>/dev/null | tr -d '\r\n ')
else
    domain_cf="d2t57v99vxtcp6.cloudfront.net"
fi
[ -z "$domain_cf" ] && domain_cf="d2t57v99vxtcp6.cloudfront.net"

domain="$domain_direct"

clear
echo -e "\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
echo -e "\e[1;33m       MEMBUAT AKUN VMESS (5 JALUR)\e[0m"
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
        echo -e " \e[33m[1]\e[0m Masukkan username lain"
        echo -e " \e[33m[0]\e[0m Kembali ke Menu Utama"
        read -rp " Pilihan [0-1, Default 1]: " -e opt_dup
        if [ "$opt_dup" == "0" ]; then
            menu
            exit 0
        fi
        continue
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

echo -e "\e[36m──────────────────────────────────────────\e[0m"
echo -e " \e[33mPILIH JALUR DOMAIN AKUN:\e[0m"
echo -e " [1] Domain Biasa / Direct (${domain_direct})"
echo -e " [2] Domain AWS CloudFront (${domain_cf})"
echo -e " [3] Tampilkan Keduanya (Output Terpisah)"
echo -e "\e[36m──────────────────────────────────────────\e[0m"
read -p " Pilihan Jalur [1-3, Default 1]: " opt_domain
[ -z "$opt_domain" ] && opt_domain="1"

# Generate UUID & Tanggal Expired
uuid=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || python3 -c 'import uuid; print(uuid.uuid4())')
exp=$(date -d "+$masaaktif days" +"%Y-%m-%d" 2>/dev/null || date -d "$masaaktif days" +"%Y-%m-%d" 2>/dev/null || date -v+${masaaktif}d +"%Y-%m-%d" 2>/dev/null)
[ -z "$exp" ] && exp=$(date -d "+30 days" +"%Y-%m-%d" 2>/dev/null || date +"%Y-%m-%d")

# Injeksi ke Config Xray menggunakan Python 3 (Aman & Presisi)
python3 - <<EOF
import json
try:
    with open("$CONFIG_XRAY", "r") as f:
        data = json.load(f)
    for ib in data.get("inbounds", []):
        if ib.get("protocol") == "vmess":
            clients = ib.setdefault("settings", {}).setdefault("clients", [])
            clients.append({
                "id": "$uuid",
                "alterId": 0,
                "email": "$user"
            })
    with open("$CONFIG_XRAY", "w") as f:
        json.dump(data, f, indent=2)
except Exception as e:
    print("Gagal mengupdate config:", e)
EOF


# Simpan ke Database
echo "${user} | ${uuid} | ${exp} | vmess" >> /etc/premdigital/xray-users.db
systemctl restart xray > /dev/null 2>&1

# Simpan riwayat user
echo "$user | $uuid | $exp | vmess" >> /etc/premdigital/xray-users.db

# ==========================================
# Generate 5 Link JSON (Direct Domain)
# ==========================================
domain="${domain_direct}"

# 1. WS TLS Direct
json_ws_tls=$(cat <<EOF
{
  "v": "2",
  "ps": "${user}",
  "add": "${domain}",
  "port": "443",
  "id": "${uuid}",
  "aid": "0",
  "net": "ws",
  "path": "/vmess",
  "type": "none",
  "host": "${domain}",
  "sni": "${domain}",
  "tls": "tls"
}
EOF
)
link_ws_tls="vmess://$(echo -n "$json_ws_tls" | base64 -w 0 2>/dev/null || echo -n "$json_ws_tls" | base64)"

# 2. WS Non-TLS Direct
json_ws_ntls=$(cat <<EOF
{
  "v": "2",
  "ps": "${user}",
  "add": "${domain}",
  "port": "80",
  "id": "${uuid}",
  "aid": "0",
  "net": "ws",
  "path": "/vmess",
  "type": "none",
  "host": "${domain}",
  "sni": "${domain}",
  "tls": "none"
}
EOF
)
link_ws_ntls="vmess://$(echo -n "$json_ws_ntls" | base64 -w 0 2>/dev/null || echo -n "$json_ws_ntls" | base64)"

# 3. gRPC Direct
json_grpc=$(cat <<EOF
{
  "v": "2",
  "ps": "${user}",
  "add": "${domain}",
  "port": "443",
  "id": "${uuid}",
  "aid": "0",
  "net": "grpc",
  "path": "vmess",
  "type": "none",
  "host": "${domain}",
  "sni": "${domain}",
  "tls": "tls"
}
EOF
)
link_grpc="vmess://$(echo -n "$json_grpc" | base64 -w 0 2>/dev/null || echo -n "$json_grpc" | base64)"

# 4. HTTP Upgrade TLS Direct
json_up_tls=$(cat <<EOF
{
  "v": "2",
  "ps": "${user}",
  "add": "${domain}",
  "port": "443",
  "id": "${uuid}",
  "aid": "0",
  "net": "httpupgrade",
  "path": "/upvmess",
  "type": "none",
  "host": "${domain}",
  "sni": "${domain}",
  "tls": "tls"
}
EOF
)
link_up_tls="vmess://$(echo -n "$json_up_tls" | base64 -w 0 2>/dev/null || echo -n "$json_up_tls" | base64)"

# 5. HTTP Upgrade Non-TLS Direct
json_up_ntls=$(cat <<EOF
{
  "v": "2",
  "ps": "${user}",
  "add": "${domain}",
  "port": "80",
  "id": "${uuid}",
  "aid": "0",
  "net": "httpupgrade",
  "path": "/upvmess",
  "type": "none",
  "host": "${domain}",
  "sni": "${domain}",
  "tls": "none"
}
EOF
)
link_up_ntls="vmess://$(echo -n "$json_up_ntls" | base64 -w 0 2>/dev/null || echo -n "$json_up_ntls" | base64)"

# ==========================================
# Generate 5 Link JSON (CloudFront CDN)
# ==========================================
cf_ws_tls=$(cat <<EOF
{
  "v": "2",
  "ps": "${user}-CloudFront",
  "add": "${domain_cf}",
  "port": "443",
  "id": "${uuid}",
  "aid": "0",
  "net": "ws",
  "path": "/vmess",
  "type": "none",
  "host": "${domain_cf}",
  "sni": "${domain_cf}",
  "tls": "tls"
}
EOF
)
cf_link_ws_tls="vmess://$(echo -n "$cf_ws_tls" | base64 -w 0 2>/dev/null || echo -n "$cf_ws_tls" | base64)"

cf_ws_ntls=$(cat <<EOF
{
  "v": "2",
  "ps": "${user}-CloudFront",
  "add": "${domain_cf}",
  "port": "80",
  "id": "${uuid}",
  "aid": "0",
  "net": "ws",
  "path": "/vmess",
  "type": "none",
  "host": "${domain_cf}",
  "sni": "${domain_cf}",
  "tls": "none"
}
EOF
)
cf_link_ws_ntls="vmess://$(echo -n "$cf_ws_ntls" | base64 -w 0 2>/dev/null || echo -n "$cf_ws_ntls" | base64)"

cf_grpc=$(cat <<EOF
{
  "v": "2",
  "ps": "${user}-CloudFront",
  "add": "${domain_cf}",
  "port": "443",
  "id": "${uuid}",
  "aid": "0",
  "net": "grpc",
  "path": "vmess",
  "type": "none",
  "host": "${domain_cf}",
  "sni": "${domain_cf}",
  "tls": "tls"
}
EOF
)
cf_link_grpc="vmess://$(echo -n "$cf_grpc" | base64 -w 0 2>/dev/null || echo -n "$cf_grpc" | base64)"

cf_up_tls=$(cat <<EOF
{
  "v": "2",
  "ps": "${user}-CloudFront",
  "add": "${domain_cf}",
  "port": "443",
  "id": "${uuid}",
  "aid": "0",
  "net": "httpupgrade",
  "path": "/upvmess",
  "type": "none",
  "host": "${domain_cf}",
  "sni": "${domain_cf}",
  "tls": "tls"
}
EOF
)
cf_link_up_tls="vmess://$(echo -n "$cf_up_tls" | base64 -w 0 2>/dev/null || echo -n "$cf_up_tls" | base64)"

cf_up_ntls=$(cat <<EOF
{
  "v": "2",
  "ps": "${user}-CloudFront",
  "add": "${domain_cf}",
  "port": "80",
  "id": "${uuid}",
  "aid": "0",
  "net": "httpupgrade",
  "path": "/upvmess",
  "type": "none",
  "host": "${domain_cf}",
  "sni": "${domain_cf}",
  "tls": "none"
}
EOF
)
cf_link_up_ntls="vmess://$(echo -n "$cf_up_ntls" | base64 -w 0 2>/dev/null || echo -n "$cf_up_ntls" | base64)"

# ==========================================
# Output Hasil di Terminal
# ==========================================
clear

if [ "$opt_domain" == "1" ] || [ "$opt_domain" == "3" ]; then
echo -e "\e[1;32m✅  SUKSES CREATE AKUN VMESS (DOMAIN DIRECT)\e[0m"
echo -e "\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
echo -e "👤 Username     : \e[1;33m${user}\e[0m"
echo -e "🆔 UUID         : \e[1;37m${uuid}\e[0m"
echo -e "🌍 Host / SNI   : \e[1;37m${domain_direct}\e[0m"
echo -e "⏳ Masa Aktif   : \e[1;37m${masaaktif} Hari\e[0m"
echo -e "📅 Expired Pada : \e[1;31m${exp}\e[0m"
echo -e "🛡️ Max Login    : \e[1;32m2 IP (AutoKill)\e[0m"
echo -e "\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
echo -e "🔒 \e[1;32m1. WS TLS (Port 443)\e[0m"
echo -e "${link_ws_tls}"
echo -e "🔓 \e[1;32m2. WS Non-TLS (Port 80)\e[0m"
echo -e "${link_ws_ntls}"
echo -e "⚡ \e[1;32m3. gRPC (Port 443)\e[0m"
echo -e "${link_grpc}"
echo -e "🚀 \e[1;32m4. HTTPUpgrade TLS (Port 443)\e[0m"
echo -e "${link_up_tls}"
echo -e "📡 \e[1;32m5. HTTPUpgrade Non-TLS (Port 80)\e[0m"
echo -e "${link_up_ntls}"
echo -e "\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
fi

if [ "$opt_domain" == "2" ] || [ "$opt_domain" == "3" ]; then
[ "$opt_domain" == "3" ] && echo -e "\n"
echo -e "\e[1;33m☁️  SUKSES CREATE AKUN VMESS (AWS CLOUDFRONT CDN)\e[0m"
echo -e "\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
echo -e "👤 Username     : \e[1;33m${user}\e[0m"
echo -e "🆔 UUID         : \e[1;37m${uuid}\e[0m"
echo -e "☁️ Server CDN   : \e[1;37m${domain_cf}\e[0m"
echo -e "🌍 Origin VPS   : \e[1;37m${domain_direct}\e[0m"
echo -e "⏳ Masa Aktif   : \e[1;37m${masaaktif} Hari\e[0m"
echo -e "📅 Expired Pada : \e[1;31m${exp}\e[0m"
echo -e "🛡️ Max Login    : \e[1;32m2 IP (AutoKill)\e[0m"
echo -e "\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
echo -e "🔒 \e[1;33m1. CloudFront WS TLS (Port 443)\e[0m"
echo -e "${cf_link_ws_tls}"
echo -e "🔓 \e[1;33m2. CloudFront WS Non-TLS (Port 80)\e[0m"
echo -e "${cf_link_ws_ntls}"
echo -e "⚡ \e[1;33m3. CloudFront gRPC (Port 443)\e[0m"
echo -e "${cf_link_grpc}"
echo -e "🚀 \e[1;33m4. CloudFront HTTPUpgrade TLS (Port 443)\e[0m"
echo -e "${cf_link_up_tls}"
echo -e "📡 \e[1;33m5. CloudFront HTTPUpgrade Non-TLS (Port 80)\e[0m"
echo -e "${cf_link_up_ntls}"
echo -e "\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
fi
echo -e "🪁 Terima Kasih telah menggunakan layanan kami!"
echo ""
echo -e "\e[33m====================================================\e[0m"
read -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama..."
menu
