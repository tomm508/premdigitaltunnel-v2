import os

path = "/app/applet/patch_vps.sh"
with open(path, "r") as f:
    content = f.read()

# Make sure we use find to locate the binary dynamically since BadVPN's cmake 
# behavior varies across different Ubuntu versions.
target = "cp udpgw/badvpn-udpgw /usr/local/bin/"
target_old = "cp badvpn-udpgw /usr/local/bin/"

replacement = """find /root/badvpn -type f -name "badvpn-udpgw" -exec cp {} /usr/local/bin/ \\;"""

if target in content:
    content = content.replace(target, replacement)
elif target_old in content:
    content = content.replace(target_old, replacement)

with open(path, "w") as f:
    f.write(content)

path_install = "/app/applet/install.sh"
with open(path_install, "r") as f:
    install_content = f.read()

if target in install_content:
    install_content = install_content.replace(target, replacement)
elif target_old in install_content:
    install_content = install_content.replace(target_old, replacement)

with open(path_install, "w") as f:
    f.write(install_content)

print("Dynamic BadVPN path implemented")
