#!/bin/bash
# ==========================================
# Script Delete SSH Account
# ==========================================

clear
echo -e "\e[36m====================================================\e[0m"
echo -e "\e[31m                 HAPUS AKUN SSH                     \e[0m"
echo -e "\e[36m====================================================\e[0m"
echo -e "\e[33mDaftar Akun SSH/WS di Server:\e[0m"

total_ssh=0
while IFS=: read -r u _ uid _ _ _ _; do
    if [ "$uid" -ge 1000 ] 2>/dev/null && [ "$u" != "nobody" ] && [ "$u" != "root" ]; then
        exp=$(chage -l "$u" 2>/dev/null | grep "Account expires" | awk -F": " '{print $2}')
        echo -e "  - Username: \e[1;32m$u\e[0m | Expired: \e[1;31m$exp\e[0m"
        total_ssh=$((total_ssh + 1))
    fi
done < /etc/passwd

if [ $total_ssh -eq 0 ]; then
    echo -e "  \e[31m(Tidak ada akun SSH)\e[0m"
fi

echo -e "\e[36m====================================================\e[0m"
read -p "Masukkan Username yang akan dihapus: " username

if [ -z "$username" ]; then
    echo -e "\e[31mUsername tidak boleh kosong!\e[0m"
    sleep 2
    menu
    exit 0
fi

if ! id "$username" >/dev/null 2>&1; then
    echo -e "\e[31mUsername '$username' tidak ditemukan!\e[0m"
    sleep 2
    menu
    exit 1
fi

pkill -u "$username" 2>/dev/null || true
userdel -f "$username" 2>/dev/null
rm -f "/etc/premdigital/multilogin/$username" 2>/dev/null
rm -f "/etc/premdigital/user_quota/$username" 2>/dev/null

echo -e "\e[32mAkun '$username' berhasil dihapus!\e[0m"
echo -e "\e[33m====================================================\e[0m"
read -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama..."
menu
