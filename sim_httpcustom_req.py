import socket, threading, time

# Simulasi ws-openssh server
def run_ws():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(('127.0.0.1', 8888))
    s.listen(1)
    c, addr = s.accept()
    req = c.recv(4096)
    print("WS received request:\n", req.decode('utf-8', 'ignore'))
    c.sendall(b"HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n")
    c.close()
    s.close()

t = threading.Thread(target=run_ws)
t.start()

time.sleep(0.2)
c = socket.create_connection(('127.0.0.1', 8888))
# Misal HTTP Custom mengirim:
c.sendall(b"CONNECT 127.0.0.1:22 HTTP/1.1\r\nHost: udp-premdigital.web.id\r\nProxy-Connection: Keep-Alive\r\n\r\n")
resp = c.recv(4096)
print("Client got resp:\n", resp.decode('utf-8', 'ignore'))
c.close()
