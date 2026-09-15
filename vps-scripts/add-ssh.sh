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
echo -e "\e[32m====================================================\e[0m"
echo -e "              INFORMASI AKUN SSH/WS                 "
echo -e "\e[32m====================================================\e[0m"
echo -e "Username   : $username"
echo -e "Password   : $password"
echo -e "Expired    : $exp"
echo -e "\e[36m====================================================\e[0m"
echo -e "Host/IP    : $domain"
echo -e "OpenSSH    : 22"
echo -e "Dropbear   : 109, 143"
echo -e "SSH WS     : 80, 8080"
echo -e "SSH SSL/TLS: 443"
echo -e "UDP Custom : 1-65535"
echo -e "\e[32m====================================================\e[0m"
echo -e "Payload WS:"
echo -e "GET / HTTP/1.1[crlf]Host: $domain[crlf]Upgrade: websocket[crlf][crlf]"
echo -e "\e[36m====================================================\e[0m"
-e 

echo -e "[33m====================================================[0m"
read -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama..."
menu

