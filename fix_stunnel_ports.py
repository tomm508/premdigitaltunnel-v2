import glob

for filename in ["/app/applet/install.sh", "/app/applet/patch_vps.sh"]:
    try:
        with open(filename, "r") as f:
            content = f.read()
            
        # Fix stunnel port 443 -> 445, 8443 -> 447
        content = content.replace("accept = 443\nconnect = 127.0.0.1:80", "accept = 445\nconnect = 127.0.0.1:80")
        content = content.replace("accept = 8443\nconnect = 127.0.0.1:109", "accept = 447\nconnect = 127.0.0.1:109")
        
        with open(filename, "w") as f:
            f.write(content)
        print(f"Patched {filename}")
    except Exception as e:
        print(e)
