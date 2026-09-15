import os

with open("/app/applet/install.sh", "r") as f:
    content = f.read()

# Make sure dropbear is installed in install.sh
if "apt-get install -y dropbear" not in content:
    content = content.replace("apt-get install -y python3", "apt-get install -y python3 dropbear")

# Replace udp-custom URL in install.sh
old_url = "https://raw.githubusercontent.com/Bvpn-net/Xray_Vpn/main/udp-custom"
new_url = "https://raw.githubusercontent.com/noobconner21/UDP-Custom-Script/main/udp-custom-linux-amd64"
content = content.replace(old_url, new_url)

with open("/app/applet/install.sh", "w") as f:
    f.write(content)

print("install.sh synced")
