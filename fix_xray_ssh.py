# Buat script websocket baru yang jalan di port lain (misal 10080)
# supaya Nginx/Xray tetap jalan di 80, dan Stunnel forward ke 10080
import glob

for filename in ["/app/applet/install.sh", "/app/applet/patch_vps.sh"]:
    try:
        with open(filename, "r") as f:
            content = f.read()
            
        # Ubah port ws-openssh dari 80 ke 10080
        content = content.replace("connect = 127.0.0.1:80", "connect = 127.0.0.1:10080")
        
        with open(filename, "w") as f:
            f.write(content)
        print(f"Patched {filename}")
    except Exception as e:
        print(e)
