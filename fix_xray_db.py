import os

files_to_fix = [
    "/app/applet/vps-scripts/add-vmess.sh",
    "/app/applet/vps-scripts/add-vless.sh",
    "/app/applet/vps-scripts/add-trojan.sh"
]

for script_path in files_to_fix:
    with open(script_path, "r") as f:
        content = f.read()

    # Pastikan direktori database xray terbuat
    db_setup = """# Pastikan folder database ada
mkdir -p /etc/premdigital
touch /etc/premdigital/xray-users.db
"""

    if "# Pastikan folder database ada" not in content:
        # Masukkan setelah baris ========================================== kedua (setelah header)
        parts = content.split("==========================================\\e[0m\"")
        if len(parts) >= 2:
            new_content = parts[0] + "==========================================\\e[0m\"\n\n" + db_setup + parts[1]
            if len(parts) > 2:
                for i in range(2, len(parts)):
                    new_content += "==========================================\\e[0m\"" + parts[i]
            content = new_content

    # Tambahkan pencatatan ke database xray-users.db
    if "vmess" in script_path.lower():
        record_cmd = """
# Simpan ke Database
echo "${user} | ${uuid} | ${exp} | vmess" >> /etc/premdigital/xray-users.db
"""
    elif "vless" in script_path.lower():
        record_cmd = """
# Simpan ke Database
echo "${user} | ${uuid} | ${exp} | vless" >> /etc/premdigital/xray-users.db
"""
    elif "trojan" in script_path.lower():
        record_cmd = """
# Simpan ke Database
echo "${user} | ${password} | ${exp} | trojan" >> /etc/premdigital/xray-users.db
"""

    if "# Simpan ke Database" not in content:
        # Masukkan sebelum sistem merestart xray
        content = content.replace("systemctl restart xray", record_cmd + "systemctl restart xray")
    
    with open(script_path, "w") as f:
        f.write(content)

print("Database recording added to all Xray scripts")
