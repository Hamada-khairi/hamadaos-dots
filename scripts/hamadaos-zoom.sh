#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# HamadaOS — ZoomIt (screen zoom, Sysinternals-style)
# ═══════════════════════════════════════════════════════════════════════════════
#   in / out   — smooth multiplicative steps (hold the key: binde repeats)
#   toggle     — jump 1.0 ↔ 2.0 like ZoomIt's Ctrl+1
#   reset      — back to 1.0
# Uses Hyprland's GPU cursor-zoom: zero overhead, follows the mouse.
# Drawing on screen (ZoomIt's Ctrl+2) is gromit-mpx — see keybindings.conf.
# ═══════════════════════════════════════════════════════════════════════════════

set -uo pipefail

cur() { hyprctl getoption cursor:zoom_factor -j 2>/dev/null | jq -r '.float // 1'; }
set_zoom() {
    local z="$1"
    awk -v z="$z" 'BEGIN { if (z < 1) z = 1; if (z > 5) z = 5; print z }' | {
        read -r clamped
        hyprctl keyword cursor:zoom_factor "$clamped" >/dev/null
    }
}

Z="$(cur)"
case "${1:-toggle}" in
    in)     set_zoom "$(awk -v z="$Z" 'BEGIN { print z * 1.2 }')" ;;
    out)    set_zoom "$(awk -v z="$Z" 'BEGIN { print z / 1.2 }')" ;;
    reset)  set_zoom 1 ;;
    toggle)
        if awk -v z="$Z" 'BEGIN { exit !(z > 1.01) }'; then
            set_zoom 1
        else
            set_zoom 2
        fi
        ;;
esac
