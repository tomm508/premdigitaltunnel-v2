import os

path = "/app/applet/vps-scripts/menu.sh"
with open(path, "r") as f:
    content = f.read()

target = """        if [ -n "$new_domain" ]; then
            echo "$new_domain" > /etc/vps-domain.txt
            echo -e "${GREEN}Domain berhasil diubah! Restarting...${NC}"
            systemctl restart xray
            echo ""
            read -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama..."
            menu
        fi"""

replacement = """        if [ -n "$new_domain" ]; then
            echo "$new_domain" > /etc/vps-domain.txt
            echo -e "${GREEN}Domain berhasil diubah! Restarting...${NC}"
            systemctl restart xray
            echo ""
            echo -e "${YELLOW}====================================================${NC}"
            read -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama..."
            menu
        fi"""

if target in content:
    content = content.replace(target, replacement)
    
target2 = """        echo "Merestart layanan..."
        systemctl restart xray ssh dropbear 2>/dev/null
        echo -e "${GREEN}Restart Selesai!${NC}"
        echo ""
        read -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama..."
        menu"""

replacement2 = """        echo "Merestart layanan..."
        systemctl restart xray ssh dropbear 2>/dev/null
        echo -e "${GREEN}Restart Selesai!${NC}"
        echo ""
        echo -e "${YELLOW}====================================================${NC}"
        read -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama..."
        menu"""

if target2 in content:
    content = content.replace(target2, replacement2)

with open(path, "w") as f:
    f.write(content)
print("Fixed menu.sh")
