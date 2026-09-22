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

# Bersihkan karakter spasi atau newline
user=$(echo "$user" | tr -d '\r\n' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

if [[ -z "$user" ]]; then
    echo -e "\e[1;31mUsername tidak boleh kosong!\e[0m"
    sleep 2
    menu
    exit 1
fi

# Backup config xray sebelum diedit
if [ -f "$CONFIG_XRAY" ]; then
    cp -f "$CONFIG_XRAY" "${CONFIG_XRAY}.bak" 2>/dev/null
fi

# Eksekusi penghapusan menggunakan Python secara menyeluruh (config.json & xray-users.db)
result=$(python3 - <<PY_EOF
import json
import os

target = "$user".strip()
deleted_any = False

# 1. Hapus dari /etc/xray/config.json
cfg_path = "$CONFIG_XRAY"
if os.path.exists(cfg_path):
    try:
        with open(cfg_path, "r") as f:
            data = json.load(f)
        changed = False
        for ib in data.get("inbounds", []):
            settings = ib.get("settings", {})
            if "clients" in settings and isinstance(settings["clients"], list):
                orig_len = len(settings["clients"])
                settings["clients"] = [
                    c for c in settings["clients"]
                    if c.get("email", "").strip().lower() != target.lower() and
                       c.get("password", "").strip().lower() != target.lower()
                ]
                if len(settings["clients"]) != orig_len:
                    changed = True
                    deleted_any = True
        if changed:
            with open(cfg_path, "w") as f:
                json.dump(data, f, indent=2)
    except Exception as e:
        pass

# 2. Hapus dari /etc/premdigital/xray-users.db
db_path = "$XRAY_DB"
if os.path.exists(db_path):
    try:
        with open(db_path, "r") as f:
            lines = f.readlines()
        new_lines = []
        for line in lines:
            parts = [p.strip() for p in line.split("|")]
            if parts and parts[0].lower() == target.lower():
                deleted_any = True
            else:
                new_lines.append(line)
        with open(db_path, "w") as f:
            f.writelines(new_lines)
    except Exception as e:
        pass

if deleted_any:
    print("SUCCESS")
else:
    print("NOT_FOUND")
PY_EOF
)

if [[ "$result" == *"SUCCESS"* ]]; then
    systemctl restart xray > /dev/null 2>&1
    echo -e "\e[1;32m✅ Akun '${user}' berhasil dihapus dari server!\e[0m"
else
    echo -e "\e[1;31mUsername '${user}' tidak ditemukan di sistem Xray maupun database!\e[0m"
fi

echo -e "\e[1;33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
read -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama..."
menu
