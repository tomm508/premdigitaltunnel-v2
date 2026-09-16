import glob

for filename in ["/app/applet/install.sh", "/app/applet/patch_vps.sh"]:
    try:
        with open(filename, "r") as f:
            content = f.read()
            
        # Fix ws-openssh port
        if "connect = 127.0.0.1:80" in content:
            content = content.replace("connect = 127.0.0.1:80", "connect = 127.0.0.1:10080")
            
        # If it was patched to 10080 already, fix the accept port to 8443 and 2053
        content = content.replace("accept = 443\nconnect = 127.0.0.1:10080", "accept = 8443\nconnect = 127.0.0.1:10080")
        content = content.replace("accept = 445\nconnect = 127.0.0.1:10080", "accept = 8443\nconnect = 127.0.0.1:10080")
        content = content.replace("accept = 8443\nconnect = 127.0.0.1:109", "accept = 2053\nconnect = 127.0.0.1:109")
        content = content.replace("accept = 447\nconnect = 127.0.0.1:109", "accept = 2053\nconnect = 127.0.0.1:109")
        
        # fix ws-openssh installation to replace LISTENING_PORT = 80 -> 10080 inside install.sh
        if 'sed -i "s/LISTENING_PORT = 80/LISTENING_PORT = 10080/g" /usr/local/bin/ws-openssh' not in content:
            content = content.replace("chmod +x /usr/local/bin/ws-openssh", 'chmod +x /usr/local/bin/ws-openssh\nsed -i "s/LISTENING_PORT = 80/LISTENING_PORT = 10080/g" /usr/local/bin/ws-openssh')
            
        with open(filename, "w") as f:
            f.write(content)
        print(f"Patched {filename}")
    except Exception as e:
        print(e)
