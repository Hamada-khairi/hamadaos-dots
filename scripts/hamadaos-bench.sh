#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# HamadaOS — Benchmark & Telemetry Capture
# ═══════════════════════════════════════════════════════════════════════════════
# "Measure, don't guess." Captures everything needed to evaluate a tuning
# change, then prints the numbers that actually matter for smoothness:
#
#   · frametimes from MangoHud logs → avg fps, 1% low, 0.1% low,
#     99th-percentile frametime (the stutter number)
#   · GPU clocks, temperature, and THROTTLE REASONS sampled every second
#     (nvidia-smi on NVIDIA, sysfs on AMD)
#
# Usage:
#   hamadaos-bench.sh start      — begin a capture session
#   hamadaos-bench.sh stop       — end session, print + save the report
#   hamadaos-bench.sh report     — re-print the last report
#
# Workflow: start → play 5 minutes of the same level → stop. Change ONE
# thing. Repeat. Compare reports in ~/.local/share/hamadaos/bench/.
# MangoHud must be on (Settings → Gaming) — logging starts automatically.
# ═══════════════════════════════════════════════════════════════════════════════

set -uo pipefail

BENCH_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/hamadaos/bench"
SESSION_DIR="$BENCH_DIR/current"
mkdir -p "$BENCH_DIR"

# ── GPU sampler (1Hz): clocks, temp, utilization, throttle reasons ──────────────
sample_gpu() {
    local out="$1"
    if command -v nvidia-smi >/dev/null 2>&1; then
        echo "time,clock_mhz,mem_mhz,temp_c,util_pct,power_w,throttle" > "$out"
        while :; do
            local line reasons
            line="$(nvidia-smi --query-gpu=clocks.gr,clocks.mem,temperature.gpu,utilization.gpu,power.draw --format=csv,noheader,nounits 2>/dev/null | head -1)"
            # Active throttle reasons (the "why is it slow" answer)
            reasons="$(nvidia-smi -q -d PERFORMANCE 2>/dev/null \
                | grep -E 'SW Thermal|HW Thermal|SW Power|HW Power|Sync Boost' \
                | grep -i active | grep -vi 'not active' \
                | sed 's/ *: Active//; s/^ *//' | paste -sd'+' -)"
            echo "$(date +%s),${line// /},${reasons:-none}" >> "$out"
            sleep 1
        done
    else
        echo "time,clock_mhz,temp_c,util_pct" > "$out"
        while :; do
            local clk temp util
            clk="$(cat /sys/class/drm/card*/device/pp_dpm_sclk 2>/dev/null | grep '\*' | grep -oE '[0-9]+Mhz' | head -1 | tr -d 'Mhz')"
            temp="$(cat /sys/class/drm/card*/device/hwmon/hwmon*/temp1_input 2>/dev/null | head -1)"
            util="$(cat /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -1)"
            echo "$(date +%s),${clk:-0},$(( ${temp:-0} / 1000 )),${util:-0}" >> "$out"
            sleep 1
        done
    fi
}

case "${1:-}" in
start)
    rm -rf "$SESSION_DIR"; mkdir -p "$SESSION_DIR"
    # Tell MangoHud to log frametimes here (picked up by next game launch,
    # or press Shift_L+F2 in an already-running game to toggle logging).
    mkdir -p "$HOME/.config/MangoHud"
    grep -q "output_folder" "$HOME/.config/MangoHud/MangoHud.conf" 2>/dev/null \
        || echo "output_folder=$SESSION_DIR" >> "$HOME/.config/MangoHud/MangoHud.conf"
    sed -i "s|^output_folder=.*|output_folder=$SESSION_DIR|" "$HOME/.config/MangoHud/MangoHud.conf"

    sample_gpu "$SESSION_DIR/gpu.csv" &
    echo $! > "$SESSION_DIR/sampler.pid"
    date +%s > "$SESSION_DIR/started"
    echo "[bench] Capturing → $SESSION_DIR"
    echo "[bench] In-game: Shift_L+F2 starts/stops MangoHud frametime logging."
    echo "[bench] Play your test scene, then: hamadaos-bench.sh stop"
    ;;

stop)
    [[ -f "$SESSION_DIR/sampler.pid" ]] && kill "$(cat "$SESSION_DIR/sampler.pid")" 2>/dev/null || true
    STAMP="$(date +%Y%m%d-%H%M%S)"
    FINAL="$BENCH_DIR/$STAMP"
    mv "$SESSION_DIR" "$FINAL"
    "$0" report "$FINAL"
    ;;

report)
    DIR="${2:-$(ls -d "$BENCH_DIR"/2* 2>/dev/null | sort | tail -1)}"
    [[ -d "$DIR" ]] || { echo "[bench] no sessions found"; exit 1; }
    echo "═══ HamadaOS Bench Report — $(basename "$DIR") ═══════════════"

    # ── Frametime stats from MangoHud CSV logs ──────────────────────────────
    FT_LOG="$(ls "$DIR"/*.csv 2>/dev/null | grep -v gpu.csv | head -1)"
    if [[ -n "${FT_LOG:-}" && -f "$FT_LOG" ]]; then
        # MangoHud log: col1=fps, col2=frametime(ms) after 3 header lines
        awk -F, 'NR>3 && $2+0>0 {print $2}' "$FT_LOG" | sort -n > /tmp/hamadaos-ft.$$
        N=$(wc -l < /tmp/hamadaos-ft.$$)
        if [[ "$N" -gt 100 ]]; then
            AVG=$(awk '{s+=$1} END {printf "%.2f", s/NR}' /tmp/hamadaos-ft.$$)
            P99=$(awk -v n="$N" 'NR==int(n*0.99){printf "%.2f", $1}' /tmp/hamadaos-ft.$$)
            # 1% low fps = mean of worst 1% frametimes, inverted
            LOW1=$(tail -n "$(( N / 100 + 1 ))" /tmp/hamadaos-ft.$$ | awk '{s+=$1} END {printf "%.1f", 1000/(s/NR)}')
            LOW01=$(tail -n "$(( N / 1000 + 1 ))" /tmp/hamadaos-ft.$$ | awk '{s+=$1} END {printf "%.1f", 1000/(s/NR)}')
            echo "  Frames captured : $N"
            echo "  Average fps     : $(awk -v a="$AVG" 'BEGIN{printf "%.1f", 1000/a}')"
            echo "  1% low fps      : $LOW1"
            echo "  0.1% low fps    : $LOW01     ← the stutter number"
            echo "  99th %ile frame : ${P99}ms"
        else
            echo "  Not enough frametime data (enable MangoHud + Shift_L+F2 logging)."
        fi
        rm -f /tmp/hamadaos-ft.$$
    else
        echo "  No MangoHud frametime log found in this session."
    fi

    # ── GPU behavior ─────────────────────────────────────────────────────────
    if [[ -f "$DIR/gpu.csv" ]]; then
        echo ""
        awk -F, 'NR>1 && $2+0>0 {c+=$2; n++; if($2<min||!min)min=$2; if($2>max)max=$2}
                 END {if(n) printf "  GPU clock       : avg %dMHz  (min %d / max %d)\n", c/n, min, max}' "$DIR/gpu.csv"
        awk -F, 'NR>1 && $4+0>0 {t+=$4; n++; if($4>max)max=$4}
                 END {if(n) printf "  GPU temp        : avg %d°C  (peak %d°C)\n", t/n, max}' "$DIR/gpu.csv" 2>/dev/null
        THROTTLED=$(awk -F, 'NR>1 && $NF!="none" && $NF!="" {n++} END {print n+0}' "$DIR/gpu.csv")
        TOTAL=$(awk 'END {print NR-1}' "$DIR/gpu.csv")
        if [[ "$THROTTLED" -gt 0 ]]; then
            echo "  THROTTLING      : ${THROTTLED}s of ${TOTAL}s ($(( THROTTLED * 100 / (TOTAL==0?1:TOTAL) ))%)"
            awk -F, 'NR>1 && $NF!="none" && $NF!="" {print $NF}' "$DIR/gpu.csv" | sort | uniq -c | sort -rn \
                | head -3 | sed 's/^/      /'
        else
            echo "  THROTTLING      : none detected ✓"
        fi
    fi
    echo "════════════════════════════════════════════════════════════"
    echo "  Full data: $DIR"
    ;;

*)
    echo "Usage: hamadaos-bench.sh <start|stop|report>"
    exit 1
    ;;
esac
