#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# HamadaOS — WiFi Network Menu (rofi-based)
# ═══════════════════════════════════════════════════════════════════════════════
# Lists available WiFi networks via nmcli, presents them in a rofi dmenu,
# and connects to the selected network. Prompts for password if the network
# is secured.
#
# Bound to: Super+W (keybindings.conf)
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ── Ensure WiFi is enabled ─────────────────────────────────────────────────────
WIFI_STATE="$(nmcli radio wifi 2>/dev/null)"
if [[ "$WIFI_STATE" == "disabled" ]]; then
    nmcli radio wifi on 2>/dev/null || true
    notify-send -a "HamadaOS" -i "network-wireless" -t 2000 \
        "WiFi Enabled" "Scanning for networks..." 2>/dev/null || true
    sleep 2   # wait for scan to populate
fi

# ── Rescan for fresh results ───────────────────────────────────────────────────
nmcli device wifi rescan 2>/dev/null || true
sleep 0.5

# ── Get network list ───────────────────────────────────────────────────────────
# Output format: SSID (BARS) SECURITY_SIGNAL
# Active connection is marked with "*"
NETWORKS="$(nmcli -t -f SSID,SECURITY,BARS,IN-USE device wifi list 2>/dev/null)"

if [[ -z "$NETWORKS" ]]; then
    notify-send -a "HamadaOS" -i "network-wireless" -t 3000 \
        "WiFi" "No networks found." 2>/dev/null || true
    exit 0
fi

# ── Format for rofi display ────────────────────────────────────────────────────
# Build a display list: each line shows SSID with signal bars and lock icon
DISPLAY_LIST=""
declare -A NETWORK_SECURITY

while IFS=: read -r ssid security bars in_use; do
    [[ -z "$ssid" ]] && continue

    # Build display string
    LOCK=""
    [[ "$security" != "" ]] && LOCK="🔒 "
    MARKER=""
    [[ "$in_use" == "*" ]] && MARKER="(connected) "
    DISPLAY="${LOCK}${MARKER}${ssid}   ${bars}"

    # Track security status for this SSID
    NETWORK_SECURITY["$ssid"]="$security"

    DISPLAY_LIST="${DISPLAY_LIST}${DISPLAY}\n"
done <<< "$NETWORKS"

# ── Show rofi menu ─────────────────────────────────────────────────────────────
SELECTION="$(echo -e "$DISPLAY_LIST" | rofi -dmenu -p "WiFi Network" -i -theme-str 'listview { lines: 10; }' 2>/dev/null)" || {
    echo "[WiFi] Selection cancelled."
    exit 0
}

# ── Extract SSID from selection ────────────────────────────────────────────────
# Remove leading lock icon, (connected) marker, and trailing signal bars
SSID="$(echo "$SELECTION" | sed -E 's/^🔒 ?//' | sed -E 's/^\(connected\) ?//' | sed -E 's/   .*$//' | xargs)"

if [[ -z "$SSID" ]]; then
    exit 0
fi

# ── Connect ─────────────────────────────────────────────────────────────────────
SECURITY="${NETWORK_SECURITY["$SSID"]:-}"

if [[ -n "$SECURITY" ]]; then
    # Secured network — prompt for password
    PASSWORD="$(rofi -dmenu -password -p "Password for $SSID" -theme-str 'listview { lines: 0; }' 2>/dev/null)" || {
        echo "[WiFi] Password entry cancelled."
        exit 0
    }

    nmcli device wifi connect "$SSID" password "$PASSWORD" 2>/dev/null && {
        notify-send -a "HamadaOS" -i "network-wireless-connected" -t 3000 \
            "WiFi Connected" "Connected to $SSID" 2>/dev/null || true
    } || {
        notify-send -a "HamadaOS" -i "network-wireless-error" -t 4000 \
            "WiFi Failed" "Could not connect to $SSID. Wrong password?" 2>/dev/null || true
    }
else
    # Open network — connect without password
    nmcli device wifi connect "$SSID" 2>/dev/null && {
        notify-send -a "HamadaOS" -i "network-wireless-connected" -t 3000 \
            "WiFi Connected" "Connected to $SSID" 2>/dev/null || true
    } || {
        notify-send -a "HamadaOS" -i "network-wireless-error" -t 4000 \
            "WiFi Failed" "Could not connect to $SSID." 2>/dev/null || true
    }
fi
