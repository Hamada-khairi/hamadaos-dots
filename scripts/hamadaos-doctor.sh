#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# HamadaOS — Doctor (check + FIX framework)
# ═══════════════════════════════════════════════════════════════════════════════
#   hamadaos-doctor.sh           human-readable report
#   hamadaos-doctor.sh --json    one JSON object per line (consumed by the
#                                Settings → Health page)
#   hamadaos-doctor.sh --fix     re-run checks and auto-repair everything
#                                that has a known fix, then re-report
#
# Every check declares its own fix. The GUI's "Fix everything" button is
# literally this script — no separate logic to drift out of sync.
# ═══════════════════════════════════════════════════════════════════════════════

MODE="report"
case "${1:-}" in
    --json) MODE="json" ;;
    --fix)  MODE="fix" ;;
esac

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[0;33m'; NC='\033[0m'
PASS=0; FAIL=0; WARN=0; FIXED=0

have() { command -v "$1" >/dev/null 2>&1; }
in_session() { [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; }

json_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

emit() {  # emit <ok|warn|fail> <name> <detail> [fixed]
    local status="$1" name="$2" detail="$3" fixed="${4:-}"
    case "$status" in
        ok)   ((PASS++)) ;;
        warn) ((WARN++)) ;;
        fail) ((FAIL++)) ;;
    esac
    [[ -n "$fixed" ]] && ((FIXED++))
    if [[ "$MODE" == "json" ]]; then
        printf '{"status":"%s","name":"%s","detail":"%s","fixed":%s}\n' \
            "$status" "$(json_escape "$name")" "$(json_escape "$detail")" \
            "${fixed:+true}${fixed:-false}"
    else
        local mark
        case "$status" in
            ok)   mark="${GREEN}✓${NC}" ;;
            warn) mark="${YELLOW}!${NC}" ;;
            fail) mark="${RED}✗${NC}" ;;
        esac
        echo -e "  $mark $name${detail:+ — $detail}${fixed:+  ${GREEN}[fixed]${NC}}"
    fi
}

# check <name> <test-fn> <fix-fn|-> <fail-detail> [warn-only]
# Runs test; on failure in --fix mode runs fix then re-tests.
check() {
    local name="$1" test_fn="$2" fix_fn="$3" detail="$4" sev="${5:-fail}"
    if $test_fn; then
        emit ok "$name" ""
        return
    fi
    if [[ "$MODE" == "fix" && "$fix_fn" != "-" ]]; then
        $fix_fn >/dev/null 2>&1
        if $test_fn; then
            emit ok "$name" "$detail" yes
            return
        fi
    fi
    emit "$sev" "$name" "$detail"
}

hdr() { [[ "$MODE" != "json" ]] && echo -e "\n── $1"; }

REPO_DIR="$(dirname "$(readlink -f "$HOME/.config/hypr/userprefs.conf" 2>/dev/null)" 2>/dev/null)"
REPO_DIR="${REPO_DIR%/config/hypr}"

[[ "$MODE" != "json" ]] && echo "═══ HamadaOS Doctor ═══════════════════════════════════"

# ═══ Environment ═══════════════════════════════════════════════════════════════
hdr "Environment"
VIRT="$(systemd-detect-virt 2>/dev/null || echo none)"
if [[ "$VIRT" != "none" ]]; then
    emit ok "Virtual machine detected" "$VIRT — VM graphics profile applies"
    if compgen -G "/dev/dri/renderD*" >/dev/null; then
        DRV="$(grep -hsoE 'DRIVER=\w+' /sys/class/drm/card*/device/uevent 2>/dev/null | head -1 | cut -d= -f2)"
        emit ok "VM 3D acceleration" "render node present (${DRV:-unknown})"
    else
        emit warn "VM 3D acceleration" "none — running on llvmpipe (CPU). Host fix: virt-manager → Video 'Virtio' + 3D acceleration ON; VirtualBox → VMSVGA + Enable 3D; VMware → Accelerate 3D graphics"
    fi
    t_vmconf() { grep -q no_hardware_cursors ~/.config/hypr/gpu.conf 2>/dev/null; }
    f_vmconf() { "$HOME/.config/hypr/scripts/hamadaos-hw-profile.sh"; }
    check "VM graphics profile applied" t_vmconf f_vmconf "cursor/sync fixes missing — re-profiling"
else
    emit ok "Bare metal" ""
fi

# ═══ Core stack ═══════════════════════════════════════════════════════════════
hdr "Core stack"
check "Hyprland"            "have hyprctl"        - "not installed"
check "Quickshell"          "have quickshell"     - "yay -S quickshell-git"
check "HyDE"                "have hyde-shell"     - "HyDE not installed — run install.sh"
check "matugen"             "have matugen"        - "yay -S matugen-bin — colors won't follow wallpaper"
check "hyprswitch (Alt+Tab)" "have hyprswitch"    - "yay -S hyprswitch" warn
check "jq (snapping/scripts)" "have jq"           - "sudo pacman -S jq"
check "zenity (file dialogs)" "have zenity"       - "sudo pacman -S zenity" warn

# ═══ Runtime (inside a session) ═══════════════════════════════════════════════
hdr "Runtime"
if in_session; then
    t_qs() { pgrep -f quickshell >/dev/null; }
    f_qs() { hyde-shell app -u "hyde-$XDG_SESSION_DESKTOP-bar.scope" -t scope -- quickshell & sleep 3; }
    check "Quickshell running" t_qs f_qs "shell not running"

    t_ipc() { qs ipc show 2>/dev/null | grep -q hamadaos; }
    check "HamadaOS IPC registered" t_ipc - "shell up but IPC missing — check 'quickshell' output" warn

    t_bars() { hyprctl plugin list 2>/dev/null | grep -qi hyprbars; }
    f_bars() { hyprctl plugin load /usr/lib/hyprland/libhyprbars.so; }
    check "hyprbars (title bars)" t_bars f_bars "plugin not loaded" warn

    t_expo() { hyprctl plugin list 2>/dev/null | grep -qi hyprexpo; }
    f_expo() { hyprctl plugin load /usr/lib/hyprland/libhyprexpo.so; }
    check "hyprexpo (workspace grid)" t_expo f_expo "plugin not loaded" warn

    t_idle() { pgrep -x hypridle >/dev/null; }
    f_idle() { hypridle & }
    check "hypridle (lock/dpms)" t_idle f_idle "not running" warn

    t_sunset() { pgrep -f hyprsunset >/dev/null; }
    f_sunset() { hyprsunset & }
    check "hyprsunset (night light)" t_sunset f_sunset "not running" warn

    t_notif() { busctl --user status org.freedesktop.Notifications >/dev/null 2>&1; }
    check "Notification daemon" t_notif - "nothing owns org.freedesktop.Notifications"

    t_portal() { pgrep -f xdg-desktop-portal-hyprland >/dev/null; }
    f_portal() { systemctl --user restart xdg-desktop-portal-hyprland xdg-desktop-portal; sleep 2; }
    check "Screen-capture portal" t_portal f_portal "screenshare would be black"

    t_pw() { pgrep -x pipewire >/dev/null; }
    f_pw() { systemctl --user restart pipewire pipewire-pulse wireplumber; sleep 2; }
    check "PipeWire" t_pw f_pw "no audio/capture"
else
    emit warn "Session checks" "not inside Hyprland — skipped"
fi

# ═══ Config files ══════════════════════════════════════════════════════════════
hdr "Config files"
relink() { [[ -n "$REPO_DIR" && -x "$REPO_DIR/install.sh" ]] && HAMADAOS_LINKS_ONLY=1 bash "$REPO_DIR/install.sh"; }
t_conf() {
    [[ -f ~/.config/hypr/userprefs.conf && -f ~/.config/hypr/windowrules.conf \
    && -f ~/.config/hypr/plugins.conf && -f ~/.config/hyde/config.toml \
    && -f ~/.config/quickshell/shell.qml ]]
}
check "Core config links" t_conf relink "missing links — re-running installer link phase"

t_bridge() { [[ -f ~/.config/hyde/wallbash/scripts/hamadaos.sh ]]; }
check "Wallbash → matugen bridge" t_bridge relink "wallpaper recoloring broken"

t_audio_conf() { [[ -f ~/.config/wireplumber/wireplumber.conf.d/51-hamadaos-bluetooth.conf \
               && -f ~/.config/pipewire/pipewire.conf.d/10-hamadaos-quantum.conf ]]; }
check "Audio configs (BT quality + quantum)" t_audio_conf relink "headset mic will be telephone-quality"

t_hw() { [[ -f ~/.config/hamadaos/hardware.env ]]; }
f_hw() { "$HOME/.config/hypr/scripts/hamadaos-hw-profile.sh"; }
check "Hardware profile" t_hw f_hw "machine not profiled"

# Hybrid-specific
if grep -q "IS_HYBRID=1" ~/.config/hamadaos/hardware.env 2>/dev/null; then
    t_gpuconf() { grep -q AQ_DRM_DEVICES ~/.config/hypr/gpu.conf 2>/dev/null; }
    check "Hybrid GPU routing (compositor → iGPU)" t_gpuconf f_hw "double-copy risk"
fi

# ═══ Gaming ═══════════════════════════════════════════════════════════════════
hdr "Gaming"
check "Steam"      "have steam"      - "not installed" warn
check "GameMode"   "have gamemoded"  - "not installed" warn
check "MangoHud"   "have mangohud"   - "not installed" warn
check "gamescope (FSR)" "have gamescope" - "FSR upscaling unavailable" warn
check "Game wrapper (hamadaos-game-run)" "have hamadaos-game-run" - "re-run install.sh"
check "scxctl (gaming scheduler)" "have scxctl" - "install scx-scheds" warn
check "LACT (overclocking)" "have lact" - "no Afterburner equivalent" warn

t_lactd() { systemctl is-active lactd >/dev/null 2>&1; }
f_lactd() { sudo -n systemctl enable --now lactd; }
check "lactd daemon" t_lactd f_lactd "GPU control daemon down" warn

t_sudoers() { sudo -n /usr/local/bin/hamadaos-perf-tune balanced >/dev/null 2>&1; }
check "Passwordless perf-tune" t_sudoers - "sudoers drop-in inactive — re-run install.sh" warn

t_ulimit() { [[ "$(ulimit -Hn)" -ge 524288 ]]; }
check "File limits (esync)" t_ulimit - "reboot needed after install"

check "Vesktop (Discord share)" "have vesktop" - "official Discord can't capture Wayland" warn

# ═══ App compatibility ════════════════════════════════════════════════════════
hdr "App compatibility"
check "Piper (Logitech mouse config)" "have piper" - "G HUB replacement missing" warn
check "Solaar (Logitech receivers)" "have solaar" - "no receiver pairing/battery" warn
t_ratbag() { have ratbagctl && ratbagctl list >/dev/null 2>&1; }
check "libratbag daemon reachable" t_ratbag - "Piper won't see devices" warn
t_office() { [[ -f ~/.local/share/applications/hamadaos-word.desktop ]]; }
f_office() { "$HOME/.config/hypr/scripts/hamadaos-office-setup.sh" setup; }
check "Microsoft Office PWAs" t_office f_office "run office setup from Settings → Compatibility" warn
check "LibreOffice (local .docx fallback)" "have soffice" - "local Office files have no handler" warn
check "Bottles (run .exe)" "have bottles" - "no Windows-app runner" warn

# ═══ Theming ═══════════════════════════════════════════════════════════════════
hdr "Theming"
t_geist() { fc-list 2>/dev/null | grep -qi geist; }
check "Geist font" t_geist - "UI font missing" warn
t_nerd() { fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd"; }
f_nerd() { fc-cache -f; }
check "Nerd Font (bar icons)" t_nerd f_nerd "icons would render as boxes" warn
t_kitty_theme() { [[ -f ~/.config/kitty/current-theme.conf ]]; }
check "Generated terminal theme" t_kitty_theme - "set a wallpaper to generate" warn

# ═══ Recovery ═══════════════════════════════════════════════════════════════════
hdr "Recovery"
t_safe() { [[ -f /usr/share/wayland-sessions/hamadaos-safe.desktop && -x /usr/local/bin/hamadaos-safe-session ]]; }
check "Safe Mode login session" t_safe - "re-run install.sh — no rescue path if the desktop breaks"
t_snapper() { sudo -n snapper -c root list >/dev/null 2>&1 || snapper -c root list >/dev/null 2>&1; }
check "System snapshots (snapper)" t_snapper - "snapper not configured — no rollback for bad updates" warn
t_backup() { [[ -x ~/.config/hypr/scripts/hamadaos-backup.sh ]]; }
check "Settings backup tool" t_backup - "re-run install.sh" warn

# ═══ Summary ═══════════════════════════════════════════════════════════════════
if [[ "$MODE" == "json" ]]; then
    printf '{"summary":true,"pass":%d,"warn":%d,"fail":%d,"fixed":%d}\n' "$PASS" "$WARN" "$FAIL" "$FIXED"
else
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo -e "  ${GREEN}$PASS passed${NC} · ${YELLOW}$WARN warnings${NC} · ${RED}$FAIL failures${NC}${FIXED:+ · $FIXED fixed}"
    [[ $FAIL -eq 0 ]] && echo "  System healthy. Go play. 🎮"
    [[ $FAIL -gt 0 && "$MODE" != "fix" ]] && echo "  Run with --fix to auto-repair."
fi
exit $(( FAIL > 0 ? 1 : 0 ))
