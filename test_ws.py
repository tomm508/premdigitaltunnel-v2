import urllib.request
url = "https://raw.githubusercontent.com/tomm508/premdigitaltunnel-v2/main/vps-scripts/ws-openssh.py"
data = urllib.request.urlopen(url).read().decode('utf-8')
print("Contains 'import time':", "import time" in data)
