import os

path = "/app/applet/vps-scripts/add-vmess.sh"
with open(path, "r") as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    if "Output Hasil di Terminal" in line:
        # found the block
        break
    new_lines.append(line)

new_output = """# ==========================================
# Output Hasil di Terminal
# ==========================================
clear
echo -e "\\e[1;32m✅  SUKSES CREATE AKUN VMESS\\e[0m"
echo -e "\\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\e[0m"
echo -e "👤 Username     : \\e[1;33m${user}\\e[0m"
echo -e "🆔 UUID         : \\e[1;37m${uuid}\\e[0m"
echo -e "🌍 Host / SNI   : \\e[1;37m${domain}\\e[0m"
echo -e "⏳ Masa Aktif   : \\e[1;37m${masaaktif} Hari\\e[0m"
echo -e "📅 Expired Pada : \\e[1;31m${exp}\\e[0m"
echo -e "\\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\e[0m"
echo -e "🔒 \\e[1;32m1. WS TLS (Port 443)\\e[0m"
echo -e "${link_ws_tls}"
echo -e "🔓 \\e[1;32m2. WS Non-TLS (Port 80)\\e[0m"
echo -e "${link_ws_ntls}"
echo -e "⚡ \\e[1;32m3. gRPC (Port 443)\\e[0m"
echo -e "${link_grpc}"
echo -e "🚀 \\e[1;32m4. HTTPUpgrade TLS (Port 443)\\e[0m"
echo -e "${link_up_tls}"
echo -e "📡 \\e[1;32m5. HTTPUpgrade Non-TLS (Port 80)\\e[0m"
echo -e "${link_up_ntls}"
echo -e "\\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\e[0m"
echo -e "🪁 Terima Kasih telah menggunakan layanan kami!"
echo ""
echo -e "\\e[33m====================================================\\e[0m"
read -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama..."
menu
"""

with open(path, "w") as f:
    f.writelines(new_lines)
    f.write(new_output)

print("Rewrote VMess output")
