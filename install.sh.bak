#!/bin/bash
# ==========================================
# INSTALL SCRIPT - PREMDIGITAL TUNNELING (WEB PANEL EDITION)
# ==========================================

REPO_URL="https://raw.githubusercontent.com/tomm508/premdigitaltunnel-v2/main"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_SCRIPTS="${SCRIPT_DIR}/vps-scripts"

WGET_AUTH=""
if [ -n "$GITHUB_TOKEN" ]; then
    WGET_AUTH="--header=Authorization: token $GITHUB_TOKEN"
fi

if [ "${EUID}" -ne 0 ]; then
    echo -e "\e[31mMohon jalankan script ini sebagai root (sudo su)\e[0m"
    exit 1
fi

# Helper download / copy function
fetch_script() {
    local name="$1"
    local dest="$2"
    if [ -f "${LOCAL_SCRIPTS}/${name}" ]; then
        cp -f "${LOCAL_SCRIPTS}/${name}" "$dest"
        chmod +x "$dest" 2>/dev/null || true
        return 0
    fi

    local tmp_file="/tmp/${name}.tmp"
    rm -f "$tmp_file"

    if [ -n "$GITHUB_TOKEN" ]; then
        curl -sSL -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github.v3.raw" "${REPO_URL}/vps-scripts/${name}" -o "$tmp_file" 2>/dev/null
    else
        curl -sSL "${REPO_URL}/vps-scripts/${name}" -o "$tmp_file" 2>/dev/null || wget -qO "$tmp_file" "${REPO_URL}/vps-scripts/${name}" 2>/dev/null
    fi

    if [ -s "$tmp_file" ] && ! grep -q "404: Not Found" "$tmp_file"; then
        cp -f "$tmp_file" "$dest"
        chmod +x "$dest" 2>/dev/null || true
    else
        echo -e "\e[31m[PERINGATAN] Gagal mengunduh $name dari repo!\e[0m"
    fi
    rm -f "$tmp_file"
}

# ==========================================
# FITUR UPDATE SCRIPT
# ==========================================
if [ "$1" == "--update-menu" ]; then
    echo -e "\e[33m============================================\e[0m"
    echo -e "\e[32m       UPDATE SCRIPT & MENU DIMULAI         \e[0m"
    echo -e "\e[33m============================================\e[0m"

    mkdir -p /vps-scripts
    cd /vps-scripts || exit

    echo "Mendownload file update terbaru..."
    fetch_script "add-ssh.sh" "add-ssh.sh"
    fetch_script "del-ssh.sh" "del-ssh.sh"
    fetch_script "add-vmess.sh" "add-vmess.sh"
    fetch_script "add-vless.sh" "add-vless.sh"
    fetch_script "add-trojan.sh" "add-trojan.sh"
    fetch_script "list-account.sh" "list-account.sh"
    fetch_script "del-account.sh" "del-account.sh"
    fetch_script "menu.sh" "menu.sh"
    fetch_script "uninstall.sh" "uninstall.sh"
    fetch_script "cek-service.sh" "cek-service.sh"
    fetch_script "limit-ip.py" "limit-ip.py"
    fetch_script "limit-ip-menu.sh" "limit-ip-menu.sh"
    fetch_script "limit-ip.sh" "limit-ip.sh"
    fetch_script "setup-limit-ip.sh" "setup-limit-ip.sh"
    fetch_script "load-balancer-menu.sh" "load-balancer-menu.sh"
    fetch_script "setup-haproxy-lb.sh" "setup-haproxy-lb.sh"
    fetch_script "migrate.sh" "migrate.sh"
    fetch_script "auto-kill-expired.sh" "auto-kill-expired.sh"
    fetch_script "optimize-speed.sh" "optimize-speed.sh"
    fetch_script "update.sh" "update.sh"
    fetch_script "premdigital_creator.py" "premdigital_creator.py"
    fetch_script "ws-openssh.py" "ws-openssh.py"

    chmod +x *.sh *.py

    echo "Menyalin script ke sistem utama..."
    mkdir -p /vps-scripts
    cp -f *.sh *.py /vps-scripts/ 2>/dev/null || true
    chmod +x /vps-scripts/*.sh /vps-scripts/*.py 2>/dev/null || true
    [ -f premdigital_creator.py ] && cp -f premdigital_creator.py /vps-scripts/premdigital_creator.py
    [ -f update.sh ] && cp -f update.sh /usr/local/bin/update-script && chmod +x /usr/local/bin/update-script
    cp add-ssh.sh /usr/bin/add-ssh
    cp del-ssh.sh /usr/bin/del-ssh
    cp add-vmess.sh /usr/bin/add-vmess
    cp add-vless.sh /usr/bin/add-vless
    cp add-trojan.sh /usr/bin/add-trojan
    cp list-account.sh /usr/bin/list-account
    cp del-account.sh /usr/bin/del-account
    cp menu.sh /usr/bin/menu
    cp cek-service.sh /usr/bin/cek-service
    cp uninstall.sh /usr/bin/uninstall
    cp limit-ip.sh /usr/bin/limit-ip
    cp limit-ip.sh /usr/local/bin/limit-ip
    cp limit-ip-menu.sh /usr/local/bin/limit-ip-menu
    cp limit-ip.py /usr/local/bin/limit-ip.py
    cp load-balancer-menu.sh /usr/local/bin/load-balancer-menu
    cp migrate.sh /usr/local/bin/migrate
    cp auto-kill-expired.sh /usr/local/bin/auto-kill-expired
    cp auto-kill-expired.sh /usr/bin/auto-kill-expired
    ln -sf /usr/local/bin/auto-kill-expired /usr/bin/xp
    cp ws-openssh.py /usr/local/bin/ws-openssh
    systemctl restart ws-openssh 2>/dev/null || true

    echo "Mengaktifkan konfigurasi Limit IP 2 Login & AutoKill..."
    bash setup-limit-ip.sh

    echo "Mengoptimalkan Kernel BBR & Socket Buffer (Anti-DC)..."
    bash optimize-speed.sh

    # Setup Cron Auto Kill Expired Accounts (Tiap Jam 00:00 & tiap jam)
    cat > /etc/cron.d/auto-kill-expired << 'CRON_EOF'
0 0 * * * root /usr/local/bin/auto-kill-expired --cron >> /var/log/premdigital-expired.log 2>&1
CRON_EOF
    chmod 644 /etc/cron.d/auto-kill-expired
    systemctl restart cron 2>/dev/null || systemctl restart crond 2>/dev/null || true

    chmod +x /usr/bin/add-* /usr/bin/del-* /usr/bin/list-account /usr/bin/menu /usr/bin/cek-service /usr/bin/uninstall /usr/bin/limit-ip /usr/local/bin/limit-ip* /usr/local/bin/load-balancer-menu /usr/local/bin/migrate /usr/local/bin/auto-kill-expired /usr/bin/xp

    echo -e "\e[32m============================================\e[0m"
    echo -e "\e[32m       UPDATE MENU SELESAI!                 \e[0m"
    echo -e "\e[32m============================================\e[0m"
    exit 0
fi

# ==========================================
# INSTALLASI BARU (FULL)
# ==========================================
echo -e "\e[33m============================================\e[0m"
echo -e "\e[32m  MEMULAI INSTALASI PREMDIGITAL TUNNELING   \e[0m"
echo -e "\e[33m============================================\e[0m"

# Install Dependencies
apt-get update -y
apt-get install -y wget curl

echo -n "Masukkan Domain VPS Anda (Contoh: vpn.domain.com) [ENTER utk pakai IP]: "
if [ -e /dev/tty ] && [ -r /dev/tty ]; then
    read domain_input < /dev/tty 2>/dev/null || domain_input=""
elif [ -t 0 ]; then
    read domain_input 2>/dev/null || domain_input=""
else
    domain_input=""
fi

if [ -n "$domain_input" ]; then
    echo "$domain_input" > /etc/vps-domain.txt
else
    # Jika dikosongkan (skip), deteksi IP Address VPS sebagai default
    curl -s -m 3 ipv4.icanhazip.com 2>/dev/null > /etc/vps-domain.txt
    if [ ! -s /etc/vps-domain.txt ]; then
        curl -s -m 3 ipinfo.io/ip 2>/dev/null > /etc/vps-domain.txt
    fi
fi

mkdir -p /vps-scripts
cd /vps-scripts || exit

echo -e "\e[33m[1/2] Mengunduh script setup Xray...\e[0m"
fetch_script "setup-xray.sh" "setup-xray.sh"
chmod +x setup-xray.sh

echo -e "\e[33m[2/2] Menjalankan setup Xray...\e[0m"
bash setup-xray.sh

echo -e "\e[33m[INFO] Mengunduh script menu CLI & Limit IP...\e[0m"
fetch_script "add-ssh.sh" "add-ssh.sh"
fetch_script "del-ssh.sh" "del-ssh.sh"
fetch_script "add-vmess.sh" "add-vmess.sh"
fetch_script "add-vless.sh" "add-vless.sh"
fetch_script "add-trojan.sh" "add-trojan.sh"
fetch_script "list-account.sh" "list-account.sh"
fetch_script "del-account.sh" "del-account.sh"
fetch_script "menu.sh" "menu.sh"
fetch_script "uninstall.sh" "uninstall.sh"
fetch_script "cek-service.sh" "cek-service.sh"
fetch_script "limit-ip.py" "limit-ip.py"
fetch_script "limit-ip-menu.sh" "limit-ip-menu.sh"
fetch_script "limit-ip.sh" "limit-ip.sh"
fetch_script "setup-limit-ip.sh" "setup-limit-ip.sh"
fetch_script "load-balancer-menu.sh" "load-balancer-menu.sh"
fetch_script "setup-haproxy-lb.sh" "setup-haproxy-lb.sh"
fetch_script "migrate.sh" "migrate.sh"
fetch_script "auto-kill-expired.sh" "auto-kill-expired.sh"
fetch_script "optimize-speed.sh" "optimize-speed.sh"
fetch_script "update.sh" "update.sh"
fetch_script "premdigital_creator.py" "premdigital_creator.py"
fetch_script "ws-openssh.py" "ws-openssh.py"

chmod +x *.sh *.py

# Copy scripts
mkdir -p /vps-scripts
cp -f *.sh *.py /vps-scripts/ 2>/dev/null || true
chmod +x /vps-scripts/*.sh /vps-scripts/*.py 2>/dev/null || true
[ -f premdigital_creator.py ] && cp -f premdigital_creator.py /vps-scripts/premdigital_creator.py
[ -f update.sh ] && cp -f update.sh /usr/local/bin/update-script && chmod +x /usr/local/bin/update-script
cp add-ssh.sh /usr/bin/add-ssh
cp del-ssh.sh /usr/bin/del-ssh
cp add-vmess.sh /usr/bin/add-vmess
cp add-vless.sh /usr/bin/add-vless
cp add-trojan.sh /usr/bin/add-trojan
cp list-account.sh /usr/bin/list-account
cp del-account.sh /usr/bin/del-account
cp menu.sh /usr/bin/menu
cp cek-service.sh /usr/bin/cek-service
cp uninstall.sh /usr/bin/uninstall
cp limit-ip.sh /usr/bin/limit-ip
cp limit-ip.sh /usr/local/bin/limit-ip
cp limit-ip-menu.sh /usr/local/bin/limit-ip-menu
cp limit-ip.py /usr/local/bin/limit-ip.py
cp load-balancer-menu.sh /usr/local/bin/load-balancer-menu
cp migrate.sh /usr/local/bin/migrate
cp auto-kill-expired.sh /usr/local/bin/auto-kill-expired
cp auto-kill-expired.sh /usr/bin/auto-kill-expired
ln -sf /usr/local/bin/auto-kill-expired /usr/bin/xp
chmod +x /usr/bin/add-* /usr/bin/del-* /usr/bin/list-account /usr/bin/menu /usr/bin/cek-service /usr/bin/uninstall /usr/bin/limit-ip /usr/local/bin/limit-ip* /usr/local/bin/load-balancer-menu /usr/local/bin/migrate /usr/local/bin/auto-kill-expired /usr/bin/xp

echo "Mengaktifkan konfigurasi Limit IP 2 Login & AutoKill..."
bash setup-limit-ip.sh

echo "Mengaktifkan Kernel Turbo BBR & TCP Buffer Optimizer..."
bash optimize-speed.sh

# ==========================================
# INSTALL DROPBEAR (PORT 109 FOR TUNNELING)
# ==========================================
echo -e "\e[33m[INFO] Menginstal & Konfigurasi Dropbear (Port 109)...\e[0m"
apt-get install -y dropbear
cat > /etc/default/dropbear << 'END_DROPBEAR'
NO_START=0
DROPBEAR_PORT=109
DROPBEAR_EXTRA_ARGS="-p 127.0.0.1:109 -W 65536 -K 30 -I 60"
DROPBEAR_BANNER="/etc/issue.net"
DROPBEAR_RECEIVE_WINDOW=65536
END_DROPBEAR
systemctl restart dropbear 2>/dev/null || true

# ==========================================
# INSTALL STUNNEL5 (TLS WS SSH)
# ==========================================
echo -e "\e[33m[INFO] Menginstal Stunnel (Port 443 / 8443)...\e[0m"
apt-get install -y stunnel4

cat > /etc/stunnel/stunnel.conf << END_STUNNEL
cert = /etc/xray/xray.crt
key = /etc/xray/xray.key
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1
socket = l:SO_RCVBUF=262144
socket = r:SO_SNDBUF=262144

[dropbear-stunnel-8443]
accept = 8443
connect = 127.0.0.1:109
END_STUNNEL

sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
systemctl restart stunnel4

# ==========================================
# INSTALL PYSW (PYTHON SSH WEBSOCKET)
# ==========================================
echo -e "\e[33m[INFO] Menginstal Python SSH Websocket (Port 80, 8080, 8880)...\e[0m"
apt-get install -y python3
fetch_script "ws-openssh.py" "/usr/local/bin/ws-openssh"
chmod +x /usr/local/bin/ws-openssh

cat > /etc/systemd/system/ws-openssh.service << 'END_WS_SVC'
[Unit]
Description=Python SSH Websocket Multi-Port 80, 8080, 8880
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 /usr/local/bin/ws-openssh
Restart=always
RestartSec=3
LimitNOFILE=1000000
LimitNPROC=10000

[Install]
WantedBy=multi-user.target
END_WS_SVC

systemctl daemon-reload
systemctl enable ws-openssh >/dev/null 2>&1
systemctl restart ws-openssh


# ==========================================
# INSTALL BADVPN UDPGW
# ==========================================
echo -e "\e[33m[INFO] Menginstal BadVPN UDPGW (Port 7100, 7200, 7300)...\e[0m"
apt-get install -y cmake make gcc git
rm -rf /root/badvpn
mkdir -p /root/badvpn
cd /root/badvpn || exit
if [ ! -f /usr/local/bin/badvpn-udpgw ]; then
    git clone https://github.com/ambrop72/badvpn.git /root/badvpn
    mkdir -p build && cd build || exit
    cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1
    make
    find /root/badvpn -type f -name "badvpn-udpgw" -exec cp {} /usr/local/bin/ \;
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
echo -e "\e[33m[INFO] Menginstal UDP Custom...\e[0m"
wget -qO /usr/local/bin/udp-custom "https://raw.githubusercontent.com/tomm508/premdigitaltunnel-v2/main/bin/udp-custom" || \
wget -qO /usr/local/bin/udp-custom "https://raw.githubusercontent.com/noobconner21/UDP-Custom-Script/main/udp-custom-linux-amd64"
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

# ==========================================
# SET SSH BANNER
# ==========================================
echo -e "\e[33m[INFO] Menyiapkan Banner SSH...\e[0m"
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

# Fix Dropbear shell issue untuk user /bin/false
if ! grep -q "/bin/false" /etc/shells; then
    echo "/bin/false" >> /etc/shells
fi

systemctl restart ssh sshd dropbear 2>/dev/null

echo -e "\e[32m============================================\e[0m"
echo -e "\e[32m  INSTALASI SELESAI!                        \e[0m"
echo -e "\e[32m============================================\e[0m"
echo -e "Ketik \e[33mmenu\e[0m untuk membuka panel CLI"
