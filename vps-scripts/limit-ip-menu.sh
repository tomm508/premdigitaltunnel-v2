#!/bin/bash
# ==========================================
# PremDigital - Menu Manajemen Max Login IP (AutoKill)
# ==========================================

RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
CYAN='\e[1;36m'
NC='\e[0m'

PY_ENGINE="/usr/local/bin/limit-ip.py"
[ ! -f "$PY_ENGINE" ] && PY_ENGINE="/vps-scripts/limit-ip.py"
[ ! -f "$PY_ENGINE" ] && PY_ENGINE="$(pwd)/vps-scripts/limit-ip.py"

CONF_PATH="/etc/premdigital/limit-ip.conf"
max_ip=2
autokill=1
if [ -f "$CONF_PATH" ]; then
    max_ip=$(grep "^MAX_IP=" "$CONF_PATH" 2>/dev/null | cut -d'=' -f2)
    autokill=$(grep "^AUTOKILL=" "$CONF_PATH" 2>/dev/null | cut -d'=' -f2)
fi
[ -z "$max_ip" ] && max_ip=2
[ -z "$autokill" ] && autokill=1

if [ "$autokill" == "1" ]; then
    st_kill="${GREEN}AKTIF (ON)${NC}"
else
    st_kill="${RED}NON-AKTIF (OFF)${NC}"
fi

clear
echo -e "${BLUE}====================================================${NC}"
echo -e "${GREEN}        PENGATURAN MAX LOGIN IP & AUTOKILL          ${NC}"
echo -e "${BLUE}====================================================${NC}"
echo -e " Status AutoKill : $st_kill"
echo -e " Batas Maksimal  : ${CYAN}${max_ip} IP${NC}"
echo -e " Proteksi Untuk  : ${YELLOW}SSH, Dropbear, WS, VMess, VLess, Trojan${NC}"
echo -e "${BLUE}====================================================${NC}"
echo -e " ${YELLOW}[1]${NC} Cek User & IP yang Sedang Login Sekarang"
echo -e " ${YELLOW}[2]${NC} Ubah Batas Maksimal IP (Default: 2 IP)"
echo -e " ${YELLOW}[3]${NC} Aktifkan AutoKill (Proteksi Otomatis Tiap 1 Menit)"
echo -e " ${YELLOW}[4]${NC} Matikan AutoKill"
echo -e " ${YELLOW}[5]${NC} Jalankan Pemutusan Paksa Sekarang (Manual Kill)"
echo -e " ${YELLOW}[6]${NC} Lihat Log Riwayat Pelanggar Multi-Login"
echo -e " ${YELLOW}[0]${NC} Kembali ke Menu Utama"
echo -e "${BLUE}====================================================${NC}"
read -p " Pilih Menu [0-6] : " opt_limit

case $opt_limit in
    1)
        clear
        python3 "$PY_ENGINE" --check
        echo ""
        read -n 1 -s -r -p "Tekan Enter untuk kembali..."
        bash "$0"
        ;;
    2)
        clear
        echo -e "${CYAN}====================================================${NC}"
        echo -e "${YELLOW}               UBAH BATAS MAX LOGIN IP              ${NC}"
        echo -e "${CYAN}====================================================${NC}"
        echo "Batas saat ini: $max_ip IP"
        echo ""
        read -p "Masukkan Batas IP Baru (contoh: 2): " new_max
        if [[ "$new_max" =~ ^[0-9]+$ ]] && [ "$new_max" -gt 0 ]; then
            python3 "$PY_ENGINE" --set-max "$new_max"
            echo -e "${GREEN}[SUKSES] Batas login berhasil diperbarui menjadi ${new_max} IP!${NC}"
        else
            echo -e "${RED}[ERROR] Masukan harus berupa angka lebih dari 0!${NC}"
        fi
        sleep 2
        bash "$0"
        ;;
    3)
        clear
        python3 "$PY_ENGINE" --enable
        # Pastikan cron aktif
        (crontab -l 2>/dev/null | grep -v "limit-ip"; echo "*/1 * * * * /usr/bin/python3 /usr/local/bin/limit-ip.py --kill >/dev/null 2>&1") | crontab -
        echo -e "${GREEN}[SUKSES] AutoKill Max Login diaktifkan dan berjalan otomatis setiap 1 menit!${NC}"
        sleep 2
        bash "$0"
        ;;
    4)
        clear
        python3 "$PY_ENGINE" --disable
        crontab -l 2>/dev/null | grep -v "limit-ip" | crontab -
        echo -e "${YELLOW}[SUKSES] AutoKill dinonaktifkan.${NC}"
        sleep 2
        bash "$0"
        ;;
    5)
        clear
        echo -e "${YELLOW}Memindai dan memutuskan sesi user yang melebihi batas...${NC}"
        python3 "$PY_ENGINE" --kill
        echo -e "${GREEN}Selesai! Periksa hasil di opsi [1] atau log di opsi [6].${NC}"
        echo ""
        read -n 1 -s -r -p "Tekan Enter untuk kembali..."
        bash "$0"
        ;;
    6)
        clear
        echo -e "${CYAN}====================================================${NC}"
        echo -e "${YELLOW}         LOG RIWAYAT AUTOKILL MULTI-LOGIN           ${NC}"
        echo -e "${CYAN}====================================================${NC}"
        if [ -s /var/log/limit-ip.log ]; then
            tail -n 25 /var/log/limit-ip.log
        else
            echo "Belum ada riwayat pelanggaran atau file log masih kosong."
        fi
        echo -e "${CYAN}====================================================${NC}"
        echo ""
        read -n 1 -s -r -p "Tekan Enter untuk kembali..."
        bash "$0"
        ;;
    0)
        menu 2>/dev/null || bash /vps-scripts/menu.sh
        ;;
    *)
        bash "$0"
        ;;
esac
