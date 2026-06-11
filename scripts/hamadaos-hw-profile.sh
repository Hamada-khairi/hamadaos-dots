#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# HamadaOS — Hardware Profiler
# ═══════════════════════════════════════════════════════════════════════════════
# Detects what machine we're on ONCE and writes ~/.config/hamadaos/hardware.env.
# Everything performance-related (hamadaos-game-run, gaming-mode.sh) reads
# this file instead of guessing — that's how the same dotfiles behave
# correctly on an MX350 Optimus ultrabook, a 40W RTX 3050 laptop, a desktop
# 4070, or an all-AMD machine.
#
# Run automatically by install.sh; re-run any time hardware changes:
#   ~/.config/hypr/scripts/hamadaos-hw-profile.sh
# ═══════════════════════════════════════════════════════════════════════════════

set -uo pipefail

OUT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hamadaos"
OUT="$OUT_DIR/hardware.env"
mkdir -p "$OUT_DIR"

# ── Virtualization (decides the entire graphics strategy) ───────────────────────
VIRT_TYPE="$(systemd-detect-virt 2>/dev/null || echo none)"
IS_VM=0
[[ "$VIRT_TYPE" != "none" ]] && IS_VM=1

# Does the VM expose accelerated 3D? (virtio-gpu with virgl, vmwgfx with 3D on)
VM_HAS_3D=0
if [[ $IS_VM -eq 1 ]]; then
    if compgen -G "/dev/dri/renderD*" >/dev/null \
       && grep -qsE 'virtio_gpu|vmwgfx|qxl' /sys/class/drm/card*/device/uevent 2>/dev/null; then
        VM_HAS_3D=1
    fi
fi

# ── GPUs ────────────────────────────────────────────────────────────────────────
GPUS="$(lspci -nn 2>/dev/null | grep -Ei 'vga|3d|display' || true)"

HAS_NVIDIA=0; HAS_AMD_GPU=0; HAS_INTEL_GPU=0
echo "$GPUS" | grep -qi 'nvidia'              && HAS_NVIDIA=1
echo "$GPUS" | grep -qiE 'amd|ati|radeon'     && HAS_AMD_GPU=1
echo "$GPUS" | grep -qi 'intel'               && HAS_INTEL_GPU=1

GPU_COUNT="$(echo "$GPUS" | grep -c . || echo 0)"

# Hybrid graphics (Optimus / AMD switchable): iGPU + dGPU present together.
IS_HYBRID=0
if [[ $GPU_COUNT -ge 2 && $HAS_NVIDIA -eq 1 && ( $HAS_INTEL_GPU -eq 1 || $HAS_AMD_GPU -eq 1 ) ]]; then
    IS_HYBRID=1
elif [[ $GPU_COUNT -ge 2 && $HAS_AMD_GPU -eq 1 && $HAS_INTEL_GPU -eq 1 ]]; then
    IS_HYBRID=1
fi

# NVIDIA driver actually loaded? (nouveau vs proprietary matters)
NVIDIA_PROPRIETARY=0
[[ $HAS_NVIDIA -eq 1 ]] && lsmod 2>/dev/null | grep -q '^nvidia ' && NVIDIA_PROPRIETARY=1

# ── VRAM (MB) — the single most important number for weak-GPU tuning ───────────
VRAM_MB=0
if [[ $NVIDIA_PROPRIETARY -eq 1 ]] && command -v nvidia-smi >/dev/null 2>&1; then
    VRAM_MB="$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | sort -rn | head -1 || echo 0)"
else
    # AMD/Intel: largest VRAM among DRM devices
    for f in /sys/class/drm/card*/device/mem_info_vram_total; do
        [[ -r "$f" ]] || continue
        mb=$(( $(cat "$f") / 1024 / 1024 ))
        (( mb > VRAM_MB )) && VRAM_MB=$mb
    done
fi
VRAM_MB="${VRAM_MB:-0}"

LOW_VRAM=0
[[ "$VRAM_MB" -gt 0 && "$VRAM_MB" -le 4608 ]] && LOW_VRAM=1   # ≤4.5GB: MX350(2G), 3050(4G)

# ── RAM ─────────────────────────────────────────────────────────────────────────
RAM_GB=$(( $(grep MemTotal /proc/meminfo | awk '{print $2}') / 1024 / 1024 ))
LOW_RAM=0
[[ $RAM_GB -le 12 ]] && LOW_RAM=1

# ── Chassis: laptop vs desktop (battery present = laptop) ───────────────────────
IS_LAPTOP=0
compgen -G "/sys/class/power_supply/BAT*" >/dev/null && IS_LAPTOP=1

# ── CPU ─────────────────────────────────────────────────────────────────────────
CPU_VENDOR="unknown"
grep -qi 'GenuineIntel' /proc/cpuinfo && CPU_VENDOR="intel"
grep -qi 'AuthenticAMD' /proc/cpuinfo && CPU_VENDOR="amd"
CPU_CORES="$(nproc)"

# Shared-TDP thin laptop heuristic: hybrid laptop + low VRAM dGPU.
# On these, CPU boost steals package power the GPU needs (the 40W 3050 case).
TDP_SHARED=0
[[ $IS_LAPTOP -eq 1 && $IS_HYBRID -eq 1 && $LOW_VRAM -eq 1 ]] && TDP_SHARED=1

# ── ReBAR (Resizable BAR) — decides VKD3D upload heuristics ─────────────────────
HAS_REBAR=0
if [[ $NVIDIA_PROPRIETARY -eq 1 ]] && command -v nvidia-smi >/dev/null 2>&1; then
    # >256MB BAR1 = ReBAR active
    BAR1="$(nvidia-smi -q 2>/dev/null | grep -A2 'BAR1 Memory' | grep Total | grep -oE '[0-9]+' | head -1 || echo 0)"
    [[ "${BAR1:-0}" -gt 512 ]] && HAS_REBAR=1
fi

# ── DRM card mapping (MUX-less hybrid fix) ──────────────────────────────────────
# On hybrid laptops the panel is wired to the iGPU. Hyprland MUST composite on
# the iGPU — if it picks the dGPU, every desktop frame double-copies over PCIe
# and the dGPU can never power down. We detect which /dev/dri/card* belongs to
# which driver and write an explicit AQ_DRM_DEVICES ordering (iGPU first).
IGPU_CARD=""; DGPU_CARD=""
for card in /sys/class/drm/card?; do
    [[ -e "$card/device/driver" ]] || continue
    drv="$(basename "$(readlink -f "$card/device/driver")")"
    node="/dev/dri/$(basename "$card")"
    case "$drv" in
        i915|xe)          IGPU_CARD="$node" ;;
        nvidia)           DGPU_CARD="$node" ;;
        amdgpu)
            # amdgpu can be either; boot_vga flag disambiguates
            if [[ "$(cat "$card/device/boot_vga" 2>/dev/null)" == "1" && -z "$IGPU_CARD" ]]; then
                IGPU_CARD="$node"
            else
                DGPU_CARD="$node"
            fi ;;
    esac
done

GPU_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/gpu.conf"
mkdir -p "$(dirname "$GPU_CONF")"
if [[ $IS_VM -eq 1 ]]; then
    # ── VM MODE — why Hyprland "doesn't work in VMs" and the three counters ──
    #  1. No hardware cursor plane    → render the cursor in software
    #  2. Fake/absent DRM modifiers   → disable explicit sync, simple buffers
    #  3. Weak or no 3D acceleration  → llvmpipe (CPU) rendering when there's
    #     no render node; kill blur/shadows so llvmpipe stays interactive
    cat > "$GPU_CONF" <<EOF
# Auto-generated by hamadaos-hw-profile.sh — VIRTUAL MACHINE ($VIRT_TYPE).
# Full HamadaOS runs for testing; gaming features no-op gracefully.

cursor {
    no_hardware_cursors = true
}

# Virtual displays announce odd mode lists — take the preferred one.
monitor = Virtual-1, preferred, auto, 1

# Explicit sync needs real fences; VMs lie about them.
render {
    explicit_sync = 0
}

misc {
    vrr = 0
}
EOF
    if [[ $VM_HAS_3D -eq 0 ]]; then
        cat >> "$GPU_CONF" <<'EOF'

# No GPU render node — CPU rendering (llvmpipe). Usable for testing;
# heavy effects would make it crawl, so they're off.
env = LIBGL_ALWAYS_SOFTWARE,1
env = GALLIUM_DRIVER,llvmpipe
decoration {
    blur { enabled = false }
    shadow { enabled = false }
}
EOF
    fi
elif [[ $IS_HYBRID -eq 1 && -n "$IGPU_CARD" && -n "$DGPU_CARD" ]]; then
    cat > "$GPU_CONF" <<EOF
# Auto-generated by hamadaos-hw-profile.sh — MUX-less hybrid laptop detected.
# Hyprland composites on the iGPU ($IGPU_CARD); games offload to the dGPU
# ($DGPU_CARD) via hamadaos-game-run. Do not edit — re-run the profiler.
env = AQ_DRM_DEVICES,$IGPU_CARD:$DGPU_CARD
EOF
else
    cat > "$GPU_CONF" <<EOF
# Auto-generated by hamadaos-hw-profile.sh — single-GPU system, no override.
EOF
fi

# ── Write profile ────────────────────────────────────────────────────────────────
cat > "$OUT" <<EOF
# Auto-generated by hamadaos-hw-profile.sh — $(date -Iseconds)
# Re-run the script after hardware/driver changes. Do not edit by hand.
IS_VM=$IS_VM
VIRT_TYPE=$VIRT_TYPE
VM_HAS_3D=$VM_HAS_3D
HAS_NVIDIA=$HAS_NVIDIA
NVIDIA_PROPRIETARY=$NVIDIA_PROPRIETARY
HAS_AMD_GPU=$HAS_AMD_GPU
HAS_INTEL_GPU=$HAS_INTEL_GPU
IS_HYBRID=$IS_HYBRID
VRAM_MB=$VRAM_MB
LOW_VRAM=$LOW_VRAM
RAM_GB=$RAM_GB
LOW_RAM=$LOW_RAM
IS_LAPTOP=$IS_LAPTOP
TDP_SHARED=$TDP_SHARED
CPU_VENDOR=$CPU_VENDOR
CPU_CORES=$CPU_CORES
HAS_REBAR=$HAS_REBAR
EOF

echo "[hw-profile] wrote $OUT:"
cat "$OUT" | grep -v '^#'
