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
apt-get install -y python3
cat > /usr/local/bin/ws-openssh << 'END_WS'
#!/usr/bin/env python3
import socket
import threading
import sys

# Konfigurasi
LISTENING_PORT = 80
TARGET_PORT = 22
TARGET_HOST = "127.0.0.1"

def handle_client(client_socket):
    try:
        # Terima payload HTTP awal (Upgrade request)
        request = client_socket.recv(4096).decode('utf-8', errors='ignore')
        
        # Kirim response 101 Switching Protocols jika diminta, atau abaikan dan langsung forward
        if "HTTP/1.1" in request:
            response = "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n"
            client_socket.sendall(response.encode())

        # Hubungkan ke server SSH lokal
        server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server_socket.connect((TARGET_HOST, TARGET_PORT))

        def forward(source, destination):
            try:
                while True:
                    data = source.recv(4096)
                    if not data:
                        break
                    destination.sendall(data)
            except:
                pass
            finally:
                source.close()
                destination.close()

        threading.Thread(target=forward, args=(client_socket, server_socket)).start()
        threading.Thread(target=forward, args=(server_socket, client_socket)).start()

    except Exception as e:
        client_socket.close()

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind(("0.0.0.0", LISTENING_PORT))
server.listen(100)

print(f"Websocket SSH Listening on port {LISTENING_PORT}")
while True:
    client_sock, addr = server.accept()
    threading.Thread(target=handle_client, args=(client_sock,)).start()
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
