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
echo -e " Script ini akan memperbarui script di VPS langsung"
echo -e " dari repository Private GitHub Anda."
echo -e "${BLUE}====================================================${NC}"

REPO_OWNER="tomm508"
REPO_NAME="premdigitaltunnel-v2"
TOKEN_FILE="/root/.github_token"

if [ -f "$TOKEN_FILE" ]; then
    GH_TOKEN=$(cat "$TOKEN_FILE")
fi

echo -e "\n${YELLOW}[1/4] Mengunduh arsip script terbaru dari GitHub...${NC}"
TMP_TAR="/tmp/script-vps-update.tar.gz"
AUTH_HEADER=""
[ -n "$GH_TOKEN" ] && AUTH_HEADER="-H Authorization: Bearer $GH_TOKEN"

HTTP_CODE=$(curl -sL -w "%{http_code}" $AUTH_HEADER \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/tarball/main" \
    -o "$TMP_TAR")

if [ "$HTTP_CODE" != "200" ]; then
    # Fallback direct raw tarball jika tanpa token
    curl -sL "https://github.com/${REPO_OWNER}/${REPO_NAME}/archive/refs/heads/main.tar.gz" -o "$TMP_TAR"
    if [ ! -s "$TMP_TAR" ]; then
        echo -e "${RED}[GAGAL] Gagal mengunduh repo (HTTP $HTTP_CODE).${NC}"
        rm -f "$TMP_TAR"
        exit 1
    fi
fi

echo -e "${GREEN}[OK] Berhasil mengunduh kode terbaru.${NC}"

echo -e "${YELLOW}[2/4] Mengekstrak file dan memperbarui /vps-scripts...${NC}"
TMP_DIR=$(mktemp -d)
tar -xzf "$TMP_TAR" -C "$TMP_DIR"
EXTRACTED_DIR=$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)

if [ -d "$EXTRACTED_DIR/vps-scripts" ]; then
    mkdir -p /vps-scripts
    cp -rf "$EXTRACTED_DIR/vps-scripts/"* /vps-scripts/
    [ -f "$EXTRACTED_DIR/install.sh" ] && cp -f "$EXTRACTED_DIR/install.sh" /root/install.sh
fi

rm -rf "$TMP_DIR" "$TMP_TAR"

echo -e "${YELLOW}[3/4] Menerapkan izin eksekusi & symlink bin...${NC}"
chmod +x /vps-scripts/*.sh 2>/dev/null
chmod +x /vps-scripts/*.py 2>/dev/null

[ -f /vps-scripts/menu.sh ] && cp -f /vps-scripts/menu.sh /usr/local/bin/menu && cp -f /vps-scripts/menu.sh /usr/bin/menu
[ -f /vps-scripts/ws-openssh.py ] && cp -f /vps-scripts/ws-openssh.py /usr/local/bin/ws-openssh && chmod +x /usr/local/bin/ws-openssh
[ -f /vps-scripts/limit-ip.py ] && cp -f /vps-scripts/limit-ip.py /usr/local/bin/limit-ip.py && chmod +x /usr/local/bin/limit-ip.py
[ -f /vps-scripts/auto-kill-expired.sh ] && cp -f /vps-scripts/auto-kill-expired.sh /usr/local/bin/auto-kill-expired && chmod +x /usr/local/bin/auto-kill-expired
[ -f /vps-scripts/optimize-speed.sh ] && bash /vps-scripts/optimize-speed.sh

# Pastikan update-script ada di /usr/local/bin/update-script
cp -f /vps-scripts/update.sh /usr/local/bin/update-script 2>/dev/null
chmod +x /usr/local/bin/update-script 2>/dev/null

echo -e "${YELLOW}[4/4] Merestart service terkait...${NC}"
systemctl restart ws-openssh 2>/dev/null || true
systemctl restart dropbear 2>/dev/null || true
systemctl restart stunnel4 2>/dev/null || true

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${GREEN}        UPDATE SCRIPT SELESAI DENGAN SUKSES!        ${NC}"
echo -e "${BLUE}====================================================${NC}"
echo -e " Semua file script dan service di VPS telah diperbarui"
echo -e " ke versi terbaru dari GitHub Private Repository."
echo -e "${BLUE}====================================================${NC}"
