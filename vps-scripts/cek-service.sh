#!/bin/bash
clear
echo -e "\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
echo -e "\e[1;33m          STATUS SEMUA LAYANAN            \e[0m"
echo -e "\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"

services=("ssh" "dropbear" "stunnel4" "ws-openssh" "xray" "udp-custom" "badvpn-7100" "badvpn-7200" "badvpn-7300" "cron")

for svc in "${services[@]}"; do
    if systemctl is-active --quiet $svc; then
        echo -e " 🔹 $svc \t: \e[1;32m[ RUNNING ]\e[0m"
    else
        echo -e " 🔹 $svc \t: \e[1;31m[ STOPPED / ERROR ]\e[0m"
    fi
done
echo -e "\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
echo ""
echo -e "\e[33m[1]\e[0m Restart Semua Layanan (Fix Error)"
echo -e "\e[33m[0]\e[0m Kembali ke Menu Utama"
echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
read -p " Pilih [0-1]: " opt_svc
if [ "$opt_svc" == "1" ]; then
    echo -e "\e[33mMerestart layanan...\e[0m"
    for svc in "${services[@]}"; do
        systemctl restart $svc 2>/dev/null
    done
    echo -e "\e[1;32mRestart Selesai!\e[0m"
    sleep 2
fi
menu
