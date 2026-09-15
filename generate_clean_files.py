import os

python_ws_script = r'''#!/usr/bin/python3
import socket, threading, select, sys

LISTENING_ADDR = '0.0.0.0'
LISTENING_PORT = 80
BUFLEN = 8192
TIMEOUT = 60
DEFAULT_HOST = '127.0.0.1:22'
RESPONSE = b'HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n'

class Server(threading.Thread):
    def __init__(self, host, port):
        super().__init__()
        self.running = False
        self.host = host
        self.port = port
        self.threads = []
        self.threadsLock = threading.Lock()

    def run(self):
        self.soc = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.soc.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.soc.settimeout(2)
        try:
            self.soc.bind((self.host, int(self.port)))
        except Exception as e:
            return
        self.soc.listen(100)
        self.running = True
        while self.running:
            try:
                c, addr = self.soc.accept()
                c.setblocking(True)
                conn = ConnectionHandler(c, self, addr)
                conn.start()
                self.addConn(conn)
            except socket.timeout:
                continue
            except Exception:
                break
        self.close()

    def addConn(self, conn):
        with self.threadsLock:
            if self.running: self.threads.append(conn)

    def removeConn(self, conn):
        with self.threadsLock:
            if conn in self.threads: self.threads.remove(conn)

    def close(self):
        self.running = False
        with self.threadsLock:
            threads = list(self.threads)
            for c in threads: c.close()
        self.soc.close()

class ConnectionHandler(threading.Thread):
    def __init__(self, socClient, server, addr):
        super().__init__()
        self.client = socClient
        self.server = server
        self.target = None

    def close(self):
        if self.client:
            try: self.client.shutdown(socket.SHUT_RDWR)
            except: pass
            self.client.close()
        if self.target:
            try: self.target.shutdown(socket.SHUT_RDWR)
            except: pass
            self.target.close()
        self.server.removeConn(self)

    def run(self):
        try:
            client_buffer = self.client.recv(BUFLEN)
            if not client_buffer:
                return
            hostPort = self.findHeader(client_buffer, 'X-Real-Host') or DEFAULT_HOST
            self.connect_target(hostPort)
            self.client.sendall(RESPONSE)
            self.do_proxy()
        except Exception:
            pass
        finally:
            self.close()

    def findHeader(self, head, header):
        try:
            head_str = head.decode('utf-8', 'ignore')
            aux = head_str.find(f'{header}: ')
            if aux == -1: return ''
            start = aux + len(header) + 2
            end = head_str.find('\r\n', start)
            return head_str[start:end] if end != -1 else ''
        except: return ''

    def connect_target(self, host):
        host, port = (host.split(':') + ['22'])[:2]
        self.target = socket.create_connection((host, int(port)))

    def do_proxy(self):
        sockets = [self.client, self.target]
        while True:
            readable, _, exceptional = select.select(sockets, [], sockets, TIMEOUT)
            if exceptional or not readable:
                break
            for sock in readable:
                try:
                    data = sock.recv(BUFLEN)
                    if not data:
                        return
                    if sock is self.client:
                        self.target.sendall(data)
                    else:
                        self.client.sendall(data)
                except Exception:
                    return

def main():
    server = Server(LISTENING_ADDR, LISTENING_PORT)
    server.start()
    try:
        server.join()
    except KeyboardInterrupt:
        server.close()

if __name__ == '__main__':
    main()
'''

# Simpan file python murni ke dalam repo agar bisa di-wget langsung tanpa risiko escape string bash
os.makedirs("/app/applet/vps-scripts", exist_ok=True)
with open("/app/applet/vps-scripts/ws-openssh.py", "w") as f:
    f.write(python_ws_script)

patch_vps_content = """#!/bin/bash
# ==========================================
# SUPER PATCH: FIX WEBSOCKET, DROPBEAR & UDP-CUSTOM
# ==========================================

echo -e "\\e[33m[1/4] Menginstal Dropbear & Menjalankannya...\\e[0m"
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

echo -e "\\e[33m[2/4] Mengunduh UDP-Custom Binary yang valid...\\e[0m"
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

echo -e "\\e[33m[3/4] Mengunduh & Menjalankan Python WS-OpenSSH...\\e[0m"
wget -qO /usr/local/bin/ws-openssh "https://raw.githubusercontent.com/tomm508/premdigitaltunnel-v2/main/vps-scripts/ws-openssh.py"
chmod +x /usr/local/bin/ws-openssh

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

echo -e "\\e[33m[4/4] Memastikan Port Stunnel4 Aktif di 443 & 8443...\\e[0m"
cat > /etc/stunnel/stunnel.conf << 'END_STUNNEL'
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
systemctl restart stunnel4 2>/dev/null

echo -e "\\e[1;32mSemua Patch Selesai! Silakan cek menu nomor 9.\\e[0m"
"""

with open("/app/applet/patch_vps.sh", "w") as f:
    f.write(patch_vps_content)

print("Generated clean ws-openssh.py and patch_vps.sh")
