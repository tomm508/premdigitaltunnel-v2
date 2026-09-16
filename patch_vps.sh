#!/bin/bash
# ==========================================
# SUPER PATCH: FIX WEBSOCKET, DROPBEAR & UDP-CUSTOM
# ==========================================

echo -e "\e[33m[1/4] Menginstal Dropbear & Menjalankannya...\e[0m"
apt-get update -y
apt-get install -y dropbear
cat > /etc/default/dropbear << 'END_DROPBEAR'
NO_START=0
DROPBEAR_PORT=109
DROPBEAR_EXTRA_ARGS="-p 143"
DROPBEAR_BANNER="/etc/issue.net"
DROPBEAR_RECEIVE_WINDOW=65536
END_DROPBEAR
systemctl restart dropbear 2>/dev/null
systemctl enable dropbear 2>/dev/null

echo -e "\e[33m[2/4] Mengunduh UDP-Custom Binary yang valid...\e[0m"
systemctl stop udp-custom 2>/dev/null
wget -qO /usr/local/bin/udp-custom "https://raw.githubusercontent.com/noobconner21/UDP-Custom-Script/main/udp-custom-linux-amd64"
chmod +x /usr/local/bin/udp-custom
mkdir -p /etc/udp

cat > /etc/udp/config.json << 'END_UDP_CONF'
{
  "listen": ":36712",
  "stream_buffer": 33554432,
  "receive_buffer": 83886080,
  "auth": {
    "mode": "passwords"
  }
}
END_UDP_CONF

cat > /etc/systemd/system/udp-custom.service << 'END_UDP_SVC'
[Unit]
Description=UDP Custom
After=network.target

[Service]
User=root
Type=simple
ExecStart=/usr/local/bin/udp-custom server -exclude 22,109,143,443,80,8080,8443
WorkingDirectory=/etc/udp/
Restart=always
RestartSec=2

[Install]
WantedBy=default.target
END_UDP_SVC

systemctl daemon-reload
systemctl enable udp-custom >/dev/null 2>&1
systemctl restart udp-custom

echo -e "\e[33m[3/4] Mengunduh & Menjalankan Python WS-OpenSSH...\e[0m"
wget -qO /usr/local/bin/ws-openssh "https://raw.githubusercontent.com/tomm508/premdigitaltunnel-v2/main/vps-scripts/ws-openssh.py"
chmod +x /usr/local/bin/ws-openssh
sed -i "s/LISTENING_PORT = 80/LISTENING_PORT = 10080/g" /usr/local/bin/ws-openssh

cat > /etc/systemd/system/ws-openssh.service << 'END_WS_SVC'
[Unit]
Description=Python SSH Websocket Port 80
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 /usr/local/bin/ws-openssh
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
END_WS_SVC

systemctl daemon-reload
systemctl enable ws-openssh >/dev/null 2>&1
systemctl restart ws-openssh

echo -e "\e[33m[4/4] Memastikan Port Stunnel4 Aktif di 445 & 447...\e[0m"
cat > /etc/stunnel/stunnel.conf << 'END_STUNNEL'
cert = /etc/xray/xray.crt
key = /etc/xray/xray.key
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[ws-stunnel]
accept = 443
connect = 127.0.0.1:10080

[dropbear-stunnel]
accept = 8443
connect = 127.0.0.1:109
END_STUNNEL
systemctl restart stunnel4 2>/dev/null


echo -e "\e[33m[5/5] Memperbarui script menu utama...\e[0m"
wget -qO /usr/local/bin/menu "https://raw.githubusercontent.com/tomm508/premdigitaltunnel-v2/main/vps-scripts/menu.sh"
chmod +x /usr/local/bin/menu


# Ganti Domain Cepat langsung ke sgdo-premdigital.web.id
if [ -n "$1" ]; then
    TARGET_DOMAIN="$1"
else
    TARGET_DOMAIN="sgdo-premdigital.web.id"
fi

echo "$TARGET_DOMAIN" > /etc/vps-domain.txt
echo -e "\e[33mMemperbarui Sertifikat SSL untuk $TARGET_DOMAIN...\e[0m"
mkdir -p /etc/xray
openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -sha256 \
-subj "/C=ID/ST=DKI Jakarta/L=Jakarta/O=PremDigital/OU=PremDigital/CN=$TARGET_DOMAIN" \
-out /etc/xray/xray.crt -keyout /etc/xray/xray.key 2>/dev/null
chmod 644 /etc/xray/xray.crt 2>/dev/null
chmod 600 /etc/xray/xray.key 2>/dev/null

systemctl restart stunnel4 2>/dev/null || true
systemctl restart xray 2>/dev/null || true
systemctl restart ws-openssh 2>/dev/null || true
echo -e "\e[32mDomain dan Sertifikat SSL berhasil diperbarui ke: $TARGET_DOMAIN\e[0m"

echo -e "\e[1;32mSemua Patch Selesai! Silakan cek menu nomor 9.\e[0m"
