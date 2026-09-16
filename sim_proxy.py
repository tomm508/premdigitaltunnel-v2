import socket, threading, time

# Simulasi SSH Server di port 2222
ssh_ready = threading.Event()
def fake_ssh():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(('127.0.0.1', 2222))
    s.listen(1)
    ssh_ready.set()
    conn, addr = s.accept()
    # SSH sends banner immediately!
    conn.sendall(b"SSH-2.0-OpenSSH_8.9p1 Ubuntu-3ubuntu0.10\r\n")
    data = conn.recv(1024)
    print("SSH received from client:", data)
    conn.close()
    s.close()

t_ssh = threading.Thread(target=fake_ssh)
t_ssh.start()
ssh_ready.wait()

# Sekarang connect dari python ws proxy
target = socket.create_connection(('127.0.0.1', 2222))
# Dalam do_proxy:
# select.select([client, target], [], [client, target], 60)
# Target sudah ada SSH banner siap dibaca:
readable, _, _ = select.select([target], [], [], 2)
print("Readable sockets:", readable)
if target in readable:
    banner = target.recv(1024)
    print("Banner received by proxy:", banner)

target.close()
