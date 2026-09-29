#!/bin/bash
clear
GREEN='\e[32m'
BLUE='\e[36m'
YELLOW='\e[33m'
CYAN='\e[36m'
RED='\e[31m'
NC='\e[0m'

echo -e "${BLUE}====================================================${NC}"
echo -e "${GREEN}          UPDATE SCRIPT PREMDIGITAL TUNNEL          ${NC}"
echo -e "${BLUE}====================================================${NC}"
echo -e " Script ini akan memperbarui semua file script di VPS"
echo -e " langsung dari GitHub Repository Publik."
echo -e "${BLUE}====================================================${NC}"

REPO_OWNER="tomm508"
REPO_NAME="premdigitaltunnel-v2"
BRANCH="main"
BASE_RAW="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${BRANCH}"

echo -e "\n${YELLOW}[1/4] Mengunduh arsip script terbaru dari GitHub...${NC}"
TMP_TAR="/tmp/script-vps-update.tar.gz"
rm -f "$TMP_TAR"

# Unduh tarball repo publik langsung
curl -fsSL "https://github.com/${REPO_OWNER}/${REPO_NAME}/archive/refs/heads/${BRANCH}.tar.gz" -o "$TMP_TAR" 2>/dev/null || \
wget -qO "$TMP_TAR" "https://github.com/${REPO_OWNER}/${REPO_NAME}/archive/refs/heads/${BRANCH}.tar.gz" 2>/dev/null

UPDATED=0
if [ -s "$TMP_TAR" ]; then
    echo -e "${GREEN}[OK] Berhasil mengunduh kode terbaru.${NC}"
    echo -e "${YELLOW}[2/4] Mengekstrak file dan memperbarui /vps-scripts...${NC}"
    TMP_DIR=$(mktemp -d)
    if tar -xzf "$TMP_TAR" -C "$TMP_DIR" 2>/dev/null; then
        EXTRACTED_DIR=$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)
        if [ -d "$EXTRACTED_DIR/vps-scripts" ]; then
            mkdir -p /vps-scripts
            cp -rf "$EXTRACTED_DIR/vps-scripts/"* /vps-scripts/
            [ -f "$EXTRACTED_DIR/install.sh" ] && cp -f "$EXTRACTED_DIR/install.sh" /root/install.sh
            UPDATED=1
        fi
    fi
    rm -rf "$TMP_DIR" "$TMP_TAR"
fi

# Fallback: jika tarball gagal diunduh atau diekstrak, download langsung file per file via raw github
if [ "$UPDATED" -eq 0 ]; then
    echo -e "${YELLOW}[INFO] Mengunduh langsung file script dari GitHub Raw...${NC}"
    mkdir -p /vps-scripts
    SCRIPTS=(
        "add-ssh.sh" "del-ssh.sh" "add-vmess.sh" "add-vless.sh" "add-trojan.sh"
        "list-account.sh" "del-account.sh" "menu.sh" "update.sh" "uninstall.sh"
        "cek-service.sh" "limit-ip.py" "limit-ip-menu.sh" "limit-ip.sh"
        "setup-limit-ip.sh" "load-balancer-menu.sh" "setup-haproxy-lb.sh"
        "migrate.sh" "auto-kill-expired.sh" "optimize-speed.sh"
        "premdigital_creator.py" "ws-openssh.py" "setup-xray.sh"
    )
    for s in "${SCRIPTS[@]}"; do
        curl -fsSL "${BASE_RAW}/vps-scripts/${s}" -o "/vps-scripts/${s}" 2>/dev/null || \
        wget -qO "/vps-scripts/${s}" "${BASE_RAW}/vps-scripts/${s}" 2>/dev/null
    done
    curl -fsSL "${BASE_RAW}/install.sh" -o "/root/install.sh" 2>/dev/null || true
    echo -e "${GREEN}[OK] File script berhasil diunduh.${NC}"
fi

echo -e "${YELLOW}[3/4] Menerapkan izin eksekusi & symlink bin...${NC}"
chmod +x /vps-scripts/*.sh 2>/dev/null || true
chmod +x /vps-scripts/*.py 2>/dev/null || true

# Salin script utama ke PATH sistem (/usr/bin dan /usr/local/bin)
[ -f /vps-scripts/menu.sh ] && cp -f /vps-scripts/menu.sh /usr/local/bin/menu && cp -f /vps-scripts/menu.sh /usr/bin/menu && chmod +x /usr/local/bin/menu /usr/bin/menu
[ -f /vps-scripts/update.sh ] && cp -f /vps-scripts/update.sh /usr/local/bin/update-script && chmod +x /usr/local/bin/update-script
[ -f /vps-scripts/ws-openssh.py ] && cp -f /vps-scripts/ws-openssh.py /usr/local/bin/ws-openssh && chmod +x /usr/local/bin/ws-openssh
[ -f /vps-scripts/limit-ip.py ] && cp -f /vps-scripts/limit-ip.py /usr/local/bin/limit-ip.py && chmod +x /usr/local/bin/limit-ip.py
[ -f /vps-scripts/limit-ip-menu.sh ] && cp -f /vps-scripts/limit-ip-menu.sh /usr/local/bin/limit-ip-menu && chmod +x /usr/local/bin/limit-ip-menu
[ -f /vps-scripts/limit-ip.sh ] && cp -f /vps-scripts/limit-ip.sh /usr/local/bin/limit-ip && cp -f /vps-scripts/limit-ip.sh /usr/bin/limit-ip && chmod +x /usr/local/bin/limit-ip /usr/bin/limit-ip
[ -f /vps-scripts/load-balancer-menu.sh ] && cp -f /vps-scripts/load-balancer-menu.sh /usr/local/bin/load-balancer-menu && chmod +x /usr/local/bin/load-balancer-menu
[ -f /vps-scripts/migrate.sh ] && cp -f /vps-scripts/migrate.sh /usr/local/bin/migrate && chmod +x /usr/local/bin/migrate
[ -f /vps-scripts/auto-kill-expired.sh ] && cp -f /vps-scripts/auto-kill-expired.sh /usr/local/bin/auto-kill-expired && cp -f /vps-scripts/auto-kill-expired.sh /usr/bin/auto-kill-expired && chmod +x /usr/local/bin/auto-kill-expired /usr/bin/auto-kill-expired
[ -f /vps-scripts/cek-service.sh ] && cp -f /vps-scripts/cek-service.sh /usr/bin/cek-service && chmod +x /usr/bin/cek-service
[ -f /vps-scripts/list-account.sh ] && cp -f /vps-scripts/list-account.sh /usr/bin/list-account && chmod +x /usr/bin/list-account
[ -f /vps-scripts/add-ssh.sh ] && cp -f /vps-scripts/add-ssh.sh /usr/bin/add-ssh && chmod +x /usr/bin/add-ssh
[ -f /vps-scripts/del-ssh.sh ] && cp -f /vps-scripts/del-ssh.sh /usr/bin/del-ssh && chmod +x /usr/bin/del-ssh
[ -f /vps-scripts/add-vmess.sh ] && cp -f /vps-scripts/add-vmess.sh /usr/bin/add-vmess && chmod +x /usr/bin/add-vmess
[ -f /vps-scripts/add-vless.sh ] && cp -f /vps-scripts/add-vless.sh /usr/bin/add-vless && chmod +x /usr/bin/add-vless
[ -f /vps-scripts/add-trojan.sh ] && cp -f /vps-scripts/add-trojan.sh /usr/bin/add-trojan && chmod +x /usr/bin/add-trojan
[ -f /vps-scripts/del-account.sh ] && cp -f /vps-scripts/del-account.sh /usr/bin/del-account && chmod +x /usr/bin/del-account

[ -f /vps-scripts/optimize-speed.sh ] && bash /vps-scripts/optimize-speed.sh 2>/dev/null || true

echo -e "${YELLOW}[4/4] Merestart service terkait...${NC}"
systemctl restart ws-openssh 2>/dev/null || true
systemctl restart dropbear 2>/dev/null || true
systemctl restart stunnel4 2>/dev/null || true

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${GREEN}        UPDATE SCRIPT SELESAI DENGAN SUKSES!        ${NC}"
echo -e "${BLUE}====================================================${NC}"
echo -e " Semua file script dan service di VPS telah diperbarui"
echo -e " ke versi terbaru dari GitHub Repository."
echo -e "${BLUE}====================================================${NC}"
echo ""
read -n 1 -s -r -p "Tekan Enter Untuk Kembali Ke Menu Utama..."
menu
