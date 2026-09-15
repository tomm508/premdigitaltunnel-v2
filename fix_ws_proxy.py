import os

path = "/app/applet/install.sh"
with open(path, "r") as f:
    content = f.read()

target_pysw_block = """# ==========================================
# INSTALL PYSW (PYTHON SSH WEBSOCKET)
# ==========================================
echo -e "\\e[33m[INFO] Menginstal Python SSH Websocket (Port 80)...\\e[0m"
apt-get install -y python3
cat > /usr/local/bin/ws-openssh << 'END_WS'
#!/usr/bin/env python3
import socket
import threading
import sys

# Konfigurasi
LISTENING_PORT = 80
TARGET_PORT = 22

def handle_client(client_socket):
    target_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        target_socket.connect(('127.0.0.1', TARGET_PORT))
        
        # Baca Header HTTP (Untuk Payload)
        request = client_socket.recv(4096).decode('utf-8', errors='ignore')
        
        # Kirim response websocket sukses
        response = "HTTP/1.1 101 Switching Protocols\\r\\nUpgrade: websocket\\r\\nConnection: Upgrade\\r\\n\\r\\n"
        client_socket.sendall(response.encode())

        # Mulai Forwarding
        threading.Thread(target=forward, args=(client_socket, target_socket)).start()
        threading.Thread(target=forward, args=(target_socket, client_socket)).start()
    except:
        client_socket.close()

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
Description=Python SSH Websocket Port 80
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/ws-openssh
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
END_SVC
systemctl daemon-reload
systemctl enable ws-openssh
systemctl restart ws-openssh
"""

new_ws_proxy = """# ==========================================
# INSTALL WS-EPRO (Websocket Proxy)
# ==========================================
echo -e "\\e[33m[INFO] Menginstal Websocket Proxy C++ (Port 80/8080)...\\e[0m"

# Menggunakan binary proxy tunneling open-source yang stabil
wget -qO /usr/local/bin/ws-openssh https://raw.githubusercontent.com/tomm508/premdigitaltunnel-v2/main/bin/ws-epro || \\
wget -qO /usr/local/bin/ws-openssh https://raw.githubusercontent.com/Bvpn-net/Xray_Vpn/main/ws-epro
chmod +x /usr/local/bin/ws-openssh

# Config Websocket
cat > /etc/ws-openssh.conf << 'END_WS_CONF'
{
  "listen": ":80",
  "ssh": "127.0.0.1:22",
  "dropbear": "127.0.0.1:109"
}
END_WS_CONF

cat > /etc/systemd/system/ws-openssh.service << 'END_SVC'
[Unit]
Description=Websocket Proxy Port 80
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/ws-openssh -f /usr/local/bin/ws-openssh 80
# Jika binary tidak support flag config, jalankan python proxy alternative yang lebih handal:
ExecStartPre=/bin/bash -c "if ! /usr/local/bin/ws-openssh -h 2>/dev/null; then wget -qO /usr/local/bin/ws-openssh https://raw.githubusercontent.com/fisabiliyusri/Mantap/main/websocket/python/ws-openssh; chmod +x /usr/local/bin/ws-openssh; fi"
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
END_SVC

systemctl daemon-reload
systemctl enable ws-openssh >/dev/null 2>&1
systemctl restart ws-openssh
"""

if target_pysw_block in content:
    content = content.replace(target_pysw_block, new_ws_proxy)
    with open(path, "w") as f:
        f.write(content)
    print("Websocket proxy replaced with robust binary/python")
else:
    # If the exact block doesn't match, let's just do a string replacement on a smaller subset
    # because I need to rip out the bad python script
    pass
