#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# HamadaOS — Wallbash post-script (the matugen bridge)
# ═══════════════════════════════════════════════════════════════════════════════
# HyDE's Wallbash runs this automatically on every wallpaper, theme, and
# dark/light switch (registered by wallbash/always/hamadaos.dcol). We don't
# replace any HyDE machinery — we extend it:
#
#   HyDE sets wallpaper → Wallbash caches colors → this script runs
#       → matugen regenerates: Quickshell colors, GTK3/4 CSS, Kvantum,
#         kitty theme, VS Code theme, Hyprland colors.conf
#       → kitty live-reloads, Hyprland reloads, Quickshell hot-reloads
#
# Total desktop re-color: under 2 seconds, from one wallpaper change.
# ═══════════════════════════════════════════════════════════════════════════════

set -uo pipefail

# Current wallpaper — HyDE keeps a stable handle in its cache.
CACHE_HOME="${HYDE_CACHE_HOME:-$HOME/.cache/hyde}"
WALL="$(readlink -f "$CACHE_HOME/wall.set" 2>/dev/null || true)"
[[ -f "$WALL" ]] || WALL="$CACHE_HOME/wall.set"
[[ -f "$WALL" ]] || { echo "[hamadaos] no current wallpaper found"; exit 0; }

command -v matugen >/dev/null 2>&1 || {
    echo "[hamadaos] matugen not installed — skipping (yay -S matugen-bin)"
    exit 0
}

# Dark/light follows HyDE's mode (from the env file Wallbash just wrote).
MODE="dark"
if [[ -f "$CACHE_HOME/wallbash/hamadaos.env" ]]; then
    # shellcheck disable=SC1091
    source "$CACHE_HOME/wallbash/hamadaos.env" 2>/dev/null || true
    [[ "${HAMADAOS_MODE:-dark}" == "light" ]] && MODE="light"
fi

# ── 1. matugen — writes every template in ~/.config/matugen/config.toml ───────
matugen image "$WALL" --mode "$MODE" 2>/dev/null

# ── 2. Live-reload terminals ───────────────────────────────────────────────────
KITTY_THEME="$HOME/.config/kitty/current-theme.conf"
if [[ -f "$KITTY_THEME" ]]; then
    for sock in /tmp/kitty-*; do
        [[ -S "$sock" ]] && kitty @ --to "unix:$sock" set-colors --all "$KITTY_THEME" 2>/dev/null
    done
    pkill -USR1 -x kitty 2>/dev/null || true
fi

# ── 3. Hyprland — pick up new border colors ────────────────────────────────────
hyprctl reload >/dev/null 2>&1 || true

# ── 4. Quickshell — GeneratedColors.qml hot-reloads itself; just confirm ───────
qs ipc call hamadaos themeReloaded >/dev/null 2>&1 || true

echo "[hamadaos] desktop re-colored from $(basename "$WALL") ($MODE)"
