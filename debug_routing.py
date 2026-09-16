# The user's screenshot shows:
# 301 Moved Permanently
# 400 Bad Request
# Server menutup koneksi.
# This means traffic is hitting Xray on 443, which falls back to Nginx on 80.
# Nginx on 80 sees a weird request, returns 301 or 400, and drops it.
# It is NOT reaching our Python script!
# To fix this, we need to bypass Nginx entirely, OR configure Nginx to proxy EVERYTHING to 10080 blindly.
import os

print("The 301 error means Nginx is intercepting the traffic instead of passing it to Python.")
