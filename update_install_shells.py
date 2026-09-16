with open("/app/applet/install.sh", "r") as f:
    content = f.read()

shell_fix = """
# Fix Dropbear shell issue untuk user /bin/false
if ! grep -q "/bin/false" /etc/shells; then
    echo "/bin/false" >> /etc/shells
fi

systemctl restart ssh sshd dropbear 2>/dev/null
"""

content = content.replace("systemctl restart ssh sshd dropbear 2>/dev/null\n", shell_fix)

with open("/app/applet/install.sh", "w") as f:
    f.write(content)
print("install.sh patched with /bin/false fix")
