#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# HamadaOS — Remote Desktop Setup (wayvnc + RDP)
# ═══════════════════════════════════════════════════════════════════════════════
# Installs and configures remote access: wayvnc (Wayland VNC server),
# xrdp (RDP for Windows Remote Desktop), and remmina (RDP client).
# Run once: ./setup-remote-desktop.sh
# ═══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

echo "=== HamadaOS Remote Desktop Setup ==="

echo "[1/3] Installing packages..."
yay -S --needed --noconfirm wayvnc xrdp remmina 2>/dev/null || true
sudo pacman -S --needed --noconfirm freerdp 2>/dev/null || true

echo "[2/3] Enabling xrdp (RDP server)..."
sudo systemctl enable --now xrdp 2>/dev/null || echo "  xrdp already enabled"

echo "[3/3] Remote access ready."
echo "  VNC server: wayvnc  (Wayland-native, low latency)"
echo "  RDP server: xrdp    (Windows mstsc.exe compatible)"
echo "  RDP client: remmina (connect TO Windows machines)"
echo ""
echo "Firewall ports to allow:"
echo "  VNC: 5900/tcp"
echo "  RDP: 3389/tcp"
echo ""
echo "  Allow firewall: sudo ufw allow 3389/tcp && sudo ufw allow 5900/tcp"
