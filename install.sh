#!/bin/bash
# ==========================================
# INSTALL SCRIPT - PREMDIGITAL TUNNELING (WEB PANEL EDITION)
# ==========================================

REPO_URL="https://raw.githubusercontent.com/tomm508/premdigitaltunnel-v2/main"

if [ "${EUID}" -ne 0 ]; then
    echo -e "\e[31mMohon jalankan script ini sebagai root (sudo su)\e[0m"
    exit 1
fi

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
    wget -qO add-ssh.sh "${REPO_URL}/vps-scripts/add-ssh.sh"
    wget -qO del-ssh.sh "${REPO_URL}/vps-scripts/del-ssh.sh"
    wget -qO add-vmess.sh "${REPO_URL}/vps-scripts/add-vmess.sh"
    wget -qO add-vless.sh "${REPO_URL}/vps-scripts/add-vless.sh"
    wget -qO add-trojan.sh "${REPO_URL}/vps-scripts/add-trojan.sh"
    wget -qO list-account.sh "${REPO_URL}/vps-scripts/list-account.sh"
    wget -qO del-account.sh "${REPO_URL}/vps-scripts/del-account.sh"
    wget -qO menu.sh "${REPO_URL}/vps-scripts/menu.sh"
    wget -qO uninstall.sh "${REPO_URL}/vps-scripts/uninstall.sh"

    chmod +x *.sh

    echo "Menyalin script ke sistem utama..."
    cp add-ssh.sh /usr/bin/add-ssh
    cp del-ssh.sh /usr/bin/del-ssh
    cp add-vmess.sh /usr/bin/add-vmess
    cp add-vless.sh /usr/bin/add-vless
    cp add-trojan.sh /usr/bin/add-trojan
    cp list-account.sh /usr/bin/list-account
    cp del-account.sh /usr/bin/del-account
    cp menu.sh /usr/bin/menu
    chmod +x /usr/bin/add-* /usr/bin/del-* /usr/bin/list-account /usr/bin/menu

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

mkdir -p /vps-scripts
cd /vps-scripts || exit

echo -e "\e[33m[1/2] Mengunduh script setup Xray...\e[0m"
wget -qO setup-xray.sh "${REPO_URL}/vps-scripts/setup-xray.sh"
chmod +x setup-xray.sh

echo -e "\e[33m[2/2] Menjalankan setup Xray...\e[0m"
bash setup-xray.sh

echo -e "\e[33m[INFO] Mengunduh script menu CLI...\e[0m"
wget -qO add-ssh.sh "${REPO_URL}/vps-scripts/add-ssh.sh"
wget -qO del-ssh.sh "${REPO_URL}/vps-scripts/del-ssh.sh"
wget -qO add-vmess.sh "${REPO_URL}/vps-scripts/add-vmess.sh"
wget -qO add-vless.sh "${REPO_URL}/vps-scripts/add-vless.sh"
wget -qO add-trojan.sh "${REPO_URL}/vps-scripts/add-trojan.sh"
wget -qO list-account.sh "${REPO_URL}/vps-scripts/list-account.sh"
wget -qO del-account.sh "${REPO_URL}/vps-scripts/del-account.sh"
wget -qO menu.sh "${REPO_URL}/vps-scripts/menu.sh"
wget -qO uninstall.sh "${REPO_URL}/vps-scripts/uninstall.sh"

chmod +x *.sh

# Copy scripts
cp add-ssh.sh /usr/bin/add-ssh
cp del-ssh.sh /usr/bin/del-ssh
cp add-vmess.sh /usr/bin/add-vmess
cp add-vless.sh /usr/bin/add-vless
cp add-trojan.sh /usr/bin/add-trojan
cp list-account.sh /usr/bin/list-account
cp del-account.sh /usr/bin/del-account
cp menu.sh /usr/bin/menu
chmod +x /usr/bin/add-* /usr/bin/del-* /usr/bin/list-account /usr/bin/menu

echo -e "\e[32m============================================\e[0m"
echo -e "\e[32m  INSTALASI SELESAI!                        \e[0m"
echo -e "\e[32m============================================\e[0m"
echo -e "Ketik \e[33mmenu\e[0m untuk membuka panel CLI"
