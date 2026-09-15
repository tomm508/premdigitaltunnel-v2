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

mkdir -p /vps-scripts
cd /vps-scripts || exit

echo -e "\e[33m[1/2] Mengunduh script setup Xray...\e[0m"
wget -qO setup-xray.sh "${REPO_URL}/vps-scripts/setup-xray.sh"
chmod +x setup-xray.sh

echo -e "\e[33m[2/2] Menjalankan setup Xray...\e[0m"
bash setup-xray.sh

echo -e "\e[32m============================================\e[0m"
echo -e "\e[32m  INSTALASI SELESAI!                        \e[0m"
echo -e "\e[32m============================================\e[0m"
