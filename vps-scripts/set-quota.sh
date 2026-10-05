#!/bin/bash
# ==========================================
# SET VPS MONTHLY BANDWIDTH QUOTA
# PremDigital Tunneling
# ==========================================
mkdir -p /etc/premdigital

QUOTA_FILE="/etc/premdigital/quota.txt"
current_quota="Belum diset"
[ -f "$QUOTA_FILE" ] && current_quota=$(cat "$QUOTA_FILE" | tr -d '\r\n ')

echo -e "\e[34m====================================================\e[0m"
echo -e "\e[32m       ATUR KUOTA BANDWIDTH BULANAN VPS            \e[0m"
echo -e "\e[34m====================================================\e[0m"
echo -e " Kuota Saat Ini : \e[33m$current_quota\e[0m"
echo ""
echo -e " Masukkan batas kuota paket VPS Anda."
echo -e " Contoh input: \e[36m1TB\e[0m, \e[36m2TB\e[0m, \e[36m4TB\e[0m, \e[36m5TB\e[0m, atau \e[36mUnlimited\e[0m"
echo -e "\e[34m----------------------------------------------------\e[0m"
read -p " Batas Kuota Baru [Contoh: 4TB] : " input_quota

if [ -n "$input_quota" ]; then
    echo "$input_quota" > "$QUOTA_FILE"
    echo -e "\n\e[32m[SUKSES] Kuota bulanan VPS berhasil diatur ke: $input_quota\e[0m"
    echo -e "Silakan ketik \e[33mmenu\e[0m untuk melihat tampilan baru."
else
    echo -e "\n\e[31m[BATAL] Tidak ada perubahan kuota.\e[0m"
fi
