import os

path = "/app/applet/install.sh"
with open(path, "r") as f:
    content = f.read()

stunnel_script = """
# ==========================================
# INSTALL STUNNEL5 (TLS WS SSH)
# ==========================================
echo -e "\\e[33m[INFO] Menginstal Stunnel (Port 443 / 8443)...\\e[0m"
apt-get install -y stunnel4

cat > /etc/stunnel/stunnel.conf << END_STUNNEL
cert = /etc/xray/xray.crt
key = /etc/xray/xray.key
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[ws-stunnel]
accept = 443
connect = 127.0.0.1:80

[dropbear-stunnel]
accept = 8443
connect = 127.0.0.1:109
END_STUNNEL

sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
systemctl restart stunnel4
"""

if "INSTALL STUNNEL5" not in content:
    content = content.replace("# ==========================================\n# INSTALL PYSW", stunnel_script + "\n# ==========================================\n# INSTALL PYSW")
    with open(path, "w") as f:
        f.write(content)
    print("Stunnel Script added")
else:
    print("Stunnel already exists")
