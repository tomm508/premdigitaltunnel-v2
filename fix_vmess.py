import os

path = "/app/applet/vps-scripts/add-vmess.sh"
with open(path, "r") as f:
    content = f.read()

target = """echo -e "\\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\e[0m"
echo -e "💡 Simpan link di atas untuk dimasukkan ke V2rayNG, Clash, atau Sing-box."
echo ""
-e echo -e " [33m==================================================== [0m"
read -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama..."
menu"""

replacement = """echo -e "\\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\e[0m"
echo -e "🪁 Terima Kasih telah menggunakan layanan kami!"
echo ""
echo -e "\\e[33m====================================================\\e[0m"
read -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama..."
menu"""

if target in content:
    content = content.replace(target, replacement)
    with open(path, "w") as f:
        f.write(content)
    print("Fixed add-vmess.sh bottom")
else:
    print("Target not found in add-vmess.sh")
