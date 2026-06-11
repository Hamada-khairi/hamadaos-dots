// ═══════════════════════════════════════════════════════════════════════════════
// HamadaOS — System Info Service (CPU / GPU / RAM / temps / uptime)
// ═══════════════════════════════════════════════════════════════════════════════
// Polls every 2 seconds while something is actually displaying the data
// (Control Center open, Settings → Gaming open). Zero work when hidden.
//
//   cpuPercent / ramPercent — parsed from /proc via FileView (async-safe)
//   gpuPercent / gpuTemp    — nvidia-smi or AMD sysfs, auto-detected
//   kernel / uptime         — live, for the Control Center detail card
// ═══════════════════════════════════════════════════════════════════════════════

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

Singleton {
    id: root

    // Components that show stats set this true while visible.
    property int watchers: 0
    readonly property bool polling: watchers > 0

    property real cpuPercent: 0
    property real gpuPercent: 0
    property real ramPercent: 0
    property real cpuTemp: 0
    property real gpuTemp: 0
    property string kernel: ""
    property string uptime: ""

    property string cpuPercentStr: cpuPercent.toFixed(0) + "%"
    property string gpuPercentStr: gpuPercent.toFixed(0) + "%"
    property string ramPercentStr: ramPercent.toFixed(0) + "%"
    property string cpuTempStr: cpuTemp > 0 ? cpuTemp.toFixed(0) + "°C" : "--"
    property string gpuTempStr: gpuTemp > 0 ? gpuTemp.toFixed(0) + "°C" : "--"

    property var _prevCpu: null

    Timer {
        interval: 2000
        running: root.polling
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statFile.reload()
            meminfoFile.reload()
            gpuProc.running = true
            miscProc.running = true
        }
    }

    // ── CPU — parse in onLoaded so we never read stale text ────────────────
    FileView {
        id: statFile
        path: "/proc/stat"
        onLoaded: {
            const m = text().match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/)
            if (!m) return
            const stats = m.slice(1).map(Number)
            const total = stats.reduce((a, b) => a + b, 0)
            const idle = stats[3] + stats[4]   // idle + iowait
            if (root._prevCpu) {
                const dt = total - root._prevCpu.total
                const di = idle - root._prevCpu.idle
                if (dt > 0) root.cpuPercent = Math.max(0, Math.min(100, (1 - di / dt) * 100))
            }
            root._prevCpu = { total: total, idle: idle }
        }
    }

    // ── RAM ─────────────────────────────────────────────────────────────────
    FileView {
        id: meminfoFile
        path: "/proc/meminfo"
        onLoaded: {
            const t = text()
            const total = Number(t.match(/MemTotal:\s*(\d+)/)?.[1] ?? 1)
            const avail = Number(t.match(/MemAvailable:\s*(\d+)/)?.[1] ?? 0)
            root.ramPercent = total > 0 ? ((total - avail) / total) * 100 : 0
        }
    }

    // ── GPU — NVIDIA via nvidia-smi, AMD via sysfs (any cardN) ─────────────
    Process {
        id: gpuProc
        command: ["sh", "-c",
            "if command -v nvidia-smi >/dev/null 2>&1; then " +
            "  nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits 2>/dev/null; " +
            "else " +
            "  busy=$(cat /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -1); " +
            "  temp=$(cat /sys/class/drm/card*/device/hwmon/hwmon*/temp1_input 2>/dev/null | head -1); " +
            "  [ -n \"$busy\" ] && echo \"$busy, $(( ${temp:-0} / 1000 ))\"; " +
            "fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",")
                const util = parseFloat(parts[0])
                const temp = parseFloat(parts[1])
                if (!isNaN(util)) root.gpuPercent = util
                if (!isNaN(temp)) root.gpuTemp = temp
            }
        }
    }

    // ── Kernel, uptime, CPU temp ─────────────────────────────────────────────
    Process {
        id: miscProc
        command: ["sh", "-c",
            "uname -r; uptime -p | sed 's/^up //'; " +
            "cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -rn | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                root.kernel = lines[0] ?? ""
                root.uptime = lines[1] ?? ""
                const t = parseInt(lines[2])
                if (!isNaN(t)) root.cpuTemp = t > 1000 ? t / 1000 : t
            }
        }
    }
}
