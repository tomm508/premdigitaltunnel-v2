#!/bin/bash
clear
echo -e "\e[36m====================================================\e[0m"
echo -e "\e[32m             PREMDIGITAL TUNNELING MENU             \e[0m"
echo -e "\e[36m====================================================\e[0m"
echo -e " \e[33m[1]\e[0m Tambah Akun Vmess"
echo -e " \e[33m[2]\e[0m Tambah Akun Vless"
echo -e " \e[33m[3]\e[0m Tambah Akun Trojan"
echo -e " \e[33m[4]\e[0m Daftar Akun Aktif"
echo -e " \e[33m[5]\e[0m Hapus Akun"
echo -e " \e[33m[6]\e[0m Restart Service (Xray & Bot)"
echo -e " \e[33m[7]\e[0m Hapus Script (Uninstall)"
echo -e " \e[33m[0]\e[0m Keluar"
echo -e "\e[36m====================================================\e[0m"
read -p " Pilih Menu [0-7] : " menu_num

case $menu_num in
    1) add-vmess ;;
    2) add-vless ;;
    3) add-trojan ;;
    4) list-account ;;
    5) del-account ;;
    6) 
        echo "Merestart layanan..."
        systemctl restart xray
        systemctl restart vps-bot 2>/dev/null
        echo -e "\e[32mSelesai merestart Xray dan Bot!\e[0m"
        ;;
    7) 
        if [ -f /vps-scripts/uninstall.sh ]; then
            bash /vps-scripts/uninstall.sh
        else
            echo "Script uninstall tidak ditemukan!"
        fi
        ;;
    0) exit 0 ;;
    *) echo -e "\e[31mPilihan tidak valid!\e[0m" ;;
esac
