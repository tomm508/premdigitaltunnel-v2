#!/usr/bin/python3
import socket, threading, select, sys, os, json, time

LISTENING_ADDR = '0.0.0.0'
LISTENING_PORTS = [80, 8080, 8880]
BUFLEN = 65536
TIMEOUT = 86400
DEFAULT_HOST = '127.0.0.1:109'
RESPONSE = b'HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n'
RESPONSE_200 = b'HTTP/1.1 200 Connection Established\r\nConnection: keep-alive\r\n\r\n'

def set_keepalive(sock):
    try:
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_KEEPALIVE, 1)
        sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 262144)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_SNDBUF, 262144)
        if hasattr(socket, 'TCP_KEEPIDLE'):
            sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_KEEPIDLE, 20)
        if hasattr(socket, 'TCP_KEEPINTVL'):
            sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_KEEPINTVL, 5)
        if hasattr(socket, 'TCP_KEEPCNT'):
            sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_KEEPCNT, 5)
    except Exception:
        pass

SESSION_LOCK = threading.Lock()
ACTIVE_WS_SESSIONS = {}
SESSION_FILE = '/run/premdigital_ws_sessions.json'

def save_ws_sessions():
    try:
        os.makedirs(os.path.dirname(SESSION_FILE), exist_ok=True)
        temp_file = SESSION_FILE + '.tmp'
        with open(temp_file, 'w') as f:
            json.dump(ACTIVE_WS_SESSIONS, f)
        os.replace(temp_file, SESSION_FILE)
    except Exception:
        pass

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
        self.addr = addr
        self.real_ip = addr[0] if addr else '127.0.0.1'
        self.target = None
        self.local_port = None
        self.ssh_started = False

    def close(self):
        if self.local_port:
            try:
                with SESSION_LOCK:
                    if self.local_port in ACTIVE_WS_SESSIONS:
                        del ACTIVE_WS_SESSIONS[self.local_port]
                        save_ws_sessions()
            except Exception:
                pass
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
            forwarded = self.findHeader(client_buffer, 'X-Forwarded-For') or self.findHeader(client_buffer, 'X-Real-IP')
            if forwarded:
                self.real_ip = forwarded.split(',')[0].strip()
            if client_buffer.startswith(b'SSH-'):
                # Raw SSH stream (e.g. from Xray direct fallback or stunnel)
                self.connect_target('127.0.0.1:109')
                set_keepalive(self.target)
                self.ssh_started = True
                self.target.sendall(client_buffer)
                self.do_proxy()
                return

            head_str = client_buffer.decode('utf-8', 'ignore')
            first_line = head_str.split('\r\n')[0] if '\r\n' in head_str else ''
            parts = first_line.split(' ')
            path = parts[1] if len(parts) > 1 else '/'

            # Unified Xray Non-TLS WebSocket routing on Port 80/8080/8880
            if '/vmess' in path:
                self.target = socket.create_connection(('127.0.0.1', 10001), timeout=5)
                set_keepalive(self.target)
                self.ssh_started = True
                self.target.sendall(client_buffer)
                self.do_proxy()
                return
            elif '/vless' in path:
                self.target = socket.create_connection(('127.0.0.1', 10002), timeout=5)
                set_keepalive(self.target)
                self.ssh_started = True
                self.target.sendall(client_buffer)
                self.do_proxy()
                return
            elif '/trojan' in path:
                self.target = socket.create_connection(('127.0.0.1', 10003), timeout=5)
                set_keepalive(self.target)
                self.ssh_started = True
                self.target.sendall(client_buffer)
                self.do_proxy()
                return

            # Default: SSH WebSocket (Enhanced / Standard WS / CONNECT)
            hostPort = self.findHeader(client_buffer, 'X-Real-Host') or DEFAULT_HOST
            self.connect_target(hostPort)
            set_keepalive(self.target)
            if client_buffer.startswith(b'CONNECT '):
                self.client.sendall(RESPONSE_200)
            else:
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
        parts = host.split(':')
        h = parts[0]
        p = int(parts[1]) if len(parts) > 1 and parts[1].isdigit() else 109
        # Coba konek ke Dropbear (109) dulu, fallback ke OpenSSH (22)
        try:
            self.target = socket.create_connection((h, p), timeout=5)
        except Exception:
            self.target = socket.create_connection(('127.0.0.1', 109 if p != 109 else 22), timeout=5)
        try:
            self.local_port = str(self.target.getsockname()[1])
            with SESSION_LOCK:
                ACTIVE_WS_SESSIONS[self.local_port] = {
                    "client_ip": self.real_ip,
                    "target_port": str(p),
                    "time": time.time()
                }
                save_ws_sessions()
        except Exception:
            pass

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
                        if not self.ssh_started:
                            if b'SSH-' in data:
                                self.ssh_started = True
                                ssh_idx = data.find(b'SSH-')
                                self.target.sendall(data[ssh_idx:])
                            elif data.startswith(b'HTTP/') or b'\r\nHTTP/' in data or data.startswith(b'PATCH ') or data.startswith(b'HEAD ') or data.startswith(b'GET '):
                                # Filter dummy responses dari payload Enhanced ([split]HTTP/ 200)
                                pass
                            else:
                                self.ssh_started = True
                                self.target.sendall(data)
                        else:
                            self.target.sendall(data)
                    else:
                        self.client.sendall(data)
                except Exception:
                    return

def main():
    servers = []
    for port in LISTENING_PORTS:
        try:
            s = Server(LISTENING_ADDR, port)
            s.start()
            servers.append(s)
        except Exception as e:
            pass
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        for s in servers:
            s.close()

if __name__ == '__main__':
    main()
