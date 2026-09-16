const fs = require('fs');
const file = '/app/applet/src/App.tsx';
let content = fs.readFileSync(file, 'utf8');

const target = `cat > /root/node_config.txt << 'EOF_CONFIG'
NODE_ID="sg-premium-01"
NODE_NAME="SG1 DigitalOcean"
CITY="Singapore"
COUNTRY_CODE="SG"
PROJECT_ID="web-premdigitalvpn"
API_KEY="AIzaSyDEtjcfHC9cnqxdTpMv8hnRUMDv4c5EYB4"
EOF_CONFIG

bash <(curl -s https://raw.githubusercontent.com/tomm508/premdigitaltunnel-v2/main/vps-scripts/install_worker.sh)`;

const replacement = `cat > /root/node_config.txt << 'EOF_CONFIG'
NODE_ID="sg-premium-01"
NODE_NAME="SG1 DigitalOcean"
CITY="Singapore"
COUNTRY_CODE="SG"
PROJECT_ID="web-premdigitalvpn"
API_KEY="AIzaSyDEtjcfHC9cnqxdTpMv8hnRUMDv4c5EYB4"
EOF_CONFIG

cat > /root/premdigital_reporter.sh << 'EOF_REPORTER'
#!/bin/bash
source /root/node_config.txt
REST_URL="https://firestore.googleapis.com/v1/projects/\\\\\${PROJECT_ID}/databases/(default)/documents/vps_nodes"
SERVER_IP=\\\\\$(curl -s https://api.ipify.org || hostname -I | awk '{print \\\\\$1}')
[ -z "\\\\\$SERVER_IP" ] && SERVER_IP="127.0.0.1"
RAM_USAGE=\\\\\$(free | grep Mem | awk '{print int(\\\\\$3/\\\\\$2 * 100.0)}')
CPU_LOAD=\\\\\$(uptime | awk -F'load average:' '{ print \\\\\$2 }' | cut -d, -f1 | awk '{print int(\\\\\$1 * 100)}')
ONLINE_USERS=\\\\\$(netstat -tnpa 2>/dev/null | grep 'ESTABLISHED.*sshd' | wc -l)
JSON_PAYLOAD=\\\\\$(cat <<EOF
{
  "fields": {
    "name": { "stringValue": "\\\\\${NODE_NAME}" },
    "ip": { "stringValue": "\\\\\${SERVER_IP}" },
    "city": { "stringValue": "\\\\\${CITY}" },
    "countryCode": { "stringValue": "\\\\\${COUNTRY_CODE}" },
    "status": { "stringValue": "Online" },
    "onlineUsers": { "integerValue": "\\\\\${ONLINE_USERS}" },
    "cpuLoad": { "integerValue": "\\\\\${CPU_LOAD}" },
    "ramUsage": { "integerValue": "\\\\\${RAM_USAGE}" },
    "lastHeartbeat": { "timestampValue": "\\\\\$(date -u +'%Y-%m-%dT%H:%M:%SZ')" }
  }
}
EOF
)
curl -s -X PATCH "\\\\\${REST_URL}/\\\\\${NODE_ID}?key=\\\\\${API_KEY}" -H "Content-Type: application/json" -d "\\\\\${JSON_PAYLOAD}" > /dev/null
EOF_REPORTER

chmod +x /root/premdigital_reporter.sh
(crontab -l 2>/dev/null | grep -v "premdigital_reporter.sh"; echo "*/1 * * * * /root/premdigital_reporter.sh >/dev/null 2>&1") | crontab -`;

if (content.includes(target)) {
  content = content.replace(target, replacement);
  fs.writeFileSync(file, content);
  console.log("Patched App.tsx successfully");
} else {
  console.log("App.tsx Target not found");
}
