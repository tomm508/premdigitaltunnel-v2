#!/bin/bash
# ==========================================
# PremDigital - Menu Load Balancer & Server Migration
# ==========================================

RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
CYAN='\e[1;36m'
NC='\e[0m'

clear

# Cek Status HAProxy
if systemctl is-active --quiet haproxy; then
    st_lb="${GREEN}AKTIF (RUNNING)${NC}"
else
    st_lb="${RED}NON-AKTIF (STOPPED)${NC}"
fi

MYIP=$(curl -s -m 3 ipv4.icanhazip.com || echo "127.0.0.1")

echo -e "${BLUE}====================================================${NC}"
echo -e "${GREEN}      LOAD BALANCER & SERVER MIGRATION SYSTEM       ${NC}"
echo -e "${BLUE}====================================================${NC}"
echo -e " Status HAProxy LB : $st_lb"
echo -e " Algoritma         : ${CYAN}leastconn (Beban koneksi paling ringan)${NC}"
echo -e " Port Listener     : ${YELLOW}80 (WS HTTP) & 443 (TLS/HTTPS)${NC}"
echo -e " Stats Dashboard   : ${CYAN}http://$MYIP:8443${NC} (admin:premdigital)"
echo -e "${BLUE}====================================================${NC}"
echo -e " ${YELLOW}[1]${NC} Pasang / Update HAProxy Load Balancer"
echo -e " ${YELLOW}[2]${NC} Status & Statistik HAProxy Real-time"
echo -e " ${YELLOW}[3]${NC} Restart Service HAProxy"
echo -e " ${YELLOW}[4]${NC} Matikan HAProxy"
echo -e " ${YELLOW}[5]${NC} 🚀 1-Click Migrasi Server (VPS A ➔ VPS B)"
echo -e " ${YELLOW}[6]${NC} Panduan DNS Failover / Switch Domain"
echo -e " ${YELLOW}[0]${NC} Kembali ke Menu Utama"
echo -e "${BLUE}====================================================${NC}"
read -p " Pilih opsi [0-6]: " opt_lb

case $opt_lb in
    1)
        clear
        bash /vps-scripts/setup-haproxy-lb.sh
        echo ""
        read -n 1 -s -r -p "Tekan Enter untuk kembali..."
        bash "$0"
        ;;
    2)
        clear
        echo -e "${CYAN}====================================================${NC}"
        echo -e "${YELLOW}           STATUS LOAD BALANCER HAPROXY             ${NC}"
        echo -e "${CYAN}====================================================${NC}"
        systemctl status haproxy --no-pager
        echo ""
        read -n 1 -s -r -p "Tekan Enter untuk kembali..."
        bash "$0"
        ;;
    3)
        clear
        echo -e "${YELLOW}Merestart HAProxy...${NC}"
        systemctl restart haproxy
        echo -e "${GREEN}Selesai!${NC}"
        sleep 2
        bash "$0"
        ;;
    4)
        clear
        echo -e "${YELLOW}Menghentikan HAProxy...${NC}"
        systemctl stop haproxy
        systemctl disable haproxy 2>/dev/null
        echo -e "${GREEN}HAProxy dimatikan.${NC}"
        sleep 2
        bash "$0"
        ;;
    5)
        bash /vps-scripts/migrate.sh
        bash "$0"
        ;;
    6)
        clear
        echo -e "${CYAN}====================================================${NC}"
        echo -e "${GREEN}      PANDUAN MIGRASI SAAT MASA SEWA VPS HABIS      ${NC}"
        echo -e "${CYAN}====================================================${NC}"
        echo -e "Jika VPS A akan habis masa sewanya dan Anda menyewa VPS B:"
        echo -e ""
        echo -e "1. ${YELLOW}Di VPS A (Lama):${NC}"
        echo -e "   - Buka menu: ${CYAN}menu${NC} -> pilih ${CYAN}1-Click Migrasi Server${NC} -> pilih ${CYAN}[1] Export Data${NC}."
        echo -e "   - File ${GREEN}/root/premdigital_backup.tar.gz${NC} otomatis terbuat."
        echo -e ""
        echo -e "2. ${YELLOW}Di VPS B (Baru):${NC}"
        echo -e "   - Install autoscript PremDigital seperti biasa."
        echo -e "   - Tarik file backup dari VPS A:"
        echo -e "     ${CYAN}scp root@IP_VPS_A:/root/premdigital_backup.tar.gz /root/${NC}"
        echo -e "   - Buka menu migrasi -> pilih ${CYAN}[2] Import Data${NC}."
        echo -e ""
        echo -e "3. ${YELLOW}Arahkan Domain:${NC}"
        echo -e "   - Buka Cloudflare / penyedia DNS Anda."
        echo -e "   - Ubah A Record domain Anda dari IP VPS A ke IP VPS B."
        echo -e "   - Selesai! Semua pelanggan langsung otomatis terkoneksi ke VPS B"
        echo -e "     tanpa perlu ubah akun atau password."
        echo -e "${CYAN}====================================================${NC}"
        echo ""
        read -n 1 -s -r -p "Tekan Enter untuk kembali..."
        bash "$0"
        ;;
    0)
        menu 2>/dev/null || bash /vps-scripts/menu.sh
        ;;
    *)
        bash "$0"
        ;;
esac
