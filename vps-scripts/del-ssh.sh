#!/bin/bash
# ==========================================
# Script Delete SSH Account
# ==========================================

clear
echo -e "\e[36m====================================================\e[0m"
echo -e "\e[31m                 HAPUS AKUN SSH                     \e[0m"
echo -e "\e[36m====================================================\e[0m"

read -p "Masukkan Username yang akan dihapus: " username
if ! id "$username" >/dev/null 2>&1; then
    echo -e "\e[31mUsername '$username' tidak ditemukan!\e[0m"
    exit 1
fi

userdel -f $username
echo -e "\e[32mAkun '$username' berhasil dihapus!\e[0m"
-e 

echo -e "[33m====================================================[0m"
read -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama..."
menu

