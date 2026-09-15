import os
import re

path = "/app/applet/vps-scripts/menu.sh"
with open(path, "r") as f:
    content = f.read()

# Fix untuk Menu 5 yang melompati fungsi list-account.sh sebelumnya
target_5 = """    5) 
        clear
        echo -e "${BLUE}=== Akun SSH/WS ===${NC}"
        awk -F: '($3>=1000)&&($1!="nobody"){print $1}' /etc/passwd | grep -v 'ubuntu'
        echo -e "\\n${BLUE}=== Akun Xray ===${NC}"
        bash /vps-scripts/list-account.sh
        ;;"""

replacement_5 = """    5) 
        bash /vps-scripts/list-account.sh
        ;;"""

if target_5 in content:
    content = content.replace(target_5, replacement_5)
    with open(path, "w") as f:
        f.write(content)
    print("Fixed menu 5")
else:
    print("Menu 5 target not found")
