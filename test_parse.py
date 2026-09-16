raw = b'''CONNECT 127.0.0.1:22 HTTP/1.1\r
Host: 159.65.10.28:80\r
X-Real-Host: 127.0.0.1:22\r
Upgrade: websocket\r
Connection: Upgrade\r
\r
'''

def findHeader(head, header):
    try:
        head_str = head.decode('utf-8', 'ignore')
        aux = head_str.find(f'{header}: ')
        if aux == -1: return ''
        start = aux + len(header) + 2
        end = head_str.find('\r\n', start)
        return head_str[start:end] if end != -1 else ''
    except: return ''

print("Found header:", findHeader(raw, 'X-Real-Host'))
