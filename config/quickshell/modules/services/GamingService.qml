// ═══════════════════════════════════════════════════════════════════════════════
// HamadaOS — Gaming Mode Service
// ═══════════════════════════════════════════════════════════════════════════════
// One toggle, one implementation: gaming-mode.sh is the single source of
// truth (it's also bound to Super+Shift+G). The script:
//   - switches HyDE's workflow to "gaming" (kills blur/shadows/animations)
//   - sets tuned-adm throughput-performance + CPU performance governor
//     (via a sudoers drop-in installed by install.sh — no password prompt)
//   - sets VRR to fullscreen-only
//
// State lives in the flag file the script writes; we watch it so the QML
// toggle stays in sync no matter which side flipped the mode.
// ═══════════════════════════════════════════════════════════════════════════════

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

Singleton {
    id: root

    property bool active: false
    readonly property string flagPath:
        Quickshell.env("XDG_RUNTIME_DIR") + "/hamadaos-gaming-mode"

    function toggle() {
        Quickshell.execDetached([
            Quickshell.env("HOME") + "/.config/hypr/scripts/gaming-mode.sh"
        ])
        // The flag-file watcher below confirms the state change.
    }

    function restore() {
        // If gaming mode was on when the shell restarted, just reflect it.
        flagWatcher.reload()
    }

    FileView {
        id: flagWatcher
        path: root.flagPath
        watchChanges: true
        onLoaded: { root.active = true; Config.options.gamingMode = true }
        onLoadFailed: { root.active = false; Config.options.gamingMode = false }
        onFileChanged: reload()
    }

    // The flag file being deleted doesn't always emit fileChanged — poll
    // lazily as a fallback (cheap: one stat every 5s, only while active).
    Timer {
        interval: 5000
        running: root.active
        repeat: true
        onTriggered: flagWatcher.reload()
    }
}
