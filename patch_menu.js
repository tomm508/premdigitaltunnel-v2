const fs = require('fs');
const file = '/app/applet/vps-scripts/menu.sh';
let content = fs.readFileSync(file, 'utf8');

const target = `        if [ "$web_opt" == "1" ]; then
            echo -e "\\${CYAN}Mengunduh script worker Firebase... (Fitur ini sedang disempurnakan)\\${NC}"
            echo ""
            read -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama..."
            menu`;

const replacement = `        if [ "$web_opt" == "1" ]; then
            echo -e "\\${CYAN}Memulai instalasi Daemon Telemetri...\\${NC}"
            bash <(curl -s https://raw.githubusercontent.com/tomm508/premdigitaltunnel-v2/main/vps-scripts/install_worker.sh)
            echo ""
            read -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama..."
            menu`;

if (content.includes(target)) {
  content = content.replace(target, replacement);
  fs.writeFileSync(file, content);
  console.log("Patched successfully");
} else {
  console.log("Target not found");
}
