// ═══════════════════════════════════════════════════════════════════════════════
// HamadaOS — Monitor Service (multi-monitor management from Settings)
// ═══════════════════════════════════════════════════════════════════════════════
// The Windows "Display settings" experience for 3-monitor setups:
//   - lists every monitor (including disabled ones) with its available modes
//   - applies resolution/refresh/scale/enable live via hyprctl
//   - "Save layout" persists the current state into monitors.conf
//
// Data source: hyprctl monitors all -j (availableModes included).
// ═══════════════════════════════════════════════════════════════════════════════

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // [{ name, description, width, height, refreshRate, x, y, scale,
    //    disabled, vrr, availableModes: ["1920x1080@144.00Hz", ...] }]
    property var monitors: []

    function refresh() { listProc.running = true }

    Process {
        id: listProc
        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.monitors = JSON.parse(text) } catch (e) {
                    console.log("[MonitorService] parse failed: " + e)
                }
            }
        }
    }

    // ── Live apply ───────────────────────────────────────────────────────────
    // mode: "2560x1440@165" (or "" to keep current), scale like 1.0/1.25
    function applyMode(mon, mode, scale) {
        const m = mode && mode !== "" ? mode : (mon.width + "x" + mon.height + "@" + Math.round(mon.refreshRate))
        const pos = mon.x + "x" + mon.y
        Quickshell.execDetached(["hyprctl", "keyword", "monitor",
            `${mon.name},${m},${pos},${scale}`])
        refreshSoon.restart()
    }

    function setEnabled(mon, enabled) {
        if (enabled)
            Quickshell.execDetached(["hyprctl", "keyword", "monitor",
                `${mon.name},preferred,auto,1`])
        else
            Quickshell.execDetached(["hyprctl", "keyword", "monitor",
                `${mon.name},disable`])
        refreshSoon.restart()
    }

    Timer {
        id: refreshSoon
        interval: 600; repeat: false
        onTriggered: root.refresh()
    }

    // ── Persist the CURRENT live state into monitors.conf ────────────────────
    function saveLayout() {
        let out = "# HamadaOS — monitor layout (written by Settings → Display → Save layout)\n"
        out += "# Edit from the Settings app, or with nwg-displays.\n\n"
        for (const m of monitors) {
            if (m.disabled) {
                out += `monitor = ${m.name}, disable\n`
            } else {
                const rate = (m.refreshRate ?? 60).toFixed(2)
                const vrr = m.vrr ? ", vrr, 1" : ""
                out += `monitor = ${m.name}, ${m.width}x${m.height}@${rate}, ${m.x}x${m.y}, ${m.scale}${vrr}\n`
            }
        }
        out += "\n# Fallback for newly plugged monitors:\nmonitor = , preferred, auto, 1\n"
        confFile.setText(out)
    }

    FileView {
        id: confFile
        path: Quickshell.env("HOME") + "/.config/hypr/monitors.conf"
    }

    Component.onCompleted: refresh()
}
