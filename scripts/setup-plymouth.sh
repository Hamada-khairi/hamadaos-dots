#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# HamadaOS — Plymouth Boot Animation Setup
# ═══════════════════════════════════════════════════════════════════════════════
# Installs Plymouth and the lone dark theme, rebuilds initramfs.
# Run once: sudo ./setup-plymouth.sh
# ═══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

if [[ $EUID -ne 0 ]]; then echo "Run as root: sudo ./setup-plymouth.sh"; exit 1; fi

echo "=== HamadaOS Plymouth Setup ==="

echo "[1/4] Installing Plymouth..."
pacman -S --needed --noconfirm plymouth 2>/dev/null || true

echo "[2/4] Installing lone dark theme..."
# yay/makepkg refuse to run as root — drop privileges to the invoking user.
REAL_USER="${SUDO_USER:-}"
if ! pacman -Q plymouth-theme-lone &>/dev/null; then
    if [[ -n "$REAL_USER" ]]; then
        sudo -u "$REAL_USER" yay -S --needed --noconfirm plymouth-theme-lone 2>/dev/null || {
            echo "  Building from AUR as $REAL_USER..."
            sudo -u "$REAL_USER" git clone https://aur.archlinux.org/plymouth-theme-lone.git /tmp/plymouth-lone 2>/dev/null || true
            [[ -d /tmp/plymouth-lone ]] && (cd /tmp/plymouth-lone && sudo -u "$REAL_USER" makepkg -s --noconfirm && pacman -U --noconfirm /tmp/plymouth-lone/*.pkg.tar.zst) || echo "  Skipping — will use fallback theme"
        }
    else
        echo "  No SUDO_USER — cannot build AUR theme as root. Using fallback theme."
    fi
fi

echo "[3/4] Setting Plymouth theme..."
if plymouth-set-default-theme -l 2>/dev/null | grep -q "lone"; then
    plymouth-set-default-theme -R lone 2>/dev/null || true
elif [[ -d /usr/share/plymouth/themes/lone ]]; then
    plymouth-set-default-theme -R lone 2>/dev/null || true
else
    echo "  Lone theme not available. Available themes:"
    plymouth-set-default-theme -l 2>/dev/null || true
    echo "  Using default spinner theme."
fi

echo "[4/4] Updating GRUB config..."
if grep -q "splash" /etc/default/grub 2>/dev/null; then
    echo "  splash already in GRUB_CMDLINE_LINUX_DEFAULT"
else
    sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash /' /etc/default/grub 2>/dev/null || true
    echo "  Added quiet splash to GRUB"
fi

if command -v grub-mkconfig &>/dev/null; then
    grub-mkconfig -o /boot/grub/grub.cfg
    echo "  GRUB config regenerated."
elif command -v update-grub &>/dev/null; then
    update-grub
fi

echo ""
echo "=== Plymouth setup complete. Reboot to see the boot animation. ==="
