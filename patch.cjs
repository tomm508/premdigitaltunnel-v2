const fs = require('fs');
const file = '/app/applet/src/App.tsx';
let content = fs.readFileSync(file, 'utf8');

const target = `{nodes.length === 0 ? (
        <div className="p-8 text-center text-slate-500 bg-white rounded-xl border border-dashed">
          Menunggu telemetri dari VPS... Pastikan script report_status.sh berjalan di server Anda.
        </div>
      ) : (`;

const replacement = `{nodes.length === 0 ? (
        <div className="p-8 text-center bg-white rounded-xl border border-dashed flex flex-col items-center">
          <p className="text-slate-500 mb-6">Menunggu telemetri dari VPS...</p>
          
          <div className="w-full max-w-3xl text-left bg-slate-900 rounded-lg p-6 shadow-inner">
            <h3 className="text-white font-medium mb-3 flex items-center">
              <Terminal className="w-4 h-4 mr-2 text-cyan-400" />
              Instalasi Cepat di VPS Anda
            </h3>
            <p className="text-slate-400 text-sm mb-4">Salin dan jalankan perintah ini di terminal VPS Anda untuk menghubungkannya ke panel ini:</p>
            
            <pre className="bg-slate-950 p-4 rounded text-sm text-emerald-400 overflow-x-auto whitespace-pre-wrap font-mono">
{\`cat > /root/node_config.txt << 'EOF_CONFIG'
NODE_ID="sg-premium-01"
NODE_NAME="SG1 DigitalOcean"
CITY="Singapore"
COUNTRY_CODE="SG"
PROJECT_ID="web-premdigitalvpn"
API_KEY="AIzaSyDEtjcfHC9cnqxdTpMv8hnRUMDv4c5EYB4"
EOF_CONFIG

bash <(curl -s https://raw.githubusercontent.com/tomm508/premdigitaltunnel-v2/main/vps-scripts/install_worker.sh)\`}
            </pre>
          </div>
        </div>
      ) : (`;

if (content.includes(target)) {
  content = content.replace(target, replacement);
  fs.writeFileSync(file, content);
  console.log("Patched successfully");
} else {
  console.log("Target not found");
}
