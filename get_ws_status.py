import urllib.request
url = "https://raw.githubusercontent.com/tomm508/premdigitaltunnel-v2/main/vps-scripts/ws-openssh.py"
try:
    content = urllib.request.urlopen(url).read().decode('utf-8')
    print("Script length:", len(content))
except Exception as e:
    print(e)
