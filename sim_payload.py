# Mari simulasikan HTTP Custom payload
# Di HTTP Custom, user biasanya pakai payload seperti:
# GET / HTTP/1.1[crlf]Host: domain[crlf]Upgrade: websocket[crlf][crlf]
# ATAU
# GET / HTTP/1.1[crlf]Host: bug.com[crlf]X-Real-Host: domain[crlf]Upgrade: websocket[crlf][crlf]

payload = b"GET / HTTP/1.1\r\nHost: udp-premdigital.web.id\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n"

def findHeader(head, header):
    try:
        head_str = head.decode('utf-8', 'ignore')
        aux = head_str.find(f'{header}: ')
        if aux == -1: return ''
        start = aux + len(header) + 2
        end = head_str.find('\r\n', start)
        return head_str[start:end] if end != -1 else ''
    except: return ''

hostPort = findHeader(payload, 'X-Real-Host') or '127.0.0.1:22'
print("Target hostPort:", hostPort)
