#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# HamadaOS — Settings Backup / Restore
# ═══════════════════════════════════════════════════════════════════════════════
#   hamadaos-backup.sh export            → ~/Documents/hamadaos-backup-<date>.tar.gz
#   hamadaos-backup.sh import <file>     → restores (current state backed up first)
#   hamadaos-backup.sh auto              → silent snapshot into ~/.local/state
#                                          (called before every update)
#
# What's inside: everything personal that ISN'T in the dots repo —
# shell settings, monitor layout, per-game overrides, HyDE user config,
# LACT GPU profiles. Restoring on a fresh install = your desktop back.
# ═══════════════════════════════════════════════════════════════════════════════

set -uo pipefail
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/hamadaos/backups"

PATHS=(
    "$CFG/hamadaos"                 # shell settings + hardware profile + games.d
    "$CFG/hypr/monitors.conf"       # saved display layout
    "$CFG/hypr/gpu.conf"
    "$CFG/hyde/config.toml"         # HyDE user overrides
    "$CFG/lact"                     # GPU overclock profiles (if any)
    "$CFG/MangoHud"
)

do_pack() {  # do_pack <output.tar.gz>
    local out="$1" tmp
    tmp="$(mktemp -d)"
    local p
    for p in "${PATHS[@]}"; do
        [[ -e "$p" ]] && cp -a --parents "$p" "$tmp" 2>/dev/null
    done
    tar -czf "$out" -C "$tmp" . && rm -rf "$tmp"
}

case "${1:-}" in
export)
    mkdir -p "$HOME/Documents"
    OUT="$HOME/Documents/hamadaos-backup-$(date +%Y%m%d-%H%M).tar.gz"
    do_pack "$OUT"
    echo "Exported → $OUT"
    notify-send -a "HamadaOS" "Settings exported" "$(basename "$OUT") in Documents" 2>/dev/null || true
    ;;
import)
    IN="${2:-}"
    [[ -f "$IN" ]] || { echo "Usage: hamadaos-backup.sh import <file.tar.gz>"; exit 1; }
    # Safety net: snapshot current state before overwriting anything.
    mkdir -p "$STATE"
    do_pack "$STATE/pre-import-$(date +%Y%m%d-%H%M%S).tar.gz"
    tar -xzf "$IN" -C / 2>/dev/null || tar -xzf "$IN" -C "$HOME" --strip-components=2 2>/dev/null
    echo "Imported. Restart the shell (or relog) to apply."
    ;;
auto)
    mkdir -p "$STATE"
    do_pack "$STATE/pre-update-$(date +%Y%m%d-%H%M%S).tar.gz"
    # Keep the last 10
    ls -t "$STATE"/pre-update-*.tar.gz 2>/dev/null | tail -n +11 | xargs -r rm
    ;;
*)
    echo "Usage: hamadaos-backup.sh <export|import FILE|auto>"
    exit 1
    ;;
esac
