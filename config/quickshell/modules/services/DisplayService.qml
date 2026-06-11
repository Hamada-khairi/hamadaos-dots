// ═══════════════════════════════════════════════════════════════════════════════
// HamadaOS — Display Service (VRR + monitor tools)
// ═══════════════════════════════════════════════════════════════════════════════
// Brightness lives in BrightnessService; this handles VRR state (read live
// from Hyprland, not assumed) and launching the drag-and-drop monitor tool.
// ═══════════════════════════════════════════════════════════════════════════════

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // 0 = off, 1 = global, 2 = fullscreen-only
    property int vrrMode: 1

    function refresh() { vrrProc.running = true }

    function setVrr(mode) {
        vrrMode = mode
        Quickshell.execDetached(["hyprctl", "keyword", "misc:vrr", String(mode)])
    }

    function openMonitorArrangement() {
        Quickshell.execDetached(["nwg-displays"])
    }

    Process {
        id: vrrProc
        command: ["hyprctl", "getoption", "misc:vrr", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.vrrMode = JSON.parse(text).int ?? 1 } catch (e) { }
            }
        }
    }

    Component.onCompleted: refresh()
}
