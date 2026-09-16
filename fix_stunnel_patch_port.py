import glob

for filename in ["/app/applet/install.sh", "/app/applet/patch_vps.sh"]:
    try:
        with open(filename, "r") as f:
            content = f.read()
            
        content = content.replace("Memastikan Port Stunnel4 Aktif di 443 & 8443", "Memastikan Port Stunnel4 Aktif di 445 & 447")
        
        with open(filename, "w") as f:
            f.write(content)
    except Exception as e:
        print(e)
print("done")
