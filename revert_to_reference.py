import glob

# Karena port 80 dan 443 di VPS Anda dipegang oleh Xray, 
# kita akan menggunakan script WS-Proxy murni dari referensi Anda, 
# TAPI kita biarkan Xray jalan, dan WS-Proxy ini berjalan di port 10080 untuk HTTP dan 445 untuk SSL.

print("Done preparing plan.")
