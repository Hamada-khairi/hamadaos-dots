#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# HamadaOS — Microsoft Office (the honest, working way)
# ═══════════════════════════════════════════════════════════════════════════════
# Desktop Office binaries don't run under Wine — full stop (Click-to-Run is
# the blocker; CrossOver can't either). What DOES work 100%:
#
#   Microsoft 365 web apps installed as PWAs through native Microsoft Edge
#   for Linux: each app gets its own window, taskbar entry, and icon. Your
#   Microsoft account, OneDrive, real-time co-editing — it's Microsoft's own
#   runtime, so compatibility is total for what the web apps support.
#
# For the rare desktop-only features (VBA macros, some add-ins), the escape
# hatch is WinApps (real binaries via a hidden VM) — documented in the
# Compatibility page, deliberately not installed by default.
#
#   hamadaos-office-setup.sh setup           install Edge if needed + all PWAs
#   hamadaos-office-setup.sh launch word     open one app (auto-setup first)
# ═══════════════════════════════════════════════════════════════════════════════

set -uo pipefail

APPS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
mkdir -p "$APPS_DIR"

# Current Microsoft 365 endpoints (cloud.microsoft is the 2024+ home)
declare -A URLS=(
    [word]="https://word.cloud.microsoft/"
    [excel]="https://excel.cloud.microsoft/"
    [powerpoint]="https://powerpoint.cloud.microsoft/"
    [outlook]="https://outlook.office.com/mail/"
    [onedrive]="https://onedrive.live.com/"
    [office]="https://m365.cloud.microsoft/"
)
declare -A NAMES=(
    [word]="Word" [excel]="Excel" [powerpoint]="PowerPoint"
    [outlook]="Outlook" [onedrive]="OneDrive" [office]="Microsoft 365"
)
declare -A ICONS=(  # Papirus ships real MS icons
    [word]="ms-word" [excel]="ms-excel" [powerpoint]="ms-powerpoint"
    [outlook]="ms-outlook" [onedrive]="onedrive" [office]="ms-office"
)

find_browser() {
    command -v microsoft-edge-stable && return
    command -v microsoft-edge-beta && return
    command -v chromium && return
    command -v brave && return
    command -v google-chrome-stable && return
    return 1
}

ensure_browser() {
    BROWSER="$(find_browser)" && return 0
    echo "[office] No PWA-capable browser found — installing Microsoft Edge…"
    local helper; helper="$(command -v yay || command -v paru)"
    [[ -n "$helper" ]] && "$helper" -S --needed --noconfirm microsoft-edge-stable-bin
    BROWSER="$(find_browser)" || {
        echo "[office] Could not install a browser. Install chromium and retry."
        notify-send -a HamadaOS "Office setup failed" "Install Microsoft Edge or Chromium first" 2>/dev/null
        exit 1
    }
}

write_pwa() {  # write_pwa <key>
    local key="$1"
    cat > "$APPS_DIR/hamadaos-${key}.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=${NAMES[$key]}
Comment=Microsoft 365 — runs in its own window
Exec=$BROWSER --app=${URLS[$key]} --class=hamadaos-${key}
Icon=${ICONS[$key]}
Categories=Office;
StartupWMClass=hamadaos-${key}
EOF
}

do_setup() {
    ensure_browser
    local key
    for key in "${!URLS[@]}"; do write_pwa "$key"; done
    update-desktop-database "$APPS_DIR" 2>/dev/null || true
    echo "[office] Installed: Word, Excel, PowerPoint, Outlook, OneDrive, Microsoft 365"
    echo "[office] Sign in once in any of them — the session is shared."
    notify-send -a HamadaOS -i ms-office "Microsoft Office ready" \
        "Word, Excel, PowerPoint, Outlook & OneDrive are in your launcher" 2>/dev/null || true
}

case "${1:-setup}" in
setup) do_setup ;;
launch)
    key="${2:-office}"
    [[ -n "${URLS[$key]:-}" ]] || { echo "Unknown app: $key"; exit 1; }
    # Self-healing: first launch sets everything up.
    [[ -f "$APPS_DIR/hamadaos-${key}.desktop" ]] || do_setup
    BROWSER="${BROWSER:-$(find_browser)}" || { do_setup; }
    exec "$BROWSER" --app="${URLS[$key]}" --class="hamadaos-${key}"
    ;;
*) echo "Usage: hamadaos-office-setup.sh <setup|launch word|excel|powerpoint|outlook|onedrive|office>" ;;
esac
