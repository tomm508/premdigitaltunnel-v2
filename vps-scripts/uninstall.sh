#!/bin/bash
# ==========================================
# UNINSTALL SCRIPT - PREMDIGITAL TUNNELING
# ==========================================

if [ "${EUID}" -ne 0 ]; then
    echo -e "\e[31mMohon jalankan script ini sebagai root (sudo su)\e[0m"
    exit 1
fi

echo -e "\e[33m============================================\e[0m"
echo -e "\e[31m  MENGHAPUS INSTALASI PREMDIGITAL TUNNELING \e[0m"
echo -e "\e[33m============================================\e[0m"
read -p "Apakah Anda yakin ingin menghapus semua instalasi? (y/n): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Uninstall dibatalkan."
    exit 0
fi

echo -e "\e[33m[1/5] Menghentikan service tunneling...\e[0m"
systemctl stop ws-proxy 2>/dev/null
systemctl disable ws-proxy 2>/dev/null
systemctl stop badvpn-7300 badvpn-7100 badvpn-udpgw 2>/dev/null
systemctl disable badvpn-7300 badvpn-7100 badvpn-udpgw 2>/dev/null
systemctl stop vps-api 2>/dev/null
systemctl disable vps-api 2>/dev/null
systemctl stop vps-bot 2>/dev/null
systemctl disable vps-bot 2>/dev/null

echo -e "\e[33m[2/5] Menghapus file systemd service...\e[0m"
rm -f /etc/systemd/system/ws-proxy.service
rm -f /etc/systemd/system/badvpn-7300.service
rm -f /etc/systemd/system/badvpn-7100.service
rm -f /etc/systemd/system/badvpn-udpgw.service
rm -f /etc/systemd/system/vps-api.service
rm -f /etc/systemd/system/vps-bot.service
systemctl daemon-reload

echo -e "\e[33m[3/5] Menghapus binary dan script...\e[0m"
rm -f /usr/local/bin/ws-proxy
rm -f /usr/bin/badvpn-udpgw
rm -f /usr/local/bin/vps-api
rm -f /usr/local/bin/vps-bot
rm -f /usr/bin/menu
rm -f /usr/bin/menu-service
rm -f /usr/local/bin/auto-delete
rm -f /usr/local/bin/auto-kill-multilogin
rm -f /var/log/multilogin.log

echo -e "\e[33m[4/5] Menghapus konfigurasi dan database...\e[0m"
rm -rf /etc/premdigital/
rm -f /etc/vps-domain.txt
rm -f /etc/stunnel/stunnel.pem
rm -f /etc/stunnel/stunnel.conf

# Hapus cronjob auto-delete & auto-kill
crontab -l 2>/dev/null | grep -v "/usr/local/bin/auto-delete" | grep -v "/usr/local/bin/auto-kill-multilogin" | crontab -

# Hapus alias menu
sed -i '/alias menu=/d' ~/.bashrc 2>/dev/null

echo -e "\e[33m[5/5] Merestart layanan jaringan...\e[0m"
systemctl restart dropbear 2>/dev/null
systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null

echo -e "\e[32m============================================\e[0m"
echo -e "\e[32m  UNINSTALL BERHASIL! SEMUA TELAH BERSIH.   \e[0m"
echo -e "\e[32m============================================\e[0m"
