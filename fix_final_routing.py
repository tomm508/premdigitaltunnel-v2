# The user says the HTTP Custom log is STILL the same (403/400).
# This means Stunnel is still NOT pointing to our new 10080 port OR it's still being intercepted by Xray.
import os

# Let's write a shell script to forcefully overwrite stunnel.conf and restart it,
# just to be absolutely sure the routing is correct.
with open("fix_stunnel.sh", "w") as f:
    f.write("""#!/bin/bash
cat > /etc/stunnel/stunnel.conf << 'END_STUNNEL'
cert = /etc/xray/xray.crt
key = /etc/xray/xray.key
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[ws-stunnel]
accept = 445
connect = 127.0.0.1:10080

[dropbear-stunnel]
accept = 447
connect = 127.0.0.1:109
END_STUNNEL

systemctl restart stunnel4
echo "Stunnel restarted and forced to point to 10080."
""")
print("Script ready.")
