const fs = require('fs');

const file = '/app/applet/vps-scripts/menu.sh';
let content = fs.readFileSync(file, 'utf8');

const target = `        if [ "$web_opt" == "1" ]; then
            echo -e "\\${CYAN}Memulai instalasi Daemon Telemetri...\\${NC}"
            bash <(curl -s https://raw.githubusercontent.com/tomm508/premdigitaltunnel-v2/main/vps-scripts/install_worker.sh)
            echo ""
            read -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama..."
            menu
        elif [ "$web_opt" == "0" ]; then`;

const replacement = `        if [ "$web_opt" == "1" ]; then
            echo -e "\\${CYAN}Memulai instalasi Daemon Telemetri...\\${NC}"
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

            echo -e "\\${GREEN}Konfigurasi berhasil disimpan di /root/node_config.txt\\${NC}"
            echo -e "\\${CYAN}Membuat script Auto-Reporter...\\${NC}"
            
            # Buat script reporter langsung di VPS tanpa curl ke github
            cat > /root/premdigital_reporter.sh << 'EOF_REPORTER'
#!/bin/bash
source /root/node_config.txt
if [ -z "\\$REST_URL" ]; then
    REST_URL="https://firestore.googleapis.com/v1/projects/\\${PROJECT_ID}/databases/(default)/documents/vps_nodes"
fi
SERVER_IP=\\$(curl -s https://api.ipify.org || hostname -I | awk '{print \\$1}')
[ -z "\\$SERVER_IP" ] && SERVER_IP="127.0.0.1"
RAM_USAGE=\\$(free | grep Mem | awk '{print int(\\$3/\\$2 * 100.0)}')
CPU_LOAD=\\$(uptime | awk -F'load average:' '{ print \\$2 }' | cut -d, -f1 | awk '{print int(\\$1 * 100)}')
ONLINE_USERS=\\$(netstat -tnpa 2>/dev/null | grep 'ESTABLISHED.*sshd' | wc -l)
JSON_PAYLOAD=\\$(cat <<EOF
{
  "fields": {
    "name": { "stringValue": "\\${NODE_NAME}" },
    "ip": { "stringValue": "\\${SERVER_IP}" },
    "city": { "stringValue": "\\${CITY}" },
    "countryCode": { "stringValue": "\\${COUNTRY_CODE}" },
    "status": { "stringValue": "Online" },
    "onlineUsers": { "integerValue": "\\${ONLINE_USERS}" },
    "cpuLoad": { "integerValue": "\\${CPU_LOAD}" },
    "ramUsage": { "integerValue": "\\${RAM_USAGE}" },
    "lastHeartbeat": { "timestampValue": "\\$(date -u +'%Y-%m-%dT%H:%M:%SZ')" }
  }
}
