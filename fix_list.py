import os

path = "/app/applet/vps-scripts/list-account.sh"
with open(path, "r") as f:
    content = f.read()

target = """echo ""
read -r -p "Tekan [Enter] untuk kembali..." dummy
-e echo -e " \e[33m====================================================\e[0m"
read -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama..."
menu"""

replacement = """echo ""
echo -e "\\e[33m====================================================\\e[0m"
read -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama..."
menu"""

if target in content:
    content = content.replace(target, replacement)
else:
    # Alternative targeting if escape characters got weird
    import re
    content = re.sub(r'read -r -p "Tekan \[Enter\] untuk kembali\.\.\." dummy\n-e .*?\nread -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama\.\.\."\nmenu', replacement, content, flags=re.DOTALL)
    
with open(path, "w") as f:
    f.write(content)

print("Fixed list-account")
