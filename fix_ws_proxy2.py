import os

path = "/app/applet/install.sh"
with open(path, "r") as f:
    content = f.read()

# Fallback string replacement if exact match failed
if "import socket" in content and "def handle_client" in content:
    # We will replace the entire ws-openssh python block with a better one
    start_str = "cat > /usr/local/bin/ws-openssh << 'END_WS'"
    end_str = "END_WS\nchmod +x /usr/local/bin/ws-openssh"
    
    start_idx = content.find(start_str)
    end_idx = content.find(end_str) + len(end_str)
    
    if start_idx != -1 and end_idx != -1:
        better_python_ws = """cat > /usr/local/bin/ws-openssh << 'END_WS'
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
        response = "HTTP/1.1 101 Switching Protocols\\r\\nUpgrade: websocket\\r\\nConnection: Upgrade\\r\\nSec-WebSocket-Accept: HSmrc0sMlYUkAGmm5OPpG2HaGWk=\\r\\n\\r\\n"
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
chmod +x /usr/local/bin/ws-openssh"""
        
        content = content[:start_idx] + better_python_ws + content[end_idx:]
        with open(path, "w") as f:
            f.write(content)
        print("Python WS Proxy logic improved")
