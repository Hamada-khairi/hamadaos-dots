#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# HamadaOS — Fingerprint Authentication Setup (Windows Hello equivalent)
# ═══════════════════════════════════════════════════════════════════════════════
# Enables fprintd PAM modules for sudo, SDDM login, and lockscreen unlock.
# Run once: sudo ./setup-fingerprint.sh
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Run as root: sudo ./setup-fingerprint.sh"
    exit 1
fi

echo "=== HamadaOS Fingerprint Setup ==="

# ── Install fprintd if not present ────────────────────────────────────────────
if ! command -v fprintd-enroll &>/dev/null; then
    echo "[1/4] Installing fprintd..."
    pacman -S --needed --noconfirm fprintd
fi

# ── Enable fprintd PAM module for sudo ────────────────────────────────────────
echo "[2/4] Adding pam_fprintd.so to sudo..."
PAM_SUDO="/etc/pam.d/sudo"
if ! grep -q "pam_fprintd.so" "$PAM_SUDO" 2>/dev/null; then
    sed -i '1a auth       sufficient   pam_fprintd.so' "$PAM_SUDO"
    echo "  ✓ Fingerprint added to sudo PAM"
else
    echo "  - Already configured"
fi

# ── Enable fprintd for SDDM login ─────────────────────────────────────────────
echo "[3/4] Adding pam_fprintd.so to SDDM..."
PAM_SDDM="/etc/pam.d/sddm"
if [[ -f "$PAM_SDDM" ]] && ! grep -q "pam_fprintd.so" "$PAM_SDDM" 2>/dev/null; then
    sed -i '1a auth       sufficient   pam_fprintd.so' "$PAM_SDDM"
    echo "  ✓ Fingerprint added to SDDM PAM"
else
    echo "  - Already configured or SDDM not installed"
fi

# ── Enable fprintd for hyprlock (lockscreen) ──────────────────────────────────
echo "[4/4] Adding pam_fprintd.so to hyprlock..."
PAM_HYPRLOCK="/etc/pam.d/hyprlock"
if [[ -f "$PAM_HYPRLOCK" ]] && ! grep -q "pam_fprintd.so" "$PAM_HYPRLOCK" 2>/dev/null; then
    sed -i '1a auth       sufficient   pam_fprintd.so' "$PAM_HYPRLOCK"
    echo "  ✓ Fingerprint added to hyprlock PAM"
else
    echo "  - Already configured or hyprlock not installed"
fi

echo ""
echo "=== Setup complete. Enroll your fingerprint: fprintd-enroll ==="
