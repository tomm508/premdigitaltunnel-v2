import os

path = "/app/applet/install.sh"
with open(path, "r") as f:
    content = f.read()

udpgw_script = """
# ==========================================
# INSTALL BADVPN UDPGW
# ==========================================
echo -e "\\e[33m[INFO] Menginstal BadVPN UDPGW (Port 7100, 7200, 7300)...\\e[0m"
apt-get install -y cmake make gcc git
mkdir -p /root/badvpn
cd /root/badvpn || exit
if [ ! -f /usr/local/bin/badvpn-udpgw ]; then
    git clone https://github.com/ambrop72/badvpn.git /root/badvpn
    mkdir -p build && cd build || exit
    cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1
    make
    cp badvpn-udpgw /usr/local/bin/
    chmod +x /usr/local/bin/badvpn-udpgw
fi

cat > /etc/systemd/system/badvpn-7100.service << 'END_BADVPN'
[Unit]
Description=BadVPN UDPGW Port 7100
After=network.target

[Service]
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:7100 --max-clients 500
User=root
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
END_BADVPN

cat > /etc/systemd/system/badvpn-7200.service << 'END_BADVPN'
[Unit]
Description=BadVPN UDPGW Port 7200
After=network.target

[Service]
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 500
User=root
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
END_BADVPN

cat > /etc/systemd/system/badvpn-7300.service << 'END_BADVPN'
[Unit]
Description=BadVPN UDPGW Port 7300
After=network.target

[Service]
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500
User=root
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
END_BADVPN

systemctl daemon-reload
systemctl enable badvpn-7100 badvpn-7200 badvpn-7300 >/dev/null 2>&1
systemctl restart badvpn-7100 badvpn-7200 badvpn-7300
cd /root || exit

# ==========================================
# INSTALL UDP CUSTOM
# ==========================================
echo -e "\\e[33m[INFO] Menginstal UDP Custom...\\e[0m"
wget -qO /usr/local/bin/udp-custom "https://raw.githubusercontent.com/tomm508/premdigitaltunnel-v2/main/bin/udp-custom" || \\
wget -qO /usr/local/bin/udp-custom "https://raw.githubusercontent.com/Bvpn-net/Xray_Vpn/main/udp-custom"
chmod +x /usr/local/bin/udp-custom
mkdir -p /etc/udp

cat > /etc/udp/config.json << 'END_UDP_CONF'
{
  "listen": ":36712",
  "stream_buffer": 33554432,
  "receive_buffer": 83886080,
  "auth": {
    "mode": "passwords"
  }
}
END_UDP_CONF

cat > /etc/systemd/system/udp-custom.service << 'END_UDP_SVC'
[Unit]
Description=UDP Custom
After=network.target

[Service]
User=root
Type=simple
ExecStart=/usr/local/bin/udp-custom server -exclude 22,109,443,80,8080,8443
WorkingDirectory=/etc/udp/
Restart=always
RestartSec=2

[Install]
WantedBy=default.target
END_UDP_SVC

systemctl daemon-reload
systemctl enable udp-custom >/dev/null 2>&1
systemctl restart udp-custom
"""

if "INSTALL BADVPN UDPGW" not in content:
    content = content.replace("# ==========================================\n# SET SSH BANNER", udpgw_script + "\n# ==========================================\n# SET SSH BANNER")
    with open(path, "w") as f:
        f.write(content)
    print("UDPGW & UDP Custom Script added")
else:
    print("UDPGW already exists")
