#!/bin/bash
clear
echo -e "\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
echo -e "\e[1;33m          STATUS SEMUA LAYANAN            \e[0m"
echo -e "\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"

services=("ssh" "dropbear" "stunnel4" "ws-openssh" "xray" "udp-custom" "cron")

for svc in "${services[@]}"; do
    if systemctl is-active --quiet $svc; then
        printf " 🔹 %-15s : \e[1;32m[ RUNNING ]\e[0m
" "$svc"
    else
        printf " 🔹 %-15s : \e[1;31m[ STOPPED / ERROR ]\e[0m
" "$svc"
    fi
done

# Badvpn dipersingkat
if (systemctl is-active --quiet badvpn-7300 || systemctl is-active --quiet badvpn-7100 || systemctl is-active --quiet udpgw) || pgrep -f badvpn-udpgw >/dev/null; then
    printf " 🔹 %-15s : \e[1;32m[ RUNNING ]\e[0m
" "badvpn (71-73)"
else
    printf " 🔹 %-15s : \e[1;31m[ STOPPED / ERROR ]\e[0m
" "badvpn (71-73)"
fi

echo -e "\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
echo ""
echo -e "\e[33m[1]\e[0m Restart Semua Layanan (Normal Restart)"
echo -e "\e[33m[2]\e[0m Auto Repair Xray (Perbaiki Xray Merah / Stopped)"
echo -e "\e[33m[0]\e[0m Kembali ke Menu Utama"
echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
read -p " Pilih [0-2]: " opt_svc

if [ "$opt_svc" == "1" ]; then
    echo -e "\e[33mMerestart layanan...\e[0m"
    for svc in "${services[@]}"; do
        systemctl restart $svc 2>/dev/null
    done
    systemctl restart badvpn-7100 badvpn-7200 badvpn-7300 2>/dev/null
    
    # Cek apakah xray masih mati setelah restart normal
    if ! systemctl is-active --quiet xray; then
        echo -e "\e[1;31m[!] Xray masih gagal start. Menjalankan Auto Repair...\e[0m"
        sleep 1
        if [ -f /vps-scripts/repair-xray.sh ]; then
            bash /vps-scripts/repair-xray.sh
            exit 0
        elif [ -f /usr/local/bin/repair-xray ]; then
            repair-xray
            exit 0
        fi
    fi
    echo -e "\e[1;32mRestart Selesai!\e[0m"
    sleep 2
elif [ "$opt_svc" == "2" ]; then
    if [ -f /vps-scripts/repair-xray.sh ]; then
        bash /vps-scripts/repair-xray.sh
        exit 0
    elif [ -f /usr/local/bin/repair-xray ]; then
        repair-xray
        exit 0
    else
        echo -e "\e[1;31mSkrip repair-xray tidak ditemukan. Silakan update script.\e[0m"
        sleep 2
    fi
fi
menu
