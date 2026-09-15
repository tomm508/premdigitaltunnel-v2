import os

path = "/app/applet/vps-scripts/setup-xray.sh"
with open(path, "r") as f:
    content = f.read()

# Ubah port Xray dari 4430/443 agar tidak bentrok dengan Stunnel
target_port = """    {
      "port": 4430,"""
replacement_port = """    {
      "port": 443,"""

if target_port in content:
    content = content.replace(target_port, replacement_port)
    with open(path, "w") as f:
        f.write(content)
    print("Xray port changed to 443")
