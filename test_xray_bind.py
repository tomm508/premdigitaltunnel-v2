with open("/app/applet/vps-scripts/setup-xray.sh") as f:
    txt = f.read()

import re
ports = re.findall(r'"port":\s*(\d+)', txt)
listens = re.findall(r'"listen":\s*"([^"]+)"', txt)
print("Xray ports:", ports)
print("Xray listens:", listens)
