#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# HamadaOS — Rescue Menu
# ═══════════════════════════════════════════════════════════════════════════════
# Runs automatically in the Safe Mode session; also reachable from the
# launcher ("safe mode" / "recovery"). Every option is reversible.
# ═══════════════════════════════════════════════════════════════════════════════

set -uo pipefail
SCRIPTS="$HOME/.config/hypr/scripts"
CFG="$HOME/.config"

while :; do
    clear
    cat <<'MENU'
═══════════════════════════════════════════════════════
   HamadaOS Rescue — pick a number
═══════════════════════════════════════════════════════

  1) Check & auto-fix everything        (doctor --fix)
  2) Export logs for help               (tar.gz on Desktop)
  3) Disable Hyprland plugins           (if title bars crash the session)
  4) Reset shell settings to defaults   (keeps a backup)
  5) Re-link all configs                (repairs broken/missing symlinks)
  6) Restore previous system snapshot   (guided snapper rollback)
  7) Update everything                  (often the actual fix)
  8) Open a plain terminal
  9) Reboot
  0) Exit menu

MENU
    read -rp "  > " choice
    case "$choice" in
    1)  "$SCRIPTS/hamadaos-doctor.sh" --fix; read -rp "Enter to continue…" ;;
    2)
        OUT="$HOME/Desktop/hamadaos-logs-$(date +%Y%m%d-%H%M).tar.gz"
        mkdir -p "$HOME/Desktop" /tmp/hamadaos-logs
        journalctl --user -b --no-pager > /tmp/hamadaos-logs/journal-user.log 2>/dev/null
        journalctl -b -p warning --no-pager > /tmp/hamadaos-logs/journal-system.log 2>/dev/null
        hyprctl rollinglog > /tmp/hamadaos-logs/hyprland.log 2>/dev/null || \
            cp "$XDG_RUNTIME_DIR"/hypr/*/hyprland.log /tmp/hamadaos-logs/ 2>/dev/null
        "$SCRIPTS/hamadaos-doctor.sh" > /tmp/hamadaos-logs/doctor.txt 2>&1
        cp "$CFG/hamadaos/hardware.env" /tmp/hamadaos-logs/ 2>/dev/null
        tar -czf "$OUT" -C /tmp hamadaos-logs && rm -rf /tmp/hamadaos-logs
        echo "  → $OUT  (attach this when asking for help)"
        read -rp "Enter to continue…" ;;
    3)
        if [[ -e "$CFG/hypr/plugins.conf" ]]; then
            mv "$CFG/hypr/plugins.conf" "$CFG/hypr/plugins.conf.disabled"
            : > "$CFG/hypr/plugins.conf"
            echo "  Plugins disabled. Re-enable: mv plugins.conf.disabled plugins.conf"
        else
            echo "  plugins.conf not found."
        fi
        read -rp "Enter to continue…" ;;
    4)
        if [[ -f "$CFG/hamadaos/config.json" ]]; then
            mv "$CFG/hamadaos/config.json" "$CFG/hamadaos/config.json.bak-$(date +%s)"
            echo "  Shell settings reset (backup kept in ~/.config/hamadaos/)."
        fi
        read -rp "Enter to continue…" ;;
    5)
        REPO="$(dirname "$(readlink -f "$CFG/hypr/userprefs.conf" 2>/dev/null)" 2>/dev/null)"
        REPO="${REPO%/config/hypr}"
        if [[ -x "$REPO/install.sh" ]]; then
            HAMADAOS_LINKS_ONLY=1 bash "$REPO/install.sh"
        else
            echo "  Could not locate the hamadaos-dots repo."
        fi
        read -rp "Enter to continue…" ;;
    6)
        echo ""
        echo "  Recent system snapshots (newest last):"
        sudo snapper -c root list 2>/dev/null | tail -8 || {
            echo "  snapper not configured — snapshots unavailable."
            read -rp "Enter to continue…"; continue
        }
        echo ""
        echo "  To roll the SYSTEM back to snapshot N:   sudo snapper -c root rollback N"
        echo "  then reboot. Your personal files in /home are NOT affected."
        read -rp "Enter to continue…" ;;
    7)  "$SCRIPTS/hamadaos-update.sh" --apply ;;
    8)  bash ;;
    9)  systemctl reboot ;;
    0)  exit 0 ;;
    esac
done
