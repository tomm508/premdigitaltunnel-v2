#!/bin/bash
# ==========================================
# Script Add SSH/WS Account
# ==========================================

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

clear
echo -e "\e[36m====================================================\e[0m"
echo -e "\e[32m             TAMBAH AKUN SSH & WEBSOCKET            \e[0m"
echo -e "\e[36m====================================================\e[0m"

while true; do
    read -p "Username SSH : " username
    username=$(echo "$username" | tr -d "\r\n " | tr -cd "[:alnum:]_")
    if [ -z "$username" ]; then
        echo -e "\e[31mUsername tidak boleh kosong!\e[0m"
        continue
    fi
    if id "$username" >/dev/null 2>&1; then
        echo -e "\e[31mUsername '$username' sudah terdaftar!\e[0m"
        echo -e " \e[33m[1]\e[0m Masukkan username lain"
        echo -e " \e[33m[0]\e[0m Kembali ke Menu Utama"
        read -p " Pilihan [0-1, Default 1]: " opt_dup
        if [ "$opt_dup" == "0" ]; then
            menu
            exit 0
        fi
        continue
    fi
    break
done

while true; do
    read -p "Password SSH : " password
    if [ -z "$password" ]; then
        echo -e "\e[31mPassword tidak boleh kosong!\e[0m"
        continue
    fi
    break
done

while true; do
    read -p "Durasi (Hari, Default 30): " masaaktif
    [ -z "$masaaktif" ] && masaaktif=30
    if [[ ! "$masaaktif" =~ ^[0-9]+$ ]] || [ "$masaaktif" -le 0 ]; then
        echo -e "\e[31mDurasi harus berupa angka positif!\e[0m"
        continue
    fi
    break
done

echo -e "\e[36m────────────────────────────────────────────────────\e[0m"
echo -e " \e[33mPILIH JALUR DOMAIN AKUN:\e[0m"
echo -e " [1] Domain Biasa / Direct (${domain_direct})"
echo -e " [2] Domain AWS CloudFront (${domain_cf})"
echo -e " [3] Tampilkan Keduanya (Output Terpisah)"
echo -e "\e[36m────────────────────────────────────────────────────\e[0m"
read -p " Pilihan Jalur [1-3, Default 1]: " opt_domain
[ -z "$opt_domain" ] && opt_domain="1"

# Buat user system
useradd -e `date -d "$masaaktif days" +"%Y-%m-%d"` -s /bin/false -M $username
echo -e "$password\n$password" | passwd $username >/dev/null 2>&1

exp=$(chage -l $username | grep "Account expires" | awk -F": " '{print $2}')

clear

# Ambil ISP dengan Cache & Cadangan
ISP=""
if [ -s /etc/premdigital/isp.cache ]; then
    ISP=$(cat /etc/premdigital/isp.cache 2>/dev/null | tr -d '\r\n')
fi
if [ -z "$ISP" ] || [[ "$ISP" == *"Rate limit"* ]] || [[ "$ISP" == *"429"* ]]; then
    RAW_ISP=$(curl -s -m 2 ipinfo.io/org 2>/dev/null)
    if [ -n "$RAW_ISP" ] && [[ ! "$RAW_ISP" == *"Rate limit"* ]] && [[ ! "$RAW_ISP" == *"429"* ]]; then
        ISP=$(echo "$RAW_ISP" | sed -E 's/^AS[0-9]+ //')
    fi
    [ -z "$ISP" ] && ISP=$(curl -s -m 2 "http://ip-api.com/line/?fields=isp" 2>/dev/null)
    [ -n "$ISP" ] && echo "$ISP" > /etc/premdigital/isp.cache 2>/dev/null
fi
[ -z "$ISP" ] && ISP="Internet Provider"

CITY=""
if [ -s /etc/premdigital/city.cache ]; then
    CITY=$(cat /etc/premdigital/city.cache 2>/dev/null | tr -d '\r\n')
fi
if [ -z "$CITY" ] || [[ "$CITY" == *"Rate limit"* ]] || [[ "$CITY" == *"429"* ]]; then
    RAW_CITY=$(curl -s -m 2 ipinfo.io/city 2>/dev/null)
    if [ -n "$RAW_CITY" ] && [[ ! "$RAW_CITY" == *"Rate limit"* ]] && [[ ! "$RAW_CITY" == *"429"* ]]; then
        CITY="$RAW_CITY"
    fi
    [ -z "$CITY" ] && CITY=$(curl -s -m 2 "http://ip-api.com/line/?fields=city" 2>/dev/null)
    [ -n "$CITY" ] && echo "$CITY" > /etc/premdigital/city.cache 2>/dev/null
fi
[ -z "$CITY" ] && CITY="Unknown"

exp_fmt=$(date -d "+$masaaktif days" +"%b %d, %Y" 2>/dev/null || date -d "$masaaktif days" +"%b %d, %Y" 2>/dev/null || echo "$exp")

clear

if [ "$opt_domain" == "1" ] || [ "$opt_domain" == "3" ]; then
echo -e "\e[1;32m✅  SUKSES CREATE AKUN SSH/WS (DOMAIN DIRECT)\e[0m"
echo -e "\e[36m====================================================\e[0m"
echo -e "              INFORMASI AKUN SSH/WS DIRECT          "
echo -e "\e[36m====================================================\e[0m"
echo -e "Host         : $domain_direct"
echo -e "ISP          : $ISP"
echo -e "City         : $CITY"
echo -e "Username     : $username"
echo -e "Password     : $password"
echo -e "Expiry Date  : $exp_fmt"
echo -e "Expiry Time  : $masaaktif Days"
echo -e "Max Login    : 2 IP (AutoKill)"
echo -e "\e[36m====================================================\e[0m"
echo -e "⚙️ Ports Direct:"
echo -e "• OpenSSH     : 22, 3303"
echo -e "• Dropbear    : 109"
echo -e "• SSL/TLS     : 443, 8443"
echo -e "• Non TLS     : 80, 8080, 8888"
echo -e "• OVPN TCP    : 1194"
echo -e "• UDP Custom  : 1-65535"
echo -e "• BadVPN      : 7300"
echo -e "• Squid       : 3128"
echo -e "\e[36m====================================================\e[0m"
echo -e "📌 Payload WS Direct:"
echo -e "GET / HTTP/1.1"
echo -e "Host: $domain_direct"
echo -e "Connection: Upgrade"
echo -e "User-Agent: [ua]"
echo -e "Upgrade: websocket"
echo -e ""
echo -e "📌 Payload Enhanced Direct:"
echo -e "PATCH / HTTP/1.1"
echo -e "Host: $domain_direct"
echo -e "Host: bug.com"
echo -e "Connection: Upgrade"
echo -e "User-Agent: [ua]"
echo -e "Upgrade: websocket"
echo -e "\e[36m====================================================\e[0m"
fi

if [ "$opt_domain" == "2" ] || [ "$opt_domain" == "3" ]; then
[ "$opt_domain" == "3" ] && echo -e "\n"
echo -e "\e[1;33m☁️  SUKSES CREATE AKUN SSH/WS (AWS CLOUDFRONT CDN)\e[0m"
echo -e "\e[36m====================================================\e[0m"
echo -e "              INFORMASI AKUN SSH/WS CLOUDFRONT      "
echo -e "\e[36m====================================================\e[0m"
echo -e "Server CDN   : $domain_cf"
echo -e "Username     : $username"
echo -e "Password     : $password"
echo -e "Expiry Date  : $exp_fmt"
echo -e "Expiry Time  : $masaaktif Days"
echo -e "Max Login    : 2 IP (AutoKill)"
echo -e "\e[36m====================================================\e[0m"
echo -e "⚙️ Ports CloudFront:"
echo -e "• CDN TLS      : 443"
echo -e "• CDN Non-TLS  : 80, 8888"
echo -e "• OpenSSH     : 22, 3303"
echo -e "• Dropbear    : 109"
echo -e "• OVPN TCP    : 1194"
echo -e "• UDP Custom  : 1-65535"
echo -e "• BadVPN      : 7300"
echo -e "• Squid       : 3128"
echo -e ""
echo -e "\e[36m====================================================\e[0m"
echo -e "📌 Payload WS:"
echo -e "GET / HTTP/1.1"
echo -e "Host: $domain_cf"
echo -e "Connection: Upgrade"
echo -e "User-Agent: [ua]"
echo -e "Upgrade: websocket"
echo -e ""
echo -e "📌 Payload Enhanced:"
echo -e "PATCH / HTTP/1.1"
echo -e "Host: $domain_cf"
echo -e "Host: bug.com"
echo -e "Connection: Upgrade"
echo -e "User-Agent: [ua]"
echo -e "Upgrade: websocket"
echo -e "\e[36m====================================================\e[0m"
fi

echo -e "🪁 Terima Kasih telah menggunakan layanan kami!"
echo ""
echo -e "\e[33m====================================================\e[0m"
read -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama..."
menu
