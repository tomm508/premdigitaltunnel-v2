with open("/app/applet/vps-scripts/menu.sh", "r") as f:
    menu = f.read()

# Make sure option 7 regenerates SSL and restarts services cleanly
old_opt7 = """    7)
        read -p "Masukkan Domain Baru: " new_domain
        if [ -n "$new_domain" ]; then
            echo "$new_domain" > /etc/vps-domain.txt
            echo -e "${GREEN}Domain berhasil diubah! Restarting...${NC}"
            systemctl restart xray
            echo ""
            echo -e "${YELLOW}====================================================${NC}"
            read -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama..."
            menu
        fi
        ;;"""

new_opt7 = """    7)
        echo -e "\\n${CYAN}====================================================${NC}"
        echo -e "${GREEN}                  GANTI DOMAIN VPS                  ${NC}"
        echo -e "${CYAN}====================================================${NC}"
        read -p " Masukkan Domain Baru: " new_domain
        if [ -n "$new_domain" ]; then
            echo "$new_domain" > /etc/vps-domain.txt
            echo -e "\\n${YELLOW}[1/3] Menghasilkan Sertifikat SSL baru untuk $new_domain...${NC}"
            mkdir -p /etc/xray
            openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -sha256 \\
            -subj "/C=ID/ST=DKI Jakarta/L=Jakarta/O=PremDigital/OU=PremDigital/CN=$new_domain" \\
            -out /etc/xray/xray.crt -keyout /etc/xray/xray.key 2>/dev/null
            chmod 644 /etc/xray/xray.crt 2>/dev/null
            chmod 600 /etc/xray/xray.key 2>/dev/null
            
            echo -e "${YELLOW}[2/3] Merestart Stunnel4 & Xray...${NC}"
            systemctl restart stunnel4 2>/dev/null || true
            systemctl restart xray 2>/dev/null || true
            systemctl restart ws-openssh 2>/dev/null || true
            
            echo -e "${GREEN}[3/3] Sukses! Domain VPS berhasil diubah ke: $new_domain${NC}"
            echo ""
            echo -e "${YELLOW}====================================================${NC}"
            read -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama..."
            menu
        fi
        ;;"""

menu = menu.replace(old_opt7, new_opt7)
with open("/app/applet/vps-scripts/menu.sh", "w") as f:
    f.write(menu)

print("menu.sh domain handler upgraded")
