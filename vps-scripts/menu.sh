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
RAM=$(free -m | awk 'NR==2{printf "%s/%sMB { %.2f%% }", $3,$2,$3*100/$2 }')

# Ambil OS dan ISP
OS=$(cat /etc/os-release | grep -w PRETTY_NAME | head -n1 | cut -d '"' -f 2)
ISP=$(curl -s -m 5 ipinfo.io/org | cut -d " " -f 2- || echo "Unknown")

# Ambil Bandwidth (Membaca tx/rx dari interface utama dan diformat otomatis KB/MB/GB/TB)
IFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
if [ -n "$IFACE" ] && [ -f /sys/class/net/$IFACE/statistics/rx_bytes ]; then
    RX=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
    TX=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)
    
    # Fungsi konversi bytes ke human readable (KB, MB, GB, TB)
    TX_FORMAT=$(echo $TX | awk '{ split("B KB MB GB TB", v); s=1; while($1>1024){$1/=1024; s++} printf "%.2f %s", $1, v[s] }')
    
    BWIDTH="$TX_FORMAT { 5TB }"
else
    BWIDTH="Unknown"
fi

if [ -f /etc/vps-domain.txt ]; then
    domain=$(cat /etc/vps-domain.txt)
else
    domain="Belum diset"
fi

# Cek Status Service
if systemctl is-active --quiet ssh; then ssh_st="${GREEN}ON${NC}"; else ssh_st="${RED}OFF${NC}"; fi
if systemctl is-active --quiet xray; then xray_st="${GREEN}ON${NC}"; else xray_st="${RED}OFF${NC}"; fi
web_st="${GREEN}ON${NC}" # Placeholder
sys_health="${GREEN}GOOD${NC}"

echo -e "${BLUE}====================================================${NC}"
echo -e "${GREEN}               PREMDIGITAL TUNNEL V2                ${NC}"
echo -e "${BLUE}====================================================${NC}"
echo -e " IP VPS    : ${CYAN}$MYIP${NC}"
echo -e " OS        : ${CYAN}$OS${NC}"
echo -e " ISP       : ${CYAN}$ISP${NC}"
echo -e " RAM Usage : ${CYAN}$RAM${NC}"
echo -e " Bandwidth : ${CYAN}$BWIDTH${NC}"
echo -e " Domain    : ${CYAN}$domain${NC}"
echo -e " ╭──────────────────────────────────────────────────╮"
echo -e " │  SSH/WS: $ssh_st  │  X-RAY: $xray_st  │  WEB: $web_st  │  $sys_health   │"
echo -e " ╰──────────────────────────────────────────────────╯"
echo -e " ${YELLOW}[1]${NC} Creat SSH/WS"
echo -e " ${YELLOW}[2]${NC} Creat Vmess"
echo -e " ${YELLOW}[3]${NC} Creat Vless"
echo -e " ${YELLOW}[4]${NC} Creat Trojan"
echo -e " ${YELLOW}[5]${NC} Account Summary { SSH/WS & Xray }"
echo -e " ${YELLOW}[6]${NC} Delete Account { SSH/WS & Xray }"
echo -e " ${YELLOW}[7]${NC} Change Domain"
echo -e " ${YELLOW}[8]${NC} Web Connection Setting"
echo -e " ${YELLOW}[9]${NC} Restart All Service"
echo -e " ${YELLOW}[10]${NC} ❗Uninstall Script❗"
echo -e " ${YELLOW}[0]${NC} Keluar"
echo -e "${BLUE}====================================================${NC}"
read -p " Pilih Menu [0-10] : " menu_num

case $menu_num in
    1) add-ssh ;;
    2) add-vmess ;;
    3) add-vless ;;
    4) add-trojan ;;
    5) 
        clear
        echo -e "${BLUE}=== Akun SSH/WS ===${NC}"
        awk -F: '($3>=1000)&&($1!="nobody"){print $1}' /etc/passwd | grep -v 'ubuntu'
        echo -e "\n${BLUE}=== Akun Xray ===${NC}"
        list-account 
        ;;
    6) 
        echo -e "\n${YELLOW}Pilih Tipe Akun yang akan dihapus:${NC}"
        echo "1. Akun SSH/WS"
        echo "2. Akun Xray (Vmess/Vless/Trojan)"
        read -p "Pilihan [1/2]: " del_opt
        if [ "$del_opt" == "1" ]; then del-ssh; else del-account; fi
        ;;
    7)
        read -p "Masukkan Domain Baru: " new_domain
        if [ -n "$new_domain" ]; then
            echo "$new_domain" > /etc/vps-domain.txt
            echo -e "${GREEN}Domain berhasil diubah! Restarting...${NC}"
            systemctl restart xray
        fi
        ;;
    8)
        clear
        echo -e "${GREEN}============================================${NC}"
        echo -e "${GREEN}        WEB CONNECTION SETTING              ${NC}"
        echo -e "${GREEN}============================================${NC}"
        echo -e "Menu ini digunakan untuk menyambungkan VPS Anda"
        echo -e "ke Dashboard Web Panel PremDigital via Firebase."
        echo -e ""
        echo -e "1. Install Daemon Telemetri & Auto-Creator"
        echo -e "2. Ganti ID Server (Node ID)"
        echo -e "0. Kembali"
        read -p "Pilih [0-2]: " web_opt
        if [ "$web_opt" == "1" ]; then
            echo -e "${CYAN}Mengunduh script worker Firebase... (Fitur ini sedang disempurnakan)${NC}"
            # Nanti bisa diisi bash download file worker
        fi
        ;;
    9) 
        echo "Merestart layanan..."
        systemctl restart xray ssh dropbear 2>/dev/null
        echo -e "${GREEN}Restart Selesai!${NC}"
        ;;
    10) 
        if [ -f /vps-scripts/uninstall.sh ]; then bash /vps-scripts/uninstall.sh; fi
        ;;
    0) clear ; exit 0 ;;
    *) echo -e "${RED}Pilihan tidak valid!${NC}" ;;
esac
