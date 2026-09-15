#!/bin/bash
# ==========================================
# Script Add SSH/WS Account
# ==========================================

if [ -f /etc/vps-domain.txt ]; then
    domain=$(cat /etc/vps-domain.txt)
else
    domain=$(curl -s ipv4.icanhazip.com)
fi

clear
echo -e "\e[36m====================================================\e[0m"
echo -e "\e[32m             TAMBAH AKUN SSH & WEBSOCKET            \e[0m"
echo -e "\e[36m====================================================\e[0m"

read -p "Username SSH : " username
if id "$username" >/dev/null 2>&1; then
    echo -e "\e[31mUsername '$username' sudah terdaftar!\e[0m"
    exit 1
fi

read -p "Password SSH : " password
read -p "Durasi (Hari): " masaaktif

# Buat user system
useradd -e `date -d "$masaaktif days" +"%Y-%m-%d"` -s /bin/false -M $username
echo -e "$password\n$password" | passwd $username >/dev/null 2>&1

exp=$(chage -l $username | grep "Account expires" | awk -F": " '{print $2}')

clear

ISP=$(curl -s -m 5 ipinfo.io/org | cut -d " " -f 2- || echo "Unknown")
CITY=$(curl -s -m 5 ipinfo.io/city || echo "Unknown")

clear
echo -e "\e[1;32m✅  SUKSES CREATE AKUN SSH/WS\e[0m"
echo -e "\e[36m====================================================\e[0m"
echo -e "              INFORMASI AKUN SSH/WS                 "
echo -e "\e[36m====================================================\e[0m"
echo -e "Host         : $domain"
echo -e "ISP          : $ISP"
echo -e "City         : $CITY"
echo -e "Username     : $username"
echo -e "Password     : $password"
echo -e "Expiry Date  : $exp"
echo -e "Expiry Time  : $masaaktif Days"
echo -e "\e[36m====================================================\e[0m"
echo -e "⚙️Ports:"
echo -e ""
echo -e "SSL/TLS      : 443, 8443"
echo -e "Non TLS      : 80, 8080"
echo -e "OVPN  TCP    : 1194"
echo -e "OVPN  UDP    : 25000"
echo -e "Dropbear     : 109, 143"
echo -e "UDP Custom   : 1-65535"
echo -e "\e[36m====================================================\e[0m"
echo -e "📌Payload WS:"
echo -e ""
echo -e "GET / HTTP/1.1"
echo -e "Host: $domain"
echo -e "Connection: Upgrade"
echo -e "User-Agent: [ua]"
echo -e "Upgrade: websocket"
echo -e ""
echo -e ""
echo -e "📌Payload Enhanced:"
echo -e ""
echo -e "PATCH / HTTP/1.1"
echo -e "Host: $domain"
echo -e "Host: bug.com"
echo -e "Connection: Upgrade"
echo -e "User-Agent: [ua]"
echo -e "Upgrade: websocket"
echo -e "\e[36m====================================================\e[0m"
echo -e "🪁 Terima Kasih telah menggunakan layanan kami!"
echo ""
echo -e "\e[33m====================================================\e[0m"
read -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama..."
menu
