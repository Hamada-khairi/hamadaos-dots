#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# HamadaOS — Night Light Toggle (Super+Shift+B)
# ═══════════════════════════════════════════════════════════════════════════════
# Goes through Quickshell when it's running (keeps the Settings toggle and
# saved state in sync), falls back to raw hyprsunset IPC otherwise.
# ═══════════════════════════════════════════════════════════════════════════════

set -uo pipefail

if qs ipc call hamadaos toggleNightLight 2>/dev/null; then
    exit 0
fi

# Fallback: drive hyprsunset directly via Hyprland IPC.
STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/hamadaos-nightlight"
if [[ -f "$STATE_FILE" ]]; then
    hyprctl hyprsunset identity >/dev/null
    rm -f "$STATE_FILE"
    notify-send -a "HamadaOS" -t 2000 "Night Light OFF" 2>/dev/null || true
else
    hyprctl hyprsunset temperature 3500 >/dev/null
    touch "$STATE_FILE"
    notify-send -a "HamadaOS" -t 2000 "Night Light ON" "3500K" 2>/dev/null || true
fi
