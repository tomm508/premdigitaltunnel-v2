# Ah, I misunderstood. The user used Orange Cloud ONLY with the reference script, 
# but for THEIR script, they want to use Grey Cloud (DNS only) and the standard setup.
# Reverting the installer patch back to the standard Stunnel ports (443 & 8443) 
# and moving ws-openssh back to a safe internal port (10080) so it doesn't clash with Nginx.

import glob

for filename in ["/app/applet/install.sh", "/app/applet/patch_vps.sh"]:
    try:
        with open(filename, "r") as f:
            content = f.read()
            
        # Revert Stunnel accept ports back to normal (443 and 8443)
        # But keep the connect for WS to 10080 to avoid Nginx clash
        content = content.replace("accept = 8443\nconnect = 127.0.0.1:10080", "accept = 443\nconnect = 127.0.0.1:10080")
        content = content.replace("accept = 2053\nconnect = 127.0.0.1:109", "accept = 8443\nconnect = 127.0.0.1:109")
        
        with open(filename, "w") as f:
            f.write(content)
        print(f"Patched back {filename}")
    except Exception as e:
        print(e)
