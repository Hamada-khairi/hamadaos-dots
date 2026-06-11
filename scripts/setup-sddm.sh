#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# HamadaOS — SDDM Login Fixes
# ═══════════════════════════════════════════════════════════════════════════════
# HyDE already ships and themes SDDM (corners theme, wallpaper sync via
# `hyde-shell sddm`). We do NOT replace it — we only:
#   1. Fix the documented capital-letters-in-username login bug
#   2. Set cursor theme via a drop-in (never clobber /etc/sddm.conf)
# Run as root (install.sh does this).
# ═══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

if [[ $EUID -ne 0 ]]; then echo "Run as root."; exit 1; fi

echo "[1/2] Username-capitals fix (HyDE corners theme)..."
SDDM_CORNERS="/usr/share/sddm/themes/corners/theme.conf"
if [[ -f "$SDDM_CORNERS" ]] && ! grep -q "AllowBadUsername" "$SDDM_CORNERS"; then
    echo "AllowBadUsername=true" >> "$SDDM_CORNERS"
    echo "  patched: $SDDM_CORNERS"
else
    echo "  already patched or theme not present — ok"
fi

echo "[2/2] Cursor theme drop-in..."
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/20-hamadaos.conf << 'EOF'
[Theme]
CursorTheme=Bibata-Modern-Classic
EOF

echo "SDDM setup complete (HyDE's theme kept; sync wallpaper with: hyde-shell sddm)"
