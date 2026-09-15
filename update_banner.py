import os

install_path = "/app/applet/install.sh"
with open(install_path, "r") as f:
    content = f.read()

banner_script = """
# ==========================================
# SET SSH BANNER
# ==========================================
echo -e "\\e[33m[INFO] Menyiapkan Banner SSH...\\e[0m"
cat << 'BANNER_EOF' > /etc/issue.net
<br>
<center>
<font color="#0080ff">━━━━━━</font><font color="#00e5ff">ஐஇ⚙️இஐ</font><font color="#0080ff">━━━━━━</font><br>
<font color="#ffd700"><b>--- ★ PREMDIGITAL ★ ---</b></font><br>
<font color="#ff3333"><b>! TERM OF SERVICE !</b></font><br>
<font color="#00ffff"><b>NO SPAM</b></font><br>
<font color="#00ffff"><b>NO DDOS</b></font><br>
<font color="#00ffff"><b>NO HACKING AND CARDING</b></font><br>
<font color="#ff4444"><b>NO TORRENT!!</b></font><br>
<font color="#ff4444"><b>NO MULTI LOGIN!!</b></font><br>
<font color="#b388ff"><b>Order Premium :</b></font><br>
<font color="#00ffff"><b>https://www.premdigital.web.id</b></font><br>
<font color="#0080ff">━━━━━━</font><font color="#00e5ff">ஐஇ⚙️இஐ</font><font color="#0080ff">━━━━━━</font>
</center>
<br>
BANNER_EOF

# Konfigurasi SSH
if grep -q "Banner /etc/issue.net" /etc/ssh/sshd_config; then
    echo "Banner sudah ada di sshd_config" > /dev/null
else
    echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config
fi
sed -i 's@DropbearBanner=""@DropbearBanner="/etc/issue.net"@g' /etc/default/dropbear 2>/dev/null
sed -i 's@DROPBEAR_BANNER=""@DROPBEAR_BANNER="/etc/issue.net"@g' /etc/default/dropbear 2>/dev/null
systemctl restart ssh sshd dropbear 2>/dev/null

"""

if "# SET SSH BANNER" not in content:
    content = content.replace("echo -e \"\\e[32m============================================\\e[0m\"\necho -e \"\\e[32m  INSTALASI SELESAI!                        \\e[0m\"", banner_script + "echo -e \"\\e[32m============================================\\e[0m\"\necho -e \"\\e[32m  INSTALASI SELESAI!                        \\e[0m\"")
    with open(install_path, "w") as f:
        f.write(content)
    print("Banner script added successfully")
else:
    print("Banner already exists")
