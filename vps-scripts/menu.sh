#!/bin/bash
clear

# Warna dan Teks
GREEN='\e[32m'
BLUE='\e[36m'
YELLOW='\e[33m'
CYAN='\e[36m'
RED='\e[31m'
NC='\e[0m'

# Direktori Cache Konfigurasi
mkdir -p /etc/premdigital 2>/dev/null

# Ambil IP VPS dengan Cache & Cadangan Multi-Provider
MYIP=""
if [ -s /etc/premdigital/myip.cache ]; then
    MYIP=$(cat /etc/premdigital/myip.cache 2>/dev/null | tr -d '\r\n ')
fi
if [ -z "$MYIP" ] || [ "$MYIP" == "Unknown" ]; then
    MYIP=$(curl -s -m 2 ipv4.icanhazip.com 2>/dev/null | tr -d '\r\n ')
    [ -z "$MYIP" ] && MYIP=$(curl -s -m 2 api.ipify.org 2>/dev/null | tr -d '\r\n ')
    [ -z "$MYIP" ] && MYIP=$(curl -s -m 2 ipinfo.io/ip 2>/dev/null | tr -d '\r\n ')
    [ -z "$MYIP" ] && MYIP=$(ip -4 addr show scope global 2>/dev/null | grep -Po '(?<=inet )\d+(\.\d+){3}' | head -n1)
    [ -z "$MYIP" ] && MYIP=$(hostname -I 2>/dev/null | awk '{print $1}')
    [ -n "$MYIP" ] && echo "$MYIP" > /etc/premdigital/myip.cache 2>/dev/null
fi
[ -z "$MYIP" ] && MYIP="Unknown"

# Ambil RAM
RAM_DATA=$(free -m 2>/dev/null | awk 'NR==2{if($2>0) printf "%s/%sMB { %.2f%% }", $3,$2,$3*100/$2; else print ""}')
if [ -n "$RAM_DATA" ]; then
    RAM="$RAM_DATA"
else
    RAM="N/A"
fi

# Ambil OS
OS=""
if [ -f /etc/os-release ]; then
    OS=$(grep -w PRETTY_NAME /etc/os-release 2>/dev/null | head -n1 | sed -e 's/^PRETTY_NAME=//' -e 's/^"//' -e 's/"$//')
fi
[ -z "$OS" ] && OS=$(cat /etc/issue 2>/dev/null | head -n1 | awk '{print $1,$2,$3}')
[ -z "$OS" ] && OS=$(uname -s -r 2>/dev/null)
[ -z "$OS" ] && OS="Linux OS"

# Ambil ISP dengan Cache & Cadangan Multi-Provider (Anti Rate-Limit & Anti Blank)
ISP=""
if [ -s /etc/premdigital/isp.cache ]; then
    ISP=$(cat /etc/premdigital/isp.cache 2>/dev/null | tr -d '\r\n')
fi
if [ -z "$ISP" ] || [[ "$ISP" == *"Rate limit"* ]] || [[ "$ISP" == *"Unknown"* ]] || [[ "$ISP" == *"error"* ]] || [[ "$ISP" == *"429"* ]]; then
    RAW_ISP=$(curl -s -m 2 ipinfo.io/org 2>/dev/null)
    if [ -n "$RAW_ISP" ] && [[ ! "$RAW_ISP" == *"Rate limit"* ]] && [[ ! "$RAW_ISP" == *"error"* ]] && [[ ! "$RAW_ISP" == *"429"* ]]; then
        ISP=$(echo "$RAW_ISP" | sed -E 's/^AS[0-9]+ //')
    fi
    if [ -z "$ISP" ] || [[ "$ISP" == *"Rate limit"* ]]; then
        RAW_ISP2=$(curl -s -m 2 "http://ip-api.com/line/?fields=isp" 2>/dev/null)
        [ -n "$RAW_ISP2" ] && ISP="$RAW_ISP2"
    fi
    if [ -z "$ISP" ] || [[ "$ISP" == *"Rate limit"* ]]; then
        RAW_ISP3=$(curl -s -m 2 "https://ipapi.co/org" 2>/dev/null)
        [ -n "$RAW_ISP3" ] && [[ ! "$RAW_ISP3" == *"error"* ]] && ISP="$RAW_ISP3"
    fi
    if [ -n "$ISP" ] && [[ ! "$ISP" == *"Rate limit"* ]] && [[ ! "$ISP" == *"429"* ]]; then
        echo "$ISP" > /etc/premdigital/isp.cache 2>/dev/null
    fi
fi
[ -z "$ISP" ] && ISP="Internet Provider"

# Ambil Bandwidth (Deteksi Interface Handal)
IFACE=$(ip -4 route ls 2>/dev/null | grep default | grep -Po '(?<=dev )\S+' | head -n1)
[ -z "$IFACE" ] && IFACE=$(ip route get 1.1.1.1 2>/dev/null | grep -Po '(?<=dev )\S+' | head -n1)
[ -z "$IFACE" ] && IFACE=$(ip route 2>/dev/null | grep default | awk '{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}' | head -n1)
[ -z "$IFACE" ] && IFACE=$(ls /sys/class/net 2>/dev/null | grep -vE 'lo|docker|tun|wg|veth' | head -n1)

# Baca Kuota Bulanan VPS dari setting user atau default ram-based
QUOTA_FILE="/etc/premdigital/quota.txt"
if [ -f "$QUOTA_FILE" ]; then
    MAX_QUOTA=$(cat "$QUOTA_FILE" 2>/dev/null | tr -d '
 ')
fi
if [ -z "$MAX_QUOTA" ]; then
    # Auto estimasi kuota standar cloud (1GB RAM ~ 1TB, 2GB ~ 2TB, 4GB ~ 4TB)
    total_ram_mb=$(free -m | awk '/Mem:/ {print $2}')
    if [ "$total_ram_mb" -gt 3500 ]; then
        MAX_QUOTA="4TB"
    elif [ "$total_ram_mb" -gt 1500 ]; then
        MAX_QUOTA="2TB"
    elif [ "$total_ram_mb" -gt 800 ]; then
        MAX_QUOTA="1TB"
    else
        MAX_QUOTA="1TB"
    fi
fi

if [ -n "$IFACE" ] && [ -f "/sys/class/net/$IFACE/statistics/tx_bytes" ]; then
    TX=$(cat "/sys/class/net/$IFACE/statistics/tx_bytes" 2>/dev/null || echo 0)
    RX=$(cat "/sys/class/net/$IFACE/statistics/rx_bytes" 2>/dev/null || echo 0)
    TOTAL_BYTES=$(( TX + RX ))
    BW_FORMAT=$(awk -v b="$TOTAL_BYTES" 'BEGIN {
        split("B KB MB GB TB", v);
        s=1;
        while(b>1024 && s<5){b/=1024; s++}
        printf "%.2f %s", b, v[s]
    }')
    [ -z "$BW_FORMAT" ] && BW_FORMAT="0.00 B"
    BWIDTH="$BW_FORMAT { $MAX_QUOTA }"
else
    BWIDTH="0.00 B { $MAX_QUOTA }"
fi

# Ambil Domain
domain=""
if [ -f /etc/vps-domain.txt ]; then
    domain=$(head -n 1 /etc/vps-domain.txt 2>/dev/null | tr -d '\r\n ')
fi
[ -z "$domain" ] && domain="Belum diset"

domain_cf=""
if [ -f /etc/vps-cloudfront.txt ]; then
    domain_cf=$(head -n 1 /etc/vps-cloudfront.txt 2>/dev/null | tr -d '\r\n ')
fi
[ -z "$domain_cf" ] && domain_cf="Belum diset"

# Cek Status Service
if systemctl is-active --quiet ssh 2>/dev/null || systemctl is-active --quiet sshd 2>/dev/null || systemctl is-active --quiet ws-openssh 2>/dev/null; then 
    ssh_st="${GREEN}ON${NC}"
else 
    ssh_st="${RED}OFF${NC}"
fi

if systemctl is-active --quiet xray 2>/dev/null; then 
    xray_st="${GREEN}ON${NC}"
else 
    xray_st="${RED}OFF${NC}"
fi

if systemctl is-active --quiet udp-custom 2>/dev/null || systemctl is-active --quiet badvpn-7100 2>/dev/null; then 
    udp_st="${GREEN}ON${NC}"
else 
    udp_st="${RED}OFF${NC}"
fi

if [[ "$ssh_st" =~ "OFF" ]] || [[ "$xray_st" =~ "OFF" ]]; then
    sys_health="${YELLOW}WARN${NC}"
else
    sys_health="${GREEN}GOOD${NC}"
fi

echo -e "${BLUE}====================================================${NC}"
echo -e "${GREEN}               PREMDIGITAL TUNNEL V2                ${NC}"
echo -e "${BLUE}====================================================${NC}"
echo -e " IP VPS    : ${CYAN}$MYIP${NC}"
echo -e " OS        : ${CYAN}$OS${NC}"
echo -e " ISP       : ${CYAN}$ISP${NC}"
echo -e " RAM Usage : ${CYAN}$RAM${NC}"
echo -e " Bandwidth : ${CYAN}$BWIDTH${NC}"
echo -e " Domain    : ${CYAN}$domain${NC}"
echo -e " CloudFront: ${CYAN}$domain_cf${NC}"
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
echo -e " ${YELLOW}[7]${NC} Domain & CloudFront Manager"
echo -e " ${YELLOW}[8]${NC} Web Connection Setting"
echo -e " ${YELLOW}[9]${NC} Service Status & Restart"
echo -e " ${YELLOW}[10]${NC} Limit Multi-Login"
echo -e " ${YELLOW}[11]${NC} Load Balancer & Server Migration"
echo -e " ${YELLOW}[12]${NC} Update Script"
echo -e " ${YELLOW}[13]${NC} ❗Uninstall Script❗"
echo -e " ${YELLOW}[0]${NC} Keluar"
echo -e "${BLUE}====================================================${NC}"
read -p " Pilih Menu [0-13] : " menu_num

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
        echo "3. Auto kill & delete { SSH/WS & Xray }"
        read -p "Pilihan [1/2/3]: " del_opt
        if [ "$del_opt" == "1" ]; then
            bash /vps-scripts/del-ssh.sh
        elif [ "$del_opt" == "2" ]; then
            bash /vps-scripts/del-account.sh
        elif [ "$del_opt" == "3" ]; then
            MENU_XP="/usr/local/bin/auto-kill-expired"
            [ ! -f "$MENU_XP" ] && MENU_XP="/vps-scripts/auto-kill-expired.sh"
            [ ! -f "$MENU_XP" ] && MENU_XP="$(pwd)/vps-scripts/auto-kill-expired.sh"
            bash "$MENU_XP"
        else
            menu
        fi
        ;;
    7)
        echo -e "\n${CYAN}====================================================${NC}"
        echo -e "${GREEN}             KELOLA DOMAIN & CLOUDFRONT             ${NC}"
        echo -e "${CYAN}====================================================${NC}"
        echo -e " [1] Ganti Domain Direct / VPS (Saat ini: ${CYAN}${domain}${NC})"
        echo -e " [2] Ganti / Atur Domain CloudFront (Saat ini: ${CYAN}${domain_cf}${NC})"
        echo -e " [0] Kembali ke Menu Utama"
        echo -e "${CYAN}====================================================${NC}"
        read -p " Pilihan [0-2]: " dom_opt
        if [ "$dom_opt" == "1" ]; then
            read -p " Masukkan Domain Direct Baru: " new_domain
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
            fi
        elif [ "$dom_opt" == "2" ]; then
            read -p " Masukkan Domain CloudFront Baru (contoh: dxxx.cloudfront.net): " new_cf
            if [ -n "$new_cf" ]; then
                echo "$new_cf" > /etc/vps-cloudfront.txt
                echo -e "${GREEN}Sukses! Domain CloudFront disimpan: $new_cf${NC}"
            fi
        fi
        echo ""
        echo -e "${YELLOW}====================================================${NC}"
        read -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama..."
        menu
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
            
            # Cek jika konfigurasi lama sudah ada
            CUR_API_KEY=""
            CUR_PROJECT_ID="premdigital-vpn"
            if [ -f /root/node_config.txt ]; then
                source /root/node_config.txt
                CUR_API_KEY="$API_KEY"
                CUR_PROJECT_ID="${PROJECT_ID:-premdigital-vpn}"
            fi

            if [ -z "$CUR_API_KEY" ]; then
                read -p "Masukkan Firebase API Key: " INPUT_KEY
                API_KEY="$INPUT_KEY"
            else
                read -p "Masukkan Firebase API Key [Sudah Tersimpan / Tekan Enter]: " INPUT_KEY
                API_KEY="${INPUT_KEY:-$CUR_API_KEY}"
            fi
            PROJECT_ID="$CUR_PROJECT_ID"
            
            # Buat file konfigurasi
            cat > /root/node_config.txt << EOF_CONFIG
NODE_ID="$NODE_ID"
NODE_NAME="$NODE_NAME"
CITY="$CITY"
COUNTRY_CODE="$COUNTRY_CODE"
PROJECT_ID="$PROJECT_ID"
API_KEY="$API_KEY"
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
PROJECT_ID="${PROJECT_ID:-premdigital-vpn}"
API_KEY="$API_KEY"
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
        MENU_LIMIT="/usr/local/bin/limit-ip-menu"
        [ ! -f "$MENU_LIMIT" ] && MENU_LIMIT="/vps-scripts/limit-ip-menu.sh"
        [ ! -f "$MENU_LIMIT" ] && MENU_LIMIT="$(pwd)/vps-scripts/limit-ip-menu.sh"
        bash "$MENU_LIMIT"
        ;;
    11)
        MENU_LB="/usr/local/bin/load-balancer-menu"
        [ ! -f "$MENU_LB" ] && MENU_LB="/vps-scripts/load-balancer-menu.sh"
        [ ! -f "$MENU_LB" ] && MENU_LB="$(pwd)/vps-scripts/load-balancer-menu.sh"
        bash "$MENU_LB"
        ;;
    12)
        if [ ! -f /vps-scripts/update.sh ]; then
            echo -e "${CYAN}Mengunduh script update...${NC}"
            mkdir -p /vps-scripts
            curl -fsSL https://raw.githubusercontent.com/tomm508/premdigitaltunnel-v2/main/vps-scripts/update.sh -o /vps-scripts/update.sh 2>/dev/null || \
            wget -qO /vps-scripts/update.sh https://raw.githubusercontent.com/tomm508/premdigitaltunnel-v2/main/vps-scripts/update.sh 2>/dev/null
            chmod +x /vps-scripts/update.sh 2>/dev/null
        fi
        if [ -f /vps-scripts/update.sh ]; then
            bash /vps-scripts/update.sh
        else
            echo -e "${RED}[ERROR] File /vps-scripts/update.sh tidak ditemukan dan gagal diunduh.${NC}"
            sleep 2
            menu
        fi
        ;;
    13) 
        if [ -f /vps-scripts/uninstall.sh ]; then bash /vps-scripts/uninstall.sh; fi
        ;;
    0) clear ; exit 0 ;;
    *) 
        echo -e "${RED}Pilihan tidak valid!${NC}" 
        sleep 2
        menu
        ;;
esac
