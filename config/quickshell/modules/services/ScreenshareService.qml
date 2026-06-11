// ═══════════════════════════════════════════════════════════════════════════════
// HamadaOS — Screenshare Guard
// ═══════════════════════════════════════════════════════════════════════════════
// Solves "I share my screen on Discord and tearing starts / fps tanks."
//
// Hyprland emits a `screencast` IPC event the instant ANY portal capture
// starts or stops (Discord, OBS, browser tab share). We react in real time:
//
//   share STARTS →  · disable tearing (immediate page-flips + screencopy
//                     produce torn, broken capture frames AND visible tearing)
//                   · force VRR off for the duration (capture clocks the
//                     frame timeline; VRR + capture = pacing fights)
//   share STOPS  →  · restore whatever gaming mode wants
//
// Windows can't do this — apps can't reconfigure the compositor per-capture.
// ═══════════════════════════════════════════════════════════════════════════════

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    property bool sharing: false

    function init() { /* touching the singleton instantiates the listener */ }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name !== "screencast") return
            // payload: "STATE,OWNER" — STATE 1 = a capture session started
            const active = event.data.split(",")[0] === "1"
            if (active === root.sharing) return
            root.sharing = active

            if (active) {
                // Tearing + screencopy = torn frames on both ends. Kill it.
                Quickshell.execDetached(["hyprctl", "--batch",
                    "keyword general:allow_tearing false ; keyword misc:vrr 0"])
                Quickshell.execDetached(["notify-send", "-a", "HamadaOS",
                    "-i", "video-display", "-t", "3000",
                    "Screenshare mode", "Tearing off · VRR paused — restored when you stop sharing"])
            } else {
                // Back to whatever the current mode wants.
                const gaming = GamingService.active
                Quickshell.execDetached(["hyprctl", "--batch",
                    "keyword general:allow_tearing true ; keyword misc:vrr " + (gaming ? "2" : "1")])
            }
        }
    }
}
