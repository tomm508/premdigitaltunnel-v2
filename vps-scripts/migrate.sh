#!/bin/bash
# ==========================================
# PremDigital - 1-Click Server Migration & Sync Tool
# Memudahkan migrasi akun SSH & Xray antar VPS saat masa sewa habis
# ==========================================

RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
CYAN='\e[1;36m'
NC='\e[0m'

BACKUP_DIR="/root/premdigital_migration"
BACKUP_ARCHIVE="/root/premdigital_backup.tar.gz"

export_data() {
    clear
    echo -e "${BLUE}====================================================${NC}"
    echo -e "${GREEN}       EXPORT DATA SERVER (UNTUK MIGRASI)           ${NC}"
    echo -e "${BLUE}====================================================${NC}"
    echo -e "${YELLOW}Sedang mengemas seluruh data akun & konfigurasi...${NC}"

    rm -rf "$BACKUP_DIR" "$BACKUP_ARCHIVE"
    mkdir -p "$BACKUP_DIR/ssh" "$BACKUP_DIR/xray" "$BACKUP_DIR/premdigital"

    # 1. Backup Akun SSH (Pengguna biasa non-system)
    awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd > "$BACKUP_DIR/ssh/users.list"
    if [ -s "$BACKUP_DIR/ssh/users.list" ]; then
        grep -E "^($(paste -sd '|' "$BACKUP_DIR/ssh/users.list")):" /etc/passwd > "$BACKUP_DIR/ssh/passwd.bak"
        grep -E "^($(paste -sd '|' "$BACKUP_DIR/ssh/users.list")):" /etc/shadow > "$BACKUP_DIR/ssh/shadow.bak"
        grep -E "^($(paste -sd '|' "$BACKUP_DIR/ssh/users.list")):" /etc/group > "$BACKUP_DIR/ssh/group.bak"
    fi

    # 2. Backup Xray (VMess, VLess, Trojan, UUIDs)
    if [ -f /etc/xray/config.json ]; then
        cp /etc/xray/config.json "$BACKUP_DIR/xray/"
    fi
    if [ -f /etc/xray/xray.crt ]; then
        cp /etc/xray/xray.crt /etc/xray/xray.key "$BACKUP_DIR/xray/" 2>/dev/null
    fi

    # 3. Backup Domain & Konfigurasi Limit IP
    [ -f /etc/vps-domain.txt ] && cp /etc/vps-domain.txt "$BACKUP_DIR/"
    [ -d /etc/premdigital ] && cp -r /etc/premdigital/* "$BACKUP_DIR/premdigital/" 2>/dev/null

    # 4. Arsipkan ke file tar.gz
    tar -czf "$BACKUP_ARCHIVE" -C /root premdigital_migration
    rm -rf "$BACKUP_DIR"

    MYIP=$(curl -s -m 3 ipv4.icanhazip.com || echo "IP_SERVER_INI")
    echo -e "${GREEN}[SUKSES] Seluruh akun dan konfigurasi berhasil dikemas!${NC}"
    echo -e "Lokasi File Backup: ${CYAN}$BACKUP_ARCHIVE${NC}"
    echo ""
    echo -e "${YELLOW}================ CARA PINDAH KE VPS BARU ================${NC}"
    echo -e "Di VPS BARU (VPS B), jalankan perintah ini untuk langsung import:"
    echo -e "${CYAN}scp root@$MYIP:$BACKUP_ARCHIVE /root/${NC}"
    echo -e "${CYAN}bash /vps-scripts/migrate.sh --import /root/premdigital_backup.tar.gz${NC}"
    echo -e "${YELLOW}========================================================${NC}"
    echo ""
    read -n 1 -s -r -p "Tekan Enter untuk kembali..."
}

import_data() {
    ARCHIVE_PATH="$1"
    [ -z "$ARCHIVE_PATH" ] && ARCHIVE_PATH="$BACKUP_ARCHIVE"

    if [ ! -f "$ARCHIVE_PATH" ]; then
        echo -e "${RED}[ERROR] File arsip $ARCHIVE_PATH tidak ditemukan!${NC}"
        read -p "Masukkan path file backup .tar.gz: " ARCHIVE_PATH
        if [ ! -f "$ARCHIVE_PATH" ]; then
            echo -e "${RED}File tetap tidak ditemukan. Batal.${NC}"
            sleep 2
            return
        fi
    fi

    clear
    echo -e "${BLUE}====================================================${NC}"
    echo -e "${GREEN}         IMPORT & RESTORE KE VPS BARU               ${NC}"
    echo -e "${BLUE}====================================================${NC}"
    echo -e "${YELLOW}[1/4] Mengekstrak arsip migrasi...${NC}"
    rm -rf "$BACKUP_DIR"
    tar -xzf "$ARCHIVE_PATH" -C /root/

    # 1. Restore Akun SSH
    echo -e "${YELLOW}[2/4] Memulihkan akun-akun SSH/WS...${NC}"
    if [ -f "$BACKUP_DIR/ssh/passwd.bak" ]; then
        while IFS=: read -r username password uid gid gecos home shell; do
            if ! id "$username" &>/dev/null; then
                useradd -m -u "$uid" -g "$gid" -s "$shell" -d "$home" "$username" 2>/dev/null || useradd -m -s "$shell" "$username"
            fi
        done < "$BACKUP_DIR/ssh/passwd.bak"

        # Update shadow passwords
        if [ -f "$BACKUP_DIR/ssh/shadow.bak" ]; then
            while IFS=: read -r username enc_pw rest; do
                if id "$username" &>/dev/null && [ -n "$enc_pw" ]; then
                    usermod -p "$enc_pw" "$username" 2>/dev/null
                fi
            done < "$BACKUP_DIR/ssh/shadow.bak"
        fi
    fi

    # 2. Restore Xray
    echo -e "${YELLOW}[3/4] Memulihkan akun-akun Xray (VMess, VLess, Trojan)...${NC}"
    mkdir -p /etc/xray
    if [ -f "$BACKUP_DIR/xray/config.json" ]; then
        cp "$BACKUP_DIR/xray/config.json" /etc/xray/config.json
    fi
    if [ -f "$BACKUP_DIR/xray/xray.crt" ]; then
        cp "$BACKUP_DIR/xray/xray.crt" /etc/xray/
        cp "$BACKUP_DIR/xray/xray.key" /etc/xray/
    fi

    # 3. Restore Domain & Settings
    if [ -f "$BACKUP_DIR/vps-domain.txt" ]; then
        cp "$BACKUP_DIR/vps-domain.txt" /etc/vps-domain.txt
        DOM=$(cat /etc/vps-domain.txt)
    fi
    if [ -d "$BACKUP_DIR/premdigital" ]; then
        mkdir -p /etc/premdigital
        cp -r "$BACKUP_DIR/premdigital/"* /etc/premdigital/ 2>/dev/null
    fi

    rm -rf "$BACKUP_DIR"

    # 4. Restart Semua Service
    echo -e "${YELLOW}[4/4] Memuat ulang dan merestart service VPN...${NC}"
    systemctl restart ssh sshd xray stunnel4 ws-openssh haproxy 2>/dev/null || true

    NEW_IP=$(curl -s -m 3 ipv4.icanhazip.com || echo "IP_VPS_BARU")
    echo ""
    echo -e "${GREEN}====================================================${NC}"
    echo -e "${GREEN}     MIGRASI KE VPS BARU SELESAI & SUKSES!          ${NC}"
    echo -e "${GREEN}====================================================${NC}"
    echo -e "Semua akun pelanggan SSH, VMess, VLess, dan Trojan sudah aktif di VPS ini."
    echo -e "UUID dan password pelanggan PERSIS SAMA (pelanggan tidak perlu ubah akun)."
    echo ""
    echo -e "${YELLOW}LANGKAH TERAKHIR (PENTING):${NC}"
    echo -e "Arahkan DNS/A-Record domain Anda (${CYAN}${DOM:-domain-anda.com}${NC}) di Cloudflare/Registrar"
    echo -e "ke IP VPS Baru ini: ${GREEN}${NEW_IP}${NC}"
    echo -e "Setelah DNS berubah, semua pelanggan otomatis terhubung ke VPS baru ini!"
    echo -e "${GREEN}====================================================${NC}"
    echo ""
    read -n 1 -s -r -p "Tekan Enter untuk selesai..."
}

case "$1" in
    --export) export_data ;;
    --import) import_data "$2" ;;
    *)
        clear
        echo -e "${BLUE}====================================================${NC}"
        echo -e "${GREEN}       MENU 1-CLICK SERVER MIGRATION PREMDIGITAL     ${NC}"
        echo -e "${BLUE}====================================================${NC}"
        echo -e " ${YELLOW}[1]${NC} Export Data (Jalankan di VPS A yang mau habis masa sewanya)"
        echo -e " ${YELLOW}[2]${NC} Import Data (Jalankan di VPS B yang baru disewa)"
        echo -e " ${YELLOW}[0]${NC} Keluar"
        echo -e "${BLUE}====================================================${NC}"
        read -p " Pilih opsi [0-2]: " opt_mig
        case $opt_mig in
            1) export_data ;;
            2) import_data ;;
            0) exit 0 ;;
        esac
        ;;
esac
