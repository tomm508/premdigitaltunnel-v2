with open('/app/applet/vps-scripts/ws-openssh.py') as f:
    code = f.read()

print("Current ws-openssh.py lines:")
for i, line in enumerate(code.split('\n'), 1):
    if 'RESPONSE' in line or 'connect_target' in line or 'do_proxy' in line or 'run' in line or 'sendall' in line:
        print(f"{i}: {line}")
