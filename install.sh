#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# HamadaOS — One-Command Installer
# ═══════════════════════════════════════════════════════════════════════════════
# From a fresh CachyOS install:
#     git clone <repo> && cd hamadaos-dots && ./install.sh
# installs HyDE itself if missing, every package, every config, every service.
#
# Design rules:
#   · idempotent — safe to re-run any time
#   · fault-tolerant — one broken AUR package never kills the install;
#     failures are collected and reported at the end
#   · HAMADAOS_LINKS_ONLY=1 ./install.sh  → only re-link configs + system
#     files (used by hamadaos-update.sh and doctor --fix)
# ═══════════════════════════════════════════════════════════════════════════════

set -uo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
LINKS_ONLY="${HAMADAOS_LINKS_ONLY:-0}"
FAILED_PKGS=()

step() { echo -e "\n\033[1;35m═══ $1 ═══\033[0m"; }

# ── AUR helper: prefer what's there (CachyOS ships paru), bootstrap yay if none
AUR_HELPER="$(command -v yay || command -v paru || true)"
ensure_aur_helper() {
    [[ -n "$AUR_HELPER" ]] && return
    step "Bootstrapping yay (no AUR helper found)"
    sudo pacman -S --needed --noconfirm git base-devel
    local tmp; tmp="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin" \
        && (cd "$tmp/yay-bin" && makepkg -si --noconfirm) \
        && AUR_HELPER="$(command -v yay)"
    rm -rf "$tmp"
    [[ -n "$AUR_HELPER" ]] || { echo "FATAL: could not install an AUR helper"; exit 1; }
}

# ── Fault-tolerant install: try the batch (fast), fall back per-package
pkg_install() {  # pkg_install <repo|aur> pkg...
    local kind="$1"; shift
    local cmd
    if [[ "$kind" == "repo" ]]; then cmd=(sudo pacman -S --needed --noconfirm)
    else cmd=("$AUR_HELPER" -S --needed --noconfirm); fi
    if "${cmd[@]}" "$@" 2>/dev/null; then return; fi
    echo "  batch failed — retrying individually…"
    local p
    for p in "$@"; do
        "${cmd[@]}" "$p" || { echo "  !! $p failed"; FAILED_PKGS+=("$p"); }
    done
}

# ── HyDE bootstrap: this is what makes it ONE command from bare CachyOS
ensure_hyde() {
    command -v hyde-shell >/dev/null 2>&1 && return
    step "HyDE not found — installing it first"
    sudo pacman -S --needed --noconfirm git base-devel
    if [[ ! -d "$HOME/HyDE" ]]; then
        git clone --depth 1 https://github.com/HyDE-Project/HyDE "$HOME/HyDE"
    fi
    (cd "$HOME/HyDE/Scripts" && ./install.sh) || {
        echo "FATAL: HyDE installation failed — fix the error above and re-run."
        exit 1
    }
}

if [[ "$LINKS_ONLY" != "1" ]]; then
    ensure_aur_helper
    ensure_hyde

# ═══ 1. Packages ═════════════════════════════════════════════════════════════
step "[1/8] Packages"

pkg_install repo \
    steam gamemode lib32-gamemode mangohud lib32-mangohud gamescope \
    lutris \
    flatpak xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
    kdeconnect seahorse fprintd gnome-disk-utility \
    blueman nm-connection-editor networkmanager-openvpn \
    system-config-printer kooha qalculate-gtk gwenview \
    ark p7zip okular imagemagick \
    tesseract tesseract-data-eng tesseract-data-ara \
    ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji \
    zram-generator tuned ananicy-cpp brightnessctl \
    scx-scheds \
    fcitx5 fcitx5-qt fcitx5-gtk fcitx5-configtool \
    qt6-base qt6-declarative qt6-wayland qt6-svg qt6-multimedia \
    snapper snap-pac \
    jq zenity mpv gnome-calendar hardinfo2 \
    xdg-utils grim slurp wl-clipboard \
    pacman-contrib gromit-mpx \
    game-devices-udev \
    piper solaar headsetcontrol libreoffice-fresh \
    corectrl

pkg_install aur \
    quickshell-git \
    hyprland-plugins \
    hyprswitch \
    matugen-bin \
    ttf-geist-font-git \
    nwg-displays nwg-look \
    mission-center \
    fsearch-git \
    pwvucontrol easyeffects \
    bottles \
    kvantum qt6ct \
    input-remapper-git \
    proton-ge-custom-bin \
    heroic-games-launcher-bin \
    goverlay \
    adw-gtk-theme \
    gufw \
    wayfreeze-git \
    snapper-gui-git \
    pamac-aur \
    linux-wifi-hotspot \
    lact \
    vesktop

fi  # end of package phase (skipped when HAMADAOS_LINKS_ONLY=1)

# ═══ 2. Config symlinks ═══════════════════════════════════════════════════════
step "[2/8] Linking configs"

link() {
    local src="$REPO_DIR/$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    # Back up real files (not symlinks) once before replacing.
    if [[ -e "$dst" && ! -L "$dst" ]]; then
        mv "$dst" "$dst.hamadaos-bak" 2>/dev/null || true
    fi
    ln -sfn "$src" "$dst"
    echo "  linked: $dst"
}

# Hyprland (HyDE user-safe files)
link "config/hypr/userprefs.conf"      "$CONFIG_DIR/hypr/userprefs.conf"
link "config/hypr/keybindings.conf"    "$CONFIG_DIR/hypr/keybindings.conf"
link "config/hypr/windowrules.conf"    "$CONFIG_DIR/hypr/windowrules.conf"
link "config/hypr/monitors.conf"       "$CONFIG_DIR/hypr/monitors.conf"
link "config/hypr/plugins.conf"        "$CONFIG_DIR/hypr/plugins.conf"
link "config/hypr/nvidia.conf"         "$CONFIG_DIR/hypr/nvidia.conf"
link "config/hypr/animations.conf"     "$CONFIG_DIR/hypr/animations.conf"
link "config/hypr/animations/hamadaos.conf" "$CONFIG_DIR/hypr/animations/hamadaos.conf"
link "config/hypr/xdph.conf"           "$CONFIG_DIR/hypr/xdph.conf"

# Quickshell, matugen, fonts, gaming
link "config/quickshell"               "$CONFIG_DIR/quickshell"
link "config/matugen"                  "$CONFIG_DIR/matugen"
link "config/fontconfig/fonts.conf"    "$CONFIG_DIR/fontconfig/fonts.conf"
link "config/MangoHud/MangoHud.conf"   "$CONFIG_DIR/MangoHud/MangoHud.conf"
link "config/hyprswitch/config.toml"   "$CONFIG_DIR/hyprswitch/config.toml"

# GameMode — auto gaming-mode hooks on every game launch
link "config/gamemode/gamemode.ini"    "$CONFIG_DIR/gamemode.ini"

# Audio: PipeWire quantum floor (weak-CPU crackle fix) + Bluetooth quality
# (mSBC/SBC-XQ/LE Audio — the "headset mic ruins audio" fix)
link "config/pipewire/pipewire.conf.d/10-hamadaos-quantum.conf" \
     "$CONFIG_DIR/pipewire/pipewire.conf.d/10-hamadaos-quantum.conf"
link "config/wireplumber/wireplumber.conf.d/51-hamadaos-bluetooth.conf" \
     "$CONFIG_DIR/wireplumber/wireplumber.conf.d/51-hamadaos-bluetooth.conf"

# HyDE user override (NOT the schema file — this one survives HyDE updates)
link "config/hyde/config.toml"         "$CONFIG_DIR/hyde/config.toml"

# Wallbash → matugen bridge (HyDE's documented extension point)
link "config/hyde/wallbash/always/hamadaos.dcol"          "$CONFIG_DIR/hyde/wallbash/always/hamadaos.dcol"
link "config/hyde/wallbash/always/hamadaos-hyprbars.dcol" "$CONFIG_DIR/hyde/wallbash/always/hamadaos-hyprbars.dcol"
link "config/hyde/wallbash/scripts/hamadaos.sh"           "$CONFIG_DIR/hyde/wallbash/scripts/hamadaos.sh"

# Scripts
mkdir -p "$CONFIG_DIR/hypr/scripts"
for script in "$REPO_DIR/scripts/"*.sh; do
    chmod +x "$script"
    link "scripts/$(basename "$script")" "$CONFIG_DIR/hypr/scripts/$(basename "$script")"
done

# Sourced-but-generated files must exist or Hyprland shows a config-error bar.
mkdir -p "$CONFIG_DIR/hypr/themes"
touch "$CONFIG_DIR/hypr/hyprbars-colors.conf" "$CONFIG_DIR/hypr/themes/colors.conf" \
      "$CONFIG_DIR/hypr/gpu.conf"
mkdir -p "$CONFIG_DIR/hamadaos"   # Quickshell settings live here

# ═══ 3. System files ══════════════════════════════════════════════════════════
step "[3/8] System config (sudo)"

sudo install -Dm644 "$REPO_DIR/system/sysctl/99-gaming.conf"   /etc/sysctl.d/99-gaming.conf
sudo install -Dm644 "$REPO_DIR/system/systemd/99-nofile.conf"  /etc/systemd/system.conf.d/99-nofile.conf
sudo install -Dm644 "$REPO_DIR/system/zram-generator.conf"     /etc/systemd/zram-generator.conf
sudo install -Dm755 "$REPO_DIR/system/bin/hamadaos-perf-tune"  /usr/local/bin/hamadaos-perf-tune
sudo install -Dm755 "$REPO_DIR/system/bin/hamadaos-game-run"   /usr/local/bin/hamadaos-game-run

# Safe Mode: a login-screen session that always boots, no matter what broke
sudo install -Dm755 "$REPO_DIR/system/bin/hamadaos-safe-session" /usr/local/bin/hamadaos-safe-session
sudo install -Dm644 "$REPO_DIR/system/wayland-sessions/hamadaos-safe.desktop" \
    /usr/share/wayland-sessions/hamadaos-safe.desktop
link "config/hypr/hyprland-safe.conf" "$CONFIG_DIR/hypr/hyprland-safe.conf"

# Sudoers drop-in — validate before installing, never brick sudo.
sudo visudo -cf "$REPO_DIR/system/sudoers.d/hamadaos-gaming" \
    && sudo install -Dm440 "$REPO_DIR/system/sudoers.d/hamadaos-gaming" /etc/sudoers.d/hamadaos-gaming \
    || echo "  !! sudoers file failed validation — skipped"

sudo sysctl --system >/dev/null

if [[ "$LINKS_ONLY" == "1" ]]; then
    step "Links refreshed (HAMADAOS_LINKS_ONLY) — done"
    exit 0
fi

# ═══ 4. Services + hardware profile ═══════════════════════════════════════════
step "[4/8] Services + hardware detection"
sudo systemctl enable --now tuned 2>/dev/null || true
sudo tuned-adm profile balanced 2>/dev/null || true
sudo systemctl enable --now ananicy-cpp 2>/dev/null || true
sudo systemctl enable --now input-remapper 2>/dev/null || true

# Detect this machine (GPU vendor, Optimus, VRAM, RAM, TDP-shared laptop…)
bash "$REPO_DIR/scripts/hamadaos-hw-profile.sh" || true

# LACT daemon — GPU overclocking/fan control (MSI Afterburner equivalent)
sudo systemctl enable --now lactd 2>/dev/null \
    && echo "  lactd enabled (GPU control daemon)" || echo "  lactd unavailable"

# Per-title Proton overrides directory + example
mkdir -p "$CONFIG_DIR/hamadaos/games.d"
cp -n "$REPO_DIR/config/hamadaos/games.d/"* "$CONFIG_DIR/hamadaos/games.d/" 2>/dev/null || true

# NVIDIA hybrid laptops: Dynamic Boost daemon shifts package watts between
# CPU and GPU per-frame — exactly what a 40W RTX 3050 needs.
if [[ -f "$CONFIG_DIR/hamadaos/hardware.env" ]]; then
    # shellcheck disable=SC1091
    source "$CONFIG_DIR/hamadaos/hardware.env"
    if [[ "${NVIDIA_PROPRIETARY:-0}" == "1" && "${IS_LAPTOP:-0}" == "1" ]]; then
        sudo systemctl enable --now nvidia-powerd 2>/dev/null \
            && echo "  nvidia-powerd enabled (Dynamic Boost)" \
            || echo "  nvidia-powerd unavailable (driver too old or unsupported GPU)"
    fi
    # MUX-less hybrid: let the dGPU fully power down when no game runs.
    if [[ "${NVIDIA_PROPRIETARY:-0}" == "1" && "${IS_HYBRID:-0}" == "1" ]]; then
        sudo install -Dm644 "$REPO_DIR/system/modprobe.d/hamadaos-nvidia-pm.conf" \
            /etc/modprobe.d/hamadaos-nvidia-pm.conf
        sudo install -Dm644 "$REPO_DIR/system/udev/80-hamadaos-nvidia-pm.rules" \
            /etc/udev/rules.d/80-hamadaos-nvidia-pm.rules
        echo "  NVIDIA runtime D3 power-gating installed (takes effect next boot)"
    fi
fi

# ═══ 5. Flatpak ═══════════════════════════════════════════════════════════════
step "[5/8] Flatpak"
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo flatpak override --env=QT_QPA_PLATFORMTHEME=qt6ct 2>/dev/null || true
sudo flatpak override --env=GTK_THEME=adw-gtk3-dark 2>/dev/null || true

# ═══ 6. Optional extras (best-effort, non-fatal) ═══════════════════════════════
step "[6/8] Boot polish + login (optional)"
[[ -x "$REPO_DIR/scripts/setup-sddm.sh" ]]     && sudo bash "$REPO_DIR/scripts/setup-sddm.sh"     || echo "  SDDM setup skipped"
[[ -x "$REPO_DIR/scripts/setup-plymouth.sh" ]] && sudo bash "$REPO_DIR/scripts/setup-plymouth.sh" || echo "  Plymouth skipped"
[[ -x "$REPO_DIR/scripts/setup-fingerprint.sh" ]] && sudo bash "$REPO_DIR/scripts/setup-fingerprint.sh" || echo "  Fingerprint skipped"

# ═══ 7. Caches ════════════════════════════════════════════════════════════════
step "[7/8] Font cache"
fc-cache -f >/dev/null

# ═══ 8. Done ══════════════════════════════════════════════════════════════════
step "[8/8] Finished"

if [[ ${#FAILED_PKGS[@]} -gt 0 ]]; then
    echo ""
    echo "  ⚠ These packages failed to install (everything else is fine):"
    printf '      %s\n' "${FAILED_PKGS[@]}"
    echo "    Retry later with: $AUR_HELPER -S ${FAILED_PKGS[*]}"
fi

cat <<'EOF'

  ✓ Quickshell shell (bar · dock · launcher · control center · settings ·
    notifications · OSD · power menu) replaces Waybar + dunst
  ✓ Float-all window rules (Hyprland 0.53 syntax, legacy fallback included)
  ✓ hyprbars title bars + hyprswitch Alt+Tab + hyprexpo grid
  ✓ Wallbash → matugen bridge: wallpaper recolors the ENTIRE desktop
  ✓ Gaming: Steam, Proton-GE, GameMode, MangoHud, gaming-mode toggle
    (passwordless via scoped sudoers drop-in)
  ✓ Adaptive performance: hardware profiled (Optimus/VRAM/ReBAR/TDP),
    hamadaos-game-run wrapper, scx_lavd scheduler, auto gaming-mode hooks
    → Steam launch options for EVERY game:  hamadaos-game-run %command%
  ✓ Arabic IME (fcitx5), KDE Connect, fingerprint, snapshots

  Next:
    1. REBOOT (file-limit + zram changes need it)
    2. Pick Hyprland at the login screen
    3. Set a wallpaper:  ~/.config/hypr/scripts/wallpaper.sh <image>
    4. Verify health:    ~/.config/hypr/scripts/hamadaos-doctor.sh
    5. Open settings:    Super+I

EOF
