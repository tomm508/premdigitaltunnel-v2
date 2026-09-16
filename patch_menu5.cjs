const fs = require('fs');

const file = '/app/applet/vps-scripts/menu.sh';
let content = fs.readFileSync(file, 'utf8');

const target = '        if [ "$web_opt" == "1" ]; then\n' +
'            echo -e "${CYAN}Memulai instalasi Daemon Telemetri...${NC}"\n' +
'            bash <(curl -s https://raw.githubusercontent.com/tomm508/premdigitaltunnel-v2/main/vps-scripts/install_worker.sh)\n' +
'            echo ""\n' +
'            read -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama..."\n' +
'            menu\n' +
'        elif [ "$web_opt" == "0" ]; then';

const replacement = '        if [ "$web_opt" == "1" ]; then\n' +
'            echo -e "${CYAN}Memulai instalasi Daemon Telemetri...${NC}"\n' +
'            echo ""\n' +
'            echo "Silakan masukkan detail VPS untuk Web Panel:"\n' +
'            read -p "Masukkan ID Server (contoh: sg-premium-01): " NODE_ID\n' +
'            read -p "Masukkan Nama Server (contoh: SG1 DigitalOcean): " NODE_NAME\n' +
'            read -p "Masukkan Kota (contoh: Singapore): " CITY\n' +
'            read -p "Masukkan Kode Negara (contoh: SG): " COUNTRY_CODE\n' +
'            \n' +
'            # Buat file konfigurasi\n' +
'            cat > /root/node_config.txt << EOF_CONFIG\n' +
'NODE_ID="$NODE_ID"\n' +
'NODE_NAME="$NODE_NAME"\n' +
'CITY="$CITY"\n' +
'COUNTRY_CODE="$COUNTRY_CODE"\n' +
'PROJECT_ID="web-premdigitalvpn"\n' +
'API_KEY="AIzaSyDEtjcfHC9cnqxdTpMv8hnRUMDv4c5EYB4"\n' +
'EOF_CONFIG\n' +
'\n' +
'            echo -e "${GREEN}Konfigurasi berhasil disimpan di /root/node_config.txt${NC}"\n' +
'            echo -e "${CYAN}Membuat script Auto-Reporter...${NC}"\n' +
'            \n' +
'            # Buat script reporter langsung di VPS tanpa curl ke github\n' +
'            cat > /root/premdigital_reporter.sh << \'EOF_REPORTER\'\n' +
'#!/bin/bash\n' +
'source /root/node_config.txt\n' +
'if [ -z "$REST_URL" ]; then\n' +
'    REST_URL="https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/vps_nodes"\n' +
'fi\n' +
'SERVER_IP=$(curl -s https://api.ipify.org || hostname -I | awk \'{print $1}\')\n' +
'[ -z "$SERVER_IP" ] && SERVER_IP="127.0.0.1"\n' +
'RAM_USAGE=$(free | grep Mem | awk \'{print int($3/$2 * 100.0)}\')\n' +
'CPU_LOAD=$(uptime | awk -F\'load average:\' \'{ print $2 }\' | cut -d, -f1 | awk \'{print int($1 * 100)}\')\n' +
'ONLINE_USERS=$(netstat -tnpa 2>/dev/null | grep \'ESTABLISHED.*sshd\' | wc -l)\n' +
'JSON_PAYLOAD=$(cat <<EOF\n' +
'{\n' +
'  "fields": {\n' +
'    "name": { "stringValue": "${NODE_NAME}" },\n' +
'    "ip": { "stringValue": "${SERVER_IP}" },\n' +
'    "city": { "stringValue": "${CITY}" },\n' +
'    "countryCode": { "stringValue": "${COUNTRY_CODE}" },\n' +
'    "status": { "stringValue": "Online" },\n' +
'    "onlineUsers": { "integerValue": "${ONLINE_USERS}" },\n' +
'    "cpuLoad": { "integerValue": "${CPU_LOAD}" },\n' +
'    "ramUsage": { "integerValue": "${RAM_USAGE}" },\n' +
'    "lastHeartbeat": { "timestampValue": "$(date -u +\'%Y-%m-%dT%H:%M:%SZ\')" }\n' +
'  }\n' +
'}\n' +
'EOF\n' +
')\n' +
'curl -s -X PATCH "${REST_URL}/${NODE_ID}?key=${API_KEY}" -H "Content-Type: application/json" -d "${JSON_PAYLOAD}" > /dev/null\n' +
'EOF_REPORTER\n' +
'\n' +
'            chmod +x /root/premdigital_reporter.sh\n' +
'            (crontab -l 2>/dev/null | grep -v "premdigital_reporter.sh"; echo "*/1 * * * * /root/premdigital_reporter.sh >/dev/null 2>&1") | crontab -\n' +
'            \n' +
'            echo -e "${GREEN}[SUCCESS] Instalasi selesai! VPS ini sekarang akan otomatis melapor ke Web Admin setiap 1 menit.${NC}"\n' +
'            echo ""\n' +
'            read -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama..."\n' +
'            menu\n' +
'        elif [ "$web_opt" == "0" ]; then';

if (content.includes(target)) {
  content = content.replace(target, replacement);
  fs.writeFileSync(file, content);
  console.log("Patched successfully");
} else {
  console.log("Target not found");
}
