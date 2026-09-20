import urllib.request
import json
import subprocess
import time
import os
import datetime
import uuid

def is_valid_uuid(val):
    try:
        uuid.UUID(str(val))
        return True
    except:
        return False

def load_config():
    config = {
        "PROJECT_ID": os.environ.get("FIREBASE_PROJECT_ID", "premdigital-vpn"),
        "API_KEY": os.environ.get("FIREBASE_API_KEY", ""),
        "SERVER_ID": "sg-premium-01"
    }
    if os.path.exists("/root/node_config.txt"):
        with open("/root/node_config.txt") as f:
            for line in f:
                line = line.strip()
                if "=" in line and not line.startswith("#"):
                    k, v = line.split("=", 1)
                    k = k.strip()
                    v = v.strip().strip('"').strip("'")
                    if k == "NODE_ID":
                        config["SERVER_ID"] = v
                    elif k in ["PROJECT_ID", "API_KEY"]:
                        config[k] = v
    return config

CONF = load_config()
PROJECT_ID = CONF["PROJECT_ID"]
API_KEY = CONF["API_KEY"]
SERVER_ID = CONF["SERVER_ID"]

BASE_URL = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents"

print(f"[PREMDIGITAL-CREATOR] Dimulai untuk Node: {SERVER_ID} (Project: {PROJECT_ID})")

def get_pending_commands():
    url = f"{BASE_URL}/vps_commands?key={API_KEY}&pageSize=50"
    try:
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req, timeout=10) as response:
            res_data = json.loads(response.read().decode())
            commands = []
            for doc in res_data.get('documents', []):
                doc_id = doc['name'].split('/')[-1]
                fields = doc.get('fields', {})
                sid = fields.get('serverId', {}).get('stringValue', '')
                status = fields.get('status', {}).get('stringValue', '')
                
                if sid == SERVER_ID and status == 'pending':
                    commands.append({
                        "id": doc_id,
                        "username": fields.get('username', {}).get('stringValue', ''),
                        "password": fields.get('password', {}).get('stringValue', ''),
                        "protocol": fields.get('protocol', {}).get('stringValue', 'ssh').lower(),
                        "uuid": fields.get('uuid', {}).get('stringValue', ''),
                        "activeDays": int(fields.get('activeDays', {}).get('integerValue', 30))
                    })
            return commands
    except Exception as e:
        print("[ERROR] Fetching commands:", e)
        return []

def update_command_status(doc_id, status, message=""):
    patch_url = f"{BASE_URL}/vps_commands/{doc_id}?updateMask.fieldPaths=status&updateMask.fieldPaths=message&key={API_KEY}"
    payload = {
        "fields": {
            "status": {"stringValue": status},
            "message": {"stringValue": message}
        }
    }
    try:
        req = urllib.request.Request(patch_url, data=json.dumps(payload).encode('utf-8'), headers={'Content-Type': 'application/json'}, method='PATCH')
        with urllib.request.urlopen(req, timeout=10) as response:
            pass
    except Exception as e:
        print("[ERROR] Updating status:", e)

def create_ssh(username, password, days):
    if not username or not password:
        return False, "Username atau password kosong"
    try:
        exp_date = (datetime.date.today() + datetime.timedelta(days=int(days))).strftime("%Y-%m-%d")
        check = subprocess.run(f"id {username}", shell=True, capture_output=True, text=True)
        if check.returncode == 0:
            subprocess.run(f"usermod -e {exp_date} -s /bin/false {username}", shell=True, check=True)
        else:
            subprocess.run(f"useradd -e {exp_date} -s /bin/false -M {username}", shell=True, check=True)
        subprocess.run(f'echo "{username}:{password}" | chpasswd', shell=True, check=True)
        return True, f"Akun SSH {username} aktif s/d {exp_date}"
    except Exception as e:
        return False, str(e)

def create_xray(protocol, username, password, user_uuid, days):
    config_path = "/etc/xray/config.json"
    if not os.path.exists(config_path):
        return False, f"File config Xray tidak ditemukan di {config_path}"
    try:
        exp_date = (datetime.date.today() + datetime.timedelta(days=int(days))).strftime("%Y-%m-%d")
        final_uuid = user_uuid if (user_uuid and is_valid_uuid(user_uuid)) else str(uuid.uuid4())
        
        with open(config_path, "r") as f:
            data = json.load(f)
            
        inbounds = data.get("inbounds", [])
        added = False
        for ib in inbounds:
            proto = ib.get("protocol", "").lower()
            if proto == protocol.lower():
                settings = ib.setdefault("settings", {})
                clients = settings.setdefault("clients", [])
                clients = [c for c in clients if c.get("email") != username]
                if protocol.lower() == "trojan":
                    clients.append({"password": password or final_uuid, "email": username})
                elif protocol.lower() == "vmess":
                    clients.append({"id": final_uuid, "alterId": 0, "email": username})
                elif protocol.lower() == "vless":
                    clients.append({"id": final_uuid, "email": username})
                settings["clients"] = clients
                added = True
                
        if not added:
            return False, f"Inbound {protocol} tidak ditemukan di config Xray"
            
        with open(config_path, "w") as f:
            json.dump(data, f, indent=2)
            
        os.makedirs("/etc/premdigital", exist_ok=True)
        with open("/etc/premdigital/xray-users.db", "a") as f:
            f.write(f"{username} | {final_uuid} | {exp_date} | {protocol}\n")
            
        subprocess.run("systemctl restart xray", shell=True)
        return True, f"Akun {protocol.upper()} {username} aktif s/d {exp_date}"
    except Exception as e:
        return False, str(e)

while True:
    commands = get_pending_commands()
    for cmd in commands:
        proto = cmd['protocol']
        u = cmd['username']
        p = cmd['password']
        days = cmd['activeDays']
        print(f"[MEMPROSES] {proto.upper()} untuk user '{u}' ({days} hari)...")
        
        if proto in ["ssh", "websocket"]:
            success, msg = create_ssh(u, p, days)
        elif proto in ["vmess", "vless", "trojan"]:
            success, msg = create_xray(proto, u, p, cmd['uuid'], days)
        else:
            success, msg = False, f"Protokol {proto} tidak dikenal"
            
        if success:
            print(f"[SUKSES] {msg}")
            update_command_status(cmd['id'], 'success', msg)
        else:
            print(f"[GAGAL] {msg}")
            update_command_status(cmd['id'], 'error', msg)
            
    time.sleep(5)
