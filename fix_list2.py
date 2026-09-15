import os

path = "/app/applet/vps-scripts/list-account.sh"
with open(path, "r") as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    if line.startswith("-e "):
        continue
    if "Tekan [Enter] untuk kembali..." in line:
        continue
    new_lines.append(line)

with open(path, "w") as f:
    f.writelines(new_lines)

print("Fixed list-account part 2")
