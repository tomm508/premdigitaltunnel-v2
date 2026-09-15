with open("/app/applet/patch_vps.sh", "r") as f:
    content = f.read()

menu_update = """
echo -e "\\e[33m[5/5] Memperbarui script menu utama...\\e[0m"
wget -qO /usr/local/bin/menu "https://raw.githubusercontent.com/tomm508/premdigitaltunnel-v2/main/vps-scripts/menu.sh"
chmod +x /usr/local/bin/menu
"""

if "[5/5]" not in content:
    content = content.replace('echo -e "\\e[1;32mSemua Patch Selesai!', menu_update + '\necho -e "\\e[1;32mSemua Patch Selesai!')

with open("/app/applet/patch_vps.sh", "w") as f:
    f.write(content)

print("patch_vps.sh updated with menu updater")
