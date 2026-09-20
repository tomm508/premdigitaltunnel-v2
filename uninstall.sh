#!/bin/bash
# ==========================================
# UNINSTALL SCRIPT - PREMDIGITAL TUNNELING
# Membersihkan Seluruh Komponen, Service, & Binary
# ==========================================

RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
CYAN='\e[36m'
NC='\e[0m'

if [ "${EUID}" -ne 0 ]; then
    echo -e "${RED}Mohon jalankan script ini sebagai root (sudo su)${NC}"
    exit 1
fi

clear
echo -e "${RED}====================================================${NC}"
echo -e "${RED}       UNINSTALL TOTAL PREMDIGITAL TUNNELING        ${NC}"
echo -e "${RED}====================================================${NC}"
echo -e "${YELLOW}PERINGATAN:${NC}"
echo -e "Tindakan ini akan menghapus dan mematikan:"
echo -e " - Service Xray Core (Vmess, Vless, Trojan)"
echo -e " - Service Python SSH WebSocket (Port 80/10080)"
echo -e " - Service Stunnel4 & Dropbear"
echo -e " - Service BadVPN UDPGW (7100, 7200, 7300)"
echo -e " - Service UDP Custom (Port 36712)"
echo -e " - Service Limit Multi-Login (AutoKill & Cron)"
echo -e " - Semua Menu CLI, Script helper, Sertifikat SSL & Log"
echo -e ""
echo -e "${GREEN}Akses SSH standar (Port 22) akan tetap AKTIF & aman.${NC}"
echo -e "${RED}====================================================${NC}"
if [[ "$1" == "-y" || "$1" == "--yes" || "$1" == "-f" ]]; then
    confirm="y"
elif [ -t 0 ]; then
    read -p "Ketik 'y' untuk melanjutkan proses pembersihan total (y/n): " confirm
else
    # Jika dipanggil via pipe seperti: wget ... | bash
    if [ -e /dev/tty ]; then
        read -p "Ketik 'y' untuk melanjutkan proses pembersihan total (y/n): " confirm < /dev/tty
    else
        confirm="y"
    fi
fi

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo -e "${GREEN}Uninstall dibatalkan.${NC}"
    exit 0
fi

echo -e "\n${YELLOW}[1/7] Menghentikan dan menonaktifkan semua service...${NC}"
SERVICES=(
    "xray"
    "xray@none"
    "ws-openssh"
    "ws-proxy"
    "badvpn-7100"
    "badvpn-7200"
    "badvpn-7300"
    "badvpn-udpgw"
    "udp-custom"
    "limit-ip"
    "stunnel4"
    "dropbear"
    "vps-api"
    "vps-bot"
)

for svc in "${SERVICES[@]}"; do
    if systemctl is-active --quiet "$svc" 2>/dev/null || systemctl is-enabled --quiet "$svc" 2>/dev/null; then
        echo -e " - Menghentikan $svc..."
        systemctl stop "$svc" 2>/dev/null
        systemctl disable "$svc" 2>/dev/null
    fi
done

# Matikan proses yang mungkin masih berjalan di background
pkill -9 -f "ws-openssh" 2>/dev/null
pkill -9 -f "badvpn-udpgw" 2>/dev/null
pkill -9 -f "udp-custom" 2>/dev/null
pkill -9 -f "limit-ip.py" 2>/dev/null
pkill -9 -f "xray" 2>/dev/null

echo -e "${YELLOW}[2/7] Menghapus file systemd unit service...${NC}"
SYSTEMD_FILES=(
    "/etc/systemd/system/ws-openssh.service"
    "/etc/systemd/system/ws-proxy.service"
    "/etc/systemd/system/badvpn-7100.service"
    "/etc/systemd/system/badvpn-7200.service"
    "/etc/systemd/system/badvpn-7300.service"
    "/etc/systemd/system/badvpn-udpgw.service"
    "/etc/systemd/system/udp-custom.service"
    "/etc/systemd/system/limit-ip.service"
    "/etc/systemd/system/vps-api.service"
    "/etc/systemd/system/vps-bot.service"
)

for f in "${SYSTEMD_FILES[@]}"; do
    rm -f "$f"
done
systemctl daemon-reload

echo -e "${YELLOW}[3/7] Menghapus cronjob & penjadwal otomatis...${NC}"
rm -f /etc/cron.d/limit-ip
rm -f /etc/cron.d/xp
rm -f /etc/cron.d/auto-delete
crontab -l 2>/dev/null | grep -v "limit-ip" | grep -v "premdigital" | grep -v "auto-kill" | grep -v "auto-delete" | crontab - 2>/dev/null || true

echo -e "${YELLOW}[4/7] Menghapus binary tunneling dan script CLI...${NC}"
BIN_FILES=(
    "/usr/local/bin/xray"
    "/usr/bin/xray"
    "/usr/local/bin/ws-openssh"
    "/usr/local/bin/ws-proxy"
    "/usr/local/bin/badvpn-udpgw"
    "/usr/bin/badvpn-udpgw"
    "/usr/local/bin/udp-custom"
    "/usr/bin/udp-custom"
    "/usr/local/bin/limit-ip.py"
    "/usr/local/bin/limit-ip-menu"
    "/usr/local/bin/limit-ip"
    "/usr/bin/limit-ip"
    "/usr/bin/menu"
    "/usr/bin/menu-service"
    "/usr/bin/add-ssh"
    "/usr/bin/del-ssh"
    "/usr/bin/add-vmess"
    "/usr/bin/add-vless"
    "/usr/bin/add-trojan"
    "/usr/bin/list-account"
    "/usr/bin/del-account"
    "/usr/bin/cek-service"
    "/usr/bin/uninstall"
    "/usr/bin/uninstall-script"
    "/usr/local/bin/vps-api"
    "/usr/local/bin/vps-bot"
    "/usr/local/bin/auto-delete"
    "/usr/local/bin/auto-kill-multilogin"
)

for b in "${BIN_FILES[@]}"; do
    rm -f "$b"
done

echo -e "${YELLOW}[5/7] Menghapus direktori konfigurasi, sertifikat SSL & log...${NC}"
rm -rf /vps-scripts
rm -rf /etc/xray
rm -rf /var/log/xray
rm -rf /etc/udp
rm -rf /etc/stunnel
rm -rf /etc/premdigital
rm -rf /root/badvpn
rm -f /etc/vps-domain.txt
rm -f /etc/limit-ip.conf
rm -f /var/log/limit-ip.log
rm -f /var/log/multilogin.log
rm -f /root/node_config.txt
rm -f /root/premdigital_reporter.sh

echo -e "${YELLOW}[6/7] Mengembalikan konfigurasi SSH & Banner ke standar...${NC}"
if [ -f /etc/issue.net ]; then
    echo "Default SSH Banner" > /etc/issue.net
fi
sed -i '/Banner \/etc\/issue.net/d' /etc/ssh/sshd_config 2>/dev/null
sed -i 's@DropbearBanner="/etc/issue.net"@DropbearBanner=""@g' /etc/default/dropbear 2>/dev/null
sed -i 's@DROPBEAR_BANNER="/etc/issue.net"@DROPBEAR_BANNER=""@g' /etc/default/dropbear 2>/dev/null
sed -i '/alias menu=/d' ~/.bashrc 2>/dev/null

echo -e "${YELLOW}[7/7] Merestart layanan SSH utama...${NC}"
systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null

echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}      UNINSTALL SUKSES! VPS BERSIH 100%             ${NC}"
echo -e "${GREEN}====================================================${NC}"
echo -e "Seluruh port tunneling (80, 443, 8080, 8443, 7100, 7200, 7300, 36712) telah dibebaskan."
echo -e "Akses SSH server Anda tetap berjalan normal di port 22."
echo -e "${GREEN}====================================================${NC}\n"

