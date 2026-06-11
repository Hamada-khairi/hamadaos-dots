#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# HamadaOS — Wallpaper convenience wrapper
# ═══════════════════════════════════════════════════════════════════════════════
# Prefers HyDE's wallpaper pipeline (which triggers Wallbash → our matugen
# bridge automatically). Falls back to swww + manual bridge when HyDE isn't
# available (e.g. testing in a nested session).
#
# Usage: wallpaper.sh [image]      (no arg = random from ~/Pictures/wallpapers)
# ═══════════════════════════════════════════════════════════════════════════════

set -uo pipefail

WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/wallpapers}"

# ── Pick image ──────────────────────────────────────────────────────────────────
if [[ -n "${1:-}" && -f "$1" ]]; then
    IMAGE="$(readlink -f "$1")"
elif [[ -d "$WALLPAPER_DIR" ]]; then
    IMAGE="$(find "$WALLPAPER_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | shuf -n1)"
else
    echo "Usage: wallpaper.sh <image>  (or create $WALLPAPER_DIR)"
    exit 1
fi
[[ -n "${IMAGE:-}" ]] || { echo "No image selected."; exit 1; }

# ── Preferred: HyDE pipeline (Wallbash fires the matugen bridge for us) ────────
if command -v hyde-shell >/dev/null 2>&1; then
    hyde-shell wallpaper -s "$IMAGE" 2>/dev/null \
        || hyde-shell wallpaper --set "$IMAGE" 2>/dev/null \
        && exit 0
fi

# ── Fallback: raw swww + run the bridge manually ───────────────────────────────
if command -v swww >/dev/null 2>&1; then
    pgrep -x swww-daemon >/dev/null || swww-daemon &
    swww img "$IMAGE" --transition-type grow --transition-fps 60
fi

mkdir -p "${HYDE_CACHE_HOME:-$HOME/.cache/hyde}"
ln -sf "$IMAGE" "${HYDE_CACHE_HOME:-$HOME/.cache/hyde}/wall.set"
exec "$HOME/.config/hyde/wallbash/scripts/hamadaos.sh"
