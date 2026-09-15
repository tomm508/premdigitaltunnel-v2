#!/bin/bash
# ==========================================
# INSTALL SCRIPT - PREMDIGITAL TUNNELING (WEB PANEL EDITION)
# ==========================================

REPO_URL="https://raw.githubusercontent.com/tomm508/premdigitaltunnel-v2/main"

if [ "${EUID}" -ne 0 ]; then
    echo -e "\e[31mMohon jalankan script ini sebagai root (sudo su)\e[0m"
    exit 1
fi

# ==========================================
# FITUR UPDATE SCRIPT
# ==========================================
if [ "$1" == "--update-menu" ]; then
    echo -e "\e[33m============================================\e[0m"
    echo -e "\e[32m       UPDATE SCRIPT & MENU DIMULAI         \e[0m"
    echo -e "\e[33m============================================\e[0m"

    mkdir -p /vps-scripts
    cd /vps-scripts || exit

    echo "Mendownload file update terbaru..."
    wget -qO add-ssh.sh "${REPO_URL}/vps-scripts/add-ssh.sh"
    wget -qO del-ssh.sh "${REPO_URL}/vps-scripts/del-ssh.sh"
    wget -qO add-vmess.sh "${REPO_URL}/vps-scripts/add-vmess.sh"
    wget -qO add-vless.sh "${REPO_URL}/vps-scripts/add-vless.sh"
    wget -qO add-trojan.sh "${REPO_URL}/vps-scripts/add-trojan.sh"
    wget -qO list-account.sh "${REPO_URL}/vps-scripts/list-account.sh"
    wget -qO del-account.sh "${REPO_URL}/vps-scripts/del-account.sh"
    wget -qO menu.sh "${REPO_URL}/vps-scripts/menu.sh"
    wget -qO uninstall.sh "${REPO_URL}/vps-scripts/uninstall.sh"
    wget -qO cek-service.sh "${REPO_URL}/vps-scripts/cek-service.sh"

    chmod +x *.sh

    echo "Menyalin script ke sistem utama..."
    cp add-ssh.sh /usr/bin/add-ssh
    cp del-ssh.sh /usr/bin/del-ssh
    cp add-vmess.sh /usr/bin/add-vmess
    cp add-vless.sh /usr/bin/add-vless
    cp add-trojan.sh /usr/bin/add-trojan
    cp list-account.sh /usr/bin/list-account
    cp del-account.sh /usr/bin/del-account
    cp menu.sh /usr/bin/menu
cp cek-service.sh /usr/bin/cek-service
    chmod +x /usr/bin/add-* /usr/bin/del-* /usr/bin/list-account /usr/bin/menu

    echo -e "\e[32m============================================\e[0m"
    echo -e "\e[32m       UPDATE MENU SELESAI!                 \e[0m"
    echo -e "\e[32m============================================\e[0m"
    exit 0
fi

# ==========================================
# INSTALLASI BARU (FULL)
# ==========================================
echo -e "\e[33m============================================\e[0m"
echo -e "\e[32m  MEMULAI INSTALASI PREMDIGITAL TUNNELING   \e[0m"
echo -e "\e[33m============================================\e[0m"

# Install Dependencies
apt-get update -y
apt-get install -y wget curl

echo -n "Masukkan Domain VPS Anda (Contoh: vpn.domain.com) [ENTER utk pakai IP]: "
read domain_input < /dev/tty

if [ -n "$domain_input" ]; then
    echo "$domain_input" > /etc/vps-domain.txt
else
    # Jika dikosongkan (skip), deteksi IP Address VPS sebagai default
    curl -s -m 3 ipv4.icanhazip.com 2>/dev/null > /etc/vps-domain.txt
    if [ ! -s /etc/vps-domain.txt ]; then
        curl -s -m 3 ipinfo.io/ip 2>/dev/null > /etc/vps-domain.txt
    fi
fi

mkdir -p /vps-scripts
cd /vps-scripts || exit

echo -e "\e[33m[1/2] Mengunduh script setup Xray...\e[0m"
wget -qO setup-xray.sh "${REPO_URL}/vps-scripts/setup-xray.sh"
chmod +x setup-xray.sh

echo -e "\e[33m[2/2] Menjalankan setup Xray...\e[0m"
bash setup-xray.sh

echo -e "\e[33m[INFO] Mengunduh script menu CLI...\e[0m"
wget -qO add-ssh.sh "${REPO_URL}/vps-scripts/add-ssh.sh"
wget -qO del-ssh.sh "${REPO_URL}/vps-scripts/del-ssh.sh"
wget -qO add-vmess.sh "${REPO_URL}/vps-scripts/add-vmess.sh"
wget -qO add-vless.sh "${REPO_URL}/vps-scripts/add-vless.sh"
wget -qO add-trojan.sh "${REPO_URL}/vps-scripts/add-trojan.sh"
wget -qO list-account.sh "${REPO_URL}/vps-scripts/list-account.sh"
wget -qO del-account.sh "${REPO_URL}/vps-scripts/del-account.sh"
wget -qO menu.sh "${REPO_URL}/vps-scripts/menu.sh"
wget -qO uninstall.sh "${REPO_URL}/vps-scripts/uninstall.sh"
    wget -qO cek-service.sh "${REPO_URL}/vps-scripts/cek-service.sh"

chmod +x *.sh

# Copy scripts
cp add-ssh.sh /usr/bin/add-ssh
cp del-ssh.sh /usr/bin/del-ssh
cp add-vmess.sh /usr/bin/add-vmess
cp add-vless.sh /usr/bin/add-vless
cp add-trojan.sh /usr/bin/add-trojan
cp list-account.sh /usr/bin/list-account
cp del-account.sh /usr/bin/del-account
cp menu.sh /usr/bin/menu
cp cek-service.sh /usr/bin/cek-service
chmod +x /usr/bin/add-* /usr/bin/del-* /usr/bin/list-account /usr/bin/menu




# ==========================================
# INSTALL STUNNEL5 (TLS WS SSH)
# ==========================================
echo -e "\e[33m[INFO] Menginstal Stunnel (Port 443 / 8443)...\e[0m"
apt-get install -y stunnel4

cat > /etc/stunnel/stunnel.conf << END_STUNNEL
cert = /etc/xray/xray.crt
key = /etc/xray/xray.key
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[ws-stunnel]
accept = 443
connect = 127.0.0.1:80

[dropbear-stunnel]
accept = 8443
connect = 127.0.0.1:109
END_STUNNEL

sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
systemctl restart stunnel4

# ==========================================
# INSTALL PYSW (PYTHON SSH WEBSOCKET)
# ==========================================
echo -e "\e[33m[INFO] Menginstal Python SSH Websocket (Port 80)...\e[0m"
apt-get install -y python3 dropbear
cat > /usr/local/bin/ws-openssh << 'END_WS'
#!/usr/bin/env python3
import socket
import threading
import sys

LISTENING_PORT = 80
TARGET_PORT = 22

def handle_client(client_socket):
    target_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        target_socket.connect(('127.0.0.1', TARGET_PORT))
        
        # Baca Header HTTP (Untuk Payload)
        request = client_socket.recv(8192).decode('utf-8', errors='ignore')
        
        # Respon 101 Switching Protocols yang lebih universal untuk HC/HI
        response = "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: HSmrc0sMlYUkAGmm5OPpG2HaGWk=\r\n\r\n"
        client_socket.sendall(response.encode())

        # Mulai Forwarding Bidirectional
        threading.Thread(target=forward, args=(client_socket, target_socket)).start()
        threading.Thread(target=forward, args=(target_socket, client_socket)).start()
    except Exception as e:
        client_socket.close()

def forward(source, destination):
    try:
        while True:
            data = source.recv(8192)
            if not data:
                break
            destination.sendall(data)
    except:
        pass
    finally:
        source.close()
        destination.close()

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind(('0.0.0.0', LISTENING_PORT))
server.listen(100)

while True:
    client, addr = server.accept()
    threading.Thread(target=handle_client, args=(client,)).start()
END_WS
chmod +x /usr/local/bin/ws-openssh

cat > /etc/systemd/system/ws-openssh.service << 'END_SVC'
[Unit]
Description=Python Websocket SSH
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/ws-openssh
Restart=always

[Install]
WantedBy=multi-user.target
END_SVC

systemctl daemon-reload
systemctl enable ws-openssh >/dev/null 2>&1
systemctl restart ws-openssh


# ==========================================
# INSTALL BADVPN UDPGW
# ==========================================
echo -e "\e[33m[INFO] Menginstal BadVPN UDPGW (Port 7100, 7200, 7300)...\e[0m"
apt-get install -y cmake make gcc git
rm -rf /root/badvpn
mkdir -p /root/badvpn
cd /root/badvpn || exit
if [ ! -f /usr/local/bin/badvpn-udpgw ]; then
    git clone https://github.com/ambrop72/badvpn.git /root/badvpn
    mkdir -p build && cd build || exit
    cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1
    make
    find /root/badvpn -type f -name "badvpn-udpgw" -exec cp {} /usr/local/bin/ \;
    chmod +x /usr/local/bin/badvpn-udpgw
fi

cat > /etc/systemd/system/badvpn-7100.service << 'END_BADVPN'
[Unit]
Description=BadVPN UDPGW Port 7100
After=network.target

[Service]
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:7100 --max-clients 500
User=root
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
END_BADVPN

cat > /etc/systemd/system/badvpn-7200.service << 'END_BADVPN'
[Unit]
Description=BadVPN UDPGW Port 7200
After=network.target

[Service]
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 500
User=root
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
END_BADVPN

cat > /etc/systemd/system/badvpn-7300.service << 'END_BADVPN'
[Unit]
Description=BadVPN UDPGW Port 7300
After=network.target

[Service]
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500
User=root
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
END_BADVPN

systemctl daemon-reload
systemctl enable badvpn-7100 badvpn-7200 badvpn-7300 >/dev/null 2>&1
systemctl restart badvpn-7100 badvpn-7200 badvpn-7300
cd /root || exit

# ==========================================
# INSTALL UDP CUSTOM
# ==========================================
echo -e "\e[33m[INFO] Menginstal UDP Custom...\e[0m"
wget -qO /usr/local/bin/udp-custom "https://raw.githubusercontent.com/tomm508/premdigitaltunnel-v2/main/bin/udp-custom" || \
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
ExecStart=/usr/local/bin/udp-custom server -exclude 22,109,443,80,8080,8443
WorkingDirectory=/etc/udp/
Restart=always
RestartSec=2

[Install]
WantedBy=default.target
END_UDP_SVC

systemctl daemon-reload
systemctl enable udp-custom >/dev/null 2>&1
systemctl restart udp-custom

# ==========================================
# SET SSH BANNER
# ==========================================
echo -e "\e[33m[INFO] Menyiapkan Banner SSH...\e[0m"
cat << 'BANNER_EOF' > /etc/issue.net
<br>
<center>
<font color="#0080ff">━━━━━━</font><font color="#00e5ff">ஐஇ⚙️இஐ</font><font color="#0080ff">━━━━━━</font><br>
<font color="#ffd700"><b>--- ★ PREMDIGITAL ★ ---</b></font><br>
<font color="#ff3333"><b>! TERM OF SERVICE !</b></font><br>
<font color="#00ffff"><b>NO SPAM</b></font><br>
<font color="#00ffff"><b>NO DDOS</b></font><br>
<font color="#00ffff"><b>NO HACKING AND CARDING</b></font><br>
<font color="#ff4444"><b>NO TORRENT!!</b></font><br>
<font color="#ff4444"><b>NO MULTI LOGIN!!</b></font><br>
<font color="#b388ff"><b>Order Premium :</b></font><br>
<font color="#00ffff"><b>https://www.premdigital.web.id</b></font><br>
<font color="#0080ff">━━━━━━</font><font color="#00e5ff">ஐஇ⚙️இஐ</font><font color="#0080ff">━━━━━━</font>
</center>
<br>
BANNER_EOF

# Konfigurasi SSH
if grep -q "Banner /etc/issue.net" /etc/ssh/sshd_config; then
    echo "Banner sudah ada di sshd_config" > /dev/null
else
    echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config
fi
sed -i 's@DropbearBanner=""@DropbearBanner="/etc/issue.net"@g' /etc/default/dropbear 2>/dev/null
sed -i 's@DROPBEAR_BANNER=""@DROPBEAR_BANNER="/etc/issue.net"@g' /etc/default/dropbear 2>/dev/null
systemctl restart ssh sshd dropbear 2>/dev/null

echo -e "\e[32m============================================\e[0m"
echo -e "\e[32m  INSTALASI SELESAI!                        \e[0m"
echo -e "\e[32m============================================\e[0m"
echo -e "Ketik \e[33mmenu\e[0m untuk membuka panel CLI"
