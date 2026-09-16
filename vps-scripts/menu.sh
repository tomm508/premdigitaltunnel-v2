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
if systemctl is-active --quiet udp-custom || systemctl is-active --quiet badvpn-7100; then udp_st="${GREEN}ON${NC}"; else udp_st="${RED}OFF${NC}"; fi
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
echo -e "${BLUE}====================================================${NC}"
echo -e " ╭──────────────────────────────────────────────────╮"
echo -e " │  SSH/WS: $ssh_st  │  X-RAY: $xray_st  │  UDP: $udp_st  │  $sys_health   │"
echo -e " ╰──────────────────────────────────────────────────╯"
echo -e " ${YELLOW}[1]${NC} Creat SSH/WS"
echo -e " ${YELLOW}[2]${NC} Creat Vmess"
echo -e " ${YELLOW}[3]${NC} Creat Vless"
echo -e " ${YELLOW}[4]${NC} Creat Trojan"
echo -e " ${YELLOW}[5]${NC} Account Summary { SSH/WS & Xray }"
echo -e " ${YELLOW}[6]${NC} Delete Account { SSH/WS & Xray }"
echo -e " ${YELLOW}[7]${NC} Change Domain"
echo -e " ${YELLOW}[8]${NC} Web Connection Setting"
echo -e " ${YELLOW}[9]${NC} Service Status & Restart"
echo -e " ${YELLOW}[10]${NC} ❗Uninstall Script❗"
echo -e " ${YELLOW}[0]${NC} Keluar"
echo -e "${BLUE}====================================================${NC}"
read -p " Pilih Menu [0-10] : " menu_num

case $menu_num in
    1) bash /vps-scripts/add-ssh.sh ;;
    2) bash /vps-scripts/add-vmess.sh ;;
    3) bash /vps-scripts/add-vless.sh ;;
    4) bash /vps-scripts/add-trojan.sh ;;
    5) 
        bash /vps-scripts/list-account.sh
        ;;
    6) 
        echo -e "\n${YELLOW}Pilih Tipe Akun yang akan dihapus:${NC}"
        echo "1. Akun SSH/WS"
        echo "2. Akun Xray (Vmess/Vless/Trojan)"
        read -p "Pilihan [1/2]: " del_opt
        if [ "$del_opt" == "1" ]; then bash /vps-scripts/del-ssh.sh; else bash /vps-scripts/del-account.sh; fi
        ;;
    7)
        echo -e "\n${CYAN}====================================================${NC}"
        echo -e "${GREEN}                  GANTI DOMAIN VPS                  ${NC}"
        echo -e "${CYAN}====================================================${NC}"
        read -p " Masukkan Domain Baru: " new_domain
        if [ -n "$new_domain" ]; then
            echo "$new_domain" > /etc/vps-domain.txt
            echo -e "\n${YELLOW}[1/3] Menghasilkan Sertifikat SSL baru untuk $new_domain...${NC}"
            mkdir -p /etc/xray
            openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -sha256 \
            -subj "/C=ID/ST=DKI Jakarta/L=Jakarta/O=PremDigital/OU=PremDigital/CN=$new_domain" \
            -out /etc/xray/xray.crt -keyout /etc/xray/xray.key 2>/dev/null
            chmod 644 /etc/xray/xray.crt 2>/dev/null
            chmod 600 /etc/xray/xray.key 2>/dev/null
            
            echo -e "${YELLOW}[2/3] Merestart Stunnel4 & Xray...${NC}"
            systemctl restart stunnel4 2>/dev/null || true
            systemctl restart xray 2>/dev/null || true
            systemctl restart ws-openssh 2>/dev/null || true
            
            echo -e "${GREEN}[3/3] Sukses! Domain VPS berhasil diubah ke: $new_domain${NC}"
            echo ""
            echo -e "${YELLOW}====================================================${NC}"
            read -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama..."
            menu
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
            echo -e "${CYAN}Memulai instalasi Daemon Telemetri...${NC}"
            echo ""
            echo "Silakan masukkan detail VPS untuk Web Panel:"
            read -p "Masukkan ID Server (contoh: sg-premium-01): " NODE_ID
            read -p "Masukkan Nama Server (contoh: SG1 DigitalOcean): " NODE_NAME
            read -p "Masukkan Kota (contoh: Singapore): " CITY
            read -p "Masukkan Kode Negara (contoh: SG): " COUNTRY_CODE
            
            # Buat file konfigurasi
            cat > /root/node_config.txt << EOF_CONFIG
NODE_ID="$NODE_ID"
NODE_NAME="$NODE_NAME"
CITY="$CITY"
COUNTRY_CODE="$COUNTRY_CODE"
PROJECT_ID="web-premdigitalvpn"
API_KEY="AIzaSyDEtjcfHC9cnqxdTpMv8hnRUMDv4c5EYB4"
EOF_CONFIG

            echo -e "${GREEN}Konfigurasi berhasil disimpan di /root/node_config.txt${NC}"
            echo -e "${CYAN}Membuat script Auto-Reporter...${NC}"
            
            # Buat script reporter langsung di VPS tanpa curl ke github
            cat > /root/premdigital_reporter.sh << 'EOF_REPORTER'
#!/bin/bash
source /root/node_config.txt
if [ -z "$REST_URL" ]; then
    REST_URL="https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/vps_nodes"
fi
SERVER_IP=$(curl -s https://api.ipify.org || hostname -I | awk '{print $1}')
[ -z "$SERVER_IP" ] && SERVER_IP="127.0.0.1"
RAM_USAGE=$(free | grep Mem | awk '{print int($3/$2 * 100.0)}')
CPU_LOAD=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d, -f1 | awk '{print int($1 * 100)}')
ONLINE_USERS=$(netstat -tnpa 2>/dev/null | grep 'ESTABLISHED.*sshd' | wc -l)
JSON_PAYLOAD=$(cat <<EOF
{
  "fields": {
    "name": { "stringValue": "${NODE_NAME}" },
    "ip": { "stringValue": "${SERVER_IP}" },
    "city": { "stringValue": "${CITY}" },
    "countryCode": { "stringValue": "${COUNTRY_CODE}" },
    "status": { "stringValue": "Online" },
    "onlineUsers": { "integerValue": "${ONLINE_USERS}" },
    "cpuLoad": { "integerValue": "${CPU_LOAD}" },
    "ramUsage": { "integerValue": "${RAM_USAGE}" },
    "lastHeartbeat": { "timestampValue": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" }
  }
}
EOF
)
curl -s -X PATCH "${REST_URL}/${NODE_ID}?key=${API_KEY}" -H "Content-Type: application/json" -d "${JSON_PAYLOAD}" > /dev/null
EOF_REPORTER

            chmod +x /root/premdigital_reporter.sh
            (crontab -l 2>/dev/null | grep -v "premdigital_reporter.sh"; echo "*/1 * * * * /root/premdigital_reporter.sh >/dev/null 2>&1") | crontab -
            
            echo -e "${CYAN}Mengirim status pertama kali ke Web Panel...${NC}"
            /root/premdigital_reporter.sh &
            
            echo -e "${GREEN}[SUCCESS] Instalasi selesai! VPS ini sekarang akan otomatis melapor ke Web Admin setiap 1 menit.${NC}"
            echo ""
            read -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama..."
            menu
        elif [ "$web_opt" == "2" ]; then
            echo -e "${CYAN}Mengganti Data Server VPS...${NC}"
            if [ -f /root/node_config.txt ]; then
                source /root/node_config.txt
                echo "Data saat ini:"
                echo "ID Server: $NODE_ID"
                echo "Nama     : $NODE_NAME"
                echo "Kota     : $CITY"
                echo "Negara   : $COUNTRY_CODE"
                echo ""
            fi
            echo "Silakan masukkan detail baru (kosongkan lalu enter jika tidak ingin mengubah baris tersebut):"
            read -p "Masukkan ID Server [$NODE_ID]: " NEW_NODE_ID
            read -p "Masukkan Nama Server [$NODE_NAME]: " NEW_NODE_NAME
            read -p "Masukkan Kota [$CITY]: " NEW_CITY
            read -p "Masukkan Kode Negara [$COUNTRY_CODE]: " NEW_COUNTRY_CODE
            
            NODE_ID="${NEW_NODE_ID:-$NODE_ID}"
            NODE_NAME="${NEW_NODE_NAME:-$NODE_NAME}"
            CITY="${NEW_CITY:-$CITY}"
            COUNTRY_CODE="${NEW_COUNTRY_CODE:-$COUNTRY_CODE}"
            
            cat > /root/node_config.txt << EOF_CONFIG
NODE_ID="$NODE_ID"
NODE_NAME="$NODE_NAME"
CITY="$CITY"
COUNTRY_CODE="$COUNTRY_CODE"
PROJECT_ID="web-premdigitalvpn"
API_KEY="AIzaSyDEtjcfHC9cnqxdTpMv8hnRUMDv4c5EYB4"
EOF_CONFIG
            
            echo -e "${GREEN}Konfigurasi berhasil diupdate di /root/node_config.txt!${NC}"
            if [ -f /root/premdigital_reporter.sh ]; then
                echo "Mengirim update status seketika ke Web Panel..."
                /root/premdigital_reporter.sh &
            fi
            echo ""
            read -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama..."
            menu
        elif [ "$web_opt" == "0" ]; then
            menu
        else
            menu
        fi
        ;;
    9) 
        bash /vps-scripts/cek-service.sh
        ;;
    10) 
        if [ -f /vps-scripts/uninstall.sh ]; then bash /vps-scripts/uninstall.sh; fi
        ;;
    0) clear ; exit 0 ;;
    *) 
        echo -e "${RED}Pilihan tidak valid!${NC}" 
        sleep 2
        menu
        ;;
esac
