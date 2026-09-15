import os

path = "/app/applet/patch_vps.sh"
with open(path, "r") as f:
    content = f.read()

# Fix the badvpn copy path
if "cp badvpn-udpgw /usr/local/bin/" in content:
    content = content.replace("cp badvpn-udpgw /usr/local/bin/", "cp udpgw/badvpn-udpgw /usr/local/bin/")
    
# Fix the git clone issue if folder exists
if "mkdir -p /root/badvpn" in content:
    content = content.replace("mkdir -p /root/badvpn", "rm -rf /root/badvpn\nmkdir -p /root/badvpn")

with open(path, "w") as f:
    f.write(content)

# Update install.sh as well
path_install = "/app/applet/install.sh"
with open(path_install, "r") as f:
    install_content = f.read()

if "cp badvpn-udpgw /usr/local/bin/" in install_content:
    install_content = install_content.replace("cp badvpn-udpgw /usr/local/bin/", "cp udpgw/badvpn-udpgw /usr/local/bin/")
if "mkdir -p /root/badvpn" in install_content:
    install_content = install_content.replace("mkdir -p /root/badvpn", "rm -rf /root/badvpn\nmkdir -p /root/badvpn")

with open(path_install, "w") as f:
    f.write(install_content)

print("Fixed BadVPN path and git clone issue")
