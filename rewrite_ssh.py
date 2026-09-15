import os

path = "/app/applet/vps-scripts/add-ssh.sh"
with open(path, "r") as f:
    lines = f.readlines()

new_lines = []
in_output_block = False
for line in lines:
    if 'echo -e "\\e[32m====================================================\\e[0m"' in line and "INFORMASI AKUN SSH/WS" in "".join(lines):
        in_output_block = True
        break
    new_lines.append(line)

new_output = """
ISP=$(curl -s -m 5 ipinfo.io/org | cut -d " " -f 2- || echo "Unknown")
CITY=$(curl -s -m 5 ipinfo.io/city || echo "Unknown")

clear
echo -e "\\e[1;32m✅  SUKSES CREATE AKUN SSH/WS\\e[0m"
echo -e "\\e[36m====================================================\\e[0m"
echo -e "              INFORMASI AKUN SSH/WS                 "
echo -e "\\e[36m====================================================\\e[0m"
echo -e "Host           : $domain"
echo -e "ISP            : $ISP"
echo -e "City           : $CITY"
echo -e "Username       : $username"
echo -e "Password       : $password"
echo -e "Expiry Date    : $exp"
echo -e "Expiry Time    : $masaaktif Days"
echo -e "\\e[36m====================================================\\e[0m"
echo -e ""
echo -e "OpenSSH        : 22"
echo -e "Dropbear       : 109, 143"
echo -e "SSH WS         : 80, 8080"
echo -e "SSH SSL/TLS    : 443"
echo -e "UDP Custom     : 1-65535"
echo -e "\\e[36m====================================================\\e[0m"
echo -e "📌Payload WS:"
echo -e ""
echo -e "GET / HTTP/1.1"
echo -e "Host: $domain"
echo -e "Connection: Upgrade"
echo -e "User-Agent: [ua]"
echo -e "Upgrade: websocket"
echo -e ""
echo -e ""
echo -e "📌Payload Enhanced:"
echo -e ""
echo -e "PATCH / HTTP/1.1"
echo -e "Host: $domain"
echo -e "Host: bug.com"
echo -e "Connection: Upgrade"
echo -e "User-Agent: [ua]"
echo -e "Upgrade: websocket"
echo -e "\\e[36m====================================================\\e[0m"
echo -e "🪁 Terima Kasih telah menggunakan layanan kami!"
echo ""
echo -e "\\e[33m====================================================\\e[0m"
read -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama..."
menu
"""

with open(path, "w") as f:
    f.writelines(new_lines)
    f.write(new_output)

print("Rewrote SSH output")
