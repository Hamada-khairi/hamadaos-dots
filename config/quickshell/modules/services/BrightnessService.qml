// ═══════════════════════════════════════════════════════════════════════════════
// HamadaOS — Brightness Service (brightnessctl)
// ═══════════════════════════════════════════════════════════════════════════════
// Reads the backlight once at startup, then tracks state locally — writes go
// through brightnessctl. External changes (hardware keys bound to
// brightnessctl in Hyprland) also route through here via IPC, so state and
// OSD stay in sync without polling.
// ═══════════════════════════════════════════════════════════════════════════════

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // 0.0–1.0; -1 means "no backlight device" (desktop monitor — hide sliders)
    property real brightness: -1
    property bool available: brightness >= 0

    signal brightnessChangedByUser()

    function setBrightness(v) {
        const clamped = Math.max(0.01, Math.min(1, v))
        brightness = clamped
        Quickshell.execDetached(["brightnessctl", "set", Math.round(clamped * 100) + "%", "-q"])
        root.brightnessChangedByUser()
    }

    function increment() { if (available) setBrightness(brightness + 0.05) }
    function decrement() { if (available) setBrightness(brightness - 0.05) }

    function refresh() { readProc.running = true }

    Process {
        id: readProc
        command: ["sh", "-c", "echo $(( $(brightnessctl get 2>/dev/null || echo -1) * 100 / $(brightnessctl max 2>/dev/null || echo 1) ))"]
        stdout: StdioCollector {
            onStreamFinished: {
                const pct = parseInt(text.trim())
                root.brightness = (isNaN(pct) || pct < 0) ? -1 : pct / 100
            }
        }
    }

    Component.onCompleted: refresh()
}
