#!/bin/bash
# Script Auto-Reporter (Membaca konfigurasi dari file)
# Dijalankan otomatis oleh Cronjob

# Load variabel
source /root/node_config.txt

# Base URL Firestore (jika belum diset di config, maka di-set di sini)
if [ -z "$REST_URL" ]; then
    REST_URL="https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/vps_nodes"
fi

# Ambil IP Public VPS
SERVER_IP=$(curl -s https://api.ipify.org || hostname -I | awk '{print $1}')
[ -z "$SERVER_IP" ] && SERVER_IP="127.0.0.1"

# Ambil data RAM (Persentase)
RAM_USAGE=$(free | grep Mem | awk '{print int($3/$2 * 100.0)}')
# Ambil data CPU Load (1 menit terakhir, dikali 100)
CPU_LOAD=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d, -f1 | awk '{print int($1 * 100)}')
# Menghitung user SSH aktif (Contoh sederhana)
ONLINE_USERS=$(netstat -tnpa 2>/dev/null | grep 'ESTABLISHED.*sshd' | wc -l)

# Buat JSON Payload format Firestore
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

# Kirim ke Firebase Firestore
# Karena kita menggunakan PATCH, ini akan update jika sudah ada, atau create jika belum ada.
curl -s -X PATCH "${REST_URL}/${NODE_ID}?key=${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "${JSON_PAYLOAD}" > /dev/null
