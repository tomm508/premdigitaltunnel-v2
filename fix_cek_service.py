import os

path = "/app/applet/vps-scripts/cek-service.sh"
with open(path, "r") as f:
    content = f.read()

target = """services=("ssh" "dropbear" "stunnel4" "ws-openssh" "xray" "udp-custom" "badvpn-7100" "badvpn-7200" "badvpn-7300" "cron")

for svc in "${services[@]}"; do
    if systemctl is-active --quiet $svc; then
        echo -e " 🔹 $svc \\t: \\e[1;32m[ RUNNING ]\\e[0m"
    else
        echo -e " 🔹 $svc \\t: \\e[1;31m[ STOPPED / ERROR ]\\e[0m"
    fi
done"""

replacement = """services=("ssh" "dropbear" "stunnel4" "ws-openssh" "xray" "udp-custom" "cron")

for svc in "${services[@]}"; do
    if systemctl is-active --quiet $svc; then
        printf " 🔹 %-15s : \\e[1;32m[ RUNNING ]\\e[0m\\n" "$svc"
    else
        printf " 🔹 %-15s : \\e[1;31m[ STOPPED / ERROR ]\\e[0m\\n" "$svc"
    fi
done

# Badvpn dipersingkat
if systemctl is-active --quiet badvpn-7100 && systemctl is-active --quiet badvpn-7200 && systemctl is-active --quiet badvpn-7300; then
    printf " 🔹 %-15s : \\e[1;32m[ RUNNING ]\\e[0m\\n" "badvpn (71-73)"
else
    printf " 🔹 %-15s : \\e[1;31m[ STOPPED / ERROR ]\\e[0m\\n" "badvpn (71-73)"
fi"""

if target in content:
    content = content.replace(target, replacement)
    with open(path, "w") as f:
        f.write(content)
    print("Fixed cek-service.sh alignment and badvpn")
else:
    print("Target not found in cek-service.sh")
