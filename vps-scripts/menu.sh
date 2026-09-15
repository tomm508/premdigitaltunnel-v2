#!/bin/bash
clear

# Warna dan Teks
GREEN='\e[32m'
BLUE='\e[36m'
YELLOW='\e[33m'
CYAN='\e[36m'
RED='\e[31m'
NC='\e[0m'

# Ambil IP dan RAM
MYIP=$(curl -s -m 3 ipv4.icanhazip.com || echo "Unknown")
RAM=$(free -m | awk 'NR==2{printf "%s/%sMB (%.2f%%)", $3,$2,$3*100/$2 }')

if [ -f /etc/vps-domain.txt ]; then
    domain=$(cat /etc/vps-domain.txt)
else
    domain="Belum diset"
fi

echo -e "${BLUE}====================================================${NC}"
echo -e "${GREEN}             PREMDIGITAL TUNNELING MENU             ${NC}"
echo -e "${BLUE}====================================================${NC}"
echo -e " IP VPS    : ${CYAN}$MYIP${NC}"
echo -e " Domain    : ${CYAN}$domain${NC}"
echo -e " RAM Usage : ${CYAN}$RAM${NC}"
echo -e "${BLUE}====================================================${NC}"
echo -e ""
echo -e " ${YELLOW}[1]${NC} Tambah Akun SSH/WS"
echo -e " ${YELLOW}[2]${NC} Tambah Akun Vmess"
echo -e " ${YELLOW}[3]${NC} Tambah Akun Vless"
echo -e " ${YELLOW}[4]${NC} Tambah Akun Trojan"
echo -e " ${YELLOW}[5]${NC} Daftar Akun Xray Aktif"
echo -e " ${YELLOW}[6]${NC} Hapus Akun Xray"
echo -e " ${YELLOW}[7]${NC} Hapus Akun SSH/WS"
echo -e " ${YELLOW}[8]${NC} Edit Domain VPS"
echo -e " ${YELLOW}[9]${NC} Restart Service"
echo -e " ${YELLOW}[10]${NC} Hapus Script (Uninstall)"
echo -e " ${YELLOW}[0]${NC} Keluar"
echo -e ""
echo -e "${BLUE}====================================================${NC}"
read -p " Pilih Menu [0-10] : " menu_num

case $menu_num in
    1) add-ssh ;;
    2) add-vmess ;;
    3) add-vless ;;
    4) add-trojan ;;
    5) list-account ;;
    6) del-account ;;
    7) del-ssh ;;
    8)
        read -p "Masukkan Domain Baru: " new_domain
        if [ -n "$new_domain" ]; then
            echo "$new_domain" > /etc/vps-domain.txt
            echo -e "${GREEN}Domain berhasil diubah! Restarting...${NC}"
            systemctl restart xray
        fi
        ;;
    9) 
        echo "Merestart layanan..."
        systemctl restart xray
        systemctl restart ssh
        systemctl restart dropbear 2>/dev/null
        systemctl restart stunnel4 2>/dev/null
        
        echo -e "${GREEN}Restart Selesai!${NC}"
        ;;
    10) 
        if [ -f /vps-scripts/uninstall.sh ]; then
            bash /vps-scripts/uninstall.sh
        else
            echo "Script uninstall tidak ditemukan!"
        fi
        ;;
    0) clear ; exit 0 ;;
    *) echo -e "${RED}Pilihan tidak valid!${NC}" ;;
esac
