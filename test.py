import urllib.request
print(urllib.request.urlopen("https://raw.githubusercontent.com/tomm508/premdigitaltunnel-v2/main/vps-scripts/ws-openssh.py").read().decode('utf-8')[:100])
