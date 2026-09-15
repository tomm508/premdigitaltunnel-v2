#!/bin/bash
# ==========================================
# Script List Accounts
# ==========================================

clear
echo -e "\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
echo -e "\e[1;33m          DAFTAR AKUN VPN AKTIF           \e[0m"
echo -e "\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"

echo -e "\e[1;32m[+] Akun SSH / Dropbear:\e[0m"
awk -F: '($3>=1000)&&($1!="nobody"){print $1}' /etc/passwd | while read -r line
do
    exp=$(chage -l "$line" 2>/dev/null | grep "Account expires" | awk -F": " '{print $2}')
    if [[ "$exp" != "never" ]]; then
        echo -e "  - Username: \e[1;37m$line\e[0m | Expired: \e[1;31m$exp\e[0m"
    fi
done
echo ""

if [ -f /etc/premdigital/xray-users.db ]; then
    echo -e "\e[1;32m[+] Akun Xray (VMess):\e[0m"
    grep -i "vmess" /etc/premdigital/xray-users.db | while IFS=" | " read -r user uuid exp proto; do
        echo -e "  - Username: \e[1;37m$user\e[0m | Expired: \e[1;31m$exp\e[0m"
    done
    echo ""
    
    echo -e "\e[1;32m[+] Akun Xray (VLess):\e[0m"
    grep -i "vless" /etc/premdigital/xray-users.db | while IFS=" | " read -r user uuid exp proto; do
        echo -e "  - Username: \e[1;37m$user\e[0m | Expired: \e[1;31m$exp\e[0m"
    done
    echo ""

    echo -e "\e[1;32m[+] Akun Xray (Trojan):\e[0m"
    grep -i "trojan" /etc/premdigital/xray-users.db | while IFS=" | " read -r user pass exp proto; do
        echo -e "  - Username: \e[1;37m$user\e[0m | Expired: \e[1;31m$exp\e[0m"
    done
else
    echo -e "\e[1;31mDatabase Xray (/etc/premdigital/xray-users.db) belum dibuat atau kosong.\e[0m"
fi

echo -e "\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
echo ""

echo -e "[33m====================================================[0m"
read -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama..."
menu

