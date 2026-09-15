import os

path = "/app/applet/vps-scripts/menu.sh"
with open(path, "r") as f:
    content = f.read()

target_status = """# Cek Status Service
if systemctl is-active --quiet ssh; then ssh_st="${GREEN}ON${NC}"; else ssh_st="${RED}OFF${NC}"; fi
if systemctl is-active --quiet xray; then xray_st="${GREEN}ON${NC}"; else xray_st="${RED}OFF${NC}"; fi
web_st="${GREEN}ON${NC}" # Placeholdersys_health="${GREEN}GOOD${NC}"
"""

replacement_status = """# Cek Status Service Real-Time
if systemctl is-active --quiet ssh && systemctl is-active --quiet ws-openssh && systemctl is-active --quiet stunnel4; then 
    ssh_st="${GREEN}ON${NC}"
else 
    ssh_st="${RED}OFF${NC}"
fi

if systemctl is-active --quiet xray; then 
    xray_st="${GREEN}ON${NC}"
else 
    xray_st="${RED}OFF${NC}"
fi

if systemctl is-active --quiet udp-custom && systemctl is-active --quiet badvpn-7100; then 
    udp_st="${GREEN}ON${NC}"
else 
    udp_st="${RED}OFF${NC}"
fi

# Cek Beban CPU (Sys Health)
CPU_LOAD=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d, -f1 | awk '{$1=$1};1')
CPU_INT=$(echo $CPU_LOAD | cut -d. -f1)
if [ "$CPU_INT" -ge 2 ]; then
    sys_health="${RED}HEAVY${NC}"
else
    sys_health="${GREEN}GOOD${NC}"
fi
"""

if target_status in content:
    content = content.replace(target_status, replacement_status)

target_box = """echo -e " ╭──────────────────────────────────────────────────╮"
echo -e " │  SSH/WS: $ssh_st  │  X-RAY: $xray_st  │  WEB: $web_st  │  $sys_health   │"
echo -e " ╰──────────────────────────────────────────────────╯"
"""

replacement_box = """echo -e " ╭──────────────────────────────────────────────────╮"
echo -e " │  SSH/WS: $ssh_st  │  X-RAY: $xray_st  │  UDP: $udp_st  │  $sys_health   │"
echo -e " ╰──────────────────────────────────────────────────╯"
"""

if target_box in content:
    content = content.replace(target_box, replacement_box)

# Buat file terpisah untuk cek semua service
with open("/app/applet/vps-scripts/cek-service.sh", "w") as cek:
    cek.write("""#!/bin/bash
clear
echo -e "\\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\e[0m"
echo -e "\\e[1;33m          STATUS SEMUA LAYANAN            \\e[0m"
echo -e "\\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\e[0m"

services=("ssh" "dropbear" "stunnel4" "ws-openssh" "xray" "udp-custom" "badvpn-7100" "badvpn-7200" "badvpn-7300" "cron")

for svc in "${services[@]}"; do
    if systemctl is-active --quiet $svc; then
        echo -e " 🔹 $svc \\t: \\e[1;32m[ RUNNING ]\\e[0m"
    else
        echo -e " 🔹 $svc \\t: \\e[1;31m[ STOPPED / ERROR ]\\e[0m"
    fi
done
echo -e "\\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\e[0m"
echo ""
echo -e "\\e[33m[1]\\e[0m Restart Semua Layanan (Fix Error)"
echo -e "\\e[33m[0]\\e[0m Kembali ke Menu Utama"
echo -e "\\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\e[0m"
read -p " Pilih [0-1]: " opt_svc
if [ "$opt_svc" == "1" ]; then
    echo -e "\\e[33mMerestart layanan...\\e[0m"
    for svc in "${services[@]}"; do
        systemctl restart $svc 2>/dev/null
    done
    echo -e "\\e[1;32mRestart Selesai!\\e[0m"
    sleep 2
fi
menu
""")

# Edit Menu Nomor 9 menjadi All Service
target_menu_9 = """    9) 
        echo "Merestart layanan..."
        systemctl restart xray ssh dropbear 2>/dev/null
        echo -e "${GREEN}Restart Selesai!${NC}"
        echo ""
        echo -e "${YELLOW}====================================================${NC}"
        read -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama..."
        menu
        ;;"""

replacement_menu_9 = """    9) 
        bash /vps-scripts/cek-service.sh
        ;;"""

target_menu_text_9 = """echo -e " ${YELLOW}[9]${NC} Restart All Service\""""
replacement_menu_text_9 = """echo -e " ${YELLOW}[9]${NC} Service Status & Restart\""""

if target_menu_9 in content:
    content = content.replace(target_menu_9, replacement_menu_9)
if target_menu_text_9 in content:
    content = content.replace(target_menu_text_9, replacement_menu_text_9)

with open(path, "w") as f:
    f.write(content)

# Update install.sh agar mengunduh/copy cek-service.sh
install_path = "/app/applet/install.sh"
with open(install_path, "r") as f:
    install_content = f.read()

if "cek-service.sh" not in install_content:
    install_content = install_content.replace('wget -qO uninstall.sh "${REPO_URL}/vps-scripts/uninstall.sh"', 'wget -qO uninstall.sh "${REPO_URL}/vps-scripts/uninstall.sh"\n    wget -qO cek-service.sh "${REPO_URL}/vps-scripts/cek-service.sh"')
    install_content = install_content.replace('cp menu.sh /usr/bin/menu', 'cp menu.sh /usr/bin/menu\ncp cek-service.sh /usr/bin/cek-service')
    with open(install_path, "w") as f:
        f.write(install_content)

print("Menu status fixed and cek-service added")
