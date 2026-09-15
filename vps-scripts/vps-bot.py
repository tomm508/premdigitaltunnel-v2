#!/usr/bin/python3
import requests, time, os, subprocess, json, random, string, base64, uuid
from datetime import datetime, timedelta

BOT_TOKEN = "ISI_TOKEN_BOT_DISINI"
LAST_UPDATE_ID = 0

try:
    with open('/etc/vps-domain.txt', 'r') as f:
        DOMAIN = f.read().strip()
except:
    DOMAIN = "IP_VPS"

ADMIN_CONTACT = "t.me/T0M15"
WEB_URL = "https://www.premdigital.web.id"
VERSION = "v1.8 { PremDigital }"
OWNER_ID = "6010478011"
GROUP_TESTI_ID = "-1004466282250" 

TRIAL_SETTING_FILE = "/etc/premdigital/trial_setting.txt"
TRIAL_LIMIT_FILE = "/etc/premdigital/trial_limit.txt"
SERVER_LIMIT_FILE = "/etc/premdigital/server_limit.txt"

PRICE_IP1_FILE = "/etc/premdigital/price_ip1.txt"
PRICE_IP2_FILE = "/etc/premdigital/price_ip2.txt"
PRICE_IP3_FILE = "/etc/premdigital/price_ip3.txt"
PRICE_IP5_FILE = "/etc/premdigital/price_ip5.txt"

PRICE_RES_IP1_FILE = "/etc/premdigital/price_res_ip1.txt"
PRICE_RES_IP2_FILE = "/etc/premdigital/price_res_ip2.txt"
PRICE_RES_IP3_FILE = "/etc/premdigital/price_res_ip3.txt"
PRICE_RES_IP5_FILE = "/etc/premdigital/price_res_ip5.txt"

QUOTA_FILE = "/etc/premdigital/quota_setting.txt"

DB_FILE = "/etc/premdigital/users_db.json"
QRIS_FILE_ID = "/etc/premdigital/qris_id.txt"

CONFIG_XRAY = "/etc/xray/config.json"
XRAY_DB = "/etc/premdigital/xray-users.db"

USER_STATE = {}

def load_db():
    if not os.path.exists(DB_FILE):
        os.makedirs('/etc/premdigital', exist_ok=True)
        with open(DB_FILE, 'w') as f: json.dump({}, f)
        return {}
    with open(DB_FILE, 'r') as f:
        try: return json.load(f)
        except: return {}

def save_db(data):
    os.makedirs('/etc/premdigital', exist_ok=True)
    with open(DB_FILE, 'w') as f: json.dump(data, f, indent=4)

def get_user(user_id):
    db = load_db()
    uid = str(user_id)
    if uid not in db:
        db[uid] = {"balance": 0, "role": "USER", "trial_count": 0, "last_trial_date": "", "accounts": []}
        if uid == str(OWNER_ID): db[uid]["role"] = "ADMIN"
        save_db(db)
    elif "accounts" not in db[uid]:
        db[uid]["accounts"] = []
        save_db(db)
    return db[uid]

def get_trial_duration():
    try:
        with open(TRIAL_SETTING_FILE, 'r') as f: return f.read().strip()
    except: return "15 Menit"

def set_trial_duration(duration):
    try:
        os.makedirs('/etc/premdigital', exist_ok=True)
        with open(TRIAL_SETTING_FILE, 'w') as f: f.write(duration)
    except: pass

def get_trial_limit():
    try:
        with open(TRIAL_LIMIT_FILE, 'r') as f: return f.read().strip()
    except: return "1"

def set_trial_limit(limit):
    try:
        os.makedirs('/etc/premdigital', exist_ok=True)
        with open(TRIAL_LIMIT_FILE, 'w') as f: f.write(limit)
    except: pass

def get_server_limit():
    try:
        with open(SERVER_LIMIT_FILE, 'r') as f: return f.read().strip()
    except: return "150"

def set_server_limit(limit):
    try:
        os.makedirs('/etc/premdigital', exist_ok=True)
        with open(SERVER_LIMIT_FILE, 'w') as f: f.write(str(limit))
    except: pass

def get_quota():
    try:
        with open(QUOTA_FILE, 'r') as f: return f.read().strip()
    except: return "70"

def set_quota(q):
    try:
        os.makedirs('/etc/premdigital', exist_ok=True)
        with open(QUOTA_FILE, 'w') as f: f.write(str(q))
    except: pass

def get_price_ip(limit):
    paths = {"1": PRICE_IP1_FILE, "2": PRICE_IP2_FILE, "3": PRICE_IP3_FILE, "5": PRICE_IP5_FILE}
    defs = {"1": 200, "2": 400, "3": 600, "5": 1000}
    try:
        with open(paths[str(limit)], 'r') as f: return int(f.read().strip())
    except:
        return defs.get(str(limit), 200)

def set_price_ip(limit, price):
    paths = {"1": PRICE_IP1_FILE, "2": PRICE_IP2_FILE, "3": PRICE_IP3_FILE, "5": PRICE_IP5_FILE}
    try:
        os.makedirs('/etc/premdigital', exist_ok=True)
        with open(paths[str(limit)], 'w') as f: f.write(str(price))
    except: pass

def get_reseller_price(limit):
    paths = {"1": PRICE_RES_IP1_FILE, "2": PRICE_RES_IP2_FILE, "3": PRICE_RES_IP3_FILE, "5": PRICE_RES_IP5_FILE}
    defs = {"1": 150, "2": 300, "3": 450, "5": 750}
    try:
        with open(paths[str(limit)], 'r') as f: return int(f.read().strip())
    except:
        return defs.get(str(limit), 150)

def set_reseller_price(limit, price):
    paths = {"1": PRICE_RES_IP1_FILE, "2": PRICE_RES_IP2_FILE, "3": PRICE_RES_IP3_FILE, "5": PRICE_RES_IP5_FILE}
    try:
        os.makedirs('/etc/premdigital', exist_ok=True)
        with open(paths[str(limit)], 'w') as f: f.write(str(price))
    except: pass

# ==========================================================
# XRAY HELPER & LINK GENERATOR
# ==========================================================
def ensure_xray_ready():
    if not os.path.exists('/usr/local/bin/xray') or not os.path.exists(CONFIG_XRAY):
        if os.path.exists('/usr/local/bin/setup-xray'):
            os.system('bash /usr/local/bin/setup-xray >/dev/null 2>&1')

def add_xray_client(protocol, user, credential):
    ensure_xray_ready()
    proto = protocol.lower()
    try:
        with open(CONFIG_XRAY, 'r') as f:
            data = json.load(f)
        for ib in data.get("inbounds", []):
            if ib.get("protocol") == proto:
                clients = ib.setdefault("settings", {}).setdefault("clients", [])
                clients[:] = [c for c in clients if c.get("email") != user]
                if proto == "vmess":
                    clients.append({"id": str(credential), "alterId": 0, "email": user})
                elif proto == "vless":
                    clients.append({"id": str(credential), "email": user})
                elif proto == "trojan":
                    clients.append({"password": str(credential), "email": user})
        with open(CONFIG_XRAY, 'w') as f:
            json.dump(data, f, indent=2)
        os.system("systemctl restart xray >/dev/null 2>&1")
        return True
    except:
        return False

def record_xray_db(user, credential, exp_date, protocol):
    os.makedirs('/etc/premdigital', exist_ok=True)
    lines = []
    if os.path.exists(XRAY_DB):
        with open(XRAY_DB, 'r') as f:
            lines = [l for l in f if not l.strip().startswith(f"{user} |")]
    lines.append(f"{user} | {credential} | {exp_date} | {protocol.lower()}\n")
    with open(XRAY_DB, 'w') as f:
        f.writelines(lines)

def generate_vmess_links(user, user_uuid, domain):
    j_tls = {"v": "2", "ps": user, "add": domain, "port": "443", "id": str(user_uuid), "aid": "0", "net": "ws", "path": "/vmess", "type": "none", "host": domain, "sni": domain, "tls": "tls"}
    b64_tls = base64.b64encode(json.dumps(j_tls).encode()).decode()
    link_ws_tls = f"vmess://{b64_tls}"

    j_ntls = {"v": "2", "ps": user, "add": domain, "port": "80", "id": str(user_uuid), "aid": "0", "net": "ws", "path": "/vmess", "type": "none", "host": domain, "sni": "", "tls": "none"}
    b64_ntls = base64.b64encode(json.dumps(j_ntls).encode()).decode()
    link_ws_ntls = f"vmess://{b64_ntls}"

    j_grpc = {"v": "2", "ps": user, "add": domain, "port": "443", "id": str(user_uuid), "aid": "0", "net": "grpc", "path": "vmess", "type": "gun", "host": domain, "sni": domain, "tls": "tls"}
    b64_grpc = base64.b64encode(json.dumps(j_grpc).encode()).decode()
    link_grpc = f"vmess://{b64_grpc}"

    return link_ws_tls, link_ws_ntls, link_grpc

def generate_vless_links(user, user_uuid, domain):
    link_ws_tls = f"vless://{user_uuid}@{domain}:443?path=/vless&security=tls&encryption=none&host={domain}&type=ws&sni={domain}#{user}"
    link_ws_ntls = f"vless://{user_uuid}@{domain}:80?path=/vless&security=none&encryption=none&host={domain}&type=ws#{user}"
    link_grpc = f"vless://{user_uuid}@{domain}:443?mode=multi&security=tls&encryption=none&type=grpc&serviceName=vless&sni={domain}#{user}"
    return link_ws_tls, link_ws_ntls, link_grpc

def generate_trojan_links(user, password, domain):
    link_ws_tls = f"trojan://{password}@{domain}:443?path=/trojan&security=tls&host={domain}&type=ws&sni={domain}#{user}"
    link_ws_ntls = f"trojan://{password}@{domain}:80?path=/trojan&security=none&host={domain}&type=ws#{user}"
    link_grpc = f"trojan://{password}@{domain}:443?mode=multi&security=tls&type=grpc&serviceName=trojan&sni={domain}#{user}"
    return link_ws_tls, link_ws_ntls, link_grpc

# ==========================================================
# TELEGRAM API HELPERS
# ==========================================================
def send_message_with_keyboard(chat_id, text, reply_markup=None):
    url = f"https://api.telegram.org/bot{BOT_TOKEN}/sendMessage"
    payload = {"chat_id": chat_id, "text": text, "parse_mode": "HTML", "disable_web_page_preview": True}
    if reply_markup: payload["reply_markup"] = reply_markup
    try: 
        res = requests.post(url, json=payload, timeout=5).json()
        return res.get("result", {}).get("message_id")
    except: return None

def edit_message_with_keyboard(chat_id, message_id, text, reply_markup=None):
    url_edit = f"https://api.telegram.org/bot{BOT_TOKEN}/editMessageText"
    payload = {"chat_id": chat_id, "message_id": message_id, "text": text, "parse_mode": "HTML", "disable_web_page_preview": True}
    if reply_markup: payload["reply_markup"] = reply_markup
    try: 
        res = requests.post(url_edit, json=payload, timeout=5).json()
        if not res.get("ok"):
            requests.post(f"https://api.telegram.org/bot{BOT_TOKEN}/deleteMessage", json={"chat_id": chat_id, "message_id": message_id}, timeout=5)
            requests.post(f"https://api.telegram.org/bot{BOT_TOKEN}/sendMessage", json=payload, timeout=5)
    except: pass

def edit_message_caption(chat_id, message_id, caption, reply_markup=None):
    url = f"https://api.telegram.org/bot{BOT_TOKEN}/editMessageCaption"
    payload = {"chat_id": chat_id, "message_id": message_id, "caption": caption, "parse_mode": "HTML"}
    if reply_markup: payload["reply_markup"] = reply_markup
    try: requests.post(url, json=payload, timeout=5)
    except: pass

def get_main_menu_text(first_name, user_id):
    user_data = get_user(user_id)
    saldo_str = f"Rp {user_data['balance']:,}".replace(',', '.')
    role_str = user_data['role']
    if str(user_id) == str(OWNER_ID): role_str = "ADMIN / OWNER"
    
    vmess_count = vless_count = trojan_count = 0
    xray_users = set()
    if os.path.exists(XRAY_DB):
        try:
            with open(XRAY_DB, 'r') as f:
                for line in f:
                    parts = [p.strip() for p in line.split('|')]
                    if len(parts) >= 4:
                        xray_users.add(parts[0])
                        proto = parts[3].lower()
                        if proto == 'vmess': vmess_count += 1
                        elif proto == 'vless': vless_count += 1
                        elif proto == 'trojan': trojan_count += 1
        except: pass
        
    try:
        all_ml = os.listdir('/etc/premdigital/multilogin')
        ssh_count = len([u for u in all_ml if u not in xray_users])
    except:
        ssh_count = 0
        
    total_count = ssh_count + vmess_count + vless_count + trojan_count
    return (
        f"📦━━━━━━━[ <b>PREMDIGITAL</b> ]━━━━━━━📦\n\n"
        f"👋 Selamat datang di <b>VPN AUTO ORDER</b> 💎\n"
        f"Solusi kelola akun VPN cepat, aman, & otomatis 🚀\n\n"
        f"🧭 <b>Informasi Akun (Bot)</b>\n"
        f"┌───────────────────────┐\n"
        f"├ 👤 <b>Nama  :</b> {first_name}\n"
        f"├ 🆔 <b>ID    :</b> <code>{user_id}</code>\n"
        f"├ 💰 <b>Saldo :</b> {saldo_str}\n"
        f"├ 👑 <b>Role  :</b> {role_str}\n"
        f"└───────────────────────┘\n\n"
        f"📊 <b>Akun Aktif</b>\n"
        f"┌───────────────────────┐\n"
        f"│ SSH       : {ssh_count}\n"
        f"│ VMESS     : {vmess_count}\n"
        f"│ VLESS     : {vless_count}\n"
        f"│ TROJAN    : {trojan_count}\n"
        f"├───────────────────────┤\n"
        f"│ 📦 Total  : {total_count}\n"
        f"└───────────────────────┘\n\n"
        f"⚡ <b>Sistem</b>\n"
        f"• Otomatis 24 Jam\n"
        f"• Cepat & Stabil\n"
        f"• Support Banyak Protocol\n\n"
        f"☎️ <b>Admin</b>\n"
        f"📧 {ADMIN_CONTACT}\n"
        f"🌐 {WEB_URL}\n\n"
        f"<i>Version {VERSION}</i>"
    )

def get_main_menu_keyboard():
    return {
        "inline_keyboard": [
            [{"text": "🛒 Order Akun", "callback_data": "menu_order_akun"}, {"text": "🆓 Trial Akun", "callback_data": "menu_trial_akun"}],
            [{"text": "🔄 Perpanjang", "callback_data": "menu_perpanjang"}, {"text": "💳 Isi Saldo", "callback_data": "menu_isi_saldo"}],
            [{"text": "📋 Daftar Akun Saya", "callback_data": "menu_daftar_akun"}],
            [{"text": "🚀 Upgrade Reseller", "callback_data": "menu_upgrade_reseller"}],
            [{"text": "👨‍💻 Hubungi Admin ↗️", "url": f"https://{ADMIN_CONTACT}"}]
        ]
    }

def get_admin_menu_text():
    return (
        f"🛠 <b>PANEL ADMIN PDI</b>\n"
        f"━━━━━━━━━━━━━━━━━━━━━━\n"
        f"Selamat datang di Control Panel Administrator.\n"
        f"Silakan pilih menu manajemen di bawah ini:"
    )

def get_admin_menu_keyboard():
    return {
        "inline_keyboard": [
            [{"text": "💰 Saldo User", "callback_data": "admin_add_saldo"}, {"text": "🌟 Reseller", "callback_data": "admin_add_reseller"}],
            [{"text": "📢 Broadcast", "callback_data": "admin_broadcast"}, {"text": "⚙️ Kuota", "callback_data": "admin_quota_setting"}],
            [{"text": "⚙️ Harga User", "callback_data": "admin_price_setting"}, {"text": "⚙️ Harga Reseller", "callback_data": "admin_price_res_setting"}],
            [{"text": "⚙️ Limit Server", "callback_data": "admin_server_limit"}, {"text": "⚙️ Atur Trial", "callback_data": "admin_trial_setting"}],
            [{"text": "🖼️ Set / Upload QRIS", "callback_data": "admin_set_qris"}],
            [{"text": "🔙 Kembali ke Main Menu", "callback_data": "back_to_main"}]
        ]
    }

def render_admin_trial_setting(chat_id, message_id):
    current_dur = get_trial_duration()
    current_lim = get_trial_limit()
    lim_label = "Unlimited" if current_lim == "999" else f"{current_lim}x / Hari"
    msg = (
        f"⚙️ <b>PENGATURAN TRIAL AKUN</b>\n"
        f"━━━━━━━━━━━━━━━━━━━━━━\n"
        f"⏱ <b>Durasi Trial :</b> {current_dur}\n"
        f"🛡 <b>Limit per ID :</b> {lim_label}\n\n"
        f"<i>Silakan klik tombol di bawah untuk mengubah pengaturan:</i>"
    )
    keyboard = {
        "inline_keyboard": [
            [{"text": "⏱ 15 Mnt", "callback_data": "set_trial_15 Menit"}, {"text": "⏱ 30 Mnt", "callback_data": "set_trial_30 Menit"}],
            [{"text": "⏱ 1 Jam", "callback_data": "set_trial_1 Jam"}, {"text": "⏱ 1 Hari", "callback_data": "set_trial_1 Hari"}],
            [{"text": "🛡 Limit 1x/Hari", "callback_data": "set_tlimit_1"}, {"text": "🛡 Limit 2x/Hari", "callback_data": "set_tlimit_2"}],
            [{"text": "🛡 Limit 3x/Hari", "callback_data": "set_tlimit_3"}, {"text": "🛡 Unlimited", "callback_data": "set_tlimit_999"}],
            [{"text": "🔙 Kembali", "callback_data": "back_to_admin"}]
        ]
    }
    edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)

def render_admin_price_setting(chat_id, message_id):
    p1 = get_price_ip("1"); p2 = get_price_ip("2")
    p3 = get_price_ip("3"); p5 = get_price_ip("5")
    msg = (
        f"⚙️ <b>PENGATURAN HARGA USER (PER HARI)</b>\n"
        f"━━━━━━━━━━━━━━━━━━━━━━\n"
        f"📱 <b>Harga 1 IP :</b> Rp {p1}\n"
        f"📱 <b>Harga 2 IP :</b> Rp {p2}\n"
        f"📱 <b>Harga 3 IP :</b> Rp {p3}\n"
        f"📱 <b>Harga 5 IP :</b> Rp {p5}\n\n"
        f"<i>Pilih limit IP yang ingin diubah harganya:</i>"
    )
    keyboard = {
        "inline_keyboard": [
            [{"text": "✏️ Ubah Harga 1 IP", "callback_data": "set_price_ip_1"}],
            [{"text": "✏️ Ubah Harga 2 IP", "callback_data": "set_price_ip_2"}],
            [{"text": "✏️ Ubah Harga 3 IP", "callback_data": "set_price_ip_3"}],
            [{"text": "✏️ Ubah Harga 5 IP", "callback_data": "set_price_ip_5"}],
            [{"text": "🔙 Kembali", "callback_data": "back_to_admin"}]
        ]
    }
    edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)

def render_admin_price_res_setting(chat_id, message_id):
    p1 = get_reseller_price("1"); p2 = get_reseller_price("2")
    p3 = get_reseller_price("3"); p5 = get_reseller_price("5")
    msg = (
        f"⚙️ <b>PENGATURAN HARGA RESELLER (PER HARI)</b>\n"
        f"━━━━━━━━━━━━━━━━━━━━━━\n"
        f"📱 <b>Harga 1 IP :</b> Rp {p1}\n"
        f"📱 <b>Harga 2 IP :</b> Rp {p2}\n"
        f"📱 <b>Harga 3 IP :</b> Rp {p3}\n"
        f"📱 <b>Harga 5 IP :</b> Rp {p5}\n\n"
        f"<i>Pilih limit IP yang ingin diubah harganya (Khusus Reseller):</i>"
    )
    keyboard = {
        "inline_keyboard": [
            [{"text": "✏️ Ubah Harga 1 IP", "callback_data": "set_res_price_1"}],
            [{"text": "✏️ Ubah Harga 2 IP", "callback_data": "set_res_price_2"}],
            [{"text": "✏️ Ubah Harga 3 IP", "callback_data": "set_res_price_3"}],
            [{"text": "✏️ Ubah Harga 5 IP", "callback_data": "set_res_price_5"}],
            [{"text": "🔙 Kembali", "callback_data": "back_to_admin"}]
        ]
    }
    edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)

def render_admin_server_limit(chat_id, message_id):
    current_limit = get_server_limit()
    msg = (
        f"⚙️ <b>PENGATURAN LIMIT SERVER</b>\n"
        f"━━━━━━━━━━━━━━━━━━━━━━\n"
        f"👥 Limit Maksimal Akun di VPS ini: <b>{current_limit} Akun</b>\n\n"
        f"<i>Silakan pilih atau ketik manual limit yang diinginkan:</i>"
    )
    keyboard = {
        "inline_keyboard": [
            [{"text": "50 Akun", "callback_data": "set_slimit_50"}, {"text": "100 Akun", "callback_data": "set_slimit_100"}],
            [{"text": "150 Akun", "callback_data": "set_slimit_150"}, {"text": "200 Akun", "callback_data": "set_slimit_200"}],
            [{"text": "✍️ Input Manual", "callback_data": "set_slimit_manual"}],
            [{"text": "🔙 Kembali", "callback_data": "back_to_admin"}]
        ]
    }
    edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)

# ==========================================================
# CALLBACK QUERY DISPATCHER
# ==========================================================
def process_callback(callback_query):
    chat_id = callback_query["message"]["chat"]["id"]
    message_id = callback_query["message"]["message_id"]
    first_name = callback_query["message"]["chat"].get("first_name", "User")
    user_id = callback_query["from"]["id"]
    data = callback_query["data"]
    
    try: requests.post(f"https://api.telegram.org/bot{BOT_TOKEN}/answerCallbackQuery", json={"callback_query_id": callback_query["id"]}, timeout=3)
    except: pass

    if data == "back_to_main":
        if user_id in USER_STATE and USER_STATE[user_id].get('step') != 'topup_pending': 
            del USER_STATE[user_id]
        msg = get_main_menu_text(first_name, user_id)
        keyboard = get_main_menu_keyboard()
        edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)
        
    elif data == "cancel_order":
        if user_id in USER_STATE: del USER_STATE[user_id]
        msg = get_main_menu_text(first_name, user_id)
        keyboard = get_main_menu_keyboard()
        edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)

    elif data == "menu_daftar_akun":
        user_data = get_user(user_id)
        acc_list = user_data.get("accounts", [])
        if not acc_list:
            msg = (
                "📋 <b>DAFTAR AKUN SAYA</b>\n"
                "━━━━━━━━━━━━━━━━━━━━━━\n"
                "Anda belum memiliki akun aktif yang dibuat di bot ini.\n\n"
                "Silakan klik tombol <b>Order Akun</b> atau <b>Trial Akun</b> untuk membuat akun baru!"
            )
        else:
            msg = "📋 <b>DAFTAR AKUN SAYA</b>\n━━━━━━━━━━━━━━━━━━━━━━\n"
            for idx, acc in enumerate(acc_list, start=1):
                p_name = acc.get("protocol", "SSH").upper()
                u_name = acc.get("username", "-")
                e_date = acc.get("exp_date", "-")
                msg += f"<b>{idx}. [{p_name}]</b> <code>{u_name}</code>\n"
                msg += f"    📅 Expired: {e_date}\n\n"
        keyboard = {"inline_keyboard": [[{"text": "🔙 Kembali ke Main Menu", "callback_data": "back_to_main"}]]}
        edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)

    elif data == "menu_perpanjang":
        USER_STATE[user_id] = {'step': 'renew_username'}
        msg = (
            "🔄 <b>PERPANJANG AKUN VPN</b>\n"
            "━━━━━━━━━━━━━━━━━━━━━━\n"
            "Silakan ketik <b>username</b> akun yang ingin Anda perpanjang:\n\n"
            "<i>(Pastikan saldo mencukupi sesuai tarif durasi perpanjangan)</i>"
        )
        keyboard = {"inline_keyboard": [[{"text": "⛔ Batal", "callback_data": "back_to_main"}]]}
        edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)

    elif data.startswith("acc_topup_"):
        if str(user_id) != str(OWNER_ID): return
        parts = data.split("_")
        target_id = parts[2]
        amount = int(parts[3])
        
        db = load_db()
        if target_id in db:
            db[target_id]["balance"] += amount
            save_db(db)
            if int(target_id) in USER_STATE and USER_STATE[int(target_id)].get('step') == 'topup_pending':
                del USER_STATE[int(target_id)]
            
            edit_message_caption(chat_id, message_id, f"✅ <b>DEPOSIT DISETUJUI</b>\n━━━━━━━━━━━━━━━━━━━━━━\nBerhasil menambahkan saldo Rp {amount:,} ke User ID: <code>{target_id}</code>")
            send_message_with_keyboard(target_id, f"🎉 <b>SALDO MASUK!</b>\n━━━━━━━━━━━━━━━━━━━━━━\nDeposit Anda sebesar <b>Rp {amount:,}</b> telah disetujui Admin. Saldo sudah masuk ke akun Anda.")
            
    elif data.startswith("rej_topup_"):
        if str(user_id) != str(OWNER_ID): return
        parts = data.split("_")
        target_id = parts[2]
        amount = parts[3]
        
        if int(target_id) in USER_STATE and USER_STATE[int(target_id)].get('step') == 'topup_pending':
            del USER_STATE[int(target_id)]
            
        edit_message_caption(chat_id, message_id, f"❌ <b>DEPOSIT DITOLAK</b>\n━━━━━━━━━━━━━━━━━━━━━━\nDeposit Rp {amount} dari User ID <code>{target_id}</code> telah Anda tolak.")
        send_message_with_keyboard(target_id, f"❌ <b>DEPOSIT DITOLAK</b>\n━━━━━━━━━━━━━━━━━━━━━━\nMaaf, pengajuan deposit Anda sebesar Rp {amount} <b>Ditolak oleh Admin</b> karena bukti transfer tidak valid. Silakan hubungi admin jika ini kesalahan.")

    elif data == "back_to_admin":
        if user_id in USER_STATE: del USER_STATE[user_id]
        msg = get_admin_menu_text()
        keyboard = get_admin_menu_keyboard()
        edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)

    elif data == "admin_add_saldo":
        msg = "💰 <b>TAMBAH SALDO USER</b>\n━━━━━━━━━━━━━━━━━━━━━━\nKetik perintah ini untuk menambah saldo (otomatis ke akun user):\n<code>/addsaldo [ID_USER] [JUMLAH]</code>\n\nAtau jika ingin <b>mengisi saldo ke akun Anda sendiri</b>, cukup ketik:\n<code>/addsaldo [JUMLAH]</code>"
        keyboard = {"inline_keyboard": [[{"text": "🔙 Kembali", "callback_data": "back_to_admin"}]]}
        edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)

    elif data == "admin_add_reseller":
        msg = "🌟 <b>TAMBAH / HAPUS RESELLER MANUAL</b>\n━━━━━━━━━━━━━━━━━━━━━━\nUntuk menjadikan user sebagai Reseller secara manual, ketik:\n<code>/addreseller [ID_USER]</code>\n\nUntuk menghapus status Reseller (mengembalikan menjadi User biasa), ketik:\n<code>/delreseller [ID_USER]</code>\n\n<i>Contoh:</i> <code>/addreseller 123456789</code>"
        keyboard = {"inline_keyboard": [[{"text": "🔙 Kembali", "callback_data": "back_to_admin"}]]}
        edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)

    elif data == "admin_broadcast":
        msg = "📢 <b>BROADCAST PESAN</b>\n━━━━━━━━━━━━━━━━━━━━━━\nKirim pesan massal ke semua member bot dengan:\n<code>/bc [PESAN ANDA]</code>\nContoh: <code>/bc Halo semuanya!</code>"
        keyboard = {"inline_keyboard": [[{"text": "🔙 Kembali", "callback_data": "back_to_admin"}]]}
        edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)
        
    elif data == "admin_quota_setting":
        USER_STATE[user_id] = {'step': 'input_quota'}
        curr = get_quota()
        display_curr = "Unlimited" if curr == "0" else f"{curr} GB"
        msg = f"⚙️ <b>PENGATURAN KUOTA VPN</b>\n━━━━━━━━━━━━━━━━━━━━━━\nKuota saat ini: <b>{display_curr}</b>\n\nSilakan ketik angka kuota baru (dalam GB):\n<i>(Ketik 0 untuk Unlimited)\nContoh: 100</i>"
        keyboard = {"inline_keyboard": [[{"text": "⛔ Batal", "callback_data": "back_to_admin"}]]}
        edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)

    elif data == "admin_set_qris":
        USER_STATE[user_id] = {'step': 'upload_qris'}
        msg = "🖼️ <b>UPLOAD FOTO QRIS</b>\n━━━━━━━━━━━━━━━━━━━━━━\nSilakan <b>Kirimkan / Upload Foto Barcode QRIS</b> Anda sekarang ke dalam chat ini.\n\n<i>(Foto yang Anda kirim akan otomatis disimpan di sistem bot)</i>"
        keyboard = {"inline_keyboard": [[{"text": "⛔ Batal", "callback_data": "back_to_admin"}]]}
        edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)

    elif data == "admin_trial_setting":
        render_admin_trial_setting(chat_id, message_id)
        
    elif data == "admin_price_setting":
        render_admin_price_setting(chat_id, message_id)
        
    elif data == "admin_price_res_setting":
        render_admin_price_res_setting(chat_id, message_id)
        
    elif data == "admin_server_limit":
        render_admin_server_limit(chat_id, message_id)

    elif data.startswith("set_price_ip_"):
        ip_target = data.replace("set_price_ip_", "")
        USER_STATE[user_id] = {'step': f'input_price_ip_{ip_target}'}
        msg = f"✍️ <b>INPUT HARGA USER {ip_target} IP</b>\n━━━━━━━━━━━━━━━━━━━━━━\nSilakan ketik harga per hari (dalam Rupiah) untuk limit {ip_target} IP.\nContoh: 200"
        keyboard = {"inline_keyboard": [[{"text": "⛔ Batal", "callback_data": "admin_price_setting"}]]}
        edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)
        
    elif data.startswith("set_res_price_"):
        ip_target = data.replace("set_res_price_", "")
        USER_STATE[user_id] = {'step': f'input_res_price_{ip_target}'}
        msg = f"✍️ <b>INPUT HARGA RESELLER {ip_target} IP</b>\n━━━━━━━━━━━━━━━━━━━━━━\nSilakan ketik harga per hari (dalam Rupiah) untuk RESELLER limit {ip_target} IP.\nContoh: 150"
        keyboard = {"inline_keyboard": [[{"text": "⛔ Batal", "callback_data": "admin_price_res_setting"}]]}
        edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)

    elif data.startswith("set_trial_"):
        new_duration = data.split("_", 2)[2]
        set_trial_duration(new_duration)
        try: requests.post(f"https://api.telegram.org/bot{BOT_TOKEN}/answerCallbackQuery", json={"callback_query_id": callback_query["id"], "text": f"✅ Durasi trial diubah ke {new_duration}!", "show_alert": True}, timeout=3)
        except: pass
        render_admin_trial_setting(chat_id, message_id)
        
    elif data.startswith("set_tlimit_"):
        new_limit = data.split("_", 2)[2]
        set_trial_limit(new_limit)
        lim_label = "Unlimited" if new_limit == "999" else f"{new_limit}x / Hari"
        try: requests.post(f"https://api.telegram.org/bot{BOT_TOKEN}/answerCallbackQuery", json={"callback_query_id": callback_query["id"], "text": f"✅ Limit trial diubah ke {lim_label}!", "show_alert": True}, timeout=3)
        except: pass
        render_admin_trial_setting(chat_id, message_id)
        
    elif data.startswith("set_slimit_"):
        val = data.replace("set_slimit_", "")
        if val == "manual":
            USER_STATE[user_id] = {'step': 'set_server_limit'}
            msg = "✍️ <b>INPUT LIMIT MANUAL</b>\n━━━━━━━━━━━━━━━━━━━━━━\nSilakan ketik angka limit maksimal akun untuk VPS ini (Contoh: 150):"
            keyboard = {"inline_keyboard": [[{"text": "⛔ Batal", "callback_data": "admin_server_limit"}]]}
            edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)
        else:
            set_server_limit(val)
            try: requests.post(f"https://api.telegram.org/bot{BOT_TOKEN}/answerCallbackQuery", json={"callback_query_id": callback_query["id"], "text": f"✅ Limit Server diubah ke {val} Akun!", "show_alert": True}, timeout=3)
            except: pass
            render_admin_server_limit(chat_id, message_id)

    elif data in ["menu_order_akun", "menu_trial_akun"]:
        tipe = "ORDER" if data == "menu_order_akun" else "TRIAL"
        msg = f"⚙️ <b>PILIH PROTOKOL/LAYANAN {tipe}</b>\n━━━━━━━━━━━━━━━━━━━━━━\nSilakan pilih jenis layanan VPN yang ingin Anda buat:"
        keyboard = {
            "inline_keyboard": [
                [{"text": "SSH", "callback_data": f"select_{tipe.lower()}_ssh"}, {"text": "VMESS", "callback_data": f"select_{tipe.lower()}_vmess"}],
                [{"text": "VLESS", "callback_data": f"select_{tipe.lower()}_vless"}, {"text": "TROJAN", "callback_data": f"select_{tipe.lower()}_trojan"}],
                [{"text": "🔙 Kembali", "callback_data": "back_to_main"}]
            ]
        }
        edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)

    elif data.startswith("select_"):
        parts = data.split("_")
        action = parts[1]
        protocol = parts[2].upper()
        
        user_data = get_user(user_id)
        
        isp = "Unknown ISP"; country = "Unknown"; country_code = "UN"
        try:
            req_ip = requests.get("http://ip-api.com/json/", timeout=5).json()
            isp = req_ip.get("isp", "Unknown ISP")
            country = req_ip.get("country", "Unknown").upper()
            country_code = req_ip.get("countryCode", "UN")
        except: pass

        try:
            ping_ms = subprocess.getoutput("ping -c 1 8.8.8.8 | grep time= | awk '{print $7}' | cut -d '=' -f2")
            if not ping_ms: ping_ms = "30"
        except: ping_ms = "30"
            
        server_code = f"{country_code}-{isp[:3].upper().replace(' ', '')}"
        
        try: current_acc = int(subprocess.getoutput("ls -1 /etc/premdigital/multilogin 2>/dev/null | wc -l"))
        except: current_acc = 0
        max_limit = get_server_limit()
        
        if action == "order":
            if user_data["role"] in ["RESELLER", "ADMIN"]:
                p1 = get_reseller_price("1"); p2 = get_reseller_price("2")
                p3 = get_reseller_price("3"); p5 = get_reseller_price("5")
                hrg_title = "💰 HARGA RESELLER:"
            else:
                p1 = get_price_ip("1"); p2 = get_price_ip("2")
                p3 = get_price_ip("3"); p5 = get_price_ip("5")
                hrg_title = "💰 DAFTAR HARGA:"
                
            curr_q = get_quota()
            display_q = "Unlimited" if curr_q == "0" else f"{curr_q} GB"
            msg = (
                f"🌐 <b>{server_code}</b>\n"
                f"📍 Lokasi: {country}\n"
                f"📡 ISP: {isp}\n"
                f"⚡ Ping: {ping_ms} ms 🟢\n"
                f"📊 Quota: {display_q}\n"
                f"👥 Total Akun: {current_acc}/{max_limit}\n\n"
                f"<b>{hrg_title}</b>\n"
                f"▪️ 1 IP = Rp {p1} / Hari\n"
                f"▪️ 2 IP = Rp {p2} / Hari\n"
                f"▪️ 3 IP = Rp {p3} / Hari\n"
                f"▪️ 5 IP = Rp {p5} / Hari\n\n"
                f"<i>Silakan pilih Limit IP untuk melanjutkan:</i>"
            )
            keyboard = {
                "inline_keyboard": [
                    [{"text": "📱 1 IP", "callback_data": f"do_{action}_{protocol}_{server_code}_1"},
                     {"text": "📱 2 IP", "callback_data": f"do_{action}_{protocol}_{server_code}_2"}],
                    [{"text": "📱 3 IP", "callback_data": f"do_{action}_{protocol}_{server_code}_3"},
                     {"text": "📱 5 IP", "callback_data": f"do_{action}_{protocol}_{server_code}_5"}],
                    [{"text": "🔙 Kembali", "callback_data": f"menu_{action}_akun"}]
                ]
            }
        else: # trial mode
            msg = (
                f"🌐 <b>{server_code}</b>\n"
                f"📍 Lokasi: {country}\n"
                f"📡 ISP: {isp}\n"
                f"⚡ Ping: {ping_ms} ms 🟢\n"
                f"📊 Quota: 5 GB\n"
                f"👥 Total Akun: {current_acc}/{max_limit}\n\n"
                f"<i>Silakan klik tombol di bawah untuk membuat Trial (Limit 1 IP):</i>"
            )
            keyboard = {
                "inline_keyboard": [
                    [{"text": "🆓 Buat Trial Akun (1 IP)", "callback_data": f"do_{action}_{protocol}_{server_code}_1"}],
                    [{"text": "🔙 Kembali", "callback_data": f"menu_{action}_akun"}]
                ]
            }

        edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)

    elif data.startswith("do_"):
        parts = data.split("_")
        action = parts[1]
        protocol = parts[2].upper()
        server = parts[3]
        iplimit = parts[4] if len(parts) > 4 else "1"
        
        user_id_str = str(user_id)
        db = load_db()
        user_data = get_user(user_id)
        
        if action == "trial":
            limit_str = get_trial_limit()
            today = datetime.now().strftime("%Y-%m-%d")
            
            if user_data.get("last_trial_date") != today:
                user_data["trial_count"] = 0
                user_data["last_trial_date"] = today
                
            current_count = user_data.get("trial_count", 0)
            
            if user_data["role"] not in ["RESELLER", "ADMIN"]:
                if limit_str != "999" and current_count >= int(limit_str):
                    try: requests.post(f"https://api.telegram.org/bot{BOT_TOKEN}/answerCallbackQuery", json={"callback_query_id": callback_query["id"], "text": f"❌ Limit Trial Anda hari ini sudah habis ({limit_str}x).", "show_alert": True}, timeout=3)
                    except: pass
                    return
            
            frames = ["⏳ <i>Sedang memproses trial...</i>", "⌛ <i>Sedang membuat akun...</i>", "⌛ <i>Menyiapkan data server...</i>"]
            for frame in frames:
                edit_message_with_keyboard(chat_id, message_id, frame)
                time.sleep(0.4)
            
            rnd_user = ''.join(random.choices(string.ascii_lowercase + string.digits, k=4))
            rnd_pass = ''.join(random.choices(string.ascii_lowercase + string.digits, k=5))
            
            user = f"tr{protocol.lower()[:2]}{rnd_user}"
            pwd = rnd_pass
            ip_limit = "1"
            kuota_gb = "5"
            exp_date = (datetime.now() + timedelta(days=1)).strftime('%Y-%m-%d')
            durasi_label = get_trial_duration()
            
            os.makedirs('/etc/premdigital/multilogin', exist_ok=True)
            os.makedirs('/etc/premdigital/user_quota', exist_ok=True)
            with open(f'/etc/premdigital/multilogin/{user}', 'w') as f: f.write(str(ip_limit))
            with open(f'/etc/premdigital/user_quota/{user}', 'w') as f: f.write(str(kuota_gb))

            if protocol == "SSH":
                os.system(f'useradd -e {exp_date} -m -s /bin/false -M {user}')
                os.system(f'echo "{user}:{pwd}" | chpasswd')
                msg = (
                    f"<b>✅ AKUN TRIAL SSH BERHASIL DIBUAT</b>\n"
                    f"━━━━━━━━━━━━━━━━━━━━━━\n"
                    f"👤 <b>Username :</b> <code>{user}</code>\n"
                    f"🔑 <b>Password :</b> <code>{pwd}</code>\n"
                    f"🌐 <b>Host/IP  :</b> <code>{DOMAIN}</code>\n"
                    f"⏳ <b>Durasi   :</b> {durasi_label}\n"
                    f"📅 <b>Expired  :</b> {exp_date}\n"
                    f"📱 <b>Limit IP :</b> {ip_limit} Device\n"
                    f"📦 <b>Kuota    :</b> {'Unlimited' if str(kuota_gb) == '0' else str(kuota_gb) + ' GB'}\n"
                    f"━━━━━━━━━━━━━━━━━━━━━━\n"
                    f"<b>🔌 PORT LAYANAN:</b>\n"
                    f"▪️ TLS/SSL  : 443, 8443\n"
                    f"▪️ HTTP/WS  : 80, 8880, 2082\n"
                    f"▪️ OpenSSH  : 22, 2253\n"
                    f"▪️ Dropbear : 109, 143\n"
                    f"▪️ UDPGW    : 7100\n"
                    f"━━━━━━━━━━━━━━━━━━━━━━\n"
                    f"<b>📥 PAYLOAD WEBSOCKET:</b>\n"
                    f"<code>GET / HTTP/1.1[crlf]Host: [host_port][crlf]User-Agent: [ua][crlf]Upgrade: websocket[crlf][crlf]</code>\n"
                    f"━━━━━━━━━━━━━━━━━━━━━━"
                )
            elif protocol == "VMESS":
                user_uuid = str(uuid.uuid4())
                add_xray_client("vmess", user, user_uuid)
                record_xray_db(user, user_uuid, exp_date, "vmess")
                l_tls, l_ntls, l_grpc = generate_vmess_links(user, user_uuid, DOMAIN)
                msg = (
                    f"<b>✅ AKUN TRIAL VMESS BERHASIL DIBUAT</b>\n"
                    f"━━━━━━━━━━━━━━━━━━━━━━\n"
                    f"👤 <b>Username :</b> <code>{user}</code>\n"
                    f"🆔 <b>UUID     :</b> <code>{user_uuid}</code>\n"
                    f"🌐 <b>Host/SNI :</b> <code>{DOMAIN}</code>\n"
                    f"⏳ <b>Durasi   :</b> {durasi_label}\n"
                    f"📅 <b>Expired  :</b> {exp_date}\n"
                    f"📱 <b>Limit IP :</b> {ip_limit} Device\n"
                    f"📦 <b>Kuota    :</b> {'Unlimited' if str(kuota_gb) == '0' else str(kuota_gb) + ' GB'}\n"
                    f"━━━━━━━━━━━━━━━━━━━━━━\n"
                    f"🔒 <b>1. VMESS WS TLS (Port 443):</b>\n<code>{l_tls}</code>\n\n"
                    f"🔓 <b>2. VMESS WS Non-TLS (Port 80):</b>\n<code>{l_ntls}</code>\n\n"
                    f"⚡ <b>3. VMESS gRPC (Port 443):</b>\n<code>{l_grpc}</code>\n"
                    f"━━━━━━━━━━━━━━━━━━━━━━"
                )
            elif protocol == "VLESS":
                user_uuid = str(uuid.uuid4())
                add_xray_client("vless", user, user_uuid)
                record_xray_db(user, user_uuid, exp_date, "vless")
                l_tls, l_ntls, l_grpc = generate_vless_links(user, user_uuid, DOMAIN)
                msg = (
                    f"<b>✅ AKUN TRIAL VLESS BERHASIL DIBUAT</b>\n"
                    f"━━━━━━━━━━━━━━━━━━━━━━\n"
                    f"👤 <b>Username :</b> <code>{user}</code>\n"
                    f"🆔 <b>UUID     :</b> <code>{user_uuid}</code>\n"
                    f"🌐 <b>Host/SNI :</b> <code>{DOMAIN}</code>\n"
                    f"⏳ <b>Durasi   :</b> {durasi_label}\n"
                    f"📅 <b>Expired  :</b> {exp_date}\n"
                    f"📱 <b>Limit IP :</b> {ip_limit} Device\n"
                    f"📦 <b>Kuota    :</b> {'Unlimited' if str(kuota_gb) == '0' else str(kuota_gb) + ' GB'}\n"
                    f"━━━━━━━━━━━━━━━━━━━━━━\n"
                    f"🔒 <b>1. VLESS WS TLS (Port 443):</b>\n<code>{l_tls}</code>\n\n"
                    f"🔓 <b>2. VLESS WS Non-TLS (Port 80):</b>\n<code>{l_ntls}</code>\n\n"
                    f"⚡ <b>3. VLESS gRPC (Port 443):</b>\n<code>{l_grpc}</code>\n"
                    f"━━━━━━━━━━━━━━━━━━━━━━"
                )
            elif protocol == "TROJAN":
                add_xray_client("trojan", user, pwd)
                record_xray_db(user, pwd, exp_date, "trojan")
                l_tls, l_ntls, l_grpc = generate_trojan_links(user, pwd, DOMAIN)
                msg = (
                    f"<b>✅ AKUN TRIAL TROJAN BERHASIL DIBUAT</b>\n"
                    f"━━━━━━━━━━━━━━━━━━━━━━\n"
                    f"👤 <b>Username :</b> <code>{user}</code>\n"
                    f"🔑 <b>Password :</b> <code>{pwd}</code>\n"
                    f"🌐 <b>Host/SNI :</b> <code>{DOMAIN}</code>\n"
                    f"⏳ <b>Durasi   :</b> {durasi_label}\n"
                    f"📅 <b>Expired  :</b> {exp_date}\n"
                    f"📱 <b>Limit IP :</b> {ip_limit} Device\n"
                    f"📦 <b>Kuota    :</b> {'Unlimited' if str(kuota_gb) == '0' else str(kuota_gb) + ' GB'}\n"
                    f"━━━━━━━━━━━━━━━━━━━━━━\n"
                    f"🔒 <b>1. TROJAN WS TLS (Port 443):</b>\n<code>{l_tls}</code>\n\n"
                    f"🔓 <b>2. TROJAN WS Non-TLS (Port 80):</b>\n<code>{l_ntls}</code>\n\n"
                    f"⚡ <b>3. TROJAN gRPC (Port 443):</b>\n<code>{l_grpc}</code>\n"
                    f"━━━━━━━━━━━━━━━━━━━━━━"
                )

            if user_data["role"] not in ["RESELLER", "ADMIN"]:
                user_data["trial_count"] = current_count + 1
                db[user_id_str] = user_data
                save_db(db)
                
            keyboard = {"inline_keyboard": [[{"text": "🔙 Kembali", "callback_data": f"select_{action}_{protocol.lower()}"}]]}
            edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)
            
            MSG_GROUP = (
                f"📢 <b>NOTIFIKASI TRIAL AKUN</b>\n"
                f"━━━━━━━━━━━━━━━━━━━━━━\n"
                f"👤 <b>Pelanggan :</b> <a href='tg://user?id={user_id}'>{first_name}</a>\n"
                f"🛠 <b>Layanan   :</b> {protocol}\n"
                f"⏳ <b>Durasi    :</b> {durasi_label}\n"
                f"📱 <b>Limit IP  :</b> {ip_limit} Device\n"
                f"✅ <b>Status    :</b> Berhasil (Sukses)\n"
                f"━━━━━━━━━━━━━━━━━━━━━━\n"
                f"<i>🚀 Powered by PremDigital AutoBot</i>"
            )
            send_message_with_keyboard(GROUP_TESTI_ID, MSG_GROUP)

        else:
            USER_STATE[user_id] = {'step': 'username', 'server': server, 'protocol': protocol, 'iplimit': iplimit}
            msg = (
                f"📝 <b>PEMBUATAN AKUN {protocol} ({iplimit} IP)</b>\n"
                f"━━━━━━━━━━━━━━━━━━━━━━\n"
                f"Server : <b>{server}</b>\n"
                f"Limit  : <b>{iplimit} Device</b>\n\n"
                f"Silakan masukkan <b>username</b>:\n"
                f"<i>(⚠️ Gunakan huruf kecil & angka saja, tanpa spasi/simbol)</i>"
            )
            keyboard = {"inline_keyboard": [[{"text": "⛔ Batal", "callback_data": "cancel_order"}]]}
            edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)

    elif data == "menu_isi_saldo":
        if user_id in USER_STATE and USER_STATE[user_id].get('step') == 'topup_pending':
            try: requests.post(f"https://api.telegram.org/bot{BOT_TOKEN}/answerCallbackQuery", json={"callback_query_id": callback_query["id"], "text": "⚠️ Anda masih memiliki pengajuan top up yang belum dikonfirmasi Admin. Mohon tunggu.", "show_alert": True}, timeout=3)
            except: pass
            return
            
        USER_STATE[user_id] = {'step': 'topup_nominal'}
        try: requests.post(f"https://api.telegram.org/bot{BOT_TOKEN}/deleteMessage", json={"chat_id": chat_id, "message_id": message_id}, timeout=3)
        except: pass
        
        msg = (
            f"💰 <b>DEPOSIT SALDO (STEP 1)</b>\n"
            f"━━━━━━━━━━━━━━━━━━━━━━\n"
            f"Silakan ketik <b>nominal</b> yang ingin Anda depositkan.\n\n"
            f"<i>Contoh: 20000</i> (Tanpa titik)"
        )
        keyboard = {"inline_keyboard": [[{"text": "⛔ Batal", "callback_data": "back_to_main"}]]}
        send_message_with_keyboard(chat_id, msg, reply_markup=keyboard)

    elif data == "menu_upgrade_reseller":
        user_data = get_user(user_id)
        if user_data["role"] in ["RESELLER", "ADMIN"]:
            msg = f"✅ <b>ANDA SUDAH RESELLER</b>\n━━━━━━━━━━━━━━━━━━━━━━\nStatus Anda saat ini sudah RESELLER / ADMIN.\nNikmati harga khusus dan fitur trial tanpa batas!"
            keyboard = {"inline_keyboard": [[{"text": "🔙 Kembali", "callback_data": "back_to_main"}]]}
            edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)
        else:
            msg = f"🚀 <b>UPGRADE RESELLER</b>\n━━━━━━━━━━━━━━━━━━━━━━\nMenjadi reseller memberikan keuntungan:\n✅ Harga Lebih Murah\n✅ Trial Akun TANPA BATAS\n✅ Prioritas Support\n\n💡 <b>Cara Upgrade:</b>\nSistem akan memotong Saldo Anda sebesar Rp 25.000."
            keyboard = {
                "inline_keyboard": [
                    [{"text": "💸 Bayar Rp 25.000 (Potong Saldo)", "callback_data": "do_upgrade_reseller"}],
                    [{"text": "🔙 Kembali", "callback_data": "back_to_main"}]]
            }
            edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)
            
    elif data == "do_upgrade_reseller":
        db = load_db()
        uid = str(user_id)
        if uid in db:
            if db[uid]["balance"] >= 25000:
                db[uid]["balance"] -= 25000
                db[uid]["role"] = "RESELLER"
                save_db(db)
                try: requests.post(f"https://api.telegram.org/bot{BOT_TOKEN}/answerCallbackQuery", json={"callback_query_id": callback_query["id"], "text": "🎉 SELAMAT! Anda resmi menjadi RESELLER.", "show_alert": True}, timeout=3)
                except: pass
                msg = get_main_menu_text(first_name, user_id)
                keyboard = get_main_menu_keyboard()
                edit_message_with_keyboard(chat_id, message_id, msg, reply_markup=keyboard)
            else:
                try: requests.post(f"https://api.telegram.org/bot{BOT_TOKEN}/answerCallbackQuery", json={"callback_query_id": callback_query["id"], "text": "❌ Saldo tidak cukup! Silakan isi saldo minimal Rp 25.000.", "show_alert": True}, timeout=3)
                except: pass

def process_photo(message_data):
    chat_id = message_data["chat"]["id"]
    first_name = message_data["chat"].get("first_name", "User")
    user_id = message_data["from"]["id"]
    
    photo_file_id = message_data["photo"][-1]["file_id"]
    state = USER_STATE.get(user_id, {})
    nominal = state.get('nominal', 0)
    
    if state.get('step') == 'upload_qris' and str(user_id) == str(OWNER_ID):
        os.makedirs('/etc/premdigital', exist_ok=True)
        with open(QRIS_FILE_ID, 'w') as f:
            f.write(photo_file_id)
        send_message_with_keyboard(chat_id, "✅ <b>FOTO QRIS BERHASIL DISIMPAN!</b>\nSekarang pembeli akan langsung melihat foto ini saat Top Up.")
        del USER_STATE[user_id]
        
        msg_admin = get_admin_menu_text()
        key_admin = get_admin_menu_keyboard()
        send_message_with_keyboard(chat_id, msg_admin, reply_markup=key_admin)
        return

    if state.get('step') == 'topup_pending':
        send_message_with_keyboard(chat_id, "⚠️ <b>Pengajuan Anda sedang diproses.</b>\nMohon tunggu admin memverifikasi struk Anda sebelumnya.")
        return
        
    if state.get('step') == 'awaiting_receipt' and nominal > 0:
        caption = (
            f"🧾 <b>REQUEST PENGAJUAN SALDO</b>\n"
            f"━━━━━━━━━━━━━━━━━━━━━━\n"
            f"👤 <b>Nama   :</b> <a href='tg://user?id={user_id}'>{first_name}</a>\n"
            f"🆔 <b>ID     :</b> <code>{user_id}</code>\n"
            f"💰 <b>Jumlah :</b> Rp {nominal:,}\n\n"
            f"<i>Silakan cek struk di atas. Jika valid, klik Setuju. Jika palsu, klik Tolak.</i>"
        )
        keyboard = {
            "inline_keyboard": [
                [{"text": f"✅ Setuju (Rp {nominal:,})", "callback_data": f"acc_topup_{user_id}_{nominal}"}],
                [{"text": "❌ Tolak", "callback_data": f"rej_topup_{user_id}_{nominal}"}]
            ]
        }
        USER_STATE[user_id]['step'] = 'topup_pending'
    else:
        caption = (
            f"📸 <b>KIRIMAN GAMBAR DARI USER</b>\n"
            f"👤 Dari: <a href='tg://user?id={user_id}'>{first_name}</a>\n"
            f"🆔 ID: <code>{user_id}</code>"
        )
        keyboard = None

    try: requests.post(f"https://api.telegram.org/bot{BOT_TOKEN}/sendPhoto", json={"chat_id": OWNER_ID, "photo": photo_file_id, "caption": caption, "parse_mode": "HTML", "reply_markup": keyboard}, timeout=5)
    except: pass
    
    if state.get('step') != 'upload_qris':
        send_message_with_keyboard(chat_id, "⏳ <b>Struk berhasil dikirim!</b>\nMohon tunggu admin mengecek dan melakukan konfirmasi.")

def process_document(message_data):
    chat_id = message_data["chat"]["id"]
    first_name = message_data["chat"].get("first_name", "User")
    user_id = message_data["from"]["id"]
    doc_file_id = message_data["document"]["file_id"]
    caption = f"📁 <b>KIRIMAN DOKUMEN DARI USER</b>\n👤 Dari: <a href='tg://user?id={user_id}'>{first_name}</a>\n🆔 ID: <code>{user_id}</code>"
    try: requests.post(f"https://api.telegram.org/bot{BOT_TOKEN}/sendDocument", json={"chat_id": OWNER_ID, "document": doc_file_id, "caption": caption, "parse_mode": "HTML"}, timeout=5)
    except: pass
    send_message_with_keyboard(chat_id, "⏳ <b>File berhasil dikirim!</b>\nMohon tunggu admin mengeceknya.")

# ==========================================================
# MESSAGE DISPATCHER & HANDLER
# ==========================================================
def process_message(text, chat_id, first_name, user_id):
    text = text.strip()
    get_user(user_id)
    
    if user_id in USER_STATE and not text.startswith("/"):
        state = USER_STATE[user_id]
        
        if state['step'].startswith('input_price_ip_'):
            if not text.isdigit():
                send_message_with_keyboard(chat_id, "❌ <b>Format salah!</b>\nHarap masukkan angka saja (tanpa titik).")
                return
            ip_target = state['step'].replace('input_price_ip_', '')
            set_price_ip(ip_target, int(text))
            del USER_STATE[user_id]
            send_message_with_keyboard(chat_id, f"✅ Harga User untuk <b>{ip_target} IP</b> berhasil diubah menjadi <b>Rp {text}/hari</b>.\nSilakan tekan /admin untuk kembali.")
            return

        elif state['step'].startswith('input_res_price_'):
            if not text.isdigit():
                send_message_with_keyboard(chat_id, "❌ <b>Format salah!</b>\nHarap masukkan angka saja (tanpa titik).")
                return
            ip_target = state['step'].replace('input_res_price_', '')
            set_reseller_price(ip_target, int(text))
            del USER_STATE[user_id]
            send_message_with_keyboard(chat_id, f"✅ Harga Reseller untuk <b>{ip_target} IP</b> berhasil diubah menjadi <b>Rp {text}/hari</b>.\nSilakan tekan /admin untuk kembali.")
            return

        elif state['step'] == 'input_quota':
            if not text.isdigit():
                send_message_with_keyboard(chat_id, "❌ <b>Format salah!</b>\nHarap masukkan angka saja.")
                return
            set_quota(text)
            del USER_STATE[user_id]
            display_text = "Unlimited" if str(text) == "0" else f"{text} GB"
            send_message_with_keyboard(chat_id, f"✅ Kuota VPN berhasil diubah menjadi <b>{display_text}</b>.\nSilakan tekan /admin untuk kembali.")
            return
            
        elif state['step'] == 'topup_nominal':
            if not text.isdigit():
                send_message_with_keyboard(chat_id, "❌ <b>Format salah!</b>\nHarap masukkan angka saja (tanpa titik).\n\nSilakan ketik nominal deposit:")
                return
            
            nominal = int(text)
            if nominal < 5000:
                send_message_with_keyboard(chat_id, "❌ <b>Minimal deposit adalah Rp 5.000</b>\n\nSilakan ketik ulang nominal deposit:")
                return

            USER_STATE[user_id]['nominal'] = nominal
            USER_STATE[user_id]['step'] = 'awaiting_receipt'
            
            msg = (
                f"💰 <b>DEPOSIT SALDO (STEP 2)</b>\n"
                f"━━━━━━━━━━━━━━━━━━━━━━\n"
                f"Silakan transfer sebesar <b>Rp {nominal:,}</b> ke QRIS di atas.\n\n"
                f"<b>NMID :</b> ID1025412116432\n"
                f"<b>Nama :</b> PREM DIGITAL\n\n"
                f"<i>⚠️ PENTING:\nJika sudah transfer, langsung <b>UPLOAD FOTO STRUK</b> ke dalam chat bot ini. Jangan mengetik apapun lagi sebelum upload struk.</i>"
            )
            keyboard = {"inline_keyboard": [[{"text": "⛔ Batal Top Up", "callback_data": "back_to_main"}]]}
            
            try:
                with open(QRIS_FILE_ID, 'r') as f:
                    qris_target = f.read().strip()
            except:
                send_message_with_keyboard(chat_id, "❌ <b>Admin belum memasang foto QRIS.</b>\nMohon tunggu admin mengatur QRIS terlebih dahulu.", reply_markup=keyboard)
                return

            url_photo = f"https://api.telegram.org/bot{BOT_TOKEN}/sendPhoto"
            payload = {
                "chat_id": chat_id, 
                "photo": qris_target, 
                "caption": msg, 
                "parse_mode": "HTML", 
                "reply_markup": keyboard
            }
            
            try:
                res = requests.post(url_photo, json=payload, timeout=5).json()
                if not res.get("ok"):
                    send_message_with_keyboard(chat_id, "❌ <b>Terjadi kesalahan sistem.</b>\nGambar QRIS yang diupload Admin tidak valid. Harap lapor admin.", reply_markup=keyboard)
            except:
                pass
            return
            
        elif state['step'] == 'awaiting_receipt':
            send_message_with_keyboard(chat_id, "⚠️ <b>Silakan kirim/upload FOTO STRUK bukti transfer.</b>\nBukan berupa teks (Jangan mengetik). Klik icon penjepit kertas lalu pilih foto struk.")
            return

        elif state['step'] == 'upload_qris':
            send_message_with_keyboard(chat_id, "⚠️ <b>Admin, silakan kirim FOTO!</b>\nJangan kirim teks, langsung klik icon penjepit kertas dan kirim fotonya.")
            return

        elif state['step'] == 'topup_pending':
            send_message_with_keyboard(chat_id, "⚠️ <b>Pengajuan Anda sedang diproses.</b>\nMohon tunggu admin memverifikasi struk Anda sebelumnya.")
            return

        elif state['step'] == 'set_server_limit':
            if not text.isdigit():
                send_message_with_keyboard(chat_id, "❌ <b>Format salah!</b>\nHarap masukkan angka saja.\n\nSilakan ketik angka limit maksimal:")
                return
            set_server_limit(text)
            del USER_STATE[user_id]
            send_message_with_keyboard(chat_id, f"✅ Limit maksimal server berhasil diubah menjadi <b>{text}</b> Akun.\nSilakan tekan /admin untuk mengecek menu.")
            return

        elif state['step'] == 'renew_username':
            target_acc = text.strip()
            user_data = get_user(user_id)
            # Search in multilogin or xray-users.db
            found = False
            proto_found = "SSH"
            if os.path.exists(XRAY_DB):
                with open(XRAY_DB, 'r') as f:
                    for line in f:
                        if line.startswith(f"{target_acc} |"):
                            found = True
                            parts = [p.strip() for p in line.split('|')]
                            if len(parts) >= 4: proto_found = parts[3].upper()
                            break
            if not found and os.path.exists(f"/etc/premdigital/multilogin/{target_acc}"):
                found = True
                proto_found = "SSH"
                
            if not found:
                send_message_with_keyboard(chat_id, f"❌ Akun <code>{target_acc}</code> tidak ditemukan di server!\nPastikan username benar.")
                del USER_STATE[user_id]
                return
                
            state['renew_user'] = target_acc
            state['renew_proto'] = proto_found
            state['step'] = 'renew_duration'
            send_message_with_keyboard(chat_id, f"✅ Akun <b>{target_acc}</b> ({proto_found}) ditemukan!\n\nSilakan masukkan jumlah <b>hari perpanjangan</b> (Contoh: 30):")
            return

        elif state['step'] == 'renew_duration':
            if not text.isdigit() or int(text) < 1 or int(text) > 365:
                send_message_with_keyboard(chat_id, "❌ Masukkan angka valid (1 - 365 hari):")
                return
            days = int(text)
            target_acc = state['renew_user']
            proto_found = state['renew_proto']
            user_data = get_user(user_id)
            
            p_hari = get_reseller_price("1") if user_data['role'] in ["RESELLER", "ADMIN"] else get_price_ip("1")
            total_cost = days * p_hari
            
            if user_data['role'] not in ["ADMIN", "OWNER"] and user_data['balance'] < total_cost:
                send_message_with_keyboard(chat_id, f"❌ Saldo tidak cukup!\nTotal: Rp {total_cost:,}\nSaldo: Rp {user_data['balance']:,}\nSilakan top up dulu.")
                del USER_STATE[user_id]
                return
                
            if user_data['role'] not in ["ADMIN", "OWNER"]:
                db = load_db()
                db[str(user_id)]["balance"] -= total_cost
                save_db(db)
                
            new_exp = (datetime.now() + timedelta(days=days)).strftime('%Y-%m-%d')
            if proto_found == "SSH":
                os.system(f"chage -E {new_exp} {target_acc} 2>/dev/null")
            else:
                # Update xray db
                lines = []
                if os.path.exists(XRAY_DB):
                    with open(XRAY_DB, 'r') as f:
                        for line in f:
                            if line.startswith(f"{target_acc} |"):
                                parts = [p.strip() for p in line.split('|')]
                                if len(parts) >= 4:
                                    lines.append(f"{parts[0]} | {parts[1]} | {new_exp} | {parts[3]}\n")
                            else:
                                lines.append(line)
                    with open(XRAY_DB, 'w') as f:
                        f.writelines(lines)
            
            send_message_with_keyboard(chat_id, f"✅ <b>PERPANJANG AKUN BERHASIL!</b>\n━━━━━━━━━━━━━━━━━━━━━━\n👤 Akun : <code>{target_acc}</code>\n🛠 Protokol : {proto_found}\n⏳ Ditambah : {days} Hari\n📅 Expired Baru : <b>{new_exp}</b>\n💰 Terpotong : Rp {total_cost:,}")
            del USER_STATE[user_id]
            return

        elif state['step'] == 'username':
            if text != text.lower() or not text.isalnum():
                send_message_with_keyboard(chat_id, "❌ <b>Username tidak boleh menggunakan huruf kapital atau spasi.</b>\nGunakan huruf kecil dan angka saja.\n\nSilakan masukkan username kembali:")
                return
            state['username'] = text
            protocol = state.get('protocol', 'SSH').upper()
            
            if protocol in ['VMESS', 'VLESS']:
                state['step'] = 'duration'
                send_message_with_keyboard(chat_id, f"✅ <i>Username diterima: <b>{text}</b></i>\n\nSilakan masukkan <b>masa aktif (hari)</b>:\n<i>Contoh: 30</i>")
            else:
                state['step'] = 'password'
                send_message_with_keyboard(chat_id, "✅ <i>Username diterima.</i>\n\nSilakan masukkan <b>password</b>:\n<i>(⚠️ Sama seperti username, huruf kecil & angka saja)</i>")
            return
            
        elif state['step'] == 'password':
            if text != text.lower() or not text.isalnum():
                send_message_with_keyboard(chat_id, "❌ <b>Password tidak boleh menggunakan huruf kapital atau spasi.</b>\nGunakan huruf kecil dan angka saja.\n\nSilakan masukkan password kembali:")
                return
            state['password'] = text
            state['step'] = 'duration'
            send_message_with_keyboard(chat_id, "✅ <i>Password diterima.</i>\n\nSilakan masukkan <b>masa aktif (hari)</b>:\n<i>Contoh: 30</i>")
            return
            
        elif state['step'] == 'duration':
            if not text.isdigit() or int(text) < 1 or int(text) > 365:
                send_message_with_keyboard(chat_id, "❌ <b>Masa aktif tidak valid!</b>\nHarus berupa angka (1 - 365).\n\nSilakan masukkan masa aktif kembali:")
                return
            
            hari = int(text)
            user_data = get_user(user_id)
            iplimit = state.get('iplimit', '1')
            protocol = state.get('protocol', 'SSH').upper()
            
            # Cek Harga berdasar role User/Reseller
            if user_data['role'] in ["RESELLER", "ADMIN"]:
                harga_per_hari = get_reseller_price(iplimit)
            else:
                harga_per_hari = get_price_ip(iplimit)
                
            total_harga = hari * harga_per_hari
            
            if user_data['role'] not in ["ADMIN", "OWNER"] and user_data['balance'] < total_harga:
                send_message_with_keyboard(chat_id, f"❌ <b>Saldo tidak mencukupi!</b>\n\nTotal Harga : Rp {total_harga:,}\nSaldo Anda : Rp {user_data['balance']:,}\n\nSilakan klik /start dan isi saldo terlebih dahulu.")
                del USER_STATE[user_id]
                return
                
            if user_data['role'] not in ["ADMIN", "OWNER"]:
                db = load_db()
                db[str(user_id)]["balance"] -= total_harga
                save_db(db)
                user_data['balance'] -= total_harga
            
            loading_msg_id = send_message_with_keyboard(chat_id, "⏳ <i>Memproses pesanan, mohon tunggu...</i>")
            if loading_msg_id:
                frames = ["⌛ <i>Memproses pesanan, mohon tunggu...</i>", "⏳ <i>Sedang membuat akun...</i>", "⌛ <i>Menyiapkan data server...</i>"]
                for frame in frames:
                    time.sleep(0.4)
                    edit_message_with_keyboard(chat_id, loading_msg_id, frame)
            else:
                time.sleep(1.0)
            
            acc_user = state['username']
            acc_pwd = state.get('password', acc_user)
            ip_limit = iplimit
            kuota_gb = get_quota()
            
            try: exp_date = (datetime.now() + timedelta(days=hari)).strftime('%Y-%m-%d')
            except: exp_date = (datetime.now() + timedelta(days=30)).strftime('%Y-%m-%d')

            os.makedirs('/etc/premdigital/multilogin', exist_ok=True)
            os.makedirs('/etc/premdigital/user_quota', exist_ok=True)
            with open(f'/etc/premdigital/multilogin/{acc_user}', 'w') as f: f.write(str(ip_limit))
            with open(f'/etc/premdigital/user_quota/{acc_user}', 'w') as f: f.write(str(kuota_gb))

            if protocol == "SSH":
                os.system(f'useradd -e {exp_date} -m -s /bin/false -M {acc_user}')
                os.system(f'echo "{acc_user}:{acc_pwd}" | chpasswd')
                MSG = (
                    f"<b>✅ PEMBELIAN AKUN SSH BERHASIL</b>\n"
                    f"━━━━━━━━━━━━━━━━━━━━━━\n"
                    f"👤 <b>Username :</b> <code>{acc_user}</code>\n"
                    f"🔑 <b>Password :</b> <code>{acc_pwd}</code>\n"
                    f"🌐 <b>Host/IP  :</b> <code>{DOMAIN}</code>\n"
                    f"⏳ <b>Durasi   :</b> {hari} Hari\n"
                    f"📅 <b>Expired  :</b> {exp_date}\n"
                    f"📱 <b>Limit IP :</b> {ip_limit} Device\n"
                    f"📦 <b>Kuota    :</b> {'Unlimited' if str(kuota_gb) == '0' else str(kuota_gb) + ' GB'}\n"
                    f"━━━━━━━━━━━━━━━━━━━━━━\n"
                    f"💰 <b>Harga    :</b> Rp {total_harga:,}\n"
                    f"💳 <b>Sisa Saldo:</b> Rp {user_data['balance']:,}\n"
                    f"━━━━━━━━━━━━━━━━━━━━━━\n"
                    f"<b>🔌 PORT LAYANAN:</b>\n"
                    f"▪️ TLS/SSL  : 443, 8443\n"
                    f"▪️ HTTP/WS  : 80, 8880, 2082\n"
                    f"▪️ OpenSSH  : 22, 2253\n"
                    f"▪️ Dropbear : 109, 143\n"
                    f"▪️ UDPGW    : 7100\n"
                    f"━━━━━━━━━━━━━━━━━━━━━━\n"
                    f"<b>📥 PAYLOAD WEBSOCKET:</b>\n"
                    f"<code>GET / HTTP/1.1[crlf]Host: [host_port][crlf]User-Agent: [ua][crlf]Upgrade: websocket[crlf][crlf]</code>\n"
                    f"━━━━━━━━━━━━━━━━━━━━━━"
                )
            elif protocol == "VMESS":
                user_uuid = str(uuid.uuid4())
                add_xray_client("vmess", acc_user, user_uuid)
                record_xray_db(acc_user, user_uuid, exp_date, "vmess")
                l_tls, l_ntls, l_grpc = generate_vmess_links(acc_user, user_uuid, DOMAIN)
                MSG = (
                    f"<b>✅ PEMBELIAN AKUN VMESS BERHASIL</b>\n"
                    f"━━━━━━━━━━━━━━━━━━━━━━\n"
                    f"👤 <b>Username :</b> <code>{acc_user}</code>\n"
                    f"🆔 <b>UUID     :</b> <code>{user_uuid}</code>\n"
                    f"🌐 <b>Host/SNI :</b> <code>{DOMAIN}</code>\n"
                    f"⏳ <b>Durasi   :</b> {hari} Hari\n"
                    f"📅 <b>Expired  :</b> {exp_date}\n"
                    f"📱 <b>Limit IP :</b> {ip_limit} Device\n"
                    f"📦 <b>Kuota    :</b> {'Unlimited' if str(kuota_gb) == '0' else str(kuota_gb) + ' GB'}\n"
                    f"━━━━━━━━━━━━━━━━━━━━━━\n"
                    f"💰 <b>Harga    :</b> Rp {total_harga:,}\n"
                    f"💳 <b>Sisa Saldo:</b> Rp {user_data['balance']:,}\n"
                    f"━━━━━━━━━━━━━━━━━━━━━━\n"
                    f"🔒 <b>1. VMESS WS TLS (Port 443):</b>\n<code>{l_tls}</code>\n\n"
                    f"🔓 <b>2. VMESS WS Non-TLS (Port 80):</b>\n<code>{l_ntls}</code>\n\n"
                    f"⚡ <b>3. VMESS gRPC (Port 443):</b>\n<code>{l_grpc}</code>\n"
                    f"━━━━━━━━━━━━━━━━━━━━━━"
                )
            elif protocol == "VLESS":
                user_uuid = str(uuid.uuid4())
                add_xray_client("vless", acc_user, user_uuid)
                record_xray_db(acc_user, user_uuid, exp_date, "vless")
                l_tls, l_ntls, l_grpc = generate_vless_links(acc_user, user_uuid, DOMAIN)
                MSG = (
                    f"<b>✅ PEMBELIAN AKUN VLESS BERHASIL</b>\n"
                    f"━━━━━━━━━━━━━━━━━━━━━━\n"
                    f"👤 <b>Username :</b> <code>{acc_user}</code>\n"
                    f"🆔 <b>UUID     :</b> <code>{user_uuid}</code>\n"
                    f"🌐 <b>Host/SNI :</b> <code>{DOMAIN}</code>\n"
                    f"⏳ <b>Durasi   :</b> {hari} Hari\n"
                    f"📅 <b>Expired  :</b> {exp_date}\n"
                    f"📱 <b>Limit IP :</b> {ip_limit} Device\n"
                    f"📦 <b>Kuota    :</b> {'Unlimited' if str(kuota_gb) == '0' else str(kuota_gb) + ' GB'}\n"
                    f"━━━━━━━━━━━━━━━━━━━━━━\n"
                    f"💰 <b>Harga    :</b> Rp {total_harga:,}\n"
                    f"💳 <b>Sisa Saldo:</b> Rp {user_data['balance']:,}\n"
                    f"━━━━━━━━━━━━━━━━━━━━━━\n"
                    f"🔒 <b>1. VLESS WS TLS (Port 443):</b>\n<code>{l_tls}</code>\n\n"
                    f"🔓 <b>2. VLESS WS Non-TLS (Port 80):</b>\n<code>{l_ntls}</code>\n\n"
                    f"⚡ <b>3. VLESS gRPC (Port 443):</b>\n<code>{l_grpc}</code>\n"
                    f"━━━━━━━━━━━━━━━━━━━━━━"
                )
            elif protocol == "TROJAN":
                add_xray_client("trojan", acc_user, acc_pwd)
                record_xray_db(acc_user, acc_pwd, exp_date, "trojan")
                l_tls, l_ntls, l_grpc = generate_trojan_links(acc_user, acc_pwd, DOMAIN)
                MSG = (
                    f"<b>✅ PEMBELIAN AKUN TROJAN BERHASIL</b>\n"
                    f"━━━━━━━━━━━━━━━━━━━━━━\n"
                    f"👤 <b>Username :</b> <code>{acc_user}</code>\n"
                    f"🔑 <b>Password :</b> <code>{acc_pwd}</code>\n"
                    f"🌐 <b>Host/SNI :</b> <code>{DOMAIN}</code>\n"
                    f"⏳ <b>Durasi   :</b> {hari} Hari\n"
                    f"📅 <b>Expired  :</b> {exp_date}\n"
                    f"📱 <b>Limit IP :</b> {ip_limit} Device\n"
                    f"📦 <b>Kuota    :</b> {'Unlimited' if str(kuota_gb) == '0' else str(kuota_gb) + ' GB'}\n"
                    f"━━━━━━━━━━━━━━━━━━━━━━\n"
                    f"💰 <b>Harga    :</b> Rp {total_harga:,}\n"
                    f"💳 <b>Sisa Saldo:</b> Rp {user_data['balance']:,}\n"
                    f"━━━━━━━━━━━━━━━━━━━━━━\n"
                    f"🔒 <b>1. TROJAN WS TLS (Port 443):</b>\n<code>{l_tls}</code>\n\n"
                    f"🔓 <b>2. TROJAN WS Non-TLS (Port 80):</b>\n<code>{l_ntls}</code>\n\n"
                    f"⚡ <b>3. TROJAN gRPC (Port 443):</b>\n<code>{l_grpc}</code>\n"
                    f"━━━━━━━━━━━━━━━━━━━━━━"
                )

            # Simpan riwayat akun ke db user
            db = load_db()
            uid_str = str(user_id)
            if uid_str in db:
                db[uid_str].setdefault("accounts", []).append({
                    "username": acc_user,
                    "protocol": protocol,
                    "exp_date": exp_date,
                    "created_at": datetime.now().strftime("%Y-%m-%d %H:%M")
                })
                save_db(db)

            if loading_msg_id: edit_message_with_keyboard(chat_id, loading_msg_id, MSG)
            else: send_message_with_keyboard(chat_id, MSG)
            
            MSG_GROUP = (
                f"📢 <b>NOTIFIKASI ORDER AKUN</b>\n"
                f"━━━━━━━━━━━━━━━━━━━━━━\n"
                f"👤 <b>Pelanggan :</b> <a href='tg://user?id={user_id}'>{first_name}</a>\n"
                f"🛠 <b>Layanan   :</b> {protocol}\n"
                f"⏳ <b>Durasi    :</b> {hari} Hari\n"
                f"📱 <b>Limit IP  :</b> {ip_limit} Device\n"
                f"✅ <b>Status    :</b> Berhasil (Sukses)\n"
                f"━━━━━━━━━━━━━━━━━━━━━━\n"
                f"<i>🚀 Powered by PremDigital AutoBot</i>"
            )
            send_message_with_keyboard(GROUP_TESTI_ID, MSG_GROUP)
            
            del USER_STATE[user_id]
            return

    if text.startswith("/"):
        if user_id in USER_STATE and USER_STATE[user_id].get('step') != 'topup_pending':
            del USER_STATE[user_id]
            
        if text.startswith("/start") or text.startswith("/help") or text.lower() == "/menu":
            msg = get_main_menu_text(first_name, user_id)
            keyboard = get_main_menu_keyboard()
            send_message_with_keyboard(chat_id, msg, reply_markup=keyboard)
            
        elif text.startswith("/admin"):
            if str(user_id) == str(OWNER_ID):
                msg = get_admin_menu_text()
                keyboard = get_admin_menu_keyboard()
                send_message_with_keyboard(chat_id, msg, reply_markup=keyboard)
            else:
                send_message_with_keyboard(chat_id, "⛔ <b>Akses Ditolak!</b> Anda bukan Administrator.")
                
        elif text.startswith("/addsaldo"):
            if str(user_id) == str(OWNER_ID):
                parts = text.split()
                if len(parts) == 3:
                    target_id = parts[1]
                    amount_str = parts[2]
                elif len(parts) == 2:
                    target_id = str(user_id)
                    amount_str = parts[1]
                else:
                    send_message_with_keyboard(chat_id, "❌ Format salah!\nGunakan: <code>/addsaldo [ID_USER] [JUMLAH]</code>\nAtau isi saldo sendiri: <code>/addsaldo [JUMLAH]</code>")
                    return
                    
                try:
                    amount = int(amount_str)
                    db = load_db()
                    if target_id in db:
                        db[target_id]["balance"] += amount
                        save_db(db)
                        if target_id == str(user_id):
                            send_message_with_keyboard(chat_id, f"✅ Sukses menambah saldo sebesar <b>Rp {amount:,}</b> ke akun Anda sendiri.")
                        else:
                            send_message_with_keyboard(chat_id, f"✅ Berhasil menambah saldo <b>Rp {amount:,}</b> ke ID <code>{target_id}</code>")
                            send_message_with_keyboard(target_id, f"💰 <b>SALDO MASUK!</b>\nAdmin telah menambahkan saldo sebesar <b>Rp {amount:,}</b> ke akun Anda.")
                    else:
                        send_message_with_keyboard(chat_id, "❌ ID User tidak ditemukan di database.")
                except:
                    send_message_with_keyboard(chat_id, "❌ Format salah. Jumlah harus berupa angka tanpa titik.")

        elif text.startswith("/addreseller"):
            if str(user_id) == str(OWNER_ID):
                parts = text.split()
                if len(parts) == 2:
                    target_id = parts[1]
                    db = load_db()
                    if target_id in db:
                        db[target_id]["role"] = "RESELLER"
                        save_db(db)
                        send_message_with_keyboard(chat_id, f"✅ Sukses! User <code>{target_id}</code> sekarang adalah <b>RESELLER</b>.")
                        send_message_with_keyboard(target_id, f"🎉 <b>SELAMAT!</b>\nAdmin telah menaikkan status Anda menjadi <b>RESELLER</b>.\nSekarang Anda mendapatkan harga khusus yang lebih murah!")
                    else:
                        send_message_with_keyboard(chat_id, "❌ ID User tidak ditemukan (User belum pernah start bot).")
                else: send_message_with_keyboard(chat_id, "❌ Format: <code>/addreseller [ID_USER]</code>")
                
        elif text.startswith("/delreseller"):
            if str(user_id) == str(OWNER_ID):
                parts = text.split()
                if len(parts) == 2:
                    target_id = parts[1]
                    db = load_db()
                    if target_id in db:
                        db[target_id]["role"] = "USER"
                        save_db(db)
                        send_message_with_keyboard(chat_id, f"✅ Sukses! Status Reseller untuk <code>{target_id}</code> telah dicabut.")
                        send_message_with_keyboard(target_id, f"⚠️ <b>INFORMASI</b>\nStatus Reseller Anda telah dicabut oleh Admin. Status Anda sekarang kembali menjadi User Reguler.")
                    else:
                        send_message_with_keyboard(chat_id, "❌ ID User tidak ditemukan di database.")
                else: send_message_with_keyboard(chat_id, "❌ Format: <code>/delreseller [ID_USER]</code>")
                    
        elif text.startswith("/bc"):
            if str(user_id) == str(OWNER_ID):
                pesan = text.replace("/bc ", "")
                if pesan and pesan != "/bc":
                    db = load_db()
                    sukses = 0
                    for uid in db.keys():
                        try:
                            send_message_with_keyboard(uid, f"📢 <b>BROADCAST ADMIN</b>\n━━━━━━━━━━━━━━━━━━━━━━\n{pesan}")
                            sukses += 1
                            time.sleep(0.1)
                        except: pass
                    send_message_with_keyboard(chat_id, f"✅ Broadcast selesai dikirim ke {sukses} user.")
                else: send_message_with_keyboard(chat_id, "❌ Format: <code>/bc [PESAN ANDA]</code>")

def setup_bot_menu():
    url = f"https://api.telegram.org/bot{BOT_TOKEN}/setMyCommands"
    commands = {"commands": [{"command": "start", "description": "Tampilkan Main Menu"}, {"command": "admin", "description": "Admin PDI"}]}
    try: requests.post(url, json=commands, timeout=5)
    except: pass

setup_bot_menu()

while True:
    try:
        req = requests.get(f"https://api.telegram.org/bot{BOT_TOKEN}/getUpdates?offset={LAST_UPDATE_ID}", timeout=5)
        data = req.json()
        for result in data.get("result", []):
            LAST_UPDATE_ID = result["update_id"] + 1
            if "callback_query" in result:
                process_callback(result["callback_query"])
            elif "message" in result:
                if "photo" in result["message"]:
                    process_photo(result["message"])
                elif "document" in result["message"]:
                    process_document(result["message"])
                else:
                    chat_id = result["message"]["chat"]["id"]
                    text = result["message"].get("text", "")
                    first_name = result["message"]["chat"].get("first_name", "User")
                    user_id = result["message"]["from"]["id"]
                    if text: process_message(text, chat_id, first_name, user_id)
    except Exception as e:
        pass
    time.sleep(2)
