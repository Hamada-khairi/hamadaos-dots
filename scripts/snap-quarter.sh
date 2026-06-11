#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# HamadaOS — Quarter-Screen Window Snapping (FancyZones equivalent)
# ═══════════════════════════════════════════════════════════════════════════════
# Snaps the active window to a quarter of the monitor.
# Works on FLOATING windows (HamadaOS default) by using resizeactive + moveactive.
#
# Usage: snap-quarter.sh <direction>
#   directions: topleft, topright, bottomleft, bottomright, left, right, top, bottom
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

DIRECTION="${1:-}"
if [[ -z "$DIRECTION" ]]; then
    echo "Usage: snap-quarter.sh <topleft|topright|bottomleft|bottomright|left|right|top|bottom>"
    exit 1
fi

# ── Read monitor dimensions from Hyprland ──────────────────────────────────────
MONITOR_JSON="$(hyprctl monitors -j 2>/dev/null)" || {
    echo "[Snap] Error: could not read monitor info from hyprctl."
    exit 1
}

# Find the focused monitor
MONITOR="$(echo "$MONITOR_JSON" | jq -r '.[] | select(.focused == true)')"
if [[ -z "$MONITOR" || "$MONITOR" == "null" ]]; then
    MONITOR="$(echo "$MONITOR_JSON" | jq -r '.[0]')"
fi

# Logical (scaled) dimensions — moveactive/resizeactive use logical pixels.
MON_SCALE="$(echo "$MONITOR" | jq -r '.scale // 1.0')"
MON_WIDTH="$(echo "$MONITOR" | jq -r "(.width / $MON_SCALE) | floor")"
MON_HEIGHT="$(echo "$MONITOR" | jq -r "(.height / $MON_SCALE) | floor")"
MON_X="$(echo "$MONITOR" | jq -r '.x // 0')"
MON_Y="$(echo "$MONITOR" | jq -r '.y // 0')"

# Account for bar (40px) — subtract from usable height
BAR_OFFSET=40
HALF_W="$(( MON_WIDTH / 2 ))"
HALF_H="$(( (MON_HEIGHT - BAR_OFFSET) / 2 ))"

# ── Ensure floating WITHOUT toggling an already-floating window back to tiled ──
IS_FLOATING="$(hyprctl activewindow -j 2>/dev/null | jq -r '.floating // false')"
[[ "$IS_FLOATING" == "false" ]] && hyprctl dispatch setfloating active 2>/dev/null || true

case "$DIRECTION" in
    # ── Half-screen snaps ────────────────────────────────────────────────────
    left)
        hyprctl dispatch moveactive exact "$MON_X" "$MON_Y"
        hyprctl dispatch resizeactive exact "$HALF_W" "$MON_HEIGHT"
        ;;
    right)
        hyprctl dispatch moveactive exact "$((MON_X + HALF_W))" "$MON_Y"
        hyprctl dispatch resizeactive exact "$HALF_W" "$MON_HEIGHT"
        ;;
    top)
        hyprctl dispatch moveactive exact "$MON_X" "$MON_Y"
        hyprctl dispatch resizeactive exact "$MON_WIDTH" "$HALF_H"
        ;;
    bottom)
        hyprctl dispatch moveactive exact "$MON_X" "$((MON_Y + HALF_H + BAR_OFFSET))"
        hyprctl dispatch resizeactive exact "$MON_WIDTH" "$HALF_H"
        ;;
    # ── Quarter-screen snaps ─────────────────────────────────────────────────
    topleft)
        hyprctl dispatch moveactive exact "$MON_X" "$MON_Y"
        hyprctl dispatch resizeactive exact "$HALF_W" "$HALF_H"
        ;;
    topright)
        hyprctl dispatch moveactive exact "$((MON_X + HALF_W))" "$MON_Y"
        hyprctl dispatch resizeactive exact "$HALF_W" "$HALF_H"
        ;;
    bottomleft)
        hyprctl dispatch moveactive exact "$MON_X" "$((MON_Y + HALF_H + BAR_OFFSET))"
        hyprctl dispatch resizeactive exact "$HALF_W" "$HALF_H"
        ;;
    bottomright)
        hyprctl dispatch moveactive exact "$((MON_X + HALF_W))" "$((MON_Y + HALF_H + BAR_OFFSET))"
        hyprctl dispatch resizeactive exact "$HALF_W" "$HALF_H"
        ;;
    *)
        echo "Invalid direction: $DIRECTION"
        echo "Valid: topleft, topright, bottomleft, bottomright, left, right, top, bottom"
        exit 1
        ;;
esac

echo "[Snap] Window snapped to $DIRECTION (${HALF_W}x${HALF_H})"
