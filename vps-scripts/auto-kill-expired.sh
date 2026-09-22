#!/bin/bash
# ====================================================
# PremDigital - Auto Kill & Delete Expired Accounts
# (SSH / Dropbear / WS, VMess, VLess, Trojan)
# ====================================================

RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
CYAN='\e[1;36m'
NC='\e[0m'

LOG_FILE="/var/log/premdigital-expired.log"
XRAY_CONFIG="/etc/xray/config.json"
XRAY_DB="/etc/premdigital/xray-users.db"

mkdir -p /var/log
mkdir -p /etc/premdigital

is_cron=0
if [ "$1" == "--cron" ] || [ "$1" == "-q" ]; then
    is_cron=1
fi

TODAY_STR=$(date +"%Y-%m-%d")
TODAY_SEC=$(date -d "$TODAY_STR" +%s 2>/dev/null || date +%s)

if [ $is_cron -eq 0 ]; then
    clear
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}      AUTO KILL & BERSIHKAN AKUN EXPIRED          ${NC}"
    echo -e "${CYAN}      PremDigital Tunneling - Automation System   ${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e " Tanggal Server Hari Ini: ${YELLOW}$(date '+%A, %d %B %Y (%T)')${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "\n${CYAN}[1/2] Memeriksa akun SSH / Dropbear / WebSocket...${NC}"
fi

# ==========================================
# 1. CEK & BERSIHKAN AKUN SSH EXPIRED
# ==========================================
ssh_deleted=0
ssh_users_list=()

while IFS=: read -r username _ uid _ _ _ _; do
    # Hanya periksa user sistem non-root (UID >= 1000 dan bukan nobody)
    if [ "$uid" -ge 1000 ] 2>/dev/null && [ "$username" != "nobody" ] && [ "$username" != "root" ]; then
        exp_raw=$(chage -l "$username" 2>/dev/null | grep "Account expires" | awk -F": " '{print $2}')
        
        if [ -n "$exp_raw" ] && [ "$exp_raw" != "never" ]; then
            user_exp_sec=$(date -d "$exp_raw" +%s 2>/dev/null)
            
            if [ -n "$user_exp_sec" ] && [ "$user_exp_sec" -le "$TODAY_SEC" ]; then
                # User kadaluarsa!
                # 1. Putuskan semua koneksi aktif user tersebut
                pkill -u "$username" 2>/dev/null || true
                killall -u "$username" 2>/dev/null || true
                
                # 2. Hapus user dari sistem Linux
                userdel -f "$username" 2>/dev/null || true
                
                # 3. Hapus data konfigurasi limit/kuota jika ada
                rm -f "/etc/premdigital/multilogin/$username" 2>/dev/null
                rm -f "/etc/premdigital/user_quota/$username" 2>/dev/null
                
                ssh_deleted=$((ssh_deleted + 1))
                ssh_users_list+=("$username (Expired: $exp_raw)")
                
                # Catat ke log
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SSH/WS EXPIRED] User '$username' kadaluarsa pada '$exp_raw' - Berhasil diputus & dihapus." >> "$LOG_FILE"
            fi
        fi
    fi
done < /etc/passwd

if [ $is_cron -eq 0 ]; then
    if [ $ssh_deleted -gt 0 ]; then
        for u in "${ssh_users_list[@]}"; do
            echo -e "  ${RED}✖ [DIHAPUS]${NC} SSH User: ${YELLOW}$u${NC}"
        done
        echo -e "  ${GREEN}✓ Total $ssh_deleted akun SSH expired berhasil dihapus.${NC}"
    else
        echo -e "  ${GREEN}✓ Tidak ada akun SSH yang kadaluarsa.${NC}"
    fi
    echo -e "\n${CYAN}[2/2] Memeriksa akun Xray (VMess / VLess / Trojan)...${NC}"
fi

# ==========================================
# 2. CEK & BERSIHKAN AKUN XRAY EXPIRED
# ==========================================
xray_deleted=0
xray_users_list=()

if [ -f "$XRAY_DB" ] && [ -f "$XRAY_CONFIG" ]; then
    # Backup config xray sebelum dimodifikasi (aturan keamanan)
    cp -f "$XRAY_CONFIG" "${XRAY_CONFIG}.bak" 2>/dev/null

    # Ambil daftar user expired dari database xray
    expired_xray_users=()
    temp_db="/tmp/xray-users-new.db"
    rm -f "$temp_db"

    while IFS=" | " read -r user uuid_pass exp proto; do
        # Format exp adalah YYYY-MM-DD
        if [ -n "$user" ] && [ -n "$exp" ]; then
            user_exp_sec=$(date -d "$exp" +%s 2>/dev/null)
            if [ -n "$user_exp_sec" ] && [ "$user_exp_sec" -le "$TODAY_SEC" ]; then
                expired_xray_users+=("$user:$proto:$exp")
                xray_deleted=$((xray_deleted + 1))
                xray_users_list+=("$user [Protocol: $proto | Expired: $exp]")
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] [XRAY EXPIRED] User '$user' ($proto) kadaluarsa pada '$exp' - Berhasil dihapus." >> "$LOG_FILE"
            else
                # Masih aktif, pertahankan di DB
                echo "$user | $uuid_pass | $exp | $proto" >> "$temp_db"
            fi
        fi
    done < "$XRAY_DB"

    if [ $xray_deleted -gt 0 ]; then
        # Update database xray
        mv -f "$temp_db" "$XRAY_DB"

        # Hapus user expired dari /etc/xray/config.json menggunakan Python
        python3 - <<PY_EOF
import json

config_path = "$XRAY_CONFIG"
expired_list = "$xray_deleted"

with open("$LOG_FILE", "r") as lf:
    lines = lf.readlines()

# Baca user yang baru dihapus hari ini
to_delete = []
EOF_USERS = """
$(for item in "${expired_xray_users[@]}"; do echo "$item"; done)
"""
for line in EOF_USERS.strip().split("\n"):
    if line.strip():
        parts = line.strip().split(":")
        to_delete.append(parts[0])

try:
    with open(config_path, "r") as f:
        data = json.load(f)

    changed = False
    for ib in data.get("inbounds", []):
        settings = ib.get("settings", {})
        if "clients" in settings and isinstance(settings["clients"], list):
            initial_count = len(settings["clients"])
            settings["clients"] = [c for c in settings["clients"] if c.get("email") not in to_delete]
            if len(settings["clients"]) != initial_count:
                changed = True

    if changed:
        with open(config_path, "w") as f:
            json.dump(data, f, indent=2)
except Exception as e:
    pass
PY_EOF

        # Restart service xray agar perubahan diterapkan seketika
        systemctl restart xray > /dev/null 2>&1
        systemctl restart ws-openssh > /dev/null 2>&1 || true
    else
        rm -f "$temp_db"
    fi
fi

if [ $is_cron -eq 0 ]; then
    if [ $xray_deleted -gt 0 ]; then
        for u in "${xray_users_list[@]}"; do
            echo -e "  ${RED}✖ [DIHAPUS]${NC} Xray User: ${YELLOW}$u${NC}"
        done
        echo -e "  ${GREEN}✓ Total $xray_deleted akun Xray expired berhasil dihapus & service di-restart.${NC}"
    else
        echo -e "  ${GREEN}✓ Tidak ada akun Xray yang kadaluarsa.${NC}"
    fi

    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}      HASIL PEMBERSIHAN AKUN EXPIRED              ${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e " Akun SSH Dihapus  : ${YELLOW}$ssh_deleted Akun${NC}"
    echo -e " Akun Xray Dihapus : ${YELLOW}$xray_deleted Akun${NC}"
    echo -e " Log Penyimpanan   : ${CYAN}$LOG_FILE${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama..."
    [ -f /usr/bin/menu ] && menu || exit 0
fi
