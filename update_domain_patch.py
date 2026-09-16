patch_cmd = """
# Ganti Domain Cepat langsung ke sgdo-premdigital.web.id
if [ -n "$1" ]; then
    TARGET_DOMAIN="$1"
else
    TARGET_DOMAIN="sgdo-premdigital.web.id"
fi

echo "$TARGET_DOMAIN" > /etc/vps-domain.txt
echo -e "\\e[33mMemperbarui Sertifikat SSL untuk $TARGET_DOMAIN...\\e[0m"
mkdir -p /etc/xray
openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -sha256 \\
-subj "/C=ID/ST=DKI Jakarta/L=Jakarta/O=PremDigital/OU=PremDigital/CN=$TARGET_DOMAIN" \\
-out /etc/xray/xray.crt -keyout /etc/xray/xray.key 2>/dev/null
chmod 644 /etc/xray/xray.crt 2>/dev/null
chmod 600 /etc/xray/xray.key 2>/dev/null

systemctl restart stunnel4 2>/dev/null || true
systemctl restart xray 2>/dev/null || true
systemctl restart ws-openssh 2>/dev/null || true
echo -e "\\e[32mDomain dan Sertifikat SSL berhasil diperbarui ke: $TARGET_DOMAIN\\e[0m"
"""

with open("/app/applet/patch_vps.sh", "r") as f:
    content = f.read()

if "TARGET_DOMAIN" not in content:
    content = content.replace("echo -e \"\\e[1;32mSemua Patch Selesai!", patch_cmd + "\necho -e \"\\e[1;32mSemua Patch Selesai!")

with open("/app/applet/patch_vps.sh", "w") as f:
    f.write(content)

print("patch_vps.sh updated with auto-domain setup")
