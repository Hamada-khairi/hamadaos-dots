#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# HamadaOS — Thermal Guard
# ═══════════════════════════════════════════════════════════════════════════════
# Started by gaming-mode.sh ON, killed by gaming-mode.sh OFF.
#
# The problem on 40W-class laptops: heat builds for 3-5 minutes, then the
# firmware hard-throttles and your stable 60fps becomes 38fps "for no reason."
# Windows does nothing about this. We act BEFORE the cliff:
#
#   Step 0 (normal)    : nothing — full speed
#   Step 1 (hot)       : cap CPU turbo → package watts flow to the GPU
#                        (on TDP-shared laptops this often RAISES fps)
#   Step 2 (throttling): notify with the actual throttle reason + suggestion
#
# Hysteresis, not a PID fantasy: escalate at the hot threshold, de-escalate
# only after cooling 8°C below it, never flap. Detection uses REAL throttle
# reasons from the driver where available (nvidia-smi), temps as fallback.
# All knobs come from the hardware profile — safe on any machine.
# ═══════════════════════════════════════════════════════════════════════════════

set -uo pipefail

CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hamadaos"
# shellcheck disable=SC1091
[[ -f "$CFG_DIR/hardware.env" ]] && source "$CFG_DIR/hardware.env"
IS_LAPTOP="${IS_LAPTOP:-0}"
TDP_SHARED="${TDP_SHARED:-0}"

# Desktops with real cooling don't need a babysitter.
[[ "$IS_LAPTOP" == "1" ]] || exit 0

HOT_C=87          # escalate above this (firmware limits are usually 95-100)
COOL_C=$(( HOT_C - 8 ))
STEP=0
LAST_NOTIFY=0

notify() {
    local now; now="$(date +%s)"
    (( now - LAST_NOTIFY < 60 )) && return    # max one notification per minute
    LAST_NOTIFY=$now
    notify-send -a "HamadaOS" -i "temperature-warm" -t 5000 "$1" "$2" 2>/dev/null || true
}

gpu_temp() {
    if command -v nvidia-smi >/dev/null 2>&1; then
        nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1
    else
        local t; t="$(cat /sys/class/drm/card*/device/hwmon/hwmon*/temp1_input 2>/dev/null | sort -rn | head -1)"
        echo $(( ${t:-0} / 1000 ))
    fi
}

cpu_temp() {
    local t; t="$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -rn | head -1)"
    echo $(( ${t:-0} / 1000 ))
}

gpu_throttling() {  # exit 0 if the driver says it's actively throttling
    command -v nvidia-smi >/dev/null 2>&1 || return 1
    nvidia-smi -q -d PERFORMANCE 2>/dev/null \
        | grep -E 'SW Thermal|HW Thermal|HW Power Brake' \
        | grep -qi ': Active'
}

while :; do
    GPU_T="$(gpu_temp)"; CPU_T="$(cpu_temp)"
    HOTTEST=$(( GPU_T > CPU_T ? GPU_T : CPU_T ))

    if [[ $STEP -eq 0 && ( $HOTTEST -ge $HOT_C ) ]]; then
        # ── Escalate step 1: shift watts from CPU to GPU ────────────────────
        if [[ "$TDP_SHARED" == "1" ]]; then
            sudo -n /usr/local/bin/hamadaos-perf-tune cpu-boost-off 2>/dev/null || true
            notify "Thermal guard: step 1" \
                   "${HOTTEST}°C — CPU turbo capped so the GPU keeps its clocks"
        else
            notify "Running hot" "${HOTTEST}°C — consider an FPS cap (Settings → Gaming)"
        fi
        STEP=1

    elif [[ $STEP -ge 1 ]] && gpu_throttling; then
        # ── Step 2: firmware is throttling anyway — tell the truth ──────────
        notify "GPU is throttling (firmware)" \
               "Lower the FSR render scale or set an FPS cap — free fps over raw heat"
        STEP=2

    elif [[ $STEP -ge 1 && $HOTTEST -le $COOL_C ]]; then
        # ── De-escalate: cooled down with margin ─────────────────────────────
        if [[ "$TDP_SHARED" == "1" ]]; then
            # Respect the user's manual GPU-priority setting — only restore
            # boost if they didn't ask for permanent capping.
            GPU_PRIO="$(jq -r '.gpuPriority // false' "$CFG_DIR/config.json" 2>/dev/null || echo false)"
            [[ "$GPU_PRIO" != "true" ]] && sudo -n /usr/local/bin/hamadaos-perf-tune cpu-boost-on 2>/dev/null || true
        fi
        STEP=0
    fi

    sleep 5
done
