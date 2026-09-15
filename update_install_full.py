with open("/app/applet/install.sh", "r") as f:
    content = f.read()

# Replace the ws-openssh setup block in install.sh to use the clean script
old_section_start = "# INSTALL PYSW (PYTHON SSH WEBSOCKET)"
old_section_end = "systemctl restart ws-openssh"

start_idx = content.find(old_section_start)
end_idx = content.find(old_section_end)

if start_idx != -1 and end_idx != -1:
    end_idx += len(old_section_end)
    new_section = """# INSTALL PYSW (PYTHON SSH WEBSOCKET)
# ==========================================
echo -e "\\e[33m[INFO] Menginstal Python SSH Websocket (Port 80)...\\e[0m"
apt-get install -y python3
wget -qO /usr/local/bin/ws-openssh "${REPO_URL}/vps-scripts/ws-openssh.py"
chmod +x /usr/local/bin/ws-openssh

cat > /etc/systemd/system/ws-openssh.service << 'END_WS_SVC'
[Unit]
Description=Python SSH Websocket Port 80
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 /usr/local/bin/ws-openssh
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
END_WS_SVC

systemctl daemon-reload
systemctl enable ws-openssh >/dev/null 2>&1
systemctl restart ws-openssh"""
    content = content[:start_idx] + new_section + content[end_idx:]
    with open("/app/applet/install.sh", "w") as f:
        f.write(content)
    print("install.sh successfully updated with ws-openssh.py")
else:
    print("Indices not found in install.sh")
