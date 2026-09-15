import os

path = "/app/applet/install.sh"
with open(path, "r") as f:
    content = f.read()

ws_script = """
# ==========================================
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
TARGET_HOST = "127.0.0.1"

def handle_client(client_socket):
    try:
        # Terima payload HTTP awal (Upgrade request)
        request = client_socket.recv(4096).decode('utf-8', errors='ignore')
        
        # Kirim response 101 Switching Protocols jika diminta, atau abaikan dan langsung forward
        if "HTTP/1.1" in request:
            response = "HTTP/1.1 101 Switching Protocols\\r\\nUpgrade: websocket\\r\\nConnection: Upgrade\\r\\n\\r\\n"
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

"""

if "# INSTALL PYSW" not in content:
    content = content.replace("# ==========================================\n# SET SSH BANNER", ws_script + "# ==========================================\n# SET SSH BANNER")
    with open(path, "w") as f:
        f.write(content)
    print("Websocket Script added")
else:
    print("Websocket already exists")
