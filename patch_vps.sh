#!/bin/bash
# Script ini dibuat agar klien bisa menimpa file di VPS tanpa perlu REBUILD.

echo "Menerapkan Patch Websocket, UDP Custom, dan BadVPN..."

# 1. Update File Websocket Python
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
        
        request = client_socket.recv(8192).decode('utf-8', errors='ignore')
        
        response = "HTTP/1.1 101 Switching Protocols\\r\\nUpgrade: websocket\\r\\nConnection: Upgrade\\r\\nSec-WebSocket-Accept: HSmrc0sMlYUkAGmm5OPpG2HaGWk=\\r\\n\\r\\n"
        client_socket.sendall(response.encode())

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
systemctl restart ws-openssh

# 2. Instalasi BadVPN & UDP Custom On-The-Fly
apt-get update
apt-get install -y cmake make gcc git

# BadVPN
rm -rf /root/badvpn
mkdir -p /root/badvpn
cd /root/badvpn || exit
if [ ! -f /usr/local/bin/badvpn-udpgw ]; then
    git clone https://github.com/ambrop72/badvpn.git /root/badvpn
    mkdir -p build && cd build || exit
    cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1
    make
    cp udpgw/badvpn-udpgw /usr/local/bin/
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

# UDP Custom
wget -qO /usr/local/bin/udp-custom "https://raw.githubusercontent.com/Bvpn-net/Xray_Vpn/main/udp-custom"
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

echo "Selesai! Silakan cek kembali koneksi SSH & HTTP Custom Anda."
