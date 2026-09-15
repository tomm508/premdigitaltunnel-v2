#!/bin/bash
# ==========================================
# INSTALL SCRIPT - PREMDIGITAL TUNNELING
# ==========================================

REPO_URL="https://raw.githubusercontent.com/tomm508/premdigitaltunnel-v2/main"

if [ "${EUID}" -ne 0 ]; then
    echo -e "\e[31mMohon jalankan script ini sebagai root (sudo su)\e[0m"
    exit 1
fi

# ==========================================
# FITUR UPDATE MENU & SCRIPT
# ==========================================
if [ "$1" == "--update-menu" ]; then
    echo -e "\e[33m============================================\e[0m"
    echo -e "\e[32m       UPDATE SCRIPT & MENU DIMULAI         \e[0m"
    echo -e "\e[33m============================================\e[0m"

    mkdir -p /vps-scripts
    cd /vps-scripts || exit

    echo "Mendownload file update terbaru..."
    wget -qO vps-bot.py "${REPO_URL}/vps-scripts/vps-bot.py"
    wget -qO add-vmess.sh "${REPO_URL}/vps-scripts/add-vmess.sh"
    wget -qO add-vless.sh "${REPO_URL}/vps-scripts/add-vless.sh"
    wget -qO add-trojan.sh "${REPO_URL}/vps-scripts/add-trojan.sh"
    wget -qO list-account.sh "${REPO_URL}/vps-scripts/list-account.sh"
    wget -qO del-account.sh "${REPO_URL}/vps-scripts/del-account.sh"
    wget -qO uninstall.sh "${REPO_URL}/vps-scripts/uninstall.sh"

    chmod +x *.sh
    chmod +x *.py

    echo "Menyalin script ke sistem utama..."
    cp vps-bot.py /usr/local/bin/vps-bot
    chmod +x /usr/local/bin/vps-bot

    cp add-vmess.sh /usr/bin/add-vmess
    cp add-vless.sh /usr/bin/add-vless
    cp add-trojan.sh /usr/bin/add-trojan
    cp list-account.sh /usr/bin/list-account
    cp del-account.sh /usr/bin/del-account
    chmod +x /usr/bin/add-* /usr/bin/list-account /usr/bin/del-account

    systemctl restart vps-bot 2>/dev/null

    echo -e "\e[32m============================================\e[0m"
    echo -e "\e[32m       UPDATE MENU & BOT SELESAI!           \e[0m"
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
apt-get install -y wget curl python3 python3-pip

# PENTING: Karena script di-pipe melalui bash (wget | bash), perintah 'read' 
# terkadang bentrok jika menggunakan input standar. 
# Kita ubah pendekatannya dengan membaca langsung dari /dev/tty
echo -n "Masukkan Domain VPS Anda (Contoh: vpn.domain.com) [ENTER utk pakai IP]: "
read domain_input < /dev/tty

if [ -n "$domain_input" ]; then
    echo "$domain_input" > /etc/vps-domain.txt
else
    # Jika dikosongkan (skip), deteksi IP Address VPS sebagai default
    curl -s -m 3 ipv4.icanhazip.com 2>/dev/null > /etc/vps-domain.txt
    if [ ! -s /etc/vps-domain.txt ]; then
        curl -s -m 3 ipinfo.io/ip 2>/dev/null > /etc/vps-domain.txt
    fi
fi

echo -n "Masukkan BOT TOKEN Telegram Anda [ENTER utk skip]: "
read bot_token < /dev/tty
echo -n "Masukkan CHAT ID Admin [ENTER utk skip]: "
read admin_id < /dev/tty

mkdir -p /vps-scripts
cd /vps-scripts || exit

echo -e "\e[33m[1/3] Mengunduh script setup Xray...\e[0m"
wget -qO setup-xray.sh "${REPO_URL}/vps-scripts/setup-xray.sh"
chmod +x setup-xray.sh

echo -e "\e[33m[2/3] Menjalankan setup Xray...\e[0m"
bash setup-xray.sh

echo -e "\e[33m[3/3] Menginstall & Menyiapkan Bot Telegram...\e[0m"
wget -qO vps-bot.py "${REPO_URL}/vps-scripts/vps-bot.py"
wget -qO add-vmess.sh "${REPO_URL}/vps-scripts/add-vmess.sh"
wget -qO add-vless.sh "${REPO_URL}/vps-scripts/add-vless.sh"
wget -qO add-trojan.sh "${REPO_URL}/vps-scripts/add-trojan.sh"
wget -qO list-account.sh "${REPO_URL}/vps-scripts/list-account.sh"
wget -qO del-account.sh "${REPO_URL}/vps-scripts/del-account.sh"
wget -qO uninstall.sh "${REPO_URL}/vps-scripts/uninstall.sh"

chmod +x *.sh
chmod +x *.py

# Replace Token in Bot Script if provided
if [ -n "$bot_token" ] && [ -n "$admin_id" ]; then
    sed -i "s/ISI_TOKEN_BOT_DISINI/$bot_token/g" vps-bot.py
    sed -i "s/ISI_ID_TELEGRAM_OWNER/$admin_id/g" vps-bot.py
fi

# Copy scripts
cp vps-bot.py /usr/local/bin/vps-bot
chmod +x /usr/local/bin/vps-bot
cp add-vmess.sh /usr/bin/add-vmess
cp add-vless.sh /usr/bin/add-vless
cp add-trojan.sh /usr/bin/add-trojan
cp list-account.sh /usr/bin/list-account
cp del-account.sh /usr/bin/del-account
chmod +x /usr/bin/add-* /usr/bin/list-account /usr/bin/del-account

# Install python dependencies for bot
pip3 install requests pyTelegramBotAPI >/dev/null 2>&1

# Create Bot Service
cat > /etc/systemd/system/vps-bot.service << 'SRV'
[Unit]
Description=Telegram Bot VPN PremDigital
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/usr/local/bin
ExecStart=/usr/bin/python3 /usr/local/bin/vps-bot
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
SRV

systemctl daemon-reload
if [ -n "$bot_token" ]; then
    systemctl enable vps-bot
    systemctl start vps-bot
fi

echo -e "\e[32m============================================\e[0m"
echo -e "\e[32m  INSTALASI SELESAI!                        \e[0m"
echo -e "\e[32m============================================\e[0m"
if [ -z "$bot_token" ]; then
    echo -e "\e[33m*Bot Telegram TIDAK dijalankan karena Token kosong.\e[0m"
    echo -e "Anda bisa mengedit /usr/local/bin/vps-bot nanti dan menjalankan 'systemctl restart vps-bot'."
fi
