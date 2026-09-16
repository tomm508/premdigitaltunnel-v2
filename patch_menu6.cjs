const fs = require('fs');
const file = '/app/applet/vps-scripts/menu.sh';
let content = fs.readFileSync(file, 'utf8');

const target = '            chmod +x /root/premdigital_reporter.sh\n' +
'            (crontab -l 2>/dev/null | grep -v "premdigital_reporter.sh"; echo "*/1 * * * * /root/premdigital_reporter.sh >/dev/null 2>&1") | crontab -\n' +
'            \n' +
'            echo -e "${GREEN}[SUCCESS] Instalasi selesai! VPS ini sekarang akan otomatis melapor ke Web Admin setiap 1 menit.${NC}"\n' +
'            echo ""\n' +
'            read -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama..."\n' +
'            menu\n' +
'        elif [ "$web_opt" == "0" ]; then';

const replacement = '            chmod +x /root/premdigital_reporter.sh\n' +
'            (crontab -l 2>/dev/null | grep -v "premdigital_reporter.sh"; echo "*/1 * * * * /root/premdigital_reporter.sh >/dev/null 2>&1") | crontab -\n' +
'            \n' +
'            echo -e "${CYAN}Mengirim status pertama kali ke Web Panel...${NC}"\n' +
'            /root/premdigital_reporter.sh &\n' +
'            \n' +
'            echo -e "${GREEN}[SUCCESS] Instalasi selesai! VPS ini sekarang akan otomatis melapor ke Web Admin setiap 1 menit.${NC}"\n' +
'            echo ""\n' +
'            read -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama..."\n' +
'            menu\n' +
'        elif [ "$web_opt" == "2" ]; then\n' +
'            echo -e "${CYAN}Mengganti Data Server VPS...${NC}"\n' +
'            if [ -f /root/node_config.txt ]; then\n' +
'                source /root/node_config.txt\n' +
'                echo "Data saat ini:"\n' +
'                echo "ID Server: $NODE_ID"\n' +
'                echo "Nama     : $NODE_NAME"\n' +
'                echo "Kota     : $CITY"\n' +
'                echo "Negara   : $COUNTRY_CODE"\n' +
'                echo ""\n' +
'            fi\n' +
'            echo "Silakan masukkan detail baru (kosongkan lalu enter jika tidak ingin mengubah baris tersebut):"\n' +
'            read -p "Masukkan ID Server [$NODE_ID]: " NEW_NODE_ID\n' +
'            read -p "Masukkan Nama Server [$NODE_NAME]: " NEW_NODE_NAME\n' +
'            read -p "Masukkan Kota [$CITY]: " NEW_CITY\n' +
'            read -p "Masukkan Kode Negara [$COUNTRY_CODE]: " NEW_COUNTRY_CODE\n' +
'            \n' +
'            NODE_ID="${NEW_NODE_ID:-$NODE_ID}"\n' +
'            NODE_NAME="${NEW_NODE_NAME:-$NODE_NAME}"\n' +
'            CITY="${NEW_CITY:-$CITY}"\n' +
'            COUNTRY_CODE="${NEW_COUNTRY_CODE:-$COUNTRY_CODE}"\n' +
'            \n' +
'            cat > /root/node_config.txt << EOF_CONFIG\n' +
'NODE_ID="$NODE_ID"\n' +
'NODE_NAME="$NODE_NAME"\n' +
'CITY="$CITY"\n' +
'COUNTRY_CODE="$COUNTRY_CODE"\n' +
'PROJECT_ID="web-premdigitalvpn"\n' +
'API_KEY="AIzaSyDEtjcfHC9cnqxdTpMv8hnRUMDv4c5EYB4"\n' +
'EOF_CONFIG\n' +
'            \n' +
'            echo -e "${GREEN}Konfigurasi berhasil diupdate di /root/node_config.txt!${NC}"\n' +
'            if [ -f /root/premdigital_reporter.sh ]; then\n' +
'                echo "Mengirim update status seketika ke Web Panel..."\n' +
'                /root/premdigital_reporter.sh &\n' +
'            fi\n' +
'            echo ""\n' +
'            read -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama..."\n' +
'            menu\n' +
'        elif [ "$web_opt" == "0" ]; then';

if (content.includes(target)) {
  content = content.replace(target, replacement);
  fs.writeFileSync(file, content);
  console.log("Patched successfully");
} else {
  console.log("Target not found");
}
