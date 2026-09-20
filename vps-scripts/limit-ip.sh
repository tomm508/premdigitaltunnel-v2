#!/bin/bash
# Shortcut to PremDigital Limit IP Menu / Engine
PY_ENGINE="/usr/local/bin/limit-ip.py"
[ ! -f "$PY_ENGINE" ] && PY_ENGINE="/vps-scripts/limit-ip.py"
[ ! -f "$PY_ENGINE" ] && PY_ENGINE="$(pwd)/vps-scripts/limit-ip.py"

if [ "$1" == "--check" ] || [ "$1" == "--kill" ] || [ "$1" == "--json" ] || [ "$1" == "--enable" ] || [ "$1" == "--disable" ] || [ "$1" == "--set-max" ]; then
    python3 "$PY_ENGINE" "$@"
else
    MENU_SCRIPT="/usr/local/bin/limit-ip-menu"
    [ ! -f "$MENU_SCRIPT" ] && MENU_SCRIPT="/vps-scripts/limit-ip-menu.sh"
    [ ! -f "$MENU_SCRIPT" ] && MENU_SCRIPT="$(pwd)/vps-scripts/limit-ip-menu.sh"
    bash "$MENU_SCRIPT"
fi
