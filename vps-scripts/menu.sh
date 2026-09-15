#!/bin/bash
clear

# Warna dan Teks
GREEN='\e[32m'
BLUE='\e[36m'
YELLOW='\e[33m'
CYAN='\e[36m'
RED='\e[31m'
NC='\e[0m' # No Color

# Ambil IP dan RAM
MYIP=$(curl -s -m 3 ipv4.icanhazip.com || echo "Unknown")
RAM=$(free -m | awk 'NR==2{printf "%s/%sMB (%.2f%%)", $3,$2,$3*100/$2 }')

# Ambil Domain
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
echo -e " ${YELLOW}[1]${NC} Tambah Akun Vmess"
echo -e " ${YELLOW}[2]${NC} Tambah Akun Vless"
echo -e " ${YELLOW}[3]${NC} Tambah Akun Trojan"
echo -e " ${YELLOW}[4]${NC} Daftar Akun Aktif (All Protocol)"
echo -e " ${YELLOW}[5]${NC} Hapus Akun"
echo -e " ${YELLOW}[6]${NC} Edit Domain VPS"
echo -e " ${YELLOW}[7]${NC} Restart Service (Xray & Bot)"
echo -e " ${YELLOW}[8]${NC} Hapus Script (Uninstall)"
echo -e " ${YELLOW}[0]${NC} Keluar"
echo -e ""
echo -e "${BLUE}====================================================${NC}"
read -p " Pilih Menu [0-8] : " menu_num

case $menu_num in
    1) add-vmess ;;
    2) add-vless ;;
    3) add-trojan ;;
    4) list-account ;;
    5) del-account ;;
    6)
        read -p "Masukkan Domain Baru (contoh: vpn.domain.com): " new_domain
        if [ -n "$new_domain" ]; then
            echo "$new_domain" > /etc/vps-domain.txt
            echo -e "${GREEN}Domain berhasil diubah ke: $new_domain${NC}"
            echo "Restart layanan Xray untuk menerapkan..."
            systemctl restart xray
        else
            echo -e "${RED}Dibatalkan, domain tidak boleh kosong.${NC}"
        fi
        ;;
    7) 
        echo "Merestart layanan..."
        systemctl restart xray
        systemctl restart vps-bot 2>/dev/null
        echo -e "${GREEN}Selesai merestart Xray dan Bot!${NC}"
        ;;
    8) 
        if [ -f /vps-scripts/uninstall.sh ]; then
            bash /vps-scripts/uninstall.sh
        else
            echo "Script uninstall tidak ditemukan!"
        fi
        ;;
    0) clear ; exit 0 ;;
    *) echo -e "${RED}Pilihan tidak valid!${NC}" ;;
esac
