#!/usr/bin/env python3
# ==========================================
# PremDigital - Multi-Login IP Limiter & AutoKill Engine
# Supports: OpenSSH, Dropbear, WebSocket WS, and Xray (Vmess/Vless/Trojan)
# ==========================================

import os
import sys
import re
import json
import time
import subprocess
import datetime
from collections import defaultdict

CONF_PATH = "/etc/premdigital/limit-ip.conf"
LOG_PATH = "/var/log/limit-ip.log"
STATUS_PATH = "/run/premdigital_limit_status.json"
WS_SESSIONS_FILE = "/run/premdigital_ws_sessions.json"
XRAY_LOG = "/var/log/xray/access.log"

DEFAULT_CONFIG = {
    "MAX_IP": 2,
    "AUTOKILL": 1,
    "NOTIF_LOG": 1
}

def load_config():
    cfg = dict(DEFAULT_CONFIG)
    if os.path.exists(CONF_PATH):
        try:
            with open(CONF_PATH, "r") as f:
                for line in f:
                    line = line.strip()
                    if "=" in line and not line.startswith("#"):
                        k, v = line.split("=", 1)
                        k = k.strip()
                        v = v.strip().strip('"').strip("'")
                        if k in cfg:
                            try:
                                cfg[k] = int(v)
                            except ValueError:
                                cfg[k] = v
        except Exception:
            pass
    return cfg

def save_config(cfg):
    os.makedirs(os.path.dirname(CONF_PATH), exist_ok=True)
    with open(CONF_PATH, "w") as f:
        f.write("# PremDigital AutoKill Limit IP Configuration\n")
        f.write(f"MAX_IP={cfg.get('MAX_IP', 2)}\n")
        f.write(f"AUTOKILL={cfg.get('AUTOKILL', 1)}\n")
        f.write(f"NOTIF_LOG={cfg.get('NOTIF_LOG', 1)}\n")

def log_event(message):
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    formatted = f"[{timestamp}] {message}\n"
    os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
    try:
        with open(LOG_PATH, "a") as f:
            f.write(formatted)
    except Exception:
        pass
    print(formatted.strip())

def get_ws_session_map():
    if os.path.exists(WS_SESSIONS_FILE):
        try:
            with open(WS_SESSIONS_FILE, "r") as f:
                return json.load(f)
        except Exception:
            return {}
    return {}

def scan_ssh_logins():
    """
    Scans active OpenSSH and Dropbear logins.
    Returns: dict user -> { "ips": set(), "pids": list(), "type": "ssh" }
    """
    ws_map = get_ws_session_map()
    user_data = defaultdict(lambda: {"ips": set(), "pids": [], "type": "ssh"})

    # 1. Parse 'who' command
    try:
        proc = subprocess.run(["who"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        for line in proc.stdout.splitlines():
            line = line.strip()
            if not line:
                continue
            parts = line.split()
            if len(parts) >= 5:
                uname = parts[0]
                if uname == "root":
                    continue
                ip_match = re.search(r'\((.*?)\)', line)
                if ip_match:
                    raw_ip = ip_match.group(1).strip()
                    if raw_ip and raw_ip != "127.0.0.1" and raw_ip != "localhost":
                        user_data[uname]["ips"].add(raw_ip)
    except Exception:
        pass

    # 2. Parse OpenSSH processes via ps
    try:
        proc = subprocess.run(
            ["ps", "-eo", "user,pid,args"],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
        )
        for line in proc.stdout.splitlines():
            # Matches 'sshd: username@pts/X' or 'sshd: username [priv]'
            match = re.search(r'sshd:\s+([a-zA-Z0-9_\-\.]+)(?:@|\[)', line)
            if match:
                uname = match.group(1).strip()
                if uname not in ["root", "sshd"]:
                    pid_match = re.search(r'^\s*(\S+)\s+(\d+)', line)
                    if pid_match:
                        pid = pid_match.group(2)
                        user_data[uname]["pids"].append(pid)
    except Exception:
        pass

    # 3. Correlate open sockets for Dropbear and OpenSSH
    try:
        proc = subprocess.run(
            ["ss", "-tnp"],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
        )
        for line in proc.stdout.splitlines():
            if ("dropbear" in line or "sshd" in line) and "ESTAB" in line:
                # Example: ESTAB ... 127.0.0.1:22 127.0.0.1:45123 users:(("sshd",pid=1234,fd=3))
                # or:      ESTAB ... 159.65.10.28:22 180.252.1.2:54321 users:(("sshd",pid=1234,fd=3))
                pid_match = re.search(r'pid=(\d+)', line)
                if not pid_match:
                    continue
                pid = pid_match.group(1)

                # Find which user owns this PID
                u_proc = subprocess.run(["ps", "-o", "user=", "-p", pid], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
                uname = u_proc.stdout.strip()
                if not uname or uname in ["root", "sshd"]:
                    continue

                # Find remote IP
                parts = line.split()
                if len(parts) >= 5:
                    remote_addr = parts[4]
                    if ":" in remote_addr:
                        r_ip, r_port = remote_addr.rsplit(":", 1)
                        if r_ip in ["127.0.0.1", "localhost"]:
                            # Look up in WebSocket session map
                            if r_port in ws_map:
                                real_client = ws_map[r_port].get("client_ip")
                                if real_client and real_client != "127.0.0.1":
                                    user_data[uname]["ips"].add(real_client)
                        else:
                            user_data[uname]["ips"].add(r_ip)
                user_data[uname]["pids"].append(pid)
    except Exception:
        pass

    return user_data

def scan_xray_logins(window_seconds=30):
    """
    Scans recent /var/log/xray/access.log entries for active Vmess, Vless, Trojan connections.
    Hanya menghitung koneksi yang benar-benar aktif dalam 30 detik terakhir untuk mencegah false-positive saat penggunaan berat/streaming.
    """
    user_data = defaultdict(lambda: {"ips": set(), "proto": "xray", "type": "xray"})
    if not os.path.exists(XRAY_LOG):
        return user_data

    try:
        # Read last 300 lines of xray access log
        proc = subprocess.run(["tail", "-n", "300", XRAY_LOG], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        lines = proc.stdout.splitlines()

        now = time.time()
        for line in lines:
            line = line.strip()
            if not line or "accepted" not in line or "email:" not in line:
                continue

            # Check timestamp (Format: YYYY/MM/DD HH:MM:SS)
            parts = line.split()
            if len(parts) >= 2:
                try:
                    time_str = f"{parts[0]} {parts[1]}"
                    log_dt = datetime.datetime.strptime(time_str, "%Y/%m/%d %H:%M:%S")
                    log_ts = log_dt.timestamp()
                    if (now - log_ts) > window_seconds:
                        continue
                except Exception:
                    pass

            # Extract user & protocol
            match = re.search(r'([0-9a-fA-F\.:]+):\d+\s+accepted\s+\S+\s+\[(\w+)\]\s+email:\s+(\S+)', line)
            if match:
                client_ip = match.group(1).strip()
                proto = match.group(2).strip()
                username = match.group(3).strip()

                # Clean client IP (strip IPv6 wrapper if present)
                client_ip = client_ip.replace("[", "").replace("]", "")
                if client_ip in ["127.0.0.1", "localhost"]:
                    continue

                user_data[username]["ips"].add(client_ip)
                user_data[username]["proto"] = proto
    except Exception:
        pass

    return user_data

def perform_check_and_kill(dry_run=False):
    cfg = load_config()
    max_ip = cfg.get("MAX_IP", 2)
    autokill = cfg.get("AUTOKILL", 1)

    ssh_users = scan_ssh_logins()
    xray_users = scan_xray_logins()

    all_users = {}
    violations = []

    # Process SSH Users
    for u, data in ssh_users.items():
        ip_list = sorted(list(data["ips"]))
        count = len(ip_list)
        all_users[u] = {
            "type": "SSH/WS",
            "ips": ip_list,
            "count": count,
            "max": max_ip,
            "violation": count > max_ip
        }
        if count > max_ip:
            violations.append((u, "SSH/WS", ip_list, data.get("pids", [])))

    # Process Xray Users
    for u, data in xray_users.items():
        ip_list = sorted(list(data["ips"]))
        count = len(ip_list)
        proto = data.get("proto", "xray").upper()
        all_users[f"{u} ({proto})"] = {
            "type": proto,
            "ips": ip_list,
            "count": count,
            "max": max_ip,
            "violation": count > max_ip
        }
        if count > max_ip:
            violations.append((u, proto, ip_list, []))

    # Write Status File for CLI / Web display
    status_payload = {
        "timestamp": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "max_ip": max_ip,
        "autokill_active": bool(autokill),
        "total_active_users": len(all_users),
        "total_violations": len(violations),
        "users": all_users
    }
    try:
        with open(STATUS_PATH, "w") as f:
            json.dump(status_payload, f, indent=2)
    except Exception:
        pass

    # Handle Violations
    if violations and autokill and not dry_run:
        need_xray_restart = False
        for username, u_type, ips, pids in violations:
            log_event(
                f"[AUTOKILL-TRIGGERED] User '{username}' ({u_type}) melebihi batas {max_ip} IP! "
                f"Terdeteksi {len(ips)} IP: {', '.join(ips)}"
            )

            if "SSH" in u_type:
                # Terminate SSH process
                try:
                    subprocess.run(["pkill", "-9", "-u", username], check=False)
                    for p in pids:
                        subprocess.run(["kill", "-9", p], check=False)
                    log_event(f"[SUCCESS] Sesi SSH/WS '{username}' berhasil diputus paksa.")
                except Exception as e:
                    log_event(f"[ERROR] Gagal memutus sesi SSH '{username}': {e}")
            else:
                # Untuk Xray: Catat pelanggaran tanpa me-restart service global agar user lain tidak terputus
                log_event(f"[WARNING] Akun Xray '{username}' melanggar batas IP. Pelanggaran dicatat ke sistem.")

    return status_payload

def main():
    if len(sys.argv) > 1:
        cmd = sys.argv[1]
        if cmd == "--check":
            res = perform_check_and_kill(dry_run=True)
            print("\n" + "="*55)
            print(f" HASIL PEMERIKSAAN LOGIN AKTIF (Maks: {res['max_ip']} IP)")
            print("="*55)
            if not res["users"]:
                print(" Tidak ada user yang sedang terkoneksi saat ini.")
            else:
                for uname, info in res["users"].items():
                    color_tag = "[VIOLASI!]" if info["violation"] else "[OK]"
                    print(f" User   : {uname} [{info['type']}]")
                    print(f" Status : {color_tag} {info['count']}/{info['max']} IP")
                    print(f" IP     : {', '.join(info['ips']) if info['ips'] else 'Localhost'}")
                    print("-" * 55)
            print(f"Total Pelanggaran: {res['total_violations']}")
            print("="*55 + "\n")
            return

        elif cmd == "--kill":
            perform_check_and_kill(dry_run=False)
            return

        elif cmd == "--json":
            res = perform_check_and_kill(dry_run=True)
            print(json.dumps(res, indent=2))
            return

        elif cmd == "--set-max":
            if len(sys.argv) > 2 and sys.argv[2].isdigit():
                val = int(sys.argv[2])
                cfg = load_config()
                cfg["MAX_IP"] = val
                save_config(cfg)
                print(f"[OK] Batas Max Login berhasil diubah menjadi: {val} IP")
            else:
                print("[ERROR] Masukkan angka valid. Contoh: --set-max 2")
            return

        elif cmd == "--enable":
            cfg = load_config()
            cfg["AUTOKILL"] = 1
            save_config(cfg)
            print("[OK] AutoKill Multi-Login BERHASIL DIAKTIFKAN.")
            return

        elif cmd == "--disable":
            cfg = load_config()
            cfg["AUTOKILL"] = 0
            save_config(cfg)
            print("[OK] AutoKill Multi-Login BERHASIL DINONAKTIFKAN.")
            return

    # Default run
    perform_check_and_kill(dry_run=False)

if __name__ == "__main__":
    main()
