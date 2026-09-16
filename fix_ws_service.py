import glob

for filename in ["/app/applet/install.sh", "/app/applet/patch_vps.sh"]:
    try:
        with open(filename, "r") as f:
            content = f.read()
            
        if "ExecStart=/usr/bin/python3 /usr/local/bin/ws-openssh" in content:
            print("Found ExecStart in", filename)
    except Exception:
        pass
