#!/bin/bash
# ==========================================
# Script Delete Account (SSH/VMESS/VLESS/TROJAN)
# ==========================================

CONFIG_XRAY="/etc/xray/config.json"
XRAY_DB="/etc/premdigital/xray-users.db"

clear
echo -e "\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
echo -e "\e[1;31m             HAPUS AKUN VPN               \e[0m"
echo -e "\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"

read -rp "Masukkan Username yang ingin dihapus : " user
if [[ -z "$user" ]]; then
    echo -e "\e[1;31mUsername tidak boleh kosong!\e[0m"
    exit 1
fi

found_ssh=0
found_xray=0

# Cek & Hapus dari SSH (Sistem Linux)
if id "$user" &>/dev/null; then
    userdel -f "$user" 2>/dev/null
    rm -f "/etc/premdigital/multilogin/$user" 2>/dev/null
    rm -f "/etc/premdigital/user_quota/$user" 2>/dev/null
    found_ssh=1
fi

# Cek & Hapus dari Xray
if grep -q "\"email\": \"${user}\"" "$CONFIG_XRAY" 2>/dev/null; then
    python3 - <<PY_EOF
import json
try:
    with open("$CONFIG_XRAY", "r") as f:
        data = json.load(f)
    for ib in data.get("inbounds", []):
        if "clients" in ib.get("settings", {}):
            ib["settings"]["clients"] = [c for c in ib["settings"]["clients"] if c.get("email") != "$user"]
    with open("$CONFIG_XRAY", "w") as f:
        json.dump(data, f, indent=2)
except Exception as e:
    pass
PY_EOF
    
    # Hapus dari Xray DB log
    if [ -f "$XRAY_DB" ]; then
        sed -i "/^${user} |/d" "$XRAY_DB" 2>/dev/null
    fi
    
    systemctl restart xray > /dev/null 2>&1
    found_xray=1
fi

if [[ $found_ssh -eq 0 && $found_xray -eq 0 ]]; then
    echo -e "\e[1;31mUsername '${user}' tidak ditemukan di server!\e[0m"
else
    echo -e "\e[1;32m✅ Akun '${user}' berhasil dihapus dari server!\e[0m"
fi
-e 

echo -e "[33m====================================================[0m"
read -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama..."
menu

