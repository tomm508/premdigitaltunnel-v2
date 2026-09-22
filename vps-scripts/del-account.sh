#!/bin/bash
# ==========================================
# Script Delete Account (Xray VMESS/VLESS/TROJAN)
# ==========================================

CONFIG_XRAY="/etc/xray/config.json"
XRAY_DB="/etc/premdigital/xray-users.db"

clear
echo -e "\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
echo -e "\e[1;31m         HAPUS AKUN XRAY (VPN)            \e[0m"
echo -e "\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
echo -e "\e[1;33mDaftar Akun Xray di Server:\e[0m"

total_xray=0
if [ -f "$XRAY_DB" ] && [ -s "$XRAY_DB" ]; then
    while IFS=" | " read -r u uuid_pass exp proto; do
        if [ -n "$u" ]; then
            echo -e "  - Username: \e[1;32m$u\e[0m | Proto: \e[1;36m$proto\e[0m | Expired: \e[1;31m$exp\e[0m"
            total_xray=$((total_xray + 1))
        fi
    done < "$XRAY_DB"
fi

if [ $total_xray -eq 0 ]; then
    echo -e "  \e[1;31m(Tidak ada akun Xray di database)\e[0m"
fi

echo -e "\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
read -rp "Masukkan Username yang ingin dihapus : " user

if [[ -z "$user" ]]; then
    echo -e "\e[1;31mUsername tidak boleh kosong!\e[0m"
    sleep 2
    menu
    exit 1
fi

found_xray=0

# Backup config xray sebelum diedit
if [ -f "$CONFIG_XRAY" ]; then
    cp -f "$CONFIG_XRAY" "${CONFIG_XRAY}.bak" 2>/dev/null
fi

# Cek & Hapus dari Xray config.json
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

if [[ $found_xray -eq 0 ]]; then
    echo -e "\e[1;31mUsername '${user}' tidak ditemukan di Xray!\e[0m"
else
    echo -e "\e[1;32m✅ Akun '${user}' berhasil dihapus dari server!\e[0m"
fi

echo -e "\e[1;33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
read -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama..."
menu
